//
//  ORHPXTR6Controller.h
//  Orca
//
//  Created by Mark Howe on Jan 15, 2014 2003.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------



#import "OrcaObjectController.h"

@class ORUSB;
@class ORSerialPortController;

@interface ORXTR6Controller : OrcaObjectController 
{
	IBOutlet NSMatrix*		connectionProtocolMatrix;
	IBOutlet NSTextField*   onOffStateField;
	IBOutlet NSTextField*   currentField;
	IBOutlet NSTextField*   voltageField;
	IBOutlet NSTextField*   targetVoltageField;
	IBOutlet NSTextField*   channelAddressField;
	IBOutlet NSTextField*	ipConnectedTextField;
	IBOutlet NSTextField*	ipAddressTextField;
	IBOutlet NSTabView*		connectionProtocolTabView;
	IBOutlet NSTextField*	connectionNoteTextField;
	IBOutlet NSButton*		onButton;
	IBOutlet NSButton*		offButton;
	IBOutlet NSButton*		loadParamsButton;
	IBOutlet NSButton*		sendCommandButton;
	IBOutlet NSTextField*	commandField;
	IBOutlet NSTextField*	lockDocField;

	IBOutlet NSPopUpButton* serialNumberPopup;
	IBOutlet NSButton*		ipConnectButton;
	IBOutlet NSButton*		remoteButton;
	IBOutlet NSButton*		lockButton;
	IBOutlet NSButton*		readIdButton;
	IBOutlet NSButton*		testButton;
    IBOutlet ORSerialPortController* serialPortController;
}

#pragma mark •••Notifications
- (void) canChangeProtocolChanged:(NSNotification*)aNote;

#pragma mark ***Interface Management
- (void) onOffStateChanged:(NSNotification*)aNote;
- (void) currentChanged:(NSNotification*)aNote;
- (void) voltageChanged:(NSNotification*)aNote;
- (void) targetVoltageChanged:(NSNotification*)aNote;
- (void) channelAddressChanged:(NSNotification*)aNote;
- (void) canChangeProtocolChanged:(NSNotification*)aNote;
- (void) ipConnectedChanged:(NSNotification*)aNote;
- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) connectionProtocolChanged:(NSNotification*)aNote;
- (void) updateButtons;

#pragma mark •••Actions
- (IBAction) targetVoltageAction:(id)sender;
- (IBAction) loadParamsAction:(id)sender;
- (IBAction) channelAddressAction:(id)sender;
- (IBAction) serialNumberAction:(id)sender;
- (IBAction) ipAddressTextFieldAction:(id)sender;
- (IBAction) connectionProtocolAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) readIdAction:(id) sender;
- (IBAction) sendCommandAction:(id)sender;
- (IBAction) test:(id)sender;

- (void) populateInterfacePopup;
- (void) validateInterfacePopup;

@end

