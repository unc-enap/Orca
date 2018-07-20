//
//  ORApcUpsModel.m
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2008
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
#import "ORApcUpsModel.h"
#import "NetSocket.h"
#import "ORTimeRate.h"
#import "ORFileGetterOp.h"
#import "NetSocket.h"
#import "ORAlarm.h"
#import "ORScriptTaskModel.h"

NSString* ORApcUpsModelMaintenanceModeChanged = @"ORApcUpsModelMaintenanceModeChanged";
NSString* ORApcUpsModelEventLogChanged  = @"ORApcUpsModelEventLogChanged";
NSString* ORApcUpsIsConnectedChanged	= @"ORApcUpsIsConnectedChanged";
NSString* ORApcUpsIpAddressChanged		= @"ORApcUpsIpAddressChanged";
NSString* ORApcUpsRefreshTables         = @"ORApcUpsRefreshTables";
NSString* ORApcUpsPollingTimesChanged   = @"ORApcUpsPollingTimesChanged";
NSString* ORApcUpsTimedOut              = @"ORApcUpsTimedOut";
NSString* ORApcUpsLock                  = @"ORApcUpsLock";
NSString* ORApcUpsDataValidChanged      = @"ORApcUpsDataValidChanged";
NSString* ORApcUpsUsernameChanged       = @"ORApcUpsUsernameChanged";
NSString* ORApcUpsPasswordChanged       = @"ORApcUpsPasswordChanged";
NSString* ORApcUpsHiLimitChanged		= @"ORApcUpsHiLimitChanged";
NSString* ORApcUpsLowLimitChanged		= @"ORApcUpsLowLimitChanged";

@interface ORApcUpsModel (private)
- (void) postCouchDBRecord;
- (void) clearInputBuffer;
- (void) parse:(NSString*)aResponse;
- (void) parseLine:(NSString*)aLine;
- (void) startTimeout;
- (void) cancelTimeout;
- (void) timeout;
- (ORScriptTaskModel*)       findShutdownScript;
- (id)                      findObject:(NSString*)aClassName;
@end

#define kApcEventsPath [@"~/ApcEvents.txt" stringByExpandingTildeInPath]
#define kApcDataPath   [@"~/ApcData.txt"   stringByExpandingTildeInPath]
#define KMinVoltage       100

@implementation ORApcUpsModel

@synthesize valueDictionary,lastTimePolled,nextPollScheduled,dataValid,password,username;

- (void) makeMainController
{
    [self linkToController:@"ORApcUpsController"];
}

- (void) dealloc
{
 	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [eventLog release];
    [sortedEventLog release];
    [dataInValidAlarm   clearAlarm];
    [powerOutAlarm      clearAlarm];
    [badStatusAlarm      clearAlarm];
    
    [badStatusAlarm   release];
    [dataInValidAlarm   release];
    [powerOutAlarm      release];
    [inputBuffer        release];
    [sayIt              release];
    [socket             release];
    [channelFromNameTable release];
    
    int i;
    for(i=0;i<8;i++){
        [timeRate[i] release];
    }
    
    //release the properties (newer code)
    self.valueDictionary        = nil;
    self.username               = nil;
    self.password               = nil;
    self.lastTimePolled         = nil;
    self.nextPollScheduled      = nil;
    
    [fileQueue cancelAllOperations];
    [fileQueue release];

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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsPollingTimesChanged object:self];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"ApcUpsIcon"]];
}

#pragma mark ***Accessors

- (BOOL) maintenanceMode
{
    return maintenanceMode;
}

- (void) setMaintenanceMode:(BOOL)aMaintenanceMode
{
    maintenanceMode = aMaintenanceMode;
    
    if(aMaintenanceMode){
        [self setDataValid:NO];
        [self performSelector:@selector(cancelMaintenanceMode) withObject:nil afterDelay:30*60];
        NSLogColor([NSColor redColor],@"Started maintenance on %@\n",[self fullID]);
        //also force update of times
        [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsPollingTimesChanged object:self];
    }
    else {
        NSLog(@"Ended maintenance on %@\n",[self fullID]);
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelMaintenanceMode) object:nil];
        [self performSelector:@selector(pollHardware) withObject:nil afterDelay:2];
     }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsModelMaintenanceModeChanged object:self];
    
    
}

- (void) cancelMaintenanceMode
{
    [self setMaintenanceMode:NO];
}

