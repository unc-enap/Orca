//
//  ORHP4405AController.h
//  Orca
//
//  Created by Mark Howe on Wed Jul28, 2010.
//  Copyright 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina at the UNC Physics Dept sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark ¥¥¥Imported Files

#import "ORGpibDeviceController.h"

@class ORCompositePlotView;
@class ORAxis;

@interface ORHP4405AController : ORGpibDeviceController {    
	IBOutlet   NSTextField*		centerFreqField;
	IBOutlet   NSPopUpButton*	dataTypePU;
	IBOutlet   NSButton*		continuousMeasurementCB;
	IBOutlet   NSButton*		startMeasurementButton;
	IBOutlet   NSButton*		stopMeasurementButton;
	IBOutlet   NSTextField*		optimizePreselectorFreqField;
	IBOutlet   NSTextField*		inputMaxMixerPowerField;
	IBOutlet   NSButton*		inputGainEnabledCB;
	IBOutlet   NSButton*		inputAttAutoEnabledCB;
	IBOutlet   NSTextField*		inputAttenuationField;
	IBOutlet   NSButton*		detectorGainEnabledCB;
	
	IBOutlet   NSButton*		burstPulseDiscrimEnabledCB;
	IBOutlet   NSPopUpButton*	burstModeAbsPU;
	IBOutlet   NSTextField*		burstModeSettingField;
	IBOutlet   NSButton*		burstFreqEnabledCB;
	IBOutlet   NSPopUpButton*	freqStepDirPU;
	IBOutlet   NSTextField*		freqStepSizeField;
	IBOutlet   NSPopUpButton*	unitsPU;
	IBOutlet   NSTextField*		stopFreqField;
	IBOutlet   NSTextField*		startFreqField;

	IBOutlet   NSTextField*		triggerOffsetField;
	IBOutlet   NSButton*		triggerOffsetEnabledCB;
	IBOutlet   NSTextField*		triggerDelayField;
	IBOutlet   NSButton*		triggerDelayEnableCB;
	IBOutlet   NSPopUpButton*	triggerSlopePU;
	IBOutlet   NSPopUpButton*	triggerSourcePU;

	
	IBOutlet   NSButton*		inputSettingsLoadButton;
	IBOutlet   NSButton*		frequencySettingsLoadButton;
	IBOutlet   NSButton*		triggerSettingsLoadButton;

	IBOutlet ORCompositePlotView*	plotter;	
}

#pragma mark ***Initialization
- (id) 	 init;
- (void) awakeFromNib;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void)		updateWindow;

#pragma mark ***Interface Management
- (void) traceChanged:(NSNotification*)aNote;
- (void) dataTypeChanged:(NSNotification*)aNote;
- (void) statusOperationRegChanged:(NSNotification*)aNote;
- (void) questionablePowerRegChanged:(NSNotification*)aNote;
- (void) questionableIntegrityRegChanged:(NSNotification*)aNote;
- (void) questionableFreqRegChanged:(NSNotification*)aNote;
- (void) questionableEventRegChanged:(NSNotification*)aNote;
- (void) questionableConditionRegChanged:(NSNotification*)aNote;
- (void) questionableCalibrationRegChanged:(NSNotification*)aNote;
- (void) standardEventRegChanged:(NSNotification*)aNote;
- (void) statusRegChanged:(NSNotification*)aNote;
- (void) continuousMeasurementChanged:(NSNotification*)aNote;
- (void) optimizePreselectorFreqChanged:(NSNotification*)aNote;
- (void) inputMaxMixerPowerChanged:(NSNotification*)aNote;
- (void) inputGainEnabledChanged:(NSNotification*)aNote;
- (void) inputAttAutoEnabledChanged:(NSNotification*)aNote;
- (void) inputAttenuationChanged:(NSNotification*)aNote;
- (void) detectorGainEnabledChanged:(NSNotification*)aNote;
- (void) burstPulseDiscrimEnabledChanged:(NSNotification*)aNote;
- (void) burstModeAbsChanged:(NSNotification*)aNote;
- (void) burstModeSettingChanged:(NSNotification*)aNote;
- (void) burstFreqEnabledChanged:(NSNotification*)aNote;
- (void) triggerSourceChanged:(NSNotification*)aNote;
- (void) triggerOffsetEnabledChanged:(NSNotification*)aNote;
- (void) triggerOffsetChanged:(NSNotification*)aNote;
- (void) triggerSlopeChanged:(NSNotification*)aNote;
- (void) triggerDelayEnabledChanged:(NSNotification*)aNote;
- (void) triggerDelayChanged:(NSNotification*)aNote;
- (void) freqStepDirChanged:(NSNotification*)aNote;
- (void) freqStepSizeChanged:(NSNotification*)aNote;
- (void) unitsChanged:(NSNotification*)aNote;
- (void) stopFreqChanged:(NSNotification*)aNote;
- (void) startFreqChanged:(NSNotification*)aNote;
- (void) centerFreqChanged:(NSNotification*)aNote;
- (void) lockChanged: (NSNotification*) aNote;
- (void) measurementInProgressChanged: (NSNotification*) aNote;

#pragma mark ¥¥¥Actions
- (IBAction) dataTypeAction:(id)sender;
- (IBAction) continuousMeasurementAction:(id)sender;
- (IBAction) optimizePreselectorFreqAction:(id)sender;
- (IBAction) inputMaxMixerPowerAction:(id)sender;
- (IBAction) inputGainEnabledAction:(id)sender;
- (IBAction) inputAttAutoEnabledAction:(id)sender;
- (IBAction) inputAttenuationAction:(id)sender;
- (IBAction) detectorGainEnabledAction:(id)sender;
- (IBAction) burstPulseDiscrimEnabledAction:(id)sender;
- (IBAction) burstModeAbsAction:(id)sender;
- (IBAction) burstModeSettingAction:(id)sender;
- (IBAction) burstFreqEnabledAction:(id)sender;
- (IBAction) triggerSourceAction:(id)sender;
- (IBAction) triggerOffsetEnabledAction:(id)sender;
- (IBAction) triggerOffsetAction:(id)sender;
- (IBAction) triggerSlopeAction:(id)sender;
- (IBAction) triggerDelayEnabledAction:(id)sender;
- (IBAction) triggerDelayAction:(id)sender;
- (IBAction) freqStepDirAction:(id)sender;
- (IBAction) freqStepSizeAction:(id)sender;
- (IBAction) unitsAction:(id)sender;
- (IBAction) stopFreqAction:(id)sender;
- (IBAction) startFreqAction:(id)sender;
- (IBAction) centerFreqAction:(id)sender;

- (IBAction) loadFreqSettingsAction:(id)sender;
- (IBAction) loadTriggerSettingsAction:(id)sender;
- (IBAction) loadRFBurstSettingsAction:(id)sender;
- (IBAction) loadInputPortSettingsAction:(id)sender;
- (IBAction) startMeasuremnt:(id)sender;
- (IBAction) pauseMeasuremnt:(id)sender;

- (IBAction) checkStatusAction:(id)sender;


#pragma mark ¥¥¥Plot DataSource
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
@end
