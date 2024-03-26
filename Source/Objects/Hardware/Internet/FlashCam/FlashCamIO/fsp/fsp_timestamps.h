#pragma once

typedef struct Timestamp {
  long seconds;
  long nanoseconds;
} Timestamp;

Timestamp timestamp_sub(Timestamp a, Timestamp b);
Timestamp timestamp_add(Timestamp a, Timestamp b);
int timestamp_geq(Timestamp a, Timestamp b);
int timestamp_greater(Timestamp a, Timestamp b);
int timestamp_leq(Timestamp a, Timestamp b);
int timestamp_less(Timestamp a, Timestamp b);