- (NetSocket*) socket
{
	return socket;
}

- (void) setSocket:(NetSocket*)aSocket
{
	if(aSocket != socket)[socket close];
	[aSocket retain];
	[socket release];
	socket = aSocket;
    [socket setDelegate:self];
}

- (unsigned int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(unsigned int)aPollTime
{
    
    if(aPollTime==0 || aPollTime>=kApcPollTime)aPollTime = kApcPollTime;
    
    pollTime = aPollTime;
    [self pollHardware];
}

- (NSMutableSet*) eventLog
{
    return eventLog;
}

- (void) setEventLog:(NSMutableSet*)aEventLog
{
    [aEventLog retain];
    [eventLog release];
    eventLog = aEventLog;

    [self sortEventLog];
    
}

- (void) sortEventLog
{
    [sortedEventLog release];
    sortedEventLog = [[[eventLog allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] retain];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsModelEventLogChanged object:self];
}

- (NSArray*) sortedEventLog
{
    return sortedEventLog;
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
    
    
        [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsIpAddressChanged object:self];
    }
}

- (void) setUsername:(NSString *)aName
{
	if(!aName)aName = @"";
    if(![aName isEqualToString:username]){
        [[[self undoManager] prepareWithInvocationTarget:self] setUsername:username];
        [username autorelease];
        username = [aName copy];
        [self performSelector:@selector(pollHardware) withObject:nil afterDelay:5];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsUsernameChanged object:self];
    }
}

- (void) setPassword:(NSString *)aPassword
{
 	if(!aPassword)aPassword = @"";
    if(![aPassword isEqualToString:password]){
        [[[self undoManager] prepareWithInvocationTarget:self] setPassword:password];
        [password autorelease];
        password = [aPassword copy];
        [self performSelector:@selector(pollHardware) withObject:nil afterDelay:5];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsPasswordChanged object:self];
    }
}


- (void) setDataValid:(BOOL)aState
{
    dataValid = aState;
    if(!dataValid){
        //clear the variables that are being monitored
        [valueDictionary release];
        valueDictionary = nil;
    }
    [self checkAlarms];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsDataValidChanged object:self];
}

- (void) checkAlarms
{
    if(dataValid || ([ipAddress length]!=0 && [password length]!=0 && [username length]!=0)){
        if([dataInValidAlarm isPosted]){
            [dataInValidAlarm clearAlarm];
            [dataInValidAlarm release];
            dataInValidAlarm = nil;
        }
    }
    else {
        if([ipAddress length]!=0 && [password length]!=0 && [username length]!=0){
            if(!dataInValidAlarm){
                dataInValidAlarm = [[ORAlarm alloc] initWithName:@"UPS Data Invalid" severity:kHardwareAlarm];
                [dataInValidAlarm setSticky:YES];
            }
            [dataInValidAlarm postAlarm];
        }
    }
    if(dataValid){
        float Vin1 = [self inputVoltageOnPhase:1];
        float Vin2 = [self inputVoltageOnPhase:2];
        float Vin3 = [self inputVoltageOnPhase:3];
        float bat  = [self batteryCapacity];
        if((Vin1<KMinVoltage) || (Vin2<KMinVoltage) || (Vin3<KMinVoltage)){
            if(!powerOutAlarm){
                NSLog(@"The UPS (%@) is reporting a power failure. Battery capacity is now %.0f%%\n",[self fullID],bat);
                powerOutAlarm = [[ORAlarm alloc] initWithName:@"Power Failure" severity:kEmergencyAlarm];
                [powerOutAlarm setHelpString:@"The UPS is reporting that the input voltage is less then 110V on one or more of the three phases. This Alarm can be silenced by acknowledging it, but it will not be cleared until power is restored."];
                [powerOutAlarm setSticky:YES];
                [powerOutAlarm postAlarm];
                [powerOutAlarm acknowledge]; //use the voice instead of beep
                sayItCount = 0;
                [self startPowerOutSpeech];
                [self startShutdownScript]; //once started, any shutdown runs -- no stopping it.
            }
            if(lastBatteryValue != bat){
                NSLog(@"UPS Battery capacity is now %.0f%%\n",bat);
                lastBatteryValue = bat;
            }
            NSLog(@"UPS Time Remaining: %@\n",[self valueForBattery:0 batteryTableIndex:3]);
            NSLog(@"UPS Load (Amps) L1:%@ L2:%@ L3:%@\n",
                  [self valueForLoadPhase:1 loadTableIndex:1],
                  [self valueForLoadPhase:2 loadTableIndex:1],
                  [self valueForLoadPhase:3 loadTableIndex:1]
                  );

        }
        else {
            if([powerOutAlarm isPosted]){
                [self stopPowerOutSpeech];
                [powerOutAlarm clearAlarm];
                [powerOutAlarm release];
                powerOutAlarm = nil;
                lastBatteryValue = 0;
                NSLog(@"The UPS (%@) is restored. Battery capacity is now %.0f%%\n",[self fullID],bat);
            }
        }
    }
}

