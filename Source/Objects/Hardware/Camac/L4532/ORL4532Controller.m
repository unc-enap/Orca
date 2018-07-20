/*
 *  ORL4532ModelController.cpp
 *  Orca
 *
 *  Created by Mark Howe on Fri Sept 29, 2006.
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
#import "ORL4532Controller.h"
#import "ORCamacExceptions.h"


// methods
@implementation ORL4532Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"L4532"];
	
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
                     selector : @selector(includeTimingChanged:)
                         name : ORL4532ModelIncludeTimingChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORL4532SettingsLock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(numberTriggersChanged:)
                         name : ORL4532ModelNumberTriggersChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(delayEnableMaskChanged:)
                         name : ORL4532ModelDelayEnableMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(triggerNamesChanged:)
                         name : ORL4532ModelTriggerNamesChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(delaysChanged:)
                         name : ORL4532ModelDelaysChanged
						object: model];
	
}

#pragma mark ¥¥¥Interface Management
- (void) delaysChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<16;i++){
		[[delays0_15 cellWithTag:i] setIntValue:[model delay:i]];
	}
	for(i=16;i<32;i++){
		[[delays16_31 cellWithTag:(i-16)] setIntValue:[model delay:i]];
	}
}

- (void) delayEnableMaskChanged:(NSNotification*)aNote
{
	short i;
	uint32_t theMask = [model delayEnableMask];
	for(i=0;i<16;i++){
		BOOL bitSet = (theMask&(1L<<i))>0;
		[[delayEnableMask0_15 cellWithTag:i] setState:bitSet];
	}
	for(i=16;i<32;i++){
		BOOL bitSet = (theMask&(1L<<i))>0;
		[[delayEnableMask16_31 cellWithTag:(i-16)] setState:bitSet];
	}
	[self checkDelaysInUseMessage];	
}

- (void) triggerNamesChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<16;i++){
		[[triggerNames0_15 cellWithTag:i] setStringValue:[model triggerName:i]];
	}
	for(i=16;i<32;i++){
		[[triggerNames16_31 cellWithTag:(i-16)] setStringValue:[model triggerName:i]];
	}
}

- (void) numberTriggersChanged:(NSNotification*)aNote
{
	[numberTriggersTextField setIntValue: [model numberTriggers]];
	[self enableMatrices];
	[self checkDelaysInUseMessage];
}

- (void) checkDelaysInUseMessage
{
	int i;
	uint32_t inUseMask = 0L;
	for(i=0 ; i<[model numberTriggers] ; i++){
		inUseMask |= (1L<<i);
	}
	if([model delayEnableMask] & inUseMask) [delayWarningField setStringValue:@"Delays Enabled"];
	else									[delayWarningField setStringValue:@"No Delays Enabled"];
}

- (void) enableMatrices
{
	int n = [model numberTriggers];
	int i;
	for(i=0;i<16;i++){
		[[triggerNames0_15 cellWithTag:i] setEnabled:i<n];
		[[delayEnableMask0_15 cellWithTag:i] setEnabled:i<n];
		[[delays0_15 cellWithTag:i] setEnabled:i<n];
	}
	for(i=16;i<32;i++){
		[[triggerNames16_31 cellWithTag:i-16] setEnabled:i<n];
		[[delayEnableMask16_31 cellWithTag:i-16] setEnabled:i<n];
		[[delays16_31 cellWithTag:i-16] setEnabled:i<n];
	}	
}



- (void) includeTimingChanged:(NSNotification*)aNote
{
	[includeTimingButton setState: [model includeTiming]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
	[self includeTimingChanged:nil];
	[self numberTriggersChanged:nil];
	[self delayEnableMaskChanged:nil];
	[self triggerNamesChanged:nil];
	[self delaysChanged:nil];
    [self settingsLockChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORL4532SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORL4532SettingsLock];
    BOOL locked = [gSecurity isLocked:ORL4532SettingsLock];
	
    [settingLockButton setState: locked];
	
    [includeTimingButton setEnabled:!lockedOrRunningMaintenance];
    [statusButton setEnabled:!lockedOrRunningMaintenance];
    [readInputsButton setEnabled:!lockedOrRunningMaintenance];
    [testLAMButton setEnabled:!lockedOrRunningMaintenance];
    [testLAMClearButton setEnabled:!lockedOrRunningMaintenance];
    [readInputsClearButton setEnabled:!lockedOrRunningMaintenance];
    [clearMemLAMButton setEnabled:!lockedOrRunningMaintenance];
    [numberTriggersTextField setEnabled:!lockedOrRunningMaintenance];
	
	[triggerNames0_15 setEnabled:!lockedOrRunningMaintenance];
	[triggerNames16_31 setEnabled:!lockedOrRunningMaintenance];
	[delayEnableMask0_15 setEnabled:!lockedOrRunningMaintenance];
	[delayEnableMask16_31 setEnabled:!lockedOrRunningMaintenance];
	[delays0_15 setEnabled:!lockedOrRunningMaintenance];
	[delays16_31 setEnabled:!lockedOrRunningMaintenance];
	
	[[triggerNames0_15 cellWithTag:13] setEnabled:NO];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORL4532SettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
	if(!lockedOrRunningMaintenance)[self enableMatrices];
	
}


- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"L4532 (Station %d)",(int)[model stationNumber]]];
}

#pragma mark ¥¥¥Actions

- (void) triggerNamesAction:(id)sender
{
	int offset;
	if(sender == triggerNames0_15)offset = 0;
	else offset = 16;
	[model setTrigger:(int)[[sender selectedCell] tag]+offset withName:[sender stringValue]];
}

- (void) delayEnableMaskAction:(id)sender
{
	int offset;
	if(sender == delayEnableMask0_15)offset = 0;
	else offset = 16;
	[model setDelayEnabledMaskBit:(int)[[(NSMatrix*)sender selectedCell] tag]+offset withValue:[sender intValue]];
}

- (void) delaysAction:(id)sender
{
	int offset;
	if(sender == delays0_15)offset = 0;
	else offset = 16;
	[model setDelay:(int)[[sender selectedCell] tag]+offset withValue:[sender intValue]];
}

- (void) numberTriggersAction:(id)sender
{
	[model setNumberTriggers:[sender intValue]];
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORL4532SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (void) includeTimingAction:(id)sender
{
	[model setIncludeTiming:[sender intValue]];	
}

- (IBAction) readInputsAction:(id)sender
{
    @try {
        [model checkCratePower];
        uint32_t pattern = [model readInputPattern];
		NSLog(@"L4532 (Station %d) Input Pattern = 0x%08x\n",[model stationNumber],pattern);		
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Read Input Pattern"];
    }
}

- (IBAction) readInputsAndClearAction:(id)sender
{
    @try {
        [model checkCratePower];
        uint32_t pattern = [model readInputPatternClearMemoryAndLAM];
		NSLog(@"L4532 (Station %d) Input Pattern = 0x%08x\n",[model stationNumber],pattern);		
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Read Input Pattern and Clear"];
    }
}

- (IBAction) testLAM:(id)sender
{
    @try {
        [model checkCratePower];
        BOOL state = [model testLAM];
		NSLog(@"L4532 (Station %d) LAM is %@\n",[model stationNumber],state?@"Set":@"NOT Set");		
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Test LAM"];
    }
}

- (IBAction) testClearLAM:(id)sender
{
    @try {
        [model checkCratePower];
        BOOL state = [model testAndClearLAM];
		NSLog(@"L4532 (Station %d) LAM is %@\n",[model stationNumber],state?@"Set":@"NOT Set");		
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Test LAM and Clear"];
    }
}

- (IBAction) clearMemoryAndLAM:(id)sender
{
    @try {
		[model checkCratePower];
		[model clearMemoryAndLAM];
		NSLog(@"L4532 (Station %d) Clear Memory and LAM\n",[model stationNumber]);		
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Clear Memory and LAM"];
    }
}

- (IBAction) readStatusRegisterAction:(id)sender
{
    @try {
        [model checkCratePower];
        unsigned short status = [model readStatusRegister];
		NSLog(@"L4532 (Station %d) Status Register = 0x%04x\n",[model stationNumber],status);
		NSLog(@"LAM         : %@\n",status&0x1?@"ON":@"OFF");
		NSLog(@"LAM Enabled : %@\n",status&0x2?@"ON":@"OFF");
		NSLog(@"MEM Enabled : %@\n",status&0x4?@"ON":@"OFF");
		NSLog(@"CLUSTER     : %@\n",status&0x8?@"ON":@"OFF");
		
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Read Status Register"];
    }
}

- (IBAction) showHideAction:(id)sender
{
    NSRect aFrame = [NSWindow contentRectForFrameRect:[[self window] frame] 
											styleMask:[[self window] styleMask]];
    if([showHideButton state] == NSOnState)aFrame.size.height = 680;
    else aFrame.size.height = 216;
    [self resizeWindowToSize:aFrame.size];
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
@end



