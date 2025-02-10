#include "dsp.h"

#include <assert.h>
#include <limits.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>

void tracewindow(int n, float *trace, int ss, double gain, float *out) {
  int i;
  if (ss > n / 2) ss = n / 2;
  for (i = 0; i < ss; i++) out[i] = trace[i] * gain * i * i / ss / ss;
  for (i = ss; i < n - ss; i++) out[i] = trace[i] * gain;
  for (i = n - ss; i < n; i++) out[i] = trace[i] * gain * (n - i - 1) * (n - i - 1) / ss / ss;
}

void tracewindow_int(int n, int *trace, int ss, double gain, float *out) {
  int i;
  if (ss > n / 2) ss = n / 2;
  for (i = 0; i < ss; i++) out[i] = trace[i] * gain * i * i / ss / ss;
  for (i = ss; i < n - ss; i++) out[i] = trace[i] * gain;
  for (i = n - ss; i < n; i++) out[i] = trace[i] * gain * (n - i - 1) * (n - i - 1) / ss / ss;
}

int sma_4(float *in, float *out, float *tmp, int start, int stop, int nsamples, int shaping_width,
          float scale_parameter) {
  const int dev_debug = 0;

  const int n = shaping_width;
  const int presum_length = 4 * n - 4;
  const int offset = presum_length / 2;

  const float divisor = shaping_width * shaping_width * shaping_width * shaping_width / scale_parameter;

  if (dev_debug)
    fprintf(stderr, "n=%d offset=%d presum_length=%d divisor=%f nsamples=%d\n", n, offset, presum_length, divisor,
            nsamples);

  double acc[5] = {0};

  float *t0a = &tmp[4 * n + 3];
  float *t0b = t0a - n;
  float *t1a = &tmp[3 * n + 2];
  float *t1b = t1a - n;
  float *t2a = &tmp[2 * n + 1];
  float *t2b = t2a - n;
  float *t3a = &tmp[1 * n + 0];
  float *t3b = t3a - n;

  if (dev_debug) fprintf(stderr, "pointer offsets tmp from tmp start:\n");
  if (dev_debug)
    fprintf(stderr, "t0a=%ld t0b=%ld t1a=%ld t1b=%ld t2a=%ld t2b=%ld t3a=%ld t3b=%ld\n", t0a - tmp, t0b - tmp,
            t1a - tmp, t1b - tmp, t2a - tmp, t2b - tmp, t3a - tmp, t3b - tmp);

  float *pin = in + start;
  float *pout = out + start + offset;

  if (dev_debug) fprintf(stderr, "pin=%ld pout=%ld\n", pin - in, pout - out);

  /* pre-sum */

  int i = 0;
  for (i = start; i < start + presum_length && i < stop; i++) {
    acc[0] += *pin++;
    *t0a = acc[0];
    *t1a = (acc[1] += *t0a++ - *t0b++);
    *t2a = (acc[2] += *t1a++ - *t1b++);
    *t3a = (acc[3] += *t2a++ - *t2b++);
    acc[4] = *t3a++ - *t3b++;

    if (dev_debug)
      fprintf(stderr,
              "presum   pin=%2ld pout=%2ld t0a=%2ld t0b=%2ld t1a=%2ld t1b=%2ld t2a=%2ld t2b=%2ld t3a=%2ld t3b=%2ld ",
              pin - in - 1, pout - out, t0a - tmp - 1, t0b - tmp - 1, t1a - tmp - 1, t1b - tmp - 1, t2a - tmp - 1,
              t2b - tmp - 1, t3a - tmp - 1, t3b - tmp - 1);
    if (dev_debug)
      fprintf(stderr, "i=%2d acc %3.6f %3.6f %3.6f %3.6f %3.6f out=%e\n", i, acc[0], acc[1], acc[2], acc[3], acc[4],
              acc[4] / divisor);
  }
  /* write-out */

  for (i = start + presum_length; i < nsamples && i < stop; i++) {
    acc[0] += *pin++;
    *t0a = acc[0];
    *t1a = (acc[1] += *t0a++ - *t0b++);
    *t2a = (acc[2] += *t1a++ - *t1b++);
    *t3a = (acc[3] += *t2a++ - *t2b++);
    acc[4] = *t3a++ - *t3b++;
    *pout++ = (acc[4]) / divisor;

    if (dev_debug)
      fprintf(stderr,
              "writeout pin=%2ld pout=%2ld t0a=%2ld t0b=%2ld t1a=%2ld t1b=%2ld t2a=%2ld t2b=%2ld t3a=%2ld t3b=%2ld ",
              pin - in - 1, pout - out - 1, t0a - tmp - 1, t0b - tmp - 1, t1a - tmp - 1, t1b - tmp - 1, t2a - tmp - 1,
              t2b - tmp - 1, t3a - tmp - 1, t3b - tmp - 1);
    if (dev_debug)
      fprintf(stderr, "i=%2d acc %3.6f %3.6f %3.6f %3.6f %3.6f out=%e\n", i, acc[0], acc[1], acc[2], acc[3], acc[4],
              *(pout - 1));
  }

  if (dev_debug) fprintf(stderr, "distances %d %d %ld\n", offset, presum_length, (out + nsamples) - pout);

  /* offset is centered in the middle of the presum-length, equal to the total width needed for all averaging */
  return offset;
}

