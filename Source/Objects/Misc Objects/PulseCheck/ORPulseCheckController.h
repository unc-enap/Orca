//
//  ORPulseCheckContoller.h
//  Orca
//
//  Created by Mark Howe on Monday Apr 4,2016.
//  Copyright (c) 2016 University of North Carolina. All rights reserved.
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

@interface ORPulseCheckController : OrcaObjectController <NSTableViewDataSource>{
    IBOutlet NSTableView*	pulseCheckView;
    IBOutlet NSTextField*	lastFileTextField;
    IBOutlet NSButton*      listLockButton;
    IBOutlet NSButton*      addMachineButton;
    IBOutlet NSButton*      removeMachineButton;
    IBOutlet NSButton*      saveButton;
    IBOutlet NSButton*      restoreButton;
 }

- (void) setButtonStates;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) forceReload;

#pragma mark •••Interface Management
- (BOOL) validateMenuItem:      (NSMenuItem*)menuItem;
- (void) lastFileChanged:       (NSNotification*)aNote;
- (void) machineAdded:          (NSNotification*)aNote;
- (void) machineRemoved:        (NSNotification*)aNote;
- (void) listLockChanged:       (NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) removeMachineAction:(id)sender;
- (IBAction) addMachineAction:(id)sender;
- (IBAction) listLockAction:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) cut:(id)sender;
- (IBAction) loadFileAction:(id) sender;
- (IBAction) saveFileAction:(id) sender;
- (IBAction) checkNow:(id) sender;

#pragma mark •••Delegate Methods
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification;

#pragma mark •••Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;

@end

