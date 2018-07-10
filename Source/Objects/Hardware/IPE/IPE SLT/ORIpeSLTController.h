
//
//  ORIpeSLTController.h
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
#import "ORIpeSLTModel.h"

@interface ORIpeSLTController : OrcaObjectController {
	@private
		//control reg
		IBOutlet NSButton*		initBoardButton;
		IBOutlet NSButton*		initBoard1Button;
		IBOutlet NSButton*		readBoardButton;
		IBOutlet NSMatrix*		interruptMaskMatrix;
		IBOutlet NSTextField*	nHitThresholdField;
		IBOutlet NSStepper*		nHitThresholdStepper;
		IBOutlet NSTextField*	nHitField;
		IBOutlet NSStepper*		nHitStepper;
		IBOutlet NSPopUpButton* watchDogPU;
		IBOutlet NSPopUpButton* secStrobeSrcPU;
		IBOutlet NSPopUpButton* startSrcPU;
		IBOutlet NSMatrix*		triggerSrcMatrix;
		IBOutlet NSMatrix*		controlCheckBoxMatrix;
		IBOutlet NSMatrix*		inhibitCheckBoxMatrix;
		IBOutlet NSMatrix*		inhibitMaskMatrix;
		IBOutlet NSMatrix*		pageStatusMatrix;
		IBOutlet NSMatrix*		readAllMatrix;
		IBOutlet NSButton*		calibrateButton;
		IBOutlet NSTextField*   pageSizeField;
		IBOutlet NSStepper*     pageSizeStepper;
		IBOutlet NSButton*      displayTriggerButton;
		IBOutlet NSButton*      displayEventLoopButton;
		
		//status reg
		IBOutlet NSMatrix*		statusMatrix;
		IBOutlet NSTextField*	actualPageField;
		IBOutlet NSTextField*	nextPageField;
		IBOutlet NSButton*		releaseAllPagesButton;

		IBOutlet NSButton*		dumpROMButton;
		IBOutlet NSPopUpButton*	registerPopUp;
		IBOutlet NSStepper* 	regWriteValueStepper;
		IBOutlet NSTextField* 	regWriteValueTextField;
		IBOutlet NSButton*		regWriteButton;
		IBOutlet NSButton*		regReadButton;
		IBOutlet NSButton*		setSWInhibitButton;
		IBOutlet NSButton*		relSWInhibitButton;
		IBOutlet NSButton*		forceTriggerButton;
		IBOutlet NSButton*		forceTrigger1Button;

		IBOutlet NSButton*		versionButton;
		IBOutlet NSButton*		deadTimeButton;
		IBOutlet NSButton*		vetoTimeButton;
		IBOutlet NSButton*		resetHWButton;
		IBOutlet NSButton*		usePBusSimButton;
		IBOutlet NSTextField*	versionField;
		IBOutlet NSButton*		definePatternFileButton;
		IBOutlet NSTextField*	patternFilePathField;
		IBOutlet NSButton*		loadPatternFileButton;

		IBOutlet NSSlider*		nextPageDelaySlider;
		IBOutlet NSTextField*	nextPageDelayField;
		
        IBOutlet NSButton*		settingLockButton;

		//pulser
		IBOutlet NSTextField*	pulserAmpField;
		IBOutlet NSTextField*	pulserDelayField;


        IBOutlet NSPopUpButton*	pollRatePopup;
        IBOutlet NSProgressIndicator*	pollRunningIndicator;
		
		NSImage* xImage;
		NSImage* yImage;

};

#pragma mark ¥¥¥Initialization
- (id)   init;
- (void) dealloc;
- (void) awakeFromNib;


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) readAllChanged:(NSNotification*)aNote;
- (void) patternFilePathChanged:(NSNotification*)aNote;
- (void) interruptMaskChanged:(NSNotification*)aNote;
- (void) nextPageDelayChanged:(NSNotification*)aNote;
- (void) versionChanged:(NSNotification*)aNote;
- (void) nHitThresholdChanged:(NSNotification*)aNote;
- (void) nHitChanged:(NSNotification*)aNote;
- (void) pageSizeChanged:(NSNotification*)aNote;
- (void) displayEventLoopChanged:(NSNotification*)aNote;
- (void) displayTriggerChanged:(NSNotification*)aNote;
- (void) populatePullDown;
- (void) updateWindow;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) serviceChanged:(NSNotification*)aNote;
- (void) deviceOpenChanged:(NSNotification*)aNote;
- (void) pollRateChanged:(NSNotification*)aNote;
- (void) pollRunningChanged:(NSNotification*)aNote;

- (void) endAllEditing:(NSNotification*)aNote;
- (void) usePBusSimChanged:(NSNotification*)aNote;
- (void) controlRegChanged:(NSNotification*)aNote;
- (void) statusRegChanged:(NSNotification*)aNote;
- (void) selectedRegIndexChanged:(NSNotification*) aNote;
- (void) writeValueChanged:(NSNotification*) aNote;

- (void) pulserAmpChanged:(NSNotification*) aNote;
- (void) pulserDelayChanged:(NSNotification*) aNote;
- (void) pageStatusChanged:(NSNotification*)aNote;

- (void) enableRegControls;
- (void) dumpPageStatus:(id)sender;

#pragma mark ¥¥¥Actions
- (IBAction) readAllAction:(id)sender;
- (IBAction) setSWInhibitAction:(id)sender;
- (IBAction) releaseSWInhibitAction:(id)sender;
- (IBAction) releaseAllPagesAction:(id)sender;
- (IBAction) pollRateAction:(id)sender;
- (IBAction) pollNowAction:(id)sender;
- (IBAction) readStatus:(id)sender;
- (IBAction) triggerSourceAction:(id)sender;
- (IBAction) nextPageDelayAction:(id)sender;
- (IBAction) interruptMaskAction:(id)sender;
- (IBAction) nHitThresholdAction:(id)sender;
- (IBAction) nHitAction:(id)sender;
- (IBAction) pageSizeAction:(id)sender;
- (IBAction) displayTriggerAction:(id)sender;
- (IBAction) displayEventLoopAction:(id)sender;
- (IBAction) usePBusSimAction:(id) sender;
- (IBAction) controlCheckBoxAction:(id) sender;
- (IBAction) inhibitCheckBoxAction:(id) sender;
- (IBAction) settingLockAction:(id) sender;
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
- (IBAction) initBoardAction:(id)sender;
- (IBAction) reportAllAction:(id)sender;
- (IBAction) definePatternFileAction:(id)sender;
- (IBAction) loadPatternFile:(id)sender;
- (IBAction) forceTrigger:(id)sender;
- (IBAction) calibrateAction:(id)sender;

@end
