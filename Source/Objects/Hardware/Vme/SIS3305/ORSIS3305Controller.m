 //-------------------------------------------------------------------------
//  ORSIS3305Controller.h
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
#import "ORSIS3305Controller.h"
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

@implementation ORSIS3305Controller

-(id)init
{
    self = [super initWithWindowNibName:@"SIS3305"];
    
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    basicSize       = NSMakeSize(840  ,660);
    settingSize     = NSMakeSize(700  ,600);
    rateSize		= NSMakeSize(790  ,300);
    miscSize        = NSMakeSize(450  ,250);
    
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
	
    NSString* key = [NSString stringWithFormat: @"orca.SIS3305%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
				
	NSNumberFormatter *rateFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[rateFormatter setFormat:@"##0.0;0;-##0.0"];
	
    NSNumberFormatter *hexFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    [hexFormatter setFormat:@"##%x;0"];
    
	int i;
//	for(i=0;i<kNumSIS3305Channels/kNumSIS3305Groups;i++){
//		NSCell* theCell = [GTThresholdOn14Matrix cellAtRow:i column:0];
//		[theCell setFormatter:numberFormatter];
//        theCell = [GTThresholdOn58Matrix cellAtRow:i column:0];
//        [theCell setFormatter:numberFormatter];
//        theCell = [GTThresholdOff14Matrix cellAtRow:i column:0];
//        [theCell setFormatter:numberFormatter];
//        theCell = [GTThresholdOff58Matrix cellAtRow:i column:0];
//        [theCell setFormatter:numberFormatter];
//	}
//    for(i=0;i<kNumSIS3305Channels/kNumSIS3305Groups;i++){
//        NSCell* theCell = [LTThresholdOn14Matrix cellAtRow:i column:0];
//        [theCell setFormatter:numberFormatter];
//        theCell = [LTThresholdOn58Matrix cellAtRow:i column:0];
//        [theCell setFormatter:numberFormatter];
//        theCell = [LTThresholdOff14Matrix cellAtRow:i column:0];
//        [theCell setFormatter:numberFormatter];
//        theCell = [LTThresholdOff58Matrix cellAtRow:i column:0];
//        [theCell setFormatter:numberFormatter];
//    }

    //	for(i=0;i<kNumSIS3305Channels;i++){
//		NSCell* theCell = [highThresholdMatrix cellAtRow:i column:0];
//		[theCell setFormatter:numberFormatter];
//	}
	for(i=0;i<kNumSIS3305Channels;i++){
		NSCell* theCell = [rateTextFields cellAtRow:i column:0];
		[theCell setFormatter:rateFormatter];
	}
		
    for (i=0;i<kNumSIS3305ReadRegs;i++){
        NSString* s = [NSString stringWithFormat:@"(0x%04x) %@",[model registerOffsetAt:i], [model registerNameAt:i]];
        
        [registerIndexPU insertItemWithTitle:s	atIndex:i];
        [[registerIndexPU itemAtIndex:i] setEnabled:YES];

    }
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];

	[rate0 setNumber:8 height:10 spacing:5];
    
	[super awakeFromNib];
	
}

#pragma mark - Notifications
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
                         name : ORSIS3305SettingsLock
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORSIS3305RateGroupChangedNotification
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
                     selector : @selector(channelEnabledChanged:)
                         name : ORSIS3305ChannelEnabledChanged
                       object : model];
    
//    [notifyCenter addObserver : self
//                     selector : @selector(tapDelayChanged:)
//                         name : ORSIS3305TapDelayChanged
//                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(thresholdModeChanged:)
                         name : ORSIS3305ThresholdModeChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(thresholdModeChanged:)
                         name : ORSIS3305LTThresholdEnabledChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(thresholdModeChanged:)
                         name : ORSIS3305GTThresholdEnabledChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(GTThresholdOnChanged:)
                         name : ORSIS3305GTThresholdOnChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(GTThresholdOffChanged:)
                         name : ORSIS3305GTThresholdOffChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(LTThresholdOnChanged:)
                         name : ORSIS3305LTThresholdOnChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(LTThresholdOffChanged:)
                         name : ORSIS3305LTThresholdOffChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(TDCLogicEnabledChanged:)
                         name : ORSIS3305TDCMeasurementEnabledChanged
                        object: model];

    // FIX: should add in the LED mode parts
//    [notifyCenter addObserver : self
//                     selector : @selector(ledApplicationModeChanged:)
//                         name : ORSIS3305LEDApplicationModeChanged
//                       object : model];

    
    // event config items
    
    [notifyCenter addObserver: self
                     selector: @selector(eventSavingModeChanged:)
                         name: ORSIS3305EventSavingModeChanged
                       object: model];

    [notifyCenter addObserver: self
                     selector: @selector(ADCGateModeEnabledChanged:)
                         name: ORSIS3305ADCGateModeEnabledChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(globalTriggerEnabledChanged:)
                         name: ORSIS3305GlobalTriggerEnabledChanged
                       object: model];

    [notifyCenter addObserver: self
                     selector: @selector(internalTriggerEnabledChanged:)
                         name: ORSIS3305InternalTriggerEnabledChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(startEventSamplingWithExtTrigEnabledChanged:)
                         name: ORSIS3305StartEventSamplingWithExtTrigEnabledChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(clearTimestampWhenSamplingEnabledEnabledChanged:)
                         name: ORSIS3305ClearTimestampWhenSamplingEnabledEnabledChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(grayCodeEnabledChanged:)
                         name: ORSIS3305GrayCodeEnabledChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(clearTimestampDisabledChanged:)
                         name: ORSIS3305ClearTimestampDisabledChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(waitPreTrigTimeBeforeDirectMemTrigChanged:)
                         name: ORSIS3305WaitPreTrigTimeBeforeDirectMemTrigChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(disableDirectMemoryHeaderChanged:)
                         name: ORSIS3305DirectMemoryHeaderDisabledChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(channelModeChanged:)
                         name: ORSIS3305ChannelModeChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(bandwidthChanged:)
                         name: ORSIS3305BandwidthChanged
                       object: model];

    
    [notifyCenter addObserver: self
                     selector: @selector(testModeChanged:)
                         name: ORSIS3305TestModeChanged
                       object: model];

    [notifyCenter addObserver: self
                     selector: @selector(adcOffsetChanged:)
                         name: ORSIS3305AdcOffsetChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(adcGainChanged:)
                         name: ORSIS3305AdcGainChanged
                       object: model];
    
    [notifyCenter addObserver: self
                     selector: @selector(adcPhaseChanged:)
                         name: ORSIS3305AdcPhaseChanged
                       object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoOutSelectTriggerChanged:)
                         name : ORSIS3305LemoOutSelectTriggerChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoOutSelectTriggerInChanged:)
                         name : ORSIS3305LemoOutSelectTriggerInChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoOutSelectTriggerInPulseChanged:)
                         name : ORSIS3305LemoOutSelectTriggerInPulseChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoOutSelectTriggerInPulseWithSampleAndTDCChanged:)
                         name : ORSIS3305LemoOutSelectTriggerInPulseWithSampleAndTDCChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoOutSelectSampleLogicArmedChanged:)
                         name : ORSIS3305LemoOutSelectSampleLogicArmedChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoOutSelectSampleLogicEnabledChanged:)
                         name : ORSIS3305LemoOutSelectSampleLogicEnabledChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoOutSelectKeyOutputPulseChanged:)
                         name : ORSIS3305LemoOutSelectKeyOutputPulseChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoOutSelectControlLemoTriggerOutChanged:)
                         name : ORSIS3305LemoOutSelectControlLemoTriggerOutChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoOutSelectExternalVetoChanged:)
                         name : ORSIS3305LemoOutSelectExternalVetoChanged
                        object: model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoOutSelectInternalKeyVetoChanged:)
                         name : ORSIS3305LemoOutSelectInternalKeyVetoChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoOutSelectExternalVetoLengthChanged:)
                         name : ORSIS3305LemoOutSelectExternalVetoLengthChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lemoOutSelectMemoryOverrunVetoChanged:)
                         name : ORSIS3305LemoOutSelectMemoryOverrunVetoChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(enableLemoInputTriggerChanged:)
                         name : ORSIS3305EnableLemoInputTriggerChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(enableLemoInputCountChanged:)
                         name : ORSIS3305EnableLemoInputCountChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(enableLemoInputResetChanged:)
                         name : ORSIS3305EnableLemoInputResetChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(enableLemoInputDirectVetoChanged:)
                         name : ORSIS3305EnableLemoInputDirectVetoChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(sampleLengthChanged:)
                         name : ORSIS3305SampleLengthChanged
                        object: model];
    
    
    
    
	[notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORSIS3305ClockSourceChanged
						object: model];


    [notifyCenter addObserver : self
                     selector : @selector(preTriggerDelayChanged:)
                         name : ORSIS3305ModelPreTriggerDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(runModeChanged:)
                         name : ORSIS3305ModelRunModeChanged
						object: model];

    
    
    
	
	[self registerRates];


    [notifyCenter addObserver : self
                     selector : @selector(shipTimeRecordAlsoChanged:)
                         name : ORSIS3305ModelShipTimeRecordAlsoChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(bufferWrapEnabledChanged:)
                         name : ORSIS3305ModelBufferWrapEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(firmwareVersionChanged:)
                         name : ORSIS3305ModelFirmwareVersionChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(temperatureChanged:)
                         name : ORSIS3305TemperatureChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(writeGainPhaseOffsetEnableChanged:)
                         name : ORSIS3305WriteGainPhaseOffsetChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(pulseModeChanged:)
                         name : ORSIS3305ModelPulseModeChanged
						object: model];
    
    
    // FIX: This needs the action/changed?
    [notifyCenter addObserver : self
                     selector : @selector(null)
                         name : ORSIS3305SampleStartAddressChanged
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

	[self gateLengthChanged:nil];
	[self pulseLengthChanged:nil];
	[self internalTriggerDelayChanged:nil];

    [self ORSIS3305LEDEnabledChanged:nil];
	
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];
    [self waveFormRateChanged:nil];
	
