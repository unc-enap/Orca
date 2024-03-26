#include "fsp_l200.h"

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

int FSPSetAuxParameters(StreamProcessor* processor, FSPChannelFormat format, int digital_pulser_channel,
                        int pulser_level_adc, int digital_baseline_channel, int baseline_level_adc,
                        int digital_muon_channel, int muon_level_adc) {
  if (!is_known_channelmap_format(format)) {
    if (processor->loglevel)
      fprintf(stderr,
              "ERROR LPPSetAuxParameters: channel map type %s is not supported. Valid inputs are \"fcio-trace-index\", "
              "\"fcio-tracemap\" or \"rawid\".\n",
              channelmap_fmt2str(format));
    return 0;
  }
  processor->aux.tracemap_format = format;

  processor->aux.pulser_trace_index = digital_pulser_channel;
  processor->aux.pulser_adc_threshold = pulser_level_adc;
  processor->aux.baseline_trace_index = digital_baseline_channel;
  processor->aux.baseline_adc_threshold = baseline_level_adc;
  processor->aux.muon_trace_index = digital_muon_channel;
  processor->aux.muon_adc_threshold = muon_level_adc;

  if (processor->loglevel >= 4) {
    fprintf(stderr, "DEBUG LPPSetAuxParameters\n");
    fprintf(stderr, "DEBUG channelmap_format %d : %s\n", processor->aux.tracemap_format, channelmap_fmt2str(format));
    if (processor->aux.tracemap_format == 1) {
      fprintf(stderr, "DEBUG digital_pulser_channel   0x%x level_adc %d\n", processor->aux.pulser_trace_index,
              processor->aux.pulser_adc_threshold);
      fprintf(stderr, "DEBUG digital_baseline_channel 0x%x level_adc %d\n", processor->aux.baseline_trace_index,
              processor->aux.baseline_adc_threshold);
      fprintf(stderr, "DEBUG digital_muon_channel     0x%x level_adc %d\n", processor->aux.muon_trace_index,
              processor->aux.muon_adc_threshold);
    } else {
      fprintf(stderr, "DEBUG digital_pulser_channel   %d level_adc %d\n", processor->aux.pulser_trace_index,
              processor->aux.pulser_adc_threshold);
      fprintf(stderr, "DEBUG digital_baseline_channel %d level_adc %d\n", processor->aux.baseline_trace_index,
              processor->aux.baseline_adc_threshold);
      fprintf(stderr, "DEBUG digital_muon_channel     %d level_adc %d\n", processor->aux.muon_trace_index,
              processor->aux.muon_adc_threshold);
    }
  }
  return 1;
}

int FSPSetGeParameters(StreamProcessor* processor, int nchannels, int* channelmap, FSPChannelFormat format,
                       int majority_threshold, int skip_full_counting, unsigned short* ge_prescaling_threshold_adc,
                       float ge_average_prescaling_rate_hz) {
  processor->hwm_cfg = calloc(1, sizeof(HardwareMajorityConfig));
  HardwareMajorityConfig* fmc = processor->hwm_cfg;

  if (!is_known_channelmap_format(format)) {
    if (processor->loglevel)
      fprintf(stderr,
              "ERROR LPPSetGeParameters: channel map type %s is not supported. Valid inputs are \"fcio-trace-index\", "
              "\"fcio-tracemap\" or \"rawid\".\n",
              channelmap_fmt2str(format));
    free(fmc);
    return 0;
  }
  fmc->tracemap_format = format;
  fmc->ntraces = nchannels;

  for (int i = 0; i < nchannels && i < FCIOMaxChannels; i++) {
    fmc->tracemap[i] = channelmap[i];
    fmc->fpga_energy_threshold_adc[i] = ge_prescaling_threshold_adc[i];
  }
  fmc->fast = skip_full_counting;
  if (majority_threshold >= 0)
    processor->majority_threshold = majority_threshold;
  else {
    fprintf(stderr, "CRITICAL majority_threshold needs to be >= 0 is %d\n", majority_threshold);
    return 0;
  }
  if (ge_average_prescaling_rate_hz >= 0.0)
    processor->ge_prescaling_rate = ge_average_prescaling_rate_hz;
  else {
    fprintf(stderr, "CRITICAL ge_average_prescaling_rate_hz needs to be >= 0.0 is %f\n", ge_average_prescaling_rate_hz);
    return 0;
  }

  if (processor->loglevel >= 4) {
    fprintf(stderr, "DEBUG LPPSetGeParameters\n");
    fprintf(stderr, "DEBUG majority_threshold %d\n", majority_threshold);
    fprintf(stderr, "DEBUG average_prescaling_rate_hz %f\n", ge_average_prescaling_rate_hz);
    fprintf(stderr, "DEBUG skip_full_counting %d\n", fmc->fast);
    fprintf(stderr, "DEBUG channelmap_format %d : %s\n", fmc->tracemap_format, channelmap_fmt2str(format));
    for (int i = 0; i < fmc->ntraces; i++) {
      if (fmc->tracemap_format == 1) {
        fprintf(stderr, "DEBUG channel 0x%x\n", fmc->tracemap[i]);
      } else {
        fprintf(stderr, "DEBUG channel %d\n", fmc->tracemap[i]);
      }
    }
  }
  return 1;
}

