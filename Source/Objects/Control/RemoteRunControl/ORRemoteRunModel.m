//
//  ORRemoteRunModel.m
//  Orca
//
//  Created by Mark Howe on Tue Dec 24 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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




#pragma mark ¥¥¥Imported Files
#import "ORRemoteRunModel.h"
#import "NetSocket.h"

#pragma mark ¥¥¥Definitions

NSString* ORRemoteRunModelOfflineChanged	= @"ORRemoteRunModelOfflineChanged";
NSString* ORRemoteRunIsConnectedChanged     = @"ORRemoteRunIsConnectedChanged";
NSString* ORRemoteRunAutoReconnectChanged   = @"ORRemoteRunAutoReconnectChanged";
NSString* ORRemoteRunConnectAtStartChanged  = @"ORRemoteRunConnectAtStartChanged";
NSString* ORRemoteRunRemotePortChanged      = @"ORRemoteRunRemotePortChanged";
NSString* ORRemoteRunRemoteHostChanged      = @"ORRemoteRunRemoteHostChanged";
NSString* ORRemoteRunTimedRunChanged        = @"ORRemoteRunTimedRunChanged";
NSString* ORRemoteRunRepeatRunChanged       = @"ORRemoteRunRepeatRunChanged";
NSString* ORRemoteRunTimeLimitChanged       = @"ORRemoteRunTimeLimitChanged";
NSString* ORRemoteRunTimeToGoChanged        = @"ORRemoteRunTimeToGoChanged";
NSString* ORRemoteRunElapsedTimeChanged     = @"ORRemoteRunElapsedTimeChanged";
NSString* ORRemoteRunStartTimeChanged       = @"ORRemoteRunStart TimeChanged";
NSString* ORRemoteRunNumberChanged          = @"ORRemoteRunRunNumberChanged";
NSString* ORRemoteRunQuickStartChanged      = @"ORRemoteRunQuickStartChanged";
NSString* ORRemoteRunStatusChanged          = @"ORRemoteRunStatusChanged";
NSString* ORRemoteRunLock                    = @"ORRemoteRunLock";
NSString* ORRemoteRunModelScriptNamesChanged = @"ORRemoteRunModelScriptNamesChanged";
NSString* ORRemoteRunStartScriptNameChanged = @"ORRemoteRunStartScriptNameChanged";
NSString* ORRemoteRunShutDownScriptNameChanged = @"ORRemoteRunShutDownScriptNameChanged";


@interface ORRemoteRunModel (private)
- (void) reConnect;
- (void) waitForRunStop;

@end

@implementation ORRemoteRunModel

#pragma mark ¥¥¥Initialization
-(id)init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [self setTimeLimit:3600];
    [[self undoManager] enableUndoRegistration];
    
    
    return self;
}

-(void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [startTime release];
    
    [remoteHost release];
    [scriptNames release];
	[selectedStartScriptName release];
	[selectedShutDownScriptName release];
    [socket close];
    [socket setDelegate:nil];
    [socket release];
    
    [super dealloc];
}

- (void) sleep
{
    [socket close];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"RemoteRunControl"]];
}

-(void)makeMainController
{
    [self linkToController:@"ORRemoteRunController"];
}

- (NSString*) helpURL
{
	return @"Data_Chain/Remote_Run_Control.html";
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(documentLoaded:)
                         name : ORDocumentLoadedNotification
                       object : nil];
    
    
}

- (void) documentLoaded:(NSNotification*)aNotification
{
    if(connectAtStart){
        [self connectSocket:YES];
    }
}


#pragma mark ¥¥¥Accessors
- (NSArray*) scriptNames
{
	return scriptNames;
}

- (void) setScriptNames:(NSArray*)someNames
{
	[someNames retain];
	[scriptNames release];
	scriptNames = someNames;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRemoteRunModelScriptNamesChanged object:self];
	
}

- (BOOL) offline
{
    return offline;
}

- (void) setOffline:(BOOL)aOffline
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOffline:offline];
    offline = aOffline;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRemoteRunModelOfflineChanged object:self];
}

