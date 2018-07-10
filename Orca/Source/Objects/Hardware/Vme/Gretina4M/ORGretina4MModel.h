//-------------------------------------------------------------------------
//  ORGretina4MModel.h
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "SBC_Config.h"
#import "AutoTesting.h"
#import "ORAdcInfoProviding.h"
#import "SBC_Link.h"
#import "ORGretinaTriggerProtocol.h"


@class ORRateGroup;
@class ORConnector;
@class ORFileMoverOp;
@class ORRunningAverageGroup;


#define kNumGretina4MChannels		10
#define kNumGretina4MCardParams		6
#define kGretina4MHeaderLengthLongs	7

#define kGretina4MFIFOEmpty			0x100000
#define kGretina4MFIFOAlmostEmpty	0x400000
#define kGretina4MFIFOAlmostFull	0x800000
#define kGretina4MFIFOAllFull		0x1000000

#define kGretina4MPacketSeparator    0xAAAAAAAA

#define kGretina4MNumberWordsMask	0x7FF0000

#define kGretina4MFlashMaxWordCount	0xF
#define kGretina4MFlashBlockSize		( 128 * 1024 )
#define kGretina4MFlashBlocks		128
#define kGretina4MUsedFlashBlocks	32
#define kGretina4MFlashBufferBytes	32
#define kGretina4MTotalFlashBytes	( kGretina4MFlashBlocks * kGretina4MFlashBlockSize)
#define kFlashBusy                  0x80
#define kGretina4MFlashEnableWrite	0x10
#define kGretina4MFlashDisableWrite	0x0
#define kGretina4MFlashConfirmCmd	0xD0
#define kGretina4MFlashWriteCmd		0xE8
#define kGretina4MFlashBlockEraseCmd	0x20
#define kGretina4MFlashReadArrayCmd	0xFF
#define kGretina4MFlashStatusRegCmd	0x70
#define kGretina4MFlashClearSRCmd	0x50

#define kGretina4MResetMainFPGACmd	0x30
#define kGretina4MReloadMainFPGACmd	0x3
#define kGretina4MMainFPGAIsLoaded	0x41

#define kSPIData	    0x2
#define kSPIClock	    0x4
#define kSPIChipSelect	0x8
#define kSPIRead        0x10
#define kSDLockBit      (0x1<<17)
#define kSDLostLockBit  (0x1<<24)


