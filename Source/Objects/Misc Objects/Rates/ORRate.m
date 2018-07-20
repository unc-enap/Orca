//
//  ORRate.m
//  Orca
//
//  Created by Mark Howe on Tue Aug 05 2003.
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


#pragma mark •••Imported Files
#import "ORRate.h"
#import "ORTimeRate.h"

NSString* ORRateChangedNotification 		= @"ORRateChangedNotification";

NSString* ORRateTag 				= @"ORRateTag";
NSString* ORRateValue 				= @"ORRateValue";


@implementation ORRate

#pragma mark •••Inialization
- (id) initWithTag:(int)aTag
{
	self = [super init];
	[self setTag:aTag];
	
	ORTimeRate* aTimeRate = [[ORTimeRate alloc] init];
	[self setTimeRate:aTimeRate];
	[aTimeRate release];
	
	return self;
}

- (void) dealloc
{
	[timeRate release];
	[lastTime release];
	[super dealloc];
}

#pragma mark •••Accessors
- (NSString*) rateNotification
{
	return ORRateChangedNotification;
}

- (NSDate*) lastTime
{
	return lastTime;
}
- (void) setLastTime:(NSDate*)newLastTime
{
	[newLastTime retain];
	[lastTime release];
	lastTime = newLastTime;
}

- (NSUInteger) tag
{
	return tag;
}
- (void) setTag:(int)newTag
{
	tag=newTag;
}

- (int) groupTag
{
	return groupTag;
}
- (void) setGroupTag:(int)newGroupTag
{
	groupTag=newGroupTag;
}

- (float) rate:(int)paramIgnored
{
	//method is for compatibility, index is ignored.
	return rate;
}


- (float) rate
{
	return rate;
}
- (void) setRate:(float)newRate
{	
	rate=newRate;
    [timeRate addDataToTimeAverage:rate];
    
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRateChangedNotification object:self userInfo:nil];
}

- (ORTimeRate*) timeRate
{
	return timeRate;
}
- (void) setTimeRate:(ORTimeRate*)newTimeRate
{
	[timeRate autorelease];
	timeRate=[newTimeRate retain];
}



#pragma mark •••Calculations
- (void) reset
{
	[self setLastTime:nil];
	[self setRate:0];
}

- (void) calcRate:(id)obj
{

	uint32_t currentCount = [obj getCounter:tag forGroup:groupTag];
	if(lastTime == nil){
		[self setRate:0];
		lastCount = currentCount;
		[self setLastTime:[NSDate date]];
	}
	if(currentCount >= lastCount){
	
		NSDate* now = [NSDate date];
		NSTimeInterval deltaTime = [now timeIntervalSinceDate:lastTime];

		if(deltaTime){
			[self setRate:(currentCount-lastCount)/deltaTime];
			lastCount = currentCount;
		}
		[self setLastTime:now];

	}


}

#pragma mark •••Archival
static NSString *ORRate_Tag 		= @"ORRate_Tag";
static NSString *ORRate_GroupTag 	= @"ORRate_GroupTag";
static NSString *ORRate_TimeRate 	= @"ORRate_TimeRate";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    [self setTag:[decoder decodeIntForKey:ORRate_Tag]];
    [self setGroupTag:[decoder decodeIntForKey:ORRate_GroupTag]];
    [self setTimeRate:[decoder decodeObjectForKey:ORRate_TimeRate]];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInteger:(int32_t)[self tag] forKey:ORRate_Tag];
    [encoder encodeInteger:[self groupTag] forKey:ORRate_GroupTag];
    [encoder encodeObject:[self timeRate] forKey:ORRate_TimeRate];
}

@end

