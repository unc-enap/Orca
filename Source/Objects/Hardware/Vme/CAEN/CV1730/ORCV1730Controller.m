//
//ORCV1730Controller.m
//Orca
//
//Created by Mark Howe on Tuesday, Sep 23,2014.
//Copyright (c) 2014 University of North Carolina. All rights reserved.
//
//-------------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORCV1730Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCV1730Model.h"
#import "ORValueBar.h"
#import "ORTimeRate.h"
#import "ORRate.h"
#import "ORRateGroup.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"

#define kNumTrigSourceBits 10

@implementation ORCV1730Controller

#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"CV1730" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
	
    basicSize      = NSMakeSize(280,400);
    settingsSize   = NSMakeSize(880,650);
    monitoringSize = NSMakeSize(783,450);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

    [super awakeFromNib];

    
    [registerAddressPopUp setAlignment:NSTextAlignmentCenter];
    [channelPopUp setAlignment:NSTextAlignmentCenter];
	
    [self populatePullDown];
    
    [[rate0 xAxis] setRngLimitsLow:0 withHigh:500000 withMinRng:128];
    [[totalRate xAxis] setRngLimitsLow:0 withHigh:500000 withMinRng:128];

	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];	
	
    NSString* key = [NSString stringWithFormat: @"orca.ORCaenCard%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];

	[rate0 setNumber:16 height:10 spacing:5];
    
    NSNumberFormatter* rateFormatter = [[NSNumberFormatter alloc] init];
    [rateFormatter setFormat:@"##0.00"];

    int i;
    for(i=0;i<16;i++){
        [[thresholdMatrix cellAtRow:i column:0] setTag:i];
        [[enabledMaskMatrix cellAtRow:i column:0] setTag:i];
        [[dacMatrix cellAtRow:i column:0] setTag:i];
        [[dacMatrix cellAtRow:i column:0] setFormatter:rateFormatter];
        
        [[gainMatrix cellAtRow:i column:0] setTag:i];
        [[pulseWidthMatrix cellAtRow:i column:0] setTag:i];
        [[pulseTypeMatrix cellAtRow:i column:0] setTag:i];

    }
    
    for(i=0;i<8;i++){
        [[triggerSourceMaskMatrix cellAtRow:i column:0] setTag:i];
        [[chanTriggerOutMatrix    cellAtRow:i column:0] setTag:i];
        [[selfTriggerLogicMatrix  cellAtRow:i column:0] setTag:i];
        
        int chan = i*2;
        [[selfTriggerLogicMatrix  cellAtRow:i column:0] removeAllItems];
        [[selfTriggerLogicMatrix  cellAtRow:i column:0] insertItemWithTitle:[NSString stringWithFormat:@"%d And %d",chan,chan+1] atIndex:0];
        [[selfTriggerLogicMatrix  cellAtRow:i column:0] insertItemWithTitle:[NSString stringWithFormat:@"Only %d",chan]          atIndex:1];
        [[selfTriggerLogicMatrix  cellAtRow:i column:0] insertItemWithTitle:[NSString stringWithFormat:@"Only %d",chan+1]        atIndex:2];
        [[selfTriggerLogicMatrix  cellAtRow:i column:0] insertItemWithTitle:[NSString stringWithFormat:@"%d Or %d",chan,chan+1]  atIndex:3];

    }
    
    [rateFormatter release];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [ super registerNotificationObservers ];
	
    [notifyCenter addObserver : self
					 selector : @selector(baseAddressChanged:)
						 name : ORVmeIOCardBaseAddressChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : ORCV1730SelectedRegIndexChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegChannelChanged:)
						 name : ORCV1730SelectedChannelChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : ORCV1730WriteValueChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(thresholdChanged:)
						 name : ORCV1730ChnlThresholdChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(dacChanged:)
						 name : ORCV1730ChnlDacChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(gainChanged:)
                         name : ORCV1730ChnlGainChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(pulseWidthChanged:)
                         name : ORCV1730ChnlPulseWidthChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(pulseTypeChanged:)
                         name : ORCV1730ChnlPulseTypeChanged
                       object : model];

    
    [notifyCenter addObserver : self
                     selector : @selector(channelConfigMaskChanged:)
                         name : ORCV1730ModelChannelConfigMaskChanged
					   object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(countAllTriggersChanged:)
                         name : ORCV1730ModelCountAllTriggersChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(acquisitionModeChanged:)
                         name : ORCV1730ModelAcquisitionModeChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(coincidenceLevelChanged:)
                         name : ORCV1730ModelCoincidenceLevelChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(coincidenceWindowChanged:)
                         name : ORCV1730ModelCoincidenceWindowChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(majorityLevelChanged:)
                         name : ORCV1730ModelMajorityLevelChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerSourceMaskChanged:)
                         name : ORCV1730ModelTriggerSourceMaskChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerOutMaskChanged:)
                         name : ORCV1730ModelTriggerOutMaskChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerOutLogicChanged:)
                         name : ORCV1730ModelTriggerOutLogicChanged
                       object : model];

    
	[notifyCenter addObserver : self
                     selector : @selector(fpIOControlChanged:)
                         name : ORCV1730ModelFrontPanelControlMaskChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(postTriggerSettingChanged:)
                         name : ORCV1730ModelPostTriggerSettingChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledMaskChanged:)
                         name : ORCV1730ModelEnabledMaskChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(basicLockChanged:)
						 name : ORCV1730BasicLock
					   object : nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORCV1730SettingsLock
					   object : nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(basicLockChanged:)
						 name : ORCV1730BasicLock
					   object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(integrationChanged:)
                         name : ORRateGroupIntegrationChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(basicLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(setBufferStateLabel)
                         name : ORCV1730ModelBufferCheckChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(eventSizeChanged:)
                         name : ORCV1730ModelEventSizeChanged
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(selfTriggerLogicChanged:)
                         name : ORCV1730SelfTriggerLogicChanged
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(scaleAction:)
                         name : ORAxisRangeChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(miscAttributesChanged:)
                         name : ORMiscAttributesChanged
                       object : model];
    

    
	[self registerRates];
	
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


