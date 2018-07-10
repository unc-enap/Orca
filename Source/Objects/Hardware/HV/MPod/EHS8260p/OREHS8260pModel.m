//
//  OREHS8260pModel.m
//  Orca
//
//  Created by Mark Howe on Tues Feb 1,2011
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

#pragma mark ***Imported Files
#import "OREHS8260pModel.h"
#import "ORMPodProtocol.h"
#import "ORTimeRate.h"
#import "ORHWWizSelection.h"
#import "ORHWWizParam.h"
#import "ORDetectorRamper.h"

NSString* OREHS8260pModelOutputFailureBehaviorChanged = @"OREHS8260pModelOutputFailureBehaviorChanged";
NSString* OREHS8260pModelCurrentTripBehaviorChanged = @"OREHS8260pModelCurrentTripBehaviorChanged";
NSString* OREHS8260pModelSupervisorMaskChanged	= @"OREHS8260pModelSupervisorMaskChanged";
NSString* OREHS8260pModelTripTimeChanged		= @"OREHS8260pModelTripTimeChanged";
NSString* OREHS8260pSettingsLock				= @"OREHS8260pSettingsLock";

@interface OREHS8260pModel (private)
- (void) makeRampers;
@end

@implementation OREHS8260pModel

#define kMaxVoltage 6000

#pragma mark ***Initialization
- (id) init {
	self = [super init];
	[self makeRampers];
	return self;
}
- (void) dealloc
{
	[rampers release];
    [super dealloc];
}

- (void) sleep
{
	for(ORDetectorRamper* aRamper in rampers){
		[aRamper stopRamping];
	}
    [super sleep];
}

- (NSString*) imageName
{
    return @"EHS8260p";
}

- (void) makeMainController
{
    [self linkToController:@"OREHS8260pController"];
}

- (NSString*) settingsLock
{
	 return OREHS8260pSettingsLock;
}

- (NSString*) name
{
	 return @"EHS8260p";
}

- (NSString*) helpURL
{
	return @"MPod/EHS8260p.html";
}

#pragma mark ***Accessors
- (ORDetectorRamper*) ramper:(int)channel
{
	if([self channelInBounds:channel]){
		return [rampers objectAtIndex:channel];
	}
	else return nil;
}
- (void) setRampers:(NSMutableArray*)someRampers
{
    [someRampers retain];
    [rampers release];
    rampers = someRampers;
}

- (NSMutableArray*)rampers
{	
    return rampers;
}

- (short) outputFailureBehavior:(short)chan
{
	if([self channelInBounds:chan]){
		return outputFailureBehavior[chan];
	}
	else return 0;
}

- (void) setOutputFailureBehavior:(short)chan withValue:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOutputFailureBehavior:chan withValue: outputFailureBehavior[chan]];
    outputFailureBehavior[chan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREHS8260pModelOutputFailureBehaviorChanged object:self];
}

- (short) currentTripBehavior:(short)chan
{
	if([self channelInBounds:chan]) {
		return currentTripBehavior[chan];
	}
	else return 0;
}

- (void) setCurrentTripBehavior:(short)chan withValue:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCurrentTripBehavior:chan withValue:currentTripBehavior[chan]];
    currentTripBehavior[chan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:OREHS8260pModelCurrentTripBehaviorChanged object:self];
}

- (void) setRdParamsFrom:(NSDictionary*)aDictionary
{
	[super setRdParamsFrom:aDictionary];
	 int i;	
	 for(i=0;i<8;i++){
		 if([[self ramper:i] enabled]){
			 [[self adapter] callBackToTarget:self selector:@selector(checkRamperCallBack:) userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:i] forKey:@"Channel"]];
		 }
	 }
}

- (void) checkRamperCallBack:(NSDictionary*)userInfo
{
	int aChannel = [[userInfo objectForKey:@"Channel"] intValue];
	if([self channelInBounds:aChannel]){
		[[self ramper:aChannel] execute];
	}
}

- (void) writeTripTimes
{  
	int i;
	for(i=0;i<8;i++){
		[self writeTripTime:i];
	}
}

