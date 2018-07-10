//-------------------------------------------------------------------------
//  ORSIS3320Controller.h
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
#import "ORSIS3320Controller.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORValueBar.h"
#import "ORTimeRate.h"
#import "ORRate.h"
#import "OHexFormatter.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"

@implementation ORSIS3320Controller

-(id)init
{
    self = [super initWithWindowNibName:@"SIS3320"];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
	settingSize     = NSMakeSize(750,500);
    rateSize		= NSMakeSize(480,380);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
	NSString* key = [NSString stringWithFormat: @"orca.SIS3320%d.selectedtab",[model slot]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
		
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xScale] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
	
	int i;
	for(i=0;i<8;i++){
		[[gtMatrix cellAtRow:i column:0] setTag:i];
		[[ltMatrix cellAtRow:i column:0] setTag:i];
		[[thresholdMatrix cellAtRow:i column:0] setTag:i];
		[[trigPulseLenMatrix cellAtRow:i column:0] setTag:i];
		[[sumGMatrix cellAtRow:i column:0] setTag:i];
		[[peakingTimeMatrix cellAtRow:i column:0] setTag:i];
		[[dacValueMatrix cellAtRow:i column:0] setTag:i];
		
	}
	
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
                         name : ORSIS3320SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORSIS3320RateGroupChangedNotification
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
                     selector : @selector(thresholdChanged:)
                         name : ORSIS3320ModelThresholdChanged
                       object : model];
	

    [notifyCenter addObserver : self
                     selector : @selector(dacValueChanged:)
                         name : ORSIS3320ModelDacValueChanged
                       object : model];
		
    [self registerRates];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(moduleIDChanged:)
                         name : ORSIS3320ModelIDChanged
						object: model];
	

    [notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORSIS3320ModelClockSourceChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(multiEventChanged:)
                         name : ORSIS3320ModelMultiEventChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(maxNumEventsChanged:)
                         name : ORSIS3320ModelMaxNumEventsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(trigPulseLenChanged:)
                         name : ORSIS3320ModelTrigPulseLenChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(sumGChanged:)
                         name : ORSIS3320ModelSumGChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(peakingTimeChanged:)
                         name : ORSIS3320ModelPeakingTimeChanged
						object: model];
			
    [notifyCenter addObserver : self
                     selector : @selector(autoStartModeChanged:)
                         name : ORSIS3320ModelAutoStartModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(internalTriggerAsStopChanged:)
                         name : ORSIS3320ModelInternalTriggerAsStopChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lemoStartStopLogicChanged:)
                         name : ORSIS3320ModelLemoStartStopLogicChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(startDelayChanged:)
                         name : ORSIS3320ModelStartDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(stopDelayChanged:)
                         name : ORSIS3320ModelStopDelayChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pageWrapSizeChanged:)
                         name : ORSIS3320ModelPageWrapSizeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enablePageWrapChanged:)
                         name : ORSIS3320ModelEnablePageWrapChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enableSampleLenStopChanged:)
                         name : ORSIS3320ModelEnableSampleLenStopChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enableUserInDataStreamChanged:)
                         name : ORSIS3320ModelEnableUserInDataStreamChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enableUserInAccumGateChanged:)
                         name : ORSIS3320ModelEnableUserInAccumGateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sampleLengthChanged:)
                         name : ORSIS3320ModelSampleLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(sampleStartAddressChanged:)
                         name : ORSIS3320ModelSampleStartAddressChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(gtMaskChanged:)
                         name : ORSIS3320ModelGtMaskChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(ltMaskChanged:)
                         name : ORSIS3320ModelLtMaskChanged
						object: model];
		
	[notifyCenter addObserver : self
                     selector : @selector(triggerModeMaskChanged:)
                         name : ORSIS3320ModelTriggerModeMaskChanged
						object: model];	
	
}

