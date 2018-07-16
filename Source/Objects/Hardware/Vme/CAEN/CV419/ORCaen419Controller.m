//
//  ORCaen419Controller.m
//  Orca
//
//  Created by Mark Howe on 2/20/09
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nug Physics and 
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
#import "ORCaen419Controller.h"
#import "ORCaenDataDecoder.h"
#import "ORCaen419Model.h"
#import "ORRate.h"
#import "ORRateGroup.h"
#import "ORValueBar.h"
#import "ORTimeRate.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"

@implementation ORCaen419Controller
#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"Caen419" ];
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    NSString* key = [NSString stringWithFormat: @"orca.ORCaen419_%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	[[rate0 xAxis] setRngLimitsLow:0 withHigh:500000 withMinRng:128];
	[[totalRate xAxis] setRngLimitsLow:0 withHigh:500000 withMinRng:128];

	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
	
}

#pragma mark •••Notfications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
	
    [notifyCenter addObserver:self
					 selector:@selector(baseAddressChanged:)
						 name:ORVmeIOCardBaseAddressChangedNotification
					   object:model];
		
    [notifyCenter addObserver:self
					 selector:@selector(lowThresholdChanged:)
						 name:ORCaen419LowThresholdChanged
					   object:model];

	[notifyCenter addObserver:self
					 selector:@selector(highThresholdChanged:)
						 name:ORCaen419HighThresholdChanged
					   object:model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(basicLockChanged:)
                         name : ORCaen419BasicLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(basicLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(auxAddressChanged:)
                         name : ORCaen419ModelAuxAddressChanged
						object: model];
    [notifyCenter addObserver : self
                     selector : @selector(linearGateModeChanged:)
                         name : ORCaen419ModelLinearGateModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(riseTimeProtectionChanged:)
                         name : ORCaen419ModelRiseTimeProtectionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(resetMaskChanged:)
                         name : ORCaen419ModelResetMaskChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enabledMaskChanged:)
                         name : ORCaen419ModelEnabledMaskChanged
						object: model];

	
	[notifyCenter addObserver : self
					 selector : @selector(integrationChanged:)
						 name : ORRateGroupIntegrationChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(rateGroupChanged:)
						 name : ORCaen419RateGroupChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];
	
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
					   object : [[model adcRateGroup]timeRate]];
	
    [self registerRates];
}

- (void) registerRates
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	[notifyCenter removeObserver:self name:ORRateChangedNotification object:nil];
	
	NSEnumerator* e = [[[model adcRateGroup] rates] objectEnumerator];
	id obj;
	while(obj = [e nextObject]){
		[notifyCenter addObserver : self
						 selector : @selector(adcRateChanged:)
							 name : ORRateChangedNotification
						   object : obj];
	}
}

- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
	[self auxAddressChanged:nil];
 	[self linearGateModeChanged:nil];
	[self riseTimeProtectionChanged:nil];
	[self resetMaskChanged:nil];
	[self enabledMaskChanged:nil];
	[self slotChanged:nil];
    [self adcRateChanged:nil];
    [self totalRateChanged:nil];
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self updateTimePlot:nil];
	
    short 	i;
    for (i = 0; i < [model numberOfChannels]; i++){
        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
        [userInfo setObject:[NSNumber numberWithInt:i] forKey:@"channel"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen419LowThresholdChanged object:model userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen419HighThresholdChanged object:model userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen419ModelRiseTimeProtectionChanged object:model userInfo:userInfo];
	}
	
    [self basicLockChanged:nil];
}

#pragma mark ***Interface Management
- (void) enabledMaskChanged:(NSNotification*)aNote
{
	short aMask = [model enabledMask];
	int i;
	for(i=0;i<kCV419NumberChannels;i++){
		[[enabledMaskMatrix cellWithTag:i] setIntValue:aMask&(1<<i)];
	}
}

- (void) resetMaskChanged:(NSNotification*)aNote
{
	short aMask = [model resetMask];
	int i;
	for(i=0;i<kCV419NumberChannels;i++){
		[[resetMaskMatrix cellWithTag:i] setIntValue:aMask&(1<<i)];
	}
}

- (void) riseTimeProtectionChanged:(NSNotification*)aNote
{
	int chnl = [[[aNote userInfo] objectForKey:@"channel"] intValue];
	int microSec = 2*([model riseTimeProtection:chnl] +1);
	[[riseTimeProtectionMatrix cellWithTag:chnl] setIntValue: microSec];
}

