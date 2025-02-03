#pragma once

#include <stddef.h>

#include "fcio.h"

typedef struct {
  size_t protocol;
  size_t config;
  size_t event;
  size_t sparseevent;
  size_t eventheader;
  size_t status;
  size_t fspconfig;
  size_t fspevent;
  size_t fspstatus;

} FCIORecordSizes;

void FCIOMeasureRecordSizes(FCIOData* data, FCIORecordSizes* sizes);
void FCIOCalculateRecordSizes(FCIOData* data, FCIORecordSizes* sizes);

void FCIOStateMeasureRecordSizes(FCIOState* state, FCIORecordSizes* sizes);
void FCIOStateCalculateRecordSizes(FCIOState* state, FCIORecordSizes* sizes);

size_t FCIOWrittenBytes(FCIOStream stream);
size_t FCIOStreamBytes(FCIOStream stream, int direction, size_t offset);

int FCIOSetMemField(FCIOStream stream, void *mem_addr, size_t mem_size);
void FCIOPrintRecordSizes(FCIORecordSizes sizes);
const char* FCIOTagStr(int tag);
