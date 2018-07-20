//-------------------------------------------------------------------------
//  ORSIS3302Controller.h
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
#import <Cocoa/Cocoa.h>
#import "ORSIS3302Controller.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORTimeRate.h"
#import "ORRate.h"
#import "OHexFormatter.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"

@implementation ORSIS3302Controller

-(id)init
{
    self = [super initWithWindowNibName:@"SIS3302"];
    
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
	
    settingSize     = NSMakeSize(1267,620);
    rateSize		= NSMakeSize(790,300);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
	
    NSString* key = [NSString stringWithFormat: @"orca.SIS3302%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
			
	OHexFormatter *numberFormatter = [[[OHexFormatter alloc] init] autorelease];
	
	NSNumberFormatter *rateFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[rateFormatter setFormat:@"##0.0;0;-##0.0"];
	
	int i;
	for(i=0;i<8;i++){
		NSCell* theCell = [thresholdMatrix cellAtRow:i column:0];
		[theCell setFormatter:numberFormatter];
	}
	for(i=0;i<8;i++){
		NSCell* theCell = [highThresholdMatrix cellAtRow:i column:0];
		[theCell setFormatter:numberFormatter];
	}
	for(i=0;i<8;i++){
		NSCell* theCell = [rateTextFields cellAtRow:i column:0];
		[theCell setFormatter:rateFormatter];
	}
		
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];

	[rate0 setNumber:8 height:10 spacing:5];

	
	[super awakeFromNib];
	
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(baseAddressChanged:)
                         name : ORVmeIOCardBaseAddressChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORSIS3302SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORSIS3302RateGroupChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];
	
    //a fake action for the scale objects
    [notifyCenter addObserver : self
                     selector : @selector(scaleAction:)
                         name : ORAxisRangeChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateTimePlot:)
                         name : ORRateAverageChangedNotification
                       object : [[model waveFormRateGroup]timeRate]];
    
    [notifyCenter addObserver : self
                     selector : @selector(integrationChanged:)
                         name : ORRateGroupIntegrationChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(triggerOutEnabledChanged:)
                         name : ORSIS3302TriggerOutEnabledChanged
                       object : model];

	[notifyCenter addObserver : self
                     selector : @selector(highEnergySuppressChanged:)
                         name : ORSIS3302HighEnergySuppressChanged
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(inputInvertedChanged:)
                         name : ORSIS3302InputInvertedChanged
                       object : model];
	
	
	[notifyCenter addObserver : self
                     selector : @selector(adc50KTriggerEnabledChanged:)
                         name : ORSIS3302Adc50KTriggerEnabledChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(gtChanged:)
                         name : ORSIS3302GtChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(thresholdChanged:)
                         name : ORSIS3302ThresholdChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(highThresholdChanged:)
                         name : ORSIS3302HighThresholdChanged
                       object : model];	
    
	[notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORSIS3302ClockSourceChanged
						object: model];
			
//    [notifyCenter addObserver : self
//                     selector : @selector(eventConfigChanged:)
 //                        name : ORSIS3302EventConfigChanged
//						object: model];
		
    [notifyCenter addObserver : self
                     selector : @selector(gateLengthChanged:)
                         name : ORSIS3302GateLengthChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(pulseLengthChanged:)
                         name : ORSIS3302PulseLengthChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(sumGChanged:)
                         name : ORSIS3302SumGChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(peakingTimeChanged:)
                         name : ORSIS3302PeakingTimeChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(internalTriggerDelayChanged:)
                         name : ORSIS3302InternalTriggerDelayChanged
						object: model];	

	[notifyCenter addObserver : self
                     selector : @selector(triggerDecimationChanged:)
                         name : ORSIS3302TriggerDecimationChanged
						object: model];	
	
	[notifyCenter addObserver : self
                     selector : @selector(energyDecimationChanged:)
                         name : ORSIS3302EnergyDecimationChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(lemoOutModeChanged:)
                         name : ORSIS3302LemoOutModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lemoInModeChanged:)
                         name : ORSIS3302LemoInModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dacOffsetChanged:)
                         name : ORSIS3302DacOffsetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sampleLengthChanged:)
                         name : ORSIS3302SampleLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sampleStartIndexChanged:)
                         name : ORSIS3302SampleStartIndexChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(preTriggerDelayChanged:)
                         name : ORSIS3302ModelPreTriggerDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerGateLengthChanged:)
                         name : ORSIS3302ModelTriggerGateLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energyPeakingTimeChanged:)
                         name : ORSIS3302ModelEnergyPeakingTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energyGapTimeChanged:)
                         name : ORSIS3302ModelEnergyGapTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energySampleStartIndex1Changed:)
                         name : ORSIS3302ModelEnergySampleStartIndex1Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energySampleStartIndex2Changed:)
                         name : ORSIS3302ModelEnergySampleStartIndex2Changed
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(energyNumberToSumChanged:)
                         name : ORSIS3302ModelEnergyNumberToSumChanged
						object: model];	
    
	[notifyCenter addObserver : self
                     selector : @selector(energyTauFactorChanged:)
                         name : ORSIS3302ModelEnergyTauFactorChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energySampleStartIndex3Changed:)
                         name : ORSIS3302ModelEnergySampleStartIndex3Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(runModeChanged:)
                         name : ORSIS3302ModelRunModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energyGateLengthChanged:)
                         name : ORSIS3302ModelEnergyGateLengthChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(energySetShipWaveformChanged:)
                         name : ORSIS3302SetShipWaveformChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(energySetShipSummedWaveformChanged:)
                         name : ORSIS3302SetShipSummedWaveformChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(lemoInEnabledMaskChanged:)
                         name : ORSIS3302ModelLemoInEnabledMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(internalExternalTriggersOredChanged:)
                         name : ORSIS3302ModelInternalExternalTriggersOredChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(extendedThresholdEnabledChanged:)
                         name : ORSIS3302ExtendedThresholdEnabledChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(internalTriggerEnabledChanged:)
                         name : ORSIS3302InternalTriggerEnabledChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(externalTriggerEnabledChanged:)
                         name : ORSIS3302ExternalTriggerEnabledChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(internalGateEnabledChanged:)
                         name : ORSIS3302InternalGateEnabledChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(externalGateEnabledChanged:)
                         name : ORSIS3302ExternalGateEnabledChanged
						object: model];
	
	[self registerRates];

    [notifyCenter addObserver : self
                     selector : @selector(mcaNofHistoPresetChanged:)
                         name : ORSIS3302ModelMcaNofHistoPresetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mcaLNESetupChanged:)
                         name : ORSIS3302ModelMcaLNESetupChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mcaPrescaleFactorChanged:)
                         name : ORSIS3302ModelMcaPrescaleFactorChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mcaAutoClearChanged:)
                         name : ORSIS3302ModelMcaAutoClearChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mcaNofScansPresetChanged:)
                         name : ORSIS3302ModelMcaNofScansPresetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mcaHistoSizeChanged:)
                         name : ORSIS3302ModelMcaHistoSizeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mcaPileupEnabledChanged:)
                         name : ORSIS3302ModelMcaPileupEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mcaModeChanged:)
                         name : ORSIS3302ModelMcaModeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(mcaStatusChanged:)
                         name : ORSIS3302McaStatusChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(mcaEnergyDividerChanged:)
                         name : ORSIS3302ModelMcaEnergyDividerChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mcaEnergyMultiplierChanged:)
                         name : ORSIS3302ModelMcaEnergyMultiplierChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mcaEnergyOffsetChanged:)
                         name : ORSIS3302ModelMcaEnergyOffsetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mcaUseEnergyCalculationChanged:)
                         name : ORSIS3302ModelMcaUseEnergyCalculationChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(shipTimeRecordAlsoChanged:)
                         name : ORSIS3302ModelShipTimeRecordAlsoChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cfdControlChanged:)
                         name : ORSIS3302ModelCfdControlChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(bufferWrapEnabledChanged:)
                         name : ORSIS3302ModelBufferWrapEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(firmwareVersionChanged:)
                         name : ORSIS3302ModelFirmwareVersionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pulseModeChanged:)
                         name : ORSIS3302ModelPulseModeChanged
						object: model];

}