#pragma mark ***Interface Management
- (void) updateWindow
{
	[super updateWindow];
    [self integrationChanged:nil];
    [self writeValueChanged:nil];
    [self totalRateChanged:nil];
    [self selectedRegIndexChanged:nil];
    [self selectedRegChannelChanged:nil];
	[self baseAddressChanged:nil];
    [self dacChanged:nil];
    [self gainChanged:nil];
    [self pulseWidthChanged:nil];
    [self pulseTypeChanged:nil];
	[self thresholdChanged:nil];
	[self channelConfigMaskChanged:nil];
	[self countAllTriggersChanged:nil];
	[self acquisitionModeChanged:nil];
    [self coincidenceLevelChanged:nil];
    [self coincidenceWindowChanged:nil];
    [self majorityLevelChanged:nil];
	[self triggerSourceMaskChanged:nil];
    [self triggerOutMaskChanged:nil];
    [self triggerOutLogicChanged:nil];
	[self fpIOControlChanged:nil];
	[self postTriggerSettingChanged:nil];
	[self enabledMaskChanged:nil];
    [self waveFormRateChanged:nil];
 	[self eventSizeChanged:nil];
 	[self slotChanged:nil];
    [self selfTriggerLogicChanged:nil];
	[self settingsLockChanged:nil];
    [self basicLockChanged:nil];
}

- (void) updateTimePlot:(NSNotification*)aNote
{
    if(!aNote || ([aNote object] == [[model waveFormRateGroup]timeRate])){
        [timeRatePlot setNeedsDisplay:YES];
    }
}
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

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[slot1Field setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) eventSizeChanged:(NSNotification*)aNote
{
    int puIndex = [model eventSize];
	[eventSizePopUp selectItemAtIndex:	puIndex];
    NSString* eventSizeString;
    int numBuffers = pow(2.,puIndex);
    if(puIndex<8) eventSizeString = [NSString stringWithFormat:@"%dK",640/numBuffers];
    else           eventSizeString = [NSString stringWithFormat:@"%d",(640*1024)/numBuffers];
    [eventSizeTextField setStringValue: eventSizeString];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORCV1730BasicLock to:secure];
    [basicLockButton setEnabled:secure];
    [gSecurity setLock:ORCV1730SettingsLock to:secure];
    [settingsLockButton setEnabled:secure];
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

