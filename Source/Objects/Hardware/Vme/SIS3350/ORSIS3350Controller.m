//-------------------------------------------------------------------------
//  ORSIS3350Controller.h
//
//  Created by Mark A. Howe on Thursday 8/6/09
//  Copyright (c) 2009 Universiy of North Carolina. All rights reserved.
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
#import "ORSIS3350Controller.h"
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

@implementation ORSIS3350Controller

-(id)init
{
    self = [super initWithWindowNibName:@"SIS3350"];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
	settingSize     = NSMakeSize(750,400);
    rateSize		= NSMakeSize(480,380);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
	NSString* key = [NSString stringWithFormat: @"orca.SIS3350%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	triggerModePU[0] = triggerModePU0;
	triggerModePU[1] = triggerModePU1;
	triggerModePU[2] = triggerModePU2;
	triggerModePU[3] = triggerModePU3;
	
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
	
	[rate0 setNumber:4 height:10 spacing:5];

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
                         name : ORSIS3350SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORSIS3350RateGroupChangedNotification
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
                     selector : @selector(triggerModeChanged:)
                         name : ORSIS3350ModelTriggerModeChanged
                       object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(thresholdChanged:)
                         name : ORSIS3350ModelThresholdChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(gainChanged:)
                         name : ORSIS3350ModelGainChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dacValueChanged:)
                         name : ORSIS3350ModelDacValueChanged
                       object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(thresholdOffChanged:)
                         name : ORSIS3350ModelThresholdOffChanged
                       object : model];
	
    [self registerRates];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(moduleIDChanged:)
                         name : ORSIS3350ModelIDChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(operationModeChanged:)
                         name : ORSIS3350ModelOperationModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORSIS3350ModelClockSourceChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(triggerMaskChanged:)
                         name : ORSIS3350ModelTriggerMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(multiEventChanged:)
                         name : ORSIS3350ModelMultiEventChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(invertLemoChanged:)
                         name : ORSIS3350ModelInvertLemoChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(memoryTriggerDelayChanged:)
                         name : ORSIS3350ModelMemoryTriggerDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(memoryStartModeLengthChanged:)
                         name : ORSIS3350ModelMemoryStartModeLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(freqMChanged:)
                         name : ORSIS3350ModelFreqMChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(freqNChanged:)
                         name : ORSIS3350ModelFreqNChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(maxNumEventsChanged:)
                         name : ORSIS3350ModelMaxNumEventsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(gateSyncLimitLengthChanged:)
                         name : ORSIS3350ModelGateSyncLimitLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(gateSyncExtendLengthChanged:)
                         name : ORSIS3350ModelGateSyncExtendLengthChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(trigPulseLenChanged:)
                         name : ORSIS3350ModelTrigPulseLenChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(sumGChanged:)
                         name : ORSIS3350ModelSumGChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(peakingTimeChanged:)
                         name : ORSIS3350ModelPeakingTimeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ringBufferLenChanged:)
                         name : ORSIS3350ModelRingBufferLenChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(ringBufferPreDelayChanged:)
                         name : ORSIS3350ModelRingBufferPreDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(endAddressThresholdChanged:)
                         name : ORSIS3350ModelEndAddressThresholdChanged
						object: model];
		
    [notifyCenter addObserver : self
                     selector : @selector(memoryWrapLengthChanged:)
                         name : ORSIS3350ModelMemoryWrapLengthChanged
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
	[self triggerModeChanged:nil];
	[self gainChanged:nil];
	[self dacValueChanged:nil];
	[self thresholdChanged:nil];
	[self thresholdOffChanged:nil];
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];
	[self moduleIDChanged:nil];
	[self operationModeChanged:nil];
	[self clockSourceChanged:nil];
	[self triggerMaskChanged:nil];
	[self multiEventChanged:nil];
	[self invertLemoChanged:nil];
	[self memoryTriggerDelayChanged:nil];
	[self memoryStartModeLengthChanged:nil];
	[self freqMChanged:nil];
	[self freqNChanged:nil];
	[self maxNumEventsChanged:nil];
	[self gateSyncLimitLengthChanged:nil];
	[self gateSyncExtendLengthChanged:nil];
	[self trigPulseLenChanged:nil];
	[self sumGChanged:nil];
	[self peakingTimeChanged:nil];
	[self ringBufferLenChanged:nil];
	[self ringBufferPreDelayChanged:nil];
	[self endAddressThresholdChanged:nil];
	[self memoryWrapLengthChanged:nil];
}

