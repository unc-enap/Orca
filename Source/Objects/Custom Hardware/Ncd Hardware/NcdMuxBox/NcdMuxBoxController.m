
//
//  NcdMuxBoxController.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "NcdMuxBoxController.h"
#import "NcdMuxBoxModel.h"
#import "ORRate.h"
#import "ORRateGroup.h"
#import "ORValueBar.h"
#import "ORValueBarGroupView.h"
#import "ORCompositePlotView.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"
#import "ThresholdCalibrationTask.h"
#import "ORValueBarGroupView.h"

@implementation NcdMuxBoxController

- (id) init
{
    self = [super initWithWindowNibName:@"NcdMuxBox"];
    return self;
}


- (void) dealloc
{
    [blankView release];
    [super dealloc];
}

- (void)awakeFromNib
{
    settingSize     = NSMakeSize(407,532);
    rateSize	    = NSMakeSize(504,462);
    calibrationSize = NSMakeSize(375,400);
    testingSize     = NSMakeSize(300,340);
    
    blankView = [[NSView alloc] init];
    
    NSString* key = [NSString stringWithFormat: @"orca.ORMuxBox%d.selectedtab",[model muxID]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
    
 	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release]; 
	[rate0 setNumber:13 height:10 spacing:5];
    //[self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
    [super  awakeFromNib];
}


- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"Mux %d",[model muxID]]];
    [self settingsLockChanged:nil];
    [self calibrationLockChanged:nil];
    [self testLockChanged:nil];
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(thresholdDacArrayChanged:)
                         name : NcdMuxDacArrayChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(thresholdAdcArrayChanged:)
                         name : NcdMuxAdcThresChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(thresholdDacChanged:)
                         name : NcdThresholdDacChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(integrationChanged:)
                         name : ORRateGroupIntegrationChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORMuxBoxRateGroupChangedNotification
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
    
    //the notification that the scale values were changed
    [notifyCenter addObserver : self
                     selector : @selector(rateAttributesChanged:)
                         name : ORMuxBoxRateChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(totalRateAttributesChanged:)
                         name : ORMuxBoxTotalRateChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(timeRateXAttributesChanged:)
                         name : ORMuxBoxTimeRateXChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(timeRateYAttributesChanged:)
                         name : ORMuxBoxTimeRateYChangedNotification
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(updateTimePlot:)
                         name : ORRateAverageChangedNotification
                       object : [[model rateGroup]timeRate]];
    
    [notifyCenter addObserver : self
                     selector : @selector(busNumberChanged:)
                         name : ORMuxBoxBusNumberChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(connectionChanged:)
                         name : ORConnectionChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(channelChanged:)
                         name : ORMuxBoxChannelSelectionChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(dacValueChanged:)
                         name : ORMuxBoxDacValueChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(calibrationLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(testLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(scopeChanChanged:)
                         name : ORNcdMuxBoxScopeChanChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : NcdMuxBoxSettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(calibrationLockChanged:)
                         name : NcdMuxBoxCalibrationLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(testLockChanged:)
                         name : NcdMuxBoxTestLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(calibrationEnabledMaskChanged:)
                         name : ORMuxBoxCalibrationEnabledMaskChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(calibrationFinalDeltaChanged:)
                         name : ORMuxBoxCalibrationFinalDeltaChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(calibrationStateChanged:)
                         name : ORMuxBoxCalibrationTaskChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(calibrationStateLablesChanged:)
                         name : NcdMuxCalibrationStateChanged
                       object : model];
    
    
    [self registerRates];
}

- (void) registerRates
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter removeObserver:self name:ORRateChangedNotification object:nil];
    
    NSEnumerator* e = [[[model rateGroup] rates] objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
        [notifyCenter addObserver : self
                         selector : @selector(rateChanged:)
                             name : ORRateChangedNotification
                           object : obj];
    }
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self thresholdAdcArrayChanged:nil];
    [self thresholdDacArrayChanged:nil];
    [self thresholdDacChanged:nil];
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self rateAttributesChanged:nil];
    [self totalRateAttributesChanged:nil];
    [self timeRateXAttributesChanged:nil];
    [self timeRateYAttributesChanged:nil];
    [self updateTimePlot:nil];
    [self busNumberChanged:nil];
    [self boxNumberChanged:nil];
    [self channelChanged:nil];
    [self dacValueChanged:nil];
    [self rateChanged:nil];
    [self totalRateChanged:nil];
    [self scopeChanChanged:nil];
    [self settingsLockChanged:nil];
    [self calibrationLockChanged:nil];
    [self testLockChanged:nil];
    
    [self calibrationEnabledMaskChanged:nil];
    [self calibrationFinalDeltaChanged:nil];
    [self calibrationStateChanged:nil];
    //[self calibrationStateLablesChanged:nil];
}