- (void) registerRates
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter removeObserver:self name:ORRateChangedNotification object:nil];
    
    NSEnumerator* e = [[[model waveFormRateGroup] rates] objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
		
        [notifyCenter removeObserver:self name:ORRateChangedNotification object:obj];
		
        [notifyCenter addObserver : self
                         selector : @selector(waveFormRateChanged:)
                             name : ORRateChangedNotification
                           object : obj];
    }
}


- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self inputInvertedChanged:nil];
	[self triggerOutEnabledChanged:nil];
	[self highEnergySuppressChanged:nil];
	[self adc50KTriggerEnabledChanged:nil];
	[self gtChanged:nil];
	[self thresholdChanged:nil];
	[self highThresholdChanged:nil];
	[self gateLengthChanged:nil];
	[self pulseLengthChanged:nil];
	[self sumGChanged:nil];
	[self peakingTimeChanged:nil];
	[self internalTriggerDelayChanged:nil];
	[self triggerDecimationChanged:nil];
	[self energyDecimationChanged:nil];
	
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];
    [self waveFormRateChanged:nil];
	
	[self lemoOutModeChanged:nil];
	[self lemoInModeChanged:nil];
	[self dacOffsetChanged:nil];
	[self sampleLengthChanged:nil];
	[self sampleStartIndexChanged:nil];
	[self preTriggerDelayChanged:nil];
	[self triggerGateLengthChanged:nil];
	[self energyPeakingTimeChanged:nil];
	[self energyGapTimeChanged:nil];
	[self energySampleStartIndex1Changed:nil];
	[self energySampleStartIndex2Changed:nil];
	[self energyNumberToSumChanged:nil];
	[self energyTauFactorChanged:nil];
	[self energySampleStartIndex3Changed:nil];
	[self energySetShipWaveformChanged:nil];
	[self energySetShipSummedWaveformChanged:nil];
	[self energyGateLengthChanged:nil];
	[self lemoInEnabledMaskChanged:nil];
	[self internalExternalTriggersOredChanged:nil];
	[self extendedThresholdEnabledChanged:nil];
	
	[self internalTriggerEnabledChanged:nil];
	[self externalTriggerEnabledChanged:nil];
	
	[self internalGateEnabledChanged:nil];
	[self externalGateEnabledChanged:nil];
	
	[self runModeChanged:nil];
	[self mcaNofHistoPresetChanged:nil];
	[self mcaLNESetupChanged:nil];
	[self mcaPrescaleFactorChanged:nil];
	[self mcaAutoClearChanged:nil];
	[self mcaNofScansPresetChanged:nil];
	[self mcaHistoSizeChanged:nil];
	[self mcaPileupEnabledChanged:nil];
	[self mcaModeChanged:nil];
	[self mcaStatusChanged:nil];
	[self mcaEnergyDividerChanged:nil];
	[self mcaEnergyMultiplierChanged:nil];
	[self mcaEnergyOffsetChanged:nil];
	[self mcaUseEnergyCalculationChanged:nil];
	[self shipTimeRecordAlsoChanged:nil];
	[self cfdControlChanged:nil];
	[self bufferWrapEnabledChanged:nil];
	[self firmwareVersionChanged:nil];
	[self clockSourceChanged:nil];
	[self pulseModeChanged:nil];
}

#pragma mark •••Interface Management

- (void) pulseModeChanged:(NSNotification*)aNote
{
	[pulseModeButton setIntValue: [model pulseMode]];
}
- (void) firmwareVersionChanged:(NSNotification*)aNote
{
	[firmwareVersionTextField setFloatValue: [model firmwareVersion]];
	[self settingsLockChanged:nil];
}

- (void) shipTimeRecordAlsoChanged:(NSNotification*)aNote
{
	[shipTimeRecordAlsoCB setIntValue: [model shipTimeRecordAlso]];
}

- (void) mcaUseEnergyCalculationChanged:(NSNotification*)aNote
{
	[mcaUseEnergyCalculationButton setIntValue: [model mcaUseEnergyCalculation]];
	[self mcaEnergyCalculationValues];
}

