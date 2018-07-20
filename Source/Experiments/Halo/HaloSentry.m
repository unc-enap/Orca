//-------------------------------------------------------------------------
//  HaloSentry.m
//
//  Created by Mark Howe on Saturday 12/01/2012.
//  Copyright (c) 2012 University of North Carolina. All rights reserved.
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

#pragma mark ***Imported Files
#import "HaloSentry.h"
#import "ORTaskSequence.h"
#import "NetSocket.h"
#import "ORRunModel.h"
#import "SBC_Link.h"
#import "ORShaperModel.h"
#import "ORDataFileModel.h"
#import "ORDataTaskModel.h"

NSString* HaloSentryIpNumber2Changed = @"HaloSentryIpNumber2Changed";
NSString* HaloSentryIpNumber1Changed = @"HaloSentryIpNumber1Changed";
NSString* HaloSentryIsPrimaryChanged = @"HaloSentryIsPrimaryChanged";
NSString* HaloSentryIsRunningChanged = @"HaloSentryIsRunningChanged";
NSString* HaloSentryStateChanged     = @"HaloSentryStateChanged";
NSString* HaloSentryTypeChanged      = @"HaloSentryTypeChanged";
NSString* HaloSentryIsConnectedChanged  = @"HaloSentryIsConnectedChanged";
NSString* HaloSentryRemoteStateChanged  = @"HaloSentryRemoteStateChanged";
NSString* HaloSentryStealthMode2Changed     = @"HaloSentryStealthMode2Changed";
NSString* HaloSentryStealthMode1Changed     = @"HaloSentryStealthMode1Changed";
NSString* HaloSentryMissedHeartbeat         = @"HaloSentryMissedHeartbeat";
NSString* HaloSentrySbcRootPwdChanged       = @"HaloSentrySbcRootPwdChanged";
NSString* HaloSentryToggleIntervalChanged   = @"HaloSentryToggleIntervalChanged";

#define kRemotePort 4667


@implementation HaloSentry

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [self registerNotificationObservers];
    unPingableSBCs = [[NSMutableArray arrayWithArray:sbcs]retain];

    return self;
}

- (void) dealloc 
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [socket release];
    [ipNumber2 release];
    [ipNumber1 release];
    [sbcs release];
    [shapers release];
    [runControl release];
    [otherSystemIP release];
    [thisSystemIP release];
    [unPingableSBCs release];
    [pingTask release];
    [sbcRootPwd release];
    [sentryLog release];
    [toggleTimer invalidate];
    [toggleTimer release];
    [nextToggleTime release];
    
    [self clearAllAlarms];
    
    [super dealloc];
}

- (void) sleep
{
    [self stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) wakeUp
{
    if(wasRunning)[self start];
    [self registerNotificationObservers];
}

- (void) awakeAfterDocumentLoaded
{
    if(wasRunning) [self start];
    [self collectObjects];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORGroupObjectsAdded
                       object : nil];
    
	[notifyCenter addObserver : self
                     selector : @selector(objectsChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStarted:)
                         name : ORRunStartedNotification
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStarted:)
                         name : ORRunStartSubRunNotification
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStopped:)
                         name : ORRunStoppedNotification
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(sbcSocketDropped:)
                         name : SBC_SocketDroppedUnexpectedly
						object: nil];
    
}

#pragma mark ***Notifications
- (void) objectsChanged:(NSNotification*)aNote
{
    [self collectObjects];
}

- (void) collectObjects
{

    [sbcs release];
    sbcs = nil;
    sbcs = [[[(ORAppDelegate*)[NSApp delegate]document] collectObjectsOfClass:NSClassFromString(@"ORVmecpuModel")]retain]; //SV

    [shapers release];
    shapers = nil;
    shapers = [[[(ORAppDelegate*)[NSApp delegate]document] collectObjectsOfClass:NSClassFromString(@"ORShaperModel")]retain];
    
    [runControl release];
    runControl = nil;
    NSArray* anArray = [[(ORAppDelegate*)[NSApp delegate]document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if([anArray count])runControl = [[anArray objectAtIndex:0] retain];
}

- (void) runStarted:(NSNotification*)aNote
{
    //a local run has started
    if(sentryIsRunning && !ignoreRunStates){
        [self setSentryType:ePrimary];
        [self setNextState:eStarting stepTime:.2];
        if(![toggleTimer isValid] && !scheduledToggleTime)[self startTimer]; //SV
        [self step];
        [self updateRemoteMachine];
    }
}

- (void) runStopped:(NSNotification*)aNote
{
    //a local run has ended. Switch back to being a neutral system
    if(sentryIsRunning && !ignoreRunStates){
         //SV
         if(scheduledToggleTime)
         {
             [self doScheduledToggle];
             [runControl setIgnoreRepeat:FALSE];
         }
         else
         {
             for(id anSBC in sbcs)[[anSBC sbcLink] pingVerbose:NO];
             [self setSentryType:eNeither];
             [self setNextState:eStarting stepTime:.2];
         }
        [self step];
    }
}

- (void) sbcSocketDropped:(NSNotification*)aNote
{
    if(sentryIsRunning){
        [self appendToSentryLog:@"Sentry notified of SBC socket dropped"];
        
        if(!toggleAction && ([self sentryType]!=eSecondary)){
            [self appendToSentryLog:@"Dropped socket issue will be resolved by this DAQ"];
            
            //SV - June 28th 2016
            //If an SBC was dropped, stop toggling between computers. The scheduler will have to be manually restarted.
            [self setToggleInterval:0];
            
            //the sbc socket was dropped. Most likely caused by the sbc readout process dying.
            ignoreRunStates = YES;
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleSbcSocketDropped) object:nil];
            [self performSelector:@selector(handleSbcSocketDropped) withObject:nil afterDelay:60]; //Changed delay from 5 to 60
        }
    }
}

#pragma mark ***Accessors

- (int)  sbcSocketDropCount
{
    return sbcSocketDropCount;
}

- (int)  restartCount
{
    return restartCount;
}

- (int)  sbcPingFailedCount
{
    return sbcPingFailedCount;
}

- (int)  macPingFailedCount
{
    return macPingFailedCount;
}
- (int)  sbcRebootCount
{
    return sbcRebootCount;
}

- (NSString*)sbcRootPwd
{
    if(sbcRootPwd)return sbcRootPwd;
    else return @"";
}

- (void) setSbcRootPwd:(NSString*)aString
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSbcRootPwd:sbcRootPwd];
    [sbcRootPwd autorelease];
    sbcRootPwd = [aString copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryIsRunningChanged object:self];
}

- (BOOL) sentryIsRunning
{
    return sentryIsRunning;
}
- (void) setSentryIsRunning:(BOOL)aState
{
    wasRunning = aState;
    sentryIsRunning = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryIsRunningChanged object:self];
}