int FSPSetSiPMParameters(StreamProcessor* processor, int nchannels, int* channelmap, FSPChannelFormat format,
                         float* calibration_pe_adc, float* channel_thresholds_pe, int* shaping_width_samples,
                         float* lowpass_factors, int coincidence_pre_window_ns, int coincidence_post_window_ns,
                         int coincidence_window_samples, int sum_window_start_sample, int sum_window_stop_sample,
                         float sum_threshold_pe, float coincidence_sum_threshold_pe, float average_prescaling_rate_hz,
                         int enable_muon_coincidence) {
  processor->wps_cfg = calloc(1, sizeof(WindowedPeakSumConfig));
  WindowedPeakSumConfig* asc = processor->wps_cfg;

  if (!is_known_channelmap_format(format)) {
    if (processor->loglevel)
      fprintf(stderr,
              "CRITICAL LPPSetSiPMParameters: channel map type %s is not supported. Valid inputs are "
              "\"fcio-trace-index\", \"fcio-tracemap\" or \"rawid\".\n",
              channelmap_fmt2str(format));
    free(asc);
    return 0;
  }
  asc->tracemap_format = format;

  if (coincidence_sum_threshold_pe >= 0)
    processor->relative_sum_threshold_pe = coincidence_sum_threshold_pe;
  else {
    fprintf(stderr, "CRICITAL coincidence_sum_threshold_pe needs to be >= 0 is %f\n", coincidence_sum_threshold_pe);
    return 0;
  }

  if (sum_threshold_pe >= 0)
    processor->absolute_sum_threshold_pe = sum_threshold_pe;
  else {
    fprintf(stderr, "CRICITAL sum_threshold_pe needs to be >= 0 is %f\n", sum_threshold_pe);
    return 0;
  }

  processor->pre_trigger_window.seconds = coincidence_pre_window_ns / 1000000000L;
  processor->pre_trigger_window.nanoseconds = coincidence_pre_window_ns % 1000000000L;
  processor->post_trigger_window.seconds = coincidence_post_window_ns / 1000000000L;
  processor->post_trigger_window.nanoseconds = coincidence_post_window_ns % 1000000000L;
  processor->sipm_prescaling_rate = average_prescaling_rate_hz;
  if (processor->sipm_prescaling_rate > 0.0)
    processor->sipm_prescaling = "average";  // could be "offset" when selecting ->sipm_prescaling_offset, but is disabled here.
  else
    processor->sipm_prescaling = NULL;
  processor->muon_coincidence = enable_muon_coincidence;

  // asc->repetition = processor->fast?4:sma_repetition;
  asc->coincidence_window = coincidence_window_samples;
  asc->sum_window_start_sample = sum_window_start_sample;
  asc->sum_window_stop_sample = sum_window_stop_sample;

  asc->trigger_list.size = 0;
  asc->trigger_list.threshold = coincidence_sum_threshold_pe; // use the same threshold as the processor to check for the flag

  /* TODO CHECK THIS*/
  asc->apply_gain_scaling = 1;

  asc->ntraces = nchannels;

  asc->dsp_pre_max_samples = 0;
  asc->dsp_post_max_samples = 0;
  for (int i = 0; i < nchannels && i < FCIOMaxChannels; i++) {
    asc->tracemap[i] = channelmap[i];

    if (calibration_pe_adc[i] >= 0) {
      asc->gains[i] = calibration_pe_adc[i];
    } else {
      fprintf(stderr, "CRITICAL calibration_pe_adc for channel[%d] = %d needs to be >= 0 is %f\n", i, channelmap[i], calibration_pe_adc[i]);
      return 0;
    }

    if (channel_thresholds_pe[i] >= 0) {
      asc->thresholds[i] = channel_thresholds_pe[i];
    } else {
      fprintf(stderr, "CRITICAL channel_thresholds_pe for channel[%d] = %d needs to be >= 0 is %f\n", i, channelmap[i], channel_thresholds_pe[i]);
      return 0;
    }

    if (shaping_width_samples[i] >= 1) {
      asc->shaping_widths[i] = shaping_width_samples[i];
    } else {
      fprintf(stderr, "CRITICAL shaping_width_samples for channel[%d] = %d needs to be >= 1 is %d\n", i, channelmap[i], shaping_width_samples[i]);
      return 0;
    }

    if (lowpass_factors[i] >= 0) {
      asc->lowpass[i] = lowpass_factors[i];
    } else {
      fprintf(stderr, "CRITICAL lowpass_factors for channel[%d] = %d needs to be >= 0 is %f\n", i, channelmap[i], lowpass_factors[i]);
      return 0;
    }

    asc->dsp_pre_samples[i] = fsp_dsp_diff_and_smooth_pre_samples(shaping_width_samples[i], asc->lowpass[i]);
    if (asc->dsp_pre_samples[i] > asc->dsp_pre_max_samples) asc->dsp_pre_max_samples = asc->dsp_pre_samples[i];
    asc->dsp_post_samples[i] = fsp_dsp_diff_and_smooth_post_samples(shaping_width_samples[i], asc->lowpass[i]);
    if (asc->dsp_post_samples[i] > asc->dsp_post_max_samples) asc->dsp_post_max_samples = asc->dsp_post_samples[i];
  }

  if (processor->loglevel >= 4) {
    /* DEBUGGING enabled, print all inputs */
    fprintf(stderr, "DEBUG LPPSetSiPMParameters:\n");
    fprintf(stderr, "DEBUG channelmap_format %d : %s\n", asc->tracemap_format, channelmap_fmt2str(format));
    fprintf(stderr, "DEBUG average_prescaling_rate_hz   %f\n", processor->sipm_prescaling_rate);
    fprintf(stderr, "DEBUG sum_window_start_sample      %d\n", asc->sum_window_start_sample);
    fprintf(stderr, "DEBUG sum_window_stop_sample       %d\n", asc->sum_window_stop_sample);
    fprintf(stderr, "DEBUG dsp_pre_max_samples          %d\n", asc->dsp_pre_max_samples);
    fprintf(stderr, "DEBUG dsp_post_max_samples         %d\n", asc->dsp_post_max_samples);
    fprintf(stderr, "DEBUG coincidence_pre_window_ns    %ld\n", processor->pre_trigger_window.nanoseconds);
    fprintf(stderr, "DEBUG coincidence_post_window_ns   %ld\n", processor->post_trigger_window.nanoseconds);
    fprintf(stderr, "DEBUG coincidence_window_samples   %d\n", asc->coincidence_window);
    fprintf(stderr, "DEBUG coincidence_sum_threshold_pe %f\n", processor->relative_sum_threshold_pe);
    fprintf(stderr, "DEBUG sum_threshold_pe             %f\n", processor->absolute_sum_threshold_pe);
    fprintf(stderr, "DEBUG enable_muon_coincidence      %d\n", processor->muon_coincidence);

    for (int i = 0; i < asc->ntraces; i++) {
      if (asc->tracemap_format == 1) {
        fprintf(
            stderr,
            "DEBUG channel 0x%x gain %f threshold %f shaping %d lowpass %f dsp_pre_samples %d dsp_post_samples %d\n",
            asc->tracemap[i], asc->gains[i], asc->thresholds[i], asc->shaping_widths[i], asc->lowpass[i],
            asc->dsp_pre_samples[i], asc->dsp_post_samples[i]);
      } else {
        fprintf(stderr,
                "DEBUG channel %d gain %f threshold %f shaping %d lowpass %f dsp_pre_samples %d dsp_post_samples %d\n",
                asc->tracemap[i], asc->gains[i], asc->thresholds[i], asc->shaping_widths[i], asc->lowpass[i],
                asc->dsp_pre_samples[i], asc->dsp_post_samples[i]);
      }
    }
  }
  return 1;
}

