//
//  ORDT5725Controller.m
//  Orca
//
//  Created by Mark Howe on Wed Jun 29,2016.
//  Copyright (c) 2016 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina at the Center sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#import "ORDT5725Controller.h"
#import "ORDT5725Model.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"
#import "ORValueBar.h"
#import "ORTimeRate.h"
#import "ORRate.h"
#import "ORRateGroup.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"
#import "ORQueueView.h"

#define kNumBoardConfigBits 5
#define kNumTrigSourceBits 10


@interface ORDT5725Controller (private)
- (void) populateInterfacePopup:(ORUSB*)usb;
@end

@implementation ORDT5725Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"DT5725" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
	
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceAdded
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceRemoved
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORDT5725ModelSerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORDT5725ModelUSBInterfaceChanged
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(integrationChanged:)
                         name : ORRateGroupIntegrationChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(inputDynamicRangeChanged:)
                         name : ORDT5725ModelInputDynamicRangeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(selfTrigPulseWidthChanged:)
                         name : ORDT5725ModelSelfTrigPulseWidthChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(thresholdChanged:)
                         name : ORDT5725ThresholdChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(selfTrigLogicChanged:)
                         name : ORDT5725ModelSelfTrigLogicChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(selfTrigPulseTypeChanged:)
                         name : ORDT5725ModelSelfTrigPulseTypeChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(dcOffsetChanged:)
                         name : ORDT5725ModelDCOffsetChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(testPatternEnabledChanged:)
                         name : ORDT5725ModelTestPatternEnabledChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(trigOnUnderThresholdChanged:)
                         name : ORDT5725ModelTrigOnUnderThresholdChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(trigOverlapEnabledChanged:)
                         name : ORDT5725ModelTrigOverlapEnabledChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(eventSizeChanged:)
                         name : ORDT5725ModelEventSizeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORDT5725ModelClockSourceChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(countAllTriggersChanged:)
                         name : ORDT5725ModelCountAllTriggersChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(startStopRunModeChanged:)
                         name : ORDT5725ModelStartStopRunModeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(memFullModeChanged:)
                         name : ORDT5725ModelMemFullModeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(softwareTrigEnabledChanged:)
                         name : ORDT5725ModelSoftwareTrigEnabledChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(externalTrigEnabledChanged:)
                         name : ORDT5725ModelExternalTrigEnabledChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(coincidenceWindowChanged:)
                         name : ORDT5725ModelCoincidenceWindowChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(coincidenceLevelChanged:)
                         name : ORDT5725ModelCoincidenceLevelChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerSourceEnableMaskChanged:)
                         name : ORDT5725ModelTriggerSourceMaskChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(swTrigOutEnabledChanged:)
                         name : ORDT5725ModelSwTrigOutEnabledChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(extTrigOutEnabledChanged:)
                         name : ORDT5725ModelExtTrigOutEnabledChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerOutMaskChanged:)
                         name : ORDT5725ModelTriggerOutMaskChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(triggerOutLogicChanged:)
                         name : ORDT5725ModelTriggerOutLogicChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(trigOutCoincidenceLevelChanged:)
                         name : ORDT5725ModelTrigOutCoincidenceLevelChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(postTriggerSettingChanged:)
                         name : ORDT5725ModelPostTriggerSettingChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(fpLogicTypeChanged:)
                         name : ORDT5725ModelFpLogicTypeChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fpTrigInSigEdgeDisableChanged:)
                         name : ORDT5725ModelFpTrigInSigEdgeDisableChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fpTrigInToMezzaninesChanged:)
                         name : ORDT5725ModelFpTrigInToMezzaninesChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fpForceTrigOutChanged:)
                         name : ORDT5725ModelFpForceTrigOutChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fpTrigOutModeChanged:)
                         name : ORDT5725ModelFpTrigOutModeChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fpTrigOutModeSelectChanged:)
                         name : ORDT5725ModelFpTrigOutModeSelectChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fpMBProbeSelectChanged:)
                         name : ORDT5725ModelFpMBProbeSelectChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fpBusyUnlockSelectChanged:)
                         name : ORDT5725ModelFpBusyUnlockSelectChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fpHeaderPatternChanged:)
                         name : ORDT5725ModelFpHeaderPatternChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enabledMaskChanged:)
                         name : ORDT5725ModelEnabledMaskChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(fanSpeedModeChanged:)
                         name : ORDT5725ModelFanSpeedModeChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(almostFullLevelChanged:)
                         name : ORDT5725ModelAlmostFullLevelChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(runDelayChanged:)
                         name : ORDT5725ModelRunDelayChanged
                       object : model];

    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : ORDT5725SelectedRegIndexChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegChannelChanged:)
						 name : ORDT5725SelectedChannelChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : ORDT5725WriteValueChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(basicLockChanged:)
						 name : ORDT5725BasicLock
					   object : nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(lowLevelLockChanged:)
						 name : ORDT5725LowLevelLock
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(basicLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(basicLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(setStatusStrings)
                         name : ORDT5725ModelBufferCheckChanged
                       object : model];
    
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
    

    
	[self registerRates];

}