- (void) mcaEnergyCalculationValues
{
	BOOL useEnergyCalc = [model mcaUseEnergyCalculation];
	if(useEnergyCalc){
		if([model mcaHistoSize] == 0)      [mcaEnergyDividerField setIntValue: 0x6];
		else if([model mcaHistoSize] == 1) [mcaEnergyDividerField setIntValue: 0x5];
		else if([model mcaHistoSize] == 2) [mcaEnergyDividerField setIntValue: 0x4];
		else if([model mcaHistoSize] == 3) [mcaEnergyDividerField setIntValue: 0x3];
		[mcaEnergyMultiplierField setIntValue: 0x80];
		[mcaEnergyOffsetField setIntValue: 0x0];
	}
	else {
		[mcaEnergyDividerField setIntValue: [model mcaEnergyDivider]];
		[mcaEnergyMultiplierField setIntValue: [model mcaEnergyMultiplier]];
		[mcaEnergyOffsetField setIntValue: [model mcaEnergyOffset]];
	}
}

- (void) mcaEnergyOffsetChanged:(NSNotification*)aNote
{
	[mcaEnergyOffsetField setIntValue: [model mcaEnergyOffset]];
}

- (void) mcaEnergyMultiplierChanged:(NSNotification*)aNote
{
	[mcaEnergyMultiplierField setIntValue: [model mcaEnergyMultiplier]];
}

- (void) mcaEnergyDividerChanged:(NSNotification*)aNote
{
	[mcaEnergyDividerField setIntValue: [model mcaEnergyDivider]];
}

- (void) mcaStatusChanged:(NSNotification*)aNote
{
	//sorry about the hard-coded indexes --- values from a command list....
	uint32_t acqRegValue = [model mcaStatusResult:0];
	
	BOOL mcaBusy = (acqRegValue & 0x100000) || (acqRegValue & 0x200000);
	[mcaBusyField setStringValue:mcaBusy?@"MCA Busy":@"--"];
	
	[mcaScanHistogramCounterField setIntegerValue:[model mcaStatusResult:1]];
	[mcaMultiScanScanCounterField setIntegerValue:[model mcaStatusResult:2]];
	int i;
	for(i=0;i<kNumSIS3302Channels;i++){
		uint32_t aValue;
		aValue = [model mcaStatusResult:3 + (4*i)];
		if(aValue>100000){
			[[mcaTriggerStartCounterMatrix	cellWithTag:i] setStringValue:[NSString stringWithFormat:@"%uK",aValue/1000]];
		}
		else [[mcaTriggerStartCounterMatrix	cellWithTag:i] setIntegerValue:aValue];

		aValue = [model mcaStatusResult:4 + (4*i)];
		if(aValue>100000){
			[[mcaPileupCounterMatrix	cellWithTag:i] setStringValue:[NSString stringWithFormat:@"%uK",aValue/1000]];
		}
		else [[mcaPileupCounterMatrix	cellWithTag:i] setIntegerValue:aValue];

		aValue = [model mcaStatusResult:5 + (4*i)];
		if(aValue>100000){
			[[mcaEnergy2LowCounterMatrix	cellWithTag:i] setStringValue:[NSString stringWithFormat:@"%uK",aValue/1000]];
		}
		else [[mcaEnergy2LowCounterMatrix	cellWithTag:i] setIntegerValue:aValue];

		aValue = [model mcaStatusResult:6 + (4*i)];
		if(aValue>100000){
			[[mcaEnergy2HighCounterMatrix	cellWithTag:i] setStringValue:[NSString stringWithFormat:@"%uK",aValue/1000]];
		}
		else [[mcaEnergy2HighCounterMatrix	cellWithTag:i] setIntegerValue:aValue];
	}
}

- (void) mcaModeChanged:(NSNotification*)aNote
{
	[mcaModePU selectItemAtIndex: [model mcaMode]];
}

- (void) mcaPileupEnabledChanged:(NSNotification*)aNote
{
	[mcaPileupEnabledCB setIntValue: [model mcaPileupEnabled]];
}

- (void) mcaHistoSizeChanged:(NSNotification*)aNote
{
	[mcaHistoSizePU selectItemAtIndex: [model mcaHistoSize]];
	[self mcaEnergyCalculationValues];
}

- (void) mcaNofScansPresetChanged:(NSNotification*)aNote
{
	[mcaNofScansPresetField setIntegerValue: [model mcaNofScansPreset]];
}

- (void) mcaAutoClearChanged:(NSNotification*)aNote
{
	[mcaAutoClearCB setIntValue: [model mcaAutoClear]];
}

- (void) mcaPrescaleFactorChanged:(NSNotification*)aNote
{
	[mcaPrescaleFactorField setIntegerValue: [model mcaPrescaleFactor]];
}

- (void) mcaLNESetupChanged:(NSNotification*)aNote
{
	[mcaLNESourcePU selectItemAtIndex: [model mcaLNESetup]];
}

- (void) mcaNofHistoPresetChanged:(NSNotification*)aNote
{
	[mcaNofHistoPresetField setIntegerValue: [model mcaNofHistoPreset]];
}

- (void) internalExternalTriggersOredChanged:(NSNotification*)aNote
{
	[internalExternalTriggersOredCB setIntValue: [model internalExternalTriggersOred]];
}

- (void) lemoInEnabledMaskChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<3;i++){
		[[lemoInEnabledMatrix cellWithTag:i] setState:[model lemoInEnabled:i]];
	}
}

- (void) internalTriggerEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<8;i++){
		[[internalTriggerEnabledMatrix cellWithTag:i] setState:[model internalTriggerEnabled:i]];
	}
}

- (void) externalTriggerEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<8;i++){
		[[externalTriggerEnabledMatrix cellWithTag:i] setState:[model externalTriggerEnabled:i]];
	}
}

- (void) extendedThresholdEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<8;i++){
		[[extendedThresholdEnabledMatrix cellWithTag:i] setState:[model extendedThresholdEnabled:i]];
	}
}

