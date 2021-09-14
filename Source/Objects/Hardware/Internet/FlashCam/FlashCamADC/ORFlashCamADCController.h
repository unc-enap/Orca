//  Orca
//  ORFlashCamADCController.h
//
//  Created by Tom Caldwell on Monday Dec 17,2019
//  Copyright (c) 2019 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "OrcaObjectController.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORFlashCamADCController : OrcaObjectController
{
    IBOutlet NSTextField* cardAddressTextField;
    IBOutlet NSPopUpButton* promSlotPUButton;
    IBOutlet NSButton* rebootCardButton;
    IBOutlet NSTextField* firmwareVerTextField;
    IBOutlet NSButton* getFirmwareVerButton;
    IBOutlet NSMatrix* chanEnabledMatrix;
    IBOutlet NSMatrix* baselineMatrix;
    IBOutlet NSMatrix* baseCalibMatrix;
    IBOutlet NSMatrix* thresholdMatrix;
    IBOutlet NSMatrix* adcGainMatrix;
    IBOutlet NSMatrix* trigGainMatrix;
    IBOutlet NSMatrix* shapeTimeMatrix;
    IBOutlet NSMatrix* filterTypeMatrix;
    IBOutlet NSMatrix* poleZeroTimeMatrix;
    IBOutlet NSButton* printFlagsButton;
    IBOutlet NSMatrix* chanEnabledRateMatrix;
    IBOutlet NSMatrix* rateTextFields;
    IBOutlet NSTextField* totalRateTextField;
    IBOutlet NSTextField* integrationTextField;
    IBOutlet NSButton* rateLogButton;
    IBOutlet NSButton* totalRateLogButton;
    IBOutlet NSButton* timeRateLogButton;
    IBOutlet NSStepper* integrationStepper;
    IBOutlet ORValueBarGroupView* rateView;
    IBOutlet ORValueBarGroupView* totalRateView;
    IBOutlet ORCompositeTimeLineView* timeRateView;
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) registerNotificationObservers;
- (void) registerRates;
- (void) awakeFromNib;
- (void) updateWindow;

#pragma mark •••Interface management
- (void) cardAddressChanged:(NSNotification*)note;
- (void) promSlotChanged:(NSNotification*)note;
- (void) firmwareVerRequest:(NSNotification*)note;
- (void) firmwareVerChanged:(NSNotification*)note;
- (void) cardSlotChanged:(NSNotification*)note;
- (void) chanEnabledChanged:(NSNotification*)note;
- (void) baselineChanged:(NSNotification*)note;
- (void) baseCalibChanged:(NSNotification*)note;
- (void) thresholdChanged:(NSNotification*)note;
- (void) adcGainChanged:(NSNotification*)note;
- (void) trigGainChanged:(NSNotification*)note;
- (void) shapeTimeChanged:(NSNotification*)note;
- (void) filterTypeChanged:(NSNotification*)note;
- (void) poleZeroTimeChanged:(NSNotification*)note;
- (void) rateGroupChanged:(NSNotification*)note;
- (void) waveformRateChanged:(NSNotification*)note;
- (void) totalRateChanged:(NSNotification*)note;
- (void) rateIntegrationChanged:(NSNotification*)note;
- (void) updateTimePlot:(NSNotification*)note;
- (void) scaleAction:(NSNotification*)note;
- (void) miscAttributesChanged:(NSNotification*)note;
- (void) settingsLock:(bool)lock;


#pragma mark •••Actions
- (IBAction) cardAddressAction:(id)sender;
- (IBAction) promSlotAction:(id)sender;
- (IBAction) rebootCardAction:(id)sender;
- (IBAction) firmwareVerAction:(id)sender;
- (IBAction) chanEnabledAction:(id)sender;
- (IBAction) baselineAction:(id)sender;
- (IBAction) baseCalibAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) adcGainAction:(id)sender;
- (IBAction) trigGainAction:(id)sender;
- (IBAction) shapeTimeAction:(id)sender;
- (IBAction) filterTypeAction:(id)sender;
- (IBAction) poleZeroTimeAction:(id)sender;
- (IBAction) printFlagsAction:(id)sender;
- (IBAction) rateIntegrationAction:(id)sender;

#pragma mark •••Data Source
- (double) getBarValue:(int)tag;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;


@end
