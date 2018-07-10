//
//  ORLakeShore336Heater.m
//  Orca
//
//  Created by Mark Howe on Mon, May 6, 2013.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
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

#import "ORLakeShore336Heater.h"
#import "ORTimeRate.h"

NSString* ORLakeShore336OutputChanged = @"ORLakeShore336OutputChanged";
NSString* ORLakeShore336InputChanged  = @"ORLakeShore336InputChanged";

@implementation ORLakeShore336Heater

@synthesize label,channel,output,resistance, maxCurrent, maxUserCurrent, currentOrPower;
@synthesize lowLimit,highLimit,minValue,maxValue,timeRate,timeMeasured,userMaxCurrentEnabled;
@synthesize iValue,pValue,dValue,opMode,input,powerUpEnable;

- (id) init
{
    self = [super init];
    lowLimit    = 0;
    highLimit   = 100;
    minValue    = 0;
    maxValue    = 100;
    return self;
}

- (void) dealloc
{
    [label release];
    [timeRate release];
    [super dealloc];
}

- (NSString*) heaterSetupString;
{
    return [NSString stringWithFormat:@"HTRSET %d,%d,%d,+%5.3f,%d",channel+1,resistance+1,maxCurrent,maxUserCurrent,currentOrPower+1];
}
- (NSString*) pidSetupString;
{
    return [NSString stringWithFormat:@"PID %d,+%.1f,+%.1f,%d",channel+1,pValue,iValue,dValue];
}
- (NSString*) outputSetupString;
{
    return [NSString stringWithFormat:@"OUTMODE %d,%d,%d,%d",channel+1,opMode,input,powerUpEnable];
}

- (void) setOutput:(float)aValue
{
    output = aValue;
    
    //get the time(UT!)
    time_t	ut_Time;
    time(&ut_Time);
    timeMeasured = ut_Time;
    
    if(timeRate == nil) self.timeRate = [[[ORTimeRate alloc] init] autorelease];
    [timeRate addDataToTimeAverage:aValue];
    
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:channel] forKey:@"Index"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336OutputChanged object:self userInfo:userInfo];
}

- (void) setResistance:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setResistance:resistance];
     resistance= aValue;
}

- (void) setMaxCurrent:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxCurrent:maxCurrent];
    maxCurrent = aValue;
    self.userMaxCurrentEnabled = (maxCurrent==0);
}

- (void) setMaxUserCurrent:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxUserCurrent:maxUserCurrent];
    maxUserCurrent = aValue;
}

- (void) setCurrentOrPower:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCurrentOrPower:currentOrPower];
    currentOrPower = aValue;
}


- (void) setLowLimit:(double)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:lowLimit];
    lowLimit = aValue;
}

- (void) setHighLimit:(double)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHighLimit:highLimit];
    highLimit = aValue;
}

- (void) setIValue:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIValue:iValue];
    if(aValue<.1)aValue=.1;
    else if(aValue>1000)aValue=1000;
    iValue = aValue;
}

- (void) setPValue:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPValue:pValue];
    if(aValue<.1)aValue=.1;
    else if(aValue>1000)aValue=1000;
    pValue = aValue;
}

- (void) setDValue:(unsigned short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDValue:dValue];
    if(aValue>200)aValue=200;
    dValue = aValue;
}

- (void) setOpMode:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOpMode:opMode];
    if(aValue<0)aValue=0;
    else if(aValue>5)aValue=5;
    opMode = aValue;
}

- (void) setInput:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInput:input];
    if(aValue<0)aValue=0;
    else if(aValue>3)aValue=3;
    input = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336InputChanged object:self ];
}

- (void) setPowerUpEnable:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPowerUpEnable:powerUpEnable];
     powerUpEnable = aValue;
}

- (NSUndoManager*) undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}



#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [self setChannel:       [decoder decodeIntForKey:   @"channel"]];
    [self setResistance:    [decoder decodeIntForKey:   @"resistance"]];
	//[self setMaxCurrent:    [decoder decodeIntForKey:   @"maxCurrent"]];
    [self setMaxUserCurrent:[decoder decodeIntForKey:   @"maxUserCurrent"]];
    [self setCurrentOrPower:[decoder decodeBoolForKey:  @"currentOrPower"]];
    [self setLowLimit:      [decoder decodeFloatForKey: @"lowLimit"]];
    [self setHighLimit:     [decoder decodeFloatForKey: @"highLimit"]];
    [self setMinValue:      [decoder decodeFloatForKey: @"minValue"]];
    [self setMaxValue:      [decoder decodeFloatForKey: @"maxValue"]];
    [self setPValue:        [decoder decodeFloatForKey: @"pValue"]];
    [self setIValue:        [decoder decodeFloatForKey: @"iValue"]];
    [self setDValue:        [decoder decodeIntForKey:   @"dValue"]];
    [self setLabel:         [decoder decodeObjectForKey:@"label"]];
    [self setOpMode:          [decoder decodeIntForKey:   @"mode"]];
    [self setInput:         [decoder decodeIntForKey:   @"input"]];
    [self setPowerUpEnable: [decoder decodeBoolForKey:  @"powerUpEnable"]];

    if(lowLimit < 0.001 && highLimit < 0.001 && minValue < 0.001 && maxValue < 0.001){
        lowLimit = 0;
        highLimit = 100;
        minValue = 0;
        maxValue = 100;
    }
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt:channel          forKey:@"channel"];
    [encoder encodeInt:resistance       forKey:@"resistance"];
    [encoder encodeInt:maxCurrent       forKey:@"maxCurrent"];
    [encoder encodeInt:maxUserCurrent   forKey:@"maxUserCurrent"];
    [encoder encodeBool:currentOrPower  forKey:@"currentOrPower"];
    [encoder encodeFloat:lowLimit       forKey:@"lowLimit"];
    [encoder encodeFloat:highLimit      forKey:@"highLimit"];
    [encoder encodeFloat:minValue       forKey:@"minValue"];
    [encoder encodeFloat:maxValue       forKey:@"maxValue"];
    [encoder encodeFloat:pValue         forKey:@"pValue"];
    [encoder encodeFloat:iValue         forKey:@"iValue"];
    [encoder encodeInt:dValue           forKey:@"dValue"];
    [encoder encodeObject:label         forKey:@"label"];
    [encoder encodeInt:opMode             forKey:@"mode"];
    [encoder encodeInt:input            forKey:@"input"];
    [encoder encodeBool:powerUpEnable   forKey:@"powerUpEnable"];
}

- (int) numberPointsInTimeRate
{
    return [timeRate count];
}

- (void) timeRateAtIndex:(int)i x:(double*)xValue y:(double*)yValue
{
    int count   = [timeRate count];
    int index   = count-i-1;
    *xValue     = [timeRate timeSampledAtIndex:index];
    *yValue     = [timeRate valueAtIndex:index];
}

@end

