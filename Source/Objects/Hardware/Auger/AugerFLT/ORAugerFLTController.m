//
//  ORAugerFLTController.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORAugerFLTController.h"
#import "ORAugerFLTModel.h"
#import "ORAugerFLTDefs.h"
#import "ORFireWireInterface.h"
#import "ORPlotter1D.h"
#import "ORValueBar.h"
#import "ORAxis.h"
#import "ORTimeRate.h"

@implementation ORAugerFLTController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"AugerFLT"];
    
    return self;
}

#pragma mark ¥¥¥Initialization
- (void) dealloc
{
	[rateFormatter release];
	[blankView release];
    [super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];

    settingSize     = NSMakeSize(546,680);
    rateSize	    = NSMakeSize(430,615);
    testSize	    = NSMakeSize(400,500);

	rateFormatter = [[NSNumberFormatter alloc] init];
	[rateFormatter setFormat:@"##0.00"];
	[totalHitRateField setFormatter:rateFormatter];

    blankView = [[NSView alloc] init];
    
    NSString* key = [NSString stringWithFormat: @"orca.ORAugerFLT%d.selectedtab",[model stationNumber]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];

	ORValueBar* bar = rate0;
	do {
		[bar setBackgroundColor:[NSColor whiteColor]];
		[bar setBarColor:[NSColor greenColor]];
		bar = [bar chainedView];
	}while(bar!=nil);
	
	[totalRate setBackgroundColor:[NSColor whiteColor]];
	[totalRate setBarColor:[NSColor greenColor]];


    [self updateWindow];
}

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORAugerFLTSettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORAugerCardSlotChangedNotification
					   object : model];


    [notifyCenter addObserver : self
                     selector : @selector(modeChanged:)
                         name : ORAugerFLTModelModeChanged
                       object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(thresholdChanged:)
						 name : ORAugerFLTModelThresholdChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(gainChanged:)
						 name : ORAugerFLTModelGainChanged
					   object : model];

   [notifyCenter addObserver : self
					 selector : @selector(triggerEnabledChanged:)
						 name : ORAugerFLTModelTriggerEnabledChanged
					   object : model];

   [notifyCenter addObserver : self
					 selector : @selector(hitRateEnabledChanged:)
						 name : ORAugerFLTModelHitRateEnabledChanged
					   object : model];

   [notifyCenter addObserver : self
					 selector : @selector(triggersEnabledArrayChanged:)
						 name : ORAugerFLTModelTriggersEnabledChanged
					   object : model];

   [notifyCenter addObserver : self
					 selector : @selector(hitRatesEnabledArrayChanged:)
						 name : ORAugerFLTModelHitRatesArrayChanged
					   object : model];


    [notifyCenter addObserver : self
					 selector : @selector(gainArrayChanged:)
						 name : ORAugerFLTModelGainsChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(thresholdArrayChanged:)
						 name : ORAugerFLTModelThresholdsChanged
					   object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(shapingTimesArrayChanged:)
						 name : ORAugerFLTModelShapingTimesChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(shapingTimeChanged:)
						 name : ORAugerFLTModelShapingTimeChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(hitRateLengthChanged:)
						 name : ORAugerFLTModelHitRateLengthChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(hitRateChanged:)
						 name : ORAugerFLTModelHitRateChanged
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
					 selector : @selector(totalRateChanged:)
						 name : ORRateAverageChangedNotification
					   object : [model totalRate]];

    [notifyCenter addObserver : self
					 selector : @selector(broadcastTimeChanged:)
						 name : ORAugerFLTModelBroadcastTimeChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(testEnabledArrayChanged:)
                         name : ORAugerFLTModelTestEnabledArrayChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(testStatusArrayChanged:)
                         name : ORAugerFLTModelTestStatusArrayChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : ORAugerFLTModelTestsRunningChanged
                       object : model];


    [notifyCenter addObserver : self
                     selector : @selector(testParamChanged:)
                         name : ORAugerFLTModelTestParamChanged
                       object : model];


    [notifyCenter addObserver : self
                     selector : @selector(patternChanged:)
                         name : ORAugerFLTModelTestPatternsChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(tModeChanged:)
                         name : ORAugerFLTModelTModeChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(numTestPattersChanged:)
                         name : ORAugerFLTModelTestPatternCountChanged
                       object : model];
					   
    [notifyCenter addObserver : self
					 selector : @selector(readoutPagesChanged:)
						 name : ORAugerFLTModelReadoutPagesChanged
					   object : model];


    [notifyCenter addObserver : self
                     selector : @selector(checkWaveFormEnabledChanged:)
                         name : ORAugerFLTModelCheckWaveFormEnabledChanged
						object: model];

}

