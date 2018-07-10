//
//  OROnCallListContoller.h
//  Orca
//
//  Created by Mark Howe on Monday Oct 19 2015.
//  Copyright (c) 2015 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

@interface OROnCallListController : OrcaObjectController {
    IBOutlet NSTableView*	onCallListView;
    IBOutlet NSTextField*	lastFileTextField;
    IBOutlet NSTextField*	messageField;
    IBOutlet NSButton*      listLockButton;
    IBOutlet NSButton*      addPersonButton;
    IBOutlet NSButton*      removePersonButton;
    IBOutlet NSButton*      saveButton;
    IBOutlet NSButton*      restoreButton;
    IBOutlet NSButton*      sendMessageButton;
 }

- (void) setButtonStates;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) forceReload;

#pragma mark •••Interface Management
- (BOOL) validateMenuItem:      (NSMenuItem*)menuItem;
- (void) lastFileChanged:       (NSNotification*)aNote;
- (void) personAdded:           (NSNotification*)aNote;
- (void) personRemoved:         (NSNotification*)aNote;
- (void) listLockChanged:       (NSNotification*)aNote;
- (void) peopleNotifiedChanged: (NSNotification*)aNote;
- (void) messageChanged:        (NSNotification*)aNote;
- (void) editingDidEnd:         (NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) removePersonAction:(id)sender;
- (IBAction) addPersonAction:(id)sender;
- (IBAction) listLockAction:(id)sender;
- (IBAction) sendMessageAction:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) cut:(id)sender;
- (IBAction) loadFileAction:(id) sender;
- (IBAction) saveFileAction:(id) sender;

#pragma mark •••Delegate Methods
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification;

#pragma mark •••Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;

@end

