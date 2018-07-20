//
//  ORDT5720Model.h
//  Orca
//
//  Created by Mark Howe on Wed Mar 12,2014.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina at the Center sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files

#import "ORUsbDeviceModel.h"
#import "ORUSB.h"
#import "ORDataTaker.h"

@class ORUSBInterface;
@class ORAlarm;
@class ORDataSet;
@class ORRateGroup;
@class ORSafeCircularBuffer;

enum {
	kZS_Thres,				//0x1024
	kZS_NsAmp,				//0x1028
    kThresholds,			//0x1080
    kNumOUThreshold,		//0x1084
    kStatus,				//0x1088
    kFirmwareVersion,		//0x108C
    kBufferOccupancy,		//0x1094
    kDacs,					//0x1098
    kAdcConfig,				//0x109C
    kChanConfig,			//0x8000
    kChanConfigBitSet,		//0x8004
    kChanConfigBitClr,		//0x8008
    kBufferOrganization,	//0x800C
    kAcqControl,			//0x8100
    kAcqStatus,				//0x8104
    kSWTrigger,				//0x8108
    kTrigSrcEnblMask,		//0x810C
    kFPTrigOutEnblMask,		//0x8110
    kPostTrigSetting,		//0x8114
    kFPIOControl,			//0x811C
    kChanEnableMask,		//0x8120
    kROCFPGAVersion,		//0x8124
    kEventStored,			//0x812C
    kBoardInfo,				//0x8140
    kEventSize,				//0x814C
    kVMEControl,			//0xEF00
    kVMEStatus,				//0xEF04
    kInterruptStatusID,		//0xEF14
    kInterruptEventNum,		//0xEF18
    kBLTEventNum,			//0xEF1C
    kScratch,				//0xEF20
    kSWReset,				//0xEF24
    kSWClear,				//0xEF28
    kConfigReload,			//0xEF34
    kConfigROMVersion,      //0xF030
    kConfigROMBoard2,       //0xF034
	kNumberDT5720Registers  //must be last
};

typedef struct  {
	NSString*       regName;
    uint32_t 	addressOffset;
    short			accessType;
    bool			hwReset;
    bool			softwareReset;
	bool			dataReset;
} DT5720RegisterNamesStruct;


enum {
    kNoZeroSuppression ,
    kZeroLengthEncoding,
    kFullSuppressionBasedOnAmplitude
};

#define kDT5720BufferEmpty 0
#define kDT5720BufferReady 1
#define kDT5720BufferFull  3

typedef struct  {
	NSString*       regName;
	uint32_t 	addressOffset;
	short			accessType;
    unsigned short  numBits;
} DT5720ControllerRegisterNamesStruct;


// Size of output buffer
#define kEventBufferSize 0x0FFC

#define kReadOnly 0
#define kWriteOnly 1
#define kReadWrite 2

#define kNumDT5720Channels 4

@interface ORDT5720Model : ORUsbDeviceModel <USBDevice,ORDataTaker> {
	ORUSBInterface* usbInterface;
 	ORAlarm*		noUSBAlarm;
    NSString*		serialNumber;
	uint32_t   dataId;
    unsigned short  zsThresholds[kNumDT5720Channels];
    unsigned short	numOverUnderZsThreshold[kNumDT5720Channels];
    unsigned short  thresholds[kNumDT5720Channels];
    unsigned short  nLbk[kNumDT5720Channels];
    unsigned short  nLfwd[kNumDT5720Channels];
    int             logicType[kNumDT5720Channels];
    int             zsAlgorithm;
    BOOL            packed;
    BOOL            trigOverlapEnabled;
    BOOL            testPatternEnabled;
    BOOL            trigOnUnderThreshold;
    BOOL            packEnabled;
    BOOL            clockSource;
    BOOL            gpiRunMode;
    BOOL            softwareTrigEnabled;
    BOOL            externalTrigEnabled;
    BOOL            fpExternalTrigEnabled;
    BOOL            fpSoftwareTrigEnabled;
    BOOL            gpoEnabled;
    int             ttlEnabled;
    uint32_t   triggerSourceMask;

    
	unsigned short	dac[kNumDT5720Channels];
	unsigned short	numOverUnderThreshold[kNumDT5720Channels];
    BOOL			countAllTriggers;
    unsigned short  coincidenceLevel;
	uint32_t   triggerOutMask;
    uint32_t	postTriggerSetting;
    unsigned short	enabledMask;
	ORRateGroup*	waveFormRateGroup;
	uint32_t 	waveFormCount[kNumDT5720Channels];
    int				bufferState;
    int				lastBufferState;
	ORAlarm*        bufferFullAlarm;
	int				bufferEmptyCount;
    int				eventSize;
    