static inline size_t event_flag_2char(char* string, size_t strlen, unsigned int event_flags) {
  assert(strlen >= EVT_NSTATES);

  for (size_t i = 0; i < EVT_NSTATES; i++) string[i] = '_';

  if (event_flags & EVT_DF_PULSER) string[0] = 'P';
  if (event_flags & EVT_DF_BASELINE) string[1] = 'B';
  if (event_flags & EVT_DF_MUON) string[2] = 'M';
  if (event_flags & EVT_RETRIGGER) string[3] = 'R';
  if (event_flags & EVT_EXTENDED) string[3] = 'E';

  if (event_flags & EVT_HWM_MULT_THRESHOLD) string[4] = 'M';
  if (event_flags & EVT_HWM_MULT_ENERGY_BELOW) string[5] = 'L';
  if (event_flags & EVT_WPS_REL_REFERENCE) string[6] = '!';
  if (event_flags & EVT_WPS_REL_POST_WINDOW) string[7] = '<';
  if (event_flags & EVT_WPS_REL_THRESHOLD) string[8] = '-';
  if (event_flags & EVT_WPS_REL_PRE_WINDOW) string[9] = '>';
  // string[10] = '\0';
  return 10;
}

static inline size_t st_flag_2char(char* string, size_t strlen, unsigned int st_flags) {
  assert(strlen >= ST_NSTATES);

  for (size_t i = 0; i < ST_NSTATES; i++) string[i] = '_';

  if (st_flags & ST_HWM_TRIGGER) string[0] = 'M';
  if (st_flags & ST_HWM_PRESCALED) string[1] = 'G';
  if (st_flags & ST_WPS_ABS_TRIGGER) string[2] = 'P';
  if (st_flags & ST_WPS_REL_TRIGGER) string[3] = 'C';
  if (st_flags & ST_WPS_PRESCALED) string[4] = 'S';

  // string[10] = '\0';
  return 5;
}

