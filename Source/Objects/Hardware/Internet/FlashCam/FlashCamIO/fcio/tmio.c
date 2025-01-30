/*
 * tmio: tagged message I/O for Unix streams
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Contact:
 * - main authors: felix.werner@mpi-hd.mpg.de
 * - upstream URL: https://www.mpi-hd.mpg.de/hinton/software
 */


/*==> tmio: tagged message I/O ===============================================//

Version: 0.93
Date:    2015
Authors: Thomas Kihm, Felix Werner

//--- Copyright --------------------------------------------------------------//

This software is furnished under a license and may be used and copied only in
accordance with the terms of such license and with the inclusion of the above
copyright notice.

This software or any other copies thereof may not be provided or otherwise
made available to any other person. No title to and ownership of the software
is hereby transferred.

//==> General information ====================================================//

This library provides a tagged message I/O model on top of TCP streams, Unix
standard streams, or files with and without locking.

A message is composed of a tag, specifying the type of the message, and one or
more data payloads of known size. A writer issues `tmio_write_tag` followed by
any number of calls to `tmio_write_data`. A reader typically uses `tmio_read_tag`
to skip to the next tag, followed by any number of calls to `tmio_read_data`.
For fine-grained polling, `tmio_wait` can be used to wait for the next tag with
a specified timeout.

Any stream errors or protocol timeouts will make the stream inoperable. A
protocol timeout occurs in the following conditions:

 1. a write operation (`tmio_write_tag`, `tmio_write_data`, `tmio_flush`,
    `tmio_sync`) timed out
 2. `tmio_read_data` timed out

To make sure that a reader does not run into condition (2), a writer must
issue `tmio_flush` within the protocol timeout after writing one or more tags
and data frames. The protocol timeout is initially set when creating the
context with `tmio_init` and can be changed at any time with `tmio_timeout`.

The stream is made inoperable to (a) force the application to actively handle
stream errors and (b) to simplify application code, as the user is able to
group a number of associated operations and check for errors afterwards. It is
the application's responsibility to resynchronise with the other end after a
stream error or protocol timeout.

The error handling of tmio is generally POSIX-like: if an error occurs, a
function returns either `NULL` (when returning a pointer) or -1. A status code
and description can then be retrieved with `tmio_status` and `tmio_status_str`,
similar to `errno` and `strerror(3)` but permanently associated with the stream
context. Success is indicated with a valid pointer or an integer >=0 (e.g.,
`tmio_write_data` and `tmio_read_data` return the number of bytes written/read).

//----------------------------------------------------------------------------*/

#include <assert.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

