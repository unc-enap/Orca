//
//  ORCaen419Controller.m
//  Orca
//
//  Created by Mark Howe on 2/20/09
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nug Physics and 
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
#pragma mark •••Imported Files
#import "OrcaObjectController.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

// Definition of class
@interface ORCaen419Controller : OrcaObjectController {
    IBOutlet NSTabView*		tabView;
	IBOutlet NSTextField* baseAddressField;
	IBOutlet NSTextField* auxAddressField;
	IBOutlet NSMatrix*	  enabledMaskMatrix;
	IBOutlet NSMatrix*	  resetMaskMatrix;
	IBOutlet NSMatrix*	  riseTimeProtectionMatrix;
	IBOutlet NSPopUpButton* linearGateMode0PU;
	IBOutlet NSPopUpButton* linearGateMode1PU;
	IBOutlet NSPopUpButton* linearGateMode2PU;
	IBOutlet NSPopUpButton* linearGateMode3PU;
    IBOutlet NSMatrix*	  lowThresholdMatrix;
    IBOutlet NSMatrix*	  highThresholdMatrix;
    IBOutlet NSButton*	  basicLockButton;
    IBOutlet NSButton*	  readThresholdsButton;
    IBOutlet NSButton*	  writeThresholdsButton;
    IBOutlet NSButton*	  initButton;
    IBOutlet NSButton*	  fireButton;
	IBOutlet NSButton*	  resetButton;
    IBOutlet NSTextField* slotField;
    IBOutlet NSTextField* basicLockDocField;

	//rate page
    IBOutlet NSMatrix*		rateTextFields;
    IBOutlet NSStepper* 	integrationStepper;
    IBOutlet NSTextField* 	integrationText;
    IBOutlet NSTextField* 	totalRateText;
    IBOutlet NSMatrix*		online2MaskMatrix;
	IBOutlet ORValueBarGroupView*	rate0;
    IBOutlet ORValueBarGroupView*	totalRate;
    IBOutlet NSButton*		rateLogCB;
    IBOutlet NSButton*		totalRateLogCB;
    IBOutlet ORCompositeTimeLineView*	timeRatePlot;
    IBOutlet NSButton*		timeRateLogCB;
	
}

#pragma mark ***Initialization
- (id)		init;
 	
#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) registerRates;

#pragma mark ***Interface Management
- (void) enabledMaskChanged:(NSNotification*)aNote;
- (void) resetMaskChanged:(NSNotification*)aNote;
- (void) riseTimeProtectionChanged:(NSNotification*)aNote;
- (void) linearGateModeChanged:(NSNotification*)aNote;
- (void) auxAddressChanged:(NSNotification*)aNote;
- (void) updateWindow;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) basicLockChanged:(NSNotification*)aNote;
- (void) adcRateChanged:(NSNotification*)aNotification;
- (void) totalRateChanged:(NSNotification*)aNotification;
- (void) rateGroupChanged:(NSNotification*)aNotification;
- (void) integrationChanged:(NSNotification*)aNotification;
- (void) scaleAction:(NSNotification*)aNotification;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) highThresholdChanged:(NSNotification*) aNote;
- (void) lowThresholdChanged:(NSNotification*) aNote;

#pragma mark •••Actions
- (IBAction) enabledMaskAction:(id)sender;
- (IBAction) resetMaskAction:(id)sender;
- (IBAction) riseTimeProtectionAction:(id)sender;
- (IBAction) linearGateModeAction:(id)sender;
- (IBAction) auxAddressAction:(id)sender;
- (IBAction) baseAddressAction:(id) sender;
- (IBAction) lowThresholdAction:(id) sender;
- (IBAction) highThresholdAction:(id) sender;
- (IBAction) readThresholds:(id) sender;
- (IBAction) writeThresholds:(id) sender;
- (IBAction) basicLockAction:(id)sender;
- (IBAction) initBoard:(id) sender;
- (IBAction) fire:(id) sender;
- (IBAction) reset:(id) sender;
- (IBAction) integrationAction:(id)sender;

- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