- (BOOL) otherSystemStealthMode
{
    return otherSystemStealthMode;
}

- (BOOL) stealthMode2
{
    return stealthMode2;
}

- (void) setStealthMode2:(BOOL)aStealthMode2
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStealthMode2:stealthMode2];
    stealthMode2 = aStealthMode2;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryStealthMode2Changed object:self];
    [self setOtherIP];
}

- (BOOL) stealthMode1
{
    return stealthMode1;
}

- (void) setStealthMode1:(BOOL)aStealthMode1
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStealthMode1:stealthMode1];
    stealthMode1 = aStealthMode1;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryStealthMode1Changed object:self];
    [self setOtherIP];
}

- (NSString*) ipNumber2
{
    if(!ipNumber2)return @"";
    else return ipNumber2;
}

- (void) setIpNumber2:(NSString*)aIpNumber2
{
    if(!aIpNumber2)aIpNumber2 = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIpNumber2:ipNumber2];
    
    [ipNumber2 autorelease];
    ipNumber2 = [aIpNumber2 copy];    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryIpNumber2Changed object:self];
    [self setOtherIP];

}

- (NSString*) ipNumber1
{
    if(!ipNumber1)return @"";
    else return ipNumber1;
}

- (void) setIpNumber1:(NSString*)aIpNumber1
{
    if(!aIpNumber1)aIpNumber1 = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIpNumber1:ipNumber1];
    
    [ipNumber1 autorelease];
    ipNumber1 = [aIpNumber1 copy];    
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryIpNumber1Changed object:self];
    [self setOtherIP];
}

- (void) setOtherIP
{
    //one of the addresses is ours, one is the other machine
    //we need to know which is which so
    if(ipNumber1 && ipNumber2){
        NSArray* addresses =  [[NSHost currentHost] addresses];
        for(id anAddress in addresses){
            if([anAddress isEqualToString:ipNumber1]){
                [otherSystemIP autorelease];
                otherSystemIP = [ipNumber2 copy];
                [thisSystemIP autorelease];
                thisSystemIP = [ipNumber1 copy];
                otherSystemStealthMode = stealthMode2;
                break;
            }
            if([anAddress isEqualToString:ipNumber2]){
                [otherSystemIP autorelease];
                otherSystemIP = [ipNumber1 copy];
                [thisSystemIP autorelease];
                thisSystemIP = [ipNumber2 copy];
                otherSystemStealthMode = stealthMode1;
                break;
            }
        }
    }
}


- (enum eHaloStatus) remoteMachineReachable
{
    return remoteMachineReachable;
}

- (void) setRemoteMachineReachable:(enum eHaloStatus)aState
{
    remoteMachineReachable = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryRemoteStateChanged object:self];
}

- (enum eHaloStatus) remoteORCARunning
{
    return remoteORCARunning;
}

- (void) setRemoteORCARunning:(enum eHaloStatus)aState
{
    remoteORCARunning = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryRemoteStateChanged object:self];
}


- (enum eHaloStatus) remoteRunInProgress
{
    return remoteRunInProgress;
}

- (void) setRemoteRunInProgress:(enum eHaloStatus)aState
{
    remoteRunInProgress = aState;
    
    if((aState == eYES) && sentryIsRunning){
        [[ORGlobal sharedGlobal] addRunVeto:@"Secondary" comment:@"Run in progress on Primary Machine"];
    }
    else {
        [[ORGlobal sharedGlobal] removeRunVeto:@"Secondary"];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryRemoteStateChanged object:self];
}

- (enum eHaloSentryType) sentryType
{
    return sentryType;
}

- (void) setSentryType:(enum eHaloSentryType)aType;
{
    sentryType = aType;
    if(sentryType!=eTakeOver)ignoreRunStates = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryTypeChanged object:self];
}

- (NSString*) stateName
{
    switch(state){
        case eIdle:                 return @"Idle";
        case eStarting:             return @"Starting";
        case eStopping:             return @"Stopping";
        case eCheckRemoteMachine:   return @"Pinging";
        case eConnectToRemoteOrca:  return @"Connecting";
        case eGetRunState:          return @"GetRunState";
        case eCheckRunState:        return @"Checking Run";
        case eWaitForPing:          return @"Ping Wait";
        case eGetSecondaryState:    return @"Checking Sentry";
        case eWaitForLocalRunStop:  return @"Run Stop Wait";
        case eWaitForRemoteRunStop: return @"Run Stop Wait";
        case eWaitForLocalRunStart: return @"Run Start Wait";
        case eWaitForRemoteRunStart:return @"Run Start Wait";
        case eKillCrates:           return @"Killing Crates";
        case eKillCrateWait:        return @"Wait For Crates";
        case eStartCrates:          return @"Starting Crates";
        case eStartCrateWait:       return @"Wait For Crates";
        case eStartRun:             return @"Starting Run";
        case eCheckRun:             return @"Checking Run";
        case eBootCrates:           return @"Booting Crates";
        case eWaitForBoot:          return @"Waiting For Crates";
        case ePingCrates:           return @"Pinging Crates";
        default:                    return @"?";
    }
}

- (NSString*) sentryTypeName
{
    switch(sentryType){
        case eNeither:          return @"Waiting";
        case ePrimary:          return @"Primary";
        case eSecondary:        return @"Secondary";
        case eHealthyToggle:    return @"Toggle";
        case eTakeOver:         return @"TakeOver";
        default:                return @"?";
    }
}

- (NSString*) remoteMachineStatusString
{
    if(remoteMachineReachable == eOK){
        if(otherSystemStealthMode) return @"Stealth Mode";
        else                       return @"Reachable";
    }
    else if(remoteMachineReachable == eBad)          return  @"Unreachable";
    else if(remoteMachineReachable == eBeingChecked) return  @"Being Checked";
    else return @"?";
}

- (NSString*) connectionStatusString
{
    if(missedHeartbeatCount==0){
        if(remoteORCARunning == eYES)               return @"Connected";
        else if(remoteORCARunning == eBad)          return @"NOT Connected";
        else if(remoteORCARunning == eBeingChecked) return @"Being Checked";
    }
    else if(missedHeartbeatCount<kMaxHungCount){
        return [NSString stringWithFormat:@"Missed %d Heartbeat%@",missedHeartbeatCount,missedHeartbeatCount>1?@"s":@""];
    }
    return @"Hung";
}

- (NSString*) remoteORCArunStateString
{
    if(remoteMachineReachable == eOK){
        if(remoteRunInProgress == eOK)               return @"Running";
        else if(remoteRunInProgress == eBad)         return @"NOT Running";
        else if(remoteRunInProgress == eBeingChecked)return @"Being Checked";
    }
    return @"?";
}

- (enum eHaloSentryState) state
{
    return state;
}

