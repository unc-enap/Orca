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


/*==> bufio: buffered I/O for Unix streams ===================================//

//==> General information ====================================================//

This library provides a thin buffering layer on top of the unified Unix I/O
model. It connects a TCP stream (as server or client), Unix standard streams,
or files and buffers all I/O operations. An interface very similar to stdio
has been implemented with additional support for polling.

//==> Caveats ================================================================//

No atexit(3) handlers are installed. The user is responsible to take care of
flushing and closing a bufio stream.

//----------------------------------------------------------------------------*/

#ifdef __linux__
#define _DEFAULT_SOURCE
#define _BSD_SOURCE
#define _POSIX_C_SOURCE 200809L
#else
#undef _POSIX_C_SOURCE
#endif

#include "bufio.h"

#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/tcp.h>
#include <netinet/in.h>
#include <poll.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>


// Thread-specific indicator whether a file locking operation timed out
static __thread volatile sig_atomic_t lock_timeout = 0;

static void lock_timeout_handler(int signo)
{
  assert(signo == SIGALRM);
  lock_timeout = 1;
}


static inline int start_timer(struct itimerval *timer, struct itimerval *otimer,
                              struct sigaction *oact,
                              void (*timeout_handler)(int))
{
  // Replace SIGALRM handler
  struct sigaction act;
  memset(&act, 0, sizeof(act));
  act.sa_handler = timeout_handler;
  act.sa_flags = SA_RESETHAND;
  sigaction(SIGALRM, &act, oact);

  return setitimer(ITIMER_REAL, timer, otimer);
}


static inline void stop_timer(struct itimerval *otimer, struct sigaction *oact)
{
  setitimer(ITIMER_REAL, otimer, NULL);
  sigaction(SIGALRM, oact, NULL);
}


/*
  bufio_lock acquires or releases a lock to a region within the underlying file
  of a stream.

  Parameters
  ----------

  lock_type: F_WRLCK (acquire exclusive lock), F_RDLCK (acquire shared lock),
             F_UNLCK (release lock)

  start: start of lock region relative to offset

  length: <0: locks bytes -length...offset - 1
          >0: locks bytes offset...length - 1

  offset: SEEK_SET (relative to start of file), SEEK_CUR (relative to current
          position), SEEK_END (relative to end of file)

  timeout: <0: blocking
            0: non-blocking
           >0: timeout in milliseconds

  Returns
  -------

  -1 error
   0 timed out
   1 success

  Caveats
  -------

  If timeout >0, temporarily removes any previously set realtime
  interval timer (ITIMER_REAL).
*/
static int bufio_lock(bufio_stream *s, int lock_type, size_t start, size_t length,
                      short offset, int timeout)
{
  int with_timeout = timeout > 0;

  struct itimerval timer, otimer;
  struct sigaction oact;
  if (with_timeout) {
    // Blocking mode
    timer.it_value.tv_sec = (time_t)(timeout / 1000);
    timer.it_value.tv_usec = (suseconds_t) ((timeout % 1000) * 1000);
    timerclear(&timer.it_interval);
    timerclear(&otimer.it_value);
    timerclear(&otimer.it_interval);

    lock_timeout = 0;
    start_timer(&timer, &otimer, &oact, lock_timeout_handler);
  }

  struct flock f;
  memset(&f, 0, sizeof(f));
  f.l_type = lock_type;
  f.l_start = start;
  f.l_len = length;
  f.l_whence = offset;

  int cmd = timeout == 0 ? F_SETLK : F_SETLKW;
  while (fcntl(s->fd, cmd, &f) == -1) {
    switch (errno) {
      case EAGAIN:
        // Non-blocking call failed
        assert(cmd == F_SETLK && timeout == 0 && !with_timeout);
        // fprintf(stderr, "non-blocking lock failed\n");
        return 0;

      case EINTR:
        // Received signal
        if (with_timeout && lock_timeout) {
          stop_timer(&otimer, &oact);
          return 0;
        }

        continue;

      default:
        // Any other error is critical
        if (with_timeout)
          stop_timer(&otimer, &oact);

        return -1;
    }
  }

  if (with_timeout)
    stop_timer(&otimer, &oact);

  // Success
  return 1;
}


static inline int bufio_try_read_lock(bufio_stream *stream, size_t size)
{
  assert(!stream->has_read_lock);
  // fprintf(stderr, "bufio_try_read_lock(..., %zu)\n", size);

  if (stream->type == BUFIO_LOCKEDFILE) {
    int rc = bufio_lock(stream, F_RDLCK, 0, size, SEEK_CUR, 0);
    if (rc == -1) {
      // fprintf(stderr, "bufio_try_read_lock: lock failed -- %s\n", strerror(errno));
      stream->status = -errno;
      return -1;
    } else if (rc == 0) {
      return 0;
    }

    // fprintf(stderr, "bufio_try_read_lock: acquired\n");
    stream->has_read_lock = 1;
    stream->read_lock_offset = 0;
  }

  return 1;
}


static inline int bufio_acquire_read_lock(bufio_stream *stream, size_t size, int timeout)
{
  assert(!stream->has_read_lock);

  if (stream->type == BUFIO_LOCKEDFILE) {
    int rc = bufio_lock(stream, F_RDLCK, 0, size, SEEK_CUR, timeout);
    if (rc == -1) {
      // fprintf(stderr, "bufio_acquire_read_lock: lock failed -- %s\n", strerror(errno));
      stream->status = -errno;
      return -1;
    } else if (rc == 0) {
      // fprintf(stderr, "bufio_acquire_read_lock: lock timed out\n");
      stream->status = BUFIO_TIMEDOUT;
      return 0;
    }

    // fprintf(stderr, "bufio_acquire_read_lock: acquired\n");
    stream->has_read_lock = 1;
    stream->read_lock_offset = 0;
  }

  return 1;
}


