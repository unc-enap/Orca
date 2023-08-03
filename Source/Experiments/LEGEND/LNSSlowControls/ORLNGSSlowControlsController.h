//
//  ORLNGSSlowControlsController.h
//  Orca
//
//  Created by Mark Howe on Thursday, Aug 20,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "OrcaObjectController.h"
#import "ORTimedTextField.h"

@interface ORLNGSSlowControlsController : OrcaObjectController
{
	IBOutlet NSButton*		        lockButton;
	IBOutlet NSButton*		        sendButton;

	IBOutlet NSProgressIndicator*   pollingProgress;
	IBOutlet NSPopUpButton*         pollTimePopup;
	IBOutlet NSButton*              pollNowButton;
    IBOutlet NSTextField*           userNameField;
    IBOutlet NSTextField*           cmdPathField;
    IBOutlet NSTextField*           ipAddressField;
    IBOutlet NSTextField*           inFluxAvailableField;
    IBOutlet NSTextField*           LlamaField;

    IBOutlet NSTableView*           statusTable;
    IBOutlet NSTableView*           muonTable;
    IBOutlet NSTableView*           siPMTable;
    IBOutlet NSTableView*           diodeTable;
    IBOutlet NSTableView*           sourceTable;
}

#pragma mark ***Interface Management
- (void) lockChanged:(NSNotification*)aNote;
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) userNameChanged:(NSNotification*)aNote;
- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) statusChanged:(NSNotification*)aNote;
- (void) inFluxAvailablityChanged:(NSNotification*)aNote;
- (void) reloadDataTables:(NSNotification*)aNote;;

#pragma mark •••Actions
- (IBAction) lockAction:(id) sender;
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) pollNowAction:(id)sender;
- (IBAction) userNameAction:(id)sender;
- (IBAction) cmdPathAction:(id)sender;
- (IBAction) ipAddressAction:(id)sender;
@end

