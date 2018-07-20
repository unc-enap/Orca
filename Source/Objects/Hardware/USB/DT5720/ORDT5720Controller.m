//
//  ORDT5720Controller.m
//  Orca
//
//  Created by Mark Howe on Wed Mar 12,2014.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
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


#import "ORDT5720Controller.h"
#import "ORDT5720Model.h"
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

#define kNumChanConfigBits 5
#define kNumTrigSourceBits 10


@interface ORDT5720Controller (private)
- (void) populateInterfacePopup:(ORUSB*)usb;
@end

@implementation ORDT5720Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"DT5720" ];
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
                         name : ORDT5720ModelSerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORDT5720ModelUSBInterfaceChanged
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(integrationChanged:)
                         name : ORRateGroupIntegrationChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(logicTypeChanged:)
                         name : ORDT5720ModelLogicTypeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(zsThresholdChanged:)
                         name : ORDT5720ZsThresholdChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(thresholdChanged:)
                         name : ORDT5720ThresholdChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(numOverUnderZsThresholdChanged:)
                         name : ORDT5720NumOverUnderZsThresholdChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(nlfwdChanged:)
                         name : ORDT5720NlfwdChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(nlbkChanged:)
                         name : ORDT5720NlbkChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(numOverUnderThresholdChanged:)
                         name : ORDT5720NumOverUnderThresholdChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(dacChanged:)
                         name : ORDT5720DacChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(zsAlgorithmChanged:)
                         name : ORDT5720ModelZsAlgorithmChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(packedChanged:)
                         name : ORDT5720ModelPackedChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(testPatternEnabledChanged:)
                         name : ORDT5720ModelTestPatternEnabledChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(trigOnUnderThresholdChanged:)
                         name : ORDT5720ModelTrigOnUnderThresholdChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(trigOverlapEnabledChanged:)
                         name : ORDT5720ModelTrigOverlapEnabledChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(eventSizeChanged:)
                         name : ORDT5720ModelEventSizeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORDT5720ModelClockSourceChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(countAllTriggersChanged:)
                         name : ORDT5720ModelCountAllTriggersChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(gpiRunModeChanged:)
                         name : ORDT5720ModelGpiRunModeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(softwareTrigEnabledChanged:)
                         name : ORDT5720ModelSoftwareTrigEnabledChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(externalTrigEnabledChanged:)
                         name : ORDT5720ModelExternalTrigEnabledChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(coincidenceLevelChanged:)
                         name : ORDT5720ModelCoincidenceLevelChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerSourceEnableMaskChanged:)
                         name : ORDT5720ModelTriggerSourceMaskChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(fpExternalTrigEnabledChanged:)
                         name : ORDT5720ModelFpExternalTrigEnabledChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(fpSoftwareTrigEnabledChanged:)
                         name : ORDT5720ModelFpSoftwareTrigEnabledChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerOutMaskChanged:)
                         name : ORDT5720ModelTriggerOutMaskChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(postTriggerSettingChanged:)
                         name : ORDT5720ModelPostTriggerSettingChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(gpoEnabledChanged:)
                         name : ORDT5720ModelGpoEnabledChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(ttlEnabledChanged:)
                         name : ORDT5720ModelTtlEnabledChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enabledMaskChanged:)
                         name : ORDT5720ModelEnabledMaskChanged
                       object : model];

    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : ORDT5720SelectedRegIndexChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegChannelChanged:)
						 name : ORDT5720SelectedChannelChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : ORDT5720WriteValueChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(basicLockChanged:)
						 name : ORDT5720BasicLock
					   object : nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(lowLevelLockChanged:)
						 name : ORDT5720LowLevelLock
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
                         name : ORDT5720ModelBufferCheckChanged
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
    basicSize      = NSMakeSize(970,400);
    monitoringSize = NSMakeSize(783,290);
    
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
    for(i=0;i<kNumDT5720Channels;i++){
        
        [[logicTypeMatrix       cellAtRow:i column:0] setTag:i];
        [[zsThresholdMatrix     cellAtRow:i column:0] setTag:i];
        [[nLbkMatrix            cellAtRow:i column:0] setTag:i];
        [[nLfwdMatrix           cellAtRow:i column:0] setTag:i];
        [[thresholdMatrix       cellAtRow:i column:0] setTag:i];
        [[numOverUnderZsThresholdMatrix cellAtRow:i column:0] setTag:i];
        [[numOverUnderThresholdMatrix cellAtRow:i column:0] setTag:i];
        [[dacMatrix             cellAtRow:i column:0] setTag:i];
        [[trigOnUnderThresholdMatrix cellAtRow:i column:0] setTag:i];
        [[triggerSourceEnableMaskMatrix cellAtRow:i column:0] setTag:i];
        [[triggerOutMatrix      cellAtRow:i column:0] setTag:i];
        [[enabled2MaskMatrix    cellAtRow:i column:0] setTag:i];
    }
    
    [[eventSizePopUp itemAtIndex:0]setEnabled:NO];
    [[eventSizePopUp itemAtIndex:1]setEnabled:NO];
    [eventSizePopUp setAutoenablesItems:NO];

    [super awakeFromNib];

    
    NSString* key = [NSString stringWithFormat: @"orca.%@%u.selectedtab",[model className],[model uniqueIdNumber]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	[rate0 setNumber:4 height:10 spacing:5];
    [queView setBarColor:[NSColor redColor]];

}

