//-------------------------------------------------------------------------
//  ORGretina4Model.h
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
#import "SBC_Link.h"
#import "ORAdcInfoProviding.h"

@class ORRateGroup;
@class ORAlarm;
@class ORFileMoverOp;

#define kNumGretina4Channels		10 
#define kNumGretina4CardParams		6
#define kGretina4HeaderLengthLongs	7

#define kGretina4FIFOEmpty			0x100000
#define kGretina4FIFOAlmostEmpty	0x400000
#define kGretina4FIFOAlmostFull		0x800000
#define kGretina4FIFOAllFull		0x1000000

#define kGretina4PacketSeparator    0xAAAAAAAA

#define kGretina4NumberWordsMask	0x7FF0000

#define kGretina4FlashBlockSize		( 128 * 1024 )
#define kGretina4FlashBlocks		128
#define kGretina4UsedFlashBlocks	32
#define kGretina4FlashBufferBytes	32
#define kGretina4TotalFlashBytes	( kGretina4FlashBlocks * kGretina4FlashBlockSize)
#define kGretina4FlashMaxWordCount	0xF
#define kFlashBusy                  0x80
#define kGretina4FlashEnableWrite	0x10
#define kGretina4FlashDisableWrite	0x0
#define kGretina4FlashConfirmCmd	0xD0
#define kGretina4FlashWriteCmd		0xE8
#define kGretina4FlashBlockEraseCmd	0x20
#define kGretina4FlashReadArrayCmd	0xFF
#define kGretina4FlashStatusRegCmd	0x70
#define kGretina4FlashClearSRCmd	0x50

#define kGretina4ResetMainFPGACmd	0x30
#define kGretina4ReloadMainFPGACmd	0x3
#define kGretina4MainFPGAIsLoaded	0x41

#define kTrapezoidalTriggerMode	0x4

#define kSPIData	    0x2
#define kSPIClock	    0x4
#define kSPIChipSelect	0x8
#define kSPIRead        0x10

#define kSDLockBit      (0x1<<17)
#define kSDLostLockBit  (0x1<<24)

enum {
    kSerDesIdle,
    kSerDesSetup,
    kSetDigitizerClkSrc,
    kFlushFifo,
    kReleaseClkManager,
    kPowerUpRTPower,
    kSetMasterLogic,
    kSetSDSyncBit,
    kSerDesError,
};

#pragma mark ¥¥¥Register Definitions
enum {
	kBoardID,					//[0] board ID
    kProgrammingDone,			//[1] Programming done
    kExternalWindow,			//[2] External Window
    kPileupWindow,				//[3] Pileup Window
    kNoiseWindow,				//[4] Noise Window
    kExtTriggerSlidingLength,	//[5] Extrn trigger sliding length
    kCollectionTime,			//[6] Collection time
    kIntegrationTime,			//[7] Integration time
    kHardwareStatus,			//[8] Hardware Status
	kDataPackUserDefinedData,	//[9] Data Package User Defined Data
	kColTimeLowResolution,		//[10] Collection Time Low Resolution
	KINTTimeLowResolution,		//[11] Integration Time Low resolution
	kExtFIFOMonitor,			//[12] External FIFO monitor
    kControlStatus,				//[13] Control Status
    kLEDThreshold,				//[14] LED Threshold
    kCFDParameters,				//[15] CFD Parameters
    kRawDataSlidingLength,		//[16] Raw data sliding length
    kRawDataWindowLength,		//[17] Raw data window length
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
	//why we have slave front bus send box again?
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
	kTrapezoidalTriggerReg,     //[75] Trapezoidal Trigger settings
	kNumberOfGretina4Registers	//must be last
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

enum Gretina4FIFOStates {
	kEmpty,
	kAlmostEmpty,	
	kAlmostFull,
	kFull,
	kHalfFull
};

@interface ORGretina4Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping,AutoTesting,ORAdcInfoProviding>
{
  @private
	NSThread*		fpgaProgrammingThread;
	unsigned long   dataId;
	unsigned long*  dataBuffer;

	NSMutableArray* cardInfo;
    short			enabled[kNumGretina4Channels];
    short			debug[kNumGretina4Channels];
    short			pileUp[kNumGretina4Channels];
    short			polarity[kNumGretina4Channels];
    short			triggerMode[kNumGretina4Channels];
    unsigned long               ledThreshold[kNumGretina4Channels];
    short			cfdDelay[kNumGretina4Channels];
    short			cfdThreshold[kNumGretina4Channels];
    short			cfdFraction[kNumGretina4Channels];
    short                       dataDelay[kNumGretina4Channels];
    short                       dataLength[kNumGretina4Channels];
    short                       cfdEnabled[kNumGretina4Channels];
    short                       poleZeroEnabled[kNumGretina4Channels];
    short                       poleZeroMult[kNumGretina4Channels];
    short			pzTraceEnabled[kNumGretina4Channels];
    int				downSample;
    int				histEMultiplier;
    short           clockSource;

	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[kNumGretina4Channels];
	BOOL			isRunning;

