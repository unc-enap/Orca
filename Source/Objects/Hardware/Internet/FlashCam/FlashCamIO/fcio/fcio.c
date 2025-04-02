/*
 * fcio: I/O functions for FlashCam data
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 */


/*==> FCIO FlashCam I/O system <========================//

//=== General Information =======================================//

This Library is used to read and write messages with the FlashCam
I/O system.

The first part named FCIO structured I/O describes how to read FCIO
data structures and items.

The very simplified functional interface is well designed to read
millions of short messages per sec as well it can handle on modern
nodes (@2016) wire speed 10G ethernet tcp/ip messages with less than
20% CPU usage.

Data items are copied directly to a data structure which can be easily
extended for further records and data items. The access of data items
is managed by accessing them directly. This avoids additional overhead
by getter/setter functions and allows the maximal performance in speed.
Data items must not be modified by other functions than those described
here.

The second part describes the basic low level message interface of
FCIO. It is used to compose and transfer messages to files or to
other nodes via tcp/ip.

Please refer to the first part FCIO Structured I/O
if you are reading FlashCam data only and skip the second part
"low level message interface"

//----------------------------------------------------------------*/

/*+++ Header +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/


/*==> Include  <===================================================//

#include "fcio.h"

//----------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "time_utils.h"
#include "tmio.h"

static int debug=2;

/*=== Function ===================================================*/

int FCIODebug(int level)

/*--- Description ------------------------------------------------//

Set up debug level for FCIO function calls
Returns the old debug level.

0  = logging off
1  = errors on
2  = warning on
3  = info on
>3 = debugging

If higher debugging is used you get a lot of output. Beware
of turning it on during normal operation.

The debug level is used for all further function calls
and may be set before initialization of a context structure.

//----------------------------------------------------------------*/
{
  int old=debug;
  debug=level;
  return old;
}


///// Header ///////////////////////////////////////////////////////

#define FCIOReadInt(x,i)        FCIORead(x,sizeof(int),&i)
#define FCIOReadFloat(x,f)      FCIORead(x,sizeof(float),&f)
#define FCIOReadInts(x,s,i)     FCIORead(x,(s)*sizeof(int),(void*)(i))
#define FCIOReadFloats(x,s,f)   FCIORead(x,(s)*sizeof(float),(void*)(f))
#define FCIOReadUShorts(x,s,i)  FCIORead(x,(s)*sizeof(short int),(void*)(i))

////////////////////////////////////////////////////////////////////

///// Header ///////////////////////////////////////////////////////

#define FCIOWriteInt(x,i)       { int data=(int)(i); FCIOWrite(x,sizeof(int),&data); }
#define FCIOWriteFloat(x,f)     { float data=(float)(f); FCIOWrite(x,sizeof(float),&data); }
#define FCIOWriteInts(x,s,i)    FCIOWrite(x,(s)*sizeof(int),(void*)(i))
#define FCIOWriteFloats(x,s,f)  FCIOWrite(x,(s)*sizeof(float),(void*)(f))
#define FCIOWriteUShorts(x,s,i) FCIOWrite(x,(s)*sizeof(short int),(void*)(i))

////////////////////////////////////////////////////////////////////


// helpers
/* used later
static inline float **alloc2dfloats(int ny, int nx, float **data)
{
  if(data) { free(data[0]); free(data); }
  if(ny<=0 || nx<=0 ) return 0;
  int i;
  float **yp=(float**)calloc(ny,sizeof(void*));
  float *dp=(float*)calloc(nx*ny,sizeof(float));
  for(i=0; i<ny; i++) yp[i]= &dp[i*nx];
  return yp;
}
*/


/*=== FCIO Structured I/O =======================================//

Routines which know about the data format fo FCIO writers.
Data reaping is done via a structure holding all possible
data items.

Use the following function calls to read data from an i/o stream/file
and transfer them to an internal buffer, which can be accessed by
readers of the FCIO files/streams

//----------------------------------------------------------------*/

/*--- Structures  -----------------------------------------------*/

#define FCIOMaxChannels 2400                    // the architectural limit for fc250b 12*8*24 adcch + 12*8 trgch.
#define FCIOMaxSamples  32768                   // max trace length is 8K samples for PMT firmware version (250Mhz)
                                                // while the Germanium version (62.5Mhz) suppports 32K samples.
#define FCIOMaxPulses   (FCIOMaxChannels*11000) // support up to 11,000 p.e. per channel

#define FCIOTraceBufferLength   (672 * (FCIOMaxSamples+2)) // In GE version 4 channels are combined into one -> 6 channels per card instead of 24:
                                                           // Reduces the channel limit to 12 * 8 * 6 adc channels + 12 * 6 trigger channels
                                                           // This means, the maximum needed buffer size is either 2400 * 8192 = 19660800 samples or 672 * 32768 = 22020096.
#define FCIOMaxDWords FCIOTraceBufferLength     // For backwards compatibility

typedef struct {                 // Readout configuration (typically once at start of run)

  int streamid;                  // Identifier for this data stream
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

  struct {

    unsigned int reqid, status, eventno, pps, ticks, maxticks, numenv,
                  numctilinks, numlinks, dummy;
    unsigned int totalerrors, enverrors, ctierrors, linkerrors, othererrors[5];
    int          environment[16];
    unsigned int ctilinks[4];
    unsigned int linkstates[256];

  } data[256];

} fcio_status;

typedef struct {                   // FlashCam envelope structure

  void *ptmio;                     // tmio stream
  int magic;                       // Magic number to validate structure

  fcio_config config;
  fcio_event event;
  fcio_status status;
  fcio_recevent recevent;

} FCIOData;

/*
  List of records tags to identify known records.
  FCIOGetRecord and FCIOGet(Next)State read known tags
  into the corresponding data structures, and return
  the tag only otherwise.

  Exception: FCIOFSP<name> tags, are only reserved
  to prevent future use, but are not read by
  FCIOOpen / FCIOCreateStateReader.
  libfsp provides the corresponding corresponding read functions.

*/

typedef enum {
  FCIOConfig = 1,
  FCIOCalib = 2, // deprecated
  FCIOEvent = 3,
  FCIOStatus = 4,
  FCIORecEvent = 5,
  FCIOSparseEvent = 6,
  FCIOEventHeader = 7,
  FCIOFSPConfig = 8, // reserved for libfsp
  FCIOFSPEvent = 9, // reserved for libfsp
  FCIOFSPStatus = 10 // reserved for libfsp
} FCIOTag;

//----------------------------------------------------------------*/

/*--- Structures  -----------------------------------------------*/

typedef void* FCIOStream;

/*--- Description ------------------------------------------------//

An identifier for the FCIO connection.
This item is returned by any connection to a file or tcp/ip
stream and must be used in all further FCIO calls.

//----------------------------------------------------------------*/

// forward decls
FCIOStream FCIOConnect(const char *name, int direction, int timeout, int buffer);
int FCIODisconnect(FCIOStream x);
int FCIOWriteMessage(FCIOStream x, int tag);
int FCIOWrite(FCIOStream x, int size, void *data);
int FCIOFlush(FCIOStream x);
int FCIOReadMessage(FCIOStream x);
int FCIORead(FCIOStream x, int size, void *data);

/*=== Function ===================================================*/

FCIOData *FCIOOpen(const char *name, int timeout, int buffer)