/*+++ Header +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

// Protocol definitions
// Maximum size of the protocol string: 63 characters plus one termination byte
#define TMIO_PROTOCOL_SIZE (64)
// Maximum tag that can be used for `tmio_write_tag` (1000000000)
#define TMIO_MAX_TAG (1000000000)
// Internal: protocol identifier
#define TMIO_PROTOCOL_TAG -(TMIO_MAX_TAG + 1)

// Default values
#define TMIO_DEFAULT_TIMEOUT (-1)

// Buffer sizes
#define TMIO_SKIPBUF_SIZE (1024)

// State flags
#define TMIO_WRITING (1 << 0)

// Status codes. A negative value indicates an unrecoverable error (inoperable
// stream).
typedef enum {
  TMIO_OKAY = 0,  // No error
  TMIO_ENOTCONN = -1,  // Stream is not connected
  TMIO_EREAD = -2,  // Error occured during read operation
  TMIO_EWRITE = -3,  // Error occured during write operation
  TMIO_EFLUSH = -4,  // Error occured during flush operation
  TMIO_ETIMEDOUT = -5,  // Protocol timeout occured
  TMIO_EHANDSHAKE = -6,  // Handshake failed
  TMIO_EPROTO = -7  // Protocol mismatch
} tmio_stream_status;

// Stream types
typedef enum {
  TMIO_INVALID_TYPE = 0,  // Uninitialised
  TMIO_FILE = 1,  // File or named pipe
  TMIO_SOCKET = 2,  // TCP socket
  TMIO_PIPE = 3  // Standard stream (stdin, stdout)
} tmio_stream_type;

// Main tmio data structure.
typedef struct {
  void *f;  // Pointer to underlying I/O structure

  int debug;  // Verbosity
  int protocol_timeout;  // Protocol timeout in milliseconds
  int hasbufferedheader;  // tmio_read_data or tmio_wait encountered and buffered a tag
  int bufferedheader;  // Tag buffered by tmio_read_data or tmio_wait
  int mustflush;  // Flag to indicate unflushed output data
  int state;  // Bit pattern of current state (currently 0 or TMIO_WRITING)
  tmio_stream_status status;  // Current status of the stream
  tmio_stream_type type;  // Type of the stream
  int iobufsize;  // Size of the I/O buffer in Byte

  char protocol[TMIO_PROTOCOL_SIZE];  // Protocol identifier
  char skipbuf[TMIO_SKIPBUF_SIZE];  // Scratch buffer used for skipping data frames

  // Statistics
  int flushes;
  int tagwrites;
  int tagreads;
  int datawrites;
  int datareads;
  int datashorts;
  int datatruncs;
  int datazero;
  int datamissing;
  int dataskipped;
  int tagsskipped;
} tmio_stream;

/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/

// Backend abstraction layer: currently only bufio provides all functions
// TODO: Remove this abstraction. (Otherwise: include bufio_status.)
#include <bufio.h>

#define buftcpopen(n, o, t, b, d) bufio_open(n, o, t, b, d)
#define buftcptimeout(x, t) bufio_timeout(x, t)
#define buftcpwait(x, t) bufio_wait(x, t)

#define buftcpfile bufio_stream
#define buftcpwrite(p, s, f) ((bufio_write(f, p, s) < (size_t) s) ? 0 : s)
#define buftcpread(p, s, f) ((bufio_read(f, p, s) < (size_t) s) ? 0 : s)
#define buftcpflush(f) bufio_flush(f)
#define buftcpsync(f) bufio_sync(f)
#define buftcpclose(f) bufio_close(f)

#define buftcptype(f) bufio_type(f)
#define BUFTCPFILETYPE BUFIO_FILE
#define BUFTCPSOCKETTYPE BUFIO_SOCKET
#define BUFTCPPIPETYPE BUFIO_PIPE

/*=== Function ===============================================================*/

tmio_stream *tmio_init(const char *protocol, int protocol_timeout, int bufkb,
                       int debug)

/*--- Description ------------------------------------------------------------//

Initialise a tmio context.

protocol is the protocol name. Maximum length is 63 chars and a termination
null byte. tmio_open will compare at most strlen(protocol) characters of the
protocol to that of the corresponding party and fail on any mismatch. On a
successful (possibly partial) match, the full protocol string can be obtained
with tmio_protocol.

protocol_timeout sets the initial timeout for handshaking and I/O operations.
Use tmio_timeout to change this timeout.

bufkb may be used to initialize the size (in kB) of the protocol buffers. If 0
is specified a default value will be used.

debug can be set from 0 to 3 for no logging to very verbose logging.

//--- Return values ----------------------------------------------------------//

Returns a pointer to a tmio_stream context structure which must be specified
in any other calls to this library. Use tmio_open or tmio_create to connect a
stream. Use tmio_delete to properly close a connection and deallocate the
structure.

If an allocation error occurs, NULL is returned.

The returned structure is visible but internal details and naming might change
in future revisions.

//----------------------------------------------------------------------------*/
{
  tmio_stream *stream = (tmio_stream *) calloc(1, sizeof(tmio_stream));
  if (stream == NULL)
    return NULL;

  // Populate structure
  stream->status = TMIO_ENOTCONN;
  stream->debug = debug;
  stream->iobufsize = bufkb > 0 ? bufkb * 1024 : 0;
  stream->protocol_timeout = protocol_timeout;
  strncpy(stream->protocol, protocol, strlen(protocol) < TMIO_PROTOCOL_SIZE - 1
                                          ? strlen(protocol)
                                          : TMIO_PROTOCOL_SIZE - 1);

  if (debug > 1)
    fprintf(stderr, "tmio_init: context initialized with protocol %s\n",
            stream->protocol);

  return stream;
}


