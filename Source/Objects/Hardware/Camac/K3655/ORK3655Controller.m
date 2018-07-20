/*
 *  ORK3655ModelController.cpp
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
#import "ORK3655Controller.h"
#import "ORCamacExceptions.h"
#import "ORCamacExceptions.h"
#import "ORValueBar.h"
#import "ORAxis.h"

#pragma mark ¥¥¥Macros

// methods
@implementation ORK3655Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"K3655"];
    
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
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
                         name : ORK3655SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(numberToSetChanged:)
                         name : ORK3655PulseNumberToSetChanged
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(numberToClearChanged:)
                         name : ORK3655PulseNumberToClearChanged
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(clockFreqChanged:)
                         name : ORK3655ClockFreqChanged
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(numChansChanged:)
                         name : ORK3655NumChansToUseChanged
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(continousChanged:)
                         name : ORK3655ContinousChanged
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(inhibitEnabledChanged:)
                         name : ORK3655InhibitEnabledChanged
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(useExtClockChanged:)
                         name : ORK3655UseExtClockChanged
                        object: nil];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(setPointsChanged:)
                         name : ORK3655SetPointsChangedNotification
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(setPointChanged:)
                         name : ORK3655SetPointChangedNotification
                        object: nil];
}

#pragma mark ¥¥¥Interface Management

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
	
    [self inhibitEnabledChanged:nil];
    [self continousChanged:nil];
    [self useExtClockChanged:nil];
    [self numChansChanged:nil];
    [self clockFreqChanged:nil];
    [self numberToClearChanged:nil];
    [self numberToSetChanged:nil];
    [self setPointsChanged:nil];
    [self settingsLockChanged:nil];
}


- (void) continousChanged:(NSNotification*)aNotification
{
	[continousButton setState:[model continous]];
}

- (void) inhibitEnabledChanged:(NSNotification*)aNotification
{
	[inhibitEnabledButton setState:[model inhibitEnabled]];
}

- (void) useExtClockChanged:(NSNotification*)aNotification
{
	[useExtClockButton setState:[model useExtClock]];
	[self settingsLockChanged:nil];
}

- (void) numChansChanged:(NSNotification*)aNotification
{
	[numChansField setIntValue:[model numChansToUse]];
	[self settingsLockChanged:nil];
}

- (void) enableSetPointFields
{
	//[setPointMatrix setEnabled:YES];
	int i;
	for(i=1;i<=8;i++){
		int chan = i-1;
		int numChans = [model numChansToUse];
		[[setPointMatrix cellWithTag:chan] setEnabled:i<=numChans?YES:NO];
		if(i>numChans){
			[[setPointMatrix cellWithTag:chan] setObjectValue:@"N/A"];
		}
		else {
			[[setPointMatrix cellWithTag:chan] setObjectValue:[NSNumber numberWithInt:[model setPoint:chan]]];
		}
	}
}

- (void) clockFreqChanged:(NSNotification*)aNotification
{
	[clockFreqField setIntValue:[model clockFreq]];
}

- (void) numberToClearChanged:(NSNotification*)aNotification
{
	[numberToClearField setIntValue:[model pulseNumberToClear]];
}

- (void) numberToSetChanged:(NSNotification*)aNotification
{
	[numberToSetField setIntValue:[model pulseNumberToSet]];		
}

- (void) setPointsChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<8;i++){
		[[setPointMatrix cellWithTag:i] setObjectValue:[NSNumber numberWithInt:[model setPoint:i]]];
	}
}

- (void) setPointChanged:(NSNotification*)aNotification
{
	int i = [[[aNotification userInfo] objectForKey:ORK3655Chan] intValue];
	[[setPointMatrix cellWithTag:i] setObjectValue:[NSNumber numberWithInt:[model setPoint:i]]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORK3655SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORK3655SettingsLock];
    BOOL locked = [gSecurity isLocked:ORK3655SettingsLock];
    
    [settingLockButton setState: locked];
	
	if(!lockedOrRunningMaintenance){
		[self enableSetPointFields];
	}
	else {
		[setPointMatrix setEnabled:NO];
	}
	
    [inhibitEnabledButton setEnabled:!lockedOrRunningMaintenance];
    [continousButton setEnabled:!lockedOrRunningMaintenance];
    [useExtClockButton setEnabled:!lockedOrRunningMaintenance];
	
	if([model useExtClock]){
		[clockFreqField setEnabled:NO];
	}
	else {
		[clockFreqField setEnabled:!lockedOrRunningMaintenance];
	}
	
	[numChansField setEnabled:!lockedOrRunningMaintenance];
	
	if([model inhibitEnabled]){
		[numberToClearField setEnabled:!lockedOrRunningMaintenance];
		[numberToSetField setEnabled:!lockedOrRunningMaintenance];
	}
	else {
		[numberToClearField setEnabled:NO];
		[numberToSetField setEnabled:NO];
	}
	
    [initButton setEnabled:!lockedOrRunningMaintenance];
    [testLAMButton setEnabled:!lockedOrRunningMaintenance];
    [clearLAMButton setEnabled:!lockedOrRunningMaintenance];
    [readSetPointButton setEnabled:!lockedOrRunningMaintenance];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORK3655SettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
    
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"K3655 Timing Gen (Station %d)",(int)[model stationNumber]]];
}


#pragma mark ¥¥¥Actions
- (IBAction) initAction:(id) sender
{
    @try {
		[self endEditing];
        [model initBoard];
        NSLog(@"K3655 Init for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Init Error" fCode:8];
    }
}


- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORK3655SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) testLAMAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model testLAM];
        NSLog(@"K3655 Test LAM for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Test LAM" fCode:8];
    }
}


- (IBAction) clearLAMAction:(id)sender
{
    @try {
        [model checkCratePower];
        [model clearLAM];
        NSLog(@"K3655 Clear LAM for Station %d\n",[model stationNumber]);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Enable LAM" fCode:26];
    }
}

- (IBAction) continousAction:(id)sender
{
	[model setContinous:[sender intValue]];
}

- (IBAction) inhibitEnabledAction:(id)sender
{
	[model setInhibitEnabled:[sender intValue]];
	[self settingsLockChanged:nil];
}


- (IBAction) useExtClockAction:(id)sender
{
	[model setUseExtClock:[sender intValue]];
}


- (IBAction) numChansAction:(id)sender
{
	[model setNumChansToUse:[sender intValue]];
}

- (IBAction) clockFreqAction:(id)sender
{
	[model setClockFreq:[sender intValue]];
}

- (IBAction) numberToClearAction:(id)sender
{
	[model setPulseNumberToClear:[sender intValue]];
}

- (IBAction) numberToSetAction:(id)sender
{
	[model setPulseNumberToSet:[sender intValue]];
}

- (IBAction) setPointAction:(id)sender
{
	[model setSetPoint:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) readSetPointAction:(id)sender
{
	@try {
		[model readSetPoints];
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Test LAM" fCode:8];
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

