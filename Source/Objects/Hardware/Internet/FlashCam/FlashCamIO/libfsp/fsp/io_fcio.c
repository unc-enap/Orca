#include "io_fcio.h"
#include "dsp.h"
#include "fcio.h"
#include "observables.h"
#include "processor.h"
#include "state.h"
#include "timestamps.h"

#include <fcio_utils.h>
#include <tmio.h>
#include <unistd.h>

/* internal helpers */

// FSPTraceMap
static inline int fcio_put_fsp_tracemap(FCIOStream stream, FSPTraceMap* map) {
  if (!stream || !map)
    return -1;
  FCIOWriteInt(stream, map->format);
  FCIOWriteInts(stream, map->n_mapped, map->map);
  FCIOWriteInts(stream, map->n_enabled, map->enabled);
  FCIOWrite(stream, map->n_mapped * sizeof(*map->label), map->label);
  return 0;
}
static inline int fcio_get_fsp_tracemap(FCIOStream stream, FSPTraceMap* map) {
  if (!stream || !map)
    return -1;
  FCIOReadInt(stream, map->format);
  int readbytes = 0;
  readbytes = FCIOReadInts(stream, FCIOMaxChannels, map->map);
  map->n_mapped = (readbytes >= 0) ? readbytes/sizeof(*map->map) : 0;
  readbytes = FCIOReadInts(stream, FCIOMaxChannels, map->enabled);
  map->n_enabled = (readbytes >= 0) ? readbytes/sizeof(*map->enabled) : 0;
  int nlabels = FCIORead(stream, FCIOMaxChannels * sizeof(*map->label), map->label) / sizeof(*map->label);

  if (nlabels != map->n_mapped)
    return -1;

  return 0;
}

// Timestamp
static inline int fcio_put_fsp_timestamp(FCIOStream stream, Timestamp* timestamp) {
  if (!stream || !timestamp)
    return -1;

  FCIOWrite(stream, sizeof(timestamp->seconds), &timestamp->seconds);
  FCIOWrite(stream, sizeof(timestamp->nanoseconds), &timestamp->nanoseconds);
  return 0;
}
static inline int fcio_get_fsp_timestamp(FCIOStream stream, Timestamp* timestamp) {
  if (!stream || !timestamp)
    return -1;
  FCIORead(stream, sizeof(timestamp->seconds), &timestamp->seconds);
  FCIORead(stream, sizeof(timestamp->nanoseconds), &timestamp->nanoseconds);
  return 0;
}

// FSPBuffer
static inline int fcio_put_fspconfig_buffer(FCIOStream stream, FSPBuffer* buffer) {
  if (!stream || !buffer)
    return -1;
  FCIOWriteInt(stream, buffer->max_states);
  fcio_put_fsp_timestamp(stream, &buffer->buffer_window);
  return 0;
}
static inline int fcio_get_fspconfig_buffer(FCIOStream in, FSPBuffer* buffer) {
  if (!buffer)
    return -1;
  FCIOReadInt(in, buffer->max_states);
  fcio_get_fsp_timestamp(in, &buffer->buffer_window);

  return 0;
}

// DSPHardwareMajority
static inline int fcio_put_fspconfig_hwm(FCIOStream stream, DSPHardwareMultiplicity* dsp_hwm) {
  if (!stream || !dsp_hwm)
    return -1;
  fcio_put_fsp_tracemap(stream, &dsp_hwm->tracemap);
  FCIOWriteUShorts(stream, dsp_hwm->tracemap.n_mapped, dsp_hwm->fpga_energy_threshold_adc);

  return 0;
}
static inline int fcio_get_fspconfig_hwm(FCIOStream in, DSPHardwareMultiplicity* dsp_hwm) {
  if (!dsp_hwm)
    return -1;
  fcio_get_fsp_tracemap(in, &dsp_hwm->tracemap);
  FCIOReadUShorts(in, FCIOMaxChannels, dsp_hwm->fpga_energy_threshold_adc);

  return 0;
}