static inline int bufio_release_read_lock(bufio_stream *stream)
{
  if (stream->has_read_lock) {
    int rc = bufio_lock(stream, F_UNLCK, -stream->read_lock_offset, 0, SEEK_CUR, -1);
    assert(rc == 1);  // Releasing a region should never fail

    //fprintf(stderr, "released read lock\n");
    stream->has_read_lock = 0;
  } // else fprintf(stderr, "no release of read lock required\n");

  return 0;
}



static inline int bufio_acquire_write_lock(bufio_stream *stream)
{
  if (stream->type == BUFIO_LOCKEDFILE && !stream->has_write_lock) {
    int rc = bufio_lock(stream, F_WRLCK, 0, 0, SEEK_CUR, stream->io_timeout_ms);
    if (rc == -1) {
      // fprintf(stderr, "bufio_acquire_write_lock: failed -- %s\n", strerror(errno));
      stream->status = -errno;
      return -1;
    } else if (rc == 0) {
      // fprintf(stderr, "bufio_acquire_write_lock: timed out\n");
      stream->status = BUFIO_TIMEDOUT;
      return 0;
    }

    // fprintf(stderr, "bufio_acquire_write_lock: acquired\n");
    stream->has_write_lock = 1;
    stream->write_lock_offset = 0;
  } // else fprintf(stderr, "bufio_acquire_write_lock: no need\n");

  return 1;
}


static inline int bufio_release_write_lock(bufio_stream *stream)
{
  if (stream->has_write_lock) {
    int rc = bufio_lock(stream, F_UNLCK, -stream->write_lock_offset, 0, SEEK_CUR, -1);
    assert(rc == 1);  // Releasing a region should never fail

    // fprintf(stderr, "bufio_release_write_lock: released\n");
    stream->has_write_lock = 0;
  }

  return 0;
}


// Logging functionality
static int logstring(const char *i, const char *s1)
{
  if(i) return fprintf(stderr,"%s: %s\n",i,s1);
  else return 0;
}

static int log1string(const char *i, const char *s1, const char *s2)
{
  if(i) return fprintf(stderr,"%s: %s %s\n",i,s1,s2);
  else return 0;
}

static int log2string(const char *i, const char *s1, const char *s2, const char *s3)
{
  if(i) return fprintf(stderr,"%s: %s %s %s\n",i,s1,s2,s3);
  else return 0;
}

static int loginetadr(const char *i, const char *s1, unsigned char *sa, int p)
{
  if(i) return fprintf(stderr,"%s: %s %d.%d.%d.%d:%u\n",
    i,s1,sa[0],sa[1],sa[2],sa[3],ntohs(p));
  else return 0;
}


#ifdef SO_NOSIGPIPE
static void ignore_sigpipe(int socket)
#else
static void ignore_sigpipe(int socket __attribute__((__unused__)))
#endif
{
  // TODO: See
  //  <http://www.microhowto.info/howto/ignore_sigpipe_without_affecting_other_threads_in_a_process.html>
  // for the proper way to deal with this when SO_NOSIGPIP is not available or does not succeed

  #ifdef SO_NOSIGPIPE
  // Ignore SIGPIPE for this socket only
  int so_nosigpipe = 1;
  if (setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &so_nosigpipe, sizeof(so_nosigpipe)) < 0) {
    // Ignore SIGPIPE globally
    signal(SIGPIPE, SIG_IGN);
  }
  #else
  // Ignore SIGPIPE globally
  signal(SIGPIPE, SIG_IGN);
  #endif
}


// Poll which automatically restarts on EINTR and EAGAIN
static inline int safe_poll(struct pollfd fds[], nfds_t nfds, int timeout)
{
  // TODO: Automatically decrement timeout, use ppoll on Linux
  int rc;

  do {
    rc = poll(fds, nfds, timeout);
  } while ((rc == -1) && (errno == EINTR || errno == EAGAIN));

  return rc;
}


static inline void *bufio_memcpy(void *dst, const void *src, size_t n)
{
  if (n == sizeof(int)) {
    // Quickly handle frequent case of int-sized request (e.g. tags). Note
    // that "(int *) dst = (src *) src" has not been used because this could
    // create unaligned accesses on strictly aligned platforms (i.e., we let
    // the compiler decide how to optimise this for the target platform).
    char *cdst = (char *) dst;
    char *csrc = (char *) src;
    *cdst++ = *csrc++;
    *cdst++ = *csrc++;
    *cdst++ = *csrc++;
    *cdst = *csrc;
    return dst;
  }

  return memcpy(dst, src, n);
}


/*
  Sets the buffer size to size bytes. If size is zero, a default size will be
  used. For bidirectional streams, symmetric buffers are set up. Any buffered
  input or output data which do not fit into the new buffers are discarded.

  Returns 0 on success. If an error occurs, existing buffers are freed and -1
  is returned.
*/
static int bufio_setbuffer(bufio_stream *stream, size_t size)
{
  if (size == 0)
    size = BUFIO_BUFSIZE;

  if (stream->input_buffer_fill > size)
    fprintf(stderr, "bufio_setbuffer: Truncating input buffer\n");

  if (stream->output_buffer_tail > size)
    fprintf(stderr, "bufio_setbuffer: Truncating output buffer\n");

  void *buf;
  if ((buf = realloc(stream->input_buffer_base, size)) == NULL)
    goto free_and_out;

  stream->input_buffer_base = (char *) buf;
  stream->input_buffer_size = stream->input_buffer_base ? size : 0;
  stream->input_buffer_head = 0;
  stream->input_buffer_tail = 0;
  stream->input_buffer_fill = 0;

  if ((buf = realloc(stream->output_buffer_base, size)) == NULL)
    goto free_and_out;

  stream->output_buffer_base = (char *) buf;
  stream->output_buffer_size = stream->output_buffer_base ? size : 0;
  stream->output_buffer_tail = 0;

  return 0;

free_and_out:
  if (stream->input_buffer_base) {
    free(stream->input_buffer_base);
    stream->input_buffer_base = NULL;
  }

  if (stream->output_buffer_base) {
    free(stream->output_buffer_base);
    stream->output_buffer_base = NULL;
  }

  return -1;
}