/* Internal helper function to:
   - set stream pointer
   - set timeout
   - set type
   - set initial status */
static int tmio_init_stream(tmio_stream *stream, buftcpfile *fp)
{
  stream->f = (void *) fp;
  stream->status = TMIO_OKAY;
  buftcptimeout(fp, stream->protocol_timeout);

  // Interpret type and set corresponding mode
  switch (buftcptype(fp)) {
    case BUFTCPFILETYPE:
      stream->type = TMIO_FILE;
      break;

    case BUFTCPSOCKETTYPE:
      stream->type = TMIO_SOCKET;
      break;

    case BUFTCPPIPETYPE:
      stream->type = TMIO_PIPE;
      break;

    default:
      stream->type = TMIO_INVALID_TYPE;
  }

  return 0;
}


/*=== Function ===============================================================*/

int tmio_close(tmio_stream *stream)

/*--- Description ------------------------------------------------------------//

Flushes and closes a previously opened or created stream. Resets status and
statistics.

//--- Return values ----------------------------------------------------------//

Returns 0.

//----------------------------------------------------------------------------*/
{
  buftcpfile *fp = (buftcpfile *) stream->f;
  if (fp) {
    buftcpflush(fp);
    buftcpclose(fp);
    fp = NULL;
  }

  // Reset stream
  stream->f = NULL;
  stream->state = 0;
  stream->status = TMIO_ENOTCONN;
  stream->type = TMIO_INVALID_TYPE;
  stream->hasbufferedheader = 0;
  stream->bufferedheader = 0;
  stream->mustflush = 0;

  // Reset statistics
  stream->flushes = 0;
  stream->tagwrites = 0;
  stream->tagreads = 0;
  stream->datawrites = 0;
  stream->datareads = 0;
  stream->datashorts = 0;
  stream->datatruncs = 0;
  stream->datazero = 0;
  stream->datamissing = 0;
  stream->dataskipped = 0;
  stream->tagsskipped = 0;

  return 0;
}


/*=== Function ===============================================================*/

int tmio_delete(tmio_stream *stream)

/*--- Description ------------------------------------------------------------//

Closes I/O stream and frees stream.

//--- Return values ----------------------------------------------------------//

Returns 0.

//----------------------------------------------------------------------------*/
{
  tmio_close(stream);
  free(stream);

  return 0;
}


/*=== Function ===============================================================*/

int tmio_create(tmio_stream *stream, const char *name, int connect_timeout)

/*--- Description ------------------------------------------------------------//

Creates a connection or file, with name being a plain file name, "-" for
stdout, or

tcp://listen/port           to listen to port at all interfaces
tcp://listen/port/nodename  to listen to port at nodename interface
tcp://connect/port/nodename to listen to port and nodename

If a file is created or stdout is specified it is set to write only. An
existing file is truncated and overwritten. A previously opened connection is
closed first.

connect_timeout specifies the time to wait for a connection in milliseconds.
Specify 0 to return immediately (within the typical delays imposed by the
connection and OS) or -1 to block indefinitely.

//--- Return values ----------------------------------------------------------//

Returns the stream type (TMIO_FILE, TMIO_SOCKET, TMIO_PIPE) on success. If an
error occurs, -1 is returned and the error code can be retrieved with
tmio_status.

//--- Errors -----------------------------------------------------------------//

TMIO_ENOTCONN   Error while connecting
TMIO_EHANDSHAKE Error while writing protocol

//----------------------------------------------------------------------------*/
{
  tmio_close(stream);

  if (stream->debug > 2)
    fprintf(stderr, "tmio_create: creating stream %s\n", name);

  buftcpfile *fp = buftcpopen(name, "w", connect_timeout, stream->iobufsize,
                              stream->debug > 2 ? "tmio_create/bufio_open" : 0);
  if (fp == NULL) {
    stream->status = TMIO_ENOTCONN;
    if (stream->debug)
      fprintf(stderr, "tmio_create: can not connect peer/file %s\n", name);

    return -1;
  }

  tmio_init_stream(stream, fp);

  // Send protocol
  int protocol_tag = TMIO_PROTOCOL_TAG;
  if (buftcpwrite(&protocol_tag, sizeof(protocol_tag), fp) !=
          sizeof(protocol_tag) ||
      buftcpwrite(stream->protocol, TMIO_PROTOCOL_SIZE, fp) !=
          TMIO_PROTOCOL_SIZE ||
      buftcpflush(fp) != 0) {
    if (stream->debug > 0)
      fprintf(stderr, "tmio_create: can not send protocol %s\n",
              stream->protocol);

    stream->status = TMIO_EHANDSHAKE;
    tmio_close(stream);
    return -1;
  }

  if (stream->debug > 1)
    fprintf(stderr, "tmio_create: connected file/peer %s\n", name);

  return stream->type;
}


