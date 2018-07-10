//
//  ORTaskMaster.h
//  Orca
//
//  Created by Mark Howe on Thu Nov 06 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Forward Declarations
@class ORTask;

#pragma mark ¥¥¥Definitions

@interface ORTaskMaster : NSWindowController
{
    @private
    IBOutlet NSView* taskContentView;
	NSMutableArray*	 runningTasks;
}

+ (ORTaskMaster*) sharedTaskMaster;

- (void) registerNotificationObservers;
- (void) documentClosed:(NSNotification*)aNote;
- (void) taskStarted:(NSNotification*)aNote;
- (void) taskStopped:(NSNotification*)aNote;
- (void) postRunningTaskList;

#pragma mark ¥¥¥Accessors
- (NSView*) taskContentView;

- (void)addTask:(ORTask*)aTask;
- (void) removeTask:(ORTask*)aTask;

#pragma mark ¥¥¥Delegate Methods

#pragma mark ¥¥¥Update Methods
- (void) tileTaskViews;

@end