    int fifoState;
	ORAlarm*        fifoFullAlarm;
	int				fifoEmptyCount;
    int             fifoLostEvents;

	//cache to speed takedata
	unsigned long location;
	id theController;
	unsigned long fifoAddress;
	unsigned long fifoStateAddress;

	BOOL oldEnabled[kNumGretina4Channels];
	unsigned long oldLEDThreshold[kNumGretina4Channels];
	unsigned long newLEDThreshold[kNumGretina4Channels];
	BOOL noiseFloorRunning;
	int noiseFloorState;
	int noiseFloorWorkingChannel;
	int noiseFloorLow;
	int noiseFloorHigh;
	int noiseFloorTestValue;
	int noiseFloorOffset;
    float noiseFloorIntegrationTime;
	
    NSString* mainFPGADownLoadState;
	BOOL isFlashWriteEnabled;
    NSString* fpgaFilePath;
	BOOL stopDownLoadingMainFPGA;
	BOOL downLoadMainFPGAInProgress;
    int fpgaDownProgress;
	NSLock* progressLock;
	
    unsigned long registerWriteValue;
    int registerIndex;
    unsigned long spiWriteValue;
	
	ORConnector*  spiConnector; //we won't draw this connector so we have to keep a reference to it
	ORConnector*  linkConnector; //we won't draw this connector so we have to keep a reference to it

    NSString*       firmwareStatusString;
    ORFileMoverOp*  fpgaFileMover;
    BOOL            locked;
    