- (void) lowThresholdChanged:(NSNotification*) aNote
{
	int chnl = [[[aNote userInfo] objectForKey:@"channel"] intValue];
	[[lowThresholdMatrix cellWithTag:chnl] setIntegerValue:[model lowThreshold:chnl]];
}

- (void) highThresholdChanged:(NSNotification*) aNote
{
	int chnl = [[[aNote userInfo] objectForKey:@"channel"] intValue];
	[[highThresholdMatrix cellWithTag:chnl] setIntegerValue:[model highThreshold:chnl]];
}

- (void) linearGateModeChanged:(NSNotification*)aNote
{
	[linearGateMode0PU selectItemAtIndex: [model linearGateMode:0]];
	[linearGateMode1PU selectItemAtIndex: [model linearGateMode:1]];
	[linearGateMode2PU selectItemAtIndex: [model linearGateMode:2]];
	[linearGateMode3PU selectItemAtIndex: [model linearGateMode:3]];
}

- (void) auxAddressChanged:(NSNotification*)aNote
{
	[auxAddressField setIntegerValue: [model auxAddress]];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORCaen419BasicLock to:secure];
    [basicLockButton setEnabled:secure];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
	[baseAddressField setIntegerValue: [model baseAddress]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	if(aModel)[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) basicLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORCaen419BasicLock];
    BOOL locked = [gSecurity isLocked:ORCaen419BasicLock];
    [basicLockButton setState: locked];
    
    [baseAddressField setEnabled:!locked && !runInProgress];
    [auxAddressField setEnabled:!locked && !runInProgress];
    [enabledMaskMatrix setEnabled:!lockedOrRunningMaintenance];
    [resetMaskMatrix setEnabled:!lockedOrRunningMaintenance];
    [riseTimeProtectionMatrix setEnabled:!lockedOrRunningMaintenance];
    [linearGateMode0PU setEnabled:!lockedOrRunningMaintenance];
    [linearGateMode1PU setEnabled:!lockedOrRunningMaintenance];
    [linearGateMode2PU setEnabled:!lockedOrRunningMaintenance];
    [linearGateMode3PU setEnabled:!lockedOrRunningMaintenance];
    [lowThresholdMatrix setEnabled:!lockedOrRunningMaintenance];
    [highThresholdMatrix setEnabled:!lockedOrRunningMaintenance];
    [readThresholdsButton setEnabled:!lockedOrRunningMaintenance];
    [writeThresholdsButton setEnabled:!lockedOrRunningMaintenance];
    [initButton setEnabled:!lockedOrRunningMaintenance];
    [fireButton setEnabled:!lockedOrRunningMaintenance];
	[resetButton setEnabled:!lockedOrRunningMaintenance];
    [online2MaskMatrix setEnabled:!lockedOrRunningMaintenance];
	    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORCaen419BasicLock])s = @"Not in Maintenance Run.";
    }
    [basicLockDocField setStringValue:s];
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    NSString* key = [NSString stringWithFormat: @"orca.ORCaen419_%d.selectedtab",[model slot]];
    NSInteger index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}
- (void) adcRateChanged:(NSNotification*)aNotification
{
	ORRate* theRateObj = [aNotification object];		
	[[rateTextFields cellWithTag:[theRateObj tag]] setFloatValue: [theRateObj rate]];
	[rate0 setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)aNotification
{
	ORRateGroup* theRateObj = [aNotification object];
	if(aNotification == nil || [model adcRateGroup] == theRateObj){
		
		[totalRateText setFloatValue: [theRateObj totalRate]];
		[totalRate setNeedsDisplay:YES];
	}
}

- (void) rateGroupChanged:(NSNotification*)aNotification
{
	[self registerRates];
}

- (void) integrationChanged:(NSNotification*)aNotification
{
	ORRateGroup* theRateGroup = [aNotification object];
	if(aNotification == nil || [model adcRateGroup] == theRateGroup || [aNotification object] == model){
		double dValue = [[model adcRateGroup] integrationTime];
		[integrationStepper setDoubleValue:dValue];
		[integrationText setDoubleValue: dValue];
	}
}

- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [[model adcRateGroup]timeRate])){
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

#pragma mark •••Actions
- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
	if([sender doubleValue] != [[model adcRateGroup]integrationTime]){
		[[self undoManager] setActionName: @"Set Integration Time"];
		[model setIntegrationTime:[sender doubleValue]];		
	}
	
}

