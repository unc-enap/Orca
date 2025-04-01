#pragma once

#include <stdint.h>

typedef union TriggerFlags {
  struct {
    uint8_t hwm_multiplicity; // the multiplicity threshold has been reached
    uint8_t hwm_prescaled; // the event was prescaled due to the HWM condition
    uint8_t wps_sum; // the standalone peak sum threshold was reached
    uint8_t wps_coincident_sum; // the coincidence peak sum threshold was reached and a coincidence to a reference event is fulfilled
    uint8_t wps_prescaled; // the event was prescaled due to the WPS condition
    uint8_t ct_multiplicity; // a channel was above the ChannelThreshold condition
  };
  uint64_t is_flagged;
} TriggerFlags;

typedef union EventFlags {
  struct {
    uint8_t consecutive; // the event might be a retrigger event or start immediately after
    uint8_t extended; // the event preceeds one or more consecutive events
  };
  uint64_t is_flagged;
} EventFlags;

// Windowed Peak Sum
typedef union WPSFlags {
  struct {
    uint8_t sum_threshold; // sum threshold was reached
    uint8_t coincidence_sum_threshold; // coincidence sum threshold was reached
    uint8_t coincidence_ref; // the event is a WPS reference event
    uint8_t ref_pre_window; // the event is in the pre window of a reference event
    uint8_t ref_post_window; // the event is in the post window of a reference event
    uint8_t prescaled; // the event was prescaled
  };
  uint64_t is_flagged;
} WPSFlags;

// Hardware Multiplicity
typedef union HWMFlags {
  struct {
    uint8_t sw_multiplicity; // the multiplicity threshold for number of sw triggered channels has been reached
    uint8_t hw_multiplicity; // the multiplicity threshold for number of hw triggered channels has been reached
    uint8_t prescaled; // a channel was prescaled
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
  TriggerFlags trigger;

  uint32_t write;
} FSPWriteFlags;

typedef struct FSPProcessorFlags {

  /* processor flags */
  HWMFlags hwm;
  WPSFlags wps;
  CTFlags ct;

} FSPProcessorFlags;