- (void)  startShutdownScript
{
    ORScriptTaskModel* theShutdownScript = [self findShutdownScript];
    if(![theShutdownScript running]){
        [theShutdownScript runScriptWithMessage:@"Started From UPS"];
    }
}

- (void)  startPowerOutSpeech
{
    sayItCount = 0;
    [self continuePowerOutSpeech];
}

- (void)  continuePowerOutSpeech
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startPowerOutSpeech) object:nil];
    if(!sayIt)sayIt = [[NSSpeechSynthesizer alloc] initWithVoice:[NSSpeechSynthesizer defaultVoice]];
    if(![sayIt isSpeaking]){
        if(sayItCount==0)[sayIt startSpeakingString:@"There has been a power outage."];
        else [sayIt startSpeakingString:[NSString stringWithFormat:@"The UPS is on battery power. %.0f %% remaining.",[self batteryCapacity]]];
        
        sayItCount ++;
    }
    [self performSelector:@selector(continuePowerOutSpeech) withObject:nil afterDelay:60];
}


- (void)  stopPowerOutSpeech
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(continuePowerOutSpeech) object:nil];
    [sayIt stopSpeaking];
    [sayIt startSpeakingString:@"Power is back up!"];
}

- (BOOL) powerIsOut
{
    if([powerOutAlarm isPosted]){
        NSTimeInterval timePowerHasBeenOut = [powerOutAlarm timeSincePosted];
        if(timePowerHasBeenOut >= 2*60)return YES;
        else return NO;
    }
    else return NO;
}

- (float) inputVoltageOnPhase:(int)aPhase
{
    if(aPhase>=1 && aPhase<=3) return [[self valueForPowerPhase:aPhase  powerTableIndex:0] floatValue];
    else return 0;
}

- (float) batteryCapacity
{
    return [[valueDictionary objectForKey:@"BATTERY CAPACITY"]floatValue];
}

- (void) pollHardware
{
    if([ipAddress length]!=0 && [password length]!=0 && [username length]!=0 && !maintenanceMode){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
        
        [self connect];

        [self performSelector:@selector(pollHardware) withObject:nil afterDelay:[self pollTime]];
        [self setNextPollScheduled:[NSDate dateWithTimeIntervalSinceNow:[self pollTime]]];
        [self setLastTimePolled:[NSDate date]];
        [self performSelector:@selector(getEvents) withObject:nil afterDelay:5];
    }
    else [self setDataValid:NO];
}

- (void) setUpQueue
{
    if(!fileQueue){
        fileQueue = [[NSOperationQueue alloc] init];
        [fileQueue setMaxConcurrentOperationCount:1];
        [fileQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
    }
}

- (void) connect
{
	if(![self isConnected]){
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:kApcUpsPort]];
	}
}

- (void) disconnect
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(disconnect) object:nil];
    [self setSocket:nil];
    [self setIsConnected:[socket isConnected]];
    statusSentOnce = NO;
}

- (void) setIsConnected:(BOOL)aFlag
{
    isConnected = aFlag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsIsConnectedChanged object:self];
}

- (void) getEvents
{
    [self disconnect];
    
    [self setUpQueue];
    if(mover)[mover cancel];
    else {
        mover = [[ORFileGetterOp alloc] init];
        mover.delegate     = self;
        [mover setUseFTP:YES];
        [mover setParams:@"logs/event.txt" localPath:kApcEventsPath ipAddress:ipAddress userName:username passWord:password];
        [mover setDoneSelectorName:@"eventsFileArrived"];
        [fileQueue addOperation:mover];
    }
}

- (BOOL) isConnected
{
    return isConnected || ([fileQueue operationCount]!=0);
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == fileQueue && [keyPath isEqual:@"operations"]) {
        [[NSNotificationCenter defaultCenter]  postNotificationOnMainThreadWithName:ORApcUpsIsConnectedChanged object:self userInfo:nil waitUntilDone:NO];
    }
}