#pragma mark ¥¥¥Interface Management

- (void) checkWaveFormEnabledChanged:(NSNotification*)aNote
{
	[checkWaveFormEnabledButton setIntValue: [model checkWaveFormEnabled]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self modeChanged:nil];
	[self gainArrayChanged:nil];
	[self thresholdArrayChanged:nil];
	[self triggersEnabledArrayChanged:nil];
	[self hitRatesEnabledArrayChanged:nil];
	[self shapingTimesArrayChanged:nil];
	[self hitRateLengthChanged:nil];
	[self hitRateChanged:nil];
    [self updateTimePlot:nil];
    [self totalRateChanged:nil];
	[self scaleAction:nil];
	[self broadcastTimeChanged:nil];
    [self testEnabledArrayChanged:nil];
	[self testStatusArrayChanged:nil];
	[self testParamChanged:nil];
    [self patternChanged:nil];
    [self tModeChanged:nil];
	[self numTestPattersChanged:nil];
    [self miscAttributesChanged:nil];
	[self readoutPagesChanged:nil];	
	[self checkWaveFormEnabledChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];


    [gSecurity setLock:ORAugerFLTSettingsLock to:secure];
    [settingLockButton setEnabled:secure];
	
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORAugerFLTSettingsLock];
	BOOL isRunning = [gOrcaGlobals runInProgress];
    BOOL locked = [gSecurity isLocked:ORAugerFLTSettingsLock];
	BOOL testsAreRunning = [model testsRunning];
	BOOL testingOrRunning = testsAreRunning | runInProgress;
    
    [testEnabledMatrix setEnabled:!locked && !testingOrRunning];
    [settingLockButton setState: locked];
	[readControlButton setEnabled:!lockedOrRunningMaintenance];
	[writeControlButton setEnabled:!lockedOrRunningMaintenance];
	[modeButton setEnabled:!lockedOrRunningMaintenance];
	[resetButton setEnabled:!lockedOrRunningMaintenance];
	[triggerButton setEnabled:isRunning]; // only active in run mode, ak 4.7.07
    [gainTextFields setEnabled:!lockedOrRunningMaintenance];
    [thresholdTextFields setEnabled:!lockedOrRunningMaintenance];
	[readThresholdsGainsButton setEnabled:!lockedOrRunningMaintenance];
    [triggerEnabledCBs setEnabled:!lockedOrRunningMaintenance];
    [hitRateEnabledCBs setEnabled:!lockedOrRunningMaintenance];
    [writeThresholdsGainsButton setEnabled:!lockedOrRunningMaintenance];
    [loadTimeButton setEnabled:!locked];
    [readTimeButton setEnabled:!locked];
    [broadcastTimeCB setEnabled:!lockedOrRunningMaintenance];

	[versionButton setEnabled:!isRunning];
	[testButton setEnabled:!isRunning];
	[statusButton setEnabled:!isRunning];

    [hitRateLengthField setEnabled:!lockedOrRunningMaintenance];
    [hitRateAllButton setEnabled:!lockedOrRunningMaintenance];
    [hitRateNoneButton setEnabled:!lockedOrRunningMaintenance];
	
	[readoutPagesField setEnabled:!lockedOrRunningMaintenance]; // ak, 2.7.07

	[checkWaveFormEnabledButton setEnabled:!lockedOrRunningMaintenance && [model fltRunMode] == FLT_DEBUG_MODE];

	if(testsAreRunning){
		[testButton setEnabled: YES];
		[testButton setTitle: @"Stop"];
	}
    else {
		[testButton setEnabled: !runInProgress];	
		[testButton setTitle: @"Test"];
	}

	[patternTable setEnabled:!locked];
	[numTestPatternsField setEnabled:!locked];
	[numTestPatternsStepper setEnabled:!locked];

	[tModeMatrix setEnabled:!locked];
	[initTPButton setEnabled:!locked];

}

