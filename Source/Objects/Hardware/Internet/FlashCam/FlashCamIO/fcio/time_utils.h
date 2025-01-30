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


#ifndef __TIME_UTILS_H__
#define __TIME_UTILS_H__

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus


int nsleep(double seconds);
double elapsed_time(double offset);
long utc_unix_to_gps(long utc_seconds);
long gps_unix_to_utc(long gps_seconds);
double timer_expired(double *t, const double interval);


#ifdef __cplusplus
}
#endif // __cplusplus

#endif // __TIME_UTILS_H__