#pragma mark •••Register Definitions
enum {
	kBoardID,					//[0] board ID
    kProgrammingDone,			//[1] Programming done
    kExternalWindow,			//[2] External Window
    kPileupWindow,				//[3] Pileup Window
    kNoiseWindow,               //[4] Noise Window
    kExtTrigSlidingLength,      //[5] Extrn trigger sliding length
    kCollectionTime,			//[6] Collection time
    kIntegrateTime,             //[7] Integration time
    kHardwareStatus,			//[8] Hardware Status
	kDataPackUserDefinedData,	//[9] Data Package User Defined Data
	kColTimeLowResolution,		//[10] Collection Time Low Resolution
	KINTTimeLowResolution,		//[11] Integration Time Low resolution
	kExtFIFOMonitor,			//[12] External FIFO monitor
    kControlStatus,				//[13] Control Status
    kLEDThreshold,				//[14] LED Threshold
    kWindowTiming,              //[15] Window timing
    kRisingEdgeWindow,          //[16] Rising Edge Window
    kTrapThreshold,				//[17] Trapezoidal Threshold
    kDAC,						//[18] DAC
	kSlaveFrontBusStatus,		//[19] Slave Front bus status
    kChanZeroTimeStampLSB,		//[20] Channel Zero time stamp LSB
    kChanZeroTimeStampMSB,		//[21] Channel Zero time stamp MSB
	kCentContactTimeStampLSB,	//[22] Central Contact Time Stamp LSB
	kCentContactTimeStampMSB,	//[23] Central Contact Time Stamp MSB
	kSlaveSyncCounter,			//[24] Slave Front Bus Logic Sync Counter
	kSlaveImpSyncCounter,		//[25] Slave Front Bus Logic Imperative Sync Counter
	kSlaveLatchStatusCounter,	//[26] Slave Front Bus Logic Latch Status Counter
	kSlaveHMemValCounter,		//[27] Slave Front Bus Logic Header Memory Validate Counter 
	kSlaveHMemSlowDataCounter,	//[28] Slave Front Bus Logic Header Memeory Read Slow Data Counter
	kSlaveFEReset,				//[29] Slave Front Bus Logic Front End Reset and Calibration inject Counter
    kSlaveFrontBusSendBox18_1,  //[30] Slave Front Bus Send Box 18 - 1
    kSlaveFrontBusRegister0_10, //[31] Slave Front bus register 0 - 10
    kMasterLogicStatus,			//[32] Master Logic Status
    kSlowDataCCLEDTimers,		//[33] SlowData CCLED timers
    kDeltaT155_DeltaT255,		//[34] DeltaT155_DeltaT255 (3)
    kSnapShot,					//[35] SnapShot 
    kXtalID,					//[36] XTAL ID 
    kHitPatternTimeOut,			//[37] Length of Time to get Hit Pattern 
    kFrontSideBusRegister,		//[38] Front Side Bus Register
	kTestDigitizerTxTTCL,		//[39] Test Digitizer Tx TTCL
	kTestDigitizerRxTTCL,		//[40] Test Digitizer Rx TTCL
	kSlaveFrontBusSendBox10_1,  //[41] Slave Front Bus Send Box 10 - 1
    kFrontBusRegisters0_10,		//[42] FrontBus Registers 0-10
	kLogicSyncCounter,			//[43] Master Logic Sync Counter
	kLogicImpSyncCounter,		//[44] Master Logic Imperative Sync Counter
	kLogicLatchStatusCounter,	//[45] Master Logic Latch Status Counter
	kLogicHMemValCounter,		//[46] Master Logic Header Memory Validate Counter 
	kLogicHMemSlowDataCounter,	//[47] Master Logic Header Memeory Read Slow Data Counter
	kLogicFEReset,				//[48] Master Logic Front End Reset and Calibration inject Counter
	kFBSyncCounter,				//[49] Master Front Bus Sync Counter
	kFBImpSyncCounter,			//[50] Master Front Bus Imperative Sync Counter
	kFBLatchStatusCounter,		//[51] Master Front Bus Latch Status Counter
	kFBHMemValCounter,			//[52] Master Front Bus Header Memory Validate Counter 
	kFBHMemSlowDataCounter,		//[53] Master Front Bus Header Memeory Read Slow Data Counter
	kFBFEReset,					//[54] Master Front Bus Front End Reset and Calibration inject Counter
	kSerdesError,				//[55] Serdes Data Package Error
	kCCLEDenable,				//[56] CC_LED Enable
	kDebugDataBufferAddress,	//[57] Debug data buffer address
	kDebugDataBufferData,		//[58] Debug data buffer data
	kLEDFlagWindow,				//[59] LED flag window
	kAuxIORead,					//[60] Aux io read
	kAuxIOWrite,				//[61] Aux io write
	kAuxIOConfig,				//[62] Aux io config
	kFBRead,					//[63] FB_Read
	kFBWrite,					//[64] FB_Write
	kFBConfig,					//[65] FB_Config
	kSDRead,					//[66] SD_Read
	kSDWrite,					//[67] SD_Write
	kSDConfig,					//[68] SD_Config; This has a number of important set/reset bits
	kADCConfig,					//[69] Adc config
	kSelfTriggerEnable,			//[70] self trigger enable
	kSelfTriggerPeriod,			//[71] self trigger period
	kSelfTriggerCount,			//[72] self trigger count
	kFIFOInterfaceSMReg,		//[73] FIFOInterfaceSMReg
	kTestSignalReg,				//[74] Test Signals Register
	kNumberOfGretina4MRegisters	//must be last
};

enum {
	kMainFPGAControl,			//[0] Main Digitizer FPGA configuration register
	kMainFPGAStatus,			//[1] Main Digitizer FPGA status register
	kVoltageAndTemperature,		//[2] Voltage and Temperature Status
	kVMEGPControl,				//[3] General Purpose VME Control Settings
	kVMETimeoutValue,			//[4] VME Timeout Value Register
	kVMEFPGAVersionStatus,		//[5] VME Version/Status
	kVMEFPGASandbox,			//[6] VME FPGA Sandbox Register Block
	kFlashAddress,				//[7] Flash Address
	kFlashDataWithAddrIncr,		//[8] Flash Data with Auto-increment address
	kFlashData,					//[9] Flash Data
	kFlashCommandRegister,		//[10] Flash Command Register
	kNumberOfFPGARegisters
};

