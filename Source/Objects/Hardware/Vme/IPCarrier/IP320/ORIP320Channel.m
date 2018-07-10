//
//  ORIP320Channel.m
//  Orca
//
//  Created by Mark Howe on Wed Jun 23 2004.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORIP320Channel.h"
#import "ORIP320Model.h"

@implementation ORIP320Channel

- (id) initWithAdc:(id)anAdcCard channel:(unsigned short)aChannel
{
    self = [super init];
    [self setParameters:[NSMutableDictionary dictionary]];
    [parameters setObject:[NSNumber numberWithInt:aChannel] forKey:k320ChannelKey];
    [self checkDefaults];
    return self;
}
// ===========================================================
//  - dealloc:
// ===========================================================
- (void)dealloc 
{
	[highAlarm clearAlarm];
	[lowAlarm clearAlarm];
	[highAlarm release];
	[lowAlarm release];
    [parameters release];
    [super dealloc];
}

- (void) setAdcCard:(id)aCard
{
	//don't retain to avoid retain cycles
	adcCard = aCard;
}

// ===========================================================
// - parameters:
// ===========================================================
- (NSMutableDictionary *)parameters {
    return parameters; 
}

// ===========================================================
// - setParameters:
// ===========================================================
- (void) setParameters:(NSMutableDictionary *)aParameters 
{
    [aParameters retain];
    [parameters release];
    parameters = aParameters;
}

- (void) unableToSetNilForKey:(NSString*)aKey
{
    [parameters setObject:@"-" forKey:aKey];
}

- (id) objectForKey:(id)aKey
{
	id resultObj = nil;
	@synchronized(self){
		if(![[parameters objectForKey:k320ChannelReadEnabled] boolValue]){
			if([aKey isEqualToString:k320ChannelValue])return @"-";
			else if([aKey isEqualToString:k320ChannelUnits])return @"-";
			else if([aKey isEqualToString:k320ChannelSlope])return @"-";
			else if([aKey isEqualToString:k320ChannelIntercept])return @"-";
		}
		resultObj =  [parameters objectForKey:aKey];
		if(!resultObj)[parameters objectForKey:[@"k320Channel" stringByAppendingString:aKey]]; //backward compatibility
	}
	return resultObj;
}

- (void) setObject:(id)obj forKey:(id)aKey
{
	@synchronized(self){
		[parameters setObject:obj forKey:aKey];
		if(	[aKey isEqualToString:k320ChannelLowValue] ||
			[aKey isEqualToString:k320ChannelHighValue] ){
			[self checkAlarm];
		}
		if(	[aKey isEqualToString:k320ChannelSlope] || [aKey isEqualToString:k320ChannelIntercept]){
			maxValue = 0xfff*[[parameters objectForKey:k320ChannelSlope] doubleValue] + [[parameters objectForKey:k320ChannelIntercept] doubleValue];
		}
	}
}

- (int) gain
{
	BOOL result;
	@synchronized(self){
		result =  [[parameters objectForKey:k320ChannelGain] intValue];
	}
	return result;
}

- (int) channel
{
    int result;
	@synchronized(self){
		id d = [parameters objectForKey:k320ChannelKey];
		if(!d)d = [parameters objectForKey:@"k320ChannelKey"];
		result = [d intValue];
	}
	return result;
}

- (BOOL) readEnabled
{
	BOOL result;
	@synchronized(self){
		result =  [[parameters objectForKey:k320ChannelReadEnabled] boolValue];
	}
	return result;
}

