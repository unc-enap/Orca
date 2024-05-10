#pragma once

#include <stdint.h>

#include <fcio.h>

#include <fsp_timestamps.h>
#include <fsp_dsp.h>

typedef union STFlags {
  struct {
    uint8_t hwm_multiplicity; // the multiplicity threshold has been reached
    uint8_t hwm_prescaled; // the event was prescaled due to the HWM condition
    uint8_t wps_abs; // the absolute peak sum threshold was reached
    uint8_t wps_rel; // the relative peak sum threshold was reached and a coincidence to a reference event is fulfilled
    uint8_t wps_prescaled; // the event was prescaled due to the WPS condition
    uint8_t ct_multiplicity; // a channel was above the ChannelThreshold condition
  };
  uint64_t is_flagged;
} STFlags;

typedef union EventFlags {
  struct {
    uint8_t is_retrigger; // the event is a retrigger event
    uint8_t is_extended; // the event triggered (a) retrigger event(s)
  };
  uint64_t is_flagged;
} EventFlags;

// Windowed Peak Sum
typedef union WPSFlags {
  struct {
    uint8_t abs_threshold; // absolute threshold was reached
    uint8_t rel_threshold; // relative threshold was reached
    uint8_t rel_reference; // the event is a WPS reference event
    uint8_t rel_pre_window; // the event is in the pre window of a reference event
    uint8_t rel_post_window; // the event is in the post window of a reference event
  };
  uint64_t is_flagged;
} WPSFlags;

// Hardware Multiplicity
typedef union HWMFlags {
  struct {
    uint8_t multiplicity_threshold; // the multiplicity threshold (number of channels) has been reached
    uint8_t multiplicity_below; // all non-zero channels have an hardware value below the set amplitude threshold
  };
  uint64_t is_flagged;
} HWMFlags;

// Channel Threshold
typedef union CTFlags {
  struct {
    uint8_t multiplicity; // if number of threshold triggers > 0
  };
  uint64_t is_flagged;
} CTFlags;

typedef struct FSPFlags {

  EventFlags event;
  STFlags trigger;

  WPSFlags wps;
  HWMFlags hwm;
  CTFlags ct;

} FSPFlags;

typedef struct FSPObervables {
  // Windows Peak Sum
  struct wps_obs {
    float max_value; // what is the maximum PE within the integration windows
    int max_offset;  // when is the total sum offset reached?
    int max_multiplicity;  // How many channels did have a peak above thresholds
    float max_single_peak_value;   // which one was the largest individual peak
    int max_single_peak_offset;  // which sample contains this peak

    /* sub triggerlist */
    WPSTriggerList trigger_list;
  } wps;


  // FPGA Majority
  struct hwm_obs {
    int multiplicity;          // how many channels have fpga_energy > 0
    unsigned short max_value;  // what is the largest fpga_energy of those
    unsigned short min_value;  // what is the smallest fpga_energy of those

  } hwm;

  // Channel Threshold 
  struct ct_obs {
    int multiplicity; // how many channels were above the threshold
    unsigned short max[FCIOMaxChannels]; // the maximum per channel
    int trace_idx[FCIOMaxChannels]; // the corresponding fcio trace index
    const char* label[FCIOMaxChannels]; // the name of the channel given during setup

  } ct;

  struct event_obs {
    int nextension; // if we found re-triggers how many events are consecutive from then on. the event with the extension flag carries the total number
  } evt;

} FSPObservables;

typedef struct FSPState {
  /* internal */
  FCIOState *state;
  Timestamp timestamp;
  Timestamp unixstamp;
  int has_timestamp;
  int in_buffer;
  int stream_tag;

  /* calculate observables if event */
  FSPObservables obs;
  /* condense observables into flags */
  FSPFlags flags;
  /* final write decision based on enabled flags */
  int write;

} FSPState;