    //------------------internal use only
    NSOperationQueue*	fileQueue;
    int                 initializationState;
    unsigned long       serialNumber;
}

- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian;

#pragma mark ***Accessors
- (short) initState;
- (void) setInitState:(short)aState;
- (ORConnector*) linkConnector;
- (void) setLinkConnector:(ORConnector*)aConnector;
- (ORConnector*) spiConnector;
- (void) setSpiConnector:(ORConnector*)aConnector;
- (int) downSample;
- (void) setDownSample:(int)aDownSample;
- (int) histEMultiplier;
- (void) setHistEMultiplier:(int)aHistEMultiplier;
- (int) registerIndex;
- (void) setRegisterIndex:(int)aRegisterIndex;
- (unsigned long) registerWriteValue;
- (void) setRegisterWriteValue:(unsigned long)aWriteValue;
- (unsigned long) spiWriteValue;
- (void) setSPIWriteValue:(unsigned long)aWriteValue;
- (BOOL) downLoadMainFPGAInProgress;
- (void) setDownLoadMainFPGAInProgress:(BOOL)aState;
- (int) fpgaDownProgress;
- (NSString*) mainFPGADownLoadState;
- (void) setMainFPGADownLoadState:(NSString*)aMainFPGADownLoadState;
- (NSString*) fpgaFilePath;
- (void) setFpgaFilePath:(NSString*)aFpgaFilePath;
- (float) noiseFloorIntegrationTime;
- (void) setNoiseFloorIntegrationTime:(float)aNoiseFloorIntegrationTime;
- (int) fifoState;
- (void) setFifoState:(int)aFifoState;
- (int) noiseFloorOffset;
- (void) setNoiseFloorOffset:(int)aNoiseFloorOffset;
- (void) initParams;
- (void) cardInfo:(int)index setObject:(id)aValue;
- (id)   cardInfo:(int)index;
- (id)   rawCardValue:(int)index value:(id)aValue;
- (id)   convertedCardValue:(int)index;

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

- (ORRateGroup*)    waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (id)              rateObject:(int)channel;
- (void)            setRateIntegrationTime:(double)newIntegrationTime;

#pragma mark ¥¥¥specific accessors
- (void) setExternalWindow:(int)aValue;
- (void) setPileUpWindow:(int)aValue;
- (void) setNoiseWindow:(int)aValue;
- (void) setExtTrigLength:(int)aValue;
- (void) setCollectionTime:(int)aValue;
- (void) setIntegrationTime:(int)aValue;

- (int) externalWindowAsInt;
- (int) pileUpWindowAsInt;
- (int) noiseWindowAsInt;
- (int) extTrigLengthAsInt;
- (int) collectionTimeAsInt;
- (int) integrationTimeAsInt; 

- (void) setPolarity:(short)chan withValue:(int)aValue;
- (void) setTriggerMode:(short)chan withValue:(int)aValue; 
- (void) setPileUp:(short)chan withValue:(short)aValue;		
- (void) setEnabled:(short)chan withValue:(short)aValue;
- (void) setCFDEnabled:(short)chan withValue:(short)aValue;
- (void) setPoleZeroEnabled:(short)chan withValue:(short)aValue;		
- (void) setPoleZeroMultiplier:(short)chan withValue:(short)aValue;		
- (void) setPZTraceEnabled:(short)chan withValue:(short)aValue;		
- (void) setDebug:(short)chan withValue:(short)aValue;	
- (void) setLEDThreshold:(short)chan withValue:(int)aValue;
- (void) setCFDDelay:(short)chan withValue:(int)aValue;	
- (void) setCFDFraction:(short)chan withValue:(int)aValue;	
- (void) setCFDThreshold:(short)chan withValue:(int)aValue;
- (void) setDataDelay:(short)chan withValue:(int)aValue;
// Data Length refers to total length of the record (w/ header), trace length refers to length of trace
- (void) setDataLength:(short)chan withValue:(int)aValue;  
- (void) setTraceLength:(short)chan withValue:(int)aValue;  

- (int) enabled:(short)chan;
- (int) poleZeroEnabled:(short)chan;
- (int) poleZeroMult:(short)chan;
- (int) pzTraceEnabled:(short)chan;
- (int) cfdEnabled:(short)chan;		
- (int) debug:(short)chan;		
- (int) pileUp:(short)chan;		
- (int)	polarity:(short)chan;	
- (int) triggerMode:(short)chan;	
- (int) ledThreshold:(short)chan;	
- (int) cfdDelay:(short)chan;		
- (int) cfdFraction:(short)chan;	
- (int) cfdThreshold:(short)chan;	
- (int) dataDelay:(short)chan;		
// Data Length refers to total length of the record (w/ header), trace length refers to length of trace
- (int) dataLength:(short)chan;
- (int) traceLength:(short)chan;
- (BOOL) isLocked;
- (BOOL) locked;
- (void) setLocked:(BOOL)aState;
- (NSString*) serDesStateName;

//conversion methods
- (float) poleZeroTauConverted:(short)chan;
- (float) cfdDelayConverted:(short)chan;
- (float) cfdThresholdConverted:(short)chan;
- (float) dataDelayConverted:(short)chan;
- (float) traceLengthConverted:(short)chan;

- (void) setPoleZeroTauConverted:(short)chan withValue:(float)aValue;	
- (void) setCFDDelayConverted:(short)chan withValue:(float)aValue;	
- (void) setCFDThresholdConverted:(short)chan withValue:(float)aValue;
// Data Length refers to total length of the record (w/ header), trace length refers to length of trace
- (void) setDataDelayConverted:(short)chan withValue:(float)aValue;   
- (void) setTraceLengthConverted:(short)chan withValue:(float)aValue;  

#pragma mark ¥¥¥Hardware Access
- (short) readBoardID;
- (void) resetFIFO;
- (void) resetSingleFIFO;
- (void) resetBoard;
- (BOOL) fifoIsEmpty;
- (short) clockSource;
- (void) setClockSource:(short)aClockMux;
- (void) resetMainFPGA;
- (void) initBoard:(BOOL)doEnableChannels;
- (unsigned long) readControlReg:(int)channel;
- (void) writeControlReg:(int)channel enabled:(BOOL)enabled;
- (void) writeLEDThreshold:(int)channel;
- (void) writeCFDParameters:(int)channel;
- (void) writeRawDataSlidingLength:(int)channel;
- (void) writeRawDataWindowLength:(int)channel;
- (unsigned short) readFifoState;
- (int) clearFIFO;
- (int) findNextEventInTheFIFO;
- (void) findNoiseFloors;
- (void) stepNoiseFloor;
- (BOOL) noiseFloorRunning;
- (void) writeDownSample;

- (int) readCardInfo:(int)index;
- (int) readExternalWindow;
- (int) readPileUpWindow;
- (int) readNoiseWindow;
- (int) readExtTrigLength;
- (int) readCollectionTime;
- (int) readIntegrationTime;
- (int) readDownSample;
- (BOOL) controllerIsSBC;
- (void) copyFirmwareFileToSBC:(NSString*)firmwarePath;
- (void) writeClockSource;


#pragma mark ¥¥¥FPGA download
- (void) startDownLoadingMainFPGA;
- (void) stopDownLoadingMainFPGA;
- (NSString*) firmwareStatusString;
- (void) flashFpgaStatus:(ORSBCLinkJobStatus*) jobStatus;
- (void) writeToAddress:(unsigned long)anAddress aValue:(unsigned long)aValue;
- (unsigned long) readFromAddress:(unsigned long)anAddress;
- (void) readFPGAVersions;
- (BOOL) checkFirmwareVersion;
- (BOOL) checkFirmwareVersion:(BOOL)verbose;

#pragma mark ¥¥¥Data Taker
- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*) dataRecordDescription;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (unsigned long) waveFormCount:(int)aChannel;
- (void)   startRates;
- (void) clearWaveFormCounts;
- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag;
- (void) checkFifoAlarm;
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (BOOL) bumpRateFromDecodeStage:(short)channel;

