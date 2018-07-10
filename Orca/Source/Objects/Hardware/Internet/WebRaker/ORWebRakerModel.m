//
//  ORWebRakerModel.m
//  Orca
//
//  Created by Mark Howe on Mon Jan 11 2016
//  Copyright (c) 2016 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORWebRakerModel.h"
#import "ORTimeRate.h"
#import "ORAlarm.h"

NSString* ORWebRakerIpAddressChanged	   = @"ORWebRakerIpAddressChanged";
NSString* ORWebRakerPollingTimesChanged    = @"ORWebRakerPollingTimesChanged";
NSString* ORWebRakerLock                   = @"ORWebRakerLock";
NSString* ORWebRakerDataValidChanged       = @"ORWebRakerDataValidChanged";
NSString* ORWebRakerUsernameChanged        = @"ORWebRakerUsernameChanged";
NSString* ORWebRakerHiLimitChanged         = @"ORWebRakerHiLimitChanged";
NSString* ORWebRakerLowLimitChanged		   = @"ORWebRakerLowLimitChanged";
NSString* ORWebRakerValueChanged           = @"ORWebRakerValueChanged";
NSString* ORWebRakerMinValueChanged        = @"ORWebRakerMinValueChanged";
NSString* ORWebRakerMaxValueChanged        = @"ORWebRakerMaxValueChanged";

@interface ORWebRakerModel (private)
- (void) postCouchDBRecord;
@end

@implementation ORWebRakerModel

@synthesize lastTimePolled,nextPollScheduled,dataValid;

- (void) makeMainController
{
    [self linkToController:@"ORWebRakerController"];
}

- (void) dealloc
{
 	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [dataInValidAlarm   clearAlarm];
    [dataInValidAlarm   release];
    [hiLimits release];
    [lowLimits release];
    [minValues release];
    [maxValues release];
    [timeRates release];
    [data release];
    //release the properties (newer code)
    self.lastTimePolled         = nil;
    self.nextPollScheduled      = nil;
    
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
        [self performSelector:@selector(pollHardware) withObject:nil afterDelay:3];
	}
	@catch(NSException* localException) {
	}
}

- (void) setLastTimePolled:(NSDate *)aDate
{
    [aDate retain];
    [lastTimePolled release];
    lastTimePolled = aDate;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORWebRakerPollingTimesChanged object:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"WebRaker"]];
}