#pragma mark •••Interface Management
- (void) memoryWrapLengthChanged:(NSNotification*)aNote
{
	[memoryWrapLengthField setIntegerValue: [model memoryWrapLength]];
}

- (void) endAddressThresholdChanged:(NSNotification*)aNote
{
	[endAddressThresholdField setIntValue: [model endAddressThreshold]];
}

- (void) ringBufferPreDelayChanged:(NSNotification*)aNote
{
	[ringBufferPreDelayField setIntValue: [model ringBufferPreDelay]];
}

- (void) ringBufferLenChanged:(NSNotification*)aNote
{
	[ringBufferLenField setIntValue: [model ringBufferLen]];
}

- (void) gateSyncExtendLengthChanged:(NSNotification*)aNote
{
	[gateSyncExtendLengthField setIntValue: [model gateSyncExtendLength]];
}

- (void) gateSyncLimitLengthChanged:(NSNotification*)aNote
{
	[gateSyncLimitLengthField setIntValue: [model gateSyncLimitLength]];
}

- (void) maxNumEventsChanged:(NSNotification*)aNote
{
	[maxNumEventsField setIntegerValue: [model maxNumEvents]];
}

- (void) freqNChanged:(NSNotification*)aNote
{
	[freqNPU selectItemAtIndex: [model freqN]];
}

- (void) freqMChanged:(NSNotification*)aNote
{
	[freqMField setIntValue: [model freqM]];
}

- (void) memoryStartModeLengthChanged:(NSNotification*)aNote
{
	[memoryStartModeLengthField setIntegerValue: [model memoryStartModeLength]];
}

- (void) memoryTriggerDelayChanged:(NSNotification*)aNote
{
	[memoryTriggerDelayField setIntegerValue: [model memoryTriggerDelay]];
}

- (void) invertLemoChanged:(NSNotification*)aNote
{
	[invertLemoCB setIntValue: [model invertLemo]];
}

- (void) multiEventChanged:(NSNotification*)aNote
{
	[multiEventCB setIntValue: [model multiEvent]];
	[self settingsLockChanged:nil];
}

- (void) triggerMaskChanged:(NSNotification*)aNote
{
	int aMask = [model triggerMask];
	int i;
	for(i=0;i<3;i++){
		[[triggerMaskMatrix cellWithTag:i] setIntValue:aMask & (1<<i)];
	}
	[self settingsLockChanged:nil];
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
	[clockSourcePU selectItemAtIndex: [model clockSource]];
	[self settingsLockChanged:nil];
}

- (void) operationModeChanged:(NSNotification*)aNote
{
	[operationModePU selectItemAtIndex: [model operationMode]];
	[self settingsLockChanged:nil];
}

- (void) moduleIDChanged:(NSNotification*)aNote
{
	unsigned short moduleID = [model moduleID];
	if(moduleID) [moduleIDField setStringValue:[NSString stringWithFormat:@"%x",moduleID]];
	else		 [moduleIDField setStringValue:@"---"];
}

- (void) triggerModeChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		int i;
		for(i=0;i<kNumSIS3350Channels;i++){
			[triggerModePU[i] selectItemAtIndex:[model triggerMode:i]];
		}
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[triggerModePU[i]  selectItemAtIndex:[model triggerMode:i]];
	}
	[self settingsLockChanged:nil];
}

- (void) gainChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3350Channels;i++)[[gainMatrix cellWithTag:i] setIntegerValue:[model gain:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[gainMatrix cellWithTag:i] setIntegerValue:[model gain:i]];
	}
}

- (void) dacValueChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3350Channels;i++)[[dacValueMatrix cellWithTag:i] setIntegerValue:[model dacValue:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[dacValueMatrix cellWithTag:i] setIntegerValue:[model dacValue:i]];
	}
}

- (void) thresholdChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3350Channels;i++)[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
	}
}
- (void) thresholdOffChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3350Channels;i++)[[thresholdOffMatrix cellWithTag:i] setIntValue:[model thresholdOff:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[thresholdOffMatrix cellWithTag:i] setIntValue:[model thresholdOff:i]];
	}
}

- (void) trigPulseLenChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3350Channels;i++)[[trigPulseLenMatrix cellWithTag:i] setIntValue:[model trigPulseLen:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[trigPulseLenMatrix cellWithTag:i] setIntValue:[model trigPulseLen:i]];
	}
}

