CC=gcc
CFLAGS=-I. -g -Wall

LIBS=-lLabJackM

%.o: %.c
	$(CC) -c -o $@ $< $(CFLAGS)

test_t7 : test_t7.o orca_t7.o
	$(CC) -o $@ $^ $(CFLAGS) $(LIBS)

.PHONY : clean

clean:
	rm -vf test_t7 *.o