#pragma mark ¥¥¥HW Wizard
- (int) numberOfChannels;
- (NSArray*) wizardParameters;
- (NSArray*) wizardSelections;
- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(short*)anArray forKey:(NSString*)aKey;

#pragma mark ¥¥¥AutoTesting
- (NSArray*) autoTests;

#pragma mark ¥¥¥SPI Interface
- (unsigned long) writeAuxIOSPI:(unsigned long)spiData;

#pragma mark ***AdcProviding Protocol
- (void) initBoard;
- (unsigned long) thresholdForDisplay:(unsigned short) aChan;
- (unsigned short) gainForDisplay:(unsigned short) aChan;
- (BOOL) onlineMaskBit:(int)bit;
- (BOOL) partOfEvent:(unsigned short)aChannel;
- (unsigned long) eventCount:(int)aChannel;
- (void) clearEventCounts;
- (void) postAdcInfoProvidingValueChanged;

@end

@interface NSObject (Gretina4)
- (NSString*) IPNumber;
- (NSString*) userName;
- (NSString*) passWord;
- (SBC_Link*) sbcLink;
@end

extern NSString* ORGretina4ModelDownSampleChanged;
extern NSString* ORGretina4ModelHistEMultiplierChanged;
extern NSString* ORGretina4ModelRegisterIndexChanged;
extern NSString* ORGretina4ModelRegisterWriteValueChanged;
extern NSString* ORGretina4ModelSPIWriteValueChanged;
extern NSString* ORGretina4ModelMainFPGADownLoadInProgressChanged;
extern NSString* ORGretina4ModelFpgaDownProgressChanged;
extern NSString* ORGretina4ModelMainFPGADownLoadStateChanged;
extern NSString* ORGretina4ModelFpgaFilePathChanged;
extern NSString* ORGretina4ModelNoiseFloorIntegrationTimeChanged;
extern NSString* ORGretina4ModelNoiseFloorOffsetChanged;

extern NSString* ORGretina4ModelEnabledChanged;
extern NSString* ORGretina4ModelDebugChanged;
extern NSString* ORGretina4ModelPileUpChanged;
extern NSString* ORGretina4ModelCFDEnabledChanged;
extern NSString* ORGretina4ModelPoleZeroEnabledChanged;
extern NSString* ORGretina4ModelPoleZeroMultChanged;
extern NSString* ORGretina4ModelPZTraceEnabledChanged;
extern NSString* ORGretina4ModelPolarityChanged;
extern NSString* ORGretina4ModelTriggerModeChanged;
extern NSString* ORGretina4ModelLEDThresholdChanged;
extern NSString* ORGretina4ModelCFDDelayChanged;
extern NSString* ORGretina4ModelCFDFractionChanged;
extern NSString* ORGretina4ModelCFDThresholdChanged;
extern NSString* ORGretina4ModelDataDelayChanged;
extern NSString* ORGretina4ModelDataLengthChanged;

extern NSString* ORGretina4SettingsLock;
extern NSString* ORGretina4RegisterLock;
extern NSString* ORGretina4CardInfoUpdated;
extern NSString* ORGretina4RateGroupChangedNotification;
extern NSString* ORGretina4NoiseFloorChanged;
extern NSString* ORGretina4ModelFIFOCheckChanged;
extern NSString* ORGretina4CardInited;
extern NSString* ORGretina4ModelSetEnableStatusChanged;
extern NSString* ORGretina4ModelFirmwareStatusStringChanged;
extern NSString* ORGretina4ClockSourceChanged;
extern NSString* ORGretina4ModelInitStateChanged;
extern NSString* ORGretina4LockChanged;