- (void) sumGChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3350Channels;i++)[[sumGMatrix cellWithTag:i] setIntValue:[model sumG:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[sumGMatrix cellWithTag:i] setIntValue:[model sumG:i]];
	}
}

- (void) peakingTimeChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3350Channels;i++)[[peakingTimeMatrix cellWithTag:i] setIntValue:[model peakingTime:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[peakingTimeMatrix cellWithTag:i] setIntValue:[model peakingTime:i]];
	}
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
    [gSecurity setLock:ORSIS3350SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSIS3350SettingsLock];
    BOOL locked = [gSecurity isLocked:ORSIS3350SettingsLock];
    
    [settingLockButton			setState: locked];
    [addressText				setEnabled:!locked && !runInProgress];
	[operationModePU			setEnabled:!lockedOrRunningMaintenance];
	[clockSourcePU				setEnabled:!lockedOrRunningMaintenance];
    [initButton					setEnabled:!lockedOrRunningMaintenance];
	[thresholdMatrix			setEnabled:!lockedOrRunningMaintenance];
	[trigPulseLenMatrix			setEnabled:!lockedOrRunningMaintenance];
	
	BOOL usingFreqSynesizer = ([model clockSource] == 0);
	[freqNPU	setEnabled:!lockedOrRunningMaintenance && usingFreqSynesizer];
	[freqMField setEnabled:!lockedOrRunningMaintenance && usingFreqSynesizer];

	int i;
	for(i=0;i<kNumSIS3350Channels;i++){
		[triggerModePU[i]	setEnabled:!lockedOrRunningMaintenance];
		int triggerMode = [model triggerMode:i];
		BOOL enableCondition = YES;
		if(triggerMode >= 0 && triggerMode <= 2)enableCondition = NO;
		[[sumGMatrix cellWithTag:i]			setEnabled:!lockedOrRunningMaintenance && enableCondition];
		[[peakingTimeMatrix cellWithTag:i] setEnabled:!lockedOrRunningMaintenance && enableCondition];
	}
	BOOL asynchronous_mode_flag = NO;
	switch([model operationMode]){
		case kOperationRingBufferAsync:
			[memoryTriggerDelayField	setEnabled:NO];
			[memoryStartModeLengthField setEnabled:NO];
			[memoryWrapLengthField		setEnabled:NO];
			[gateSyncExtendLengthField  setEnabled:NO];
			[gateSyncLimitLengthField   setEnabled:NO];
			[thresholdOffMatrix			setEnabled:NO];
			[ringBufferLenField			setEnabled:!lockedOrRunningMaintenance];
			[ringBufferPreDelayField	setEnabled:!lockedOrRunningMaintenance];
			[endAddressThresholdField	setEnabled:!lockedOrRunningMaintenance];
			asynchronous_mode_flag = YES ;
			break;
			
		case kOperationRingBufferSync:
			[memoryTriggerDelayField	setEnabled:NO];
			[memoryStartModeLengthField setEnabled:NO];
			[memoryWrapLengthField		setEnabled:NO];
			[gateSyncExtendLengthField  setEnabled:NO];
			[gateSyncLimitLengthField   setEnabled:NO];			
			[thresholdOffMatrix			setEnabled:NO];
			[ringBufferLenField			setEnabled:!lockedOrRunningMaintenance];
			[ringBufferPreDelayField	setEnabled:!lockedOrRunningMaintenance];
			[endAddressThresholdField	setEnabled:NO];
			asynchronous_mode_flag = NO ;
			break;
			
		case kOperationDirectMemoryGateAsync:
			[memoryTriggerDelayField	setEnabled:NO];
			[memoryStartModeLengthField setEnabled:NO];
			[memoryWrapLengthField		setEnabled:NO];
			[gateSyncExtendLengthField  setEnabled:NO];
			[gateSyncLimitLengthField   setEnabled:NO];			
			[ringBufferLenField			setEnabled:!lockedOrRunningMaintenance];
			[ringBufferPreDelayField	setEnabled:!lockedOrRunningMaintenance];
			[thresholdOffMatrix			setEnabled:!lockedOrRunningMaintenance];
			[endAddressThresholdField	setEnabled:!lockedOrRunningMaintenance];
			asynchronous_mode_flag = YES ;
			break;
			
		case kOperationDirectMemoryGateSync:
			[memoryTriggerDelayField	setEnabled:NO];
			[memoryStartModeLengthField setEnabled:NO];
			[memoryWrapLengthField		setEnabled:NO];
			[gateSyncExtendLengthField  setEnabled:!lockedOrRunningMaintenance];
			[gateSyncLimitLengthField   setEnabled:!lockedOrRunningMaintenance];			
			[thresholdOffMatrix			setEnabled:!lockedOrRunningMaintenance];
			[ringBufferLenField			setEnabled:NO];
			[ringBufferPreDelayField	setEnabled:!lockedOrRunningMaintenance];
			[endAddressThresholdField	setEnabled:!lockedOrRunningMaintenance];
			asynchronous_mode_flag = NO;
			break;
			
		case kOperationDirectMemoryStop:
			[memoryTriggerDelayField	setEnabled:!lockedOrRunningMaintenance];
			[memoryStartModeLengthField setEnabled:NO];
			[memoryWrapLengthField		setEnabled:!lockedOrRunningMaintenance];
			[gateSyncExtendLengthField  setEnabled:NO];
			[gateSyncLimitLengthField   setEnabled:NO];			
			[ringBufferLenField			setEnabled:NO];
			[ringBufferPreDelayField	setEnabled:!lockedOrRunningMaintenance];
			[thresholdOffMatrix			setEnabled:NO];
			[endAddressThresholdField	setEnabled:!lockedOrRunningMaintenance];
			asynchronous_mode_flag = NO;
			break;
			
		case kOperationDirectMemoryStart:
			[memoryTriggerDelayField	setEnabled:!lockedOrRunningMaintenance];
			[memoryStartModeLengthField setEnabled:!lockedOrRunningMaintenance];
			[memoryWrapLengthField		setEnabled:NO];
			[gateSyncExtendLengthField  setEnabled:NO];
			[gateSyncLimitLengthField   setEnabled:NO];			
			[ringBufferLenField			setEnabled:NO];
			[ringBufferPreDelayField	setEnabled:!lockedOrRunningMaintenance];
			[thresholdOffMatrix			setEnabled:NO];
			[endAddressThresholdField	setEnabled:!lockedOrRunningMaintenance];
			asynchronous_mode_flag = NO;
			break;
	}
	
	switch([model operationMode]){
		case kOperationRingBufferAsync:  
		case kOperationRingBufferSync:
		case kOperationDirectMemoryStop:
		case kOperationDirectMemoryStart:
			[thresholdOnLabel  setStringValue:@"       Threshold"];
			[thresholdOffLabel setStringValue:@"                 N/A"];
		break;
			
		case kOperationDirectMemoryGateAsync:
		case kOperationDirectMemoryGateSync:
			[thresholdOnLabel  setStringValue:@" ON  Threshold"];
			[thresholdOffLabel setStringValue:@"OFF Threshold"];
			break;
	}
		
	if (asynchronous_mode_flag == 0) {
		[triggerMaskMatrix setEnabled:!lockedOrRunningMaintenance];
		[invertLemoCB setEnabled:!lockedOrRunningMaintenance];
		[multiEventCB setEnabled:!lockedOrRunningMaintenance];
		[maxNumEventsField setEnabled:!lockedOrRunningMaintenance && [model multiEvent]];
	}
	else {
		[triggerMaskMatrix setEnabled:NO];
		[invertLemoCB setEnabled:NO];
		[multiEventCB setEnabled:NO];
		[maxNumEventsField setEnabled:NO];
	}
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3350 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3350 Card (Slot %d)",[model slot]]];
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

