//
//  ORReplayDataController.h
//  Orca
//
//  Created by Rielage on Thu Oct 02 2003.
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


@interface ORReplayDataController : OrcaObjectController  {
    @private
	IBOutlet NSButton* 		selectButton;
	IBOutlet NSButton* 		replayButton;
	IBOutlet NSTableView*   fileListView;
    IBOutlet NSOutlineView*	headerView;
	IBOutlet NSButton* 		viewHeaderButton;
	IBOutlet NSTextField* 	viewHeaderFile;
	IBOutlet NSProgressIndicator* 	progressIndicator;
	IBOutlet NSTextField* 	progressField;
	IBOutlet NSTextField* 	workingOnField;
	IBOutlet NSProgressIndicator* 	progressIndicatorBottom;
}

#pragma mark ¥¥¥Accessors
- (void) loadHeader;

#pragma  mark ¥¥¥Actions
- (IBAction) selectButtonAction:(id)sender;
- (IBAction) replayButtonAction:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) cut:(id)sender;
- (IBAction) removeItemAction:(id)sender;
- (IBAction) saveListAction:(id)sender;
- (IBAction) loadListAction:(id)sender;

#pragma mark ¥¥¥Interface Management
- (void) progressChanged:(NSNotification *)aNotification;
- (void) registerNotificationObservers;
- (void) fileListChanged:(NSNotification*)note;
- (void) started:(NSNotification *)aNotification;
- (void) stopped:(NSNotification *)aNotification;
- (void) fileChanged:(NSNotification *)aNotification;

#pragma mark ¥¥¥Data Source Methods
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex;
- (int)numberOfRowsInTableView:(NSTableView *)aTableView;


#pragma mark ¥¥¥Interface Management
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
@end