/*=== Function ===============================================================*/

int tmio_open(tmio_stream *stream, const char *name, int connect_timeout)

/*--- Description ------------------------------------------------------------//

Opens a connection or file. name can be a plain file name, "-" for stdin, or

tcp://listen/port           to listen to port at all interfaces
tcp://listen/port/nodename  to listen to port at nodename interface
tcp://connect/port/nodename to listen to port and nodename

If a file or stdin is opened it is set to read only. A previously opened
connection is closed first.

connect_timeout specifies the time to wait for a connection in milliseconds.
Specify 0 to return immediately (within the typical delays imposed by the
connection and OS) or -1 to block indefinitely.

//--- Return values ----------------------------------------------------------//

Returns the stream type (TMIO_FILE, TMIO_SOCKET, TMIO_PIPE) on success. If an
error occurs, -1 is returned and the error code can be retrieved with
tmio_status.

//--- Errors -----------------------------------------------------------------//

TMIO_ENOTCONN   Error while connecting
TMIO_EHANDSHAKE Error while reading protocol
TMIO_EPROTO     Protocols do not match

//----------------------------------------------------------------------------*/
{
  tmio_close(stream);

  if(stream->debug > 2)
    fprintf(stderr, "tmio_open: opening stream %s\n", name);

  buftcpfile *fp = buftcpopen(name, "r", connect_timeout, stream->iobufsize,
                              stream->debug > 2 ? "tmio_open/buftcpopen" : 0);
  if (fp == NULL) {
    stream->status = TMIO_ENOTCONN;
    if (stream->debug)
      fprintf(stderr,"tmio_open: can not connect peer/file %s\n",name);

    return -1;
  }

  tmio_init_stream(stream, fp);

  // Read protocol
  int protocol_tag;
  char protocol[TMIO_PROTOCOL_SIZE];
  if (buftcpread(&protocol_tag, sizeof(protocol_tag), fp) !=
          sizeof(protocol_tag) ||
      protocol_tag != TMIO_PROTOCOL_TAG ||
      buftcpread(protocol, TMIO_PROTOCOL_SIZE, fp) != TMIO_PROTOCOL_SIZE) {
    stream->status = TMIO_EHANDSHAKE;
    if (stream->debug)
      fprintf(stderr, "tmio_open: protocol handshake failed\n");

    tmio_close(stream);
    return -1;
  }

  // Sanitise input
  protocol[TMIO_PROTOCOL_SIZE - 1] = 0;

  // Compare up to strlen(requested protocol) bytes
  if (strncmp(protocol, stream->protocol,
              strlen(stream->protocol) < TMIO_PROTOCOL_SIZE
                  ? strlen(stream->protocol)
                  : TMIO_PROTOCOL_SIZE) != 0) {
    stream->status = TMIO_EPROTO;
    if (stream->debug)
      fprintf(stderr, "tmio_open: peer/file has wrong protocol %s\n", protocol);

    tmio_close(stream);
    return -1;
  }

  // Copy protocol from peer
  strncpy(stream->protocol, protocol, TMIO_PROTOCOL_SIZE);

  if (stream->debug > 1)
    fprintf(stderr, "tmio_open: connected file/peer %s\n", name);

  return stream->type;
}


/* Internal helper function to set the status of the tmio stream from the
   status of the bufio stream. */
