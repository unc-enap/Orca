//
//ORCaen1724Controller.h
//Orca
//
//Created by Mark Howe on Mon Mar 14, 2011.
//Copyright (c) 2011 University of North Carolina. All rights reserved.
//
//-------------------------------------------------------------
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
#pragma mark •••Imported Files
#import "OrcaObjectController.h"

@class ORValueBar;
@class ORPlotView;

@interface ORCaen1724Controller : OrcaObjectController {
    IBOutlet NSTabView* 	tabView;
    IBOutlet NSStepper* 	addressStepper;
    IBOutlet NSTextField* 	addressTextField;
    IBOutlet NSStepper* 	writeValueStepper;
    IBOutlet NSTextField* 	writeValueTextField;
    IBOutlet NSPopUpButton*	registerAddressPopUp;
    IBOutlet NSPopUpButton*	channelPopUp;
    IBOutlet NSTextField*   basicLockDocField;
    IBOutlet NSButton*		basicWriteButton;
    IBOutlet NSButton*		basicReadButton;

	IBOutlet NSTextField*	regNameField;
    IBOutlet NSTextField*	drTextField;
    IBOutlet NSTextField*	srTextField;
    IBOutlet NSTextField*	hrTextField;
    IBOutlet NSTextField*	registerOffsetTextField;
    IBOutlet NSTextField*	registerReadWriteTextField;


    IBOutlet NSMatrix*		thresholdMatrix;
    IBOutlet NSButton*		softwareTriggerButton;
	IBOutlet NSMatrix*		enabledMaskMatrix;
	IBOutlet NSMatrix*		chanTriggerMatrix;
	IBOutlet NSMatrix*		otherTriggerMatrix;
	IBOutlet NSTextField*	postTriggerSettingTextField;
	IBOutlet NSMatrix*		triggerSourceMaskMatrix;
	IBOutlet NSTextField*	coincidenceLevelTextField;
    IBOutlet NSMatrix*		dacMatrix;
	IBOutlet NSMatrix*		acquisitionModeMatrix;
	IBOutlet NSMatrix*		countAllTriggersMatrix;
	IBOutlet NSTextField*	customSizeTextField;
	IBOutlet NSButton*	fixedSizeButton;
	IBOutlet NSMatrix*		channelConfigMaskMatrix;
    IBOutlet NSMatrix*		overUnderMatrix;
	IBOutlet NSPopUpButton* eventSizePopUp;
	IBOutlet NSTextField*	eventSizeTextField;
    IBOutlet NSTextField*	slotField;
    IBOutlet NSTextField*	slot1Field;
	
    IBOutlet NSButton*		initButton;
    IBOutlet NSButton*		reportButton;
    IBOutlet NSButton*		loadThresholdsButton;
	
	//rates page
	IBOutlet NSMatrix*      rateTextFields;
    IBOutlet NSStepper*     integrationStepper;
    IBOutlet NSTextField*   integrationText;
    IBOutlet NSTextField*   totalRateText;
    IBOutlet NSMatrix*      enabled2MaskMatrix;

    IBOutlet ORValueBar*    rate0;
    IBOutlet ORValueBar*    totalRate;
    IBOutlet NSButton*      rateLogCB;
    IBOutlet NSButton*      totalRateLogCB;
    IBOutlet ORPlotView*    timeRatePlot;
    IBOutlet NSButton*      timeRateLogCB;
    IBOutlet NSTextField*   bufferStateField;

	
    IBOutlet NSButton*		basicLockButton;
    IBOutlet NSButton*		settingsLockButton;
	IBOutlet NSTextField*   settingsLockDocField;


    NSView *blankView;
    NSSize basicSize;
    NSSize settingsSize;
    NSSize monitoringSize;

}

#pragma mark ***Initialization
- (id)		init;
 	
#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) registerRates;

#pragma mark ***Interface Management
- (void) eventSizeChanged:(NSNotification*)aNote;
- (void) updateWindow;
- (void) integrationChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*) aNote;
- (void) writeValueChanged: (NSNotification*) aNote;
- (void) selectedRegIndexChanged: (NSNotification*) aNote;
- (void) selectedRegChannelChanged:(NSNotification*) aNote;
- (void) enabledMaskChanged:(NSNotification*)aNote;
- (void) postTriggerSettingChanged:(NSNotification*)aNote;
- (void) triggerSourceMaskChanged:(NSNotification*)aNote;
- (void) coincidenceLevelChanged:(NSNotification*)aNote;
- (void) basicLockChanged:(NSNotification*)aNote;
- (void) acquisitionModeChanged:(NSNotification*)aNote;
- (void) countAllTriggersChanged:(NSNotification*)aNote;
- (void) customSizeChanged:(NSNotification*)aNote;
- (void) isFixedSizeChanged:(NSNotification*)aNote;
- (void) channelConfigMaskChanged:(NSNotification*)aNote;
- (void) dacChanged: (NSNotification*) aNote;
- (void) overUnderChanged: (NSNotification*) aNote;
- (void) basicLockChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) thresholdChanged: (NSNotification*) aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) setBufferStateLabel;

#pragma mark •••Actions
- (IBAction) eventSizeAction:(id)sender;
- (IBAction) integrationAction:(id)sender;
- (IBAction) baseAddressAction: (id) aSender;
- (IBAction) writeValueAction: (id) aSender;
- (IBAction) selectRegisterAction: (id) aSender;
- (IBAction) selectChannelAction: (id) aSender;

- (IBAction) basicRead: (id) sender;
- (IBAction) basicWrite: (id) sender;
- (IBAction) basicLockAction:(id)sender;
- (IBAction) settingsLockAction:(id)sender;

- (IBAction) report: (id) sender;
- (IBAction) initBoard: (id) sender;
- (IBAction) loadThresholds: (id) sender;
- (IBAction) enabledMaskAction:(id)sender;
- (IBAction) postTriggerSettingTextFieldAction:(id)sender;
- (IBAction) triggerSourceMaskAction:(id)sender;
- (IBAction) coincidenceLevelTextFieldAction:(id)sender;
- (IBAction) generateTriggerAction:(id)sender;
- (IBAction) acquisitionModeAction:(id)sender;
- (IBAction) countAllTriggersAction:(id)sender;
- (IBAction) customSizeAction:(id)sender;
- (IBAction) isFixedSizeAction:(id)sender;
- (IBAction) channelConfigMaskAction:(id)sender;
- (IBAction) dacAction: (id) aSender;
- (IBAction) thresholdAction: (id) aSender;
- (IBAction) overUnderAction: (id) aSender;

#pragma mark •••Misc Helpers
- (void)    populatePullDown;
- (void)    updateRegisterDescription: (short) aRegisterIndex;
- (void)    tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

#pragma mark •••Data Source
- (double) getBarValue:(int)tag;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;


@end
