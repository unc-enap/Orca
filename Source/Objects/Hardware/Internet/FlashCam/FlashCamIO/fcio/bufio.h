/*
 * bufio: buffered I/O for Unix streams
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Contact:
 * - main authors: felix.werner@mpi-hd.mpg.de
 * - upstream URL: https://www.mpi-hd.mpg.de/hinton/software
 */


#ifndef __BUFIO_H__
#define __BUFIO_H__

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif  // __cplusplus

// Default buffer size in byte.
#define BUFIO_BUFSIZE (256 * 1024)

typedef enum {
  BUFIO_INVALID_TYPE = 0,  // Uninitialised
  BUFIO_SOCKET,            // TCP or UDP socket
  BUFIO_FILE,              // File or named pipe
  BUFIO_LOCKEDFILE,        // File or named pipe with locking
  BUFIO_PIPE,              // Standard stream (stdin, stdout)
  BUFIO_FIFO,              // Named pipe (FIFO)
  BUFIO_LISTEN_SOCKET  // TCP socket which is not accepted yet
} bufio_stream_type;

typedef enum {
  BUFIO_EPIPE = -1,    // Device or socket has been disconnected or an I/O error occured
  BUFIO_OKAY = 0,      // Success
  BUFIO_TIMEDOUT = 1,  // Poll or I/O operation timed out
  BUFIO_EOF = 2        // Reached end-of-file
} bufio_stream_status;

typedef struct {
  bufio_stream_type type;  // Type of stream
  int status;  // Status of stream (negative: -errno of the last failed
               // operation, otherwise a bufio_stream_status)
  int mode;    // Open mode, e.g., O_RDONLY, O_WRONLY, O_RDWR, O_NONBLOCK; see
               // fopen(3) for a complete list of possible values
  int fd;      // File descriptor
  int has_write_lock;     // Process holds write lock after previous end of file
  int write_lock_offset;  // Number of bytes written since acquisition of write
                          // lock
  int has_read_lock;      // Process holds read lock of the region-to-read
  int read_lock_offset;   // Number of bytes read since acquisition of read lock
  int io_timeout_ms;      // Timeout for I/O and poll operations in ms
  char *input_buffer_base;    // Pointer to input buffer
  size_t input_buffer_size;   // Size of input buffer
  size_t input_buffer_head;   // Start of buffered input
  size_t input_buffer_tail;   // End of buffered input
  size_t input_buffer_fill;   // Number of buffered bytes
  char *output_buffer_base;   // Pointer to output buffer
  size_t output_buffer_size;  // Size of output buffer
  size_t output_buffer_tail;  // End of buffered data
} bufio_stream;

bufio_stream *bufio_open(const char *peername, const char *opt, int timeout,
                         int bufsize, const char *info);

size_t bufio_read(bufio_stream *stream, void *ptr, size_t size);

size_t bufio_write(bufio_stream *stream, const void *ptr, size_t size);

int bufio_flush(bufio_stream *stream);

int bufio_sync(bufio_stream *stream);

int bufio_wait(bufio_stream *stream, int timeout);

int bufio_close(bufio_stream *stream);

int bufio_timeout(bufio_stream *stream, int msec);

int bufio_type(bufio_stream *stream);

int bufio_status(bufio_stream *stream);

const char *bufio_status_str(bufio_stream *stream);

int bufio_fileno(bufio_stream *stream);

int bufio_clear_status(bufio_stream *stream);

#ifdef __cplusplus
}
#endif  // __cplusplus

#endif