- (void) numTestPattersChanged:(NSNotification*)aNote
{
	[numTestPatternsField setIntValue:[model testPatternCount]];
	[numTestPatternsStepper setIntValue:[model testPatternCount]];
}

- (void) patternChanged:(NSNotification*) aNote
{
	[patternTable reloadData];
}

- (void) tModeChanged:(NSNotification*) aNote
{
	unsigned short pattern = [model tMode];
	int i;
	for(i=0;i<2;i++){
		[[tModeMatrix cellWithTag:i] setState:pattern&(0x1L<<i)];
	}
}

- (void) testParamChanged:(NSNotification*)aNotification
{
	[[testParamsMatrix cellWithTag:0] setIntValue:[model startChan]];
	[[testParamsMatrix cellWithTag:1] setIntValue:[model endChan]];
	[[testParamsMatrix cellWithTag:2] setIntValue:[model page]];	
}


- (void) testEnabledArrayChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumAugerFLTTests;i++){
		[[testEnabledMatrix cellWithTag:i] setIntValue:[model testEnabled:i]];
	}    
}

- (void) testStatusArrayChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumAugerFLTTests;i++){
		[[testStatusMatrix cellWithTag:i] setStringValue:[model testStatus:i]];
	}
}


- (void) scaleAction:(NSNotification*)aNotification
{
	if(aNotification == nil || [aNotification object] == [rate0 xScale]){
		[model setMiscAttributes:[[rate0 xScale]attributes] forKey:@"RateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [totalRate xScale]){
		[model setMiscAttributes:[[totalRate xScale]attributes] forKey:@"TotalRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot xScale]){
		[model setMiscAttributes:[[timeRatePlot xScale]attributes] forKey:@"TimeRateXAttributes"];
	};
	
	if(aNotification == nil || [aNotification object] == [timeRatePlot yScale]){
		[model setMiscAttributes:[[timeRatePlot yScale]attributes] forKey:@"TimeRateYAttributes"];
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
			[[timeRatePlot xScale] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot xScale] setNeedsDisplay:YES];
		}
	}
	if(aNote == nil || [key isEqualToString:@"TimeRateYAttributes"]){
		if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateYAttributes"];
		if(attrib){
			[[timeRatePlot yScale] setAttributes:attrib];
			[timeRatePlot setNeedsDisplay:YES];
			[[timeRatePlot yScale] setNeedsDisplay:YES];
			[timeRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
		}
	}
}


- (void) updateTimePlot:(NSNotification*)aNote
{
	//if(!aNote || ([aNote object] == [[model adcRateGroup]timeRate])){
	//	[timeRatePlot setNeedsDisplay:YES];
	//}
}


- (void) shapingTimeChanged:(NSNotification*)aNotification
{
	int group = [[[aNotification userInfo] objectForKey:ORAugerFLTChan] intValue];
	switch(group){
		case 0: [shapingTimePU0 selectItemAtIndex: [model shapingTime:0]]; break;
		case 1: [shapingTimePU1 selectItemAtIndex: [model shapingTime:1]]; break;
		case 2: [shapingTimePU2 selectItemAtIndex: [model shapingTime:2]]; break;
		case 3: [shapingTimePU3 selectItemAtIndex: [model shapingTime:3]]; break;
		default: break;
	}	
}

- (void) gainChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORAugerFLTChan] intValue];
	[[gainTextFields cellWithTag:chan] setIntValue: [model gain:chan]];
}