/*--- Description ------------------------------------------------//

Connects to a file, server or client for FCIO read data transfer.

name is the connection endpoint of the underlying TMIO/BUFIO
library. Please refer to the documentation of TMIO/BUFIO for
more information.

name can be:

tcp://listen/port           to listen to port at all interfaces
tcp://listen/port/nodename  to listen to port at nodename interface
tcp://connect/port/nodename to connect to port and nodename

Any other name not starting with tcp: is treated as a file name.

timeout specifies the time to wait for a connection in milliseconds.
Specify 0 to return immediately (within the typical delays imposed by the
connection and OS) or -1 to block indefinitely.

buffer may be used to initialize the size (in kB) of the protocol buffers. If 0
is specified a default value will be used.

Returns a FCIOData structure or 0 on error.

//----------------------------------------------------------------*/
{
  FCIOData *x=(FCIOData*)calloc(1,sizeof(FCIOData));
  if(!x)
  {
    if(debug) fprintf(stderr,"FCIOOpen/ERROR: can not init structure\n");
    return 0;
  }
  x->ptmio=(void*)FCIOConnect(name,'r',timeout,buffer);
  if(x->ptmio==0)
  {
    if(debug) fprintf(stderr,"FCIOOpen/ERROR: can not connect to data source %s \n",(name)?name:"(NULL)");
    free(x);
    return 0;
  }
  if(debug>2) fprintf(stderr,"FCIOOpen: io structure initialized, size %ld KB\n",(long)sizeof(FCIOData)/1024);
  return x;
}



/*=== Function ===================================================*/

int FCIOClose(FCIOData *x)

/*--- Description ------------------------------------------------//

Disconnects to any FCIOData source and closes any communication to
the endpoint and frees all associated data. x becomes invalid
after the function call.

Returns 0 on success or <0 on error.

//----------------------------------------------------------------*/
{
  if (!x) return -1;
  FCIOStream xio=x->ptmio;
  FCIODisconnect(xio);
  free(x);
  if(debug > 3) fprintf(stderr,"FCIOClose/DEBUG: closed\n");
  return 0;
}


/*=== Function ===================================================*/

FCIOStream FCIOStreamHandle(FCIOData *x)

/*--- Description ------------------------------------------------//

Returns the internal FCIOStream object on success or NULL on error.

//----------------------------------------------------------------*/
{
  if(!x) return NULL;
  FCIOStream xio=x->ptmio;
  if(debug > 3) fprintf(stderr,"FCIOStream/DEBUG: return stream pointer.\n");
  return xio;
}


static inline int fcio_put_config(FCIOStream output, fcio_config* config)
{
  if (!output || !config)
    return -1;

  FCIOWriteMessage(output,FCIOConfig);
  FCIOWriteInt(output,config->adcs);
  FCIOWriteInt(output,config->triggers);
  FCIOWriteInt(output,config->eventsamples);
  FCIOWriteInt(output,config->blprecision);
  FCIOWriteInt(output,config->sumlength);
  FCIOWriteInt(output,config->adcbits);
  FCIOWriteInt(output,config->mastercards);
  FCIOWriteInt(output,config->triggercards);
  FCIOWriteInt(output,config->adccards);
  FCIOWriteInt(output,config->gps);
  FCIOWriteInts(output,(config->adcs+config->triggers),config->tracemap);
  FCIOWriteInt(output,config->streamid);

  return FCIOFlush(output);
}

/*=== Function ===================================================*/

int FCIOPutConfig(FCIOStream output, FCIOData *input)

/*--- Description ------------------------------------------------//

Writes a record of config data (struct fcio_config) to remote peer or file.
A record consist of the message tag and all data members of the struct.

Returns 0 on success or <0 on error.

//----------------------------------------------------------------*/
{
  if (!output) {
    fprintf(stderr, "FCIOPutConfig/ERROR: Output not connected.\n");
    return -1;
  }
  if (!input) {
    fprintf(stderr, "FCIOPutConfig/ERROR: Input not valid (null pointer).\n");
    return -1;
  }

  return fcio_put_config(output, &input->config);
}


static inline int fcio_put_status(FCIOStream output, fcio_status* status)
{
  if (!output || !status)
    return -1;

  FCIOWriteMessage(output, FCIOStatus);
  FCIOWriteInt(output, status->status);
  FCIOWriteInts(output, 10, status->statustime);
  FCIOWriteInt(output, status->cards);
  FCIOWriteInt(output, status->size);
  for (int i = 0; i < status->cards; i++)
    FCIOWrite(output, status->size, (void*)&status->data[i]);

  return FCIOFlush(output);
}

/*=== Function ===================================================*/

int FCIOPutStatus(FCIOStream output, FCIOData *input)

/*--- Description ------------------------------------------------//

Writes a record of config data (struct fcio_status) to remote peer or file.
A record consist of the message tag and all data members of the struct.

The size of status.data from individual cards is sent depending on
status.cards and status.size.

Returns 0 on success or <0 on error.

//----------------------------------------------------------------*/
{
  if (!output) {
    fprintf(stderr, "FCIOPutStatus/ERROR: Output not connected.\n");
    return -1;
  }
  if (!input) {
    fprintf(stderr, "FCIOPutStatus/ERROR: Input not valid (null pointer).\n");
    return -1;
  }

  return fcio_put_status(output, &input->status);
}


static inline int fcio_put_event(FCIOStream output, fcio_config* config, fcio_event* event)
{
  if (!output || !config || !event)
    return -1;

  FCIOWriteMessage(output,FCIOEvent);
  FCIOWriteInt(output,event->type);
  FCIOWriteFloat(output,event->pulser);
  FCIOWriteInts(output, event->timeoffset_size, event->timeoffset);
  FCIOWriteInts(output, event->timestamp_size, event->timestamp);
  FCIOWriteUShorts(output,(config->adcs+config->triggers)*(config->eventsamples+2),event->traces);
  FCIOWriteInts(output, event->deadregion_size, event->deadregion);
  return FCIOFlush(output);
}

/*=== Function ===================================================*/

int FCIOPutEvent(FCIOStream output, FCIOData *input)

/*--- Description ------------------------------------------------//

Writes a record of event data (struct fcio_event) to remote peer or file.
A record consist of the message tag and all data members of the struct.

The number of items in event.timeoffset, timestamp and deadregion sent
to remote depends on their corresponding *_size items.

The number of items in event.traces sent to remote depends on
(config.adcs + config.triggers) * (config.eventsamples+2).

Returns 0 on success or <0 on error.

//----------------------------------------------------------------*/
{
  if (!output) {
    fprintf(stderr, "FCIOPutEvent/ERROR: Output not connected.\n");
    return -1;
  }
  if (!input) {
    fprintf(stderr, "FCIOPutEvent/ERROR: Input not valid (null pointer).\n");
    return -1;
  }

  return fcio_put_event(output, &input->config, &input->event);
}



static inline int fcio_put_sparseevent(FCIOStream output, fcio_config* config, fcio_event* event)
{
  if (!output || !config || !event)
    return -1;

  FCIOWriteMessage(output,FCIOSparseEvent);
  FCIOWriteInt(output,event->type);
  FCIOWriteFloat(output,event->pulser);
  FCIOWriteInts(output, event->timeoffset_size, event->timeoffset);
  FCIOWriteInts(output, event->timestamp_size, event->timestamp);
  FCIOWriteInts(output, event->deadregion_size, event->deadregion);
  FCIOWriteInts(output,1,&event->num_traces);
  FCIOWriteUShorts(output,event->num_traces,event->trace_list);

  int length = config->eventsamples+2;
  for (int i = 0; i < event->num_traces; i++)
  {
    int j = event->trace_list[i];
    FCIOWriteUShorts(output,length,&event->traces[j * length]);
  }

  return FCIOFlush(output);
}

/*=== Function ===================================================*/

int FCIOPutSparseEvent(FCIOStream output, FCIOData *input)

/*--- Description ------------------------------------------------//

Writes a sparse record of event data (struct fcio_event) to remote peer or file.
A record consist of the message tag and all data members of the struct.

The number of items in event.timeoffset, timestamp and deadregion sent
to remote depends on their corresponding *_size items.

The number of theaders sent depends on the trace_list array (with size num_traces).
Only those traces, whose indices are stored in trace_list will be serialized.

Returns 0 on success or <0 on error.

//----------------------------------------------------------------*/
{
  if (!output) {
    fprintf(stderr, "FCIOPutSparseEvent/ERROR: Output not connected.\n");
    return -1;
  }
  if (!input) {
    fprintf(stderr, "FCIOPutSparseEvent/ERROR: Input not valid (null pointer).\n");
    return -1;
  }

  return fcio_put_sparseevent(output, &input->config, &input->event);
}


