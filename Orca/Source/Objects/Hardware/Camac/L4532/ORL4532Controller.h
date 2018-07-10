
/*
 *  ORL4532ModelController.h
 *  Orca
 *
 *  Created by Mark Howe on Fri Sept 29, 2006.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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

#pragma mark ¥¥¥Imported Files
#import "ORL4532Model.h"

@interface ORL4532Controller : OrcaObjectController {
@private
	IBOutlet NSButton*		includeTimingButton;
	
	IBOutlet NSMatrix*		triggerNames0_15;
	IBOutlet NSMatrix*		triggerNames16_31;
	
	IBOutlet NSMatrix*		delayEnableMask0_15;
	IBOutlet NSMatrix*		delayEnableMask16_31;
	
	IBOutlet NSMatrix*		delays0_15;
	IBOutlet NSMatrix*		delays16_31;
	
	IBOutlet NSTextField*	numberTriggersTextField;
	IBOutlet NSButton*		readInputsButton;
	
	IBOutlet NSButton*		testLAMButton;
	IBOutlet NSButton*		testLAMClearButton;
	IBOutlet NSButton*		readInputsClearButton;
	IBOutlet NSButton*		clearMemLAMButton;
	
	IBOutlet NSTextField*   settingLockDocField;
	IBOutlet NSButton*		statusButton;
	IBOutlet NSButton*		settingLockButton;
	IBOutlet NSButton*      showHideButton;
	IBOutlet NSTextField*   delayWarningField;
};

-(id)init;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) enableMatrices;
- (void) checkDelaysInUseMessage;

#pragma mark ¥¥¥Interface Management
- (void) delayEnableMaskChanged:(NSNotification*)aNote;
- (void) numberTriggersChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) includeTimingChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (IBAction) settingLockAction:(id) sender;
- (void) triggerNamesChanged:(NSNotification*)aNote;
- (void) delaysChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) showHideAction:(id)sender;
- (IBAction) triggerNamesAction:(id)sender;
- (IBAction) delayEnableMaskAction:(id)sender;
- (IBAction) delaysAction:(id)sender;
- (IBAction) numberTriggersAction:(id)sender;
- (IBAction) testLAM:(id)sender;
- (IBAction) testClearLAM:(id)sender;
- (IBAction) readInputsAction:(id)sender;
- (IBAction) readInputsAndClearAction:(id)sender;
- (IBAction) includeTimingAction:(id)sender;
- (IBAction) readStatusRegisterAction:(id)sender;
- (IBAction) clearMemoryAndLAM:(id)sender;
- (void) showError:(NSException*)anException name:(NSString*)name;
@end