// DSPHardwwareMajority
static inline int fcio_put_fspconfig_ct(FCIOStream stream, DSPChannelThreshold* dsp_ct) {
  if (!stream || !dsp_ct)
    return -1;
  fcio_put_fsp_tracemap(stream, &dsp_ct->tracemap);
  FCIOWriteUShorts(stream, dsp_ct->tracemap.n_mapped, dsp_ct->thresholds);


  return 0;
}
static inline int fcio_get_fspconfig_ct(FCIOStream in, DSPChannelThreshold* dsp_ct) {
  if (!dsp_ct)
    return -1;
  fcio_get_fsp_tracemap(in, &dsp_ct->tracemap);
  FCIOReadUShorts(in, FCIOMaxChannels, dsp_ct->thresholds);

  return 0;
}

// DSPWindowedPeakSum
static inline int fcio_put_fspconfig_wps(FCIOStream stream, DSPWindowedPeakSum* dsp_wps) {
  if (!stream || !dsp_wps)
    return -1;
  fcio_put_fsp_tracemap(stream, &dsp_wps->tracemap);

  FCIOWriteInt(stream, dsp_wps->apply_gain_scaling);
  FCIOWriteInt(stream, dsp_wps->sum_window_size);
  FCIOWriteInt(stream, dsp_wps->sum_window_start_sample);
  FCIOWriteInt(stream, dsp_wps->sum_window_stop_sample);
  FCIOWriteFloat(stream, dsp_wps->sub_event_sum_threshold);

  FCIOWriteFloats(stream, dsp_wps->tracemap.n_mapped, dsp_wps->gains);
  FCIOWriteFloats(stream, dsp_wps->tracemap.n_mapped, dsp_wps->thresholds);
  FCIOWriteFloats(stream, dsp_wps->tracemap.n_mapped, dsp_wps->lowpass);
  FCIOWriteFloats(stream, dsp_wps->tracemap.n_mapped, dsp_wps->shaping_widths);

  FCIOWriteInt(stream, dsp_wps->dsp_max_margin_front);
  FCIOWriteInt(stream, dsp_wps->dsp_max_margin_back);
  FCIOWriteInts(stream, dsp_wps->tracemap.n_mapped, dsp_wps->dsp_margin_front);
  FCIOWriteInts(stream, dsp_wps->tracemap.n_mapped, dsp_wps->dsp_margin_back);
  FCIOWriteInts(stream, dsp_wps->tracemap.n_mapped, dsp_wps->dsp_start_sample);
  FCIOWriteInts(stream, dsp_wps->tracemap.n_mapped, dsp_wps->dsp_stop_sample);

  return 0;
}
static inline int fcio_get_fspconfig_wps(FCIOStream in, DSPWindowedPeakSum* dsp_wps) {
  if (!dsp_wps)
    return -1;

  fcio_get_fsp_tracemap(in, &dsp_wps->tracemap);

  FCIOReadInt(in, dsp_wps->apply_gain_scaling);
  FCIOReadInt(in, dsp_wps->sum_window_size);
  FCIOReadInt(in, dsp_wps->sum_window_start_sample);
  FCIOReadInt(in, dsp_wps->sum_window_stop_sample);
  FCIOReadFloat(in, dsp_wps->sub_event_sum_threshold);

  FCIOReadFloats(in, FCIOMaxChannels, dsp_wps->gains);
  FCIOReadFloats(in, FCIOMaxChannels, dsp_wps->thresholds);
  FCIOReadFloats(in, FCIOMaxChannels, dsp_wps->lowpass);
  FCIOReadFloats(in, FCIOMaxChannels, dsp_wps->shaping_widths);

  FCIOReadInt(in, dsp_wps->dsp_max_margin_front);
  FCIOReadInt(in, dsp_wps->dsp_max_margin_back);
  FCIOReadInts(in, FCIOMaxChannels, dsp_wps->dsp_margin_front);
  FCIOReadInts(in, FCIOMaxChannels, dsp_wps->dsp_margin_back);
  FCIOReadInts(in, FCIOMaxChannels, dsp_wps->dsp_start_sample);
  FCIOReadInts(in, FCIOMaxChannels, dsp_wps->dsp_stop_sample);

  return 0;
}

