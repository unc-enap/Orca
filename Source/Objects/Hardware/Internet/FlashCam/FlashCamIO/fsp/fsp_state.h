#pragma once

#include <fcio.h>

#include <fsp_timestamps.h>
#include <fsp_dsp.h>

#define ST_NSTATES 5
typedef enum SoftwareTriggerFlags {

  ST_NULL = 0,
  ST_HWM_TRIGGER = 1 << 0,
  ST_HWM_PRESCALED = 1 << 1,
  ST_WPS_ABS_TRIGGER = 1 << 2,
  ST_WPS_REL_TRIGGER = 1 << 3,
  ST_WPS_PRESCALED = 1 << 4,
  ST_DF_TRIGGER = 1 << 5,

} SoftwareTriggerFlags;

#define EVT_NSTATES 12
typedef enum EventFlags {

  EVT_NULL = 0,
  EVT_RETRIGGER = 1 << 0,
  EVT_EXTENDED = 1 << 1,
  EVT_HWM_MULT_THRESHOLD = 1 << 2,
  EVT_HWM_MULT_ENERGY_BELOW = 1 << 3,
  EVT_WPS_ABS_THRESHOLD = 1 << 4,
  EVT_WPS_REL_THRESHOLD = 1 << 5,
  EVT_WPS_REL_REFERENCE = 1 << 6,
  EVT_WPS_REL_PRE_WINDOW = 1 << 7,
  EVT_WPS_REL_POST_WINDOW = 1 << 8,
  EVT_DF_PULSER = 1 << 9,
  EVT_DF_BASELINE = 1 << 10,
  EVT_DF_MUON = 1 << 11,

} EventFlags;

typedef struct FSPFlags {

  unsigned int trigger;
  unsigned int event;

} FSPFlags;

typedef struct FSPState {
  /* internal */
  FCIOState *state;
  Timestamp timestamp;
  Timestamp unixstamp;
  int contains_timestamp;
  int in_buffer;
  int stream_tag;

  /* calculate observables if event */
  FSPFlags flags;
  // Peak Sum
  float wps_max_value; // what is the maximum PE within the integration windows
  int wps_max_offset;  // when is the total sum offset reached?
  int wps_max_multiplicity;  // How many channels did have a peak above thresholds
  float wps_max_single_peak_value;   // which one was the largest individual peak
  int wps_max_single_peak_offset;  // which sample contains this peak

  /* sub triggerlist */
  WPSTriggerList* wps_trigger_list;

  // FPGA Majority
  int hwm_multiplicity;          // how many channels have fpga_energy > 0
  unsigned short hwm_max_value;  // what is the largest fpga_energy of those
  unsigned short hwm_min_value;  // what is the smallest fpga_energy of those

  /* final write decision */
  int write;

} FSPState;
