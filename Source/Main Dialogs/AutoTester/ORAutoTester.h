//
//  ORAutoTester.mh
//  Orca
//
//  Created by Mark Howe on Sat Dec 28 2002.
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

@interface ORAutoTester : NSWindowController {
	IBOutlet NSOutlineView* totalListView;
	IBOutlet NSButton*	    runTestsButton;
	IBOutlet NSButton*	    stopTestsButton;
    IBOutlet NSButton*      lockButton;
    IBOutlet NSButton*      repeatCB;
    IBOutlet NSTextField*   repeatCountField;
	BOOL testsRunning;
	BOOL stopTesting;
	int repeatCount;
	BOOL repeat;
	NSMutableDictionary*	testResults;
	NSLock*		resultLock;
	
}

+ (ORAutoTester*) sharedAutoTester;

- (id)init;
- (void) awakeFromNib;
- (NSUndoManager*) windowWillReturnUndoManager:(NSWindow*)window;
- (void) setTestResult:(id)aResult forObject:(id)anObj;
- (id) testResultForObject:(id)anObj;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) objectsChanged:(NSNotification*)aNote;
- (void) runStatusChanged:(NSNotification*)aNote;
- (void) securityStateChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (BOOL) stopTests;
- (BOOL) repeat;
- (void) setRepeat:	(BOOL)aValue;
- (int) repeatCount;
- (void) setRepeatCount:(int)aValue;
- (void) repeatChanged:(NSNotification*)aNote;
- (void) repeatCountChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) runTest:(id)sender;
- (IBAction) tableClick:(id)sender;
- (IBAction) stopTests:(id)sender;
- (IBAction) lockAction:(id)sender;
- (IBAction) repeatCountAction:(id)sender;
- (IBAction) repeatAction:(id)sender;

#pragma mark •••Delegate Methods
- (BOOL)outlineView:(NSOutlineView *)ov shouldSelectItem:(id)item;

#pragma mark •••Data Source Methods
- (BOOL) outlineView:(NSOutlineView*)ov isItemExpandable:(id)item;
- (int)  outlineView:(NSOutlineView*)ov numberOfChildrenOfItem:(id)item;
- (id)   outlineView:(NSOutlineView*)ov child:(int)index ofItem:(id)item;
- (id)   outlineView:(NSOutlineView*)ov objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item;

@end
extern NSString*  AutoTesterLock;
extern NSString*  ORAutoTesterRepeatNotification;
extern NSString*  ORAutoTesterRepeatCountNotification;

