#include "io_fcio.h"

#include <fcio_utils.h>
#include <tmio.h>

static inline int fcio_put_fspconfig_buffer(FCIOStream stream, FSPBuffer* buffer) {
  if (!stream || !buffer)
    return -1;
  FCIOWriteInt(stream, buffer->max_states);
  FCIOWrite(stream, sizeof(buffer->buffer_window.seconds), &buffer->buffer_window.seconds);
  FCIOWrite(stream, sizeof(buffer->buffer_window.nanoseconds), &buffer->buffer_window.nanoseconds);
  return 0;
}

static inline int fcio_put_fspconfig_hwm(FCIOStream stream, DSPHardwareMajority* dsp_hwm) {
  if (!stream || !dsp_hwm)
    return -1;
  FCIOWriteInts(stream, dsp_hwm->ntraces, dsp_hwm->tracemap);
  FCIOWriteUShorts(stream, dsp_hwm->ntraces, dsp_hwm->fpga_energy_threshold_adc);

  return 0;
}

static inline int fcio_put_fspconfig_ct(FCIOStream stream, DSPChannelThreshold* dsp_ct) {
  if (!stream || !dsp_ct)
    return -1;
  FCIOWriteInts(stream, dsp_ct->ntraces, dsp_ct->tracemap);
  FCIOWriteUShorts(stream, dsp_ct->ntraces, dsp_ct->thresholds);

  return 0;
}

static inline int fcio_put_fspconfig_wps(FCIOStream stream, DSPWindowedPeakSum* dsp_wps) {
  if (!stream || !dsp_wps)
    return -1;
  FCIOWriteInt(stream, dsp_wps->apply_gain_scaling);
  FCIOWriteInt(stream, dsp_wps->coincidence_window);
  FCIOWriteInt(stream, dsp_wps->sum_window_start_sample);
  FCIOWriteInt(stream, dsp_wps->sum_window_stop_sample);
  FCIOWriteFloat(stream, dsp_wps->coincidence_threshold);

  FCIOWriteInts(stream, dsp_wps->ntraces, dsp_wps->tracemap);
  FCIOWriteFloats(stream, dsp_wps->ntraces, dsp_wps->gains);
  FCIOWriteFloats(stream, dsp_wps->ntraces, dsp_wps->thresholds);
  FCIOWriteFloats(stream, dsp_wps->ntraces, dsp_wps->lowpass);
  FCIOWriteFloats(stream, dsp_wps->ntraces, dsp_wps->shaping_widths);

  FCIOWriteInt(stream, dsp_wps->dsp_pre_max_samples);
  FCIOWriteInt(stream, dsp_wps->dsp_post_max_samples);
  FCIOWriteInts(stream, dsp_wps->ntraces, dsp_wps->dsp_pre_samples);
  FCIOWriteInts(stream, dsp_wps->ntraces, dsp_wps->dsp_post_samples);
  FCIOWriteInts(stream, dsp_wps->ntraces, dsp_wps->dsp_start_sample);
  FCIOWriteInts(stream, dsp_wps->ntraces, dsp_wps->dsp_stop_sample);

  return 0;
}

int FCIOPutFSPConfig(FCIOStream output, StreamProcessor* processor)
{
  if (!output || !processor)
    return -1;

  FCIOWriteMessage(output, FCIOFSPConfig);

  /* StreamProcessor config */
  FCIOWrite(output, sizeof(processor->config), &processor->config);

  fcio_put_fspconfig_buffer(output, processor->buffer);
  fcio_put_fspconfig_hwm(output, processor->dsp_hwm);
  fcio_put_fspconfig_ct(output, processor->dsp_ct);
  fcio_put_fspconfig_wps(output, processor->dsp_wps);

  return FCIOFlush(output);
}


static inline int fcio_get_fspconfig_buffer(FCIOStream in, FSPBuffer* buffer) {
  if (!buffer)
    return -1;
  FCIOReadInt(in, buffer->max_states);
  FCIORead(in, sizeof(buffer->buffer_window.seconds), &buffer->buffer_window.seconds);
  FCIORead(in, sizeof(buffer->buffer_window.nanoseconds), &buffer->buffer_window.nanoseconds);
  return 0;
}

static inline int fcio_get_fspconfig_hwm(FCIOStream in, DSPHardwareMajority* dsp_hwm) {
  if (!dsp_hwm)
    return -1;
  dsp_hwm->ntraces = FCIOReadInts(in, FCIOMaxChannels, dsp_hwm->tracemap) / sizeof(*dsp_hwm->tracemap);
  FCIOReadUShorts(in, FCIOMaxChannels, dsp_hwm->fpga_energy_threshold_adc);

  return 0;
}

