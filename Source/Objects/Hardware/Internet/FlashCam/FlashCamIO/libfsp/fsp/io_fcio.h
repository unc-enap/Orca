#pragma once

#include "processor.h"
#include <fcio.h>
#include <fcio_utils.h>

void FSPMeasureRecordSizes(StreamProcessor* processor, FCIORecordSizes* sizes);
void FSPCalculateRecordSizes(StreamProcessor* processor, FCIORecordSizes* sizes);

int FCIOGetFSPEvent(FCIOData* input, StreamProcessor* processor);
int FCIOGetFSPConfig(FCIOData* input, StreamProcessor* processor);
int FCIOGetFSPStatus(FCIOData* input, StreamProcessor* processor);

int FCIOPutFSPConfig(FCIOStream output, StreamProcessor* processor);
int FCIOPutFSPEvent(FCIOStream output, StreamProcessor* processor);
int FCIOPutFSPStatus(FCIOStream output, StreamProcessor* processor);

int FCIOPutFSP(FCIOStream output, StreamProcessor* processor, int tag);