- (void) setNextState:(enum eHaloSentryState)aState stepTime:(NSTimeInterval)aStep
{
    nextState = aState;
    stepTime = aStep;
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

- (BOOL) isConnected
{
	return isConnected;
}

- (void) setIsConnected:(BOOL)aIsConnected
{
	isConnected = aIsConnected;
	[[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryIsConnectedChanged object:self];
}

- (BOOL) runIsInProgress
{
    return (remoteRunInProgress == eYES) || [runControl isRunning];
}

//SV
- (NSMutableArray*) sentryLog
{
    return sentryLog;
}

//SV
- (BOOL) toggleTimerIsRunning
{
    return [toggleTimer isValid];
}

//SV
- (int)toggleInterval
{
    return toggleInterval;
}

//SV
- (BOOL) scheduledToggleTime
{
    return scheduledToggleTime;
}

//SV
//MAH -- added setter because that's the way to do things
- (void) setNextToggleTime:(NSString*)aString
{
    
    [nextToggleTime autorelease];
    nextToggleTime = [aString copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryToggleIntervalChanged object:self];
}

- (NSString*) nextToggleTime
{
    if(!nextToggleTime) nextToggleTime = @"None scheduled"; //MAH -- can never have nil string
    return nextToggleTime;
}

//SV
- (void) setToggleInterval:(int) seconds
{
    [[[self undoManager] prepareWithInvocationTarget:self] setToggleInterval:toggleInterval];
    
    scheduledToggleTime = FALSE;
    [runControl setIgnoreRepeat:FALSE];
    
    toggleInterval = seconds;
    [self appendToSentryLog:[NSString stringWithFormat:@"Toggle interval set to %i day(s)", toggleInterval/86400]];
    if(toggleTimer==0) [self setNextToggleTime:@"None scheduled"];
    
    //If timer was already running, restart with new setup/toggle interval
    if([toggleTimer isValid]) {
        [self appendToSentryLog:@"Resetting timer"];
        [self stopTimer];
        [self startTimer];
    }
    
}

//SV
- (void) startTimer
{
    if (toggleInterval > 0 && sentryIsRunning){
        [self appendToSentryLog:@"Starting sentry timer"];
        if ([toggleTimer isValid]){ [toggleTimer release]; }
        toggleTimer = [[NSTimer scheduledTimerWithTimeInterval:toggleInterval target:self selector:@selector(waitForEndOfRun:) userInfo:nil repeats:NO] retain];
        [self setNextToggleTime:[NSString stringWithFormat:@"%@", [[[NSDate date] dateByAddingTimeInterval:toggleInterval] stdDescription]]];
    }
}

//SV
- (void) stopTimer
{
    scheduledToggleTime = FALSE;
    if ([toggleTimer isValid]){
        [self appendToSentryLog:@"Stopping sentry timer"];
        [toggleTimer invalidate];
        [toggleTimer release];
        toggleTimer = nil;
    }
    
    [self setNextToggleTime : @"None scheduled"];
}

//SV
- (void) doScheduledToggle
{
    if(sentryIsRunning){
        [self appendToSentryLog:@"TOGGLING NOW"];
        [self toggleSystems];
        scheduledToggleTime = FALSE;
    }
}

//SV
- (void) waitForEndOfRun:(NSTimer*)aTimer
{
    [toggleTimer invalidate];
    [toggleTimer release];
    toggleTimer = nil;
    
    //If local run in progress
    if ([[ORGlobal sharedGlobal] runInProgress]){
        [self appendToSentryLog:@"Scheduled sentry system toggle"];
        [self appendToSentryLog:@"Waiting for local run to end"];
        scheduledToggleTime = TRUE;
        [runControl setIgnoreRepeat:TRUE];
        [self setNextToggleTime : @"Waiting for end of run"];
    }
    
    else{
        [self appendToSentryLog:@"Timer was stopped"];
        [self setNextToggleTime : @"None scheduled"];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryToggleIntervalChanged object:self];
}
    
#pragma mark ***Run Stuff
- (void) start
{
    if(sentryIsRunning || [otherSystemIP length]==0)return;
    [self setSentryIsRunning:YES];
    [self setSentryType:eNeither];
    [self setNextState:eStarting stepTime:1];
    [toggleTimer invalidate];
    [toggleTimer release];
    toggleTimer = nil; //SV
    toggleAction = false;
    [self appendToSentryLog:@"Sentry started."]; //SV
    [self step];
}

- (void) stop
{
    if (!sentryIsRunning) return;
    [self setNextState:eStopping stepTime:1];
    [self step];
    [[ORGlobal sharedGlobal] removeRunVeto:@"Secondary"];
    [self stopTimer]; //SV
    [self appendToSentryLog:@"Sentry stopped."]; //SV
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setIpNumber2:     [decoder decodeObjectForKey: @"ipNumber2"]];
    [self setIpNumber1:     [decoder decodeObjectForKey: @"ipNumber1"]];
    [self setStealthMode2:  [decoder decodeBoolForKey:   @"stealthMode2"]];
    [self setStealthMode1:  [decoder decodeBoolForKey:   @"stealthMode1"]];
    [self setSbcRootPwd:    [decoder decodeObjectForKey: @"sbcRootPwd"]];
    [self setToggleInterval:[decoder decodeFloatForKey: @"toggleInterval"]];
    
    wasRunning = [decoder decodeBoolForKey: @"wasRunning"];
    [[self undoManager] enableUndoRegistration];
    
    [self registerNotificationObservers];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:ipNumber2     forKey: @"ipNumber2"];
    [encoder encodeObject:ipNumber1     forKey: @"ipNumber1"];
    [encoder encodeBool:stealthMode2    forKey: @"stealthMode2"];
    [encoder encodeBool:stealthMode1    forKey: @"stealthMode1"];
    [encoder encodeBool:wasRunning      forKey: @"wasRunning"];
    [encoder encodeObject:sbcRootPwd    forKey: @"sbcRootPwd"];
    [encoder encodeFloat:toggleInterval forKey: @"toggleInterval"];
}

- (NSUndoManager *)undoManager
{
    return [[(ORAppDelegate*)[NSApp delegate]document]  undoManager];
}

- (void) postConnectionAlarm
{
    if(sentryIsRunning){
        if(!noConnectionAlarm){
            noConnectionAlarm = [[ORAlarm alloc] initWithName:@"No ORCA Connection" severity:kHardwareAlarm];
            [noConnectionAlarm setHelpString:@"No connection can be made to the other ORCA.\n\nThis alarm will remain until the condition is fixed. You may acknowledge the alarm to silence it"];
            [noConnectionAlarm setSticky:YES];
        }
        [noConnectionAlarm postAlarm];
    }
}

- (void) clearConnectionAlarm
{
    [noConnectionAlarm clearAlarm];
    noConnectionAlarm = nil;
}

