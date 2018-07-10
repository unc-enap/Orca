//
//  ORNHQ226LController.h
//  Orca
//
//  Created by Mark Howe on Tues Sept 14,2010.
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and Department sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORTimedTextField.h"

@interface ORNHQ226LController : OrcaObjectController {

	IBOutlet NSTextField*   portStateField;
    IBOutlet NSPopUpButton* portListPopup;
    IBOutlet NSButton*      openPortButton;
	IBOutlet NSTextField*	pollingErrorTextField;
	IBOutlet NSButton*		settingLockButton;
	IBOutlet NSTextField*	settingLockDocField;
	IBOutlet NSTextField*	setVoltageAField;
	IBOutlet NSTextField*	setVoltageBField;
	IBOutlet NSTextField*	actVoltageAField;
	IBOutlet NSTextField*	actVoltageBField;
	IBOutlet NSTextField*	actCurrentAField;
	IBOutlet NSTextField*	actCurrentBField;
	IBOutlet NSTextField*	maxCurrentAField;
	IBOutlet NSTextField*	maxCurrentBField;
	IBOutlet NSTextField*	setRampRateAField;
	IBOutlet NSTextField*	setRampRateBField;
	IBOutlet NSTextField*	currentTripAField2;
	IBOutlet NSTextField*	currentTripBField2;
	IBOutlet NSTextField*	polarityAField;
	IBOutlet NSTextField*	polarityBField;
	IBOutlet NSImageView*	hvStateAImage;
	IBOutlet NSImageView*	hvStateBImage;
	IBOutlet NSPopUpButton* pollTimePopup;
	IBOutlet NSButton*      initAButton;
	IBOutlet NSButton*      initBButton;
	IBOutlet NSButton*      panicAButton;
	IBOutlet NSButton*      panicBButton;
	IBOutlet NSButton*      stopAButton;
	IBOutlet NSButton*      stopBButton;
	IBOutlet NSButton*      systemPanicBButton;
	IBOutlet NSTextField*	manualAField;
	IBOutlet NSTextField*	manualBField;
	IBOutlet NSTextField*	hvPowerAField;
	IBOutlet NSTextField*	hvPowerBField;
	IBOutlet NSTextField*	killSwitchAField;
	IBOutlet NSTextField*	killSwitchBField;
	IBOutlet NSTextField*	statusAField;
	IBOutlet NSTextField*	statusBField;
	IBOutlet NSProgressIndicator*	pollingProgress;
	IBOutlet ORTimedTextField*	timeoutField;
}

- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) timedOut:(NSNotification*)aNote;
- (void) portNameChanged:(NSNotification*)aNote;
- (void) portStateChanged:(NSNotification*)aNote;
- (void) pollingErrorChanged:(NSNotification*)aNote;
- (void) statusReg1Changed:(NSNotification*)aNote;
- (void) statusReg2Changed:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) setVoltageChanged:(NSNotification*)aNote;
- (void) actVoltageChanged:(NSNotification*)aNote;
- (void) rampRateChanged:(NSNotification*)aNote;
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) actCurrentChanged:(NSNotification*)aNote;
- (void) maxCurrentChanged:(NSNotification*)aNote;
- (void) updateButtons;

#pragma mark •••Actions
- (IBAction) portListAction:(id) sender;
- (IBAction) openPortAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) setVoltageAction:(id)sender;
- (IBAction) maxCurrentAction:(id)sender;
- (IBAction) setRampRateAction:(id)sender;
- (IBAction) readModuleID:(id)sender;
- (IBAction) readStatus:(id)sender;
- (IBAction) loadAllValues:(id)sender;
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) stopHere:(id)sender;
- (IBAction) panic:(id)sender;
- (IBAction) systemPanic:(id)sender;
@end
