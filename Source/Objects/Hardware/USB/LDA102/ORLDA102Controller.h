//
//  ORHPLDA102Controller.h
//  Orca
//
//  Created by Mark Howe on Wed Feb 18, 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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

@class ORUSB;

@interface ORLDA102Controller : OrcaObjectController 
{
	IBOutlet NSPopUpButton* serialNumberPopup;
	IBOutlet NSTextField*	rampValueField;
	IBOutlet NSButton*		repeatRampButton;
	IBOutlet NSTextField*	idleTimeField;
	IBOutlet NSTextField*	dwellTimeField;
	IBOutlet NSTextField*	rampEndField;
	IBOutlet NSTextField*	rampStartField;
	IBOutlet NSTextField*	stepSizeField;
	IBOutlet NSTextField*	attenuationField;
	IBOutlet NSButton*		lockButton;
	IBOutlet NSButton*		rampStartStopButton;
	IBOutlet NSButton*		loadAttenuationButton;
	IBOutlet NSProgressIndicator*		rampRunningProgress;
}

#pragma mark •••Notifications
- (void) rampValueChanged:(NSNotification*)aNote;
- (void) repeatRampChanged:(NSNotification*)aNote;
- (void) idleTimeChanged:(NSNotification*)aNote;
- (void) dwellTimeChanged:(NSNotification*)aNote;
- (void) rampEndChanged:(NSNotification*)aNote;
- (void) rampStartChanged:(NSNotification*)aNote;
- (void) stepSizeChanged:(NSNotification*)aNote;
- (void) attenuationChanged:(NSNotification*)aNote;
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) rampRunningChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) loadAttenuationAction:(id)sender;
- (IBAction) repeatRampAction:(id)sender;
- (IBAction) idleTimeAction:(id)sender;
- (IBAction) dwellTimeAction:(id)sender;
- (IBAction) rampEndAction:(id)sender;
- (IBAction) rampStartAction:(id)sender;
- (IBAction) stepSizeAction:(id)sender;
- (IBAction) attenuationAction:(id)sender;
- (IBAction) serialNumberAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;

#pragma mark ***Interface Management
- (void) populateInterfacePopup:(ORUSB*)usb;
- (void) validateInterfacePopup;

@end

