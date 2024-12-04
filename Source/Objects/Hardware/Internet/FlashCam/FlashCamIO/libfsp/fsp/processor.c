#include <stdio.h>
#include <stddef.h>
#include <stdlib.h>

#include <fcio.h>
#include <time_utils.h>

#include "buffer.h"
#include "flags.h"
#include "record_processor.h"
#include "processor.h"


void FSPEnableTriggerFlags(StreamProcessor* processor, TriggerFlags flags)
{
  processor->triggerconfig.enabled_flags.trigger = flags;
  if (processor->loglevel >= 4) fprintf(stderr, "DEBUG FSPEnableTriggerFlags: %llu\n", (unsigned long long)flags.is_flagged);
}

void FSPEnableEventFlags(StreamProcessor* processor, EventFlags flags)
{
  processor->triggerconfig.enabled_flags.event = flags;
  if (processor->loglevel >= 4) fprintf(stderr, "DEBUG FSPEnableEventFlags: %llu\n", (unsigned long long)flags.is_flagged);
}

void FSPSetWPSReferences(StreamProcessor* processor, HWMFlags hwm_flags, CTFlags ct_flags, WPSFlags wps_flags, int* ct_tracemap_index, int n_ct_tracemap_indices)
{
  processor->triggerconfig.wps_reference_flags_hwm = hwm_flags;
  processor->triggerconfig.wps_reference_flags_ct = ct_flags;
  processor->triggerconfig.wps_reference_flags_wps = wps_flags;
  if (ct_tracemap_index && n_ct_tracemap_indices > 0) {
    for (int i = 0; i < n_ct_tracemap_indices; i++) {
      processor->triggerconfig.wps_reference_tracemap_index[i] = ct_tracemap_index[i];
    }
    processor->triggerconfig.n_wps_reference_tracemap_indices = n_ct_tracemap_indices;
  }
  if (processor->loglevel >= 4) fprintf(stderr, "DEBUG FSPSetWPSReferenceFlags: hwm %llu ct %llu wps %llu\n", (unsigned long long)hwm_flags.is_flagged, (unsigned long long)ct_flags.is_flagged, (unsigned long long)wps_flags.is_flagged);
}

void FSPSetLogLevel(StreamProcessor* processor, int loglevel)
{
  processor->loglevel = loglevel;
}

void FSPSetLogTime(StreamProcessor* processor, double log_time)
{
  processor->stats->log_time = log_time;
}

int FSPFlush(StreamProcessor* processor)
{
  if (!processor) return 0;

  return FSPBufferFlush(processor->buffer);
}

int FSPFreeStates(StreamProcessor* processor)
{
  if (!processor) return 0;

  return processor->buffer->max_states - processor->buffer->fill_level;
}

StreamProcessor* FSPCreate(unsigned int buffer_depth)
{
  StreamProcessor* processor = calloc(1, sizeof(StreamProcessor));
  processor->stats = calloc(1, sizeof(FSPStats));

  processor->minimum_buffer_window.nanoseconds =
      (FCIOMaxSamples + 1) * 16;        // this is required to check for retrigger events
  processor->minimum_buffer_depth = 16; // the minimum buffer window * 30kHz event rate requires at least 16 records

  FSPSetBufferSize(processor, buffer_depth);

  processor->dsp_hwm = calloc(1, sizeof(DSPHardwareMajority));
  processor->dsp_hwm->enabled = 0;
  processor->dsp_ct = calloc(1, sizeof(DSPChannelThreshold));
  processor->dsp_ct->enabled = 0;
  processor->dsp_wps = calloc(1, sizeof(DSPWindowedPeakSum));
  processor->dsp_wps->enabled = 0;

  processor->hwm_prescale_timestamp.seconds = -1; // will init when it's needed
  processor->wps_prescale_timestamp.seconds = -1; // will init when it's needed

  /* hardcoded defaults which should make sense. Used SetFunctions outside to overwrite */
  FSPEnableEventFlags(processor, (EventFlags){ .is_retrigger = 1, .is_extended = 1});
  FSPEnableTriggerFlags(processor, (TriggerFlags){ .hwm_multiplicity = 1, .hwm_prescaled = 1, .wps_abs = 1, .wps_rel = 1, .wps_prescaled = 1, .ct_multiplicity = 1} );
  HWMFlags ref_hwm = {0};
  ref_hwm.multiplicity_threshold = 1;
  CTFlags ref_ct = {0};
  WPSFlags ref_wps = {0};
  FSPSetWPSReferences(processor, ref_hwm, ref_ct, ref_wps, NULL, 0);

  return processor;
}

void FSPDestroy(StreamProcessor* processor)
{
  if (processor) {
    FSPBufferDestroy(processor->buffer);
    free(processor->stats);
    free(processor->dsp_hwm);
    free(processor->dsp_wps);
    free(processor->dsp_ct);
  }
  free(processor);
}

int FSPInput(StreamProcessor* processor, FCIOState* state)
{
  if (!processor || !state) return 0;

  FSPState* fsp_state = FSPBufferPeekState(processor->buffer);

  if (!fsp_state) {
    fprintf(stderr, "CRITICAL FSPInput: Buffer full, refuse to overwrite.\n");
    return 0;
  }
  if ((state->last_tag == FCIOEvent) || (state->last_tag == FCIOSparseEvent)) {
    processor->nevents_read++;
  }
  processor->nrecords_read++;

  int rc = fsp_process(processor, fsp_state, state);

  FSPBufferCommitState(processor->buffer);

  if (!rc)
    return 0;  // This is a proxy for 0 free states, even though we do have some. Something in previous code did not
               // work out, and the FSPGetNextState function returns NULL on nfree = 0;

  return FSPBufferFreeLevel(processor->buffer);
}