    unsigned short  selectedRegIndex;
    unsigned short  selectedChannel;
    uint32_t   selectedRegValue;

	//data taking, some are cached and only valid during running
	unsigned int    statusReg;
	uint32_t   location;
	uint32_t	eventSizeReg;
	uint32_t	dataReg;
    uint32_t   totalBytesTransfered;
    float           totalByteRate;
    NSDate*         lastTimeByteTotalChecked;
    BOOL            firstTime;
    BOOL            isRunning;
    BOOL            isDataWorkerRunning;
    BOOL            isTimeToStopDataWorker;
    ORSafeCircularBuffer* circularBuffer;
    NSMutableData*  eventData;
    BOOL            cachedPack;
}

@property (assign) BOOL isDataWorkerRunning;
@property (assign) BOOL isTimeToStopDataWorker;

#pragma mark ***USB
- (id)              getUSBController;
- (ORUSBInterface*) usbInterface;
- (void)            setUsbInterface:(ORUSBInterface*)anInterface;
- (NSString*)       serialNumber;
- (void)            setSerialNumber:(NSString*)aSerialNumber;
- (NSUInteger)   vendorID;
- (NSUInteger)   productID;
- (NSString*)       usbInterfaceDescription;
- (void)            interfaceAdded:(NSNotification*)aNote;
- (void)            interfaceRemoved:(NSNotification*)aNote;
- (void)            checkUSBAlarm;

#pragma mark Accessors
//------------------------------
- (int)             logicType:(unsigned short) i;
- (void)            setLogicType:(unsigned short) i withValue:(int)aLogicType;
- (unsigned short)	zsThreshold:(unsigned short) i;
- (void)			setZsThreshold:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (unsigned short)	numOverUnderZsThreshold:(unsigned short) i;
- (void)			setNumOverUnderZsThreshold:(unsigned short) i withValue:(unsigned short) aValue;
- (unsigned short)	nLbk:(unsigned short) i;
- (void)			setNlbk:(unsigned short) i withValue:(unsigned short) aValue;
- (unsigned short)	nLfwd:(unsigned short) i;
- (void)			setNlfwd:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (unsigned short)	threshold:(unsigned short) i;
- (void)			setThreshold:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (unsigned short)	numOverUnderThreshold:(unsigned short) i;
- (void)			setNumOverUnderThreshold:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (unsigned short)	dac:(unsigned short) i;
- (void)			setDac:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (int)             zsAlgorithm;
- (void)            setZsAlgorithm:(int)aZsAlgorithm;
- (BOOL)            packed;
- (void)            setPacked:(BOOL)aPacked;
- (BOOL)            trigOnUnderThreshold;
- (void)            setTrigOnUnderThreshold:(BOOL)aTrigOnUnderThreshold;
- (BOOL)            testPatternEnabled;
- (void)            setTestPatternEnabled:(BOOL)aTestPatternEnabled;
- (BOOL)            trigOverlapEnabled;
- (void)            setTrigOverlapEnabled:(BOOL)aTrigOverlapEnabled;
//------------------------------
- (int)				eventSize;
- (void)			setEventSize:(int)aEventSize;
//------------------------------
- (BOOL)            clockSource;
- (void)            setClockSource:(BOOL)aClockSource;
- (BOOL)			countAllTriggers;
- (void)			setCountAllTriggers:(BOOL)aCountAllTriggers;
- (BOOL)            gpiRunMode;
- (void)            setGpiRunMode:(BOOL)aGpiRunMode;
//------------------------------
- (BOOL)            softwareTrigEnabled;
- (void)            setSoftwareTrigEnabled:(BOOL)aSoftwareTrigEnabled;
- (BOOL)            externalTrigEnabled;
- (void)            setExternalTrigEnabled:(BOOL)aExternalTrigEnabled;
- (unsigned short)	coincidenceLevel;
- (void)			setCoincidenceLevel:(unsigned short)aCoincidenceLevel;
- (uint32_t)	triggerSourceMask;
- (void)			setTriggerSourceMask:(uint32_t)aTriggerSourceMask;
//------------------------------
- (BOOL)            fpSoftwareTrigEnabled;
- (void)            setFpSoftwareTrigEnabled:(BOOL)aFpSoftwareTrigEnabled;
- (BOOL)            fpExternalTrigEnabled;
- (void)            setFpExternalTrigEnabled:(BOOL)aFpExternalTrigEnabled;
- (uint32_t)	triggerOutMask;
- (void)			setTriggerOutMask:(uint32_t)aTriggerOutMask;
//------------------------------
- (BOOL)            gpoEnabled;
- (void)            setGpoEnabled:(BOOL)aGpoEnabled;
- (int)             ttlEnabled;
- (void)            setTtlEnabled:(int)aTtlEnabled;
//------------------------------
- (uint32_t)	postTriggerSetting;
- (void)			setPostTriggerSetting:(uint32_t)aPostTriggerSetting;
//------------------------------
- (unsigned short)	enabledMask;
- (void)			setEnabledMask:(unsigned short)aEnabledMask;
//------------------------------