static inline int fcio_get_fspconfig_ct(FCIOStream in, DSPChannelThreshold* dsp_ct) {
  if (!dsp_ct)
    return -1;
  dsp_ct->ntraces = FCIOReadInts(in, FCIOMaxChannels, dsp_ct->tracemap) / sizeof(*dsp_ct->tracemap);
  FCIOReadUShorts(in, FCIOMaxChannels, dsp_ct->thresholds);

  return 0;
}

static inline int fcio_get_fspconfig_wps(FCIOStream in, DSPWindowedPeakSum* dsp_wps) {
  if (!dsp_wps)
    return -1;
  FCIOReadInt(in, dsp_wps->apply_gain_scaling);
  FCIOReadInt(in, dsp_wps->coincidence_window);
  FCIOReadInt(in, dsp_wps->sum_window_start_sample);
  FCIOReadInt(in, dsp_wps->sum_window_stop_sample);
  FCIOReadFloat(in, dsp_wps->coincidence_threshold);

  dsp_wps->ntraces = FCIOReadInts(in, FCIOMaxChannels, dsp_wps->tracemap) / sizeof(*dsp_wps->tracemap);
  FCIOReadFloats(in, FCIOMaxChannels, dsp_wps->gains);
  FCIOReadFloats(in, FCIOMaxChannels, dsp_wps->thresholds);
  FCIOReadFloats(in, FCIOMaxChannels, dsp_wps->lowpass);
  FCIOReadFloats(in, FCIOMaxChannels, dsp_wps->shaping_widths);

  FCIOReadInt(in, dsp_wps->dsp_pre_max_samples);
  FCIOReadInt(in, dsp_wps->dsp_post_max_samples);
  FCIOReadInts(in, FCIOMaxChannels, dsp_wps->dsp_pre_samples);
  FCIOReadInts(in, FCIOMaxChannels, dsp_wps->dsp_post_samples);
  FCIOReadInts(in, FCIOMaxChannels, dsp_wps->dsp_start_sample);
  FCIOReadInts(in, FCIOMaxChannels, dsp_wps->dsp_stop_sample);

  return 0;
}

static inline int fcio_get_fspconfig(FCIOStream in, StreamProcessor* processor) {
  if (!in || !processor)
    return -1;
  /* StreamProcessor config */
  FCIORead(in, sizeof(processor->config), &processor->config);

  fcio_get_fspconfig_buffer(in, processor->buffer);
  fcio_get_fspconfig_hwm(in, processor->dsp_hwm);
  fcio_get_fspconfig_ct(in, processor->dsp_ct);
  fcio_get_fspconfig_wps(in, processor->dsp_wps);

  return 0;
}


int FCIOGetFSPConfig(FCIOData* input, StreamProcessor* processor)
{
  if (!input || !processor)
    return -1;

  FCIOStream in = FCIOStreamHandle(input);

  return fcio_get_fspconfig(in, processor);
}

static inline int fcio_get_fspevent(FCIOStream in, FSPState* fsp_state) {
  if (!in || !fsp_state)
    return -1;

  FCIORead(in, sizeof(fsp_state->write_flags), &fsp_state->write_flags);
  FCIORead(in, sizeof(fsp_state->proc_flags), &fsp_state->proc_flags);

  FCIORead(in, sizeof(fsp_state->obs.evt), &fsp_state->obs.evt);
  FCIORead(in, sizeof(fsp_state->obs.hwm), &fsp_state->obs.hwm);
  FCIORead(in, sizeof(fsp_state->obs.wps), &fsp_state->obs.wps);

  fsp_state->obs.ct.multiplicity = FCIOReadInts(in, FCIOMaxChannels, fsp_state->obs.ct.trace_idx)/sizeof(int);
  FCIOReadUShorts(in, FCIOMaxChannels, fsp_state->obs.ct.max);

  fsp_state->obs.sub_event_list.size = FCIOReadInts(in, FCIOMaxSamples, fsp_state->obs.sub_event_list.start)/sizeof(int);
  FCIOReadInts(in, FCIOMaxSamples, fsp_state->obs.sub_event_list.stop);
  FCIOReadFloats(in, FCIOMaxSamples, fsp_state->obs.sub_event_list.wps_max);

  return 0;
}

int FCIOGetFSPEvent(FCIOData* input, FSPState* fsp_state)
{
  if (!input || !fsp_state)
    return -1;

  FCIOStream in = FCIOStreamHandle(input);

  return fcio_get_fspevent(in, fsp_state);
}

int FCIOPutFSPEvent(FCIOStream output, FSPState* fsp_state)
{
  if (!output || !fsp_state)
    return -1;

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

  return FCIOFlush(output);
}

static inline int fcio_get_fspstatus(FCIOStream in, StreamProcessor* processor) {
  if (!in || !processor)
    return -1;

  FCIORead(in, sizeof(FSPStats), processor->stats);

  return 0;
}