- (void) writeTripTime:(int)channel
{    
	if([self channelInBounds:channel]){
		NSString* cmd = [NSString stringWithFormat:@"outputTripTimeMaxCurrent.u%d i %d",[self slotChannelValue:channel],tripTime[channel]];
		[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
	}
}
- (void) writeSupervisorBehaviours
{  
	int i;
	for(i=0;i<8;i++){
		[self writeSupervisorBehaviour:i];
	}
}

- (void) writeSupervisorBehaviour:(int)channel
{    
	if([self channelInBounds:channel]){
		short aValue = ((currentTripBehavior[channel] & 0x3)<<6) | ((outputFailureBehavior[channel] & 0x3)<<12);
		NSString* cmd = [NSString stringWithFormat:@"outputSupervisionBehavior.u%d i %d",[self slotChannelValue:channel],aValue];
		[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
        
		//disable the hw kill if the supervisor behaviour is set to ignore
		if((outputFailureBehavior[channel] & 0x3) == 0){
			NSString* cmd = [NSString stringWithFormat:@"outputSwitch.u%d i 4",[self slotChannelValue:channel]];
			[[self adapter] writeValue:cmd target:self selector:@selector(processWriteResponseArray:) priority:NSOperationQueuePriorityVeryHigh];
		}
	}
}

- (short) tripTime:(short)chan	
{ 
	if([self channelInBounds:chan])return tripTime[chan]; 
	else return 0;
}
- (void) setTripTime:(short)chan withValue:(short)aValue 
{
	if([self channelInBounds:chan]){
		if(aValue<16)		 aValue = 16;
		else if(aValue>4000) aValue = 4000;
	
		[[[self undoManager] prepareWithInvocationTarget:self] setTripTime:chan withValue:tripTime[chan]];
		tripTime[chan] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:OREHS8260pModelTripTimeChanged object:self];
	}
}

- (NSString*) behaviourString:(int)channel
{
	if([self channelInBounds:channel]){
		NSString* options[4] = {
			@"Ig",		//0
			@"RDn",		//1
			@"SwOff",	//2
			@"BdOff"	//3
		};
		
		short i = currentTripBehavior[channel];
		NSString* s1;
		if(i<4)s1 = options[i];
		else   s1 = @"?";
		
		i = outputFailureBehavior[channel];
		NSString* s2;
		if(i<4)s2 = options[i];
		else   s2 = @"?";
		return [NSString stringWithFormat:@"%@:%@",s1,s2];
	}
	else return @"--";
}

- (BOOL) channelIsRamping:(short)chan
{
	return [super channelIsRamping:chan] || [[self ramper:chan] running];
}

#pragma mark •••Hardware Access
- (void) loadValues:(short)channel
{
	if([self channelInBounds:channel]){
		
		[self writeTripTime:channel];
		[self writeSupervisorBehaviour:channel];
		[self writeRiseTime];
		[self writeMaxCurrent:channel];
		
		if(![[self ramper:channel] enabled]){
			[self commitTargetToHwGoal:channel];
			[self writeVoltage:channel];
		}
		else {
			[[self ramper:channel] setTarget:[self target:channel]];
			if(![[self ramper:channel] running])[[self ramper:channel] startRamping];
		}
	}
}

- (void) loadAllValues
{
	[self writeRiseTime];
	int i;
	for(i=0;i<8;i++){
		[self writeTripTime:i];
		[self writeSupervisorBehaviour:i];
		[self writeMaxCurrent:i];
		if(![[self ramper:i] enabled]){
			[self commitTargetToHwGoal:i];
			[self writeVoltage:i];
		}
		else {
			[[self ramper:i] setTarget:[self target:i]];
			if(![[self ramper:i] running])[[self ramper:i] startRamping];
		}
	}
}

- (void) rampToZero:(short)channel
{
	if([self channelInBounds:channel]){
		if([[self ramper:channel] enabled]){
			[[self ramper:channel] emergencyOff];			
		}
		else {
			[self setHwGoal:channel withValue:0];
			[self writeVoltage:channel];
		}
	}
}

- (void) panic:(short)channel
{
	if([self channelInBounds:channel]){
		if([[self ramper:channel] enabled]){
			[[self ramper:channel] stopRamping];
		}
		[super panic:channel];
	}
}



- (NSString*) hwGoalString:(short)chan
{
	if([self channelInBounds:chan]){
		if([[self ramper:chan] enabled]){
			return [[self ramper:chan] hwGoalString];
		}
		else return [NSString stringWithFormat:@"Goal: %d",hwGoal[chan]];
	}
	else return @"";
}

- (void) stopRamping:(short)channel
{
	if([[self ramper:channel] enabled]){
		[[self ramper:channel] stopRamping];
	}
	[super stopRamping:channel];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	[self setRampers:[decoder decodeObjectForKey:@"rampers"]];
	if(!rampers)[self makeRampers];
	int i;
	for(i=0;i<8;i++){
		[[self ramper:i] setDelegate:self];
		[self setTripTime:i withValue:[decoder decodeIntForKey: [@"tripTime" stringByAppendingFormat:@"%d",i]]];
		[self setOutputFailureBehavior:i withValue:[decoder decodeIntForKey: [@"outputFailureBehavior" stringByAppendingFormat:@"%d",i]]];
		[self setCurrentTripBehavior:i withValue:[decoder decodeIntForKey: [@"currentTripBehavior" stringByAppendingFormat:@"%d",i]]];
	}
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:rampers forKey:@"rampers"];
	int i;
 	for(i=0;i<8;i++){
		[encoder encodeInt:tripTime[i]					forKey: [@"tripTime" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:outputFailureBehavior[i]		forKey: [@"outputFailureBehavior" stringByAppendingFormat:@"%d",i]];
		[encoder encodeInt:currentTripBehavior[i]		forKey: [@"currentTripBehavior" stringByAppendingFormat:@"%d",i]];
	}
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
	[super addParametersToDictionary:dictionary];
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	[self addCurrentState:objDictionary cIntArray:tripTime forKey:@"tripTime"];
	[self addCurrentState:objDictionary cIntArray:outputFailureBehavior forKey:@"outputFailureBehavior"];
	[self addCurrentState:objDictionary cIntArray:currentTripBehavior forKey:@"currentTripBehavior"];
	
    return objDictionary;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORMPodCrate"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"OREHS8260pModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"OREHS8260pModel"]];
    return a;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [[super wizardParameters] mutableCopy];
    ORHWWizParam* p;
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trip Time"];
    [p setFormat:@"##0" upperLimit:4000 lowerLimit:16 stepSize:1 units:@"mA"];
    [p setSetMethod:@selector(setTripTime:withValue:) getMethod:@selector(tripTime:)];
	[p setInitMethodSelector:@selector(loadAllValues)];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"I Trip Behavior"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@"mA"];
    [p setSetMethod:@selector(setCurrentTripBehavior:withValue:) getMethod:@selector(currentTripBehavior:)];
	[p setInitMethodSelector:@selector(loadAllValues)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Failure Behavior"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@"mA"];
    [p setSetMethod:@selector(setOutputFailureBehavior:withValue:) getMethod:@selector(outputFailureBehavior:)];
	[p setInitMethodSelector:@selector(loadAllValues)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Step Wait"];
    [p setFormat:@"##0" upperLimit:100 lowerLimit:1 stepSize:1 units:@"s"];
    [p setSetMethod:@selector(setStepWait:withValue:) getMethod:@selector(stepWait:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Low Voltage Wait"];
    [p setFormat:@"##0" upperLimit:100 lowerLimit:1 stepSize:1 units:@"s"];
    [p setSetMethod:@selector(setLowVoltageWait:withValue:) getMethod:@selector(lowVoltageWait:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Low Voltage Threshold"];
    [p setFormat:@"##0" upperLimit:5000 lowerLimit:1 stepSize:1 units:@"V"];
    [p setSetMethod:@selector(setLowVoltageThreshold:withValue:) getMethod:@selector(lowVoltageThreshold:)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Low Voltage Step"];
    [p setFormat:@"##0" upperLimit:500 lowerLimit:1 stepSize:1 units:@"V"];
    [p setSetMethod:@selector(setLowVoltageStep:withValue:) getMethod:@selector(lowVoltageStep)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Voltage Step"];
    [p setFormat:@"##0" upperLimit:500 lowerLimit:1 stepSize:1 units:@"V"];
    [p setSetMethod:@selector(setVoltageStep:withValue:) getMethod:@selector(voltageStep)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Max Voltage"];
    [p setFormat:@"##0" upperLimit:500 lowerLimit:1 stepSize:1 units:@"V"];
    [p setSetMethod:@selector(setMaxVoltage:withValue:) getMethod:@selector(maxVoltage)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Min Voltage"];
    [p setFormat:@"##0" upperLimit:[self supplyVoltageLimit] lowerLimit:1 stepSize:1 units:@"V"];
    [p setSetMethod:@selector(setMinVoltage:withValue:) getMethod:@selector(minVoltage)];
    [a addObject:p];

    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Step Ramp Enabled"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setStepRampEnabled:withValue:) getMethod:@selector(stepRampEnabled:)];
    [a addObject:p];

    
    return [a autorelease];
}

//----------------------------------------------------------------------------------------------
//call thrus just for using the wizard.
- (void) setStepWait:(int)i withValue:(int)aValue { [self ramper:i].stepWait = aValue; }
- (int) stepWait:(int)i { return [self ramper:i].stepWait; }
- (void) setLowVoltageWait:(int)i withValue:(int)aValue { [self ramper:i].lowVoltageWait = aValue; }
- (int) lowVoltageWait:(int)i { return [self ramper:i].lowVoltageWait; }
- (void) setLowVoltageThreshold:(int)i withValue:(int)aValue { [self ramper:i].lowVoltageThreshold = aValue; }
- (int) lowVoltageThreshold:(int)i { return [self ramper:i].lowVoltageThreshold; }
- (void) setLowVoltageStep:(int)i withValue:(int)aValue { [self ramper:i].lowVoltageStep = aValue; }
- (int) lowVoltagestep:(int)i { return [self ramper:i].lowVoltageStep; }
- (void) setVoltageStep:(int)i withValue:(int)aValue { [self ramper:i].voltageStep = aValue; }
- (int) voltagestep:(int)i { return [self ramper:i].voltageStep; }
- (void) setMinVoltage:(int)i withValue:(int)aValue { [self ramper:i].minVoltage = aValue; }
- (int) minVoltage:(int)i { return [self ramper:i].minVoltage; }
- (void) setStepRampEnabled:(int)i withValue:(int)aValue { [self ramper:i].enabled = aValue; }
- (int) stepRampEnabled:(int)i { return [self ramper:i].enabled; }
- (void) setMaxVoltage:(int)i withValue:(int)aValue
{
    [self ramper:i].maxVoltage = MIN([self supplyVoltageLimit],aValue);
    [super setMaxVoltage:i withValue:aValue];
}
- (int) maxVoltage:(int)i
{
    if([self ramper:i]) return [self ramper:i].maxVoltage;
    else return kMaxVoltage;
}
- (int) supplyVoltageLimit
{
    //subclassed should override
    return kMaxVoltage;
}

//----------------------------------------------------------------------------------------------

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSNumber* value= [super extractParam:param from:fileHeader forChannel:aChannel];
	if(value)return value;
	else {
		NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
		if([param isEqualToString:@"Trip Time"])			return [[cardDictionary objectForKey:@"tripTime"] objectAtIndex:aChannel];
		else if([param isEqualToString:@"I Trip Behavior"]) return [[cardDictionary objectForKey:@"currentTripBehavior"] objectAtIndex:aChannel];
		else if([param isEqualToString:@"Failure Behavior"])return [[cardDictionary objectForKey:@"outputFailureBehavior"] objectAtIndex:aChannel];
		else return nil;
	}
}
@end

@implementation OREHS8260pModel (private)
- (void) makeRampers
{
    [[self undoManager] disableUndoRegistration];
	[self setRampers:[NSMutableArray arrayWithCapacity:8]];
	int i;
	for(i=0;i<8;i++){
		ORDetectorRamper* aRamper = [[ORDetectorRamper alloc] initWithDelegate:self channel:i];
        [rampers addObject:aRamper];

		//defaults
		aRamper.maxVoltage    = [self maxVoltage:i];
		aRamper.minVoltage    = 0;
		aRamper.voltageStep   = 150;
		aRamper.stepWait      = 10;
		
		aRamper.lowVoltageThreshold   = 500;
		aRamper.lowVoltageStep        = 75;
		aRamper.lowVoltageWait        = 30;
		
		
		[aRamper release];
	}
	
	[[self undoManager] enableUndoRegistration];
}
@end
