//-------------------------------------------------------------------------
//  ORSIS3350Controller.h
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
#import "ORSIS3350Model.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORSIS3350Controller : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
	IBOutlet NSTextField*	endAddressThresholdField;
	IBOutlet NSTextField*	ringBufferPreDelayField;
	IBOutlet NSTextField*	ringBufferLenField;
	IBOutlet NSTextField*	gateSyncExtendLengthField;
	IBOutlet NSTextField*	gateSyncLimitLengthField;
	IBOutlet NSTextField*	maxNumEventsField;
	IBOutlet NSPopUpButton*	freqNPU;
	IBOutlet NSTextField*	freqMField;
	IBOutlet NSTextField*	memoryWrapLengthField;
	IBOutlet NSTextField*	memoryStartModeLengthField;
	IBOutlet NSTextField*	memoryTriggerDelayField;
	IBOutlet NSButton*		invertLemoCB;
	IBOutlet NSButton*		multiEventCB;
	IBOutlet NSMatrix*		triggerMaskMatrix;
	IBOutlet NSPopUpButton* clockSourcePU;
	IBOutlet NSPopUpButton* operationModePU;
	
	//base address
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;
	
	//Channel Parameters
	IBOutlet NSPopUpButton*	triggerModePU0;
	IBOutlet NSPopUpButton*	triggerModePU1;
	IBOutlet NSPopUpButton*	triggerModePU2;
	IBOutlet NSPopUpButton*	triggerModePU3;	
	NSPopUpButton* triggerModePU[kNumSIS3350Channels];////arggg -- can't put popup's in a matrix for some reason
	
	IBOutlet NSMatrix*		gainMatrix;
	IBOutlet NSMatrix*		dacValueMatrix;
	IBOutlet NSMatrix*		thresholdMatrix;
	IBOutlet NSMatrix*		thresholdOffMatrix;
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

    IBOutlet ORValueBarGroupView*		rate0;
    IBOutlet ORValueBarGroupView*		totalRate;
    IBOutlet NSButton*					rateLogCB;
    IBOutlet NSButton*					totalRateLogCB;
    IBOutlet ORCompositeTimeLineView*   timeRatePlot;
    IBOutlet NSButton*					timeRateLogCB;
	IBOutlet NSTextField*				moduleIDField;

	//labels
	IBOutlet NSTextField*	thresholdOnLabel;
	IBOutlet NSTextField*	thresholdOffLabel;
	
    NSView *blankView;
    NSSize settingSize;
    NSSize rateSize;
	
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) memoryWrapLengthChanged:(NSNotification*)aNote;
- (void) endAddressThresholdChanged:(NSNotification*)aNote;
- (void) ringBufferPreDelayChanged:(NSNotification*)aNote;
- (void) ringBufferLenChanged:(NSNotification*)aNote;
- (void) gateSyncExtendLengthChanged:(NSNotification*)aNote;
- (void) gateSyncLimitLengthChanged:(NSNotification*)aNote;
- (void) maxNumEventsChanged:(NSNotification*)aNote;
- (void) freqNChanged:(NSNotification*)aNote;
- (void) freqMChanged:(NSNotification*)aNote;
- (void) memoryStartModeLengthChanged:(NSNotification*)aNote;
- (void) memoryTriggerDelayChanged:(NSNotification*)aNote;
- (void) invertLemoChanged:(NSNotification*)aNote;
- (void) multiEventChanged:(NSNotification*)aNote;
- (void) triggerMaskChanged:(NSNotification*)aNote;
- (void) clockSourceChanged:(NSNotification*)aNote;
- (void) operationModeChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) registerRates;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) triggerModeChanged:(NSNotification*)aNote;
- (void) gainChanged:(NSNotification*)aNote;
- (void) dacValueChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) thresholdOffChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) moduleIDChanged:(NSNotification*)aNote;
- (void) trigPulseLenChanged:(NSNotification*)aNote;
- (void) sumGChanged:(NSNotification*)aNote;
- (void) peakingTimeChanged:(NSNotification*)aNote;

- (void) integrationChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) report:(id)sender;
- (IBAction) memoryWrapLengthAction:(id)sender;
- (IBAction) fire:(id)sender;
- (IBAction) endAddressThresholdAction:(id)sender;
- (IBAction) ringBufferPreDelayAction:(id)sender;
- (IBAction) ringBufferLenAction:(id)sender;
- (IBAction) gateSyncExtendLengthAction:(id)sender;
- (IBAction) gateSyncLimitLengthAction:(id)sender;
- (IBAction) maxNumEventsAction:(id)sender;
- (IBAction) freqNAction:(id)sender;
- (IBAction) freqMAction:(id)sender;
- (IBAction) memoryStartModeLengthAction:(id)sender;
- (IBAction) memoryTriggerDelayAction:(id)sender;
- (IBAction) invertLemoAction:(id)sender;
- (IBAction) multiEventAction:(id)sender;
- (IBAction) triggerMaskAction:(id)sender;
- (IBAction) clockSourceAction:(id)sender;
- (IBAction) operationModeAction:(id)sender;

- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) integrationAction:(id)sender;
- (IBAction) probeBoardAction:(id)sender;

- (IBAction) triggerModeAction:(id)sender;
- (IBAction) gainAction:(id)sender;
- (IBAction) dacValueAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) thresholdOffAction:(id)sender;
- (IBAction) trigPulseLenAction:(id)sender;
- (IBAction) sumGAction:(id)sender;
- (IBAction) peakingTimeAction:(id)sender;

- (IBAction) readTemperatureAction:(id)sender;

#pragma mark •••Data Source
- (double)  getBarValue:(int)tag;
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

#pragma mark •••Data Source For Plots
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