- (void) setBufferStateLabel
{
	if(![gOrcaGlobals runInProgress]){
		[bufferStateField setTextColor:[NSColor blackColor]];
		[bufferStateField setStringValue:@"--"];
	}
	else {
		int val = [model bufferState];
		if(val) {
			[bufferStateField setTextColor:[NSColor redColor]];
			[bufferStateField setStringValue:@"Full"];
		}
		else {
			[bufferStateField setTextColor:[NSColor blackColor]];
			[bufferStateField setStringValue:@"Ready"];
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

- (void) writeValueChanged:(NSNotification*) aNotification
{
	//  Set value of both text and stepper
	[self updateStepper:writeValueStepper setting:[model writeValue]];
	[writeValueTextField setIntegerValue:[model writeValue]];
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
	
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORCV1730BasicLock];
	if ([model selectedRegIndex] >= kGain && [model selectedRegIndex]<=kChanConfig){
		[channelPopUp setEnabled:!lockedOrRunningMaintenance];
	}
	else [channelPopUp setEnabled:NO];
	
}

- (void) selectedRegChannelChanged:(NSNotification*) aNotification
{
	[self updatePopUpButton:channelPopUp setting:[model selectedChannel]];
}

- (void) enabledMaskChanged:(NSNotification*)aNote
{
	int i;
	unsigned short mask = [model enabledMask];
	for(i=0;i<[model numberOfChannels];i++){
		[[enabledMaskMatrix cellWithTag:i] setIntValue:(mask & (1<<i)) !=0];
		[[enabled2MaskMatrix cellWithTag:i] setIntValue:(mask & (1<<i)) !=0];
	}
}

- (void) postTriggerSettingChanged:(NSNotification*)aNote
{
	[postTriggerSettingTextField setIntegerValue:[model postTriggerSetting]];
}

- (void) triggerSourceMaskChanged:(NSNotification*)aNote
{
	int i;
	uint32_t mask = [model triggerSourceMask];
	for(i=0;i<16;i++){
		[[chanTriggerMatrix cellWithTag:i] setIntValue:(mask & (1L << i)) !=0];
	}
	[[otherTriggerMatrix cellWithTag:0] setIntValue:(mask & (1L << 30)) !=0];
	[[otherTriggerMatrix cellWithTag:1] setIntValue:(mask & (1L << 31)) !=0];
}

- (void) triggerOutMaskChanged:(NSNotification*)aNote
{
	int i;
	uint32_t mask = [model triggerOutMask];
	for(i=0;i<16;i++){
		[[chanTriggerOutMatrix cellWithTag:i] setIntValue:(mask & (1L << i)) !=0];
	}
	[[otherTriggerOutMatrix cellWithTag:0] setIntValue:(mask & (1L << 30)) !=0];
	[[otherTriggerOutMatrix cellWithTag:1] setIntValue:(mask & (1L << 31)) !=0];
}

- (void) triggerOutLogicChanged:(NSNotification*)aNote
{
    [triggerOutLogicPopUp selectItemAtIndex:[model triggerOutLogic]];
}

- (void) fpIOControlChanged:(NSNotification*)aNote
{
	[fpIOTrgInMatrix        selectCellWithTag:  ([model frontPanelControlMask] >> 0) & 0x1];
	[fpIOTrgOutMatrix       selectCellWithTag:  ([model frontPanelControlMask] >> 1) & 0x1];
	[fpIOLVDS0Matrix        selectCellWithTag:  ([model frontPanelControlMask] >> 2) & 0x1];
	[fpIOLVDS1Matrix        selectCellWithTag:  ([model frontPanelControlMask] >> 3) & 0x1];
	[fpIOLVDS2Matrix        selectCellWithTag:  ([model frontPanelControlMask] >> 4) & 0x1];
	[fpIOLVDS3Matrix        selectCellWithTag:  ([model frontPanelControlMask] >> 5) & 0x1];
    [fpIOModeMatrix         selectCellWithTag:  ([model frontPanelControlMask] >> 6) & 0x3];
    [fpIOPatternLatchMatrix selectCellWithTag:  ([model frontPanelControlMask] >> 9) & 0x1];
}

- (void) coincidenceLevelChanged:(NSNotification*)aNote
{
	[coincidenceLevelTextField setIntValue: [model coincidenceLevel]];
}

- (void) coincidenceWindowChanged:(NSNotification*)aNote
{
    [coincidenceWindowTextField setIntValue: [model coincidenceWindow]];
}

- (void) majorityLevelChanged:(NSNotification*)aNote
{
    [majorityLevelTextField setIntValue: [model majorityLevel]];
}

- (void) acquisitionModeChanged:(NSNotification*)aNote
{
	[acquisitionModeMatrix selectCellWithTag:[model acquisitionMode]];
}

- (void) countAllTriggersChanged:(NSNotification*)aNote
{
	[countAllTriggersMatrix selectCellWithTag: [model countAllTriggers]];
}

- (void) channelConfigMaskChanged:(NSNotification*)aNote
{
	int i;
	unsigned short mask = [model channelConfigMask];
	for(i=0;i<3;i++){
		[[channelConfigMaskMatrix cellWithTag:i] setIntValue:(mask & (0x1<<i)) >0];
	}
}

- (void) baseAddressChanged:(NSNotification*) aNotification
{
	//  Set value of both text and stepper
	[addressTextField setIntegerValue:[model baseAddress]];
}

- (void) thresholdChanged:(NSNotification*) aNotification
{
	// Get the channel that changed and then set the GUI value using the model value.
	if(aNotification){
		int chnl = [[[aNotification userInfo] objectForKey:ORCV1730Chnl] intValue];
		[[thresholdMatrix cellWithTag:chnl] setIntValue:[model threshold:chnl]];
	}
	else {
		int i;
		for (i = 0; i < [model numberOfChannels]; i++){
			[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
		}
	}
}

- (void) selfTriggerLogicChanged:(NSNotification*) aNotification
{
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORCV1730Chnl] intValue];
        [[selfTriggerLogicMatrix cellAtRow:chnl column:0] selectItemAtIndex:[model selfTriggerLogic:chnl]];
    }
    else {
        int i;
        for (i = 0; i < [model numberOfChannels]/2; i++){
            [[selfTriggerLogicMatrix cellAtRow:i column:0] selectItemAtIndex:[model selfTriggerLogic:i]];
        }
    }
}


