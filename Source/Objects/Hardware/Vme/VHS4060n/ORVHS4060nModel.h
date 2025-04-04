// ORVHS4060nModel.h
// Orca
//
//  Created by Sam Meijer onWed 30 Oct, 2019
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and Department sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark Imported Files

#import "ORVmeIOCard.h"
#import "SBC_Config.h"


#pragma mark Register Definitions
enum {
	kModuleStatus,	
	kModuleControl,
	kModuleEventStatus,			
	kModuleEventMask,			 	
	kModuleEventChannelStatus,		
	kModuleEventChannelMask,    
	kModuleEventGroupStatus,		
	kModuleEventGroupMask,		
	kVoltageRampSpeed,			 	
	kCurrentRampSpeed,				
	kVoltageMax,				
	kCurrentMax,				
	kSupplyP5,					
	kSupplyP12,			 	
	kSupplyN12,			 	
	kTemperature,		 	
	kSerialNumber,					
	kFirmwareRelease,			
	kPlacedChannels,			
	kDeviceClass,				   
	kChannel1StartOffset,
	kChannel2StartOffset,
	kChannel3StartOffset,
	kChannel4StartOffset,
	kChannel5StartOffset,
	kChannel6StartOffset,
	kChannel7StartOffset,
	kChannel8StartOffset,
	kChannel9StartOffset,
	kChannel10StartOffset,
	kChannel11StartOffset,
	kChannel12StartOffset,
	kNumberOfVHS4060nRegisters			//must be last
};

enum {
	kChannelStatus,
	kChannelControl,
	kChannelEventStatus,
	kChannelEventMask,
	kVoltageSet,
	kCurrentSetTrip,
	kVoltageMeasure,
	kCurrentMeasure,
	kVoltageBounds,
	kCurrentBounds,
	kVoltageNominal,
	kCurrentNominal,
	kNumberOfVHS4060nChannelRegisters
};

#define kNumVHS4060nChannels		 4
#define kVHS403DataRecordLength  (3 + (kNumVHS4060nChannels*kNumVHS4060nChannels))

//kModuleStatus bits
#define kIsCmdComplete				(0x1<<7)
#define kModuleWithoutFailure		(0x1<<8)
#define kAllChannelsStable			(0x1<<9)
#define kSafetyLoopClosed			(0x1<<10)
#define kAnyEventIsActiveAndMaskSet	(0x1<<11)
#define kModuleInStateGood			(0x1<<12)
#define kPowerSupplyGood			(0x1<<13)
#define kTemperatureGood			(0x1<<14)

//kModuleControl bits
#define kSpecialMode				(0x1<<0)
#define kDoClear					(0x1<<6)
#define kIntLevel					(0x7<<8)
#define kSetAdjustment				(0x1<<12)
#define kSetKillEnable				(0x1<<14)

//kModuleEventStatus bits
#define kEventSafetyLoopOpen		(0x1<<10)
#define kAtLeastSupplyNotGood		(0x1<<13)
#define kTemperatureAbove55C		(0x1<<14)

//kModuleEventStatus bits
#define kEventSafetyLoopOpenMask	(0x1<<10)
#define kAtLeastSupplyNotGoodMask	(0x1<<13)
#define kTemperatureAbove55CMask	(0x1<<14)

//Channel Status bits
#define kInputError					(0x1<<2)
#define kIsOn						(0x1<<3)
#define kIsRamping					(0x1<<4)
#define kIsEmergency				(0x1<<5)
#define kIsControlledCurrent		(0x1<<6)
#define kIsControlledVoltage		(0x1<<7)
#define kIsCurrentBoundsExceeded	(0x1<<10)
#define kIsVoltageBoundsExceeded	(0x1<<11)
#define kIsExtInhibit				(0x1<<12)
#define kIsTripSet					(0x1<<13)
#define kIsCurrentLimitExceeded		(0x1<<14)
#define kIsVoltageLimitExceeded		(0x1<<15)


@interface ORVHS4060nModel :  ORVmeIOCard
{
    @private
		unsigned short moduleStatus;
		unsigned short moduleControl;
		unsigned short moduleEventStatus;
		unsigned short moduleEventMask;
		unsigned short moduleEventChannelStatus;
		unsigned short moduleEventChannelMask;
		unsigned short moduleEventGroupMask;
		unsigned short moduleEventGroupStatus;
		float voltageMax;
		float currentMax;
		float voltageRampSpeed;
		float supplyP5;
		float supplyP12;
		float supplyN12;
		float temperature;	