static inline int fcio_put_eventheader(FCIOStream output, fcio_config* config, fcio_event* event)
{
  if (!output || !config || !event)
    return -1;

  FCIOWriteMessage(output,FCIOEventHeader);
  FCIOWriteInt(output,event->type);
  FCIOWriteFloat(output,event->pulser);
  FCIOWriteInts(output, event->timeoffset_size, event->timeoffset);
  FCIOWriteInts(output, event->timestamp_size, event->timestamp);
  FCIOWriteInts(output, event->deadregion_size, event->deadregion);
  FCIOWriteUShorts(output,event->num_traces,event->trace_list);

  const int length = config->eventsamples + 2;
  unsigned short write_buffer[FCIOMaxChannels * 2];
  for (int i = 0; i < event->num_traces; i++)
  {
    int j = event->trace_list[i];
    for (int k = 0; k < 2; k++)
      write_buffer[i * 2 + k] = event->traces[j * length + k];
  }
  FCIOWriteUShorts(output, event->num_traces * 2, write_buffer);

  return FCIOFlush(output);
}

/*=== Function ===================================================*/

int FCIOPutEventHeader(FCIOStream output, FCIOData *input)

/*--- Description ------------------------------------------------//

Writes the metadata and header of event data (struct fcio_event) to remote peer or file.

The number of items in event.timeoffset, timestamp and deadregion sent
to remote depends on their corresponding *_size items.

The number of theaders sent depends on the trace_list array (with size num_traces).
Only those traces, whose indices are stored in trace_list will be serialized.

Returns 0 on success or <0 on error.

//----------------------------------------------------------------*/
{
  if (!output) {
    fprintf(stderr, "FCIOPutEventHeader/ERROR: Output not connected.\n");
    return -1;
  }
  if (!input) {
    fprintf(stderr, "FCIOPutEventHeader/ERROR: Input not valid (null pointer).\n");
    return -1;
  }

  return fcio_put_eventheader(output, &input->config, &input->event);
}

static inline int fcio_put_recevent(FCIOStream output, fcio_config* config, fcio_recevent* recevent)
{
  if (!output || !config || !recevent) return -1;
  FCIOWriteMessage(output,FCIORecEvent);
  FCIOWriteInt(output, recevent->type);
  FCIOWriteFloat(output, recevent->pulser);
  FCIOWriteInts(output, recevent->timeoffset_size, recevent->timeoffset);
  FCIOWriteInts(output, recevent->timestamp_size, recevent->timestamp);
  FCIOWriteInts(output, recevent->deadregion_size, recevent->deadregion);
  FCIOWriteInt(output, recevent->totalpulses);
  FCIOWriteInts(output, config->adcs, recevent->channel_pulses);
  FCIOWriteInts(output, recevent->totalpulses, recevent->flags);
  FCIOWriteFloats(output, recevent->totalpulses, recevent->amplitudes);
  FCIOWriteFloats(output, recevent->totalpulses, recevent->times);

  return FCIOFlush(output);
}

/*=== Function ===================================================*/

int FCIOPutRecEvent(FCIOStream output, FCIOData *input)

/*--- Description ------------------------------------------------//

Writes a record of recevent data (struct fcio_recevent) to remote peer or file.
A record consist of the message tag and all data members of the struct.

The number of items in event.timeoffset, timestamp and deadregion sent
to remote depends on their corresponding *_size items.

The number of items in recevent.channel_pulses depends on config.adcs.

The number of items in recevent.flags, recevent.amplitudes and recevent.times
depends on recevent.totalpulses.

Returns 0 on success or <0 on error.

//----------------------------------------------------------------*/
{
  if (!output) {
    fprintf(stderr, "FCIOPutRecEvent/ERROR: Output not connected.\n");
    return -1;
  }
  if (!input) {
    fprintf(stderr, "FCIOPutRecEvent/ERROR: Input not valid (null pointer).\n");
    return -1;
  }

  return fcio_put_recevent(output, &input->config, &input->recevent);
}


/*=== Function ===================================================*/

int FCIOPutRecord(FCIOStream output, FCIOData* input, int tag)

/*--- Description ------------------------------------------------//

Writes a record of data to remote peer or file.
A record consist of a message tag and all data items stored under
this tag.

Known record tags are listed in the FCIOTag enum.

This function wraps the family of FCIOPut<..> functions.
Refer to their documentation for more details.

Returns 0 success, <0 on error or >0 on warning.
  -1 : invalid inputs (null pointer)
   1 : unknown tag

//----------------------------------------------------------------*/
{
  if (!output) {
    fprintf(stderr, "FCIOPutRecord/ERROR: Output not connected.\n");
    return -1;
  }
  if (!input) {
    fprintf(stderr, "FCIOPutRecord/ERROR: Input not valid (null pointer).\n");
    return -1;
  }

  switch (tag) {
    case FCIOEvent:
      return fcio_put_event(output, &input->config, &input->event);

    case FCIOSparseEvent:
      return fcio_put_sparseevent(output, &input->config, &input->event);

    case FCIORecEvent:
      return fcio_put_recevent(output, &input->config, &input->recevent);

    case FCIOConfig:
      return fcio_put_config(output, &input->config);

    case FCIOStatus:
      return fcio_put_status(output, &input->status);

    case FCIOEventHeader:
      return fcio_put_eventheader(output, &input->config, &input->event);
  }
  return 1;
}

static inline int fcio_get_config(FCIOStream stream, fcio_config *config)
{
  if (!stream || !config)
    return -1;

  FCIOReadInt(stream,config->adcs);
  FCIOReadInt(stream,config->triggers);
  const int n_configured_traces = config->adcs + config->triggers;
  if (n_configured_traces < 0 || n_configured_traces > FCIOMaxChannels) {
    if (debug)
      fprintf(stderr, "FCIO/fcio_get_config/ERROR: number of configured channels %d (adc %d + trigger %d) outside allowed range [0,%d]\n", n_configured_traces, config->adcs, config->triggers, FCIOMaxChannels);
    return -1;
  }

  FCIOReadInt(stream,config->eventsamples);
  if (config->eventsamples < 0 || config->eventsamples > FCIOMaxSamples) {
    if (debug)
      fprintf(stderr, "FCIO/fcio_get_config/ERROR: eventsamples %d outside allowed range [0,%d]\n", config->eventsamples, FCIOMaxSamples);
    return -1;
  }
  FCIOReadInt(stream,config->blprecision);
  FCIOReadInt(stream,config->sumlength);
  FCIOReadInt(stream,config->adcbits);
  FCIOReadInt(stream,config->mastercards);
  FCIOReadInt(stream,config->triggercards);
  FCIOReadInt(stream,config->adccards);
  FCIOReadInt(stream,config->gps);
  int tracemap_size = FCIOReadInts(stream, FCIOMaxChannels, config->tracemap)/sizeof(int);
  FCIOReadInt(stream,config->streamid);

  if (debug > 3)
    fprintf(stderr,"FCIO/fcio_get_config/DEBUG: %d/%d/%d adcs %d triggers %d samples %d adcbits %d blprec %d sumlength %d gps %d\n",
      config->mastercards, config->triggercards, config->adccards,
      config->adcs,config->triggers,config->eventsamples,config->adcbits,config->blprecision,config->sumlength,config->gps);
  if (debug > 4) {
    for (int i = 0; i < tracemap_size; i++)
       fprintf(stderr,"FCIO/fcio_get_config/DEBUG: trace %d mapped to 0x%x\n",i,config->tracemap[i]);
  }


  // tracemap must not be present, but should match number of traces.
  if (tracemap_size && tracemap_size != n_configured_traces) {
    fprintf(stderr, "FCIO/fcio_get_config/WARNING: got unexpected tracemap size %d/%d\n", tracemap_size, n_configured_traces);
    return 1;
  }
  return 0;
}

