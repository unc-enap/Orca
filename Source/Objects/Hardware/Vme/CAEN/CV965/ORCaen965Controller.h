/*
 *  ORCaen965Controller.h
 *  Orca
 *
 *  Created by Mark Howe on Friday June 19 2009.
 *  Copyright (c) 2009 UNC. All rights reserved.
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
#pragma mark •••Imported Files

#import "OrcaObjectController.h"

// Definition of class.
@interface ORCaen965Controller : OrcaObjectController {
    IBOutlet NSTabView* tabView;
	IBOutlet NSPopUpButton* modelTypePU;
    IBOutlet NSMatrix*	onlineMaskMatrix;
    IBOutlet NSMatrix*	lowThresholdMatrix;
    IBOutlet NSMatrix*	highThresholdMatrix;
    IBOutlet NSTextField* slotField;
    IBOutlet NSTextField* basicLockDocField;
    IBOutlet NSButton*	  basicLock1Button;
    IBOutlet NSButton*	  basicLock2Button;
    IBOutlet NSButton*	 initButton;
    IBOutlet NSButton*	 resetButton;
    IBOutlet NSButton*	 reportButton;

 	IBOutlet NSTextField*	baseAddressField;
    IBOutlet NSStepper*		writeValueStepper;
    IBOutlet NSTextField* 	writeValueTextField;
    IBOutlet NSPopUpButton*	registerAddressPopUp;
    IBOutlet NSPopUpButton*	channelPopUp;
    IBOutlet NSButton*		basicWriteButton;
    IBOutlet NSButton*		basicReadButton;
	
    // Results box
    IBOutlet NSTextField*	regNameField;
    IBOutlet NSTextField*	drTextField;
    IBOutlet NSTextField*	srTextField;
    IBOutlet NSTextField*	hrTextField;
    IBOutlet NSTextField*	registerOffsetTextField;
    IBOutlet NSTextField*	registerReadWriteTextField;
	
	NSView *blankView;
    NSSize settingSize;
    NSSize thresholdSize;
}

#pragma mark ***Initialization
- (id) init;

#pragma mark ***Interface Management
- (void) modelTypeChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) setModel:(id)aModel;
- (void) checkGlobalSecurity;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) lowThresholdChanged:(NSNotification*)aNote;
- (void) highThresholdChanged:(NSNotification*)aNote;
- (void) basicLockChanged:(NSNotification*)aNote;
- (void) onlineMaskChanged:(NSNotification*)aNote;
- (void) writeValueChanged:(NSNotification*)aNote;
- (void) selectedRegIndexChanged:(NSNotification*)aNote;
- (void) selectedRegChannelChanged:(NSNotification*)aNote;
- (void) enableControls;

#pragma mark •••Actions
- (IBAction) modelTypeAction:(id)sender;
- (IBAction) baseAddressAction: (id)aSender;
- (IBAction) lowThresholdAction:(id)sender;
- (IBAction) highThresholdAction:(id)sender;
- (IBAction) onlineAction:(id)sender;
- (IBAction) basicLockAction:(id)sender;
- (IBAction) writeValueAction:(id)sender;

- (IBAction) selectRegisterAction:(id)sender;
- (IBAction) selectChannelAction:(id)sender;
- (IBAction) lowThresholdAction:(id)sender;
- (IBAction) highThresholdAction:(id)sender;
- (IBAction) read:(id)sender;
- (IBAction) write:(id)sender;
- (IBAction) onlineAction:(id)sender;
- (IBAction) report:(id) sender;
- (IBAction) resetBoard:(id)sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) basicLockAction:(id)sender;

- (void) populatePullDown;
- (void) updateRegisterDescription:(short) aRegisterIndex;
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
@end
