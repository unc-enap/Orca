#pragma once

#include "state.h"
#include "processor.h"

#include <fcio.h>

int fsp_process(StreamProcessor* processor, FSPState* fsp_state, FCIOState* state);
