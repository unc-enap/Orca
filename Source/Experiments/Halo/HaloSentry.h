//-------------------------------------------------------------------------
//  HaloSentry.h
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

@class NetSocket;
@class ORRunModel;
@class ORPingTask;

static enum  eHaloSentryState {
    eIdle,
    eStarting,
    eStopping,
    eCheckRemoteMachine,
    eConnectToRemoteOrca,
    eGetRunState,
    eCheckRunState,
    eWaitForPing,
    eGetSecondaryState,
    eWaitForLocalRunStop,
    eWaitForRemoteRunStop,
    eWaitForLocalRunStart,
    eWaitForRemoteRunStart,
    eKillCrates,
    eKillCrateWait,
    eStartCrates,
    eStartCrateWait,
    eStartRun,
    eCheckRun,
    eBootCrates,
    eWaitForBoot,
    ePingCrates,
} eHaloSentryState;

static enum eHaloSentryType {
    eNeither,
    ePrimary,
    eSecondary,
    eHealthyToggle,
    eTakeOver,
}eHaloSentryType;


static enum eHaloStatus {
    eOK             = 0,
    eYES            = 0,
    eRunning        = 0,
    eBad            = 1,
    eNO             = 1,
    eBeingChecked   = 2,
    eUnknown        = 3
} eHaloStatus;

#define kMaxHungCount 2

@interface HaloSentry : NSObject
{
  @private
    enum eHaloSentryType sentryType;
    enum eHaloSentryState state;
    enum eHaloSentryState nextState;
    NSTimeInterval stepTime;    
    BOOL    sentryIsRunning;
    short   missedHeartbeatCount;
    BOOL    wasRunning;
    float   loopTime;
    NSString*   ipNumber1;
    NSString*   ipNumber2;;
    NSString*   otherSystemIP;
    NSString*   thisSystemIP;
    BOOL        stealthMode1;
    BOOL        stealthMode2;
    BOOL        otherSystemStealthMode;
    BOOL        ignoreRunStates;
    BOOL        triedBooting;
    BOOL        wasLocalRun;
    
	ORPingTask*     pingTask;
    NetSocket*  socket;
    BOOL        isConnected;
    int         sbcSocketDropCount;
    int         restartCount;
    int         sbcPingFailedCount;
    int         macPingFailedCount;
    int         sbcRebootCount;
    
    enum eHaloStatus remoteMachineReachable;
    enum eHaloStatus remoteORCARunning;
    enum eHaloStatus remoteRunInProgress;
    
    ORAlarm* macPingFailedAlarm;
    ORAlarm* noConnectionAlarm;
    ORAlarm* orcaHungAlarm;
    ORAlarm* noRemoteSentryAlarm;
    ORAlarm* runProblemAlarm;
    ORAlarm* listModAlarm;
    ORAlarm* sbcPingFailedAlarm;
    
    ORRunModel* runControl;
    NSArray* sbcs;
    NSArray* shapers;
    NSString* sbcRootPwd;
    NSMutableArray* unPingableSBCs;
    NSMutableArray* sentryLog;
    
    NSTimer* toggleTimer; //SV
    int toggleInterval; //SV
    BOOL scheduledToggleTime; //SV
    BOOL toggleAction; //SV
    NSString* nextToggleTime; //SV
}

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;
- (void) sleep;
- (void) wakeUp;
- (NSUndoManager*) undoManager;
- (void) awakeAfterDocumentLoaded;
- (void) registerNotificationObservers;

#pragma mark ***Notifications
- (void) objectsChanged:(NSNotification*)aNote;
- (void) runStarted:(NSNotification*)aNote;
- (void) runStopped:(NSNotification*)aNote;
- (void) sbcSocketDropped:(NSNotification*)aNote;