//	[self lemoOutModeChanged:nil];
//	[self lemoInModeChanged:nil];
//	[self dacOffsetChanged:nil];
	[self sampleLengthChanged:nil];
	[self sampleStartIndexChanged:nil];
	[self preTriggerDelayChanged:nil];
	[self triggerGateLengthChanged:nil];

    [self lemoInEnabledMaskChanged:nil];
//	[self internalExternalTriggersOredChanged:nil];
	
	[self internalTriggerEnabledChanged:nil];
	[self externalTriggerEnabledChanged:nil];
	
	[self internalGateEnabledChanged:nil];
	[self externalGateEnabledChanged:nil];
	
	[self runModeChanged:nil];
	[self shipTimeRecordAlsoChanged:nil];
    [self TDCLogicEnabledChanged:nil];
    [self clockSourceChanged:nil];
    
    // group settings
    // event config
    [self eventSavingModeChanged:nil];
    [self globalTriggerEnabledChanged:nil];
    [self internalTriggerEnabledChanged:nil];
    [self startEventSamplingWithExtTrigEnabledChanged:nil];
    [self clearTimestampWhenSamplingEnabledEnabledChanged:nil];
    [self clearTimestampDisabledChanged:nil];
    [self disableDirectMemoryHeaderChanged:nil];
    [self grayCodeEnabledChanged:nil];
//    [self ADCGateModeEnabledChanged:nil];
    [self waitPreTrigTimeBeforeDirectMemTrigChanged:nil];
    
    [self writeGainPhaseOffsetEnableChanged:nil];
    
    [self bandwidthChanged:nil];
    [self testModeChanged:nil];
    [self channelModeChanged:nil];
    
    
    [self lemoOutSelectTriggerChanged:nil];
    [self lemoOutSelectTriggerInChanged:nil];
    [self lemoOutSelectTriggerInPulseChanged:nil];
    [self lemoOutSelectTriggerInPulseWithSampleAndTDCChanged:nil];
    [self lemoOutSelectSampleLogicArmedChanged:nil];
    [self lemoOutSelectSampleLogicEnabledChanged:nil];
    [self lemoOutSelectKeyOutputPulseChanged:nil];
    [self lemoOutSelectControlLemoTriggerOutChanged:nil];
    [self lemoOutSelectExternalVetoChanged:nil];
    [self lemoOutSelectInternalKeyVetoChanged:nil];
    [self lemoOutSelectExternalVetoLengthChanged:nil];
    [self lemoOutSelectMemoryOverrunVetoChanged:nil];
    [self enableLemoInputTriggerChanged:nil];
    [self enableLemoInputCountChanged:nil];
    [self enableLemoInputResetChanged:nil];
    [self enableLemoInputDirectVetoChanged:nil];
    
    
    //channel settings
    [self thresholdModeChanged:nil];
    [self channelEnabledChanged:nil];

    [self GTThresholdOffChanged:nil];
    [self GTThresholdOnChanged:nil];
    [self LTThresholdOffChanged:nil];
    [self LTThresholdOnChanged:nil];
    [self thresholdModeChanged:nil];
    
	[self bufferWrapEnabledChanged:nil];
	[self firmwareVersionChanged:nil];
	[self clockSourceChanged:nil];
	[self pulseModeChanged:nil];

    [self adcGainChanged:nil];
    [self adcOffsetChanged:nil];
    [self adcPhaseChanged:nil];
    
    [self ADCGateModeEnabledChanged:nil];

}

#pragma mark - Interface Management

- (void) pulseModeChanged:(NSNotification*)aNote
{
	[pulseModeButton setIntValue: [model pulseMode]];
}
- (void) firmwareVersionChanged:(NSNotification*)aNote
{
	[firmwareVersionTextField setFloatValue: [model firmwareVersion]];
	[self settingsLockChanged:nil];
}

- (void) temperatureChanged:(NSNotification*)aNote
{
    [temperatureTextField setStringValue:[NSString stringWithFormat:@"%3.1f C",[model temperature]]];
}

- (void) writeGainPhaseOffsetEnableChanged:(NSNotification *)aNote
{
    BOOL value = [model writeGainPhaseOffsetEnabled];
    [writeGainPhaseOffsetEnableCB setIntValue: value];
    [self settingsLockChanged:nil];

}

- (void) shipTimeRecordAlsoChanged:(NSNotification*)aNote
{
	[shipTimeRecordAlsoCB setIntValue: [model shipTimeRecordAlso]];
}

- (void) TDCLogicEnabledChanged:(NSNotification *)aNote
{
    [TDCLogicEnabledCB setIntValue: [model TDCMeasurementEnabled]];
}


- (void) lemoInEnabledMaskChanged:(NSNotification*)aNote
{
//	short i;
//	for(i=0;i<3;i++){
//		[[lemoInEnabledMatrix cellWithTag:i] setState:[model lemoInEnabled:i]];
//	}
}

- (void) channelEnabledChanged:(NSNotification*)aNote
{
    short i;
    short state = 0;
    for(i=0;i<kNumSIS3305Channels;i++){
        state = [model enabled:i];
        [[channelEnabled14Matrix cellWithTag:i] setState:state];
        
        state = [model enabled:(i+4)];
        [[channelEnabled58Matrix cellWithTag:i] setState:state];    // (i+4) is for split matrix
    }
}





#pragma mark -- event config Changed Updaters

- (void) eventSavingModeChanged:(NSNotification*)aNote
{
    [eventSavingMode14PU selectItemAtIndex: [model eventSavingMode:0]]; // 0 is for group 1
    [eventSavingMode58PU selectItemAtIndex: [model eventSavingMode:1]]; // 1 is for group 2
}