int centered_moving_average_f32(float *x, float *y, int start, int stop, int nsamples, int shaping_width) {
  assert(start >= 0);
  assert(stop <= nsamples);
  assert(shaping_width < (stop - start));

  int p = (shaping_width - 1) / 2;
  int q = p + 1;
  double acc = 0;

  for (int i = start; i < start + shaping_width; i++) acc += x[i];

  y[p] = acc / shaping_width;

  for (int i = start + p + 1; i < stop - p; i++) {
    acc = acc + x[i + p] - x[i - q];
    y[i] = (acc) / shaping_width;  // shift when casting back to integers.
  }
  // returns the offset which is lost between input and output because of the filter
  return p;
}

int centered_moving_sum_f32(float *x, float *y, int start, int stop, int nsamples, int shaping_width) {
  assert(start >= 0);
  assert(stop <= nsamples);
  assert(shaping_width < (stop - start));

  int p = (shaping_width - 1) / 2;
  int q = p + 1;
  float acc = 0;

  for (int i = start; i < start + shaping_width; i++) acc += x[i];

  y[p] = acc;  // /shaping_width;

  for (int i = start + p + 1; i < stop - p; i++) {
    acc = acc + x[i + p] - x[i - q];
    y[i] = (acc);  // /shaping_width; // shift when casting back to integers.
  }
  // returns the offset which is lost between input and output because of the filter
  return p;
}

int centered_moving_average_u16(unsigned short *x, float *y, int start, int stop, int nsamples, int shaping_width) {
  assert(start >= 0);
  assert(stop <= nsamples);
  assert(shaping_width < (stop - start));

  int p = (shaping_width - 1) / 2;
  int q = p + 1;
  double acc = 0;

  for (int i = start; i < start + shaping_width; i++) acc += x[i];

  y[p] = acc / shaping_width;

  for (int i = start + p + 1; i < stop - p; i++) {
    acc = acc + x[i + p] - x[i - q];
    y[i] = (acc) / shaping_width;  // shift when casting back to integers.
  }
  // returns the offset from which valid samples can be accessed
  return q;
}

float max_windowed_sum(float *x, int start, int stop, int nsamples, int coincidence_window, float coincidence_threshold, int *largest_sum_offset, SubEventList* sub_event_list) {
  assert(start >= 0);
  assert(stop <= nsamples);
  assert(coincidence_window > 0);
  assert(sub_event_list);

  int up = 0;
  sub_event_list->size = 0; // reset the trigger list
  sub_event_list->wps_max[0] = 0.0;
  float acc = 0;
  float largest_acc = 0;

  for (int i = start; i < start + coincidence_window && i < stop; i++)
    acc += x[i];

  largest_acc = acc;
  int offset = start;
  if (acc >= coincidence_threshold) {
    sub_event_list->start[sub_event_list->size] = start;
    sub_event_list->wps_max[sub_event_list->size] = acc;
    up = 1;
  }

  for (int i = start; i < (stop-coincidence_window); i++) {
    acc += x[i + coincidence_window] - x[i];
    if (acc > largest_acc) {
      largest_acc = acc;
      offset = i;
    }

    // if (up && acc >= coincidence_threshold)
    //   // do nothing
    if (up && acc < coincidence_threshold) {
      // came down, end current trigger entry
      sub_event_list->stop[sub_event_list->size] = i + 1 + coincidence_window;
      sub_event_list->size++;
      sub_event_list->wps_max[sub_event_list->size] = 0.0; // reset the values when we use a new one
      up = 0;
    } else if (!up && acc >= coincidence_threshold) {
      // start new entry

      // only if it's not the first one do we check if they are overlapping within the coincidence window
      if (sub_event_list->size && (i+1 < sub_event_list->stop[sub_event_list->size-1])) {// check if new start is within stop of old window
        // it's inside, so we forget the previous stop and wait for the next one
        sub_event_list->size--;
      } else {
        // either it's the first one, or it's outside, so we start a new region
        sub_event_list->start[sub_event_list->size] = i + 1; // first sample of the new sum
      }
      up = 1;

    }
    if (acc > sub_event_list->wps_max[sub_event_list->size]) {
      sub_event_list->wps_max[sub_event_list->size] = acc;
    }
  }

  if (up) {
    // end the triggerlist if it's still up. last possible stop sample is `stop-coincidence_window`
    // sub_event_list->stop[sub_event_list->size] = stop-coincidence_window;
    sub_event_list->stop[sub_event_list->size] = stop;
    sub_event_list->size++;
  }

  if (largest_sum_offset)
    *largest_sum_offset = offset;  // round down if uneven window, close enough.

  return largest_acc;
}