- (void) updateWindow
{
    [ super updateWindow ];
    
	[self serialNumberChanged:nil];
    [self integrationChanged:nil];
   
    [self logicTypeChanged:nil];
    [self zsThresholdChanged:nil];
    [self nlfwdChanged:nil];
    [self nlbkChanged:nil];
    [self thresholdChanged:nil];
    [self numOverUnderZsThresholdChanged:nil];
    [self numOverUnderThresholdChanged:nil];
    [self dacChanged:nil];
    [self zsAlgorithmChanged:nil];
    [self packedChanged:nil];
    [self trigOnUnderThresholdChanged:nil];
    [self testPatternEnabledChanged:nil];
    [self trigOverlapEnabledChanged:nil];
    [self eventSizeChanged:nil];
    [self clockSourceChanged:nil];
	[self countAllTriggersChanged:nil];
    [self gpiRunModeChanged:nil];
    [self softwareTrigEnabledChanged:nil];
    [self externalTrigEnabledChanged:nil];
    [self coincidenceLevelChanged:nil];
    [self triggerSourceEnableMaskChanged:nil];
    [self triggerOutMaskChanged:nil];
    [self fpExternalTrigEnabledChanged:nil];
    [self fpSoftwareTrigEnabledChanged:nil];
    [self postTriggerSettingChanged:nil];
    [self gpoEnabledChanged:nil];
    [self ttlEnabledChanged:nil];
	[self enabledMaskChanged:nil];
    
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

- (void) logicTypeChanged:(NSNotification*)aNote
{
    if(aNote){
        int i = [[[aNote userInfo] objectForKey:ORDT5720Chnl] intValue];
       [[logicTypeMatrix cellAtRow:i column:0] selectItemAtIndex:[model logicType:i]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5720Channels; i++){
            [[logicTypeMatrix cellAtRow:i column:0] selectItemAtIndex:[model logicType:i]];
        }
    }
}

- (void) zsThresholdChanged:(NSNotification*) aNotification
{
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORDT5720Chnl] intValue];
        [[zsThresholdMatrix cellWithTag:chnl] setIntValue:[model zsThreshold:chnl]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5720Channels; i++){
            [[zsThresholdMatrix cellWithTag:i] setIntValue:[model zsThreshold:i]];
        }
    }
    [self basicLockChanged:nil];

}

- (void) packedChanged:(NSNotification*)aNote
{
    [packedCB setIntValue: [model packed]];
}

