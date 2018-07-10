//
//  OR4ChanController.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 16 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


@interface OR4ChanTriggerController : OrcaObjectController {
	
    IBOutlet NSTabView*		tabView;
	IBOutlet NSButton*		shipFirstLastButton;
    IBOutlet NSTextField*   slotField;
    IBOutlet NSStepper* 	addressStepper;
    IBOutlet NSTextField* 	addressText;

    IBOutlet NSButton*		resetRegistersButton;
    IBOutlet NSButton*		resetClockButtonPage1;
    IBOutlet NSButton*		boardIDButton;
    IBOutlet NSButton*		getStatusButton;
    IBOutlet NSMatrix*		shipClockMatrix;
    IBOutlet NSButton*		clockEnableButton;
 
    IBOutlet NSTextField*	errorField;

    IBOutlet NSTextField*	trigger1NameField;
    IBOutlet NSTextField*	trigger2NameField;
    IBOutlet NSTextField*	trigger3NameField;
    IBOutlet NSTextField*	trigger4NameField;

    IBOutlet NSButton*		settingLockButton;
    IBOutlet NSButton*		specialLockButton;
    IBOutlet NSTextField*   settingLockDocField;
    IBOutlet NSTextField*   specialLockDocField;


    IBOutlet NSTextField*	lowerClockField;
    IBOutlet NSStepper*		lowerClockStepper;
    IBOutlet NSTextField*	upperClockField;
    IBOutlet NSStepper*		upperClockStepper;
    IBOutlet NSButton*		loadLowerClockButton;
    IBOutlet NSButton*		loadUpperClockButton;
    IBOutlet NSButton*		resetClockButtonPage2;
    IBOutlet NSButton*		enableClockButton;
    IBOutlet NSButton*		disableClockButton;
   
    IBOutlet NSButton*		softLatchButton;
    IBOutlet NSButton*		readClocksButton;

}

- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) shipFirstLastChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) baseAddressChanged:(NSNotification*)aNotification;

- (void) shipClockChanged:(NSNotification*)aNotification;
- (void) updateClockMask;

- (void) lowerClockChanged:(NSNotification*)aNotification;
- (void) upperClockChanged:(NSNotification*)aNotification;
- (void) errorCountChanged:(NSNotification*)aNotification;
- (void) triggerNameChanged:(NSNotification*)aNotification;
- (void) enableClockChanged:(NSNotification*)aNotification;


- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) specialLockChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) shipFirstLastAction:(id)sender;
- (IBAction) baseAddressAction:(id)sender;

- (IBAction) lowerClockAction:(id)sender;
- (IBAction) upperClockAction:(id)sender;

- (IBAction) boardIDAction:(id)sender;
- (IBAction) statusReadAction:(id)sender;

- (IBAction) resetAction:(id)sender;
- (IBAction) resetClockAction:(id)sender;

- (IBAction) loadLowerClockAction:(id)sender;
- (IBAction) loadUpperClockAction:(id)sender;

- (IBAction) readClocksAction:(id)sender;
- (IBAction) enableClockAction:(id)sender;

- (IBAction) shipClockAction:(id)sender;

- (IBAction) triggerNameAction:(id)sender;

- (IBAction) softLatchAction:(id)sender;
- (IBAction) writeEnableClockAction:(id)sender;
- (IBAction) writeDisableClockAction:(id)sender;

- (IBAction) settingLockAction:(id) sender;
- (IBAction) specialLockAction:(id) sender;

@end
