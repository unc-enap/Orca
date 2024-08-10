#pragma once

#include <stddef.h>

typedef struct FSPStats {
  double start_time;
  double log_time;
  double dt_logtime;
  double runtime;

  int n_read_events;
  int n_written_events;
  int n_discarded_events;

  int dt_n_read_events;
  int dt_n_written_events;
  int dt_n_discarded_events;

  double dt;
  double dt_rate_read_events;
  double dt_rate_write_events;
  double dt_rate_discard_events;

  double avg_rate_read_events;
  double avg_rate_write_events;
  double avg_rate_discard_events;

} FSPStats;