- (void) postMacPingAlarm
{
    if(sentryIsRunning){
        macPingFailedCount++;

        if(!macPingFailedAlarm && !otherSystemStealthMode){
            NSString* alarmName = [NSString stringWithFormat:@"%@ Unreachable",otherSystemIP];
            macPingFailedAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kHardwareAlarm];
            [macPingFailedAlarm setHelpString:@"The backup machine is not reachable.\n\nThis alarm will remain until the condition is fixed. You may acknowledge the alarm to silence it"];
            [macPingFailedAlarm setSticky:YES];
        }
        [macPingFailedAlarm postAlarm];
    }
}

- (void) clearMacPingAlarm
{
    [macPingFailedAlarm clearAlarm];
    macPingFailedAlarm = nil;
}

- (void) postSBCPingAlarm:(NSArray*)sbcList
{
    if(sentryIsRunning){
        if(!sbcPingFailedAlarm){
            sbcPingFailedAlarm = [[ORAlarm alloc] initWithName:@"SBC(s) Failed Ping" severity:kHardwareAlarm];
            NSString* s = @"SBCs that are unreachable:\n";
            for(id anSBC in sbcList){
                s = [s stringByAppendingFormat:@"%@\n",[[anSBC sbcLink] IPNumber]];
            }
            s = [s stringByAppendingString:@"\n\nThis alarm will remain until the condition is fixed. You may acknowledge the alarm to silence it"];
            [sbcPingFailedAlarm setHelpString:s];
            [sbcPingFailedAlarm setSticky:YES];
        }
        [sbcPingFailedAlarm postAlarm];
    }
}

- (void) clearSBCPingAlarm
{
    [sbcPingFailedAlarm clearAlarm];
    sbcPingFailedAlarm = nil;
}

- (void) postOrcaHungAlarm
{
    if(sentryIsRunning){
        if(!orcaHungAlarm){
            NSString* alarmName = [NSString stringWithFormat:@"ORCA %@ Hung",otherSystemIP];
            orcaHungAlarm = [[ORAlarm alloc] initWithName:alarmName severity:kHardwareAlarm];
            [orcaHungAlarm setHelpString:@"The other ORCA appears hung.\n\nThis alarm will remain until the condition is fixed. You may acknowledge the alarm to silence it"];
            [orcaHungAlarm setSticky:YES];
        }
        [orcaHungAlarm postAlarm];
    }
}


- (void) clearOrcaHungAlarm
{
    [orcaHungAlarm clearAlarm];
    orcaHungAlarm = nil;
}

- (void) postNoRemoteSentryAlarm
{
    if(sentryIsRunning) {
        if(!noRemoteSentryAlarm){
            noRemoteSentryAlarm = [[ORAlarm alloc] initWithName:@"No Remote Sentry" severity:kInformationAlarm];
            [noRemoteSentryAlarm setHelpString:@"There is no remote sentry watching this machine.\n\nThis alarm will remain until the condition is fixed. You may acknowledge the alarm to silence it"];
            [noRemoteSentryAlarm setSticky:YES];
        }
        [noRemoteSentryAlarm postAlarm];
    }
}


- (void) clearNoRemoteSentryAlarm
{
    [noRemoteSentryAlarm clearAlarm];
    noRemoteSentryAlarm = nil;
}

- (void) postRunProblemAlarm:(NSString*)aTitle
{
    if(sentryIsRunning){
        if(!runProblemAlarm){
            runProblemAlarm = [[ORAlarm alloc] initWithName:aTitle severity:kHardwareAlarm];
            [runProblemAlarm setHelpString:@"There was trouble with the run state.\n\nThis alarm will remain until the condition is fixed. You may acknowledge the alarm to silence it"];
            [runProblemAlarm setSticky:YES];
        }
        [runProblemAlarm postAlarm];
    }
}

- (void) clearRunProblemAlarm
{
    [runProblemAlarm clearAlarm];
    runProblemAlarm = nil;
}

- (void) postListModAlarm
{
    if(sentryIsRunning){
        if(!listModAlarm){
            listModAlarm = [[ORAlarm alloc] initWithName:@"Readout List Modified" severity:kHardwareAlarm];
            [listModAlarm setHelpString:@"There was a problem with one of the SBCs, so the offending object was removed from the readout list"];
            [listModAlarm setSticky:NO];
        }
        [listModAlarm postAlarm];
    }
}


- (void) clearListModAlarm
{
    [listModAlarm clearAlarm];
    listModAlarm = nil;
}

- (void) clearAllAlarms
{
    [self clearMacPingAlarm];
    [self clearConnectionAlarm];
    [self clearOrcaHungAlarm];
    [self clearNoRemoteSentryAlarm];
    [self clearRunProblemAlarm];
    [self clearListModAlarm];
    [self clearSBCPingAlarm];
}

#pragma mark •••Finite State Machines
- (void) step
{
    state    =  nextState;
    loopTime += stepTime;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryStateChanged object:self];
   
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(step) object:nil];
    
    switch(sentryType){
        case eNeither:      [self stepSimpleWatch];     break;
        case ePrimary:      [self stepPrimarySystem];   break;
        case eSecondary:    [self stepSecondarySystem]; break;
        case eHealthyToggle:[self stepHealthyToggle];   break;
        case eTakeOver:     [self stepTakeOver];        break;
    }
    
    if(state!=eIdle)[self performSelector:@selector(step) withObject:nil afterDelay:stepTime];
}

//------------------------------------------------------------------
//Neither system is running. Just check the other system and ensure that the network is alive
//and that ORCA is running. If a run is started on a machine, that machine will become primary
//and the other one will become secondary
- (void) stepSimpleWatch
{
    toggleAction = false;
    switch (state){
        case eStarting:
            [self setRemoteMachineReachable:eBeingChecked];
            [self setRemoteRunInProgress: eUnknown];
            [self setNextState:eCheckRemoteMachine stepTime:.3];
            break;
            
        case eCheckRemoteMachine:
            [self ping];
            [self setNextState:eWaitForPing stepTime:3];
            break;
            
        case eWaitForPing:
            if(!pingTask){
                if(remoteMachineReachable == eYES){
                    [self setRemoteORCARunning:eBeingChecked];
                    [self setNextState:eConnectToRemoteOrca stepTime:1];
                    [self clearMacPingAlarm];
                }
                else {
                    [self setNextState:eCheckRemoteMachine stepTime:60];
                    [self postMacPingAlarm]; //just watching, so just post alarm
                }
            }
            break;
 
        case eConnectToRemoteOrca:
            if(!isConnected)[self connectSocket:YES];
            else [self setRemoteORCARunning:eYES];

            [self setNextState:eGetRunState stepTime:2];
            break;
            
        case eGetRunState:
            if(isConnected){
                [self clearConnectionAlarm];
                [self sendCmd:@"runStatus = [RunControl runningState];"];
                [self setNextState:eCheckRunState stepTime:1];
           }
            else {
                if(!isConnected)[self connectSocket:YES];
                else [self setRemoteORCARunning:eYES];
                [self setRemoteORCARunning:eBeingChecked];
                [self setNextState:eCheckRemoteMachine stepTime:10];
            }
            break;
            
        case eCheckRunState:
            if(remoteRunInProgress != eYES){
                [self setNextState:eGetRunState stepTime:10];
            }
            else {
               //the remote machine is running. Flip over to being the secondarySystem
                [self setSentryType:eSecondary];
                [self setNextState:eStarting stepTime:.3];
            }
            break;

        case eStopping:
            [self finish];
          break;
            
        default: break;
    }

}