void tmio_set_status(tmio_stream *stream, tmio_stream_status def)
{
  switch (bufio_status((bufio_stream *) stream->f)) {
    case BUFIO_TIMEDOUT:
    case BUFIO_EOF:
      stream->status = TMIO_ETIMEDOUT;
      break;

    default:
      stream->status = def;
  }
}


/*=== Function ===============================================================*/

int tmio_write_tag(tmio_stream *stream, int tag)

/*--- Description ------------------------------------------------------------//

Start output of a record with the given tag. tag must be >0 and <=1000000
(TMIO_MAX_TAG).

//--- Return values ----------------------------------------------------------//

Returns 0 on success. If an error occurs, -1 is returned and the error code
can be retrieved with tmio_status.

//--- Errors -----------------------------------------------------------------//

TMIO_EWRITE    A write error occured
TMIO_ETIMEDOUT Write operation timed out

//----------------------------------------------------------------------------*/
{
  buftcpfile *fp = (buftcpfile *) stream->f;

  if (tag <= 0 || tag > TMIO_MAX_TAG || stream->status < 0)
    return -1;

  stream->mustflush = 1;
  int write_tag = -tag;
  if (buftcpwrite(&write_tag, sizeof(int), fp) < (int) sizeof(int)) {
    tmio_set_status(stream, TMIO_EWRITE);
    return -1;
  }

  stream->state |= TMIO_WRITING;
  stream->tagwrites++;
  return 0;
}


/*=== Function ===============================================================*/

int tmio_write_data(tmio_stream *stream, void *data, int size)

/*--- Description ------------------------------------------------------------//

Writes size bytes of data. If size is <0, no data will be written and 0 is
returned.

//--- Return values ----------------------------------------------------------//

Returns size on success. If an error occurs, -1 is returned and the error code
can be retrieved with tmio_status.

//--- Errors -----------------------------------------------------------------//

TMIO_EWRITE    A write error occured
TMIO_ETIMEDOUT Write operation timed out

//--- Note   -----------------------------------------------------------------//

Zero writes (i.e., if size is 0, but not if size < 0) will appear as zero
reads (tmio_read_data returns 0) on the other end.

//----------------------------------------------------------------------------*/
{
  buftcpfile *fp = (buftcpfile *) stream->f;

  if ((stream->state & TMIO_WRITING) == 0 || stream->status < 0)
    return -1;

  if (size < 0)
    return 0;

  stream->mustflush = 1;
  if (buftcpwrite(&size, sizeof(int), fp) != (int) sizeof(int) ||
      buftcpwrite(data, size, fp) != size) {
    tmio_set_status(stream, TMIO_EWRITE);
    return -1;
  }

  stream->datawrites++;
  return size;
}


/*=== Function ===============================================================*/

int tmio_flush(tmio_stream *stream)

/*--- Description ------------------------------------------------------------//

Flushes output buffer.

//--- Return values ----------------------------------------------------------//

Returns 0 on success. If an error occurs, -1 is returned and the error code
can be retrieved with tmio_status.

//--- Errors -----------------------------------------------------------------//

TMIO_EFLUSH    Error while flushing
TMIO_ETIMEDOUT Flush operation timed out

//----------------------------------------------------------------------------*/
{
  buftcpfile *fp = (buftcpfile *) stream->f;

  if (stream->mustflush) {
    if (buftcpflush(fp) != 0) {
      tmio_set_status(stream, TMIO_EFLUSH);
      return -1;
    }

    stream->flushes++;
  }

  return 0;
}


/*=== Function ===============================================================*/

int tmio_sync(tmio_stream *stream)

/*--- Description ------------------------------------------------------------//

Flushes output buffer and filesystem cache. (Thus, this function is only
useful for files.)

//--- Return values ----------------------------------------------------------//

Returns 0 on success. If an error occurs, -1 is returned and the status code
can be retrieved with tmio_status.

//--- Errors -----------------------------------------------------------------//

TMIO_EFLUSH    Error while flushing
TMIO_ETIMEDOUT Flush operation timed out

//----------------------------------------------------------------------------*/

{
  if (tmio_flush(stream) == -1)
    return -1;

  if (buftcpsync((buftcpfile *) stream->f) == -1) {
    stream->status = TMIO_EFLUSH;
    return -1;
  }

  return 0;
}