enum Gretina4MFIFOStates {
	kEmpty,
	kAlmostEmpty,	
	kAlmostFull,
	kFull,
	kHalfFull
};

#define kG4MDataPacketSize 1024+2  //waveforms are fixed at 1024, ORCA header is 2

#define kPreAdjust  13
#define kPostAdjust -18
#define kFtAdjust    4
#define kHeaderSize  29

@interface ORGretina4MModel : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping,AutoTesting,ORAdcInfoProviding,ORGretinaTriggerProtocol>
{
  @private
	NSThread*		fpgaProgrammingThread;
	unsigned long   dataId;
	unsigned long   dataBuffer[kG4MDataPacketSize];

    BOOL            forceFullInitCard;
    BOOL			enabled[kNumGretina4MChannels];
    BOOL			forceFullInit[kNumGretina4MChannels];
    BOOL			trapEnabled[kNumGretina4MChannels];
    BOOL			debug[kNumGretina4MChannels];
    BOOL			pileUp[kNumGretina4MChannels];
    BOOL            poleZeroEnabled[kNumGretina4MChannels];
    BOOL            baselineRestoreEnabled[kNumGretina4MChannels];
    BOOL			pzTraceEnabled[kNumGretina4MChannels];
    BOOL			presumEnabled[kNumGretina4MChannels];
    short			triggerMode[kNumGretina4MChannels];
    BOOL			easySelected[kNumGretina4MChannels];
    
    int				ledThreshold[kNumGretina4MChannels];
    unsigned long	trapThreshold[kNumGretina4MChannels];
    short           poleZeroMult[kNumGretina4MChannels];
    short			downSample;
    short			mrpsrt[kNumGretina4MChannels];
    short			ftCnt[kNumGretina4MChannels];
    short			mrpsdv[kNumGretina4MChannels];
    short			chpsrt[kNumGretina4MChannels];
    short			chpsdv[kNumGretina4MChannels];
    short			prerecnt[kNumGretina4MChannels];
    short			postrecnt[kNumGretina4MChannels];
    short			tpol[kNumGretina4MChannels];
    unsigned short  baselineRestoredDelay;

    short           clockSource;
    short           clockPhase;
    short           externalWindow;
    short           noiseWindow;
    short           pileUpWindow;
    short           extTrigLength;
    short           collectionTime;
    short           integrateTime;
    short			histEMultiplier;

    int             fifoState;
	int				fifoEmptyCount;
    int             fifoResetCount;
	ORAlarm*        fifoFullAlarm;

	//cache to speed takedata
	unsigned long location;
	id theController;
	unsigned long fifoAddress;
	unsigned long fifoStateAddress;

	BOOL oldEnabled[kNumGretina4MChannels];
	int oldThreshold[kNumGretina4MChannels];
	int newThreshold[kNumGretina4MChannels];
	BOOL noiseFloorRunning;
	int noiseFloorState;
	int noiseFloorWorkingChannel;
	int noiseFloorLow;
	int noiseFloorHigh;
	int noiseFloorTestValue;
	int noiseFloorOffset;
    float noiseFloorIntegrationTime;
	
    NSString* mainFPGADownLoadState;
    NSString* fpgaFilePath;
	BOOL stopDownLoadingMainFPGA;
	BOOL downLoadMainFPGAInProgress;
    int fpgaDownProgress;
	NSLock* progressLock;
	
    unsigned long registerWriteValue;
    int registerIndex;
    unsigned long spiWriteValue;
	
	ORConnector*    spiConnector; //we won't draw this connector so we have to keep a reference to it
	ORConnector*    linkConnector; //we won't draw this connector so we have to keep a reference to it
    ORFileMoverOp*  fpgaFileMover;
	ORRateGroup*	waveFormRateGroup;
    ORRunningAverageGroup* rateRunningAverages; //initialized in initWithCoder, start by runstart
    unsigned long 	waveFormCount[kNumGretina4MChannels];

	BOOL			isRunning;
    NSString*       firmwareStatusString;
    BOOL            locked;
    BOOL            doHwCheck;
    