//------------------------------------------------------------------
//We are the primary, we are taking data. We will just monitor the other
//system to ensure that it is alive. If not, all we do is post an alarm.
- (void) stepPrimarySystem
{
    toggleAction = false;
    switch (state){
        case eStarting:
            //SV [self clearAllAlarms];
            [self setRemoteMachineReachable:eBeingChecked];
            [self setNextState:eCheckRemoteMachine stepTime:.3];
            break;
            
        case eCheckRemoteMachine:
            [self ping];
            [self setNextState:eWaitForPing stepTime:1];
            break;
            
        case eWaitForPing:
            if(!pingTask){
                if(remoteMachineReachable == eYES){
                    [self setNextState:eConnectToRemoteOrca stepTime:10];
                    [self clearMacPingAlarm];
               }
                else {
                    [self postMacPingAlarm];
                    [self setNextState:eCheckRemoteMachine stepTime:60];
                    //remote machine not running. post alarm and retry later
                    //we are just watching at this point so do nothing other than
                    //the alarm post
                }
            }
            break;
 
        case eConnectToRemoteOrca:
            if(!isConnected)[self connectSocket:YES];
            else [self setRemoteORCARunning:eYES];
            [self setNextState:eGetSecondaryState stepTime:2];
            break;
            
        case eGetSecondaryState:
            if(isConnected){
                [self sendCmd:@"remoteSentryRunning = [HaloModel sentryIsRunning];"];
                [self setNextState:eGetSecondaryState stepTime:30];
            }
            else {
                [self setNextState:eCheckRemoteMachine stepTime:10];
            }
            break;

            
        case eStopping:
            [self finish];
            break;
            
        default: break;
    }
}

//------------------------------------------------------------------
//We are the secondary system -- the machine in waiting. We monitor the other machine and
//if it dies, we have to take over and take control of the run
//this sentry type should not be run unless the connection is open and we are ready to take over
- (void) stepSecondarySystem
{
    toggleAction = false;
    switch (state){
        case eStarting:
            [self stopTimer]; //SV
            //SV [self clearAllAlarms];
            [self setRemoteRunInProgress:eBeingChecked];
            [self setNextState:eGetRunState stepTime:2];
           break;
            
        case eGetRunState:
            if(isConnected && !orcaHungAlarm){
                [self setNextState:ePingCrates stepTime:30];
                //we should get the runStatus at run boundaries, but we'll ask anyway
                [self sendCmd:@"runStatus = [RunControl runningState];"];
            }
            else {
                //the connection was dropped (other mac crashed) or other mac appears hung.
                //system("/usr/bin/killall Orca"); //SV - kill the hung Orca so that it does not come back up thinking it is primary, human intervention will be needed to bring it back up
                [self takeOverRunning];
            }
            break;
  
        case ePingCrates:
            [unPingableSBCs release]; //SV
            unPingableSBCs = [[NSMutableArray arrayWithArray:sbcs]retain]; //SV
            for(id anSBC in sbcs)[[anSBC sbcLink] pingVerbose:NO];
            [self setNextState:eWaitForPing stepTime:.2];
            loopTime = 0;
            break;

            
        case eWaitForPing:
            if(loopTime >= 7){
                if([unPingableSBCs count] == [sbcs count]){
                    [self appendToSentryLog:@"**Couldn't ping any of the SBCs."];
                }
                else {
                    [self appendToSentryLog:@"**Some of the SBCs responded to ping. Some didn't."];
                }
                [self postSBCPingAlarm:unPingableSBCs];
                sbcPingFailedCount += [unPingableSBCs count];

                //not much to do.. post alarm and stop. Intervention will be needed.
                [self setSentryType:eNeither];
                [self setNextState:eStarting stepTime:2];
                [self step];
            }
            else {
                for(id anSBC in sbcs){
                    if([[anSBC sbcLink]pingedSuccessfully]){
                        [unPingableSBCs removeObject:anSBC];
                    }
                }
                if([unPingableSBCs count] == 0){
                    //all OK
                    [self clearSBCPingAlarm]; //SV
                    [self clearMacPingAlarm];
                    [self setNextState:eGetRunState stepTime:2];
                }
            }
            break;

        case eStopping:
            [self finish];
            break;

        default: break;

    }
}

