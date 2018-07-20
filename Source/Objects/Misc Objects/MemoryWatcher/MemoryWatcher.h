//-------------------------------------------------------------------------
//  MemoryWatcher.h
//
//  Created by Mark Howe on Friday 05/13/2005.
//  Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files


@class ORTimeRate;
#define kNumWatchedValues 3

@interface MemoryWatcher : NSObject
{
  @private
	ORTimeRate*	timeRate[kNumWatchedValues];
	
    NSTimeInterval       taskInterval;
    NSDate*              launchTime;
    NSTimeInterval       upTime;
    NSOperationQueue*    opQueue;
    uint32_t        totalMemory;
    uint32_t        freeMemory;
    uint32_t        pageSize;
    uint32_t        orcaMemory;
}

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;

#pragma mark ***Accessors
- (NSTimeInterval) accurateUptime;
- (NSTimeInterval) upTime;
- (void) setUpTime:(NSTimeInterval)aUpTime;
- (NSDate*) launchTime;
- (void) setLaunchTime:(NSDate*)aLaunchTime;
- (NSTimeInterval) taskInterval;
- (void) setTaskInterval:(NSTimeInterval)aTaskInterval;
- (float) convertValue:(float)aValue withMultiplier:(NSString*)aMultiplier;
- (NSUInteger) timeRateCount:(int)rateIndex;
- (float) timeRate:(int)rateIndex value:(int)valueIndex;
- (void) setUpQueue;

- (void) launchTask;
- (void) processTopResult:(NSString*)taskResult;
- (void) processVmStatResult:(NSString*)taskResult;

- (void) postUpdate;
- (void) postCouchDBRecord;
- (NSString*) fullID; //so couchdb posting works

@end

extern NSString* MemoryWatcherUpTimeChanged;
extern NSString* MemoryWatcherChangedNotification;
extern NSString* MemoryWatcherTaskIntervalNotification;
//--------------------------------------------------
// ORTopShellOp
// An easier way to use top by just executing shell
// scripts and having the result go back to the delegate
//--------------------------------------------------
@interface ORTopShellOp : NSOperation
{
    id          delegate;
    int         tag;
}
- (id) initWithDelegate:(id)aDelegate;
- (void) main;
- (void) runTop;
- (void) runVmStat;

@end