- (void) internalGateEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<8;i++){
		[[internalGateEnabledMatrix cellWithTag:i] setState:[model internalGateEnabled:i]];
	}
}

- (void) externalGateEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<8;i++){
		[[externalGateEnabledMatrix cellWithTag:i] setState:[model externalGateEnabled:i]];
	}
}
- (void) energyTauFactorChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<8;i++){
		[[energyTauFactorMatrix cellWithTag:i] setIntValue:[model energyTauFactor:i]];
	}
}

- (void) energyGapTimeChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<4;i++){
		[[energyGapTimeMatrix cellWithTag:i] setIntValue:[model energyGapTime:i]];
	}
}

- (void) energyPeakingTimeChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<4;i++){
		[[energyPeakingTimeMatrix cellWithTag:i] setIntValue:[model energyPeakingTime:i]];
	}
}

- (void) runModeChanged:(NSNotification*)aNote
{
	[runModePU selectItemAtIndex: [model runMode]];
	[lemoInAssignmentsField setStringValue: [model lemoInAssignments]];
	[lemoOutAssignmentsField setStringValue: [model lemoOutAssignments]];
	[runSummaryField setStringValue: [model runSummary]];
	[self settingsLockChanged:nil];
}

- (void) energySampleStartIndex3Changed:(NSNotification*)aNote
{
	[energySampleStartIndex3Field setIntValue: [model energySampleStartIndex3]];
}

- (void) energySampleStartIndex2Changed:(NSNotification*)aNote
{
	[energySampleStartIndex2Field setIntValue: [model energySampleStartIndex2]];
}

- (void) energySampleStartIndex1Changed:(NSNotification*)aNote
{
	[energySampleStartIndex1Field setIntValue: [model energySampleStartIndex1]];
}

- (void) energyNumberToSumChanged:(NSNotification *)aNote
{
	[energyNumberToSumField setIntValue: [model energyNumberToSum]];
}


- (void) energySetShipWaveformChanged:(NSNotification*)aNote
{
	if ([energyShipWaveformButton state] != [model shipEnergyWaveform]) {
		[energyShipWaveformButton setState:[model shipEnergyWaveform]];
	}
	if ([model shipEnergyWaveform]) {
		[energySampleStartIndex3Field setEnabled:YES];
		[energySampleStartIndex2Field setEnabled:YES];
		[energySampleStartIndex1Field setEnabled:YES];
	} else {
		[energySampleStartIndex3Field setEnabled:NO];
		[energySampleStartIndex2Field setEnabled:NO];
		[energySampleStartIndex1Field setEnabled:NO];
	}
	[self settingsLockChanged:nil];
	[runSummaryField setStringValue: [model runSummary]];
}

- (void) energySetShipSummedWaveformChanged:(NSNotification *)aNote
{
	if ([energyShipSummedWaveformButton state] != [model shipSummedWaveform]) {
		[energyShipSummedWaveformButton setState:[model shipSummedWaveform]];
	}
	if ([model shipSummedWaveform]) {
		[energySampleStartIndex3Field setEnabled:NO];
		[energySampleStartIndex2Field setEnabled:NO];
		[energySampleStartIndex1Field setEnabled:YES];
	} else {
		[energySampleStartIndex3Field setEnabled:NO];
		[energySampleStartIndex2Field setEnabled:NO];
		[energySampleStartIndex1Field setEnabled:NO];
	}
	[self settingsLockChanged:nil];
	[energyBufferAssignmentField setStringValue: [model energyBufferAssignment]];
	[runSummaryField setStringValue: [model runSummary]];
}

- (void) lemoInModeChanged:(NSNotification*)aNote
{
	[lemoInModePU selectItemAtIndex: [model lemoInMode]];
	[lemoInAssignmentsField setStringValue: [model lemoInAssignments]];
}

- (void) lemoOutModeChanged:(NSNotification*)aNote
{
	[lemoOutModePU selectItemAtIndex: [model lemoOutMode]];
	[lemoOutAssignmentsField setStringValue: [model lemoOutAssignments]];
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
	[clockSourcePU selectItemAtIndex: [model clockSource]];
}

- (void) inputInvertedChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[inputInvertedMatrix cellWithTag:i] setState:[model inputInverted:i]];
	}
}

- (void) triggerOutEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[triggerOutEnabledMatrix cellWithTag:i] setState:[model triggerOutEnabled:i]];
	}
}
- (void) highEnergySuppressChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[highEnergySuppressMatrix cellWithTag:i] setState:[model highEnergySuppress:i]];
	}
	[self settingsLockChanged:nil];
}
- (void) adc50KTriggerEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[adc50KTriggerEnabledMatrix cellWithTag:i] setState:[model adc50KTriggerEnabled:i]];
	}
}

- (void) bufferWrapEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Groups;i++){
		[[bufferWrapEnabledMatrix cellWithTag:i] setState:[model bufferWrapEnabled:i]];
	}
	[self settingsLockChanged:nil];
}

- (void) gtChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[gtMatrix cellWithTag:i] setState:[model gt:i]];
	}
}

- (void) thresholdChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		//float volts = (0.0003*[model threshold:i])-5.0;
		[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
	}
}

- (void) highThresholdChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[highThresholdMatrix cellWithTag:i] setIntValue:[model highThreshold:i]];
	}
}

- (void) cfdControlChanged:(NSNotification*)aNote
{
	[cfdControl0 selectItemAtIndex:[model cfdControl:0]];
	[cfdControl1 selectItemAtIndex:[model cfdControl:1]];
	[cfdControl2 selectItemAtIndex:[model cfdControl:2]];
	[cfdControl3 selectItemAtIndex:[model cfdControl:3]];
	[cfdControl4 selectItemAtIndex:[model cfdControl:4]];
	[cfdControl5 selectItemAtIndex:[model cfdControl:5]];
	[cfdControl6 selectItemAtIndex:[model cfdControl:6]];
	[cfdControl7 selectItemAtIndex:[model cfdControl:7]];
	
	[self settingsLockChanged:nil];
}

- (void) sampleLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels/2;i++){
		[[sampleLengthMatrix cellWithTag:i] setIntValue:[model sampleLength:i]];
	}
	[runSummaryField setStringValue: [model runSummary]];
}

