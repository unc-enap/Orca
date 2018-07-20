//
//  OREdelweissFLTModel.h
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ‚Ä¢‚Ä¢‚Ä¢Imported Files
#import "ORIpeCard.h"
#import "ORHWWizard.h"
#import "ORDataTaker.h"
#import "OREdelweissFLTDefs.h"
#import "ORAdcInfoProviding.h"

#import "ipe4structure.h"



#pragma mark ‚Ä¢‚Ä¢‚Ä¢Forward Definitions
@class ORDataPacket;
@class ORTimeRate;
@class ORTestSuit;
@class ORCommandList;
@class ORRateGroup;

#define kNumEdelweissFLTTests 5
#define kEdelweissFLTBufferSizeLongs 1024
#define kEdelweissFLTBufferSizeShorts 1024/2

/** Access to the EDELWEISS first level trigger board of the IPE-DAQ V4 electronics.
 * The board contains 6 optical fiber inputs for bolometer ADC data and 
 * 6 optical fiber outputs for bolometer box commands. 
 * 
 * @section hwaccess Access to hardware  
 * ... uses the SBC Orca protocoll (software bus, using TCP/IP). 
 *
 * Every time a run is started the stored configuratiation is written to the
 * hardware before recording the data.
 *
 * The interface to the graphical configuration dialog is implemented in OREdelweissFLTController.
 *
 * The Flt will produce several types of data objects depending on the run mode:
 *   - events containing timestamp and energy
 *   - events with an additional adc data trace of ??? length (??? samples) //TODO:
 * 
 * @section readout Readout
 * UNDER CONSTRUCTION
 * .
 *
 */ 
@interface OREdelweissFLTModel : ORIpeCard <ORDataTaker,ORHWWizard,ORHWRamping,ORAdcInfoProviding>
{
    // Hardware configuration
    //int				fltRunMode;		replaced by flt ModeFlags -tb-
    NSMutableArray* thresholds;     //!< Array to keep the threshold of all 18 (==kNumEWFLTHeatIonChannels) channels
    NSMutableArray* triggerParameter;     //!< Array to keep the trigger parameters (heat+ion) - currently used for save/load only -tb-
    uint32_t        triggerPar[kNumEWFLTHeatIonChannels];//!< Array to keep the trigger parameters (heat+ion)
	uint32_t	hitRateEnabledMask;	//!< mask to store the activated trigger rate measurement
    NSMutableArray* gains;			//!< Aarry to keep the gains
    uint32_t	dataId;         //!< Id used to identify energy data set (run mode)
	uint32_t	waveFormId;		//!< Id used to identify energy+trace data set (debug mode)
	uint32_t	hitRateId;
	uint32_t	histogramId;
	unsigned short	hitRateLength;		//!< Sampling time of the hitrate measurement (hitrate period, 8 bit, 2**hitRateLength seconds)
	uint32_t		hitRateReg[kNumEWFLTHeatIonChannels];	//!< Actual value of the trigger rate/hitrate  register
	float			hitRate[kNumEWFLTHeatIonChannels];	//!< Actual value of the trigger rate measurement
	BOOL			hitRateOverFlow[kNumEWFLTHeatIonChannels];	//!< Overflow of hardware trigger rate register
	float			hitRateTotal;	//!< Sum trigger rate of all channels 
	
	BOOL			firstTime;		//!< Event loop: Flag to identify the first readout loop for initialization purpose
	
	ORTimeRate*		totalRate;
    int				analogOffset;
	uint32_t   statisticOffset; //!< Offset guess used with by the hardware statistical evaluation
	uint32_t   statisticN;		 //!< Number of samples used for statistical evaluation
	uint32_t   eventMask;		 //!<Bits set for last channels hit.
	
	//testing
	NSMutableArray* testStatusArray;
	NSMutableArray* testEnabledArray;
	BOOL testsRunning;
	ORTestSuit* testSuit;
	int savedMode;
	int savedLed;
	BOOL usingPBusSimulation;
    BOOL ledOff;
    uint32_t interruptMask;
	    
	// Register information (low level tab)
    unsigned short  selectedRegIndex;
    uint32_t   writeValue;
    uint32_t   selectedChannelValue;
    // fields for event readout
    int fifoBehaviour;
    uint32_t postTriggerTime;
    int gapLength;
    int filterLength;  //for ORKatrinV4FLTModel we use filterShapingLength from 2011-04/Orca:svnrev5050 on -tb- 
    BOOL storeDataInRam;
    BOOL runBoxCarFilter;
    BOOL readWaveforms;
    int runMode;        //!< This is the daqRunMode (not the fltRunMode on the hardware).
	                    //TODO: meaning runMode changed (compared to KATRIN); for EW we have several mode flags -tb-
    
	
    //TODO: obsolete (?) - remove it -tb- 2013-06
	BOOL noiseFloorRunning;
	int noiseFloorState;
	int noiseFloorOffset;
    int targetRate;
	int32_t noiseFloorLow[kNumEWFLTHeatIonChannels];
	int32_t noiseFloorHigh[kNumEWFLTHeatIonChannels];
	int32_t noiseFloorTestValue[kNumEWFLTHeatIonChannels];
	BOOL oldEnabled[kNumEWFLTHeatIonChannels];
	int32_t oldThreshold[kNumEWFLTHeatIonChannels];
	int32_t newThreshold[kNumEWFLTHeatIonChannels];
	
