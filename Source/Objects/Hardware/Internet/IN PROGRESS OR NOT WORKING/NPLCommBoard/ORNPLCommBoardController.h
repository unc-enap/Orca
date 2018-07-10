//
//  ORHPNPLCommBoardController.h
//  Orca
//
//  Created by Mark Howe on Fri Jun 13, 2008
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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

#import "OrcaObjectController.h"

@interface ORNPLCommBoardController : OrcaObjectController 
{
	IBOutlet NSTextField*	ipConnectedTextField;
	IBOutlet NSTextField*	controlRegTextField;
	IBOutlet NSTextField*	cmdStringTextField;
	IBOutlet NSPopUpButton* numBytesToSendPU;
	IBOutlet NSTextField*	writeValueField;
	IBOutlet NSPopUpButton* functionPU;
	IBOutlet NSPopUpButton* blocPU;
	IBOutlet NSPopUpButton* boardPU;
	IBOutlet NSTextField*	ipAddressTextField;
	IBOutlet NSButton*		ipConnectButton;
	IBOutlet NSButton*		lockButton;
	IBOutlet NSButton*		sendButton;
}

#pragma mark •••Notifications

#pragma mark ***Interface Management
- (void) controlRegChanged:(NSNotification*)aNote;
- (void) cmdStringChanged:(NSNotification*)aNote;
- (void) numBytesToSendChanged:(NSNotification*)aNote;
- (void) writeValueChanged:(NSNotification*)aNote;
- (void) functionChanged:(NSNotification*)aNote;
- (void) blocChanged:(NSNotification*)aNote;
- (void) boardChanged:(NSNotification*)aNote;
- (void) isConnectedChanged:(NSNotification*)aNote;
- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) setButtonStates;

#pragma mark •••Actions
- (IBAction) controlRegAction:(id)sender;
- (IBAction) numBytesToSendAction:(id)sender;
- (IBAction) writeValueAction:(id)sender;
- (IBAction) functionAction:(id)sender;
- (IBAction) blocAction:(id)sender;
- (IBAction) boardAction:(id)sender;
- (IBAction) ipAddressTextFieldAction:(id)sender;
- (IBAction) connectAction:(id)sender;
- (IBAction) sendCmdAction:(id)sender;
- (IBAction) lockAction:(id) sender;

@end

