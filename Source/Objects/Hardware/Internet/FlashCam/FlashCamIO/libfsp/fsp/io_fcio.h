#pragma once

#include "processor.h"
#include <fcio.h>
#include <fcio_utils.h>

void FSPMeasureRecordSizes(StreamProcessor* processor, FSPState* fspstate, FCIORecordSizes* sizes);
void FSPCalculateRecordSizes(StreamProcessor* processor, FSPState* fspstate, FCIORecordSizes* sizes);

int FCIOGetFSPEvent(FCIOData* input, FSPState* fsp_state);
int FCIOGetFSPConfig(FCIOData* input, StreamProcessor* processor);
int FCIOGetFSPStatus(FCIOData* input, StreamProcessor* processor);

int FCIOPutFSPConfig(FCIOStream output, StreamProcessor* processor);
int FCIOPutFSPEvent(FCIOStream output, FSPState* fsp_state);
int FCIOPutFSPStatus(FCIOStream output, StreamProcessor* processor);

int FCIOPutFSP(FCIOStream output, StreamProcessor* processor, int tag);