- (void) dacChanged: (NSNotification*) aNotification
{
	if(aNotification){
		int chnl = [[[aNotification userInfo] objectForKey:ORCV1730Chnl] intValue];
		[[dacMatrix cellWithTag:chnl] setFloatValue:[model convertDacToVolts:[model dac:chnl]]];
	}
	else {
		int i;
		for (i = 0; i < [model numberOfChannels]; i++){
			[[dacMatrix cellWithTag:i] setFloatValue:[model convertDacToVolts:[model dac:i]]];
		}
	}
}

- (void) gainChanged: (NSNotification*) aNotification
{
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORCV1730Chnl] intValue];
        [[gainMatrix cellAtRow:chnl column:0] selectItemAtIndex:[model selfTriggerLogic:chnl]];
    }
    else {
        int i;
        for (i = 0; i < [model numberOfChannels]; i++){
            [[gainMatrix cellAtRow:i column:0] selectItemAtIndex:[model gain:i]];
        }
    }
}

- (void) pulseWidthChanged: (NSNotification*) aNotification
{
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORCV1730Chnl] intValue];
        [[pulseWidthMatrix cellWithTag:chnl] setIntValue:[model pulseWidth:chnl]];
    }
    else {
        int i;
        for (i = 0; i < [model numberOfChannels]; i++){
            [[pulseWidthMatrix cellWithTag:i] setIntValue:[model pulseWidth:i]];
        }
    }
}

- (void) pulseTypeChanged: (NSNotification*) aNotification
{
    if(aNotification){
        int chnl = [[[aNotification userInfo] objectForKey:ORCV1730Chnl] intValue];
        [[pulseTypeMatrix cellAtRow:chnl column:0] selectItemAtIndex:[model selfTriggerLogic:chnl]];
    }
    else {
        int i;
        for (i = 0; i < [model numberOfChannels]; i++){
            [[pulseTypeMatrix cellAtRow:i column:0] selectItemAtIndex:[model selfTriggerLogic:i]];
        }
    }
}