// FSPTriggerConfig
static inline int fcio_put_fspconfig_trigger(FCIOStream stream, StreamProcessor* processor) {
  if (!stream || !processor)
    return -1;

  FSPTriggerConfig* config = &processor->triggerconfig;
  FCIOWriteInt(stream, config->hwm_min_multiplicity);
  FCIOWriteInts(stream, processor->dsp_hwm.tracemap.n_mapped, config->hwm_prescale_ratio);
  FCIOWriteInt(stream, config->wps_prescale_ratio);

  FCIOWriteFloat(stream, config->wps_coincident_sum_threshold);
  FCIOWriteFloat(stream, config->wps_sum_threshold);
  FCIOWriteFloat(stream, config->wps_prescale_rate);
  FCIOWriteFloats(stream, processor->dsp_hwm.tracemap.n_mapped, config->hwm_prescale_rate);

  FCIOWrite(stream, sizeof(FSPWriteFlags), &config->enabled_flags);
  fcio_put_fsp_timestamp(stream, &config->pre_trigger_window);
  fcio_put_fsp_timestamp(stream, &config->post_trigger_window);

  FCIOWrite(stream, sizeof(HWMFlags), &config->wps_ref_flags_hwm);
  FCIOWrite(stream, sizeof(CTFlags), &config->wps_ref_flags_ct);
  FCIOWrite(stream, sizeof(WPSFlags), &config->wps_ref_flags_wps);
  FCIOWriteInts(stream, config->n_wps_ref_map_idx, config->wps_ref_map_idx);

  return 0;
}
static inline int fcio_get_fspconfig_trigger(FCIOStream stream, FSPTriggerConfig* config) {
  if (!stream || !config)
    return -1;
  FCIOReadInt(stream, config->hwm_min_multiplicity);
  FCIOReadInts(stream, FCIOMaxChannels, config->hwm_prescale_ratio);
  FCIOReadInt(stream, config->wps_prescale_ratio);

  FCIOReadFloat(stream, config->wps_coincident_sum_threshold);
  FCIOReadFloat(stream, config->wps_sum_threshold);
  FCIOReadFloat(stream, config->wps_prescale_rate);
  FCIOReadFloats(stream, FCIOMaxChannels, config->hwm_prescale_rate);

  FCIORead(stream, sizeof(FSPWriteFlags), &config->enabled_flags);
  fcio_get_fsp_timestamp(stream, &config->pre_trigger_window);
  fcio_get_fsp_timestamp(stream, &config->post_trigger_window);

  FCIORead(stream, sizeof(HWMFlags), &config->wps_ref_flags_hwm);
  FCIORead(stream, sizeof(CTFlags), &config->wps_ref_flags_ct);
  FCIORead(stream, sizeof(WPSFlags), &config->wps_ref_flags_wps);

  int readbytes = FCIOReadInts(stream, FCIOMaxChannels, config->wps_ref_map_idx);
  config->n_wps_ref_map_idx = (readbytes >= 0) ? readbytes/sizeof(int) : 0;

  return 0;
}

// StreamProcessor / FSPConfig
int FCIOPutFSPConfig(FCIOStream output, StreamProcessor* processor)
{
  if (!output || !processor)
    return -1;

  FCIOWriteMessage(output, FCIOFSPConfig);

  /* StreamProcessor config */
  fcio_put_fspconfig_trigger(output, processor);
  fcio_put_fspconfig_buffer(output, processor->buffer);
  fcio_put_fspconfig_hwm(output, &processor->dsp_hwm);
  fcio_put_fspconfig_ct(output, &processor->dsp_ct);
  fcio_put_fspconfig_wps(output, &processor->dsp_wps);

  return FCIOFlush(output);
}
int FCIOGetFSPConfig(FCIOData* input, StreamProcessor* processor)
{
  if (!input || !processor)
    return -1;

  FCIOStream in = FCIOStreamHandle(input);

  fcio_get_fspconfig_trigger(in, &processor->triggerconfig);
  fcio_get_fspconfig_buffer(in, processor->buffer);
  fcio_get_fspconfig_hwm(in, &processor->dsp_hwm);
  fcio_get_fspconfig_ct(in, &processor->dsp_ct);
  fcio_get_fspconfig_wps(in, &processor->dsp_wps);

  return 0;
}

