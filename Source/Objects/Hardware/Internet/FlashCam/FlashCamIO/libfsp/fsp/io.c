#include "io.h"

#include <assert.h>
#include <stdlib.h>
#include <stdio.h>

static inline size_t event_flag_2char(char* string, size_t strlen, EventFlags event_flags) {
  const size_t nflags = 2;
  assert(strlen >= nflags);

  int written = 0;

  string[written++] = ':';
  if (event_flags.consecutive)
    string[written] = 'R';
  if (event_flags.extended)
    string[written] = 'E';

  written++;
  return written;
}

static inline size_t ct_flag_2char(char* string, size_t strlen, CTFlags ct_flags) {
  const size_t nflags = 2;
  assert(strlen >= nflags);

  int written = 0;
  string[written++] = ':';
  if (ct_flags.multiplicity) string[written] = 'T';
  written++;
  return written;
}

static inline size_t hwm_flag_2char(char* string, size_t strlen, HWMFlags hwm_flags) {
  const size_t nflags = 3;
  assert(strlen >= nflags);

  int written = 0;
  string[written++] = ':';
  if (hwm_flags.sw_multiplicity) string[written] = 'S';
  written++;
  if (hwm_flags.hw_multiplicity) string[written] = 'H';
  written++;
  return written;
}

static inline size_t wps_flag_2char(char* string, size_t strlen, WPSFlags wps_flags) {
  const size_t nflags = 6;
  assert(strlen >= nflags);

  int written = 0;
  string[written++] = ':';
  if (wps_flags.coincidence_ref) string[written] = '!' ;
  written++;
  if (wps_flags.ref_post_window) string[written] = '<' ;
  written++;
  if (wps_flags.coincidence_sum_threshold) string[written] = '-' ;
  written++;
  if (wps_flags.ref_pre_window) string[written] = '>' ;
  written++;
  if (wps_flags.sum_threshold) string[written] = 'A';
  written++;
  return written;
}

static inline size_t st_flag_2char(char* string, size_t strlen, TriggerFlags st_flags) {
  const size_t nflags = 7;
  assert(strlen >= nflags);

  int written = 0;
  string[written++] = ':';

  if (st_flags.hwm_multiplicity) string[written] = 'M' ;
  written++;
  if (st_flags.hwm_prescaled) string[written] = 'G' ;
  written++;
  if (st_flags.wps_sum) string[written] = 'A' ;
  written++;
  if (st_flags.wps_coincident_sum) string[written] = 'C' ;
  written++;
  if (st_flags.wps_prescaled) string[written] = 'S' ;
  written++;
  if (st_flags.ct_multiplicity) string[written] = 'T' ;
  written++;

  return written;
}

void FSPFlags2Char(FSPState* fsp_state, size_t strlen, char* cstring) {
  const size_t nfields = 9 + 6 + 1 + 1 + 2 + 5;
  assert(strlen >= nfields);

  for (size_t i = 0; i < nfields; i++) cstring[i] = '_';
  size_t curr_offset = 0;
  cstring[curr_offset++] = fsp_state->write_flags.write ? 'W' : 'D';

  switch (fsp_state->stream_tag) {
    case FCIOConfig:
      cstring[curr_offset++] = 'C';
      break;
    case FCIOStatus:
      cstring[curr_offset++] = 'S';
      break;
    case FCIOEvent:
      cstring[curr_offset++] = 'E';
      break;
    case FCIOSparseEvent:
      cstring[curr_offset++] = 'Z';
      break;
    case FCIOEventHeader:
      cstring[curr_offset++] = 'H';
      break;
    case FCIORecEvent:
      cstring[curr_offset++] = 'R';
      break;
    default:
      cstring[curr_offset++] = '?';
      break;
  }

  curr_offset += st_flag_2char(&cstring[curr_offset], 7, fsp_state->write_flags.trigger);

  curr_offset += event_flag_2char(&cstring[curr_offset], 2, fsp_state->write_flags.event);

  curr_offset += ct_flag_2char(&cstring[curr_offset], 2, fsp_state->proc_flags.ct);

  curr_offset += hwm_flag_2char(&cstring[curr_offset], 3, fsp_state->proc_flags.hwm);

  curr_offset += wps_flag_2char(&cstring[curr_offset], 6, fsp_state->proc_flags.wps);

  cstring[curr_offset++] = ':';
  cstring[curr_offset] = '\0';
}

