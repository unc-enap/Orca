//
//  ORDT5725Model.h
//  Orca
//
//  Created by Mark Howe on Wed Jun 29,2016.
//  Copyright (c) 2016 University of North Carolina. All rights reserved.
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

enum { //Assume all kept register implementations need reworking
	kInputDyRange,			//0x1n28
    kTrigPulseWidth,        //0x1n70
    kThresholds,			//0x1n80
    kSelfTrigLogic,         //0x1n84
    kStatus,				//0x1n88
    kAMCRevision,         	//0x1n8C 
    kBufferOccupancy,		//0x1n94 
    kDCOffset,				//0x1n98
    kAdcTemp,               //0x1nA8
    kBoardConfig,			//0x8000
    kBoardConfigBitSet,		//0x8004
    kBoardConfigBitClr,		//0x8008
    kBufferOrganization,	//0x800C
    kCustomSize,            //0x8020
    kChanAdcCalib,          //0x809C
    kAcqControl,			//0x8100
    kAcqStatus,				//0x8104
    kSWTrigger,             //0x8108
    kTrigSrcEnblMask,		//0x810C
    kFPTrigOutEnblMask,		//0x8110
    kPostTrigSetting,		//0x8114
    kFPIOControl,			//0x811C
    kChanEnableMask,		//0x8120
    kROCFPGAVersion,		//0x8124
    kEventStored,			//0x812C
    kBoardInfo,				//0x8140
    kEventSize,				//0x814C
    kFanSpeed,              //0x8168
    kBufAlmostFull,         //0x816C
    kRunDelay,              //0x8170
    kBFStatus,              //0x8178
    kReadoutStatus,			//0xEF04
    kBLTEventNum,			//0xEF1C
    kScratch,				//0xEF20
    kSWReset,				//0xEF24
    kSWClear,				//0xEF28
    kConfigReload,			//0xEF34
    kConfigROMVersion,      //0xF030
    kConfigROMBoard2,       //0xF034
	kNumberDT5725Registers  //must be last
};

typedef struct  {
	NSString*       regName;
    uint32_t 	addressOffset;
    short			accessType;
    bool			hwReset;
    bool			softwareReset;
	bool			dataReset;
} DT5725RegisterNamesStruct;


#define kDT5725BufferEmpty 0
#define kDT5725BufferReady 1
#define kDT5725BufferFull  3

typedef struct  {
	NSString*       regName;
	uint32_t 	addressOffset;
	short			accessType;
    unsigned short  numBits;
} DT5725ControllerRegisterNamesStruct;


// Size of output buffer
#define kEventBufferSize 0x0FFC

#define kReadOnly 0
#define kWriteOnly 1
#define kReadWrite 2

#define kNumDT5725Channels 8

@interface ORDT5725Model : ORUsbDeviceModel <USBDevice,ORDataTaker> {
    //USB
	ORUSBInterface* usbInterface;
 	ORAlarm*		noUSBAlarm;
    NSString*		serialNumber;

    //Basic Controls
    unsigned short  inputDynamicRange[kNumDT5725Channels];
    unsigned short  thresholds[kNumDT5725Channels];
    unsigned short  dcOffset[kNumDT5725Channels];
    BOOL            trigOverlapEnabled;
    BOOL            testPatternEnabled;
    BOOL            trigOnUnderThreshold;
    uint32_t	eventSize;
    uint32_t   buffCode;
    uint32_t   triggerSourceMask;
    BOOL            softwareTrigEnabled;
    BOOL            externalTrigEnabled;
    uint32_t	postTriggerSetting;
    unsigned short	enabledMask;

