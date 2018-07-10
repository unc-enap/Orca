//
//  ORShaperController.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 16 2002.
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


@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORShaperController : OrcaObjectController {

    IBOutlet NSTabView*		tabView;
	IBOutlet NSButton*		shipTimeStampCB;
    IBOutlet NSTextField*   slotField;
    IBOutlet NSStepper* 	addressStepper;
    IBOutlet NSTextField* 	addressText;
    IBOutlet NSMatrix*		thresholdSteppers;
    IBOutlet NSMatrix*		thresholdTextFields;
    IBOutlet NSMatrix*		gainSteppers;
    IBOutlet NSMatrix*		gainTextFields;
    IBOutlet NSButton*		continousModeCB;
    IBOutlet NSButton*		enableScalersCB;
    IBOutlet NSButton*		enableMultiBoardCB;
    IBOutlet NSMatrix*		scalerMaskMatrix;
    IBOutlet NSButton* 		displayRawCB;
    IBOutlet NSTextField* 	thresholdLabel;
    IBOutlet NSButton*		initButton;
    IBOutlet NSButton*		settingLockButton;
    IBOutlet NSTextField*   settingLockDocField;
    IBOutlet NSMatrix*		online1MaskMatrix;

    //scan page
    IBOutlet NSTextField*       scanStartField;
    IBOutlet NSTextField*       scanDeltaField;
    IBOutlet NSTextField*       scanNumberField;

    //rate page
    IBOutlet NSMatrix*		rateTextFields;
    IBOutlet NSStepper* 	integrationStepper;
    IBOutlet NSTextField* 	integrationText;
    IBOutlet NSTextField* 	totalRateText;
    IBOutlet NSMatrix*		online2MaskMatrix;

    //tdb... fix the bar graph so it can be automatically put into a matrix
    IBOutlet ORValueBarGroupView*	rate0;
    IBOutlet ORValueBarGroupView*	totalRate;
    IBOutlet NSButton*		rateLogCB;
    IBOutlet NSButton*		totalRateLogCB;
    IBOutlet ORCompositeTimeLineView*	timeRatePlot;
    IBOutlet NSButton*		timeRateLogCB;
}

- (void) registerNotificationObservers;
- (void) registerRates;

#pragma mark ¥¥¥Interface Management
- (void) shipTimeStampChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) thresholdArrayChanged:(NSNotification*)aNotification;
- (void) gainArrayChanged:(NSNotification*)aNotification;
- (void) baseAddressChanged:(NSNotification*)aNotification;
- (void) thresholdChanged:(NSNotification*)aNotification;
- (void) gainChanged:(NSNotification*)aNotification;
- (void) continousChanged:(NSNotification*)aNotification;
- (void) scalersEnabledChanged:(NSNotification*)aNotification;
- (void) multiBoardEnabledChanged:(NSNotification*)aNotification;
- (void) scalerMaskChanged:(NSNotification*)aNotification;
- (void) onlineMaskChanged:(NSNotification*)aNotification;
- (void) displayRawChanged:(NSNotification*)aNotification;
- (void) updateTimePlot:(NSNotification*)aNotification;

//scan page
- (void) scanStartChanged:(NSNotification*)aNotification;
- (void) scanDeltaChanged:(NSNotification*)aNotification;
- (void) scanNumberChanged:(NSNotification*)aNotification;

//rate page
- (void) adcRateChanged:(NSNotification*)aNotification;
- (void) totalRateChanged:(NSNotification*)aNotification;
- (void) rateGroupChanged:(NSNotification*)aNotification;
- (void) integrationChanged:(NSNotification*)aNotification;

- (void) scaleAction:(NSNotification*)aNotification;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item;


#pragma mark ¥¥¥Actions
- (IBAction) shipTimeStampAction:(id)sender;
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) thresholdTextAction:(id)sender;
- (IBAction) gainAction:(id)sender;
- (IBAction) continousAction:(id)sender;
- (IBAction) scalersEnabledAction:(id)sender;
- (IBAction) mulitBoardEnabledAction:(id)sender;
- (IBAction) scalerMaskAction:(id)sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) probeBoard:(id)sender;
- (IBAction) report:(id)sender;
- (IBAction) readScalers:(id)sender;
- (IBAction) displayRawAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) onlineAction:(id)sender;

- (IBAction) scanStartAction:(id)sender;
- (IBAction) scanDeltaAction:(id)sender;
- (IBAction) scanNumberAction:(id)sender;
- (IBAction) scanAction:(id)sender;

- (IBAction) integrationAction:(id)sender;

- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