	uint32_t eventCount[kNumEWFLTHeatIonChannels];
	
    //EDELWEISS vars
    int fltModeFlags; //TODO: unused, using "uint32_t controlRegister"
    //int tpix; //TODO: unused, using "uint32_t controlRegister"
    int fiberEnableMask;
    //int BBv1Mask;
    int selectFiberTrig;
	//uint64_t streamMask;
    uint64_t streamMask;
    uint64_t fiberDelays;
    int fastWrite;
    uint32_t statusRegister;
    int totalTriggerNRegister;
    uint32_t controlRegister;
    int repeatSWTriggerMode;
    double repeatSWTriggerDelay;
    int swTriggerIsRepeating;
    uint32_t fiberOutMask;
    int fiberSelectForBBStatusBits;
    int testVariable;
    uint32_t CFPGAVersion;
    
    
    uint32_t statusBitsBB[kNumEWFLTFibers][kNumBBStatusBufferLength32];//default: [6][30]
    uint32_t oldStatusBitsBB[kNumEWFLTFibers][kNumBBStatusBufferLength32];//I store the old set of the status bits
    NSMutableData* statusBitsBBData;//used for  writing 'statusBitsBB' to file
    int relaisStatesBB; //remove it
    int fiberSelectForBBAccess;
    int useBroadcastIdforBBAccess;
    #if 0
    int idBBforBBAccess;
    int adcFreqkHzForBBAccess;  //remove it!!!
    int adcMultForBBAccess;    //remove it!!!
    int adcValueForBBAccess;   //remove it
    int adcRgForBBAccess;   //remove it
    int signa;//remove it
    int daca;//remove it
    int signb;//remove it
    int dacb;//remove it
    
    int adcRtForBBAccess;   //remove it
    int adcRt;  //remove it
    #endif
    unsigned int wCmdCode;
    unsigned int wCmdArg1;
    unsigned int wCmdArg2;
    int writeToBBMode;
    int lowLevelRegInHex;
    uint64_t ionTriggerMask;
    uint64_t heatTriggerMask;
    int ionToHeatDelay;
    uint32_t BB0x0ACmdMask;
    int pollBBStatusIntervall;
    
    NSString* chargeBBFile;
    NSString* chargeBBFileForFiber[kNumEWFLTFibers];
    int progressOfChargeBB;
    
    int progressOfChargeFIC;
    NSString* chargeFICFile;
    
