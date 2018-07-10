//
//ORCaen1724Model.h
//Orca
//
//Created by Mark Howe on Mon Mar 14, 2011.
//Copyright (c) 2011 University of North Carolina. All rights reserved.
//
//-------------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORVmeIOCard.h"
#import "ORDataTaker.h"
#import "ORHWWizard.h"
#import "ORCaenDataDecoder.h"
#import "SBC_Config.h"

typedef struct  {
	NSString*       regName;
	bool			dataReset;
	bool			softwareReset;
	bool			hwReset;
	unsigned long 	addressOffset;
	short			accessType;
} Caen1724RegisterNamesStruct; 

// Declaration of constants for module.
enum {
	kOutputBuffer,			//0x0000
	kZS_Thres,				//0x1024
	kZS_NsAmp,				//0x1028
	kThresholds,			//0x1084
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
	kBufferFree,			//0x8010
	kCustomSize,			//0x8020
	kPolarityShift,			//0x802A
	kAcqControl,			//0x8100
	kAcqStatus,				//0x8104
	kSWTrigger,				//0x8108
	kTrigSrcEnblMask,		//0x810C
	kFPTrigOutEnblMask,		//0x8110
	kPostTrigSetting,		//0x8114
	kFPIOData,				//0x8118
	kFPIOControl,			//0x811C
	kChanEnableMask,		//0x8120
	kROCFPGAVersion,		//0x8124
	kDownsampleFactor,		//0x8128
	kEventStored,			//0x812C
	kSetMonitorDAC,			//0x8138
	kBoardInfo,				//0x8140
	kMonitorMode,			//0x8144
	kEventSize,				//0x814C
	kAnalogMonitor,			//0x8150
	kVMEControl,			//0xEF00
	kVMEStatus,				//0xEF04
	kBoardID,				//0xEF08
	kMultCastBaseAdd,		//0xEF0C
	kRelocationAdd,			//0xEF10		
	kInterruptStatusID,		//0xEF14
	kInterruptEventNum,		//0xEF18
	kBLTEventNum,			//0xEF1C
	kScratch,				//0xEF20
	kSWReset,				//0xEF24
	kSWClear,				//0xEF28
	kNumRegisters
};

// Size of output buffer
#define kEventBufferSize 0x0FFC
enum {
	kReadOnly,
	kWriteOnly,
	kReadWrite
};

@class ORRateGroup;
@class ORAlarm;

// Class definition
@interface ORCaen1724Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping>
{
	unsigned long   dataId;
	unsigned short  selectedRegIndex;
    unsigned short  selectedChannel;
    unsigned long   writeValue;
	unsigned short  thresholds[8];
	unsigned short	dac[8];
	unsigned short	overUnderThreshold[8];
    unsigned short	channelConfigMask;
	unsigned long	customSize;
	BOOL		isFixedSize;
    BOOL			countAllTriggers;
    unsigned short	acquisitionMode;
    unsigned short  coincidenceLevel;
    unsigned long   triggerSourceMask;
    unsigned long	postTriggerSetting;
    unsigned short	enabledMask;
	ORRateGroup*	waveFormRateGroup;
	unsigned long 	waveFormCount[8];
    int				bufferState;
	ORAlarm*        bufferFullAlarm;
	int				bufferEmptyCount;
	BOOL			isRunning;
    int				eventSize;
    unsigned long   numberBLTEventsToReadout;
	
	//cached variables, valid only during running
	unsigned int    statusReg;
	unsigned long   location;
	unsigned long	eventSizeReg;
	unsigned long	dataReg;
}

#pragma mark ***Accessors
- (int)				eventSize;
- (void)			setEventSize:(int)aEventSize;
- (int)				bufferState;
- (void)			clearWaveFormCounts;
- (void)			setRateIntegrationTime:(double)newIntegrationTime;
- (id)				rateObject:(int)channel;
- (ORRateGroup*)	waveFormRateGroup;
- (void)			setWaveFormRateGroup:(ORRateGroup*)newRateGroup;
- (unsigned short) 	selectedRegIndex;
- (void)			setSelectedRegIndex: (unsigned short) anIndex;
- (unsigned short) 	selectedChannel;
- (void)			setSelectedChannel: (unsigned short) anIndex;
- (unsigned long) 	writeValue;
- (void)			setWriteValue: (unsigned long) anIndex;
- (unsigned short)	enabledMask;
- (void)			setEnabledMask:(unsigned short)aEnabledMask;
- (unsigned long)	postTriggerSetting;
- (void)			setPostTriggerSetting:(unsigned long)aPostTriggerSetting;
- (unsigned long)	triggerSourceMask;
- (void)			setTriggerSourceMask:(unsigned long)aTriggerSourceMask;
- (unsigned short)	coincidenceLevel;
- (void)			setCoincidenceLevel:(unsigned short)aCoincidenceLevel;
- (unsigned short)	acquisitionMode;
- (void)			setAcquisitionMode:(unsigned short)aMode;
- (BOOL)			countAllTriggers;
- (void)			setCountAllTriggers:(BOOL)aCountAllTriggers;
- (unsigned long)	customSize;
- (void)			setCustomSize:(unsigned long)aCustomSize;
- (BOOL)		isFixedSize;
- (void)		setIsFixedSize:(BOOL)aIsFixedSize;
- (unsigned short)	channelConfigMask;
- (void)			setChannelConfigMask:(unsigned short)aChannelConfigMask;
- (unsigned short)	dac:(unsigned short) aChnl;
- (void)			setDac:(unsigned short) aChnl withValue:(unsigned short) aValue;
- (unsigned short)	overUnderThreshold:(unsigned short) aChnl;
- (void)			setOverUnderThreshold:(unsigned short) aChnl withValue:(unsigned short) aValue;
- (unsigned long)	numberBLTEventsToReadout;
- (void)			setNumberBLTEventsToReadout:(unsigned long)aNumberOfBLTEvents;

