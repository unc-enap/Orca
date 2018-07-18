//
//  ORDetectorRamper.m
//  Orca
//
//  Created by Mark Howe on Friday May 25,2012
//  Copyright (c) 2012 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
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

#import "ORDetectorRamper.h"
#import "ORAlarm.h"
#import "ORiSegHVCard.h"

NSString* ORDetectorRamperStepWaitChanged				= @"ORDetectorRamperStepWaitChanged";
NSString* ORDetectorRamperLowVoltageWaitChanged			= @"ORDetectorRamperLowVoltageWaitChanged";
NSString* ORDetectorRamperLowVoltageThresholdChanged	= @"ORDetectorRamperLowVoltageThresholdChanged";
NSString* ORDetectorRamperLowVoltageStepChanged			= @"ORDetectorRamperLowVoltageStepChanged";
NSString* ORDetectorRamperMaxVoltageChanged				= @"ORDetectorRamperMaxVoltageChanged";
NSString* ORDetectorRamperMinVoltageChanged				= @"ORDetectorRamperMinVoltageChanged";
NSString* ORDetectorRamperVoltageStepChanged			= @"ORDetectorRamperVoltageStepChanged";
NSString* ORDetectorRamperEnabledChanged				= @"ORDetectorRamperEnabledChanged";
NSString* ORDetectorRamperStateChanged					= @"ORDetectorRamperStateChanged";
NSString* ORDetectorRamperRunningChanged				= @"ORDetectorRamperRunningChanged";


@implementation ORDetectorRamper

@synthesize delegate, channel, stepWait, lowVoltageThreshold, enabled, state;
@synthesize voltageStep, lowVoltageWait, lowVoltageStep, maxVoltage, minVoltage;
@synthesize lastStepWaitTime, running, target, lastVoltageWaitTime;

#define kTolerance				2 //Volts
#define kCheckTime				20

#define kDetRamperIdle                  0
#define kDetRamperStartRamp				1
#define kDetRamperEmergencyOff			2
#define kDetRamperStepWaitForVoltage	3
#define kDetRamperStepToNextVoltage		4
#define kDetRamperStepWait              5
#define kDetRamperDone                  6
#define kDetRamperNoChangeError         7


- (id) initWithDelegate:(id)aDelegate channel:(int)aChannel
{
	self = [super init];
	self.delegate = aDelegate;
	self.channel = aChannel;
	return self;
}

- (void) dealloc
{
	self.lastStepWaitTime = nil;
	self.lastVoltageWaitTime = nil;
	[rampFailedAlarm clearAlarm];
	[rampFailedAlarm release];
	[super dealloc];
}

- (void) setDelegate:(ORiSegHVCard*)aDelegate
{
	if([aDelegate respondsToSelector:@selector(hwGoal:)]  &&
	   [aDelegate respondsToSelector:@selector(voltage:)] &&
	   [aDelegate respondsToSelector:@selector(target:)] &&
	   [aDelegate respondsToSelector:@selector(riseRate)] &&
	   [aDelegate respondsToSelector:@selector(writeVoltage:)] &&
	   [aDelegate respondsToSelector:@selector(setHwGoal:withValue:)] &&
	   [aDelegate respondsToSelector:@selector(isOn:)]){
		delegate = aDelegate;
	}
	else delegate = nil;
}

- (NSUndoManager*) undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}

- (void) setStepWait:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStepWait:stepWait];
	stepWait = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperStepWaitChanged object:delegate];
}

- (void) setLowVoltageWait:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowVoltageWait:lowVoltageWait];
	lowVoltageWait = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperLowVoltageWaitChanged object:delegate];
}

- (void) setLowVoltageThreshold:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowVoltageThreshold:lowVoltageThreshold];
	lowVoltageThreshold = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperLowVoltageThresholdChanged object:delegate];
}

- (void) setLowVoltageStep:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowVoltageStep:lowVoltageStep];
	lowVoltageStep = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperLowVoltageStepChanged object:delegate];
}

- (void) setMaxVoltage:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxVoltage:maxVoltage];
	maxVoltage = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperMaxVoltageChanged object:delegate];
}

- (void) setMinVoltage:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMinVoltage:minVoltage];
	minVoltage = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperMinVoltageChanged object:delegate];
}

