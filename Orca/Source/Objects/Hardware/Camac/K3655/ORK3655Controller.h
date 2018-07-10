
/*
 *  ORK3655ModelController.h
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
#import "ORK3655Model.h"

@class ORValueBar;

@interface ORK3655Controller : OrcaObjectController {
	@private
        IBOutlet NSButton*		initButton;
        IBOutlet NSButton*		testLAMButton;
        IBOutlet NSButton*		readSetPointButton;
        IBOutlet NSButton*		clearLAMButton;
        IBOutlet NSButton*		settingLockButton;
        IBOutlet NSMatrix*		setPointMatrix;
        IBOutlet NSButton*		continousButton;
        IBOutlet NSButton*		inhibitEnabledButton;
        IBOutlet NSButton*		useExtClockButton;
        IBOutlet NSTextField*   numChansField;
        IBOutlet NSTextField*   clockFreqField;
        IBOutlet NSTextField*   numberToClearField;
        IBOutlet NSTextField*   numberToSetField;
        IBOutlet NSTextField*   settingLockDocField;
};

#pragma mark ¥¥¥Interface Management
- (void) registerNotificationObservers;
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) continousChanged:(NSNotification*)aNotification;
- (void) inhibitEnabledChanged:(NSNotification*)aNotification;
- (void) useExtClockChanged:(NSNotification*)aNotification;
- (void) numChansChanged:(NSNotification*)aNotification;
- (void) clockFreqChanged:(NSNotification*)aNotification;
- (void) numberToClearChanged:(NSNotification*)aNotification;
- (void) numberToSetChanged:(NSNotification*)aNotification;
- (void) setPointsChanged:(NSNotification*)aNotification;
- (void) setPointChanged:(NSNotification*)aNotification;
- (void) enableSetPointFields;

#pragma mark ¥¥¥Actions
- (IBAction) initAction:(id) sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) testLAMAction:(id)sender;
- (IBAction) clearLAMAction:(id)sender;
- (IBAction) continousAction:(id)sender;
- (IBAction) inhibitEnabledAction:(id)sender;
- (IBAction) useExtClockAction:(id)sender;
- (IBAction) numChansAction:(id)sender;
- (IBAction) clockFreqAction:(id)sender;
- (IBAction) numberToClearAction:(id)sender;
- (IBAction) numberToSetAction:(id)sender;
- (IBAction) setPointAction:(id)sender;
- (IBAction) readSetPointAction:(id)sender;

 - (void) showError:(NSException*)anException name:(NSString*)name fCode:(int)i;

@end