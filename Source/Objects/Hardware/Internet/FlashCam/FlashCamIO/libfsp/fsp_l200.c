#include "fsp_l200.h"

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

int FSP_L200_SetAuxParameters(StreamProcessor* processor, FSPTraceFormat format, int pulser_channel,
                        int pulser_level_adc, int baseline_channel, int baseline_level_adc,
                        int muon_channel, int muon_level_adc) {
  if (!is_known_channelmap_format(format)) {
    if (processor->loglevel)
      fprintf(stderr,
              "ERROR FSP_L200_SetAuxParameters: channel map type %s is not supported. Valid inputs are \"fcio-trace-index\", "
              "\"fcio-tracemap\" or \"rawid\".\n",
              channelmap_fmt2str(format));
    return 0;
  }

  DSPChannelThreshold* ct_cfg = &processor->dsp_ct;

  ct_cfg->tracemap.format = format;

  if (pulser_channel >= 0 && pulser_level_adc > 0) {
    ct_cfg->tracemap.map[0] = pulser_channel;
    ct_cfg->thresholds[0] = pulser_level_adc;
    ct_cfg->label[0] = 'P';
    ct_cfg->tracemap.n_mapped++;
  }

  if (baseline_channel >= 0 && baseline_level_adc > 0) {
    ct_cfg->tracemap.map[1] = baseline_channel;
    ct_cfg->thresholds[1] = baseline_level_adc;
    ct_cfg->label[1] = 'B';
    ct_cfg->tracemap.n_mapped++;
  }

  if (muon_channel >= 0 && muon_level_adc > 0) {
    ct_cfg->tracemap.map[2] = muon_channel;
    ct_cfg->thresholds[2] = muon_level_adc;
    ct_cfg->label[2] = 'M';
    ct_cfg->tracemap.n_mapped++;
  }

  ct_cfg->enabled = ct_cfg->tracemap.n_mapped ? 1 : 0;

  if (processor->loglevel >= 4) {
    fprintf(stderr, "DEBUG FSP_L200_SetAuxParameters\n");
    for (int i = 0; i < ct_cfg->tracemap.n_mapped; i++) {
      if (ct_cfg->tracemap.format == FCIO_TRACE_MAP_FORMAT) {
        fprintf(stderr, "DEBUG channel   0x%x level_adc %d\n", ct_cfg->tracemap.map[i], ct_cfg->thresholds[i]);
      } else {
        fprintf(stderr, "DEBUG channel   %d level_adc %d\n", ct_cfg->tracemap.map[i], ct_cfg->thresholds[i]);
      }
    }
  }
  return 1;
}

int FSP_L200_SetGeParameters(StreamProcessor* processor, int nchannels, int* channelmap, FSPTraceFormat format,
                       int majority_threshold, int skip_full_counting, unsigned short* ge_prescale_threshold_adc,
                       int prescale_ratio) {

  DSPHardwareMajority* hwm = &processor->dsp_hwm;

  if (!is_known_channelmap_format(format)) {
    if (processor->loglevel)
      fprintf(stderr,
              "ERROR FSP_L200_SetGeParameters: channel map type %s is not supported. Valid inputs are \"fcio-trace-index\", "
              "\"fcio-tracemap\" or \"rawid\".\n",
              channelmap_fmt2str(format));
    return 0;
  }
  hwm->tracemap.format = format;
  hwm->tracemap.n_mapped = nchannels;

  for (int i = 0; i < nchannels && i < FCIOMaxChannels; i++) {
    hwm->tracemap.map[i] = channelmap[i];
    hwm->fpga_energy_threshold_adc[i] = ge_prescale_threshold_adc[i];
  }
  hwm->fast = skip_full_counting;
  if (majority_threshold >= 0)
    processor->triggerconfig.hwm_threshold = majority_threshold;
  else {
    fprintf(stderr, "CRITICAL majority_threshold needs to be >= 0 is %d\n", majority_threshold);
    return 0;
  }
  if (prescale_ratio >= 0)
    processor->triggerconfig.hwm_prescale_ratio = prescale_ratio;
  else {
    fprintf(stderr, "CRITICAL Ge prescale_ratio needs to be >= 0 is %d\n", prescale_ratio);
    return 0;
  }

  hwm->enabled = 1;

  if (processor->loglevel >= 4) {
    fprintf(stderr, "DEBUG FSP_L200_SetGeParameters\n");
    fprintf(stderr, "DEBUG majority_threshold %d\n", majority_threshold);
    fprintf(stderr, "DEBUG prescale_ratio     %d\n", prescale_ratio);
    fprintf(stderr, "DEBUG skip_full_counting %d\n", hwm->fast);
    fprintf(stderr, "DEBUG channelmap_format  %d : %s\n", hwm->tracemap.format, channelmap_fmt2str(format));
    for (int i = 0; i < hwm->tracemap.n_mapped; i++) {
      if (hwm->tracemap.format == FCIO_TRACE_MAP_FORMAT) {
        fprintf(stderr, "DEBUG channel 0x%x\n", hwm->tracemap.map[i]);
      } else {
        fprintf(stderr, "DEBUG channel %d\n", hwm->tracemap.map[i]);
      }
    }
  }
  return 1;
}

