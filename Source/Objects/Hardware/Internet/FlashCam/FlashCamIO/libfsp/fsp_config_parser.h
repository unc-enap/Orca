#pragma once

#include <fsp.h>
#include <stdlib.h>
#include <yopt.h>

// static inline int parse_int_array(const char *par, int n, int *data) {
//   int i;
//   for (i = 0; i < n && par; i++) {
//     if (sscanf(par, "%d", &data[i]) != 1) break;
//     par = strstr(par, ",");
//     if (par) par++;
//     // fprintf(stderr,"getintarray: index %d value %x ... %s\n",i,data[i],(par)?par:"");
//   }
//   return i;
// }

// static inline int parse_number_array(const char *par, int n, int *data) {
//   int i;
//   for (i = 0; i < n && par; i++) {
//     const long num = strtol(par, NULL, 0);
//     data[i] = num;
//     par = strstr(par, ",");
//     if (par) par++;
//     // fprintf(stderr,"getintarray: index %d value %x ... %s\n",i,data[i],(par)?par:"");
//   }
//   return i;
// }

// static inline int parse_hex_array(const char *par, int n, int *data) {
//   int i;
//   for (i = 0; i < n && par; i++) {
//     if (sscanf(par, "%x", &data[i]) != 1) break;
//     par = strstr(par, ",");
//     if (par) par++;
//     // fprintf(stderr,"getintarray: index %d value %x ... %s\n",i,data[i],(par)?par:"");
//   }
//   return i;
// }

// static inline int parse_ushort_array(const char *par, int n, unsigned short *data) {
//   int i;
//   for (i = 0; i < n && par; i++) {
//     if (sscanf(par, "%hu", &data[i]) != 1) break;
//     par = strstr(par, ",");
//     if (par) par++;
//     // fprintf(stderr,"getintarray: index %d value %x ... %s\n",i,data[i],(par)?par:"");
//   }
//   return i;
// }

// static inline int parse_float_array(const char *par, int n, float *data) {
//   int i;
//   for (i = 0; i < n && par; i++) {
//     if (sscanf(par, "%f", &data[i]) != 1) break;
//     par = strstr(par, ",");
//     if (par) par++;
//     // fprintf(stderr,"getfloatarray: index %d value %x ... %s\n",i,data[i],(par)?par:"");
//   }
//   return i;
// }

#define MAXBUFLEN 4096
#define MAXARGS 128

int fsp_file_to_tokens(const char *setup_path, char **argv) {
  if (!argv) return 0;

  int argc = 0;

  FILE *fp = fopen(setup_path, "r");
  if (fp != NULL) {
    char linebuffer[MAXBUFLEN + 1] = {0};
    while (fgets(linebuffer, MAXBUFLEN, fp)) {
      if (ferror(fp) != 0) {
        fprintf(stderr, "ERROR FSPSetParamtersFromFile: could not read from file.\n");
        return 0;
      }

      char *token;
      const char *delimiters = " \t\n";
      token = strtok(linebuffer, delimiters);
      while (token != NULL && argc < MAXARGS) {
        if (token[0] == '#') break;

        size_t len = strlen(linebuffer);
        memcpy(argv[argc], token, len);
        argc++;

        token = strtok(NULL, delimiters);
      }
    }
    fclose(fp);
  }
  return argc + 1;  // +1 to be similar to argc, argv of the system.
}