static inline int fcio_get_status(FCIOStream stream, fcio_status *status)
{
  if (!stream || !status)
    return -1;

  FCIOReadInt(stream,status->status);
  FCIOReadInts(stream,10,status->statustime);
  FCIOReadInt(stream,status->cards);
  FCIOReadInt(stream,status->size);
  for (int i = 0; i < status->cards; i++)
    FCIORead(stream, status->size, (void*)&status->data[i]);

  if (debug > 3) {
    int totalerrors = 0;
    for (int i = 0; i < status->cards; i++)
      totalerrors += status->data[i].totalerrors;
    fprintf(stderr,"FCIO/fcio_get_status/DEBUG: overall %d errors %d time pps %d ticks %d unix %d %d delta %d cards %d\n",
      status->status,totalerrors,status->statustime[0], status->statustime[1],status->statustime[2],
      status->statustime[3],status->statustime[4],status->cards);

    if (debug > 4) {
      for (int i = 0; i < status->cards; i++) {
        fprintf(stderr,"FCIO/fcio_get_status/DEBUG: card %d: status %d errors %d time %d %9d env",i,
          status->data[i].status,status->data[i].totalerrors,status->data[i].pps,status->data[i].ticks);
        if (debug > 5) {
          for (int i1 = 0; i1 < (int)status->data[i].numenv; i1++)
            fprintf(stderr," %d",(int)status->data[i].environment[i1]);
        }
        fprintf(stderr,"\n");
      }
    }
  }
  return 0;
}

static inline int fcio_get_event(FCIOStream stream, fcio_event *event, int num_expected_traces)
{
  if (!stream || !event)
    return -1;

  if (num_expected_traces < 0 || num_expected_traces > FCIOMaxChannels)
    return -1;

  FCIOReadInt(stream,event->type);
  FCIOReadFloat(stream,event->pulser);
  event->timeoffset_size = FCIOReadInts(stream,10,event->timeoffset)/sizeof(int);
  event->timestamp_size = FCIOReadInts(stream,10,event->timestamp)/sizeof(int);
  FCIOReadUShorts(stream,FCIOMaxChannels*(FCIOMaxSamples + 2),event->traces);
  event->deadregion_size = FCIOReadInts(stream,10,event->deadregion)/sizeof(int);
  // If an FCIOSparseEvent has been read previous to an FCIOEvent
  // num_traces and trace_list might have been adjusted to match the sparse layout
  if (event->num_traces != num_expected_traces) {
    event->num_traces = num_expected_traces;
    for (int i = 0; i < num_expected_traces; i++)
      event->trace_list[i] = i;
  }
  event->deadregion[5] = 0;
  event->deadregion[6] = num_expected_traces;

  if (debug > 3) {
    fprintf(stderr,"FCIO/fcio_get_event/DEBUG: type %d pulser %g, offset %d %d %d traces %d timestamp[%d] ",
      event->type,event->pulser,event->timeoffset[0],event->timeoffset[1],event->timeoffset[2],event->num_traces, event->timestamp_size);
    for (int i = 0; i < event->timestamp_size; i++)
      fprintf(stderr," %d",event->timestamp[i]);
    fprintf(stderr, " deadregion[%d]", event->deadregion_size);
    for (int i = 0; i < event->deadregion_size; i++)
      fprintf(stderr," %d",event->deadregion[i]);
    fprintf(stderr,"\n");
  }
  return 0;
}

static inline int fcio_get_sparseevent(FCIOStream stream, fcio_event *event, int tracesamples)
{
  if (!stream || !event)
    return -1;

  if (tracesamples < 0 || tracesamples > FCIOMaxSamples+2)
    return -1;

  FCIOReadInt(stream,event->type);
  FCIOReadFloat(stream,event->pulser);
  event->timeoffset_size = FCIOReadInts(stream,10,event->timeoffset)/sizeof(int);
  event->timestamp_size = FCIOReadInts(stream,10,event->timestamp)/sizeof(int);
  event->deadregion_size = FCIOReadInts(stream,10,event->deadregion)/sizeof(int);

  FCIOReadInts(stream,1,&event->num_traces);
  int read_trace_list_size = FCIOReadUShorts(stream, FCIOMaxChannels, event->trace_list)/sizeof(unsigned short);
  if (read_trace_list_size != event->num_traces) {
    if (debug > 1) fprintf(stderr, "FCIO/fcio_get_sparsevent/WARNING: trace_list size does not match %d/%d\n", read_trace_list_size, event->num_traces);
    if (read_trace_list_size < event->num_traces)
      event->num_traces = read_trace_list_size;
  }
  for (int i = 0; i < event->num_traces; i++) {
    int trace_idx = event->trace_list[i];
    if (trace_idx >= FCIOMaxChannels) {
      if (debug) fprintf(stderr, "FCIO/fcio_get_sparsevent/ERROR: trace_list contains out-of-bounds trace index for traces buffer %d/%d\n", trace_idx, FCIOMaxChannels);
      return -1;
    }
    FCIOReadUShorts(stream,tracesamples,&event->traces[event->trace_list[i]*tracesamples]);
  }

  if (debug > 3) {
    fprintf(stderr,"FCIO/fcio_get_sparseevent/DEBUG: type %d pulser %g, offset %d %d %d",event->type,event->pulser,event->timeoffset[0],event->timeoffset[1],event->timeoffset[2]);
    fprintf(stderr," timestamp[%d]", event->timestamp_size); for (int i = 0; i < event->timestamp_size; i++) fprintf(stderr," %d",event->timestamp[i]);
    fprintf(stderr," deadregion[%d]", event->deadregion_size); for (int i = 0; i < event->deadregion_size; i++) fprintf(stderr," %d",event->deadregion[i]);
    if (debug > 5) {
      fprintf(stderr," traces[%d]", event->num_traces);
      for (int i = 0; i < event->num_traces; i++) fprintf(stderr," %d",event->trace_list[i]);
    }
    fprintf(stderr,"\n");
  }
  return 0;
}

static inline int fcio_get_eventheader(FCIOStream stream, fcio_config* config, fcio_event *event)
{
  if (!stream || !config || !event)
    return -1;

  FCIOReadInt(stream,event->type);
  FCIOReadFloat(stream,event->pulser);
  event->timeoffset_size = FCIOReadInts(stream,10,event->timeoffset)/sizeof(int);
  event->timestamp_size = FCIOReadInts(stream,10,event->timestamp)/sizeof(int);
  event->deadregion_size = FCIOReadInts(stream,10,event->deadregion)/sizeof(int);
  event->num_traces = FCIOReadUShorts(stream, FCIOMaxChannels, event->trace_list)/sizeof(unsigned short);

  const int length = config->eventsamples + 2; // checked consistency in fcio_get_config
  unsigned short read_buffer[FCIOMaxChannels * 2];
  int read_header_elements = FCIOReadUShorts(stream, FCIOMaxChannels * 2, read_buffer)/sizeof(unsigned short)/2;
  if (read_header_elements != event->num_traces) {
    if (debug > 1) fprintf(stderr, "FCIO/fcio_get_eventheader/WARNING: trace_list size does not match %d/%d\n", read_header_elements, event->num_traces);
    if (read_header_elements < event->num_traces)
      event->num_traces = read_header_elements;
  }
  for (int i = 0; i < event->num_traces; i++) {
    int trace_idx = event->trace_list[i];
    if (trace_idx >= FCIOMaxChannels) {
      if (debug) fprintf(stderr, "FCIO/fcio_get_eventheader/ERROR: trace_list contains out-of-bounds trace index for traces buffer %d/%d\n", trace_idx, FCIOMaxChannels);
      return -1;
    }
    for (int k = 0; k < 2; k++)
      event->traces[trace_idx * length + k] = read_buffer[i * 2 + k];
  }

  if (debug > 3) {
    fprintf(stderr,"FCIO/fcio_get_eventheader/DEBUG: type %d pulser %g, offset %d %d %d",event->type,event->pulser,event->timeoffset[0],event->timeoffset[1],event->timeoffset[2]);
    fprintf(stderr," timestamp[%d]", event->timestamp_size); for (int i = 0; i < event->timestamp_size; i++) fprintf(stderr," %d",event->timestamp[i]);
    fprintf(stderr," deadregion[%d]", event->deadregion_size); for (int i = 0; i < event->deadregion_size; i++) fprintf(stderr," %d",event->deadregion[i]);
    if (debug > 5) {
      fprintf(stderr," traces[%d]", event->num_traces);
      for (int i = 0; i < event->num_traces; i++)
        fprintf(stderr," %d %u",event->trace_list[i], event->theader[event->trace_list[i]][1]);
    }
    fprintf(stderr,"\n");
  }
  return 0;
}