// FSPState / FSPEvent
int FCIOPutFSPEvent(FCIOStream output, StreamProcessor* processor)
{
  if (!output || !processor || !processor->fsp_state)
    return -1;

  FSPState* fsp_state = processor->fsp_state;

  FCIOWriteMessage(output, FCIOFSPEvent);
  FCIOWrite(output, sizeof(fsp_state->write_flags), &fsp_state->write_flags);
  FCIOWrite(output, sizeof(fsp_state->proc_flags), &fsp_state->proc_flags);

  FCIOWrite(output, sizeof(fsp_state->obs.evt), &fsp_state->obs.evt);
  FCIOWrite(output, sizeof(fsp_state->obs.hwm), &fsp_state->obs.hwm);
  FCIOWrite(output, sizeof(fsp_state->obs.wps), &fsp_state->obs.wps);

  FCIOWriteInts(output, fsp_state->obs.ct.multiplicity, fsp_state->obs.ct.trace_idx);
  FCIOWriteUShorts(output, fsp_state->obs.ct.multiplicity, fsp_state->obs.ct.max);

  FCIOWriteInts(output, fsp_state->obs.sub_event_list.size, fsp_state->obs.sub_event_list.start);
  FCIOWriteInts(output, fsp_state->obs.sub_event_list.size, fsp_state->obs.sub_event_list.stop);
  FCIOWriteFloats(output, fsp_state->obs.sub_event_list.size, fsp_state->obs.sub_event_list.wps_max);

  FCIOWriteInts(output, fsp_state->obs.ps.n_hwm_prescaled, fsp_state->obs.ps.hwm_prescaled_trace_idx);

  return FCIOFlush(output);
}
int FCIOGetFSPEvent(FCIOData* input, StreamProcessor* processor)
{
  if (!input || !processor || !processor->fsp_state)
    return -1;

  FSPState* fsp_state = processor->fsp_state;
  int readbytes = 0;

  FCIOStream in = FCIOStreamHandle(input);
  FCIORead(in, sizeof(fsp_state->write_flags), &fsp_state->write_flags);
  FCIORead(in, sizeof(fsp_state->proc_flags), &fsp_state->proc_flags);

  FCIORead(in, sizeof(fsp_state->obs.evt), &fsp_state->obs.evt);
  FCIORead(in, sizeof(fsp_state->obs.hwm), &fsp_state->obs.hwm);
  FCIORead(in, sizeof(fsp_state->obs.wps), &fsp_state->obs.wps);

  readbytes = FCIOReadInts(in, FCIOMaxChannels, fsp_state->obs.ct.trace_idx);
  fsp_state->obs.ct.multiplicity = (readbytes >= 0) ? readbytes/sizeof(int) : 0;
  FCIOReadUShorts(in, FCIOMaxChannels, fsp_state->obs.ct.max);

  readbytes = FCIOReadInts(in, FCIOMaxSamples, fsp_state->obs.sub_event_list.start);
  fsp_state->obs.sub_event_list.size = (readbytes >= 0) ? readbytes/sizeof(int) : 0;
  FCIOReadInts(in, FCIOMaxSamples, fsp_state->obs.sub_event_list.stop);
  FCIOReadFloats(in, FCIOMaxSamples, fsp_state->obs.sub_event_list.wps_max);

  readbytes = FCIOReadInts(in, FCIOMaxChannels, fsp_state->obs.ps.hwm_prescaled_trace_idx);
  fsp_state->obs.ps.n_hwm_prescaled = (readbytes >= 0) ? readbytes/sizeof(int) : 0;

  return 0;
}

// StreamProcessor / FSPStatus
int FCIOPutFSPStatus(FCIOStream output, StreamProcessor* processor)
{
  if (!output || !processor)
    return -1;

  FCIOWriteMessage(output, FCIOFSPStatus);

  FCIOWrite(output, sizeof(FSPStats), &processor->stats);

  return FCIOFlush(output);
}
int FCIOGetFSPStatus(FCIOData* input, StreamProcessor* processor)
{
  if (!input || !processor)
    return -1;

  FCIOStream in = FCIOStreamHandle(input);

  FCIORead(in, sizeof(FSPStats), &processor->stats);

  return 0;
}

