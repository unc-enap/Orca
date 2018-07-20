/*
 *  OR2228AController.cpp
 *  Orca
 *
 *  Created by Mark Howe on 6/30/05.
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
#import "OR2228AController.h"
#import "ORCamacExceptions.h"
#import "ORCamacExceptions.h"

#pragma mark ¥¥¥Macros


// methods
@implementation OR2228AController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"2228A"];
	
    return self;
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
                         name : OR2228ASettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(onlineMaskChanged:)
                         name : OR2228AOnlineMaskChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(suppressZerosChanged:)
                         name : OR2228ASuppressZerosChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(overflowCheckTimeChanged:)
                         name : OR2228AModelOverFlowCheckTimeChanged
                       object : model];
	
    
}

#pragma mark ¥¥¥Interface Management

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self onlineMaskChanged:nil];
    [self settingsLockChanged:nil];
	[self suppressZerosChanged:nil];
	[self overflowCheckTimeChanged:nil];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:OR2228ASettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:OR2228ASettingsLock];
    BOOL locked = [gSecurity isLocked:OR2228ASettingsLock];
	
    [settingLockButton setState: locked];
    [onlineMaskMatrix setEnabled:!lockedOrRunningMaintenance];
	
    [readNoResetButton setEnabled:!lockedOrRunningMaintenance];
    [readResetButton setEnabled:!lockedOrRunningMaintenance];
    [testLAMButton setEnabled:!lockedOrRunningMaintenance];
    [resetLAMButton setEnabled:!lockedOrRunningMaintenance];
    [generalResetButton setEnabled:!lockedOrRunningMaintenance];
    [disableLAMEnableLatchButton setEnabled:!lockedOrRunningMaintenance];
    [enableLAMEnableLatchButton setEnabled:!lockedOrRunningMaintenance];
    [testAllChansButton setEnabled:!lockedOrRunningMaintenance];
    [suppressZerosButton setEnabled:!lockedOrRunningMaintenance];
	[overFlowCheckTimeField setEnabled:!runInProgress];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:OR2228ASettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
	
}


- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"2228A (Station %d)",(int)[model stationNumber]]];
}

- (void) onlineMaskChanged:(NSNotification*)aNotification
{
	short i;
	unsigned char theMask = [model onlineMask];
	for(i=0;i<8;i++){
		BOOL bitSet = (theMask&(1<<i))>0;
		if(bitSet != [[onlineMaskMatrix cellWithTag:i] intValue]){
			[[onlineMaskMatrix cellWithTag:i] setState:bitSet];
		}			
	}
}

- (void) suppressZerosChanged:(NSNotification*)aNotification
{
	[suppressZerosButton setState:[model suppressZeros]];
}

- (void) overflowCheckTimeChanged:(NSNotification*)aNotification
{
	[overFlowCheckTimeField setIntValue:[model overFlowCheckTime]];
}


#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Actions
- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:OR2228ASettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) onlineAction:(id)sender
{
	if([sender intValue] != [model onlineMaskBit:(int)[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Online Mask"];
		[model setOnlineMaskBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) readNoResetAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model readNoReset];
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
		NSLog(@"2228A Test LAM for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Test LAM" fCode:8];
    }
}

- (IBAction) resetLAMAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model resetLAM];
        NSLog(@"2228A Reset LAM for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Reset LAM" fCode:10];
    }
}

- (IBAction) generalResetAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model generalReset];
        NSLog(@"2228A General Reset for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"General Reset" fCode:11];
    }
}

- (IBAction) disableLAMEnableLatchAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model disableLAMEnableLatch];
        NSLog(@"2228A Disable LAM enable latch for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Disable LAM enable latch" fCode:24];
    }
}

- (IBAction) enableLAMEnableLatchAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model enableLAMEnableLatch];
        NSLog(@"2228A Enable LAM enable latch for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Enable LAM enable latch" fCode:26];
    }
}

- (IBAction) testAllChansAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model testAllChannels];
        NSLog(@"2228A Test all channels for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Test All Channels" fCode:25];
    }
}

- (IBAction) suppressZerosAction:(id)sender
{
	[model setSuppressZeros:[sender state]];
}

- (IBAction) overflowCheckTimeAction:(id)sender
{
	[model setOverFlowCheckTime:[sender intValue]];
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
@end



