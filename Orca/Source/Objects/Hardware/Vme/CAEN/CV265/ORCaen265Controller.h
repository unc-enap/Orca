//
//  ORCaen265Controller.h
//  Orca
//
//  Created by Mark Howe on 12/7/07
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nug Physics and 
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

@interface ORCaen265Controller : OrcaObjectController {

    IBOutlet NSTextField*   slotField;
	IBOutlet NSButton*		suppressZerosButton;
	IBOutlet NSButton*		enableAllButton;
	IBOutlet NSButton*		disableAllButton;
	IBOutlet NSMatrix*		enabledMaskMatrix;
    IBOutlet NSStepper* 	addressStepper;
    IBOutlet NSTextField* 	addressText;
    IBOutlet NSButton*		initButton;
	IBOutlet NSButton*		probeButton;
    IBOutlet NSButton*		settingLockButton;
    IBOutlet NSButton*		triggerButton;
}

- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) suppressZerosChanged:(NSNotification*)aNote;
- (void) enabledMaskChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) baseAddressChanged:(NSNotification*)aNotification;

#pragma mark •••Actions
- (IBAction) suppressZerosAction:(id)sender;
- (IBAction) enabledMaskAction:(id)sender;
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) probeBoard:(id)sender;
- (IBAction) enableAllAction:(id)sender;
- (IBAction) disableAllAction:(id)sender;
- (IBAction) triggerAction:(id)sender;
@end
