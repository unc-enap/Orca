//
//  ORDT5720Controller.h
//  Orca
//
//  Created by Mark Howe on Wed Mar 12,2014.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina at the Center sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORHPPulserController.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;
@class ORSafeCircularBuffer;
@class ORQueueView;

@interface ORDT5720Controller : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
	IBOutlet NSPopUpButton* serialNumberPopup;
    IBOutlet NSMatrix*		enabledMaskMatrix;
    
    IBOutlet NSMatrix*      logicTypeMatrix;
    IBOutlet NSMatrix*		zsThresholdMatrix;
    IBOutlet NSMatrix*		numOverUnderZsThresholdMatrix;
    IBOutlet NSMatrix*		nLbkMatrix;
    IBOutlet NSMatrix*		nLfwdMatrix;
    IBOutlet NSMatrix*		thresholdMatrix;
    IBOutlet NSMatrix*		numOverUnderThresholdMatrix;
    IBOutlet NSMatrix*		dacMatrix;
    IBOutlet NSPopUpButton* zsAlgorithmPU;
    IBOutlet NSButton*      packedCB;

    IBOutlet NSMatrix*      trigOnUnderThresholdMatrix;
    IBOutlet NSButton*      testPatternEnabledButton;
    IBOutlet NSButton*      trigOverlapEnabledButton;
    IBOutlet NSPopUpButton* eventSizePopUp;
    IBOutlet NSTextField*	eventSizeTextField;

    IBOutlet NSTextField*	postTriggerSettingTextField;
    IBOutlet NSMatrix*		triggerSourceEnableMaskMatrix;
    IBOutlet NSMatrix*		triggerOutMatrix;
    IBOutlet NSTextField*	coincidenceLevelTextField;

    IBOutlet NSPopUpButton* clockSourcePU;
    IBOutlet NSMatrix*		countAllTriggersMatrix;

	IBOutlet NSMatrix*      ttlEnabledMatrix;
	IBOutlet NSMatrix*      gpoEnabledMatrix;
	IBOutlet NSButton*      fpSoftwareTrigEnabledButton;
	IBOutlet NSButton*      fpExternalTrigEnabledButton;
	IBOutlet NSButton*      externalTrigEnabledButton;
	IBOutlet NSButton*      softwareTrigEnabledButton;
	IBOutlet NSMatrix*      gpiRunModeMatrix;
 
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
    
    
    IBOutlet NSButton*		softwareTriggerButton;
	
    IBOutlet NSButton*		initButton;
    IBOutlet NSButton*		reportButton;
	
	//rates page
	IBOutlet NSMatrix*      rateTextFields;
    IBOutlet NSStepper*     integrationStepper;
    IBOutlet NSTextField*   integrationText;
    IBOutlet NSTextField*   totalRateText;
    IBOutlet NSMatrix*      enabled2MaskMatrix;
    
    IBOutlet ORValueBarGroupView*     rate0;
    IBOutlet ORValueBarGroupView*     totalRate;
    IBOutlet NSButton*                rateLogCB;
    IBOutlet NSButton*                totalRateLogCB;
    IBOutlet ORCompositeTimeLineView* timeRatePlot;
    IBOutlet NSButton*                timeRateLogCB;
    IBOutlet NSTextField*             bufferStateField;
    IBOutlet NSTextField*             transferRateField;
    IBOutlet NSButton*		basicLockButton;
    IBOutlet NSButton*		lowLevelLockButton;
    IBOutlet ORQueueView*   queView;
    
    
    NSView *blankView;
    NSSize lowLevelSize;
    NSSize basicSize;
    NSSize monitoringSize;
}

#pragma mark •••Initialization
- (id) init;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) registerRates;
- (void) updateWindow;
- (void) validateInterfacePopup;