- (void) setVoltageStep:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setVoltageStep:voltageStep];
	voltageStep = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperVoltageStepChanged object:delegate];
}

- (void) setEnabled:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:enabled];
	enabled = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperEnabledChanged object:delegate];
}

- (void) setTarget:(int)aTarget    
{
    if(aTarget > maxVoltage)      target = maxVoltage;
    else if(aTarget < minVoltage) target = minVoltage;
    else                          target = aTarget;
}

- (BOOL) atIntermediateGoal
{
	return fabsf([delegate voltage:channel] - [delegate hwGoal:channel]) < kTolerance;
}

- (BOOL) atTarget
{
	return fabsf([delegate voltage:channel] - target) < kTolerance;
}

- (int) stepSize
{
    if([delegate voltage:channel]<lowVoltageThreshold)return lowVoltageStep;
    else return voltageStep;
}

- (short) timeToWait
{
    if([delegate voltage:channel]<lowVoltageThreshold)return lowVoltageWait;
    else return stepWait;    
}

- (int) nextVoltage
{
	int currentVoltage = [delegate voltage:channel];
    if(currentVoltage <= target){
        return MIN(maxVoltage,MIN(currentVoltage+[self stepSize],target));  
    }
    else {
       return MAX(minVoltage,MAX(currentVoltage-[self stepSize],target));
    }
}

- (void) startRamping
{
	if([delegate isOn:channel]){
		self.running = YES;
		self.state = kDetRamperStartRamp;
	}
	else {
		NSLog(@"%@ channel %d not on. HV ramp not started.\n",[delegate fullID],channel);
		self.running = NO;
	}

}

- (void) emergencyOff
{
	if([delegate isOn:channel]){
		self.running = YES;
		self.state = kDetRamperEmergencyOff;
	}
    else {
		self.running = NO;
		NSLog(@"%@ channel %d not on. EmergencyOff not executed.\n",[delegate fullID],channel);
	}
}

- (void) stopRamping
{
	self.state = kDetRamperDone;
	self.running = NO;
}

- (NSString*) stateString
{
	if(!enabled)return @"--";
	else switch(state){
		case kDetRamperIdle:                return @"Idle";
		case kDetRamperStartRamp:           return @"Starting";
		case kDetRamperEmergencyOff:        return @"Ramp to zero";
		case kDetRamperStepWaitForVoltage:  return @"Waiting on Voltage";
		case kDetRamperStepToNextVoltage:   return @"Stepping";
		case kDetRamperStepWait:            return @"Waiting at Step";
		case kDetRamperDone:                return @"Done";    
		case kDetRamperNoChangeError:       return @"Ramp Failed";    
		default:                            return @"?";
	}
}