- (int)				bufferState;

//------------------------------
//rate related
- (void)			clearWaveFormCounts;
- (void)			setRateIntegrationTime:(double)newIntegrationTime;
- (id)				rateObject:(int)channel;
- (ORRateGroup*)	waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;

#pragma mark ***Register - General routines
- (void)			read;
- (void)			write;
- (void)			report;
- (void)			read:(unsigned short) pReg returnValue:(uint32_t*) pValue;
- (void)			write:(unsigned short) pReg sendValue:(uint32_t) pValue;
- (short)			getNumberRegisters;


#pragma mark ***HW Init
- (void)			initBoard;

- (void)            writeZSThresholds;
- (void)            writeZSThreshold:(unsigned short) i;
- (void)            writeZSAmplReg;
- (void)            writeZSAmplReg:(unsigned short) i;
- (void)			writeThresholds;
- (void)			writeThreshold:(unsigned short) pChan;
- (void)            writeNumOverUnderThresholds;
- (void)            writeNumOverUnderThreshold:(unsigned short) i;
- (void)			writeDacs;
- (void)			writeDac:(unsigned short) pChan;
- (void)			writeChannelConfiguration;
- (void)			writeBufferOrganization;
- (void)			writeAcquistionControl:(BOOL)start;
- (void)            trigger;
- (void)            writeTriggerSourceEnableMask;
- (void)            writeFrontPanelIOControl;
- (void)            writeFrontPanelTriggerOutEnableMask;
- (void)			writePostTriggerSetting;
- (void)			writeChannelEnabledMask;
- (void)			writeNumBLTEventsToReadout;
- (void)			softwareReset;
- (void)			clearAllMemory;
- (void)			checkBufferAlarm;

- (void)            readConfigurationROM;

#pragma mark ***Register - Register specific routines
- (unsigned short) 	selectedChannel;
- (void)			setSelectedChannel: (unsigned short) anIndex;
- (uint32_t) 	selectedRegValue;
- (void)			setSelectedRegValue: (uint32_t) anIndex;
- (unsigned short)  selectedRegIndex;
- (void)            setSelectedRegIndex:(unsigned short) anIndex;
- (NSString*) 		getRegisterName: (short) anIndex;
- (uint32_t) 	getAddressOffset: (short) anIndex;
- (short)			getAccessType: (short) anIndex;
- (BOOL)			dataReset: (short) anIndex;
- (BOOL)			swReset: (short) anIndex;
- (BOOL)			hwReset: (short) anIndex;

