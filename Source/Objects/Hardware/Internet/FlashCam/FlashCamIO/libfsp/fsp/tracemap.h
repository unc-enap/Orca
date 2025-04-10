#pragma once

#include <fcio.h>
#include <string.h>

typedef struct {
  int format; // contains the format of the channel map. For processors it must be converted to trace_idx

  // this struct provides back-and-forth lookups between the fcio_event trace_list array
  // and the list of trace_idx handled by this processor.
  // n_mapped is equal to the number of trace assigned to this processor
  // and map contains a list of trace_idx's
  //
  // the enabled array has the same sizes as fcio_config.tracemap
  // with entrys either -1 for traces not handled by this processor or the index into the `map` array
  // which allows a loopup of the correct trace_idx

  int map[FCIOMaxChannels]; // the list of assigned traces for this processor, up to n_mapped
  int n_mapped; // the number of assigned traces, applies to trace_list

  // reverse lookup for mapped channels.
  int enabled[FCIOMaxChannels]; // a list of map_idx, index with trace_idx from fcio_event.trace_list
  int n_enabled; // the total number of traces available, is equal to fcio_config.adcs. If 0 the processer was not enabled.

   // a human readable label, index similar to `map`.
  char label[FCIOMaxChannels][8];

} FSPTraceMap;

typedef enum FSPTraceFormat {
  FSPTraceFormatUnkown = 0,
  FCIO_TRACE_INDEX_FORMAT = 1,
  FCIO_TRACE_MAP_FORMAT = 2,
  L200_RAWID_FORMAT = 3

} FSPTraceFormat;

static inline int is_known_channelmap_format(FSPTraceFormat format)
{
  return (format != FSPTraceFormatUnkown) ? 1 : 0;
}

static inline const char* channelmap_fmt2str(FSPTraceFormat format)
{
  switch (format) {
    case FCIO_TRACE_INDEX_FORMAT:
      return "fcio-trace-idx";
    case FCIO_TRACE_MAP_FORMAT:
      return "fcio-trace-map";
    case L200_RAWID_FORMAT:
      return "l200-rawid";
    default:
      return "";
  }
}

static inline FSPTraceFormat channelmap_str2fmt(const char* str)
{
  FSPTraceFormat ret = FSPTraceFormatUnkown;
  if (strncmp(str, "fcio-trace-idx", 14) == 0)
    ret = FCIO_TRACE_INDEX_FORMAT;
  else if (strncmp(str, "fcio-trace-map", 14) == 0)
    ret = FCIO_TRACE_MAP_FORMAT;
  else if (strncmp(str, "l200-rawid", 10) == 0)
    ret = L200_RAWID_FORMAT;
  else
    ret = FSPTraceFormatUnkown;
  return ret;
}

static inline unsigned int rawid2tracemap(int input) {
  // int fcid = input / 1000000;
  unsigned int board_id = (input / 100) % 10000;
  unsigned int fc_input = (input % 100);
  return (board_id << 16) + fc_input;
}

static inline int tracemap2rawid(unsigned int input, int listener) {
  return listener * 1000000 + (input >> 16) * 100 + (input & 0xffff);
}

static inline int convert2rawid(int ninput, int *input, FSPTraceFormat format, unsigned int *tracemap, int listener) {
  switch (format) {
    case FCIO_TRACE_MAP_FORMAT: {
      for (int i = 0; i < ninput; i++) {
        unsigned int to_convert = input[i];
        int found = 0;
        for (int j = 0; j < FCIOMaxChannels || tracemap[j]; j++) {
          if (to_convert == tracemap[j]) {
            input[i] = tracemap2rawid(tracemap[j], listener);
            found = 1;
            break;
          }
        }
        if (!found) return i;
      }
      break;
    }
    default: {
      return 0;
    }
  }
  return 1;
}

static inline int convert2traceidx(FSPTraceMap* map, unsigned int *fcio_tracemap) {
  /*  quote from fcio.c to guide the reader:
      > unsigned int tracemap[FCIOMaxChannels]; // trace map identifiers - fadc/triggercard addresses and channels
      >                                         // stores the FADC and Trigger card addresses as follows: (address <<
     16) + adc channel (channel number on the card) quote from src/pygama/raw/orca/orca_flashcam.py: the fsp library
     does not know about multiple flashcam streams, so fcid is discarded: > def get_key(fcid, board_id, fc_input: int)
     -> int: >   return fcid * 1000000 + board_id * 100 + fc_input
  */
  switch (map->format) {
    // fcio-tracemap
    case FCIO_TRACE_MAP_FORMAT: {
      for (int i = 0; i < map->n_mapped; i++) {
        unsigned int to_convert = map->map[i];
        int found = 0;
        for (int j = 0; j < FCIOMaxChannels && fcio_tracemap[j]; j++) {
          if (to_convert == fcio_tracemap[j]) {
            map->map[i] = j;
            map->enabled[j] = i;
            found = 1;
            break;
          }
        }
        if (!found) return 0;
      }
      break;
    }
    // rawid
    case L200_RAWID_FORMAT: {
      for (int i = 0; i < map->n_mapped; i++) {
        unsigned int to_convert = map->map[i];
        int found = 0;
        for (int j = 0; j < FCIOMaxChannels && fcio_tracemap[j]; j++) {
          if (rawid2tracemap(to_convert) == fcio_tracemap[j]) {
            map->map[i] = j;
            map->enabled[j] = i;
            found = 1;
            break;
          }
        }
        if (!found) return 0;
      }
      break;
    }
    case FCIO_TRACE_INDEX_FORMAT: {
      for (int i = 0; i < map->n_mapped; i++) {
        if (map->map[i] < FCIOMaxChannels && fcio_tracemap[map->map[i]]) {
          map->map[i] = i;
          map->enabled[i] = i;
        } else {
          return 0;
        }
      }
      break;
    }

    default:
      return 0;
  }
  return 1;
}