- (void) ADCGateModeEnabledChanged:(NSNotification*)aNote
{
    [ADCGateModeEnabled14Button setState: [model ADCGateModeEnabled:0]]; // 0 is for group 1
    [ADCGateModeEnabled58Button setState: [model ADCGateModeEnabled:1]]; // 1 is for group 2
    
    [self settingsLockChanged:nil];
}

- (void) globalTriggerEnabledChanged:(NSNotification*)aNote
{

    [globalTriggerEnable14Button setState:[model globalTriggerEnabledOnGroup:0]];
    [globalTriggerEnable58Button setState:[model globalTriggerEnabledOnGroup:1]];

}

- (void) internalTriggerEnabledChanged:(NSNotification*)aNote
{
    [internalTriggerEnabled14Button setState:[model internalTriggerEnabled:0]];
    [internalTriggerEnabled58Button setState:[model internalTriggerEnabled:1]];
}

- (void) externalTriggerEnabledChanged:(NSNotification*)aNote
{
    // FIX: isn't this a event config thing? Not channel level?
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[externalTriggerEnabledMatrix cellWithTag:i] setState:[model externalTriggerEnabled:i]];
	}
}

- (void) startEventSamplingWithExtTrigEnabledChanged:(NSNotification*)aNote
{

    [startEventSamplingWithExtTrigEnabled14Button setState:[model startEventSamplingWithExtTrigEnabled:0]];
    [startEventSamplingWithExtTrigEnabled58Button setState:[model startEventSamplingWithExtTrigEnabled:1]];
}

- (void) clearTimestampWhenSamplingEnabledEnabledChanged:(NSNotification*)aNote
{
    [clearTimestampWhenSamplingEnabledEnabled14Button setState:[model clearTimestampWhenSamplingEnabledEnabled:0]];
    [clearTimestampWhenSamplingEnabledEnabled58Button setState:[model clearTimestampWhenSamplingEnabledEnabled:1]];
    
}

- (void) grayCodeEnabledChanged:(NSNotification*)aNote
{
    [grayCodeEnable14Button setState:[model grayCodeEnabled:0]];
    [grayCodeEnable58Button setState:[model grayCodeEnabled:1]];
}

- (void) clearTimestampDisabledChanged:(NSNotification*)aNote
{
    [clearTimestampDisabled14Button setState:[model clearTimestampDisabled:0]];
    [clearTimestampDisabled58Button setState:[model clearTimestampDisabled:1]];
}

- (void) disableDirectMemoryHeaderChanged:(NSNotification*)aNote
{
    [disableDirectMemoryHeader14Button setState:[model directMemoryHeaderDisabled:0]];
    [disableDirectMemoryHeader58Button setState:[model directMemoryHeaderDisabled:1]];
}

- (void) waitPreTrigTimeBeforeDirectMemTrigChanged:(NSNotification*)aNote
{
    [waitPreTrigTimeBeforeDirectMemTrig14Button setState:[model waitPreTrigTimeBeforeDirectMemTrig:0]];
    [waitPreTrigTimeBeforeDirectMemTrig58Button setState:[model waitPreTrigTimeBeforeDirectMemTrig:1]];
}


#pragma mark end of event config changed updaters


- (void) channelModeChanged:(NSNotification *)aNote
{
    [channelMode14PU selectItemAtIndex:[model channelMode:0]];
    [channelMode58PU selectItemAtIndex:[model channelMode:1]];
}

- (void) bandwidthChanged:(NSNotification *)aNote
{
    [bandwidth14PU selectItemAtIndex:[model bandwidth:0]];
    [bandwidth58PU selectItemAtIndex:[model bandwidth:1]];
}

- (void) testModeChanged:(NSNotification *)aNote
{
    [testMode14PU selectItemAtIndex:[model testMode:0]];
    [testMode58PU selectItemAtIndex:[model testMode:1]];
}

- (void) adcOffsetChanged:(NSNotification*)aNote
{
    short i;
    for(i=0;i<kNumSIS3305Channels;i++){
        if (i<4)
            [[offset14Matrix cellWithTag:i] setIntegerValue:[model adcOffset:i]];
        else if (i >= 4)
            [[offset58Matrix cellWithTag:(i-4)] setIntegerValue:[model adcOffset:i]];
    }
}

- (void) adcGainChanged:(NSNotification*)aNote
{
    short chPerGroup = kNumSIS3305Channels/kNumSIS3305Groups;
    short chan;
    for (chan=0; chan<chPerGroup; chan++) {
        [[gain14Matrix cellWithTag:chan] setIntegerValue:[model adcGain:chan]];
        [[gain58Matrix cellWithTag:(chan)] setIntegerValue:[model adcGain:(chan+4)]];

    }
}

- (void) adcPhaseChanged:(NSNotification*)aNote
{
    short i;
    for (i=0; i<4; i++) {
        [[phase14Matrix cellWithTag:i] setIntegerValue:[model adcPhase:i]];
        [[phase58Matrix cellWithTag:i] setIntegerValue:[model adcPhase:(i+4)]];
    }
}


- (void) internalGateEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[internalGateEnabledMatrix cellWithTag:i] setState:[model internalGateEnabled:i]];
	}
}

- (void) externalGateEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[externalGateEnabledMatrix cellWithTag:i] setState:[model externalGateEnabled:i]];
	}
}

- (void) runModeChanged:(NSNotification*)aNote
{
	[runModePU selectItemAtIndex: [model runMode]];
//	[lemoInAssignmentsField setStringValue: [model lemoInAssignments]];
//	[lemoOutAssignmentsField setStringValue: [model lemoOutAssignments]];
	[runSummaryField setStringValue: [model runSummary]];
	[self settingsLockChanged:nil];
}


//- (void) lemoInModeChanged:(NSNotification*)aNote
//{
//	[lemoInModePU selectItemAtIndex: [model lemoInMode]];
//	[lemoInAssignmentsField setStringValue: [model lemoInAssignments]];
//}
//
//- (void) lemoOutModeChanged:(NSNotification*)aNote
//{
//	[lemoOutModePU selectItemAtIndex: [model lemoOutMode]];
//	[lemoOutAssignmentsField setStringValue: [model lemoOutAssignments]];
//}



#pragma mark LEMO Out Select Changeds

- (void) controlLemoTriggerOutChanged:(NSNotification*)aNote
{
    [controlLemoTriggerOutButton setState:[model controlLEMOTriggerOut]];
}

- (void) lemoOutSelectTriggerChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<4;i++){   // 4 channels per group
        [[lemoOutSelectTrigger14Matrix cellWithTag:i] setState:[model lemoOutSelectTrigger:i]];
        [[lemoOutSelectTrigger58Matrix cellWithTag:i] setState:[model lemoOutSelectTrigger:(i+4)]];
    }
}

- (void) lemoOutSelectTriggerInChanged:(NSNotification*)aNote
{
    [lemoOutSelectTriggerInButton setState:[model lemoOutSelectTriggerIn]];
}

- (void) lemoOutSelectTriggerInPulseChanged:(NSNotification*)aNote
{
    [lemoOutSelectTriggerInPulseButton setState:[model lemoOutSelectTriggerInPulse]];
}

- (void) lemoOutSelectTriggerInPulseWithSampleAndTDCChanged:(NSNotification*)aNote
{
    [lemoOutSelectTriggerInPulseWithSampleAndTDCButton setState:[model lemoOutSelectTriggerInPulseWithSampleAndTDC]];
}

- (void) lemoOutSelectSampleLogicArmedChanged:(NSNotification*)aNote
{
    [lemoOutSelectSampleLogicArmedButton setState:[model lemoOutSelectSampleLogicArmed]];
}

- (void) lemoOutSelectSampleLogicEnabledChanged:(NSNotification*)aNote
{
    [lemoOutSelectSampleLogicEnabledButton setState:[model lemoOutSelectSampleLogicEnabled]];
}

