//
//  ORHV4032Supply.m
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
#import "ORHV4032Supply.h"
#import "ORHV4032Model.h"

#pragma mark ¥¥¥External Strings
NSString* ORHV4032SupplyIsPresentChanged				= @"ORHV4032SupplyIsPresentChanged";
NSString* ORHV4032SupplyId								= @"ORHV4032Supply Id";
NSString* ORHV4032SupplyControlChangedNotification		= @"ORHV4032SupplyControl Changed";
NSString* ORHV4032SupplyTargetChangedNotification		= @"ORHV4032SupplyTarget Changed";
NSString* ORHV4032SupplyDacChangedNotification			= @"ORHV4032SupplyDac Changed";
NSString* ORHV4032SupplyAdcChangedNotification			= @"ORHV4032SupplyAdc Changed";
NSString* ORHV4032SupplyRampTimeChangedNotification		= @"ORHV4032SupplyRampTime Changed";
NSString* ORHV4032SupplyCurrentChangedNotification		= @"ORHV4032SupplyCurrent Changed";
NSString* ORHV4032SupplyRampStateChangedNotification	= @"ORHV4032SupplyRampState Changed";
NSString* ORHV4032SupplyVoltageAdcOffsetChangedNotification = @"ORHV4032SupplyVoltageAdcOffsetChangedNotification";
NSString* ORHV4032SupplyVoltageAdcSlopeChangedNotification  = @"ORHV4032SupplyVoltageAdcSlopeChangedNotification";

#define kMaxCurrent 40
#define kMaxCurrentTime 4 
#define kMaxMismatchTime 4 

//defaults
#define kHVReadBackFullScale 6000.
#define kReadBackOffset 	0.


@implementation ORHV4032Supply
- (id) initWithOwner:(id)anOwner supplyNumber:(int)aSupplyId //designated initializer
{	
    self = [super init];
    
    owner = anOwner;	//don't retain the guardian
    supply = aSupplyId;
    
    rampTime 		= 300;
    voltageAdcOffset = kReadBackOffset;
    voltageAdcSlope  = kHVReadBackFullScale;
    
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [hvAdcDacMismatchAlarm clearAlarm];
    [hvAdcDacMismatchAlarm release];
    
    [hvHighCurrentAlarm clearAlarm];
    [hvHighCurrentAlarm release];
    
    [startHighCurrentTime release];
    [super dealloc];
}

#pragma mark ¥¥¥Accessors

- (BOOL) isPresent
{
    return isPresent;
}

- (void) setIsPresent:(BOOL)aIsPresent
{
    isPresent = aIsPresent;

	NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:self forKey:ORHV4032SupplyId];
	
	[[NSNotificationCenter defaultCenter]
			postNotificationName:ORHV4032SupplyIsPresentChanged
						  object: owner
						userInfo: userInfo];


}

- (void) setOwner:(id)anObj
{
    owner = anObj;
}
- (id)		owner
{
	return owner;
}

- (int) supply
{
	return supply;
}
- (void) setSupply:(int)newSupply
{
    supply = newSupply;    
}

- (int) controlled
{
	return controlled;
}
- (void) setControlled:(int)newControlled
{
    if(controlled!=newControlled){
        [[[owner undoManager] prepareWithInvocationTarget:self] setControlled:[self controlled]];
        
        controlled=newControlled;
        
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:self forKey:ORHV4032SupplyId];
        
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORHV4032SupplyControlChangedNotification
                              object: owner
                            userInfo: userInfo];
    }
}

- (int) targetVoltage
{
	return targetVoltage;
}
- (void) setTargetVoltage:(int)newTargetVoltage
{
    if(targetVoltage!=newTargetVoltage){
        
        [[[owner undoManager] prepareWithInvocationTarget:self] setTargetVoltage:[self targetVoltage]];
        
        if(newTargetVoltage> 4095)newTargetVoltage = 4095;
        if(newTargetVoltage<0)newTargetVoltage=0;
        
        targetVoltage=newTargetVoltage;
        
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:self forKey:ORHV4032SupplyId];
        
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORHV4032SupplyTargetChangedNotification
                              object: owner
                            userInfo: userInfo];
    }
}

