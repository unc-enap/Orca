#pragma once

#include <fcio.h>
#include <string.h>

typedef enum FSPChannelFormat {
  FCIO_TRACE_INDEX_FORMAT = 0,
  FCIO_TRACE_MAP_FORMAT = 1,
  L200_RAWID_FORMAT = 2,
  FSPChannelFormatUnkown = 3

} FSPChannelFormat;

static inline int is_known_channelmap_format(FSPChannelFormat format)
{
  unsigned int form = format;
  if (form < FSPChannelFormatUnkown) {
    return 1;
  } else {
    return 0;
  }
}

static inline const char* channelmap_fmt2str(FSPChannelFormat format)
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

static inline FSPChannelFormat channelmap_str2fmt(const char* str)
{
  FSPChannelFormat ret = FSPChannelFormatUnkown;
  if (strncmp(str, "fcio-trace-idx", 14) == 0)
    ret = FCIO_TRACE_INDEX_FORMAT;
  else if (strncmp(str, "fcio-trace-map", 14) == 0)
    ret = FCIO_TRACE_MAP_FORMAT;
  else if (strncmp(str, "l200-rawid", 10) == 0)
    ret = L200_RAWID_FORMAT;
  else
    ret = FSPChannelFormatUnkown;
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

static inline int convert2rawid(int ninput, int *input, FSPChannelFormat format, unsigned int *tracemap, int listener) {
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

static inline int convert2traceidx(int ninput, int *input, FSPChannelFormat format, unsigned int *tracemap) {
  /*  quote from fcio.c to guide the reader:
      > unsigned int tracemap[FCIOMaxChannels]; // trace map identifiers - fadc/triggercard addresses and channels
      >                                         // stores the FADC and Trigger card addresses as follows: (address <<
     16) + adc channel (channel number on the card) quote from src/pygama/raw/orca/orca_flashcam.py: the fsp library
     does not know about multiple flashcam streams, so fcid is discarded: > def get_key(fcid, board_id, fc_input: int)
     -> int: >   return fcid * 1000000 + board_id * 100 + fc_input
  */
  switch (format) {
    // fcio-tracemap
    case FCIO_TRACE_MAP_FORMAT: {
      for (int i = 0; i < ninput; i++) {
        unsigned int to_convert = input[i];
        int found = 0;
        for (int j = 0; j < FCIOMaxChannels || tracemap[j]; j++) {
          if (to_convert == tracemap[j]) {
            input[i] = j;
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
      for (int i = 0; i < ninput; i++) {
        unsigned int to_convert = input[i];
        int found = 0;
        for (int j = 0; j < FCIOMaxChannels || tracemap[j]; j++) {
          if (rawid2tracemap(to_convert) == tracemap[j]) {
            input[i] = j;
            found = 1;
            break;
          }
        }
        if (!found) return 0;
      }
      break;
    }
    case FCIO_TRACE_INDEX_FORMAT:
      return 1;

    default:
      return 0;
  }
  return 1;
}
