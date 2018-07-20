/*
 *  ORL2551ModelController.cpp
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
#import "ORL2551Controller.h"
#import "ORCamacExceptions.h"
#import "ORCamacExceptions.h"
#import "TimedWorker.h"
#import "ORValueBarGroupView.h"
#import "ORAxis.h"

#pragma mark ¥¥¥Macros

// methods
@implementation ORL2551Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"L2551"];
    
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
	
    [[rate0 xAxis] setRngLimitsLow:0 withHigh:100000000 withMinRng:50];
	[rate0 setNumber:12 height:10 spacing:8];
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
                         name : ORL2551SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(onlineMaskChanged:)
                         name : ORL2551OnlineMaskChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(pollRateChanged:)
                         name : TimedWorkerTimeIntervalChangedNotification
                       object : [model poller]];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(pollRunningChanged:)
                         name : TimedWorkerIsRunningChangedNotification
                       object : [model poller]];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(scalerCountChanged:)
                         name : ORL2551ScalerCountChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(scalerRateChanged:)
                         name : ORL2551RateChangedNotification
                       object : model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(shipScalersChanged:)
                         name : ORL2551ShipScalersChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(clearOnStartChanged:)
                         name : ORL2551ClearOnStartChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollWhenRunningChanged:)
                         name : ORL2551PollWhenRunningChangedNotification
                       object : model];
    
}

#pragma mark ¥¥¥Interface Management

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self onlineMaskChanged:nil];
    [self settingsLockChanged:nil];
    [self pollRateChanged:nil];
    [self pollRunningChanged:nil];
    [self shipScalersChanged:nil];
    [self clearOnStartChanged:nil];
    [self pollWhenRunningChanged:nil];
    int i;
    for(i=0;i<12;i++){
        [[countsMatrix cellWithTag:i] setIntegerValue:[model scalerCount:i]];
        [[rateMatrix cellWithTag:i] setFloatValue:[model scalerRate:i]];
    }
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORL2551SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORL2551SettingsLock];
    BOOL locked = [gSecurity isLocked:ORL2551SettingsLock];
    
    [settingLockButton setState: locked];
    [onlineMaskMatrix setEnabled:!lockedOrRunningMaintenance];
	
    [readNoResetButton setEnabled:!lockedOrRunningMaintenance];
    [readResetButton setEnabled:!lockedOrRunningMaintenance]; 
    [testLAMButton setEnabled:!lockedOrRunningMaintenance];
    [disableLAMButton setEnabled:!lockedOrRunningMaintenance];
    [enableLAMButton setEnabled:!lockedOrRunningMaintenance];
    [clearButton setEnabled:!lockedOrRunningMaintenance];
    [incAllButton setEnabled:!lockedOrRunningMaintenance];
    
    [clearOnStartButton setEnabled:!lockedOrRunningMaintenance];
    [shipButton setEnabled:!lockedOrRunningMaintenance];
	[pollWhenRunningButton setEnabled:!lockedOrRunningMaintenance];
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORL2551SettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
    
}

- (void) pollRateChanged:(NSNotification*)aNotification
{
    if(aNotification== nil || [aNotification object] == [model poller]){
        [pollRatePopup selectItemAtIndex:[pollRatePopup indexOfItemWithTag:[[model poller] timeInterval]]];
    }
}

- (void) pollRunningChanged:(NSNotification*)aNotification
{
    if(aNotification== nil || [aNotification object] == [model poller]){
        if([[model poller] isRunning])[pollRunningIndicator startAnimation:self];
        else [pollRunningIndicator stopAnimation:self];
    }
}

- (void) scalerCountChanged:(NSNotification*)aNotification
{
	unsigned short index = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
	if(index<12){
		id cell = [countsMatrix cellWithTag:index];
		[cell setIntegerValue:[model scalerCount:index]];
		
		//check for half scale and adjust color
		if([model scalerCount:index]>0x00800000)[cell setTextColor:[NSColor colorWithCalibratedRed:.7 green:0 blue:0 alpha:1.0]];
		else [cell setTextColor:[NSColor blackColor]];
	}
}

- (void) scalerRateChanged:(NSNotification*)aNotification
{
    unsigned short index = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
    if(index<12){
        [[rateMatrix cellWithTag:index] setFloatValue: [model scalerRate:index]];
        [rate0 setNeedsDisplay:YES];
    }
}


- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"L2551 Scaler (Station %d)",(int)[model stationNumber]]];
}

- (void) shipScalersChanged:(NSNotification*)aNotification
{
	[shipButton setState:[model doNotShipScalers]];
}

- (void) clearOnStartChanged:(NSNotification*)aNotification
{
	[clearOnStartButton setState:![model clearOnStart]];
}

- (void) pollWhenRunningChanged:(NSNotification*)aNotification
{
	[pollWhenRunningButton setState:[model pollWhenRunning]];
}


- (void) onlineMaskChanged:(NSNotification*)aNotification
{
	short i;        
	for(i=0;i<12;i++){
		BOOL bitSet = [model onlineMaskBit:i];
		if(bitSet != [[onlineMaskMatrix cellWithTag:i] intValue]){
			[[onlineMaskMatrix cellWithTag:i] setState:bitSet];
		}			
	}
}


#pragma mark ¥¥¥Actions
- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORL2551SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) onlineAction:(id)sender
{
	if([[(NSMatrix*)sender selectedCell] intValue] != [model onlineMaskBit:(int)[[(NSMatrix*)sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Online Mask"];
		[model setOnlineMaskBit:(int)[[(NSMatrix*)sender selectedCell] tag] withValue:[[(NSMatrix*)sender selectedCell] intValue]];
	}
}

- (IBAction) readNoResetAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model readAllScalers];
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Read/No Reset" fCode:0];
    }
}

- (IBAction) readResetAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model readReset];
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Read/Reset" fCode:0];
    }
}

- (IBAction) testLAMAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model testLAM];
        NSLog(@"L2551 Test LAM for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Test LAM" fCode:8];
    }
}


- (IBAction) clearAllAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model clearAll];
        NSLog(@"L2551 clear all for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Clear All" fCode:11];
    }
}

- (IBAction) disableLAMAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model disableLAM];
        NSLog(@"L2551 Disable LAM for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Disable LAM" fCode:24];
    }
}

- (IBAction) enableLAMAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model enableLAM];
        NSLog(@"L2551 Enable LAM for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Enable LAM" fCode:26];
    }
}

- (IBAction) incAllAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model incAll];
        NSLog(@"L2551 increment all channels for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Increment All Channels" fCode:25];
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


- (IBAction) pollRateAction:(id)sender
{
    [model setPollingInterval:[[pollRatePopup selectedItem] tag]];
}

- (IBAction) shipScalersAction:(id)sender
{
    [model setDoNotShipScalers:[sender intValue]];
}

- (IBAction) pollWhenRunningAction:(id)sender
{
    [model setPollWhenRunning:[sender intValue]];
}


- (IBAction) clearOnStartAction:(id)sender
{
    BOOL state = [sender intValue];
    [model setClearOnStart:!state];
}

- (IBAction) showHideTestAction:(id)sender
{
    NSRect aFrame = [NSWindow contentRectForFrameRect:[[self window] frame] 
											styleMask:[[self window] styleMask]];
    if([showHideTestButton state] == NSOnState)aFrame.size.height = 453;
    else aFrame.size.height = 370;
    [self resizeWindowToSize:aFrame.size];
}

- (IBAction) pollNowAction:(id)sender
{
	[model readAllScalers];
}

@end

