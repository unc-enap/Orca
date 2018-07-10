// ORVHSC040nModel.h
// Orca
//
//  Created by Mark Howe on Mon Sept 13,2010.
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

#pragma mark •••Imported Files

#import "ORVmeIOCard.h"
#import "SBC_Config.h"


#pragma mark •••Register Definitions
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
	kNumberOfVHSC040nRegisters			//must be last
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
	kNumberOfVHSC040nChannelRegisters
};

#define kNumVHSC040nChannels		 12
#define kVHS403DataRecordLength  (3 + (kNumVHSC040nChannels*kNumVHSC040nChannels))

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


@interface ORVHSC040nModel :  ORVmeIOCard
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

		float voltageSet[kNumVHSC040nChannels];
		float voltageMeasure[kNumVHSC040nChannels];
		float currentMeasure[kNumVHSC040nChannels];
		float currentSet[kNumVHSC040nChannels];
		float voltageNominal[kNumVHSC040nChannels];
		float currentNominal[kNumVHSC040nChannels];
		float voltageBounds[kNumVHSC040nChannels];
		float currentBounds[kNumVHSC040nChannels];
		unsigned short channelStatus[kNumVHSC040nChannels];
		unsigned short channelEventStatus[kNumVHSC040nChannels];
	
		int pollTime;
		unsigned long dataId;
		BOOL timeOutError;
		BOOL statusChanged; 
		BOOL pollingError;
		BOOL killEnabled;
		BOOL fineAdjustEnabled;
}

#pragma mark •••Accessors
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

- (unsigned long) dataId;
- (void) setDataId: (unsigned long) DataId;

#pragma mark •••HW Access
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

#pragma mark •••RecordShipper
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) shipVoltageRecords;

#pragma mark •••Helpers
- (float) readModuleRegIndex:(int)anIndex;
- (void)  writeModuleRegIndex:(int)anIndex withFloatValue:(float)aFloatValue;
- (void)  writeChannel:(int)aChannel regIndex:(int)anIndex withFloatValue:(float)floatValue;
- (float) readChannel:(int)aChannel regIndex:(int)anIndex;
- (NSString*) channelStatusString:(unsigned short)aChannel;


#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

#pragma mark •••External String Definitions
extern NSString* ORVHSC040nModelFineAdjustEnabledChanged;
extern NSString* ORVHSC040nModelKillEnabledChanged;
extern NSString* ORVHSC040nTemperatureChanged;
extern NSString* ORVHSC040nSupplyN12Changed;
extern NSString* ORVHSC040nSupplyP12Changed;
extern NSString* ORVHSC040nSupplyP5Changed;
extern NSString* ORVHSC040nVoltageRampSpeedChanged;
extern NSString* ORVHSC040nModuleEventGroupStatusChanged;
extern NSString* ORVHSC040nModuleEventGroupMaskChanged;
extern NSString* ORVHSC040nModuleEventChannelMaskChanged;
extern NSString* ORVHSC040nModuleEventChannelStatusChanged;
extern NSString* ORVHSC040nModuleEventMaskChanged;
extern NSString* ORVHSC040nModuleEventStatusChanged;
extern NSString* ORVHSC040nModuleControlChanged;
extern NSString* ORVHSC040nModuleStatusChanged;
extern NSString* ORVHSC040nPollingErrorChanged;
extern NSString* ORVHSC040nChannelStatusChanged;
extern NSString* ORVHSC040nChannelEventStatusChanged;
extern NSString* ORVHSC040nChan;
extern NSString* ORVHSC040nSettingsLock;
extern NSString* ORVHSC040nSetVoltageChanged;
extern NSString* ORVHSC040nPollTimeChanged;
extern NSString* ORVHSC040nTimeOutErrorChanged;
extern NSString* ORVHSC040nCurrentMeasureChanged;
extern NSString* ORVHSC040nVoltageSetChanged;
extern NSString* ORVHSC040nVoltageMeasureChanged;
extern NSString* ORVHSC040nCurrentNominalChanged;
extern NSString* ORVHSC040nVoltageNominalChanged;
extern NSString* ORVHSC040nCurrentBoundsChanged;
extern NSString* ORVHSC040nVoltageBoundsChanged;
extern NSString* ORVHSC040nCurrentMaxChanged;
extern NSString* ORVHSC040nVoltageMaxChanged;
extern NSString* ORVHSC040nCurrentSetChanged;