    //------------------internal use only
    NSOperationQueue*	fileQueue;
    int                 initializationState;
    unsigned long       snapShot[kNumberOfGretina4MRegisters];
    unsigned long       fpgaSnapShot[kNumberOfFPGARegisters];
    unsigned long       serialNumber;
    unsigned long       runNumberLocal;
    unsigned long       subRunNumberLocal;

}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian;
- (void) openPreampDialog;

#pragma mark ***Accessors
- (int) nMaxChannels;
- (BOOL) forceFullInitCard;
- (void) setForceFullInitCard:(BOOL)aForceFullInitCard;
- (short) initState;
- (void) setInitState:(short)aState;
- (short) histEMultiplier;
- (void) setHistEMultiplier:(short)aHistEMultiplier;
- (unsigned short) baselineRestoredDelay;
- (void) setBaselineRestoredDelay:(long)aBaselineRestoredDelay;
- (NSString*) firmwareStatusString;
- (void) setFirmwareStatusString:(NSString*)aFirmwareStatusString;
- (short) integrateTime;
- (void) setIntegrateTime:(short)aIntegrateTime;
- (short) collectionTime;
- (void) setCollectionTime:(short)aCollectionTime;
- (short) extTrigLength;
- (void) setExtTrigLength:(short)aExtTrigLength;
- (short) pileUpWindow;
- (void) setPileUpWindow:(short)aPileUpWindow;
- (short) externalWindow;
- (void) setExternalWindow:(short)aExternalWindow;
- (short) clockSource;
- (short) clockPhase;
- (void) setClockSource:(short)aClockMux;
- (void) setClockPhase:(short)aClockPhase;
- (ORConnector*) spiConnector;
- (void) setSpiConnector:(ORConnector*)aConnector;
- (ORConnector*) linkConnector;
- (void) setLinkConnector:(ORConnector*)aConnector;
- (short) downSample;
- (void) setDownSample:(short)aDownSample;
- (short) registerIndex;
- (void) setRegisterIndex:(int)aRegisterIndex;
- (unsigned long) registerWriteValue;
- (void) setRegisterWriteValue:(unsigned long)aWriteValue;
- (unsigned long) spiWriteValue;
- (void) setSPIWriteValue:(unsigned long)aWriteValue;
- (BOOL) downLoadMainFPGAInProgress;
- (void) setDownLoadMainFPGAInProgress:(BOOL)aState;
- (short) fpgaDownProgress;
- (NSString*) mainFPGADownLoadState;
- (void) setMainFPGADownLoadState:(NSString*)aMainFPGADownLoadState;
- (NSString*) fpgaFilePath;
- (void) setFpgaFilePath:(NSString*)aFpgaFilePath;
- (float) noiseFloorIntegrationTime;
- (void) setNoiseFloorIntegrationTime:(float)aNoiseFloorIntegrationTime;
- (short) fifoState;
- (void) setFifoState:(short)aFifoState;
- (short) noiseFloorOffset;
- (void) setNoiseFloorOffset:(short)aNoiseFloorOffset;
- (void) initParams;
- (int) baseLineLength:(int)chan;

// Register access
- (NSString*) registerNameAt:(unsigned int)index;
- (unsigned short) registerOffsetAt:(unsigned int)index;
- (NSString*) fpgaRegisterNameAt:(unsigned int)index;
- (unsigned short) fpgaRegisterOffsetAt:(unsigned int)index;
- (unsigned long) readRegister:(unsigned int)index;
- (void) writeRegister:(unsigned int)index withValue:(unsigned long)value;
- (BOOL) canReadRegister:(unsigned int)index;
- (BOOL) canWriteRegister:(unsigned int)index;
- (BOOL) displayRegisterOnMainPage:(unsigned int)index;
- (unsigned long) readFPGARegister:(unsigned int)index;
- (void) writeFPGARegister:(unsigned int)index withValue:(unsigned long)value;
- (BOOL) canReadFPGARegister:(unsigned int)index;
- (BOOL) canWriteFPGARegister:(unsigned int)index;
- (BOOL) displayFPGARegisterOnMainPage:(unsigned int)index;
- (void) writeToAddress:(unsigned long)anAddress aValue:(unsigned long)aValue;
- (unsigned long) readFromAddress:(unsigned long)anAddress;
- (void) printThresholds;
- (void) fakeASpike:(int) channel started:(BOOL)start;

