//
//  ORHV4032Supply.h
//  Orca
//
//  Created by Mark Howe on Wed May 21 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
@class ORHVSupply;

enum {
    kHV4032Idle,
    kHV4032Up,
	kHV4032Down,
	kHV4032Done,
    kHV4032Zero,
    kHV4032Panic,
    kkHVWaitForAdc,
    kHV4032Unknown,
    kHV4032NumStates //must be last
};


@interface ORHV4032Supply : NSObject {
    id 	 owner;
    int	 supply;
    BOOL controlled;
    int  targetVoltage;
    int  dacValue;
    int  adcVoltage;
    int	 current;
    int	 rampState;
    int  rampTime;
    int  actualDac;
    NSDate* startHighCurrentTime;
    NSDate* startMisMatchTime;
    BOOL wasHigh;
    BOOL wasMismatched;
    ORAlarm* hvAdcDacMismatchAlarm;
    ORAlarm* hvHighCurrentAlarm;
    float    voltageAdcOffset;
    float    voltageAdcSlope;
    BOOL	isPresent;
}

- (id) initWithOwner:(id)anOwner supplyNumber:(int)aSupplyId;

#pragma mark ¥¥¥Accessors
- (BOOL) isPresent;
- (void) setIsPresent:(BOOL)aIsPresent;
- (id)		owner;
- (void) 	setOwner:(id)anObj;
- (int) 	supply;
- (void) 	setSupply:(int)newSupply;
- (int) 	controlled;
- (void) 	setControlled:(int)newControlled;
- (int) 	targetVoltage;
- (void) 	setTargetVoltage:(int)newTargetVoltage;
- (int) 	dacValue;
- (void) 	setDacValue:(int)aValue;
- (int) 	adcVoltage;
- (void) 	setAdcVoltage:(int)newAdcVoltage;
- (int) 	rampTime;
- (void) 	setRampTime:(int)newRampType;
- (int) 	current;
- (void) 	setCurrent:(int)newCurrent;
- (NSString*) 	state;
- (void) 	setRampState:(int)newState;
- (int) 	rampState;
- (void) 	setActualDac:(int)aValue;
- (int) 	actualDac;
- (float)   voltageAdcOffset;
- (void)	setVoltageAdcOffset:(float)aVoltageAdcOffset;
- (float)   voltageAdcSlope;
- (void)	setVoltageAdcSlope:(float)aVoltageAdcSlope;
- (BOOL)    significantVoltagePresent;

#pragma mark ¥¥¥Archival
- (void)loadHVParams:(NSCoder*)decoder;
- (void)saveHVParams:(NSCoder*)encoder;

#pragma mark ¥¥¥Safety Check
- (BOOL) checkActualVsSetValues;
- (void) resolveActualVsSetValueProblem;
- (BOOL) currentIsHigh:(id)checker pollingTime:(int)pollingTime;
- (BOOL) checkAdcDacMismatch:(id)checker pollingTime:(int)pollingTime;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

@end

#pragma mark ¥¥¥External Strings
extern NSString* ORHV4032SupplyIsPresentChanged;
extern NSString* ORHV4032SupplyId;
extern NSString* ORHV4032SupplyControlChangedNotification;
extern NSString* ORHV4032SupplyTargetChangedNotification;
extern NSString* ORHV4032SupplyDacChangedNotification;
extern NSString* ORHV4032SupplyAdcChangedNotification;
extern NSString* ORHV4032SupplyRampTimeChangedNotification;
extern NSString* ORHV4032SupplyCurrentChangedNotification;
extern NSString* ORHV4032SupplyRampStateChangedNotification;
extern NSString* ORHV4032SupplyVoltageAdcOffsetChangedNotification;
extern NSString* ORHV4032SupplyVoltageAdcSlopeChangedNotification;

@interface NSObject (HVControl)
- (void) turnOnSupplies:(NSArray*)someSupplies state:(BOOL)aState;
- (void) writeDac:(int)aValue supply:(id)aSupply;
- (void) readAdc:(id)aSupply;
- (void) readCurrent:(id)aSupply;
- (void) getMainPowerState:(id)aSupply;
- (void) checkCurrent:(ORHVSupply*) aSupply;
@end
