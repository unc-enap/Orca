//
//  ORDetectorSegment.m
//  Orca
//
//  Created by Mark Howe on 11/27/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORDetectorSegment.h"
#import "ORCard.h"
#import "ORRate.h"
#import "ORRateGroup.h"

#define mapKey(A) [self mapEntry:A forKey:@"key"]

NSString* KSegmentRateChangedNotification = @"KSegmentRateChangedNotification";
NSString* KSegmentChangedNotification	  =	@"KSegmentChangedNotification";

@implementation ORDetectorSegment

#pragma mark ¥¥¥Initialization

- (id) init {
    self = [super init];
    crateIndex      = -1; //default is none
    cardIndex       = kCardSlot;
    channelIndex    = kChannel;
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [params release];
	[shape release];
	[errorShape release];
	[mapEntries release];
	[identifier release];
    [super dealloc];
}

#pragma mark ¥¥¥Accessors
- (void) setIdentifier:(NSString*)newIdentifier
{
	[identifier autorelease];
	identifier = [newIdentifier copy];
}

- (NSString*) identifier
{
	return identifier;
}

- (void) setMapEntries:(NSArray*)someMapEntries
{
	[mapEntries autorelease];
    mapEntries = [someMapEntries retain];
}

- (NSArray*) mapEntries
{
	return mapEntries;
}
	
- (id) mapEntry:(int)index forKey:(id)aKey
{
	return [[mapEntries objectAtIndex:index] objectForKey:aKey];
}

- (id) validatedParamForKey:(id)aKey
{
    NSString* anEntry = [params objectForKey:aKey];
    if([anEntry length]==0 || [anEntry rangeOfString:@"-"].location!=NSNotFound)return nil;
    else return anEntry;
}

- (BOOL) hardwarePresent
{
	return hardwareCard!=nil;
}

- (void) setShape:(NSBezierPath*)aPath
{
	[aPath retain];
	[shape release];
	shape = aPath;
}

- (void) setErrorShape:(NSBezierPath*)aPath
{
	[aPath retain];
	[errorShape release];
	errorShape = aPath;
}

- (NSString*) name
{
	return [params objectForKey:mapKey(kName)];
}

- (void) setCrateIndex:(int)aValue
{
    crateIndex = aValue;
}

- (int) crateIndex
{
    return crateIndex;
}

- (void) setCardIndex:(int)aValue
{
    cardIndex = aValue;
}

- (int) cardIndex
{
    return cardIndex;
}

- (void) setChannelIndex:(int)aValue
{
    channelIndex = aValue;
}

- (int) channelIndex
{
    return channelIndex;
}

- (unsigned long) threshold
{
	int channel = [[params objectForKey:mapKey(channelIndex)] intValue];
	if(channel>=0) return [hardwareCard thresholdForDisplay:channel];
	else return 0;
}

- (void) setThreshold:(id)aValue
{
	if(!hardwareCard)return;
	id channel = [self objectForKey:@"kChannel"];
	NSInvocation* setter = [NSInvocation invocationWithMethodSignature:[(NSObject*)hardwareCard methodSignatureForSelector:@selector(setThreshold:withValue:)]];
	[setter setSelector:@selector(setThreshold:withValue:)];
	[setter setTarget:hardwareCard];
	[setter setArgument:0  to:channel];
	[setter setArgument:1  to:aValue];
	[setter invoke];
	
}

- (short) gain
{
	int channel = [[params objectForKey:mapKey(channelIndex)] intValue];
	if(channel>=0)return [hardwareCard gainForDisplay:channel];
	else return 0;
}
- (void) setGain:(id)aValue
{
	if(!hardwareCard)return;
	id channel = [self objectForKey:@"kChannel"];
	NSInvocation* setter = [NSInvocation invocationWithMethodSignature:[(NSObject*)hardwareCard methodSignatureForSelector:@selector(setGain:withValue:)]];
	[setter setSelector:@selector(setGain:withValue:)];
	[setter setTarget:hardwareCard];
	[setter setArgument:0  to:channel];
	[setter setArgument:1  to:aValue];
	[setter invoke];
	
}

- (BOOL) partOfEvent
{
	int channel = [[params objectForKey:mapKey(channelIndex)] intValue];
	if(channel>=0)return [hardwareCard partOfEvent:channel];
	else return 0;
}