- (BOOL) isConnected
{
	return isConnected;
}
- (void) setIsConnected:(BOOL)aIsConnected
{    
	isConnected = aIsConnected;
    
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunIsConnectedChanged
	 object:self];
}

- (BOOL) autoReconnect
{
	return autoReconnect;
}
- (void) setAutoReconnect:(BOOL)aAutoReconnect
{
	[[[self undoManager] prepareWithInvocationTarget:self] setAutoReconnect:autoReconnect];
    
	autoReconnect = aAutoReconnect;
    
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunAutoReconnectChanged
	 object:self];
}

- (BOOL) connectAtStart
{
	return connectAtStart;
}
- (void) setConnectAtStart:(BOOL)aConnectAtStart
{
	[[[self undoManager] prepareWithInvocationTarget:self] setConnectAtStart:connectAtStart];
    
	connectAtStart = aConnectAtStart;
    
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunConnectAtStartChanged
	 object:self];
}

- (NSString*) selectedStartScriptName
{
	return selectedStartScriptName;
}

- (NSString*) selectedShutDownScriptName
{
	return selectedShutDownScriptName;
}

- (void) setSelectedStartScriptName:(NSString*)aName
{
	[selectedStartScriptName autorelease];
    selectedStartScriptName = [aName copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRemoteRunStartScriptNameChanged object:self];
}

- (void) setSelectedShutDownScriptName:(NSString*)aName
{
	[selectedShutDownScriptName autorelease];
    selectedShutDownScriptName = [aName copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRemoteRunShutDownScriptNameChanged object:self];
}

- (NetSocket*) socket
{
    return socket;
}
- (void) setSocket:(NetSocket*)aSocket
{
    [aSocket retain];
    [socket release];
    socket = aSocket;
    
    [socket setDelegate:self];
}

- (uint32_t) remotePort
{
    return remotePort;
}
- (void) setRemotePort:(uint32_t)aRemotePort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRemotePort:remotePort];
    
    remotePort = aRemotePort;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunRemotePortChanged
	 object:self];
}
- (NSString*) remoteHost
{
    return remoteHost;
}
- (void) setRemoteHost:(NSString*)aRemoteHost
{
    if(aRemoteHost == nil)aRemoteHost = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setRemoteHost:remoteHost];
    
    [remoteHost autorelease];
    remoteHost = [aRemoteHost copy];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunRemoteHostChanged
	 object:self];
}

-(uint32_t)runNumber
{
    return runNumber;
}

-(void)setRunNumber:(uint32_t)aRunNumber
{
    runNumber = aRunNumber;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunNumberChanged
	 object: self];
}

- (int) subRunNumber
{
    return subRunNumber;
}

- (void) setSubRunNumber:(int)aSubRunNumber
{
    subRunNumber = aSubRunNumber;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRemoteRunNumberChanged object:self];
}

-(BOOL)isRunning
{
    return runningState == eRunInProgress;
}

-(NSString*)startTime
{
    return startTime;
}

-(void)setStartTime:(NSString*)aDate
{
    if(aDate == nil)aDate = @"";
    [startTime autorelease];
    startTime = [aDate copy];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunStartTimeChanged
	 object: self];
}

-(NSTimeInterval) elapsedTime
{
    return elapsedTime;
}

-(void) setElapsedTime:(NSTimeInterval)aValue
{
    elapsedTime = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunElapsedTimeChanged
	 object: self];
}


- (NSTimeInterval)  elapsedSubRunTime
{
	return elapsedSubRunTime;
}

- (void)	setElapsedSubRunTime:(NSTimeInterval) aValue
{
    elapsedSubRunTime = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunElapsedTimeChanged
	 object: self];
}

- (NSTimeInterval)  elapsedBetweenSubRunTime
{
	return elapsedBetweenSubRunTime;
}

- (void)	setElapsedBetweenSubRunTime:(NSTimeInterval) aValue
{
    elapsedBetweenSubRunTime = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunElapsedTimeChanged
	 object: self];
}

