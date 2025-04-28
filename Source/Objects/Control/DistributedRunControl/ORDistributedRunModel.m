//
//  ORDistributedRunModel.m
//  Orca
//
//  Created by Mark Howe on Apr 22, 2025.
//  Copyright (c) 2025 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Physics Department sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#pragma mark ¥¥¥Imported Files
#import "ORDistributedRunModel.h"
#import "ORRemoteRunItem.h"
#import "StopLightView.h"
#pragma mark ¥¥¥Definitions

NSString* ORDistributedRunConnectAtStartChanged  = @"ORDistributedRunConnectAtStartChanged";
NSString* ORDistributedRunTimedRunChanged        = @"ORDistributedRunTimedRunChanged";
NSString* ORDistributedRunRepeatRunChanged       = @"ORDistributedRunRepeatRunChanged";
NSString* ORDistributedRunTimeLimitChanged       = @"ORDistributedRunTimeLimitChanged";
NSString* ORDistributedRunTimeToGoChanged        = @"ORDistributedRunTimeToGoChanged";
NSString* ORDistributedRunElapsedTimeChanged     = @"ORDistributedRunElapsedTimeChanged";
NSString* ORDistributedRunStartTimeChanged       = @"ORDistributedRunStart TimeChanged";
NSString* ORDistributedRunQuickStartChanged      = @"ORDistributedRunQuickStartChanged";
NSString* ORDistributedRunStatusChanged          = @"ORDistributedRunStatusChanged";
NSString* ORDistributedRunNumberConnectedChanged = @"ORDistributedRunNumberConnectedChanged";
NSString* ORDistributedRunNumberRunningChanged   = @"ORDistributedRunNumberRunningChanged";
NSString* ORDistributedRunSystemListChanged      = @"ORDistributedRunSystemListChanged";
NSString* ORRemoteRunItemAdded                   = @"ORRemoteRunItemAdded";
NSString* ORRemoteRunItemRemoved                 = @"ORRemoteRunItemRemoved";
NSString* ORDistributedRunLock                    = @"ORDistributedRunLock";


@interface ORDistributedRunModel (private)
- (void) waitForRunStop;
@end

@implementation ORDistributedRunModel

#pragma mark ¥¥¥Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    [self setTimeLimit:3600];
    [self ensureMinimumNumberOfRemoteItems];
    [[self undoManager] enableUndoRegistration];

    return self;
}

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [startTime release];
    [remoteRunItems release];
    [super dealloc];
}

- (void) sleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super sleep];
}

- (void) wakeUp
{
    [self ensureMinimumNumberOfRemoteItems];
    [self performSelector:@selector(doTimedUpdate) withObject:nil afterDelay:1];
    [super wakeUp];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"DistributedRunControl"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORDistributedRunController"];
}

- (NSString*) helpURL
{
	return @"Data_Chain/Distrubuted_Run_Control.html"; //TBD
}

#pragma mark ¥¥¥Accessors

-(BOOL)isRunning
{
    return numberRunning && numberConnected;
}

- (NSDate*) startTime
{
    return startTime;
}

- (void) setStartTime:(NSDate*)aDate
{
    [startTime autorelease];
    startTime = [aDate copy];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDistributedRunStartTimeChanged
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
	 postNotificationName:ORDistributedRunElapsedTimeChanged
	 object: self];
}

-(NSTimeInterval) timeToGo
{
    return timeToGo;
}

- (void) setTimeToGo:(NSTimeInterval)aValue
{
    timeToGo = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDistributedRunTimeToGoChanged
	 object: self];
}

- (BOOL) timedRun
{
    return timedRun;
}

- (void) setTimedRun:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimedRun:[self timedRun]];
    timedRun = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDistributedRunTimedRunChanged
	 object: self];
}

- (BOOL) repeatRun
{
    return repeatRun;
}

- (void) setRepeatRun:(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRepeatRun:[self repeatRun]];
    repeatRun = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDistributedRunRepeatRunChanged
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
	 postNotificationName:ORDistributedRunTimeLimitChanged
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


