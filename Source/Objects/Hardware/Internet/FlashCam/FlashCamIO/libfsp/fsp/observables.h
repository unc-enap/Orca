#pragma once

#include <fcio.h>

typedef struct {
    int size;
    // first sample the trigger is up
    int start[FCIOMaxSamples];
    // first sample after trigger up is gone
    int stop[FCIOMaxSamples];
    float wps_max[FCIOMaxSamples];
  } SubEventList;

// Windows Peak Sum
typedef struct wps_obs {
  // what is the maximum peak amplitude sum within the integration windows
  float sum_value;
  // which sample offset is max_value at?
  int sum_offset;
  // How many channels did have a peak above thresholds
  int sum_multiplicity;
  // which one was the largest individual peak
  float max_single_peak_value;
  // which sample contains this peak
  int max_single_peak_offset;
} wps_obs;

// FPGA Majority
typedef struct hwm_obs {
  // how many channels have fpga_energy > 0
  int hw_multiplicity;
  // what is the largest fpga_energy of those
  unsigned short max_value;
  // what is the smallest fpga_energy of those
  unsigned short min_value;
  // how many channels were above the fpga_energy threshold in software trigger and the required multiplicity
  int sw_multiplicity;

} hwm_obs;

// Channel Threshold
typedef struct ct_obs {
  // how many channels were above the threshold
  int multiplicity;
  // the corresponding fcio trace index
  int trace_idx[FCIOMaxChannels];
  // the maximum per channel
  unsigned short max[FCIOMaxChannels];

} ct_obs;

// Event Stream
typedef struct evt_obs {
  // if we found re-triggers how many events are consecutive from then on. the event with the extension flag carries the total number
  int nconsecutive;
} evt_obs;

typedef struct prescale_obs {
  // how many hwm channels were prescaled
  int n_hwm_prescaled;
  // which channels were prescaled
  unsigned short hwm_prescaled_trace_idx[FCIOMaxChannels];

} prescale_obs;

typedef struct FSPObervables {

  wps_obs wps;
  hwm_obs hwm;
  ct_obs ct;
  evt_obs evt;
  prescale_obs ps;

  SubEventList sub_event_list;

} FSPObservables;