-(NSTimeInterval) timeToGo
{
    return timeToGo;
}

-(void)setTimeToGo:(NSTimeInterval)aValue
{
    timeToGo = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunTimeToGoChanged
	 object: self];
}

-(BOOL)timedRun
{
    return timedRun;
}

-(void)setTimedRun:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimedRun:[self timedRun]];
    timedRun = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunTimedRunChanged
	 object: self];
}

-(BOOL)repeatRun
{
    return repeatRun;
}

-(void)setRepeatRun:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatRun:[self repeatRun]];
    repeatRun = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunRepeatRunChanged
	 object: self];
}

-(NSTimeInterval) timeLimit
{
    return timeLimit;
}

-(void)setTimeLimit:(NSTimeInterval)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimeLimit:[self timeLimit]];
    timeLimit = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunTimeLimitChanged
	 object: self];
}

- (NSString*) elapsedRunTimeString
{
	return [self elapsedTimeString:[self elapsedTime]];
}

- (NSString*) elapsedTimeString:(NSTimeInterval) aTimeInterval;

{
	if([self isRunning]){
		int hr = aTimeInterval/3600;
		int min =(aTimeInterval - hr*3600)/60;
		int sec = aTimeInterval - hr*3600 - min*60;
		return [NSString stringWithFormat:@"%02d:%02d:%02d",hr,min,sec];
	}
	else return @"---";
}


-(BOOL)quickStart
{
    return quickStart;
}

-(void)setQuickStart:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setQuickStart:quickStart];
    quickStart = flag;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORRemoteRunQuickStartChanged
	 object: self];
    
}


-(int)runningState
{
    return runningState;
}

-(void)setRunStatus:(int)aRunningState
{
    //this is just to provide a method for KVC
    [self setRunningState:aRunningState];
}

-(void)setRunningState:(int)aRunningState
{
    if(aRunningState != runningState){
        [self sendCmd:@"runNumber = [RunControl runNumber];"];
        [self sendCmd:@"subRunNumber = [RunControl subRunNumber];"];
        [self sendCmd:@"startTime = [RunControl startTimeAsString];"];
        
        runningState = aRunningState;
        
        NSDictionary* userInfo = [NSDictionary
								  dictionaryWithObjectsAndKeys:[NSNumber
																numberWithInt:runningState],ORRunStatusValue,
								  runState[runningState],ORRunStatusString,nil];
        
        [[NSNotificationCenter defaultCenter]
		 postNotificationName:ORRemoteRunStatusChanged
		 object: self
		 userInfo: userInfo];
    }
}

- (NSString*) fullRunNumberString
{
	NSString* rn;
	if([self subRunNumber] > 0){
		rn = [NSString stringWithFormat:@"%u.%d",[self runNumber],[self subRunNumber]];
	}
	else {
		rn = [NSString stringWithFormat:@"%u",[self runNumber]];
	}
	return rn;
}

- (NSString*) shortStatus
{
	if(runningState == eRunInProgress){
		return @"Running";
	}
	else if(runningState == eRunStopped){
		return @"Stopped";
	}
	else if(runningState == eRunStarting || runningState == eRunStopping){
		if(runningState == eRunStarting)return @"Starting..";
		else return @"Stopping..";
	}
	else return @"?";
}

#pragma mark ¥¥¥Run Modifiers
- (void) startNewSubRun
{
    if([socket isConnected]){
		[self sendCmd:@"[RunControl setRemoteControl:0];"];
		[self sendCmd:@"[RunControl startNewSubRun];"];
		[self sendCmd:@"[RunControl setRemoteControl:1];"];
    }
    else {
        NSLog(@"Not connected: sub run not started\n");
    }
}

- (void) prepareForNewSubRun
{
    if([socket isConnected]){
		[self sendCmd:@"[RunControl setRemoteControl:0];"];
		[self sendCmd:@"[RunControl prepareForNewSubRun];"];
		[self sendCmd:@"[RunControl setRemoteControl:1];"];
    }
    else {
        NSLog(@"Not connected: can not end sub run\n");
    }
}

