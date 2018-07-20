/*
 *  ORAD3511ModelController.cpp
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


//**********************************************************************************
//------this is really for the 3512. The real 3511 is a single wide card without a buffer. 
//If we ever get a real 3511 this object will be renamed to be a 3512 and a 3511 object will be added.
//**********************************************************************************

#pragma mark ¥¥¥Imported Files
#import "ORAD3511Controller.h"
#import "ORCamacExceptions.h"
#import "ORCamacExceptions.h"
#import "ORTimedTextField.h"

#pragma mark ¥¥¥Macros


// methods
@implementation ORAD3511Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"AD3511"];
	
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
						 name : ORAD3511SettingsLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(enabledChanged:)
						 name : ORAD3511EnabledChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(gainChanged:)
						 name : ORAD3511GainChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(offsetChanged:)
						 name : ORAD3511StorageOffsetChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(includeTimingChanged:)
                         name : ORAD3511ModelIncludeTimingChanged
						object: model];
	
}

#pragma mark ¥¥¥Interface Management

- (void) includeTimingChanged:(NSNotification*)aNote
{
	[includeTimingButton setState: [model includeTiming]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self enabledChanged:nil];
	[self gainChanged:nil];
	[self offsetChanged:nil];
	[self includeTimingChanged:nil];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORAD3511SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORAD3511SettingsLock];
    BOOL locked = [gSecurity isLocked:ORAD3511SettingsLock];
	
    [settingLockButton setState: locked];
	
    [readButton setEnabled:!lockedOrRunningMaintenance];
    [testLAMButton setEnabled:!lockedOrRunningMaintenance];
    [resetLAMButton setEnabled:!lockedOrRunningMaintenance];
    [enabledButton setEnabled:!lockedOrRunningMaintenance];
    [initButton setEnabled:!lockedOrRunningMaintenance];
    [includeTimingButton setEnabled:!runInProgress];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORAD3511SettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
	
}


- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"AD3512 (Station %d)",(int)[model stationNumber]]];
}

- (void) enabledChanged:(NSNotification*)aNotification
{
	[enabledButton setState:[model enabled]];
}

- (void) gainChanged:(NSNotification*)aNotification
{
	[gainPopUp selectItemAtIndex:[model gain]];
}

- (void) offsetChanged:(NSNotification*)aNotification
{
	[offsetPopUp selectItemAtIndex:[model storageOffset]];
}


#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Actions

- (IBAction) includeTimingAction:(id)sender
{
	[model setIncludeTiming:[sender intValue]];	
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORAD3511SettingsLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) readAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model read];
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
		NSLog(@"AD3512 Test LAM for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Test LAM" fCode:8];
    }
}

- (IBAction) resetLAMAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model resetLAMandClearBuffer];
        NSLog(@"AD3512 Reset LAM and clear buffer for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Reset LAM/Clear buffer" fCode:10];
    }
}


- (IBAction) disableLAMAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model disableLAM];
        NSLog(@"AD3512 Disable LAM enable latch for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Disable LAM enable latch" fCode:24];
    }
}

- (IBAction) enableLAMAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model enableLAM];
        NSLog(@"AD3512 Enable LAM enable latch for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Enable LAM enable latch" fCode:26];
    }
}

- (IBAction) enabledAction:(id)sender
{
	[model setEnabled:[sender state]];
}

- (IBAction) gainAction:(id)sender
{
	[model setGain:[gainPopUp indexOfSelectedItem]];
}

- (IBAction) offsetAction:(id)sender
{
	[model setStorageOffset:[offsetPopUp indexOfSelectedItem]];
}
- (IBAction) initAction:(id)sender
{
    @try {
		[model initBoard];
		NSLog(@"Init AD3511 station:%d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Board Init" fCode:26];
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
@end



