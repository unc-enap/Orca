//
//  ORRemoteRunModel.h
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

#import "ORDataChainObject.h"

#pragma mark ¥¥¥Forward Declarations
@class NetSocket;

@interface ORRemoteRunModel :  ORDataChainObject {
    @private
        unsigned long 	runNumber;
		int subRunNumber;

        NSString* startTime;

		NSTimeInterval  elapsedSubRunTime;
		NSTimeInterval	elapsedBetweenSubRunTime;
		NSTimeInterval  elapsedTime;
        NSTimeInterval  timeToGo;
        NSTimeInterval  timeLimit;
        BOOL            timedRun;
        BOOL            repeatRun;
        BOOL            quickStart;

        int         runningState;
        NSString*   remoteHost;
        unsigned long remotePort;
        NetSocket*  socket;
        BOOL        connectAtStart;
        BOOL        autoReconnect;
        BOOL        isConnected;
		NSTimeInterval timeHalted;
		BOOL		offline;
		NSArray*	scriptNames;
		NSString*	selectedStartScriptName;
		NSString*	selectedShutDownScriptName;
	
}


#pragma mark ¥¥¥Initialization

#pragma mark ¥¥¥Accessors
- (NSString*) elapsedRunTimeString;
- (NSString*) elapsedTimeString:(NSTimeInterval) aTimeInterval;
- (int) subRunNumber;
- (void) setSubRunNumber:(int)aSubRunNumber;
- (NSArray*) scriptNames;
- (void) setScriptNames:(NSArray*)someNames;
- (NSString*) selectedStartScriptName;
- (NSString*) selectedShutDownScriptName;
- (void) setSelectedStartScriptName:(NSString*)aName;
- (void) setSelectedShutDownScriptName:(NSString*)aName;
- (NSString*) shortStatus;
- (BOOL) offline;
- (void) setOffline:(BOOL)aOffline;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aIsConnected;
- (BOOL) autoReconnect;
- (void) setAutoReconnect:(BOOL)aAutoReconnect;
- (BOOL) connectAtStart;
- (void) setConnectAtStart:(BOOL)aConnectAtStart;
- (NetSocket*) socket;
- (void) setSocket:(NetSocket*)aSocket;
- (unsigned long) remotePort;
- (void) setRemotePort:(unsigned long)aRemotePort;
- (NSString*) remoteHost;
- (void) setRemoteHost:(NSString*)aRemoteHost;
- (unsigned long)   runNumber;
- (void)	    setRunNumber:(unsigned long)aRunNumber;
- (NSString*) startTime;
- (void)	setStartTime:(NSString*) aDate;
- (NSTimeInterval)  elapsedTime;
- (void)	setElapsedTime:(NSTimeInterval) aValue;
- (NSTimeInterval)  timeToGo;
- (void)	setTimeToGo:(NSTimeInterval) aValue;
- (BOOL)	timedRun;
- (void)	setTimedRun:(BOOL) aValue;
- (BOOL)	repeatRun;
- (void)	setRepeatRun:(BOOL) aValue;
- (NSTimeInterval)timeLimit;
- (void)	setTimeLimit:(NSTimeInterval) aValue;
- (NSString*)   commandID;
- (int)		runningState;
- (void)    setRunStatus:(int)aRunningState;
- (void)	setRunningState:(int)aRunningState;
- (BOOL)	quickStart;
- (void)	setQuickStart:(BOOL)flag;
- (void)    setPostAlarm:(id)anAlarm;
- (void)    setClearAlarm:(id)anAlarm;
- (void)	startNewSubRun;
- (void)	prepareForNewSubRun;
- (NSTimeInterval)  elapsedSubRunTime;
- (void)			setElapsedSubRunTime:(NSTimeInterval) aValue;
- (NSTimeInterval)  elapsedBetweenSubRunTime;
- (void)			setElapsedBetweenSubRunTime:(NSTimeInterval) aValue;
- (NSString*) fullRunNumberString;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) documentLoaded:(NSNotification*)aNotification;


#pragma mark ¥¥¥Run Modifiers
- (void) startRun:(BOOL)doInit;
- (void) startRun;
- (void) restartRun;
- (void) haltRun;
- (void) stopRun;

- (void) runStarted:(BOOL)doInit;
- (void) incrementTime;
- (void) parseString:(NSString*)inString;
- (int) processScripts:(NSArray*)lines index:(int)i;

- (void) fullUpdate;
- (void) sendSetup;
- (void) sendCmd:(NSString*)aCmd;

- (void) encodeWithCoder:(NSCoder*)encoder;
- (id)   initWithCoder:(NSCoder*)decoder;

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(id)aSocket;
- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount;
- (void) netsocketDisconnected:(NetSocket*)inNetSocket;

- (void) connectSocket:(BOOL)state;

@end



extern NSString* ORRemoteRunModelScriptNamesChanged;
extern NSString* ORRemoteRunModelOfflineChanged;
extern NSString* ORRemoteRunTimedRunChanged;
extern NSString* ORRemoteRunRepeatRunChanged;
extern NSString* ORRemoteRunTimeLimitChanged;
extern NSString* ORRemoteRunElapsedTimeChanged;
extern NSString* ORRemoteRunStartTimeChanged;
extern NSString* ORRemoteRunTimeToGoChanged;
extern NSString* ORRemoteRunNumberChanged;
extern NSString* ORRemoteRunQuickStartChanged;
extern NSString* ORRemoteRunRemoteHostChanged;
extern NSString* ORRemoteRunRemotePortChanged;
extern NSString* ORRemoteRunStatusChanged;
extern NSString* ORRemoteRunConnectAtStartChanged;
extern NSString* ORRemoteRunAutoReconnectChanged;
extern NSString* ORRemoteRunIsConnectedChanged;
extern NSString* ORRemoteRunStartScriptNameChanged;
extern NSString* ORRemoteRunShutDownScriptNameChanged;

extern NSString* ORRemoteRunLock;
