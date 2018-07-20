/*
 *  ORAD811ModelController.cpp
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
#import "ORAD811Controller.h"
#import "ORCamacExceptions.h"
#import "ORCamacExceptions.h"

#pragma mark ¥¥¥Macros


// methods
@implementation ORAD811Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"AD811"];
	
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
						 name : ORAD811SettingsLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(onlineMaskChanged:)
						 name : ORAD811OnlineMaskChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(suppressZerosChanged:)
						 name : ORAD811SuppressZerosChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(includeTimingChanged:)
						 name : ORAD811ModelIncludeTimingChanged
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
	[self includeTimingChanged:nil];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORAD811SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORAD811SettingsLock];
    BOOL locked = [gSecurity isLocked:ORAD811SettingsLock];
	
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
    [testBusyButton setEnabled:!lockedOrRunningMaintenance];
    [suppressZerosButton setEnabled:!lockedOrRunningMaintenance];
	[includeTimingButton setEnabled:!runInProgress];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORAD811SettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
	
}


- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"AD811 (Station %d)",(int)[model stationNumber]]];
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

- (void) includeTimingChanged:(NSNotification*)aNotification
{
	[includeTimingButton setState:[model includeTiming]];
}


#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Actions
- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORAD811SettingsLock to:[sender intValue] forWindow:[self window]];
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
		NSLog(@"AD811 Test LAM for Station %d\n",[model stationNumber]);
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
        NSLog(@"AD811 Reset LAM for Station %d\n",[model stationNumber]);
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
        NSLog(@"AD811 General Reset for Station %d\n",[model stationNumber]);
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
        NSLog(@"AD811 Disable LAM enable latch for Station %d\n",[model stationNumber]);
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
        NSLog(@"AD811 Enable LAM enable latch for Station %d\n",[model stationNumber]);
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
        NSLog(@"AD811 Test all channels for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Test All Channels" fCode:25];
    }
}

- (IBAction) testBusyAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model testBusy];
        NSLog(@"AD811 Test busy for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Test busy" fCode:27];
    }
}

- (IBAction) suppressZerosAction:(id)sender
{
	[model setSuppressZeros:[sender state]];
}

- (IBAction) includeTimingAction:(id)sender
{
	[model setIncludeTiming:[sender state]];
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