- (void) lemoOutSelectKeyOutputPulseChanged:(NSNotification*)aNote
{
    [lemoOutSelectKeyOutputPulseButton setState:[model lemoOutSelectKeyOutputPulse]];
}

- (void) lemoOutSelectControlLemoTriggerOutChanged:(NSNotification*)aNote
{
    [lemoOutSelectControlLemoTriggerOutButton setState:[model lemoOutSelectControlLemoTriggerOut]];
}

- (void) lemoOutSelectExternalVetoChanged:(NSNotification*)aNote
{
    [lemoOutSelectExternalVetoButton setState:[model lemoOutSelectExternalVeto]];
}

- (void) lemoOutSelectInternalKeyVetoChanged:(NSNotification*)aNote
{
    [lemoOutSelectInternalKeyVetoButton setState:[model lemoOutSelectInternalKeyVeto]];
}

- (void) lemoOutSelectExternalVetoLengthChanged:(NSNotification*)aNote
{
    [lemoOutSelectExternalVetoLengthButton setState:[model lemoOutSelectExternalVetoLength]];
}

- (void) lemoOutSelectMemoryOverrunVetoChanged:(NSNotification*)aNote
{
    [lemoOutSelectMemoryOverrunVetoButton setState:[model lemoOutSelectMemoryOverrunVeto]];
}


#pragma mark LEMO Input changeds

- (void) enableLemoInputTriggerChanged:(NSNotification*)aNote
{
    [enableLemoInputTriggerButton setState:[model enableExternalLEMOTriggerIn]];
}

- (void) enableLemoInputCountChanged:(NSNotification*)aNote
{
    [enableLemoInputCountButton setState:[model enableExternalLEMOCountIn]];
}

- (void) enableLemoInputResetChanged:(NSNotification*)aNote
{
    [enableLemoInputResetButton setState:[model enableExternalLEMOResetIn]];
}

- (void) enableLemoInputDirectVetoChanged:(NSNotification*)aNote
{
    [enableLemoInputDirectVetoButton setState:[model enableExternalLEMODirectVetoIn]];
}


#pragma mark other changeds


- (void) clockSourceChanged:(NSNotification*)aNote
{
	[clockSourcePU selectItemAtIndex: [model clockSource]];
}



- (void) thresholdModeChanged:(NSNotification*)aNote
{
    short i;
    for(i=0;i<kNumSIS3305Channels/kNumSIS3305Groups;i++){
        [[thresholdMode14PUMatrix cellAtRow:i column:0] selectItemAtIndex:[model thresholdMode:i]];
//        [[thresholdMode14PUMatrix cellWithTag:i] selectItemAtIndex:[model thresholdMode:i]];
        [[thresholdMode58PUMatrix cellAtRow:i column:0] selectItemAtIndex:[model thresholdMode:(i+4)]];    // +4 corrects for split matrix
//        [[thresholdMode58PUMatrix cellWithTag:i] selectItemAtIndex:[model thresholdMode:(i+4)]];    // +4 corrects for split matrix
    }
}

- (void) inputInvertedChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[inputInvertedMatrix cellWithTag:i] setState:[model inputInverted:i]];
	}
}

- (void) triggerOutEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[triggerOutEnabledMatrix cellWithTag:i] setState:[model triggerOutEnabled:i]];
	}
}


- (void) bufferWrapEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Groups;i++){
		[[bufferWrapEnabledMatrix cellWithTag:i] setState:[model bufferWrapEnabled:i]];
	}
	[self settingsLockChanged:nil];
}


- (void) LTThresholdOnChanged:(NSNotification*)aNote
{
    // This method combins 1-4 and 5-8.
    short chPerGroup = kNumSIS3305Channels/kNumSIS3305Groups;
    short chan;
    for (chan=0; chan<chPerGroup; chan++) {
        [[LTThresholdOn14Matrix cellWithTag:chan] setIntValue:[model LTThresholdOn:chan]];
        [[LTThresholdOn58Matrix cellWithTag:(chan)] setIntValue:[model LTThresholdOn:(chan+4)]];
    }
    
}

- (void) LTThresholdOffChanged:(NSNotification*)aNote
{
    // This method combins 1-4 and 5-8.
    short chPerGroup = kNumSIS3305Channels/kNumSIS3305Groups;
    short chan;
    for (chan=0; chan<chPerGroup; chan++) {
        [[LTThresholdOff14Matrix cellWithTag:chan] setIntValue:[model LTThresholdOff:chan]];
        [[LTThresholdOff58Matrix cellWithTag:(chan)] setIntValue:[model LTThresholdOff:(chan+4)]];
    }
}

- (void) GTThresholdOnChanged:(NSNotification*)aNote
{
    // This method combines 1-4 and 5-8.
    short chPerGroup = kNumSIS3305Channels/kNumSIS3305Groups;
    short chan;
    for (chan=0; chan<chPerGroup; chan++) {
        [[GTThresholdOn14Matrix cellWithTag:chan] setIntValue:[model GTThresholdOn:chan]];
        [[GTThresholdOn58Matrix cellWithTag:chan] setIntValue:[model GTThresholdOn:(chan+4)]];
    }
}

- (void) GTThresholdOffChanged:(NSNotification*)aNote
{
    // This method combines 1-4 and 5-8.
    short chPerGroup = kNumSIS3305Channels/kNumSIS3305Groups;
    short chan;
    for (chan=0; chan<chPerGroup; chan++) {
        [[GTThresholdOff14Matrix cellWithTag:chan]      setIntValue:[model GTThresholdOff:chan]];
        [[GTThresholdOff58Matrix cellWithTag:(chan)]  setIntValue:[model GTThresholdOff:(chan+4)]];
    }
}

//- (void) thresholdChanged:(NSNotification*)aNote
//{
//	short i;
//	for(i=0;i<kNumSIS3305Channels;i++){
//		//float volts = (0.0003*[model threshold:i])-5.0;
//		[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
//	}
//}

//- (void) highThresholdChanged:(NSNotification*)aNote
//{
//	short i;
//	for(i=0;i<kNumSIS3305Channels;i++){
//		[[highThresholdMatrix cellWithTag:i] setIntValue:[model highThreshold:i]];
//	}
//}

//- (void) cfdControlChanged:(NSNotification*)aNote
//{
//	[cfdControl0 selectItemAtIndex:[model cfdControl:0]];
//	[cfdControl1 selectItemAtIndex:[model cfdControl:1]];
//	[cfdControl2 selectItemAtIndex:[model cfdControl:2]];
//	[cfdControl3 selectItemAtIndex:[model cfdControl:3]];
//	[cfdControl4 selectItemAtIndex:[model cfdControl:4]];
//	[cfdControl5 selectItemAtIndex:[model cfdControl:5]];
//	[cfdControl6 selectItemAtIndex:[model cfdControl:6]];
//	[cfdControl7 selectItemAtIndex:[model cfdControl:7]];
//	
//	[self settingsLockChanged:nil];
//}

- (void) sampleLengthChanged:(NSNotification*)aNote
{
    /* Sample length is the same for all channels in each group */
	short i;
	for(i=0;i<kNumSIS3305Groups;i++){
		[[sampleLengthMatrix cellWithTag:i] setIntegerValue:[model sampleLength:i]];
	}
	[runSummaryField setStringValue: [model runSummary]];
}


- (void) triggerGateLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Groups;i++){
		[[triggerGateLengthMatrix cellWithTag:i] setIntValue:[model triggerGateLength:i]];
	}
}

- (void) preTriggerDelayChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
        if(i<4)
            [[preTriggerDelay14Matrix cellWithTag:i] setIntValue:[model preTriggerDelay:i]];
        else if(i>=4)
            [[preTriggerDelay58Matrix cellWithTag:i-4] setIntValue:[model preTriggerDelay:i]];
    }
}