static int accept_socket(bufio_stream *stream, int timeout, const char* info)
{
    struct pollfd poll_in;
    poll_in.fd = stream->fd;
    poll_in.events = POLLIN;

    int rc = safe_poll(&poll_in, 1, timeout);
    if (rc == 0) {
      logstring(info, "listen timeout");
      return 0;
    }

    if (rc < 0) {
      log1string(info, "listen error ... ", strerror(errno));
      return -1;
    }

    struct sockaddr_in client_address;
    socklen_t address_size = sizeof(client_address);
    int cs = accept(stream->fd, (struct sockaddr *) &client_address, &address_size);
    unsigned char *sa = (unsigned char *) &client_address.sin_addr.s_addr;
    close(stream->fd);
    if (cs < 0) {
      log1string(info, "accept failed ...", strerror(errno));
      return -1;
    }

    stream->fd = cs;
    ignore_sigpipe(stream->fd);

    // Enable non-blocking I/O
    fcntl(stream->fd, F_SETFL, (long) (O_RDWR | O_NONBLOCK));

    loginetadr(info, "connection established", sa, client_address.sin_port);

    return 1;
}


/*=== Function ===============================================================*/

bufio_stream *bufio_open(const char *peername,
                         const char *opt,
                         int timeout,
                         int bufsize,
                         const char *info)

