//
//  ORCV830Controller.h
//  Orca
//
//  Created by Mark Howe on 06/06/2012
// Copyright (c) 2012 University of North Carolina. All rights reserved.
//
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina,or U.S. Government make any warranty,
//express or implied,or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORCaenCardController.h"

@interface ORCV830Controller : ORCaenCardController {

	IBOutlet NSButton*		enableAllButton;
	IBOutlet NSTextField*   count0OffsetField;
	IBOutlet NSButton*		autoResetCB;
	IBOutlet NSButton*		clearMebCB;
	IBOutlet NSButton*		testModeCB;
	IBOutlet NSPopUpButton* acqModePU;
	IBOutlet NSTextField*	dwellTimeField;
	IBOutlet NSButton*		disableAllButton;
	IBOutlet NSMatrix*		enabledMaskMatrix;
	IBOutlet NSMatrix*		channelLabelMatrix;
	IBOutlet NSMatrix*		scalerValueMatrix;

	IBOutlet NSButton*		softwareTriggerButton;
	IBOutlet NSButton*		softwareResetButton;
	IBOutlet NSButton*		readScalersButton;
	IBOutlet NSPopUpButton* pollingButton;
	IBOutlet NSButton*		shipRecordsButton;
	IBOutlet NSButton*		initHWButton;
	IBOutlet NSButton*		softwareClearButton;
}

- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) count0OffsetChanged:(NSNotification*)aNote;
- (void) autoResetChanged:(NSNotification*)aNote;
- (void) clearMebChanged:(NSNotification*)aNote;
- (void) testModeChanged:(NSNotification*)aNote;
- (void) acqModeChanged:(NSNotification*)aNote;
- (void) dwellTimeChanged:(NSNotification*)aNote;
- (void) enabledMaskChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) allScalerValuesChanged:(NSNotification*)aNote;
- (void) scalerValueChanged:(NSNotification*)aNote;
- (void) shipRecordsChanged:(NSNotification*)aNote;
- (void) pollingStateChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) count0OffsetAction:(id)sender;
- (IBAction) autoResetAction:(id)sender;
- (IBAction) clearMebAction:(id)sender;
- (IBAction) testModeAction:(id)sender;
- (IBAction) acqModeAction:(id)sender;
- (IBAction) dwellTimeAction:(id)sender;
- (IBAction) initHWAction:(id)sender;
- (IBAction) softwareTriggerAction:(id)sender;
- (IBAction) softwareClearAction:(id)sender;
- (IBAction) softwareResetAction:(id)sender;
- (IBAction) enabledMaskAction:(id)sender;
- (IBAction) enableAllAction:(id)sender;
- (IBAction) disableAllAction:(id)sender;
- (IBAction) readScalers:(id)sender;
- (IBAction) shipRecordsAction:(id)sender;
- (IBAction) setPollingAction:(id)sender;
- (IBAction) readStatus:(id)sender;
@end