void FSPFlags2BitField(FSPState* fsp_state, uint32_t* trigger_field, uint32_t* event_field)
{
  uint32_t tfield = 0;
  uint32_t efield = 0;

  uint32_t bit = 0;
  tfield |= ((fsp_state->write_flags.trigger.hwm_multiplicity & 0x1)     << bit++);
  tfield |= ((fsp_state->write_flags.trigger.hwm_prescaled & 0x1)        << bit++);
  tfield |= ((fsp_state->write_flags.trigger.wps_sum & 0x1)              << bit++);
  tfield |= ((fsp_state->write_flags.trigger.wps_coincident_sum & 0x1)   << bit++);
  tfield |= ((fsp_state->write_flags.trigger.wps_prescaled & 0x1)        << bit++);
  tfield |= ((fsp_state->write_flags.trigger.ct_multiplicity & 0x1)      << bit++);
  tfield |= ((fsp_state->write_flags.event.extended & 0x1)               << bit++);
  tfield |= ((fsp_state->write_flags.event.consecutive & 0x1)            << bit++);

  bit = 0;
  efield |= ((fsp_state->proc_flags.evt.extended & 0x1)               << bit++);
  efield |= ((fsp_state->proc_flags.evt.consecutive & 0x1)            << bit++);
  efield |= ((fsp_state->proc_flags.wps.sum_threshold & 0x1)             << bit++);
  efield |= ((fsp_state->proc_flags.wps.coincidence_sum_threshold & 0x1) << bit++);
  efield |= ((fsp_state->proc_flags.wps.coincidence_ref & 0x1)           << bit++);
  efield |= ((fsp_state->proc_flags.wps.ref_pre_window & 0x1)            << bit++);
  efield |= ((fsp_state->proc_flags.wps.ref_post_window & 0x1)           << bit++);
  efield |= ((fsp_state->proc_flags.hwm.sw_multiplicity & 0x1)           << bit++);
  efield |= ((fsp_state->proc_flags.hwm.hw_multiplicity & 0x1)           << bit++);
  efield |= ((fsp_state->proc_flags.ct.multiplicity & 0x1)               << bit++);

  *trigger_field = tfield;
  *event_field = efield;
}

void FSPBitField2Flags(FSPState* fsp_state, uint32_t trigger_field, uint32_t event_field)
{
  uint32_t bit = 0;
  fsp_state->write_flags.trigger.hwm_multiplicity =   trigger_field & (0x1 << bit++);
  fsp_state->write_flags.trigger.hwm_prescaled =      trigger_field & (0x1 << bit++);
  fsp_state->write_flags.trigger.wps_sum =            trigger_field & (0x1 << bit++);
  fsp_state->write_flags.trigger.wps_coincident_sum = trigger_field & (0x1 << bit++);
  fsp_state->write_flags.trigger.wps_prescaled =      trigger_field & (0x1 << bit++);
  fsp_state->write_flags.trigger.ct_multiplicity =    trigger_field & (0x1 << bit++);
  fsp_state->write_flags.event.extended =             trigger_field & (0x1 << bit++);
  fsp_state->write_flags.event.consecutive =          trigger_field & (0x1 << bit++);

  bit = 0;
  fsp_state->proc_flags.evt.extended =                  event_field & (0x1 << bit++);
  fsp_state->proc_flags.evt.consecutive =               event_field & (0x1 << bit++);
  fsp_state->proc_flags.wps.sum_threshold =             event_field & (0x1 << bit++);
  fsp_state->proc_flags.wps.coincidence_sum_threshold = event_field & (0x1 << bit++);
  fsp_state->proc_flags.wps.coincidence_ref =           event_field & (0x1 << bit++);
  fsp_state->proc_flags.wps.ref_pre_window =            event_field & (0x1 << bit++);
  fsp_state->proc_flags.wps.ref_post_window =           event_field & (0x1 << bit++);
  fsp_state->proc_flags.hwm.sw_multiplicity =           event_field & (0x1 << bit++);
  fsp_state->proc_flags.hwm.hw_multiplicity =           event_field & (0x1 << bit++);
  fsp_state->proc_flags.ct.multiplicity =               event_field & (0x1 << bit++);
}


void FSPFlags2BitString(FSPState* fsp_state, size_t strlen, char* trigger_string, char* event_string)
{
  assert(strlen >= 20);

  char* trgstring = &trigger_string[8];
  char* evtstring = &event_string[12];

  *trgstring-- = 0;
  *trgstring-- = (fsp_state->write_flags.trigger.hwm_multiplicity & 0x1) ? '1' : '0';
  *trgstring-- = (fsp_state->write_flags.trigger.hwm_prescaled & 0x1) ? '1' : '0';
  *trgstring-- = (fsp_state->write_flags.trigger.wps_sum & 0x1) ? '1' : '0';
  *trgstring-- = (fsp_state->write_flags.trigger.wps_coincident_sum & 0x1) ? '1' : '0';
  *trgstring-- = (fsp_state->write_flags.trigger.wps_prescaled & 0x1) ? '1' : '0';
  *trgstring-- = (fsp_state->write_flags.trigger.ct_multiplicity & 0x1) ? '1' : '0';
  *trgstring-- = (fsp_state->write_flags.event.extended & 0x1) ? '1' : '0';
  *trgstring-- = (fsp_state->write_flags.event.consecutive & 0x1) ? '1' : '0';
  *trgstring-- = 'b';
  *trgstring = '0';

  *evtstring-- = 0;
  *evtstring-- = (fsp_state->proc_flags.evt.extended & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.evt.consecutive & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.wps.sum_threshold & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.wps.coincidence_sum_threshold & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.wps.coincidence_ref & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.wps.ref_pre_window & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.wps.ref_post_window & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.hwm.sw_multiplicity & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.hwm.hw_multiplicity & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.ct.multiplicity & 0x1) ? '1' : '0';
  *evtstring-- = 'b';
  *evtstring-- = '0';
}
