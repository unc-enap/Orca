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


#ifndef INCLUDED_tmio_h
#define INCLUDED_tmio_h

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

tmio_stream *tmio_init(const char *protocol, int protocol_timeout, int bufkb,
                       int debug)
;
int tmio_close(tmio_stream *stream)
;
int tmio_delete(tmio_stream *stream)
;
int tmio_create(tmio_stream *stream, const char *name, int connect_timeout)
;
int tmio_open(tmio_stream *stream, const char *name, int connect_timeout)
;
int tmio_write_tag(tmio_stream *stream, int tag)
;
int tmio_write_data(tmio_stream *stream, void *data, int size)
;
int tmio_flush(tmio_stream *stream)
;
int tmio_sync(tmio_stream *stream)
;
int tmio_wait(tmio_stream *stream, int timeout)
;
int tmio_read_tag(tmio_stream *stream)
;
int tmio_read_data(tmio_stream *stream, void *data, int size)
;
int tmio_status(tmio_stream *stream)
;
const char *tmio_status_str(tmio_stream *stream)
;
int tmio_timeout(tmio_stream *stream, int protocol_timeout)
;
const char *tmio_protocol(tmio_stream *stream)
;
int tmio_type(tmio_stream *stream)
;
int tmio_monitor(tmio_stream *stream)
;
#ifdef __cplusplus
}
#endif // __cplusplus

#endif