static inline int fcio_get_recevent(FCIOStream stream, fcio_recevent *recevent)
{
  if (!stream || !recevent)
    return -1;

  FCIOReadInt(stream,recevent->type);
  FCIOReadFloat(stream,recevent->pulser);
  recevent->timeoffset_size = FCIOReadInts(stream,10,recevent->timeoffset)/sizeof(int);
  recevent->timestamp_size = FCIOReadInts(stream,10,recevent->timestamp)/sizeof(int);
  recevent->deadregion_size = FCIOReadInts(stream,10,recevent->deadregion)/sizeof(int);
  FCIOReadInt(stream, recevent->totalpulses);
  FCIOReadInts(stream,FCIOMaxChannels,recevent->channel_pulses);
  int flags_size = FCIOReadInts(stream,FCIOMaxPulses,recevent->flags)/sizeof(int);
  int amplitudes_size = FCIOReadFloats(stream,FCIOMaxPulses,recevent->amplitudes)/sizeof(float);
  int times_size = FCIOReadFloats(stream,FCIOMaxPulses,recevent->times)/sizeof(float);

  if (debug > 3) {
    fprintf(stderr,"FCIO/fcio_get_recevent/DEBUG: type %d pulser %g, offset %d %d %d timestamp ",
        recevent->type,recevent->pulser,recevent->timeoffset[0],recevent->timeoffset[1],recevent->timeoffset[2]);
    for (int i = 0; i < recevent->timestamp_size; i++)
      fprintf(stderr," %d",recevent->timestamp[i]);
    fprintf(stderr,"\n");
  }

  if ( (flags_size != amplitudes_size) || (amplitudes_size != times_size) || (times_size != recevent->totalpulses) ) {
    if ( debug > 1 ) fprintf(stderr, "FCIO/fcio_get_recevent/WARNING: Mismatch in pulse parameter sizes: totalpulses %d flags %d amplitudes %d times %d\n",
      recevent->totalpulses, flags_size, amplitudes_size, times_size);
    return 1;
  }
  return 0;
}

/*=== Function ===================================================*/

int FCIOGetRecord(FCIOData* x)

/*--- Description ------------------------------------------------//

Reads a record of data from remote peer or file.
A record consist of a message tag and all data items stored under
this tag.

valid record tags are described above

Returns the tag (>0) on success or 0 on timeout and <0 on error.

If a the data items are copied to the corresponding data structure
FCIOData *x. You can access all items directly by the x pointer
e.g.: x->config.adcs yields the number of adcs of camera.

note: the structure is not complete up to now and will be extended by
further items.

//----------------------------------------------------------------*/
{
  if (!x)
    return -1;

  FCIOStream xio=x->ptmio;
  int tag = FCIOReadMessage(xio);
  if (debug > 4) fprintf(stderr,"FCIOGetRecord: got tag %d \n",tag);
  if (tag <= 0)
    return tag;

  int rc = 0;
  switch (tag) {
    case FCIOConfig:
      rc = fcio_get_config(xio, &x->config);

      // On config, the pointers can be set.
      if (rc >= 0) {
        for (int i = 0; i < x->config.adcs + x->config.triggers; i++) {
          x->event.trace[i] = &x->event.traces[2 + i * (x->config.eventsamples + 2)];
          x->event.theader[i] = &x->event.traces[i * (x->config.eventsamples + 2)];
        }
      }
    break;

    case FCIOEvent:
      rc = fcio_get_event(xio, &x->event,x->config.adcs+x->config.triggers);
    break;

    case FCIOSparseEvent:
      rc = fcio_get_sparseevent(xio, &x->event,x->config.eventsamples+2);
    break;

    case FCIORecEvent:
      rc = fcio_get_recevent(xio, &x->recevent);
    break;

    case FCIOStatus:
      rc = fcio_get_status(xio, &x->status);
    break;

    case FCIOEventHeader:
      rc = fcio_get_eventheader(xio, &x->config, &x->event);
    break;
  }

  // get implementations return status >0 on inconsistency and
  // are expected to emit their own warning messages.
  // we fail only on error.
  if (rc < 0)
    return -1;

  return tag;
}



/*=== Example reading a data with Structured I/O ==================//

// only a few items are accessed by this example

char *fcio="datafile";
fprintf(stderr,"plot FC250b events FCIO format %s\n",fcio);
int iotag;

FCIODebug(debug);
FCIOData *x=FCIOOpen(fcio,10000,0);
if(!x) exit(1);

while((iotag=FCIOGetRecord(x))>0)
{
  int i;
  switch(iotag)
  {
    case FCIOConfig:  // a config record
    // do something here
    break;

    case FCIOStatus:  // a status record
    // do something here
    break;

    case FCIOEvent:   // event record
    // show some info
    fprintf(stderr,"  adc       bl    isum-bl    tsum-bl   max-bl   pos\n");
    for(i=0;i<x->config.adcs;i++)
    {
      // calculate baseline, integrator and trace integral
      double bl=1.0*x->event.theader[i][0]/x->config.blprecision;
      double intsum=1.0*x->config.sumlength/x->config.blprecision*
         (x->event.theader[i][1]-x->event.theader[i][0]);
      double max=0; int imax=0; double tsum=0; int i1;
      for(i1=0;i1<x->config.eventsamples;i1++)
      {
        double amp=x->event.trace[i][i1]-bl;
        if(amp>max) max=amp, imax=i1;
        tsum+=amp;
      }
      if(max>0) fprintf(stderr,"%5d %8.2f %10g %10.2f %8.2f %5d\n",
         i,bl,intsum,tsum,max,imax);
    }
    break;

    case FCIOSparseEvent:  // sparse event record, also compatible with FCIOEvent
    for (j = 0; j < x->event.num_traces; j++)
    {
      i = x->event.trace_list[j];
      double bl=1.0*x->event.theader[i][0]/x->config.blprecision;
      double intsum=1.0*x->config.sumlength/x->config.blprecision*
         (x->event.theader[i][1]-x->event.theader[i][0]);
      double max=0; int imax=0; double tsum=0; int i1;
      for(i1=0;i1<x->config.eventsamples;i1++)
      {
        double amp=x->event.trace[i][i1]-bl;
        if(amp>max) max=amp, imax=i1;
        tsum+=amp;
      }
      if(max>0) fprintf(stderr,"%5d %8.2f %10g %10.2f %8.2f %5d\n",
         i,bl,intsum,tsum,max,imax);
    }

    case FCIORecEvent:  // reconstructed event record
    // do something here
    break;

    default:
    fprintf(stderr,"record tag %d... skipped \n",iotag);
    break;
  }
}

fprintf(stderr,"end of file \n");
FCIOClose(x);


//----------------------------------------------------------------*/



