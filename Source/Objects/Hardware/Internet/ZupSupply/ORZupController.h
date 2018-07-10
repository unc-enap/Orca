//
//  ORZupController.h
//  Orca
//
//  Created by Mark Howe on Monday March 16,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORRamperController.h"

@interface ORZupController : ORRamperController 
{
	IBOutlet NSButton*		lockButton;
	IBOutlet NSTextField*	actualVoltageField;
	IBOutlet NSMatrix*		statusEnableMatrix;
	IBOutlet NSMatrix*		faultEnableMatrix;
	IBOutlet NSMatrix*		faultRegMatrix;
	IBOutlet NSMatrix*		statusRegMatrix;
	IBOutlet NSTextField*	currentTextField;
	IBOutlet NSTextField*	actualCurrentTextField;
	IBOutlet NSTextField*	outputStateField;
	IBOutlet NSTextField*	boardAddressField;
	IBOutlet NSButton*		sendButton;
    IBOutlet NSTextField*   portStateField;
    IBOutlet NSPopUpButton* portListPopup;
    IBOutlet NSButton*      openPortButton;
    IBOutlet NSButton*      onOffButton;
	
	//lots of other Outlets inherited from the RamperController
	IBOutlet NSView*		totalView;
	IBOutlet NSTabView*		tabView;	
	NSSize					basicOpsSize;
	NSSize					rampOpsSize;
	NSView*					blankView;
}

#pragma mark ***Interface Management
- (void) actualVoltageChanged:(NSNotification*)aNote;
- (void) statusEnableMaskChanged:(NSNotification*)aNote;
- (void) faultEnableMaskChanged:(NSNotification*)aNote;
- (void) faultRegisterChanged:(NSNotification*)aNote;
- (void) statusRegisterChanged:(NSNotification*)aNote;
- (void) currentChanged:(NSNotification*)aNote;
- (void) actualCurrentChanged:(NSNotification*)aNote;
- (void) outputStateChanged:(NSNotification*)aNote;
- (void) boardAddressChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) setButtonStates;
- (void) portNameChanged:(NSNotification*)aNote;
- (void) portStateChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) statusEnableMaskAction:(id)sender;
- (IBAction) faultEnableMaskAction:(id)sender;
- (IBAction) currentTextFieldAction:(id)sender;
- (IBAction) actualCurrentTextFieldAction:(id)sender;
- (IBAction) boardAddressAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) initBoard:(id) sender;
- (IBAction) portListAction:(id) sender;
- (IBAction) openPortAction:(id)sender;
- (IBAction) getStatusAction:(id)sender;
- (IBAction) onOffAction:(id)sender;
- (IBAction) sendEnableSRQAction:(id)sender;

@end