- (IBAction) memoryWrapLengthAction:(id)sender
{
	[model setMemoryWrapLength:[sender intValue]];	
}

- (IBAction) readTemperatureAction:(id)sender
{
	@try {
		[model readTemperature:YES];
	}
	@catch (NSException* localException) {
		NSLog(@"Read SIS3350 board temperature failed\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3350 Temperature read FAILED", @"OK", nil, nil,
                        localException);
	}
	
}

- (IBAction) fire:(id)sender
{
	[model fireTrigger];	
}

- (IBAction) endAddressThresholdAction:(id)sender
{
	[model setEndAddressThreshold:[sender intValue]];	
}

- (IBAction) ringBufferPreDelayAction:(id)sender
{
	[model setRingBufferPreDelay:[sender intValue]];	
}

- (IBAction) ringBufferLenAction:(id)sender
{
	[model setRingBufferLen:[sender intValue]];	
}

- (IBAction) gateSyncExtendLengthAction:(id)sender
{
	[model setGateSyncExtendLength:[sender intValue]];	
}

- (IBAction) gateSyncLimitLengthAction:(id)sender
{
	[model setGateSyncLimitLength:[sender intValue]];	
}

- (IBAction) maxNumEventsAction:(id)sender
{
	[model setMaxNumEvents:[sender intValue]];	
}

