//-------------------------------------------------------------------------
//  ORSIS3320Controller.h
//
//  Created by Mark A. Howe on Thursday 8/6/09
//  Copyright (c) 2009 Universiy of North Carolina. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "OrcaObjectController.h"
#import "ORSIS3320Model.h"
@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORSIS3320Controller : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
	IBOutlet NSButton*      lemoTimeStampClrEnabledCB;
	IBOutlet NSButton*      lemoTriggerEnabledCB;
	IBOutlet NSButton*      internalTriggerEnabledCB;
	IBOutlet NSButton*      resetButton;
	IBOutlet NSButton*      triggerButton;
	IBOutlet NSButton*      clearTimeStampButton;
	IBOutlet NSMatrix*		triggerGateLengthMatrix;
	IBOutlet NSMatrix*		preTriggerDelayMatrix;
	IBOutlet NSMatrix*      endAddressThresholdMatrix;

    IBOutlet NSMatrix*		onlineMaskMatrix;
    IBOutlet NSMatrix*      invertInputMatrix;
	IBOutlet NSMatrix*      enableErrorCorrectionMatrix;
	IBOutlet NSMatrix*      saveAlwaysMatrix;
	IBOutlet NSMatrix*      saveIfPileUpMatrix;
	IBOutlet NSMatrix*      saveFIRTriggerMatrix;
	IBOutlet NSMatrix*      saveFirstEventMatrix;
	IBOutlet NSMatrix*      bufferStartMatrix;
	IBOutlet NSMatrix*      bufferLengthMatrix;
	IBOutlet NSMatrix*      accGate1LengthMatrix;
	IBOutlet NSMatrix*      accGate1StartIndexMatrix;
	IBOutlet NSMatrix*      accGate2LengthMatrix;
	IBOutlet NSMatrix*      accGate2StartIndexMatrix;
	IBOutlet NSMatrix*      accGate3LengthMatrix;
	IBOutlet NSMatrix*      accGate3StartIndexMatrix;
	IBOutlet NSMatrix*      accGate4LengthMatrix;
	IBOutlet NSMatrix*      accGate4StartIndexMatrix;
	IBOutlet NSMatrix*      accGate5LengthMatrix;
	IBOutlet NSMatrix*      accGate5StartIndexMatrix;
	IBOutlet NSMatrix*      accGate6LengthMatrix;
	IBOutlet NSMatrix*      accGate6StartIndexMatrix;
	IBOutlet NSMatrix*      accGate7LengthMatrix;
	IBOutlet NSMatrix*      accGate7StartIndexMatrix;
	IBOutlet NSMatrix*      accGate8LengthMatrix;
	IBOutlet NSMatrix*      accGate8StartIndexMatrix;

	IBOutlet NSPopUpButton* clockSourcePU;
    IBOutlet NSButton*      briefReportButton;
    IBOutlet NSTextField*   firmwareVersionField;
	IBOutlet NSButton*		probeButton;
	IBOutlet NSButton*		regDumpButton;

	//base address
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;
	
	//Channel Parameters
	
	IBOutlet NSMatrix*		triggerModeMatrix;
	IBOutlet NSMatrix*		gtMatrix;
	IBOutlet NSMatrix*		triggerOutMatrix;
	IBOutlet NSMatrix*		extendedTriggerMatrix;

	IBOutlet NSMatrix*		dacValueMatrix;
	IBOutlet NSMatrix*		thresholdMatrix;
	IBOutlet NSMatrix*		trigPulseLenMatrix;
	IBOutlet NSMatrix*		sumGMatrix;
	IBOutlet NSMatrix*		peakingTimeMatrix;

    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      initButton;
    IBOutlet NSButton*      statusButton;

    //rate page
    IBOutlet NSMatrix*      rateTextFields;
    IBOutlet NSStepper*     integrationStepper;
    IBOutlet NSTextField*   integrationText;
    IBOutlet NSTextField*   totalRateText;

    IBOutlet ORValueBarGroupView*    rate0;
    IBOutlet ORValueBarGroupView*    totalRate;
    IBOutlet NSButton*      rateLogCB;
    IBOutlet NSButton*      totalRateLogCB;
    IBOutlet ORCompositeTimeLineView*    timeRatePlot;
    IBOutlet NSButton*      timeRateLogCB;
	
    NSView *blankView;
    NSSize settingSize;
    NSSize rateSize;
	
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) accGate1LengthChanged:(NSNotification*)aNote;
- (void) accGate1StartIndexChanged:(NSNotification*)aNote;
- (void) accGate2LengthChanged:(NSNotification*)aNote;
- (void) accGate2StartIndexChanged:(NSNotification*)aNote;
- (void) accGate3LengthChanged:(NSNotification*)aNote;
- (void) accGate3StartIndexChanged:(NSNotification*)aNote;
- (void) accGate4LengthChanged:(NSNotification*)aNote;
- (void) accGate4StartIndexChanged:(NSNotification*)aNote;
- (void) accGate5LengthChanged:(NSNotification*)aNote;
- (void) accGate5StartIndexChanged:(NSNotification*)aNote;
- (void) accGate6LengthChanged:(NSNotification*)aNote;
- (void) accGate6StartIndexChanged:(NSNotification*)aNote;
- (void) accGate7LengthChanged:(NSNotification*)aNote;
- (void) accGate7StartIndexChanged:(NSNotification*)aNote;
- (void) accGate8LengthChanged:(NSNotification*)aNote;
- (void) accGate8StartIndexChanged:(NSNotification*)aNote;