- (void) awakeFromNib
{
    lowLevelSize   = NSMakeSize(300,360);
    basicSize      = NSMakeSize(930,630);
    monitoringSize = NSMakeSize(783,390);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
    [registerAddressPopUp setAlignment:NSTextAlignmentCenter];
    [channelPopUp setAlignment:NSTextAlignmentCenter];
	
    [self populatePullDown];
    
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
	[self populateInterfacePopup:[model getUSBController]];
    
    int i;
    for(i=0;i<kNumDT5725Channels;i++){
        [[inputDynamicRangeMatrix           cellAtRow:i column:0] setTag:i];
        [[selfTrigPulseWidthMatrix          cellAtRow:i column:0] setTag:i];
        [[thresholdMatrix                   cellAtRow:i column:0] setTag:i];
        [[selfTrigPulseTypeMatrix           cellAtRow:i column:0] setTag:i];
        [[dcOffsetMatrix                    cellAtRow:i column:0] setTag:i];
        [[enabledMaskMatrix                 cellAtRow:i column:0] setTag:i];
        [[enabled2MaskMatrix                cellAtRow:i column:0] setTag:i];
    }
    for(i=0;i<2;i++){
        [[trigOnUnderThresholdMatrix        cellAtRow:i column:0] setTag:i];
    }
    for(i=0;i<kNumDT5725Channels/2;i++){
        [[selfTrigLogicMatrix               cellAtRow:i column:0] setTag:i];
        [[triggerSourceEnableMaskMatrix     cellAtRow:i column:0] setTag:i];
        [[triggerOutMaskMatrix              cellAtRow:i column:0] setTag:i];
    }
    
    [super awakeFromNib];

    
    NSString* key = [NSString stringWithFormat: @"orca.%@%u.selectedtab",[model className],[model uniqueIdNumber]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	[rate0 setNumber:8 height:10 spacing:5];
    [queView setBarColor:[NSColor redColor]];

}

- (void) updateWindow
{
    [ super updateWindow ];
    
	[self serialNumberChanged:nil];
    [self integrationChanged:nil];
   
    [self inputDynamicRangeChanged:nil];
    [self selfTrigPulseWidthChanged:nil];
    [self thresholdChanged:nil];
    [self selfTrigLogicChanged:nil];
    [self selfTrigPulseTypeChanged:nil];
    [self dcOffsetChanged:nil];
    [self trigOnUnderThresholdChanged:nil];
    [self testPatternEnabledChanged:nil];
    [self trigOverlapEnabledChanged:nil];
    [self eventSizeChanged:nil];
    [self clockSourceChanged:nil];
	[self countAllTriggersChanged:nil];
    [self startStopRunModeChanged:nil];
    [self memFullModeChanged:nil];
    [self softwareTrigEnabledChanged:nil];
    [self externalTrigEnabledChanged:nil];
    [self coincidenceWindowChanged:nil];
    [self coincidenceLevelChanged:nil];
    [self triggerSourceEnableMaskChanged:nil];
    [self swTrigOutEnabledChanged:nil];
    [self extTrigOutEnabledChanged:nil];
    [self triggerOutMaskChanged:nil];
    [self triggerOutLogicChanged:nil];
    [self trigOutCoincidenceLevelChanged:nil];
    [self postTriggerSettingChanged:nil];
    [self fpLogicTypeChanged:nil];
    [self fpTrigInSigEdgeDisableChanged:nil];
    [self fpTrigInToMezzaninesChanged:nil];
    [self fpForceTrigOutChanged:nil];
    [self fpTrigOutModeChanged:nil];
    [self fpTrigOutModeSelectChanged:nil];
    [self fpMBProbeSelectChanged:nil];
    [self fpBusyUnlockSelectChanged:nil];
    [self fpHeaderPatternChanged:nil];
	[self enabledMaskChanged:nil];
    [self fanSpeedModeChanged:nil];
    [self almostFullLevelChanged:nil];
    [self runDelayChanged:nil];
    
    [self writeValueChanged:nil];
    [self totalRateChanged:nil];
    [self selectedRegIndexChanged:nil];
    [self selectedRegChannelChanged:nil];
    [self waveFormRateChanged:nil];
    [self rateGroupChanged:nil];
    [self updateTimePlot:nil];

    [self basicLockChanged:nil];
    [self lowLevelLockChanged:nil];
}

#pragma mark •••Notification of Changes
//a fake action from the scale object
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

- (void) totalRateChanged:(NSNotification*)aNotification
{
    ORRateGroup* theRateObj = [aNotification object];
    if(aNotification == nil || [model waveFormRateGroup] == theRateObj){
        
        [totalRateText setFloatValue: [theRateObj totalRate]];
        [totalRate setNeedsDisplay:YES];
    }
}

- (void) waveFormRateChanged:(NSNotification*)aNote
{
    ORRate* theRateObj = [aNote object];
    [[rateTextFields cellWithTag:[theRateObj tag]] setFloatValue: [theRateObj rate]];
    [rate0 setNeedsDisplay:YES];
}
- (void) updateTimePlot:(NSNotification*)aNote
{
    if(!aNote || ([aNote object] == [[model waveFormRateGroup]timeRate])){
        [timeRatePlot setNeedsDisplay:YES];
    }
}
- (void) rateGroupChanged:(NSNotification*)aNotification
{
    [self registerRates];
}

- (void) serialNumberChanged:(NSNotification*)aNote
{
    if(![model serialNumber] || ![model usbInterface])[serialNumberPopup selectItemAtIndex:0];
    else [serialNumberPopup selectItemWithTitle:[model serialNumber]];
    [[self window] setTitle:[model title]];
}
- (void) interfacesChanged:(NSNotification*)aNote
{
    [self populateInterfacePopup:[aNote object]];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
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

- (void) inputDynamicRangeChanged:(NSNotification*)aNote
{
    if(aNote){
       int chan = [[[aNote userInfo] objectForKey:ORDT5725Chnl] intValue];
        [[inputDynamicRangeMatrix cellAtRow:chan column:0] selectItemAtIndex:[model inputDynamicRange:chan]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5725Channels; i++){
          [[inputDynamicRangeMatrix cellAtRow:i column:0] selectItemAtIndex:[model inputDynamicRange:i]];
        }
    }
}

- (void) selfTrigPulseWidthChanged:(NSNotification*)aNote
{
    if(aNote){
        int chan = [[[aNote userInfo] objectForKey:ORDT5725Chnl] intValue];
        [[selfTrigPulseWidthMatrix cellWithTag:chan] setIntValue:[model selfTrigPulseWidth:chan]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5725Channels; i++){
            [[selfTrigPulseWidthMatrix cellWithTag:i] setIntValue:[model selfTrigPulseWidth:i]];
        }
    }
}

- (void) selfTrigLogicChanged:(NSNotification*)aNote
{
    if(aNote){
        int chan = [[[aNote userInfo] objectForKey:ORDT5725Chnl] intValue] / 2;
        [[selfTrigLogicMatrix cellAtRow:chan column:0] selectItemAtIndex:[model selfTrigLogic:chan]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5725Channels/2; i++){
            [[selfTrigLogicMatrix cellAtRow:i column:0] selectItemAtIndex:[model selfTrigLogic:i]];
        }
    }
}
- (void) selfTrigPulseTypeChanged:(NSNotification*)aNote
{
    if(aNote){
        int chan = [[[aNote userInfo] objectForKey:ORDT5725Chnl] intValue] / 2;
        [[selfTrigPulseTypeMatrix cellAtRow:chan column:0] selectItemAtIndex:[model selfTrigPulseType:chan]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5725Channels/2; i++){
            [[selfTrigPulseTypeMatrix cellAtRow:i column:0] selectItemAtIndex:[model selfTrigPulseType:i]];
        }
    }
}

- (void) thresholdChanged:(NSNotification*) aNotification
{
    if(aNotification){
        int chan = [[[aNotification userInfo] objectForKey:ORDT5725Chnl] intValue];
        [[thresholdMatrix cellWithTag:chan] setIntValue:[model threshold:chan]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5725Channels; i++){
            [[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
        }
    }
}

- (void) dcOffsetChanged:(NSNotification*)aNote
{
    if(aNote){
        int chan = [[[aNote userInfo] objectForKey:ORDT5725Chnl] intValue];
        [[dcOffsetMatrix cellWithTag:chan] setFloatValue:[model convertDacToVolts:[model dcOffset:chan] dynamicRange:[model inputDynamicRange:chan]]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5725Channels; i++){
            [[dcOffsetMatrix cellWithTag:i] setFloatValue:[model convertDacToVolts:[model dcOffset:i] dynamicRange:[model inputDynamicRange:i]]];
        }
    }
}

- (void) trigOnUnderThresholdChanged:(NSNotification*)aNote
{
    [trigOnUnderThresholdMatrix selectCellWithTag: [model trigOnUnderThreshold]];
}

- (void) trigOverlapEnabledChanged:(NSNotification*)aNote
{
    [trigOverlapEnabledButton setIntValue: [model trigOverlapEnabled]];
}

- (void) testPatternEnabledChanged:(NSNotification*)aNote
{
    [testPatternEnabledButton setIntValue: [model testPatternEnabled]];
}

- (void) eventSizeChanged:(NSNotification*)aNote
{
    [eventSizeTextField setIntegerValue: [model eventSize]];
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
    [clockSourcePU selectItemAtIndex: [model clockSource]];
}

- (void) countAllTriggersChanged:(NSNotification*)aNote
{
    [countAllTriggersMatrix selectCellWithTag: [model countAllTriggers]];
}

- (void) startStopRunModeChanged:(NSNotification*)aNote
{
    [startStopRunModePU selectItemAtIndex: [model startStopRunMode]];
}

- (void) memFullModeChanged:(NSNotification*)aNote
{
    [memFullModeMatrix selectCellWithTag: [model memFullMode]];
}

- (void) softwareTrigEnabledChanged:(NSNotification*)aNote
{
    [softwareTrigEnabledButton setIntValue: [model softwareTrigEnabled]];
}

- (void) externalTrigEnabledChanged:(NSNotification*)aNote
{
    [externalTrigEnabledButton setIntValue: [model externalTrigEnabled]];
}

- (void) coincidenceWindowChanged:(NSNotification*)aNote
{
    [coincidenceWindowTextField setIntValue: [model coincidenceWindow]];
}

- (void) coincidenceLevelChanged:(NSNotification*)aNote
{
    [coincidenceLevelTextField setIntValue: [model coincidenceLevel]];
}

- (void) triggerSourceEnableMaskChanged:(NSNotification*)aNote
{
    int i;
    uint32_t mask = [model triggerSourceMask];
    for(i=0;i<kNumDT5725Channels/2;i++){
        [[triggerSourceEnableMaskMatrix cellWithTag:i] setIntValue:(mask & (1L << i)) !=0];
    }
}

- (void) triggerOutMaskChanged:(NSNotification*)aNote
{
    int i;
    uint32_t mask = [model triggerOutMask];
    for(i=0;i<kNumDT5725Channels/2;i++){
        [[triggerOutMaskMatrix cellWithTag:i] setIntValue:(mask & (1L << i)) !=0];
    }
 }

- (void) swTrigOutEnabledChanged:(NSNotification*)aNote
{
    [swTrigOutEnabledButton setIntValue:[model swTrigOutEnabled]];
}

- (void) extTrigOutEnabledChanged:(NSNotification*)aNote
{
    [extTrigOutEnabledButton setIntValue:[model extTrigOutEnabled]];
}

- (void) triggerOutLogicChanged:(NSNotification*)aNote
{
    [triggerOutLogicPU selectItemAtIndex:[model triggerOutLogic]];
}

- (void) trigOutCoincidenceLevelChanged:(NSNotification*)aNote
{
    [trigOutCoincidenceLevelTextField setIntValue:[model trigOutCoincidenceLevel]];
}

- (void) postTriggerSettingChanged:(NSNotification*)aNote
{
    [postTriggerSettingTextField setIntegerValue:[model postTriggerSetting]];
}

- (void) fpLogicTypeChanged:(NSNotification*)aNote
{
    [fpLogicTypeMatrix selectCellWithTag:[model fpLogicType]];
}

- (void) fpTrigInSigEdgeDisableChanged:(NSNotification*)aNote
{
    [fpTrigInSigEdgeDisableButton setIntValue:[model fpTrigInSigEdgeDisable]];
}

- (void) fpTrigInToMezzaninesChanged:(NSNotification*)aNote
{
    [fpTrigInToMezzaninesButton setIntValue:[model fpTrigInToMezzanines]];
}

- (void) fpForceTrigOutChanged:(NSNotification*)aNote
{
    [fpForceTrigOutButton setIntValue:[model fpForceTrigOut]];
}

- (void) fpTrigOutModeChanged:(NSNotification*)aNote
{
    [fpTrigOutModePU selectItemAtIndex:[model fpTrigOutMode]];
}

- (void) fpTrigOutModeSelectChanged:(NSNotification*)aNote
{
    [fpTrigOutModeSelectPU selectItemAtIndex:[model fpTrigOutModeSelect]];
}

- (void) fpMBProbeSelectChanged:(NSNotification*)aNote
{
    [fpMBProbeSelectPU selectItemAtIndex:[model fpMBProbeSelect]];
}

- (void) fpBusyUnlockSelectChanged:(NSNotification*)aNote
{
    [fpBusyUnlockButton setIntValue:[model fpBusyUnlockSelect]];
}

- (void) fpHeaderPatternChanged:(NSNotification*)aNote
{
    [fpHeaderPatternMatrix selectCellWithTag:[model fpHeaderPattern]-1];
}

- (void) enabledMaskChanged:(NSNotification*)aNote
{
    int i;
    unsigned short mask = [model enabledMask];
    for(i=0;i<kNumDT5725Channels;i++){
        [[enabledMaskMatrix cellWithTag:i] setIntValue:(mask & (1<<i)) !=0];
        [[enabled2MaskMatrix cellWithTag:i] setIntValue:(mask & (1<<i)) !=0];
    }
}

- (void) fanSpeedModeChanged:(NSNotification*)aNote;
{
    [fanSpeedModeMatrix selectCellWithTag:[model fanSpeedMode]];
}

- (void) almostFullLevelChanged:(NSNotification*)aNote;
{
    [almostFullLevelTextField setIntValue:[model almostFullLevel]];
}

- (void) runDelayChanged:(NSNotification*)aNote;
{
    [runDelayTextField setIntegerValue:[model runDelay]];
}

- (void) registerRates
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter removeObserver:self name:ORRateChangedNotification object:nil];
    
    NSEnumerator* e = [[[model waveFormRateGroup] rates] objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
		
        [notifyCenter removeObserver:self name:ORRateChangedNotification object:obj];
		
        [notifyCenter addObserver:self
                         selector:@selector(waveFormRateChanged:)
                             name:ORRateChangedNotification
                           object:obj];
    }
}



- (void) setStatusStrings
{
	if(![gOrcaGlobals runInProgress]){
		[bufferStateField setTextColor:[NSColor blackColor]];
		[bufferStateField setStringValue:@"--"];
	}
	else {
		int val = [model bufferState];
        if(val == kDT5725BufferFull) {
            [bufferStateField setTextColor:[NSColor redColor]];
            [bufferStateField setStringValue:@"Full"];
        }
        else if(val == kDT5725BufferReady) {
            [bufferStateField setTextColor:[NSColor blackColor]];
            [bufferStateField setStringValue:@"Not Empty"];
        }
		else {
			[bufferStateField setTextColor:[NSColor blackColor]];
			[bufferStateField setStringValue:@"Empty"];
		}
	}
    [queView setNeedsDisplay:YES];
    float transferRate = [model totalByteRate];
    NSString* s;
    if(transferRate>=500000)    s = [NSString stringWithFormat:@"%.2f MB/sec",transferRate/1000000.];
    else if(transferRate>=1000) s = [NSString stringWithFormat:@"%.2f KB/sec",transferRate/1000.];
    else                        s = [NSString stringWithFormat:@"%.2f B/sec",transferRate];
    [transferRateField setStringValue:s];
    
}

- (void) writeValueChanged:(NSNotification*) aNotification
{
	//  Set value of both text and stepper
	[self updateStepper:writeValueStepper setting:[model selectedRegValue]];
	[writeValueTextField setIntegerValue:[model selectedRegValue]];
}

- (void) selectedRegIndexChanged:(NSNotification*) aNotification
{
	
	//  Set value of popup
	short index = [model selectedRegIndex];
	[self updatePopUpButton:registerAddressPopUp setting:index];
	[self updateRegisterDescription:index];

	
	BOOL readAllowed = [model getAccessType:index] == kReadOnly || [model getAccessType:index] == kReadWrite;
	BOOL writeAllowed = [model getAccessType:index] == kWriteOnly || [model getAccessType:index] == kReadWrite;
	
	[basicWriteButton setEnabled:writeAllowed];
	[basicReadButton setEnabled:readAllowed];
	
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORDT5725BasicLock];
	if ([model selectedRegIndex] >= kInputDyRange && [model selectedRegIndex]<=kAdcTemp){
		[channelPopUp setEnabled:!lockedOrRunningMaintenance];
	}
	else [channelPopUp setEnabled:NO];
    [writeValueTextField setEnabled:writeAllowed];
    [writeValueStepper setEnabled:writeAllowed];
}

- (void) selectedRegChannelChanged:(NSNotification*) aNotification
{
	[self updatePopUpButton:channelPopUp setting:[model selectedChannel]];
}


#pragma mark •••Security Locks
- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORDT5725BasicLock to:secure];
    [basicLockButton setEnabled:secure];
    [gSecurity setLock:ORDT5725LowLevelLock to:secure];
    [lowLevelLockButton setEnabled:secure];
}