- (int) dacValue
{
	return dacValue;
}

- (void) setDacValue:(int)newDacValue
{
    if(dacValue!=newDacValue){
        dacValue=newDacValue;
        
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:self forKey:ORHV4032SupplyId];
        
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORHV4032SupplyDacChangedNotification
                              object: owner
                            userInfo: userInfo];
    }
}
- (int) adcVoltage
{
	return adcVoltage;
}
- (void) setAdcVoltage:(int)newAdcVoltage
{
    if(adcVoltage!=newAdcVoltage){
        
        adcVoltage=newAdcVoltage;
        
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:self forKey:ORHV4032SupplyId];
        
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORHV4032SupplyAdcChangedNotification
                              object: owner
                            userInfo: userInfo];
    }
}

- (int) rampTime
{
    return rampTime;
}
- (void) setRampTime:(int)newRampTime
{
    if(rampTime!=newRampTime){
        [[[owner undoManager] prepareWithInvocationTarget:self] setRampTime:[self rampTime]];
        
        if(newRampTime<10)newRampTime=10;
        rampTime=newRampTime;
        
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:self forKey:ORHV4032SupplyId];
        
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORHV4032SupplyRampTimeChangedNotification
                              object: owner
                            userInfo: userInfo];
    }
}


- (int) current
{
	return current;
}

- (void) setCurrent:(int)newCurrent
{
    if(current!=newCurrent){
        current=newCurrent;
        
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:self forKey:ORHV4032SupplyId];
        
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORHV4032SupplyCurrentChangedNotification
                              object:owner
                            userInfo: userInfo];
    }
}

- (NSString*) state
{
    switch(rampState){
        case kHV4032Up: 	return @"Ramp Up";  break;
        case kHV4032Down: 	return @"Ramp Dn";  break;
        case kHV4032Done: 	return @"Done";     break;
        case kHV4032Zero: 	return @"Ramp Dn";  break;
        case kHV4032Panic: 	return @"Panic";    break;
       // case kHVWaitForAdc:     return @"Adc Wait"; break;
        default: 	
			if([owner hvOn])return @"On";	
			else return @"Off"; 
		break;
    }
}

- (int) rampState
{
	return rampState;
}

- (void) setRampState:(int)newState
{
    if(rampState!=newState){
        rampState = newState;
        
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:self forKey:ORHV4032SupplyId];
        
        [[NSNotificationCenter defaultCenter]
                postNotificationName:ORHV4032SupplyRampStateChangedNotification
                              object:owner
                            userInfo: userInfo];
    }
}


- (void) 	setActualDac:(int)aValue
{
    actualDac = aValue;
}

- (int) 	actualDac
{
    return actualDac;
}

- (float)voltageAdcOffset
{
    return voltageAdcOffset;
}

- (void)setVoltageAdcOffset:(float)aVoltageAdcOffset
{
    [[[owner undoManager] prepareWithInvocationTarget:self] setVoltageAdcOffset:[self voltageAdcOffset]];
    
    voltageAdcOffset = aVoltageAdcOffset;
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:self forKey:ORHV4032SupplyId];
    
    [[NSNotificationCenter defaultCenter]
	postNotificationName:ORHV4032SupplyVoltageAdcOffsetChangedNotification
                  object:owner
                userInfo: userInfo];
}

- (float)voltageAdcSlope
{
    
    return voltageAdcSlope;
}

- (void)setVoltageAdcSlope:(float)aVoltageAdcSlope
{
    [[[owner undoManager] prepareWithInvocationTarget:self] setVoltageAdcSlope:[self voltageAdcSlope]];
    
    voltageAdcSlope = aVoltageAdcSlope;
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:self forKey:ORHV4032SupplyId];
    
    [[NSNotificationCenter defaultCenter]
	postNotificationName:ORHV4032SupplyVoltageAdcSlopeChangedNotification
                  object:owner
                userInfo: userInfo];
    
    
}