- (void) triggerEnabledChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORAugerFLTChan] intValue];
	[[triggerEnabledCBs cellWithTag:chan] setState: [model triggerEnabled:chan]];
}

- (void) hitRateEnabledChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORAugerFLTChan] intValue];
	[[hitRateEnabledCBs cellWithTag:chan] setState: [model hitRateEnabled:chan]];
}

- (void) thresholdChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORAugerFLTChan] intValue];
	[[thresholdTextFields cellWithTag:chan] setIntValue: [model threshold:chan]];
}


- (void) slotChanged:(NSNotification*)aNotification
{
	// Set title of FLT configuration window, ak 15.6.07
	[[self window] setTitle:[NSString stringWithFormat:@"IPE-DAQ-V3 FLT Card (Slot %d)",[model stationNumber]]];
}

- (void) gainArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[[gainTextFields cellWithTag:chan] setIntValue: [model gain:chan]];

	}	
}

- (void) thresholdArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[[thresholdTextFields cellWithTag:chan] setIntValue: [model threshold:chan]];
	}
}

- (void) triggersEnabledArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[[triggerEnabledCBs cellWithTag:chan] setIntValue: [model triggerEnabled:chan]];

	}
}

- (void) hitRatesEnabledArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		[[hitRateEnabledCBs cellWithTag:chan] setIntValue: [model hitRateEnabled:chan]];

	}
}


- (void) shapingTimesArrayChanged:(NSNotification*)aNotification
{
	[shapingTimePU0 selectItemAtIndex: [model shapingTime:0]];
	[shapingTimePU1 selectItemAtIndex: [model shapingTime:1]];
	[shapingTimePU2 selectItemAtIndex: [model shapingTime:2]];
	[shapingTimePU3 selectItemAtIndex: [model shapingTime:3]];
}


- (void) modeChanged:(NSNotification*)aNote
{
	[modeButton selectItemAtIndex:[model fltRunMode]];
	[self settingsLockChanged:nil];	
}

- (void) broadcastTimeChanged:(NSNotification*)aNote
{
	[broadcastTimeCB setState:[model broadcastTime]];
}

- (void) hitRateLengthChanged:(NSNotification*)aNote
{
	[hitRateLengthField setIntValue:[model hitRateLength]];
}

- (void) hitRateChanged:(NSNotification*)aNote
{
	int chan;
	for(chan=0;chan<kNumFLTChannels;chan++){
		id theCell = [rateTextFields cellWithTag:chan];
		if([model hitRateOverFlow:chan]){
			[theCell setFormatter: nil];
			[theCell setTextColor:[NSColor redColor]];
			[theCell setObjectValue: @"OverFlow"];
		}
		else {
			[theCell setFormatter: rateFormatter];
			[theCell setTextColor:[NSColor blackColor]];
			[theCell setFloatValue: [model hitRate:chan]];
		}
	}
	[rate0 setNeedsDisplay:YES];
	[totalHitRateField setFloatValue:[model hitRateTotal]];
	[totalRate setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)aNote
{
	if(aNote==nil || [aNote object] == [model totalRate]){
		[timeRatePlot setNeedsDisplay:YES];
	}
}

- (void) readoutPagesChanged:(NSNotification*)aNote
{
	[readoutPagesField setIntValue:[model readoutPages]];
}


- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:settingSize];     break;
		case  1: [self resizeWindowToSize:rateSize];	    break;
		default: [self resizeWindowToSize:testSize];	    break;
    }
    [[self window] setContentView:totalView];
            
    NSString* key = [NSString stringWithFormat: @"orca.ORAugerFLT%d.selectedtab",[model stationNumber]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}

#pragma mark ¥¥¥Actions

