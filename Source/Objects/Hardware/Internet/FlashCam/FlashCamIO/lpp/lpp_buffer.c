#include "lpp_buffer.h"

#include <assert.h>
#include <lpp_state.h>
#include <math.h>
#include <stdlib.h>
#include <string.h>

#include <stdio.h>

LPPBuffer *LPPBufferCreate(unsigned int buffer_depth, Timestamp buffer_window) {
  LPPBuffer *buffer = (LPPBuffer *)calloc(1, sizeof(LPPBuffer));

  buffer->max_states = buffer_depth + 1;
  buffer->buffer_window = buffer_window;

  buffer->lpp_states = (LPPState *)calloc(buffer->max_states, sizeof(LPPState));

  buffer->insert_state = 0;
  buffer->nrecords_inserted = 0;

  return buffer;
}

void LPPBufferDestroy(LPPBuffer *buffer) {
  if (buffer)
    free(buffer->lpp_states);
  free(buffer);
}

LPPState *LPPBufferGetState(LPPBuffer *buffer, int offset) {
  if (!buffer) return NULL;

  int index = (buffer->insert_state + buffer->max_states - 1 + offset) % buffer->max_states;
  LPPState* return_state = &buffer->lpp_states[index];

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

LPPState *LPPBufferPeek(LPPBuffer *buffer) {
  /* the state is still in the buffer, and is not allowed to be modified*/
  LPPState* return_state = LPPBufferGetState(buffer, 1);
  if (return_state && return_state->in_buffer)
    return NULL;
  return return_state;
}

void LPPBufferCommit(LPPBuffer *buffer) {
  LPPState *lpp_state = LPPBufferGetState(buffer, 1);

  lpp_state->in_buffer = 1;
  buffer->insert_state = (buffer->insert_state + 1) % buffer->max_states;
  buffer->nrecords_inserted++;
  if (lpp_state->contains_timestamp)
    buffer->buffer_timestamp = timestamp_sub(lpp_state->timestamp, buffer->buffer_window);

  buffer->fill_level++;
  // fprintf(stderr, "DEBUG/BUFFER: insert_state %d has_timestamp %d fill_level %d last_tag %d\n", buffer->insert_state-1, lpp_state->contains_timestamp, buffer->fill_level, lpp_state->state->last_tag);
}

LPPState *LPPBufferFetch(LPPBuffer *buffer) {
  LPPState *lpp_state = &buffer->lpp_states[buffer->fetch_state];

  if (lpp_state && lpp_state->in_buffer &&
      (timestamp_greater(buffer->buffer_timestamp, lpp_state->timestamp) || buffer->flush_buffer)) {
    // advance to the next possible send state
    buffer->fetch_state = (buffer->fetch_state + 1) % buffer->max_states;

    buffer->nrecords_fetched++;
    buffer->fill_level--;

    // record is handed off, forget about it ... until we reuse it.
    lpp_state->in_buffer = 0;

    return lpp_state;
  // } else {
    // Timestamp delta = timestamp_sub(buffer->buffer_timestamp, lpp_state->timestamp);
    // fprintf(stderr, "DEBUG/BUFFER: Cannot fetch from buffer: lpp_state %p in_buffer %d buffer_ts=%ld.%09ld lpp_state_ts=%ld.%09ld delta_ts=%ld.%09ld\n",
    //   (void*)lpp_state, lpp_state->in_buffer, buffer->buffer_timestamp.seconds, buffer->buffer_timestamp.nanoseconds,
    //   lpp_state->timestamp.seconds, lpp_state->timestamp.nanoseconds,
    //   delta.seconds, delta.nanoseconds
    // );
  }

  return NULL;
}

int LPPBufferFillLevel(LPPBuffer *buffer) {
  return buffer->fill_level;
}

int LPPBufferFreeLevel(LPPBuffer *buffer) {
  return buffer->max_states - buffer->fill_level;
}

int LPPBufferFlush(LPPBuffer *buffer) {
  buffer->flush_buffer = 1;
  return LPPBufferFillLevel(buffer);
}
