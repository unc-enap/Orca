//
//  ORProcessHwAccessorController.h
//  Orca
//
//  Created by Mark Howe on 11/20/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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



#import "ORProcessElementController.h"

@interface ORProcessHwAccessorController : ORProcessElementController 
{
    IBOutlet NSPopUpButton* interfaceObjPU;
    IBOutlet NSTextField*	channelField;
    IBOutlet NSTextField*   currentSourceField;
    IBOutlet NSTextField*   currentSourceStateField;
    IBOutlet NSButton*      hwAccessLockButton;
	IBOutlet NSButton*		viewSourceButton;

	IBOutlet NSPopUpButton* viewIconTypePU;
	IBOutlet NSMatrix*		labelTypeMatrix;
	IBOutlet NSTextField*	customLabelField;
	IBOutlet NSTextField*	displayFormatField;
}

#pragma mark ¥¥¥Initialization
- (void) awakeFromNib;
- (void) registerNotificationObservers;
- (void) populateObjPU;
- (void) viewIconTypeChanged:(NSNotification*)aNote;
- (void) labelTypeChanged:(NSNotification*)aNote;
- (void) customLabelChanged:(NSNotification*)aNote;
- (void) displayFormatChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Interface Management
- (void) checkGlobalSecurity;
- (void)setButtonStates;
- (void) interfaceObjectChanged:(NSNotification*)aNotification;
- (void) bitChanged:(NSNotification*)aNotification;
- (void) objectsRemoved:(NSNotification*) aNotification;
- (void) objectsAdded:(NSNotification*) aNotification;
- (void) slotChanged:(NSNotification*) aNotification;
- (void) hwNameChanged:(NSNotification*) aNotification;
- (void) hwAccessLockChanged:(NSNotification *)notification;

#pragma mark ¥¥¥Actions
- (IBAction) hwAccessLockAction:(id)sender;
- (IBAction) interfaceObjPUAction:(id)sender;
- (IBAction) channelFieldAction:(id)sender;
- (IBAction) viewSourceAction:(id)sender;
- (IBAction) viewIconTypeAction:(id)sender;
- (IBAction) labelTypeAction:(id)sender;
- (IBAction) customLabelAction:(id)sender;
- (IBAction) displayFormatAction:(id)sender;@end