static inline void fsp_derive_triggerflags(StreamProcessor* processor, FSPState* fsp_state)
{
  /*
    This function calculates the trigger flag fields from the individual processor flags
  */
  if (processor->triggerconfig.enabled_flags.trigger.hwm_multiplicity && fsp_state->proc_flags.hwm.multiplicity_threshold)
    fsp_state->write_flags.trigger.hwm_multiplicity = 1;

  if (processor->triggerconfig.enabled_flags.trigger.hwm_prescaled && fsp_state->proc_flags.hwm.prescaled) {
    fsp_state->write_flags.trigger.hwm_multiplicity = 0;
    fsp_state->write_flags.trigger.hwm_prescaled = 1;
  }

  if (processor->triggerconfig.enabled_flags.trigger.ct_multiplicity && fsp_state->proc_flags.ct.multiplicity)
    fsp_state->write_flags.trigger.ct_multiplicity = 1;

  if (processor->triggerconfig.enabled_flags.trigger.wps_abs && fsp_state->proc_flags.wps.abs_threshold)
    fsp_state->write_flags.trigger.wps_abs = 1;

  if (processor->triggerconfig.enabled_flags.trigger.wps_rel && fsp_state->proc_flags.wps.rel_threshold)
    if (fsp_state->proc_flags.wps.rel_pre_window || fsp_state->proc_flags.wps.rel_post_window) {
      fsp_state->write_flags.trigger.wps_rel = 1;
    }

  if (processor->triggerconfig.enabled_flags.trigger.hwm_prescaled && fsp_state->proc_flags.hwm.prescaled)
    fsp_state->write_flags.trigger.hwm_prescaled = 1;

  if (processor->triggerconfig.enabled_flags.trigger.wps_prescaled && fsp_state->proc_flags.wps.prescaled)
    fsp_state->write_flags.trigger.wps_prescaled = 1;
}

static inline uint32_t fsp_write_decision(FSPState* fsp_state) {
  if ((fsp_state->state->last_tag != FCIOEvent) && (fsp_state->state->last_tag != FCIOSparseEvent))
    return 1;

  if (fsp_state->write_flags.event.is_flagged || fsp_state->write_flags.trigger.is_flagged)
    return 1;

  return 0;
}

FSPState* FSPOutput(StreamProcessor* processor)
{
  if (!processor) return NULL;

  FSPState* fsp_state = FSPBufferFetchState(processor->buffer);

  if (!fsp_state) {
    return NULL;
  }

  fsp_derive_triggerflags(processor, fsp_state);

  fsp_state->write_flags.write = fsp_write_decision(fsp_state);

  if (fsp_state->write_flags.write) {
    processor->nrecords_written++;
    if ((fsp_state->state->last_tag == FCIOEvent) || (fsp_state->state->last_tag == FCIOSparseEvent))
      processor->nevents_written++;

  } else {
    processor->nrecords_discarded++;
    if ((fsp_state->state->last_tag == FCIOEvent) || (fsp_state->state->last_tag == FCIOSparseEvent))
      processor->nevents_discarded++;
  }

  return fsp_state;
}

int FSPSetBufferSize(StreamProcessor* processor, unsigned int buffer_depth) {
  if (processor->buffer) {
    FSPBufferDestroy(processor->buffer);
  }
  if (buffer_depth < processor->minimum_buffer_depth)
    buffer_depth = processor->minimum_buffer_depth;

  Timestamp buffer_window = timestamp_greater(processor->minimum_buffer_window, processor->triggerconfig.pre_trigger_window)
                                ? processor->minimum_buffer_window
                                : processor->triggerconfig.pre_trigger_window;
  processor->buffer = FSPBufferCreate(buffer_depth, buffer_window);
  if (!processor->buffer) {
    if (processor->loglevel) fprintf(stderr, "ERROR FSPSetBufferSize: Couldn't allocate FSPBuffer.\n");

    return 0;
  }
    if (processor->loglevel >=2) {
        fprintf(stderr, "DEBUG FSPSetBufferSize to depth %d and window %ld.%09ld\n", processor->buffer->max_states, processor->buffer->buffer_window.seconds, processor->buffer->buffer_window.nanoseconds);
    }
  return buffer_depth;
}

FSPState* FSPGetNextState(StreamProcessor* processor, FCIOStateReader* reader, int* timedout) {
  /*
  - check if buffered -> write
  - no buffered, getnextstate until buffered reader -> write
  - no buffered and getnextstate null -> exit
  */
  if (timedout) *timedout = 0;

  if (!processor || !reader) return NULL;

  if (!processor->buffer && FSPSetBufferSize(processor, reader->max_states - 1)) return NULL;

  FSPState* fsp_state = NULL;
  FCIOState* state = NULL;
  int nfree = FSPFreeStates(processor);

  while (!(fsp_state = FSPOutput(processor))) {
    /* this should handle the timeout, so we don't have to do it in the processor.
     */
    if (!nfree) {
      if (timedout) *timedout = 10;
      return NULL;
    }
    state = FCIOGetNextState(reader, timedout);

    if (!state) {
      /* End-of-Stream or timeout reached, fcio will close with any of the following timedout states:
        timedout == 0 here means stream is closed, no timeout was reached
        timedout == 1 no event from buffer for specified timeout interval.
        timedout == 2 stream is still alive, but only unselected tags arrived
      */
      if (FSPFlush(processor)) {
        continue;  // still something in the buffer. FSPFlush unlocks the buffer and FSPOutput will read until the end.
      } else {
        return NULL;
      }
    } else {
      nfree = FSPInput(processor,state);  // got a valid state
    }
  }

  return fsp_state;
}
