//
//  ORHP4405AController.m
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
#import "ORHP4405AController.h"
#import "ORHP4405AModel.h"
#import "ORPlot.h"
#import "ORPlotView.h"
#import "ORCompositePlotView.h"
#import "ORAxis.h"

@implementation ORHP4405AController

#pragma mark ¥¥¥Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"ORHP4405A" ];
    return self;
}
- (void) awakeFromNib
{
	[super awakeFromNib];
	ORPlot* aPlot= [[ORPlot alloc] initWithTag:0 andDataSource:self];
	[plotter addPlot: aPlot];
	[aPlot release];
	[[plotter yAxis] setRngLimitsLow:0 withHigh:401 withMinRng:10];
	[[plotter yAxis] setRngDefaultsLow:0 withHigh:401];
}

#pragma mark ***Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
	
    [ notifyCenter addObserver: self
                      selector: @selector( lockChanged: )
                          name: ORRunStatusChangedNotification
                        object: nil];
    
	[notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORHP4405ALock
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(centerFreqChanged:)
                         name : ORHP4405AModelCenterFreqChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(startFreqChanged:)
                         name : ORHP4405AModelStartFreqChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(stopFreqChanged:)
                         name : ORHP4405AModelStopFreqChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(unitsChanged:)
                         name : ORHP4405AModelUnitsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(freqStepSizeChanged:)
                         name : ORHP4405AModelFreqStepSizeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(freqStepDirChanged:)
                         name : ORHP4405AModelFreqStepDirChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerDelayChanged:)
                         name : ORHP4405AModelTriggerDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerDelayEnabledChanged:)
                         name : ORHP4405AModelTriggerDelayEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerSlopeChanged:)
                         name : ORHP4405AModelTriggerSlopeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerOffsetChanged:)
                         name : ORHP4405AModelTriggerOffsetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerOffsetEnabledChanged:)
                         name : ORHP4405AModelTriggerOffsetEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerSourceChanged:)
                         name : ORHP4405AModelTriggerSourceChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(burstFreqEnabledChanged:)
                         name : ORHP4405AModelBurstFreqEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(burstModeSettingChanged:)
                         name : ORHP4405AModelBurstModeSettingChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(burstModeAbsChanged:)
                         name : ORHP4405AModelBurstModeAbsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(burstPulseDiscrimEnabledChanged:)
                         name : ORHP4405AModelBurstPulseDiscrimEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(detectorGainEnabledChanged:)
                         name : ORHP4405AModelDetectorGainEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(inputAttenuationChanged:)
                         name : ORHP4405AModelInputAttenuationChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(inputAttAutoEnabledChanged:)
                         name : ORHP4405AModelInputAttAutoEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(inputGainEnabledChanged:)
                         name : ORHP4405AModelInputGainEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(inputMaxMixerPowerChanged:)
                         name : ORHP4405AModelInputMaxMixerPowerChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(optimizePreselectorFreqChanged:)
                         name : ORHP4405AModelOptimizePreselectorFreqChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(continuousMeasurementChanged:)
                         name : ORHP4405AModelContinuousMeasurementChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(statusRegChanged:)
                         name : ORHP4405AModelStatusRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(standardEventRegChanged:)
                         name : ORHP4405AModelStandardEventRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(questionableCalibrationRegChanged:)
                         name : ORHP4405AModelQuestionableCalibrationRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(questionableConditionRegChanged:)
                         name : ORHP4405AModelQuestionableConditionRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(questionableEventRegChanged:)
                         name : ORHP4405AModelQuestionableEventRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(questionableFreqRegChanged:)
                         name : ORHP4405AModelQuestionableFreqRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(questionableIntegrityRegChanged:)
                         name : ORHP4405AModelQuestionableIntegrityRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(questionablePowerRegChanged:)
                         name : ORHP4405AModelQuestionablePowerRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(statusOperationRegChanged:)
                         name : ORHP4405AModelStatusOperationRegChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(measurementInProgressChanged:)
                         name : ORHP4405AModelMeasurementInProgressChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataTypeChanged:)
                         name : ORHP4405AModelDataTypeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(traceChanged:)
                         name : ORHP4405AModelTraceChanged
						object: model];	

}

