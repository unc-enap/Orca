#pragma once

#include <fcio.h>
#include <timestamps.h>
#include <dsp.h>

#define ST_NSTATES 6
typedef enum SoftwareTriggerFlags {

  ST_NULL = 0,
  ST_TRIGGER_FORCE = 1 << 0,
  ST_TRIGGER_SIPM_NPE = 1 << 1,
  ST_TRIGGER_SIPM_NPE_IN_WINDOW = 1 << 2,
  ST_TRIGGER_SIPM_PRESCALED = 1 << 3,
  ST_TRIGGER_GE_PRESCALED = 1 << 4,

} SoftwareTriggerFlags;

#define EVT_NSTATES 11
typedef enum EventFlags {

  EVT_NULL = 0,
  EVT_AUX_PULSER = 1 << 0,
  EVT_AUX_BASELINE = 1 << 1,
  EVT_AUX_MUON = 1 << 2,
  EVT_RETRIGGER = 1 << 3,
  EVT_EXTENDED = 1 << 4,
  EVT_FPGA_MULTIPLICITY = 1 << 5,
  EVT_ASUM_MIN_NPE = 1 << 6,
  EVT_FORCE_PRE_WINDOW = 1 << 7,
  EVT_FORCE_POST_WINDOW = 1 << 8,
  EVT_FPGA_MULTIPLICITY_ENERGY_BELOW = 1 << 9,

} EventFlags;

typedef struct Flags {
  unsigned int trigger;
  unsigned int event;
} Flags;

typedef struct LPPState {
  /* internal */
  FCIOState *state;
  Timestamp timestamp;
  Timestamp unixstamp;
  int contains_timestamp;
  int in_buffer;

  /* calculate observables if event */
  Flags flags;
  // Peak Sum
  float largest_sum_pe;    // what is the maximum PE within the integration windows
  int largest_sum_offset;  // when is the total sum offset reached?

  int channel_multiplicity;  // How many channels did have a peak above thresholds
  float largest_pe;          // which one was the largest individual peak

  // FPGA Majority
  int majority;                       // how many channels have fpga_energy > 0
  unsigned short ge_max_fpga_energy;  // what is the largest fpga_energy of those
  unsigned short ge_min_fpga_energy;  // what is the smallest fpga_energy of those

  /* sub triggerlist */
  TriggerList* trigger_list;

  /* final write decision */
  int write;
  int stream_tag;

} LPPState;