- (void) registerRates
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter removeObserver:self name:ORRateChangedNotification object:nil];
    
    NSArray* theRates = [[model waveFormRateGroup] rates];
    for(id obj in theRates){
		
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
	[self gtMaskChanged:nil];
	[self ltMaskChanged:nil];
	[self triggerModeMaskChanged:nil];
	
	[self dacValueChanged:nil];
	[self thresholdChanged:nil];
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];
	[self moduleIDChanged:nil];
	[self clockSourceChanged:nil];
	[self multiEventChanged:nil];
	[self maxNumEventsChanged:nil];
	[self trigPulseLenChanged:nil];
	[self sumGChanged:nil];
	[self peakingTimeChanged:nil];
	[self autoStartModeChanged:nil];
	[self internalTriggerAsStopChanged:nil];
	[self lemoStartStopLogicChanged:nil];
	[self startDelayChanged:nil];
	[self stopDelayChanged:nil];
	[self pageWrapSizeChanged:nil];
	[self enablePageWrapChanged:nil];
	[self enableSampleLenStopChanged:nil];
	[self enableUserInDataStreamChanged:nil];
	[self enableUserInAccumGateChanged:nil];
	[self sampleLengthChanged:nil];
	[self sampleStartAddressChanged:nil];
}

#pragma mark •••Interface Management

- (void) sampleStartAddressChanged:(NSNotification*)aNote
{
	[sampleStartAddressField setIntValue: [model sampleStartAddress]];
}

- (void) sampleLengthChanged:(NSNotification*)aNote
{
	[sampleLengthField setIntValue: [model sampleLength]];
}

- (void) enableUserInAccumGateChanged:(NSNotification*)aNote
{
	[enableUserInAccumGateButton setIntValue: [model enableUserInAccumGate]];
}

- (void) enableUserInDataStreamChanged:(NSNotification*)aNote
{
	[enableUserInDataStreamButton setIntValue: [model enableUserInDataStream]];
}

- (void) enableSampleLenStopChanged:(NSNotification*)aNote
{
	[enableSampleLenStopButton setIntValue: [model enableSampleLenStop]];
}

- (void) enablePageWrapChanged:(NSNotification*)aNote
{
	[enablePageWrapButton setIntValue: [model enablePageWrap]];
}

- (void) pageWrapSizeChanged:(NSNotification*)aNote
{
	[pageWrapSizePU selectItemAtIndex: [model pageWrapSize]];
}

- (void) stopDelayChanged:(NSNotification*)aNote
{
	[stopDelayField setIntValue: [model stopDelay]];
}

- (void) startDelayChanged:(NSNotification*)aNote
{
	[startDelayField setIntValue: [model startDelay]];
}
- (void) multiEventChanged:(NSNotification*)aNote
{
	[multiEventCB setIntValue: [model multiEvent]];
}

- (void) autoStartModeChanged:(NSNotification*)aNote
{
	[autoStartModeButton setIntValue: [model autoStartMode]];
}

- (void) lemoStartStopLogicChanged:(NSNotification*)aNote
{
	[lemoStartStopLogicButton setIntValue: [model lemoStartStopLogic]];
}

