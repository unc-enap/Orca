#pragma once

#include "timestamps.h"
#include "flags.h"
#include "observables.h"

#include <fcio.h>

typedef struct FSPState {
  /* internal */
  FCIOState *state;
  Timestamp timestamp;
  Timestamp unixstamp;
  int has_timestamp;
  int in_buffer;
  int stream_tag;

  /* condense observables into flags */
  FSPWriteFlags write_flags;
  FSPProcessorFlags proc_flags;
  /* calculate observables if event */
  FSPObservables obs;

} FSPState;