- (void) bufferStartChanged:(NSNotification*)aNote;
- (void) bufferLengthChanged:(NSNotification*)aNote;
- (void) invertInputChanged:(NSNotification*)aNote;
- (void) enableErrorCorrectionChanged:(NSNotification*)aNote;
- (void) saveAlwaysChanged:(NSNotification*)aNote;
- (void) saveIfPileUpChanged:(NSNotification*)aNote;
- (void) saveFIRTriggerChanged:(NSNotification*)aNote;
- (void) saveFirstEventChanged:(NSNotification*)aNote;
- (void) lemoTimeStampClrEnabledChanged:(NSNotification*)aNote;
- (void) lemoTriggerEnabledChanged:(NSNotification*)aNote;
- (void) internalTriggerEnabledChanged:(NSNotification*)aNote;
- (void) moduleIDChanged:(NSNotification*)aNote;
- (void) clockSourceChanged:(NSNotification*)aNote;
- (void) dacValueChanged:(NSNotification*)aNote;
- (void) triggerModeChanged:(NSNotification*)aNote;
- (void) triggerGateLengthChanged:(NSNotification*)aNote;
- (void) preTriggerDelayChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) trigPulseLenChanged:(NSNotification*)aNote;
- (void) sumGChanged:(NSNotification*)aNote;
- (void) peakingTimeChanged:(NSNotification*)aNote;
- (void) endAddressThresholdChanged:(NSNotification*)aNote;
- (void) onlineMaskChanged:(NSNotification*)aNote;



- (void) gtMaskChanged:(NSNotification*)aNote;
- (void) triggerOutMaskChanged:(NSNotification*)aNote;
- (void) extendedTriggerMaskChanged:(NSNotification*)aNote;

- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) registerRates;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;

- (void) integrationChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) onlineAction:(id)sender;
- (IBAction) accGate1LengthAction:(id)sender;
- (IBAction) accGate1StartIndexAction:(id)sender;
- (IBAction) accGate2LengthAction:(id)sender;
- (IBAction) accGate2StartIndexAction:(id)sender;
- (IBAction) accGate3LengthAction:(id)sender;
- (IBAction) accGate3StartIndexAction:(id)sender;
- (IBAction) accGate4LengthAction:(id)sender;
- (IBAction) accGate4StartIndexAction:(id)sender;
- (IBAction) accGate5LengthAction:(id)sender;
- (IBAction) accGate5StartIndexAction:(id)sender;
- (IBAction) accGate6LengthAction:(id)sender;
- (IBAction) accGate6StartIndexAction:(id)sender;
- (IBAction) accGate7LengthAction:(id)sender;
- (IBAction) accGate7StartIndexAction:(id)sender;
- (IBAction) accGate8LengthAction:(id)sender;
- (IBAction) accGate8StartIndexAction:(id)sender;

- (IBAction) bufferStartAction:(id)sender;
- (IBAction) bufferLengthAction:(id)sender;
- (IBAction) invertInputAction:(id)sender;
- (IBAction) enableErrorCorrectionAction:(id)sender;
- (IBAction) saveAlwaysAction:(id)sender;
- (IBAction) saveIfPileUpAction:(id)sender;
- (IBAction) saveFIRTriggerAction:(id)sender;
- (IBAction) saveFirstEventAction:(id)sender;
- (IBAction) lemoTimeStampClrEnabledAction:(id)sender;
- (IBAction) lemoTriggerEnabledAction:(id)sender;
- (IBAction) internalTriggerEnabledAction:(id)sender;
- (IBAction) dacValueAction:(id)sender;
- (IBAction) triggerAction:(id)sender;
- (IBAction) clearTimeStampButtonAction:(id)sender;
- (IBAction) triggerModeAction:(id)sender;
- (IBAction) triggerGateLengthAction:(id)sender;
- (IBAction) preTriggerDelayAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) gtAction:(id)sender;
- (IBAction) triggerAction:(id)sender;
- (IBAction) extendedTriggerAction:(id)sender;
- (IBAction) endAddressThresholdAction:(id)sender;

- (IBAction) clockSourceAction:(id)sender;
- (IBAction) regDump:(id)sender;

- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) integrationAction:(id)sender;

- (IBAction) triggerModeAction:(id)sender;
- (IBAction) gtAction:(id)sender;
- (IBAction) triggerOutAction:(id)sender;
- (IBAction) trigPulseLenAction:(id)sender;
- (IBAction) sumGAction:(id)sender;
- (IBAction) peakingTimeAction:(id)sender;
- (IBAction) scaleAction:(NSNotification*)aNote;

#pragma mark ***hardware actions
- (IBAction) reset:(id)sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) probeBoardAction:(id)sender;
- (IBAction) report:(id)sender;

#pragma mark •••Data Source and Delegate Actions
- (double)  getBarValue:(int)tag;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

@end
