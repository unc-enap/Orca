#include "stats.h"

#include <stdio.h>

#include <time_utils.h>

#include "processor.h"

int FSPStatsUpdate(StreamProcessor* processor, int force) {
  FSPStats* stats = &processor->stats;

  if (elapsed_time(stats->dt_logtime) > stats->log_time || force) {
    stats->runtime = elapsed_time(stats->start_time);
    stats->dt = elapsed_time(stats->dt_logtime);
    stats->dt_logtime = elapsed_time(0.0);

    stats->dt_n_read_events = processor->nevents_read - stats->n_read_events;
    stats->n_read_events = processor->nevents_read;

    stats->dt_n_written_events = processor->nevents_written - stats->n_written_events;
    stats->n_written_events = processor->nevents_written;

    stats->dt_n_discarded_events = processor->nevents_discarded - stats->n_discarded_events;
    stats->n_discarded_events = processor->nevents_discarded;

    stats->dt_rate_read_events = stats->dt_n_read_events / stats->dt;
    stats->dt_rate_write_events = stats->dt_n_written_events / stats->dt;
    stats->dt_rate_discard_events = stats->dt_n_discarded_events / stats->dt;

    stats->avg_rate_read_events = stats->n_read_events / stats->runtime;
    stats->avg_rate_write_events = stats->n_written_events / stats->runtime;
    stats->avg_rate_discard_events = stats->n_discarded_events / stats->runtime;

    return 1;
  }
  return 0;
}

int FSPStatsInfluxString(StreamProcessor* processor, char* logstring, size_t logstring_size) {

  FSPStats* stats = &processor->stats;

  int ret = snprintf(logstring, logstring_size,
                     "run_time=%.03f,cur_read_hz=%.03f,cur_write_hz=%.03f,cur_discard_hz=%.03f,avg_read_hz=%.03f,avg_write_hz=%.03f,"
                     "avg_discard_hz=%.03f,cur_nread=%d,cur_nwrite=%d,cur_ndiscard=%d,tot_nread=%d,tot_nwrite=%d,tot_ndiscard=%d",
                     stats->runtime,
                     stats->dt_rate_read_events, stats->dt_rate_write_events, stats->dt_rate_discard_events,
                     stats->avg_rate_read_events, stats->avg_rate_write_events, stats->avg_rate_discard_events, stats->dt_n_read_events,stats->dt_n_written_events, stats->dt_n_discarded_events,
                     stats->n_read_events, stats->n_written_events, stats->n_discarded_events);

  if (ret >= 0 && ret < (int)logstring_size)
    return 1;
  return 0;
}