- (void) numOverUnderZsThresholdChanged: (NSNotification*) aNotification
{
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORDT5720Chnl] intValue];
        [[numOverUnderZsThresholdMatrix cellWithTag:chnl] setIntValue:[model numOverUnderZsThreshold:chnl]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5720Channels; i++){
            [[numOverUnderZsThresholdMatrix cellWithTag:i] setIntValue:[model numOverUnderZsThreshold:i]];
        }
    }
}
- (void) nlfwdChanged:(NSNotification*) aNotification
{
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORDT5720Chnl] intValue];
        [[nLfwdMatrix cellWithTag:chnl] setIntValue:[model nLfwd:chnl]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5720Channels; i++){
            [[nLfwdMatrix cellWithTag:i] setIntValue:[model nLfwd:i]];
        }
    }
}
- (void) nlbkChanged:(NSNotification*) aNotification
{
    // Get the channel that changed and then set the GUI value using the model value.
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORDT5720Chnl] intValue];
        [[nLbkMatrix cellWithTag:chnl] setIntValue:[model nLbk:chnl]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5720Channels; i++){
            [[nLbkMatrix cellWithTag:i] setIntValue:[model nLbk:i]];
        }
    }
}

- (void) thresholdChanged:(NSNotification*) aNotification
{
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORDT5720Chnl] intValue];
        [[thresholdMatrix cellWithTag:chnl] setIntValue:[model threshold:chnl]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5720Channels; i++){
            [[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
        }
    }
}

- (void) numOverUnderThresholdChanged: (NSNotification*) aNotification
{
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORDT5720Chnl] intValue];
        [[numOverUnderThresholdMatrix cellWithTag:chnl] setIntValue:[model numOverUnderThreshold:chnl]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5720Channels; i++){
            [[numOverUnderThresholdMatrix cellWithTag:i] setIntValue:[model numOverUnderThreshold:i]];
        }
    }
}

- (void) dacChanged: (NSNotification*) aNotification
{
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORDT5720Chnl] intValue];
        [[dacMatrix cellWithTag:chnl] setFloatValue:[model convertDacToVolts:[model dac:chnl]]];
    }
    else {
        int i;
        for (i = 0; i < kNumDT5720Channels; i++){
            [[dacMatrix cellWithTag:i] setFloatValue:[model convertDacToVolts:[model dac:i]]];
        }
    }
}

- (void) zsAlgorithmChanged:(NSNotification*)aNote
{
    [zsAlgorithmPU selectItemAtIndex: [model zsAlgorithm]];
    [self basicLockChanged:nil];
}

- (void) trigOnUnderThresholdChanged:(NSNotification*)aNote
{
    [trigOnUnderThresholdMatrix selectCellWithTag: [model trigOnUnderThreshold]];
}

- (void) trigOverlapEnabledChanged:(NSNotification*)aNote
{
    [trigOverlapEnabledButton setIntValue: [model trigOverlapEnabled]];
}

- (void) eventSizeChanged:(NSNotification*)aNote
{
    [eventSizePopUp selectItemAtIndex:	[model eventSize]];
    [eventSizeTextField setStringValue:	[NSString stringWithFormat:@"%d K",(int)(1024*1024./powf(2.,(float)[model eventSize]))/1024]]; //in Samples
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
    [clockSourcePU selectItemAtIndex: [model clockSource]];
}

- (void) countAllTriggersChanged:(NSNotification*)aNote
{
    [countAllTriggersMatrix selectCellWithTag: [model countAllTriggers]];
}

- (void) gpiRunModeChanged:(NSNotification*)aNote
{
    [gpiRunModeMatrix selectCellWithTag: [model gpiRunMode]];
}

- (void) testPatternEnabledChanged:(NSNotification*)aNote
{
    [testPatternEnabledButton setIntValue: [model testPatternEnabled]];
}

- (void) softwareTrigEnabledChanged:(NSNotification*)aNote
{
    [softwareTrigEnabledButton setIntValue: [model softwareTrigEnabled]];
}