int FSPSetParametersFromFile(StreamProcessor *processor, const char *setup_path) {
  char filebuffer[MAXARGS * (MAXBUFLEN + 1)];
  char *argv[MAXARGS];
  for (int i = 0; i < MAXARGS; i++) {
    argv[i] = &filebuffer[i * (MAXBUFLEN + 1)];
  }

  int argc = fsp_file_to_tokens(setup_path, argv);

  fprintf(stderr, "%d\n", argc);
  for (int i = 0; i < argc; i++) fprintf(stderr, "%s\n", argv[i]);

  const yopt_opt_t options[] = {
      // { .val = 1, .needarg = 0, .name = "-h,--help", .desc = "Print this help."},
      {.val = 2, .needarg = 1, .name = "--log-level", .desc = "<debuglevel:int> : Increase the debug level."},
      // { .val = 3, .needarg = 1, .name = "-i,--input", .desc = "<input:str> : Input file or socket." },
      // { .val = 4, .needarg = 1, .name = "-o,--output", .desc = "<output:str> : Output file or socket." },
      {.val = 5, .needarg = 1, .name = "--pre-ns", .desc = "<pre:int> : Size of pre-trigger window in nanoseconds."},
      {.val = 6, .needarg = 1, .name = "--post-ns", .desc = "<post:int> : Size of post-trigger window in nanoseconds."},
      // { .val = 7, .needarg = 1, .name = "--record_size", .desc = "<record_size:int> : Size of FCIO record buffer in
      // number of records." },
      // { .val = 8, .needarg = 1, .name = "--buffer_size", .desc = "<buffer_size:int> : Size of FCIO internal buffer in
      // bytes." },
      // { .val = 9, .needarg = 1, .name = "--connection_timeout", .desc = "<connection_timeout:int> : FCIO internal
      // timeout to establish the initial connection and wait for records in microseconds. -1 == no timeout" },
      {.val = 10,
       .needarg = 1,
       .name = "--log-time",
       .desc = "<log-time:double> : Timedelta between logging data output."},
      {.val = 11,
       .needarg = 1,
       .name = "--sum-channel-gains-adc",
       .desc = "<log-time:double> : Timedelta between logging data output."},
      {.val = 12,
       .needarg = 1,
       .name = "--sum-channel-thresholds-pe",
       .desc = "<log-time:double> : Timedelta between logging data output."},
      {.val = 13,
       .needarg = 1,
       .name = "--sum-channel-shapings-samples",
       .desc = "<log-time:double> : Timedelta between logging data output."},
      // { .val = 14, .needarg = 1, .name = "--event-moving-average-repetitions", .desc = "<log-time:double> : Timedelta
      // between logging data output." },
      {.val = 15,
       .needarg = 1,
       .name = "--event-coincidence-window-samples",
       .desc = "<log-time:double> : Timedelta between logging data output."},
      {.val = 16,
       .needarg = 1,
       .name = "--event-sum-threshold-pe",
       .desc = "<log-time:double> : Timedelta between logging data output."},
      {.val = 17,
       .needarg = 1,
       .name = "--sum-channel-fcio-id",
       .desc = "<log-time:double> : Timedelta between logging data output."},
      {.val = 18,
       .needarg = 1,
       .name = "--fpga-majority-channel-fcio-id",
       .desc = "<log-time:double> : Timedelta between logging data output."},
      {.val = 19,
       .needarg = 1,
       .name = "--fpga-majority-threshold",
       .desc = "<log-time:double> : Timedelta between logging data output."},
      // {.val = 20,
      //  .needarg = 1,
      //  .name = "--observables",
      //  .desc = "<path-to-file:string> : File to write event-by-event observables to."},
      {.val = 21,
       .needarg = 0,
       .name = "--skip-full-counting",
       .desc = "skip calculation of trace pe sum if fpga majority is fulfilled. "},
      {.val = 22,
       .needarg = 1,
       .name = "--sum-channel-lowpass-ratio",
       .desc = "<lowpass-decay:double> : a1 = 1 - lowpass-decay, b0 = lowpass-decay; between 0 and 1, -1 disables."},
      {.val = 23,
       .needarg = 1,
       .name = "--event-windowed-sum-threshold-pe",
       .desc = "<log-time:double> : Timedelta between logging data output."},
      {.val = 24,
       .needarg = 1,
       .name = "--event-windowed-sum-start-sample",
       .desc = "<sample:int> : Set window within which the analog sum should be calculated. Start is the first sample "
               "taken into account, default 0."},
      {.val = 25,
       .needarg = 1,
       .name = "--event-windowed-sum-stop-sample",
       .desc = "<sample:int> : Set window within which the analog sum should be calculated. Stop is the last sample "
               "taken into account, default -1 == last sample."},
      {.val = 26,
       .needarg = 1,
       .name = "--pulser-flag-fcio-idx",
       .desc = "FCIO index where the pulser digital flag is connected."},
      {.val = 27,
       .needarg = 1,
       .name = "--baseline-flag-fcio-idx",
       .desc = "FCIO index where the baseline digital flag is connected."},
      {.val = 28,
       .needarg = 1,
       .name = "--muon-flag-fcio-idx",
       .desc = "FCIO index where the muon digital flag is connected."},
      {.val = 29,
       .needarg = 1,
       .name = "--channel-format",
       .desc = "Number of skipped non_ge_majority/non_aux events between prescaled write-out. e.g. use 999 for every "
               "1000th event. Default is -1 aka no prescaling."},
      {.val = 30,
       .needarg = 1,
       .name = "--sipm-prescaling-rate",
       .desc = "Minimum average rate of randomly kept events of non_ge_majority/non_aux events. Input is double in Hz. "
               "Default is 0. If set, overwrites -offset parameter."},
      {.val = 31,
       .needarg = 0,
       .name = "--muon-coincidence",
       .desc = "Treats present of a muon flag as force trigger and triggers on coincident argon events."},
      {.val = 32,
       .needarg = 1,
       .name = "--ge_prescaling_threshold_adc",
       .desc = "<threshold:unsigned short> the list of ge fpga energy thresholds below which prescaling sets in."},
      {.val = 33,
       .needarg = 1,
       .name = "--ge_prescaling_average_rate",
       .desc = "<rate:float> the average expected rate of prescaling germanium events.."},
      {0, 0, 0, 0}};

  double log_time = 1.0;
  const char *channelmap_format = NULL;
  // AUX
  int digital_pulser_channel = -1;
  int pulser_level_adc = 100;
  int digital_baseline_channel = -1;
  int baseline_level_adc = 100;
  int digital_muon_channel = -1;
  int muon_level_adc = 100;
  int enable_muon_coincidence = 0;
  // GE
  int ge_nchannels = 0;
  int ge_channelmap[FCIOMaxChannels] = {0};
  int majority_threshold = 1;
  int skip_full_counting = 0;

  // SIPM
  int sipm_nchannels = 0;
  int sipm_channelmap[FCIOMaxChannels] = {0};
  float calibration_pe_adc[FCIOMaxChannels] = {0};
  float channel_thresholds_pe[FCIOMaxChannels] = {0};
  int shaping_width_samples[FCIOMaxChannels] = {0};
  float lowpass_factors[FCIOMaxChannels] = {0};
  int coincidence_pre_window_ns = 0;
  int coincidence_post_window_ns = 0;
  int coincidence_window_samples = 0;
  int sum_window_start_sample = 0;
  int sum_window_stop_sample = -1;
  float sum_threshold_pe = 0.0;
  float coincidence_sum_threshold_pe = 0.0;
  float sipm_average_prescaling_rate_hz = 0.0;
  float ge_average_prescaling_rate_hz = 10;
  unsigned short ge_prescaling_threshold_adc[FCIOMaxChannels] = {0};
  // const char *observables_file_path = NULL;
  int loglevel = 1;

  yopt_t opt_state;
  yopt_init(&opt_state, argc, argv, options);
  char *value;
  int opt_ret;
  while ((opt_ret = yopt_next(&opt_state, &value)) >= 0) {
    int local_sipm_nchannels = 0;
    int local_ge_nchannels = 0;
    switch (opt_ret) {
      case 3:
      case 2: {
        loglevel = atoi(value) >= 0 ? atoi(value) : 0;
        break;
      }
      // case 4: { config->output_path = value; break; }
      case 5: {
        coincidence_pre_window_ns = atoi(value) >= 0 ? atoi(value) : 0;
        break;
      }
      case 6: {
        coincidence_post_window_ns = atoi(value) >= 0 ? atoi(value) : 0;
        break;
      }
      // case 7: { config->fcio_buffer_depth = atoi(value)>=0?atoi(value):0; break; }
      // case 8: { config->fcio_bufsize = atoi(value)>=0?atoi(value):0; break; }
      // case 9: { config->fcio_timeout = atoi(value)>=-1?atoi(value):0; break; }
      case 10: {
        log_time = atof(value) >= 0.0 ? atof(value) : 0;
        break;
      }
      case 11: {
        local_sipm_nchannels = parse_float_array(value, FCIOMaxChannels, calibration_pe_adc);
        break;
      }
      case 12: {
        local_sipm_nchannels = parse_float_array(value, FCIOMaxChannels, channel_thresholds_pe);
        break;
      }
      case 13: {
        local_sipm_nchannels = parse_int_array(value, FCIOMaxChannels, shaping_width_samples);
        break;
      }
      case 15: {
        coincidence_window_samples = atoi(value) >= 0 ? atoi(value) : 0;
        break;
      }
      case 16: {
        sum_threshold_pe = atof(value) >= 0 ? atof(value) : 0;
        break;
      }
      case 17: {
        local_sipm_nchannels = parse_int_array(value, FCIOMaxChannels, sipm_channelmap);
        break;
      }
      case 18: {
        local_ge_nchannels = parse_int_array(value, FCIOMaxChannels, ge_channelmap);
        break;
      }
      case 19: {
        majority_threshold = atoi(value) >= 1 ? atoi(value) : 1;
        break;
      }
      // case 20: {
      //   observables_file_path = value;
      //   break;
      // }
      case 21: {
        skip_full_counting = 1;
        break;
      }
      case 22: {
        local_sipm_nchannels = parse_float_array(value, FCIOMaxChannels, lowpass_factors);
        break;
      }
      case 23: {
        coincidence_sum_threshold_pe = atof(value) >= 0 ? atof(value) : 0;
        break;
      }
      case 24: {
        sum_window_start_sample = atoi(value) >= 0 ? atoi(value) : 0;
        break;
      }
      case 25: {
        sum_window_stop_sample = atoi(value) >= 0 ? atoi(value) : -1;
        break;
      }
      case 26: {
        digital_pulser_channel = atoi(value) >= 0 ? atoi(value) : -1;
        break;
      }
      case 27: {
        digital_baseline_channel = atoi(value) >= 0 ? atoi(value) : -1;
        break;
      }
      case 28: {
        digital_muon_channel = atoi(value) >= 0 ? atoi(value) : -1;
        break;
      }
      case 29: {
        channelmap_format = value;
        break;
      }
      case 30: {
        sipm_average_prescaling_rate_hz = atof(value) >= 0 ? atof(value) : 0.0;
        break;
      }
      case 31: {
        enable_muon_coincidence = 1;
        break;
      }
      case 32: {
        local_ge_nchannels = parse_ushort_array(value, FCIOMaxChannels, ge_prescaling_threshold_adc);
        break;
      }
      case 33: {
        ge_average_prescaling_rate_hz = atof(value) >= 0 ? atof(value) : 0;
        break;
      }
    }
    if (local_sipm_nchannels && sipm_nchannels == 0)
      sipm_nchannels = local_sipm_nchannels;
    else if (local_sipm_nchannels && sipm_nchannels && sipm_nchannels != local_sipm_nchannels) {
      fprintf(stderr,
              "SiPM input parameter error: number of channels (%d) given doesn't match number of channels (%d) given "
              "previously.\nError detector here:\n%s",
              local_sipm_nchannels, sipm_nchannels, value);
      return 0;
    }
    if (local_ge_nchannels && ge_nchannels == 0)
      ge_nchannels = local_ge_nchannels;
    else if (local_ge_nchannels && ge_nchannels && ge_nchannels != local_ge_nchannels) {
      fprintf(stderr,
              "GE input parameter error: number of channels (%d) given doesn't match number of channels (%d) given "
              "previously.\nError detector here:\n%s",
              local_ge_nchannels, ge_nchannels, value);
      return 0;
    }
  }
  if (opt_ret == -2) {
    fprintf(stderr, "Error parsing option:\n%s\n", value);
  }

  FSPSetLogLevel(processor, loglevel);
  FSPSetLogTime(processor, log_time);

  if (!FSP_L200_SetAuxParameters(processor, channelmap_format, digital_pulser_channel, pulser_level_adc,
                           digital_baseline_channel, baseline_level_adc, digital_muon_channel, muon_level_adc)) {
    fprintf(stderr, "FSP_L200_SetAuxParameters failed.");
    return 0;
  }

  if (!FSP_L200_SetGeParameters(processor, ge_nchannels, ge_channelmap, channelmap_format, majority_threshold,
                          skip_full_counting, ge_prescaling_threshold_adc, ge_average_prescaling_rate_hz)) {
    fprintf(stderr, "FSP_L200_SetGeParameters failed.");
    return 0;
  }

  if (!FSP_L200_SetSiPMParameters(processor, sipm_nchannels, sipm_channelmap, channelmap_format, calibration_pe_adc,
                            channel_thresholds_pe, shaping_width_samples, lowpass_factors, coincidence_pre_window_ns,
                            coincidence_post_window_ns, coincidence_window_samples, sum_window_start_sample,
                            sum_window_stop_sample, sum_threshold_pe, coincidence_sum_threshold_pe,
                            sipm_average_prescaling_rate_hz, enable_muon_coincidence)) {
    fprintf(stderr, "FSP_L200_SetSiPMParameters");
    return 0;
  }

  return 1;
}
