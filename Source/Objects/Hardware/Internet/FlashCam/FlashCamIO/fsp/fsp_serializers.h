#pragma once

#include <stddef.h>

#include <fsp_state.h>

void FSPFlags2BitString(FSPFlags flags, size_t strlen, char* trigger_string, char* event_string);
void FSPBitField2Flags(FSPFlags* flags, uint32_t trigger_field, uint32_t event_field);

void FSPFlags2Char(FSPState *fsp_state, size_t strlen, char *cstring);