- (void) sampleStartIndexChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels/2;i++){
		[[sampleStartIndexMatrix cellWithTag:i] setIntValue:[model sampleStartIndex:i]];
	}
}

- (void) dacOffsetChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[dacOffsetMatrix cellWithTag:i] setIntValue:[model dacOffset:i]];
	}
}

- (void) gateLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[gateLengthMatrix cellWithTag:i] setIntValue:[model gateLength:i]];
	}
}

- (void) pulseLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[pulseLengthMatrix cellWithTag:i] setIntValue:[model pulseLength:i]];
	}
}


- (void) internalTriggerDelayChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3305Channels;i++){
		[[internalTriggerDelayMatrix cellWithTag:i] setIntValue:[model internalTriggerDelay:i]];
	}
}

- (void) ORSIS3305LEDEnabledChanged:(NSNotification*)aNote
{
    //FIX: No-op
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
    [gSecurity setLock:ORSIS3305SettingsLock to:secure];
    //[settingLockButton setEnabled:secure];
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
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSIS3305SettingsLock];
    BOOL locked = [gSecurity isLocked:ORSIS3305SettingsLock];
	BOOL firmwareGEV15xx = [model firmwareVersion] >= 15;
    
    BOOL writeGPO = [model writeGainPhaseOffsetEnabled];
//    BOOL mcaMode = (([model runMode] == kMcaRunMode) && !firmwareGEV15xx);
	
    // temp

    
	[settingLockButton			setState: locked];
	//[settingLockButton			setState: locked];

    [runModePU					setEnabled:!locked && !runInProgress];
    [pulseModeButton			setEnabled:!locked && !runInProgress];
    [TDCLogicEnabledCB			setEnabled:!locked && !runInProgress];
	
    [addressText				setEnabled:!locked && !runInProgress];
    [initButton					setEnabled:!lockedOrRunningMaintenance];
	[briefReportButton			setEnabled:!lockedOrRunningMaintenance];
	[regDumpButton				setEnabled:!lockedOrRunningMaintenance];
	[probeButton				setEnabled:!lockedOrRunningMaintenance];
    [forceTriggerButton			setEnabled:!lockedOrRunningMaintenance];
	
	[triggerGateLengthMatrix		setEnabled:!lockedOrRunningMaintenance];
    [preTriggerDelay14Matrix			setEnabled:!lockedOrRunningMaintenance];
    [preTriggerDelay58Matrix			setEnabled:!lockedOrRunningMaintenance];


    [clockSourcePU					setEnabled:!lockedOrRunningMaintenance];
    
    //event config items
//    [eventSavingMode14PU			setEnabled:NO];
//    [eventSavingMode58PU			setEnabled:NO];
    [eventSavingMode14PU			setEnabled:!lockedOrRunningMaintenance];
    [eventSavingMode58PU			setEnabled:!lockedOrRunningMaintenance];
//    [channelMode14PU                setEnabled:NO];
//    [channelMode58PU                setEnabled:NO];
    [channelMode14PU                setEnabled:!lockedOrRunningMaintenance];
    [channelMode58PU                setEnabled:!lockedOrRunningMaintenance];
    
    [thresholdMode14PUMatrix        setEnabled:!lockedOrRunningMaintenance];
    [thresholdMode58PUMatrix        setEnabled:!lockedOrRunningMaintenance];

    [LTThresholdOn14Matrix          setEnabled:!lockedOrRunningMaintenance];
    [GTThresholdOn14Matrix          setEnabled:!lockedOrRunningMaintenance];
    [LTThresholdOn58Matrix          setEnabled:!lockedOrRunningMaintenance];
    [GTThresholdOn58Matrix          setEnabled:!lockedOrRunningMaintenance];

    bool gate[kNumSIS3305Groups];
    gate[0] = [model ADCGateModeEnabled:0];
    gate[1] = [model ADCGateModeEnabled:1];
    // only enable the "off" if you're in ADC gate mode.
    [LTThresholdOff14Matrix         setEnabled:(gate[0] && !lockedOrRunningMaintenance)];
    [GTThresholdOff14Matrix         setEnabled:(gate[0] && !lockedOrRunningMaintenance)];
    [LTThresholdOff58Matrix         setEnabled:(gate[1] && !lockedOrRunningMaintenance)];
    [GTThresholdOff58Matrix         setEnabled:(gate[1] && !lockedOrRunningMaintenance)];

    [gain14Matrix           setEnabled:(writeGPO && !lockedOrRunningMaintenance)];
    [gain58Matrix           setEnabled:(writeGPO && !lockedOrRunningMaintenance)];
    [phase14Matrix          setEnabled:(writeGPO && !lockedOrRunningMaintenance)];
    [phase58Matrix          setEnabled:(writeGPO && !lockedOrRunningMaintenance)];
    [offset14Matrix         setEnabled:(writeGPO && !lockedOrRunningMaintenance)];
    [offset58Matrix         setEnabled:(writeGPO && !lockedOrRunningMaintenance)];
    
    // begin key regs
    [generalResetButton             setEnabled:!locked && !runInProgress];
    [armSampleLogicButton           setEnabled:!locked && !runInProgress];
    [disarmSampleLogicButton        setEnabled:!locked && !runInProgress];
    [triggerButton                  setEnabled:!lockedOrRunningMaintenance];
    [enableSampleLogicButton        setEnabled:!locked && !runInProgress];
    [setVetoButton                  setEnabled:!locked && !runInProgress];
    [clearVetoButton                setEnabled:!lockedOrRunningMaintenance];
    [ADCClockSynchButton            setEnabled:!locked && !runInProgress];
    [ResetADCFPGALogicButton        setEnabled:!locked && !runInProgress];
    [externalTriggerOutPulseButton  setEnabled:!lockedOrRunningMaintenance];
    // end key regs
    

	[inputInvertedMatrix			setEnabled:!lockedOrRunningMaintenance];
//	[thresholdMatrix				setEnabled:!lockedOrRunningMaintenance];
//	[internalTriggerEnabledMatrix	setEnabled:!lockedOrRunningMaintenance];
//	[externalTriggerEnabledMatrix	setEnabled:!lockedOrRunningMaintenance];
	[internalGateEnabledMatrix		setEnabled:!lockedOrRunningMaintenance];
	[externalGateEnabledMatrix		setEnabled:!lockedOrRunningMaintenance];
	[internalTriggerDelayMatrix		setEnabled:!lockedOrRunningMaintenance];
	[dacOffsetMatrix				setEnabled:!lockedOrRunningMaintenance];
	[gateLengthMatrix				setEnabled:!lockedOrRunningMaintenance];
	[pulseLengthMatrix				setEnabled:!lockedOrRunningMaintenance];
	
	[triggerOutEnabledMatrix		setEnabled:!lockedOrRunningMaintenance];
	
	//can't be changed during a run or the card and probably the sbc will be hosed.
	[sampleLengthMatrix				setEnabled:!locked && !runInProgress];
	[bufferWrapEnabledMatrix		setEnabled:!locked && !runInProgress && firmwareGEV15xx];

	
    
	int i;
		
	for(i=0;i<kNumSIS3305Groups;i++){
		if([model bufferWrapEnabled:i])
            [[sampleStartIndexMatrix	cellWithTag:i]setEnabled:!locked && !runInProgress];
		else
            [[sampleStartIndexMatrix cellWithTag:i]	setEnabled:NO];
    }
	
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3305 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3305 Card (Slot %d)",[model slot]]];
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

- (void) setRegisterDisplay:(unsigned int)index
{
    if (index < kNumSIS3305ReadRegs)
    {
            [writeRegisterButton setEnabled:[model canWriteRegister:index]];
            [registerWriteValueField setEnabled:[model canWriteRegister:index]];
            [readRegisterButton setEnabled:[model canReadRegister:index]];
            [registerStatusField setStringValue:@""];
    }
}

