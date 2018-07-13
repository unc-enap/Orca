//-------------------------------------------------------------------------
//  ORSIS3300Controller.h
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
#import "ORSIS3300Controller.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORValueBarGroupView.h"
#import "ORPlot.h"
#import "ORPlotView.h"
#import "ORTimeLinePlot.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"
#import "ORRate.h"
#import "OHexFormatter.h"
#import "ORCompositePlotView.h"

@implementation ORSIS3300Controller

-(id)init
{
    self = [super initWithWindowNibName:@"SIS3300"];
    
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
	
    settingSize     = NSMakeSize(765,460);
    rateSize		= NSMakeSize(790,300);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
	
    NSString* key = [NSString stringWithFormat: @"orca.SIS3300%d.selectedtab",[model slot]];
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
		NSCell* theCell = [rateTextFields cellAtRow:i column:0];
		[theCell setFormatter:rateFormatter];
	}
	
	NSColor* color[8] = {
		[NSColor redColor],
		[NSColor greenColor],
		[NSColor blueColor],
		[NSColor brownColor],
		[NSColor blackColor],
		[NSColor orangeColor],
		[NSColor purpleColor],
		[NSColor cyanColor],
	};
	
	for(i=0;i<8;i++){
		ORPlot* aPlot = [[ORPlot alloc] initWithTag:i andDataSource:self];
		[aPlot setLineColor:color[i]];
		[plotter addPlot: aPlot];
		[aPlot release];
	}
	
	ORTimeLinePlot* aPlot1 = [[ORTimeLinePlot alloc] initWithTag:8 andDataSource:self];
	[timeRatePlot addPlot: aPlot1];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot1 release];
	
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
                         name : ORSIS3300SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORSIS3300RateGroupChangedNotification
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
                     selector : @selector(enabledChanged:)
                         name : ORSIS3300ModelEnabledChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ltGtChanged:)
                         name : ORSIS3300ModelLtGtChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(thresholdChanged:)
                         name : ORSIS3300ModelThresholdChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pageSizeChanged:)
                         name : ORSIS3300ModelPageSizeChanged
						object: model];
	
    [self registerRates];
    [notifyCenter addObserver : self
                     selector : @selector(stopDelayChanged:)
                         name : ORSIS3300ModelStopDelayChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORSIS3300ModelClockSourceChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(startDelayChanged:)
                         name : ORSIS3300ModelStartDelayChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(stopDelayChanged:)
                         name : ORSIS3300ModelStopDelayChanged
						object: model];
			
	
    [notifyCenter addObserver : self
                     selector : @selector(stopTriggerChanged:)
                         name : ORSIS3300ModelStopTriggerChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(eventConfigChanged:)
                         name : ORSIS3300ModelEventConfigChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(csrChanged:)
                         name : ORSIS3300ModelCSRRegChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(acqChanged:)
                         name : ORSIS3300ModelAcqRegChanged
						object: model];
		
    [notifyCenter addObserver : self
                     selector : @selector(updatePlot)
                         name : ORSIS3300ModelSampleDone
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(moduleIDChanged:)
                         name : ORSIS3300ModelIDChanged
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
	[self enabledChanged:nil];
	[self ltGtChanged:nil];
	[self thresholdChanged:nil];
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];
    [self waveFormRateChanged:nil];
	[self pageSizeChanged:nil];
	[self stopDelayChanged:nil];
	[self clockSourceChanged:nil];
	[self startDelayChanged:nil];
	[self stopDelayChanged:nil];
	[self randomClockChanged:nil];
	[self stopTriggerChanged:nil];
	
	[self eventConfigChanged:nil];
	[self csrChanged:nil];
	[self acqChanged:nil];
	[self moduleIDChanged:nil];
}

- (void) updatePlot
{
	[plotter setNeedsDisplay:YES];
}

#pragma mark •••Interface Management
- (void) csrChanged:(NSNotification*)aNote
{
	[[csrMatrix cellWithTag:0] setIntValue:[model enableTriggerOutput]];
	[[csrMatrix cellWithTag:1] setIntValue:[model invertTrigger]];
	[[csrMatrix cellWithTag:2] setIntValue:[model activateTriggerOnArmed]];
	[[csrMatrix cellWithTag:3] setIntValue:[model enableInternalRouting]];
	[[csrMatrix cellWithTag:4] setIntValue:[model bankFullTo1]];
	[[csrMatrix cellWithTag:5] setIntValue:[model bankFullTo2]];
	[[csrMatrix cellWithTag:6] setIntValue:[model bankFullTo3]];
}