float fsp_dsp_local_peaks_f32(float *input_trace, float *peak_trace, int start, int stop, int nsamples,
                               const float gain_adc, const float threshold_pe, float *peak_times,
                               float *peak_amplitudes, int *npeaks, int* largest_peak_offset) {
  assert(start >= 0);
  assert(stop <= nsamples);
  if (!peak_times || !peak_amplitudes | !npeaks) {
    npeaks = NULL;
    /* use the local copy of the pointer to flag writeout of peaks */
  } else {
    /* make sure npeaks is zero */
    *npeaks = 0;
  }

  int find_max = 1;

  float last_max = 0;
  float last_min = 0;
  float current_sample = 0;
  float largest_peak = 0.0;
  int largest_peak_sample = -1;
  int last_max_index = 0;
  for (int i = start + 1; i < stop; i++) {
    current_sample = input_trace[i];

    if (current_sample > last_max) {
      last_max = current_sample;
      last_max_index = i;  // imprecise, if there is a long flat top, the start will be used as timestamp
    } else if (current_sample < last_min)
      last_min = current_sample;
    if (find_max) {
      if (current_sample < last_max) {
        if (last_max > threshold_pe * gain_adc) {
          float last_max_pe = last_max / gain_adc;
          peak_trace[i] += last_max_pe;
          if (last_max_pe > largest_peak) {
            largest_peak = last_max_pe;
            largest_peak_sample = last_max_index;
          }
          if (npeaks) {
            peak_times[*npeaks] = last_max_index;
            peak_amplitudes[*npeaks] = last_max / gain_adc;
            (*npeaks)++;
          }
        }
        last_min = current_sample;
        find_max = 0;
      }
    } else {
      if (current_sample > last_min) {
        last_max = current_sample;
        find_max = 1;
      }
    }
  }

  if (largest_peak_offset)
    *largest_peak_offset = largest_peak_sample;

  return largest_peak;
}

unsigned int fsp_dsp_diff_u16(unsigned short *input_trace, float *diff_trace, int start, int stop, int nsamples) {
  assert(start >= 0);
  // diff_trace[start-1] = 0;
  start++;
  diff_trace[start - 1] = 0;
  for (int i = start; i < stop && i < nsamples; i++) {
    diff_trace[i] = input_trace[i] - input_trace[i - 1];
  }
  return start;
}

unsigned int fsp_dsp_lowpass_f16(float *input_trace, float *out_trace, int start, int stop, int nsamples, float decay,
                                  float offset, float gain) {
  assert(start >= 0);
  assert(stop <= nsamples);

  float a0 = 1 - decay;
  float b1 = decay;
  float last = offset;
  for (int i = start; i < stop; i++) last = out_trace[i] = gain * (a0 * input_trace[i] + b1 * last);

  return start;
}

unsigned int fsp_dsp_diff_i32(unsigned short *input_trace, int *diff_trace, int start, int stop, int nsamples) {
  assert(start >= 0);
  start++;
  diff_trace[start - 1] = 0;
  for (int i = start; i < stop && i < nsamples; i++) {
    diff_trace[i] = input_trace[i] - input_trace[i - 1];
  }
  return start;
}