#pragma mark ***Interface Management
- (void) logicTypeChanged:(NSNotification*)aNote;
- (void) zsThresholdChanged: (NSNotification*) aNote;
- (void) numOverUnderZsThresholdChanged: (NSNotification*) aNote;
- (void) nlbkChanged:(NSNotification*) aNote;
- (void) nlfwdChanged:(NSNotification*) aNote;
- (void) thresholdChanged: (NSNotification*) aNote;
- (void) numOverUnderThresholdChanged: (NSNotification*) aNote;
- (void) dacChanged: (NSNotification*) aNote;
- (void) zsAlgorithmChanged:(NSNotification*)aNote;
- (void) packedChanged:(NSNotification*)aNote;
- (void) trigOnUnderThresholdChanged:(NSNotification*)aNote;
- (void) testPatternEnabledChanged:(NSNotification*)aNote;
- (void) trigOverlapEnabledChanged:(NSNotification*)aNote;
- (void) eventSizeChanged:(NSNotification*)aNote;
- (void) clockSourceChanged:(NSNotification*)aNote;
- (void) countAllTriggersChanged:(NSNotification*)aNote;
- (void) gpiRunModeChanged:(NSNotification*)aNote;
- (void) softwareTrigEnabledChanged:(NSNotification*)aNote;
- (void) externalTrigEnabledChanged:(NSNotification*)aNote;
- (void) coincidenceLevelChanged:(NSNotification*)aNote;
- (void) triggerSourceEnableMaskChanged:(NSNotification*)aNote;
- (void) fpExternalTrigEnabledChanged:(NSNotification*)aNote;
- (void) fpSoftwareTrigEnabledChanged:(NSNotification*)aNote;
- (void) postTriggerSettingChanged:(NSNotification*)aNote;
- (void) triggerOutMaskChanged:(NSNotification*)aNote;
- (void) gpoEnabledChanged:(NSNotification*)aNote;
- (void) ttlEnabledChanged:(NSNotification*)aNote;
- (void) enabledMaskChanged:(NSNotification*)aNote;

- (void) scaleAction:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) integrationChanged:(NSNotification*)aNote;
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;

- (void) writeValueChanged: (NSNotification*) aNote;
- (void) selectedRegIndexChanged: (NSNotification*) aNote;
- (void) selectedRegChannelChanged:(NSNotification*) aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;

- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) basicLockChanged:(NSNotification*)aNote;
- (void) lowLevelLockChanged:(NSNotification*)aNote;

- (void) setStatusStrings;

#pragma mark •••Actions
- (IBAction) serialNumberAction:(id)sender;
- (IBAction) logicTypeAction:(id)sender;
- (IBAction) zsThresholdAction: (id) sender;
- (IBAction) numOverUnderZsThresholdAction: (id) sender;
- (IBAction) nLbkAction: (id) sender;
- (IBAction) nLfwdAction: (id) sender;
- (IBAction) thresholdAction: (id) sender;
- (IBAction) numOverUnderThresholdAction: (id) sender;
- (IBAction) dacAction: (id) sender;
- (IBAction) zsAlgorithmAction:(id)sender;
- (IBAction) packedAction:(id)sender;
- (IBAction) trigOnUnderThresholdAction:(id)sender;
- (IBAction) testPatternEnabledAction:(id)sender;
- (IBAction) trigOverlapEnabledAction:(id)sender;
- (IBAction) eventSizeAction:(id)sender;
- (IBAction) clockSourceAction:(id)sender;
- (IBAction) countAllTriggersAction:(id)sender;
- (IBAction) gpiRunModeAction:(id)sender;
- (IBAction) externalTrigEnabledAction:(id)sender;
- (IBAction) softwareTrigEnabledAction:(id)sender;
- (IBAction) softwareTrigEnabledAction:(id)sender;
- (IBAction) externalTrigEnabledAction:(id)sender;
- (IBAction) coincidenceLevelAction:(id)sender;
- (IBAction) triggerSourceEnableMaskAction:(id)sender;
- (IBAction) fpExternalTrigEnabledAction:(id)sender;
- (IBAction) fpSoftwareTrigEnabledAction:(id)sender;
- (IBAction) triggerOutMaskAction:(id)sender;
- (IBAction) postTriggerSettingAction:(id)sender;
- (IBAction) ttlEnabledAction:(id)sender;
- (IBAction) gpoEnabledAction:(id)sender;
- (IBAction) enabledMaskAction:(id)sender;

- (IBAction) writeValueAction: (id) sender;
- (IBAction) selectRegisterAction: (id) sender;
- (IBAction) selectChannelAction: (id) sender;
- (IBAction) basicReadAction: (id) sender;
- (IBAction) basicWriteAction: (id) sender;

- (IBAction) lowLevelLockAction:(id) sender;
- (IBAction) basicLockAction:(id)sender;

- (IBAction) reportAction: (id) sender;
- (IBAction) initBoardAction: (id) sender;
- (IBAction) generateTriggerAction:(id)sender;
- (IBAction) integrationAction:(id)sender;

#pragma mark •••Misc Helpers
- (void)    populatePullDown;
- (void)    updateRegisterDescription: (short) aRegisterIndex;
- (void)    tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

#pragma mark •••Data Source
- (double) getBarValue:(int)tag;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

- (void) getQueMinValue:(uint32_t*)aMinValue maxValue:(uint32_t*)aMaxValue head:(uint32_t*)aHeadValue tail:(uint32_t*)aTailValue;

@end