#pragma mark - Actions

- (void) pulseModeAction:(id)sender
{
	[model setPulseMode:[sender intValue]];
}

- (void) shipTimeRecordAlsoAction:(id)sender
{
	[model setShipTimeRecordAlso:[sender intValue]];	
}


- (IBAction) channelEnabledMaskAction:(id)sender
{
    // This method does nothing, since I rewrote the [model enabled:chan] to just return the OR of GT || LT
    
 //   [model setEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
 //   - (void) setEnabled:(short)chan withValue:(BOOL)aValue;

}

//
//- (IBAction) thresholdModeAction:(id)sender
//{
//    short chan = [[sender selectedCell] tag];
//    int value =  [[sender selectedCell] intValue];
//    
//    [model setThresholdMode:chan withValue:value];
//}

- (IBAction) writeGainPhaseOffsetEnableAction:(id)sender
{
    BOOL value = [sender intValue];
    [model setWriteGainPhaseOffsetEnabled:value];
}

- (IBAction) GTThresholdOn14Action:(id)sender
{
    short chan = [[sender selectedCell] tag];
    int value =  [[sender selectedCell] intValue];

    //this should be done in the model as well, in case anyone uses a script to set it
    if(value>1023)
        value = 1023;
    else if(value < 0)
        value = 0;
    
//    if(value != [model GTThresholdOn:chan]){
        [model setGTThresholdOn:chan withValue:value];
//    }
}

- (IBAction) GTThresholdOn58Action:(id)sender
{
    short chan = [[sender selectedCell] tag] + 4;   // chans 5-8 are a new matrix, so they will be 4 off
    int value =  [[sender selectedCell] intValue];
    
    if(value>1023)
        value = 1023;
    else if(value < 0)
        value = 0;
    
//    if(value != [model GTThresholdOn:chan]){
        [model setGTThresholdOn:chan withValue:value];
//    }
}

- (IBAction) GTThresholdOff14Action:(id)sender
{
    short chan = [[sender selectedCell] tag];
    int value =  [[sender selectedCell] intValue];
    
    if(value>1023)
        value = 1023;
    else if(value < 0)
        value = 0;
    
//    if(value != [model GTThresholdOff:chan]){
        [model setGTThresholdOff:chan withValue:value];
//    }
}

- (IBAction) GTThresholdOff58Action:(id)sender
{
    short chan = [[sender selectedCell] tag] + 4;   // chans 5-8 are a new matrix, so they will be 4 off
    int value =  [[sender selectedCell] intValue];
    
    if(value>1023)
        value = 1023;   
    else if(value < 0)
        value = 0;
    
//    if(value != [model GTThresholdOff:chan]){
        [model setGTThresholdOff:chan withValue:value];
//    }
}

- (IBAction) LTThresholdOn14Action:(id)sender
{
    short chan = [[sender selectedCell] tag];
    int value = [sender intValue];
    
    if(value>1023)
        value = 1023;
    else if(value < 0)
        value = 0;
    
//    if(value != [model LTThresholdOn:chan]){
        [model setLTThresholdOn:chan withValue:value];
//    }
}

- (IBAction) LTThresholdOn58Action:(id)sender
{
    short chan = [[sender selectedCell] tag] + 4;   // chans 5-8 are a new matrix, so they will be 4 off
    int value = [sender intValue];
    
    if(value>1023)
        value = 1023;
    else if(value < 0)
        value = 0;
    
//    if(value != [model LTThresholdOn:chan]){
        [model setLTThresholdOn:chan withValue:value];
//    }
}

- (IBAction) LTThresholdOff14Action:(id)sender
{
    short chan = [[sender selectedCell] tag];
    int value = [sender intValue];
    
    if(value>1023)
        value = 1023;
    else if(value < 0)
        value = 0;
    
//    if(value != [model LTThresholdOff:chan]){
        [model setLTThresholdOff:chan withValue:value];
//    }
}

- (IBAction) LTThresholdOff58Action:(id)sender
{
    short chan = [[sender selectedCell] tag] + 4;   // chans 5-8 are a new matrix, so they will be 4 off
    int value = [sender intValue];
    
    if(value>1023)
        value = 1023;
    else if(value < 0)
        value = 0;
    
//    if(value != [model LTThresholdOff:chan]){
        [model setLTThresholdOff:chan withValue:value];
//    }
}





