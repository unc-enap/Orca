//
//  ORLevelMonitor.h
//  Orca
//
//  Created by Mark Howe on Sat Sept 2007.
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

@interface ORLevelMonitor : NSView {
	IBOutlet id dataSource;
	NSImage*	lowLevelBugImage;
	NSImage*	hiLevelBugImage;
	NSImage*	lowFillPointBugImage;
	NSImage*	hiFillPointBugImage;
	BOOL		movingLowAlarm;
	BOOL		movingHiAlarm;
	BOOL		movingLowFillPoint;
	BOOL		movingHiFillPoint;
	NSColor* 	tankColor;
	NSColor* 	contentsColor;
	NSGradient*	levelGradient;
	NSGradient* tankGradient;
	BOOL		showFillPoints;
}

- (id)initWithFrame:(NSRect)frame;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ¥¥¥Accessors
- (void) setShowFillPoints:(BOOL)aState;
- (void) setTankColor:(NSColor*)aColor;
- (NSColor*) tankColor;
- (void) setContentsColor:(NSColor*)aColor;
- (NSColor*) contentsColor;
- (NSUndoManager*) undoManager;

#pragma mark ¥¥¥Events
- (void) mouseDown:(NSEvent*)event;
- (void) mouseDragged:(NSEvent*)event;
- (void) mouseUp:(NSEvent*)event;
- (BOOL)mouseDownCanMoveWindow;

#pragma mark ¥¥¥Drawing
- (void) drawRect:(NSRect)rect ;

#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;
@end

@interface NSObject (ORLevelMonitor_DataSource)
- (void) setLevelMonitor:(ORLevelMonitor*)aMonitor lowAlarm:(float)aValue;
- (void) setLevelMonitor:(ORLevelMonitor*)aMonitor hiAlarm:(float)aValue;
- (float) levelMonitorHiAlarmLevel:(id)aLevelMonitor;
- (float) levelMonitorLowAlarmLevel:(id)aLevelMonitor;
- (float) levelMonitorLevel:(id)aLevelMonitor;
- (void) loadAlarmsToHardware;
- (void) setLevelMonitor:(ORLevelMonitor*)aMonitor lowFillPoint:(float)aValue;
- (void) setLevelMonitor:(ORLevelMonitor*)aMonitor hiFillPoint:(float)aValue;
- (float) levelMonitorHiFillPoint:(id)aLevelMonitor;
- (float) levelMonitorLowFillPoint:(id)aLevelMonitor;

@end
