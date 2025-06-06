//
//  ORDistributedRunModel.h
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
#import "OrcaObject.h"

#pragma mark ¥¥¥Forward Declarations
@class ORRemoteRunItem;

@interface ORDistributedRunModel :  OrcaObject {
    @private
        NSDate*         startTime;
		NSTimeInterval  elapsedTime;
        NSTimeInterval  timeToGo;
        NSTimeInterval  timeLimit;
        NSTimeInterval  timeHalted;
        BOOL            timedRun;
        BOOL            repeatRun;
        BOOL            quickStart;
        int             runningState;
        NSTimer*        timer;

        NSMutableArray* remoteRunItems;
        NSInteger       numberConnected;
        NSInteger       numberRunning;
        uint32_t        runNumber;
        NSString*       dirName;
        NSString*       definitionsFilePath;
}

#pragma mark ¥¥¥Accessors
- (NSMutableArray*) remoteRunItems;
- (void)        setRemoteRunItems:(NSMutableArray*)anItem;
- (NSString*)   elapsedRunTimeString;
- (NSString*)   elapsedTimeString:(NSTimeInterval) aTimeInterval;
- (NSDate*)     startTime;
- (void)	    setStartTime:(NSDate*) aDate;
- (NSTimeInterval)  elapsedTime;
- (void)	    setElapsedTime:(NSTimeInterval) aValue;
- (NSTimeInterval)  timeToGo;
- (void)	    setTimeToGo:(NSTimeInterval) aValue;
- (BOOL)	    timedRun;
- (void)	    setTimedRun:(BOOL) aValue;
- (BOOL)	    repeatRun;
- (void)	    setRepeatRun:(BOOL) aValue;
- (NSTimeInterval) timeLimit;
- (void)	    setTimeLimit:(NSTimeInterval) aValue;
- (NSString*)   commandID;
- (int)		    runningState;
- (void)	    setRunningState:(int)aRunningState;
- (BOOL)	    quickStart;
- (void)	    setQuickStart:(BOOL)flag;
- (void)        scanAndUpdate;
- (void)        incrementTime:(NSTimer*)aTimer;
- (void)        setElapsedRunTime:(NSTimeInterval)aValue;

- (NSMutableArray*) remoteRunItems;
- (void) setRemoteRunItems:(NSMutableArray*)anItem;
- (void) addRemoteRunItem:(ORRemoteRunItem*)anItem afterItem:(ORRemoteRunItem*)anotherItem;
- (void) removeRemoteRunItem:(ORRemoteRunItem*)anItem;
- (void) addRemoteRunItem;
- (void) ensureMinimumNumberOfRemoteItems;
- (void) connectAll;
- (void) disConnectAll;

#pragma mark ¥¥¥Remote Run Stuff
- (void) startRun;
- (void) haltRun;
- (void) stopRun;

- (void)      fullUpdate;
- (void)      sendSetup;
- (NSInteger) numberRemoteSystems;
- (NSInteger) numberConnected;
- (void)      setNumberConnected:(NSInteger)aValue;;
- (NSInteger) numberRunning;
- (void)      setNumberRunning:(NSInteger)aValue;;
- (NSInteger) numberRemoteSystems;
- (uint32_t)   runNumber;
- (void)       setRunNumber:(uint32_t)aRunNumber;
- (void) setDirName:(NSString*)aDirName;
- (NSString*)dirName;
- (NSString *)definitionsFilePath;
- (void) setDefinitionsFilePath:(NSString *)aDefinitionsFilePath;

#pragma mark ¥¥¥Archival
- (void) encodeWithCoder:(NSCoder*)encoder;
- (id)   initWithCoder:(NSCoder*)decoder;
@end

extern NSString* ORDistributedRunTimedRunChanged;
extern NSString* ORDistributedRunRepeatRunChanged;
extern NSString* ORDistributedRunTimeLimitChanged;
extern NSString* ORDistributedRunStartTimeChanged;
extern NSString* ORDistributedRunTimeToGoChanged;
extern NSString* ORDistributedRunQuickStartChanged;
extern NSString* ORDistributedRunStatusChanged;
extern NSString* ORDistributedRunNumberConnectedChanged;
extern NSString* ORDistributedRunNumberRunningChanged;
extern NSString* ORDistributedRunElapsedTimeChanged;
extern NSString* ORDistributedRunSystemListChanged;
extern NSString* ORRemoteRunItemAdded;
extern NSString* ORRemoteRunItemRemoved;
extern NSString* ORDistributedRunNumberLock;
extern NSString* ORDistributedRunNumberChanged;
extern NSString* ORDistributedRunNumberDirChanged;