unsigned int fsp_dsp_diff_f32(float *input_trace, float *diff_trace, int start, int stop, int nsamples) {
  assert(start >= 0);
  start++;
  diff_trace[start - 1] = 0;
  for (int i = start; i < stop && i < nsamples; i++) {
    diff_trace[i] = input_trace[i] - input_trace[i - 1];
  }
  return start;
}

int fsp_dsp_diff_and_smooth_pre_samples(unsigned int shaping_width_samples, float lowpass) {
  int offset = 1;                                 // diff requires one input sample
  if (lowpass > 0.0) offset += 1;                 // lowpass requires one input sample
  offset += (4 * shaping_width_samples - 4) / 2;  // sma_4 requires variable samples;
  return offset;
}
int fsp_dsp_diff_and_smooth_post_samples(unsigned int shaping_width_samples, float lowpass __attribute__((unused))) {
  int offset = (4 * shaping_width_samples - 4) / 2;  // sma_4 requires variable samples;
  return offset;
}

void fsp_dsp_diff_and_smooth(int nsamples, int *start, int *stop, unsigned int shaping_width_samples,
                              unsigned short *input_trace, float *diff_trace, float *peak_trace, float *work_trace,
                              float *work_trace2, float gain_adc, int apply_gain_scaling, float threshold_pe,
                              float lowpass, float *peak_times, float *peak_amplitudes, int *npeaks,
                              float *largest_peak, int* largest_peak_offset) {
  assert(start);
  assert(stop);
  assert(gain_adc > 0.0);
  assert(*start >= 0);
  assert(*stop <= nsamples);

  float gain_scaling = 1.0;

  // (*start)++;
  *start = fsp_dsp_diff_u16(input_trace, diff_trace, *start, *stop, nsamples);

  if (lowpass > 0) {
    float lpoffset = diff_trace[*start];
    start++;

    gain_scaling = 1 / sqrt((1 - lowpass * lowpass));
    *start = fsp_dsp_lowpass_f16(diff_trace, diff_trace, *start, *stop, nsamples, lowpass, lpoffset,
                                  (apply_gain_scaling) ? gain_scaling : 1.0);
  }

  gain_scaling = shaping_width_samples * 1.5;
  int offset = sma_4(diff_trace, work_trace, work_trace2, *start, *stop, nsamples, shaping_width_samples,
                     (apply_gain_scaling) ? gain_scaling : 1.0);
  *start += offset;
  *stop -= offset;

  int _largest_peak_offset = -1;
  float _largest_peak = fsp_dsp_local_peaks_f32(work_trace, peak_trace, *start, *stop, nsamples, gain_adc,
                                                 threshold_pe, peak_times, peak_amplitudes, npeaks, &_largest_peak_offset);

  if (largest_peak) {
    *largest_peak = _largest_peak;
  }
  if (largest_peak_offset) {
    *largest_peak_offset = _largest_peak_offset;
  }
}