- (void) calibrationEnabledMaskChanged:(NSNotification*)aNotification
{
	int i;
	unsigned short mask = [model calibrationEnabledMask];
	for(i=0;i<kNumMuxChannels-1;i++){
		[[calibrationEnabledMatrix cellWithTag:i] setState: mask & (1<<i)];
	}    
}
- (void) calibrationFinalDeltaChanged:(NSNotification*)aNotification
{
	[self updateStepper:calibrationFinalDeltaStepper setting:[model calibrationFinalDelta]];
	[self updateIntText:calibrationFinalDeltaTextField setting:[model calibrationFinalDelta]];
}


- (void) calibrationStateLablesChanged:(NSNotification*)aNotification
{
	int channel = [[[aNotification userInfo] objectForKey:NcdMuxStateChannel] intValue];
	[[calibrationStateMatrix cellWithTag:channel] setStringValue:[model thresholdCalibration:channel]];
}

- (void) calibrationStateChanged:(NSNotification*)aNotification
{
	if(![model calibrationTask]){
		[calibrateButton setTitle:@"Start Calibration"];
	}
	else {
		[calibrateButton setTitle:@"Stop"];
	}
}

- (void) thresholdDacChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:NcdMuxChan] intValue];
	int value = [model thresholdDac:chan];
	[[thresholdDacSteppers cellWithTag:chan] setIntValue:value];
	[[thresholdDacTextFields cellWithTag:chan] setIntValue: value];
	[[calibrationThresholdMatrix cellWithTag:chan] setIntValue: value];
}


- (void) thresholdDacArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumMuxChannels;chan++){
		int value = [model thresholdDac:chan];
		[[thresholdDacSteppers cellWithTag:chan] setIntValue:value];
		[[thresholdDacTextFields cellWithTag:chan] setIntValue: value];
		[[calibrationThresholdMatrix cellWithTag:chan] setIntValue: value];
	}
}

- (void) thresholdAdcArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumMuxChannels;chan++){
		[[thresholdAdcTextFields cellWithTag:chan] setIntValue: [model thresholdAdc:chan]];
	}
}

- (void) busNumberChanged:(NSNotification*)aNotification
{
	[busNumberField setIntValue:[model busNumber]];
}

- (void) boxNumberChanged:(NSNotification*)aNotification
{
	[boxNumberField setIntValue:[model muxID]];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:NcdMuxBoxSettingsLock to:secure];
    [gSecurity setLock:NcdMuxBoxTestLock to:secure];
    [gSecurity setLock:NcdMuxBoxCalibrationLock to:secure];
    [settingsLockButton setEnabled:secure];
    [testLockButton setEnabled:secure];
    [calibrationLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification *)notification
{
    BOOL locked = [gSecurity isLocked:NcdMuxBoxSettingsLock];
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:NcdMuxBoxSettingsLock];
    BOOL lockedOrRunning = [gSecurity runInProgressOrIsLocked:NcdMuxBoxSettingsLock];
    
    [settingsLockButton setState:locked];
    
    [thresholdDacSteppers setEnabled:!locked];
    [thresholdDacTextFields setEnabled:!locked];
    [readThresholdsButton setEnabled:!lockedOrRunningMaintenance];
    [initThresholdsButton setEnabled:!lockedOrRunningMaintenance];
    
    
    [scopeChanStepper setEnabled:!lockedOrRunning];
    [scopeChanTextField setEnabled:!lockedOrRunning];
    
    [pingButton setEnabled:!runInProgress];
    
    [selectChannelPU setEnabled:!runInProgress];
    [readAdcButton setEnabled:!runInProgress];
    [writeDacButton setEnabled:!runInProgress];
    [readEventRegButton setEnabled:!runInProgress];
    [reArmButton setEnabled:!runInProgress];
    [statusQueryButton setEnabled:!runInProgress];
    [testAdcDacButton setEnabled:!runInProgress];
    [dacValueField setEnabled:!runInProgress];
    [dacValueStepper setEnabled:!runInProgress];
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:NcdMuxBoxSettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
}

