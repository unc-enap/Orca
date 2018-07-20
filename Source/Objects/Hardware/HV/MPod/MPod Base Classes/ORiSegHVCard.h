//
//  ORMPodiSegHVCardCard.h
//  Orca
//
//  Created by Mark Howe on Wed Feb 2,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ¥¥¥Imported Files
#import "ORMPodCard.h"
#import "ORHWWizard.h"

@class ORTimeRate;
@class ORAlarm;
@class ORDataPacket;

#define kPositivePolarity 1
#define kNegativePolarity 0

enum {
	kiSegHVCardOutputOff                    = 0,
	kiSegHVCardOutputOn                     = 1,
	kiSegHVCardOutputResetEmergencyOff      = 2,
	kiSegHVCardOutputSetEmergencyOff        = 3,
	kiSegHVCardOutputClearEvents            = 10,
};

enum {
	outputOnMask						= (0x1<<0), 
	outputInhibitMask					= (0x1<<1), 
	outputFailureMinSenseVoltageMask	= (0x1<<2),
	outputFailureMaxSenseVoltageMask	= (0x1<<3),
	
	outputFailureMaxTerminalVoltageMask = (0x1<<4),
	outputFailureMaxCurrentMask			= (0x1<<5),
	outputFailureMaxTemperatureMask		= (0x1<<6),
	outputFailureMaxPowerMask			= (0x1<<7),
	
	outputFailureTimeoutMask			= (0x1<<9),
	outputCurrentLimitedMask			= (0x1<<10), 
	outputRampUpMask					= (0x1<<11),
	outputRampDownMask					= (0x1<<12), 
	
	outputEnableKillMask				= (0x1<<13),
	outputEmergencyOffMask				= (0x1<<14)
};

enum{
    moduleEventPowerFail                = (0x1<<0),
    
    moduleEventLiveInsertion            = (0x1<<2),

	moduleEventService                  = (0x1<<4),
	moduleHardwareLimitVoltageNotGood   = (0x1<<5),
    moduleEventInputError               = (0x1<<6),
    
    moduleEventSafetyLoopNotGood        = (0x1<<10),
    
    moduleEventSupplyNotGood            = (0x1<<13),
    moduleEventTemperatureNotGood       = (0x1<<14)
};

#define kiSegHVCardProblemMask (outputFailureMaxTerminalVoltageMask | outputFailureMaxCurrentMask | outputFailureMaxTemperatureMask | outputFailureMaxPowerMask | outputFailureTimeoutMask | outputCurrentLimitedMask)

@interface ORiSegHVCard : ORMPodCard <ORHWWizard>
{
  @protected
    uint32_t	exceptionCount;
	uint32_t   dataId;
    short			hwGoal[16];		//value to send to hw
    short			target[16];		//input by user
    float			riseRate;
	NSDictionary*	rdParams[16];
    NSDictionary*   modParams;
    int				selectedChannel;
    float			maxCurrent[16];
    int             maxVoltage[16];
    NSString*       customInfo[16];
	NSString*       chanName[16];
	ORTimeRate*		voltageHistory[16];
	ORTimeRate*		currentHistory[16];
    BOOL			shipRecords;
    NSMutableDictionary* hvConstraints;
    ORAlarm*        safetyLoopNotGoodAlarm;
    BOOL            doNotPostSafetyLoopAlarm;
    NSDate*         lastHistoryPost;
}

#pragma mark ***Initialization
- (void) makeCurrentHistory:(short)index;
- (id) init;
- (void) dealloc;
- (NSString*) imageName;
- (void) setUpImage;
- (void) makeMainController;
- (BOOL) polarity;
- (void) registerNotificationObservers;
- (void) runStarted:(NSNotification*)aNote;
- (void) productionModeChanged:(NSNotification*)aNote;

#pragma mark ***Accessors
- (id)				adapter;
- (uint32_t)   exceptionCount;
- (void)			incExceptionCount;
- (void)			clearExceptionCount;
- (NSString*) settingsLock;
- (NSString*) name;
- (BOOL)	shipRecords;
- (void)	setShipRecords:(BOOL)aShipRecords;
- (int)     maxVoltage:(short)chan;
- (void)	setMaxVoltage:(short)chan withValue:(int)aValue;
- (NSString*) customInfo:(short)chan;
- (void) setCustomInfo:(short)chan string:(NSString*)aString;
- (NSString*) chanName:(short)chan;
- (void)	setChan:(short)chan name:(NSString*)aName;
- (int)     supplyVoltageLimit;
- (float)	maxCurrent:(short)chan;
- (void)	setMaxCurrent:(short)chan withValue:(float)aMaxCurrent;
- (int)		selectedChannel;
- (void)	setSelectedChannel:(int)aSelectedChannel;
- (int)		slotChannelValue:(int)aChannel;
- (int)		channel:(short)i readParamAsInt:(NSString*)name;
- (float)	channel:(short)i readParamAsFloat:(NSString*)name;
- (id)		channel:(short)i readParamAsObject:(NSString*)name;
- (id)		channel:(short)i readParamAsValue:(NSString*)name;
- (float)	riseRate;	
- (void)	setRiseRate:(float)aValue;
- (int)		hwGoal:(short)chan;	
- (void)	setHwGoal:(short)chan withValue:(int)aValue;
- (NSString*) hwGoalString:(short)chan;
- (int)		target:(short)chan;	
- (void)	setTarget:(short)chan withValue:(int)aValue;
- (void)	syncDialog;
- (void)	commitTargetsToHwGoals;
- (void)	commitTargetToHwGoal:(short)channel;
- (NSString*) channelState:(short)channel;
- (int)		numberChannelsOn;
- (uint32_t) channelStateMask;
- (int)		numberChannelsRamping;
- (int)		numberChannelsWithNonZeroVoltage;
- (int)		numberChannelsWithNonZeroHwGoal;
- (BOOL)	channelIsRamping:(short)chan;
- (uint32_t) failureEvents:(short)channel;
- (uint32_t) failureEvents;
- (uint32_t) moduleFailureEvents;
- (BOOL) channelInBounds:(short)aChan;
- (BOOL) isOn:(short)aChannel;
- (BOOL) hvOnAnyChannel;
- (void) setRdParamsFrom:(NSDictionary*)aDictionary;
- (NSDictionary*) rdParams:(int)i;
- (NSDictionary*) modParams;
- (BOOL) constraintsInPlace;
- (void) requestMaxValues:(int)aChannel;
- (void) requestCustomInfo:(int)aChannel;
- (NSString*) getModuleString;

