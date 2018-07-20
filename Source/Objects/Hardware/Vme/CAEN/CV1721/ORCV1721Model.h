//
//ORCV1721Model.h
//Orca
//
//Created by Mark Howe on Mon Apr 14 2008.
//Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//
//-------------------------------------------------------------
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
	uint32_t 	addressOffset;
	short			accessType;
} CV1721RegisterNamesStruct; 

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
	kEventStored,			//0x812C
	kSetMonitorDAC,			//0x8138
	kBoardInfo,				//0x8140
	kMonitorMode,			//0x8144
	kEventSize,				//0x814C
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
@interface ORCV1721Model : ORVmeIOCard <ORDataTaker,ORHWWizard,ORHWRamping>
{
	uint32_t   dataId;
	unsigned short  selectedRegIndex;
    unsigned short  selectedChannel;
    uint32_t   writeValue;
	unsigned short  thresholds[8];
	unsigned short	dac[8];
	unsigned short	overUnderThreshold[8];
    unsigned short	channelConfigMask;
    uint32_t	customSize;
	BOOL		isCustomSize;
	BOOL		isFixedSize;
    BOOL			countAllTriggers;
    unsigned short	acquisitionMode;
    unsigned short  coincidenceLevel;
    uint32_t   triggerSourceMask;
	uint32_t   triggerOutMask;
	uint32_t   frontPanelControlMask;
    uint32_t	postTriggerSetting;
    unsigned short	enabledMask;
	ORRateGroup*	waveFormRateGroup;
	uint32_t 	waveFormCount[8];
    int				bufferState;
	ORAlarm*        bufferFullAlarm;
	int				bufferEmptyCount;
	BOOL			isRunning;
    int				eventSize;
    uint32_t   numberBLTEventsToReadout;
	
