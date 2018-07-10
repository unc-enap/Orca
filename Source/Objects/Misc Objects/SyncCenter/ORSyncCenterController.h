//
//  ORHPSyncCenterController.h
//  Orca
//
//  Created by Mark Howe on Thursday, Sept 15, 2016
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

#import "OrcaObjectController.h"
@class ORCompositeTimeLineView;

@interface ORSyncCenterController : OrcaObjectController 
{
    IBOutlet NSTableView*   orcaListView;
	IBOutlet NSButton*		dialogLock;
	IBOutlet ORGroupView*   subComponentsView;
    IBOutlet NSButton* 		removeOrcaButton;
    IBOutlet NSButton* 		addOrcaButton;
    IBOutlet NSButton* 		syncButton;
}

#pragma mark ***Interface Management
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) groupChanged:(NSNotification*)note;
- (void) orcaAdded:(NSNotification*)aNote;
- (void) orcaRemoved:(NSNotification*)aNote;
- (void) tableViewSelectionDidChange:(NSNotification *)aNote;
- (void) reloadData:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) settingLockAction:(id) sender;
- (IBAction) dialogLockAction:(id)sender;
- (IBAction) addOrcaAction:(id)sender;
- (IBAction) removeOrcaAction:(id)sender;
- (IBAction) delete:(id)sender;
- (IBAction) cut:(id)sender;
@end