/*
  Internal helper function to skip the next frame. If a frame header has
  been buffered, skips the associated frame and clears the buffer.

  Returns 0 on success, -1 on error and sets stream status.
*/
static int tmio_skip_frame(tmio_stream *stream)
{
  buftcpfile *fp = (buftcpfile *) stream->f;

  if (stream->status < 0)
    return -1;

  int frame_header = 0;
  if (stream->hasbufferedheader) {
    frame_header = stream->bufferedheader;
    stream->bufferedheader = 0;
    stream->hasbufferedheader = 0;
  } else if (buftcpread((char *) &frame_header, sizeof(frame_header), fp) <
             (int) sizeof(frame_header)) {
    // Failed to read frame header
    tmio_set_status(stream, TMIO_EREAD);
    return -1;
  }

  if (frame_header < 0) {
    // Skip tag
    stream->tagsskipped++;
  } else {
    // Skip data frame
    int remaining_bytes = frame_header;
    while (remaining_bytes > 0) {
      int to_read = remaining_bytes < TMIO_SKIPBUF_SIZE ? remaining_bytes
                                                        : TMIO_SKIPBUF_SIZE;
      int nbytes = buftcpread(stream->skipbuf, to_read, fp);
      if (nbytes < to_read) {
        // Failed to read data frame
        tmio_set_status(stream, TMIO_EREAD);
        return -1;
      }

      assert(nbytes <= remaining_bytes);
      remaining_bytes -= nbytes;
    }

    stream->dataskipped++;
  }

  return 0;
}


/*=== Function ===============================================================*/

int tmio_wait(tmio_stream *stream, int timeout)

/*--- Description ------------------------------------------------------------//

Convenience function which flushes the output buffer and waits for the next
tag. Any data frames encountered while waiting are skipped. This function is
useful in case the coarse timeout set for I/O operations is not sufficient for
fine-grained waiting and polling.

If timeout is greater than zero, it specifies a maximum interval (in
milliseconds) to wait for data to arrive. If timeout is 0, then tmio_wait()
will return without blocking -- use this to quickly check for data in the
input buffers. If the value of timeout is -1, the poll blocks indefinitely.

In the current implementation the timeout is restarted on the arrival of each
frame.

//--- Return values ----------------------------------------------------------//

-1 an error occured or the connection is broken
 0 no input data is present after the given timeout
 1 tag is present

//--- Errors -----------------------------------------------------------------//

TMIO_EREAD     Error while reading
TMIO_EFLUSH    Error while flushing
TMIO_ETIMEDOUT Flush or read operation timed out (note that I/O operations
               within data frames work with the protocol timeout)

//----------------------------------------------------------------------------*/
{
  buftcpfile *fp = (buftcpfile *) stream->f;

  if (tmio_flush(stream) == -1)
    return -1;

  // Handle buffered frame header
  int *frame_header = &stream->bufferedheader;
  if (stream->hasbufferedheader) {
    if (*frame_header < 0)
      return 1;
    else if (tmio_skip_frame(stream) == -1)
      return -1;
  }

  int status = 0;
  while ((status = buftcpwait((buftcpfile *) stream->f, timeout)) == 1) {
    if (buftcpread((char *) frame_header, sizeof(*frame_header), fp) <
        (int) sizeof(*frame_header)) {
      // Failed to read frame header
      tmio_set_status(stream, TMIO_EREAD);
      return -1;
    }

    stream->hasbufferedheader = 1;
    if (*frame_header < 0)
      break;
    else if (tmio_skip_frame(stream) == -1)  // clears hasbufferedheader on success
      return -1;
  }

  if (status == -1)
    stream->status = TMIO_EREAD;

  return status;
}


/*=== Function ===============================================================*/

int tmio_read_tag(tmio_stream *stream)

