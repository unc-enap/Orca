CONCURRENT  = /usr/local/universe/lib/libcctvmeen.so
DRIVERLINK  = $(wildcard $(CONCURRENT))
UCFLAGS     = -g -Wall -gstabs+ -D_LINUX -DNeedHwMutex -I/usr/local/universe/include
LFLAGS      = -lpthread -lstdc++ -ldl -L/usr/local/universe/lib $(DRIVERLINK) -luniverse_api
