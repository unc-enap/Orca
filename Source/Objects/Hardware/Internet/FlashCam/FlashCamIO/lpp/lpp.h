#pragma once

#include <dsp.h>
#include <fcio.h>
#include <lpp_buffer.h>
#include <lpp_state.h>
#include <stddef.h>
#include <stdio.h>
#include <timestamps.h>

typedef struct LPPStats {
  double start_time;
  double log_time;
  double dt_logtime;
  double runtime;

  int n_read_events;
  int n_written_events;
  int n_discarded_events;

  int current_nread;
  int current_nwritten;
  int current_ndiscarded;

  double dt_current;
  double current_read_rate;
  double current_write_rate;
  double current_discard_rate;

  double avg_read_rate;
  double avg_write_rate;
  double avg_discard_rate;

} LPPStats;

typedef struct PostProcessor {
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

  float windowed_sum_threshold_pe;
  float sum_threshold_pe;
  int majority_threshold;
  int muon_coincidence;

  int sipm_prescaling_offset;
  int sipm_prescaling_counter;
  float sipm_prescaling_rate;
  char *sipm_prescaling;

  Timestamp sipm_prescaling_timestamp;
  Timestamp ge_prescaling_timestamp;

  int ge_prescaling_threshold_adc;
  float ge_prescaling_rate;

  int loglevel;

  LPPStats stats;

  int checks;

  unsigned int set_trigger_flags;
  unsigned int set_event_flags;

  struct {
    int pulser_trace_index;
    int pulser_adc_threshold;

    int baseline_trace_index;
    int baseline_adc_threshold;

    int muon_trace_index;
    int muon_adc_threshold;

    int tracemap_format;
  } aux;

  LPPBuffer *buffer;
  Timestamp minimum_buffer_window;
  int minimum_buffer_depth;

  AnalogueSumCfg *analogue_sum_cfg;
  FPGAMajorityCfg *fpga_majority_cfg;

} PostProcessor;

/* Con-/Destructors and required setup. */

PostProcessor *LPPCreate(void);
void LPPDestroy(PostProcessor *processor);
int LPPSetBufferSize(PostProcessor *processor, int buffer_depth);

/* Change defaults*/

void LPPSetLogLevel(PostProcessor *processor, int loglevel);
void LPPSetLogTime(PostProcessor *processor, double log_time);

void LPPEnableTriggerFlags(PostProcessor *processor, unsigned int flags);
void LPPEnableEventFlags(PostProcessor *processor, unsigned int flags);

/* use in loop operations:
  - Feed FCIOStates via LPPInput asap
  - Poll LPPOutput until NULL
  - if states are null, buffer is flushed
*/

void LPPFlags2char(LPPState *lpp_state, size_t strlen, char *cstring);

int LPPInput(PostProcessor *processor, FCIOState *state);
LPPState *LPPOutput(PostProcessor *processor);
int LPPFlush(PostProcessor *processor);
int LPPFreeStates(PostProcessor *processor);
LPPState *LPPGetNextState(PostProcessor *processor, FCIOStateReader *reader, int *timedout);
int LPPStatsUpdate(PostProcessor *processor, int force);
int LPPStatsInfluxString(PostProcessor *processor, char *logstring, size_t logstring_size);

int LPPSetAuxParameters(PostProcessor *processor, const char *channelmap_format, int digital_pulser_channel,
                        int pulser_level_adc, int digital_baseline_channel, int baseline_level_adc,
                        int digital_muon_channel, int muon_level_adc);

int LPPSetGeParameters(PostProcessor *processor, int nchannels, int *channelmap, const char *channelmap_format,
                       int majority_threshold, int skip_full_counting, unsigned short *ge_prescaling_threshold_adc,
                       float ge_average_prescaling_rate_hz);

int LPPSetSiPMParameters(PostProcessor *processor, int nchannels, int *channelmap, const char *channelmap_format,
                         float *calibration_factors, float *channel_thresholds_pe, int *shaping_width_samples,
                         float *lowpass_factors, int coincidence_pre_window_ns, int coincidence_post_window_ns,
                         int coincidence_window_samples, int sum_window_start_sample, int sum_window_stop_sample,
                         float sum_threshold_pe, float coincidence_sum_threshold_pe, float average_prescaling_rate_hz,
                         int enable_muon_coincidence);