/*=== FCIO Low Level I/O functions ================================//

Functions for composing and transferring messages within the FCIO
stream based I/O system.

Please refer to the first part FCIO Structured I/O
if you are reading FlashCam data only and skip the rest of this document

//----------------------------------------------------------------*/


/*=== Function ===================================================*/

FCIOStream FCIOConnect(const char *name, int direction, int timeout, int buffer)

/*--- Description ------------------------------------------------//

Connects to a file, server or client for FCIO data transfer.

name is the connection endpoint of the underlying TMIO/BUFIO
library. Please refer to the documentation of TMIO/BUFIO for
more information.

Creates a connection or file, with name being a plain file name, "-" for
stdout, or

tcp://listen/port           to listen to port at all interfaces
tcp://listen/port/nodename  to listen to port at nodename interface
tcp://connect/port/nodename to connect to port and nodename

Any other name not starting with tcp: is treated as a file name.

direction must be an character 'r' or 'w' to specify the direction
of read and write,

timeout specifies the time to wait for a connection in milliseconds.
Specify 0 to return immediately (within the typical delays imposed by the
connection and OS) or -1 to block indefinitely.

buffer may be used to initialize the size (in kB) of the protocol buffers. If 0
is specified a default value will be used.

Returns a FCIOStream or NULL on error.

//----------------------------------------------------------------*/
{
  const char *proto="FlashCamV1";
  if(name==0) {
    if(debug) fprintf(stderr,"FCIOConnect/ERROR: endpoint not given, output will be discarded \n");
    return NULL;
  }

  int tmio_debug = debug-3;
  tmio_stream *x=tmio_init(proto, timeout, buffer, tmio_debug<0?0:tmio_debug);
  if(x==0) {
    if(debug) fprintf(stderr,"FCIOConnect/ERROR: init of tmio structure failed\n");
    return NULL;
  }

  int rc=-1;
  if(direction=='w') rc=tmio_create(x, name, timeout);
  else if(direction=='r') rc=tmio_open(x, name, timeout);
  if(rc<0) {
    if(debug) fprintf(stderr,"FCIOConnect/ERROR: can not connect to stream %s, %s\n",
        name,tmio_status_str(x));
    tmio_delete(x);
    return NULL;
  }

  if(debug>3) fprintf(stderr,"FCIOConnect/DEBUG: %s connected, proto %s \n",name,proto);
  return (FCIOStream)x;
}


/*=== Function ===================================================*/

int FCIODisconnect(FCIOStream x)

/*--- Description ------------------------------------------------//

Disconnects to any FCIOStream and closes any communication to
the endpoint.

Returns 0 on success and <0 on error.

//----------------------------------------------------------------*/
{
  if (!x) return -1;
  tmio_stream *xio=(tmio_stream *)x;

  tmio_delete(xio); // always returns 0
  if (debug>3) fprintf(stderr,"FCIODisconnect/DEBUG: stream closed\n");
  return 0;
}


/*=== Function ===================================================*/

int FCIOTimeout(FCIOStream x, int timeout_ms)

/*--- Description ------------------------------------------------//

Sets the timeout for I/O operations in milliseconds.

Returns the previously set timeout.

//----------------------------------------------------------------*/
{
  return tmio_timeout((tmio_stream *) x, timeout_ms);
}


/*=== Writing Messages ===========================================//

For getting the maximum speed during write messages will be composed
on the fly. The following underlying function calls are used to
composed FCIO messages.

//----------------------------------------------------------------*/

/*=== Function ===================================================*/

int FCIOWriteMessage(FCIOStream x, int tag)

/*--- Description ------------------------------------------------//

Starts a message with tag
Returns 0 on success or <0 on error

//----------------------------------------------------------------*/
{
  if (!x) return -1;
  // tmio_write_tag checks for tag validity itself

  tmio_stream *xio=(tmio_stream *)x;

  if (debug > 5)
    fprintf(stderr,"FCIOWriteMessage/DEBUG: tag %d @ %p \n",tag,(void*)xio);

  if (tmio_write_tag(xio,tag) ) {
    if (debug && (tmio_status(xio)<0))
      fprintf(stderr,"FCIOWriteMessage/ERROR: writing tag %d \n",tag);
    return -1;
  }

  return 0;
}


/*=== Function ===================================================*/

int FCIOWrite(FCIOStream x, int size, void *data)

/*--- Description ------------------------------------------------//

Write a data item of size bytes length.
Data must point to the data buffer to transfer.
Returns size on success, 0 on size < 0 or <0 on error

//----------------------------------------------------------------*/
{
  if (!x) {
    if (debug) fprintf(stderr, "FCIOWrite/ERROR: output not connected\n");
    return -1;
  }
  if (!data) {
    if (debug) fprintf(stderr, "FCIOWrite/ERROR: data not valid (null pointer)\n");
    return -1;
  }
  // tmio_write_data checks on size < 0 and returns 0
  // don't need to check here.

  tmio_stream *xio=(tmio_stream *)x;

  int written_size = tmio_write_data(xio, data, size);
  if (debug > 5)
    fprintf(stderr,"FCIOWrite/DEBUG: size %d/%d @ %p \n", written_size, size,(void*)xio);
  if (debug && written_size != size)
    fprintf(stderr,"FCIOWrite/ERROR: %s with size %d/%d\n", tmio_status_str(xio), written_size, size);

  return written_size;
}


/*=== Function ===================================================*/

int FCIOFlush(FCIOStream x)

/*--- Description ------------------------------------------------//

Flush all composed messages.

Returns 0 on success or -1 on error.

//----------------------------------------------------------------*/
{
  if (!x) return -1;
  tmio_stream *xio = (tmio_stream *)x;

  if (tmio_flush(xio)) {
    if (debug)
      fprintf(stderr,"FCIOFlush/ERROR: %s\n",tmio_status_str(xio));
    return -1;
  }
  return 0;
}

/*=== Reading Messages ===========================================//

The following read function calls transfers written
data messages to an user specified buffer.

//----------------------------------------------------------------*/


/*=== Function ===================================================*/

int FCIOReadMessage(FCIOStream x)

/*--- Description ------------------------------------------------//

Read the message tag starting a record.

Returns the tag (>0) on success or 0 on timeout and <0 on error.

//----------------------------------------------------------------*/
{
  if (!x) return -1;
  tmio_stream *xio=(tmio_stream *)x;

  int tag = tmio_read_tag(xio);
  if (debug > 5)
    fprintf(stderr,"FCIOReadMessage/DEBUG: got tag %d @ %p \n", tag, (void*)xio);
  return tag;
}


/*=== Function ===================================================*/

int FCIORead(FCIOStream x, int size, void *data)

/*--- Description ------------------------------------------------//

Read a data item of size bytes length into the buffer data.

Returns tmio frame_size (in bytes) on success or <0 on error

//----------------------------------------------------------------*/
{
  if (!x) return -1;

  tmio_stream *xio=(tmio_stream *)x;

  int frame_size = tmio_read_data(xio, data, size);
  if (debug > 5)
    fprintf(stderr,"FCIORead/DEBUG: size %d/%d @ %p \n",
      frame_size, size, (void*)xio);

  if (debug) {
    if (debug > 1 && frame_size == -2) {
      fprintf(stderr, "FCIORead/WARNING: got unexpected tag or read size < 0 (%d)\n", size);
    }
    if (frame_size == -1)
      fprintf(stderr,"FCIORead/ERROR: %s size %d/%d @ %p\n",
        tmio_status_str(xio), frame_size,size, (void*)xio);
  }
  return frame_size;
}


/*--- Structures  -----------------------------------------------*/

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

//----------------------------------------------------------------*/


// Forward declarations
int FCIOSelectStateTag(FCIOStateReader *reader, int tag);


/*=== Function ===================================================*/