- (void) externalTrigEnabledChanged:(NSNotification*)aNote
{
    [externalTrigEnabledButton setIntValue: [model externalTrigEnabled]];
}

- (void) coincidenceLevelChanged:(NSNotification*)aNote
{
    [coincidenceLevelTextField setIntValue: [model coincidenceLevel]];
}

- (void) triggerSourceEnableMaskChanged:(NSNotification*)aNote
{
    int i;
    uint32_t mask = [model triggerSourceMask];
    for(i=0;i<kNumDT5720Channels;i++){
        [[triggerSourceEnableMaskMatrix cellWithTag:i] setIntValue:(mask & (1L << i)) !=0];
    }
}

- (void) triggerOutMaskChanged:(NSNotification*)aNote
{
    int i;
    uint32_t mask = [model triggerOutMask];
    for(i=0;i<kNumDT5720Channels;i++){
        [[triggerOutMatrix cellWithTag:i] setIntValue:(mask & (1L << i)) !=0];
    }
 }

- (void) fpExternalTrigEnabledChanged:(NSNotification*)aNote
{
    [fpExternalTrigEnabledButton setIntValue: [model fpExternalTrigEnabled]];
}

- (void) fpSoftwareTrigEnabledChanged:(NSNotification*)aNote
{
    [fpSoftwareTrigEnabledButton setIntValue: [model fpSoftwareTrigEnabled]];
}

- (void) postTriggerSettingChanged:(NSNotification*)aNote
{
    [postTriggerSettingTextField setIntegerValue:(int)[model postTriggerSetting]];
}

- (void) gpoEnabledChanged:(NSNotification*)aNote
{
    [gpoEnabledMatrix selectCellWithTag: [model gpoEnabled]];
}

- (void) ttlEnabledChanged:(NSNotification*)aNote
{
	[ttlEnabledMatrix selectCellWithTag: [model ttlEnabled]];
}

- (void) enabledMaskChanged:(NSNotification*)aNote
{
    int i;
    unsigned short mask = [model enabledMask];
    for(i=0;i<kNumDT5720Channels;i++){
        [[enabledMaskMatrix cellWithTag:i] setIntValue:(mask & (1<<i)) !=0];
        [[enabled2MaskMatrix cellWithTag:i] setIntValue:(mask & (1<<i)) !=0];
    }
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
        if(val == kDT5720BufferFull) {
            [bufferStateField setTextColor:[NSColor redColor]];
            [bufferStateField setStringValue:@"Full"];
        }
        else if(val == kDT5720BufferReady) {
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
	
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORDT5720BasicLock];
	if ([model selectedRegIndex] >= kZS_Thres && [model selectedRegIndex]<=kAdcConfig){
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
    [gSecurity setLock:ORDT5720BasicLock to:secure];
    [basicLockButton setEnabled:secure];
    [gSecurity setLock:ORDT5720LowLevelLock to:secure];
    [lowLevelLockButton setEnabled:secure];
}


- (void) lowLevelLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL locked						= [gSecurity isLocked:ORDT5720BasicLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORDT5720BasicLock];
	

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
		if(runInProgress && ![gSecurity isLocked:ORDT5720BasicLock])s = @"Not in Maintenance Run.";
    }
    [basicLockDocField setStringValue:s];
}

