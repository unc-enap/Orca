#pragma once

#include <stddef.h>
#include <sys/types.h>

#include "state.h"

void FSPFlags2BitString(FSPState* fsp_state, size_t strlen, char* trigger_string, char* event_string);
void FSPBitField2Flags(FSPState* fsp_state, uint32_t trigger_field, uint32_t event_field);
void FSPFlags2BitField(FSPState* fsp_state, uint32_t* trigger_field, uint32_t* event_field);
void FSPFlags2Char(FSPState *fsp_state, size_t strlen, char *cstring);
