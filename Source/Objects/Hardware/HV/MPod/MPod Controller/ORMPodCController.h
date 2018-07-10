//
//  ORMPodCController.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "OrcaObjectController.h"
#import "ORMPodCController.h"

@class ORValueBarGroupView;
@class ORTimedTextField;

@interface ORMPodCController : OrcaObjectController 
{
	IBOutlet NSButton*			  lockButton;
	IBOutlet NSButton*			  verboseCB;
	IBOutlet NSTextField*		  opTimeField;
	IBOutlet NSTextField*		  serialNumberField;
	IBOutlet NSTextField*		  crateStatusField;
	IBOutlet NSTextField*		  cratePowerStateField;
	IBOutlet NSTextField*		  queueCountField;
	IBOutlet NSComboBox*		  ipNumberComboBox;
	IBOutlet NSButton*			  pingButton;
	IBOutlet NSProgressIndicator* pingTaskProgress;
	IBOutlet NSButton*			  cratePowerButton;
    IBOutlet ORValueBarGroupView* queueValueBar;
	IBOutlet ORTimedTextField*    timeoutField;
}

#pragma mark •••Initialization
- (id)	 init;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;

#pragma mark ***Interface Management
- (void) verboseChanged:(NSNotification*)aNote;
- (void) timeoutHappened:(NSNotification*)aNote;
- (void) queueCountChanged:(NSNotification*)aNote;
- (void) systemStateChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) pingTaskChanged:(NSNotification*)aNote;
- (void) ipNumberChanged:(NSNotification*)aNote;
- (void) updateButtons;

#pragma mark •••Actions
- (IBAction) verboseAction:(id)sender;
- (IBAction) ping:(id)sender;
- (IBAction) ipNumberAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) updateAction:(id)sender;
- (IBAction) clearHistoryAction:(id)sender;
- (IBAction) powerAction:(id)sender;
@end