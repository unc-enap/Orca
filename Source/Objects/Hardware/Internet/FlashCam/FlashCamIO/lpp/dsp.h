#pragma once

#include <fcio.h>

typedef struct TriggerList
{
  float threshold;
  int start[FCIOMaxSamples];
  int stop[FCIOMaxSamples]; // first sample after trigger up is gone
  float max_sum_pe[FCIOMaxSamples];
  int size;
} TriggerList;

typedef struct AnalogueSumCfg {
  int tracemap_format;
  int tracemap[FCIOMaxChannels];
  float gains[FCIOMaxChannels];
  float thresholds[FCIOMaxChannels];
  float lowpass[FCIOMaxChannels];
  int shaping_widths[FCIOMaxChannels];
  int dsp_pre_samples[FCIOMaxChannels];
  int dsp_post_samples[FCIOMaxChannels];
  int dsp_start_sample[FCIOMaxChannels];
  int dsp_stop_sample[FCIOMaxChannels];
  int dsp_pre_max_samples;
  int dsp_post_max_samples;
  int ntraces;

  int apply_gain_scaling;

  // unsigned int repetition;
  int coincidence_window;
  int sum_window_start_sample;
  int sum_window_stop_sample;

  /* testing -> determine the above threshold snippets
      coincidence_window_trigger_list_threshold should be the same as the largest_sum_pe threshold in the calling
  */
  TriggerList trigger_list;

  float peak_trace[FCIOMaxSamples];
  float diff_trace[FCIOMaxSamples];
  int diff_trace_i32[FCIOMaxSamples];
  int peak_trace_i32[FCIOMaxSamples];
  float work_trace[FCIOMaxSamples * 3];
  float work_trace2[FCIOMaxSamples * 3];
  int work_trace_i32[FCIOMaxSamples * 3];
  int work_trace2_i32[FCIOMaxSamples * 3];

  float largest_sum_pe;
  int largest_sum_offset;
  float largest_pe;
  int multiplicity;


  float *pulse_times;
  float *pulse_amplitudes;
  int *channel_pulses;
  int *total_pulses;

} AnalogueSumCfg;

typedef struct FPGAMajorityCfg {
  int tracemap_format;
  int ntraces;
  int tracemap[FCIOMaxChannels];
  unsigned short fpga_energy_threshold_adc[FCIOMaxChannels];

  int fast;
  /* result fields */
  int multiplicity;
  int n_fpga_energy_below;
  unsigned short max_fpga_energy;
  unsigned short min_fpga_energy;

} FPGAMajorityCfg;

/* Differentiates trace, searches for gain adjusted peaks above threshold. Peaks are stored in peak_trace.*/
float tale_dsp_diff_and_find_peaks(float *input_trace, float *diff_trace, float *peak_trace, int start, int stop,
                                   int nsamples, float gain, float threshold);

/* applies <repetition> times centered moving averages with shaping_width_samples to trace, and applies
  diff_and_find_peaks. Needs work_trace for moving averages.
*/
// unsigned int tale_dsp_diff_and_smooth(int nsamples, unsigned int shaping_width_samples, unsigned int repetition,
//     unsigned short* input_trace, float* diff_trace, float* peak_trace, float* work_trace, float* work_trace2, float
//     gain, float threshold);
void tale_dsp_diff_and_smooth(int nsamples, int *start, int *stop, unsigned int shaping_width_samples,
                              unsigned short *input_trace, float *diff_trace, float *peak_trace, float *work_trace,
                              float *work_trace2, float gain, int apply_gain_scaling, float threshold, float lowpass,
                              float *peak_times, float *peak_amplitudes, int *npeaks, float *largest_peak);
int tale_dsp_diff_and_smooth_pre_samples(unsigned int shaping_width_samples, float lowpass);
int tale_dsp_diff_and_smooth_post_samples(unsigned int shaping_width_samples, float lowpass);

void tale_dsp_windowed_analogue_sum(AnalogueSumCfg *proc, int nsamples, int ntraces, unsigned short **traces);
void tale_dsp_fpga_energy_majority(FPGAMajorityCfg *fpga_majority_cfg, int ntraces, unsigned short **trace_headers);

unsigned short trace_larger_than(unsigned short *trace, int start, int stop, int nsamples, unsigned short threshold);

void tracewindow(int n, float *trace, int ss, double gain, float *out);