- (void) basicLockChanged:(NSNotification*)aNotification
{	
    BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL locked						= [gSecurity isLocked:ORCV1730BasicLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORCV1730BasicLock];
	
	//[softwareTriggerButton setEnabled: !locked && !runInProgress]; 
    [basicLockButton setState: locked];
    
    [addressTextField setEnabled:!locked && !runInProgress];
	
    [writeValueStepper setEnabled:!lockedOrRunningMaintenance];
    [writeValueTextField setEnabled:!lockedOrRunningMaintenance];
    [registerAddressPopUp setEnabled:!lockedOrRunningMaintenance];
	
    [self selectedRegIndexChanged:nil];
	
    [basicWriteButton setEnabled:!lockedOrRunningMaintenance];
    [basicReadButton setEnabled:!lockedOrRunningMaintenance]; 
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORCV1730BasicLock])s = @"Not in Maintenance Run.";
    }
    [basicLockDocField setStringValue:s];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{	
    BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL locked						= [gSecurity isLocked:ORCV1730SettingsLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORCV1730SettingsLock];
    [settingsLockButton setState: locked];
	[self setBufferStateLabel];
    [thresholdMatrix setEnabled:!lockedOrRunningMaintenance]; 
    //[softwareTriggerButton setEnabled:!lockedOrRunningMaintenance]; 
	[softwareTriggerButton setEnabled:YES]; 
    [otherTriggerMatrix setEnabled:!lockedOrRunningMaintenance]; 
    [chanTriggerMatrix setEnabled:!lockedOrRunningMaintenance]; 
	[otherTriggerOutMatrix setEnabled:!lockedOrRunningMaintenance]; 
	[chanTriggerOutMatrix setEnabled:!lockedOrRunningMaintenance]; 
	[fpIOModeMatrix setEnabled:!lockedOrRunningMaintenance]; 
	[fpIOLVDS0Matrix setEnabled:!lockedOrRunningMaintenance]; 
	[fpIOLVDS1Matrix setEnabled:!lockedOrRunningMaintenance]; 
	[fpIOLVDS2Matrix setEnabled:!lockedOrRunningMaintenance]; 
	[fpIOLVDS3Matrix setEnabled:!lockedOrRunningMaintenance]; 
	[fpIOPatternLatchMatrix setEnabled:!lockedOrRunningMaintenance]; 
	[fpIOTrgInMatrix setEnabled:!lockedOrRunningMaintenance]; 
	[fpIOTrgOutMatrix setEnabled:!lockedOrRunningMaintenance]; 
	[fpIOGetButton setEnabled:!lockedOrRunningMaintenance]; 
	[fpIOSetButton setEnabled:!lockedOrRunningMaintenance]; 
    [postTriggerSettingTextField setEnabled:!lockedOrRunningMaintenance]; 
    [triggerSourceMaskMatrix setEnabled:!lockedOrRunningMaintenance]; 
    [coincidenceLevelTextField setEnabled:!lockedOrRunningMaintenance];
    [coincidenceWindowTextField setEnabled:!lockedOrRunningMaintenance];
    [majorityLevelTextField setEnabled:!lockedOrRunningMaintenance];
    [dacMatrix setEnabled:!lockedOrRunningMaintenance];
    [acquisitionModeMatrix setEnabled:!lockedOrRunningMaintenance]; 
    [countAllTriggersMatrix setEnabled:!lockedOrRunningMaintenance]; 
    [channelConfigMaskMatrix setEnabled:!lockedOrRunningMaintenance]; 
    [eventSizePopUp setEnabled:!lockedOrRunningMaintenance]; 
    [loadThresholdsButton setEnabled:!lockedOrRunningMaintenance]; 
    [initButton setEnabled:!lockedOrRunningMaintenance]; 
	
	//these must NOT or can not be changed when run in progress
    [eventSizePopUp setEnabled:!locked && !runInProgress];
    [enabledMaskMatrix setEnabled:!locked && !runInProgress]; 
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORCV1730SettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingsLockDocField setStringValue:s];
	
	
}