- (void) checkWaveFormEnabledAction:(id)sender
{
	[model setCheckWaveFormEnabled:[sender intValue]];	
}

- (IBAction) numTestPatternsAction:(id)sender
{
	[model setTestPatternCount:[sender intValue]];
}

- (IBAction) testEnabledAction:(id)sender
{
	NSMutableArray* anArray = [NSMutableArray array];
	int i;
	for(i=0;i<kNumAugerFLTTests;i++){
		if([[testEnabledMatrix cellWithTag:i] intValue])[anArray addObject:[NSNumber numberWithBool:YES]];
		else [anArray addObject:[NSNumber numberWithBool:NO]];
	}
	[model setTestEnabledArray:anArray];
}



- (IBAction) readThresholdsGains:(id)sender
{
	NS_DURING
		int i;
		NSLog(@"FLT (station %d)\n",[model stationNumber]);
		NSLog(@"chan Threshold Gain\n");
		for(i=0;i<kNumFLTChannels;i++){
			NSLog(@"%d: %d %d \n",i,[model readThreshold:i],[model readGain:i]);
			//NSLog(@"%d: %d\n",i,[model readGain:i]);
		}
	NS_HANDLER
		NSLog(@"Exception reading FLT gains and thresholds\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) writeThresholdsGains:(id)sender
{
	[self endEditing];
	NS_DURING
		[model loadThresholdsAndGains];
	NS_HANDLER
		NSLog(@"Exception writing FLT gains and thresholds\n");
        NSRunAlertPanel([localException name], @"%@\nWrite of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) gainAction:(id)sender
{
	if([sender intValue] != [model gain:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Gain"];
		[model setGain:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) thresholdAction:(id)sender
{
	if([sender intValue] != [model threshold:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Threshold"];
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}


- (IBAction) triggerEnableAction:(id)sender
{
	[[self undoManager] setActionName: @"Set TriggerEnabled"];
	[model setTriggerEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) hitRateEnableAction:(id)sender
{
	[[self undoManager] setActionName: @"Set HitRate Enabled"];
	[model setHitRateEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}


- (IBAction) readControlButtonAction:(id)sender
{
	[self endEditing];
	NS_DURING
		[model readMode];
	NS_HANDLER
		NSLog(@"Exception reading FLT status\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) writeControlButtonAction:(id)sender
{
	[self endEditing];
	NS_DURING
		[model writeMode:[model fltRunMode]];
	NS_HANDLER
		NSLog(@"Exception writing FLT status\n");
        NSRunAlertPanel([localException name], @"%@\nWrite of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORAugerFLTSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) modeAction: (id) sender
{
	[model setFltRunMode:[modeButton indexOfSelectedItem]];
}

- (IBAction) versionAction: (id) sender
{
	NS_DURING
		NSLog(@"FLT %d Revision: %d\n",[model stationNumber],[model readVersion]);
		int fpga;
		for (fpga=0;fpga<4;fpga++) {
			int version = [model readFPGAVersion:fpga];
			NSLog(@"FLT %d peripherial FPGA%d version 0x%02x\n",[model stationNumber], fpga, version);
		}
	NS_HANDLER
		NSLog(@"Exception reading FLT HW Model Version\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) testAction: (id) sender
{
	NS_DURING
		[model runTests];
	NS_HANDLER
		NSLog(@"Exception reading FLT HW Model Test\n");
        NSRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}


- (IBAction) resetAction: (id) sender
{
	NS_DURING
		[model reset];
	NS_HANDLER
		NSLog(@"Exception during FLT reset\n");
        NSRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) triggerAction: (id) sender
{
	NS_DURING
		[model trigger];
	NS_HANDLER
		NSLog(@"Exception during FLT trigger\n");
        NSRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}


- (IBAction) loadTimeAction: (id) sender
{
	NS_DURING
		[model loadTime];
	NS_HANDLER
		NSLog(@"Exception during FLT load time\n");
        NSRunAlertPanel([localException name], @"%@\nWrite of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
	
}

- (IBAction) readTimeAction: (id) sender
{
	NS_DURING
		unsigned long timeLoaded = [model readTime];
		NSLog(@"FLT %d time:%d = %@\n",[model stationNumber],timeLoaded,[NSDate dateWithTimeIntervalSinceReferenceDate:(NSTimeInterval)timeLoaded]);
	NS_HANDLER
		NSLog(@"Exception during FLT read time\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) shapingTimeAction: (id) sender
{
	if([sender intValue] != [model gain:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set ShapingTime"]; 
		[model setShapingTime:[sender tag] withValue:[sender indexOfSelectedItem]];
	}
}

- (IBAction) hitRateLengthAction: (id) sender
{
	if([sender intValue] != [model hitRateLength]){
		[[self undoManager] setActionName: @"Set Hit Rate Length"]; 
		[model setHitRateLength:[sender intValue]];
	}
}

- (IBAction) hitRateAllAction: (id) sender
{
	[model enableAllHitRates:YES];
}

- (IBAction) hitRateNoneAction: (id) sender
{
	[model enableAllHitRates:NO];
}

- (IBAction) broadcastTimeAction: (id) sender
{
	[model setBroadcastTime:[sender state]];
}

- (IBAction) testParamAction: (id) sender
{
	[self endEditing];
	switch([[sender selectedCell] tag]){
		case 0: 	[model setStartChan:[sender intValue]]; break;
		case 1: 	[model setEndChan:[sender intValue]]; break;
		case 2: 	[model setPage:[sender intValue]]; break;
		default: break;
	}
}

- (IBAction) statusAction:(id)sender
{
	NS_DURING
		[model printStatusReg];
	NS_HANDLER
		NSLog(@"Exception during FLT read status\n");
        NSRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) tModeAction: (id) sender
{
	unsigned long pattern = 0;
	int i;
	for(i=0;i<2;i++){
		BOOL state = [[tModeMatrix cellWithTag:i] state];
		if(state)pattern |= (0x1L<<i);
		else pattern &= ~(0x1L<<i);
	}
	
	[model setTMode:pattern];
}

- (IBAction) initTPAction: (id) sender
{
	NS_DURING
		[model writeTestPatterns];
	NS_HANDLER
		NSLog(@"Exception during FLT init test Pattern\n");
        NSRunAlertPanel([localException name], @"%@\nTest Pattern Init FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}


- (IBAction) readoutPagesAction: (id) sender
{
	if([sender intValue] != [model readoutPages]){
		[[self undoManager] setActionName: @"Set Readout Pages"]; 
		[model setReadoutPages:[sender intValue]];
	}
}

#pragma mark ¥¥¥Plot DataSource
- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set
{
	return [[model  totalRate]count];
}
- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x 
{
	int count = [[model totalRate]count];
	return [[model totalRate] valueAtIndex:count-x-1];
}

- (unsigned long)  	secondsPerUnit:(id) aPlotter
{
	return [[model totalRate] sampleTime];
}

//table 
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    NSParameterAssert(rowIndex >= 0 && rowIndex < [[model testPatterns] count]);
	if([[aTableColumn identifier] isEqualToString:@"Index"]){
		return [NSNumber numberWithInt:rowIndex];
	}
	else {
		return [[model testPatterns] objectAtIndex:rowIndex];
	}
}

// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [[model testPatterns] count];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if(rowIndex>=0 && rowIndex<24){
		[[model testPatterns] replaceObjectAtIndex:rowIndex withObject:anObject];
	}
}


- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(cut:)) {
        return [patternTable selectedRow] >= 0 ;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [patternTable selectedRow] >= 0;
    }
    else if ([menuItem action] == @selector(copy:)) {
        return NO; //enable when cut/paste is finished
    }
    else if ([menuItem action] == @selector(paste:)) {
        return NO; //enable when cut/paste is finished
    }
    return YES;
}

@end



