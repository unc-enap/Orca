//
//  ORCmdLabelController.h
//  Orca
//
//  Created by Mark Howe on Tuesday Apr 6,2009.
//  Copyright © 20010 University of North Carolina. All rights reserved.
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
#import "ORLabelController.h"

@interface ORCmdLabelController : ORLabelController
{
	IBOutlet NSTableView*	commandTable;
    IBOutlet NSTextField*	objectField;
    IBOutlet NSTextField*	setSelectorField;
    IBOutlet NSTextField*	formatField;
    IBOutlet NSTextField*	loadField;
    IBOutlet NSTextField*	argField;
	IBOutlet NSTextField*	itemCountField;
	IBOutlet NSButton*		okButton;
	IBOutlet NSButton*		okAllButton;
	IBOutlet NSButton*		removeButton;
	IBOutlet NSButton*		addButton;
}

#pragma mark •••Initialization
- (id) init;

#pragma mark •••Interface Management
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) labelLockChanged:(NSNotification*)aNote;
- (void) commandSelectionChanged:(NSNotification *)aNote;
- (void) detailsChanged:(NSNotification*)aNote;
- (void) fillItemCount;

#pragma mark •••Actions
- (IBAction) okAction:(id)sender;
- (IBAction) okAllAction:(id)sender;

- (IBAction) checkSyntaxAction:(id)sender;
- (IBAction) labelLockAction:(id)sender;
- (IBAction) detailsAction:(id)sender;
- (IBAction) addCommandAction:(id)sender;
- (IBAction) removeCommandAction:(id)sender;
@end
