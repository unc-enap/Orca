-include HWMakefile.mk

TARGET = OrcaReadout
CSOURCES = $(wildcard *.c) 
CCSOURCES = $(wildcard *.cc) 


OBJECTS = $(filter-out $(patsubst %, %.o,$(TARGET)), $(CSOURCES:.c=.o) $(CCSOURCES:.cc=.o) )

all: depend $(TARGET)

.depend depend:
	@echo "Checking dependencies..."
	@$(CXX) -M $(UCFLAGS) $(CSOURCES) $(CCSOURCES) > .depend

$(TARGET): $(OBJECTS)
	@echo linking $*
	$(CXX)  -o $(TARGET) $(OBJECTS) $(LIBs) $(LFLAGS)  

%.o: %.c
	@echo compiling $*
	$(CC) -c $(UCFLAGS) $<

%.o: %.cc
	@echo compiling $*
	$(CXX) -c $(UCFLAGS) $<


clean :
	rm -f $(TARGET) *.o .depend

#ifneq ($(MAKECMDGOALS), clean)
-include .depend
#end if
