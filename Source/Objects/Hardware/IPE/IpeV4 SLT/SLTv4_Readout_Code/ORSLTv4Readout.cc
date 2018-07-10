#include "ORSLTv4Readout.hh"
#include "readout_code.h"


#ifndef PMC_COMPILE_IN_SIMULATION_MODE
	#define PMC_COMPILE_IN_SIMULATION_MODE 0
#endif

#if PMC_COMPILE_IN_SIMULATION_MODE
    #warning MESSAGE: ORSLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 1
    #include <sys/time.h> // for gettimeofday on MAC OSX -tb-
#else
    //#warning MESSAGE: ORFLTv4Readout - PMC_COMPILE_IN_SIMULATION_MODE is 0
	#include "katrinhw4/subrackkatrin.h"
#endif


#if !PMC_COMPILE_IN_SIMULATION_MODE
// (this is the standard code accessing the v4 crate-tb-)
//----------------------------------------------------------------
extern hw4::SubrackKatrin* srack; 

bool ORSLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
    //init
    //uint32_t secondsSetSendToFLTs = GetDeviceSpecificData()[0];
    //uint32_t runFlags   = GetDeviceSpecificData()[3];//this is runFlagsMask of ORKatrinV4FLTModel.m, load_HW_Config_Structure:index:


    //SLT read out
     //  currently there is no readout, but we init the timers
    
    
    int32_t leaf_index;
    //read out the children flts that are in the readout list
    leaf_index = GetNextTriggerIndex()[0];
    while(leaf_index >= 0) {
        leaf_index = readout_card(leaf_index,lamData);
    }
    
    
 
    return true; 
}


#else //of #if !PMC_COMPILE_IN_SIMULATION_MODE
// (here follow the 'simulation' versions of all functions -tb-)
//----------------------------------------------------------------

// 'simulation' of hitrate is done in HW_Readout.cc in doReadBlock -tb-

bool ORSLTv4Readout::Readout(SBC_LAM_Data* lamData)
{
#if 1
    //"counter" for debugging/simulation
    static int currentSec=0;
    static int currentUSec=0;
    static int lastSec=0;
    static int lastUSec=0;
    //static long int counter=0;
    static long int secCounter=0;
    
    struct timeval t;//    struct timezone tz; is obsolete ... -tb-
    //timing
    gettimeofday(&t,NULL);
    currentSec = t.tv_sec;  
    currentUSec = t.tv_usec;  
    double diffTime = (double)(currentSec  - lastSec) +
    ((double)(currentUSec - lastUSec)) * 0.000001;
    
    if(diffTime >1.0){
        secCounter++;
        printf("PrPMC (SLTv4 simulation mode) sec %ld: 1 sec is over ...\n",secCounter);
        fflush(stdout);
        //remember for next call
        lastSec      = currentSec; 
        lastUSec     = currentUSec; 
    }else{
        // skip shipping data record
        // obsolete ... return config->card_info[index].next_Card_Index;
        // obsolete, too ... return GetNextCardIndex();
    }
#endif
	//loop over FLTs
    int32_t leaf_index;
    //read out the children flts that are in the readout list
    leaf_index = GetNextTriggerIndex()[0];
    while(leaf_index >= 0) {
        leaf_index = readout_card(leaf_index,lamData);
    }
    
    
#if 0
    uint32_t dataId            = config->card_info[index].hw_mask[0];
    uint32_t stationNumber     = config->card_info[index].slot;
    uint32_t crate             = config->card_info[index].crate;
    data[dataIndex++] = dataId | 5;
    data[dataIndex++] =  ((stationNumber & 0x0000001f) << 16) | (crate & 0x0f) <<21;
    data[dataIndex++] = 6;
    data[dataIndex++] = 8;
    data[dataIndex++] = 15;
#endif
 
    return true; 
}




#endif //of #if !PMC_COMPILE_IN_SIMULATION_MODE ... #else ...
//----------------------------------------------------------------



