#pragma once

#include <fsp_timestamps.h>
#include <fsp_stats.h>
#include <fsp_state.h>
#include <fsp_buffer.h>
#include <fsp_dsp.h>

#include <fcio.h>

#define FC_MAXTICKS 249999999

typedef struct StreamProcessor {
  Timestamp pre_trigger_window;
  Timestamp post_trigger_window;

  int nrecords_read;
  int nrecords_written;
  int nrecords_discarded;

  int nevents_read;
  int nevents_written;
  int nevents_discarded;

  /* move to processor */
  Timestamp force_trigger_timestamp;
  Timestamp post_trigger_timestamp;
  Timestamp pre_trigger_timestamp;

  float relative_wps_threshold;
  float absolute_wps_threshold;
  int hwm_threshold;
  int muon_coincidence;

  uint64_t wps_reference_flags_ct;
  uint64_t wps_reference_flags_hwm;
  uint64_t wps_reference_flags_wps;

  int wps_prescale_ratio;
  int wps_prescale_ready_counter;
  float wps_prescale_rate;
  Timestamp wps_prescale_timestamp;

  int hwm_prescale_ratio;
  int hwm_prescale_ready_counter;
  float hwm_prescale_rate;
  Timestamp hwm_prescale_timestamp;

  int loglevel;

  FSPStats* stats;

  int checks;

  FSPFlags enabled_flags;

  FSPBuffer *buffer;
  Timestamp minimum_buffer_window;
  int minimum_buffer_depth;

  WindowedPeakSumConfig *wps_cfg;
  HardwareMajorityConfig *hwm_cfg;
  ChannelThresholdConfig *ct_cfg;

} StreamProcessor;


int fsp_process(StreamProcessor* processor, FSPState* fsp_state, FCIOState* state);
// unsigned int fsp_write_decision(FSPState* fsp_state);