- (void) testLockChanged:(NSNotification *)notification
{
    BOOL locked = [gSecurity isLocked:NcdMuxBoxTestLock];
    BOOL lockedOrRunning = [gSecurity runInProgressOrIsLocked:NcdMuxBoxTestLock];
    
    [testLockButton setState:locked];
    
    [selectChannelPU setEnabled:!lockedOrRunning];
    [readAdcButton setEnabled:!lockedOrRunning];
    [writeDacButton setEnabled:!lockedOrRunning];
    [readEventRegButton setEnabled:!lockedOrRunning];
    [reArmButton setEnabled:!lockedOrRunning];
    [statusQueryButton setEnabled:!lockedOrRunning];
    [testAdcDacButton setEnabled:!lockedOrRunning];
    [dacValueField setEnabled:!lockedOrRunning];
    [dacValueStepper setEnabled:!lockedOrRunning];
}


- (void) calibrationLockChanged:(NSNotification *)notification
{
    BOOL locked = [gSecurity isLocked:NcdMuxBoxCalibrationLock];
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL runButNotMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked: NcdMuxBoxCalibrationLock];
    [calibrationLockButton setState:locked];
    
    BOOL okToCalibrate = !locked && (runInProgress && !runButNotMaintenance);
    [calibrateButton setEnabled:okToCalibrate];
    [calibrationEnabledMatrix setEnabled:okToCalibrate];
    [calibrationFinalDeltaStepper setEnabled:okToCalibrate];
    [calibrationFinalDeltaTextField setEnabled:okToCalibrate];
    [enableAllButton setEnabled:okToCalibrate];
    [enableNoneButton setEnabled:okToCalibrate];
    
    NSString* s = @"";
    if(!locked && (!runInProgress || runButNotMaintenance))s = @"Not in Maintenance Run.";
    [calibrationLockDocField setStringValue:s];
}



- (void) connectionChanged: (NSNotification*) aNotification
{
    [self updateWindow];
}