#pragma mark ***Register - General routines
- (void)			read;
- (void)			write;
- (void)			report;
- (void)			read:(unsigned short) pReg returnValue:(unsigned long*) pValue;
- (void)			write:(unsigned short) pReg sendValue:(unsigned long) pValue;
- (short)			getNumberRegisters;
- (void)			generateSoftwareTrigger;
- (void)			softwareReset;
- (void)			clearAllMemory;
- (void)			checkBufferAlarm;

#pragma mark ***HW Init
- (void)			initBoard;
- (void)			writeChannelConfiguration;
- (void)			writeCustomSize;
- (void)			writeAcquistionControl:(BOOL)start;
- (void)			writeTriggerSource;
- (void)			writePostTriggerSetting;
- (void)			writeChannelEnabledMask;
- (void)            writeNumberBLTEvents:(BOOL)enable;
- (void)            writeEnableBerr:(BOOL)enable;
- (void)			writeOverUnderThresholds;

#pragma mark ***Register - Register specific routines
- (unsigned short) selectedRegIndex;
- (void) setSelectedRegIndex:(unsigned short) anIndex;
- (NSString*) 		getRegisterName: (short) anIndex;
- (unsigned long) 	getAddressOffset: (short) anIndex;
- (short)			getAccessType: (short) anIndex;
- (BOOL)			dataReset: (short) anIndex;
- (BOOL)			swReset: (short) anIndex;
- (BOOL)			hwReset: (short) anIndex;
- (void)			writeThresholds;
- (unsigned short)	threshold:(unsigned short) aChnl;
- (void)			setThreshold:(unsigned short) aChnl withValue:(unsigned long) aValue;
- (void)			writeChan:(unsigned short)chan reg:(unsigned short) pReg sendValue:(unsigned long) pValue;
- (void)			readChan:(unsigned short)chan reg:(unsigned short) pReg returnValue:(unsigned long*) pValue;
- (void)			writeDacs;
- (void)			writeDac:(unsigned short) pChan;
- (float)			convertDacToVolts:(unsigned short)aDacValue;
- (unsigned short)	convertVoltsToDac:(float)aVoltage;
- (void)			writeThreshold:(unsigned short) pChan;
- (void)			readOverUnderThresholds;
- (void)			writeBufferOrganization;

#pragma mark •••DataTaker
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (unsigned long)	dataId;
- (void)			setDataId: (unsigned long) DataId;
- (void)			setDataIds:(id)assigner;
- (void)			syncDataIdsWith:(id)anotherShaper;
- (NSDictionary*)	dataRecordDescription;
- (void)			runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;
- (void)			takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void)			runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo;
- (BOOL)			bumpRateFromDecodeStage:(short)channel;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

extern NSString* ORCaen1724ModelEventSizeChanged;
extern NSString* ORCaen1724SelectedRegIndexChanged;
extern NSString* ORCaen1724SelectedChannelChanged;
extern NSString* ORCaen1724WriteValueChanged;
extern NSString* ORCaen1724ModelEnabledMaskChanged;
extern NSString* ORCaen1724ModelPostTriggerSettingChanged;
extern NSString* ORCaen1724ModelTriggerSourceMaskChanged;
extern NSString* ORCaen1724ModelCoincidenceLevelChanged;
extern NSString* ORCaen1724ModelAcquisitionModeChanged;
extern NSString* ORCaen1724ModelCountAllTriggersChanged;
extern NSString* ORCaen1724ModelCustomSizeChanged;
extern NSString* ORCaen1724ModelIsFixedSizeChanged;
extern NSString* ORCaen1724ModelChannelConfigMaskChanged;
extern NSString* ORCaen1724ModelNumberBLTEventsToReadoutChanged;
extern NSString* ORCaen1724ChnlDacChanged;
extern NSString* ORCaen1724OverUnderThresholdChanged;
extern NSString* ORCaen1724Chnl;
extern NSString* ORCaen1724ChnlThresholdChanged;
extern NSString* ORCaen1724SelectedRegIndexChanged;
extern NSString* ORCaen1724SelectedRegIndexChanged;
extern NSString* ORCaen1724SelectedChannelChanged;
extern NSString* ORCaen1724WriteValueChanged;
extern NSString* ORCaen1724BasicLock;
extern NSString* ORCaen1724SettingsLock;
extern NSString* ORCaen1724RateGroupChanged;
extern NSString* ORCaen1724ModelBufferCheckChanged;

//the decoder concrete decoder class
@interface ORCaen1724DecoderForCAEN : ORCaenDataDecoder
{}
- (NSString*) identifier;
@end

