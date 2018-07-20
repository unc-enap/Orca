//
//  ORMJDDewarScaleModel.m
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
#import "ORMJDDewarScaleModel.h"
#import "ORTimeRate.h"
#import "ORAlarm.h"

NSString* ORMJDDewarScaleIsConnectedChanged     = @"ORMJDDewarScaleIsConnectedChanged";
NSString* ORMJDDewarScaleIpAddressChanged		= @"ORMJDDewarScaleIpAddressChanged";
NSString* ORMJDDewarScalePollingTimesChanged    = @"ORMJDDewarScalePollingTimesChanged";
NSString* ORMJDDewarScaleLock                   = @"ORMJDDewarScaleLock";
NSString* ORMJDDewarScaleDataValidChanged       = @"ORMJDDewarScaleDataValidChanged";
NSString* ORMJDDewarScaleUsernameChanged        = @"ORMJDDewarScaleUsernameChanged";
NSString* ORMJDDewarScaleHiLimitChanged         = @"ORMJDDewarScaleHiLimitChanged";
NSString* ORMJDDewarScaleLowLimitChanged		= @"ORMJDDewarScaleLowLimitChanged";
NSString* ORMJDDewarScaleValueChanged           = @"ORMJDDewarScaleValueChanged";

@interface ORMJDDewarScaleModel (private)
- (void) postCouchDBRecord;
@end

@implementation ORMJDDewarScaleModel

@synthesize lastTimePolled,nextPollScheduled,dataValid;

- (void) makeMainController
{
    [self linkToController:@"ORMJDDewarScaleController"];
}

- (void) dealloc
{
 	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [dataInValidAlarm   clearAlarm];
    [dataInValidAlarm   release];
    
    int i;
    for(i=0;i<kNumMJDDewarScaleChannels;i++){
        [timeRate[i] release];
    }
    
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDDewarScalePollingTimesChanged object:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"MJDDewarScale"]];
}

#pragma mark ***Accessors
- (unsigned int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(unsigned int)aPollTime
{
    
    if(aPollTime==0 || aPollTime>=kMJDDewarScalePollTime)aPollTime = kMJDDewarScalePollTime;
    
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
    if(![aIpAddress isEqualToString:ipAddress]){
        [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
        
        [ipAddress autorelease];
        ipAddress = [aIpAddress copy];
	
        [self performSelector:@selector(pollHardware) withObject:nil afterDelay:5];
    
    
        [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDDewarScaleIpAddressChanged object:self];
    }
}
- (float) value:(int)i
{
    if(i>=0 && i<kNumMJDDewarScaleChannels)return value[i];
    else return 0;
}
- (float) weight:(int)i
{
    if(i>=0 && i<kNumMJDDewarScaleChannels)return weight[i];
    else return 0;
}
- (void) setDataValid:(BOOL)aState
{
    dataValid = aState;
    if(!dataValid){
        value[0] = 0;
        value[1] = 0;
    }
    [self checkAlarms];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDDewarScaleDataValidChanged object:self];
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
                dataInValidAlarm = [[ORAlarm alloc] initWithName:@"MJD Scale Data Invalid" severity:kHardwareAlarm];
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
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@",ipAddress]]
                completionHandler:^(NSData* data,
                                    NSURLResponse* response,
                                    NSError* error) {
                    NSString* s = [[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding] autorelease];
                    int valueCount = 0;
                    s = [s stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                    s = [s stringByReplacingOccurrencesOfString:@"<!DOCTYPE HTML>\n" withString:@""];
                    s = [s stringByReplacingOccurrencesOfString:@"<html>" withString:@""];
                    s = [s stringByReplacingOccurrencesOfString:@"</html>" withString:@""];
                    s = [s stringByReplacingOccurrencesOfString:@"<br />" withString:@""];
                    NSArray* lines = [s componentsSeparatedByString:@"\n"];
                    for(NSString* aLine in lines){
                        if([aLine length]>0){
                            NSArray* parts = [aLine componentsSeparatedByString:@" "];
                            if([parts count]>=4){
                                int aScale = [[parts objectAtIndex:1] intValue];
                                int adc = [[parts objectAtIndex:3] intValue];
                                //float lbs = 0.7423*adc - 398.88;
                                
                                if(aScale>=0 && aScale <kNumMJDDewarScaleChannels){
                                    valueCount++;
                                    
                                    float lbs;
                                    if(aScale == 0) lbs = 1.223*adc - 478.9;
                                    else            lbs = 1.194*adc - 462.6;
                                    
                                    float aValue = ((lbs - 23.0)/307.0)*100.;
                                    
                                    if(lbs<0)lbs = 0;
                                    if(aValue<0)aValue=0;
                                    else if(aValue>100)aValue=100;
                                    
                                    if(aValue!=value[aScale]){
                                        value[aScale]  = aValue;
                                        weight[aScale] = lbs;
                                        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                                        [userInfo setObject:[NSNumber numberWithInt:aScale] forKey: @"Channel"];
                                        [[NSNotificationCenter defaultCenter] postNotificationName:ORMJDDewarScaleValueChanged object:self userInfo:userInfo];
                                        
                                        if(timeRate[aScale] == nil){
                                            timeRate[aScale] = [[ORTimeRate alloc] init];
                                            [timeRate[aScale] setSampleTime: [self pollTime]];
                                        }
                                        [timeRate[aScale] addDataToTimeAverage:value[aScale]];

                                    }
                                }
                            }
                        }
                    }
                    [self setDataValid:valueCount==kNumMJDDewarScaleChannels];
                    [self postCouchDBRecord];
                }] resume];
        
        [self performSelector:@selector(pollHardware) withObject:nil afterDelay:[self pollTime]];
        [self setNextPollScheduled:[NSDate dateWithTimeIntervalSinceNow:[self pollTime]]];
        [self setLastTimePolled:[NSDate date]];
    }
    else [self setDataValid:NO];
}