		float voltageSet[kNumVHS4060nChannels];
		float voltageMeasure[kNumVHS4060nChannels];
		float currentMeasure[kNumVHS4060nChannels];
		float currentSet[kNumVHS4060nChannels];
		float voltageNominal[kNumVHS4060nChannels];
		float currentNominal[kNumVHS4060nChannels];
		float voltageBounds[kNumVHS4060nChannels];
		float currentBounds[kNumVHS4060nChannels];
		unsigned short channelStatus[kNumVHS4060nChannels];
		unsigned short channelEventStatus[kNumVHS4060nChannels];
	
		int pollTime;
		uint32_t dataId;
		BOOL timeOutError;
		BOOL statusChanged; 
		BOOL pollingError;
		BOOL killEnabled;
		BOOL fineAdjustEnabled;
}

#pragma mark Accessors
- (BOOL) fineAdjustEnabled;
- (void) setFineAdjustEnabled:(BOOL)aFineAdjustEnabled;
- (BOOL) killEnabled;
- (void) setKillEnabled:(BOOL)aKillEnabled;
- (float) temperature;
- (void) setTemperature:(float)aTemperature;
- (float) supplyN12;
- (void) setSupplyN12:(float)aSupplyN12;
- (float) supplyP12;
- (void) setSupplyP12:(float)aSupplyP12;
- (float) supplyP5;
- (void) setSupplyP5:(float)aSupplyP5;
- (float) voltageRampSpeed;
- (void) setVoltageRampSpeed:(float)aVoltageRampSpeed;
- (float) voltageMax;
- (void) setVoltageMax:(float)aValue;
- (float) currentMax;
- (void) setCurrentMax:(float)aValue;

- (unsigned short) moduleEventGroupStatus;
- (void) setModuleEventGroupStatus:(unsigned short)aModuleEventGroupStatus;
- (unsigned short) moduleEventGroupMask;
- (void) setModuleEventGroupMask:(unsigned short)aModuleEventGroupMask;
- (unsigned short) moduleEventChannelMask;
- (void) setModuleEventChannelMask:(unsigned short)aModuleEventChannelMask;
- (unsigned short) moduleEventChannelStatus;
- (void) setModuleEventChannelStatus:(unsigned short)aModuleEventChannelStatus;
- (unsigned short) moduleEventMask;
- (void) setModuleEventMask:(unsigned short)aModuleEventMask;
- (unsigned short) moduleEventStatus;
- (void) setModuleEventStatus:(unsigned short)aModuleEventStatus;
- (unsigned short) moduleControl;
- (void) setModuleControl:(unsigned short)aModuleControl;
- (unsigned short) moduleStatus;
- (void) setModuleStatus:(unsigned short)aModuleStatus;

- (float) voltageSet:(unsigned short) aChan;
- (void)  setVoltageSet:(unsigned short)aChannel withValue:(float) aValue;
- (float) voltageMeasure:(unsigned short) aChan;
- (void)  setVoltageMeasure:(unsigned short)aChannel withValue:(float) aValue;
- (float) currentMeasure:(unsigned short) aChan;
- (void)  setCurrentMeasure:(unsigned short) aChan withValue:(float) aValue;
- (float) currentSet:(unsigned short) aChan;
- (void)  setCurrentSet:(unsigned short) aChan withValue:(float) aValue;
- (float) voltageNominal:(unsigned short) aChan;
- (void)  setVoltageNominal:(unsigned short)aChannel withValue:(float) aValue;
- (float) currentNominal:(unsigned short) aChan;
- (void)  setCurrentNominal:(unsigned short) aChan withValue:(float) aValue;
- (void) setChannelStatus:(unsigned short)aChan withValue:(unsigned short)aValue;
- (unsigned short) channelStatus:(unsigned short)aChan;
- (unsigned short) channelEventStatus:(unsigned short)aChan;
- (void) setChannelEventStatus:(unsigned short)aChan withValue:(unsigned short)aValue;
- (float) currentBounds:(unsigned short) aChan;
- (void) setCurrentBounds:(unsigned short) aChan withValue:(float) aCurrent;
- (float) voltageBounds:(unsigned short) aChan;
- (void) setVoltageBounds:(unsigned short) aChan withValue:(float) aVoltage;

- (BOOL) pollingError;
- (void) setPollingError:(BOOL)aPollingError;
- (void) setTimeErrorState:(BOOL)aState;
- (int) pollTime;
- (void) setPollTime:(int)aPollTime;
- (float) currentBounds:(unsigned short) aChan;
- (void)  setCurrentBounds:(unsigned short) aChan withValue:(float) aCurrent;

- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;

#pragma mark HW Access
- (void) readModuleInfo;
- (float) readTemperature;
- (float) readSupplyN12;
- (float) readSupplyP12;
- (float) readSupplyP5;
- (float) readVoltageMax;
- (float) readCurrentMax;
- (void) writeVoltageRampSpeed;
- (unsigned short) readModuleStatus;
- (unsigned short) readModuleEventStatus;
- (void) writeModuleControl;
- (void) doClear;
- (void) loadModuleValues;