- (void) basicLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL locked						= [gSecurity isLocked:ORDT5720BasicLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORDT5720BasicLock];
    [basicLockButton setState: locked];
    
	[self setStatusStrings];
    
    [serialNumberPopup setEnabled:!locked];
    
    [logicTypeMatrix                setEnabled:!lockedOrRunningMaintenance];
    [thresholdMatrix                setEnabled:!lockedOrRunningMaintenance];
    
    switch([model zsAlgorithm]){
            
        case kNoZeroSuppression:
            [zsThresholdMatrix              setEnabled:NO];
            [numOverUnderZsThresholdMatrix  setEnabled:NO];
            [nLbkMatrix                     setEnabled:NO];
            [nLfwdMatrix                    setEnabled:NO];
            break;
            
        case kZeroLengthEncoding:
            [zsThresholdMatrix              setEnabled:NO];
            [numOverUnderZsThresholdMatrix  setEnabled:NO];
            [nLbkMatrix                     setEnabled:!lockedOrRunningMaintenance];
            [nLfwdMatrix                    setEnabled:!lockedOrRunningMaintenance];
            break;
            
        case kFullSuppressionBasedOnAmplitude:
            [zsThresholdMatrix              setEnabled:!lockedOrRunningMaintenance];
            [numOverUnderZsThresholdMatrix  setEnabled:!lockedOrRunningMaintenance];
            [nLbkMatrix                     setEnabled:NO];
            [nLfwdMatrix                    setEnabled:NO];
            break;
    }
    
    [numOverUnderThresholdMatrix    setEnabled:!lockedOrRunningMaintenance];
    [dacMatrix                      setEnabled:!lockedOrRunningMaintenance];
    [trigOverlapEnabledButton       setEnabled:!lockedOrRunningMaintenance];
    [testPatternEnabledButton       setEnabled:!lockedOrRunningMaintenance];
    [triggerOutMatrix               setEnabled:!lockedOrRunningMaintenance];
    [trigOnUnderThresholdMatrix     setEnabled:!lockedOrRunningMaintenance];
    [fpSoftwareTrigEnabledButton    setEnabled:!lockedOrRunningMaintenance];
    [fpExternalTrigEnabledButton    setEnabled:!lockedOrRunningMaintenance];
    [postTriggerSettingTextField    setEnabled:!lockedOrRunningMaintenance];
    [triggerSourceEnableMaskMatrix  setEnabled:!lockedOrRunningMaintenance];
    [ttlEnabledMatrix               setEnabled:!lockedOrRunningMaintenance];
    [gpoEnabledMatrix               setEnabled:!lockedOrRunningMaintenance];
    [softwareTrigEnabledButton      setEnabled:!lockedOrRunningMaintenance];
    [externalTrigEnabledButton      setEnabled:!lockedOrRunningMaintenance];
    [gpiRunModeMatrix               setEnabled:!lockedOrRunningMaintenance];
    [clockSourcePU                  setEnabled:!lockedOrRunningMaintenance];
    
    [coincidenceLevelTextField      setEnabled:!lockedOrRunningMaintenance];
    [countAllTriggersMatrix         setEnabled:!lockedOrRunningMaintenance];
    [eventSizePopUp                 setEnabled:!lockedOrRunningMaintenance];
    [initButton                     setEnabled:!lockedOrRunningMaintenance];
	
    [eventSizePopUp                 setEnabled:!locked && !runInProgress];
    [enabledMaskMatrix              setEnabled:!locked && !runInProgress];
}

