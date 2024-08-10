#pragma once

#include <stdint.h>

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
    uint8_t prescaled; // in addition to the multiplicity_below condition the current event is ready to prescale to it's timestamp
  };
  uint64_t is_flagged;
} WPSFlags;

// Hardware Multiplicity
typedef union HWMFlags {
  struct {
    uint8_t multiplicity_threshold; // the multiplicity threshold (number of channels) has been reached
    uint8_t multiplicity_below; // all non-zero channels have an hardware value below the set amplitude threshold
    uint8_t prescaled; // in addition to the multiplicity_below condition the current event is ready to prescale to it's timestamp
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

typedef struct FSPWriteFlags {
  /* write flags */
  EventFlags event;
  STFlags trigger;

  uint32_t write;
} FSPWriteFlags;

typedef struct FSPProcessorFlags {

  /* processor flags */
  HWMFlags hwm;
  WPSFlags wps;
  CTFlags ct;

} FSPProcessorFlags;