void fsp_dsp_windowed_peak_sum(DSPWindowedPeakSum *cfg, int nsamples, int num_traces, unsigned short* trace_list, unsigned short **traces) {

  int *npulses = NULL;
  float *pulse_times = NULL;
  float *pulse_amplitudes = NULL;

  if (cfg->channel_pulses && cfg->peak_times && cfg->peak_amplitudes && cfg->total_pulses) {
    /* use npulses as a proxy for existance of all pointers in the if down below. */
    /* need to reset ourselves, aka make sure we use the previously written values.*/
    *(cfg->total_pulses) = 0;
  }

  for (int j = 0; j < nsamples; j++) cfg->peak_trace[j] = 0;

  int multiplicity = 0;
  float total_largest_peak = 0;
  int total_largest_peak_offset = -1;
  for (int i = 0; i < num_traces; i++) {
    int trace_idx = trace_list[i];
    if (cfg->tracemap.enabled[trace_idx] < 0)
      continue;
    int map_idx = cfg->tracemap.enabled[trace_idx];
    assert(trace_idx == cfg->tracemap.map[map_idx]);

    unsigned short *trace = traces[trace_idx];
    assert(nsamples + (4 * (cfg->shaping_widths[map_idx] + 1) <= 3 * FCIOMaxSamples));

    float gain = cfg->gains[map_idx];
    float threshold = cfg->thresholds[map_idx];
    float lowpass = cfg->lowpass[map_idx];
    int shaping_width_samples = cfg->shaping_widths[map_idx];

    for (int j = 0; j < 4 * (shaping_width_samples + 1); j++) {
      cfg->work_trace[j] = 0;
      cfg->work_trace2[j] = 0;
    }

    if (cfg->total_pulses) {
      npulses = &cfg->channel_pulses[trace_idx];
      *npulses = 0;
      pulse_times = &cfg->peak_times[*(cfg->total_pulses)];
      pulse_amplitudes = &cfg->peak_amplitudes[*(cfg->total_pulses)];
    }
    float largest_peak = 0.0;
    int largest_peak_offset = -1;
    /* TODO pre-calculate from sum cfg */
    int start = cfg->dsp_start_sample[map_idx];
    int stop = cfg->dsp_stop_sample[map_idx];

    fsp_dsp_diff_and_smooth(nsamples, &start, &stop, shaping_width_samples, trace, cfg->diff_trace, cfg->peak_trace,
                             cfg->work_trace, cfg->work_trace2, gain, cfg->apply_gain_scaling, threshold, lowpass,
                             pulse_times, pulse_amplitudes, npulses, &largest_peak, &largest_peak_offset);

    if (largest_peak_offset > 0) {
      multiplicity++;
      if (largest_peak > total_largest_peak) {
        total_largest_peak = largest_peak;
        total_largest_peak_offset = largest_peak_offset;
      }
    }


    if (cfg->total_pulses) {
      *(cfg->total_pulses) += *npulses;
    }
  }

  cfg->max_peak_sum_value = max_windowed_sum(cfg->peak_trace, cfg->sum_window_start_sample, cfg->sum_window_stop_sample,
                                         nsamples, cfg->coincidence_window, cfg->coincidence_threshold, &cfg->max_peak_sum_offset, cfg->sub_event_list);
  cfg->max_peak_sum_multiplicity = multiplicity;
  cfg->max_peak_value = total_largest_peak;
  cfg->max_peak_offset = total_largest_peak_offset;
}

void fsp_dsp_hardware_majority(DSPHardwareMajority *cfg, int num_traces, unsigned short* trace_list, unsigned short **trace_headers) {

  int multiplicity = 0;
  int mult_below_threshold = 0;
  unsigned short max = 0;
  unsigned short min = USHRT_MAX;
  for (int i = 0; i < num_traces; i++) {
    int trace_idx = trace_list[i];
    if (cfg->tracemap.enabled[trace_idx] < 0)
      continue;
    int map_idx = cfg->tracemap.enabled[trace_idx];
    assert(trace_idx == cfg->tracemap.map[map_idx]);

    /* FCIO Trace Header 1 contains fpga_energy */
    unsigned short fpga_energy = trace_headers[trace_idx][1];
    if (fpga_energy) {
      multiplicity++;

      if (fpga_energy < cfg->fpga_energy_threshold_adc[map_idx])
        mult_below_threshold++;

      if (fpga_energy < min) min = fpga_energy;
      if (fpga_energy > max) max = fpga_energy;

      if (cfg->fast) break;
    }
  }

  cfg->multiplicity = multiplicity;
  cfg->mult_below_threshold = mult_below_threshold;
  cfg->max_value = max;

  if (!multiplicity) {
    cfg->min_value = 0;
  } else {
    cfg->min_value = min;
  }
}

unsigned short fsp_dsp_trace_larger_than(unsigned short *trace, int start, int stop, int nsamples, unsigned short threshold) {
  assert(start >= 0);
  assert(stop <= nsamples);

  unsigned short found = 0;
  for (int i = start; i < stop; i++) {
    unsigned short ampl = trace[i];

    if (ampl < found)
      return found;

    if (ampl > threshold && ampl > found)
      found = ampl;
  }
  return 0;
}

void fsp_dsp_channel_threshold(DSPChannelThreshold* cfg, int nsamples, int num_traces, unsigned short* trace_list, unsigned short **traces, unsigned short** theaders) {

  int nfound = 0;
  for (int i = 0; i < num_traces; i++) {
    int trace_idx = trace_list[i];
    if (cfg->tracemap.enabled[trace_idx] < 0)
      continue;
    int map_idx = cfg->tracemap.enabled[trace_idx];
    assert(trace_idx == cfg->tracemap.map[map_idx]);

    unsigned short *trace = traces[trace_idx];
    unsigned short baseline = theaders[trace_idx][0];

    cfg->max_values[map_idx] = fsp_dsp_trace_larger_than(trace, 0, nsamples, nsamples, cfg->thresholds[map_idx] + baseline);
    if (cfg->max_values[map_idx]) {
      nfound++;
    }
  }
  cfg->multiplicity = nfound;
}