- (void) enabledMaskAction:(id)sender
{
	short aMask = 0;
	int i;
	for(i=0;i<kCV419NumberChannels;i++){
		if([[enabledMaskMatrix cellWithTag:i] intValue]){
			aMask |= (1<<i);
		}
	}
	[model setEnabledMask:aMask];	
}

- (void) resetMaskAction:(id)sender
{
	short aMask = 0;
	int i;
	for(i=0;i<kCV419NumberChannels;i++){
		if([[resetMaskMatrix cellWithTag:i] intValue]){
			aMask |= (1<<i);
		}
	}
	[model setResetMask:aMask];	
}

- (void) riseTimeProtectionAction:(id)sender
{
    if ([sender intValue] != [model riseTimeProtection:[[sender selectedCell] tag]]){
		int rawValue = [sender intValue]/2 - 1;
        [model setRiseTimeProtection:[[sender selectedCell] tag] withValue:rawValue]; 
    }
}

- (void) linearGateModeAction:(id)sender
{
	[model setLinearGateMode:[sender tag] withValue:[sender indexOfSelectedItem]];	
}

- (void) auxAddressAction:(id)sender
{
	[model setAuxAddress:[sender intValue]];	
}

- (IBAction) baseAddressAction:(id) sender
{
    if ([sender intValue] != [model baseAddress]){
		[model setBaseAddress:[sender intValue]]; 
    }
} 

- (IBAction) lowThresholdAction:(id) sender
{
    if ([sender intValue] != [model lowThreshold:[[sender selectedCell] tag]]){
        [model setLowThreshold:[[sender selectedCell] tag] withValue:[sender intValue]]; 
    }
}

- (IBAction) highThresholdAction:(id) sender
{
    if ([sender intValue] != [model highThreshold:[[sender selectedCell] tag]]){
        [model setHighThreshold:[[sender selectedCell] tag] withValue:[sender intValue]]; 
    }
}

- (IBAction) readThresholds:(id) sender
{
	@try {
		[self endEditing];
		[model readThresholds];
		[model logThresholds];
    }
	@catch(NSException* localException) {
        NSLog(@"Read of %@ thresholds FAILED.\n",[model identifier]);
        ORRunAlertPanel([localException name], @"%@\nFailed Reading Thresholds", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) initBoard:(id) sender
{
	@try {
		[self endEditing];
		[model initBoard];
    }
	@catch(NSException* localException) {
        NSLog(@"Init of %@  FAILED.\n",[model identifier]);
        ORRunAlertPanel([localException name], @"%@\nFailed Init", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) basicLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORCaen419BasicLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) writeThresholds:(id) pSender
{
	@try {
		[self endEditing];
		[model writeThresholds];
    }
	@catch(NSException* localException) {
        NSLog(@"Write of %@ thresholds FAILED.\n",[model identifier]);
        ORRunAlertPanel([localException name], @"%@\nFailed Writing Thresholds", @"OK", nil, nil,
                        localException);
    }
}
- (IBAction) fire:(id) pSender
{
	@try {
		[self endEditing];
		[model fire];
    }
	@catch(NSException* localException) {
        NSLog(@"Software trigger of %@  FAILED.\n",[model identifier]);
        ORRunAlertPanel([localException name], @"%@\nFailed Software Trigger", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) reset:(id) pSender
{
	@try {
		[self endEditing];
		[model reset];
    }
	@catch(NSException* localException) {
        NSLog(@"Reset data buffer of %@  FAILED.\n",[model identifier]);
        ORRunAlertPanel([localException name], @"%@\nFailed data buffer reset", @"OK", nil, nil,
                        localException);
    }
}

- (double) getBarValue:(int)tag
{
	
	return [[[[model adcRateGroup]rates] objectAtIndex:tag] rate];
}


- (int) numberPointsInPlot:(id)aPlotter
{
	return (int)[[[model adcRateGroup]timeRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
	int count = (int)[[[model adcRateGroup]timeRate] count];
	int index = count-i-1;
	*yValue =  [[[model adcRateGroup] timeRate] valueAtIndex:index];
	*xValue =  [[[model adcRateGroup] timeRate] timeSampledAtIndex:index];
}

@end