//------------------------------------------------------------------
//The System is running, but the user requested a toggle. Just do it
//
- (void) stepHealthyToggle
{
    toggleAction = true;
    switch (state){
        case eStarting:
            loopTime = 0;
            ignoreRunStates = YES;
            [self appendToSentryLog:@"Toggling healthy systems"];
            if([runControl isRunning]){
                wasLocalRun = YES;
                if(!scheduledToggleTime) //SV
                {
                    [self appendToSentryLog:@"Stopping local run."];
                    [runControl haltRun];
                }
                [self setNextState:eWaitForLocalRunStop stepTime:.1];
                [self stopTimer]; //SV
            }
            else if (remoteRunInProgress == eYES){
                wasLocalRun = NO;
                [self appendToSentryLog:@"Stopping remote run."];
                [self sendCmd:@"[RunControl haltRun];"];
                [self setNextState:eWaitForRemoteRunStop stepTime:2];
            }
            break;
            
        case eWaitForLocalRunStop:
            if(![runControl isRunning]){
                for(id anSBC in sbcs)[[anSBC sbcLink] disconnect];
                [self appendToSentryLog:@"Local run stopped. Passing control to other system"];
                [self sendCmd:@"[HaloModel takeOverRunning];"];
                [self setSentryType:eNeither];
                [self setNextState:eStarting stepTime:2];
           }
            else {
                if(loopTime>10){
                    //something is seriously wrong...
                    [self appendToSentryLog:[NSString stringWithFormat:@"Local run didn't stop after %.0f seconds.\n",loopTime]];
                    [self appendToSentryLog:@"Passing control to other system"];
                    [self postRunProblemAlarm:@"Local Run didn't stop"];
                    [self sendCmd:@"[HaloModel takeOverRunning];"];
                    [self setSentryType:eNeither];
                    [self setNextState:eStarting stepTime:2];
                }
            }
            break;
            
        case eWaitForRemoteRunStop:
            if(remoteRunInProgress == eNO){
                [self takeOverRunning:YES];
            }
            else {
                if(loopTime>10){
                    [self appendToSentryLog:[NSString stringWithFormat:@"Remote run didn't stop after %.0f seconds.\n",loopTime]];
                    [self postRunProblemAlarm:@"Remote Run didn't stop"];
                    [self takeOverRunning];
                }
            }
           break;
 
        default: break;
    }
}
//------------------------------------------------------------------
//Something is wrong with the other machine. It is hung or it dropped the
//connection to this machine. Either way we will take over the run.
//The main idea here is to kill the sbc readouts to prepare for the restart,
//then try and figure out if the sbcs are healthy, and then restart from
//this machine.
- (void) stepTakeOver
{
    toggleAction = true;
    switch (state){
        case eStarting:
            restartCount++;
            [self setNextState:eKillCrates stepTime:.1];
            break;
            
        case eKillCrates:
            [self appendToSentryLog:@"Killing Crates to ensure the socket is cleared."];
            for(id anSBC in sbcs)[[anSBC sbcLink] killCrate];
            [self setNextState:eKillCrateWait stepTime:.1];
            loopTime = 0;
            break;
            
        case eKillCrateWait:
            if(loopTime >= 8)[self setNextState:ePingCrates stepTime:.1];
            break;
  
        case ePingCrates:
            [unPingableSBCs release]; //SV
            unPingableSBCs = [[NSMutableArray arrayWithArray:sbcs]retain]; //SV
            [self appendToSentryLog:@"Pinging Crates"];
            for(id anSBC in sbcs)[[anSBC sbcLink] pingVerbose:NO];
            [self setNextState:eWaitForPing stepTime:1];
            loopTime = 0;
         break;

        case eWaitForPing:
            if(loopTime >= 5){
                if([unPingableSBCs count] == [sbcs count]){
                    [self appendToSentryLog:@"**None of the SBCs responded to ping. Nothing to be done."];
                    [self setSentryType:eNeither];
                    [self setNextState:eStarting stepTime:2];
                    [self step];
                }
                else {
                    [self appendToSentryLog:@"**Some of the SBCs responded to ping. Some didn't -- they are removed from readout list"];
                    [self removeFromReadoutList:unPingableSBCs];
                    //[sbcs removeObjectsInArray:unPingableSBCs]; //SV - remove to stop thinking it needs to remove SBCs from the readout list
                    [self setNextState:eStartCrates stepTime:2];
                }
                sbcPingFailedCount += [unPingableSBCs count];
                [self postSBCPingAlarm:unPingableSBCs];
            }
            else {
                for(id anSBC in sbcs){
                    if([[anSBC sbcLink]pingedSuccessfully]){
                        [unPingableSBCs removeObject:anSBC];
                    }
                }
                if([unPingableSBCs count] == 0){
                    [self clearSBCPingAlarm]; //SV
                    [self clearMacPingAlarm];
                    [self appendToSentryLog:@"All SBCs responded to ping"];
                    [self setNextState:eStartCrates stepTime:2];
                }
            }
            break;

            
        case eStartCrates:
            for(id anSBC in sbcs){
                if(![unPingableSBCs containsObject:anSBC]){
                    if([[anSBC sbcLink] isConnected])[[anSBC sbcLink] disconnect];
                    [self appendToSentryLog:[NSString stringWithFormat:@"Start crate @ %@",[[anSBC sbcLink] IPNumber]]];
                    [[anSBC sbcLink] setForceReload:NO];
                    [[anSBC sbcLink] startCrate];
                }
            }
            [self setNextState:eStartCrateWait stepTime:.1];
            loopTime = 0;
            break;
            
        case eStartCrateWait:
            if(loopTime >= 5){
                [self appendToSentryLog:@"**One or more crates didn't restart. Will try rebooting."];
                [self setNextState:eBootCrates stepTime:.1];
            }
            else {
                int connectedSBCCount=0;
                for(id anSBC in sbcs){
                    if(![unPingableSBCs containsObject:anSBC]){
                        if([[anSBC sbcLink]isConnected]){
                            connectedSBCCount++;
                        }
                    }
                }
                if(connectedSBCCount == ([sbcs count]-[unPingableSBCs count])){
                    [self setNextState:eStartRun stepTime:.1];
                }
            }
            break;

        case eStartRun:
            [self appendToSentryLog:@"Try to start run"];
            [[ORGlobal sharedGlobal] removeRunVeto:@"Secondary"];
            [runControl startRun];
            [self setNextState:eCheckRun stepTime:.1];
            loopTime = 0;
            break;

        case eCheckRun:
            if(loopTime >= 8){
                [self appendToSentryLog:@"**Run failed to start. Will try rebooting."];
                [self setNextState:eBootCrates stepTime:.1];
            }
            else if([runControl isRunning]){
                [self appendToSentryLog:@"Now running again"];
                [self setSentryType:ePrimary];
                [self setNextState:eStarting stepTime:.1];
            }
            else [self setNextState:eCheckRun stepTime:.2];
            break;
  
        case eBootCrates:
            if(triedBooting){
                [self appendToSentryLog:@"**Takeover failed after one reboot"];
                [self postRunProblemAlarm:@"Sentry unable to start run"];
                [self setSentryType:eNeither];
                [self setNextState:eStarting stepTime:2];
                [self step];
            }
            else {
                sbcRebootCount++;
                triedBooting = YES;
                for(id anSBC in sbcs)[[anSBC sbcLink] shutDown:sbcRootPwd reboot:YES];
                [self setNextState:eWaitForBoot stepTime:.1];
                loopTime = 0;
            }
            break;

            
        case eWaitForBoot:
            stepTime = 5;
            if(loopTime >= 45){
                [self appendToSentryLog:@"Wait for reboot over. Will try to start run again."];
                [self setNextState:eStarting stepTime:.1];
            }
           break;
        
            
        case eStopping:
            [self setSentryType:eNeither];
            [self setNextState:eStarting stepTime:.1];
            [self finish];
            break;

        default: break;
    }
}

- (void) finish
{
    toggleAction = false;
    [self connectSocket:NO];
    [self setRemoteMachineReachable:eUnknown];
    [self setRemoteORCARunning:eUnknown];
    [self setRemoteRunInProgress:eUnknown];
    [self clearMacPingAlarm];
    [self clearConnectionAlarm];
    [self clearOrcaHungAlarm];
    [self clearRunProblemAlarm];
    [self setSentryIsRunning:NO];
    [self setSentryType:eNeither];
    [self setNextState:eIdle stepTime:.2];
}