    //Advanced Controls
    unsigned short  selfTrigPulseWidth[kNumDT5725Channels];
    unsigned short  selfTrigLogic[kNumDT5725Channels/2];
    unsigned short  selfTrigPulseType[kNumDT5725Channels/2];
    unsigned short  startStopRunMode;
    BOOL			countAllTriggers;
    BOOL            memFullMode;
    BOOL            clockSource;
    unsigned short  coincidenceWindow;
    unsigned short  coincidenceLevel;
	uint32_t   triggerOutMask;
    unsigned short  triggerOutLogic;
    unsigned short  trigOutCoincidenceLevel;
    BOOL            extTrigOutEnabled;
    BOOL            swTrigOutEnabled;
    BOOL            fpLogicType;
    BOOL            fpTrigInSigEdgeDisable;
    BOOL            fpTrigInToMezzanines;
    BOOL            fpForceTrigOut;
    BOOL            fpTrigOutMode;
    unsigned short  fpTrigOutModeSelect;
    unsigned short  fpMBProbeSelect;
    BOOL            fpBusyUnlockSelect;
    unsigned short  fpHeaderPattern;
    BOOL            fanSpeedMode;
    unsigned short  almostFullLevel;
    uint32_t   runDelay;
    
    //-------------------------------------
	ORRateGroup*	waveFormRateGroup;
	uint32_t 	waveFormCount[kNumDT5725Channels];
    int				bufferState;
    int				lastBufferState;
	ORAlarm*        bufferFullAlarm;
	int				bufferEmptyCount;
    //-------------------------------------
    
    unsigned short  selectedRegIndex;
    unsigned short  selectedChannel;
    uint32_t   selectedRegValue;