- (void) lowLevelLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL locked						= [gSecurity isLocked:ORDT5725BasicLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORDT5725BasicLock];
	

	//[softwareTriggerButton setEnabled: !locked && !runInProgress];
    [basicLockButton setState: locked];
    
    [writeValueStepper setEnabled:!lockedOrRunningMaintenance];
    [writeValueTextField setEnabled:!lockedOrRunningMaintenance];
    [registerAddressPopUp setEnabled:!lockedOrRunningMaintenance];

    [self selectedRegIndexChanged:nil];
	
    [basicWriteButton setEnabled:!lockedOrRunningMaintenance];
    [basicReadButton setEnabled:!lockedOrRunningMaintenance];
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORDT5725BasicLock])s = @"Not in Maintenance Run.";
    }
    [basicLockDocField setStringValue:s];
}

- (void) basicLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL locked						= [gSecurity isLocked:ORDT5725BasicLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORDT5725BasicLock];
    [basicLockButton setState: locked];
    
    [inputDynamicRangeMatrix            setEnabled:!lockedOrRunningMaintenance];
    [selfTrigPulseWidthMatrix           setEnabled:!lockedOrRunningMaintenance];
    [thresholdMatrix                    setEnabled:!lockedOrRunningMaintenance];
    [selfTrigLogicMatrix                setEnabled:!lockedOrRunningMaintenance];
    [dcOffsetMatrix                     setEnabled:!lockedOrRunningMaintenance];

    [trigOverlapEnabledButton           setEnabled:!lockedOrRunningMaintenance];
    [testPatternEnabledButton           setEnabled:!lockedOrRunningMaintenance];
    [trigOnUnderThresholdMatrix         setEnabled:!lockedOrRunningMaintenance];

    [clockSourcePU                      setEnabled:!lockedOrRunningMaintenance];
    [countAllTriggersMatrix             setEnabled:!lockedOrRunningMaintenance];
    [startStopRunModePU                 setEnabled:!lockedOrRunningMaintenance];
    [memFullModeMatrix                  setEnabled:!lockedOrRunningMaintenance];

    [softwareTrigEnabledButton          setEnabled:!lockedOrRunningMaintenance];
    [externalTrigEnabledButton          setEnabled:!lockedOrRunningMaintenance];
    [coincidenceLevelTextField          setEnabled:!lockedOrRunningMaintenance];
    [coincidenceWindowTextField         setEnabled:!lockedOrRunningMaintenance];
    [triggerSourceEnableMaskMatrix      setEnabled:!lockedOrRunningMaintenance];

    [swTrigOutEnabledButton             setEnabled:!lockedOrRunningMaintenance];
    [extTrigOutEnabledButton            setEnabled:!lockedOrRunningMaintenance];
    [triggerOutMaskMatrix               setEnabled:!lockedOrRunningMaintenance];
    [triggerOutLogicPU                  setEnabled:!lockedOrRunningMaintenance];
    [trigOutCoincidenceLevelTextField   setEnabled:!lockedOrRunningMaintenance];

    [postTriggerSettingTextField        setEnabled:!lockedOrRunningMaintenance];

    [fpLogicTypeMatrix                  setEnabled:!lockedOrRunningMaintenance];
    [fpTrigInSigEdgeDisableButton       setEnabled:!lockedOrRunningMaintenance];
    [fpTrigInToMezzaninesButton         setEnabled:!lockedOrRunningMaintenance];
    [fpForceTrigOutButton               setEnabled:!lockedOrRunningMaintenance];
    [fpTrigOutModePU                    setEnabled:!lockedOrRunningMaintenance];
    [fpTrigOutModeSelectPU              setEnabled:!lockedOrRunningMaintenance];
    [fpMBProbeSelectPU                  setEnabled:!lockedOrRunningMaintenance];
    [fpBusyUnlockButton                 setEnabled:!lockedOrRunningMaintenance];
    [fpHeaderPatternMatrix              setEnabled:!lockedOrRunningMaintenance];

    [fanSpeedModeMatrix                 setEnabled:!lockedOrRunningMaintenance];
    [almostFullLevelTextField           setEnabled:!lockedOrRunningMaintenance];
    [runDelayTextField                  setEnabled:!lockedOrRunningMaintenance];

    [initButton                         setEnabled:!lockedOrRunningMaintenance];
	
    [adcCalibrateButton                 setEnabled:!locked && !runInProgress];
    [eventSizeTextField                 setEnabled:!locked && !runInProgress];
    [enabledMaskMatrix                  setEnabled:!locked && !runInProgress];
    
    [serialNumberPopup setEnabled:!locked];
    [self setStatusStrings];

}