	//cached variables, valid only during running
	uint32_t    statusReg;
	uint32_t   location;
	uint32_t	eventSizeReg;
	uint32_t	dataReg;
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
- (uint32_t) 	writeValue;
- (void)			setWriteValue: (uint32_t) anIndex;
- (unsigned short)	enabledMask;
- (void)			setEnabledMask:(unsigned short)aEnabledMask;
- (uint32_t)	postTriggerSetting;
- (void)			setPostTriggerSetting:(uint32_t)aPostTriggerSetting;
- (uint32_t)	triggerSourceMask;
- (void)			setTriggerSourceMask:(uint32_t)aTriggerSourceMask;
- (uint32_t)	triggerOutMask;
- (void)			setTriggerOutMask:(uint32_t)aTriggerOutMask;
- (uint32_t)	frontPanelControlMask;
- (void)			setFrontPanelControlMask:(uint32_t)aFrontPanelControlMask;
- (unsigned short)	coincidenceLevel;
- (void)			setCoincidenceLevel:(unsigned short)aCoincidenceLevel;
- (unsigned short)	acquisitionMode;
- (void)			setAcquisitionMode:(unsigned short)aMode;
- (BOOL)			countAllTriggers;
- (void)			setCountAllTriggers:(BOOL)aCountAllTriggers;
- (BOOL)		isCustomSize;
- (void)		setIsCustomSize:(BOOL)aIsCustomSize;
- (BOOL)		isFixedSize;
- (void)		setIsFixedSize:(BOOL)aIsFixedSize;
- (uint32_t)	customSize;
- (void)			setCustomSize:(uint32_t)aCustomSize;
- (unsigned short)	channelConfigMask;
- (void)			setChannelConfigMask:(unsigned short)aChannelConfigMask;
- (unsigned short)	dac:(unsigned short) aChnl;
- (void)			setDac:(unsigned short) aChnl withValue:(unsigned short) aValue;
- (unsigned short)	overUnderThreshold:(unsigned short) aChnl;
- (void)			setOverUnderThreshold:(unsigned short) aChnl withValue:(unsigned short) aValue;
- (uint32_t)	numberBLTEventsToReadout;
- (void)			setNumberBLTEventsToReadout:(uint32_t)aNumberOfBLTEvents;

#pragma mark ***Register - General routines
- (uint32_t)   probeBoard;
- (void)			read;
- (void)			write;
- (void)			report;
- (void)			read:(unsigned short) pReg returnValue:(uint32_t*) pValue;
- (void)			write:(unsigned short) pReg sendValue:(uint32_t) pValue;
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
- (void)			writeTriggerOut;
- (void)			writeFrontPanelControl;
- (void)			readFrontPanelControl;
- (void)			writePostTriggerSetting;
- (void)			writeChannelEnabledMask;
- (void)            writeNumberBLTEvents:(BOOL)enable;
- (void)            writeEnableBerr:(BOOL)enable;
- (void)			writeOverUnderThresholds;

#pragma mark ***Register - Register specific routines
- (unsigned short) selectedRegIndex;
- (void) setSelectedRegIndex:(unsigned short) anIndex;
- (NSString*) 		getRegisterName: (short) anIndex;
- (uint32_t) 	getAddressOffset: (short) anIndex;
- (short)			getAccessType: (short) anIndex;
- (BOOL)			dataReset: (short) anIndex;
- (BOOL)			swReset: (short) anIndex;
- (BOOL)			hwReset: (short) anIndex;
- (void)			writeThresholds;
- (unsigned short)	threshold:(unsigned short) aChnl;
- (void)			setThreshold:(unsigned short) aChnl withValue:(uint32_t) aValue;
- (void)			writeChan:(unsigned short)chan reg:(unsigned short) pReg sendValue:(uint32_t) pValue;
- (void)			readChan:(unsigned short)chan reg:(unsigned short) pReg returnValue:(uint32_t*) pValue;
- (void)			writeDacs;
- (void)			writeDac:(unsigned short) pChan;
- (float)			convertDacToVolts:(unsigned short)aDacValue;
- (unsigned short)	convertVoltsToDac:(float)aVoltage;
- (void)			writeThreshold:(unsigned short) pChan;
- (void)			readOverUnderThresholds;
- (void)			writeBufferOrganization;

#pragma mark •••DataTaker
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index;
- (uint32_t)	dataId;
- (void)			setDataId: (uint32_t) DataId;
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

extern NSString* ORCV1721ModelEventSizeChanged;
extern NSString* ORCV1721SelectedRegIndexChanged;
extern NSString* ORCV1721SelectedChannelChanged;
extern NSString* ORCV1721WriteValueChanged;
extern NSString* ORCV1721ModelEnabledMaskChanged;
extern NSString* ORCV1721ModelPostTriggerSettingChanged;
extern NSString* ORCV1721ModelTriggerSourceMaskChanged;
extern NSString* ORCV1721ModelTriggerOutMaskChanged;
extern NSString* ORCV1721ModelFrontPanelControlMaskChanged;
extern NSString* ORCV1721ModelCoincidenceLevelChanged;
extern NSString* ORCV1721ModelAcquisitionModeChanged;
extern NSString* ORCV1721ModelCountAllTriggersChanged;
extern NSString* ORCV1721ModelCustomSizeChanged;
extern NSString* ORCV1721ModelIsCustomSizeChanged;
extern NSString* ORCV1721ModelIsFixedSizeChanged;
extern NSString* ORCV1721ModelChannelConfigMaskChanged;
extern NSString* ORCV1721ModelNumberBLTEventsToReadoutChanged;
extern NSString* ORCV1721ChnlDacChanged;
extern NSString* ORCV1721OverUnderThresholdChanged;
extern NSString* ORCV1721Chnl;
extern NSString* ORCV1721ChnlThresholdChanged;
extern NSString* ORCV1721SelectedRegIndexChanged;
extern NSString* ORCV1721SelectedRegIndexChanged;
extern NSString* ORCV1721SelectedChannelChanged;
extern NSString* ORCV1721WriteValueChanged;
extern NSString* ORCV1721BasicLock;
extern NSString* ORCV1721SettingsLock;
extern NSString* ORCV1721RateGroupChanged;
extern NSString* ORCV1721ModelBufferCheckChanged;
//the decoder concrete decoder class
@interface ORCV1721DecoderForCAEN : ORCaenDataDecoder
{}
- (NSString*) identifier;
@end