void FSPFlags2Char(FSPState* fsp_state, size_t strlen, char* cstring) {
  assert(strlen >= ST_NSTATES + EVT_NSTATES + 4);

  for (size_t i = 0; i < ST_NSTATES + EVT_NSTATES + 4; i++) cstring[i] = '_';
  size_t curr_offset = 0;
  cstring[curr_offset++] = fsp_state->write ? 'W' : 'D';

  switch (fsp_state->stream_tag) {
    case FCIOConfig:
      cstring[curr_offset++] = 'C';
      break;
    case FCIOStatus:
      cstring[curr_offset++] = 'S';
      break;
    case FCIOEvent:
      cstring[curr_offset++] = 'E';
      break;
    case FCIOSparseEvent:
      cstring[curr_offset++] = 'Z';
      break;
    case FCIORecEvent:
      cstring[curr_offset++] = 'R';
      break;
    default:
      cstring[curr_offset++] = '?';
      break;
  }
  cstring[curr_offset++] = '.';

  curr_offset += st_flag_2char(&cstring[curr_offset], ST_NSTATES, fsp_state->flags.trigger);
  cstring[curr_offset++] = '.';

  curr_offset += event_flag_2char(&cstring[curr_offset], EVT_NSTATES, fsp_state->flags.event);
  cstring[curr_offset] = '\0';
}