/*--- Description ------------------------------------------------------------//

Open a connection or file.

peername can be a plain file name, "-" for stdin/stdout, or

tcp://listen/port           to listen to port at all interfaces
tcp://listen/port/nodename  to listen to port at nodename interface
tcp://connect/port/nodename to listen to port and nodename
udp://connect/port/nodename to connect to port at nodename
lockedfile://filename       to open a file with region locking (see below)

Other protocols might be implemeted later, e.g.,
tty://dev/ttyUS0/raw/speed:9600 or pipe://read/pipefile

opt specifies the mode of file I/O, if a file has been opened. See fopen(3)
for modes supported. This parameter is currently ignored for tcp streams,
which are always bidirectional. Also, standard streams (stdin, stdout) are
unidirectional. If required, files are created with rw-rw-r--.

timeout specifies the time to wait for a connection in milliseconds. Specify
-1 to block indefinitely.

bufsize specifies the buffer size in Byte. If 0 a default value will be used.

info is used as a prefix for log messages to stderr. If Null, no logging is
performed.

The function returns a valid pointer to a bufio_stream or Null if no
connection or file could be opened within the specified timeout.

//--- Note -------------------------------------------------------------------//

If timeout is smaller than a resonable value for the type of connection it is
extended.

Locked files are handled in the following way: bufio_write acquires an exclusive
region lock from the current position until infinity. To minimise overhead, the
lock is not released immediately, so that subsequent write operations can reuse
the lock. bufio_flush releases the exclusive lock. bufio_read and bufio_wait
try to obtain a shared lock of the appropriate length (requested bytes or a
single byte) for each read that is issued.

//--- Side effects -----------------------------------------------------------//

On systems which do not support ignoring SIGPIPE for specific file descriptors
(e.g., Linux), the function sets the pipe signal to be ignored globally with

  signal(SIGPIPE, SIG_IGN);

This may affect the rest of your code, but there is no other way to avoid the
horror of signalling in Unix kernels. SIGPIPE signals can be enabled manually
afterwards, but this is at your risk and care has to be taken that the
application code does not crash during writes to a broken pipe.

//----------------------------------------------------------------------------*/
{
  int port = 0;
  int type = 0;
  char name[1025] = {0};
  unsigned char *sa;
  int socket_type = 0;

  // Guess stream type from peername
  if (sscanf(peername, "tcp://connect/%d/%1024s", &port, name) > 0) {
    socket_type = SOCK_STREAM;
    type = 'c';
  } else if (sscanf(peername, "tcp://listen/%d/%1024s", &port, name) > 0) {
    socket_type = SOCK_STREAM;
    type = 'l';
  } else if (sscanf(peername, "tcp://serve/%d/%1024s", &port, name) > 0) {
    socket_type = SOCK_STREAM;
    type = 'L';
  } else if (sscanf(peername, "udp://connect/%d/%1024s", &port, name) > 0) {
    socket_type = SOCK_DGRAM;
    type = 'c';
  } else {
    // Interpret as filename
    type = 'f';
  }

  // Create and populate structure
  bufio_stream *stream = (bufio_stream *) calloc(1, sizeof(bufio_stream));
  if (stream == NULL) {
    logstring(info, "failed to allocate stream: out of memory");
    return NULL;
  }

  // Set stream mode and type
  stream->mode = O_NONBLOCK;
  if (type == 'f') {
    stream->type = BUFIO_FILE;

    if (strcmp(opt, "r") == 0)
      stream->mode |= O_RDONLY;
    else if (strcmp(opt, "r+") == 0)
      stream->mode |= O_RDWR;
    else if (strcmp(opt, "w") == 0)
      stream->mode |= O_WRONLY | O_CREAT | O_TRUNC;
    else if (strcmp(opt, "w+") == 0)
      stream->mode |= O_RDWR | O_CREAT;
  } else {
    if (type == 'L')
      stream->type = BUFIO_LISTEN_SOCKET;
    else
      stream->type = BUFIO_SOCKET;
    stream->mode |= O_RDWR;
  }

  // Handle file open
  if (stream->type == BUFIO_FILE) {
    if (strcmp(peername, "-") == 0) {
      // Handle standard streams (unidirectional)
      stream->type = BUFIO_PIPE;  // TODO: Restructure code
      if (stream->mode & O_WRONLY) {
        stream->fd = STDOUT_FILENO;  // Write-only
      } else if ((stream->mode & O_RDWR) == 0) {
        stream->fd = STDIN_FILENO;  // Read-only
      } else {
        // Read/write
        log2string(info, "invalid mode", opt, "for standard stream");
        goto free_and_out;
      }
    } else {
      if (sscanf(peername, "lockedfile://%1024s", name) > 0)
        stream->type = BUFIO_LOCKEDFILE;
      else
        strncpy(name, peername, 1024);

      int stat_rc;
      struct stat statbuf;
      if ((stat_rc = stat(name, &statbuf) == -1) && (errno != ENOENT || !(stream->mode & O_CREAT))) {
        log1string(info, "stat failed --", strerror(errno));
        goto free_and_out;
      }

      // Check type of file
      if (!stat_rc && S_ISDIR(statbuf.st_mode)) {
        log1string(info, "can not open directory", name);
        goto free_and_out;
      } else if (!stat_rc && S_ISFIFO(statbuf.st_mode)) {
        // TODO: LOCKEDFIFO?
        stream->type = BUFIO_FIFO;
      }

      // Open file
      mode_t file_flags = S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH;
      if ((stream->fd = open(name, stream->mode, file_flags)) == -1) {
        log2string(info, "failed to open file with mode", opt, name);
        goto free_and_out;
      }
    }

    if (bufio_setbuffer(stream, bufsize > 0 ? bufsize : BUFIO_BUFSIZE) != 0) {
      logstring(info, "can not create buffer");
      goto close_free_and_out;
    }

    return stream;
  }

  // Handle socket connection
  // Set default timeout to blocking
  stream->io_timeout_ms = -1;

  // Fill address information
  struct sockaddr_in address;
  address.sin_addr.s_addr = INADDR_ANY;
  address.sin_family = AF_INET;
  address.sin_port = htons(port);

  if (name[0]) {
    struct hostent *hostentry = gethostbyname(name);
    if (hostentry == 0) {
      log1string(info, "no such host", name);
      goto free_and_out;
    }

    memcpy(&(address.sin_addr.s_addr), hostentry->h_addr, hostentry->h_length);
  }

  sa = (unsigned char *) &address.sin_addr.s_addr;
  stream->fd = socket(AF_INET, socket_type, 0);
  if (stream->fd == -1) {
    logstring(info, "create socket failed");
    goto free_and_out;
  }

  ignore_sigpipe(stream->fd);

  if (timeout < 0)
    timeout = -1;
  else if (timeout > 0 && timeout < 100)
    timeout = 100;

  if (type == 'l' || type == 'L') {
    // Handle server connection
    int so_resueaddr = 1;
    if ((setsockopt(stream->fd, SOL_SOCKET, SO_REUSEADDR, &so_resueaddr, sizeof(so_resueaddr)) < 0))
      logstring(info, "can not set socketopt/reuseaddr");

    if (bind(stream->fd, (struct sockaddr *) &address, (socklen_t) sizeof(address)) == -1) {
      log1string(info,"bind failed ...", strerror(errno));
      goto close_free_and_out;
    }

    if (listen(stream->fd, 1) < 0) {
      log1string(info, "listen failed ...", strerror(errno));
      goto close_free_and_out;
    }

    loginetadr(info, "server waiting for connections", sa, address.sin_port);
    if (stream->type != BUFIO_LISTEN_SOCKET && accept_socket(stream, timeout, info) != 1)
      goto close_free_and_out;
  } else {
    // Handle client connection
    loginetadr(info, "connecting to", sa, address.sin_port);

    int rc = -1;
    while (1) {
      // TODO: Measure 'connect' (and 'close'/'socket') time to properly decrease timeout
      rc = connect(stream->fd, (struct sockaddr *) &address, (socklen_t) sizeof(address));
      // fprintf(stderr, "bufio_open: connect rc %d errno %d desc %s\n", rc, errno, strerror(errno));
      if (rc == 0 || (timeout >= 0 && timeout < 50))
        break;

      if (rc == -1 && errno == ECONNREFUSED) {
        // if the peer is not ready and refuses we try again
        // linux would accept retrying the connect() call directly
        // apple/bsd require closing and opening the socket again.
        close(stream->fd);
        if ( (stream->fd = socket(AF_INET, socket_type, 0)) == -1 ) {
          logstring(info, "create socket failed");
          goto free_and_out;
        }
        ignore_sigpipe(stream->fd);
      }
      usleep(50000);
      timeout -= 50;
#ifdef __APPLE__
      errno = 0;  // On OS X, usleep sets errno even on success
#endif
    }

    if (rc != 0) {
      log1string(info, "connect timeout /", strerror(errno));
      goto close_free_and_out;
    }
  }

  // Enable non-blocking I/O
  fcntl(stream->fd, F_SETFL, (long) (O_RDWR | O_NONBLOCK));

  if (bufio_setbuffer(stream, bufsize > 0 ? bufsize : BUFIO_BUFSIZE) != 0) {
    logstring(info, "can not create buffer");
    goto close_free_and_out;
  }

  if (stream->type != BUFIO_LISTEN_SOCKET)
    loginetadr(info, "connection established, peer", sa, address.sin_port);
  return stream;

close_free_and_out:
  close(stream->fd);

free_and_out:
  free(stream);
  return NULL;
}


/*=== Function ===============================================================*/

size_t bufio_read(bufio_stream *stream,
                  void *ptr,
                  size_t size)