-(BOOL) quickStart
{
    return quickStart;
}

- (void) setQuickStart:(BOOL)flag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setQuickStart:quickStart];
    quickStart = flag;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORDistributedRunQuickStartChanged
	 object: self];
}

- (int) runningState
{
    return runningState;
}

- (void) setRunningState:(int)aRunningState
{
    if(aRunningState != runningState){
        for(ORRemoteRunItem* anOrca in remoteRunItems){
            [anOrca setRunningState:aRunningState];
        }
        runningState = aRunningState;
        
        NSDictionary* userInfo = [NSDictionary
								  dictionaryWithObjectsAndKeys:[NSNumber
																numberWithInt:runningState],ORRunStatusValue,
								  runState[runningState],ORRunStatusString,nil];
        
        [[NSNotificationCenter defaultCenter]
		 postNotificationName:ORDistributedRunStatusChanged
		 object: self
		 userInfo: userInfo];
    }
}

#pragma mark ¥¥¥Run Stuff
- (void) startRun
{
    for(ORRemoteRunItem* anOrca in remoteRunItems){
        [anOrca startRun:!quickStart];
    }
    [self setStartTime:[NSDate date]];
    [self startTimer];
}

- (void) startTimer
{
    [timer invalidate];
    [timer release];
    timer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(incrementTime:)userInfo:nil repeats:YES] retain];
}

- (void) incrementTime:(NSTimer*)aTimer
{
    if([self isRunning]){
        NSTimeInterval deltaTime = -[startTime timeIntervalSinceNow];
        [self setElapsedRunTime:deltaTime];
        
        NSTimeInterval t = (timeLimit - deltaTime)+1;
        if(t<0)t=0; //prevent negative values
        [self setTimeToGo:t];
        if(timedRun &&(deltaTime >= timeLimit)){
            if(repeatRun){
                [[NSNotificationCenter defaultCenter] postNotificationName:ORRunIsAboutToRollOver
                                                                    object:self];
            }
            [self stopRun];
        }
    }
}

- (void) setElapsedRunTime:(NSTimeInterval)aValue
{
    elapsedTime = aValue;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ORDistributedRunElapsedTimeChanged
     object: self];
}

- (void) haltRun
{
    [self stopRun];
}

- (void)stopRun
{
    for(ORRemoteRunItem* anOrca in remoteRunItems){
        [anOrca stopRun];
    }
    
    [timer invalidate];
    [timer release];
    timer = nil;
    timeHalted = [NSDate timeIntervalSinceReferenceDate];
    [self waitForRunStop];
}

- (NSInteger) numberConnected
{
    return numberConnected;
}

- (void) setNumberConnected:(NSInteger)aValue;
{
    numberConnected = aValue;
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ORDistributedRunNumberConnectedChanged
     object: self
     userInfo: nil];
}

- (NSInteger) numberRunning
{
    return numberRunning;
}

- (void) setNumberRunning:(NSInteger)aValue;
{
    numberRunning = aValue;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ORDistributedRunNumberRunningChanged
     object: self
     userInfo: nil];
}

- (void) doTimedUpdate
{
    for(ORRemoteRunItem* anOrca in remoteRunItems){
        [anOrca doTimedUpdate];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doTimedUpdate) object:nil];
    [self performSelector:@selector(doTimedUpdate) withObject:nil afterDelay:2];
}

- (void) connectAll
{
    for(ORRemoteRunItem* anOrca in remoteRunItems){
        if(![anOrca isConnected])[anOrca connectSocket:YES];
    }
}

- (void) disConnectAll
{
    for(ORRemoteRunItem* anOrca in remoteRunItems){
        if([anOrca isConnected])[anOrca connectSocket:NO];
    }
}

- (NSMutableArray*) remoteRunItems
{
    return remoteRunItems;
}

- (void) setRemoteRunItems:(NSMutableArray*)anItem
{
    [anItem retain];
    [remoteRunItems release];
    remoteRunItems = anItem;
}

- (NSInteger) numberRemoteSystems;
{
    return [remoteRunItems count];
}

