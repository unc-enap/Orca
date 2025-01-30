#include "fsp_buffer.h"

#include <assert.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#include <stdio.h>

FSPBuffer *FSPBufferCreate(unsigned int buffer_depth, Timestamp buffer_window) {
  FSPBuffer *buffer = (FSPBuffer *)calloc(1, sizeof(FSPBuffer));

  buffer->max_states = buffer_depth + 1;
  buffer->buffer_window = buffer_window;

  buffer->fsp_states = (FSPState *)calloc(buffer->max_states, sizeof(FSPState));

  buffer->insert_state = 0;
  buffer->nrecords_inserted = 0;

  return buffer;
}

void FSPBufferDestroy(FSPBuffer *buffer) {
  if (buffer)
    free(buffer->fsp_states);
  free(buffer);
}

FSPState *FSPBufferGetState(FSPBuffer *buffer, int offset) {
  if (!buffer) return NULL;

  int index = (buffer->insert_state + buffer->max_states - 1 + offset) % buffer->max_states;
  FSPState* return_state = &buffer->fsp_states[index];

  if (offset == 0 || offset == 1) {
    return return_state;

  } else if (offset < 0) {
    if (-offset >= buffer->nrecords_inserted || -offset > buffer->max_states - 1) {
      return NULL;
    }

    return return_state;

  } else {
    return NULL;
  }
}

FSPState *FSPBufferPeekState(FSPBuffer *buffer) {
  /* the state is still in the buffer, and is not allowed to be modified*/
  FSPState* return_state = FSPBufferGetState(buffer, 1);
  if (return_state && return_state->in_buffer)
    return NULL;
  return return_state;
}

void FSPBufferCommitState(FSPBuffer *buffer) {
  FSPState *fsp_state = FSPBufferGetState(buffer, 1);

  fsp_state->in_buffer = 1;
  buffer->insert_state = (buffer->insert_state + 1) % buffer->max_states;
  buffer->nrecords_inserted++;
  if (fsp_state->has_timestamp)
    buffer->buffer_timestamp = timestamp_sub(fsp_state->timestamp, buffer->buffer_window);

  buffer->fill_level++;
  // fprintf(stderr, "DEBUG/BUFFER: insert_state %d has_timestamp %d fill_level %d last_tag %d\n", buffer->insert_state-1, fsp_state->has_timestamp, buffer->fill_level, fsp_state->state->last_tag);
}

FSPState *FSPBufferFetchState(FSPBuffer *buffer) {
  FSPState *fsp_state = &buffer->fsp_states[buffer->fetch_state];

  if (fsp_state && fsp_state->in_buffer &&
      (timestamp_greater(buffer->buffer_timestamp, fsp_state->timestamp) || buffer->flush_buffer)) {
    // advance to the next possible send state
    buffer->fetch_state = (buffer->fetch_state + 1) % buffer->max_states;

    buffer->nrecords_fetched++;
    buffer->fill_level--;

    // record is handed off, forget about it
    fsp_state->in_buffer = 0;

    return fsp_state;
  }

  return NULL;
}

int FSPBufferFillLevel(FSPBuffer *buffer) {
  return buffer->fill_level;
}

int FSPBufferFreeLevel(FSPBuffer *buffer) {
  return buffer->max_states - buffer->fill_level;
}

int FSPBufferFlush(FSPBuffer *buffer) {
  buffer->flush_buffer = 1;
  return FSPBufferFillLevel(buffer);
}