/*--- Description ------------------------------------------------------------//

Attempts to read size bytes of data from stream into the buffer pointed to by
ptr. If buffered data is present, this is copied first. Otherwise, bufio tries
to fill its read buffer as much as possible with one read operation.

//--- Return values ----------------------------------------------------------//

Upon successful completion, the number of bytes actually read and placed in
the buffer is returned. If this is less than requested, an error has occured
and the status code of the stream was set.

//--- Status codes -----------------------------------------------------------//

  BUFIO_TIMEDOUT A read operation or poll timed out.

  BUFIO_EOF      Reached end-of-file. Use bufio_wait to wait for new data.

  BUFIO_EPIPE    The device or socket has been disconnected or an exceptional
                 condition such as a low-level I/O error has occurred on the
                 device or socket.

//----------------------------------------------------------------------------*/

{
  if (size == 0 || stream->type == BUFIO_LISTEN_SOCKET) {
    // fprintf(stderr, "bufio_read: size 0\n");
    return 0;
  }

  if (size <= stream->input_buffer_fill) {
    // Destination can be filled completely from buffer
    // fprintf(stderr, "bufio_read: Copying %zu bytes\n", size);
    bufio_memcpy(ptr, stream->input_buffer_base + stream->input_buffer_head, size);

    size_t remaining_bytes = stream->input_buffer_fill - size;
    if (remaining_bytes > 0) {
      // Adjust head
      // TODO: This eats away and blocks bits of the buffer; test bipartite or
      // circular buffer for speed gains
      stream->input_buffer_head += size;
      stream->input_buffer_fill -= size;
    } else {
      // Reset buffer
      stream->input_buffer_head = 0;
      stream->input_buffer_tail = 0;
      stream->input_buffer_fill = 0;
    }

    return size;
  }

  // Not enough data in buffer: copy buffered data and perform read
  // fprintf(stderr, "bufio_read: Reading %zu bytes, %zu from buffer\n", size, stream->input_buffer_fill);
  size_t remaining_bytes = size - stream->input_buffer_fill;

  if (stream->input_buffer_fill > 0) {
    // Fill first part of destination from buffer
    bufio_memcpy(ptr, stream->input_buffer_base + stream->input_buffer_head,
                 stream->input_buffer_fill);
    stream->input_buffer_head = 0;
    stream->input_buffer_tail = 0;
    stream->input_buffer_fill = 0;
  }

  assert(stream->input_buffer_head == 0 && stream->input_buffer_tail == 0 &&
         stream->input_buffer_fill == 0);

  struct iovec read_vec[2];
  read_vec[1].iov_base = stream->input_buffer_base;
  read_vec[1].iov_len = stream->input_buffer_size;

  struct pollfd poll_in;
  poll_in.fd = stream->fd;
  poll_in.events = POLLIN;
  poll_in.revents = 0;

  if (bufio_try_read_lock(stream, remaining_bytes + stream->input_buffer_size) != 1) {
    if (bufio_acquire_read_lock(stream, remaining_bytes, stream->io_timeout_ms) != 1)
      return size - remaining_bytes;

    read_vec[1].iov_len = 0;
  }

  int poll_rc = 0;
  do {
    read_vec[0].iov_base = (char *) ptr + (size - remaining_bytes);
    read_vec[0].iov_len = remaining_bytes;

    ssize_t nbytes = readv(stream->fd, read_vec, 2);
    if (nbytes == -1) {
      if (errno == EAGAIN || errno == EINTR)
        continue;

      // General I/O error, see readv(2)
      // fprintf(stderr, "bufio_read: Error\n");
      stream->status = -errno;
      bufio_release_read_lock(stream);
      return size - remaining_bytes;
    }

    if (nbytes == 0 && poll_in.revents & POLLIN) {
      // Reached end-of-file
      stream->status = BUFIO_EOF;
      bufio_release_read_lock(stream);
      return size - remaining_bytes;
    }

    assert(nbytes >= 0);
    stream->read_lock_offset += nbytes;

    if ((size_t) nbytes > remaining_bytes) {
      stream->input_buffer_tail = nbytes - remaining_bytes;
      stream->input_buffer_fill = stream->input_buffer_tail;
      remaining_bytes = 0;
      // fprintf(stderr, "bufio_read: Read %zu bytes, placed %zu bytes in buffer\n", nbytes, stream->input_buffer_fill);
    } else {
      // fprintf(stderr, "bufio_read: Read %zu bytes\n", (size_t) nbytes);
      remaining_bytes -= nbytes;
    }
  } while (remaining_bytes > 0 &&
           (poll_rc = safe_poll(&poll_in, 1, stream->io_timeout_ms)) == 1 &&
           poll_in.revents & POLLIN);

  bufio_release_read_lock(stream);

  if (remaining_bytes == 0)
    return size;

  if (poll_in.revents & POLLHUP)
    stream->status = -EPIPE;
  else if (poll_in.revents & POLLERR)
    stream->status = -EIO;  // EIO comes closest to "an exceptional condition"
  else if (poll_rc == 0) {
    fprintf(stderr, "TIMEOUT with %zu remaining bytes (%zu bytes requested)\n", remaining_bytes, size);
    stream->status = BUFIO_TIMEDOUT;
  }

  return size - remaining_bytes;
}


/*=== Function ===============================================================*/

size_t bufio_write(bufio_stream *stream,
                   const void *ptr,
                   size_t size)

/*--- Description ------------------------------------------------------------//

Attempts to write all buffered data and the size bytes of data from the buffer
pointed to by ptr to stream. If enough space is left in the local write
buffer, the data is buffered instead.

//--- Return values ----------------------------------------------------------//

Upon successful completion, the number of bytes from the given buffer that
have been buffered or written is returned. If this is less than requested, an
error has occured and the status code of the stream was set.

//--- Status codes -----------------------------------------------------------//

  BUFIO_TIMEDOUT A write operation or poll timed out.

  BUFIO_EPIPE    The device or socket has been disconnected or an exceptional
                 condition such as a low-level I/O error has occurred on the
                 device or socket.

//----------------------------------------------------------------------------*/