#pragma mark ¥¥¥Archival
-(id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    
    [self setTimeLimit:     [decoder decodeIntegerForKey:@"runTimeLimit"]];
    [self setTimedRun:      [decoder decodeBoolForKey:   @"timedRun"]];
    [self setRepeatRun:     [decoder decodeBoolForKey:   @"repeatRun"]];
    [self setQuickStart:    [decoder decodeBoolForKey:   @"quickStart"]];
    
    [self setRemoteRunItems:[decoder decodeObjectForKey:@"remoteRunItems"]];
    [self ensureMinimumNumberOfRemoteItems];
    [remoteRunItems makeObjectsPerformSelector:@selector(setOwner:) withObject:self];

    [[self undoManager] enableUndoRegistration];
    
    return self;
}

-(void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:timeLimit     forKey:@"runTimeLimit"];
    [encoder encodeBool:timedRun         forKey:@"timedRun"];
    [encoder encodeBool:repeatRun        forKey:@"repeatRun"];
    [encoder encodeBool:quickStart       forKey:@"quickStart"];
    [encoder encodeObject:remoteRunItems forKey:@"remoteRunItems"];
}


-(NSString*) commandID
{
    return @"DistributedRunControl";
}

- (void) scanAndUpdate
{
    int numConnected = 0;
    int numRunning = 0;
    for(ORRemoteRunItem* anOrca in remoteRunItems){
        if([anOrca isConnected])                  numConnected++;
        if([anOrca runningState] == eRunInProgress)numRunning++;
    }
    [self setNumberRunning:numRunning];
    [self setNumberConnected:numConnected];
}

#pragma mark ¥¥¥Remote
- (void) fullUpdate
{
    for(ORRemoteRunItem* anOrca in remoteRunItems){
        [anOrca fullUpdate];
    }
}

- (void) sendSetup
{
    for(ORRemoteRunItem* anOrca in remoteRunItems){
        [anOrca sendSetup];
    }
}
-
(void) ensureMinimumNumberOfRemoteItems
{
    if(!remoteRunItems)[self setRemoteRunItems:[NSMutableArray array]];
    if([remoteRunItems count] == 0){
        ORRemoteRunItem* anItem = [[ORRemoteRunItem alloc] initWithOwner:self];
        [remoteRunItems addObject:anItem];
        [anItem release];
    }
}

- (void) addRemoteRunItem
{
    ORRemoteRunItem* anItem = [[ORRemoteRunItem alloc] initWithOwner:self];
    [remoteRunItems addObject:anItem];
    [anItem release];
}

- (void) addRemoteRunItem:(ORRemoteRunItem*)anItem afterItem:(ORRemoteRunItem*)anotherItem
{
    int index = (int)[remoteRunItems indexOfObject:anotherItem];
    if(![remoteRunItems containsObject:anItem]){
        [remoteRunItems insertObject:anItem atIndex:index];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORRemoteRunItemAdded object:self userInfo:[NSDictionary dictionaryWithObject:anItem forKey:@"RemoteRunItem"]];
    }
}

- (void) removeRemoteRunItem:(ORRemoteRunItem*)anItem
{
    if([remoteRunItems count] > 1){
        [anItem retain];
        [remoteRunItems removeObject:anItem];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORRemoteRunItemRemoved object:self userInfo:[NSDictionary dictionaryWithObject:anItem forKey:@"RemoteRunItem"]];
        [anItem release];
    }
}
@end

@implementation ORDistributedRunModel (private)
- (void) waitForRunStop
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(waitForRunStop) object:nil];
	
	if(numberRunning==0){
		NSLog(@"-------------------------------------\n");
		NSLog(@"All remote runs stopped.\n");
		NSLog(@"-------------------------------------\n");
		return;
	}
	if([NSDate timeIntervalSinceReferenceDate]-timeHalted > 8){
		NSLog(@"TimeOut waiting for remote runs to stop.\n");
        NSLog(@"%ld remote systems still running\n",numberRunning);
		return;
	}
    [self performSelector:@selector(waitForRunStop) withObject:nil afterDelay:1];
}
@end