    uint32_t ficCardCtrlReg1[kNumEWFLTFibers];
    uint32_t ficCardCtrlReg2[kNumEWFLTFibers];
    uint32_t ficCardADC01CtrlReg[kNumEWFLTFibers];
    uint32_t ficCardADC23CtrlReg[kNumEWFLTFibers];
    uint32_t ficCardTriggerCmd[kNumEWFLTFibers];
    int hitrateLimitHeat;
    int hitrateLimitIon;
    BOOL saveIonChanFilterOutputRecords;//unused
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (short) getNumberRegisters;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
//- (void) runIsAboutToStop:(NSNotification*)aNote;
- (void) runIsAboutToStart:(NSNotification*)aNote;
- (void) runIsAboutToChangeState:(NSNotification*)aNote;
- (BOOL) preRunChecks;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Accessors
- (BOOL) saveIonChanFilterOutputRecords;
- (void) setSaveIonChanFilterOutputRecords:(BOOL)aSaveIonChanFilterOutputRecords;
- (int) hitrateLimitIon;
- (void) setHitrateLimitIon:(int)aHitrateLimitIon;
- (int) hitrateLimitHeat;
- (void) setHitrateLimitHeat:(int)aHitrateLimitHeat;
- (NSString*) chargeFICFile;
- (void) setChargeFICFile:(NSString*)aChargeFICFile;
- (int) progressOfChargeFIC;
- (void) setProgressOfChargeFIC:(int)aProgressOfChargeFIC;
- (uint32_t) ficCardTriggerCmdForFiber:(int)aFiber;
- (void) setFicCardTriggerCmd:(uint32_t)aFicCardTriggerCmd forFiber:(int)aFiber;
- (uint32_t) ficCardADC23CtrlRegForFiber:(int)aFiber;
- (void) setFicCardADC23CtrlReg:(uint32_t)aFicCardADC23CtrlReg forFiber:(int)aFiber;
- (uint32_t) ficCardADC01CtrlRegForFiber:(int)aFiber;
- (void) setFicCardADC01CtrlReg:(uint32_t)aFicCardADC01CtrlReg forFiber:(int)aFiber;
- (uint32_t) ficCardCtrlReg2ForFiber:(int)aFiber;
- (void) setFicCardCtrlReg2:(uint32_t)aFicCardCtrlReg2 forFiber:(int)aFiber;
- (void) setFicCardCtrlReg2AddrOffs:(uint32_t)aOffset  forFiber:(int)aFiber;
- (uint32_t) ficCardCtrlReg1ForFiber:(int)aFiber;
- (void) setFicCardCtrlReg1:(uint32_t)aFicCardCtrlReg1 forFiber:(int)aFiber;
- (int) pollBBStatusIntervall;
- (void) setPollBBStatusIntervall:(int)aPollBBStatusIntervall;
- (int) progressOfChargeBB;
- (void) setProgressOfChargeBB:(int)aProgressOfChargeBB;
- (NSString*) chargeBBFileForFiber:(int) aFiber;
- (void) setChargeBBFile:(NSString*)aChargeBBFileForFiber forFiber:(int) aFiber;
  - (int) chargeBBWithDataFromFile:(NSString*)aFilename;
- (uint32_t) BB0x0ACmdMask;
- (void) setBB0x0ACmdMask:(uint32_t)aBB0x0ACmdMask;
- (NSString*) chargeBBFile;
- (void) setChargeBBFile:(NSString*)aChargeBBFile;
- (int) ionToHeatDelay;
- (void) setIonToHeatDelay:(int)aIonToHeatDelay;
- (int) lowLevelRegInHex;
- (void) setLowLevelRegInHex:(int)aLowLevelRegInHex;
- (int) writeToBBMode;
- (void) setWriteToBBMode:(int)aWriteToBBMode;
- (void) setDefaultsToBB:(int)aFiber;
- (void) writeDefaultsToBB:(int)aFiber;
- (void) writeAllToBB:(int)aFiber;

- (unsigned int) wCmdArg2;
- (void) setWCmdArg2:(unsigned int)aWCmdArg2;
- (unsigned int) wCmdArg1;
- (void) setWCmdArg1:(unsigned int)aWCmdArg1;
- (unsigned int) wCmdCode;
- (void) setWCmdCode:(unsigned int)aWCmdCode;
- (NSMutableData*) statusBitsBBData;
- (void) setStatusBitsBBData:(NSMutableData*)aStatusBitsBBData;

- (int) dacbForFiber:(int)aFiber atIndex:(int)aIndex;
- (void) setDacbForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aDacb;
- (int) signbForFiber:(int)aFiber atIndex:(int)aIndex;
- (void) setSignbForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aSignb;
- (int) dacaForFiber:(int)aFiber atIndex:(int)aIndex;
- (void) setDacaForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aDaca;
- (int) signaForFiber:(int)aFiber atIndex:(int)aIndex;
- (void) setSignaForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aSigna;
- (int) adcRgForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex;
- (void) setAdcRgForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aAdcRgForBBAccess;
- (void) writeAdcRgForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex;//HW access for Regul Parameter
- (int) RgForFiber:(int)aFiber;
- (void) setRgForFiber:(int)aFiber to:(int)aAdcRg;
- (int) RtForFiber:(int)aFiber;
- (void) setRtForFiber:(int)aFiber to:(int)aAdcRt;
- (void) writeRgRtForBBAccessForFiber:(int)aFiber;//HW access Rt
- (int) D2ForFiber:(int)aFiber;
- (void) setD2ForFiber:(int)aFiber to:(int)aAdcRt;
- (void) writeD2ForBBAccessForFiber:(int)aFiber;//HW access D2
- (int) D3ForFiber:(int)aFiber;
- (void) setD3ForFiber:(int)aFiber to:(int)aAdcRt;
- (void) writeD3ForBBAccessForFiber:(int)aFiber;//HW access D3
- (int) adcValueForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex;
- (void) setAdcValueForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aAdcValueForBBAccess;
- (void) writeAdcValueForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex;//HW access 
- (int) adcMultForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex; //TODO: change name to 'gains' (instead of Mult)
- (void) setAdcMultForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aAdcMultForBBAccess;
- (int) adcFreqkHzForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex;
- (void) setAdcFreqkHzForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aAdcFreqkHzForBBAccess;
- (void) writeAdcFilterForBBAccessForFiber:(int)aFiber atIndex:(int)aIndex;//HW access for Freq+Gain (Mult)
- (int) useBroadcastIdforBBAccess;
- (void) setUseBroadcastIdforBBAccess:(int)aUseBroadcastIdforBBAccess;
- (int) idBBforBBAccessForFiber:(int)aFiber;
- (void) setIdBBforBBAccessForFiber:(int)aFiber to:(int)aIdBBforBBAccess;
- (int) fiberSelectForBBAccess;
- (void) setFiberSelectForBBAccess:(int)aFiberSelectForBBAccess;
- (int) relaisStatesBBForFiber:(int)aFiber;
- (void) setRelaisStatesBBForFiber:(int)aFiber to:(int)aRelaisStatesBB;
- (void) writeRelaisStatesForBBAccessForFiber:(int)aFiber;//HW access Relais
- (int) refForBBAccessForFiber:(int)aFiber;
- (void) setRefForBBAccessForFiber:(int)aFiber to:(int)aValue;
- (int) adcOnOffForBBAccessForFiber:(int)aFiber;
- (void) setAdcOnOffForBBAccessForFiber:(int)aFiber to:(int)aValue;
- (int) relais1ForBBAccessForFiber:(int)aFiber;
- (void) setRelais1ForBBAccessForFiber:(int)aFiber to:(int)aValue;
- (int) relais2ForBBAccessForFiber:(int)aFiber;
- (void) setRelais2ForBBAccessForFiber:(int)aFiber to:(int)aValue;
- (int) mezForBBAccessForFiber:(int)aFiber;
- (void) setMezForBBAccessForFiber:(int)aFiber to:(int)aValue;

- (int) polarDacForFiber:(int)aFiber atIndex:(int)aIndex;  // DAC = polar_dac (cew_control name)
- (void) setPolarDacForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aDacValue;
- (void) writePolarDacForFiber:(int)aFiber atIndex:(int)aIndex;//HW access

- (int) triDacForFiber:(int)aFiber atIndex:(int)aIndex;
- (void) setTriDacForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aDacValue;
- (void) writeTriDacForFiber:(int)aFiber atIndex:(int)aIndex;//HW access

- (int) rectDacForFiber:(int)aFiber atIndex:(int)aIndex;
- (void) setRectDacForFiber:(int)aFiber atIndex:(int)aIndex to:(int)aDacValue;
- (void) writeRectDacForFiber:(int)aFiber atIndex:(int)aIndex;//HW access

- (double) temperatureBBforBBAccessForFiber:(int)aFiber;

//BB status bit buffer
- (uint32_t) statusBB32forFiber:(int)aFiber atIndex:(int)aIndex;
- (void) setStatusBB32forFiber:(int)aFiber atIndex:(int)aIndex to:(uint32_t)aValue;
- (uint16_t) statusBB16forFiber:(int)aFiber atIndex:(int)aIndex;
- (void) setStatusBB16forFiber:(int)aFiber atIndex:(int)aIndex to:(uint16_t)aValue;
- (uint16_t) statusBB16forFiber:(int)aFiber atOffset:(int) off index:(int)aIndex mask:(uint16_t) mask shift:(int) shift;
- (void) setStatusBB16forFiber:(int)aFiber atOffset:(int) off index:(int)aIndex mask:(uint16_t) mask shift:(int) shift to:(uint16_t)aValue;
- (void) dumpStatusBB16forFiber:(int)aFiber;

- (int) fiberSelectForBBStatusBits;//
- (void) setFiberSelectForBBStatusBits:(int)aFiberSelectForBBStatusBits;
- (uint32_t) fiberOutMask;
- (void) setFiberOutMask:(uint32_t)aFiberOutMask;
- (int) swTriggerIsRepeating;
- (void) setSwTriggerIsRepeating:(int)aSwTriggerIsRepeating;
- (int) repeatSWTriggerMode;
- (void) setRepeatSWTriggerMode:(int)aRepeatSWTriggerMode;
- (double) repeatSWTriggerDelay;
- (void) setRepeatSWTriggerDelay:(double)aRepeatSWTriggerDelay;
- (uint32_t) controlRegister;
- (void) setControlRegister:(uint32_t)aControlRegister;
- (int) statusLatency;//obsolete 2014 -tb-
- (void) setStatusLatency:(int)aValue;//obsolete 2014 -tb-
- (int) vetoFlag;
- (void) setVetoFlag:(int)aValue;
- (uint32_t) selectFiberTrig;//obsolete 2014 -tb-
- (void) setSelectFiberTrig:(int)aSelectFiberTrig;//obsolete 2014 -tb-
- (int) BBv1Mask;
- (BOOL) BBv1MaskForChan:(int)i;
- (void) setBBv1Mask:(int)aBBv1Mask;
- (int) fiberEnableMask;
- (int) fiberEnableMaskForChan:(int)i;
- (void) setFiberEnableMask:(int)aFiberEnableMask;
- (int) fltModeFlags;
- (void) setFltModeFlags:(int)aFltModeFlags;
- (int) tpix;//obsolete 2014 -tb-
- (void) setTpix:(int)aTpix;//obsolete 2014 -tb-
- (int) statusBitPos;//new 2014 -tb-
- (void) setStatusBitPos:(int)aValue;//new 2014 -tb-
- (int) ficOnFiberMask;
- (int) ficOnFiberMaskForChan:(int)i;
- (void) setFicOnFiberMask:(int)aMask;


- (int) totalTriggerNRegister;
- (void) setTotalTriggerNRegister:(int)aTotalTriggerNRegister;
- (uint32_t) statusRegister;
- (void) setStatusRegister:(uint32_t)aStatusRegister;
- (int) fastWrite;
- (void) setFastWrite:(int)aFastWrite;
- (uint64_t) fiberDelays;
- (void) setFiberDelays:(uint64_t)aFiberDelays;
- (uint64_t) streamMask;
- (uint32_t) streamMask1;
- (uint32_t) streamMask2;
- (int) streamMaskForFiber:(int)aFiber chan:(int)aChan;
- (void) setStreamMask:(uint64_t)aStreamMask;
//- (void) setStreamMaskForFiber:(int)aFiber chan:(int)aChan;

- (uint64_t) ionTriggerMask;
- (uint32_t) ionTriggerMask1;
- (uint32_t) ionTriggerMask2;
- (int) ionTriggerMaskForFiber:(int)aFiber chan:(int)aChan;
- (void) setIonTriggerMask:(uint64_t)aIonTriggerMask;

- (uint64_t) heatTriggerMask;
- (uint32_t) heatTriggerMask1;
- (uint32_t) heatTriggerMask2;
- (int) heatTriggerMaskForFiber:(int)aFiber chan:(int)aChan;
- (void) setHeatTriggerMask:(uint64_t)aHeatTriggerMask;


- (int) targetRate;
- (void) setTargetRate:(int)aTargetRate;
- (int) runMode;
- (void) setRunMode:(int)aRunMode;
- (void) setToDefaults;
- (BOOL) storeDataInRam;
- (void) setStoreDataInRam:(BOOL)aStoreDataInRam;
- (int) filterLength;
- (void) setFilterLength:(int)aFilterLength;
- (int) gapLength;//TODO: obsolete - remove it -tb- 2013-06
- (void) setGapLength:(int)aGapLength;//TODO: obsolete - remove it -tb- 2013-06
- (uint32_t) postTriggerTime;
- (void) setPostTriggerTime:(uint32_t)aPostTriggerTime;
- (int) fifoBehaviour;
- (void) setFifoBehaviour:(int)aFifoBehaviour;
- (int) analogOffset;
- (void) setAnalogOffset:(int)aAnalogOffset;
- (BOOL) ledOff;
- (void) setLedOff:(BOOL)aledOff;
- (uint32_t) interruptMask;
- (void) setInterruptMask:(uint32_t)aInterruptMask;
- (unsigned short) hitRateLength;
- (void) setHitRateLength:(unsigned short)aHitRateLength;
- (BOOL) noiseFloorRunning;
- (int) noiseFloorOffset;
- (void) setNoiseFloorOffset:(int)aNoiseFloorOffset;
- (void) findNoiseFloors;
- (NSString*) noiseFloorStateString;


- (uint32_t) dataId;
- (void) setDataId: (uint32_t)aDataId;
- (uint32_t) waveFormId;
- (void) setWaveFormId: (uint32_t) aWaveFormId;
- (uint32_t) hitRateId;
- (void) setHitRateId: (uint32_t)aHitRateId;
- (uint32_t) histogramId;
- (void) setHistogramId: (uint32_t)aHistogramId;

- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherCard;

- (NSMutableArray*) thresholds;
- (void) setThresholds:(NSMutableArray*)aThresholds;
- (NSMutableArray*) triggerParameter;
- (void) setTriggerParameter:(NSMutableArray*)aTriggerParameter;

- (uint32_t) hitRateEnabledMask;
- (void) setHitRateEnabledMask:(uint32_t)aMask;
- (void) setHitRateEnabled:(unsigned short) aChan withValue:(BOOL) aState;
- (BOOL) hitRateEnabled:(unsigned short) aChan;

- (NSMutableArray*) gains;
- (void) setGains:(NSMutableArray*)aGains;

- (void) readTriggerParameters;
- (void) writeTriggerParametersVerbose;
- (void) writeTriggerParameters;
- (void) writeTriggerParametersDisableAll;
- (void) dumpTriggerParameters;
- (void) setTriggerPar:(unsigned short)chan  withValue:(uint32_t) val;
- (uint32_t) triggerPar:(unsigned short)chan;

- (uint32_t)threshold:(unsigned short) aChan;
- (unsigned short)gain:(unsigned short) aChan;
- (void) setThreshold:(unsigned short) aChan withValue:(uint32_t) aThreshold;
- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain;
- (BOOL) triggerEnabled:(unsigned short) aChan;
- (void) setTriggerEnabled:(unsigned short) aChan withValue:(BOOL) aState;
- (BOOL) negPolarity:(unsigned short) aChan;
- (void) setNegPolarity:(unsigned short) aChan withValue:(BOOL) aState;
- (BOOL) posPolarity:(unsigned short) aChan;
- (void) setPosPolarity:(unsigned short) aChan withValue:(BOOL) aState;
- (int) gapLength:(unsigned short) aChan;
- (void) setGapLength:(unsigned short) aChan withValue:(int) aLength;
- (int) downSampling:(unsigned short) aChan;
- (void) setDownSampling:(unsigned short) aChan withValue:(int) aValue;
- (int) shapingLength:(unsigned short) aChan;
- (void) setShapingLength:(unsigned short) aChan withValue:(int) aLength;
- (int) windowPosStart:(unsigned short) aChan;
- (void) setWindowPosStart:(unsigned short) aChan withValue:(int) aLength;
- (int) windowPosEnd:(unsigned short) aChan;
- (void) setWindowPosEnd:(unsigned short) aChan withValue:(int) aLength;

- (void) enableAllHitRates:(BOOL)aState;
- (void) enableAllTriggers:(BOOL)aState;
- (float) hitRate:(unsigned short)aChan;
- (float) rate:(int)aChan;

- (BOOL) hitRateOverFlow:(unsigned short)aChan;
- (BOOL) hitRateRegulationIsOn:(unsigned short)aChan;
- (float) hitRateTotal;

- (ORTimeRate*) totalRate;
- (void) setTotalRate:(ORTimeRate*)newTimeRate;

- (NSString*) getRegisterName: (short) anIndex;
- (uint32_t) getAddressOffset: (short) anIndex;
- (short) getAccessType: (short) anIndex;

- (unsigned short) selectedRegIndex;
- (void) setSelectedRegIndex:(unsigned short) anIndex;
- (uint32_t) writeValue;
- (void) setWriteValue:(uint32_t) aValue;
- (unsigned short) selectedChannelValue;
- (void) setSelectedChannelValue:(unsigned short) aValue;
- (int) restrictIntValue:(int)aValue min:(int)aMinValue max:(int)aMaxValue;
- (unsigned int) restrictUnsignedIntValue:(unsigned int)aValue min:(unsigned int)aMinValue max:(unsigned int)aMaxValue;
- (float) restrictFloatValue:(int)aValue min:(float)aMinValue max:(float)aMaxValue;


#pragma mark ‚Ä¢‚Ä¢‚Ä¢HW Access
//all can raise exceptions
- (uint32_t) regAddress:(uint32_t)aReg channel:(int)aChannel index:(int)index;
- (uint32_t) regAddress:(uint32_t)aReg channel:(int)aChannel;
- (uint32_t) regAddress:(uint32_t)aReg;
- (uint32_t) adcMemoryChannel:(int)aChannel page:(int)aPage;
- (uint32_t) readReg:(uint32_t)aReg;
- (uint32_t) readReg:(uint32_t)aReg channel:(int)aChannel;
- (uint32_t) readReg:(uint32_t)aReg channel:(int)aChannel  index:(int)aIndex;
- (void) writeReg:(uint32_t)aReg value:(uint32_t)aValue;
- (void) writeReg:(uint32_t)aReg channel:(int)aChannel value:(uint32_t)aValue;
- (void) readBlock:(uint32_t)aReg dataBuffer:(uint32_t*)aDataBuffer length:(uint32_t)length;

- (void) executeCommandList:(ORCommandList*)aList;
- (id) readRegCmd:(uint32_t) aRegister channel:(short) aChannel;
- (id) writeRegCmd:(uint32_t) aRegister channel:(short) aChannel value:(uint32_t)aValue;
- (id) readRegCmd:(uint32_t) aRegister;
- (id) writeRegCmd:(uint32_t) aRegister value:(uint32_t)aValue;

- (uint32_t) readVersion;

- (uint32_t) readFiberOutMask;
- (void) writeFiberOutMask;

- (int)		readMode;

- (void) loadThresholdsAndGains;
- (void) initBoard;
- (void) initTrigger;
- (void) readAll;
- (void) writeInterruptMask;
- (void) pollBBStatus;
- (void) readHitRates;
- (void) writeTestPattern:(uint32_t*)mask length:(int)len;
- (void) rewindTestPattern;
- (void) writeNextPattern:(uint32_t)aValue;
- (uint32_t) readStatus;
- (uint32_t) readControl;
- (void) writeRunControl;
- (uint32_t) readTotalTriggerNRegister;
- (void) writeControl;
- (void) writeStreamMask;
- (void) readStreamMask;
- (void) writeIonTriggerMask;
- (void) readIonTriggerMask;
- (void) writeHeatTriggerMask;
- (void) readHeatTriggerMask;
- (void) writePostTriggerTimeAndIonToHeatDelay;
- (void) readPostTriggerTimeAndIonToHeatDelay;
- (void) writeTriggerPar:(int)i value:(uint32_t)aValue;
- (uint32_t) readTriggerPar:(int)i;

- (void) writeFiberDelays;
- (void) readFiberDelays;
- (void) writeCommandResync;
- (void) writeCommandTrigEvCounterReset;
- (void) writeCommandSoftwareTrigger;
- (void) readTriggerData;

- (void) devTabButtonAction;

- (void) killChargeBBJobButtonAction;
- (void) chargeBBWithFile:(NSString*) aFile;	

- (void) killChargeFICJobButtonAction;
- (int) chargeFICWithDataFromFile:(NSString*)aFilename;

- (void) sendWCommand;
- (void) sendWCommandIdBB:(int) idBB cmd:(int) cmd arg1:(int) arg1  arg2:(int) arg2;
- (void) readBBStatusForBBAccess;//BB access tab
- (void) readBBStatusBits;//low level tab
- (void) readAllBBStatusBits;

- (void) printStatusReg;
- (void) printVersions;
- (void) printValueTable;
- (void) printEventFIFOs;

/** Print result of hardware statistics for all channels */
- (void) printStatistics; // ak, 7.10.07
- (void) writeThresholds;
- (void) readThresholds;
- (void) writeThreshold:(int)i value:(unsigned int)aValue;
- (uint32_t) readThreshold:(int)i;
- (void) writeTriggerControl;
- (BOOL) partOfEvent:(short)chan;
- (uint32_t) eventMask;
- (void) eventMask:(uint32_t)aMask;
- (NSString*) boardTypeName:(int)aType;
- (NSString*) fifoStatusString:(int)aType;

/** Enable the statistic evaluation of sum and sum square of the 
 * ADC signals in all channels.  */
- (void) enableStatistics; // ak, 7.10.07

/** Get statistics of a single channel */
- (void) getStatistics:(int)aChannel mean:(double *)aMean  var:(double *)aVar; // ak, 7.10.07

- (uint32_t) readMemoryChan:(int)chan page:(int)aPage;
- (void) readMemoryChan:(int)aChan page:(int)aPage pageBuffer:(unsigned short*)aPageBuffer;
- (void) clear:(int)aChan page:(int)aPage value:(unsigned short)aValue;

- (uint32_t) eventCount:(int)aChannel;
- (void)		  clearEventCounts;
- (BOOL) bumpRateFromDecodeStage:(short)channel;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (NSDictionary*) dataRecordDescription;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Data Taker
- (void) fireRepeatedSoftwareTriggerInRun;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;



@end

@interface OREdelweissFLTModel (tests)
- (void) runTests;
- (BOOL) testsRunning;
- (void) setTestsRunning:(BOOL)aTestsRunning;
- (NSMutableArray*) testEnabledArray;
- (void) setTestEnabledArray:(NSMutableArray*)aTestsEnabled;
- (NSMutableArray*) testStatusArray;
- (void) setTestStatusArray:(NSMutableArray*)aTestStatus;
- (NSString*) testStatus:(int)index;
- (BOOL) testEnabled:(int)index;

- (void) ramTest;
- (void) modeTest;
- (void) thresholdGainTest;
- (void) speedTest;
- (void) eventTest;
- (int) compareData:(unsigned short*) data
			pattern:(unsigned short*) pattern
			  shift:(int) shift
				  n:(int) n;
@end

extern NSString* OREdelweissFLTModelSaveIonChanFilterOutputRecordsChanged;
extern NSString* OREdelweissFLTModelRepeatSWTriggerDelayChanged;
extern NSString* OREdelweissFLTModelHitrateLimitIonChanged;
extern NSString* OREdelweissFLTModelHitrateLimitHeatChanged;
extern NSString* OREdelweissFLTModelChargeFICFileChanged;
extern NSString* OREdelweissFLTModelProgressOfChargeFICChanged;
extern NSString* OREdelweissFLTModelFicCardTriggerCmdChanged;
extern NSString* OREdelweissFLTModelFicCardADC23CtrlRegChanged;
extern NSString* OREdelweissFLTModelFicCardADC01CtrlRegChanged;
extern NSString* OREdelweissFLTModelFicCardCtrlReg2Changed;
extern NSString* OREdelweissFLTModelFicCardCtrlReg1Changed;
extern NSString* OREdelweissFLTModelPollBBStatusIntervallChanged;
extern NSString* OREdelweissFLTModelProgressOfChargeBBChanged;
extern NSString* OREdelweissFLTModelChargeBBFileForFiberChanged;
extern NSString* OREdelweissFLTModelBB0x0ACmdMaskChanged;
extern NSString* OREdelweissFLTModelChargeBBFileChanged;
extern NSString* OREdelweissFLTModelIonToHeatDelayChanged;
extern NSString* OREdelweissFLTModelHeatTriggerMaskChanged;
extern NSString* OREdelweissFLTModelIonTriggerMaskChanged;
extern NSString* OREdelweissFLTModelTriggerParameterChanged;
extern NSString* OREdelweissFLTModelTriggerEnabledMaskChanged;
extern NSString* OREdelweissFLTModelLowLevelRegInHexChanged;
extern NSString* OREdelweissFLTModelWriteToBBModeChanged;
extern NSString* OREdelweissFLTModelWCmdArg2Changed;
extern NSString* OREdelweissFLTModelWCmdArg1Changed;
extern NSString* OREdelweissFLTModelWCmdCodeChanged;
extern NSString* OREdelweissFLTModelAdcRtChanged;
extern NSString* OREdelweissFLTModelD2Changed;
extern NSString* OREdelweissFLTModelD3Changed;
extern NSString* OREdelweissFLTModelDacbChanged;
extern NSString* OREdelweissFLTModelSignbChanged;
extern NSString* OREdelweissFLTModelDacaChanged;
extern NSString* OREdelweissFLTModelSignaChanged;
extern NSString* OREdelweissFLTModelStatusBitsBBDataChanged;
extern NSString* OREdelweissFLTModelAdcRtForBBAccessChanged;
extern NSString* OREdelweissFLTModelAdcRgForBBAccessChanged;
extern NSString* OREdelweissFLTModelAdcValueForBBAccessChanged;
extern NSString* OREdelweissFLTModelPolarDacChanged;
extern NSString* OREdelweissFLTModelTriDacChanged;
extern NSString* OREdelweissFLTModelRectDacChanged;
extern NSString* OREdelweissFLTModelAdcMultForBBAccessChanged;
extern NSString* OREdelweissFLTModelAdcFreqkHzForBBAccessChanged;
extern NSString* OREdelweissFLTFiber;
extern NSString* OREdelweissFLTIndex;
extern NSString* OREdelweissFLTModelUseBroadcastIdforBBAccessChanged;
extern NSString* OREdelweissFLTModelIdBBforBBAccessChanged;
extern NSString* OREdelweissFLTModelFiberSelectForBBAccessChanged;
extern NSString* OREdelweissFLTModelRelaisStatesBBChanged;
extern NSString* OREdelweissFLTModelFiberSelectForBBStatusBitsChanged;
extern NSString* OREdelweissFLTModelFiberOutMaskChanged;
extern NSString* OREdelweissFLTModelTpixChanged;
extern NSString* OREdelweissFLTModelSwTriggerIsRepeatingChanged;
extern NSString* OREdelweissFLTModelRepeatSWTriggerModeChanged;
extern NSString* OREdelweissFLTModelControlRegisterChanged;
extern NSString* OREdelweissFLTModelTotalTriggerNRegisterChanged;
extern NSString* OREdelweissFLTModelStatusRegisterChanged;
extern NSString* OREdelweissFLTModelFastWriteChanged;
extern NSString* OREdelweissFLTModelFiberDelaysChanged;
extern NSString* OREdelweissFLTModelStreamMaskChanged;
extern NSString* OREdelweissFLTModelSelectFiberTrigChanged;
extern NSString* OREdelweissFLTModelBBv1MaskChanged;
extern NSString* OREdelweissFLTModelFiberEnableMaskChanged;
extern NSString* OREdelweissFLTModelFltModeFlagsChanged;
extern NSString* OREdelweissFLTModelTargetRateChanged;
extern NSString* OREdelweissFLTModelStoreDataInRamChanged;
extern NSString* OREdelweissFLTModelFilterLengthChanged;
extern NSString* OREdelweissFLTModelGapLengthChanged;
extern NSString* OREdelweissFLTModelPostTriggerTimeChanged;
extern NSString* OREdelweissFLTModelFifoBehaviourChanged;
extern NSString* OREdelweissFLTModelAnalogOffsetChanged;
extern NSString* OREdelweissFLTModelLedOffChanged;
extern NSString* OREdelweissFLTModelInterruptMaskChanged;
extern NSString* OREdelweissFLTModelTestsRunningChanged;
extern NSString* OREdelweissFLTModelTestEnabledArrayChanged;
extern NSString* OREdelweissFLTModelTestStatusArrayChanged;
extern NSString* OREdelweissFLTModelHitRateChanged;
extern NSString* OREdelweissFLTModelHitRateLengthChanged;
extern NSString* OREdelweissFLTModelHitRateEnabledMaskChanged;
extern NSString* OREdelweissFLTModelGainChanged;
extern NSString* OREdelweissFLTModelThresholdChanged;
extern NSString* OREdelweissFLTChan;
extern NSString* OREdelweissFLTModelGainsChanged;
extern NSString* OREdelweissFLTModelThresholdsChanged;
extern NSString* OREdelweissFLTModelModeChanged;
extern NSString* OREdelweissFLTSettingsLock;
extern NSString* OREdelweissFLTModelEventMaskChanged;
extern NSString* OREdelweissFLTNoiseFloorChanged;
extern NSString* OREdelweissFLTNoiseFloorOffsetChanged;

extern NSString* ORIpeSLTModelName;

extern NSString* OREdelweissFLTSelectedRegIndexChanged;
extern NSString* OREdelweissFLTWriteValueChanged;
extern NSString* OREdelweissFLTSelectedChannelValueChanged;