- (void) checkAlarm
{
	@synchronized(self){
		if([[parameters objectForKey:k320ChannelAlarmEnabled] boolValue]){

			NSNumber* theConvertedValue		= [parameters objectForKey:k320ChannelValue];
			NSNumber* theLowAlarmThreshold  = [parameters objectForKey:k320ChannelLowValue];
			NSNumber* theHighAlarmThreshold = [parameters objectForKey:k320ChannelHighValue];
			
			if([theLowAlarmThreshold intValue] == 0 && [theHighAlarmThreshold intValue] == 0) return;

			if([theLowAlarmThreshold compare:theHighAlarmThreshold] == NSOrderedDescending){
				[[theLowAlarmThreshold retain] autorelease];
				[[theHighAlarmThreshold retain] autorelease];
				[parameters setObject:theLowAlarmThreshold forKey:k320ChannelHighValue];
				[parameters setObject:theHighAlarmThreshold forKey:k320ChannelLowValue];
				theLowAlarmThreshold  = [parameters objectForKey:k320ChannelLowValue];
				theHighAlarmThreshold = [parameters objectForKey:k320ChannelHighValue];
			}

			if([theLowAlarmThreshold compare:theConvertedValue] == NSOrderedDescending){
				//fire the low alarm
				if(!lowAlarm){
					NSString* alarmName = [NSString stringWithFormat:@"ADC %@ chan:%@ Low",[adcCard processingTitle],[parameters objectForKey:k320ChannelKey]];
					lowAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kRangeAlarm];
					[lowAlarm setSticky:YES];
					[lowAlarm setHelpString:[NSString stringWithFormat:@"The value of adc %@ has dropped below the low alarm limit of %@",[parameters objectForKey:k320ChannelKey],theLowAlarmThreshold]];
					[lowAlarm postAlarm];
				}
				if(highAlarm){
					[highAlarm clearAlarm];
					[highAlarm release];
					highAlarm = nil;
				}
			}
			else if([theHighAlarmThreshold compare:theConvertedValue] == NSOrderedAscending){
				//fire the high alarm
				if(!highAlarm){
					NSString* alarmName = [NSString stringWithFormat:@"ADC %@ chan:%@ High",[adcCard processingTitle],[parameters objectForKey:k320ChannelKey]];
					highAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kRangeAlarm];
					[highAlarm setSticky:YES];
					[highAlarm setHelpString:[NSString stringWithFormat:@"The value of adc %@ has risen above the high alarm limit of %@",[parameters objectForKey:k320ChannelKey],theHighAlarmThreshold]];
					[highAlarm postAlarm];
					
				}
				if(lowAlarm){
					[lowAlarm clearAlarm];
					[lowAlarm release];
					lowAlarm = nil;
				}
			}
			else {
				[highAlarm clearAlarm];
				[highAlarm release];
				highAlarm = nil;
					
				[lowAlarm clearAlarm];
				[lowAlarm release];
				lowAlarm = nil;
			}
		}
		else {
			if(highAlarm){
				[highAlarm clearAlarm];
				[highAlarm release];
				highAlarm = nil;
			}
			if(lowAlarm){
				[lowAlarm clearAlarm];
				[lowAlarm release];
				lowAlarm = nil;
			}
		}
	}
}

- (BOOL) setChannelValue:(int)aValue time:(time_t)aTime
{    
	BOOL changed = NO;
	@synchronized(self){
		rawValue = aValue;
		float convertedValue = aValue*[[parameters objectForKey:k320ChannelSlope] doubleValue] + [[parameters objectForKey:k320ChannelIntercept] doubleValue];
		changed = (convertedValue!=[[parameters objectForKey:k320ChannelValue] doubleValue]);
		NSNumber* theConvertedValue = [NSNumber numberWithFloat:convertedValue];
		[parameters setObject:theConvertedValue forKey:k320ChannelValue];
		[parameters setObject:[NSNumber numberWithInt:rawValue] forKey:k320ChannelRawValue];
		[self checkAlarm];
		[adcCard loadConvertedTimeSeries:convertedValue atTime:aTime forChannel:[self channel]];
		[adcCard loadRawTimeSeries:aValue atTime:aTime forChannel:[self channel]];

	}
    return changed;
}

- (int) rawValue
{
	return rawValue;
}

- (double) maxValue
{
	return maxValue;
}

- (void) checkDefaults
{
    if(![parameters objectForKey:k320ChannelValue])[parameters setObject:[NSNumber numberWithDouble:0.0] forKey:k320ChannelValue];
    if(![parameters objectForKey:k320ChannelReadEnabled])[parameters setObject:[NSNumber numberWithBool:YES] forKey:k320ChannelReadEnabled];
    if(![parameters objectForKey:k320ChannelIntercept])[parameters setObject:[NSNumber numberWithDouble:0.0] forKey:k320ChannelIntercept];
    if(![parameters objectForKey:k320ChannelSlope])[parameters setObject:[NSNumber numberWithDouble:1.0] forKey:k320ChannelSlope];
    if(![parameters objectForKey:k320ChannelGain])[parameters setObject:[NSNumber numberWithInt:0] forKey:k320ChannelGain];
    if(![parameters objectForKey:k320ChannelUnits])[parameters setObject:@"" forKey:k320ChannelUnits];
    if(![parameters objectForKey:k320ChannelAlarmEnabled])[parameters setObject:[NSNumber numberWithBool:NO] forKey:k320ChannelAlarmEnabled];
    if(![parameters objectForKey:k320ChannelLowValue])[parameters setObject:[NSNumber numberWithInt:0] forKey:k320ChannelLowValue];
    if(![parameters objectForKey:k320ChannelHighValue])[parameters setObject:[NSNumber numberWithInt:0] forKey:k320ChannelHighValue];

    maxValue = 0xfff*[[parameters objectForKey:k320ChannelSlope] doubleValue] + [[parameters objectForKey:k320ChannelIntercept] doubleValue];

}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    [self setParameters:[decoder decodeObjectForKey:@"parameters"]];
    [self checkDefaults];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:parameters forKey:@"parameters"];
}

@end