- (float) totalCounts
{
	int channel = [[params objectForKey:mapKey(channelIndex)] intValue];
	if(channel>=0){
		return (float)[hardwareCard eventCount:channel];
	}
	else return 0;
}

- (void) clearTotalCounts
{
	[hardwareCard clearEventCounts];
}

- (float) rate
{
    return rate;
}

- (void) setRate:(float)newRate
{
    rate=newRate;
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:KSegmentRateChangedNotification
                      object:self];
}

- (BOOL) segmentError
{
	return segmentError;
}

- (void) setSegmentError:(BOOL)state
{
	segmentError = state;
}
- (void) clearSegmentError
{
	segmentError = NO;
}
- (void) setSegmentError
{
	segmentError = YES;
}

- (BOOL) isValid
{
    return isValid;
}

- (void) setIsValid:(BOOL)newIsValid
{
    isValid=newIsValid;
}
- (NSMutableDictionary *) params
{
    return params;
}

- (void) setParams: (NSMutableDictionary *) aParams
{
	[aParams retain];
    [params release];
    params = aParams;
}

- (void) decodeLine:(NSString*)aString
{
    if(!params){
        [self setParams:[NSMutableDictionary dictionary]];
    }
    NSArray* items = [aString componentsSeparatedByString:@","];
    int i;
    int count = [items count];
	if(count == 5){
		//old format
		int x = [[items objectAtIndex:0] intValue];
		int y = [[items objectAtIndex:1] intValue];
		[params setObject:[NSNumber numberWithInt:x + (y*8)] forKey:mapKey(0)];
		[params setObject:[items objectAtIndex:2] forKey:mapKey(1)];
		[params setObject:[items objectAtIndex:3] forKey:mapKey(2)];
		isValid = YES;
	}
	else {
		int n = MIN(count,[mapEntries count]);
		for(i=0;i<n;i++){
			[params setObject:[items objectAtIndex:i] forKey:mapKey(i)];
		}
		isValid = YES;
    }
    
}

- (NSString*) paramHeader
{
	NSMutableString* aHeader = [NSMutableString string];
	int i;
	for(i=0;i<[mapEntries count];i++){
		[aHeader appendFormat:@"%@,",mapKey(i)];
	}
	if([aHeader length]>0){
		[aHeader deleteCharactersInRange:NSMakeRange([aHeader length]-1,1)];
		[aHeader appendString:@"\n"];
	}
	return aHeader;
}

- (NSString*) paramsAsString
{
	NSString* result = [NSString string];
	int i;
	for(i=0;i<[mapEntries count];i++){
        id aKey = mapKey(i);
		id aParam = [params objectForKey:aKey];
		if(aParam) result = [result stringByAppendingFormat:@"%@",aParam];
		else result = [result stringByAppendingString:@"--"];
		if(i<[mapEntries count]-1)result = [result stringByAppendingString:@","];
	}
	return result;
}

- (BOOL) online
{
	return online;
}
- (BOOL) hwPresent
{
	return hwPresent;
}
- (void) setHwPresent:(BOOL)state
{
	hwPresent = state;
}

- (NSUndoManager*) undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}
- (id) hardwareCard
{
	return hardwareCard;
}

- (NSString*) hardwareClassName
{
	return [(NSObject*)hardwareCard className];
}

- (int) cardSlot
{
	NSNumber* num = [self objectForKey:mapKey(cardIndex)];
	if(!num)return -1;
	else return [num intValue];
}

- (int) channel
{
	NSString* s = [self objectForKey:mapKey(channelIndex)];
	if([s isEqualToString:@"--"])return -1;
	else if(!s)return -1;
	else return [s intValue];
}


-(id) objectForKey:(id)key
{
	if([key isEqualToString:@"threshold"]){
		if(hardwareCard) return [NSNumber numberWithInt:[self threshold]];
		else return @"--";
	}
	else if([key isEqualToString:@"gain"]){
		if(hardwareCard) return [NSNumber numberWithInt:[self gain]];
		else return @"--";
	}
	else {
		id obj =  [params objectForKey:key];
		if(!obj)					return @"--";
		else if([obj intValue]<0)	return @"--";
		else						return obj;
	}
}

