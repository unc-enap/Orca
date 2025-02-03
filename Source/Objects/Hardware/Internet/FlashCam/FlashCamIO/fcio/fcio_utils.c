#include "fcio_utils.h"
#include "fcio.h"

#include <bufio.h>
#include <tmio.h>

int FCIOSetMemField(FCIOStream stream, void *mem_addr, size_t mem_size) {
  if (!mem_addr)
    return -1;
  // bufio_set_mem_field check if the stream was opened using mem://
  // returns 0 on success, 1 on error.
  return bufio_set_mem_field((bufio_stream*)tmio_stream_handle((tmio_stream*)stream), (char*)mem_addr, mem_size);
}

size_t FCIOStreamBytes(FCIOStream stream, int direction, size_t offset)
{
  if (!stream)
      return 0;
  tmio_stream* tmio = (tmio_stream*)stream;
  switch(direction) {
      case 'w': return tmio->byteswritten - offset;
      case 'r': return tmio->bytesread - offset;
      case 's': return tmio->bytesskipped - offset;
      default: return 0;
  }
}

size_t FCIOWrittenBytes(FCIOStream stream)
{
  static size_t written = 0;
  if (!stream)
    return written = 0;
  tmio_stream* tmio = (tmio_stream*)stream;

  size_t new_bytes = tmio->byteswritten - written;
  written = tmio->byteswritten;
  return new_bytes;
}

void FCIOMeasureRecordSizes(FCIOData* data, FCIORecordSizes* sizes)
{
  if (!data || !sizes)
    return;
  const char* null_device = "file:///dev/null";

  FCIOWrittenBytes(NULL);
  FCIOStream stream = FCIOConnect(null_device, 'w', 0, 0);
  sizes->protocol = FCIOWrittenBytes(stream);

  size_t current_size = 0;
  int rc = 0;

  rc = FCIOPutConfig(stream, data);
  if ((current_size = FCIOWrittenBytes(stream)) && !rc)
    sizes->config = current_size;

  rc = FCIOPutEvent(stream, data);
  if ((current_size = FCIOWrittenBytes(stream)) && !rc)
    sizes->event = current_size;

  rc = FCIOPutStatus(stream, data);
  if ((current_size = FCIOWrittenBytes(stream)) && !rc)
    sizes->status = current_size;

  rc = FCIOPutEventHeader(stream, data);
  if ((current_size = FCIOWrittenBytes(stream)) && !rc)
    sizes->eventheader = current_size;

  rc = FCIOPutSparseEvent(stream, data);
  if ((current_size = FCIOWrittenBytes(stream)) && !rc)
    sizes->sparseevent = current_size;

  FCIODisconnect(stream);
}


static inline size_t event_size(FCIOTag tag, const fcio_event* event, const fcio_config* config)
{
  const size_t frame_header = sizeof(int);
  size_t total_size = 0;

  total_size += frame_header; // tag_size
  total_size += frame_header + sizeof(((fcio_event){0}).type); // type_size
  total_size += frame_header + sizeof(((fcio_event){0}).pulser); // pulser_size
  total_size += frame_header + sizeof(*((fcio_event){0}).timeoffset) * event->timeoffset_size; // timeoffset_size
  total_size += frame_header + sizeof(*((fcio_event){0}).timestamp) * event->timestamp_size; // timestamp_size
  total_size += frame_header + sizeof(*((fcio_event){0}).deadregion) * event->deadregion_size; // deadregion_size
  switch (tag) {
    case FCIOEvent:
    total_size += frame_header + sizeof(*((fcio_event){0}).traces) * ((config->adcs+config->triggers) * (config->eventsamples+2)); // traces
    break;
    case FCIOSparseEvent:
    total_size += frame_header + sizeof(((fcio_event){0}).num_traces); // num_traces
    total_size += frame_header + sizeof(*((fcio_event){0}).trace_list) * event->num_traces; // trace_list
    total_size += event->num_traces * (frame_header + (config->eventsamples+2) * sizeof(*((fcio_event){0}).traces)); // individual traces
    break;
    case FCIOEventHeader:
    total_size += frame_header + sizeof(*((fcio_event){0}).trace_list) * event->num_traces; // trace_list
    total_size += frame_header + sizeof(unsigned short) * event->num_traces * 2; // headerbuffer
    break;
    default:
      return 0;
  }
  return total_size;
}