FCIOStateReader *FCIOCreateStateReader(
  const char *peer,
  int io_timeout,
  int io_buffer_size,
  unsigned int state_buffer_depth)

/*--- Description ------------------------------------------------//

Returns a FCIOStateReader struct on success or NULL on error.

//----------------------------------------------------------------*/
{
  FCIOStateReader *reader = (FCIOStateReader *) calloc(1, sizeof(FCIOStateReader));
  if (!reader) {
    if (debug)
      fprintf(stderr,"FCIOCreateStateReader/ERROR: failed to allocate structure\n");

    return (FCIOStateReader *) NULL;
  }

  reader->timeout = io_timeout;
  reader->stream = (void *) FCIOConnect(peer, 'r', io_timeout, io_buffer_size);
  if (!reader->stream) {
    if (debug)
      fprintf(stderr, "FCIOCreateStateReader/ERROR: failed to connect to data source %s\n", peer ? peer : "(NULL)");

    free(reader);
    return (FCIOStateReader *) NULL;
  }

  FCIOSelectStateTag(reader, 0);

  reader->max_states = state_buffer_depth + 1;
  reader->states = (FCIOState*) calloc(state_buffer_depth + 1, sizeof(FCIOState));
  reader->configs = (fcio_config*) calloc(state_buffer_depth + 1, sizeof(fcio_config));
  reader->events = (fcio_event*) calloc(state_buffer_depth + 1, sizeof(fcio_event));
  reader->statuses = (fcio_status*) calloc(state_buffer_depth + 1, sizeof(fcio_status));
  reader->recevents = (fcio_recevent*) calloc(state_buffer_depth + 1, sizeof(fcio_recevent));

  if (reader->states && reader->configs && reader->events && reader->statuses && reader->recevents)
    return reader;  // Success

  // Clean up
  if (reader->recevents)
    free(reader->recevents);
  if (reader->statuses)
    free(reader->statuses);
  if (reader->events)
    free(reader->events);
  if (reader->configs)
    free(reader->configs);
  if (reader->states)
    free(reader->states);
  FCIODisconnect(reader->stream);
  free(reader);
  return (FCIOStateReader *) NULL;
}


/*=== Function ===================================================*/

int FCIODestroyStateReader(FCIOStateReader *reader)

/*--- Description ------------------------------------------------//

Returns 0 on success or <0 on error.

//----------------------------------------------------------------*/
{
  if (!reader)
    return -1;

  FCIODisconnect(reader->stream);
  free(reader->recevents);
  free(reader->statuses);
  free(reader->events);
  free(reader->configs);
  free(reader->states);
  free(reader);

  return 0;
}


/*=== Function ===================================================*/

int FCIOSelectStateTag(FCIOStateReader *reader, int tag)

/*--- Description ------------------------------------------------//

Returns 0 on success or <0 on error.

//----------------------------------------------------------------*/
{
  if (!tag)
    reader->selected_tags = 0xffffffff;
  else if (tag > 0 && tag <= 31)
    reader->selected_tags |= (1 << tag);
  else
    return -1;

  return 0;
}


/*=== Function ===================================================*/

int FCIODeselectStateTag(FCIOStateReader *reader, int tag)

/*--- Description ------------------------------------------------//

Returns 0 on success or <0 on error.

//----------------------------------------------------------------*/
{
  if (!tag)
    reader->selected_tags = 0;
  else if (tag > 0 && tag <= 31)
    reader->selected_tags &= ~(1 << tag);
  else
    return -1;

  return 0;
}


static int tag_selected(FCIOStateReader *reader, int tag)
{
  if (tag <= 0 || tag > 31)
    return 0;

  return reader->selected_tags & (1 << tag);
}

/*=== Function ===============================================================*/

int FCIOWaitMessage(FCIOStream x, int tmo)

/*--- Description ------------------------------------------------------------//

This function is useful in case the coarse timeout set for I/O operations is
not sufficient for fine-grained waiting and polling.

If timeout is greater than zero, it specifies a maximum interval (in
milliseconds) to wait for data to arrive. If timeout is 0, then FCIOWaitMessage()
will return without blocking -- use this to quickly check for data in the
input buffers. If the value of timeout is -1, the poll blocks indefinitely.

In the current implementation the timeout is restarted on the arrival of each
frame.

//--- Return values ----------------------------------------------------------//

-1 an error occured or the connection is broken
 0 no input data is present after the given timeout
 1 message is present

//----------------------------------------------------------------------------*/
{
  if (!x) return -1;
  tmio_stream *xio=(tmio_stream *)x;

  return tmio_wait(xio, tmo);
}


static int get_next_record(FCIOStateReader *reader, int timeout)
{
  if (!reader)
    return -1;

  FCIOStream stream = reader->stream;
  if (!stream)
    return -1;

  switch (FCIOWaitMessage(stream, timeout)) {
    case 1: break;
    case 0: return 0;
    default: return -1;
  }

  int tag = FCIOReadMessage(stream);
  if (debug > 4)
    fprintf(stderr, "get_next_record: got tag %d \n", tag);

  if (tag <= 0)
    return tag;

  fcio_config *config = reader->nconfigs ? &reader->configs[(reader->cur_config + reader->max_states - 1) % reader->max_states] : NULL;
  fcio_event *event = reader->nevents ? &reader->events[(reader->cur_event + reader->max_states - 1) % reader->max_states] : NULL;
  fcio_status *status = reader->nstatuses ? &reader->statuses[(reader->cur_status + reader->max_states - 1) % reader->max_states] : NULL;
  fcio_recevent *recevent = reader->nrecevents ? &reader->recevents[(reader->cur_recevent + reader->max_states - 1) % reader->max_states] : NULL;

  int rc = 0;
  switch (tag) {
  case FCIOConfig:
    config = &reader->configs[reader->cur_config];
    rc = fcio_get_config(stream, config);

    reader->cur_config = (reader->cur_config + 1) % reader->max_states;
    reader->nconfigs++;
    break;

  case FCIOEvent:
    event = &reader->events[reader->cur_event];
    rc = fcio_get_event(stream, event, config->adcs + config->triggers);

    if (config) {
      for (int i = 0; i < config->adcs + config->triggers; i++) {
        event->trace[i] = &event->traces[2 + i * (config->eventsamples + 2)];
        event->theader[i] = &event->traces[i * (config->eventsamples + 2)];
      }
    } else if (debug > 1) {
      fprintf(stderr, "FCIOGetState/WARNING Received event without known configuration. Unable to adjust trace pointers.\n");
    }

    reader->cur_event = (reader->cur_event + 1) % reader->max_states;
    reader->nevents++;
    break;

  case FCIOSparseEvent:
    event = &reader->events[reader->cur_event];
    if (config) {
      rc = fcio_get_sparseevent(stream, event, config->eventsamples + 2);

      for (int i = 0; i < event->num_traces; i++) {
        int j = event->trace_list[i];
        event->trace[j] = &event->traces[2 + j * (config->eventsamples + 2)];
        event->theader[j] = &event->traces[j * (config->eventsamples + 2)];
      }
    } else if (debug > 1) {
      fprintf(stderr, "FCIOGetState/WARNING Received sparse event without known configuration. Unable to adjust trace pointers.\n");
    }

    reader->cur_event = (reader->cur_event + 1) % reader->max_states;
    reader->nevents++;
    break;

  case FCIORecEvent:
    recevent = &reader->recevents[reader->cur_recevent];
    rc = fcio_get_recevent(stream, recevent);

    reader->cur_recevent = (reader->cur_recevent + 1) % reader->max_states;
    reader->nrecevents++;
    break;

  case FCIOStatus:
    status = &reader->statuses[reader->cur_status];
    rc = fcio_get_status(stream, status);

    reader->cur_status = (reader->cur_status + 1) % reader->max_states;
    reader->nstatuses++;
    break;

  case FCIOEventHeader:
    event = &reader->events[reader->cur_event];
    if (config) {
      rc = fcio_get_eventheader(stream, config, event);

      for (int i = 0; i < event->num_traces; i++) {
        int j = event->trace_list[i];
        event->trace[j] = &event->traces[2 + j * (config->eventsamples + 2)];
        event->theader[j] = &event->traces[j * (config->eventsamples + 2)];
      }
    } else {
      fprintf(stderr, "[WARNING] Received event header without known configuration. Unable to adjust trace pointers.\n");
    }

    reader->cur_event = (reader->cur_event + 1) % reader->max_states;
    reader->nevents++;
    break;
  }

  if (rc < 0)
    return -1;

  // Fill current state buffer
  FCIOState *state = &reader->states[reader->cur_state];
  state->config = config;
  state->event = event;
  state->status = status;
  state->recevent = recevent;
  state->last_tag = tag;

  // Advance state buffer
  if (tag_selected(reader, tag)) {
    reader->cur_state = (reader->cur_state + 1) % reader->max_states;
    reader->nrecords++;
  }

  return tag;
}


