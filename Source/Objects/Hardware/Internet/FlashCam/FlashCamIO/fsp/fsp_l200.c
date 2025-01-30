#include "fsp_l200.h"

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

#include <fsp_state.h>

int FSPSetAuxParameters(StreamProcessor* processor, FSPChannelFormat format, int pulser_channel,
                        int pulser_level_adc, int baseline_channel, int baseline_level_adc,
                        int muon_channel, int muon_level_adc) {
  if (!is_known_channelmap_format(format)) {
    if (processor->loglevel)
      fprintf(stderr,
              "ERROR LPPSetAuxParameters: channel map type %s is not supported. Valid inputs are \"fcio-trace-index\", "
              "\"fcio-tracemap\" or \"rawid\".\n",
              channelmap_fmt2str(format));
    return 0;
  }
  processor->ct_cfg = calloc(1, sizeof(ChannelThresholdConfig));

  ChannelThresholdConfig* ct_cfg = processor->ct_cfg;

  ct_cfg->tracemap_format = format;
  ct_cfg->tracemap[0] = pulser_channel;
  ct_cfg->tracemap[1] = baseline_channel;
  ct_cfg->tracemap[2] = muon_channel;
  ct_cfg->thresholds[0] = pulser_level_adc;
  ct_cfg->thresholds[1] = baseline_level_adc;
  ct_cfg->thresholds[2] = muon_level_adc;
  ct_cfg->labels[0] = "Pulser";
  ct_cfg->labels[1] = "Baseline";
  ct_cfg->labels[2] = "Muon";
  ct_cfg->ntraces = 3;

  if (processor->loglevel >= 4) {
    fprintf(stderr, "DEBUG LPPSetAuxParameters\n");
    for (int i = 0; i < ct_cfg->ntraces; i++) {
      if (ct_cfg->tracemap_format == FCIO_TRACE_MAP_FORMAT) {
        fprintf(stderr, "DEBUG %s channel   0x%x level_adc %d\n", ct_cfg->labels[i], ct_cfg->tracemap[i],
                ct_cfg->thresholds[i]);
      } else {
        fprintf(stderr, "DEBUG %s channel   %d level_adc %d\n", ct_cfg->labels[i], ct_cfg->tracemap[i],
                ct_cfg->thresholds[i]);
      }
    }
  }
  return 1;
}

