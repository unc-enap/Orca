#include "io.h"
#include "buffer.h"
#include "dsp.h"
#include "processor.h"

#include <assert.h>
#include <stdlib.h>

static inline size_t event_flag_2char(char* string, size_t strlen, EventFlags event_flags) {
  const size_t nflags = 2;
  assert(strlen >= nflags);

  int written = 0;

  string[written++] = ':';
  if (event_flags.is_retrigger)
    string[written] = 'R';
  if (event_flags.is_extended)
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
  if (hwm_flags.multiplicity_threshold) string[written] = 'M';
  written++;
  if (hwm_flags.multiplicity_below) string[written] = 'L';
  written++;
  return written;
}

static inline size_t wps_flag_2char(char* string, size_t strlen, WPSFlags wps_flags) {
  const size_t nflags = 6;
  assert(strlen >= nflags);

  int written = 0;
  string[written++] = ':';
  if (wps_flags.rel_reference) string[written] = '!' ;
  written++;
  if (wps_flags.rel_post_window) string[written] = '<' ;
  written++;
  if (wps_flags.rel_threshold) string[written] = '-' ;
  written++;
  if (wps_flags.rel_pre_window) string[written] = '>' ;
  written++;
  if (wps_flags.abs_threshold) string[written] = 'A';
  written++;
  return written;
}

static inline size_t st_flag_2char(char* string, size_t strlen, STFlags st_flags) {
  const size_t nflags = 7;
  assert(strlen >= nflags);

  int written = 0;
  string[written++] = ':';

  if (st_flags.hwm_multiplicity) string[written] = 'M' ;
  written++;
  if (st_flags.hwm_prescaled) string[written] = 'G' ;
  written++;
  if (st_flags.wps_abs) string[written] = 'A' ;
  written++;
  if (st_flags.wps_rel) string[written] = 'C' ;
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
  for (int i = 0; curr_offset < strlen && i < fsp_state->obs.ct.multiplicity; i++, curr_offset++) {
    cstring[curr_offset] = (char)i;
  }
  cstring[curr_offset] = '\0';
}

void FSPFlags2BitField(FSPState* fsp_state, uint32_t* trigger_field, uint32_t* event_field)
{
  uint32_t tfield = 0;
  uint32_t efield = 0;

  tfield |= ((fsp_state->write_flags.trigger.hwm_multiplicity & 0x1) << 0);
  tfield |= ((fsp_state->write_flags.trigger.hwm_prescaled & 0x1)    << 1);
  tfield |= ((fsp_state->write_flags.trigger.wps_abs & 0x1)          << 2);
  tfield |= ((fsp_state->write_flags.trigger.wps_rel & 0x1)          << 3);
  tfield |= ((fsp_state->write_flags.trigger.wps_prescaled & 0x1)    << 4);
  tfield |= ((fsp_state->write_flags.trigger.ct_multiplicity & 0x1)  << 5);

  efield |= ((fsp_state->write_flags.event.is_extended & 0x1)          << 0);
  efield |= ((fsp_state->write_flags.event.is_retrigger & 0x1)         << 1);
  efield |= ((fsp_state->proc_flags.wps.abs_threshold & 0x1)          << 2);
  efield |= ((fsp_state->proc_flags.wps.rel_threshold & 0x1)          << 3);
  efield |= ((fsp_state->proc_flags.wps.rel_reference & 0x1)          << 4);
  efield |= ((fsp_state->proc_flags.wps.rel_pre_window & 0x1)         << 5);
  efield |= ((fsp_state->proc_flags.wps.rel_post_window & 0x1)        << 6);
  efield |= ((fsp_state->proc_flags.hwm.multiplicity_threshold & 0x1) << 7);
  efield |= ((fsp_state->proc_flags.hwm.multiplicity_below & 0x1)     << 8);
  efield |= ((fsp_state->proc_flags.ct.multiplicity & 0x1)            << 9);

  *trigger_field = tfield;
  *event_field = efield;
}

void FSPBitField2Flags(FSPState* fsp_state, uint32_t trigger_field, uint32_t event_field)
{
  fsp_state->write_flags.trigger.hwm_multiplicity =  trigger_field & (0x1 << 0);
  fsp_state->write_flags.trigger.hwm_prescaled =     trigger_field & (0x1 << 1);
  fsp_state->write_flags.trigger.wps_abs =           trigger_field & (0x1 << 2);
  fsp_state->write_flags.trigger.wps_rel =           trigger_field & (0x1 << 3);
  fsp_state->write_flags.trigger.wps_prescaled =     trigger_field & (0x1 << 4);
  fsp_state->write_flags.trigger.ct_multiplicity =   trigger_field & (0x1 << 5);

  fsp_state->write_flags.event.is_extended =           event_field & (0x1 << 0);
  fsp_state->write_flags.event.is_retrigger =          event_field & (0x1 << 1);
  fsp_state->proc_flags.wps.abs_threshold =           event_field & (0x1 << 2);
  fsp_state->proc_flags.wps.rel_threshold =           event_field & (0x1 << 3);
  fsp_state->proc_flags.wps.rel_reference =           event_field & (0x1 << 4);
  fsp_state->proc_flags.wps.rel_pre_window =          event_field & (0x1 << 5);
  fsp_state->proc_flags.wps.rel_post_window =         event_field & (0x1 << 6);
  fsp_state->proc_flags.hwm.multiplicity_threshold =  event_field & (0x1 << 7);
  fsp_state->proc_flags.hwm.multiplicity_below =      event_field & (0x1 << 8);
  fsp_state->proc_flags.ct.multiplicity =             event_field & (0x1 << 9);
}


void FSPFlags2BitString(FSPState* fsp_state, size_t strlen, char* trigger_string, char* event_string)
{
  assert(strlen >= 20);

  char* trgstring = &trigger_string[8];
  char* evtstring = &event_string[12];

  *trgstring-- = 0;
  *trgstring-- = (fsp_state->write_flags.trigger.hwm_multiplicity & 0x1) ? '1' : '0';
  *trgstring-- = (fsp_state->write_flags.trigger.hwm_prescaled & 0x1) ? '1' : '0';
  *trgstring-- = (fsp_state->write_flags.trigger.wps_abs & 0x1) ? '1' : '0';
  *trgstring-- = (fsp_state->write_flags.trigger.wps_rel & 0x1) ? '1' : '0';
  *trgstring-- = (fsp_state->write_flags.trigger.wps_prescaled & 0x1) ? '1' : '0';
  *trgstring-- = (fsp_state->write_flags.trigger.ct_multiplicity & 0x1) ? '1' : '0';
  *trgstring-- = 'b';
  *trgstring = '0';

  *evtstring-- = 0;
  *evtstring-- = (fsp_state->write_flags.event.is_extended & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->write_flags.event.is_retrigger & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.wps.abs_threshold & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.wps.rel_threshold & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.wps.rel_reference & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.wps.rel_pre_window & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.wps.rel_post_window & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.hwm.multiplicity_threshold & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.hwm.multiplicity_below & 0x1) ? '1' : '0';
  *evtstring-- = (fsp_state->proc_flags.ct.multiplicity & 0x1) ? '1' : '0';
  *evtstring-- = 'b';
  *evtstring-- = '0';
}