- (void) startRun
{
    if([socket isConnected]){
        [self startRun:!quickStart];
    }
    else {
        NSLog(@"Not connected: run not started\n");
    }
}

- (void) startRun:(BOOL)doInit
{
    
    [self sendCmd:@"[RunControl setRemoteControl:0];"];
    [self sendSetup];        
    NSString* startRunCmd = [NSString stringWithFormat:@"[RunControl startRun:%d];",doInit];
    [self sendCmd:startRunCmd];
    [self sendCmd:@"runNumber = [RunControl runNumber];"];
    [self sendCmd:@"subRunNumber = [RunControl subRunNumber];"];
    [self sendCmd:@"[RunControl setRemoteControl:1];"];
    [self sendCmd:@"[RunControl setRemoteInterface:1];"];
    
    [self runStarted:doInit];
    [self performSelector:@selector(incrementTime) withObject:nil afterDelay:1];
    
}

- (void) restartRun
{
    [self stopRun];
    [self startRun];
}

- (void) haltRun
{
    [self stopRun];
}


- (void)stopRun
{
    
    if([socket isConnected]){
        [self sendCmd:@"[RunControl haltRun];"];
        [self sendCmd:@"[RunControl setRemoteControl:0];"];
        
		timeHalted = [NSDate timeIntervalSinceReferenceDate];
		[self waitForRunStop];
	}
}


- (void) incrementTime
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(incrementTime) object:nil];
    
    if([socket isConnected]){
        [self sendCmd:@"runningState=[RunControl runningState];"];
        [self sendCmd:@"elapsedTime=[RunControl elapsedRunTime];"];
        [self sendCmd:@"timeToGo=[RunControl timeToGo];"];
		[self sendCmd:@"elapsedSubRunTime=[RunControl elapsedSubRunTime];"];
		[self sendCmd:@"elapsedBetweenSubRunTime=[RunControl elapsedBetweenSubRunTime];"];
   }
    
    [self performSelector:@selector(incrementTime) withObject:nil afterDelay:2];
}

-(void)runStarted:(BOOL)doInit
{    
    [self sendSetup];
    
    if([[self document] isDocumentEdited]){
        [[self document] saveDocument:[self document]];
    }
    
    NSLog(@"-------------------------------------\n");
    NSLog(@"Run %d started(%@).\n",[self runNumber]+1,doInit?@"cold start":@"quick start");
    NSLog(@"-------------------------------------\n");
    
}

#pragma mark ¥¥¥Notifications

#pragma mark ¥¥¥Archival
static NSString *ORRunTimeLimit		= @"Run Time Limit";
static NSString *ORRunTimedRun		= @"Run Is Timed";
static NSString *ORRunRepeatRun		= @"Run Will Repeat";
static NSString *ORRunQuickStart 	= @"ORRunQuickStart";
static NSString *ORRunRemoteHost 	= @"ORRunRemoteHost";
static NSString *ORRunRemotePort 	= @"ORRunRemotePort";
static NSString *ORRunRemoteAutoReconnect	= @"ORRunRemoteAutoReconnect";
static NSString *ORRunRemoteConnectAtStart	= @"ORRunRemoteConnectAtStart";