int FSPSetGeParameters(StreamProcessor* processor, int nchannels, int* channelmap, FSPChannelFormat format,
                       int majority_threshold, int skip_full_counting, unsigned short* ge_prescale_threshold_adc,
                       int prescale_ratio) {
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
    fmc->fpga_energy_threshold_adc[i] = ge_prescale_threshold_adc[i];
  }
  fmc->fast = skip_full_counting;
  if (majority_threshold >= 0)
    processor->hwm_threshold = majority_threshold;
  else {
    fprintf(stderr, "CRITICAL majority_threshold needs to be >= 0 is %d\n", majority_threshold);
    return 0;
  }
  if (prescale_ratio >= 0)
    processor->hwm_prescale_ratio = prescale_ratio;
  else {
    fprintf(stderr, "CRITICAL Ge prescale_ratio needs to be >= 0 is %d\n", prescale_ratio);
    return 0;
  }

  if (processor->loglevel >= 4) {
    fprintf(stderr, "DEBUG LPPSetGeParameters\n");
    fprintf(stderr, "DEBUG majority_threshold %d\n", majority_threshold);
    fprintf(stderr, "DEBUG prescale_ratio     %d\n", prescale_ratio);
    fprintf(stderr, "DEBUG skip_full_counting %d\n", fmc->fast);
    fprintf(stderr, "DEBUG channelmap_format  %d : %s\n", fmc->tracemap_format, channelmap_fmt2str(format));
    for (int i = 0; i < fmc->ntraces; i++) {
      if (fmc->tracemap_format == FCIO_TRACE_MAP_FORMAT) {
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
                         float sum_threshold_pe, float coincidence_wps_threshold, int prescale_ratio,
                         int enable_muon_coincidence) {
  processor->wps_cfg = calloc(1, sizeof(WindowedPeakSumConfig));
  WindowedPeakSumConfig* wps_cfg = processor->wps_cfg;

  if (!is_known_channelmap_format(format)) {
    if (processor->loglevel)
      fprintf(stderr,
              "CRITICAL LPPSetSiPMParameters: channel map type %s is not supported. Valid inputs are "
              "\"fcio-trace-index\", \"fcio-tracemap\" or \"rawid\".\n",
              channelmap_fmt2str(format));
    free(wps_cfg);
    return 0;
  }
  wps_cfg->tracemap_format = format;

  if (coincidence_wps_threshold >= 0)
    processor->relative_wps_threshold = coincidence_wps_threshold;
  else {
    fprintf(stderr, "CRICITAL coincidence_wps_threshold needs to be >= 0 is %f\n", coincidence_wps_threshold);
    return 0;
  }

  if (sum_threshold_pe >= 0)
    processor->absolute_wps_threshold = sum_threshold_pe;
  else {
    fprintf(stderr, "CRICITAL sum_threshold_pe needs to be >= 0 is %f\n", sum_threshold_pe);
    return 0;
  }

  processor->pre_trigger_window.seconds = coincidence_pre_window_ns / 1000000000L;
  processor->pre_trigger_window.nanoseconds = coincidence_pre_window_ns % 1000000000L;
  processor->post_trigger_window.seconds = coincidence_post_window_ns / 1000000000L;
  processor->post_trigger_window.nanoseconds = coincidence_post_window_ns % 1000000000L;
  processor->muon_coincidence = enable_muon_coincidence;
  if (prescale_ratio >= 0)
    processor->wps_prescale_ratio = prescale_ratio;
  else {
    fprintf(stderr, "CRITICAL SiPM prescale_ratio needs to be >= 0 is %d\n", prescale_ratio);
    return 0;
  }

  wps_cfg->coincidence_window = coincidence_window_samples;
  wps_cfg->sum_window_start_sample = sum_window_start_sample;
  wps_cfg->sum_window_stop_sample = sum_window_stop_sample;
  wps_cfg->coincidence_threshold = coincidence_wps_threshold;

  /* TODO CHECK THIS*/
  wps_cfg->apply_gain_scaling = 1;

  wps_cfg->ntraces = nchannels;

  wps_cfg->dsp_pre_max_samples = 0;
  wps_cfg->dsp_post_max_samples = 0;
  for (int i = 0; i < nchannels && i < FCIOMaxChannels; i++) {
    wps_cfg->tracemap[i] = channelmap[i];

    if (calibration_pe_adc[i] >= 0) {
      wps_cfg->gains[i] = calibration_pe_adc[i];
    } else {
      fprintf(stderr, "CRITICAL calibration_pe_adc for channel[%d] = %d needs to be >= 0 is %f\n", i, channelmap[i], calibration_pe_adc[i]);
      return 0;
    }

    if (channel_thresholds_pe[i] >= 0) {
      wps_cfg->thresholds[i] = channel_thresholds_pe[i];
    } else {
      fprintf(stderr, "CRITICAL channel_thresholds_pe for channel[%d] = %d needs to be >= 0 is %f\n", i, channelmap[i], channel_thresholds_pe[i]);
      return 0;
    }

    if (shaping_width_samples[i] >= 1) {
      wps_cfg->shaping_widths[i] = shaping_width_samples[i];
    } else {
      fprintf(stderr, "CRITICAL shaping_width_samples for channel[%d] = %d needs to be >= 1 is %d\n", i, channelmap[i], shaping_width_samples[i]);
      return 0;
    }

    if (lowpass_factors[i] >= 0) {
      wps_cfg->lowpass[i] = lowpass_factors[i];
    } else {
      fprintf(stderr, "CRITICAL lowpass_factors for channel[%d] = %d needs to be >= 0 is %f\n", i, channelmap[i], lowpass_factors[i]);
      return 0;
    }

    wps_cfg->dsp_pre_samples[i] = fsp_dsp_diff_and_smooth_pre_samples(shaping_width_samples[i], wps_cfg->lowpass[i]);
    if (wps_cfg->dsp_pre_samples[i] > wps_cfg->dsp_pre_max_samples) wps_cfg->dsp_pre_max_samples = wps_cfg->dsp_pre_samples[i];
    wps_cfg->dsp_post_samples[i] = fsp_dsp_diff_and_smooth_post_samples(shaping_width_samples[i], wps_cfg->lowpass[i]);
    if (wps_cfg->dsp_post_samples[i] > wps_cfg->dsp_post_max_samples) wps_cfg->dsp_post_max_samples = wps_cfg->dsp_post_samples[i];
  }

  if (processor->loglevel >= 4) {
    /* DEBUGGING enabled, print all inputs */
    fprintf(stderr, "DEBUG LPPSetSiPMParameters:\n");
    fprintf(stderr, "DEBUG channelmap_format %d : %s\n", wps_cfg->tracemap_format, channelmap_fmt2str(format));
    fprintf(stderr, "DEBUG prescale_ratio               %d\n", processor->wps_prescale_ratio);
    fprintf(stderr, "DEBUG sum_window_start_sample      %d\n", wps_cfg->sum_window_start_sample);
    fprintf(stderr, "DEBUG sum_window_stop_sample       %d\n", wps_cfg->sum_window_stop_sample);
    fprintf(stderr, "DEBUG dsp_pre_max_samples          %d\n", wps_cfg->dsp_pre_max_samples);
    fprintf(stderr, "DEBUG dsp_post_max_samples         %d\n", wps_cfg->dsp_post_max_samples);
    fprintf(stderr, "DEBUG coincidence_pre_window_ns    %ld\n", processor->pre_trigger_window.nanoseconds);
    fprintf(stderr, "DEBUG coincidence_post_window_ns   %ld\n", processor->post_trigger_window.nanoseconds);
    fprintf(stderr, "DEBUG coincidence_window_samples   %d\n", wps_cfg->coincidence_window);
    fprintf(stderr, "DEBUG relative_wps_threshold       %f\n", processor->relative_wps_threshold);
    fprintf(stderr, "DEBUG absolute_sum_threshold       %f\n", processor->absolute_wps_threshold);
    fprintf(stderr, "DEBUG enable_muon_coincidence      %d\n", processor->muon_coincidence);

    for (int i = 0; i < wps_cfg->ntraces; i++) {
      if (wps_cfg->tracemap_format == 1) {
        fprintf(
            stderr,
            "DEBUG channel 0x%x gain %f threshold %f shaping %d lowpass %f dsp_pre_samples %d dsp_post_samples %d\n",
            wps_cfg->tracemap[i], wps_cfg->gains[i], wps_cfg->thresholds[i], wps_cfg->shaping_widths[i], wps_cfg->lowpass[i],
            wps_cfg->dsp_pre_samples[i], wps_cfg->dsp_post_samples[i]);
      } else {
        fprintf(stderr,
                "DEBUG channel %d gain %f threshold %f shaping %d lowpass %f dsp_pre_samples %d dsp_post_samples %d\n",
                wps_cfg->tracemap[i], wps_cfg->gains[i], wps_cfg->thresholds[i], wps_cfg->shaping_widths[i], wps_cfg->lowpass[i],
                wps_cfg->dsp_pre_samples[i], wps_cfg->dsp_post_samples[i]);
      }
    }
  }
  return 1;
}