- (void) updateWindow
{
    [ super updateWindow ];
	[self centerFreqChanged:nil];
	[self startFreqChanged:nil];
	[self stopFreqChanged:nil];
	[self unitsChanged:nil];
	[self freqStepSizeChanged:nil];
	[self freqStepDirChanged:nil];
	[self triggerDelayChanged:nil];
	[self triggerDelayEnabledChanged:nil];
	[self triggerSlopeChanged:nil];
	[self triggerOffsetChanged:nil];
	[self triggerOffsetEnabledChanged:nil];
	[self triggerSourceChanged:nil];
	[self burstFreqEnabledChanged:nil];
	[self burstModeSettingChanged:nil];
	[self burstModeAbsChanged:nil];
	[self burstPulseDiscrimEnabledChanged:nil];
	[self detectorGainEnabledChanged:nil];
	[self inputAttenuationChanged:nil];
	[self inputAttAutoEnabledChanged:nil];
	[self inputGainEnabledChanged:nil];
	[self inputMaxMixerPowerChanged:nil];
	[self optimizePreselectorFreqChanged:nil];
	[self continuousMeasurementChanged:nil];
	[self statusRegChanged:nil];
	[self standardEventRegChanged:nil];
	[self questionableCalibrationRegChanged:nil];
	[self questionableConditionRegChanged:nil];
	[self questionableEventRegChanged:nil];
	[self questionableFreqRegChanged:nil];
	[self questionableIntegrityRegChanged:nil];
	[self questionablePowerRegChanged:nil];
	[self statusOperationRegChanged:nil];
	[self measurementInProgressChanged:nil];
	[self dataTypeChanged:nil];
	[self traceChanged:nil];
    [self lockChanged:nil];
}

- (void) lockChanged: (NSNotification*) aNotification
{
}

#pragma mark ***Interface Management
- (void) traceChanged:(NSNotification*)aNote
{
	[plotter autoScaleY:self];
	[plotter setNeedsDisplay:YES];
}

- (void) dataTypeChanged:(NSNotification*)aNote
{
	[dataTypePU selectItemAtIndex: [model dataType]];
}

- (void) measurementInProgressChanged: (NSNotification*) aNotification
{
	BOOL measuring = [model measurementInProgress];
	[startMeasurementButton setEnabled: !measuring];
	[continuousMeasurementCB setEnabled: !measuring];
	[stopMeasurementButton setEnabled: measuring];
	
	
	[centerFreqField setEnabled: !measuring];
	[dataTypePU setEnabled: !measuring];
	[optimizePreselectorFreqField setEnabled: !measuring];
	[inputMaxMixerPowerField setEnabled: !measuring];
	[inputGainEnabledCB setEnabled: !measuring];
	[inputAttAutoEnabledCB setEnabled: !measuring];
	[inputAttenuationField setEnabled: !measuring];
	[detectorGainEnabledCB setEnabled: !measuring];
	
	[burstPulseDiscrimEnabledCB setEnabled: !measuring];
	[burstModeAbsPU setEnabled: !measuring];
	[burstModeSettingField setEnabled: !measuring];
	[burstFreqEnabledCB setEnabled: !measuring];
	[freqStepDirPU setEnabled: !measuring];
	[freqStepSizeField setEnabled: !measuring];
	[unitsPU setEnabled: !measuring];
	[stopFreqField setEnabled: !measuring];
	[startFreqField setEnabled: !measuring];
	
	[triggerOffsetField setEnabled: !measuring];
	[triggerOffsetEnabledCB setEnabled: !measuring];
	[triggerDelayField setEnabled: !measuring];
	[triggerDelayEnableCB setEnabled: !measuring];
	[triggerSlopePU setEnabled: !measuring];
	[triggerSourcePU setEnabled: !measuring];
	
	[inputSettingsLoadButton setEnabled: !measuring];
	[frequencySettingsLoadButton setEnabled: !measuring];
	[triggerSettingsLoadButton setEnabled: !measuring];
	
}

- (void) statusOperationRegChanged:(NSNotification*)aNote
{
	NSLog(@"status Op: 0x%x\n",[model statusOperationReg]);
}

- (void) questionablePowerRegChanged:(NSNotification*)aNote
{
}

- (void) questionableIntegrityRegChanged:(NSNotification*)aNote
{
}

- (void) questionableFreqRegChanged:(NSNotification*)aNote
{
}

- (void) questionableEventRegChanged:(NSNotification*)aNote
{
}

- (void) questionableConditionRegChanged:(NSNotification*)aNote
{
}

- (void) questionableCalibrationRegChanged:(NSNotification*)aNote
{
}

- (void) standardEventRegChanged:(NSNotification*)aNote
{
	NSLog(@"standard event: 0x%0x\n",[model standardEventReg]);
}

- (void) statusRegChanged:(NSNotification*)aNote
{
	NSLog(@"status event: 0x%0x\n",[model statusReg]);
}

- (void) continuousMeasurementChanged:(NSNotification*)aNote
{
	[continuousMeasurementCB setIntValue: [model continuousMeasurement]];
}

- (void) optimizePreselectorFreqChanged:(NSNotification*)aNote
{
	[optimizePreselectorFreqField setIntValue: [model optimizePreselectorFreq]];
}

