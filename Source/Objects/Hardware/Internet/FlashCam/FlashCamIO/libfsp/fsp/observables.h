#pragma once

#include <fcio.h>

typedef struct {
    int size;
    int start[FCIOMaxSamples];
    int stop[FCIOMaxSamples]; // first sample after trigger up is gone
    float wps_max[FCIOMaxSamples];
  } SubEventList;

// Windows Peak Sum
typedef struct wps_obs {
  float sum_value; // what is the maximum peak amplitude sum within the integration windows
  int sum_offset;  // which sample offset is max_value at?
  int sum_multiplicity;  // How many channels did have a peak above thresholds
  float max_single_peak_value;   // which one was the largest individual peak
  int max_single_peak_offset;  // which sample contains this peak
} wps_obs;

// FPGA Majority
typedef struct hwm_obs {
  int multiplicity;          // how many channels have fpga_energy > 0
  unsigned short max_value;  // what is the largest fpga_energy of those
  unsigned short min_value;  // what is the smallest fpga_energy of those

} hwm_obs;

// Channel Threshold
typedef struct ct_obs {
  int multiplicity; // how many channels were above the threshold
  int trace_idx[FCIOMaxChannels]; // the corresponding fcio trace index
  unsigned short max[FCIOMaxChannels]; // the maximum per channel

} ct_obs;

// Event Stream
typedef struct evt_obs {
  int nconsecutive; // if we found re-triggers how many events are consecutive from then on. the event with the extension flag carries the total number
} evt_obs;

typedef struct FSPObervables {

  wps_obs wps;
  hwm_obs hwm;
  ct_obs ct;
  evt_obs evt;

  SubEventList sub_event_list;

} FSPObservables;
