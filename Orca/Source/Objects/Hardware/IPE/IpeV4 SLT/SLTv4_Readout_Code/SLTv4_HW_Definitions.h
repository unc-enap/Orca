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

#define kSLTv4    1
#define kFLTv4    2

#define kKatrinV4SLT    1   //TODO: !!!!!!!!!!!!

#define kReadWaveForms	0x1 << 0

//flt run modes (sent to hw, FLTv4 control register) -> for fltRunMode -tb-
#define kIpeFltV4Katrin_StandBy_Mode		0
#define kIpeFltV4Katrin_Run_Mode			1
#define kIpeFltV4Katrin_Histo_Mode			2
#define kIpeFltV4Katrin_Veto_Mode			3
#define kIpeFltV4Katrin_Bipolar_Mode		5
//#define kIpeFltV4Katrin_Test_Mode			3   //TODO: see fpga8_package.vhd -tb-

enum daqMode {
	kIpeFltV4_EnergyDaqMode			= 0,
	kIpeFltV4_EnergyTraceDaqMode	= 1,
	kIpeFltV4_Histogram_DaqMode		= 2,
	kIpeFltV4_VetoEnergyDaqMode		= 3, 
	kIpeFltV4_VetoEnergyTraceDaqMode= 4,
	kIpeFltV4_VetoEnergyAutoDaqMode = 5, //for future use
	kIpeFltV4_VetoEnergyTraceSyncDaqMode	= 6, //for future use
	kIpeFltV4_EnergyTraceSyncDaqMode= 7,
	kIpeFltV4_BipolarEnergyDaqMode  = 8,
	kIpeFltV4_BipolarEnergyTraceDaqMode  = 9,
	kIpeFltV4_NumberOfDaqModes // do not assign a value, the compiler will do it
};

//flags in the runFlagsMask, sent to PrPMC by ORIpeV4FLTModel::load_HW_Config_Structure
#define kFirstTimeFlag              0x010000
#define kSyncFltWithSltTimerFlag    0x020000
#define kShipSumHistogramFlag		0x040000
#define kSecondsSetInitWithHostFlag	0x080000
#define kSecondsSetSendToFLTsFlag	0x100000
#define kSkipFltEventReadoutFlag	0x200000  //unused, thus the same as kForceFltReadoutFlag
#define kForceFltReadoutFlag	    0x200000

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

typedef struct { // -tb- 2013-05-27 struct for histogram buffer (for summing up histograms)
	uint32_t orcaHeader;
	uint32_t location;
	int32_t readoutSec;
	int32_t refreshTimeSec;  
	int32_t firstBin;
	int32_t lastBin;
	int32_t histogramLength; //don't use unsigned! - it may become negative, at least temporaryly -tb-
    int32_t maxHistogramLength;
    int32_t binSize;
    int32_t offsetEMin;
    uint32_t histogramID;
    uint32_t histogramInfo;
    uint32_t h[2048];
} katrinV4FullHistogramDataStruct;


#endif
