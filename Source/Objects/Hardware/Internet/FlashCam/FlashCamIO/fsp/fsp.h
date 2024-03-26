#pragma once

#include <fsp_processor.h>
#include <fsp_dsp.h>
#include <fsp_state.h>
#include <fsp_stats.h>
#include <fsp_l200.h>
#include <fsp_channelmaps.h>

#include <stddef.h>

#include <fcio.h>

/* Con-/Destructors and required setup. */

StreamProcessor *FSPCreate(void);
void FSPDestroy(StreamProcessor *processor);
int FSPSetBufferSize(StreamProcessor *processor, int buffer_depth);

/* Change defaults*/

void FSPSetLogLevel(StreamProcessor *processor, int loglevel);
void FSPSetLogTime(StreamProcessor *processor, double log_time);

void FSPEnableTriggerFlags(StreamProcessor *processor, unsigned int flags);
void FSPEnableEventFlags(StreamProcessor *processor, unsigned int flags);

/* use in loop operations:
  - Feed FCIOStates via LPPInput asap
  - Poll LPPOutput until NULL
  - if states are null, buffer is flushed
*/

int FSPInput(StreamProcessor *processor, FCIOState *state);
FSPState *FSPOutput(StreamProcessor *processor);
int FSPFlush(StreamProcessor *processor);
int FSPFreeStates(StreamProcessor *processor);
FSPState *FSPGetNextState(StreamProcessor *processor, FCIOStateReader *reader, int *timedout);

int FSPStatsInfluxString(StreamProcessor* processor, char* logstring, size_t logstring_size);
int FSPStatsUpdate(StreamProcessor* processor, int force);
