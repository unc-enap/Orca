//
//  ORRunListModel.h
//  Orca
//
//  Created by Mark Howe on Tues Feb 09 2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
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

@class TimedWorker;
@class ORRunModel;
@class ORScriptIDEModel;



@interface ORRunListModel : OrcaObject  {
	NSMutableArray* items;
    NSMutableArray* orderArray;     //an array of indexes into the items array
	TimedWorker*    timedWorker;
	float           totalExpectedTime;
	float           accumulatedTime;
	ORRunModel*     runModel;
	BOOL            oldTimedRun;
	BOOL            oldRepeatRun;
	int             oldRepeatTime;
	int             runListState;
    int             nextState; //used by some states to dynamically set the next state
	float           runLength;
    float           runTimeElapsed;
    BOOL            randomize;
	NSString*       lastFile;
    int             timesToRepeat;
    int             executionCount;
    ORScriptIDEModel* scriptAtStartModel;
    ORScriptIDEModel* scriptAtEndModel;
    NSDate*         timeStarted;
    NSDate*         timeRunStarted;
    float           skippedTime;
}

- (void) registerNotificationObservers;
- (void)runHalted:(NSNotification*)aNote;

#pragma mark •••Accessors
- (int) executionCount;
- (int) timesToRepeat;
- (void) setTimesToRepeat:(int)aTimesToRepeat;
- (NSString*) lastFile;
- (void) setLastFile:(NSString*)aLastFile;
- (float) totalExpectedTime;
- (float) accumulatedTime;
- (BOOL) randomize;
- (void) setRandomize:(BOOL)aRandomize;
- (BOOL) isRunning;
- (BOOL) isPaused;
- (void) startRunning;
- (void) pauseRunning;
- (void) restartRunning;
- (void) stopRunning;
- (void) addItem;
- (void) removeItemAtIndex:(NSInteger) anIndex;
- (void) addItem:(id)anItem atIndex:(NSInteger)anIndex;
- (id) itemAtIndex:(NSInteger)anIndex;
- (uint32_t) itemCount;
- (TimedWorker*) timedWorker;
- (NSString*) runStateName;

#pragma mark •••Save/Restore
- (void) saveToFile:(NSString*)aPath;
- (void) restoreFromFile:(NSString*)aPath;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORRunListModelTimesToRepeatChanged;
extern NSString* ORRunListModelLastFileChanged;
extern NSString* ORRunListModelRandomizeChanged;
extern NSString* ORRunListModelWorkingItemIndexChanged;
extern NSString* ORRunListListLock;
extern NSString* ORRunListItemsAdded;
extern NSString* ORRunListItemsRemoved;
extern NSString* ORRunListRunStateChanged;
extern NSString* ORRunListModelReloadTable;