#pragma mark •••Actions
- (IBAction) inputDynamicRangeAction:(id)sender
{
    [model setInputDynamicRange:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) selfTrigPulseWidthAction:(id)sender
{
    [model setSelfTrigPulseWidth:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) thresholdAction:(id)sender
{
    [model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) selfTrigLogicAction:(id)sender
{
    [model setSelfTrigLogic:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) selfTrigPulseTypeAction:(id)sender
{
    [model setSelfTrigPulseType:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) dcOffsetAction:(id) sender
{
    float aVoltage = [[sender selectedCell] floatValue];
    BOOL dynamicRange = [model inputDynamicRange:[[sender selectedCell] tag]];
    if(dynamicRange){
        if(aVoltage < -0.25) aVoltage = -0.25;
        else if(aVoltage > 0.25) aVoltage = 0.25;
    }
    else{
        if(aVoltage < -1) aVoltage = -1;
        else if(aVoltage > 1) aVoltage = 1;
    }
    unsigned short aValue = [model convertVoltsToDac:aVoltage dynamicRange:dynamicRange];
    [model setDCOffset:[sender selectedRow] withValue:aValue];
}

- (IBAction) trigOnUnderThresholdAction:(id)sender
{
    [model setTrigOnUnderThreshold:[[sender selectedCell] tag]];
}

- (IBAction) testPatternEnabledAction:(id)sender
{
    [model setTestPatternEnabled:[sender intValue]];
}

- (IBAction) trigOverlapEnabledAction:(id)sender
{
    [model setTrigOverlapEnabled:[sender intValue]];
}

- (void) eventSizeAction:(id)sender
{
    [model setEventSize:[sender intValue]];
}

- (IBAction) clockSourceAction:(id)sender
{
    [model setClockSource:[sender indexOfSelectedItem]];
}

- (IBAction) countAllTriggersAction:(id)sender
{
    [model setCountAllTriggers:[[sender selectedCell] tag]];
}

- (IBAction) startStopRunModeAction:(id)sender
{
    [model setStartStopRunMode:[sender indexOfSelectedItem]];
}

- (IBAction) memFullModeAction:(id)sender
{
    [model setMemFullMode:[[sender selectedCell] tag]];
}

- (IBAction) softwareTrigEnabledAction:(id)sender
{
    [model setSoftwareTrigEnabled:[sender intValue]];
}

- (IBAction) externalTrigEnabledAction:(id)sender
{
    [model setExternalTrigEnabled:[sender intValue]];
}

- (IBAction) coincidenceWindowAction:(id)sender
{
    [model setCoincidenceWindow:[sender intValue]];
}

- (IBAction) coincidenceLevelAction:(id)sender
{
    [model setCoincidenceLevel:[sender intValue]];
}

- (IBAction) triggerSourceEnableMaskAction:(id)sender
{
    int i;
    uint32_t mask = 0;
    for(i=0;i<kNumDT5725Channels/2;i++){
        if([[triggerSourceEnableMaskMatrix cellWithTag:i] intValue]) mask |= (1L << i);
    }
    [model setTriggerSourceMask:mask];
}

- (IBAction) swTrigOutEnabledAction:(id)sender
{
    [model setSwTrigOutEnabled:[sender intValue]];
}

- (IBAction) extTrigOutEnabledAction:(id)sender
{
    [model setExtTrigOutEnabled:[sender intValue]];
}

- (IBAction) triggerOutMaskAction:(id)sender
{
    int i;
    uint32_t mask = 0;
    for(i=0;i<kNumDT5725Channels/2;i++){
        if([[triggerOutMaskMatrix cellWithTag:i] intValue]) mask |= (1L << i);
    }
    [model setTriggerOutMask:mask];
}

- (IBAction) triggerOutLogicAction:(id)sender
{
    [model setTriggerOutLogic:(int)[sender indexOfSelectedItem]];
}

- (IBAction) trigOutCoincidenceLevelAction:(id)sender
{
    [model setTrigOutCoincidenceLevel:(int)[sender intValue]];
}

- (IBAction) postTriggerSettingAction:(id)sender
{
	[model setPostTriggerSetting:[sender intValue]];
}

- (IBAction) fpLogicTypeAction:(id)sender
{
    [model setFpLogicType:[[sender selectedCell] tag]];
}

- (IBAction) fpTrigInSigEdgeDisableAction:(id)sender
{
    [model setFpTrigInSigEdgeDisable:[sender intValue]];
}

- (IBAction) fpTrigInToMezzaninesAction:(id)sender
{
    [model setFpTrigInToMezzanines:[sender intValue]];
}

- (IBAction) fpForceTrigOutAction:(id)sender
{
    [model setFpForceTrigOut:[sender intValue]];
}

- (IBAction) fpTrigOutModeAction:(id)sender
{
    [model setFpTrigOutMode:[sender indexOfSelectedItem]];
}

- (IBAction) fpTrigOutModeSelectAction:(id)sender
{
    [model setFpTrigOutModeSelect:[sender indexOfSelectedItem]];
}

- (IBAction) fpMBProbeSelectAction:(id)sender
{
    [model setFpMBProbeSelect:[sender indexOfSelectedItem]];
}

- (IBAction) fpBusyUnlockSelectAction:(id)sender
{
    [model setFpBusyUnlockSelect:[sender intValue]];
}

- (IBAction) fpHeaderPatternAction:(id)sender
{
    [model setFpHeaderPattern:[[sender selectedCell] tag] + 1];
}

- (void) enabledMaskAction:(id)sender
{
    int i;
    unsigned short mask = 0;
    for(i=0;i<kNumDT5725Channels;i++){
        if([[sender cellWithTag:i] intValue]) mask |= (1 << i);
    }
    [model setEnabledMask:mask];
}

- (IBAction) fanSpeedModeAction:(id)sender
{
    [model setFanSpeedMode:[[sender selectedCell] tag]];
}

- (IBAction) almostFullLevelAction:(id)sender
{
    [model setAlmostFullLevel:[sender intValue]];
}

- (IBAction) runDelayAction:(id)sender
{
    [model setRunDelay:[sender intValue]];
}

- (IBAction) basicReadAction:(id) pSender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		[model read];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nRead of %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:[model selectedRegIndex]]);
    }
}

- (IBAction) basicWriteAction:(id) pSender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		[model write];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nWrite to %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:[model selectedRegIndex]]);
    }
}