#pragma mark ¥¥¥Actions
-(IBAction) thresholdDacAction:(id)sender
{
    if([sender intValue] != [model thresholdDac:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Mux Threshold Dac"];
        [model setThresholdDac:[[sender selectedCell] tag] withValue:[sender intValue]];
    }
}

- (IBAction) readThresholdAction:(id)sender
{
    @try {
		[self endEditing];
		[model readThresholds];
		
	}
	@catch(NSException* localException) {
		NSLog(@"Read of Mux %d Thresholds Failed.\n",[model muxID]);
		ORRunAlertPanel([localException name], @"%@\nFailed Read of Mux Thresholds.", @"OK", nil, nil,
						localException);
    }
}

- (IBAction) initThresholdAction:(id)sender
{
    @try {
		[self endEditing];
		[model loadThresholdDacs];
		NSLog(@"Loaded Mux %d Thresholds\n",[model muxID]);
		[model readThresholds];
		[model checkThresholds];
		
    }
	@catch(NSException* localException) {
		NSLog(@"Load of Mux %d Thresholds Failed.\n",[model muxID]);
		ORRunAlertPanel([localException name], @"%@\nFailed Load of Mux Thresholds.", @"OK", nil, nil,
						localException);
    }
}

- (IBAction) settingsLockAction:(id)sender
{
    [gSecurity tryToSetLock:NcdMuxBoxSettingsLock to:[sender intValue] forWindow:[self window]];
}
- (IBAction) calibrationLockAction:(id)sender
{
    [gSecurity tryToSetLock:NcdMuxBoxCalibrationLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) testLockAction:(id)sender
{
    [gSecurity tryToSetLock:NcdMuxBoxTestLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) testAction:(id)sender
{
    [self endEditing];
    [model runMuxBitTest];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case 0: [self resizeWindowToSize:settingSize];      break;
		case 1: [self resizeWindowToSize:rateSize];	    break;
		case 2: [self resizeWindowToSize:calibrationSize];  break;
		default:[self resizeWindowToSize:testingSize];      break;
    }
    [[self window] setContentView:tabView];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORMuxBox%d.selectedtab",[model muxID]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}

- (void) rateChanged:(NSNotification*)aNotification
{
    ORRate* theRateObj = [aNotification object];
    unsigned short index = 	[theRateObj tag];
    [[rateTextFields cellWithTag:index] setFloatValue: [theRateObj rate]];
    [[calibrationRateTextMatrix cellWithTag:index] setFloatValue: [theRateObj rate]];
    [[countTextFields cellWithTag:index] setIntegerValue: [model rateCount:index]];
    [rate0 setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)aNotification
{
    ORRateGroup* theRateObj = [aNotification object];
    if(aNotification == nil || [model rateGroup] == theRateObj){
		
		[totalRateText setFloatValue: [theRateObj totalRate]];
		[totalRate setNeedsDisplay:YES];
    }
}

- (void) rateGroupChanged:(NSNotification*)aNotification
{
	[self registerRates];
}

- (void) scopeChanChanged:(NSNotification*)aNotification
{
	[scopeChanTextField setIntValue:[model scopeChan]];
	[scopeChanStepper setIntValue:[model scopeChan]];
	
}


- (void) integrationChanged:(NSNotification*)aNotification
{
    ORRateGroup* theRateGroup = [aNotification object];
	if(aNotification == nil || [model rateGroup] == theRateGroup || [aNotification object] == model){
		double dValue = [[model rateGroup] integrationTime];
		[integrationStepper setDoubleValue:dValue];
		[integrationText setDoubleValue: dValue];
    }
}


- (void) rateAttributesChanged:(NSNotification*)aNote
{
    //do we care?
	
	[[rate0 xAxis] setAttributes:[model rateAttributes]];
	[rate0 setNeedsDisplay:YES];
	[[rate0 xAxis]setNeedsDisplay:YES];
	
	BOOL state = [[[model rateAttributes] objectForKey:ORAxisUseLog] boolValue];
	[rateLogCB setState:state];
	
}

- (void) totalRateAttributesChanged:(NSNotification*)aNote
{
	
	[[totalRate xAxis] setAttributes:[model totalRateAttributes]];
	[totalRate setNeedsDisplay:YES];
	[[totalRate xAxis]setNeedsDisplay:YES];
	
	BOOL state = [[[model totalRateAttributes] objectForKey:ORAxisUseLog] boolValue];
	[totalRateLogCB setState:state];
	
}


- (void) timeRateXAttributesChanged:(NSNotification*)aNote
{
	[(ORAxis*)[timeRatePlot xAxis] setAttributes:[model timeRateXAttributes]];
	[timeRatePlot setNeedsDisplay:YES];
	[[timeRatePlot xAxis]setNeedsDisplay:YES];
}



- (void) timeRateYAttributesChanged:(NSNotification*)aNote
{	
	[(ORAxis*)[timeRatePlot yAxis] setAttributes:[model timeRateYAttributes]];
	[timeRatePlot setNeedsDisplay:YES];
	[[timeRatePlot yAxis]setNeedsDisplay:YES];
	
	BOOL state = [[[model timeRateYAttributes] objectForKey:ORAxisUseLog] boolValue];
	[timeRateLogCB setState:state];
	
}


- (void) channelChanged:(NSNotification*)aNote
{
	[self updatePopUpButton:selectChannelPU setting:[model selectedChannel]];
	
}

- (void) dacValueChanged:(NSNotification*)aNote
{
	double dValue = [model dacValue];
	[dacValueStepper setDoubleValue:dValue];
	[dacValueField setDoubleValue: dValue];
}


- (void) updateTimePlot:(NSNotification*)aNote
{
    if(!aNote || ([aNote object] == [[model rateGroup]timeRate])){
		[timeRatePlot setNeedsDisplay:YES];
    }
}

//a fake action from the scale object
- (void) scaleAction:(NSNotification*)aNotification
{
    if(aNotification == nil || [aNotification object] == [rate0 xAxis]){
		[[self undoManager] setActionName: @"Set Mux Rate Attributes"];
		[model setRateAttributes:[[rate0 xAxis]attributes]];
    };
    if(aNotification == nil || [aNotification object] == [totalRate xAxis]){
		[[self undoManager] setActionName: @"Set Mux Total Rate Attributes"];
		[model setTotalRateAttributes:[[totalRate xAxis]attributes]];
    };
    
    
    if(aNotification == nil || [aNotification object] == [timeRatePlot xAxis]){
		[[self undoManager] setActionName: @"Set Mux Time Rate X Attributes"];
		[model setTimeRateXAttributes:[(ORAxis*)[timeRatePlot xAxis]attributes]];
    };
    if(aNotification == nil || [aNotification object] == [timeRatePlot yAxis]){
		[[self undoManager] setActionName: @"Set Mux Time Rate Y Attributes"];
		[model setTimeRateYAttributes:[(ORAxis*)[timeRatePlot yAxis]attributes]];
    };
    
}

- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model rateGroup]integrationTime]){
		[[self undoManager] setActionName: @"Set Integration Time"];
		[model setIntegrationTime:[sender doubleValue]];
    }
    
}

