/*
 *  ORJADCLModelController.cpp
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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


#pragma mark ¥¥¥Imported Files
#import "ORJADCLController.h"
#import "ORCamacExceptions.h"
#import "ORPlotView.h"
#import "ORTimeLinePlot.h"
#import "ORTimeAxis.h"
#import "ORCompositePlotView.h"
#import "ORTimeRate.h"

// methods
@implementation ORJADCLController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"JADCL"];
	
    return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
    [[plotter0 yAxis] setRngLow:0.0 withHigh:12.];
	[[plotter0 yAxis] setRngLimitsLow:0.0 withHigh:12 withMinRng:4];
    [[plotter1 yAxis] setRngLow:0.0 withHigh:12.];
	[[plotter1 yAxis] setRngLimitsLow:0.0 withHigh:12 withMinRng:4];
    [[plotter2 yAxis] setRngLow:0.0 withHigh:12.];
	[[plotter2 yAxis] setRngLimitsLow:0.0 withHigh:12 withMinRng:4];
    [[plotter3 yAxis] setRngLow:0.0 withHigh:12.];
	[[plotter3 yAxis] setRngLimitsLow:0.0 withHigh:12 withMinRng:4];
	
	
    [[plotter0 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter0 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[plotter1 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter1 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[plotter2 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter2 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];
    [[plotter3 xAxis] setRngLow:0.0 withHigh:10000];
	[[plotter3 xAxis] setRngLimitsLow:0.0 withHigh:200000. withMinRng:200];

	NSColor* theColors[4] =
	{
		[NSColor redColor],
		[NSColor greenColor],
		[NSColor blueColor],
		[NSColor yellowColor]	
	};	
	
	int i;
	for(i=0;i<4;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i andDataSource:self];
		[aPlot setLineColor:theColors[i]];
		[plotter0 addPlot: aPlot];
		[aPlot setName:[NSString stringWithFormat:@"chan %d",i]];
		[(ORTimeAxis*)[plotter0 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
	for(i=0;i<4;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i+4 andDataSource:self];
		[aPlot setLineColor:theColors[i]];
		[plotter1 addPlot: aPlot];
		[aPlot setName:[NSString stringWithFormat:@"chan %d",i+4]];
		[(ORTimeAxis*)[plotter1 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
	
	for(i=0;i<4;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i+8 andDataSource:self];
		[aPlot setLineColor:theColors[i]];
		[plotter2 addPlot: aPlot];
		[aPlot setName:[NSString stringWithFormat:@"chan %d",i+8]];
		[(ORTimeAxis*)[plotter2 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}
	for(i=0;i<4;i++){
		ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:i+12 andDataSource:self];
		[aPlot setLineColor:theColors[i]];
		[plotter3 addPlot: aPlot];
		[aPlot setName:[NSString stringWithFormat:@"chan %d",i+12]];
		[(ORTimeAxis*)[plotter3 xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
		[aPlot release];
	}

	[plotter0 setShowLegend:YES];
	[plotter1 setShowLegend:YES];
	[plotter2 setShowLegend:YES];
	[plotter3 setShowLegend:YES];
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORCamacCardSlotChangedNotification
                       object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORJADCLSettingsLock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledMaskChanged:)
                         name : ORJADCLModelEnabledMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(alarmsEnabledMaskChanged:)
                         name : ORJADCLModelAlarmsEnabledMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(lowLimitChanged:)
                         name : ORJADCLModelLowLimitChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(highLimitChanged:)
                         name : ORJADCLModelHighLimitChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(adcValueChanged:)
                         name : ORJADCLModelAdcValueChanged
						object: model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(rangeIndexChanged:)
                         name : ORJADCLModelRangeIndexChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(lastReadChanged:)
                         name : ORJADCLModelLastReadChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollingStateChanged:)
                         name : ORJADCLModelPollingStateChanged
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(updateTimePlot:)
						 name : ORRateAverageChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
	
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self enabledMaskChanged:nil];
	[self alarmsEnabledMaskChanged:nil];
	[self highLimitChanged:nil];
	[self lowLimitChanged:nil];
	[self adcValueChanged:nil];
	[self rangeIndexChanged:nil];
	[self lastReadChanged:nil];
	[self pollingStateChanged:nil];
	[self updateTimePlot:nil];
    [self miscAttributesChanged:nil];
}

- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [plotter0 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 xAxis]attributes] forKey:@"XAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter0 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter0 yAxis]attributes] forKey:@"YAttributes0"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter1 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter1 xAxis]attributes] forKey:@"XAttributes1"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter1 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter1 yAxis]attributes] forKey:@"YAttributes1"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter2 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter2 xAxis]attributes] forKey:@"XAttributes2"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter2 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter2 yAxis]attributes] forKey:@"YAttributes2"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter3 xAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter3 xAxis]attributes] forKey:@"XAttributes3"];
	};
	
	if(aNotification == nil || [aNotification object] == [plotter3 yAxis]){
		[model setMiscAttributes:[(ORAxis*)[plotter3 yAxis]attributes] forKey:@"YAttributes3"];
	};
	
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
	
	NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
	NSMutableDictionary* attrib = [model miscAttributesForKey:key];
	
	if(aNote == nil || [key isEqualToString:@"XAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 xAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes0"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes0"];
		if(attrib){
			[(ORAxis*)[plotter0 yAxis] setAttributes:attrib];
			[plotter0 setNeedsDisplay:YES];
			[[plotter0 yAxis] setNeedsDisplay:YES];
		}
	}
	
	if(aNote == nil || [key isEqualToString:@"XAttributes1"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes1"];
		if(attrib){
			[(ORAxis*)[plotter1 xAxis] setAttributes:attrib];
			[plotter1 setNeedsDisplay:YES];
			[[plotter1 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes1"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes1"];
		if(attrib){
			[(ORAxis*)[plotter1 yAxis] setAttributes:attrib];
			[plotter1 setNeedsDisplay:YES];
			[[plotter1 yAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"XAttributes2"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes2"];
		if(attrib){
			[(ORAxis*)[plotter2 xAxis] setAttributes:attrib];
			[plotter2 setNeedsDisplay:YES];
			[[plotter2 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes2"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes2"];
		if(attrib){
			[(ORAxis*)[plotter2 yAxis] setAttributes:attrib];
			[plotter2 setNeedsDisplay:YES];
			[[plotter2 yAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"XAttributes3"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"XAttributes3"];
		if(attrib){
			[(ORAxis*)[plotter3 xAxis] setAttributes:attrib];
			[plotter3 setNeedsDisplay:YES];
			[[plotter3 xAxis] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"YAttributes3"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"YAttributes3"];
		if(attrib){
			[(ORAxis*)[plotter3 yAxis] setAttributes:attrib];
			[plotter3 setNeedsDisplay:YES];
			[[plotter3 yAxis] setNeedsDisplay:YES];
		}
	}
}

- (void) updateTimePlot:(NSNotification*)aNote
{
	if(!aNote || ([aNote object] == [model timeRate:0])){
		[plotter0 setNeedsDisplay:YES];
	}
	else if(!aNote || ([aNote object] == [model timeRate:1])){
		[plotter1 setNeedsDisplay:YES];
	}
	else if(!aNote || ([aNote object] == [model timeRate:2])){
		[plotter2 setNeedsDisplay:YES];
	}
	else if(!aNote || ([aNote object] == [model timeRate:3])){
		[plotter3 setNeedsDisplay:YES];
	}
	
}

- (void) pollingStateChanged:(NSNotification*)aNote
{
	[pollingStatePopup selectItemWithTag: [model pollingState]];
}

- (void) lastReadChanged:(NSNotification*)aNote
{
	[lastReadTextField setStringValue: [model lastRead]];
}

- (void) rangeIndexChanged:(NSNotification*)aNote
{
	[rangeIndexPopup selectItemAtIndex: [model rangeIndex]];
}

- (void) lowLimitChanged:(NSNotification*)aNote
{
	if(aNote == nil){
		int i;
		for(i=0;i<16;i++)[[lowLimitsMatrix cellWithTag:i] setFloatValue: [model lowLimit:i]];
		
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:ORJADCLChan] intValue];
		[[lowLimitsMatrix cellWithTag:chan] setFloatValue: [model lowLimit:chan]];
	}
}

- (void) highLimitChanged:(NSNotification*)aNote
{
	if(aNote == nil){
		int i;
		for(i=0;i<16;i++)[[highLimitsMatrix cellWithTag:i] setFloatValue: [model highLimit:i]];
		
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:ORJADCLChan] intValue];
		[[highLimitsMatrix cellWithTag:chan] setFloatValue: [model highLimit:chan]];
	}
}

- (void) adcValueChanged:(NSNotification*)aNote
{
	if(aNote == nil){
		int i;
		for(i=0;i<16;i++){
			[[adcValueMatrix cellWithTag:i] setFloatValue: [model adcValue:i]];
			[[adcValueMatrix cellWithTag:i] setTextColor:[NSColor blackColor]];
		}
		
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:ORJADCLChan] intValue];
		[[adcValueMatrix cellWithTag:chan] setFloatValue: [model adcValue:chan]];
		int range = [model adcRange:chan];
		NSColor* theColor = [NSColor blackColor];
		if(range == kAdcLRangeLow || range == kAdcLRangeHigh)theColor = [NSColor colorWithCalibratedRed:.5 green:0 blue:0 alpha:1];
		[[adcValueMatrix cellWithTag:chan] setTextColor:theColor];
	}
}

- (void) enabledMaskChanged:(NSNotification*)aNote
{
	unsigned short theMask = [model enabledMask];
	int i;
	for(i=0;i<16;i++){
		[[enabledMaskMatrix cellWithTag:i] setState: (theMask & (1<<i))!=0];
	}
}
- (void) alarmsEnabledMaskChanged:(NSNotification*)aNote
{
	unsigned short theMask = [model alarmsEnabledMask];
	int i;
	for(i=0;i<16;i++){
		[[alarmsEnabledMaskMatrix cellWithTag:i] setState: (theMask & (1<<i))!=0];
	}
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORJADCLSettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORJADCLSettingsLock];
    BOOL locked = [gSecurity isLocked:ORJADCLSettingsLock];
	
    [settingLockButton setState: locked];
	[lowLimitsMatrix setEnabled:!lockedOrRunningMaintenance];
	[highLimitsMatrix setEnabled:!lockedOrRunningMaintenance];
	[enabledMaskMatrix setEnabled:!lockedOrRunningMaintenance];
	[alarmsEnabledMaskMatrix setEnabled:!lockedOrRunningMaintenance];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORJADCLSettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
	
}


- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"JADCL (Station %d)",(int)[model stationNumber]]];
}

#pragma mark ¥¥¥Actions

- (void) pollingStatePopupAction:(id)sender
{
	[model setPollingState:(int)[[(NSPopUpButton*) sender selectedItem] tag]];	//tag is set to seconds
}

- (void) rangeIndexPopupAction:(id)sender
{
	[model setRangeIndex:(int)[(NSPopUpButton*)sender indexOfSelectedItem]];
}

- (void) enabledMaskMatrixAction:(id)sender
{
	unsigned short theMask = [model enabledMask];
	int tag = (int)[[sender selectedCell] tag];
	if(![sender intValue]) theMask &= ~(1<<tag);
	else theMask |= (1<<tag);
	[model setEnabledMask:theMask];	
}

- (void) alarmsEnabledMaskMatrixAction:(id)sender
{
	unsigned short theMask = [model alarmsEnabledMask];
	int tag = (int)[[sender selectedCell] tag];
	if(![sender intValue]) theMask &= ~(1<<tag);
	else theMask |= (1<<tag);
	[model setAlarmsEnabledMask:theMask];	
}

-(IBAction) lowLimitsMatrixAction:(id)sender
{
	if([sender floatValue] != [model lowLimit:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set LowLimit"];
		[model setLowLimit:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}

-(IBAction) highLimitsMatrixAction:(id)sender
{
	if([sender floatValue] != [model highLimit:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set HighLimit"];
		[model setHighLimit:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORJADCLSettingsLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) readLimitsAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model readLimits];
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Read Limits" fCode:4];
    }
}

- (IBAction) initAction:(id)sender
{
    @try {
		[self endEditing];
        [model checkCratePower];
        [model initBoard];
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"InitBoard"];
    }
}

- (IBAction) readAdcsAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model readAdcs:YES];
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Read Adcs"];
    }
}

- (void) showError:(NSException*)anException name:(NSString*)name fCode:(int)i
{
    NSLog(@"Failed Cmd: %@ (F%d)\n",name,i);
    if([[anException name] isEqualToString: OExceptionNoCamacCratePower]) {
        [[model crate]  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@ (F%d)",name,i]];
    }
    else {
        ORRunAlertPanel([anException name], @"%@\n%@ (F%d)", @"OK", nil, nil,
                        [anException name],name,i);
    }
}

- (void) showError:(NSException*)anException name:(NSString*)name
{
    NSLog(@"Failed Cmd: %@\n",name);
    if([[anException name] isEqualToString: OExceptionNoCamacCratePower]) {
        [[model crate]  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@",name]];
    }
    else {
        ORRunAlertPanel([anException name], @"%@\n%@", @"OK", nil, nil,
                        [anException name],name);
    }
}


#pragma mark ¥¥¥Data Source
- (int) numberPointsInPlot:(id)aPlotter
{
	int set = (int)[aPlotter tag];
	return (int)[[model timeRate:set] count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
	int set = (int)[aPlotter tag];
	int count = (int)[[model timeRate:set] count];
	int index = count-i-1;
	*yValue = [[model timeRate:set] valueAtIndex:index];
	*xValue = [[model timeRate:set] timeSampledAtIndex:index];
}

@end