- (void) acqChanged:(NSNotification*)aNote
{
	[[acqMatrix cellWithTag:0] setIntValue:[model bankSwitchMode]];
	[[acqMatrix cellWithTag:1] setIntValue:[model autoStart]];
	[[acqMatrix cellWithTag:2] setIntValue:[model multiEventMode]];
	[[acqMatrix cellWithTag:3] setIntValue:[model multiplexerMode]];
	[[acqMatrix cellWithTag:4] setIntValue:[model lemoStartStop]];
	[[acqMatrix cellWithTag:5] setIntValue:[model p2StartStop]];
	[[acqMatrix cellWithTag:6] setIntValue:[model gateMode]];
	[startDelayEnabledButton setIntValue: [model startDelayEnabled]];
	[stopDelayEnabledButton setIntValue: [model stopDelayEnabled]];
}

- (void) moduleIDChanged:(NSNotification*)aNote
{
	unsigned short moduleID = [model moduleID];
	if(moduleID) [moduleIDField setStringValue:[NSString stringWithFormat:@"%x",moduleID]];
	else		 [moduleIDField setStringValue:@"---"];
}

- (void) eventConfigChanged:(NSNotification*)aNote
{
	[[eventConfigMatrix cellWithTag:0] setIntValue:[model pageWrap]];
	[[eventConfigMatrix cellWithTag:1] setIntValue:[model gateChaining]];
}

- (void) stopTriggerChanged:(NSNotification*)aNote
{
	[stopTriggerButton setIntValue: [model stopTrigger]];
}

- (void) randomClockChanged:(NSNotification*)aNote
{
	[randomClockButton setIntValue: [model randomClock]];
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
	[clockSourcePU selectItemAtIndex: [model clockSource]];
}

- (void) startDelayChanged:(NSNotification*)aNote
{
	[startDelayField setIntValue: [model startDelay]];
}

- (void) stopDelayChanged:(NSNotification*)aNote
{
	[stopDelayField setIntValue: [model stopDelay]];
}

- (void) pageSizeChanged:(NSNotification*)aNote
{
	[pageSizePU selectItemWithTag: [model pageSize]];
}

- (void) enabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3300Channels;i++){
		[[enabledMatrix cellWithTag:i] setState:[model enabled:i]];
		[[enabled2Matrix cellWithTag:i] setState:[model enabled:i]];
	}
}

- (void) ltGtChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3300Channels;i++){
		[[ltGtMatrix cellWithTag:i] setState:[model ltGt:i]];
	}
}

