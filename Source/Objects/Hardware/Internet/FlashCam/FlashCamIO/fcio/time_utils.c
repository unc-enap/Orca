/*
 * time_utils: Convenience functions for sleeping and timing
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Contact:
 * - main authors: felix.werner@mpi-hd.mpg.de
 * - upstream URL: https://www.mpi-hd.mpg.de/hinton/software
 */

#define _POSIX_C_SOURCE 200112L

#include <errno.h>
#include <float.h>
#include <inttypes.h>
#ifdef __MACH__
#include <mach/mach_time.h>
#endif
#include <time.h>


/*
 * Causes the calling thread to sleep for at least the amount of time
 * specified. The actual time slept may be longer, due to system
 * latencies and possible limitations in the timer resolution of the
 * hardware.
 *
 * Same return values and signalling behaviour as nanosleep(2).
 */
int nsleep(double seconds)
{
  if (seconds <= 0.0)
    return 0;

  struct timespec t;
  t.tv_sec = seconds;
  t.tv_nsec = 1.0e9 * (seconds - t.tv_sec);

  return nanosleep(&t, NULL);
}

/*
 * Returns the elapsed time in seconds since a specified offset. The
 * monotonic system timer is used. Pass zero for 'initialisation',
 * e.g.:
 *
 *   double t0 = elapsed_time(0.0);
 *   // Do some work...
 *   double dt = elapsed_time(t0);
 *
 * Needs to be linked with "-lrt" on Linux.
 *
 * Inspired by Mizzi's timer(), but uses a monotonic time source.
 */
double elapsed_time(double offset)
{
#ifndef __MACH__
  static __thread time_t t0 = 0;
  struct timespec t;

  clock_gettime(CLOCK_MONOTONIC, &t);

  if (!t0) {
    t0 = t.tv_sec;
    return 1.0e-9 * t.tv_nsec - offset;
  }

  return (t.tv_sec - t0) + 1.0e-9 * t.tv_nsec - offset;
#else
  static __thread uint64_t t0 = 0;
  static __thread double scale = 0.0;

  if (!t0) {
    static __thread mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    scale = (1.0e-9 * info.numer) / info.denom;
    t0 = mach_absolute_time();
    return -offset;
  }

  return scale * (mach_absolute_time() - t0) - offset;
#endif
}


/*
 * Returns the seconds elapsed since the timer t expired, i.e.
 *   fmax(elapsed_time(t) - interval, 0.0);
 * If the time elapsed since t exceeds the given interval, t
 * will be incremented by interval or multiples thereof in
 * case an interval has been skipped.
 *
 * t should be initialised using elapsed_time(0.0).
 */
double timer_expired(double *t, const double interval)
{
  if (!t)
    return 0.0;

  double dt = elapsed_time(*t) - interval;
  if (dt < 0.0)
    return 0.0;

  const double rc = (dt == 0.0) ? DBL_MIN : dt;
  do {
    *t += interval;
  } while ((dt -= interval) >= 0.0);

  return rc;
}


/*
 * Converts an NTP timestamp to Unix seconds. Used internally by
 * `utc_unix_to_gps`.
 */
#define ntp_to_unix(ntp) ((long) ((unsigned long) ntp - 2208988800UL))


// The GPS time was synchronised to the UTC time on
// 6 Jan 1980 00:00:00 UTC -- 315964800 in Unix time format
// (3657 days since 1 Jan 1970 times 86400 seconds/day).
// Since then, GPS time and UTC drift apart because leap
// seconds are inserted into UTC every few years. Below,
// we keep a list of leap seconds generated from the
// authorative list by the IERS. Since we'd like to insert
// new leap seconds with minimal maintainenance effort,
// we add the 19 leap seconds as of 6 Jan 1980 to the
// GPS to UTC Unix offset here such that we can subtract the
// total leap seconds from this authorative list below.
const long gps_offset_to_utc_unix = 315964800L + 19L;


/*
 * Converts a UTC timestamp given in Unix time format (seconds since
 * 1 Jan 1970 incl. leap seconds) to GPS time (seconds since 1 Jan 1980
 * without leap seconds).
 *
 * UTC timestamps before the GPS epoch will be clamped to 0.
 *
 * The internal leap second table used for the conversion is valid
 * until 28 June 2019.
 */
long utc_unix_to_gps(long utc_unix_seconds)
{
  // The following list is automatically generated from
  // the official leap-seconds.list from the IERS:
  //   https://hpiers.obspm.fr/iers/bul/bulc/ntp/leap-seconds.list
  // A (sometimes slightly dated) copy can be obtained from the IETF:
  //   https://www.ietf.org/timezones/data/leap-seconds.list
  // It expires on 28 June 2019.
  long nleaps;
  if (utc_unix_seconds >= ntp_to_unix(3692217600UL))  // 1 Jan 2017
    nleaps = 37;
  else if (utc_unix_seconds >= ntp_to_unix(3644697600UL))  // 1 Jul 2015
    nleaps = 36;
  else if (utc_unix_seconds >= ntp_to_unix(3550089600UL))  // 1 Jul 2012
    nleaps = 35;
  else if (utc_unix_seconds >= ntp_to_unix(3439756800UL))  // 1 Jan 2009
    nleaps = 34;
  else if (utc_unix_seconds >= ntp_to_unix(3345062400UL))  // 1 Jan 2006
    nleaps = 33;
  else if (utc_unix_seconds >= ntp_to_unix(3124137600UL))  // 1 Jan 1999
    nleaps = 32;
  else if (utc_unix_seconds >= ntp_to_unix(3076704000UL))  // 1 Jul 1997
    nleaps = 31;
  else if (utc_unix_seconds >= ntp_to_unix(3029443200UL))  // 1 Jan 1996
    nleaps = 30;
  else if (utc_unix_seconds >= ntp_to_unix(2982009600UL))  // 1 Jul 1994
    nleaps = 29;
  else if (utc_unix_seconds >= ntp_to_unix(2950473600UL))  // 1 Jul 1993
    nleaps = 28;
  else if (utc_unix_seconds >= ntp_to_unix(2918937600UL))  // 1 Jul 1992
    nleaps = 27;
  else if (utc_unix_seconds >= ntp_to_unix(2871676800UL))  // 1 Jan 1991
    nleaps = 26;
  else if (utc_unix_seconds >= ntp_to_unix(2840140800UL))  // 1 Jan 1990
    nleaps = 25;
  else if (utc_unix_seconds >= ntp_to_unix(2776982400UL))  // 1 Jan 1988
    nleaps = 24;
  else if (utc_unix_seconds >= ntp_to_unix(2698012800UL))  // 1 Jul 1985
    nleaps = 23;
  else if (utc_unix_seconds >= ntp_to_unix(2634854400UL))  // 1 Jul 1983
    nleaps = 22;
  else if (utc_unix_seconds >= ntp_to_unix(2603318400UL))  // 1 Jul 1982
    nleaps = 21;
  else if (utc_unix_seconds >= ntp_to_unix(2571782400UL))  // 1 Jul 1981
    nleaps = 20;
  else
    nleaps = 19;

  const long gps_seconds = utc_unix_seconds - gps_offset_to_utc_unix + nleaps;
  return (gps_seconds > 0) ? gps_seconds : 0;
}


long gps_unix_to_utc(long gps_seconds)
{
  long utc_seconds = gps_seconds + gps_offset_to_utc_unix;
  while (utc_unix_to_gps(utc_seconds) > gps_seconds)
    utc_seconds--;

  return utc_seconds;
}