int FSP_L200_SetSiPMParameters(StreamProcessor* processor, int nchannels, int* channelmap, FSPTraceFormat format,
                         float* calibration_pe_adc, float* channel_thresholds_pe, int* shaping_width_samples,
                         float* lowpass_factors, int coincidence_pre_window_ns, int coincidence_post_window_ns,
                         int coincidence_window_samples, int sum_window_start_sample, int sum_window_stop_sample,
                         float sum_threshold_pe, float coincidence_wps_threshold, int prescale_ratio, int enable_muon_coincidence) {

  DSPWindowedPeakSum* wps = &processor->dsp_wps;

  if (!is_known_channelmap_format(format)) {
    if (processor->loglevel)
      fprintf(stderr,
              "CRITICAL FSP_L200_SetSiPMParameters: channel map type %s is not supported. Valid inputs are "
              "\"fcio-trace-index\", \"fcio-tracemap\" or \"rawid\".\n",
              channelmap_fmt2str(format));
    return 0;
  }
  wps->tracemap.format = format;

  if (coincidence_wps_threshold >= 0)
    processor->triggerconfig.relative_wps_threshold = coincidence_wps_threshold;
  else {
    fprintf(stderr, "CRICITAL coincidence_wps_threshold needs to be >= 0 is %f\n", coincidence_wps_threshold);
    return 0;
  }

  if (sum_threshold_pe >= 0)
    processor->triggerconfig.absolute_wps_threshold = sum_threshold_pe;
  else {
    fprintf(stderr, "CRICITAL sum_threshold_pe needs to be >= 0 is %f\n", sum_threshold_pe);
    return 0;
  }

  processor->triggerconfig.pre_trigger_window.seconds = coincidence_pre_window_ns / 1000000000L;
  processor->triggerconfig.pre_trigger_window.nanoseconds = coincidence_pre_window_ns % 1000000000L;
  processor->triggerconfig.post_trigger_window.seconds = coincidence_post_window_ns / 1000000000L;
  processor->triggerconfig.post_trigger_window.nanoseconds = coincidence_post_window_ns % 1000000000L;
  if (prescale_ratio >= 0)
    processor->triggerconfig.wps_prescale_ratio = prescale_ratio;
  else {
    fprintf(stderr, "CRITICAL SiPM prescale_ratio needs to be >= 0 is %d\n", prescale_ratio);
    return 0;
  }

  wps->coincidence_window = coincidence_window_samples;
  wps->sum_window_start_sample = sum_window_start_sample;
  wps->sum_window_stop_sample = sum_window_stop_sample;
  wps->coincidence_threshold = coincidence_wps_threshold;

  wps->apply_gain_scaling = 1;

  wps->tracemap.n_mapped = nchannels;

  wps->dsp_pre_max_samples = 0;
  wps->dsp_post_max_samples = 0;
  for (int i = 0; i < nchannels && i < FCIOMaxChannels; i++) {
    wps->tracemap.map[i] = channelmap[i];

    if (calibration_pe_adc[i] >= 0) {
      wps->gains[i] = calibration_pe_adc[i];
    } else {
      fprintf(stderr, "CRITICAL calibration_pe_adc for channel[%d] = %d needs to be >= 0 is %f\n", i, channelmap[i], calibration_pe_adc[i]);
      return 0;
    }

    if (channel_thresholds_pe[i] >= 0) {
      wps->thresholds[i] = channel_thresholds_pe[i];
    } else {
      fprintf(stderr, "CRITICAL channel_thresholds_pe for channel[%d] = %d needs to be >= 0 is %f\n", i, channelmap[i], channel_thresholds_pe[i]);
      return 0;
    }

    if (shaping_width_samples[i] >= 1) {
      wps->shaping_widths[i] = shaping_width_samples[i];
    } else {
      fprintf(stderr, "CRITICAL shaping_width_samples for channel[%d] = %d needs to be >= 1 is %d\n", i, channelmap[i], shaping_width_samples[i]);
      return 0;
    }

    if (lowpass_factors[i] >= 0) {
      wps->lowpass[i] = lowpass_factors[i];
    } else {
      fprintf(stderr, "CRITICAL lowpass_factors for channel[%d] = %d needs to be >= 0 is %f\n", i, channelmap[i], lowpass_factors[i]);
      return 0;
    }

    wps->dsp_pre_samples[i] = fsp_dsp_diff_and_smooth_pre_samples(shaping_width_samples[i], wps->lowpass[i]);
    if (wps->dsp_pre_samples[i] > wps->dsp_pre_max_samples) wps->dsp_pre_max_samples = wps->dsp_pre_samples[i];
    wps->dsp_post_samples[i] = fsp_dsp_diff_and_smooth_post_samples(shaping_width_samples[i], wps->lowpass[i]);
    if (wps->dsp_post_samples[i] > wps->dsp_post_max_samples) wps->dsp_post_max_samples = wps->dsp_post_samples[i];
  }

  wps->enabled = 1;

  if (enable_muon_coincidence) {
    int ct_map_indices[1];
    ct_map_indices[0] = 2; // see Set Aux Channels, map idx 2 (trace_list[2]) should be muon channel
    FSPSetWPSReferences(processor, (HWMFlags){.multiplicity_threshold = 1}, (CTFlags){0}, (WPSFlags){0}, ct_map_indices, 1);
  }

  if (processor->loglevel >= 4) {
    /* DEBUGGING enabled, print all inputs */
    fprintf(stderr, "DEBUG FSP_L200_SetSiPMParameters:\n");
    fprintf(stderr, "DEBUG channelmap_format %d : %s\n", wps->tracemap.format, channelmap_fmt2str(format));
    fprintf(stderr, "DEBUG prescale_ratio               %d\n", processor->triggerconfig.wps_prescale_ratio);
    fprintf(stderr, "DEBUG sum_window_start_sample      %d\n", wps->sum_window_start_sample);
    fprintf(stderr, "DEBUG sum_window_stop_sample       %d\n", wps->sum_window_stop_sample);
    fprintf(stderr, "DEBUG dsp_pre_max_samples          %d\n", wps->dsp_pre_max_samples);
    fprintf(stderr, "DEBUG dsp_post_max_samples         %d\n", wps->dsp_post_max_samples);
    fprintf(stderr, "DEBUG coincidence_pre_window_ns    %ld\n", processor->triggerconfig.pre_trigger_window.nanoseconds);
    fprintf(stderr, "DEBUG coincidence_post_window_ns   %ld\n", processor->triggerconfig.post_trigger_window.nanoseconds);
    fprintf(stderr, "DEBUG coincidence_window_samples   %d\n", wps->coincidence_window);
    fprintf(stderr, "DEBUG relative_wps_threshold       %f\n", processor->triggerconfig.relative_wps_threshold);
    fprintf(stderr, "DEBUG absolute_sum_threshold       %f\n", processor->triggerconfig.absolute_wps_threshold);
    fprintf(stderr, "DEBUG enable_muon_coincidence      %d\n", enable_muon_coincidence);

    for (int i = 0; i < wps->tracemap.n_mapped; i++) {
      if (wps->tracemap.format == 1) {
        fprintf(
            stderr,
            "DEBUG channel 0x%x gain %f threshold %f shaping %d lowpass %f dsp_pre_samples %d dsp_post_samples %d\n",
            wps->tracemap.map[i], wps->gains[i], wps->thresholds[i], wps->shaping_widths[i], wps->lowpass[i],
            wps->dsp_pre_samples[i], wps->dsp_post_samples[i]);
      } else {
        fprintf(stderr,
                "DEBUG channel %d gain %f threshold %f shaping %d lowpass %f dsp_pre_samples %d dsp_post_samples %d\n",
                wps->tracemap.map[i], wps->gains[i], wps->thresholds[i], wps->shaping_widths[i], wps->lowpass[i],
                wps->dsp_pre_samples[i], wps->dsp_post_samples[i]);
      }
    }
  }
  return 1;
}