-(id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setOffline:[decoder decodeBoolForKey:@"offline"]];
    [self setTimeLimit:[decoder decodeIntegerForKey:ORRunTimeLimit]];
    [self setTimedRun:[decoder decodeBoolForKey:ORRunTimedRun]];
    [self setRepeatRun:[decoder decodeBoolForKey:ORRunRepeatRun]];
    [self setQuickStart:[decoder decodeBoolForKey:ORRunQuickStart]];
    [self setRemoteHost:[decoder decodeObjectForKey:ORRunRemoteHost]];
    [self setAutoReconnect:[decoder decodeBoolForKey:ORRunRemoteAutoReconnect]];
    [self setConnectAtStart:[decoder decodeBoolForKey:ORRunRemoteConnectAtStart]];
    [self setRemotePort:[decoder decodeIntForKey:ORRunRemotePort]];
    
    [[self undoManager] enableUndoRegistration];
    
	[self registerNotificationObservers];
    
    return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:offline forKey:@"offline"];
    [encoder encodeInteger:timeLimit forKey:ORRunTimeLimit];
    [encoder encodeBool:timedRun forKey:ORRunTimedRun];
    [encoder encodeBool:repeatRun forKey:ORRunRepeatRun];
    [encoder encodeBool:quickStart forKey:ORRunQuickStart];
    [encoder encodeObject:remoteHost forKey:ORRunRemoteHost];
    [encoder encodeBool:autoReconnect forKey:ORRunRemoteAutoReconnect];
    [encoder encodeBool:connectAtStart forKey:ORRunRemoteConnectAtStart];
    [encoder encodeInt:remotePort forKey:ORRunRemotePort];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    //get the time(UT!)
    time_t	ut_time;
    time(&ut_time);
    //struct tm* theTimeGMTAsStruct = gmtime(&theTime);
    //time_t ut_time = mktime(theTimeGMTAsStruct);
    NSTimeInterval refTime = [NSDate timeIntervalSinceReferenceDate];
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class])            forKey:@"Class Name"];
    [objDictionary setObject:[NSNumber numberWithLong:ut_time]          forKey:@"startTime"];
    [objDictionary setObject:[NSNumber numberWithFloat:refTime]         forKey:@"refTime"];
    [objDictionary setObject:[NSNumber numberWithBool:quickStart]       forKey:@"quickStart"];
    [objDictionary setObject:[NSNumber numberWithBool:offline]			forKey:@"offline"];
    [objDictionary setObject:[NSNumber numberWithLong:[self runNumber]] forKey:@"RunNumber"];
    
    [dictionary setObject:objDictionary forKey:@"Remote Run Control"];
    
    
    return objDictionary;
}


-(NSString*)commandID
{
    return @"RemoteRunControl";
}

- (void) setPostAlarm:(id)anAlarm
{
    NSLog(@"<%@>Posted:%@\n",remoteHost,anAlarm);
}
- (void) setClearAlarm:(id)anAlarm
{
    NSLog(@"<%@>Cleared:%@\n",remoteHost,anAlarm);
}

- (void) parseString:(NSString*)inString
{
    [[self undoManager] disableUndoRegistration];
    NSArray* lines= [inString componentsSeparatedByString:@"\n"];
    int n = (int)[lines count];
    int i;
    NSCharacterSet* numberSet =  [NSCharacterSet decimalDigitCharacterSet];
    
    for(i=0;i<n;i++){
        NSString* aLine = [lines objectAtIndex:i];
        NSRange firstColonRange = [aLine rangeOfString:@":"];
        if(firstColonRange.location != NSNotFound){
            NSString* key = [aLine substringToIndex:firstColonRange.location];
            id value      = [aLine substringFromIndex:firstColonRange.location+1];
			if([key isEqualToString:@"scripts"]){
				i=[self processScripts:lines index:i+1];
			}
            else if([key isEqualToString:@"startTime"]){
                [self setStartTime:value];            
            }
            else {
                if([numberSet characterIsMember:[value characterAtIndex:0]]){
                    value = [NSDecimalNumber decimalNumberWithString:value];
                }
                @try {
                    [self setValue:value forKey:key];
				}
				@catch(NSException* localException) {
				}
            }
        }
		
    }
	[[self undoManager] enableUndoRegistration];
}

- (int) processScripts:(NSArray*)lines index:(int)i
{
	NSMutableArray* theRemoteScriptNames = [NSMutableArray array];
	NSString* aScript;
	do {
		NSString* aLine = [lines objectAtIndex:i];
		if([aLine rangeOfString:@")"].location != NSNotFound)break;
		NSScanner* scanner = [NSScanner scannerWithString:aLine];
		[scanner scanUpToString:@"\"" intoString:nil];
		[scanner scanString:@"\"" intoString:nil];
		if([scanner scanUpToString:@"\"" intoString:&aScript]){
			[theRemoteScriptNames addObject:aScript];
			i++;
			if(i>=[lines count])break;
		}
		if([scanner isAtEnd])break;
	} while(1);
	[self setScriptNames:theRemoteScriptNames];
	return i;
}

