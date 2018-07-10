//
//  ORAlarmController.h
//  Orca
//
//  Created by Mark Howe on Fri Jan 17 2003.
//  Copyright © 2003 CENPA, University of Washington. All rights reserved.
//
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
#import "ORAlarmCollection.h"

@interface ORAlarmController : NSWindowController {

	IBOutlet NSButton* 		acknowledgeButton;
	IBOutlet NSButton* 		helpButton;
	IBOutlet NSTextView* 	helpTextView;
    IBOutlet NSTableView* 	tableView;
	IBOutlet NSDrawer* 		helpDrawer;
	IBOutlet NSMatrix*      severityMatrix;
	IBOutlet NSTableView*	addressList;
	IBOutlet NSTextField*	addressField;
	IBOutlet NSButton* 		removeAddressButton;
	IBOutlet NSButton* 		eMailEnabledButton;
}

#pragma mark •••Inialization
+ (ORAlarmController*) sharedAlarmController;

#pragma mark •••Accessors
- (NSButton*) acknowledgeButton;
- (NSButton*) helpButton;
- (ORAlarmCollection*) alarmCollection;

#pragma mark •••Actions
- (IBAction) acknowledge:(id)sender;
- (IBAction) addAddress:(id)sender;
- (IBAction) removeAddress:(id)sender;
- (IBAction) severityAction:(id)sender;
- (IBAction) addressAction:(id)sender;
- (IBAction) eMailEnabledAction:(id)sender;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) eMailEnabledChanged:(NSNotification*)aNotification;
- (void) alarmsChanged:(NSNotification*)aNotification;
- (void) severitySelectionChanged:(NSNotification*)aNotification;
- (void) addressChanged:(NSNotification*)aNotification;
- (void) documentLoaded:(NSNotification*)aNotification;
- (void) addressAdded:(NSNotification*)aNote;
- (void) addressRemoved:(NSNotification*)aNote;
- (void) reloadAddressList:(NSNotification*)aNote;
- (void) editingDidEnd:(NSNotification*)aNote;

- (void) setUpHelpText;
- (BOOL)validateMenuItem:(NSMenuItem*)menuItem;

#pragma mark •••Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification;

@end