- (void) energyGateLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels/2;i++){
		[[energyGateLengthMatrix cellWithTag:i] setIntValue:[model energyGateLength:i]];
	}
}

- (void) triggerGateLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels/2;i++){
		[[triggerGateLengthMatrix cellWithTag:i] setIntValue:[model triggerGateLength:i]];
	}
}

- (void) preTriggerDelayChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels/2;i++){
		[[preTriggerDelayMatrix cellWithTag:i] setIntValue:[model preTriggerDelay:i]];
	}
}

- (void) sampleStartIndexChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels/2;i++){
		[[sampleStartIndexMatrix cellWithTag:i] setIntValue:[model sampleStartIndex:i]];
	}
}

- (void) dacOffsetChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[dacOffsetMatrix cellWithTag:i] setIntValue:[model dacOffset:i]];
	}
}

- (void) gateLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[gateLengthMatrix cellWithTag:i] setIntValue:[model gateLength:i]];
	}
}

- (void) pulseLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[pulseLengthMatrix cellWithTag:i] setIntValue:[model pulseLength:i]];
	}
}

- (void) sumGChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[sumGMatrix cellWithTag:i] setIntValue:[model sumG:i]];
	}
}

- (void) peakingTimeChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[peakingTimeMatrix cellWithTag:i] setIntValue:[model peakingTime:i]];
	}
}

- (void) internalTriggerDelayChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3302Channels;i++){
		[[internalTriggerDelayMatrix cellWithTag:i] setIntValue:[model internalTriggerDelay:i]];
	}
}

- (void) triggerDecimationChanged:(NSNotification*)aNote
{
	[triggerDecimation0 selectItemAtIndex:[model triggerDecimation:0]];
	[triggerDecimation1 selectItemAtIndex:[model triggerDecimation:1]];
	[triggerDecimation2 selectItemAtIndex:[model triggerDecimation:2]];
	[triggerDecimation3 selectItemAtIndex:[model triggerDecimation:3]];
}

- (void) energyDecimationChanged:(NSNotification*)aNote
{
	[energyDecimation0 selectItemAtIndex:[model energyDecimation:0]];
	[energyDecimation1 selectItemAtIndex:[model energyDecimation:1]];
	[energyDecimation2 selectItemAtIndex:[model energyDecimation:2]];
	[energyDecimation3 selectItemAtIndex:[model energyDecimation:3]];
}