- (IBAction) writeValueAction:(id) sender
{
    if ([sender intValue] != [model selectedRegValue]){
		[[[model document] undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setSelectedRegValue:[sender intValue]]; // Set new value
    }
}

- (IBAction) selectRegisterAction:(id) sender
{
    if ([sender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[[model document] undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[sender indexOfSelectedItem]]; // set new value
    }
}

- (IBAction) selectChannelAction:(id) sender
{
    if ([sender indexOfSelectedItem] != [model selectedChannel]){
		[[[model document] undoManager] setActionName:@"Select Channel"]; // Set undo name
		[model setSelectedChannel:[sender indexOfSelectedItem]]; // Set new value
    }
}

- (IBAction) reportAction: (id) sender
{
	@try {
		[model report];
	}
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nRead failed", @"OK", nil, nil,
                        localException);
	}
}
- (IBAction) initBoardAction: (id) sender
{
	@try {
        [self endEditing];
		[model initBoard];
	}
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nInit failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) adcCalibrateAction:(id)sender
{
    @try {
        [model adcCalibrate];
    }
    @catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nADC Calibration Failed", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) generateTriggerAction:(id)sender
{
	@try {
		[model trigger];
	}
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nSoftware Trigger Failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) softwareResetAction:(id)sender
{
    @try {
        [model softwareReset];
    }
    @catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nSoftware Reset Failed", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) softwareClearAction:(id)sender
{
    @try {
        [model clearAllMemory];
    }
    @catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nSoftware Clea Failed", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) configReloadAction:(id)sender
{
    @try {
        [model configReload];
    }
    @catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nConfiguration Reload Failed", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) serialNumberAction:(id)sender
{
    if([serialNumberPopup indexOfSelectedItem] == 0){
        [model setSerialNumber:nil];
    }
    else {
        [model setSerialNumber:[serialNumberPopup titleOfSelectedItem]];
    }
    
}

- (IBAction) basicLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORDT5725BasicLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) lowLevelLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORDT5725LowLevelLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model waveFormRateGroup]integrationTime]){
        [model setRateIntegrationTime:[sender doubleValue]];
    }
}