int FCIOPutFSP(FCIOStream output, StreamProcessor* processor, int tag)
{

  if (!output || !processor)
    return -1;

  if (tag == 0)
    tag = processor->fsp_state->state->last_tag;

  switch (tag) {
    case FCIOConfig:
    case FCIOFSPConfig:
      return FCIOPutFSPConfig(output, processor);

    case FCIOEvent:
    case FCIOSparseEvent:
    case FCIOEventHeader:
    case FCIOFSPEvent:
      return FCIOPutFSPEvent(output, processor);

    case FCIOStatus:
    case FCIOFSPStatus:
      return FCIOPutFSPStatus(output, processor);
  }
  return -2;
}

void FSPMeasureRecordSizes(StreamProcessor* processor, FCIORecordSizes* sizes)
{
  if (!processor || !processor->fsp_state || !sizes)
    return;

  const char* null_device = "file:///dev/null";
  FCIOWrittenBytes(NULL);
  FCIOStream stream = FCIOConnect(null_device, 'w', 0, 0);
  size_t current_size = 0;
  int rc = 0;

  sizes->protocol = FCIOWrittenBytes(stream);

  rc = FCIOPutFSPConfig(stream, processor);
  if ((current_size = FCIOWrittenBytes(stream)) && !rc)
    sizes->fspconfig = current_size;

  rc = FCIOPutFSPEvent(stream, processor);
  if ((current_size = FCIOWrittenBytes(stream)) && !rc)
    sizes->fspevent = current_size;

  rc = FCIOPutFSPStatus(stream, processor);
  if ((current_size = FCIOWrittenBytes(stream)) && !rc)
    sizes->fspstatus = current_size;

  FCIODisconnect(stream);
}

static inline size_t fsptracemap_size(FSPTraceMap* map)
{
  const size_t frame_header = sizeof(int);
  size_t total_size = 0;
  total_size += frame_header + sizeof(map->format);
  total_size += frame_header + sizeof(*((FSPTraceMap){0}).map) * map->n_mapped;
  total_size += frame_header + sizeof(*((FSPTraceMap){0}).label) * map->n_mapped;
  total_size += frame_header + sizeof(*((FSPTraceMap){0}).enabled) * map->n_enabled;
  return total_size;
}

static inline size_t fsptimestamp_size(void)
{
  const size_t frame_header = sizeof(int);
  return 2 * frame_header + sizeof(((Timestamp){0}).seconds) + sizeof(((Timestamp){0}).nanoseconds);
}

