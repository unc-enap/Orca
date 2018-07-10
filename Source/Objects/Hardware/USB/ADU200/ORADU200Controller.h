//
//  ORHPADU200Controller.h
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

@interface ORADU200Controller : OrcaObjectController 
{
	IBOutlet NSPopUpButton* serialNumberPopup;
	IBOutlet NSPopUpButton* pollTimePopup;
	IBOutlet NSPopUpButton* debouncePopup;
	IBOutlet NSMatrix*		eventCounterMatrix;
	IBOutlet NSMatrix*		portAMatrix;
	IBOutlet NSMatrix*		relayStateMatrix;
	IBOutlet NSMatrix*		relayControlMatrix;
    IBOutlet NSTextField*   commandField;
    IBOutlet NSButton*		sendCommandButton;
	IBOutlet NSButton*		queryButton;
	IBOutlet NSButton*		readClearButton;
	IBOutlet NSButton*		lockButton;
}

#pragma mark ¥¥¥Notifications

#pragma mark ***Interface Management
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) debounceChanged:(NSNotification*)aNote;
- (void) eventCounterChanged:(NSNotification*)aNote;
- (void) portAChanged:(NSNotification*)aNote;
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) relayStateChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) debounceAction:(id)sender;
- (IBAction) serialNumberAction:(id)sender;
- (IBAction) relayControlAction:(id)sender;
- (IBAction) sendCommandAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) queryAction:(id)sender;
- (IBAction) readClearAction:(id)sender;

- (void) populateInterfacePopup:(ORUSB*)usb;
- (void) validateInterfacePopup;

@end