-(void) setObject:(id)obj forKey:(id)key
{
	if(!obj)obj = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setObject:[params objectForKey:key] forKey:key];

	if(!params)[self setParams:[NSMutableDictionary dictionary]];
    [params setObject:obj forKey:key];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:KSegmentChangedNotification object:self];
}

- (void) setSegmentNumber:(NSUInteger)index
{
	if(!params)[self setParams:[NSMutableDictionary dictionary]];
	[params setObject:[NSNumber numberWithInt:index] forKey:@"kSegmentNumber"];
}

- (NSUInteger) segmentNumber
{
	return [[params objectForKey:@"kSegmentNumber"] intValue];
}

- (void) unregisterRates
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) rateChanged:(NSNotification*)note
{
	int channel = [[params objectForKey:@"kChannel"] intValue];
    float r = [[note object] rate:channel];
    if(r != rate)[self setRate:r];
}

- (void) registerForRates:(NSArray*)rateProviders
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter removeObserver : self];
	
    for(ORCard* aCard in rateProviders){
        int theSlot  = [[params objectForKey: mapKey(cardIndex)]intValue];
        int theCrate;
        if(crateIndex>0)theCrate = [[params objectForKey: mapKey(crateIndex)]intValue];
        else theCrate = 0;
		if(theSlot >=0){
			if( theSlot == [aCard displayedSlotNumber] && theCrate == [aCard crateNumber]){
				
				id rateObj = [aCard rateObject:[[params objectForKey: mapKey(channelIndex)]intValue]];
				if(rateObj)[notifyCenter addObserver : self
								 selector : @selector(rateChanged:)
									 name : [rateObj rateNotification]
								   object : rateObj];
				break;
			}
        }
    }
}


- (void) configurationChanged:(NSArray*)adcCards
{
	int card;
	
	//assume the worst
	hwPresent = NO;
	online = NO;
	hardwareCard = nil;
	for(card = 0;card<[adcCards count];card++){
		id aCard = [adcCards objectAtIndex:card];
		if(!aCard)break;
		int theSlot = [[params objectForKey: mapKey(cardIndex)]intValue];
        int theCrate;
        if(crateIndex>0)theCrate = [[params objectForKey: mapKey(crateIndex)]intValue];
        else theCrate = 0;
		if(theSlot>=0){
			if([aCard displayedSlotNumber] == theSlot && [aCard crateNumber] == theCrate){
				hwPresent = YES;
				int chan = [[params objectForKey: mapKey(channelIndex)]intValue];
				if([aCard onlineMaskBit:chan])online = YES;
				hardwareCard = aCard;
				break;
			}
		}
	}
}

- (void) showDialog
{
	[hardwareCard makeMainController];
}

- (id) description
{		
	NSString* string = [NSString stringWithFormat:@"         Segment: %d\n",[self segmentNumber]];
	NSString* theModel = [(NSObject*)hardwareCard className];
	if([theModel hasPrefix:@"OR"]) theModel   = [theModel substringFromIndex:2];
	if([theModel hasSuffix:@"Model"])theModel = [theModel substringToIndex:[theModel length]-[@"Model"length]];
	string = [string stringByAppendingFormat:     @"       Adc Class: %@\n",theModel];
	string = [string stringByAppendingFormat:     @"       Threshold: %lu\n",[self threshold]];
	for(id aKey in params){
		const char *theKeyAsCString = [[aKey substringFromIndex:1] cStringUsingEncoding:NSASCIIStringEncoding];
		NSString* p = [NSString stringWithFormat:   @"%17s: %@\n",theKeyAsCString,[params objectForKey:aKey]];
		string = [string stringByAppendingString:[p substringFromIndex:1]];
	}
	//string = [string stringByAppendingFormat:   @"Slot     : %d\n",[self cardSlot]];
	//string = [string stringByAppendingFormat:   @"Channel  : %d\n",[self channel]];
	//if([self name])string = [string stringByAppendingFormat:   @"Name     : %@\n",[self name]];
	return string;
}


#pragma mark ¥¥¥Achival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    [self setIsValid:[decoder decodeBoolForKey:@"SegmentIsValid"]];
    [self setParams:[decoder decodeObjectForKey:@"SegmentParams"]];
    if(!params){
        [self setParams:[NSMutableDictionary dictionary]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeBool:isValid forKey:@"SegmentIsValid"];
    [encoder encodeObject:params forKey:@"SegmentParams"];
}

@end