- (IBAction) internalGateEnabledMaskAction:(id)sender
{
	[model setInternalGateEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) externalGateEnabledMaskAction:(id)sender
{
	[model setExternalGateEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

//- (IBAction) internalTriggerEnabledMaskAction:(id)sender
//{
//	[model setInternalTriggerEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
//}
//
//- (IBAction) externalTriggerEnabledMaskAction:(id)sender
//{
//	[model setExternalTriggerEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
//}


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



- (IBAction) lemoInModeAction:(id)sender
{
	[model setLemoInMode:[sender indexOfSelectedItem]];	
}

- (IBAction) lemoOutModeAction:(id)sender
{
	[model setLemoOutMode:[sender indexOfSelectedItem]];	
}


- (IBAction) controlLemoTriggerOutAction:(id)sender
{
    BOOL mode = [sender state];
    [model setControlLEMOTriggerOut:mode];
}

- (IBAction) lemoOutSelectTrigger14Action:(id)sender
{
    int chan;
    BOOL mode;

    chan = (int)[[sender selectedCell] tag];     // set to 0-3
    mode = [[sender selectedCell] state];
    
    [model setLemoOutSelectTrigger:chan toState:mode];
}

- (IBAction) lemoOutSelectTrigger58Action:(id)sender
{
//    int chan;
    BOOL mode;
    unsigned short chan;
    
    chan = ([[sender selectedCell] tag] + 4);   // tag is 0-3 here
    mode = [[sender selectedCell] state];
    
    [model setLemoOutSelectTrigger:chan toState:mode];
}
- (IBAction) lemoOutSelectTriggerInAction:(id)sender
{
    BOOL mode = [sender state];
    [model setLemoOutSelectTriggerIn:mode];
}

- (IBAction) lemoOutSelectTriggerInPulseAction:(id)sender
{
    BOOL mode = [sender state];
    [model setLemoOutSelectTriggerInPulse:mode];
}

- (IBAction) lemoOutSelectTriggerInPulseWithSampleAndTDCAction:(id)sender
{
    BOOL mode = [sender state];
    [model setLemoOutSelectTriggerInPulseWithSampleAndTDC:mode];
}

- (IBAction) lemoOutSelectSampleLogicArmedAction:(id)sender
{
    BOOL mode = [sender state];
    [model setLemoOutSelectSampleLogicArmed:mode];
}

- (IBAction) lemoOutSelectSampleLogicEnabledAction:(id)sender
{
    BOOL mode = [sender state];
    [model setLemoOutSelectSampleLogicEnabled:mode];
}

- (IBAction) lemoOutSelectKeyOutputPulseAction:(id)sender
{
    BOOL mode = [sender state];
    [model setLemoOutSelectKeyOutputPulse:mode];
}

- (IBAction) lemoOutSelectControlLemoTriggerOutAction:(id)sender
{
    BOOL mode = [sender state];
    [model setLemoOutSelectControlLemoTriggerOut:mode];
}

- (IBAction) lemoOutSelectExternalVetoAction:(id)sender
{
    BOOL mode = [sender state];
    [model setLemoOutSelectExternalVeto:mode];
}

- (IBAction) lemoOutSelectInternalKeyVetoAction:(id)sender
{
    BOOL mode = [sender state];
    [model setLemoOutSelectInternalKeyVeto:mode];
}

- (IBAction) lemoOutSelectExternalVetoLengthAction:(id)sender
{
    BOOL mode = [sender state];
    [model setLemoOutSelectExternalVetoLength:mode];
}

- (IBAction) lemoOutSelectMemoryOverrunVetoAction:(id)sender
{
    BOOL mode = [sender state];
    [model setLemoOutSelectMemoryOverrunVeto:mode];
}



- (IBAction) enableLemoInputTriggerAction:(id)sender
{
    BOOL aState = [sender state];
    [model setEnableExternalLEMOTriggerIn:aState];
}


- (IBAction) enableLemoInputCountAction:(id)sender
{
    BOOL aState = [sender state];
    [model setEnableExternalLEMOCountIn:aState];
}

- (IBAction) enableLemoInputResetAction:(id)sender
{
    BOOL aState = [sender state];
    [model setEnableExternalLEMOResetIn:aState];
}

- (IBAction) enableLemoInputDirectVetoAction:(id)sender
{
    BOOL aState = [sender state];
    [model setEnableExternalLEMODirectVetoIn:aState];
}


#pragma mark - hardware actions

#pragma mark -- register R/W access

- (IBAction) registerIndexPUAction:(id)sender
{
    int index = (int)[sender indexOfSelectedItem];
    [model setRegisterIndex:index];
    [self setRegisterDisplay:index];
}

- (IBAction) readRegisterAction:(id)sender
{
    [self endEditing];
    uint32_t aValue = 0;
    unsigned int index = [model registerIndex];
    if (index < kNumSIS3305ReadRegs) {
        aValue = [model readRegister:index];
        NSLog(@"SIS3305(%d,%d) %@: %u (0x%0x)\n",[model crateNumber],[model slot], [model registerNameAt:index],aValue,aValue);
    }
    
}

- (IBAction) writeRegisterAction:(id)sender
{
    [self endEditing];
    uint32_t aValue = [model registerWriteValue];
    unsigned int index = [model registerIndex];
    if (index < kNumSIS3305ReadRegs) {
        [model writeRegister:index withValue:aValue];
        NSLog(@"SIS3305(%d,%d) Writing to %@: with value %u (0x%0x)\n",[model crateNumber],[model slot], [model registerNameAt:index],aValue,aValue);

    }
    else {
        NSLog(@"Invalid register name");
    }
}

- (IBAction) registerWriteValueAction:(id)sender
{
    [model setRegisterWriteValue:[sender intValue]];
}



#pragma mark -- misc hardware actions

//hardware actions
- (IBAction) probeBoardAction:(id)sender;
{
	@try {
		[model probeBoard];
	}
	@catch (NSException* localException) {
		NSLog(@"Probe of SIS 3305 board ID failed\n");
        ORRunAlertPanel([localException name], @"%@\nProbe Failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) TDCLogicEnabledAction:(id)sender
{
    bool value = [sender state];
    [model setTDCMeasurementEnabled:value];
}

- (IBAction) clockSourceAction:(id)sender
{
	[model setClockSource:(int)[sender indexOfSelectedItem]];
}


#pragma mark -- Event config actions
// event config actions
- (IBAction) eventSavingMode14Action:(id)sender
{
    short mode = [sender indexOfSelectedItem];
    [model setEventSavingModeOf:0 toValue:mode];    // 0 is for group 1
}

- (IBAction) eventSavingMode58Action:(id)sender
{
    short mode = [sender indexOfSelectedItem];
    [model setEventSavingModeOf:1 toValue:mode];    // 1 is for group 2
}

- (IBAction) ADCGateModeEnabled14Action:(id)sender
{
    short mode = [sender state];
    [model setADCGateModeEnabled:0 toValue:mode];
}

- (IBAction) ADCGateModeEnabled58Action:(id)sender
{
    short mode = [sender state];
    [model setADCGateModeEnabled:1 toValue:mode];
}

- (IBAction) globalTriggerEnabled14Action:(id)sender
{
    short mode = [sender state];
    [model setGlobalTriggerEnabledOnGroup:0 toValue:mode];
}
- (IBAction) globalTriggerEnabled58Action:(id)sender
{
    short mode = [sender state];
    [model setGlobalTriggerEnabledOnGroup:1 toValue:mode];
}

- (IBAction) internalTriggerEnabled14Action:(id)sender
{
    short mode = [sender state];
    [model setInternalTriggerEnabled:0 toValue:mode];
}
- (IBAction) internalTriggerEnabled58Action:(id)sender
{
    short mode = [sender state];
    [model setInternalTriggerEnabled:1 toValue:mode];
}

- (IBAction) externalTriggerEnabled14Action:(id)sender
{
    short mode = [sender state];
    [model setExternalTriggerEnabled:0 withValue:mode];
}
- (IBAction) externalTriggerEnabled58Action:(id)sender
{
    short mode = [sender state];
    [model setExternalTriggerEnabled:0 withValue:mode];
}

- (IBAction) startEventSamplingWithExtTrigEnabled14Action:(id)sender
{
    short mode = [sender state];
    [model setStartEventSamplingWithExtTrigEnabled:0 toValue:mode];
}
- (IBAction) startEventSamplingWithExtTrigEnabled58Action:(id)sender
{
    short mode = [sender state];
    [model setStartEventSamplingWithExtTrigEnabled:1 toValue:mode];
}

- (IBAction) clearTimestampWhenSamplingEnabledEnabled14Action:(id)sender
{
    short mode = [sender state];
    [model setClearTimestampWhenSamplingEnabledEnabled:0 toValue:mode];
}
- (IBAction) clearTimestampWhenSamplingEnabledEnabled58Action:(id)sender
{
    short mode = [sender state];
    [model setClearTimestampWhenSamplingEnabledEnabled:1 toValue:mode];
}

- (IBAction) grayCodeEnabled14Action:(id)sender
{
    short mode = [sender state];
    [model setGrayCodeEnabled:0 toValue:mode];
}

- (IBAction) grayCodeEnabled58Action:(id)sender
{
    short mode = [sender state];
    [model setGrayCodeEnabled:1 toValue:mode];
}

- (IBAction) clearTimestampDisabled14Changed:(id)sender
{
    short mode = [sender state];
    [model setClearTimestampDisabled:0 toValue:mode];
   
}
- (IBAction) clearTimestampDisabled58Changed:(id)sender
{
    short mode = [sender state];
    [model setClearTimestampDisabled:1 toValue:mode];
}
- (IBAction) disableDirectMemoryHeader14Changed:(id)sender
{
    short mode = [sender state];
    [model setDirectMemoryHeaderDisabled:0 toValue:mode];
}
- (IBAction) disableDirectMemoryHeader58Changed:(id)sender
{
    short mode = [sender state];
    [model setDirectMemoryHeaderDisabled:1 toValue:mode];
}

- (IBAction) waitPreTrigTimeBeforeDirectMemTrig14Changed:(id)sender
{
    short mode = [sender state];
    [model setWaitPreTrigTimeBeforeDirectMemTrig:0 toValue:mode];
}

- (IBAction) waitPreTrigTimeBeforeDirectMemTrig58Changed:(id)sender
{
    short mode = [sender state];
    [model setWaitPreTrigTimeBeforeDirectMemTrig:1 toValue:mode];
}





- (IBAction) channelMode14Action:(id)sender
{
    unsigned short mode = [[sender selectedCell] indexOfSelectedItem];
    const unsigned short group = 0;
    
    [model setChannelMode:group withValue:mode];
}
- (IBAction) channelMode58Action:(id)sender
{
    unsigned short mode = [[sender selectedCell] indexOfSelectedItem];
    const unsigned short group = 1;
    
    [model setChannelMode:group withValue:mode];
}

- (IBAction) bandwidth14Action:(id)sender;
{
    unsigned short mode = [[sender selectedCell] indexOfSelectedItem];
    const unsigned short group = 0;
    
    [model setBandwidth:group withValue:mode];
}

- (IBAction) bandwidth58Action:(id)sender
{
    unsigned short mode = [[sender selectedCell] indexOfSelectedItem];
    const unsigned short group = 1;
    
    [model setBandwidth:group withValue:mode];
}

- (IBAction) testMode14Action:(id)sender;
{
    unsigned short mode = [[sender selectedCell] indexOfSelectedItem];
    const unsigned short group = 0;
    
    [model setTestMode:group withValue:mode];
}

- (IBAction) testMode58Action:(id)sender;
{
    unsigned short mode = [[sender selectedCell] indexOfSelectedItem];
    const unsigned short group = 1;
    
    [model setTestMode:group withValue:mode];
}


- (IBAction) adcGain14Action:(id)sender
{
    unsigned short chan = [[sender selectedCell] tag];
    unsigned short value = [sender intValue];
    
    [model setAdcGain:chan toValue:value];
}

- (IBAction) adcGain58Action:(id)sender
{
    unsigned short chan = 4 + [[sender selectedCell] tag];
    unsigned short value = [sender intValue];
    
    [model setAdcGain:chan toValue:value];
}

- (IBAction) adcOffset14Action:(id)sender
{
    unsigned short chan = [[sender selectedCell] tag];
    unsigned short value = [sender intValue];
    
    [model setAdcOffset:chan toValue:value];
}

- (IBAction) adcOffset58Action:(id)sender
{
    unsigned short chan = 4 + [[sender selectedCell] tag];
    unsigned short value = [sender intValue];
    
    [model setAdcOffset:chan toValue:value];
}

- (IBAction) adcPhase14Action:(id)sender
{
    unsigned short chan = [[sender selectedCell] tag];
    unsigned short value = [sender intValue];
    
    [model setAdcPhase:chan toValue:value];
}

- (IBAction) adcPhase58Action:(id)sender
{
    unsigned short chan = 4 + [[sender selectedCell] tag];
    unsigned short value = [sender intValue];
    
    [model setAdcPhase:chan toValue:value];
}




- (IBAction) thresholdMode14Action:(id)sender
{
    short chan = [sender selectedRow] ;
    short value = [[sender selectedCell] indexOfSelectedItem];
    
    [model setThresholdMode:chan withValue:value];
}

- (IBAction) thresholdMode58Action:(id)sender
{
    short chan = [sender selectedRow]+4 ;                       // +4 corrects for split matrix
    short value = [[sender selectedCell] indexOfSelectedItem];
    
    [model setThresholdMode:chan withValue:value];
}

- (IBAction) triggerOutEnabledAction:(id)sender
{
	[model setTriggerOutEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}


- (IBAction) inputInvertedAction:(id)sender
{
	[model setInputInverted:[[sender selectedCell] tag] withValue:[sender intValue]];
}


- (IBAction) LTThresoldEnabledAction:(id)sender
{
    short chan = [[sender selectedCell] tag];
    short value = [sender intValue];
    
    [model setLTThresholdEnabled:chan withValue:value];
}

- (IBAction) GTThresoldEnabledAction:(id)sender
{
    short chan = [[sender selectedCell] tag];
    short value = [sender intValue];
    
    [model setGTThresholdEnabled:chan withValue:value];
}

- (IBAction) bufferWrapEnabledAction:(id)sender
{
	[model setBufferWrapEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

//- (IBAction) triggerDecimationAction:(id)sender
//{
//	if([sender indexOfSelectedItem] != [model triggerDecimation:[sender tag]]){
//		[model setTriggerDecimation:[sender tag] withValue:[sender indexOfSelectedItem]];
//	}
//}

//- (IBAction) energyDecimationAction:(id)sender
//{
//    if([sender indexOfSelectedItem] != [model energyDecimation:[sender tag]]){
//		[model setEnergyDecimation:[sender tag] withValue:[sender indexOfSelectedItem]];
//	}
//}

//- (IBAction) thresholdAction:(id)sender
//{
//    if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
//		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
//	}
//}

//- (IBAction) highThresholdAction:(id)sender
//{
//    if([sender intValue] != [model highThreshold:[[sender selectedCell] tag]]){
//		[model setHighThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
//	}
//}

//- (IBAction) cfdControlAction:(id)sender
//{
//    //if([sender intValue] != [model cfdControl:[sender tag]]){
////		[model setCfdControl:[sender tag] withValue:[sender indexOfSelectedItem]];
//	//}
//}

//- (IBAction) triggerGateLengthAction:(id)sender
//{
//    if([sender intValue] != [model triggerGateLength:[[sender selectedCell] tag]]){
//		[model setTriggerGateLength:[[sender selectedCell] tag] withValue:[sender intValue]];
//	}
//}

- (IBAction) preTriggerDelay14Action:(id)sender
{
    int value = [sender intValue];
    int chan = (int)[[sender selectedCell] tag];
    
    if(value != [model preTriggerDelay:chan]){
        [model setPreTriggerDelay:chan withValue:value];
    }
}
- (IBAction) preTriggerDelay58Action:(id)sender
{
    int value = [sender intValue];
    int chan = (int)[[sender selectedCell] tag] + 4;     // the +4 corrects for the split matrix
    
    if(value != [model preTriggerDelay:chan ]){
        [model setPreTriggerDelay:chan withValue:value];
    }
}

- (IBAction) sampleLengthAction:(id)sender
{
    unsigned short group = [[sender selectedCell] tag];
    uint32_t value = [sender intValue];
    [model setSampleLength:group withValue:value];
}

#pragma mark KEY Reg actions

- (IBAction) generalResetAction:(id)sender
{
    [model reset];
}

- (IBAction) armSampleLogicAction:(id)sender
{
    [model armSampleLogic];
}

- (IBAction) disarmSampleLogicAction:(id)sender
{
    [model disarmSampleLogic];
}

- (IBAction) triggerAction:(id)sender
{
    [model forceTrigger];
}

- (IBAction) enableSampleLogicAction:(id)sender
{
    [model enableSampleLogic];
}

- (IBAction) setVetoAction:(id)sender
{
    [model setVeto];
}

- (IBAction) clearVetoAction:(id)sender
{
    [model clearVeto];
}

- (IBAction) ADCClockSynchAction:(id)sender
{
    [model ADCSynchReset];
}

- (IBAction) resetADCFPGALogicAction:(id)sender
{
    [model ADCFPGAReset];
}

- (IBAction) externalTriggerOutPulseAction:(id)sender
{
    [model pulseExternalTriggerOut];
}


#pragma mark -- Don't know about these



- (IBAction) sampleStartIndexAction:(id)sender
{
	if([sender intValue] != [model sampleStartIndex:(int)[[sender selectedCell] tag]]){
		[model setSampleStartIndex:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
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
//		[model setPulseLength:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) internalTriggerDelayAction:(id)sender
{
    if([sender intValue] != [model internalTriggerDelay:[[sender selectedCell] tag]]){
		[model setInternalTriggerDelay:[[sender selectedCell] tag] withValue:[sender intValue]];
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
    [gSecurity tryToSetLock:ORSIS3305SettingsLock to:[sender intValue] forWindow:[self window]];
}

-(IBAction) initBoard:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];		//initialize and load hardward
        NSLog(@"Initialized SIS3305 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset and Init of SIS3305 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3305 Reset and Init", @"OK", nil, nil,
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
		[self resizeWindowToSize:basicSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:settingSize];
        [[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:miscSize];
        [[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:rateSize];
        [[self window] setContentView:tabView];
    }
    NSString* key = [NSString stringWithFormat: @"orca.ORSIS3305%d.selectedtab",[model slot]];
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
        NSLog(@"SIS3305 Report FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3305 Report FAILED", @"OK", nil, nil,
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
        NSLog(@"SIS3305 Reg Dump FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3305 Reg Dump FAILED", @"OK", nil, nil,
                        localException);
    }
	if(ok)[model regDump];
}

- (IBAction) forceTriggerAction:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];
        [model forceTrigger];
    }
    @catch(NSException* localException) {
        NSLog(@"SIS3305 Force Trigger FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3305 Force Trigger FAILED", @"OK", nil, nil,
                        localException);
    }
    
}

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Data Source

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