- (void) connectSocket:(BOOL)state
{
    if(state){
        [self setSocket:[NetSocket netsocketConnectedToHost:remoteHost port:remotePort]];
    }
    else {
        [socket close];
        [self setIsConnected:[socket isConnected]];
        [self setRunningState:eRunStopped];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(incrementTime) object:nil];
    }
}

#pragma mark ***Remote Getters
- (void) fullUpdate 
{
    [self sendCmd:@"runNumber = [RunControl runNumber];"];
    [self sendCmd:@"subRunNumber = [RunControl subRunNumber];"];
    [self sendCmd:@"elapsedTime = [RunControl elapsedRunTime];"];
    [self sendCmd:@"repeatRun = [RunControl repeatRun];"];
    [self sendCmd:@"timedRun = [RunControl timedRun];"];    
    [self sendCmd:@"timeLimit = [RunControl timeLimit];"];
    [self sendCmd:@"timeToGo = [RunControl timeToGo];"];
    [self sendCmd:@"quickStart = [RunControl quickStart];"];
    [self sendCmd:@"offline = [RunControl offlineRun];"];
    [self sendCmd:@"runningState = [RunControl runningState];"];
    [self sendCmd:@"startTime = [RunControl startTimeAsString];"];
    [self sendCmd:@"scripts = [RunControl runScriptList];"];
    [self sendCmd:@"selectedStartScriptName = [RunControl selectedStartScriptName];"];
    [self sendCmd:@"selectedShutDownScriptName = [RunControl selectedShutDownScriptName];"];
	[self sendCmd:@"elapsedSubRunTime=[RunControl elapsedSubRunTime];"];
	[self sendCmd:@"elapsedBetweenSubRunTime=[RunControl elapsedBetweenSubRunTime];"];
}

- (void) sendSetup
{
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setTimeLimit:%f];" ,timeLimit]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setRepeatRun:%d];" ,repeatRun]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setTimedRun:%d];"  ,timedRun]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setQuickStart:%d];",quickStart]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setOfflineRun:%d];",offline]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setStartScriptName:@\"%@\"];",selectedStartScriptName]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setShutDownScriptName:@\"%@\"];",selectedShutDownScriptName]];
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(id)aSocket
{
    if(aSocket == socket){
        [self setIsConnected:[socket isConnected]];
        [self sendCmd:@"[self setName:Orca];"];        
        [self fullUpdate];
        [self performSelector:@selector(incrementTime) withObject:nil afterDelay:1];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
    if(inNetSocket == socket){
        NSString* inString = [socket readString:NSASCIIStringEncoding];
        if(inString){
            [self parseString:inString];
        }
    }
}


- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(incrementTime) object:nil];
        [self setIsConnected:[socket isConnected]];
        if(autoReconnect)[self performSelector:@selector(reConnect) withObject:nil afterDelay:10];
        [self setIsConnected:NO];
        [self setRunningState:eRunStopped];
    }
}

- (void) sendCmd:(NSString*)aCmd
{
    if([self isConnected]){
        [socket writeString:aCmd encoding:NSASCIIStringEncoding];
    }
}

@end


@implementation ORRemoteRunModel (private)
- (void) reConnect
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reConnect) object:nil];
    [self connectSocket:YES];
}
- (void) waitForRunStop
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(waitForRunStop) object:nil];
	
	if(runningState == eRunStopped){
		NSLog(@"-------------------------------------\n");
		NSLog(@"Remote Run %d stopped.\n",[self runNumber]);
		NSLog(@"-------------------------------------\n");
		return;
	}
	if([NSDate timeIntervalSinceReferenceDate]-timeHalted > 8){
		NSLog(@"TimeOut waiting for remote run to stop.\n");
		return;
	}
    [self performSelector:@selector(waitForRunStop) withObject:nil afterDelay:1];
}

@end
