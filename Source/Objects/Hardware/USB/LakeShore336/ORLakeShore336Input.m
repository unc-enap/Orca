//
//  ORLakeShore336Input.m
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

#import "ORLakeShore336Input.h"
#import "ORTimeRate.h"


NSString* ORLakeShore336InputTemperatureChanged  = @"ORLakeShore336InputTemperatureChanged";

@implementation ORLakeShore336Input

@synthesize label,channel,temperature, sensorType, autoRange, range, compensation, units;
@synthesize lowLimit,highLimit,minValue,maxValue,timeRate,timeMeasured;
@synthesize rangeStrings,setPoint;
- (id) init
{
    self = [super init];
    lowLimit    = 0;
    highLimit   = 350;
    minValue    = 0;
    maxValue    = 350;
    return self;
}

- (void) dealloc
{
    [rangeStrings release];
    [label release];
    [timeRate release];
    [super dealloc];
}

- (BOOL) sensorEnabled
{
    return sensorType>0;
}

- (void) setTemperature:(float)aValue
{
    temperature = aValue;

    //get the time(UT!)
    time_t	ut_Time;
    time(&ut_Time);
    timeMeasured = ut_Time;

    if(timeRate == nil) self.timeRate = [[[ORTimeRate alloc] init] autorelease];
    [timeRate addDataToTimeAverage:aValue];

    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:channel] forKey:@"Index"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLakeShore336InputTemperatureChanged object:self userInfo:userInfo];
}

- (void) setSetPoint:(float)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSetPoint:setPoint];
    setPoint = aValue;
}

- (void) setRange:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRange:range];
    range = aValue;
}

- (void) setCompensation:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCompensation:compensation];
    compensation = aValue;
}

- (void) setUnits:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUnits:units];
    units = aValue;
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

- (void) setAutoRange:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoRange:autoRange];
    autoRange = aValue;
    
}
- (void) setSensorType:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSensorType:sensorType];
    sensorType = aValue;
    switch(sensorType){
        case 0:
            [self setRangeStrings:[NSArray arrayWithObjects:
                                   @"--",
                                   nil]];
            break;
        case 1:
            [self setRangeStrings:[NSArray arrayWithObjects:
                                   @"2.5 V",
                                   @"10 V",
                                   nil]];
            break;
        case 2:
            [self setRangeStrings:[NSArray arrayWithObjects:
                                   @"10 Ω",
                                   @"30 Ω",
                                   @"100 Ω",
                                   @"300 Ω",
                                   @"1 KΩ",
                                   @"3 KΩ",
                                   @"10 KΩ",
                                   nil]];
            break;
            
        case 3:
            [self setRangeStrings:[NSArray arrayWithObjects:
                                   @"10 Ω",
                                   @"30 Ω",
                                   @"100 Ω",
                                   @"300 Ω",
                                   @"1 KΩ",
                                   @"3 KΩ",
                                   @"10 KΩ",
                                   @"30 KΩ",
                                   @"100 KΩ",
                                   nil]];
            break;
            
        case 4:
            [self setRangeStrings:[NSArray arrayWithObjects:
                                   @"50 mV",
                                   nil]];
            break;
            
        default:
            [self setRangeStrings:nil];
            break;
    }
    
}

- (NSArray*) sensorTypes
{
    return [NSArray arrayWithObjects:
            @"Disabled",
            @"Diode",
            @"Platinum RTD",
            @"NTC RTD",
            @"Thermocouple",
            @"Capacitance",
            nil
            ];
}

- (int) range
{
    //have to limit range for different sensor types
    switch(sensorType) {
        case 0: return 0;
        case 1:
            if(range>=0 && range<=1)return range;
            else return 0;
            break;
        case 2:
            if(range>=0 && range<=6)return range;
            else return 0;
            break;
        case 3:
            if(range>=0 && range<=8)return range;
            else return 0;
            break;
        case 4:
            if(range==0)return range;
            else return 0;
            break;
        default: return 0;
    }
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
    [self setChannel:       [decoder decodeIntForKey:    @"channel"]];
    [self setLabel:         [decoder decodeObjectForKey: @"label"]];
    [self setSensorType:    [decoder decodeIntForKey:    @"sensorType"]];
	[self setAutoRange:     [decoder decodeBoolForKey:   @"autoRange"]];
    [self setRange:         [decoder decodeIntForKey:    @"range"]];
    [self setCompensation:  [decoder decodeBoolForKey:   @"compensation"]];
    [self setUnits:         [decoder decodeIntForKey:    @"units"]];
    [self setLowLimit:      [decoder decodeFloatForKey:  @"lowLimit"]];
    [self setHighLimit:      [decoder decodeFloatForKey: @"highLimit"]];
    [self setMinValue:      [decoder decodeFloatForKey:  @"minValue"]];
    [self setMaxValue:      [decoder decodeFloatForKey:  @"maxValue"]];
    [self setSetPoint:      [decoder decodeFloatForKey:  @"setPoint"]];

    if(lowLimit < 0.001 && highLimit < 0.001 && minValue < 0.001 && maxValue < 0.001){
        lowLimit = 0;
        highLimit = 350;
        minValue = 0;
        maxValue = 350;
    }
    
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInteger:channel          forKey:@"channel"];
    [encoder encodeObject:label         forKey:@"label"];
    [encoder encodeBool:autoRange       forKey:@"autoRange"];
    [encoder encodeBool:compensation    forKey:@"compensation"];
    [encoder encodeInteger:units            forKey:@"units"];
    [encoder encodeFloat:lowLimit       forKey:@"lowLimit"];
    [encoder encodeFloat:highLimit      forKey:@"highLimit"];
    [encoder encodeFloat:minValue       forKey:@"minValue"];
    [encoder encodeFloat:maxValue       forKey:@"maxValue"];
    [encoder encodeInteger:sensorType       forKey:@"sensorType"];
    [encoder encodeInteger:[self range]     forKey:@"range"];
    [encoder encodeFloat:setPoint       forKey:@"setPoint"];
}

- (NSString*) inputSetupString;
{
    return [NSString stringWithFormat:@"INTYPE %c,%d,%d,%d,%d,%d",'A'+channel,sensorType,autoRange,range,compensation,units];
}

- (NSString*) setPointString;
{
    return [NSString stringWithFormat:@"SETP %d,%@%f.2",channel+1,setPoint>0?@"+":@"-",setPoint];
}


- (NSUInteger) numberPointsInTimeRate
{
    return [timeRate count];
}

- (void) timeRateAtIndex:(int)i x:(double*)xValue y:(double*)yValue
{
    NSUInteger count   = [timeRate count];
    NSUInteger index   = count-i-1;
    *xValue     = [timeRate timeSampledAtIndex:index];
    *yValue     = [timeRate valueAtIndex:index];
}
@end