- (void) internalTriggerAsStopChanged:(NSNotification*)aNote
{
	[internalTriggerAsStopButton setIntValue: [model internalTriggerAsStop]];
}
- (void) triggerModeMaskChanged:(NSNotification*)aNotification
{
	short i;
	unsigned long theMask = [model triggerModeMask];
	for(i=0;i<8;i++){
		[[triggerModeMatrix cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
	}
	[self  settingsLockChanged:nil];
}

- (void) gtMaskChanged:(NSNotification*)aNotification
{
	short i;
	unsigned long theMask = [model gtMask];
	for(i=0;i<8;i++){
		[[gtMatrix cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
	}
}

- (void) ltMaskChanged:(NSNotification*)aNotification
{
	short i;
	unsigned long theMask = [model ltMask];
	for(i=0;i<8;i++){
		[[ltMatrix cellWithTag:i] setIntValue:(theMask&(1<<i))!=0];
	}
}

- (void) maxNumEventsChanged:(NSNotification*)aNote
{
	[maxNumEventsField setIntValue: [model maxNumEvents]];
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
	[clockSourcePU selectItemAtIndex: [model clockSource]];
	[self settingsLockChanged:nil];
}


- (void) moduleIDChanged:(NSNotification*)aNote
{
	unsigned short moduleID = [model moduleID];
	if(moduleID) [moduleIDField setStringValue:[NSString stringWithFormat:@"%x",moduleID]];
	else		 [moduleIDField setStringValue:@"---"];
}

- (void) dacValueChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3320Channels;i++)[[dacValueMatrix cellWithTag:i] setIntValue:[model dacValue:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[dacValueMatrix cellWithTag:i] setIntValue:[model dacValue:i]];
	}
}

- (void) thresholdChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3320Channels;i++)[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
	}
	else {
		int i = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
	}
}
- (void) trigPulseLenChanged:(NSNotification*)aNote
{
	if(![aNote userInfo]){
		short i;
		for(i=0;i<kNumSIS3320Channels;i++)[[trigPulseLenMatrix cellWithTag:i] setIntValue:[model trigPulseLen:i]];
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
		for(i=0;i<kNumSIS3320Channels;i++)[[sumGMatrix cellWithTag:i] setIntValue:[model sumG:i]];
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
		for(i=0;i<kNumSIS3320Channels;i++)[[peakingTimeMatrix cellWithTag:i] setIntValue:[model peakingTime:i]];
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
    [gSecurity setLock:ORSIS3320SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSIS3320SettingsLock];
    BOOL locked = [gSecurity isLocked:ORSIS3320SettingsLock];
    
    [settingLockButton			setState: locked];
    [addressText				setEnabled:!locked && !runInProgress];
	[clockSourcePU				setEnabled:!lockedOrRunningMaintenance];
    [initButton					setEnabled:!lockedOrRunningMaintenance];
	[thresholdMatrix			setEnabled:!lockedOrRunningMaintenance];
	
	int i;
	for(i=0;i<kNumSIS3320Channels;i++){
		BOOL enableCondition = [model triggerModeMaskBit:i];
		[[sumGMatrix cellWithTag:i]				setEnabled:!lockedOrRunningMaintenance && !enableCondition];
		[[peakingTimeMatrix cellWithTag:i]		setEnabled:!lockedOrRunningMaintenance && !enableCondition];
		[[trigPulseLenMatrix	cellWithTag:i]	setEnabled:!lockedOrRunningMaintenance && !enableCondition];
	}
	
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3320 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3320 Card (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
    [addressText setIntValue: [model baseAddress]];
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


- (IBAction) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [rate0 xScale]){
		[model setMiscAttributes:[[rate0 xScale]attributes] forKey:@"RateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [totalRate xScale]){
		[model setMiscAttributes:[[totalRate xScale]attributes] forKey:@"TotalRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot xScale]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot xScale]attributes] forKey:@"TimeRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot yScale]){
		[model setMiscAttributes:[(ORAxis*)[timeRatePlot yScale]attributes] forKey:@"TimeRateYAttributes"];
	};
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"RateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"RateXAttributes"];
		if(attrib){
			[[rate0 xScale] setAttributes:attrib];
			[rate0 setNeedsDisplay:YES];
			[[rate0 xScale] setNeedsDisplay:YES];
			[rateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TotalRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TotalRateXAttributes"];
		if(attrib){
			[[totalRate xScale] setAttributes:attrib];
			[totalRate setNeedsDisplay:YES];
			[[totalRate xScale] setNeedsDisplay:YES];
			[totalRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateXAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateXAttributes"];
		if(attrib){
			[(ORAxis*)[timeRatePlot xScale] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateYAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateYAttributes"];
		if(attrib){
			[(ORAxis*)[timeRatePlot yScale] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot yScale] setNeedsDisplay:YES];
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

- (IBAction) sampleStartAddressAction:(id)sender
{
	[model setSampleStartAddress:[sender intValue]];	
}

- (IBAction) sampleLengthAction:(id)sender
{
	[model setSampleLength:[sender intValue]];	
}

//- (IBAction) shiftAccumBy4Action:(id)sender
//{
//	[model setShiftAccumBy4:[sender intValue]];	
//}

- (IBAction) enableUserInAccumGateAction:(id)sender
{
	[model setEnableUserInAccumGate:[sender intValue]];	
}

- (IBAction) enableUserInDataStreamAction:(id)sender
{
	[model setEnableUserInDataStream:[sender intValue]];	
}

//- (IBAction) enableAccumModeAction:(id)sender
//{
//	[model setEnableAccumMode:[sender intValue]];	
//}

- (IBAction) enableSampleLenStopAction:(id)sender
{
	[model setEnableSampleLenStop:[sender intValue]];	
}

- (IBAction) enablePageWrapAction:(id)sender
{
	[model setEnablePageWrap:[sender intValue]];	
}

- (IBAction) pageWrapSizeAction:(id)sender
{
	[model setPageWrapSize:[sender indexOfSelectedItem]];	
}

- (IBAction) stopDelayAction:(id)sender
{
	[model setStopDelay:[sender intValue]];	
}

- (IBAction) startDelayAction:(id)sender
{
	[model setStartDelay:[sender intValue]];	
}

- (IBAction) lemoStartStopLogicAction:(id)sender
{
	[model setLemoStartStopLogic:[sender intValue]];	
}

- (IBAction) internalTriggerAsStopAction:(id)sender
{
	[model setInternalTriggerAsStop:[sender intValue]];	
}

- (IBAction) autoStartModeAction:(id)sender
{
	[model setAutoStartMode:[sender intValue]];	
}

- (IBAction) triggerModeAction:(id)sender
{
	[model setTriggerModeMaskBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) gtAction:(id)sender
{
	[model setGtMaskBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) ltAction:(id)sender
{
	[model setLtMaskBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}


- (IBAction) maxNumEventsAction:(id)sender
{
	[model setMaxNumEvents:[sender intValue]];	
}
- (IBAction) multiEventAction:(id)sender
{
	[model setMultiEvent:[sender intValue]];	
}

- (IBAction) clockSourceAction:(id)sender
{
	[model setClockSource:[sender indexOfSelectedItem]];	
}

//hardware actions
- (IBAction) probeBoardAction:(id)sender;
{
	@try {
		[model readModuleID:YES];
	}
	@catch (NSException* localException) {
		NSLog(@"Probe of SIS3320 board ID failed\n");
        NSRunAlertPanel([localException name], @"%@\nSIS3320 Probe FAILED", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) report:(id)sender;
{
	@try {
		[model printReport];
	}
	@catch (NSException* localException) {
		NSLog(@"Read for Report of SIS3320 board ID failed\n");
        NSRunAlertPanel([localException name], @"%@\nSIS3320 Report FAILED", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) dacValueAction:(id)sender
{
    if([sender intValue] != [model dacValue:[[sender selectedCell] tag]]){
		[model setDacValue:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}


- (IBAction) thresholdAction:(id)sender
{
    if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
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
    [gSecurity tryToSetLock:ORSIS3320SettingsLock to:[sender intValue] forWindow:[self window]];
}


-(IBAction) initBoard:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];		//initialize and load hardward
        NSLog(@"Initialized SIS3320 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset and Init of SIS3320 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed SIS3320 Reset and Init", @"OK", nil, nil,
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

    NSString* key = [NSString stringWithFormat: @"orca.ORSIS3320%d.selectedtab",[model slot]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
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
	return [[[model waveFormRateGroup]timeRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
	int count = [[[model waveFormRateGroup]timeRate] count];
	int index = count-i-1;
	*yValue =  [[[model waveFormRateGroup]timeRate]valueAtIndex:index];
	*xValue =  [[[model waveFormRateGroup]timeRate]timeSampledAtIndex:index];
}

@end