/*--- Description ------------------------------------------------------------//

Reads a tag from the stream of data. Skips any data frames when required.
Since tags mark the beginning of a message, which in some protocols might come
with any delay, a timeout does not mark the stream inoperable.

//--- Return values ----------------------------------------------------------//

Returns the tag found. If a timeout occurs, 0 is returned. If an error occurs,
-1 is returned and the status code can be retrieved with tmio_status.

//--- Errors -----------------------------------------------------------------//

TMIO_EREAD     An error occured while reading
TMIO_ETIMEDOUT A timeout occured while skipping a data frame

//----------------------------------------------------------------------------*/
{
  buftcpfile *fp = (buftcpfile *) stream->f;

  if (stream->status < 0)
    return -1;

  if (stream->hasbufferedheader) {
    if (stream->bufferedheader < 0) {
      int tag = -stream->bufferedheader;
      stream->hasbufferedheader = 0;
      stream->bufferedheader = 0;
      stream->tagreads++;
      return tag;
    }

    if (tmio_skip_frame(stream) == -1)
      return -1;
  }

  // Skip to the next tag
  int frame_header = 0;
  while (1) {
    if (buftcpread((char *) &frame_header, sizeof(frame_header), fp) <
        (int) sizeof(frame_header)) {
      // Failed to read frame header
      if (bufio_status(fp) == BUFIO_TIMEDOUT ||
          bufio_status(fp) == BUFIO_EOF)
        return 0;

      stream->status = TMIO_EREAD;
      return -1;
    }

    if (frame_header < 0)
      break;

    stream->bufferedheader = frame_header;
    stream->hasbufferedheader = 1;
    if (tmio_skip_frame(stream) == -1)
      return -1;
  }

  stream->tagreads++;
  return -frame_header;
}


/*=== Function ===============================================================*/

int tmio_read_data(tmio_stream *stream, void *data, int size)

/*--- Description ------------------------------------------------------------//

After reading a tag you can read the associated data records. size specifies
the maximum data length in bytes. If a data record bigger than size is found
the first size bytes are copied to data and the rest of the data is skipped.
If the record found is smaller than size, the remaining part of the buffer
will be left untouched.

If a tag is found, no data is transferred.

If a timeout occurs, the stream is marked inoperable.

//--- Return values ----------------------------------------------------------//

Returns the number of bytes found in the stream (which might be more or less
than the specified size). If an error occurs, -1 is returned and the status code
can be retrieved with tmio_status. If a tag is found, -2 is returned.

//--- Errors -----------------------------------------------------------------//

TMIO_EREAD     An error occured while reading
TMIO_ETIMEDOUT The timeout was hit before a complete data frame could be read

//----------------------------------------------------------------------------*/
{
  buftcpfile *fp = (buftcpfile *) stream->f;

  if (stream->status < 0)
    return -1;

  if (size < 0 || (stream->hasbufferedheader && stream->bufferedheader < 0))
    return -2;  // Found tag

  int *frame_header = &stream->bufferedheader;
  if (buftcpread((char *) frame_header, sizeof(*frame_header), fp) <
      (int) sizeof(*frame_header)) {
    tmio_set_status(stream, TMIO_EREAD);
    return -1;
  }

  if (*frame_header < 0) {
    // Handle tag
    stream->hasbufferedheader = 1;
    stream->datamissing++;
    return -2;  // Found tag
  }

  const int frame_size = *frame_header;
  int to_read = frame_size < size ? frame_size : size;
  if (buftcpread(data, to_read, fp) < to_read) {
    tmio_set_status(stream, TMIO_EREAD);
    return -1;
  }

  // Update statistics
  stream->datareads++;
  if (frame_size > size)
    stream->datatruncs++;
  else if (frame_size < size)
    stream->datashorts++;

  int remaining_bytes = frame_size - to_read;
  while (remaining_bytes > 0) {
    // Skip remaining data
    to_read = remaining_bytes < TMIO_SKIPBUF_SIZE ? remaining_bytes
                                                  : TMIO_SKIPBUF_SIZE;
    int nbytes = buftcpread(stream->skipbuf, to_read, fp);
    if (nbytes < to_read) {
      // Failed to read data frame
      tmio_set_status(stream, TMIO_EREAD);
      return -1;
    }

    assert(nbytes <= remaining_bytes);
    remaining_bytes -= nbytes;
  }

  return frame_size;
}


