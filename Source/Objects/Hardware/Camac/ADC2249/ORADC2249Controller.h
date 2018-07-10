
/*
 *  ORADC2249ModelController.h
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
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
#import "ORADC2249Model.h"

@interface ORADC2249Controller : OrcaObjectController {
	@private
        IBOutlet NSMatrix*		onlineMaskMatrix;
        IBOutlet NSButton*		settingLockButton;
        IBOutlet NSTextField*   settingLockDocField;
        IBOutlet NSButton*		readNoResetButton;
        IBOutlet NSButton*		readResetButton;
        IBOutlet NSButton*		testLAMButton;
        IBOutlet NSButton*		resetLAMButton;
        IBOutlet NSButton*		disableLAMEnableLatchButton;
        IBOutlet NSButton*		enableLAMEnableLatchButton;
        IBOutlet NSButton*		testAllChansButton;
        IBOutlet NSButton*		suppressZerosButton;
        IBOutlet NSButton*		includeTimingButton;
       IBOutlet NSButton*		generalResetButton;
//       IBOutlet NSButton*		testBusyButton;
};

- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) onlineMaskChanged:(NSNotification*)aNotification;
- (void) suppressZerosChanged:(NSNotification*)aNotification;
- (void) includeTimingChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Actions
- (IBAction) includeTimingAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) onlineAction:(id)sender;
- (IBAction) readNoResetAction:(id)sender;
- (IBAction) readResetAction:(id)sender;
- (IBAction) testLAMAction:(id)sender;
- (IBAction) resetLAMAction:(id)sender;
- (IBAction) disableLAMEnableLatchAction:(id)sender;
- (IBAction) enableLAMEnableLatchAction:(id)sender;
- (IBAction) testAllChansAction:(id)sender;
- (IBAction) suppressZerosAction:(id)sender;
//- (IBAction) testBusyAction:(id)sender;
- (IBAction) generalResetAction:(id)sender;

 - (void) showError:(NSException*)anException name:(NSString*)name fCode:(int)i;

@end