#pragma mark ***Accessors
- (unsigned int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(unsigned int)aPollTime
{
    if(aPollTime==0 || aPollTime>=kWebRakerPollTime)aPollTime = kWebRakerPollTime;
    
    pollTime = aPollTime;
    [self pollHardware];
}

- (NSString*) ipAddress
{
    if([ipAddress length]==0)return @"";
    else return ipAddress;
}

- (void) setIpAddress:(NSString*)aIpAddress
{
	if(!aIpAddress)aIpAddress = @"";
    aIpAddress = [aIpAddress stringByReplacingOccurrencesOfString:@"http://" withString:@""];
    if(![aIpAddress isEqualToString:ipAddress]){
        [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
        
        [ipAddress autorelease];
        ipAddress = [aIpAddress copy];
	
        [self performSelector:@selector(pollHardware) withObject:nil afterDelay:5];
    
    
        [[NSNotificationCenter defaultCenter] postNotificationName:ORWebRakerIpAddressChanged object:self];
    }
}
- (NSInteger) numDataItems
{
    NSInteger count = 0;
    @synchronized (self) {
        count = [data count];
    }
    return count;
}

- (NSDictionary*) dataAtIndex:(int)index
{
    NSDictionary* theData = nil;
    @synchronized (self) {
        if(index>=0 && index < [self numDataItems]){
            theData = [[[data objectAtIndex:index]copy] autorelease];
        }
    }
    return theData;;
}


- (void) setDataValid:(BOOL)aState
{
    if(aState!=dataValid){
        dataValid = aState;
        [self checkAlarms];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORWebRakerDataValidChanged object:self];
    }
}

- (void) checkAlarms
{
    if(dataValid || ([ipAddress length]!=0)){
        if([dataInValidAlarm isPosted]){
            [dataInValidAlarm clearAlarm];
            [dataInValidAlarm release];
            dataInValidAlarm = nil;
        } 
    }
    else {
        if([ipAddress length]!=0){
            if(!dataInValidAlarm){
                dataInValidAlarm = [[ORAlarm alloc] initWithName:@"Web Raker Data Invalid" severity:kHardwareAlarm];
                [dataInValidAlarm setSticky:YES];
            }
            [dataInValidAlarm postAlarm];
        }
    }
    if(dataValid){
        [dataInValidAlarm clearAlarm];
        [dataInValidAlarm release];
        dataInValidAlarm = nil;
    }
}
- (void) pollHardware
{
    if([ipAddress length]!=0){
        @synchronized (self) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
            NSURLSessionDataTask* downloadTask =[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@",ipAddress]]
                completionHandler:^(NSData* theData,
                                    NSURLResponse* response,
                                    NSError* error) {
                    if(error == nil){
                        dispatch_async(dispatch_get_main_queue(), ^{[self processData:theData];});
                    }
                    else {
                        dispatch_async(dispatch_get_main_queue(), ^{[self processData:nil];});
                    }
                }];
            [downloadTask resume];
            [self performSelector:@selector(pollHardware) withObject:nil afterDelay:[self pollTime]];
            [self setNextPollScheduled:[NSDate dateWithTimeIntervalSinceNow:[self pollTime]]];
            [self setLastTimePolled:[NSDate date]];
       }
    }
    else {
        [self setDataValid:NO];
    }
}
- (void) processData:(NSData*)theData
{
    @try {
        @synchronized (self) {
            
            NSError* error = nil;
            NSString* s= [[[NSString alloc] initWithData:theData
                                                  encoding:NSUTF8StringEncoding] autorelease];
            s = [s stringByReplacingOccurrencesOfString:@"'" withString:@"\""];
            NSData* test = [s dataUsingEncoding:NSASCIIStringEncoding];
        
            NSArray* theNewData = [[NSJSONSerialization JSONObjectWithData:test options:0 error:&error]retain];
        
            if(theNewData){
                
                [data autorelease];
                data = [theNewData retain];
                
                int i;
                //make sure all the array sizes are the same as the data set
                int lowLimitCountDiff = [data count] - [lowLimits count];
                if(lowLimitCountDiff < 0)for(i=0;i<lowLimitCountDiff;i++)[lowLimits removeLastObject];
                if(lowLimitCountDiff > 0)for(i=0;i<lowLimitCountDiff;i++)[lowLimits addObject:[NSNumber numberWithFloat:0]];
                
                int hiLimitCountDiff = [data count] - [hiLimits count];
                if(hiLimitCountDiff < 0)for(i=0;i<hiLimitCountDiff;i++)[hiLimits removeLastObject];
                if(hiLimitCountDiff > 0)for(i=0;i<hiLimitCountDiff;i++)[hiLimits addObject:[NSNumber numberWithFloat:0]];
         
                int minValueCountDiff = [data count] - [minValues count];
                if(minValueCountDiff < 0)for(i=0;i<minValueCountDiff;i++)[minValues removeLastObject];
                if(minValueCountDiff > 0)for(i=0;i<minValueCountDiff;i++)[minValues addObject:[NSNumber numberWithFloat:0]];

                int maxValueCountDiff = [data count] - [maxValues count];
                if(maxValueCountDiff < 0)for(i=0;i<maxValueCountDiff;i++)[maxValues removeLastObject];
                if(maxValueCountDiff > 0)for(i=0;i<maxValueCountDiff;i++)[maxValues addObject:[NSNumber numberWithFloat:0]];

                
                int timeRateCountDiff = [data count] - [timeRates count];
                if(timeRateCountDiff < 0)for(i=0;i<timeRateCountDiff;i++)[timeRates removeLastObject];
                if(timeRateCountDiff > 0)for(i=0;i<timeRateCountDiff;i++){
                    if(!timeRates)timeRates = [[NSMutableArray alloc] init];
                    ORTimeRate* aTimeRate = [[[ORTimeRate alloc] init] autorelease];
                    [timeRates addObject:aTimeRate];
                    [aTimeRate setSampleTime: [self pollTime]];
                }
                
                //update the values in the plots
                for(i=0;i<[data count];i++){
                    float theValue = [[[data objectAtIndex:i]objectForKey:@"value"] floatValue];
                    [[timeRates objectAtIndex:i] addDataToTimeAverage:theValue];
                }
                [self setDataValid:YES];
                [self postCouchDBRecord];
            }
            else [self setDataValid:NO];
        }
    }
    @catch(NSException* e){
        [self setDataValid:NO];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORWebRakerValueChanged object:self];
}

#pragma mark ***Delegate Methods
- (ORTimeRate*)timeRate:(int)aChannel
{
    if(aChannel>=0 && aChannel<[timeRates count]) return [timeRates objectAtIndex:aChannel];
    else return nil;
}

#pragma mark •••Process Limits
- (float) lowLimit:(int)i
{
	if(i>=0 && i<[lowLimits count])return [[lowLimits objectAtIndex:i]floatValue];
	else return 0;
}