- (void) toggleHVOnOff:(unsigned short)aChannel;
- (unsigned short) readChannelStatus:(unsigned short)aChan;
- (float) readVoltageMeasure:(unsigned short)aChan;
- (float) readCurrentMeasure:(unsigned short)aChan;
- (float) readVoltageNominal:(unsigned short)aChan;
- (float) readCurrentNominal:(unsigned short)aChan;
- (void) writeVoltageSet:(unsigned short)aChannel;
- (void) writeCurrentSet:(unsigned short)aChannel;
- (void) writeVoltageBounds:(unsigned short)aChannel;
- (void) writeCurrentBounds:(unsigned short)aChannel;
- (void) turnOn:(unsigned short)aChannel; 
- (void) turnOff:(unsigned short)aChannel;
- (void) panicToZero:(unsigned short)aChan;
- (void) stopRamp:(unsigned short)aChan;
- (void) loadValues:(unsigned short)aChan;
- (void) writeEmergency:(unsigned short)aChan;
- (void) clearEmergency:(unsigned short)aChan; 

- (BOOL) isVoltageOutOfBounds:(unsigned short)aChan;
- (BOOL) isCurrentOutOfBounds:(unsigned short)aChan;
- (BOOL) isVoltageLimitExceeded:(unsigned short)aChan;
- (BOOL) isCurrentLimitExceeded:(unsigned short)aChan;
- (BOOL) isControlledVoltage:(unsigned short)aChan;
- (BOOL) isControlledCurrent:(unsigned short)aChan;
- (BOOL) isEmergency:(unsigned short)aChan;
- (BOOL) isInputError:(unsigned short)aChan;
- (BOOL) isRamping:(unsigned short)aChan;
- (BOOL) hvPower:(unsigned short)aChan;
- (BOOL) isExternInhibit:(unsigned short)aChan;
- (BOOL) isTripSet:(unsigned short)aChan;

#pragma mark RecordShipper
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) shipVoltageRecords;

#pragma mark Helpers
- (float) readModuleRegIndex:(int)anIndex;
- (void)  writeModuleRegIndex:(int)anIndex withFloatValue:(float)aFloatValue;
- (void)  writeChannel:(int)aChannel regIndex:(int)anIndex withFloatValue:(float)floatValue;
- (float) readChannel:(int)aChannel regIndex:(int)anIndex;
- (NSString*) channelStatusString:(unsigned short)aChannel;


#pragma mark Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

#pragma mark External String Definitions
extern NSString* ORVHS4060nModelFineAdjustEnabledChanged;
extern NSString* ORVHS4060nModelKillEnabledChanged;
extern NSString* ORVHS4060nTemperatureChanged;
extern NSString* ORVHS4060nSupplyN12Changed;
extern NSString* ORVHS4060nSupplyP12Changed;
extern NSString* ORVHS4060nSupplyP5Changed;
extern NSString* ORVHS4060nVoltageRampSpeedChanged;
extern NSString* ORVHS4060nModuleEventGroupStatusChanged;
extern NSString* ORVHS4060nModuleEventGroupMaskChanged;
extern NSString* ORVHS4060nModuleEventChannelMaskChanged;
extern NSString* ORVHS4060nModuleEventChannelStatusChanged;
extern NSString* ORVHS4060nModuleEventMaskChanged;
extern NSString* ORVHS4060nModuleEventStatusChanged;
extern NSString* ORVHS4060nModuleControlChanged;
extern NSString* ORVHS4060nModuleStatusChanged;
extern NSString* ORVHS4060nPollingErrorChanged;
extern NSString* ORVHS4060nChannelStatusChanged;
extern NSString* ORVHS4060nChannelEventStatusChanged;
extern NSString* ORVHS4060nChan;
extern NSString* ORVHS4060nSettingsLock;
extern NSString* ORVHS4060nSetVoltageChanged;
extern NSString* ORVHS4060nPollTimeChanged;
extern NSString* ORVHS4060nTimeOutErrorChanged;
extern NSString* ORVHS4060nCurrentMeasureChanged;
extern NSString* ORVHS4060nVoltageSetChanged;
extern NSString* ORVHS4060nVoltageMeasureChanged;
extern NSString* ORVHS4060nCurrentNominalChanged;
extern NSString* ORVHS4060nVoltageNominalChanged;
extern NSString* ORVHS4060nCurrentBoundsChanged;
extern NSString* ORVHS4060nVoltageBoundsChanged;
extern NSString* ORVHS4060nCurrentMaxChanged;
extern NSString* ORVHS4060nVoltageMaxChanged;
extern NSString* ORVHS4060nCurrentSetChanged;