#pragma mark •••Accessors
- (void) setOtherIP;
- (enum eHaloStatus) remoteMachineReachable;
- (void) setRemoteMachineReachable:(enum eHaloStatus)aState;
- (enum eHaloStatus) remoteORCARunning;
- (void) setRemoteORCARunning:(enum eHaloStatus)aState;
- (enum eHaloStatus) remoteRunInProgress;
- (void) setRemoteRunInProgress:(enum eHaloStatus)aState;
- (BOOL) stealthMode2;
- (void) setStealthMode2:(BOOL)aStealthMode2;
- (BOOL) stealthMode1;
- (void) setStealthMode1:(BOOL)aStealthMode1;
- (BOOL) otherSystemStealthMode;
- (BOOL) sentryIsRunning;
- (void) setSentryIsRunning:(BOOL)aState;
- (BOOL) isConnected;
- (NSString*)sbcRootPwd;
- (void) setSbcRootPwd:(NSString*)aString;
- (int)  sbcSocketDropCount;
- (int)  restartCount;
- (int)  sbcPingFailedCount;
- (int)  macPingFailedCount;
- (int)  sbcRebootCount;
- (NSString*) ipNumber2;
- (void) setIpNumber2:(NSString*)aIpNumber2;
- (NSString*) ipNumber1;
- (void) setIpNumber1:(NSString*)aIpNumber1;
- (enum eHaloSentryType) sentryType;
- (void) setSentryType:(enum eHaloSentryType)aType;
- (enum eHaloSentryState) state;
- (void) setNextState:(enum eHaloSentryState)aState stepTime:(NSTimeInterval)aTime;
- (void) takeOverRunning;
- (void) takeOverRunning:(BOOL)quiet;
- (void) handleSbcSocketDropped;
- (NSString*) sentryTypeName;
- (NSString*) stateName;
- (NSString*) report;
- (NSString*) diskStatus;

- (BOOL) toggleTimerIsRunning; //SV
- (int) toggleInterval; //SV
- (BOOL) scheduledToggleTime; //SV
- (void) doScheduledToggle; //SV
- (void) setToggleInterval:(int) seconds; //SV
- (void) startTimer; //SV
- (void) stopTimer; //SV
- (void) waitForEndOfRun:(NSTimer*)aTimer; //SV
- (void) setNextToggleTime:(NSString*)aString;//MAH
- (NSString*) nextToggleTime; //SV
- (NSMutableArray*) sentryLog; //SV

#pragma mark ***Run Stuff
- (void) start;
- (void) stop;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***Helpers
- (void) collectObjects;
- (void) ping;
- (BOOL) pingTaskRunning;
- (void) taskFinished:(ORPingTask*)aTask;
- (void) updateRemoteMachine;
- (void) toggleSystems;
- (void) startHeartbeatTimeout;
- (void) cancelHeartbeatTimeout;
- (void) missedHeartBeat;
- (short) missedHeartBeatCount;
- (NSString*) remoteMachineStatusString;
- (NSString*) connectionStatusString;
- (NSString*) remoteORCArunStateString;
- (BOOL) runIsInProgress;
- (void) appendToSentryLog:(NSString*)aString;
- (void) flushSentryLog;
- (void) clearStats;
- (void) updateRemoteShapers;
- (void) connectSocket:(BOOL)aFlag;
- (void) sendCmd:(NSString*)aCmd;
- (void) removeFromReadoutList:(NSArray*)someObjects;

#pragma mark ***Alarms
- (void) postMacPingAlarm;
- (void) clearMacPingAlarm;
- (void) postConnectionAlarm;
- (void) clearConnectionAlarm;
- (void) postOrcaHungAlarm;
- (void) clearOrcaHungAlarm;
- (void) postNoRemoteSentryAlarm;
- (void) clearNoRemoteSentryAlarm;
- (void) postRunProblemAlarm:(NSString*)aTitle;
- (void) clearRunProblemAlarm;
- (void) postListModAlarm;
- (void) clearListModAlarm;
- (void) postSBCPingAlarm:(id)anSBC;
- (void) clearSBCPingAlarm;

- (void) clearAllAlarms;

#pragma mark •••Finite State Machines
- (void) step;
- (void) stepSimpleWatch;
- (void) stepPrimarySystem;
- (void) stepSecondarySystem;
- (void) stepHealthyToggle;
- (void) stepTakeOver;
- (void) finish;

@end

extern NSString* HaloSentryStealthMode2Changed;
extern NSString* HaloSentryStealthMode1Changed;
extern NSString* HaloSentryIpNumber2Changed;
extern NSString* HaloSentryIpNumber1Changed;
extern NSString* HaloSentryIsPrimaryChanged;
extern NSString* HaloSentryIsRunningChanged;
extern NSString* HaloSentryStateChanged;
extern NSString* HaloSentryTypeChanged;
extern NSString* HaloSentryIsConnectedChanged;
extern NSString* HaloSentryRemoteStateChanged;
extern NSString* HaloSentryMissedHeartbeat;
extern NSString* HaloSentrySbcRootPwdChanged;
extern NSString* HaloSentryToggleIntervalChanged;