{
  struct pollfd poll_out;
  poll_out.fd = stream->fd;
  poll_out.events = POLLOUT;
  poll_out.revents = 0;

  if (size == 0 || stream->type == BUFIO_LISTEN_SOCKET) {
    // fprintf(stderr, "bufio_write: size 0\n");
    return 0;
  }

  if (stream->output_buffer_size - stream->output_buffer_tail >= size) {
    // Copy data into output buffer and advance index
    // fprintf(stderr, "bufio_write: buffering %zu bytes\n", size);
    bufio_memcpy(stream->output_buffer_base + stream->output_buffer_tail, ptr, size);
    stream->output_buffer_tail += size;

    return size;
  }

  // Remaining buffer too small for data: perform actual writes
  if (bufio_acquire_write_lock(stream) != 1)
    return 0;

  if (stream->output_buffer_tail == 0) {
    // Buffer is empty: write data directly
    // fprintf(stderr, "bufio_write: direct write\n");
    int poll_rc = 0;
    size_t remaining_bytes = size;
    do {
      ssize_t nbytes = write(stream->fd, ptr, remaining_bytes);
      if (nbytes == -1) {
        if (errno == EAGAIN || errno == EINTR)
          continue;

        // fprintf(stderr, "bufio_write: error in direct write -- %s\n", strerror(errno));

        stream->status = -errno;
        return size - remaining_bytes;
      }

      // Advance pointer
      assert(nbytes >= 0 && (size_t) nbytes <= remaining_bytes);
      remaining_bytes -= nbytes;
      stream->write_lock_offset += nbytes;
      ptr = (char *) ptr + nbytes;
    } while (remaining_bytes > 0 &&
             (poll_rc = safe_poll(&poll_out, 1, stream->io_timeout_ms)) == 1 &&
             poll_out.revents == POLLOUT);

    if (remaining_bytes == 0)
      return size;

    // fprintf(stderr, "bufio_write: error in direct write -- %s\n", strerror(errno));

    if (poll_out.revents & POLLHUP)
      stream->status = -EPIPE;
    else if (poll_out.revents & POLLERR)
      stream->status = -EIO;  // comes closest to "an exceptional condition"
    else if (poll_rc == 0)
      stream->status = BUFIO_TIMEDOUT;

    return size - remaining_bytes;
  }

  // Write buffer and data with one call
  // fprintf(stderr, "bufio_write: scattered write\n");
  struct iovec write_vec[2];
  write_vec[0].iov_base = stream->output_buffer_base;
  write_vec[0].iov_len = stream->output_buffer_tail;
  write_vec[1].iov_base = (void *) ptr;
  write_vec[1].iov_len = size;

  int poll_rc = 0;
  size_t output_buffer_head = 0;
  size_t remaining_bytes = stream->output_buffer_tail + size;
  do {
    ssize_t nbytes = writev(stream->fd, write_vec, 2);
    if (nbytes == -1) {
      if (errno == EAGAIN || errno == EINTR)
        continue;

      stream->status = -errno;
      return (remaining_bytes > size) ? 0 : (size - remaining_bytes);
    }

    assert(nbytes >= 0 && (size_t) nbytes <= remaining_bytes);
    stream->write_lock_offset += nbytes;

    if (nbytes > 0 && write_vec[0].iov_len > 0) {
      // Advance buffer
      size_t nbytes_buf =
          ((size_t) nbytes < stream->output_buffer_tail - output_buffer_head)
              ? (size_t) nbytes
              : (stream->output_buffer_tail - output_buffer_head);
      output_buffer_head += nbytes_buf;
      write_vec[0].iov_base = (char *) write_vec[0].iov_base + nbytes_buf;
      write_vec[0].iov_len = stream->output_buffer_tail - output_buffer_head;
      nbytes -= nbytes_buf;
      remaining_bytes -= nbytes_buf;

      if (write_vec[0].iov_len == 0) {
        // Reset output buffer
        // TODO: Could optimise writev => write after this point -- investigate performance gain
        output_buffer_head = 0;
        stream->output_buffer_tail = 0;
      }
    }

    if (nbytes > 0) {
      write_vec[1].iov_base = (char *) write_vec[1].iov_base + nbytes;
      write_vec[1].iov_len -= nbytes;
      remaining_bytes -= nbytes;
    }
  } while (remaining_bytes > 0 &&
           (poll_rc = safe_poll(&poll_out, 1, stream->io_timeout_ms)) == 1 &&
           poll_out.revents == POLLOUT);

  if (remaining_bytes == 0)
    return size;

  fprintf(stderr, "bufio_write: Error\n");

  if (poll_out.revents & POLLHUP)
    stream->status = -EPIPE;
  else if (poll_out.revents & POLLERR)
    stream->status = -EIO;  // comes closest to "an exceptional condition"
  else if (poll_rc == 0)
    stream->status = BUFIO_TIMEDOUT;

  return (remaining_bytes > size) ? 0 : (size - remaining_bytes);
}


/*=== Function ===============================================================*/

int bufio_flush(bufio_stream *stream)

/*--- Description ------------------------------------------------------------//

Flushes output buffers.

//--- Return values ----------------------------------------------------------//

Returns 0 on success. If an error occurs, -1 is returned and the status code
of the stream was set.

//--- Status codes -----------------------------------------------------------//

  BUFIO_TIMEDOUT A write operation or poll timed out.

  BUFIO_EPIPE    The device or socket has been disconnected or an exceptional
                 condition such as a low-level I/O error has occurred on the
                 device or socket.

//----------------------------------------------------------------------------*/