- (void) inputMaxMixerPowerChanged:(NSNotification*)aNote
{
	[inputMaxMixerPowerField setIntValue: [model inputMaxMixerPower]];
}

- (void) inputGainEnabledChanged:(NSNotification*)aNote
{
	[inputGainEnabledCB setIntValue: [model inputGainEnabled]];
}

- (void) inputAttAutoEnabledChanged:(NSNotification*)aNote
{
	[inputAttAutoEnabledCB setIntValue: [model inputAttAutoEnabled]];
}

- (void) inputAttenuationChanged:(NSNotification*)aNote
{
	[inputAttenuationField setIntValue: [model inputAttenuation]];
}

- (void) detectorGainEnabledChanged:(NSNotification*)aNote
{
	[detectorGainEnabledCB setIntValue: [model detectorGainEnabled]];
}

- (void) burstPulseDiscrimEnabledChanged:(NSNotification*)aNote
{
	[burstPulseDiscrimEnabledCB setIntValue: [model burstPulseDiscrimEnabled]];
}

- (void) burstModeAbsChanged:(NSNotification*)aNote
{
	[burstModeAbsPU setIntValue: [model burstModeAbs]];
}

- (void) burstModeSettingChanged:(NSNotification*)aNote
{
	[burstModeSettingField setIntValue: [model burstModeSetting]];
}

- (void) burstFreqEnabledChanged:(NSNotification*)aNote
{
	[burstFreqEnabledCB setIntValue: [model burstFreqEnabled]];
}

- (void) triggerSourceChanged:(NSNotification*)aNote
{
	[triggerSourcePU selectItemAtIndex: [model triggerSource]];
}

- (void) triggerOffsetEnabledChanged:(NSNotification*)aNote
{
	[triggerOffsetEnabledCB setIntValue: [model triggerOffsetEnabled]];
}

- (void) triggerOffsetChanged:(NSNotification*)aNote
{
	[triggerOffsetField setFloatValue: [model triggerOffset]];
}

- (void) triggerSlopeChanged:(NSNotification*)aNote
{
	[triggerSlopePU setIntValue: [model triggerSlope]];
}

- (void) triggerDelayEnabledChanged:(NSNotification*)aNote
{
	[triggerDelayEnableCB setFloatValue: [model triggerDelayEnabled]];
}

- (void) triggerDelayChanged:(NSNotification*)aNote
{
	[triggerDelayField setFloatValue: [model triggerDelay]];
}

- (void) freqStepDirChanged:(NSNotification*)aNote
{
	[freqStepDirPU selectItemAtIndex: [model freqStepDir]];
}

- (void) freqStepSizeChanged:(NSNotification*)aNote
{
	[freqStepSizeField setFloatValue: [model freqStepSize]];
}

- (void) unitsChanged:(NSNotification*)aNote
{
    ORHP4405AModel* theModel = (ORHP4405AModel*)model;
	[unitsPU selectItemAtIndex: [theModel units]];
	[[plotter yAxis] setLabel:[model unitFullName:[theModel units]]];
}

- (void) stopFreqChanged:(NSNotification*)aNote
{
	[stopFreqField setFloatValue: [model stopFreq]];
}

- (void) startFreqChanged:(NSNotification*)aNote
{
	[startFreqField setFloatValue: [model startFreq]];
}

- (void) centerFreqChanged:(NSNotification*)aNote
{
	[centerFreqField setFloatValue: [model centerFreq]];
}

#pragma mark ¥¥¥Actions

- (IBAction) dataTypeAction:(id)sender
{
	[model setDataType:(int)[sender indexOfSelectedItem]];
}

- (IBAction) continuousMeasurementAction:(id)sender
{
	[model setContinuousMeasurement:[sender intValue]];	
}

- (IBAction) optimizePreselectorFreqAction:(id)sender
{
	[model setOptimizePreselectorFreq:[sender intValue]];	
}

- (IBAction) inputMaxMixerPowerAction:(id)sender
{
	[model setInputMaxMixerPower:[sender intValue]];	
}

- (IBAction) inputGainEnabledAction:(id)sender
{
	[model setInputGainEnabled:[sender intValue]];	
}

- (IBAction) inputAttAutoEnabledAction:(id)sender
{
	[model setInputAttAutoEnabled:[sender intValue]];	
}

- (IBAction) inputAttenuationAction:(id)sender
{
	[model setInputAttenuation:[sender intValue]];	
}

- (IBAction) detectorGainEnabledAction:(id)sender
{
	[model setDetectorGainEnabled:[sender intValue]];	
}

- (IBAction) burstPulseDiscrimEnabledAction:(id)sender
{
	[model setBurstPulseDiscrimEnabled:[sender intValue]];	
}

