//
//  ORHPPulser33220Controller.h
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
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



#import "ORHPPulserController.h"

@class ORUSB;

@interface ORPulser33220Controller : ORHPPulserController 
{
	IBOutlet NSMatrix*		connectionProtocolMatrix;
	IBOutlet NSTextField*	ipConnectedTextField;
	IBOutlet NSTextField*	ipAddressTextField;
	IBOutlet NSTabView*		connectionProtocolTabView;
	IBOutlet NSTextField*	connectionNoteTextField;

	IBOutlet NSPopUpButton* serialNumberPopup;
	IBOutlet NSButton*		ipConnectButton;
	IBOutlet NSButton*		remoteButton;
}

#pragma mark ¥¥¥Notifications
- (void) connectionProtocolChanged:(NSNotification*)aNote;

#pragma mark ***Interface Management
- (void) canChangeConnectionProtocolChanged:(NSNotification*)aNote;
- (void) ipConnectedChanged:(NSNotification*)aNote;
- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) serialNumberAction:(id)sender;
- (IBAction) ipAddressTextFieldAction:(id)sender;
- (IBAction) connectionProtocolAction:(id)sender;
- (IBAction) remoteAction:(id)sender;

- (void) populateInterfacePopup;
- (void) validateInterfacePopup;

@end

