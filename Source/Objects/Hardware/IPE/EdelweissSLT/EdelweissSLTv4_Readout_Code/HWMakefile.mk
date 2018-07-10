#this configures the make process (-include will silently skip if the file does not exist -tb-):
-include simulationmode.mk


# RECOMMENDED SETUP:
# It is assuemed that the fdhwlib is compiled in the folder: ~/src/v4
#
# create the folder ~/lib and add following line in .bashrc:
# export LIBRARY_PATH=$LIBRARY_PATH:/home/katrin/lib
# add following line in .bashrc:
# export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:/home/katrin/src/v4/fdhwlib/src
# 
# ... to be continued ...
#
# -tb- 2009-09 
# mail: till.bergmann@ipe.fzk.de
#
# UPDATE:
# now there is a rpm repository, which may be installed with 'yast'
# (then UCFLAGS = ... -I ~/src/v4/fdhwlib/src  isn't necessary any more)
# -tb- 2009-09 
# mail: till.bergmann@kit.edu



#-tb- Conditional compiling (with hardware library or with hardware simulation):
ifeq ($(PMC_COMPILE_IN_SIMULATION_MODE),1)
  defflags='-DPMC_COMPILE_IN_SIMULATION_MODE=1'
else
  defflags='-DPMC_COMPILE_IN_SIMULATION_MODE=0'
endif

UCFLAGS =  -g -Wall  -gstabs+ -I ~/src/v4/fdhwlib/src  $(defflags)
#Note: -Wno-sign-compare supresses 'comparison int with unsigned int' compiler warning -tb-
#LFLAGS  = -fexceptions -lpbusaccess -lPbus1394 -lakutil -lpthread -lstdc++ \
#                                /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation \
#                                /System/Library/Frameworks/IOKit.framework/IOKit 

#-tb- Use this for Pbus  simulation mode (yes, -lPbusSim is needed two times!):
#LFLAGS  =  -fexceptions -lpbusaccess -lPbusSim -lHw -lPbusSim  -lakutil -lpthread -lstdc++ 

#-tb- Use this for V4 SLT+FLT PbusPCI lib (Linux only!):
# This used libpbusaccess (C wrapper for C++ fdhwlib), benefit: uses C; misfit: needs to link with non-fdhwlib library
#UCFLAGS =  -g -Wall  -gstabs+ -I ~/src/v4/fdhwlib/src -I ~/src/v4/pbusaccess
#LFLAGS  =  -fexceptions -lpbusaccess -lPbusPCI  -lkatrinhw4 -lhw4 -lakutil -lpthread -lstdc++ 

#-tb- Use this for V4 SLT PbusPCI lib (Linux only!):
#LFLAGS  =  -fexceptions -lPbusPCI  -lkatrinhw4 -lhw4 -lakutil -lpthread -lstdc++ 
#LIBs    = 


#-tb- Conditional compiling (with hardware library or with hardware simulation):
ifeq ($(PMC_COMPILE_IN_SIMULATION_MODE),1)
  LFLAGS  =  -fexceptions -lpthread -lstdc++
else
  LFLAGS  =  -fexceptions -lPbusPCIDMA  -lkatrinhw4 -lhw4 -lakutil -lpthread -lstdc++
#for DMA:        LFLAGS  =  -fexceptions -lPbusPCIDMA  -lkatrinhw4 -lhw4 -lakutil -lpthread -lstdc++
#without DMA:    LFLAGS  =  -fexceptions -lPbusPCI  -lkatrinhw4 -lhw4 -lakutil -lpthread -lstdc++

endif
#LFLAGS  =  -fexceptions -lPbusPCI  -lkatrinhw4 -lhw4 -lakutil -lpthread -lstdc++
LIBs    = 
