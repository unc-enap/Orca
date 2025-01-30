#pragma once


#include <fsp_processor.h>
#include <fsp_dsp.h>
#include <fsp_state.h>
#include <fsp_stats.h>
#include <fsp_l200.h>
#include <fsp_channelmaps.h>
#include <fsp_serializers.h>

#include <stdint.h>
#include <stddef.h>

#include <fcio.h>

/* Con-/Destructors and required setup. */

StreamProcessor *FSPCreate(void);
void FSPDestroy(StreamProcessor *processor);
int FSPSetBufferSize(StreamProcessor *processor, int buffer_depth);

/* Change defaults*/

void FSPSetLogLevel(StreamProcessor *processor, int loglevel);
void FSPSetLogTime(StreamProcessor *processor, double log_time);

void FSPEnableTriggerFlags(StreamProcessor *processor, STFlags flags);
void FSPEnableEventFlags(StreamProcessor *processor, EventFlags flags);
void FSPSetWPSReferenceFlag(StreamProcessor* processor, uint64_t hwm_flags, uint64_t ct_flags, uint64_t wps_flags);

/* Use FSPGetNextState to process states provided by FCIOStateReader until it returns NULL.
    - Feed FCIOStates from FCIOGetNextStatevia LPPInput
    - Poll FSPOutput until NULL
    - if states are null, buffer is flushed
*/
FSPState *FSPGetNextState(StreamProcessor *processor, FCIOStateReader *reader, int *timedout);

int FSPInput(StreamProcessor *processor, FCIOState *state);
FSPState *FSPOutput(StreamProcessor *processor);
int FSPFlush(StreamProcessor *processor);
int FSPFreeStates(StreamProcessor *processor);

int FSPStatsInfluxString(StreamProcessor* processor, char* logstring, size_t logstring_size);
int FSPStatsUpdate(StreamProcessor* processor, int force);