- (void) registerNotificationObservers;
- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(short)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;
- (void)            rateSpikeChanged:(NSNotification*)aNote;
- (ORRunningAverageGroup*) rateRunningAverages;
- (void)			setRateRunningAverages:(ORRunningAverageGroup*)newRunningAverageGroup;
- (void) setExternalWindow:(short)aValue;
- (short) externalWindow;
- (void) setPileUpWindow:(short)aValue;
- (short) pileUpWindow;
- (void) setExtTrigLength:(short)aValue;
- (short) extTrigLength;
- (void) setCollectionTime:(short)aValue;
- (short) collectionTime;
- (void) setIntegrateTime:(short)aValue;
- (short) integrateTime;
- (void) setNoiseWindow:(short)aNoiseWindow;
- (short) noiseWindow;

- (BOOL) doHwCheck;
- (void) setDoHwCheck:(BOOL)aFlag;
- (void) setForceFullInit:(short)chan withValue:(BOOL)aValue;
- (void) setTriggerMode:(short)chan withValue:(short)aValue;
- (void) setPileUp:(short)chan withValue:(short)aValue;		
- (void) setEnabled:(short)chan withValue:(BOOL)aValue;
- (void) setTrapEnabled:(short)chan withValue:(BOOL)aValue;
- (void) setPoleZeroEnabled:(short)chan withValue:(BOOL)aValue;
- (void) setBaselineRestoreEnabled:(short)chan withValue:(BOOL)aValue;
- (void) setPoleZeroMultiplier:(short)chan withValue:(short)aValue;
- (void) setPZTraceEnabled:(short)chan withValue:(BOOL)aValue;		
- (void) setDebug:(short)chan withValue:(BOOL)aValue;	
- (void) setLEDThreshold:(short)chan withValue:(int)aValue;
- (void) setThreshold:(short)chan withValue:(int)aValue;
- (void) setTrapThreshold:(short)chan withValue:(unsigned long)aValue;
- (void) setMrpsrt:(short)chan withValue:(short)aValue;
- (void) setFtCnt:(short)chan withValue:(short)aValue;
- (void) setMrpsdv:(short)chan withValue:(short)aValue;
- (void) setChpsrt:(short)chan withValue:(short)aValue;
- (void) setChpsdv:(short)chan withValue:(short)aValue;
- (void) setPrerecnt:(short)chan withValue:(short)aValue;
- (void) setPostrecnt:(short)chan withValue:(short)aValue;
- (void) setTpol:(short)chan withValue:(short)aValue;
- (void) setPresumEnabled:(short)chan withValue:(BOOL)aValue;
- (void) setEasySelected:(short)chan withValue:(BOOL)aValue;
- (void) writeClockPhase;
- (void) writeClockPhaseWithValue:(unsigned long)value;


- (BOOL) enabled:(short)chan;
- (BOOL) forceFullInit:(short)chan;
- (BOOL) trapEnabled:(short)chan;
- (BOOL) poleZeroEnabled:(short)chan;
- (BOOL) baselineRestoreEnabled:(short)chan;
- (short) poleZeroMult:(short)chan;
- (BOOL) pzTraceEnabled:(short)chan;
- (BOOL) debug:(short)chan;		
- (BOOL) pileUp:(short)chan;		
- (short) triggerMode:(short)chan;
- (int) ledThreshold:(short)chan;	
- (unsigned long) trapThreshold:(short)chan;
- (short) mrpsrt:(short)chan;
- (short) ftCnt:(short)chan;
- (short) mrpsdv:(short)chan;
- (short) chpsrt:(short)chan;
- (short) chpsdv:(short)chan;
- (short) prerecnt:(short)chan;
- (short) postrecnt:(short)chan;
- (short) tpol:(short)chan;
- (BOOL) presumEnabled:(short)chan;
- (BOOL) easySelected:(short)chan;

//conversion methods
- (float) poleZeroTauConverted:(short)chan;

- (void) setPoleZeroTauConverted:(short)chan withValue:(float)aValue;	

- (void) setNoiseWindowConverted:(float)aValue;
- (void) setExternalWindowConverted:(float)aValue;
- (void) setPileUpWindowConverted:(float)aValue;
- (void) setBLRDelayConverted:(float)aValue;
- (void) setExtTrigLengthConverted:(float)aValue;
- (void) setCollectionTimeConverted:(float)aValue;
- (void) setIntegrateTimeConverted:(float)aValue;

