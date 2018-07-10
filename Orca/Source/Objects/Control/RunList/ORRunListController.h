//
//  ORRunListContoller.h
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

@interface ORRunListController : OrcaObjectController {
    IBOutlet NSTableView*	itemsListView;
	IBOutlet NSTextField*	executionCountField;
	IBOutlet NSTextField*	timesToRepeatField;
	IBOutlet NSTextField*	lastFileTextField;
    IBOutlet NSTextField*   runCountField;
    IBOutlet NSTextField*   pausedStatusField;
	IBOutlet NSButton*		randomizeCB;
    IBOutlet NSButton*      listLockButton;
    IBOutlet NSButton*      addItemButton;
    IBOutlet NSButton*      removeItemButton;
    IBOutlet NSButton*      startButton;
    IBOutlet NSButton*      pauseButton;
    IBOutlet NSButton*      stopButton;
    IBOutlet NSButton*      saveButton;
    IBOutlet NSButton*      restoreButton;
    IBOutlet NSProgressIndicator*      progressBar;
}

- (void) setButtonStates;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) forceReload;

#pragma mark •••Actions
- (IBAction) timesToRepeatAction:(id)sender;
- (IBAction) lastFileTextFieldAction:(id)sender;
- (IBAction) randomizeAction:(id)sender;
- (IBAction) removeItemAction:(id)sender;
- (IBAction) addItemAction:(id)sender;
- (IBAction) listLockAction:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) cut:(id)sender;
- (IBAction) startRunning:(id)sender;
- (IBAction) pauseRunning:(id)sender;
- (IBAction) stopRunning:(id)sender;
- (IBAction) loadFileAction:(id) sender;
- (IBAction) saveFileAction:(id) sender;

#pragma mark •••Interface Management
- (void) timesToRepeatChanged:(NSNotification*)aNote;
- (void) lastFileChanged:(NSNotification*)aNote;
- (void) randomizeChanged:(NSNotification*)aNote;
- (void) updateProgressBar:(NSNotification*)aNote;
- (void) runStateChanged:(NSNotification*)aNote;
- (BOOL) validateMenuItem:(NSMenuItem*)menuItem;
- (void) itemsAdded:(NSNotification*)aNote;
- (void) itemsRemoved:(NSNotification*)aNote;
- (void) listLockChanged:(NSNotification*)aNote;
- (void) runStateChanged:(NSNotification*)aNote;

#pragma mark •••Delegate Methods
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification;

#pragma mark •••Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;

@end

