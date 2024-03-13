#pragma once

#include <lpp_state.h>
#include <timestamps.h>

typedef struct LPPBuffer {
  int insert_state;
  int fetch_state;
  int max_states;
  LPPState *lpp_states;

  int nrecords_inserted;
  int nrecords_fetched;
  int fill_level;

  int flush_buffer;

  Timestamp buffer_timestamp;
  Timestamp buffer_window;

} LPPBuffer;

LPPBuffer *LPPBufferCreate(unsigned int buffer_depth, Timestamp buffer_window);
void LPPBufferDestroy(LPPBuffer *buffer);
LPPState *LPPBufferGetState(LPPBuffer *buffer, int offset);
LPPState *LPPBufferPeek(LPPBuffer *buffer);
void LPPBufferCommit(LPPBuffer *buffer);
LPPState *LPPBufferFetch(LPPBuffer *buffer);
int LPPBufferFillLevel(LPPBuffer *buffer);
int LPPBufferFreeLevel(LPPBuffer *buffer);
int LPPBufferFlush(LPPBuffer *buffer);
