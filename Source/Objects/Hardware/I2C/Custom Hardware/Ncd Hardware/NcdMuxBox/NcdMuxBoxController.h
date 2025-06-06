//
//  NcdMuxBoxController.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Forward Declarations
@class ORValueBar;
@class ORCompositeValueBarView;
@class ORValueBarGroupView;

@interface NcdMuxBoxController : OrcaObjectController
{
    @private
		IBOutlet NSMatrix*	thresholdDacSteppers;
		IBOutlet NSMatrix*	thresholdDacTextFields;
		IBOutlet NSMatrix*	thresholdAdcTextFields;
		IBOutlet NSButton*	readThresholdsButton;
		IBOutlet NSButton*	initThresholdsButton;	
		IBOutlet NSButton*	pingButton;	
		IBOutlet NSTabView*	tabView;	

		IBOutlet NSTextField*   settingLockDocField;
		IBOutlet NSButton*      settingsLockButton;
		IBOutlet NSTextField*   calibrationLockDocField;
		IBOutlet NSButton*      calibrationLockButton;


		//rate page
		IBOutlet NSMatrix*      rateTextFields;
		IBOutlet NSMatrix*      countTextFields;
		IBOutlet NSStepper* 	integrationStepper;
		IBOutlet NSTextField* 	integrationText;
		IBOutlet NSTextField* 	totalRateText;

		//calibation page
		IBOutlet NSButton*      calibrateButton;
		IBOutlet NSMatrix*      calibrationEnabledMatrix;
		IBOutlet NSMatrix*      calibrationRateTextMatrix;
		IBOutlet NSMatrix*		calibrationThresholdMatrix;
		IBOutlet NSMatrix*		calibrationStateMatrix;
		IBOutlet NSStepper* 	calibrationFinalDeltaStepper;
		IBOutlet NSTextField* 	calibrationFinalDeltaTextField;
		IBOutlet NSButton*		enableAllButton;	
		IBOutlet NSButton*		enableNoneButton;	


		//testing page
		IBOutlet NSPopUpButton*	selectChannelPU;
		IBOutlet NSButton*	readAdcButton;	
		IBOutlet NSButton*	writeDacButton;	
		IBOutlet NSButton*	readEventRegButton;	
		IBOutlet NSButton*	reArmButton;	
		IBOutlet NSButton*	statusQueryButton;	
		IBOutlet NSButton*	testAdcDacButton;
		IBOutlet NSTextField*	dacValueField;	
		IBOutlet NSStepper*	dacValueStepper;	
		IBOutlet NSButton*      testLockButton;

		//tdb... fix the bar graph so it can be automatically put into a matrix
		IBOutlet ORValueBarGroupView*	rate0;
		IBOutlet ORValueBarGroupView*	totalRate;
		IBOutlet NSButton*      rateLogCB;
		IBOutlet NSButton*      totalRateLogCB;
		IBOutlet id				timeRatePlot;
		IBOutlet NSButton*      timeRateLogCB;

		IBOutlet NSTextField*   busNumberField;
		IBOutlet NSTextField*   boxNumberField;
		IBOutlet NSStepper*     scopeChanStepper;
		IBOutlet NSTextField*   scopeChanTextField;

		NSView *blankView;
		NSSize settingSize;
		NSSize rateSize;
		NSSize calibrationSize;
		NSSize testingSize;

}

#pragma mark ¥¥¥Interface Management
- (void) registerRates;
- (void) updateWindow;
- (void) registerNotificationObservers;
- (void) thresholdDacChanged:(NSNotification*)aNotification;
- (void) thresholdAdcArrayChanged:(NSNotification*)aNotification;
- (void) thresholdDacArrayChanged:(NSNotification*)aNotification;
- (void) connectionChanged: (NSNotification*) aNotification;

//rate page
- (void) rateChanged:(NSNotification*)aNotification;
- (void) totalRateChanged:(NSNotification*)aNotification;
- (void) rateGroupChanged:(NSNotification*)aNotification;
- (void) integrationChanged:(NSNotification*)aNotification;

- (void) scaleAction:(NSNotification*)aNotification;
- (void) rateAttributesChanged:(NSNotification*)aNote;
- (void) totalRateAttributesChanged:(NSNotification*)aNote;
- (void) timeRateXAttributesChanged:(NSNotification*)aNote;
- (void) timeRateYAttributesChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;

- (void) busNumberChanged:(NSNotification*)aNotification;
- (void) boxNumberChanged:(NSNotification*)aNotification;

//calibration page
- (void) channelChanged:(NSNotification*)aNotification;
- (void) dacValueChanged:(NSNotification*)aNotification;

- (void) thresholdDacArrayChanged:(NSNotification*)aNotification;
- (void) thresholdAdcArrayChanged:(NSNotification*)aNotification;
- (void) scopeChanChanged:(NSNotification*)aNotification;
- (void) settingsLockChanged:(NSNotification *)notification;
- (void) testLockChanged:(NSNotification *)notification;
- (void) calibrationLockChanged:(NSNotification *)notification;
- (void) calibrationEnabledMaskChanged:(NSNotification *)notification;
- (void) calibrationFinalDeltaChanged:(NSNotification *)notification;
- (void) calibrationStateChanged:(NSNotification*)aNotification;
- (void) calibrationStateLablesChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) thresholdDacAction:(id)sender;
- (IBAction) readThresholdAction:(id)sender;
- (IBAction) initThresholdAction:(id)sender;
- (IBAction) settingsLockAction:(id)sender;
- (IBAction) calibrationLockAction:(id)sender;
- (IBAction) testLockAction:(id)sender;

- (IBAction) integrationAction:(id)sender;
- (IBAction) rateUsesLogAction:(id)sender;
- (IBAction) totalRateUsesLogAction:(id)sender;
- (IBAction) timeRateUsesLogAction:(id)sender;
- (IBAction) ping:(id)sender;

- (IBAction) channelAction:(id)sender;
- (IBAction) dacValueAction:(id)sender;
- (IBAction) writeDacAction:(id)sender;
- (IBAction) readAdcAction:(id)sender;

- (IBAction) readEventRegAction:(id)sender;
- (IBAction) reArmAction:(id)sender;
- (IBAction) statusQueryAction:(id)sender;
- (IBAction) testAction:(id)sender;

- (IBAction) scopeChanAction:(id)sender;

- (IBAction) calibrateAction:(id)sender;
- (IBAction) calibrationEnabledAction:(id)sender;
- (IBAction) calibrationFinalDeltaAction:(id)sender;
- (IBAction) calibrationEnableAllAction:(id)sender;
- (IBAction) calibrationEnableNoneAction:(id)sender;


- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
@end