static inline size_t config_size(const fcio_config* config)
{
  const size_t frame_header = sizeof(int);
  size_t total_size = 0;

  total_size += frame_header; // tag_size
  total_size += frame_header + sizeof(((fcio_config){0}).adcs);
  total_size += frame_header + sizeof(((fcio_config){0}).triggers);
  total_size += frame_header + sizeof(((fcio_config){0}).eventsamples);
  total_size += frame_header + sizeof(((fcio_config){0}).blprecision);
  total_size += frame_header + sizeof(((fcio_config){0}).sumlength);
  total_size += frame_header + sizeof(((fcio_config){0}).adcbits);
  total_size += frame_header + sizeof(((fcio_config){0}).mastercards);
  total_size += frame_header + sizeof(((fcio_config){0}).triggercards);
  total_size += frame_header + sizeof(((fcio_config){0}).adccards);
  total_size += frame_header + sizeof(((fcio_config){0}).gps);
  total_size += frame_header + sizeof(*((fcio_config){0}).tracemap) * (config->adcs+config->triggers);
  total_size += frame_header + sizeof(((fcio_config){0}).streamid);
  return total_size;
}

static inline size_t status_size(const fcio_status* status)
{
  const size_t frame_header = sizeof(int);
  size_t total_size = 0;

  total_size += frame_header; // tag_size
  total_size += frame_header + sizeof(((fcio_status){0}).status);
  total_size += frame_header + sizeof(*((fcio_status){0}).statustime) * 10;
  total_size += frame_header + sizeof(((fcio_status){0}).cards);
  total_size += frame_header + sizeof(((fcio_status){0}).size);
  total_size += (frame_header + status->size) * status->cards;
  return total_size;
}


void FCIOCalculateRecordSizes(FCIOData* data, FCIORecordSizes* sizes)
{
  if (!data || !sizes)
    return;

  const size_t frame_header = sizeof(int);

  sizes->protocol = TMIO_PROTOCOL_SIZE + frame_header;
  sizes->config = config_size(&data->config);
  sizes->event = event_size(FCIOEvent, &data->event, &data->config);
  sizes->status = status_size(&data->status);
  sizes->eventheader = event_size(FCIOEventHeader, &data->event, &data->config);
  sizes->sparseevent = event_size(FCIOSparseEvent, &data->event, &data->config);
}

void FCIOStateCalculateRecordSizes(FCIOState* state, FCIORecordSizes* sizes)
{
    if (!state || !sizes)
      return;

    const size_t frame_header = sizeof(int);

    sizes->protocol = TMIO_PROTOCOL_SIZE + frame_header;
    if (state->config)
        sizes->config = config_size(state->config);

    if (state->status)
        sizes->status = status_size(state->status);

    if (state->config && state->event) {
        sizes->event = event_size(FCIOEvent, state->event, state->config);
        sizes->eventheader = event_size(FCIOEventHeader, state->event, state->config);
        sizes->sparseevent = event_size(FCIOSparseEvent, state->event, state->config);
    }
}

void FCIOPrintRecordSizes(FCIORecordSizes sizes)
{
  fprintf(stderr, "..protocol    %zu bytes\n", sizes.protocol);
  fprintf(stderr, "..config      %zu bytes\n", sizes.config);
  fprintf(stderr, "..event       %zu bytes\n", sizes.event);
  fprintf(stderr, "..sparseevent %zu bytes\n", sizes.sparseevent);
  fprintf(stderr, "..eventheader %zu bytes\n", sizes.eventheader);
  fprintf(stderr, "..status      %zu bytes\n", sizes.status);
  fprintf(stderr, "..fspconfig   %zu bytes\n", sizes.fspconfig);
  fprintf(stderr, "..fspevent    %zu bytes\n", sizes.fspevent);
  fprintf(stderr, "..fspstatus   %zu bytes\n", sizes.fspstatus);
}

const char* FCIOTagStr(int tag)
{
  switch (tag) {
    case FCIOConfig: return "FCIOConfig";
    case FCIOCalib: return "FCIOCalib";
    case FCIOEvent: return "FCIOEvent";
    case FCIOStatus: return "FCIOStatus";
    case FCIORecEvent: return "FCIORecEvent";
    case FCIOSparseEvent: return "FCIOSparseEvent";
    case FCIOEventHeader: return "FCIOEventHeader";
    case FCIOFSPConfig: return "FCIOFSPConfig";
    case FCIOFSPEvent: return "FCIOFSPEvent";
    case FCIOFSPStatus: return "FCIOFSPStatus";
    case 0: return "EOF";
    default: return "ERROR";
  }
}
