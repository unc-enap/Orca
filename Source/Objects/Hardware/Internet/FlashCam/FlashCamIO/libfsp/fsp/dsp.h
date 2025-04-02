#pragma once

#include <fcio.h>

#include "observables.h"
#include "tracemap.h"

typedef struct DSPWindowedPeakSum {
  FSPTraceMap tracemap;
  float gains[FCIOMaxChannels];
  float thresholds[FCIOMaxChannels];
  float lowpass[FCIOMaxChannels];
  int shaping_widths[FCIOMaxChannels];
  int dsp_margin_front[FCIOMaxChannels];
  int dsp_margin_back[FCIOMaxChannels];
  int dsp_start_sample[FCIOMaxChannels];
  int dsp_stop_sample[FCIOMaxChannels];
  int dsp_max_margin_front;
  int dsp_max_margin_back;

  int apply_gain_scaling;

  // unsigned int repetition;
  int sum_window_size;
  int sum_window_start_sample;
  int sum_window_stop_sample;
  float sub_event_sum_threshold;

  float peak_trace[FCIOMaxSamples];
  float diff_trace[FCIOMaxSamples];
  int diff_trace_i32[FCIOMaxSamples];
  int peak_trace_i32[FCIOMaxSamples];
  float work_trace[FCIOMaxSamples * 3];
  float work_trace2[FCIOMaxSamples * 3];
  int work_trace_i32[FCIOMaxSamples * 3];
  int work_trace2_i32[FCIOMaxSamples * 3];

  /* result fields */

  /* testing -> determine the above threshold snippets
      coincidence_window_trigger_list_threshold should be the same as the largest_sum_pe threshold in the calling
  */
  SubEventList* sub_event_list;

  float max_peak_sum_value;
  int max_peak_sum_offset;
  float max_peak_value;
  int max_peak_offset;
  int max_peak_sum_multiplicity;

  float *peak_times;
  float *peak_amplitudes;
  int *channel_pulses;
  int *total_pulses;

  int enabled;

} DSPWindowedPeakSum;

typedef struct DSPHardwareMultiplicity {
  FSPTraceMap tracemap;
  unsigned short fpga_energy_threshold_adc[FCIOMaxChannels];

  int fast;
  /* result fields */
  int multiplicity; // multiplicity of hardware energy values
  int n_below_minimum_multiplicity; // counts the number of channels below fpga_energy_threshold_adc but > 0
  unsigned short max_value; // the largest channel hw value
  unsigned short min_value; // the smallest channel hw value, but > 0

  int enabled;

} DSPHardwareMultiplicity;

typedef struct DSPChannelThreshold {
  FSPTraceMap tracemap;
  unsigned short thresholds[FCIOMaxChannels];
  /* result fields */
  unsigned short max_values[FCIOMaxChannels];
  int multiplicity;

  int enabled;

} DSPChannelThreshold;

/* Differentiates trace, searches for gain adjusted peaks above threshold. Peaks are stored in peak_trace.*/
float fsp_dsp_diff_and_find_peaks(float *input_trace, float *diff_trace, float *peak_trace, int start, int stop,
                                   int nsamples, float gain, float threshold);

void fsp_dsp_diff_and_smooth(int nsamples, int *start, int *stop, unsigned int shaping_width_samples,
                              unsigned short *input_trace, float *diff_trace, float *peak_trace, float *work_trace,
                              float *work_trace2, float gain, int apply_gain_scaling, float threshold, float lowpass,
                              float *peak_times, float *peak_amplitudes, int *npeaks, float *largest_peak, int* largest_peak_offset);
int fsp_dsp_diff_and_smooth_pre_samples(unsigned int shaping_width_samples, float lowpass);
int fsp_dsp_diff_and_smooth_post_samples(unsigned int shaping_width_samples, float lowpass);

unsigned short fsp_dsp_trace_larger_than(unsigned short *trace, int start, int stop, int nsamples, unsigned short threshold);

float fsp_dsp_local_peaks_f32(float *input_trace, float *peak_trace, int start, int stop, int nsamples,
                               const float gain_adc, const float threshold_pe, float *peak_times,
                               float *peak_amplitudes, int *npeaks, int* largest_peak_offset);

void fsp_dsp_windowed_peak_sum(DSPWindowedPeakSum *cfg, int nsamples, int num_traces, unsigned short* trace_list, unsigned short **traces);
void fsp_dsp_hardware_majority(DSPHardwareMultiplicity *cfg, int num_traces, unsigned short* trace_list, unsigned short **trace_headers);
void fsp_dsp_channel_threshold(DSPChannelThreshold* cfg, int nsamples, int num_traces, unsigned short* trace_list, unsigned short **traces, unsigned short **theaders);


void tracewindow(int n, float *trace, int ss, double gain, float *out);