- (NSString*) hwGoalString
{
	if(!enabled)return @"--";
	else switch(state){
		case kDetRamperIdle:                return @"Idle";
		case kDetRamperStartRamp:           return @"Starting";
		case kDetRamperEmergencyOff:        return @"Ramp to Zero";
		case kDetRamperStepWaitForVoltage:  return [NSString stringWithFormat:@"Waiting for %d",[delegate hwGoal:channel]];
		case kDetRamperStepToNextVoltage:   return @"Stepping";
		case kDetRamperStepWait:            return [NSString stringWithFormat:@"Waiting at %d",[delegate hwGoal:channel]];
		case kDetRamperDone:                return @"At Target";    
		case kDetRamperNoChangeError:       return @"Failed";    
		default:                            return @"?";
	}
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
			
	[self setChannel:				[decoder decodeIntegerForKey: @"channel"]];
	[self setStepWait:				[decoder decodeIntegerForKey: @"stepWait"]];
    [self setLowVoltageWait:		[decoder decodeIntegerForKey: @"lowVoltageWait"]];
    [self setLowVoltageThreshold:	[decoder decodeIntForKey: @"lowVoltageThreshold"]];
    [self setLowVoltageStep:		[decoder decodeIntForKey: @"lowVoltageStep"]];
    [self setMaxVoltage:			[decoder decodeIntForKey: @"maxVoltage"]];
    [self setMinVoltage:			[decoder decodeIntForKey: @"minVoltage"]];
    [self setVoltageStep:			[decoder decodeIntForKey: @"voltageStep"]];
    [self setEnabled:				[decoder decodeBoolForKey:@"enabled"]];
	
 	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{	
	[encoder encodeInteger:channel              forKey:@"channel"];
	[encoder encodeInteger:stepWait             forKey:@"stepWait"];
	[encoder encodeInteger:lowVoltageWait		forKey:@"lowVoltageWait"];
	[encoder encodeInteger:lowVoltageThreshold	forKey:@"lowVoltageThreshold"];
	[encoder encodeInteger:lowVoltageStep		forKey:@"lowVoltageStep"];
	[encoder encodeInteger:maxVoltage			forKey:@"maxVoltage"];
	[encoder encodeInteger:minVoltage			forKey:@"minVoltage"];
	[encoder encodeInteger:voltageStep			forKey:@"voltageStep"];
	[encoder encodeBool:enabled				forKey:@"enabled"];
}

- (void) execute
{
	
	if(!enabled)                 return;	//must be enabled
	if(![delegate isOn:channel]) return;	//channel must be on
		
	switch (state) {
			
		case kDetRamperStartRamp:
            self.target = [delegate target:channel];
            self.state  = kDetRamperStepToNextVoltage;
			break;
			
		case kDetRamperEmergencyOff:
            self.target = 0;
            self.state  = kDetRamperStepToNextVoltage;			
			break;
			
		case kDetRamperStepToNextVoltage:
            if([self atTarget])                self.state = kDetRamperDone;
			else {
				[delegate setHwGoal:channel withValue:[self nextVoltage]];
				[delegate writeVoltage:channel];
				lastVoltage = [delegate voltage:channel];
				self.state = kDetRamperStepWaitForVoltage;	
			}
			break;
            
        case kDetRamperStepWaitForVoltage:
			if(lastVoltageWaitTime) {
				if([[NSDate date] timeIntervalSinceDate:lastVoltageWaitTime] >= kCheckTime){
					float voltage = [delegate voltage:channel];
					if(fabs(voltage-lastVoltage)<kTolerance){
						NSLog(@"%@ channel %d not ramping.\n",[delegate fullID],channel);
						self.state = kDetRamperNoChangeError;
					}
					self.lastVoltageWaitTime = [NSDate date];
					lastVoltage = voltage;
				}
				else {
					if([self atTarget])                self.state = kDetRamperDone;
					else if([self atIntermediateGoal]) self.state = kDetRamperStepWait;
				}
			}
			else {
				self.lastVoltageWaitTime = [NSDate date];
                [self execute];
			}
			break;
			
        case kDetRamperStepWait:
			if(lastStepWaitTime) {
				if([[NSDate date] timeIntervalSinceDate:lastStepWaitTime] >= [self timeToWait]){
					self.state	          = kDetRamperStepToNextVoltage;
				}
			}
            else {
                self.lastStepWaitTime = [NSDate date];
                [self execute];
            }
			break;
            
		case kDetRamperDone:
			self.running = NO;
			break;
			
		case kDetRamperNoChangeError:
			self.running = NO;
			
			if(!rampFailedAlarm){
				NSString* s = [NSString stringWithFormat:@"%@,%d Ramp Failed",[delegate fullID],channel];
				rampFailedAlarm = [[ORAlarm alloc] initWithName:s severity:3];
				[rampFailedAlarm setSticky:NO];
				[rampFailedAlarm setHelpString:@"There was no change in the HV voltage during ramping. The ramping process was flagged as failed. Check the channel manually. Acknowledge the alarm to clear it."];
			}                      
			[rampFailedAlarm setAcknowledged:NO];
			[rampFailedAlarm postAlarm];
			
			break;
	}
}

- (void) setRunning:(BOOL)aValue
{
    running = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperRunningChanged object:delegate];
}

- (void) setState:(int)aValue
{
    state = aValue;
    
    //reset timers as needed.
    if(state == kDetRamperStepWait)                    self.lastStepWaitTime = nil;
    else if(state == kDetRamperStepWaitForVoltage)    self.lastVoltageWaitTime = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORDetectorRamperStateChanged object:delegate];
}
@end



