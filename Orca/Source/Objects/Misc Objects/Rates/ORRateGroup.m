//
//  ORRateGroup.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 06 2003.
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


#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORTimeRate.h"

NSString* ORRateGroupIntegrationChangedNotification = @"ORRateGroupIntegrationChangedNotification";
NSString* ORRateGroupTotalRateChangedNotification   = @"ORRateGroupTotalRateChangedNotification";


@implementation ORRateGroup

#pragma mark •••Initialization
- (id) initGroup:(int)numberInGroup groupTag:(int)aGroupTag
{
	self = [super init];
	[self setRates:[NSMutableArray array]];
	[self setTag:aGroupTag];
	int i;
	for(i=0;i<numberInGroup;i++){
		ORRate* aRateObj = [[ORRate alloc]initWithTag:i];
		[aRateObj setTag:i];
		[aRateObj setGroupTag:aGroupTag];
		[rates addObject:aRateObj];
		[aRateObj release];
	}

	ORTimeRate* aTimeRate = [[ORTimeRate alloc] init];
	[self setTimeRate:aTimeRate];
	[aTimeRate release];
	
	
	return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[timeRate release];
	[rates release];
	[super dealloc];
}

#pragma mark •••Accessors
- (NSArray*) rates
{
	return rates;
}

- (void) setRates:(NSMutableArray*)newRates
{
	[newRates retain];
	[rates release];
	rates = newRates;
}

- (id) rateObject:(int)index
{
	if(index<[rates count]){
		return [rates objectAtIndex:index];
	}
	else return nil;
}

- (double) integrationTime
{
	return integrationTime;
}
- (void) setIntegrationTime:(double)newIntegrationTime
{
	integrationTime=newIntegrationTime;
	//[NSObject cancelPreviousPerformRequestsWithTarget:self];
	//[self performSelector:@selector(calcRates) withObject:nil afterDelay:integrationTime];
	//[self calcRates];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRateGroupIntegrationChangedNotification object:self userInfo:nil];
}

- (double) totalRate
{
	return totalRate;
}
- (void) setTotalRate:(double)newTotalRate
{
	totalRate=newTotalRate;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRateGroupTotalRateChangedNotification object:self userInfo:nil];
}

- (int) tag
{
	return tag;
}
- (void) setTag:(int)newTag
{
	tag=newTag;
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



- (void) start:(id)obj
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	[self resetRates];
	objectKeepingCount = obj;
	
	[self performSelector:@selector(calcRates) withObject:nil afterDelay:integrationTime];
	[self calcRates];

	[self collectTimeRate];
}

- (void) quit
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    objectKeepingCount = nil;
}

- (void) stop
{
        [self quit];
	[self resetRates];
}

- (void) calcRates
{
   
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(calcRates) object:nil];
	[rates makeObjectsPerformSelector:@selector(calcRate:) withObject:objectKeepingCount];

	NSEnumerator* e = [rates objectEnumerator];
	id obj;
	double newTotalRate = 0;
	while(obj=[e nextObject]){
		newTotalRate += [obj rate];
	}
	[self setTotalRate:newTotalRate];
	[self performSelector:@selector(calcRates) withObject:nil afterDelay:integrationTime];
}

- (void) resetRates
{
	[rates makeObjectsPerformSelector:@selector(reset)];
	[self setTotalRate:0];
}


- (void) collectTimeRate
{
	[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(collectTimeRate) object:nil];
	[timeRate addDataToTimeAverage:totalRate];
	[self performSelector:@selector(collectTimeRate) withObject:self afterDelay:2.0];
}

#pragma mark •••Archival
static NSString *ORRateGroupRateArray 		= @"ORRateGroupRateArray";
static NSString *ORRateGroupIntegrationTime = @"ORRateGroupIntegrationTime";
static NSString *ORRateGroupTag 			= @"ORRateGroupTag";
static NSString *ORGroupRate_TimeRate 		= @"ORGroupRate_TimeRate";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    [self setRates:[decoder decodeObjectForKey:ORRateGroupRateArray]];
    [self setIntegrationTime:[decoder decodeDoubleForKey:ORRateGroupIntegrationTime]];
    [self setTag:[decoder decodeIntForKey:ORRateGroupTag]];
    [self setTimeRate:[decoder decodeObjectForKey:ORGroupRate_TimeRate]];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:[self rates] forKey:ORRateGroupRateArray];
    [encoder encodeDouble:[self integrationTime] forKey:ORRateGroupIntegrationTime];
    [encoder encodeInt:[self tag] forKey:ORRateGroupTag];
    [encoder encodeObject:[self timeRate] forKey:ORGroupRate_TimeRate];
}

@end