#pragma mark •••Actions
- (IBAction) logicTypeAction:(id)sender
{
    [model setLogicType:[sender selectedRow] withValue:(int)[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) zsThresholdAction:(id) sender
{
    [model setZsThreshold:[[sender selectedCell] tag] withValue:[sender intValue]]; // Set new value
}

- (IBAction) numOverUnderZsThresholdAction: (id) sender
{
    [model setNumOverUnderZsThreshold:[[sender selectedCell] tag] withValue:[[sender selectedCell] intValue]]; // Set new value
}

- (IBAction) nLfwdAction: (id) sender
{
    [model setNlfwd:[[sender selectedCell] tag] withValue:[sender intValue]]; // Set new value
}

- (IBAction) nLbkAction: (id) sender
{
    [model setNlbk:[[sender selectedCell] tag] withValue:[sender intValue]]; // Set new value
}

- (IBAction) thresholdAction:(id) sender
{
    [model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]]; // Set new value
}

- (IBAction) numOverUnderThresholdAction: (id) sender
{
    [model setNumOverUnderThreshold:[[sender selectedCell] tag] withValue:[[sender selectedCell] intValue]]; // Set new value
}

- (IBAction) dacAction:(id) sender
{
    float aVoltage = [[sender selectedCell] floatValue];
    if(aVoltage < -1)aVoltage = -1;
    else if(aVoltage > 1)aVoltage = 1;
    [model setDac:[[sender selectedCell] tag] withValue:[model convertVoltsToDac:aVoltage]]; // Set new value
}

- (IBAction) zsAlgorithmAction:(id)sender
{
    [model setZsAlgorithm:(int)[sender indexOfSelectedItem]];
}

- (void) packedAction:(id)sender
{
    [model setPacked:[sender intValue]];
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
    [model setEventSize:(int)[sender indexOfSelectedItem]];
}

- (IBAction) clockSourceAction:(id)sender
{
    [model setClockSource:[sender indexOfSelectedItem]];
}


- (IBAction) countAllTriggersAction:(id)sender
{
    [model setCountAllTriggers:[[sender selectedCell] tag]];
}

- (IBAction) gpiRunModeAction:(id)sender
{
    [model setGpiRunMode:[[sender selectedCell] tag]];
}

- (IBAction) softwareTrigEnabledAction:(id)sender
{
    [model setSoftwareTrigEnabled:[sender intValue]];
}

- (IBAction) externalTrigEnabledAction:(id)sender
{
    [model setExternalTrigEnabled:[sender intValue]];
}

- (IBAction) coincidenceLevelAction:(id)sender
{
    [model setCoincidenceLevel:[sender intValue]];
}

- (IBAction) triggerSourceEnableMaskAction:(id)sender
{
    int i;
    uint32_t mask = 0;
    for(i=0;i<kNumDT5720Channels;i++){
        if([[triggerSourceEnableMaskMatrix cellWithTag:i] intValue]) mask |= (1L << i);
    }
    if([[triggerSourceEnableMaskMatrix cellWithTag:0] intValue]) mask |= (1L << 30);
    if([[triggerSourceEnableMaskMatrix cellWithTag:1] intValue]) mask |= (1L << 31);
    [model setTriggerSourceMask:mask];
}

- (IBAction) triggerOutMaskAction:(id)sender
{
    int i;
    uint32_t mask = 0;
    for(i=0;i<kNumDT5720Channels;i++){
        if([[triggerOutMatrix cellWithTag:i] intValue]) mask |= (1L << i);
    }
    if([[triggerOutMatrix cellWithTag:0] intValue]) mask |= (1L << 30);
    if([[triggerOutMatrix cellWithTag:1] intValue]) mask |= (1L << 31);
    [model setTriggerOutMask:mask];
}

- (IBAction) fpExternalTrigEnabledAction:(id)sender
{
    [model setFpExternalTrigEnabled:[sender intValue]];
}

- (IBAction) fpSoftwareTrigEnabledAction:(id)sender
{
    [model setFpSoftwareTrigEnabled:[sender intValue]];
}

- (IBAction) gpoEnabledAction:(id)sender
{
    [model setGpoEnabled:[[sender selectedCell] tag]];
}

- (IBAction) ttlEnabledAction:(id)sender
{
    [model setTtlEnabled:(int)[[sender selectedCell] tag]];
}

- (void) enabledMaskAction:(id)sender
{
    int i;
    unsigned short mask = 0;
    for(i=0;i<kNumDT5720Channels;i++){
        if([[sender cellWithTag:i] intValue]) mask |= (1 << i);
    }
    [model setEnabledMask:mask];
    
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

- (IBAction) postTriggerSettingAction:(id)sender
{
	[model setPostTriggerSetting:[sender intValue]];
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
    [gSecurity tryToSetLock:ORDT5720BasicLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) lowLevelLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORDT5720LowLevelLock to:[sender intValue] forWindow:[self window]];
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

	for (i = 0; i < kNumDT5720Channels ; i++) {
        [channelPopUp insertItemWithTitle:[NSString stringWithFormat:@"%d", i]
								  atIndex:i];
    }
    [channelPopUp insertItemWithTitle:@"All" atIndex:kNumDT5720Channels];
    
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

@implementation ORDT5720Controller (private)

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

