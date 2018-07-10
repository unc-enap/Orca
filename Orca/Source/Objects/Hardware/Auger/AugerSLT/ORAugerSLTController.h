
//
//  ORAugerSLTController.h
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORAugerSLTModel.h"

@interface ORAugerSLTController : OrcaObjectController {
	@private
		//control reg
		IBOutlet NSButton*		readControlButton;
		IBOutlet NSTextField*	nHitThresholdField;
		IBOutlet NSStepper*		nHitThresholdStepper;
		IBOutlet NSTextField*	nHitField;
		IBOutlet NSStepper*		nHitStepper;
		IBOutlet NSButton*		writeControlButton;
		IBOutlet NSPopUpButton* watchDogPU;
		IBOutlet NSPopUpButton* secStrobeSrcPU;
		IBOutlet NSPopUpButton* startSrcPU;
		IBOutlet NSPopUpButton* triggerSrcPU;
		IBOutlet NSMatrix*		controlCheckBoxMatrix;
		IBOutlet NSMatrix*		inhibitCheckBoxMatrix;

		//status reg
		IBOutlet NSButton*		readStatusButton;
		IBOutlet NSMatrix*		statusCheckBoxMatrix;

		IBOutlet NSButton*		dumpROMButton;
		IBOutlet NSPopUpButton*	registerPopUp;
		IBOutlet NSStepper* 	regWriteValueStepper;
		IBOutlet NSTextField* 	regWriteValueTextField;
		IBOutlet NSButton*		regWriteButton;
		IBOutlet NSButton*		regReadButton;

		IBOutlet NSButton*		versionButton;
		IBOutlet NSButton*		deadTimeButton;
		IBOutlet NSButton*		vetoTimeButton;
		IBOutlet NSButton*		resetHWButton;
		IBOutlet NSButton*		usePBusSimButton;
		IBOutlet NSTextField*	versionField;
		
        IBOutlet NSButton*		settingLockButton;

		//pulser
		IBOutlet NSTextField*	pulserAmpField;
		IBOutlet NSTextField*	pulserDelayField;

};

#pragma mark ¥¥¥Initialization
- (id)   init;
- (void) dealloc;
- (void) awakeFromNib;


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) nHitThresholdChanged:(NSNotification*)aNote;
- (void) nHitChanged:(NSNotification*)aNote;
- (void) populatePullDown;
- (void) updateWindow;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) serviceChanged:(NSNotification*)aNote;
- (void) deviceOpenChanged:(NSNotification*)aNote;

- (void) endAllEditing:(NSNotification*)aNote;
- (void) usePBusSimChanged:(NSNotification*)aNote;
- (void) controlRegChanged:(NSNotification*)aNote;
- (void) statusRegChanged:(NSNotification*)aNote;
- (void) selectedRegIndexChanged:(NSNotification*) aNote;
- (void) writeValueChanged:(NSNotification*) aNote;

- (void) pulserAmpChanged:(NSNotification*) aNote;
- (void) pulserDelayChanged:(NSNotification*) aNote;

- (void) enableRegControls;

#pragma mark ¥¥¥Actions
- (IBAction) nHitThresholdAction:(id)sender;
- (IBAction) nHitAction:(id)sender;
- (IBAction) usePBusSimAction:(id) sender;
- (IBAction) controlCheckBoxAction:(id) sender;
- (IBAction) inhibitCheckBoxAction:(id) sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) readControlButtonAction:(id)sender;
- (IBAction) writeControlButtonAction:(id)sender;
- (IBAction) readStatusButtonAction:(id)sender;
- (IBAction) dumpROMAction:(id)sender;
- (IBAction) controlRegAction:(id)sender;
- (IBAction) selectRegisterAction:(id) sender;
- (IBAction) writeValueAction:(id) sender;
- (IBAction) readRegAction: (id) sender;
- (IBAction) writeRegAction: (id) sender;
- (IBAction) versionAction: (id) sender;
- (IBAction) deadTimeAction: (id) sender;
- (IBAction) vetoTimeAction: (id) sender;
- (IBAction) resetHWAction: (id) sender;
- (IBAction) pulserAmpAction: (id) sender;
- (IBAction) pulserDelayAction: (id) sender;
- (IBAction) pulseOnceAction: (id) sender;
- (IBAction) loadPulserAction: (id) sender;

@end