#pragma mark •••Actions

- (void) eventSizeAction:(id)sender
{
	[model setEventSize:(int)[sender indexOfSelectedItem]];
}

- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model waveFormRateGroup]integrationTime]){
        [model setRateIntegrationTime:[sender doubleValue]];		
    }
}
- (IBAction) baseAddressAction:(id) aSender
{
    if ([aSender intValue] != [model baseAddress]){
		[[[model document] undoManager] setActionName:@"Set Base Address"]; // Set undo name.
		[model setBaseAddress:[aSender intValue]]; // set new value.
    }
} 

- (IBAction) basicRead:(id) pSender
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

- (IBAction) basicWrite:(id) pSender
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

- (IBAction) writeValueAction:(id) aSender
{
    if ([aSender intValue] != [model writeValue]){
		[[[model document] undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}

- (IBAction) selectRegisterAction:(id) aSender
{
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[[model document] undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
    }
}

- (IBAction) selectChannelAction:(id) aSender
{
    if ([aSender indexOfSelectedItem] != [model selectedChannel]){
		[[[model document] undoManager] setActionName:@"Select Channel"]; // Set undo name
		[model setSelectedChannel:[aSender indexOfSelectedItem]]; // Set new value
    }
}
- (IBAction) basicLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORCV1730BasicLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) settingsLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORCV1730SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) report: (id) sender
{
	@try {
		[model report];
	}
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nRead failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) loadThresholds: (id) sender
{
	@try {
		[model writeThresholds];
		NSLog(@"Caen 1730 Card %d thresholds loaded\n",[model slot]);
	}
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nThreshold loading failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) initBoard: (id) sender
{
	@try {
		[model initBoard];
		NSLog(@"Caen 1730 Card %d inited\n",[model slot]);
	}
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nInit failed", @"OK", nil, nil,
                        localException);
	}
}


- (void) enabledMaskAction:(id)sender
{
	int i;
	unsigned short mask = 0;
	for(i=0;i<[model numberOfChannels];i++){
		if([[sender cellWithTag:i] intValue]) mask |= (1 << i);
	}
	[model setEnabledMask:mask];	
	
}

- (void) postTriggerSettingTextFieldAction:(id)sender
{
	[model setPostTriggerSetting:[sender intValue]];
}

- (IBAction) triggerSourceMaskAction:(id)sender
{
	int i;
	uint32_t mask = 0;
	for(i=0;i<8;i++){
		if([[chanTriggerMatrix cellWithTag:i] intValue]) mask |= (1L << i);
	}
    if([[triggerSourceMaskMatrix cellWithTag:0] intValue]) mask |= (1L << 31);
	if([[triggerSourceMaskMatrix cellWithTag:1] intValue]) mask |= (1L << 30);
	[model setTriggerSourceMask:mask];
}

- (IBAction) triggerOutMaskAction:(id)sender
{
	int i;
	uint32_t mask = 0;
	for(i=0;i<8;i++){
		if([[chanTriggerOutMatrix cellWithTag:i] intValue]) mask |= (1L << i);
	}
	if([[otherTriggerOutMatrix cellWithTag:0] intValue]) mask |= (1L << 30);
	if([[otherTriggerOutMatrix cellWithTag:1] intValue]) mask |= (1L << 31);
	[model setTriggerOutMask:mask];	
}

- (IBAction) triggerOutLogicAction:(id)sender
{
    [model setTriggerOutLogic:[triggerOutLogicPopUp indexOfSelectedItem]];
}

- (IBAction) fpIOControlAction:(id)sender
{
	uint32_t mask = 0;
    mask |= [[fpIOTrgInMatrix           selectedCell] tag] << 0;
    mask |= [[fpIOTrgOutMatrix          selectedCell] tag] << 1;
    mask |= [[fpIOLVDS0Matrix           selectedCell] tag] << 2;
    mask |= [[fpIOLVDS1Matrix           selectedCell] tag] << 3;
    mask |= [[fpIOLVDS2Matrix           selectedCell] tag] << 4;
    mask |= [[fpIOLVDS3Matrix           selectedCell] tag] << 5;
    mask |= [[fpIOModeMatrix            selectedCell] tag] << 6;
    mask |= [[fpIOFeaturesMatrix        selectedCell] tag] << 8;
    mask |= [[fpIOPatternLatchMatrix    selectedCell] tag] << 9;
	[model setFrontPanelControlMask:mask];	
}