#pragma mark •••DataTaker
- (uint32_t)	dataId;
- (void)			setDataId: (uint32_t) DataId;
- (void)			setDataIds:(id)assigner;
- (void)			syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*)	dataRecordDescription;
- (void)			runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;
- (void)			takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void)			runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;
- (BOOL)            bumpRateFromDecodeStage:(short)channel;
- (float)           totalByteRate;

#pragma mark ***Helpers
- (float)			convertDacToVolts:(unsigned short)aDacValue;
- (unsigned short)	convertVoltsToDac:(float)aVoltage;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(int32_t*)anArray forKey:(NSString*)aKey;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***HW Read/Write API
- (int)     writeLongBlock:(uint32_t*) writeValue atAddress:(uint32_t) vmeAddress;
- (int)     readLongBlock:(uint32_t*)  readValue atAddress:(uint32_t) vmeAddress;
- (void)    writeChan:(unsigned short)chan reg:(unsigned short) pReg sendValue:(uint32_t) pValue;
- (void)    readChan:(unsigned short)chan reg:(unsigned short) pReg returnValue:(uint32_t*) pValue;
- (int) readFifo:(char*)destBuff numBytesToRead:(uint32_t)    numBytes;


@end

extern NSString* ORDT5720BasicLock;
extern NSString* ORDT5720LowLevelLock;
extern NSString* ORDT5720ModelUSBInterfaceChanged;
extern NSString* ORDT5720ModelSerialNumberChanged;

extern NSString* ORDT5720ModelLogicTypeChanged;
extern NSString* ORDT5720ZsThresholdChanged;
extern NSString* ORDT5720NumOverUnderZsThresholdChanged;
extern NSString* ORDT5720NlbkChanged;
extern NSString* ORDT5720NlfwdChanged;
extern NSString* ORDT5720ThresholdChanged;
extern NSString* ORDT5720NumOverUnderThresholdChanged;
extern NSString* ORDT5720DacChanged;
extern NSString* ORDT5720ModelZsAlgorithmChanged;
extern NSString* ORDT5720ModelPackedChanged;
extern NSString* ORDT5720ModelTrigOnUnderThresholdChanged;
extern NSString* ORDT5720ModelTestPatternEnabledChanged;
extern NSString* ORDT5720ModelTrigOverlapEnabledChanged;
extern NSString* ORDT5720ModelEventSizeChanged;
extern NSString* ORDT5720ModelClockSourceChanged;
extern NSString* ORDT5720ModelCountAllTriggersChanged;
extern NSString* ORDT5720ModelGpiRunModeChanged;
extern NSString* ORDT5720ModelTriggerSourceMaskChanged;
extern NSString* ORDT5720ModelExternalTrigEnabledChanged;
extern NSString* ORDT5720ModelSoftwareTrigEnabledChanged;
extern NSString* ORDT5720ModelCoincidenceLevelChanged;
extern NSString* ORDT5720ModelEnabledMaskChanged;
extern NSString* ORDT5720ModelFpSoftwareTrigEnabledChanged;
extern NSString* ORDT5720ModelFpExternalTrigEnabledChanged;
extern NSString* ORDT5720ModelTriggerOutMaskChanged;
extern NSString* ORDT5720ModelPostTriggerSettingChanged;
extern NSString* ORDT5720ModelGpoEnabledChanged;
extern NSString* ORDT5720ModelTtlEnabledChanged;



extern NSString* ORDT5720Chnl;
extern NSString* ORDT5720SelectedRegIndexChanged;
extern NSString* ORDT5720SelectedChannelChanged;
extern NSString* ORDT5720WriteValueChanged;

extern NSString* ORDT5720SelectedRegIndexChanged;
extern NSString* ORDT5720SelectedRegIndexChanged;
extern NSString* ORDT5720SelectedChannelChanged;
extern NSString* ORDT5720WriteValueChanged;

extern NSString* ORDT5720RateGroupChanged;
extern NSString* ORDT5720ModelBufferCheckChanged;

