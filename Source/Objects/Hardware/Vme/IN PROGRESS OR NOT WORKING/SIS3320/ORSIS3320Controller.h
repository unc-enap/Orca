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
@class ORValueBar;
@class ORPlotView;

@interface ORSIS3320Controller : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
	IBOutlet NSTextField*	sampleStartAddressField;
	IBOutlet NSTextField*	sampleLengthField;
//	IBOutlet NSButton*		shiftAccumBy4Button;
	IBOutlet NSButton*		enableUserInAccumGateButton;
	IBOutlet NSButton*		enableUserInDataStreamButton;
//	IBOutlet NSButton*		enableAccumModeButton;
	IBOutlet NSButton*		enableSampleLenStopButton;
	IBOutlet NSButton*		enablePageWrapButton;
	IBOutlet NSPopUpButton* pageWrapSizePU;
	IBOutlet NSTextField*	stopDelayField;
	IBOutlet NSTextField*	startDelayField;
	IBOutlet NSButton*		lemoStartStopLogicButton;
	IBOutlet NSButton*		internalTriggerAsStopButton;
	IBOutlet NSButton*		autoStartModeButton;
	IBOutlet NSTextField*	maxNumEventsField;
	IBOutlet NSButton*		multiEventCB;
	IBOutlet NSPopUpButton* clockSourcePU;
	
	//base address
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;
	
	//Channel Parameters
	
	IBOutlet NSMatrix*		triggerModeMatrix;
	IBOutlet NSMatrix*		gtMatrix;
	IBOutlet NSMatrix*		ltMatrix;
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

    IBOutlet ORValueBar*    rate0;
    IBOutlet ORValueBar*    totalRate;
    IBOutlet NSButton*      rateLogCB;
    IBOutlet NSButton*      totalRateLogCB;
    IBOutlet ORPlotView*    timeRatePlot;
    IBOutlet NSButton*      timeRateLogCB;
	IBOutlet NSTextField*	moduleIDField;
	
    NSView *blankView;
    NSSize settingSize;
    NSSize rateSize;
	
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) sampleStartAddressChanged:(NSNotification*)aNote;
- (void) sampleLengthChanged:(NSNotification*)aNote;
- (void) enableUserInAccumGateChanged:(NSNotification*)aNote;
- (void) enableUserInDataStreamChanged:(NSNotification*)aNote;
- (void) enableSampleLenStopChanged:(NSNotification*)aNote;
- (void) enablePageWrapChanged:(NSNotification*)aNote;
- (void) pageWrapSizeChanged:(NSNotification*)aNote;
- (void) stopDelayChanged:(NSNotification*)aNote;
- (void) startDelayChanged:(NSNotification*)aNote;
- (void) lemoStartStopLogicChanged:(NSNotification*)aNote;
- (void) internalTriggerAsStopChanged:(NSNotification*)aNote;
- (void) autoStartModeChanged:(NSNotification*)aNote;
- (void) gtMaskChanged:(NSNotification*)aNote;
- (void) ltMaskChanged:(NSNotification*)aNote;
- (void) triggerModeMaskChanged:(NSNotification*)aNote;

- (void) maxNumEventsChanged:(NSNotification*)aNote;
- (void) multiEventChanged:(NSNotification*)aNote;
- (void) clockSourceChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) registerRates;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) dacValueChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) moduleIDChanged:(NSNotification*)aNote;
- (void) trigPulseLenChanged:(NSNotification*)aNote;
- (void) sumGChanged:(NSNotification*)aNote;
- (void) peakingTimeChanged:(NSNotification*)aNote;

- (void) integrationChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) sampleStartAddressAction:(id)sender;
- (IBAction) sampleLengthAction:(id)sender;
//- (IBAction) shiftAccumBy4Action:(id)sender;
- (IBAction) enableUserInAccumGateAction:(id)sender;
- (IBAction) enableUserInDataStreamAction:(id)sender;
//- (IBAction) enableAccumModeAction:(id)sender;
- (IBAction) enableSampleLenStopAction:(id)sender;
- (IBAction) enablePageWrapAction:(id)sender;
- (IBAction) pageWrapSizeAction:(id)sender;
- (IBAction) stopDelayAction:(id)sender;
- (IBAction) startDelayAction:(id)sender;
- (IBAction) lemoStartStopLogicAction:(id)sender;
- (IBAction) internalTriggerAsStopAction:(id)sender;
- (IBAction) autoStartModeAction:(id)sender;

- (IBAction) report:(id)sender;
- (IBAction) maxNumEventsAction:(id)sender;
- (IBAction) multiEventAction:(id)sender;
- (IBAction) clockSourceAction:(id)sender;

- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) integrationAction:(id)sender;
- (IBAction) probeBoardAction:(id)sender;

- (IBAction) triggerModeAction:(id)sender;
- (IBAction) gtAction:(id)sender;
- (IBAction) ltAction:(id)sender;
- (IBAction) dacValueAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) trigPulseLenAction:(id)sender;
- (IBAction) sumGAction:(id)sender;
- (IBAction) peakingTimeAction:(id)sender;
- (IBAction) scaleAction:(NSNotification*)aNote;

#pragma mark •••Data Source
- (double)  getBarValue:(int)tag;
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

#pragma mark •••Data Source For Plots
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