- (void) thresholdChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumSIS3300Channels;i++){
		//float volts = (0.0003*[model threshold:i])-5.0;
		[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
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
    [gSecurity setLock:ORSIS3300SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSIS3300SettingsLock];
    BOOL locked = [gSecurity isLocked:ORSIS3300SettingsLock];
    
    [settingLockButton		setState: locked];
    [addressText			setEnabled:!locked && !runInProgress];
    [initButton				setEnabled:!lockedOrRunningMaintenance];
	[enabledMatrix			setEnabled:!lockedOrRunningMaintenance];
	[ltGtMatrix				setEnabled:!lockedOrRunningMaintenance];
	[thresholdMatrix		setEnabled:!lockedOrRunningMaintenance];
	[checkEventButton	    setEnabled:!locked && !runInProgress];
	[testMemoryButton	    setEnabled:!locked && !runInProgress];
	
	[csrMatrix				setEnabled:!locked && !runInProgress];
	[acqMatrix				setEnabled:!locked && !runInProgress];
	[eventConfigMatrix		setEnabled:!locked && !runInProgress];
	[stopTriggerButton		setEnabled:!lockedOrRunningMaintenance];
	[randomClockButton		setEnabled:!lockedOrRunningMaintenance];
	[startDelayEnabledButton setEnabled:!lockedOrRunningMaintenance];
	[stopDelayEnabledButton setEnabled:!lockedOrRunningMaintenance];
	[startDelayField		setEnabled:!lockedOrRunningMaintenance];
	[clockSourcePU			setEnabled:!lockedOrRunningMaintenance];
	[stopDelayField			setEnabled:!lockedOrRunningMaintenance];
	[pageSizePU				setEnabled:!locked && !runInProgress];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3300 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3300 Card (Slot %d)",[model slot]]];
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
- (IBAction) csrAction:(id)sender
{
	//tags are defined in IB, they have to match here or there will be trouble
	BOOL state = [[sender selectedCell] intValue];
	switch ([[sender selectedCell] tag]) {
		case 0: [model setEnableTriggerOutput:state];		break; 
		case 1: [model setInvertTrigger:state];				break; 
		case 2: [model setActivateTriggerOnArmed:state];	break; 
		case 3: [model setEnableInternalRouting:state];		break; 
		case 4: [model setBankFullTo1:state];				break; 
		case 5: [model setBankFullTo2:state];				break; 
		case 6: [model setBankFullTo3:state];				break; 
		default: break;
	}
}

- (IBAction) acqAction:(id)sender
{
	//tags are defined in IB, they have to match here or there will be trouble
	BOOL state = [[sender selectedCell] intValue];
	switch ([[sender selectedCell] tag]) {
		case 0: [model setBankSwitchMode:state];	break; 
		case 1: [model setAutoStart:state];			break; 
		case 2: [model setMultiEventMode:state];	break; 
		case 3: [model setMultiplexerMode:state];	break; 
		case 4: [model setLemoStartStop:state];		break; 
		case 5: [model setP2StartStop:state];		break; 
		case 6: [model setGateMode:state];			break; 
		case 7: [model setStartDelayEnabled:state];			break; 
		case 8: [model setStopDelayEnabled:state];			break; 
		default: break;
	}
}

- (IBAction) eventConfigAction:(id)sender
{
	//tags are defined in IB, they have to match here or there will be trouble
	BOOL state = [[sender selectedCell] intValue];
	switch ([[sender selectedCell] tag]) {
		case 0: [model setPageWrap:state];			break; 
		case 1: [model setGateChaining:state];		break; 
		default: break;
	}
}

//hardware actions
- (IBAction) testMemoryBankAction:(id)sender;
{
	@try {
		[model testMemory];
	}
	@catch (NSException* localException) {
		NSLog(@"Test of SIS 3300 Memory Bank failed\n");
	}
}
- (IBAction) probeBoardAction:(id)sender;
{
	@try {
		[model readModuleID:YES];
	}
	@catch (NSException* localException) {
		NSLog(@"Probe of SIS 3300 board ID failed\n");
	}
}

- (IBAction) stopTriggerAction:(id)sender
{
	[model setStopTrigger:[sender intValue]];	
}

- (IBAction) randomClockAction:(id)sender
{
	[model setRandomClock:[sender intValue]];	
}

- (IBAction) startDelayEnabledAction:(id)sender
{
	[model setStartDelayEnabled:[sender intValue]];	
}

- (IBAction) stopDelayEnabledAction:(id)sender
{
	[model setStopDelayEnabled:[sender intValue]];	
}

- (IBAction) startDelayAction:(id)sender
{
	[model setStartDelay:[sender intValue]];	
}

- (IBAction) clockSourceAction:(id)sender
{
	[model setClockSource:(int)[sender indexOfSelectedItem]];
}

- (IBAction) stopDelayAction:(id)sender
{
	[model setStopDelay:[sender intValue]];	
}

- (IBAction) pageSizeAction:(id)sender
{
	[model setPageSize:(int)[[sender selectedItem] tag]];
}

- (IBAction) enabledAction:(id)sender
{
	[model setEnabledBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) ltGtAction:(id)sender
{
	[model setLtGtBit:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) thresholdAction:(id)sender
{
	//int dacVal = ([sender floatValue]+5)/0.0003;
    if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
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
    [gSecurity tryToSetLock:ORSIS3300SettingsLock to:[sender intValue] forWindow:[self window]];
}


-(IBAction) initBoard:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];		//initialize and load hardward
        NSLog(@"Initialized SIS3300 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset and Init of SIS3300 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3300 Reset and Init", @"OK", nil, nil,
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
	
    NSString* key = [NSString stringWithFormat: @"orca.ORSIS3300%d.selectedtab",[model slot]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

- (IBAction) writeThresholdsAction:(id)sender
{
    @try {
        [self endEditing];
        [model writeThresholds:YES];
    }
	@catch(NSException* localException) {
        NSLog(@"SIS3300 Thresholds write FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3300 Write FAILED", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readThresholdsAction:(id)sender
{
    @try {
        [self endEditing];
        [model readThresholds:YES];
    }
	@catch(NSException* localException) {
        NSLog(@"SIS3300 Thresholds read FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3300 Read FAILED", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) checkEvent:(id)sender
{
	[self endEditing];
	[model testEventRead];
}

#pragma mark •••Data Source

- (double) getBarValue:(int)tag
{
	return [[[[model waveFormRateGroup]rates] objectAtIndex:tag] rate];
}

- (int) numberPointsInPlot:(id)aPlotter
{
	int set = (int)[aPlotter tag];
	if(set<8)return [model numberOfSamples];
	else return (int)[[[model waveFormRateGroup] timeRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
	int set = (int)[aPlotter tag];
	if(set<8){
		*yValue =  [model dataWord:set index:i];
		*xValue = i;
	}
	else if(set == 8){
		int count = (int)[[[model waveFormRateGroup]timeRate] count];
		int index = count-i-1;
		*yValue = [[[model waveFormRateGroup] timeRate] valueAtIndex:index];
		*xValue = [[[model waveFormRateGroup] timeRate] timeSampledAtIndex:index];
	}
	else {
		*yValue = 0;
		*xValue = 0;		
	}
}

@end