{
  if (stream->type == BUFIO_LISTEN_SOCKET)
    return 0;

  if (stream->output_buffer_tail == 0) {
    bufio_release_write_lock(stream);
    return 0;
  }

  // fprintf(stderr, "bufio_flush: Flushing %zu bytes\n", stream->output_buffer_tail);

  struct pollfd poll_out;
  poll_out.fd = stream->fd;
  poll_out.events = POLLOUT;
  poll_out.revents = 0;

  int poll_rc = 0;
  size_t output_buffer_head = 0;
  do {
    ssize_t nbytes = write(stream->fd,
                           stream->output_buffer_base + output_buffer_head,
                           stream->output_buffer_tail - output_buffer_head);
    if (nbytes == -1) {
      if (errno == EAGAIN || errno == EINTR)
        continue;

      stream->status = -errno;
      bufio_release_write_lock(stream);
      return -1;
    }

    // fprintf(stderr, "bufio_flush: Wrote %zu bytes\n", (size_t) nbytes);
    assert(nbytes >= 0 &&
           (size_t) nbytes <= stream->output_buffer_tail - output_buffer_head);
    output_buffer_head += nbytes;
    stream->write_lock_offset += nbytes;
  } while (output_buffer_head != stream->output_buffer_tail &&
           (poll_rc = safe_poll(&poll_out, 1, stream->io_timeout_ms)) == 1 &&
           poll_out.revents == POLLOUT);

  bufio_release_write_lock(stream);

  if (output_buffer_head == stream->output_buffer_tail) {
    stream->output_buffer_tail = 0;
    return 0;
  }

  if (poll_out.revents & POLLHUP)
    stream->status = -EPIPE;
  else if (poll_out.revents & POLLERR)
    stream->status = -EIO;  // comes closest to "an exceptional condition"
  else if (poll_rc == 0)
    stream->status = BUFIO_TIMEDOUT;

  return -1;
}


/*=== Function ===============================================================*/

int bufio_sync(bufio_stream *stream)

/*--- Description ------------------------------------------------------------//

Flushes output and kernel buffers. Useful only for files.

//--- Return values ----------------------------------------------------------//

Returns 0 on success. If an error occurs, -1 is returned and errno is set to
indicate the error.

//--- Status codes------------------------------------------------------------//

  BUFIO_TIMEDOUT A write operation or poll timed out.

  BUFIO_EPIPE    The device or socket has been disconnected or an exceptional
                 condition such as a low-level I/O error has occurred on the
                 device or socket.

//----------------------------------------------------------------------------*/

{
  if (bufio_flush(stream) != 0)
    return -1;

  if (stream->type != BUFIO_FILE)
    return 0;

  int status = 0;
  do {
    status = fsync(stream->fd);
  } while (status == -1 && errno == EINTR);

  if (status == -1) {
    stream->status = -errno;
    return -1;
  }

  return 0;
}


/*=== Function ===============================================================*/

int bufio_wait(bufio_stream *stream, int timeout)

/*--- Description ------------------------------------------------------------//

Waits for incoming data and checks the status of the stream. This function is
useful in case the coarse timeout set for I/O operations is not sufficient for
fine grained waiting and polling or to wait for new data after end-of-file has
been reached.

If timeout is greater than zero, it specifies a maximum interval (in
milliseconds) to wait for data to arrive. If timeout is 0, then bufio_wait()
will return without blocking -- use this to quickly check for data in the
input buffers. If the value of timeout is -1, the poll blocks indefinitely.

//--- Return values ----------------------------------------------------------//

-1 the connection is broken
 0 no input data is present within the given timeout (BUFIO_TIMEDOUT or
   BUFIO_EOF is set)
 1 input data is present

//--- Status codes -----------------------------------------------------------//

  BUFIO_TIMEDOUT A read operation or poll timed out.

  BUFIO_EOF      Reached end-of-file.

  BUFIO_EPIPE    The device or socket has been disconnected or an exceptional
                 condition such as a low-level I/O error has occurred on the
                 device or socket.

//----------------------------------------------------------------------------*/
{
  if (stream->type == BUFIO_LISTEN_SOCKET) {
    int rc = accept_socket(stream, timeout, NULL);
    if (rc < 1)  // timeout or error
      return rc;

    // Connection has been established for the first time, continue with normal wait logic
    stream->type = BUFIO_SOCKET;
  }

  // Check buffer
  if (stream->input_buffer_fill > 0)
    return 1;  // Data present

  if (stream->mode & O_WRONLY)
    return 0;

  // Try non-blocking read
  assert(stream->input_buffer_size > 0 &&
         stream->input_buffer_size - stream->input_buffer_tail > 0);

  size_t read_size = stream->input_buffer_size - stream->input_buffer_tail;
  while (1) {
    if (bufio_try_read_lock(stream, read_size) != 1) {
      int rc = bufio_acquire_read_lock(stream, 1, timeout);
      if (rc != 1)
        return rc;

      read_size = 1;
    }

    ssize_t nbytes = read(stream->fd, stream->input_buffer_base + stream->input_buffer_tail,
                          read_size);

    int read_errno = errno;  // Store errno before calling bufio_release_read_lock
    bufio_release_read_lock(stream);

    if (nbytes > 0) {
      // Read successful: advance pointer
      // fprintf(stderr, "bufio_wait: Read %zu bytes\n", (size_t) nbytes);
      stream->input_buffer_tail += nbytes;
      stream->input_buffer_fill += nbytes;
      stream->read_lock_offset += nbytes;
      return 1;  // Data present
    }

    if (nbytes == -1 && read_errno != EAGAIN && read_errno != EINTR) {
      stream->status = -read_errno;
      return -1;  // Stream error
    }

    // When trying a non-blocking read on a TCP connection in CLOSE_WAIT state,
    // - macOS yields 0 bytes and ETIMEDOUT, while
    // - Linux yields 0 bytes and EAGAIN.
    if (stream->type == BUFIO_SOCKET && nbytes == 0 && (read_errno == ETIMEDOUT || read_errno == EAGAIN)) {
      stream->status = BUFIO_EPIPE;
      return -1;  // Stream error
    }

    if (timeout == 0) {
      if (nbytes == 0)
        stream->status = BUFIO_EOF;

      // fprintf(stderr, "bufio_wait: No data, skipping poll (nbytes: %zi, read_errno: %i - %s)\n", nbytes, read_errno, strerror(read_errno));
      return 0;  // No data present
    }

    if (nbytes == -1) {
      assert(stream->type != BUFIO_FILE && stream->type != BUFIO_LOCKEDFILE);

      // Poll for incoming data (with protection from external signals)
      // fprintf(stderr, "bufio_wait: Poll\n");
      struct pollfd poll_in;
      poll_in.fd = stream->fd;
      poll_in.events = POLLIN;
      poll_in.revents = 0;

      int rc = safe_poll(&poll_in, 1, timeout);
      if (rc == 0) {
        stream->status = BUFIO_TIMEDOUT;
        return 0;  // Timeout
      } else if (rc > 0 && (poll_in.revents & POLLIN)) {
        return bufio_wait(stream, 0);  // data could be present, but only a call to read() tells us if this is true (esp. in TCP hangup conditions)
      } else {
        if (poll_in.revents & POLLHUP)
          stream->status = -EPIPE;
        else  // typically POLLERR
          stream->status = -EIO;  // comes closes to "an exceptional condition"

        return -1;  // Stream error
      }
    }

    // Reached end-of-file; poll won't work in this case, so sleep and retry
    // non-blocking read
    // TODO: Protect from signals and measure actual sleep time
    // TODO: Wait for SIGIO instead of sleeping?
    if (timeout > 50) {
      usleep(50000);
      timeout -= 50;
    } else {
      usleep(timeout * 1000);
      timeout = 0;
    }
  }
}