/*=== Function ===============================================================*/

int tmio_status(tmio_stream *stream)

/*--- Description ------------------------------------------------------------//

Returns the last known status of stream.

//--- Return values ----------------------------------------------------------//

TMIO_OKAY (0)   No errors
TMIO_ENOTCONN   Stream is not connected or failed to connect
TMIO_EREAD      An error occured while reading
TMIO_EWRITE     An error occured while writing
TMIO_EFLUSH     An error occured while flushing the output buffer
TMIO_ETIMEDOUT  A timeout occured while reading or writing
TMIO_EHANDSHAKE An error occured during handshake
TMIO_EPROTO     A protocol mismatch or error occured

//----------------------------------------------------------------------------*/
{
  // Positive status codes are internal, return 0 in this case
  return stream->status < 0 ? stream->status : 0;
}


/*=== Function ===============================================================*/

const char *tmio_status_str(tmio_stream *stream)

/*--- Description ------------------------------------------------------------//

Returns a description of the current status code of stream.

//----------------------------------------------------------------------------*/
{
  if (stream->status >= 0)
    return "okay";
  else switch(stream->status) {
    case TMIO_ENOTCONN:   return "connection error";
    case TMIO_EREAD:      return "read error";
    case TMIO_EWRITE:     return "write error";
    case TMIO_EFLUSH:     return "flush error";
    case TMIO_ETIMEDOUT:  return "timeout";
    case TMIO_EHANDSHAKE: return "handshake error";
    case TMIO_EPROTO:     return "protocol error";
    default:              return "unknown error";
  }
}


/*=== Function ===============================================================*/

int tmio_timeout(tmio_stream *stream, int protocol_timeout)

/*--- Description ------------------------------------------------------------//

Sets the protocol timeout in milliseconds for any data exchange. Must be set
to a value which is guaranteed to be never exceeded when both ends operate
properly: a stream becomes inoperable if this time out is exceeded. If set to
-1, I/O operations will block forever.

//--- Return values ----------------------------------------------------------//

Returns the previous protocol timeout.

//----------------------------------------------------------------------------*/
{
  int old_protocol_timeout = stream->protocol_timeout;

  stream->protocol_timeout = protocol_timeout;
  buftcptimeout((buftcpfile *) stream->f, protocol_timeout);

  return old_protocol_timeout;
}


/*=== Function ===============================================================*/

const char *tmio_protocol(tmio_stream *stream)

/*--- Description ------------------------------------------------------------//

Returns a pointer to the protocol identifier.

//----------------------------------------------------------------------------*/
{
  return stream->protocol;
}


/*=== Function ===============================================================*/

int tmio_type(tmio_stream *stream)

/*--- Description ------------------------------------------------------------//

Returns the stream type (TMIO_FILE, TMIO_SOCKET, TMIO_PIPE).

//----------------------------------------------------------------------------*/
{
  return stream->type;
}


/*=== Function ===============================================================*/

int tmio_monitor(tmio_stream *stream)

/*--- Description ------------------------------------------------------------//

Prints statistics.

//----------------------------------------------------------------------------*/
{
  fprintf(stderr, "tmio_monitor: statistics\n");
  fprintf(stderr, "... tags written     %d\n", stream->tagwrites);
  fprintf(stderr, "... data records out %d\n", stream->datawrites);
  fprintf(stderr, "... tags read        %d\n", stream->tagreads);
  fprintf(stderr, "... data records in  %d\n", stream->datareads);
  fprintf(stderr, "... data flushes     %d\n", stream->flushes);
  fprintf(stderr, "... read zero        %d\n", stream->datazero);
  fprintf(stderr, "... read missing     %d\n", stream->datamissing);
  fprintf(stderr, "... read shortened   %d\n", stream->datashorts);
  fprintf(stderr, "... read truncated   %d\n", stream->datatruncs);
  fprintf(stderr, "... data skipped     %d\n", stream->dataskipped);
  fprintf(stderr, "... tags skipped     %d\n", stream->tagsskipped);

  return 0;
}

/*+++ Header +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
#ifdef __cplusplus
}
#endif // __cplusplus
/*++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++*/
