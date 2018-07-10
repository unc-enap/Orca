//
//  ORRemoteRunModel.m
//  Orca
//
//  Created by Mark Howe on Tue Dec 24 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
//



#pragma mark ¥¥¥Imported Files
#import <sys/time.h>
#import "ORRemoteRunModel.h"
#import "StatusLog.h"
#import "ORAppDelegate.h"
#import "ORDocument.h"
#import "ORGlobal.h"
#import "ORAlarm.h"
#import "NetSocket.h"
#import "NSString+Extensions.h"

#pragma mark ¥¥¥Definitions

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
    [remoteHost release];
    
    [socket close];
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

- (unsigned long) remotePort
{
    return remotePort;
}
- (void) setRemotePort:(unsigned long)aRemotePort
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

-(unsigned long)runNumber
{
    return runNumber;
}

-(void)setRunNumber:(unsigned long)aRunNumber
{
    runNumber = aRunNumber;
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORRemoteRunNumberChanged
                      object: self];
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


#pragma mark ¥¥¥Run Modifiers

-(void)startRun
{
    if([socket isConnected]){
        [self startRun:!quickStart];
    }
    else {
        NSLog(@"Not connected: run not started\n");
    }
}

-(void)startRun:(BOOL)doInit
{
    
    [self sendCmd:@"[RunControl setRemoteControl:0];"];
    [self sendSetup];        
    NSString* startRunCmd = [NSString stringWithFormat:@"[RunControl startRun:%d];",doInit];
    [self sendCmd:startRunCmd];
    [self sendCmd:@"runNumber = [RunControl runNumber];"];
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


-(void)incrementTime
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(incrementTime) object:nil];
    
    if([socket isConnected]){
        [self sendCmd:@"runningState=[RunControl runningState];"];
        [self sendCmd:@"elapsedTime=[RunControl elapsedTime];"];
        [self sendCmd:@"timeToGo=[RunControl timeToGo];"];
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
    
    [self setTimeLimit:[decoder decodeInt32ForKey:ORRunTimeLimit]];
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
    [encoder encodeInt32:timeLimit forKey:ORRunTimeLimit];
    [encoder encodeBool:timedRun forKey:ORRunTimedRun];
    [encoder encodeBool:repeatRun forKey:ORRunRepeatRun];
    [encoder encodeBool:quickStart forKey:ORRunQuickStart];
    [encoder encodeObject:remoteHost forKey:ORRunRemoteHost];
    [encoder encodeBool:autoReconnect forKey:ORRunRemoteAutoReconnect];
    [encoder encodeBool:connectAtStart forKey:ORRunRemoteConnectAtStart];
    [encoder encodeInt:remotePort forKey:ORRunRemotePort];
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
    int n = [lines count];
    int i;
    NSCharacterSet* numberSet =  [NSCharacterSet decimalDigitCharacterSet];
    
    for(i=0;i<n;i++){
        NSString* aLine = [lines objectAtIndex:i];
        NSRange firstColonRange = [aLine rangeOfString:@":"];
        if(firstColonRange.location != NSNotFound){
            NSString* key = [aLine substringToIndex:firstColonRange.location];
            id value      = [aLine substringFromIndex:firstColonRange.location+1];
            if([key isEqualToString:@"startTime"]){
                [self setStartTime:value];            
            }
            else {
                if([numberSet characterIsMember:[value characterAtIndex:0]]){
                    value = [NSDecimalNumber decimalNumberWithString:value];
                }
                NS_DURING
                    [self setValue:value forKey:key];
                NS_HANDLER
                    NS_ENDHANDLER
            }
        }
            
    }
        [[self undoManager] enableUndoRegistration];
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
    [self sendCmd:@"elapsedTime = [RunControl elapsedTime];"];
    [self sendCmd:@"repeatRun = [RunControl repeatRun];"];
    [self sendCmd:@"timedRun = [RunControl timedRun];"];    
    [self sendCmd:@"timeLimit = [RunControl timeLimit];"];
    [self sendCmd:@"timeToGo = [RunControl timeToGo];"];
    [self sendCmd:@"quickStart = [RunControl quickStart];"];
    [self sendCmd:@"runningState = [RunControl runningState];"];
    [self sendCmd:@"startTime = [RunControl startTimeAsString];"];
}

- (void) sendSetup
{
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setTimeLimit:%f];" ,timeLimit]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setRepeatRun:%d];" ,repeatRun]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setTimedRun:%d];"  ,timedRun]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setQuickStart:%d];",quickStart]];
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

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(unsigned)inAmount
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