- (void) waveFormRateChanged:(NSNotification*)aNote
{
    ORRate* theRateObj = [aNote object];		
    [[rateTextFields cellWithTag:[theRateObj tag]] setFloatValue: [theRateObj rate]];
    [rate0 setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)aNotification
{
	ORRateGroup* theRateObj = [aNotification object];
	if(aNotification == nil || [model waveFormRateGroup] == theRateObj){
		
		[totalRateText setFloatValue: [theRateObj totalRate]];
		[totalRate setNeedsDisplay:YES];
	}
}

- (void) rateGroupChanged:(NSNotification*)aNote
{
    [self registerRates];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORSIS3302SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem 
{
	if ([menuItem action] == @selector(runModeAction:)) {
		if([menuItem tag] == 0  && [model firmwareVersion] >= 15) return NO;
		else return YES;
    }
	else if ([menuItem action] == @selector(clockSourceAction:)) {
		if([menuItem tag] == 0) return NO;
		else return YES;
    }
    return YES;
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSIS3302SettingsLock];
    BOOL locked = [gSecurity isLocked:ORSIS3302SettingsLock];
	BOOL firmwareGEV15xx = [model firmwareVersion] >= 15;
    BOOL mcaMode = (([model runMode] == kMcaRunMode) && !firmwareGEV15xx);
	
	[settingLockButton			setState: locked];

    [runModePU					setEnabled:!locked && !runInProgress];
    [pulseModeButton			setEnabled:!locked && !runInProgress];
	
    [addressText				setEnabled:!locked && !runInProgress];
    [initButton					setEnabled:!lockedOrRunningMaintenance];
	[briefReportButton			setEnabled:!lockedOrRunningMaintenance];
	[regDumpButton				setEnabled:!lockedOrRunningMaintenance];
	[probeButton				setEnabled:!lockedOrRunningMaintenance];
	
    [internalExternalTriggersOredCB	setEnabled:!lockedOrRunningMaintenance];
	[energyTauFactorMatrix			setEnabled:!lockedOrRunningMaintenance];
	[energyGapTimeMatrix			setEnabled:!lockedOrRunningMaintenance];
	[energyPeakingTimeMatrix		setEnabled:!lockedOrRunningMaintenance];
	[triggerGateLengthMatrix		setEnabled:!lockedOrRunningMaintenance];
	[preTriggerDelayMatrix			setEnabled:!lockedOrRunningMaintenance];
	[lemoInModePU					setEnabled:!lockedOrRunningMaintenance];
	[lemoOutModePU					setEnabled:!lockedOrRunningMaintenance];

	[clockSourcePU					setEnabled:!lockedOrRunningMaintenance];
	[triggerDecimation0				setEnabled:!lockedOrRunningMaintenance];
	[triggerDecimation1				setEnabled:!lockedOrRunningMaintenance];
	[triggerDecimation2				setEnabled:!lockedOrRunningMaintenance];
	[triggerDecimation3				setEnabled:!lockedOrRunningMaintenance];
	[energyDecimation0				setEnabled:!lockedOrRunningMaintenance];
	[energyDecimation1				setEnabled:!lockedOrRunningMaintenance];
	[energyDecimation2				setEnabled:!lockedOrRunningMaintenance];
	[energyDecimation3				setEnabled:!lockedOrRunningMaintenance];

	[gtMatrix						setEnabled:!lockedOrRunningMaintenance];
	[inputInvertedMatrix			setEnabled:!lockedOrRunningMaintenance];
	[thresholdMatrix				setEnabled:!lockedOrRunningMaintenance];
	[internalTriggerEnabledMatrix	setEnabled:!lockedOrRunningMaintenance];
	[externalTriggerEnabledMatrix	setEnabled:!lockedOrRunningMaintenance];
	[internalGateEnabledMatrix		setEnabled:!lockedOrRunningMaintenance];
	[externalGateEnabledMatrix		setEnabled:!lockedOrRunningMaintenance];
	[internalTriggerDelayMatrix		setEnabled:!lockedOrRunningMaintenance];
	[dacOffsetMatrix				setEnabled:!lockedOrRunningMaintenance];
	[gateLengthMatrix				setEnabled:!lockedOrRunningMaintenance];
	[pulseLengthMatrix				setEnabled:!lockedOrRunningMaintenance];
	[sumGMatrix						setEnabled:!lockedOrRunningMaintenance];
	[peakingTimeMatrix				setEnabled:!lockedOrRunningMaintenance];
	
	[lemoInEnabledMatrix			setEnabled:!lockedOrRunningMaintenance];
	[triggerOutEnabledMatrix		setEnabled:!lockedOrRunningMaintenance];
	
	//mca specific
	[adc50KTriggerEnabledMatrix setEnabled:!lockedOrRunningMaintenance && mcaMode];
	[mcaModePU					setEnabled:!lockedOrRunningMaintenance && mcaMode];
    [mcaHistoSizePU				setEnabled:!lockedOrRunningMaintenance && mcaMode];
    [mcaLNESourcePU				setEnabled:!lockedOrRunningMaintenance && mcaMode];
    [mcaPileupEnabledCB			setEnabled:!lockedOrRunningMaintenance && mcaMode];
    [mcaAutoClearCB				setEnabled:!lockedOrRunningMaintenance && mcaMode];
    [mcaNofScansPresetField		setEnabled:!lockedOrRunningMaintenance && mcaMode];
    [mcaPrescaleFactorField		setEnabled:!lockedOrRunningMaintenance && mcaMode];
    [mcaNofHistoPresetField		setEnabled:!lockedOrRunningMaintenance && mcaMode];
	
	BOOL useEnergyCalc = [model mcaUseEnergyCalculation];
	[mcaUseEnergyCalculationButton	setEnabled:!lockedOrRunningMaintenance && mcaMode];
	[mcaEnergyOffsetField		setEnabled:!lockedOrRunningMaintenance && mcaMode && !useEnergyCalc];
    [mcaEnergyMultiplierField	setEnabled:!lockedOrRunningMaintenance && mcaMode && !useEnergyCalc];
    [mcaEnergyDividerField		setEnabled:!lockedOrRunningMaintenance && mcaMode && !useEnergyCalc];

	//can't be changed during a run or the card and probably the sbc will be hosed.
	[sampleLengthMatrix				setEnabled:!locked && !runInProgress];
	[bufferWrapEnabledMatrix		setEnabled:!locked && !runInProgress && firmwareGEV15xx];
	//	[energySampleStartIndex3Field	setEnabled:!locked && !runInProgress];
	//	[energySampleStartIndex2Field	setEnabled:!locked && !runInProgress];
	//	[energySampleStartIndex1Field	setEnabled:!locked && !runInProgress];
	
	
	if(![model shipSummedWaveform])	[energyShipWaveformButton		setEnabled:!locked && !runInProgress];
	else [energyShipWaveformButton			setEnabled:NO];
	if(![model shipEnergyWaveform])	[energyShipSummedWaveformButton setEnabled:!locked && !runInProgress && firmwareGEV15xx];
	else [energyShipSummedWaveformButton	setEnabled:NO];
	if([model shipSummedWaveform]) [energyNumberToSumField			setEnabled:!lockedOrRunningMaintenance && firmwareGEV15xx];
	else [energyNumberToSumField			setEnabled:NO];
	
	int i;
	
	for(i=0;i<kNumSIS3302Channels;i++){
		if([model highEnergySuppress:i] && ([model cfdControl:i]!=0))[[highThresholdMatrix cellWithTag:i]setEnabled:!locked && !runInProgress];
		else [[highThresholdMatrix cellWithTag:i]	setEnabled:NO];
	}
		
	for(i=0;i<kNumSIS3302Groups;i++){
		if([model bufferWrapEnabled:i])[[sampleStartIndexMatrix	cellWithTag:i]setEnabled:!locked && !runInProgress];
		else [[sampleStartIndexMatrix cellWithTag:i]	setEnabled:NO];
	}
	
	for(i=0;i<kNumSIS3302Channels;i++){
		if([model cfdControl:i]!=0)[[highEnergySuppressMatrix cellWithTag:i]setEnabled:!locked && !runInProgress];
		else [[highEnergySuppressMatrix cellWithTag:i]	setEnabled:NO];
	}
	
	[cfdControl0					setEnabled:!lockedOrRunningMaintenance && firmwareGEV15xx];
	[cfdControl1					setEnabled:!lockedOrRunningMaintenance && firmwareGEV15xx];
	[cfdControl2					setEnabled:!lockedOrRunningMaintenance && firmwareGEV15xx];
	[cfdControl3					setEnabled:!lockedOrRunningMaintenance && firmwareGEV15xx];
	[cfdControl4					setEnabled:!lockedOrRunningMaintenance && firmwareGEV15xx];
	[cfdControl5					setEnabled:!lockedOrRunningMaintenance && firmwareGEV15xx];
	[cfdControl6					setEnabled:!lockedOrRunningMaintenance && firmwareGEV15xx];
	[cfdControl7					setEnabled:!lockedOrRunningMaintenance && firmwareGEV15xx];
	
	
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3302 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3302 Card (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
    [addressText setIntegerValue: [model baseAddress]];
}

- (void) integrationChanged:(NSNotification*)aNotification
{
    ORRateGroup* theRateGroup = [aNotification object];
    if(aNotification == nil || [model waveFormRateGroup] == theRateGroup || [aNotification object] == model){
        double dValue = [[model waveFormRateGroup] integrationTime];
        [integrationStepper setDoubleValue:dValue];
        [integrationText setDoubleValue: dValue];
    }
}


- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [rate0 xAxis]){
		[model setMiscAttributes:[[rate0 xAxis]attributes] forKey:@"RateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [totalRate xAxis]){
		[model setMiscAttributes:[[totalRate xAxis]attributes] forKey:@"TotalRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot xAxis]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot xAxis]attributes] forKey:@"TimeRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot yAxis]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot yAxis]attributes] forKey:@"TimeRateYAttributes"];
	};
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"RateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"RateXAttributes"];
		if(attrib){
			[[rate0 xAxis] setAttributes:attrib];
			[rate0 setNeedsDisplay:YES];
			[[rate0 xAxis] setNeedsDisplay:YES];
			[rateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TotalRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TotalRateXAttributes"];
		if(attrib){
			[[totalRate xAxis] setAttributes:attrib];
			[totalRate setNeedsDisplay:YES];
			[[totalRate xAxis] setNeedsDisplay:YES];
			[totalRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateXAttributes"];
		if(attrib){
			[(ORAxis*)[timeRatePlot xAxis] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateYAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateYAttributes"];
		if(attrib){
			[(ORAxis*)[timeRatePlot yAxis] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot yAxis] setNeedsDisplay:YES];
			[timeRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
}

- (void) updateTimePlot:(NSNotification*)aNote
{
    if(!aNote || ([aNote object] == [[model waveFormRateGroup]timeRate])){
        [timeRatePlot setNeedsDisplay:YES];
    }
}

#pragma mark •••Actions

- (void) pulseModeAction:(id)sender
{
	[model setPulseMode:[sender intValue]];	
}

- (void) shipTimeRecordAlsoAction:(id)sender
{
	[model setShipTimeRecordAlso:[sender intValue]];	
}

- (IBAction) mcaUseEnergyCalculationAction:(id)sender
{
	[model setMcaUseEnergyCalculation:[sender intValue]];
	[self settingsLockChanged:nil];
}

- (IBAction) mcaEnergyOffsetAction:(id)sender
{
	[model setMcaEnergyOffset:[sender intValue]];	
}

- (IBAction) mcaEnergyMultiplierAction:(id)sender
{
	[model setMcaEnergyMultiplier:[sender intValue]];	
}

- (IBAction) mcaEnergyDividerAction:(id)sender
{
	[model setMcaEnergyDivider:[sender intValue]];	
}

- (IBAction) mcaModeAction:(id)sender
{
	[model setMcaMode:(int)[sender indexOfSelectedItem]];
}

- (IBAction) mcaPileupEnabledAction:(id)sender
{
	[model setMcaPileupEnabled:[sender intValue]];	
}

- (IBAction) mcaHistoSizeAction:(id)sender
{
	[model setMcaHistoSize:(int)[sender indexOfSelectedItem]];
}

- (IBAction) mcaNofScansPresetAction:(id)sender
{
	[model setMcaNofScansPreset:[sender intValue]];	
}

- (IBAction) mcaAutoClearAction:(id)sender
{
	[model setMcaAutoClear:[sender intValue]];	
}

- (IBAction) mcaPrescaleFactorAction:(id)sender
{
	[model setMcaPrescaleFactor:[sender intValue]];	
}

- (IBAction) mcaLNESetupAction:(id)sender
{
	[model setMcaLNESetup:[sender indexOfSelectedItem]];	
}

- (IBAction) mcaNofHistoPresetAction:(id)sender
{
	[model setMcaNofHistoPreset:[sender intValue]];	
}

- (IBAction) internalGateEnabledMaskAction:(id)sender
{
	[model setInternalGateEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) externalGateEnabledMaskAction:(id)sender
{
	[model setExternalGateEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) internalTriggerEnabledMaskAction:(id)sender
{
	[model setInternalTriggerEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) externalTriggerEnabledMaskAction:(id)sender
{
	[model setExternalTriggerEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) extendedThresholdEnabledMaskAction:(id)sender
{
	[model setExtendedThresholdEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) internalExternalTriggersOredAction:(id)sender
{
	[model setInternalExternalTriggersOred:[sender intValue]];	
}

- (IBAction) lemoInEnabledMaskAction:(id)sender
{
	[model setLemoInEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) runModeAction:(id)sender
{
	[model setRunMode:(int)[sender indexOfSelectedItem]];
}

- (IBAction) energySampleStartIndex3Action:(id)sender
{
	[model setEnergySampleStartIndex3:[sender intValue]];	
}

- (IBAction) energySampleStartIndex2Action:(id)sender
{
	[model setEnergySampleStartIndex2:[sender intValue]];	
}

- (IBAction) energySampleStartIndex1Action:(id)sender
{
	[model setEnergySampleStartIndex1:[sender intValue]];	
}

- (IBAction) energyNumberToSumAction:(id)sender
{
	[model setEnergyNumberToSum:[sender intValue]];
}

- (IBAction) energyShipWaveformAction:(id)sender
{
	if ([sender state] == 1) {
		[model setShipEnergyWaveform:YES];
		[energySampleStartIndex3Field setEnabled:YES];
		[energySampleStartIndex2Field setEnabled:YES];
		[energySampleStartIndex1Field setEnabled:YES];
	} else {
		[model setShipEnergyWaveform:NO];
		[energySampleStartIndex3Field setEnabled:NO];
		[energySampleStartIndex2Field setEnabled:NO];
		[energySampleStartIndex1Field setEnabled:NO];
	}
}

- (IBAction) energyShipSummedWaveformAction:(id)sender
{
	if ([sender state] == 1) {
		[model setShipSummedWaveform:YES];
		[energySampleStartIndex3Field setEnabled:NO];
		[energySampleStartIndex2Field setEnabled:NO];
		[energySampleStartIndex1Field setEnabled:YES];
	} else {
		[model setShipSummedWaveform:NO];
		[energySampleStartIndex3Field setEnabled:NO];
		[energySampleStartIndex2Field setEnabled:NO];
		[energySampleStartIndex1Field setEnabled:NO];
	}
}

- (IBAction) lemoInModeAction:(id)sender
{
	[model setLemoInMode:[sender indexOfSelectedItem]];	
}

- (IBAction) lemoOutModeAction:(id)sender
{
	[model setLemoOutMode:[sender indexOfSelectedItem]];	
}

//hardware actions
- (IBAction) probeBoardAction:(id)sender;
{
	@try {
		[model readModuleID:YES];
	}
	@catch (NSException* localException) {
		NSLog(@"Probe of SIS 3300 board ID failed\n");
        ORRunAlertPanel([localException name], @"%@\nProbe Failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) clockSourceAction:(id)sender
{
	[model setClockSource:(int)[sender indexOfSelectedItem]];
}

- (IBAction) triggerOutEnabledAction:(id)sender
{
	[model setTriggerOutEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) highEnergySuppressAction:(id)sender
{
	[model setHighEnergySuppress:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) inputInvertedAction:(id)sender
{
	[model setInputInverted:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) adc50KTriggerEnabledAction:(id)sender
{
	[model setAdc50KTriggerEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) gtAction:(id)sender
{
	[model setGtBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) bufferWrapEnabledAction:(id)sender
{
	[model setBufferWrapEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) triggerDecimationAction:(id)sender
{
	if([sender indexOfSelectedItem] != [model triggerDecimation:[sender tag]]){
		[model setTriggerDecimation:[sender tag] withValue:[sender indexOfSelectedItem]];
	}
}

- (IBAction) energyDecimationAction:(id)sender
{
    if([sender indexOfSelectedItem] != [model energyDecimation:[sender tag]]){
		[model setEnergyDecimation:[sender tag] withValue:[sender indexOfSelectedItem]];
	}
}

- (IBAction) thresholdAction:(id)sender
{
    if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) highThresholdAction:(id)sender
{
    if([sender intValue] != [model highThreshold:[[sender selectedCell] tag]]){
		[model setHighThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) cfdControlAction:(id)sender
{
    //if([sender intValue] != [model cfdControl:[sender tag]]){
		[model setCfdControl:[sender tag] withValue:[sender indexOfSelectedItem]];
	//}
}

- (IBAction) triggerGateLengthAction:(id)sender
{
    if([sender intValue] != [model triggerGateLength:[[sender selectedCell] tag]]){
		[model setTriggerGateLength:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) preTriggerDelayAction:(id)sender
{
    if([sender intValue] != [model preTriggerDelay:[[sender selectedCell] tag]]){
		[model setPreTriggerDelay:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) sampleStartIndexAction:(id)sender
{
	if([sender intValue] != [model sampleStartIndex:(int)[[sender selectedCell] tag]]){
		[model setSampleStartIndex:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) sampleLengthAction:(id)sender
{
    if([sender intValue] != [model sampleLength:[[sender selectedCell] tag]]){
		[model setSampleLength:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) dacOffsetAction:(id)sender
{
    if([sender intValue] != [model dacOffset:[[sender selectedCell] tag]]){
		[model setDacOffset:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) gateLengthAction:(id)sender
{
    if([sender intValue] != [model gateLength:[[sender selectedCell] tag]]){
		[model setGateLength:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) pulseLengthAction:(id)sender
{
    if([sender intValue] != [model pulseLength:[[sender selectedCell] tag]]){
		[model setPulseLength:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) sumGAction:(id)sender
{
    if([sender intValue] != [model sumG:[[sender selectedCell] tag]]){
		[model setSumG:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) peakingTimeAction:(id)sender
{
    if([sender intValue] != [model peakingTime:[[sender selectedCell] tag]]){
		[model setPeakingTime:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) internalTriggerDelayAction:(id)sender
{
    if([sender intValue] != [model internalTriggerDelay:[[sender selectedCell] tag]]){
		[model setInternalTriggerDelay:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) energyTauFactorAction:(id)sender
{
    if([sender intValue] != [model energyTauFactor:[[sender selectedCell] tag]]){
		[model setEnergyTauFactor:[[sender selectedCell] tag] withValue:[sender intValue]];	
	}
}

- (IBAction) energyGapTimeAction:(id)sender
{
    if([sender intValue] != [model energyGapTime:[[sender selectedCell] tag]]){
		[model setEnergyGapTime:[[sender selectedCell] tag] withValue:[sender intValue]];	
	}
}

- (IBAction) energyPeakingTimeAction:(id)sender
{
    if([sender intValue] != [model energyPeakingTime:[[sender selectedCell] tag]]){
		[model setEnergyPeakingTime:[[sender selectedCell] tag] withValue:[sender intValue]];	
	}
}


- (IBAction) baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORSIS3302SettingsLock to:[sender intValue] forWindow:[self window]];
}

-(IBAction) initBoard:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];		//initialize and load hardward
        NSLog(@"Initialized SIS3302 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset and Init of SIS3302 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3302 Reset and Init", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model waveFormRateGroup]integrationTime]){
        [model setRateIntegrationTime:[sender doubleValue]];		
    }
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:settingSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:rateSize];
		[[self window] setContentView:tabView];
    }
	
    NSString* key = [NSString stringWithFormat: @"orca.ORSIS3302%d.selectedtab",[model slot]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

- (IBAction) briefReport:(id)sender
{
    @try {
		[self endEditing];
		[model initBoard];
		[model briefReport];
	}
	@catch(NSException* localException) {
        NSLog(@"SIS3302 Report FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3302 Report FAILED", @"OK", nil, nil,
                        localException);
    }

}

- (IBAction) regDump:(id)sender
{
	BOOL ok = NO;
    @try {
		[self endEditing];
		[model initBoard];
		ok = YES;
	}
	@catch(NSException* localException) {
        NSLog(@"SIS3302 Reg Dump FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3302 Reg Dump FAILED", @"OK", nil, nil,
                        localException);
    }
	if(ok)[model regDump];
}


#pragma mark •••Data Source

- (double) getBarValue:(int)tag
{
	
	return [[[[model waveFormRateGroup]rates] objectAtIndex:tag] rate];
}

- (int) numberPointsInPlot:(id)aPlotter
{
	return (int)[[[model waveFormRateGroup]timeRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
	int count = (int)[[[model waveFormRateGroup]timeRate] count];
	int index = count-i-1;
	*yValue = [[[model waveFormRateGroup] timeRate]valueAtIndex:index];
	*xValue = [[[model waveFormRateGroup] timeRate]timeSampledAtIndex:index];
}

@end
