
/*
 *  ORAD413AModelController.h
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
#import "ORAD413AModel.h"

@interface ORAD413AController : OrcaObjectController {
	@private
        IBOutlet NSMatrix*		onlineMaskMatrix;
        IBOutlet NSMatrix*		discriminatorFieldMatrix;
        IBOutlet NSMatrix*		discriminatorStepperMatrix;
        IBOutlet NSButton*		clearModuleButton;
        
        IBOutlet NSButton*		settingLockButton;

		IBOutlet NSTextField*   virtualStationField;
		IBOutlet NSTextField*   CAMACEnabledField;
        IBOutlet NSMatrix*		controlReg1Matrix;
        IBOutlet NSButton*		readControlReg1Button;
        IBOutlet NSButton*		writeControlReg1Button;
		IBOutlet NSTextField*   conflictField;

        IBOutlet NSMatrix*		controlReg2Matrix;
        IBOutlet NSButton*		readControlReg2Button;
        IBOutlet NSButton*		writeControlReg2Button;

};

- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) onlineMaskChanged:(NSNotification*)aNotification;
- (void) discriminatorChanged:(NSNotification*)aNotification;
- (void) controlReg1Changed:(NSNotification*)aNotification;
- (void) controlReg2Changed:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) settingLockAction:(id) sender;
- (IBAction) onlineAction:(id)sender;

- (IBAction) discriminatorAction:(id)sender;
- (IBAction) readDiscriminatorAction:(id)sender;
- (IBAction) writeDiscriminatorAction:(id)sender;
- (IBAction) clearModuleAction:(id)sender;

- (IBAction) controlReg1Action:(id)sender;
- (IBAction) readControlReg1Action:(id)sender;
- (IBAction) writeControlReg1Action:(id)sender;

- (IBAction) controlReg2Action:(id)sender;
- (IBAction) readControlReg2Action:(id)sender;
- (IBAction) writeControlReg2Action:(id)sender;


- (void) showError:(NSException*)anException name:(NSString*)name;

@end