- (float) noiseWindowConverted;
- (float) externalWindowConverted;
- (float) pileUpWindowConverted;
- (float) BLRDelayConverted;
- (float) extTrigLengthConverted;
- (float) collectionTimeConverted;
- (float) integrateTimeConverted;

- (void) dumpAllRegisters;
- (void) snapShotRegisters;
- (void) compareToSnapShot;

#pragma mark •••Hardware Access
- (short) readBoardID;
- (BOOL) checkFirmwareVersion;
- (BOOL) checkFirmwareVersion:(BOOL)verbose;
- (void) readFPGAVersions;
- (void) resetBoard;
- (void) resetClock;
- (void) resetMainFPGA;
- (void) resetFIFO;
- (void) resetSingleFIFO;
- (void) doForcedInitBoard;
- (void) initBoard;
- (unsigned long) readControlReg:(short)channel;
- (void) writeControlReg:(short)channel enabled:(BOOL)enabled;
- (void) writeClockSource: (unsigned long) clocksource;
- (void) writeClockSource;
- (void) writeLEDThreshold:(short)channel;
- (void) writeTrapThreshold:(int)channel;
- (void) writeWindowTiming:(short)channel;
- (void) writeRisingEdgeWindow:(short)channel;
- (unsigned short) readFifoState;
- (void) setTestThreshold:(short)chan withValue:(int)aValue;
- (unsigned long) testThreshold:(short)chan;
- (unsigned long) maxTestThreshold:(short)chan;
- (void) findNoiseFloors;
- (void) stepNoiseFloor;
- (BOOL) noiseFloorRunning;
- (void) writeDownSample;
- (BOOL) fifoIsEmpty;
- (void) loadThresholds;

- (short) readClockSource;
- (short) readExternalWindow;
- (short) readPileUpWindow;
- (short) readExtTrigLength;
- (short) readCollectionTime;
- (short) readIntegrateTime;
- (short) readDownSample;

- (void) writeNoiseWindow;
- (void) writeExternalWindow;
- (void) writePileUpWindow;
- (void) writeExtTrigLength;
- (void) writeCollectionTime;
- (void) writeIntegrateTime;

- (void) tasksCompleted: (NSNotification*)aNote;
- (BOOL) queueIsRunning;

#pragma mark •••HW checks
- (void) checkBoard:(BOOL)verbose;
- (BOOL) checkClockPhase:(BOOL)verbose;
- (BOOL) checkExternalWindow:(BOOL)verbose;
- (BOOL) checkPileUpWindow:(BOOL)verbose;
- (BOOL) checkNoiseWindow:(BOOL)verbose;
- (BOOL) checkExtTrigLength:(BOOL)verbose;
- (BOOL) checkCollectionTime:(BOOL)verbose;
- (BOOL) checkIntegrateTime:(BOOL)verbose;
- (BOOL) checkDownSample:(BOOL)verbose;
- (BOOL) checkControlReg:(short)chan verbose:(BOOL)verbose;
- (BOOL) checkWindowTiming:(short)channel verbose:(BOOL)verbose;
- (BOOL) checkRisingEdgeWindow:(short)channel verbose:(BOOL)verbose;
- (BOOL) checkTrapThreshold:(short)channel verbose:(BOOL)verbose;
- (BOOL) checkLEDThreshold:(short)channel verbose:(BOOL)verbose;

#pragma mark •••FPGA download
- (void) startDownLoadingMainFPGA;
- (void) stopDownLoadingMainFPGA;

#pragma mark •••Data Taker
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (unsigned long) waveFormCount:(short)aChannel;
- (void)   startRates;
- (void) clearWaveFormCounts;
- (unsigned long) getCounter:(short)counterTag forGroup:(short)groupTag;

- (void) checkFifoAlarm;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (BOOL) bumpRateFromDecodeStage:(int)channel;

- (float) getRate:(short)channel;

#pragma mark •••HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) addCurrentState:(NSMutableDictionary*)dictionary shortArray:(short*)anArray forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary boolArray:(BOOL*)anArray forKey:(NSString*)aKey;

#pragma mark •••AutoTesting
- (NSArray*) autoTests;