static inline size_t fspconfig_size(StreamProcessor* processor) {
  const size_t frame_header = sizeof(int);
  size_t total_size = 0;

  total_size += frame_header; // tag_size
  total_size += frame_header + sizeof(((FSPTriggerConfig){0}).hwm_min_multiplicity);
  total_size += frame_header + sizeof(*((FSPTriggerConfig){0}).hwm_prescale_ratio) * processor->dsp_hwm.tracemap.n_mapped;
  total_size += frame_header + sizeof(((FSPTriggerConfig){0}).wps_prescale_ratio);
  total_size += frame_header + sizeof(((FSPTriggerConfig){0}).wps_coincident_sum_threshold);
  total_size += frame_header + sizeof(((FSPTriggerConfig){0}).wps_sum_threshold);
  total_size += frame_header + sizeof(((FSPTriggerConfig){0}).wps_prescale_rate);
  total_size += frame_header + sizeof(*((FSPTriggerConfig){0}).hwm_prescale_rate) * processor->dsp_hwm.tracemap.n_mapped;


  total_size += frame_header + sizeof(((FSPTriggerConfig){0}).enabled_flags);
  total_size += fsptimestamp_size();
  total_size += fsptimestamp_size();

  total_size += frame_header + sizeof(((FSPTriggerConfig){0}).wps_ref_flags_hwm);
  total_size += frame_header + sizeof(((FSPTriggerConfig){0}).wps_ref_flags_ct);
  total_size += frame_header + sizeof(((FSPTriggerConfig){0}).wps_ref_flags_wps);
  total_size += frame_header + sizeof(*((FSPTriggerConfig){0}).wps_ref_map_idx) * processor->triggerconfig.n_wps_ref_map_idx;

  total_size += frame_header + sizeof(((FSPBuffer){0}).max_states);
  total_size += fsptimestamp_size();

  total_size += fsptracemap_size(&processor->dsp_hwm.tracemap);
  total_size += frame_header + sizeof(*((DSPHardwareMultiplicity){0}).fpga_energy_threshold_adc) * processor->dsp_hwm.tracemap.n_mapped;

  total_size += fsptracemap_size(&processor->dsp_ct.tracemap);
  total_size += frame_header + sizeof(*((DSPChannelThreshold){0}).thresholds) * processor->dsp_ct.tracemap.n_mapped;

  total_size += fsptracemap_size(&processor->dsp_wps.tracemap);

  total_size += frame_header + sizeof(((DSPWindowedPeakSum){0}).apply_gain_scaling);
  total_size += frame_header + sizeof(((DSPWindowedPeakSum){0}).sum_window_size);
  total_size += frame_header + sizeof(((DSPWindowedPeakSum){0}).sum_window_start_sample);
  total_size += frame_header + sizeof(((DSPWindowedPeakSum){0}).sum_window_stop_sample);
  total_size += frame_header + sizeof(((DSPWindowedPeakSum){0}).sub_event_sum_threshold);

  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).gains) * processor->dsp_wps.tracemap.n_mapped;
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).thresholds) * processor->dsp_wps.tracemap.n_mapped;
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).lowpass) * processor->dsp_wps.tracemap.n_mapped;
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).shaping_widths) * processor->dsp_wps.tracemap.n_mapped;

  total_size += frame_header + sizeof(((DSPWindowedPeakSum){0}).dsp_max_margin_front);
  total_size += frame_header + sizeof(((DSPWindowedPeakSum){0}).dsp_max_margin_back);
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).dsp_margin_front) * processor->dsp_wps.tracemap.n_mapped;
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).dsp_margin_back) * processor->dsp_wps.tracemap.n_mapped;
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).dsp_start_sample) * processor->dsp_wps.tracemap.n_mapped;
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).dsp_stop_sample) * processor->dsp_wps.tracemap.n_mapped;
  return total_size;
}

static inline size_t fspevent_size(FSPState* fspstate) {
  const size_t frame_header = sizeof(int);
  size_t total_size = 0;

  total_size += frame_header; // tag_size
  total_size += frame_header + sizeof(FSPWriteFlags);
  total_size += frame_header + sizeof(FSPProcessorFlags);
  total_size += frame_header + sizeof(evt_obs);
  total_size += frame_header + sizeof(hwm_obs);
  total_size += frame_header + sizeof(wps_obs);

  total_size += frame_header + sizeof(*((ct_obs){0}).trace_idx) * fspstate->obs.ct.multiplicity;
  total_size += frame_header + sizeof(*((ct_obs){0}).max) * fspstate->obs.ct.multiplicity;
  total_size += frame_header + sizeof(*((SubEventList){0}).start) * fspstate->obs.sub_event_list.size;
  total_size += frame_header + sizeof(*((SubEventList){0}).stop) * fspstate->obs.sub_event_list.size;
  total_size += frame_header + sizeof(*((SubEventList){0}).wps_max) * fspstate->obs.sub_event_list.size;
  total_size += frame_header + sizeof(*((prescale_obs){0}).hwm_prescaled_trace_idx) * fspstate->obs.ps.n_hwm_prescaled;

  return total_size;
}

static inline size_t fspstatus_size(void) {
  const size_t frame_header = sizeof(int);
  size_t total_size = 0;

  total_size += frame_header; // tag_size
  total_size += frame_header + sizeof(FSPStats);

  return total_size;
}

void FSPCalculateRecordSizes(StreamProcessor* processor, FCIORecordSizes* sizes)
{
  if (!processor || !processor->fsp_state || !sizes)
    return;

  sizes->protocol = sizeof(int) + TMIO_PROTOCOL_SIZE;
  sizes->fspconfig = fspconfig_size(processor);
  sizes->fspevent = fspevent_size(processor->fsp_state);
  sizes->fspstatus = fspstatus_size();
}