- (IBAction) rateUsesLogAction:(id)sender
{
    if([sender state] != [[rate0 xAxis] isLog]){
		NSMutableDictionary* attributes = [[rate0 xAxis]attributes];
		[attributes setObject:[NSNumber numberWithBool:[sender state]] forKey:ORAxisUseLog];
		[model setRateAttributes:attributes];
    }
    
}
- (IBAction) totalRateUsesLogAction:(id)sender
{
    if([sender state] != [[totalRate xAxis] isLog]){
		[totalRate setLogX:sender];
		NSMutableDictionary* attributes = [[totalRate xAxis]attributes];
		[attributes setObject:[NSNumber numberWithBool:[sender state]] forKey:ORAxisUseLog];
		[model setTotalRateAttributes:attributes];
    }
}

- (IBAction) timeRateUsesLogAction:(id)sender
{
    if([sender state] != [[timeRatePlot yAxis] isLog]){
		[timeRatePlot setLogY:sender];
		NSMutableDictionary* attributes = [(ORAxis*)[timeRatePlot yAxis]attributes];
		[attributes setObject:[NSNumber numberWithBool:[sender state]] forKey:ORAxisUseLog];
		[model setTimeRateYAttributes:attributes];
    }
}
- (IBAction) ping:(id)sender
{
    [model ping];
}

- (IBAction) channelAction:(id)sender
{
    if([sender indexOfSelectedItem] != [model selectedChannel]){
		[[self undoManager] setActionName: @"Set Selected Channel"];
		[model setSelectedChannel:[sender indexOfSelectedItem]];
    }
}

- (IBAction) dacValueAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [model dacValue]){
		[[self undoManager] setActionName: @"Set Dac Value"];
		[model setDacValue:[sender doubleValue]];
    }
}

- (IBAction) scopeChanAction:(id)sender
{
    [self endEditing];
    if([sender intValue] != [model scopeChan]){
		[[self undoManager] setActionName: @"Set Mux Scope Chan"];
		[model setScopeChan:[sender intValue]];
    }
}


- (IBAction) writeDacAction:(id)sender
{
    [model writeDacValue];
}

- (IBAction) readAdcAction:(id)sender
{
    [model readAdcValue];
}

- (IBAction) readEventRegAction:(id)sender
{
    [model readEventReg];
}

- (IBAction) reArmAction:(id)sender
{
    [model reArm];
	NSLog(@"manual forced reArm of mux system\n"); 
}

- (IBAction) statusQueryAction:(id)sender
{
    [self ping:sender];
}

- (IBAction) calibrateAction:(id)sender
{
    [model calibrate];
}

- (IBAction) calibrationEnabledAction:(id)sender
{
    //if([sender intValue] != [model calibrationEnabledMask]){
	unsigned short mask = 0;
	int i;
	for(i=0;i<kNumMuxChannels-1;i++){
	    if([[calibrationEnabledMatrix cellWithTag:i] state])
			mask |= 1<<i ;
	}
	[model setCalibrationEnabledMask:mask];
    // }
}



- (IBAction) calibrationFinalDeltaAction:(id)sender
{
    [self endEditing];
    if([sender intValue] != [model calibrationFinalDelta]){
		[[self undoManager] setActionName: @"Set Calibration Final Level"];
		[model setCalibrationFinalDelta:[sender intValue]];
    }
}

- (IBAction) calibrationEnableAllAction:(id)sender
{
    [model setCalibrationEnabledMask:0xffff];
}

- (IBAction) calibrationEnableNoneAction:(id)sender
{
    [model setCalibrationEnabledMask:0x0];
}

- (double) getBarValue:(int)tag
{
    return [[[[model rateGroup]rates] objectAtIndex:tag] rate];
}

- (int) numberPointsInPlot:(id)aPlotter
{
    return (int)[[[model rateGroup]timeRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	NSUInteger count = [[[model rateGroup]timeRate] count];
	NSUInteger index = count-i-1;
	*yValue =  [[[model rateGroup]timeRate]valueAtIndex:index];
	*xValue =  [[[model rateGroup]timeRate]timeSampledAtIndex:index];
}


@end
