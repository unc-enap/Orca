
/*
 *  ORAD3511ModelController.h
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
#import "ORAD3511Model.h"

@class ORTimedTextField;

@interface ORAD3511Controller : OrcaObjectController {
	@private
        IBOutlet NSButton*		settingLockButton;
		IBOutlet NSButton*		includeTimingButton;
        IBOutlet NSTextField*   settingLockDocField;
        IBOutlet NSButton*		readButton;
        IBOutlet NSButton*		testLAMButton;
        IBOutlet NSButton*		resetLAMButton;
        IBOutlet NSButton*		enabledButton;
        IBOutlet NSButton*		initButton;
        IBOutlet NSPopUpButton*	gainPopUp;
        IBOutlet NSPopUpButton*	offsetPopUp;
};

- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) includeTimingChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) enabledChanged:(NSNotification*)aNotification;
- (void) gainChanged:(NSNotification*)aNotification;
- (void) offsetChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Actions
- (IBAction) includeTimingAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) readAction:(id)sender;
- (IBAction) testLAMAction:(id)sender;
- (IBAction) resetLAMAction:(id)sender;
- (IBAction) enabledAction:(id)sender;
- (IBAction) gainAction:(id)sender;
- (IBAction) offsetAction:(id)sender;
- (IBAction) initAction:(id)sender;

 - (void) showError:(NSException*)anException name:(NSString*)name fCode:(int)i;

@end