- (BOOL) currentIsHigh:(id)checker pollingTime:(int)pollingTime
{
    if(([self current] > kMaxCurrent) && ([self adcVoltage] >0)){
        if(!wasHigh){
            wasHigh = YES;
            startHighCurrentTime = [[NSDate date] retain];
        }
        else {
            if(fabs([startHighCurrentTime timeIntervalSinceNow]) > kMaxCurrentTime){
                [startHighCurrentTime release];
                startHighCurrentTime = nil;
                wasHigh = NO;
                
                if(!hvHighCurrentAlarm){
                    NSString* alarmString = [NSString stringWithFormat:@"HV High Current (%d)",[self supply]];
                    hvHighCurrentAlarm = [[ORAlarm alloc] initWithName:alarmString severity:kHardwareAlarm];
                    [hvHighCurrentAlarm setHelpStringFromFile:@"HVHighCurrentHelp"];
                    [hvHighCurrentAlarm setAcknowledged:NO];
                }  
                //this alarm is posted by the high current condition, but can only be cleared by acknowledgment.
                [hvHighCurrentAlarm postAlarm];
                
                return YES;
            }
        }
        if(pollingTime>1 && wasHigh)[checker performSelector:@selector(checkCurrent:) withObject:self afterDelay:1];
    }
    else {
        [startHighCurrentTime release];
        startHighCurrentTime = nil;
        wasHigh = NO;
    }
    
    return NO;
}

- (BOOL) checkAdcDacMismatch:(id)checker pollingTime:(int)pollingTime
{
    float diff = abs([self adcVoltage] - [self dacValue]);
    if([self dacValue]>50 && diff>(.20*[self dacValue])){
        if(!wasMismatched){
            wasMismatched = YES;
            startMisMatchTime = [[NSDate date] retain];
        }
        else {
            if(fabs([startMisMatchTime timeIntervalSinceNow]) > kMaxMismatchTime){
                [startMisMatchTime release];
                startMisMatchTime = nil;
                wasMismatched = NO;
                
                if(!hvAdcDacMismatchAlarm){
                    NSString* alarmString = [NSString stringWithFormat:@"HV ADC DAC Mismatch (%d)",[self supply]];
                    hvAdcDacMismatchAlarm = [[ORAlarm alloc] initWithName:alarmString severity:kHardwareAlarm];
                    [hvAdcDacMismatchAlarm setSticky:YES];
                    //[hvAdcDacMismatchAlarm setHelpStringFromFile:@"HVHighCurrentHelp"];
                    [hvAdcDacMismatchAlarm setAcknowledged:NO];
                    [hvAdcDacMismatchAlarm postAlarm];
                }
                
                if([self rampState] == kHV4032Up){
                    [self  setRampState:kHV4032Idle];
                }
                
                return YES;
            }
        }
        if(pollingTime>1 && wasMismatched)[checker performSelector:@selector(checkAdcDacMismatch:) withObject:self afterDelay:1];
    }
    else {
        [startMisMatchTime release];
        startMisMatchTime = nil;
        wasMismatched = NO;
        if(hvAdcDacMismatchAlarm){
            [hvAdcDacMismatchAlarm clearAlarm];
            [hvAdcDacMismatchAlarm release];
            hvAdcDacMismatchAlarm = nil;
        }
        
    }
    return NO;
}


- (BOOL)    significantVoltagePresent
{
	return [self adcVoltage]>30;
}