- (IBAction) burstModeAbsAction:(id)sender
{
	[model setBurstModeAbs:[sender indexOfSelectedItem]];	
}

- (IBAction) burstModeSettingAction:(id)sender
{
	[model setBurstModeSetting:[sender intValue]];	
}

- (void) burstFreqEnabledAction:(id)sender
{
	[model setBurstFreqEnabled:[sender intValue]];	
}

- (IBAction) triggerSourceAction:(id)sender
{
	[model setTriggerSource:(int)[sender indexOfSelectedItem]];
}

- (IBAction) triggerOffsetEnabledAction:(id)sender
{
	[model setTriggerOffsetEnabled:[sender intValue]];	
}

- (IBAction) triggerOffsetAction:(id)sender
{
	[model setTriggerOffset:[sender floatValue]];	
}

- (IBAction) triggerSlopeAction:(id)sender
{
	[model setTriggerSlope:(int)[sender indexOfSelectedItem]];
}

- (IBAction) triggerDelayEnabledAction:(id)sender
{
	[model setTriggerDelayEnabled:[sender intValue]];	
}

- (IBAction) triggerDelayAction:(id)sender
{
	[model setTriggerDelay:[sender floatValue]];	
}

- (IBAction) freqStepDirAction:(id)sender
{
	[model setFreqStepDir:[sender indexOfSelectedItem]];	
}

- (IBAction) freqStepSizeAction:(id)sender
{
	[model setFreqStepSize:[sender floatValue]];	
}

- (IBAction) unitsAction:(id)sender
{
	[model setUnits:(int)[sender indexOfSelectedItem]];	
}

- (IBAction) stopFreqAction:(id)sender
{
	[model setStopFreq:[sender floatValue]];	
}

- (IBAction) startFreqAction:(id)sender
{
	[model setStartFreq:[sender floatValue]];	
}

- (IBAction) centerFreqAction:(id)sender
{
	[model setCenterFreq:[sender floatValue]];	
}

#pragma mark ¥¥¥Hardware Actions
- (IBAction) loadFreqSettingsAction:(id)sender
{
	@try {
		[self endEditing];
		[model loadFreqSettings];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"HP4405A Freq Settings Load Failed");
        ORRunAlertPanel( @"HP4405A Freq Settings Load Failed",
						@"%@",
						@"OK",
						nil,
						nil,
                        [localException reason]
                        );
	}
}

- (IBAction) loadTriggerSettingsAction:(id)sender
{
	@try {
		[self endEditing];
		[model loadTriggerSettings];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"HP4405A Trigger Settings Load Failed");
        ORRunAlertPanel( @"HP4405A Trigger Settings Load Failed",
						@"%@",
						@"OK",
						nil,
						nil,
                        [localException reason]);
	}
}

- (IBAction) loadRFBurstSettingsAction:(id)sender
{
	@try {
		[self endEditing];
		[model loadRFBurstSettings];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"HP4405A RF Burst Settings Load Failed");
        ORRunAlertPanel( @"HP4405A RF Burst Settings Load Failed",
						@"%@",
						@"OK",
						nil,
						nil,
                        [localException reason]);
	}
}
- (IBAction) loadInputPortSettingsAction:(id)sender
{
	@try {
		[self endEditing];
		[model loadInputPortSettings];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"HP4405A Input Port Settings Load Failed");
        ORRunAlertPanel( @"HP4405A Input Port Settings Load Failed",
						@"%@",
						@"OK",
						nil,
						nil,
                        [localException reason]);
	}
}

- (IBAction) startMeasuremnt:(id)sender
{
	@try {
		[self endEditing];
		[model startMeasurement];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"HP4405A Initiate Measurement Failed");
        ORRunAlertPanel( @"HP4405A Initiate Measurement Failed",
						@"%@",
						@"OK",
						nil,
						nil,
                        [localException reason]);
	}
}

- (IBAction) pauseMeasuremnt:(id)sender
{
	@try {
		[self endEditing];
		[model pauseMeasurement];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"HP4405A Pause Measurement Failed");
        ORRunAlertPanel( @"HP4405A Pause Measurement Failed",
						@"%@",
						@"OK",
						nil,
						nil,
                        [localException reason]);
	}
}

- (IBAction) checkStatusAction:(id)sender;
{
	@try {
		[self endEditing];
		[model checkStatus];
	}
	@catch(NSException* localException) {
        NSLogColor([NSColor redColor],@"HP4405A Check Status Failed");
        ORRunAlertPanel( @"HP4405A Check Status Failed",
						@"%@",
						@"OK",
						nil,
						nil,
                        [localException reason]);
	}
}


- (int) numberPointsInPlot:(id)aPlotter
{
    return [model numPoints];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	[model plotter:aPlotter index:i x:xValue y:yValue];
}

@end