#pragma mark ***Delegate Methods
- (ORTimeRate*)timeRate:(int)aChannel
{
    if(aChannel>=0 && aChannel<kNumMJDDewarScaleChannels) return timeRate[aChannel];
    else return nil;
}

#pragma mark •••Process Limits
- (float) lowLimit:(int)i
{
	if(i>=0 && i<kNumMJDDewarScaleChannels)return lowLimit[i];
	else return 0;
}

- (void) setLowLimit:(int)i value:(float)aValue
{
	if(i>=0 && i<kNumMJDDewarScaleChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:i value:lowLimit[i]];
		
		lowLimit[i] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDDewarScaleLowLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) hiLimit:(int)i
{
	if(i>=0 && i<kNumMJDDewarScaleChannels)return hiLimit[i];
	else return 0;
}

- (void) setHiLimit:(int)i value:(float)aValue
{
	if(i>=0 && i<kNumMJDDewarScaleChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setHiLimit:i value:lowLimit[i]];
		
		hiLimit[i] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORMJDDewarScaleHiLimitChanged object:self userInfo:userInfo];
		
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
		s= [NSString stringWithFormat:@"MJDDewarScale,%u",[self uniqueIdNumber]];
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

- (BOOL) processValue:(int)channel
{
	BOOL theValue = 0;
	@synchronized(self){
        return [self convertedValue:channel];
	}
	return theValue;
}

- (double) convertedValue:(int)aChan
{
	double theValue = 0;
	@synchronized(self){
        return [self weight:aChan];
    }
	return theValue;
}

- (void) setProcessOutput:(int)aChan value:(int)aValue
{ /*nothing to do*/ }

- (double) maxValueForChan:(int)aChan
{
    return 350;
}

- (double) minValueForChan:(int)aChan
{
    return 20;
}

- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		if(channel < kNumMJDDewarScaleChannels){
			*theLowLimit  = lowLimit[channel];
			*theHighLimit =  hiLimit[channel];
		}
	}
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    pollTime = kMJDDewarScalePollTime;
    
    [[self undoManager] disableUndoRegistration];
	[self setIpAddress:[decoder decodeObjectForKey:@"ipAddress"]];
    int i;
    for(i=0;i<kNumMJDDewarScaleChannels;i++) {

		[self setLowLimit:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"lowLimit%d",i]]];
		[self setHiLimit:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"hiLimit%d",i]]];
	}

    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:ipAddress forKey:@"ipAddress"];
    int i;
	for(i=0;i<kMJDDewarScalePollTime;i++) {
		[encoder encodeFloat:lowLimit[i] forKey:[NSString stringWithFormat:@"lowLimit%d",i]];
		[encoder encodeFloat:hiLimit[i] forKey:[NSString stringWithFormat:@"hiLimit%d",i]];
	}
}

@end

@implementation ORMJDDewarScaleModel (private)
- (void) postCouchDBRecord
{
    NSMutableDictionary* couchRecord = [NSMutableDictionary dictionary];
    NSArray* levels = [NSArray arrayWithObjects:[NSNumber numberWithFloat:value[0]],[NSNumber numberWithFloat:value[1]],nil];
    NSArray* weights = [NSArray arrayWithObjects:[NSNumber numberWithFloat:weight[0]],[NSNumber numberWithFloat:weight[1]],nil];
    [couchRecord setObject:[NSNumber numberWithInt:30] forKey:@"pollTime"];
    [couchRecord setObject:levels forKey:@"Levels"];
    [couchRecord setObject:weights forKey:@"Weights"];
    [couchRecord setObject:[NSNumber numberWithBool:dataValid] forKey:@"dataValid"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:couchRecord];
}
@end