int FCIOGetFSPStatus(FCIOData* input, StreamProcessor* processor)
{
  if (!input || !processor)
    return -1;

  FCIOStream in = FCIOStreamHandle(input);

  return fcio_get_fspstatus(in, processor);
}

int FCIOPutFSPStatus(FCIOStream output, StreamProcessor* processor)
{
  if (!output || !processor)
    return -1;

  FCIOWriteMessage(output, FCIOFSPStatus);

  FCIOWrite(output, sizeof(FSPStats), processor->stats);

  return FCIOFlush(output);
}

int FCIOPutFSP(FCIOStream output, StreamProcessor* processor, int tag)
{

  if (!output || !processor)
    return -1;

  if (tag == 0)
    tag = processor->buffer->last_fsp_state->state->last_tag;

  switch (tag) {
    case FCIOConfig:
    case FCIOFSPConfig:
      return FCIOPutFSPConfig(output, processor);

    case FCIOEvent:
    case FCIOSparseEvent:
    case FCIOEventHeader:
    case FCIOFSPEvent:
      return FCIOPutFSPEvent(output, processor->buffer->last_fsp_state);

    case FCIOStatus:
    case FCIOFSPStatus:
      return FCIOPutFSPStatus(output, processor);
  }
  return -2;
}

void FSPMeasureRecordSizes(StreamProcessor* processor, FSPState* fspstate, FCIORecordSizes* sizes)
{
  if (!processor || !fspstate || !sizes)
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

  rc = FCIOPutFSPEvent(stream, fspstate);
  if ((current_size = FCIOWrittenBytes(stream)) && !rc)
    sizes->fspevent = current_size;

  rc = FCIOPutFSPStatus(stream, processor);
  if ((current_size = FCIOWrittenBytes(stream)) && !rc)
    sizes->fspstatus = current_size;

  FCIODisconnect(stream);
}


static inline size_t fspconfig_size(StreamProcessor* processor) {
  const size_t frame_header = sizeof(int);
  size_t total_size = 0;

  total_size += frame_header; // tag_size
  total_size += frame_header + sizeof(((FSPConfig){0}));

  total_size += frame_header + sizeof(((FSPBuffer){0}).max_states);
  total_size += frame_header + sizeof(((Timestamp){0}).seconds);
  total_size += frame_header + sizeof(((Timestamp){0}).nanoseconds);

  total_size += frame_header + sizeof(*((DSPHardwareMajority){0}).tracemap) * processor->dsp_hwm->ntraces;
  total_size += frame_header + sizeof(*((DSPHardwareMajority){0}).fpga_energy_threshold_adc) * processor->dsp_hwm->ntraces;

  total_size += frame_header + sizeof(*((DSPChannelThreshold){0}).tracemap) * processor->dsp_ct->ntraces;
  total_size += frame_header + sizeof(*((DSPChannelThreshold){0}).thresholds) * processor->dsp_ct->ntraces;

  total_size += frame_header + sizeof(((DSPWindowedPeakSum){0}).apply_gain_scaling);
  total_size += frame_header + sizeof(((DSPWindowedPeakSum){0}).coincidence_window);
  total_size += frame_header + sizeof(((DSPWindowedPeakSum){0}).sum_window_start_sample);
  total_size += frame_header + sizeof(((DSPWindowedPeakSum){0}).sum_window_stop_sample);
  total_size += frame_header + sizeof(((DSPWindowedPeakSum){0}).coincidence_threshold);

  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).tracemap) * processor->dsp_wps->ntraces;
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).gains) * processor->dsp_wps->ntraces;
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).thresholds) * processor->dsp_wps->ntraces;
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).lowpass) * processor->dsp_wps->ntraces;
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).shaping_widths) * processor->dsp_wps->ntraces;

  total_size += frame_header + sizeof(((DSPWindowedPeakSum){0}).dsp_pre_max_samples);
  total_size += frame_header + sizeof(((DSPWindowedPeakSum){0}).dsp_post_max_samples);
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).dsp_pre_samples) * processor->dsp_wps->ntraces;
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).dsp_post_samples) * processor->dsp_wps->ntraces;
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).dsp_start_sample) * processor->dsp_wps->ntraces;
  total_size += frame_header + sizeof(*((DSPWindowedPeakSum){0}).dsp_stop_sample) * processor->dsp_wps->ntraces;
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

  return total_size;
}

static inline size_t fspstatus_size(void) {
  const size_t frame_header = sizeof(int);
  size_t total_size = 0;

  total_size += frame_header; // tag_size
  total_size += frame_header + sizeof(FSPStats);

  return total_size;
}

void FSPCalculateRecordSizes(StreamProcessor* processor, FSPState* fspstate, FCIORecordSizes* sizes)
{
  if (!processor || !fspstate || !sizes)
    return;

  sizes->fspconfig = fspconfig_size(processor);
  sizes->fspevent = fspevent_size(fspstate);
  sizes->fspstatus = fspstatus_size();
}