#pragma mark •••SPI Interface
- (unsigned long) writeAuxIOSPI:(unsigned long)spiData;
#pragma mark •••AdcProviding Protocol
- (BOOL) onlineMaskBit:(int)bit;
- (BOOL) partOfEvent:(unsigned short)aChannel;
- (unsigned long) eventCount:(int)aChannel;
- (void) clearEventCounts;
- (unsigned long) thresholdForDisplay:(unsigned short) aChan;
- (unsigned short) gainForDisplay:(unsigned short) aChan;

- (BOOL) isLocked;
- (BOOL) locked;
- (void) setLocked:(BOOL)aState;

#pragma mark •••Internal Use only
- (void) stepSerDesInit;
- (NSString*) serDesStateName;

@end

@interface NSObject (Gretina4M)
- (NSString*) IPNumber;
- (NSString*) userName;
- (NSString*) passWord;
- (SBC_Link*) sbcLink;
@end

extern NSString* ORGretina4MModelBaselineRestoredDelayChanged;
extern NSString* ORGretina4MModelFirmwareStatusStringChanged;
extern NSString* ORGretina4MNoiseWindowChanged;
extern NSString* ORGretina4MClockSourceChanged;
extern NSString* ORGretina4MClockPhaseChanged;
extern NSString* ORGretina4MIntegrateTimeChanged;
extern NSString* ORGretina4MCollectionTimeChanged;
extern NSString* ORGretina4MExtTrigLengthChanged;
extern NSString* ORGretina4MPileUpWindowChanged;
extern NSString* ORGretina4MExternalWindowChanged;
extern NSString* ORGretina4MClockMuxChanged;
extern NSString* ORGretina4MDownSampleChanged;
extern NSString* ORGretina4MRegisterIndexChanged;
extern NSString* ORGretina4MRegisterWriteValueChanged;
extern NSString* ORGretina4MSPIWriteValueChanged;
extern NSString* ORGretina4MMainFPGADownLoadInProgressChanged;
extern NSString* ORGretina4MFpgaDownProgressChanged;
extern NSString* ORGretina4MMainFPGADownLoadStateChanged;
extern NSString* ORGretina4MFpgaFilePathChanged;
extern NSString* ORGretina4MNoiseFloorIntegrationTimeChanged;
extern NSString* ORGretina4MNoiseFloorOffsetChanged;

extern NSString* ORGretina4MForceFullInitCardChanged;
extern NSString* ORGretina4MForceFullInitChanged;
extern NSString* ORGretina4MEnabledChanged;
extern NSString* ORGretina4MTrapEnabledChanged;
extern NSString* ORGretina4MDebugChanged;
extern NSString* ORGretina4MPileUpChanged;
extern NSString* ORGretina4MPoleZeroEnabledChanged;
extern NSString* ORGretina4MBaselineRestoreEnabledChanged;
extern NSString* ORGretina4MPoleZeroMultChanged;
extern NSString* ORGretina4MPZTraceEnabledChanged;
extern NSString* ORGretina4MTriggerModeChanged;
extern NSString* ORGretina4MLEDThresholdChanged;
extern NSString* ORGretina4ModelTrapThresholdChanged;

extern NSString* ORGretina4MSettingsLock;
extern NSString* ORGretina4MRegisterLock;
extern NSString* ORGretina4MRateGroupChangedNotification;
extern NSString* ORGretina4MNoiseFloorChanged;
extern NSString* ORGretina4MFIFOCheckChanged;
extern NSString* ORGretina4MCardInited;
extern NSString* ORGretina4MSetEnableStatusChanged;

extern NSString* ORGretina4MMrpsrtChanged;
extern NSString* ORGretina4MFtCntChanged;
extern NSString* ORGretina4MMrpsdvChanged;
extern NSString* ORGretina4MChpsrtChanged;
extern NSString* ORGretina4MChpsdvChanged;
extern NSString* ORGretina4MPrerecntChanged;
extern NSString* ORGretina4MPostrecntChanged;
extern NSString* ORGretina4MTpolChanged;
extern NSString* ORGretina4MPresumEnabledChanged;
extern NSString* ORGretina4MEasySelectedChanged;
extern NSString* ORGretina4MModelHistEMultiplierChanged;
extern NSString* ORGretina4MModelInitStateChanged;
extern NSString* ORGretina4MForceFullInitCardChanged;
extern NSString* ORGretina4MLockChanged;
extern NSString* ORGretina4MDoHwCheckChanged;
extern NSString* ORRunningAverageChangedNotification;

extern NSString* ORGretina4MModelRateSpiked;

