//
//  ORProcessThread.h
//  Orca
//
//  Created by Mark Howe on 11/23/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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




@class ORProcessEndNode;
@class ProcessElementSet;

@interface ORProcessThread : NSObject {
    NSMutableSet*    endNodes;
    BOOL             running;
    BOOL             canceled;
    NSArray*         allProcessElements;
    NSArray*         allEndNodes;
    NSArray*         allProcesses;
    ProcessElementSet*  inputs;
    ProcessElementSet*  outputs;
	id    crBits[256];
}

#pragma mark ¥¥¥Inialization
+ (ORProcessThread*) sharedProcessThread;
+ (void) registerInputObject:(id)anObject;
+ (void) registerOutputObject:(id)anObject;
+ (void) setCR:(int)aBit value:(id)aValue;
+ (id) getCR:(int)aBit;
+ (BOOL) isRunning;

- (id) init;
- (void) dealloc;
- (void) registerNotificationObservers;
- (void) documentIsClosing:(NSNotification*)aNote;
- (void) orcaIsQuitting:(NSNotification*)aNote;

#pragma mark ¥¥¥Accessors
- (BOOL) isRunning;
- (void) startNodes:(NSArray*) someNodes;
- (void) startNode:(ORProcessEndNode*) aNode;
- (void) stopNode:(ORProcessEndNode*) aNode;
- (void) stopNodes:(NSArray*) someNodes;
- (BOOL) nodesRunning:(NSArray*)someNodes;
- (void) registerInputObject:(id)anObject;
- (void) registerOutputObject:(id)anObject;
- (void) setCR:(int)aBit value:(id)aValue;
- (id) getCR:(int)aBit;

#pragma mark ¥¥¥Thread
- (void) start;
- (void) stop;
- (void) markAsCanceled;
- (BOOL) cancelled;
- (void) processThread;

@end

@interface ProcessElementSet : NSObject
{
	NSMutableArray* processElements;
}
- (void) addObject:(id)anObject;
- (void) startProcessCycle;
- (void) endProcessCycle;
@end


@interface ProcessElementInfo : NSObject
{
	id hwObject;
	NSMutableArray* processes;
}
- (void) setHWObject:(id)anObject;
- (id) hwObject;
- (void) addProcess:(id)aProcess;
- (void) startProcessCycle;
- (void) endProcessCycle;

@end