- (void) eventsFileArrived
{
    [mover release];
    mover = nil;
    
    NSStringEncoding* en=nil;
    NSString* contents = [NSString stringWithContentsOfFile:kApcEventsPath usedEncoding:en error:nil];
    NSArray* lines = [contents componentsSeparatedByString:@"\n"];
    int i=0;
    if(!eventLog)[self setEventLog:[NSMutableSet setWithCapacity:500]];
    for(id aLine in lines){
        if(i>=7){
            if([aLine rangeOfString:@"logged"].location != NSNotFound) continue;
            else {
                NSMutableArray* parts = [[aLine componentsSeparatedByString:@"\t"] mutableCopy];
                if([parts count]){
                    NSString* date = [parts objectAtIndex:0];
                    NSArray* dateParts = [date componentsSeparatedByString:@"/"];
                    if([dateParts count]>=3){
                        //reorder the date so it sorts correctly.
                        NSString* newDate = [NSString stringWithFormat:@"%@/%@/%@",[dateParts objectAtIndex:2],[dateParts objectAtIndex:0],[dateParts objectAtIndex:1]];
                        [parts replaceObjectAtIndex:0 withObject:newDate];
                        aLine = [parts componentsJoinedByString:@" "];
                        int len = (int)[aLine length];
                        if(len>6) aLine = [aLine substringToIndex:len-6];
                        [eventLog addObject:aLine];
                    }
                }
                [parts release];
            }
        }
        i++;
    }
    [self sortEventLog];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsModelEventLogChanged object:self];
    [self postCouchDBRecord];
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
    }
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:NO];
		[socket autorelease];
		socket = nil;
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
    if(inNetSocket == socket){
		NSString* theString = [[[[NSString alloc] initWithData:[inNetSocket readData] encoding:NSASCIIStringEncoding] autorelease] uppercaseString];
        if(!inputBuffer)inputBuffer = [[NSMutableString alloc]initWithString:theString];
        else [inputBuffer appendString:theString];
        
        if([theString rangeOfString:@"USER NAME"].location != NSNotFound){
            [inNetSocket writeString:[NSString stringWithFormat:@"%@\r",username] encoding:NSASCIIStringEncoding];
            [self clearInputBuffer];
        }
        else if([theString rangeOfString:@"PASSWORD"].location != NSNotFound){
            [inNetSocket writeString:[NSString stringWithFormat:@"%@\r",password] encoding:NSASCIIStringEncoding];
            [self clearInputBuffer];
        }
        else if([theString rangeOfString:@"APC>"].location != NSNotFound){
            if(!statusSentOnce){
                statusSentOnce = YES;
                [inNetSocket writeString:@"detstatus -all\r" encoding:NSASCIIStringEncoding];
                [self startTimeout];
            }
            [self parse:inputBuffer];
            [self clearInputBuffer];
        }
    }
}

- (void) clearEventLog
{
    NSLog(@"Cleared UPS Event Log\n");
    [self setEventLog:nil];
    [self pollHardware];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsModelEventLogChanged object:self];

}

- (ORTimeRate*)timeRate:(int)aChannel
{
    if(aChannel>=0 && aChannel<8) return timeRate[aChannel];
    else return nil;
}

- (NSString*) valueForPowerPhase:(int)aPhaseIndex powerTableIndex:(int)aRowIndex
{
    if(aRowIndex<=3){
        id aKey = [NSString stringWithFormat:@"%@ L%d",[self nameAtIndexInPowerTable:aRowIndex],aPhaseIndex];
        return [valueDictionary objectForKey:aKey];
    }
    else return @"?";
}

- (NSString*) valueForLoadPhase:(int)aPhaseIndex loadTableIndex:(int)aRowIndex
{
    if(aRowIndex<=3){
        id aKey = [NSString stringWithFormat:@"%@ L%d",[self nameForIndexInLoadTable:aRowIndex],aPhaseIndex];
        return [valueDictionary objectForKey:aKey];
    }
    else return @"?";
}

- (NSString*) valueForBattery:(int)aLoadIndex batteryTableIndex:(int)aRowIndex
{
    NSString* s = [valueDictionary objectForKey:[self nameForIndexInBatteryTable:aRowIndex]];
    if([s length]==0)return @"?";
    else return s;
}

