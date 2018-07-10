//
//  ORRunNotesContoller.h
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

@interface ORRunNotesController : OrcaObjectController {
    IBOutlet NSTableView*	notesListView;
	IBOutlet NSTextField*   definitionsFilePathField;
	IBOutlet NSButton*		doNotOpenButton;
	IBOutlet NSButton*		ignoreValuesButton;
	IBOutlet NSTextView*	commentsView;
    IBOutlet NSButton*      listLockButton;
    IBOutlet NSTabView*     ignoreNoticeView;
    IBOutlet NSButton*      continueRunButton;
    IBOutlet NSButton*      cancelRunButton;
    IBOutlet NSButton*      addItemButton;
    IBOutlet NSButton*      removeItemButton;
    IBOutlet NSButton*      readDefFileButton;
    IBOutlet NSPanel*		addItemPanel;
    IBOutlet NSTextField*	addItemNameField;
    IBOutlet NSTextField*	addItemValueField;
    IBOutlet NSButton*		addItemDoneButton;
}

- (void) setButtonStates;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Actions
- (IBAction) doNotOpenAction:(id)sender;
- (IBAction) ignoreValuesAction:(id)sender;
- (IBAction) removeItemAction:(id)sender;
- (IBAction) listLockAction:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) cut:(id)sender;
- (IBAction) continueWithRun:(id)sender;
- (IBAction) cancelRun:(id)sender;
- (IBAction) openAddItemPanel:(id)sender;
- (IBAction) closeAddItemPanel:(id)sender;
- (IBAction) doAddItemAction:(id)sender;
- (IBAction) definitionsFileAction:(id)sender;

#pragma mark •••Interface Management
- (void) definitionsFilePathChanged:(NSNotification*)aNote;
- (BOOL) validateMenuItem:(NSMenuItem*)menuItem;
- (void) doNotOpenChanged:(NSNotification*)aNote;
- (void) ignoreValuesChanged:(NSNotification*)aNote;
- (void) itemsAdded:(NSNotification*)aNote;
- (void) itemsRemoved:(NSNotification*)aNote;
- (void) commentsChanged:(NSNotification*)aNote;
- (void) modalChanged:(NSNotification*)aNote;
- (void) listLockChanged:(NSNotification*)aNote;
- (void) itemChanged:(NSNotification*)aNote;
- (void) checkNotice;

#pragma mark •••Delegate Methods
- (void) tableViewSelectionDidChange:(NSNotification *)aNotification;

#pragma mark •••Data Source
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(NSInteger) rowIndex;
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex;
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
@end