- (BOOL) doNotPostSafetyLoopAlarm;
- (void) setDoNotPostSafetyLoopAlarm:(BOOL)aState;

#pragma mark ¥¥¥Data Records
- (uint32_t) dataId;
- (void) setDataId: (uint32_t) DataId;
- (void) setDataIds:(id)assigner;
- (void) syncDataIdsWith:(id)anotherShaper;
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (NSDictionary*) dataRecordDescription;

#pragma mark ***Polling
- (NSArray*) addChannelNumbersToParams:(NSArray*)someChannelParams;
- (NSArray*) addChannel:(int)i toParams:(NSArray*)someChannelParams;
- (void) processWriteResponseArray:(NSArray*)response;

#pragma mark ¥¥¥Hardware Access
- (void) loadValues:(short)channel;
- (void) writeVoltage:(short)channel;
- (void) writeVoltages;
- (void) writeMaxCurrents;
- (void) writeMaxCurrent:(short)channel;
- (void) writeRiseTime;
- (void) writeRiseTime:(float)aValue;
- (void) setPowerOn:(short)channel withValue:(BOOL)aValue;
- (void) turnChannelOn:(short)channel;
- (void) turnChannelOff:(short)channel;
- (void) panicChannel:(short)channel;
- (void) clearPanicChannel:(short)channel;
- (void) clearEventsChannel:(short)channel;
- (void) stopRamping:(short)channel;
- (void) rampToZero:(short)channel;
- (void) panic:(short)channel;

- (void) loadAllValues;
- (void) turnAllChannelsOn;
- (void) turnAllChannelsOff;
- (void) panicAllChannels;
- (void) clearAllPanicChannels;
- (void) clearAllEventsChannels;
- (void) stopAllRamping;
- (void) rampAllToZero;
- (void) panicAll;
- (void) clearModule;

#pragma mark ¥¥¥Trends
- (ORTimeRate*) voltageHistory:(short)index;
- (ORTimeRate*) currentHistory:(short)index;
- (void) shipDataRecords;

#pragma mark ¥¥¥Convenience Methods
- (float) voltage:(short)aChannel;
- (float) current:(short)aChannel;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cIntArray:(short*)anArray forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cFloatArray:(float*)anArray forKey:(NSString*)aKey;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cBoolArray:(BOOL*)anArray forKey:(NSString*)aKey;

#pragma mark ¥¥¥HW Wizard
- (NSArray*) wizardParameters;
- (int) numberOfChannels;
- (NSArray*) wizardSelections;

#pragma mark ¥¥¥Constraints
- (void) addHvConstraint:(NSString*)aName reason:(NSString*)aReason;
- (void) removeHvConstraint:(NSString*)aName;
- (NSDictionary*)hvConstraints;
- (NSString*) constraintReport;

@end

@interface NSObject (ORiSegHVCard)
- (BOOL) power;
- (void) pollHardware;
@end

extern NSString* ORiSegHVCardShipRecordsChanged;
extern NSString* ORiSegHVCardMaxVoltageChanged;
extern NSString* ORiSegHVCardMaxCurrentChanged;
extern NSString* ORiSegHVCardCustomInfoChanged;
extern NSString* ORiSegHVCardSelectedChannelChanged;
extern NSString* ORiSegHVCardRiseRateChanged;
extern NSString* ORiSegHVCardHwGoalChanged;
extern NSString* ORiSegHVCardTargetChanged;
extern NSString* ORiSegHVCardCurrentChanged;
extern NSString* ORiSegHVCardSettingsLock;
extern NSString* ORiSegHVCardOutputSwitchChanged;
extern NSString* ORiSegHVCardChannelReadParamsChanged;
extern NSString* ORiSegHVCardExceptionCountChanged;
extern NSString* ORiSegHVCardConstraintsChanged;
extern NSString* ORiSegHVCardRequestHVMaxValues;
extern NSString* ORiSegHVCardRequestCustomInfo;
extern NSString* ORiSegHVCardChanNameChanged;
extern NSString* ORiSegHVCardDoNotPostSafetyAlarmChanged;