- (NSString*) nameAtIndexInPowerTable:(int)i;
{
    switch(i){
        case 0: return @"INPUT VOLTAGE";
        case 1: return @"BYPASS INPUT VOLTAGE";
        case 2: return @"OUTPUT VOLTAGE";
        case 3: return @"INPUT CURRENT";
        case 4: return @"INPUT FREQUENCY";
        default: return @"";
    }
}

- (NSString*) nameForIndexInLoadTable:(int)i
{
    switch(i){
        case 0: return @"OUTPUT KVA";
        case 1: return @"OUTPUT CURRENT";
        case 2: return @"INTERNAL TEMP";
        case 3: return @"OUTPUT FREQUENCY";
        default: return @"";
    }
}

- (NSString*) nameForIndexInBatteryTable:(int)i
{
    switch(i){
        case 0: return @"BATTERY CAPACITY";
        case 1: return @"BATTERY VOLTAGE";
        case 2: return @"BATTERY CURRENT";
        case 3: return @"RUNTIME REMAINING";
        default: return @"";
    }
}

- (NSString*) nameForIndexInProcessTable:(int)i
{
    switch(i){
        case 0: return @"Battery Current";
        case 1: return @"Battery Voltage";
        case 2: return @"Battery Capacity";
        case 3: return @"Input Voltage L1";
        case 4: return @"Input Voltage L2";
        case 5: return @"Input Voltage L3";
        case 6: return @"Output Current L1";
        case 7: return @"Output Current L2";
        case 8: return @"Output Current L3";
        default: return @"";
    }
}

- (id) nameForChannel:(int)aChannel
{
    switch(aChannel){
        case 0:return @"BATTERY CURRENT";   break;
        case 1:return @"BATTERY VOLTAGE";   break;
        case 2:return @"BATTERY CAPACITY";  break;
        case 3:return @"INPUT VOLTAGE L1";  break;
        case 4:return @"INPUT VOLTAGE L2";  break;
        case 5:return @"INPUT VOLTAGE L3";  break;
        case 6:return @"OUTPUT CURRENT L1"; break;
        case 7:return @"OUTPUT CURRENT L2"; break;
        case 8:return @"OUTPUT CURRENT L3"; break;
        default: return @"";
    }
}

- (float) valueForChannel:(int)aChannel
{
    NSString* key = [self nameForChannel:aChannel];;
    if(key)return [[valueDictionary objectForKey:key]floatValue];
    else return 0;
}

- (int) channelForName:(NSString*)aName
{
    NSNumber* aChannelNumber = [channelFromNameTable objectForKey:aName];
    if(aChannelNumber)return [aChannelNumber intValue];
    else return -1;
}

- (id) valueForKeyInValueDictionary:(NSString*)aKey
{
    return [valueDictionary objectForKey:aKey];
}

#pragma mark •••Process Limits
- (float) lowLimit:(int)i
{
	if(i>=0 && i<kNumApcUpsAdcChannels)return lowLimit[i];
	else return 0;
}

- (void) setLowLimit:(int)i value:(float)aValue
{
	if(i>=0 && i<kNumApcUpsAdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:i value:lowLimit[i]];
		
		lowLimit[i] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsLowLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) hiLimit:(int)i
{
	if(i>=0 && i<kNumApcUpsAdcChannels)return hiLimit[i];
	else return 0;
}

- (void) setHiLimit:(int)i value:(float)aValue
{
	if(i>=0 && i<kNumApcUpsAdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setHiLimit:i value:lowLimit[i]];
		
		hiLimit[i] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsHiLimitChanged object:self userInfo:userInfo];
		
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
		s= [NSString stringWithFormat:@"ApcUps,%u",[self uniqueIdNumber]];
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
        return [self valueForChannel:aChan];
    }
	return theValue;
}

- (void) setProcessOutput:(int)aChan value:(int)aValue
{ /*nothing to do*/ }

- (double) maxValueForChan:(int)aChan
{
    switch(aChan){
        case 0: return 50;  //battery amps
            
        case 1:
        case 2:
        case 3: return 130; //Input voltages

        case 4:
        case 5:
        case 6: return 50; //Output current
            
        default: return 0;
    }
}

- (double) minValueForChan:(int)aChan
{
    return 0;
}

- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		if(channel < kNumApcUpsAdcChannels){
			*theLowLimit  = lowLimit[channel];
			*theHighLimit =  hiLimit[channel];
		}
	}
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    pollTime = kApcPollTime;
    
    [[self undoManager] disableUndoRegistration];
    [self setEventLog: [decoder decodeObjectForKey:@"eventLog"]];
	[self setIpAddress:[decoder decodeObjectForKey:@"ipAddress"]];
	[self setUsername: [decoder decodeObjectForKey:@"username"]];
	[self setPassword: [decoder decodeObjectForKey:@"password"]];
    int i;
    for(i=0;i<kNumApcUpsAdcChannels;i++) {

		[self setLowLimit:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"lowLimit%d",i]]];
		[self setHiLimit:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"hiLimit%d",i]]];
	}

    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:eventLog  forKey:@"eventLog"];
    [encoder encodeObject:ipAddress forKey:@"ipAddress"];
    [encoder encodeObject:username  forKey:@"username"];
    [encoder encodeObject:password  forKey:@"password"];
    int i;
	for(i=0;i<kNumApcUpsAdcChannels;i++) {
		[encoder encodeFloat:lowLimit[i] forKey:[NSString stringWithFormat:@"lowLimit%d",i]];
		[encoder encodeFloat:hiLimit[i] forKey:[NSString stringWithFormat:@"hiLimit%d",i]];
	}
}
#pragma mark •••CardHolding Protocol
- (int) maxNumberOfObjects	{ return 2; }	//default
- (int) objWidth			{ return 100; }	//default
- (int) groupSeparation		{ return 0; }	//default
- (NSString*) nameForSlot:(int)aSlot
{
    return [NSString stringWithFormat:@"Slot %d",aSlot];
}

- (NSRange) legalSlotsForObj:(id)anObj
{
	if(     [anObj isKindOfClass:NSClassFromString(@"ORScriptTaskModel")])		return NSMakeRange(0,1);
	else if([anObj isKindOfClass:NSClassFromString(@"ORRemoteSocketModel")])	return NSMakeRange(1,1);
    else return NSMakeRange(0,0);
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj
{
	if(aSlot == 0      && [anObj isKindOfClass:NSClassFromString(@"ORScriptTaskModel")])      return NO;
	else if(aSlot == 1 && [anObj isKindOfClass:NSClassFromString(@"ORRemoteSocketModel")])	  return NO;
    else return YES;
}

- (int) slotAtPoint:(NSPoint)aPoint
{
	return floor(((int)aPoint.x)/[self objWidth]);
}

- (NSPoint) pointForSlot:(int)aSlot
{
	return NSMakePoint(aSlot*[self objWidth],0);
}

- (void) place:(id)anObj intoSlot:(int)aSlot
{
    [anObj setTag:aSlot];
	NSPoint slotPoint = [self pointForSlot:aSlot];
	[anObj moveTo:slotPoint];
}

- (int) slotForObj:(id)anObj
{
    return (int)[anObj tag];
}

- (int) numberSlotsNeededFor:(id)anObj
{
	return 1;
}

- (id)   remoteSocket;
{
    return [self findObject:@"ORRemoteSocketModel"];
}

@end

@implementation ORApcUpsModel (private)
- (ORScriptTaskModel*) findShutdownScript	{ return [self findObject:@"ORScriptTaskModel"]; }
- (id) findObject:(NSString*)aClassName
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj isKindOfClass:NSClassFromString(aClassName)])return anObj;
	}
	return nil;
}

- (void) postCouchDBRecord
{
    NSMutableDictionary* values = [NSMutableDictionary dictionaryWithDictionary:valueDictionary];
    [values setObject:[NSNumber numberWithInt:30] forKey:@"pollTime"];
    
    NSArray* events = [self sortedEventLog];
    NSMutableString* eventLogString = [NSMutableString stringWithString:@""];
    for (NSString *anEvent in events) {
        [eventLogString appendFormat:@"%@\n",anEvent];
    }
    [values setObject:eventLogString forKey:@"eventLog"];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:values];
}

