//
//  MemoryWatcherController.h
//  Orca
//
//  Created by Mark Howe on 5/13/05.
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



@class MemoryWatcher;
@class ORCompositePlotView;
@class ORAxis;

@interface MemoryWatcherController : NSWindowController {
    MemoryWatcher* watcher;
    IBOutlet ORCompositePlotView* plotView;
    IBOutlet NSTextField* upTimeField;
}

+ (MemoryWatcherController*) sharedMemoryWatcherController;
- (void) registerNotificationObservers;
- (void) memoryStatsChanged:(NSNotification*)aNote;
- (void) upTimeChanged:(NSNotification*)aNote;
- (void) taskIntervalChanged:(NSNotification*)aNote;

#pragma mark ***Accessors
- (void) setMemoryWatcher:(MemoryWatcher*)aWatcher;
- (int)	 numberPointsInPlot:(id)aPlot;
- (void) plotter:(id)aPlot index:(int)i x:(double*)xValue y:(double*)yValue;

@end
