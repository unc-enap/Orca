#include "timestamps.h"

Timestamp timestamp_sub(Timestamp a, Timestamp b) {
  long sec_diff = a.seconds - b.seconds;
  long nsec_diff = a.nanoseconds - b.nanoseconds;

  while (nsec_diff < 0) {
    nsec_diff += 1000000000L;
    sec_diff--;
  }
  while (nsec_diff > 1000000000L) {
    nsec_diff -= 1000000000L;
    sec_diff++;
  }
  Timestamp diff = {.seconds = sec_diff, .nanoseconds = nsec_diff};
  return diff;
}

Timestamp timestamp_add(Timestamp a, Timestamp b) {
  long sec_sum = a.seconds + b.seconds;
  long nsec_sum = a.nanoseconds + b.nanoseconds;

  while (nsec_sum > 1000000000L) {
    nsec_sum -= 1000000000L;
    sec_sum++;
  }
  Timestamp sum = {.seconds = sec_sum, .nanoseconds = nsec_sum};
  return sum;
}

int timestamp_geq(Timestamp a, Timestamp b) {
  if (a.seconds > b.seconds) {
    return 1;
  } else if (a.seconds == b.seconds && a.nanoseconds >= b.nanoseconds) {
    return 1;
  } else {
    return 0;
  }
}

int timestamp_greater(Timestamp a, Timestamp b) {
  if (a.seconds > b.seconds) {
    return 1;
  } else if (a.seconds == b.seconds && a.nanoseconds > b.nanoseconds) {
    return 1;
  } else {
    return 0;
  }
}

int timestamp_leq(Timestamp a, Timestamp b) {
  if (a.seconds < b.seconds) {
    return 1;
  } else if (a.seconds == b.seconds && a.nanoseconds <= b.nanoseconds) {
    return 1;
  } else {
    return 0;
  }
}

int timestamp_less(Timestamp a, Timestamp b) {
  if (a.seconds < b.seconds) {
    return 1;
  } else if (a.seconds == b.seconds && a.nanoseconds < b.nanoseconds) {
    return 1;
  } else {
    return 0;
  }
}