#pragma mark ¥¥¥Archival
static NSString *ORHV4032SupplyOwner	  = @"ORHV4032Supply Owner";
static NSString *ORSupplyId		  = @"ORHV4032Supply Id";
static NSString *ORSupplyControlled 	  = @"ORHV4032Supply Controlled";
static NSString *ORSupplyRampTime         = @"ORHV4032Supply Ramp Time";
static NSString *ORSupplyTargetVoltage 	  = @"ORHV4032Supply Target Voltage";
static NSString *ORSupplyVoltageAdcOffset = @"ORHV4032Supply Volt adc offset";
static NSString *ORSupplyVoltageAdcSlope  = @"ORHV4032Supply Volt adc slope";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [self setOwner:[decoder decodeObjectForKey:ORHV4032SupplyOwner]];
    [[owner undoManager] disableUndoRegistration];
    
    [self setSupply:[decoder decodeIntForKey:ORSupplyId]];
    [self setControlled:[decoder decodeIntForKey:ORSupplyControlled]];
    [self setRampTime:[decoder decodeIntForKey:ORSupplyRampTime]];
    [self setTargetVoltage:[decoder decodeIntForKey:ORSupplyTargetVoltage]];
    [self setVoltageAdcOffset:[decoder decodeFloatForKey:ORSupplyVoltageAdcOffset]];
    [self setVoltageAdcSlope:[decoder decodeFloatForKey:ORSupplyVoltageAdcSlope]];
    
    if(voltageAdcSlope < .1){
        [self setVoltageAdcOffset:kReadBackOffset];
        [self setVoltageAdcSlope:kHVReadBackFullScale];
    }
    
    [[owner undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:owner forKey:ORHV4032SupplyOwner];
    [encoder encodeInteger:[self supply] forKey:ORSupplyId];
    [encoder encodeInteger:[self controlled] forKey:ORSupplyControlled];
    [encoder encodeInteger:[self rampTime] forKey:ORSupplyRampTime];
    [encoder encodeInteger:[self targetVoltage] forKey:ORSupplyTargetVoltage];
    [encoder encodeFloat:[self voltageAdcOffset] forKey:ORSupplyVoltageAdcOffset];
    [encoder encodeFloat:[self voltageAdcSlope] forKey:ORSupplyVoltageAdcSlope];
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class])             forKey:@"Class Name"];
    [objDictionary setObject:[NSNumber numberWithInt:supply]             forKey:@"supply"];
    [objDictionary setObject:[NSNumber numberWithInt:targetVoltage]      forKey:@"targetVoltage"];
    [objDictionary setObject:[NSNumber numberWithInt:adcVoltage]         forKey:@"adcVoltage"];
    [objDictionary setObject:[NSNumber numberWithFloat:voltageAdcSlope]  forKey:@"voltageAdcSlope"];
    [objDictionary setObject:[NSNumber numberWithFloat:voltageAdcOffset] forKey:@"voltageAdcOffset"];
    
    [dictionary setObject:objDictionary forKey:[NSString stringWithFormat:@"supply %d",supply]];
    
    
    return objDictionary;
}
//special archiving for the target values and dac values. There are kept separate from
//the regular document. these values are saved whenever there is change in the HV state.
static NSString *ORSupplyDacValue 	= @"ORHV4032Supply Dac Voltage";

- (void)loadHVParams:(NSCoder*)decoder
{	
    [[owner undoManager] disableUndoRegistration];
	
    [self setDacValue:(int)[decoder decodeIntegerForKey:[ORSupplyDacValue stringByAppendingFormat:@"%d",supply]]];
    
    [[owner undoManager] enableUndoRegistration];
}

- (void)saveHVParams:(NSCoder*)encoder
{
    [encoder encodeInt:[self dacValue] forKey:[ORSupplyDacValue stringByAppendingFormat:@"%d",supply]];
}


#pragma mark ¥¥¥Safety Check
- (BOOL) checkActualVsSetValues
{
    //check the DAC values against the ActualDac Values states
    //assumes that a hardware read has been done.
    int diff = abs(adcVoltage - dacValue);
    if(diff < 50)return YES; //close enough
    
    if(adcVoltage>0){
        float percentDiff = 1. - dacValue/(float)adcVoltage;
        if(percentDiff>.20)return NO;
        else return YES;
    }
    else return NO;
    
}

- (void) resolveActualVsSetValueProblem
{
    dacValue = adcVoltage;
}


@end
