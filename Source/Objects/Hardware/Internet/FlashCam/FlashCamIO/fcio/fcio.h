/*
 * fcio: I/O functions for FlashCam data
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Contact:
 * - mailing list: fcio-maintainers@mpi-hd.mpg.de
 * - upstream URL: https://www.mpi-hd.mpg.de/hinton/software
 */


/*========================================================//
date:    Tue Feb  9 13:49:27 CET 2021
sources: Libs-fc/fcio/fcio.c
//========================================================*/
#ifndef INCLUDED_fcio_h
#define INCLUDED_fcio_h

#ifdef __cplusplus
extern "C" {
#endif

int FCIODebug(int level)
;
#define FCIOReadInt(x,i)        FCIORead(x,sizeof(int),&i)
#define FCIOReadFloat(x,f)      FCIORead(x,sizeof(float),&f)
#define FCIOReadInts(x,s,i)     FCIORead(x,(s)*sizeof(int),(void*)(i))
#define FCIOReadFloats(x,s,f)   FCIORead(x,(s)*sizeof(float),(void*)(f))
#define FCIOReadUShorts(x,s,i)  FCIORead(x,(s)*sizeof(short int),(void*)(i))

#define FCIOWriteInt(x,i)       { int data=(int)(i); FCIOWrite(x,sizeof(int),&data); }
#define FCIOWriteFloat(x,f)     { float data=(int)(f); FCIOWrite(x,sizeof(float),&data); }
#define FCIOWriteInts(x,s,i)    FCIOWrite(x,(s)*sizeof(int),(void*)(i))
#define FCIOWriteFloats(x,s,f)  FCIOWrite(x,(s)*sizeof(float),(void*)(f))
#define FCIOWriteUShorts(x,s,i) FCIOWrite(x,(s)*sizeof(short int),(void*)(i))

#define FCIOMaxChannels 2400                    // the architectural limit for fc250b 12*8*24 adcch + 12*8 trgch.
#define FCIOMaxSamples  32768                   // max trace length is 8K samples for PMT firmware version (250Mhz)
                                                // while the Germanium version (62.5Mhz) suppports 32K samples.
#define FCIOMaxPulses   (FCIOMaxChannels*11000) // support up to 11,000 p.e. per channel

#define FCIOTraceBufferLength   (672 * (FCIOMaxSamples+2)) // In GE version 4 channels are combined into one -> 6 channels per card instead of 24:
                                                           // Reduces the channel limit to 12 * 8 * 6 adc channels + 12 * 6 trigger channels
                                                           // This means, the maximum needed buffer size is either 2400 * 8192 = 19660800 samples or 672 * 32768 = 22020096.
#define FCIOMaxDWords FCIOTraceBufferLength     // For backwards compatibility

typedef struct {                 // Readout configuration (typically once at start of run)

  int telid;                     // trace event list id ;-) 
  int adcs;                      // Number of FADC channels
  int triggers;                  // Number of trigger channels
  int eventsamples;              // Number of FADC samples per trace
  int adcbits;                   // Number of bits per FADC sample
  int sumlength;                 // Number of samples of the FPGA integrator
  int blprecision;               // Precision of the FPGA baseline algorithm (1/LSB)
  int mastercards;               // Number of master cards
  int triggercards;              // Number of trigger cards
  int adccards;                  // Number of FADC cards
  int gps;                       // GPS mode flag (0: not used, 1: sync PPS and 10 MHz)
  unsigned int tracemap[FCIOMaxChannels]; // trace map identifiers - fadc/triggercard addresses and channels
                                          // stores the FADC and Trigger card addresses as follows: (address << 16) + adc channel (channel number on the card)

} fcio_config;

typedef struct {                  // Raw event

  int type;                       // 1: Generic event, 2: calibration event, 3: simtel traces

  float pulser;                   // Used pulser amplitude in case of calibration event

  int timeoffset[10];             // [0] the offset in sec between the master and unix
                                  // [1] the offset in usec between master and unix
                                  // [2] the calculated sec which must be added to the master
                                  // [3] the delta time between master and unix in usec
                                  // [4] the abs(time) between master and unix in usec
                                  // [5] startsec
                                  // [6] startusec
                                  // [7-9] reserved for future use

  int deadregion[10];             // [0] start pps of the next dead window
                                  // [1] start ticks of the next dead window
                                  // [2] stop pps of the next dead window
                                  // [3] stop ticks of the next dead window
                                  // [4] maxticks of the dead window
                                  // [5] sparse event adc channel block beginning (see below)
                                  // [6] sparse event adc channel block end (see below)
                                  // the values are updated by each event but
                                  // stay at the previous value if no new dead region
                                  // has been detected. The dead region window
                                  // can define a window in the future
                                  // channel block:
                                  // Due to firmware implementation details, deadtime affects all
                                  // channels on a triggered ADC module even in sparse readout mode.
                                  // Fields 5 and 6 specify the index of the first trace that is affected
                                  // by deadtime and the number of consecutive traces.
                                  // In normal readout mode and in some sparse readout configurations this covers all traces.

  int timestamp[10];              // [0] Event no., [1] PPS, [2] ticks, [3] max. ticks
                                  // [4] reserved for trigger mask in fc250b v2
                                  // [5-9] dummies reserved for future use

  int timeoffset_size;            // actual size of the timeoffset array
  int timestamp_size;             // actual size of the timestamp array

  int deadregion_size;            // actual size of the deadregion array

  int num_traces;                              // used for sparse mode (FCIOSparseEvent); num_traces contains the length of the trace_list array.
  unsigned short trace_list[FCIOMaxChannels];  // list of updated trace indices while writing/reading in sparse mode (FCIOSparseEvent)
                                               // this index list contains the valid trace[] fields which are allowed to access.
                                               // adc channels / traces which are not listed here contain the traces from the previous FCIOSparseEvent while reading!

  unsigned short *trace[FCIOMaxChannels];        // Accessors for trace samples
  unsigned short *theader[FCIOMaxChannels];      // Accessors for traces incl. header bytes
                                                 // (FPGA baseline, FPGA integrator)
  unsigned short traces[FCIOTraceBufferLength];  // internal trace storage

} fcio_event;

typedef struct {                  // Reconstructed event

  int type;                       // 1: Generic event, 2: calibration event, 3: simtel true p.e., 4: merged simtel true p.e.

  float pulser;                   // Used pulser amplitude in case of calibration event

  int timeoffset[10];             // [0] the offset in sec between the master and unix
                                  // [1] the offset in usec between master and unix
                                  // [2] the calculated sec which must be added to the master
                                  // [3] the delta time between master and unix in usec
                                  // [4] the abs(time) between master and unix in usec
                                  // [5] startsec 
                                  // [6] startusec
                                  // [7-9] reserved for future use

  int deadregion[10];             // [0] start pps of the next dead window
                                  // [1] start ticks of the next dead window
                                  // [2] stop pps of the next dead window
                                  // [3] stop ticks of the next dead window
                                  // [4] maxticks of the dead window
                                  // [5] sparse event adc channel block beginning (see below)
                                  // [6] sparse event adc channel block end (see below)
                                  // the values are updated by each event but
                                  // stay at the previous value if no new dead region
                                  // has been detected. The dead region window
                                  // can define a window in the future
                                  // channel block:
                                  // Due to firmware implementation details, deadtime affects all
                                  // channels on a triggered ADC module even in sparse readout mode.
                                  // Fields 5 and 6 specify the index of the first trace that is affected
                                  // by deadtime and the number of consecutive traces.
                                  // In normal readout mode and in some sparse readout configurations this covers all traces.

  int timestamp[10];              // [0] Event no., [1] PPS, [2] ticks, [3] max. ticks
                                  // [4] reserved for trigger mask in fc250b v2
                                  // [5-9] dummies reserved for future use

  int timeoffset_size;            // actual size of the timeoffset array
  int timestamp_size;             // actual size of the timestamp array
  int deadregion_size;            // actual size of the deadregion array

  int totalpulses;
  int channel_pulses[FCIOMaxChannels];
  int flags[FCIOMaxPulses];
  float times[FCIOMaxPulses];
  float amplitudes[FCIOMaxPulses];

} fcio_recevent;


typedef struct {

  unsigned int reqid, status, eventno, pps, ticks, maxticks, numenv,
                numctilinks, numlinks, dummy;
  unsigned int totalerrors, enverrors, ctierrors, linkerrors, othererrors[5];
  int          environment[16];
  unsigned int ctilinks[4];
  unsigned int linkstates[256];

} card_status;

typedef struct {        // Readout status (~1 Hz, programmable)

  int status;           // 0: Errors occured, 1: no errors
  int statustime[10];   // fc250 seconds, microseconds, CPU seconds, microseconds, dummy, startsec startusec 
  int cards;            // Total number of cards (number of status data to follow)
  int size;             // Size of each status data

  // Status data of master card, trigger cards, and FADC cards (in that order)
  // the environment vars are:

  // 5 Temps in mDeg
  // 6 Voltages in mV
  // 1 main current in mA
  // 1 humidity in o/oo
  // 2 Temps from adc cards in mDeg

  // links are int's which are used in an undefined manner
  // current adc links and trigger links contain:
  // (one byte each MSB first)

  // valleywidth bitslip wordslip(trigger)/tapposition(adc) errors

  // these values should be used as informational content and can be
  // changed in future versions

  card_status data[256];

} fcio_status;

typedef struct {                   // FlashCam envelope structure

  void *ptmio;                     // tmio stream
  int magic;                       // Magic number to validate structure

  fcio_config config;
  fcio_event event;
  fcio_status status;
  fcio_recevent recevent;

} FCIOData;

typedef enum {
  FCIOConfig = 1,
  FCIOCalib = 2, // deprecated
  FCIOEvent = 3,
  FCIOStatus = 4,
  FCIORecEvent = 5,
  FCIOSparseEvent = 6
} FCIOTag;

typedef void* FCIOStream;

FCIOData *FCIOOpen(const char *name, int timeout, int buffer)
;
int FCIOClose(FCIOData *x)
;
int FCIOPutConfig(FCIOStream output, FCIOData *input)
;
int FCIOPutStatus(FCIOStream output, FCIOData *input)
;
int FCIOPutEvent(FCIOStream output, FCIOData *input)
;
int FCIOPutSparseEvent(FCIOStream output, FCIOData *input)
;
int FCIOPutRecEvent(FCIOStream output, FCIOData *input)
;
int FCIOPutRecord(FCIOStream output, FCIOData* input, int tag)
;
int FCIOGetRecord(FCIOData* x)
;
FCIOStream FCIOConnect(const char *name, int direction, int timeout, int buffer)
;
int FCIODisconnect(FCIOStream x)
;
int FCIOTimeout(FCIOStream x, int timeout_ms)
;
int FCIOWriteMessage(FCIOStream x, int tag)
;
int FCIOWrite(FCIOStream x, int size, void *data)
;
int FCIOFlush(FCIOStream x)
;
int FCIOReadMessage(FCIOStream x)
;
int FCIORead(FCIOStream x, int size, void *data)
;
int FCIOWaitMessage(FCIOStream x, int tmo)
;

typedef struct {
  fcio_config *config;
  fcio_event *event;
  fcio_status *status;
  fcio_recevent *recevent;
  int last_tag;

} FCIOState;

typedef struct {
  FCIOStream stream;
  int nrecords;
  int max_states;
  int cur_state;
  FCIOState *states;
  unsigned int selected_tags;
  int timeout;
  int nconfigs;
  int nevents;
  int nstatuses;
  int nrecevents;
  int cur_config;
  int cur_event;
  int cur_status;
  int cur_recevent;
  fcio_config *configs;
  fcio_event *events;
  fcio_status *statuses;
  fcio_recevent *recevents;

} FCIOStateReader;

FCIOStateReader *FCIOCreateStateReader(
  const char *peer,
  int io_timeout,
  int io_buffer_size,
  unsigned int state_buffer_depth)
;
int FCIODestroyStateReader(FCIOStateReader *reader)
;
int FCIOSelectStateTag(FCIOStateReader *reader, int tag)
;
int FCIODeselectStateTag(FCIOStateReader *reader, int tag)
;
FCIOState *FCIOGetState(FCIOStateReader *reader, int offset, int *timedout)
;
FCIOState *FCIOGetNextState(FCIOStateReader *reader, int *timedout)
;
#ifdef __cplusplus
}
#endif

#endif
