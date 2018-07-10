#this configures the make process (-include will silently skip if the file does not exist -tb-):
-include simulationmode.mk
-include linkwithdmalib.mk


# 2013-04 changes -tb-
# automatic compilation with PCIDMA on 64 bit machines or when SLT driver ver. 3 is loaded.
#SLTDRVVERSION=$(shell cat /proc/devices | awk '/fzk_ipe_slt/{print $2}'  | cut -b 12-)
SLTDRVVERSION=$(shell cat /proc/devices | grep fzk_ipe_slt   | tail -c2)
#testflags = xxx $(cat /proc/devices | grep fzk_ipe_slt | awk '/fzk_ipe_slt/{print $2}'  | cut -b 12-) yyy
#testflags = xxx $(shell cat /proc/devices | grep fzk_ipe_slt   | tail -c2) yyy
#sltdrvversion = -DSLTDRVVERSION=$(shell cat /proc/devices | grep fzk_ipe_slt   | tail -c2)
sltdrvversion = -DSLTDRVVERSION=$(SLTDRVVERSION)


# 2013-03 changes -tb-
# Simulation mode and new Macs (as local host): they use clang, not gcc any more:
# - removed compile option -gstabs+ (GNU GCC specific)
# - added defines to use gcc (now or from OSX 10.8 CXX is c++, CC?)
# - added defines to use gcc and compile 32-bit application (for testing)
#Standard: use standard on target system (usually gcc on Linux, clang/llvm on OSX >= 10.8)
#CXX=gcc
#CC=gcc
#CXX=gcc -m32
#CC=gcc -m32


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

#-tb- Conditional compiling (with pci dma library or with standard pci lib):
# added 2013-04: if DPMC_LINK_WITH_DMA_LIB is not set explicitly,
#                compilation is done by checking the host system
ifeq ($(PMC_LINK_WITH_DMA_LIB),1)
  defflags2='-DPMC_LINK_WITH_DMA_LIB=1'
endif
ifeq ($(PMC_LINK_WITH_DMA_LIB),0)
  defflags2='-DPMC_LINK_WITH_DMA_LIB=0'
endif



UCFLAGS =  -g -Wall   -I ~/src/v4/fdhwlib/src  $(defflags)  $(defflags2) $(sltdrvversion)
#2013-03: removed  -gstabs+: UCFLAGS =  -g -Wall  -gstabs+ -I ~/src/v4/fdhwlib/src  $(defflags)  $(defflags2)
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

#SYSTEMARCH = x86_64
#-tb- Conditional compiling (with hardware library or with hardware simulation):
#without DMA:  LFLAGS  =  -fexceptions -lPbusPCI  -lkatrinhw4 -lhw4 -lakutil -lpthread -lstdc++
#for DMA:    LFLAGS  =  -fexceptions -lPbusPCIDMA  -lkatrinhw4 -lhw4 -lakutil -lpthread -lstdc++
ifeq ($(PMC_COMPILE_IN_SIMULATION_MODE),1)
  LFLAGS  =  -fexceptions -lpthread -lstdc++
else
  ifeq ($(PMC_LINK_WITH_DMA_LIB),1)
    LFLAGS  =  -fexceptions -lPbusPCIDMA  -lkatrinhw4 -lhw4 -lakutil -lpthread -lstdc++
  else ifeq ($(PMC_LINK_WITH_DMA_LIB),0)
    LFLAGS  =  -fexceptions -lPbusPCI  -lkatrinhw4 -lhw4 -lakutil -lpthread -lstdc++
  else
      #2013-04 if not explicitly defined, we try to detect the architecture (32/64 bit machine) and SLT driver version -tb-
      #SYSTEMARCH = $(shell uname -m)
      #ifeq ($(SYSTEMARCH),x86_64)
      ifeq ($(SLTDRVVERSION),3)
          #TODO - TODO - TODO - TODO - TODO - TODO - TODO - for new driver versions I need to extend this! currently only ver.3 -tb-
          PMC_LINK_WITH_DMA_LIB=1
          defflags2='-DPMC_LINK_WITH_DMA_LIB=1'
          LFLAGS  =  -fexceptions -lPbusPCIDMA  -lkatrinhw4 -lhw4 -lakutil -lpthread -lstdc++
      else
          PMC_LINK_WITH_DMA_LIB=0
          defflags2='-DPMC_LINK_WITH_DMA_LIB=0'
          LFLAGS  =  -fexceptions -lPbusPCI  -lkatrinhw4 -lhw4 -lakutil -lpthread -lstdc++
      endif
  endif



endif

#LFLAGS  =  -fexceptions -lPbusPCI  -lkatrinhw4 -lhw4 -lakutil -lpthread -lstdc++
LIBs    = 