	//data taking, some are cached and only valid during running
    uint32_t   dataId;
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
- (unsigned short)  inputDynamicRange:(unsigned short) i;
- (void)            setInputDynamicRange:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (unsigned short)  selfTrigPulseWidth:(unsigned short) i;
- (void)            setSelfTrigPulseWidth:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (unsigned short)	threshold:(unsigned short) i;
- (void)			setThreshold:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (unsigned short)  selfTrigLogic:(unsigned short) i;
- (void)            setSelfTrigLogic:(unsigned short) i withValue:(unsigned short) aValue;
- (unsigned short)  selfTrigPulseType:(unsigned short) i;
- (void)            setSelfTrigPulseType:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (unsigned short)  dcOffset:(unsigned short) i;
- (void)            setDCOffset:(unsigned short) i withValue:(unsigned short) aValue;
//------------------------------
- (BOOL)            trigOnUnderThreshold;
- (void)            setTrigOnUnderThreshold:(BOOL)aTrigOnUnderThreshold;
- (BOOL)            testPatternEnabled;
- (void)            setTestPatternEnabled:(BOOL)aTestPatternEnabled;
- (BOOL)            trigOverlapEnabled;
- (void)            setTrigOverlapEnabled:(BOOL)aTrigOverlapEnabled;
//------------------------------
- (uint32_t)   eventSize;
- (void)			setEventSize:(uint32_t)aEventSize;
//------------------------------
- (BOOL)            clockSource;
- (void)            setClockSource:(BOOL)aClockSource;
- (BOOL)			countAllTriggers;
- (void)			setCountAllTriggers:(BOOL)aCountAllTriggers;
- (unsigned short)  startStopRunMode;
- (void)            setStartStopRunMode:(BOOL)aStartStopRunMode;
- (BOOL)            memFullMode;
- (void)            setMemFullMode:(BOOL)aMemFullMode;
//------------------------------
- (BOOL)            softwareTrigEnabled;
- (void)            setSoftwareTrigEnabled:(BOOL)aSoftwareTrigEnabled;
- (BOOL)            externalTrigEnabled;
- (void)            setExternalTrigEnabled:(BOOL)aExternalTrigEnabled;
- (unsigned short)  coincidenceWindow;
- (void)            setCoincidenceWindow:(unsigned short)aCoincidenceWindow;
- (unsigned short)	coincidenceLevel;
- (void)			setCoincidenceLevel:(unsigned short)aCoincidenceLevel;
- (uint32_t)	triggerSourceMask;
- (void)			setTriggerSourceMask:(uint32_t)aTriggerSourceMask;
//------------------------------
- (BOOL)            swTrigOutEnabled;
- (void)            setSwTrigOutEnabled:(BOOL)aSwTrigOutEnabled;
- (BOOL)            extTrigOutEnabled;
- (void)            setExtTrigOutEnabled:(BOOL)aExtTrigOutEnabled;
- (uint32_t)	triggerOutMask;
- (void)			setTriggerOutMask:(uint32_t)aTriggerOutMask;
- (unsigned short)  triggerOutLogic;
- (void)            setTriggerOutLogic:(unsigned short)aTriggerOutLogic;
- (unsigned short)  trigOutCoincidenceLevel;
- (void)            setTrigOutCoincidenceLevel:(unsigned short)aTrigOutCoincidenceLevel;
//------------------------------
- (uint32_t)	postTriggerSetting;
- (void)			setPostTriggerSetting:(uint32_t)aPostTriggerSetting;
//------------------------------
- (BOOL)            fpLogicType;
- (void)            setFpLogicType:(BOOL)aFpLogicType;
- (BOOL)            fpTrigInSigEdgeDisable;
- (void)            setFpTrigInSigEdgeDisable:(BOOL)aFpTrigInSigEdgeDisable;
- (BOOL)            fpTrigInToMezzanines;
- (void)            setFpTrigInToMezzanines:(BOOL)aFpTrigInToMezzanines;
- (BOOL)            fpForceTrigOut;
- (void)            setFpForceTrigOut:(BOOL)aFpForceTrigOut;
- (BOOL)            fpTrigOutMode;
- (void)            setFpTrigOutMode:(BOOL)aFpTrigOutMode;
- (unsigned short)  fpTrigOutModeSelect;
- (void)            setFpTrigOutModeSelect:(unsigned short)aFpTrigOutModeSelect;
- (unsigned short)  fpMBProbeSelect;
- (void)            setFpMBProbeSelect:(unsigned short)aFpMBProbeSelect;
- (BOOL)            fpBusyUnlockSelect;
- (void)            setFpBusyUnlockSelect:(BOOL)aFpBusyUnlockSelect;
- (unsigned short)  fpHeaderPattern;
- (void)            setFpHeaderPattern:(unsigned short)aFpHeaderPattern;
//------------------------------
- (unsigned short)	enabledMask;
- (void)			setEnabledMask:(unsigned short)aEnabledMask;
//------------------------------
- (BOOL)            fanSpeedMode;
- (void)            setFanSpeedMode:(BOOL)aFanSpeedMode;
//------------------------------
- (unsigned short)  almostFullLevel;
- (void)            setAlmostFullLevel:(unsigned short)anAlmostFullLevel;
//------------------------------
- (uint32_t)   runDelay;
- (void)            setRunDelay:(uint32_t)aRunDelay;
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

- (void)            writeDynamicRanges;
- (void)            writeDynamicRange:(unsigned short) pChan;
- (void)            writeTrigPulseWidths;
- (void)            writeTrigPulseWidth:(unsigned short) pChan;
- (void)			writeThresholds;
- (void)			writeThreshold:(unsigned short) pChan;
- (void)            writeSelfTrigLogics;
- (void)            writeSelfTrigLogic:(unsigned short) pChan;
- (void)            writeDCOffsets;
- (void)            writeDCOffset:(unsigned short) pChan;
- (void)			writeBoardConfiguration;
- (void)            writeSize;
- (void)            adcCalibrate;
- (void)			writeAcquisitionControl:(BOOL)start;
- (void)            trigger;
- (void)            writeTriggerSourceEnableMask;
- (void)            writeFrontPanelTriggerOutEnableMask;
- (void)			writePostTriggerSetting;
- (void)            writeFrontPanelIOControl;
- (void)			writeChannelEnabledMask;
- (void)            writeFanSpeedControl;
- (void)            writeBufferAlmostFull;
- (void)            writeRunDelay;
- (void)			writeNumBLTEventsToReadout;
- (void)			softwareReset;
- (void)			clearAllMemory;
- (void)            configReload;
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
- (float)			convertDacToVolts:(unsigned short)aDacValue dynamicRange:(BOOL)dynamicRange;
- (unsigned short)	convertVoltsToDac:(float)aVoltage dynamicRange:(BOOL)dynamicRange;
- (void)            addCurrentState:(NSMutableDictionary*)dictionary longArray:(int32_t*)anArray forKey:(NSString*)aKey;
- (void)            addCurrentState:(NSMutableDictionary*)dictionary uShortArray:(unsigned short*)anArray forKey:(NSString*)aKey;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***HW Read/Write API
- (int)     writeLongBlock:(uint32_t*) writeValue atAddress:(uint32_t) vmeAddress;
- (int)     readLongBlock:(uint32_t*)  readValue atAddress:(uint32_t) vmeAddress;
- (void)    writeChan:(unsigned short)chan reg:(unsigned short) pReg sendValue:(uint32_t) pValue;
- (void)    readChan:(unsigned short)chan reg:(unsigned short) pReg returnValue:(uint32_t*) pValue;
- (int)     readFifo:(char*)destBuff numBytesToRead:(int)    numBytes;


@end

extern NSString* ORDT5725BasicLock;
extern NSString* ORDT5725LowLevelLock;
extern NSString* ORDT5725ModelUSBInterfaceChanged;
extern NSString* ORDT5725ModelSerialNumberChanged;

extern NSString* ORDT5725ModelInputDynamicRangeChanged;
extern NSString* ORDT5725ModelSelfTrigPulseWidthChanged;
extern NSString* ORDT5725ThresholdChanged;
extern NSString* ORDT5725ModelSelfTrigLogicChanged;
extern NSString* ORDT5725ModelSelfTrigPulseTypeChanged;
extern NSString* ORDT5725ModelDCOffsetChanged;
extern NSString* ORDT5725ModelTrigOnUnderThresholdChanged;
extern NSString* ORDT5725ModelTestPatternEnabledChanged;
extern NSString* ORDT5725ModelTrigOverlapEnabledChanged;
extern NSString* ORDT5725ModelEventSizeChanged;
extern NSString* ORDT5725ModelClockSourceChanged;
extern NSString* ORDT5725ModelCountAllTriggersChanged;
extern NSString* ORDT5725ModelStartStopRunModeChanged;
extern NSString* ORDT5725ModelMemFullModeChanged;
extern NSString* ORDT5725ModelSoftwareTrigEnabledChanged;
extern NSString* ORDT5725ModelExternalTrigEnabledChanged;
extern NSString* ORDT5725ModelCoincidenceWindowChanged;
extern NSString* ORDT5725ModelCoincidenceLevelChanged;
extern NSString* ORDT5725ModelTriggerSourceMaskChanged;
extern NSString* ORDT5725ModelSwTrigOutEnabledChanged;
extern NSString* ORDT5725ModelExtTrigOutEnabledChanged;
extern NSString* ORDT5725ModelTriggerOutMaskChanged;
extern NSString* ORDT5725ModelTriggerOutLogicChanged;
extern NSString* ORDT5725ModelTrigOutCoincidenceLevelChanged;
extern NSString* ORDT5725ModelPostTriggerSettingChanged;
extern NSString* ORDT5725ModelFpLogicTypeChanged;
extern NSString* ORDT5725ModelFpTrigInSigEdgeDisableChanged;
extern NSString* ORDT5725ModelFpTrigInToMezzaninesChanged;
extern NSString* ORDT5725ModelFpForceTrigOutChanged;
extern NSString* ORDT5725ModelFpTrigOutModeChanged;
extern NSString* ORDT5725ModelFpTrigOutModeSelectChanged;
extern NSString* ORDT5725ModelFpMBProbeSelectChanged;
extern NSString* ORDT5725ModelFpBusyUnlockSelectChanged;
extern NSString* ORDT5725ModelFpHeaderPatternChanged;
extern NSString* ORDT5725ModelEnabledMaskChanged;
extern NSString* ORDT5725ModelFanSpeedModeChanged;
extern NSString* ORDT5725ModelAlmostFullLevelChanged;
extern NSString* ORDT5725ModelRunDelayChanged;

extern NSString* ORDT5725Chnl;
extern NSString* ORDT5725SelectedRegIndexChanged;
extern NSString* ORDT5725SelectedChannelChanged;
extern NSString* ORDT5725WriteValueChanged;

extern NSString* ORDT5725SelectedRegIndexChanged;
extern NSString* ORDT5725SelectedRegIndexChanged;
extern NSString* ORDT5725SelectedChannelChanged;
extern NSString* ORDT5725WriteValueChanged;

extern NSString* ORDT5725RateGroupChanged;
extern NSString* ORDT5725ModelBufferCheckChanged;