- (IBAction) fpIOGetAction:(id)sender
{
	@try {
		[model readFrontPanelControl];
	}
	@catch(NSException* localException) {
		ORRunAlertPanel([localException name], @"%@\nGet Front Panel Failed", @"OK", nil, nil,
				localException);
	}
}

- (IBAction) fpIOSetAction:(id)sender
{
	@try {
		[model writeFrontPanelControl];
	}
	@catch(NSException* localException) {
		ORRunAlertPanel([localException name], @"%@\nSet Front Panel Failed", @"OK", nil, nil,
				localException);
	}
}

- (IBAction) coincidenceLevelTextFieldAction:(id)sender
{
	[model setCoincidenceLevel:[sender intValue]];	
}

- (IBAction) coincidenceWindowTextFieldAction:(id)sender
{
    [model setCoincidenceWindow:[sender intValue]];
}

- (IBAction) majorityLevelTextFieldAction:(id)sender
{
    [model setMajorityLevel:[sender intValue]];
}

- (IBAction) generateTriggerAction:(id)sender
{
	@try {
		[model generateSoftwareTrigger];
	}
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nSoftware Trigger Failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) acquisitionModeAction:(id)sender
{
	[model setAcquisitionMode:[[sender selectedCell] tag]];	
}

- (IBAction) countAllTriggersAction:(id)sender
{
	[model setCountAllTriggers:[[sender selectedCell] tag]];	
}

- (IBAction) channelConfigMaskAction:(id)sender
{
	int i;
	unsigned short mask = 0;
	for(i=0;i<3;i++){
		if([[sender cellWithTag:i] intValue]) mask |= (0x1 << i);
	}
	[model setChannelConfigMask:mask];	
}

- (IBAction) dacAction:(id) aSender
{
	[model setDac:[[aSender selectedCell] tag] withValue:[model convertVoltsToDac:[[aSender selectedCell] floatValue]]];
}

- (IBAction) gainAction:(id) aSender
{
    [model setGain:[aSender selectedRow] withValue:[[aSender selectedCell] indexOfSelectedItem]];
}

- (IBAction) pulseWidthAction:(id) aSender
{
    [model setPulseWidth:[[aSender selectedCell] tag] withValue:[[aSender selectedCell] intValue]];
}

- (IBAction) pulseTypeAction:(id) aSender
{
    [model setPulseType:[aSender selectedRow] withValue:[[aSender selectedCell] indexOfSelectedItem]];
}

- (IBAction) thresholdAction:(id) aSender
{
    [model setThreshold:[[aSender selectedCell] tag] withValue:[aSender intValue]]; // Set new value
}

- (IBAction) selfTriggerLogicAction:(id)aSender
{
    [model setSelfTriggerLogic:[aSender selectedRow] withValue:(uint32_t)[[aSender selectedCell] indexOfSelectedItem]];
}

#pragma mark ***Misc Helpers
- (void) populatePullDown
{
    short	i;
	
    [registerAddressPopUp removeAllItems];
    [channelPopUp removeAllItems];
    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerAddressPopUp insertItemWithTitle:[model 
												   getRegisterName:i] 
										  atIndex:i];
    }
	
	for (i = 0; i < 16 ; i++) {
        [channelPopUp insertItemWithTitle:[NSString stringWithFormat:@"%d", i] 
								  atIndex:i];
    }
    [channelPopUp insertItemWithTitle:@"All" atIndex:16];
    
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
		[self resizeWindowToSize:basicSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:settingsSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:monitoringSize];
		[[self window] setContentView:tabView];
    }
	
    NSString* key = [NSString stringWithFormat: @"orca.ORCaenCard%d.selectedtab",[model slot]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
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
	*yValue = [[[model waveFormRateGroup] timeRate] valueAtIndex:index];
	*xValue = [[[model waveFormRateGroup] timeRate] timeSampledAtIndex:index];
}

@end
