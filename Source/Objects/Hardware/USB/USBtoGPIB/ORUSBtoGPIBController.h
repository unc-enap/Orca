//
//  ORHPUSBtoGPIBController.h
//  Orca
//
//  Created by Mark Howe on Thurs Jan 26 2007.
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

@interface ORUSBtoGPIBController : OrcaObjectController 
{
	IBOutlet   NSPopUpButton*	serialNumberPopup;
	IBOutlet   NSTextField*		commandTextField;
	IBOutlet   NSTextField*		addressTextField;
}

#pragma mark ¥¥¥Notifications

#pragma mark ***Interface Management
- (void) commandChanged:(NSNotification*)aNote;
- (void) addressChanged:(NSNotification*)aNote;
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) sendAction:(id)sender;
- (IBAction) commandTextFieldAction:(id)sender;
- (IBAction) addressTextFieldAction:(id)sender;
- (IBAction) serialNumberAction:(id)sender;

- (void) populateInterfacePopup:(ORUSB*)usb;
- (void) validateInterfacePopup;

@end