- (void) takeOverRunning:(BOOL)quiet
{
    if(!quiet)NSLogColor([NSColor redColor],@"Something is wrong. Trying to restart everything.\n");
    triedBooting = NO;
    [self setSentryType:eTakeOver];
    [self setNextState:eStarting stepTime:.2];
    [self step];
}

- (void) takeOverRunning
{
    //take over. don't be quiet about it.
    [self takeOverRunning:NO];
}

- (void) handleSbcSocketDropped
{
    //try to restart
    if(![self runIsInProgress]){ //Added to prevent killing the crates if the other computer is running
        sbcSocketDropCount++;
        [self appendToSentryLog:@"TakeOver due to socket dropped."];
        [self takeOverRunning:YES];
    }
}

- (void) appendToSentryLog:(NSString*)aString
{
    if([aString hasPrefix:@"**"])   NSLogColor([NSColor redColor],@"SENTRY - %@\n",aString); //SV - added sentry prefix
    else                            NSLog(@"SENTRY - %@\n",aString); //SV - added sentry prefix
    if(!sentryLog)sentryLog = [[NSMutableArray array] retain];
    
    NSDate* now = [NSDate date];
    NSString* stringWithDate = [NSString stringWithFormat:@"%@ %@",[now stdDescription],aString];

    if(aString)[sentryLog addObject:stringWithDate];
}

- (void) flushSentryLog
{
    [sentryLog release];
    sentryLog = nil;
}

#pragma mark •••Helpers
- (void) clearStats
{
    sbcSocketDropCount   = 0;
    sbcPingFailedCount   = 0;
    restartCount         = 0;
    macPingFailedCount   = 0;
    sbcRebootCount       = 0;
    missedHeartbeatCount = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryStateChanged object:self];
}

- (void) ping
{
    if(!pingTask){
        if(otherSystemStealthMode){
            [self setRemoteMachineReachable:eYES];
        }
        else {
            pingTask = [[ORPingTask pingTaskWithDelegate:self] retain];
            
            pingTask.launchPath= @"/sbin/ping";
            pingTask.arguments = [NSArray arrayWithObjects:@"-c",@"1",@"-t",@"10",@"-q",otherSystemIP,nil];
            
            pingTask.verbose = NO;
            pingTask.textToDelegate = YES;
            [pingTask ping];
        }
    }
}


- (BOOL) pingTaskRunning
{
	return pingTask != nil;
}

- (void) taskFinished:(ORPingTask*)aTask
{
    if(aTask == pingTask){
        [pingTask release];
        pingTask = nil;
    }
}
- (void) taskData:(NSDictionary*)taskData
{
    id       aTask = [taskData objectForKey:@"Task"];
    NSString* text = [taskData objectForKey:@"Text"];
    if(aTask != pingTask) return;

    if([text rangeOfString:@"100.0% packet loss"].location != NSNotFound){
        if(otherSystemStealthMode) [self setRemoteMachineReachable:eYES];
        else                       [self setRemoteMachineReachable:eBad];
    }
    else {
        [self setRemoteMachineReachable:eYES];
    }
}

- (void) connectSocket:(BOOL)aFlag
{
    if(aFlag){
        [self setSocket:[NetSocket netsocketConnectedToHost:otherSystemIP port:kRemotePort]];
    }
    else {
        [socket close];
        [self setIsConnected:[socket isConnected]];
    }
}

- (void) parseString:(NSString*)inString
{
    //handle returns from the other system
    //If a connection is open, a heartbeat should arrive every 30 seconds
    //the run state of the remote machine should arrive whenever it changes
    NSArray* lines= [inString componentsSeparatedByString:@"\n"];
    int n = (int)[lines count];
    int i;    
    for(i=0;i<n;i++){
        NSString* aLine = [lines objectAtIndex:i];
        NSRange firstColonRange = [aLine rangeOfString:@":"];
        if(firstColonRange.location != NSNotFound){
            NSString* key = [aLine substringToIndex:firstColonRange.location];
            id value      = [aLine substringFromIndex:firstColonRange.location+1];
            int32_t ival = (int32_t)[value doubleValue];
            if([key isEqualToString:@"runStatus"] || [key isEqualToString:@"runningState"]){
                if(ival==eRunStopped)   [self setRemoteRunInProgress:eNO];
                else                    [self setRemoteRunInProgress:eYES];
            }
            else if([key isEqualToString:@"remoteSentryRunning"]){
                if(ival == NO)  [self postNoRemoteSentryAlarm];
                else            [self clearNoRemoteSentryAlarm];
            }
        }
        else {
            if([aLine hasPrefix:@"OrcaHeartBeat"]){
                [self startHeartbeatTimeout];
            }
         }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryRemoteStateChanged object:self];

}

- (void) removeFromReadoutList:(NSArray*)someObjects
{
    if([someObjects count]){
        [[self undoManager] disableUndoRegistration];

        NSArray* dataTasks = [[(ORAppDelegate*)[NSApp delegate]document] collectObjectsOfClass:NSClassFromString(@"ORDataTaskModel")];
        for(ORDataTaskModel* aDataTask in dataTasks){
            for(id anObj in someObjects){
                [aDataTask removeOrcaObject:anObj];
            }
        }
        [self postListModAlarm];
        sbcSocketDropCount = 0;
        [[self undoManager] enableUndoRegistration];
    }
}

#pragma mark ***Delegate Methods
//SV
- (void) netsocketConnected:(id)aSocket
{
    [self performSelector:@selector(socketReallyConnected:) withObject:aSocket afterDelay:1];
}

//SV - used to be in netSocketConnected without perfomSelector and [socket isConnected] in if statement.
//But alarm kept reposting, it's because a new socket is opened at every check and initializes as connected.
- (void) socketReallyConnected:(id) aSocket
{
    if(aSocket == socket && [socket isConnected]){
        [self setIsConnected:[socket isConnected]];
        [self clearConnectionAlarm];
        [self setRemoteORCARunning:eYES];
        [self startHeartbeatTimeout];
    }
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
        [self setIsConnected:NO];
        [self setRemoteORCARunning:eBad];
        //if(![socket isConnected]){
        [self postConnectionAlarm];
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

- (void) sendCmd:(NSString*)aCmd
{
    if([self isConnected]){
        [socket writeString:aCmd encoding:NSASCIIStringEncoding];
    }
}

- (void) updateRemoteMachine
{
    //[self sendCmd:[NSString stringWithFormat:@"[RunControl setRunNumber:%u];",[runControl runNumber]]];
    //[self sendCmd:[NSString stringWithFormat:@"[RunControl setSubRunNumber:%d];",[runControl subRunNumber]]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setRepeatRun:%d];",[runControl repeatRun]]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setTimedRun:%d];",[runControl timedRun]]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setTimeLimit:%f];",[runControl timeLimit]]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setQuickStart:%d];",[runControl quickStart]]];
    [self sendCmd:[NSString stringWithFormat:@"[RunControl setOfflineRun:%d];",[runControl offlineRun]]];
    [self sendCmd:@"runStatus = [RunControl runningState];"];
    [self updateRemoteShapers];
}

- (void) updateRemoteShapers
{
    for(id aShaper in shapers){
        int i;
        for(i=0;i<8;i++){
            [self sendCmd:[NSString stringWithFormat:@"[%@ setThreshold:%d withValue:%d];",[aShaper fullID],i,[aShaper threshold:i]]];
            [self sendCmd:[NSString stringWithFormat:@"[%@ setGain:%d withValue:%d];",[aShaper fullID],i,[aShaper gain:i]]];

        }
    }
}

- (void) startHeartbeatTimeout
{
    [self clearOrcaHungAlarm];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(missedHeartBeat) object:nil];
    [self performSelector:@selector(missedHeartBeat) withObject:nil afterDelay:40];
    missedHeartbeatCount = 0;
}

