//-------------------------------------------------------------------------
//  OREHS8240nModel.h
//
//  Created by James Browning on Tuesday Aug 23,2022
//-----------------------------------------------------------
//-------------------------------------------------------------
#pragma mark ***Imported Files

#import "ORiSegHVCard.h"

@class ORDetectorRamper;

@interface OREHS8240nModel : ORiSegHVCard
{
  @private
	NSMutableArray* rampers;
    short		tripTime[8];
    short		currentTripBehavior[8];
    short		outputFailureBehavior[8];
}

#pragma mark ***Initialization
- (NSString*) imageName;
- (void) makeMainController;

#pragma mark ***Accessors
- (void) setRampers:(NSMutableArray*)someRampers;
- (short)	outputFailureBehavior:(short)chan;
- (void)	setOutputFailureBehavior:(short)chan withValue:(short)aValue;
- (short)	currentTripBehavior:(short)chan;
- (void)	setCurrentTripBehavior:(short)chan withValue:(short)aValue;
- (short)	tripTime:(short)chan;
- (void)	setTripTime:(short)chan withValue:(short)aValue;
- (NSString*) settingsLock;
- (NSString*) name;
- (NSString*) behaviourString:(int)channel;
- (ORDetectorRamper*) ramper:(int)channel;
- (void) checkRamperCallBack:(NSDictionary*)userInfo;

#pragma mark •••Hardware Access
- (void) writeTripTime:(int)channel;
- (void) writeTripTimes;
- (void) writeSupervisorBehaviours;
- (void) writeSupervisorBehaviour:(int)channel;
- (void) loadAllValues;

#pragma mark •••Hardware Wizard
- (NSArray*) wizardSelections;
- (void) setStepWait:(int)i withValue:(int)aValue;
- (int) stepWait:(int)i;
- (void) setLowVoltageWait:(int)i withValue:(int)aValue;
- (int) lowVoltageWait:(int)i;
- (void) setLowVoltageThreshold:(int)i withValue:(int)aValue;
- (int) lowVoltageThreshold:(int)i;
- (void) setLowVoltageStep:(int)i withValue:(int)aValue;
- (int) lowVoltagestep:(int)i;
- (void) setVoltageStep:(int)i withValue:(int)aValue;
- (int) voltagestep:(int)i;
- (void) setMaxVoltage:(int)i withValue:(int)aValue;
- (int) maxVoltage:(int)i;
- (void) setMinVoltage:(int)i withValue:(int)aValue;
- (int) minVoltage:(int)i;
- (void) setStepRampEnabled:(int)i withValue:(int)aValue;
- (int) stepRampEnabled:(int)i;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;
@end

extern NSString* OREHS8240nModelOutputFailureBehaviorChanged;
extern NSString* OREHS8240nModelCurrentTripBehaviorChanged;
extern NSString* OREHS8240nModelSupervisorMaskChanged;
extern NSString* OREHS8240nModelTripTimeChanged;
extern NSString* OREHS8240nSettingsLock;
