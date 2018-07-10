//
// SLTv4_HW_Definitions.h
//  Orca
//
//  Created by Mark Howe on Mon Mar 10, 2008
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#ifndef _H_SLTV4HWDEFINITIONS_
#define _H_SLTV4HWDEFINITIONS_

#define kSLTv4EW    1
#define kFLTv4EW    2

//#define kNumEWTriggFLTChannels 18  //use kNumEWFLTHeatIonChannels


//SLT revisions which require special handling ...
#define kSLTRev20131212_5WordsPerEvent	0x41950242
//FLT events in SLT Event FIFO consists now of 5 instead of 4 words
//+ new driver necessary (kit_ipe_slt)
#define kSLTRev20140710_TimerWithSubsec	0x41970018
//the 48 bit SLT time register now counts in 100 kHz sub units (was rounded to seconds up to now)


#define kReadWaveForms	0x1 << 0

//Edelweiss SLT DAQ modes  -> for sltDAQMode -tb-
#define kSltDAQMode_Event_Mode		        0
#define kSltDAQMode_Orca_Streaming		    1
#define kSltDAQMode_ipe4reader_Streaming    2
#define kSltDAQMode_Monitoring		        3


//flt run modes (sent to hw, FLTv4 control register) -> for fltRunMode -tb-
//OBSOLETE - KATRIN MODES !
#define kIpeFltV4Katrin_StandBy_Mode		0
#define kIpeFltV4Katrin_Run_Mode			1
#define kIpeFltV4Katrin_Histo_Mode			2
#define kIpeFltV4Katrin_Veto_Mode			3
//#define kIpeFltV4Katrin_Test_Mode			3   //TODO: see fpga8_package.vhd -tb-


#if 0
//daq run modes set by user in popup -> for daqRunMode -tb-
//old names: kIpeFlt_EnergyMode, kIpeFlt_EnergyTrace, kIpeFlt_Histogram_Mode
#define kIpeFltV4_EnergyDaqMode					0
#define kIpeFltV4_EnergyTraceDaqMode			1
#define kIpeFltV4_Histogram_DaqMode				2
#define kIpeFltV4_VetoEnergyDaqMode				3
#define kIpeFltV4_VetoEnergyTraceDaqMode		4
#define kIpeFltV4_VetoEnergyAutoDaqMode			5
#define kIpeFltV4_VetoEnergyTraceSyncDaqMode	6
// new modes after mode redesign 2011-01 -tb-
#define kIpeFltV4_EnergyTraceSyncDaqMode		7
#define kIpeFltV4_NumberOfDaqModes				8
// kIpeFltV4_NumberOfDaqModes MUST be the number of daq modes; no gaps allowed! TODO: using a enum would be better -tb- <------NOTE!

#else
// I switched to enums to always have a guilty kIpeFltV4_NumberOfDaqModes; older Orca versions may get newer Orca files with daq modes
// still unknown to the older Orca; with kIpeFltV4_NumberOfDaqModes we can check this -tb-
enum daqMode { 
	kIpeFltV4_EventDaqMode			= 0,
	kIpeFltV4_MonitoringDaqMode		= 1,
#if 0
	kIpeFltV4_EnergyTraceDaqMode	= 1,
	kIpeFltV4_Histogram_DaqMode		= 2,
	kIpeFltV4_VetoEnergyDaqMode		= 3, 
	kIpeFltV4_VetoEnergyTraceDaqMode= 4,
	kIpeFltV4_VetoEnergyAutoDaqMode = 5, //for future use
	kIpeFltV4_VetoEnergyTraceSyncDaqMode	= 6, //for future use
	kIpeFltV4_EnergyTraceSyncDaqMode= 7,
#endif
	kIpeFltV4_NumberOfDaqModes // do not assign a value, the compiler will do it
};
#endif
	
//flags in the runFlagsMask, sent to PrPMC by ORIpeV4FLTModel::load_HW_Config_Structure
#define kFirstTimeFlag                          0x10000
#define kTakeEventDataFlag                      0x20000
//KATRIN #define kShipSumHistogramFlag		0x40000
#define kSaveIonChanFilterOutputRecordsFlag		0x40000

typedef struct { // -tb- 2008-02-27
	int32_t readoutSec;
	int32_t refreshTimeSec;  //! this holds the refresh time -tb-
	int32_t firstBin;
	int32_t lastBin;
	int32_t histogramLength; //don't use unsigned! - it may become negative, at least temporaryly -tb-
    int32_t maxHistogramLength;
    int32_t binSize;
    int32_t offsetEMin;
    uint32_t histogramID;
    uint32_t histogramInfo;
} katrinV4HistogramDataStruct;




#if 0 //TODO: remove, moved to ipe4structure.h -tb-

//TODO: add/include ipe4reader6.h (then: ipe4ewstreamer.h) -tb-
//TODO: -------------------------------------------------- -tb-
/*--------------------------------------------------------------------
 *    UDP packed definitions
 *       data, IPE crate status  -tb-
 *--------------------------------------------------------------------*/ //-tb-
#if 0
//size: id + header + 21*16 + UDPFIFOmap + IPmap = (1 + 8 + 336 + 5 + 20) 32-bit words = 1480 bytes
#define MAX_NUM_FLT_CARDS 20
#define IPE_BLOCK_SIZE    16

//defined  somewere else ...#define SIZEOF_UDPStructIPECrateStatus 1480
#endif

typedef struct{
    //identification
    union {
	    uint32_t		id4;  //packet header: 16 bit id=0xFFD0 + 16 bit reserved
	    struct {
	        uint16_t id0; 
	        uint16_t id1;};
	};
	
    //header
	uint32_t	presentFLTMap;
	uint32_t	reserved0;
	uint32_t	reserved1;
	
	//SLT info (16 words)
	uint32_t    SLT[IPE_BLOCK_SIZE];                   //one 16 word32 block for the SLT

    //FLT info (20x16 = 320 words)
	uint32_t    FLT[MAX_NUM_FLT_CARDS][IPE_BLOCK_SIZE];//twenty FLTs, one 16 word32 block per each FLT
    
    //IP Adress Map (20 words)
	uint32_t	IPAdressMap[MAX_NUM_FLT_CARDS];    //IP address map associated to the according SLT/HW FIFO
    //Port Map      (10 words)
	uint16_t	PortMap[MAX_NUM_FLT_CARDS];        //IP address map associated to the according SLT/HW FIFO
}
UDPStructIPECrateStatus;



#endif






#endif