- (void) cancelHeartbeatTimeout
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(missedHeartBeat) object:nil];
}

- (void) missedHeartBeat
{
    missedHeartbeatCount++;
    if(missedHeartbeatCount>=kMaxHungCount){
        [self postOrcaHungAlarm];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(missedHeartBeat) object:nil];
    [self performSelector:@selector(missedHeartBeat) withObject:nil afterDelay:40];
    [[NSNotificationCenter defaultCenter] postNotificationName:HaloSentryMissedHeartbeat object:self];

}

- (short) missedHeartBeatCount
{
    return missedHeartbeatCount;
}
- (BOOL) systemIsHeathy
{
    if(!macPingFailedAlarm &&
       !sbcPingFailedAlarm &&
       !noConnectionAlarm &&
       !orcaHungAlarm &&
       !noRemoteSentryAlarm) {
        return YES;
    }
    else {
        return NO;
    }
}

- (void) toggleSystems
{
    [self flushSentryLog];
    if([self systemIsHeathy]){
        [self setSentryType:eHealthyToggle];
        [self setNextState:eStarting stepTime:.1];
        [self step];
    }
    else {
        [self takeOverRunning];
    }
}

- (NSString*) diskStatus
{
    NSString* s = @"";
    NSArray* disks = [[(ORAppDelegate*)[NSApp delegate]document] collectObjectsOfClass:NSClassFromString(@"ORDataFileModel")];
    for(ORDataFileModel* aDisk in disks){
        if([aDisk involvedInCurrentRun]){
            [aDisk checkDiskStatus];
            s = [s stringByAppendingFormat:@"Disk: %@ = %.2f%%\n",[aDisk fullID],[aDisk convertedValue:0]];
        }
    }
    return s;
}

- (NSString*) report
{
    NSString* theReport = @"";
    theReport = [theReport stringByAppendingFormat:@"Reporting machine: %@\n",thisSystemIP];
    theReport = [theReport stringByAppendingString:@"----------------------------------------------\n"];
    theReport = [theReport stringByAppendingFormat:@"Sentry running: %@\n",[self sentryIsRunning]?@"YES":@"NO"];
    theReport = [theReport stringByAppendingFormat:@"Sentry type   : %@\n",[self sentryTypeName]];
    if(sentryType == ePrimary){
        if([runControl subRunNumber]==0) theReport = [theReport stringByAppendingFormat:@"Run Number: %d\n",[runControl runNumber]];
        else                             theReport = [theReport stringByAppendingFormat:@"Run Number: %d.%d\n",[runControl runNumber],[runControl subRunNumber]];
        theReport = [theReport stringByAppendingFormat:@"Elapsed time: %@\n",[runControl elapsedRunTimeString]];
        theReport = [theReport stringByAppendingString:[self diskStatus]];
        theReport = [theReport stringByAppendingString:@"Designated as the Primary machine\n"];
        theReport = [theReport stringByAppendingString:@"Status of the Secondary machine:\n"];
        theReport = [theReport stringByAppendingFormat:@"Computer: %@\n",[self remoteMachineStatusString]];
        theReport = [theReport stringByAppendingFormat:@"ORCA: %@\n",[self connectionStatusString]];
    }
    else if(sentryType == eSecondary){
        theReport = [theReport stringByAppendingString:@"Designated as the Secondary machine\n"];
        if([self systemIsHeathy]){
            theReport = [theReport stringByAppendingString:@"Status of the Primary machine:\n"];
            theReport = [theReport stringByAppendingFormat:@"Computer: %@\n",[self remoteMachineStatusString]];
            theReport = [theReport stringByAppendingFormat:@"ORCA: %@\n",[self connectionStatusString]];
            theReport = [theReport stringByAppendingFormat:@"Running: %@\n",[self remoteORCArunStateString]];
        }
    }
    else if(sentryType == eNeither){
        theReport = [theReport stringByAppendingString:@"No run is in progress\n"];
    }
    else {
        theReport = [theReport stringByAppendingString:@"Sentry state is one that would indicate a problem is being addressed right now.\n"];
        if([sentryLog count]!=0){
            theReport = [theReport stringByAppendingString:@"Attached sentry log will be incomplete\n"];
        }
   }

    if([sentryLog count]==0){
        theReport = [theReport stringByAppendingString:@"----------------------------------------------\n"];
        theReport = [theReport stringByAppendingString:@"Only normal sentry activity since last report.\n"];
        theReport = [theReport stringByAppendingString:@"----------------------------------------------\n"];
    }
    else {
        theReport = [theReport stringByAppendingString:@"----------------------------------------------\n"];
        theReport = [theReport stringByAppendingFormat:@"Run restart attempts: %d\n",           restartCount];
        theReport = [theReport stringByAppendingFormat:@"SBC dropped socket connections: %d\n", sbcSocketDropCount];
        theReport = [theReport stringByAppendingFormat:@"SBC failed pings: %d\n",               sbcPingFailedCount];
        theReport = [theReport stringByAppendingFormat:@"SBC reboot attempts: %d\n",            sbcRebootCount];
        theReport = [theReport stringByAppendingFormat:@"MAC missed heartbeats: %d\n",          missedHeartbeatCount];
        theReport = [theReport stringByAppendingFormat:@"MAC failed pings: %d\n",               macPingFailedCount];
        theReport = [theReport stringByAppendingString:@"----------------------------------------------\n"];
        theReport = [theReport stringByAppendingString:@"Sentry log:\n\n"];
        for(id aLine in sentryLog)theReport = [theReport stringByAppendingFormat:@"%@\n",aLine];
        theReport = [theReport stringByAppendingString:@"----------------------------------------------\n"];
        [self clearStats];
        [self flushSentryLog];
    }
    
    return theReport;
}

@end