- (IBAction) freqNAction:(id)sender
{
	[model setFreqN:(int)[sender indexOfSelectedItem]];
}

- (IBAction) freqMAction:(id)sender
{
	[model setFreqM:[sender intValue]];	
}

- (IBAction) memoryStartModeLengthAction:(id)sender
{
	[model setMemoryStartModeLength:[sender intValue]];	
}

- (IBAction) memoryTriggerDelayAction:(id)sender
{
	[model setMemoryTriggerDelay:[sender intValue]];	
}

- (IBAction) invertLemoAction:(id)sender
{
	[model setInvertLemo:[sender intValue]];	
}

- (IBAction) multiEventAction:(id)sender
{
	[model setMultiEvent:[sender intValue]];	
}

- (IBAction) triggerMaskAction:(id)sender
{
	int aMask = 0;
	int i;
	for(i=0;i<3;i++){
		if([[triggerMaskMatrix cellWithTag:i] intValue])aMask |= (1<<i);
	}
	[model setTriggerMask:aMask];	
}

- (IBAction) clockSourceAction:(id)sender
{
	[model setClockSource:(int)[sender indexOfSelectedItem]];
}

- (IBAction) operationModeAction:(id)sender
{
	[model setOperationMode:(int)[sender indexOfSelectedItem]];
}

//hardware actions
- (IBAction) probeBoardAction:(id)sender;
{
	@try {
		[model readModuleID:YES];
	}
	@catch (NSException* localException) {
		NSLog(@"Probe of SIS3350 board ID failed\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3350 Probe FAILED", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) report:(id)sender;
{
	@try {
		[model printReport];
	}
	@catch (NSException* localException) {
		NSLog(@"Read for Report of SIS3350 board ID failed\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3350 Report FAILED", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) triggerModeAction:(id)sender
{
	[model setTriggerMode:[sender tag] withValue:(uint32_t)[sender indexOfSelectedItem]];
}

- (IBAction) gainAction:(id)sender
{
    if([sender intValue] != [model gain:(int)[[sender selectedCell] tag]]){
		[model setGain:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) dacValueAction:(id)sender
{
    if([sender intValue] != [model dacValue:(int)[[sender selectedCell] tag]]){
		[model setDacValue:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}


- (IBAction) thresholdAction:(id)sender
{
    if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) thresholdOffAction:(id)sender
{
    if([sender intValue] != [model thresholdOff:[[sender selectedCell] tag]]){
		[model setThresholdOff:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}


- (IBAction) trigPulseLenAction:(id)sender
{
    if([sender intValue] != [model trigPulseLen:[[sender selectedCell] tag]]){
		[model setTrigPulseLen:[[sender selectedCell] tag] withValue:[sender intValue]];
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

-(IBAction) baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORSIS3350SettingsLock to:[sender intValue] forWindow:[self window]];
}


-(IBAction) initBoard:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];		//initialize and load hardward
        NSLog(@"Initialized SIS3350 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset and Init of SIS3350 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3350 Reset and Init", @"OK", nil, nil,
                        localException);
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

    NSString* key = [NSString stringWithFormat: @"orca.ORSIS3350%d.selectedtab",[model slot]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
}

- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model waveFormRateGroup]integrationTime]){
        [model setRateIntegrationTime:[sender doubleValue]];		
    }
}


#pragma mark •••Data Source
- (double) getBarValue:(int)tag
{
	return [[[[model waveFormRateGroup]rates] objectAtIndex:tag] rate];
}

- (int) numberPointsInPlot:(id)aPlotter;
{
	return (int)[[[model waveFormRateGroup]timeRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
	int count = (int)[[[model waveFormRateGroup]timeRate] count];
	int index = count-i-1;
	*yValue =  [[[model waveFormRateGroup]timeRate]valueAtIndex:index];
	*xValue =  [[[model waveFormRateGroup]timeRate]timeSampledAtIndex:index];
}

@end