#pragma mark ***Misc Helpers
- (void) populatePullDown
{
    short	i;
	
    [registerAddressPopUp removeAllItems];
    [channelPopUp removeAllItems];
    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerAddressPopUp insertItemWithTitle:[model getRegisterName:i]
										  atIndex:i];
    }

	for (i = 0; i < kNumDT5725Channels ; i++) {
        [channelPopUp insertItemWithTitle:[NSString stringWithFormat:@"%d", i]
								  atIndex:i];
    }
    [channelPopUp insertItemWithTitle:@"All" atIndex:kNumDT5725Channels];
    
    [self selectedRegIndexChanged:nil];
    [self selectedRegChannelChanged:nil];
	
}

- (void) updateRegisterDescription:(short) aRegisterIndex
{
    NSString* types[] = {
		@"[ReadOnly]",
		@"[WriteOnly]",
		@"[ReadWrite]"
    };
	
    [registerOffsetTextField setStringValue:
	 [NSString stringWithFormat:@"0x%04x",
	  [model getAddressOffset:aRegisterIndex]]];
	
    [registerReadWriteTextField setStringValue:types[[model getAccessType:aRegisterIndex]]];
    [regNameField setStringValue:[model getRegisterName:aRegisterIndex]];
	
    [drTextField setStringValue:[model dataReset:aRegisterIndex] ? @"Y" :@"N"];
    [srTextField setStringValue:[model swReset:aRegisterIndex]   ? @"Y" :@"N"];
    [hrTextField setStringValue:[model hwReset:aRegisterIndex]   ? @"Y" :@"N"];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:lowLevelSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:basicSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:monitoringSize];
		[[self window] setContentView:tabView];
    }
	
    NSString* key = [NSString stringWithFormat: @"orca.%@%u.selectedtab",[model className],[model uniqueIdNumber]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

#pragma mark •••Data Source

- (void) getQueMinValue:(uint32_t*)aMinValue maxValue:(uint32_t*)aMaxValue head:(uint32_t*)aHeadValue tail:(uint32_t*)aTailValue
{
    [model getQueMinValue:aMinValue maxValue:aMaxValue head:aHeadValue tail:aTailValue];
    
}

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
	*yValue = [[[model waveFormRateGroup] timeRate] valueAtIndex:index];
	*xValue = [[[model waveFormRateGroup] timeRate] timeSampledAtIndex:index];
}

- (void) validateInterfacePopup
{
	NSArray* interfaces = [[model getUSBController] interfacesForVender:[model vendorID] product:[model productID]];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([anInterface registeredObject] == nil || [serialNumber isEqualToString:[model serialNumber]]){
			[[serialNumberPopup itemWithTitle:serialNumber] setEnabled:YES];
		}
		else [[serialNumberPopup itemWithTitle:serialNumber] setEnabled:NO];
		
	}
}
@end

@implementation ORDT5725Controller (private)

- (void) populateInterfacePopup:(ORUSB*)usb
{
    [[self undoManager] disableUndoRegistration];
	NSArray* interfaces = [usb interfacesForVender:[model vendorID] product:[model productID]];
	[serialNumberPopup removeAllItems];
	[serialNumberPopup addItemWithTitle:@"N/A"];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([serialNumber length]){
			[serialNumberPopup addItemWithTitle:serialNumber];
		}
	}
	[self validateInterfacePopup];
	if([model serialNumber]){
		[serialNumberPopup selectItemWithTitle:[model serialNumber]];
	}
	else [serialNumberPopup selectItemAtIndex:0];
    [[self undoManager] enableUndoRegistration];
}

@end