static inline FCIOState *get_last_state(FCIOStateReader *reader)
{
  return &reader->states[(reader->cur_state + reader->max_states - 1) % reader->max_states];
}


/*=== Function ===================================================*/

FCIOState *FCIOGetState(FCIOStateReader *reader, int offset, int *timedout)

/*--- Description ------------------------------------------------//

Returns a valid FCIOState on succes, NULL on error.
If an error has occured the reason can be retrieved from timedout,
with 0 indicating a stream error, 1 a timeout and 2 arrival of deselected
tags within the timeout.

//----------------------------------------------------------------*/
{
  if (timedout)
    *timedout = 0;

  if (debug > 4)
    fprintf(stderr, "FCIOGetState(reader, %i): max_states=%i, cur_state=%i\n", offset, reader->max_states, reader->cur_state);

  if (!reader)
    return NULL;

  if (!offset)
    return get_last_state(reader);

  if (offset < 0) {
    if (-offset >= reader->nrecords || -offset > reader->max_states - 1) {
      if (debug > 4)
        fprintf(stderr, "FCIOGetState: Requested event %i not in buffer.\n", offset);
      return NULL;
    }

    int i = (reader->cur_state + reader->max_states - 1 + offset) % reader->max_states;
    if (debug > 4)
      fprintf(stderr, "FCIOGetState: Returning state %i.\n", i);
    return &reader->states[i];
  }

  // Read new data from stream
  if (debug > 4)
    fprintf(stderr, "FCIOGetState: Trying to read %i records from stream...\n", offset);

  int tag = 0;
  int timeout = reader->timeout;
  double start_time = reader->timeout > 0 ? elapsed_time(0.0) : 0.0;  // track time only when a timeout is requested
  while ((tag = get_next_record(reader, timeout)) && tag > 0) {
    if (!tag_selected(reader, tag)) {
      if (timedout)
        *timedout = 2;  // deselected tags arrived

      // Avoid infinitely waiting for a selected tag when there are other records in between
      // that always arrive within the given timeout
      if (reader->timeout > 0) {
        double elapsed_msec = 1000.0 * elapsed_time(start_time);
        timeout = reader->timeout - elapsed_msec + 0.5;
        if (timeout < 0) {
          tag = 0;
          break;  // avoid passing -1 (wait indefinitely) to tmio_wait
        }
      }

      continue;  // skip tag
    }

    if (!--offset) {
      if (timedout)
        *timedout = 0;  // timedout may have been set to 2 from an interleaved deselected tag

      if (debug > 4)
        fprintf(stderr, "FCIOGetState: Found record [cur_state=%i, config=%p, event=%p, status=%p, recevent=%p].\n", reader->cur_state,
          (void*)get_last_state(reader)->config,
          (void*)get_last_state(reader)->event,
          (void*)get_last_state(reader)->status,
          (void*)get_last_state(reader)->recevent);

      return get_last_state(reader);
    }
  }

  if (tag == 0) {
    if (timedout && !*timedout)
      *timedout = 1;  // no deselected tags arrived before timeout was reached - otherwise timedout = 2
    return NULL;
  }

  // End-of-stream has been reached
  if (debug > 4)
    fprintf(stderr, "FCIOGetState: End-of-stream reached with %i events outstanding.\n", offset);
  return NULL;
}

/*=== Function ===================================================*/

FCIOState *FCIOGetNextState(FCIOStateReader *reader, int *timedout)

/*--- Description ------------------------------------------------//

Calls FCIOGetState with offset == 1.

//----------------------------------------------------------------*/
{
  return FCIOGetState(reader, 1, timedout);
}

/*=== Function ===================================================*/

int FCIOPutState(FCIOStream output, FCIOState* state, int tag)

/*--- Description ------------------------------------------------//

Returns 0 on success or <0 on error.

//----------------------------------------------------------------*/
{
  if (!output || !state)
    return -1;

  if (tag == 0)
    tag = state->last_tag;

  switch (tag) {
    case FCIOEvent:
      return fcio_put_event(output, state->config, state->event);

    case FCIOSparseEvent:
      return fcio_put_sparseevent(output, state->config, state->event);

    case FCIORecEvent:
      return fcio_put_recevent(output, state->config, state->recevent);

    case FCIOConfig:
      return fcio_put_config(output, state->config);

    case FCIOStatus:
      return fcio_put_status(output, state->status);

    case FCIOEventHeader:
      return fcio_put_eventheader(output, state->config, state->event);
  }
  return -2;

}


/* The following functions need refactoring (lots of duplicate code with FCIOGetState).
FCIOState *FCIOGetEvent(FCIOStateReader *reader, int offset)
{
  if (debug > 4)
    fprintf(stderr, "FCIOGetEvent(reader, %i): max_states=%i, cur_state=%i\n", offset, reader->max_states, reader->cur_state);

  if (!reader || (offset <= 0 && !reader->nevents))
    return NULL;

  if (offset <= 0) {
    if (-offset >= reader->nevents || -offset > reader->max_states - 1) {
      if (debug > 4)
        fprintf(stderr, "FCIOGetEvent: Requested event %i not in buffer.\n", offset);
      return NULL;
    }

    // TODO: Implement shortcut when only the FCIOEvent tag is selected
    int i = 0;
    int nevents = 0;
    while (-i <= reader->max_states - 1 && -i <= reader->nrecords) {
      if (reader->states[(reader->cur_state + reader->max_states - 1 + i) % reader->max_states].last_tag == FCIOEvent &&
          ++nevents == -offset + 1)
        return &reader->states[(reader->cur_state + reader->max_states - 1 + i) % reader->max_states];

      i--;
    }
  }

  // Read new data from stream
  if (debug > 4)
    fprintf(stderr, "FCIOGetEvent: Trying to read %i events from stream...\n", offset);

  int tag = 0;
  while ((tag = get_next_record(reader)) && tag >= 0) {
    if (tag != FCIOEvent) {
      if (debug > 4)
        fprintf(stderr, "FCIOGetEvent: Skipping record %i...\n", tag);
      continue;
    }

    if (!--offset) {
      if (debug > 4)
        fprintf(stderr, "FCIOGetEvent: Found event [cur_state=%i, config=%p, calib=%p, event=%p, status=%p].\n", reader->cur_state,
          get_last_state(reader)->config,
          get_last_state(reader)->calib,
          get_last_state(reader)->event,
          get_last_state(reader)->status);
      return get_last_state(reader);
    }
  }

  // End-of-stream has been reached
  if (debug > 4)
    fprintf(stderr, "FCIOGetState: End-of-stream reached with %i events outstanding.\n", offset);
  return NULL;
}

FCIOState *FCIOGetNextEvent(FCIOStateReader *reader)
{
  return FCIOGetEvent(reader, 1);
}
*/

/*+++ Header +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#ifdef __cplusplus
}
#endif // __cplusplus

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
