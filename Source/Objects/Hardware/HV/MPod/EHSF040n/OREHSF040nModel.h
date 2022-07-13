//
//  OREHS8240pModel.h
//  Orca
//
//  Created by James Browning on Tues June 2,2022
//-------------------------------------------------------------

#pragma mark ***Imported Files

#import "ORiSegHVCard.h"

@class ORDetectorRamper;

@interface OREHSF040nModel : ORiSegHVCard
{
  @private
	NSMutableArray* rampers;
    short		tripTime[16];
    short		currentTripBehavior[16];
    short		outputFailureBehavior[16];
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

extern NSString* OREHSF040nModelOutputFailureBehaviorChanged;
extern NSString* OREHSF040nModelCurrentTripBehaviorChanged;
extern NSString* OREHSF040nModelSupervisorMaskChanged;
extern NSString* OREHSF040nModelTripTimeChanged;
extern NSString* OREHSF040nSettingsLock;
