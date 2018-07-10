//
//  ORHVSupply.h
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


enum {
    kHVRampIdle,
    kHVRampUp,
    kHVRampDown,
    kHVRampDone,
    kHVRampZero,
    kHVRampPanic,
    kHVWaitForAdc,
    kHVRampUnknown,
    kHVRampNumStates //must be last
};


@interface ORHVSupply : NSObject {
    id 	 owner;
    int	 supply;
    BOOL controlled;
    int  targetVoltage;
    int  dacValue;
    int  adcVoltage;
    int	 current;
    int	 rampState;
    int  rampTime;
    BOOL relay; 
    BOOL actualRelay; 
    BOOL supplyPower;
    int  actualDac;
    NSDate* startHighCurrentTime;
    NSDate* startMisMatchTime;
    BOOL wasHigh;
    BOOL wasMismatched;
    ORAlarm* hvAdcDacMismatchAlarm;
    ORAlarm* hvHighCurrentAlarm;
    float    voltageAdcOffset;
    float    voltageAdcSlope;
}

- (id) initWithOwner:(id)anOwner supplyNumber:(int)aSupplyId;

#pragma mark ¥¥¥Accessors
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
- (BOOL) 	relay;
- (void) 	setRelay:(BOOL)newRelay;
- (BOOL) 	actualRelay;
- (void) 	setActualRelay:(BOOL)newActualRelay;
- (BOOL)	supplyPower;
- (void)	setSupplyPower:(BOOL)aState;
- (void) 	setActualDac:(int)aValue;
- (int) 	actualDac;
- (float)   voltageAdcOffset;
- (void)	setVoltageAdcOffset:(float)aVoltageAdcOffset;
- (float)   voltageAdcSlope;
- (void)	setVoltageAdcSlope:(float)aVoltageAdcSlope;

#pragma mark ¥¥¥Archival
- (void)loadHVParams:(NSCoder*)decoder;
- (void)saveHVParams:(NSCoder*)encoder;

#pragma mark ¥¥¥Safety Check
- (BOOL) checkActualVsSetValues;
- (void) resolveActualVsSetValueProblem;
- (BOOL) currentIsHigh:(id)checker pollingTime:(int)pollingTime;
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary;

@end

#pragma mark ¥¥¥External Strings
extern NSString* ORHVSupplyId;
extern NSString* ORHVSupplyControlChangedNotification;
extern NSString* ORHVSupplyTargetChangedNotification;
extern NSString* ORHVSupplyDacChangedNotification;
extern NSString* ORHVSupplyAdcChangedNotification;
extern NSString* ORHVSupplyRampTimeChangedNotification;
extern NSString* ORHVSupplyCurrentChangedNotification;
extern NSString* ORHVSupplyRampStateChangedNotification;
extern NSString* ORHVSupplyActualRelayChangedNotification;
extern NSString* ORHVSupplyVoltageAdcOffsetChangedNotification;
extern NSString* ORHVSupplyVoltageAdcSlopeChangedNotification;

@interface NSObject (HVControl)
- (void) turnOnSupplies:(NSArray*)someSupplies state:(BOOL)aState;
- (void) writeDac:(int)aValue supply:(id)aSupply;
- (void) readAdc:(id)aSupply;
- (void) readCurrent:(id)aSupply;
- (void) getMainPowerState:(id)aSupply;
- (void) getActualRelayState:(id)aSupply;
- (unsigned long) readRelayMask;
- (unsigned long) lowPowerOn;
- (void) checkCurrent:(ORHVSupply*) aSupply;
- (BOOL) checkAdcDacMismatch:(id)checker pollingTime:(int)pollingTime;
- (void) checkAdcDacMismatch:(ORHVSupply*) aSupply;
@end
