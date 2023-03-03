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

#import "ORFlashCamCardController.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORFlashCamADCController : ORFlashCamCardController
{
    IBOutlet NSMatrix* chanEnabledMatrix;
    IBOutlet NSMatrix* trigOutEnabledMatrix;
    IBOutlet NSMatrix* baselineMatrix;
    IBOutlet NSMatrix* thresholdMatrix;
    IBOutlet NSMatrix* adcGainMatrix;
    IBOutlet NSMatrix* trigGainMatrix;
    IBOutlet NSMatrix* shapeTimeMatrix;
    IBOutlet NSMatrix* filterTypeMatrix;
    IBOutlet NSMatrix* flatTopTimeMatrix;
    IBOutlet NSMatrix* poleZeroTimeMatrix;
    IBOutlet NSMatrix* postTriggerMatrix;
    IBOutlet NSMatrix* baselineSlewMatrix;
    IBOutlet NSMatrix* swTrigIncludeMatrix;
    IBOutlet NSTextField* baseBiasTextField;
    IBOutlet NSTextField* shapingLabel;
    IBOutlet NSTextField* flatTopLabel;
    IBOutlet NSPopUpButton* majorityLevelPUButton;
    IBOutlet NSTextField* majorityWidthTextField;
    IBOutlet NSButton* trigOutEnableButton;
    IBOutlet NSMatrix* chanEnabledRateMatrix;
    IBOutlet NSMatrix* rateTextFields;
    IBOutlet NSMatrix* trigRateTextFields;
    IBOutlet NSTextField* totalRateTextField;
    IBOutlet NSTextField* totalTrigRateTextField;
    IBOutlet NSTextField* integrationTextField;
    IBOutlet NSButton* rateLogButton;
    IBOutlet NSButton* totalRateLogButton;
    IBOutlet NSButton* timeRateLogButton;
    IBOutlet NSStepper* integrationStepper;
    IBOutlet ORValueBarGroupView* rateView;
    IBOutlet ORValueBarGroupView* totalRateView;
    IBOutlet ORCompositeTimeLineView* timeRateView;
    IBOutlet NSButton* enableBaselineHistoryButton;
    IBOutlet NSTextField* baselineSampleTimeTextField;
    IBOutlet ORCompositeTimeLineView* baselineView0;
    IBOutlet ORCompositeTimeLineView* baselineView1;
    IBOutlet ORCompositeTimeLineView* baselineView2;
    IBOutlet ORCompositeTimeLineView* baselineView3;
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
- (void) trigOutEnabledChanged:(NSNotification*)note;
- (void) cardSlotChanged:(NSNotification*)note;
- (void) chanEnabledChanged:(NSNotification*)note;
- (void) baselineChanged:(NSNotification*)note;
- (void) thresholdChanged:(NSNotification*)note;
- (void) adcGainChanged:(NSNotification*)note;
- (void) trigGainChanged:(NSNotification*)note;
- (void) shapeTimeChanged:(NSNotification*)note;
- (void) filterTypeChanged:(NSNotification*)note;
- (void) flatTopTimeChanged:(NSNotification*)note;
- (void) poleZeroTimeChanged:(NSNotification*)note;
- (void) postTriggerChanged:(NSNotification*)note;
- (void) baselineSlewChanged:(NSNotification*)note;
- (void) swTrigIncludeChanged:(NSNotification*)note;
- (void) baseBiasChanged:(NSNotification*)note;
- (void) majorityLevelChanged:(NSNotification*)note;
- (void) majorityWidthChanged:(NSNotification*)note;
- (void) rateGroupChanged:(NSNotification*)note;
- (void) waveformRateChanged:(NSNotification*)note;
- (void) totalRateChanged:(NSNotification*)note;
- (void) rateIntegrationChanged:(NSNotification*)note;
- (void) updateTimePlot:(NSNotification*)note;
- (void) scaleAction:(NSNotification*)note;
- (void) miscAttributesChanged:(NSNotification*)note;
- (void) enableBaselineHistoryChanged:(NSNotification*)note;
- (void) baselineSampleTimeChanged:(NSNotification*)note;
- (void) settingsLock:(bool)lock;

#pragma mark •••Actions
- (IBAction) chanEnabledAction:(id)sender;
- (IBAction) trigOutEnabledAction:(id)sender;
- (IBAction) baselineAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) adcGainAction:(id)sender;
- (IBAction) trigGainAction:(id)sender;
- (IBAction) shapeTimeAction:(id)sender;
- (IBAction) filterTypeAction:(id)sender;
- (IBAction) flatTopTimeAction:(id)sender;
- (IBAction) poleZeroTimeAction:(id)sender;
- (IBAction) postTriggerAction:(id)sender;
- (IBAction) baselineSlewAction:(id)sender;
- (IBAction) swTrigIncludeAction:(id)sender;
- (IBAction) baseBiasAction:(id)sender;
- (IBAction) majorityLevelAction:(id)sender;
- (IBAction) majorityWidthAction:(id)sender;
- (IBAction) trigOutEnableAction:(id)sender;
- (IBAction) printFlagsAction:(id)sender;
- (IBAction) rateIntegrationAction:(id)sender;
- (IBAction) enableBaselineHistoryAction:(id)sender;
- (IBAction) baselineSampleTimeAction:(id)sender;

#pragma mark •••Data Source
- (double) getBarValue:(int)tag;
- (double) getSecondaryBarValue:(int)tag;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end


@interface ORFlashCamADCStdController : ORFlashCamADCController { }
@end