/*=== Function ===============================================================*/

int bufio_close(bufio_stream *stream)

/*--- Description ------------------------------------------------------------//

Flushes buffers, closes the current stream, and frees stream and the
associated buffers.

//--- Return values ----------------------------------------------------------//

Returns 0 on success. If an error occurs, -1 is returned and errno is set to
indicate the error. See the documentation of close(2) and bufio_flush for a
list of possible error codes.

//----------------------------------------------------------------------------*/

{
  if (!stream)
    return 0;

  // Flush buffers, synchronise and close file descriptor
  int retval = 0;
  if ((bufio_flush(stream) != 0) ||
      (close(stream->fd) != 0))
    retval = -1;

  // Free buffers
  if (stream->input_buffer_base)
    free(stream->input_buffer_base);

  if (stream->output_buffer_base)
    free(stream->output_buffer_base);

  // Free structure
  free(stream);

  return retval;
}


/*=== Function ===============================================================*/

int bufio_timeout(bufio_stream *stream, int msec)

/*--- Description ------------------------------------------------------------//

Sets the timeout for poll and I/O operations. If timeout is greater than zero,
it specifies a maximum interval (in milliseconds) to wait for poll and I/O
operations. If timeout is zero, then poll and I/O operations will return
without blocking. If the value of timeout is -1, poll and I/O operations block
indefinitely.

//--- Return values ----------------------------------------------------------//

Returns the previously set timeout.

//----------------------------------------------------------------------------*/
{
  // Set default timeout for polls
  int old_msec = stream->io_timeout_ms;
  stream->io_timeout_ms = msec;

  return old_msec;
}


/*=== Function ===============================================================*/

int bufio_type(bufio_stream *stream)

/*--- Description ------------------------------------------------------------//

Returns the type of stream.

//--- Return values ----------------------------------------------------------//

BUFIO_FILE   File type
BUFIO_PIPE   Standard stream type
BUFIO_SOCKET Socket type

//----------------------------------------------------------------------------*/

{
  if (!stream)
    return BUFIO_INVALID_TYPE;
  return stream->type;
}


/*=== Function ===============================================================*/

int bufio_status(bufio_stream *stream)

/*--- Description ------------------------------------------------------------//

Returns the status of stream.

//--- Return values ----------------------------------------------------------//

BUFIO_OKAY (0) No error
BUFIO_TIMEDOUT Poll or I/O operation timed out
BUFIO_EOF      Reached end-of-file
BUFIO_EPIPE    I/O error occured

//----------------------------------------------------------------------------*/

{
  return (!stream || stream->status < 0) ? BUFIO_EPIPE : stream->status;
}


/*=== Function ===============================================================*/

const char *bufio_status_str(bufio_stream *stream)

/*--- Description ------------------------------------------------------------//

Returns a description of the status of stream.

//----------------------------------------------------------------------------*/

{
  if (!stream)
    return "closed";

  if (stream->status < 0)
    return strerror(-stream->status);
  else switch (stream->status) {
    case BUFIO_OKAY:     return "okay";
    case BUFIO_TIMEDOUT: return "timeout";
    case BUFIO_EOF:      return "end-of-file";
    default:             return "unknown error";
  }
}


/*=== Function ===============================================================*/

int bufio_fileno(bufio_stream *stream)

/*--- Description ------------------------------------------------------------//

Returns the associated file descriptor of stream.

//----------------------------------------------------------------------------*/

{
  return stream->fd;
}


/*=== Function ===============================================================*/

int bufio_clear_status(bufio_stream *stream)

/*--- Description ------------------------------------------------------------//

Clears the status of stream.

//--- Return values ----------------------------------------------------------//

Returns BUFIO_OKAY.

//----------------------------------------------------------------------------*/

{
  return (stream->status = BUFIO_OKAY);
}