- (void) parse:(NSString*)aResponse
{
    if(!valueDictionary){
        self.valueDictionary = [NSMutableDictionary dictionary];
    }
    
    aResponse = [aResponse stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    NSArray* lines = [aResponse componentsSeparatedByString:@"\r"];
    for(NSString* aLine in lines){
        aLine = [aLine removeNLandCRs];
        if([aLine rangeOfString:@":"].location != NSNotFound){
            //special cases
            if([aLine hasPrefix:@"NAME"]     ||
               [aLine hasPrefix:@"CONTACT"]  ||
               [aLine hasPrefix:@"LOCATION"] ||
               [aLine hasPrefix:@"UP TIME"]){
                [self parseLine:[aLine substringToIndex:46]];
                [self parseLine:[aLine substringFromIndex:46]];
            }
            else [self parseLine:aLine];
        }
    }
    
    int i;
    for(i=0;i<8;i++){
        if(timeRate[i] == nil){
            timeRate[i] = [[ORTimeRate alloc] init];
            [timeRate[i] setSampleTime: [self pollTime]];
        }
        [timeRate[i] addDataToTimeAverage:[self valueForChannel:i]];
    }

    [self cancelTimeout];
}
//STATUS OF UPS: INTERNAL FAULT BYPASS, BATTERY CHARGER FAILURE, OTHER ALARMS PRESENT,

- (void) parseLine:(NSString*)aLine
{
    NSArray* parts = [aLine componentsSeparatedByString:@":"];
    if([parts count]==2){
        
        NSString* varName = [[parts objectAtIndex:0] removeNLandCRs];
        varName = [varName trimSpacesFromEnds];
        
        NSString* value = [[parts objectAtIndex:1] removeNLandCRs];
        value = [value trimSpacesFromEnds];

        if([varName hasPrefix:@"BATTERY STATE OF CHARGE"])varName = @"BATTERY CAPACITY";
        else if([varName hasPrefix:@"INTERNAL TEMPERATURE"]){
            NSArray* tempParts = [value componentsSeparatedByString:@","];
            if([tempParts count] > 1){
                value = [tempParts objectAtIndex:0];
            }
        }
        else if([varName hasPrefix:@"STATUS OF UPS"]){
            if([value rangeOfString:@"INTERNAL FAULT BYPASS"].location != NSNotFound ||
               [value rangeOfString:@"BATTERY CHARGER FAILURE"].location != NSNotFound ){
                if(!badStatusAlarm){
                    NSLog(@"The UPS (%@) is reporting serious alarms. %@\n",[self fullID],value);
                    badStatusAlarm = [[ORAlarm alloc] initWithName:@"UPS Faults" severity:kEmergencyAlarm];
                    [badStatusAlarm setHelpString:[NSString stringWithFormat:@"The %@ UPS is reporting that it has serioius fault conditions. This Alarm can be silenced by acknowledging it, but it will not be cleared until power is restored.",[self fullID]]];
                    [badStatusAlarm setSticky:YES];
                    [badStatusAlarm postAlarm];
                }
            }
            else {
                if([badStatusAlarm isPosted]){
                    [badStatusAlarm clearAlarm];
                    [badStatusAlarm release];
                    badStatusAlarm = nil;
                    NSLog(@"The UPS faults cleared.\n");
                }
            }
        }
        
        [valueDictionary setObject:value forKey:varName];
        if([valueDictionary objectForKey:@"INPUT VOLTAGE L1"] &&
           [valueDictionary objectForKey:@"INPUT VOLTAGE L2"] &&
           [valueDictionary objectForKey:@"INPUT VOLTAGE L3"]){
            [self setDataValid:YES];
        }
        
    }
    else  if([parts count]==4){
        //special case TIME
        NSString* varName = [[parts objectAtIndex:0] trimSpacesFromEnds];
        varName = [varName removeNLandCRs];
        if([varName isEqualToString:@"TIME"]){
            NSString* time = [NSString stringWithFormat:@"%@:%@:%@",
                              [[parts objectAtIndex:1] trimSpacesFromEnds],
                              [[parts objectAtIndex:2] trimSpacesFromEnds],
                              [[parts objectAtIndex:3] trimSpacesFromEnds]
                              ];
            time = [time removeNLandCRs];
            [valueDictionary setObject:time forKey:varName];
        }
    }
}

- (void) clearInputBuffer
{
    [inputBuffer release];
    inputBuffer = nil;
}

- (void) startTimeout
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
   	[self performSelector:@selector(timeout) withObject:nil afterDelay:3];
}

- (void) cancelTimeout
{
   	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
}

- (void) timeout
{
    [self setDataValid:NO];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	NSLogError(@"command timeout",[self fullID],nil);
    [[NSNotificationCenter defaultCenter] postNotificationName:ORApcUpsTimedOut object:self];
}

@end

