#pragma once

#include <string.h>

static inline int get_tracemap_for_subsystem(int max_channels, int *channels, const char *subsystem) {
  if (strncmp(subsystem, "argon", 5) == 0) {
    const int last_card = 10;
    const int max_card_slots = 6;  // 16-bit firmware
    const int baseaddress = 0x200;

    int nchannels = 0;
    for (int i = 1; i <= last_card; i++) {
      int card_address = baseaddress + i * 0x10;  // 0x10 == 16
      for (int j = 0; j < max_card_slots && nchannels < max_channels; j++) {
        if (i == 1 && j < 2) {
          /* First 2 Channels not connected */
          continue;
        }
        channels[nchannels++] = (card_address << 16) + j;
      }
    }
    return nchannels;
  }
  return 0;
}

static inline int get_channelmap_format(const char *channelmap_format) {
  if (!channelmap_format || (strncmp(channelmap_format, "fcio-trace-index", 16) == 0)) {
    return 0;
  } else if (channelmap_format && strncmp(channelmap_format, "fcio-tracemap", 13) == 0) {
    return 1;
  } else if (channelmap_format && strncmp(channelmap_format, "rawid", 5) == 0) {
    return 2;
  } else {
    return -1;
  }
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

static inline int convert_rawid(int ninput, int *input, int format, unsigned int *tracemap, int listener) {
  switch (format) {
    case 1: {
      for (int i = 0; i < ninput; i++) {
        unsigned int to_convert = input[i];
        int found = 0;
        for (int j = 0; j < FCIOMaxChannels || tracemap[j]; j++) {
          if (to_convert == tracemap[j]) {
            input[i] = tracemap2rawid(tracemap[j], listener);
            ;
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

static inline int convert_trace_idx(int ninput, int *input, int format, unsigned int *tracemap) {
  /*  quote from fcio.c to guide the reader:
      > unsigned int tracemap[FCIOMaxChannels]; // trace map identifiers - fadc/triggercard addresses and channels
      >                                         // stores the FADC and Trigger card addresses as follows: (address <<
     16) + adc channel (channel number on the card) quote from src/pygama/raw/orca/orca_flashcam.py: the lpp library
     does not know about multiple flashcam streams, so fcid is discarded: > def get_key(fcid, board_id, fc_input: int)
     -> int: >   return fcid * 1000000 + board_id * 100 + fc_input
  */
  switch (format) {
    // fcio-tracemap
    case 1: {
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
    case 2: {
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

    default:
      return 0;
  }
  return 1;
}