- (void) setLowLimit:(int)i value:(float)aValue
{
	if(i>=0 && i<[lowLimits count]){
        [[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:i value:[self lowLimit:i]];
		
         [lowLimits replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:aValue]];
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORWebRakerLowLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) hiLimit:(int)i
{
    if(i>=0 && i<[hiLimits count])return [[hiLimits objectAtIndex:i]floatValue];
	else return 0;
}

- (void) setHiLimit:(int)i value:(float)aValue
{
    if(i>=0 && i<[hiLimits count]){
        [[[self undoManager] prepareWithInvocationTarget:self] setHiLimit:i value:[self hiLimit:i]];
		
        [hiLimits replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:aValue]];
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORWebRakerHiLimitChanged object:self userInfo:userInfo];
		
	}
}
//---
- (float) minValue:(int)i
{
    if(i>=0 && i<[minValues count])return [[minValues objectAtIndex:i]floatValue];
    else return 0;
}

- (void) setMinValue:(int)i value:(float)aValue
{
    if(i>=0 && i<[minValues count]){
        [[[self undoManager] prepareWithInvocationTarget:self] setMinValue:i value:[self minValue:i]];
        
        [minValues replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:aValue]];
        
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORWebRakerMinValueChanged object:self userInfo:userInfo];
        
    }
}

- (float) maxValue:(int)i
{
    if(i>=0 && i<[maxValues count])return [[maxValues objectAtIndex:i]floatValue];
    else return 0;
}

- (void) setMaxValue:(int)i value:(float)aValue
{
    if(i>=0 && i<[maxValues count]){
        [[[self undoManager] prepareWithInvocationTarget:self] setMaxValue:i value:[self maxValue:i]];
        
        [maxValues replaceObjectAtIndex:i withObject:[NSNumber numberWithInt:aValue]];
        
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORWebRakerMaxValueChanged object:self userInfo:userInfo];
    }
}


#pragma mark •••Bit Processing Protocol
- (void) startProcessCycle { }
- (void) endProcessCycle   { }
- (void) processIsStarting { }
- (void) processIsStopping {}


- (NSString*) identifier
{
	NSString* s;
 	@synchronized(self){
		s= [NSString stringWithFormat:@"WebRaker,%lu",[self uniqueIdNumber]];
	}
	return s;
}

- (NSString*) processingTitle
{
	NSString* s;
 	@synchronized(self){
		s= [self identifier];
	}
	return s;
}

- (BOOL) processValue:(int)aChan
{
	BOOL theValue = 0;
	@synchronized(self){
        if(aChan>=0 && aChan<[data count]){
            theValue = [[[data objectAtIndex:aChan]objectForKey:@"value"] floatValue];
        }
	}
	return theValue;
}

- (double) convertedValue:(int)aChan
{
    return [self processValue:aChan];
}

- (void) setProcessOutput:(int)aChan value:(int)aValue
{ /*nothing to do*/ }

- (double) maxValueForChan:(int)aChan
{
    double aValue;
    @synchronized(self){
        aValue = [self maxValue:aChan];
    }
    return aValue;
}

- (double) minValueForChan:(int)aChan
{
    double aValue;
    @synchronized(self){
        aValue = [self minValue:aChan];
    }
    return aValue;
}

- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
        float lowLimitValue = [self lowLimit:channel];
        *theLowLimit  = lowLimitValue;
        float hiLimitValue = [self hiLimit:channel];
        *theHighLimit  = hiLimitValue;
	}
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    pollTime = kWebRakerPollTime;
    
    [[self undoManager] disableUndoRegistration];
	[self setIpAddress:[decoder decodeObjectForKey:@"ipAddress"]];
    lowLimits  = [[decoder decodeObjectForKey:@"lowLimits"]retain];
    hiLimits   = [[decoder decodeObjectForKey:@"hiLimits"]retain];
    minValues  = [[decoder decodeObjectForKey:@"minValues"]retain];
    maxValues  = [[decoder decodeObjectForKey:@"maxValues"]retain];

    if(!lowLimits)lowLimits     = [[NSMutableArray alloc] init];
    if(!hiLimits) hiLimits      = [[NSMutableArray alloc] init];
    if(!minValues) minValues    = [[NSMutableArray alloc] init];
    if(!maxValues) maxValues    = [[NSMutableArray alloc] init];
    
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:ipAddress forKey:@"ipAddress"];
    [encoder encodeObject:lowLimits forKey:@"lowLimits"];
    [encoder encodeObject:hiLimits  forKey:@"hiLimits"];
    [encoder encodeObject:minValues forKey:@"minValues"];
    [encoder encodeObject:maxValues forKey:@"maxValues"];
}

@end

@implementation ORWebRakerModel (private)
- (void) postCouchDBRecord
{
   	@synchronized(self){
        NSMutableDictionary* couchRecord = [NSMutableDictionary dictionary];
        [couchRecord setObject:[NSNumber numberWithInt:pollTime] forKey:@"pollTime"];
        [couchRecord setObject:data forKey:@"data"];
        [couchRecord setObject:[NSNumber numberWithBool:dataValid] forKey:@"dataValid"];
    
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:couchRecord];
    }
}
@end

