//
//  OR4ChanController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 16 2002.
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


#import "OR4ChanTriggerController.h"
#import "OR4ChanTriggerModel.h"

@implementation OR4ChanTriggerController

-(id)init
{
    self = [super initWithWindowNibName:@"4ChanTrigger"];
	
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    NSString* key = [NSString stringWithFormat: @"orca.4ChanTrigger%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
}

#pragma mark ¥¥¥Notifications
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
                     selector : @selector(lowerClockChanged:)
                         name : OR4ChanLowerClockChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(upperClockChanged:)
                         name : OR4ChanUpperClockChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(shipClockChanged:)
                         name : OR4ChanShipClockChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(errorCountChanged:)
                         name : OR4ChanErrorCountChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(triggerNameChanged:)
                         name : OR4ChanNameChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : OR4ChanSettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(specialLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(specialLockChanged:)
                         name : OR4ChanSpecialLock
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(enableClockChanged:)
                         name : OR4ChanEnableClockChangedNotification
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(shipFirstLastChanged:)
                         name : OR4ChanTriggerModelShipFirstLastChanged
						object: model];

}

#pragma mark ¥¥¥Interface Management

- (void) shipFirstLastChanged:(NSNotification*)aNote
{
	[shipFirstLastButton setIntValue: [model shipFirstLast]];
}
- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self lowerClockChanged:nil];
    [self upperClockChanged:nil];
    [self errorCountChanged:nil];
    [self triggerNameChanged:nil];
    [self settingsLockChanged:nil];
    [self specialLockChanged:nil];
    [self enableClockChanged:nil];
	
    [self updateClockMask];
	[self shipFirstLastChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:OR4ChanSettingsLock to:secure];
    [gSecurity setLock:OR4ChanSpecialLock to:secure];
    [settingLockButton setEnabled:secure];
    [specialLockButton setEnabled:secure];
}


- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    NSString* key = [NSString stringWithFormat: @"orca.OR4Chan%d.selectedtab",[model slot]];
    int index = (int)[tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}


- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:OR4ChanSettingsLock];
    BOOL locked = [gSecurity isLocked:OR4ChanSettingsLock];
	
    [settingLockButton setState: locked];
    [addressStepper setEnabled:!locked && !runInProgress];
    [addressText setEnabled:!locked && !runInProgress];
	
    [resetRegistersButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [resetClockButtonPage1 setEnabled:!locked && !lockedOrRunningMaintenance];
    [boardIDButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [getStatusButton setEnabled:!locked && !lockedOrRunningMaintenance];
	
    [trigger1NameField setEnabled:!locked && !runInProgress];
    [trigger2NameField setEnabled:!locked && !runInProgress];
    [trigger3NameField setEnabled:!locked && !runInProgress];
    [trigger4NameField setEnabled:!locked && !runInProgress];

	[shipFirstLastButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [shipClockMatrix setEnabled:!locked && !lockedOrRunningMaintenance];
    [clockEnableButton setEnabled:!locked && !lockedOrRunningMaintenance];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:OR4ChanSettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
	
}

- (void) specialLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:OR4ChanSpecialLock];
    BOOL locked = [gSecurity isLocked:OR4ChanSpecialLock];
	
    [specialLockButton setState: locked];
	
    [loadLowerClockButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [loadUpperClockButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [resetClockButtonPage2 setEnabled:!locked && !lockedOrRunningMaintenance];
	
    [enableClockButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [disableClockButton setEnabled:!locked && !lockedOrRunningMaintenance];
	
	
    [lowerClockField setEnabled:!locked && !lockedOrRunningMaintenance];
    [upperClockField setEnabled:!locked && !lockedOrRunningMaintenance];
    [lowerClockStepper setEnabled:!locked && !lockedOrRunningMaintenance];
    [upperClockStepper setEnabled:!locked && !lockedOrRunningMaintenance];
	
    [readClocksButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [softLatchButton setEnabled:!locked && !lockedOrRunningMaintenance];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:OR4ChanSettingsLock])s = @"Not in Maintenance Run.";
    }
    [specialLockDocField setStringValue:s];
	
}

- (void) errorCountChanged:(NSNotification*)aNotification
{
	[errorField setIntValue:(int)[model errorCount]];
}

- (void) updateClockMask
{
	int i;
	for(i=0;i<5;i++){
		[[shipClockMatrix cellWithTag:i] setState:[model shipClock:i]];
	}
}

- (void) shipClockChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
	[[shipClockMatrix cellWithTag:chan] setState:[model shipClock:chan]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
}

- (void) baseAddressChanged:(NSNotification*)aNotification
{
	[addressText setIntegerValue: [model baseAddress]];
	[self updateStepper:addressStepper setting:[model baseAddress]];
}

- (void) lowerClockChanged:(NSNotification*)aNotification
{
	[lowerClockField setIntegerValue: [model lowerClock]];
	[self updateStepper:lowerClockStepper setting:[model lowerClock]];
}

- (void) upperClockChanged:(NSNotification*)aNotification
{
	[upperClockField setIntegerValue: [model upperClock]];
	[self updateStepper:upperClockStepper setting:[model upperClock]];
}

- (void) enableClockChanged:(NSNotification*)aNotification
{
	[clockEnableButton setState: [model enableClock]];
}

- (void) triggerNameChanged:(NSNotification*)aNotification
{
	[trigger1NameField setStringValue: [model triggerName:0]];
	[trigger2NameField setStringValue: [model triggerName:1]];
	[trigger3NameField setStringValue: [model triggerName:2]];
	[trigger4NameField setStringValue: [model triggerName:3]];
}

#pragma mark ¥¥¥Actions

- (void) shipFirstLastAction:(id)sender
{
	[model setShipFirstLast:[sender intValue]];	
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:OR4ChanSettingsLock to:[sender intValue] forWindow:[self window]];
}
- (IBAction) specialLockAction:(id) sender
{
    [gSecurity tryToSetLock:OR4ChanSpecialLock to:[sender intValue] forWindow:[self window]];
}

-(IBAction)baseAddressAction:(id)sender
{
	if([sender intValue] != [model baseAddress]){
		[[self undoManager] setActionName: @"Set Base Address"];
		[model setBaseAddress:[sender intValue]];
	}
}


- (IBAction) lowerClockAction:(id)sender
{
	if([sender intValue] != [model lowerClock]){
		[[self undoManager] setActionName: @"Set Lower Clock"];
		[model setLowerClock:[sender intValue]];
	}	
}

- (IBAction) upperClockAction:(id)sender
{
	if([sender intValue] != [model upperClock]){
		[[self undoManager] setActionName: @"Set Upper Clock"];
		[model setUpperClock:[sender intValue]];
	}
}

- (IBAction) boardIDAction:(id)sender
{
    @try {
		NSLog(@"%@\n",[model boardIdString]);
		
    }
	@catch(NSException* localException) {
        NSLog(@"Read of Trigger Board ID FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nRead of Trigger Card Board ID FAILED", @"OK", nil, nil,
                        localException);
    }	
}

- (IBAction) statusReadAction:(id)sender
{
	@try {
        unsigned short status = [model readStatus];
		NSLog(@"---Trigger Board Status---\n");
        NSLog(@"Status Register : 0x%04x\n",status);
		NSLog(@"SoftLatch Event : %s\n",status&kEvent0Mask?"true":"false");
		NSLog(@"Trigger 1 Event : %s\n",status&kEvent1Mask?"true":"false");
		NSLog(@"Trigger 2 Event : %s\n",status&kEvent2Mask?"true":"false");
		NSLog(@"Trigger 3 Event : %s\n",status&kEvent3Mask?"true":"false");
		NSLog(@"Trigger 4 Event : %s\n",status&kEvent4Mask?"true":"false");
		NSLog(@"--------------------------\n");
		
		
    }
	@catch(NSException* localException) {
        NSLog(@"Read of Trigger Board Status FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nRead of Trigger Board Status FAILED", @"OK", nil, nil,
                        localException);
    }	
}

- (IBAction) resetAction:(id)sender
{
	@try {
        [model reset];
        NSLog(@"Trigger Board Reset\n");
		
    }
	@catch(NSException* localException) {
        NSLog(@"Reset of Trigger Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nReset of Trigger Board FAILED", @"OK", nil, nil,
                        localException);
    }	
}


- (IBAction) enableClockAction:(id)sender
{
    [model setEnableClock:[sender state]];
}

- (IBAction) writeEnableClockAction:(id)sender
{
	@try {
        [model writeEnableClock:YES];
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to enable Trigger 100MHz Clock: 0x%04x\n",[model lowerClock]);
		ORRunAlertPanel([localException name], @"%@\nFAILED to enable Trigger 100MHz Clock", @"OK", nil, nil,
						localException);
    }
}


- (IBAction) writeDisableClockAction:(id)sender
{
	@try {
        [model writeEnableClock:NO];
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to disable Trigger 100MHz Clock: 0x%04x\n",[model lowerClock]);
		ORRunAlertPanel([localException name], @"%@\nFAILED to disable Trigger 100MHz Clock", @"OK", nil, nil,
						localException);
    }
}

- (IBAction) loadLowerClockAction:(id)sender
{
	@try {
		[self endEditing];
		[model loadLowerClock:[model lowerClock]];
		NSLog(@"Loaded Trigger Lower 100MHz Clock: 0x%04x\n",[model lowerClock]);
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to load Trigger Lower 100MHz Clock: 0x%04x\n",[model lowerClock]);
		ORRunAlertPanel([localException name], @"%@\nFAILED to load Trigger Lower 100MHz Clock: 0x%04lx", @"OK", nil, nil,
						localException,[model lowerClock]);
    }
}

- (IBAction) loadUpperClockAction:(id)sender
{
	@try {
		[self endEditing];
		[model loadUpperClock:[model upperClock]];
		NSLog(@"Loaded Trigger Upper 100MHz Clock: 0x%04x\n",[model upperClock]);
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to load Trigger Upper 100MHz Clock: 0x%04x\n",[model upperClock]);
		ORRunAlertPanel([localException name], @"%@\nFAILED to load Trigger Upper 100MHz Clock: 0x%04lx", @"OK", nil, nil,
						localException,[model upperClock]);
    }	
}

- (IBAction) triggerNameAction:(id)sender
{
    [self endEditing];
    [model setTriggerName:[trigger1NameField stringValue] index:0];
    [model setTriggerName:[trigger2NameField stringValue] index:1];
    [model setTriggerName:[trigger3NameField stringValue] index:2];
    [model setTriggerName:[trigger4NameField stringValue] index:3];
}

- (IBAction) shipClockAction:(id)sender
{
    int i;
    for(i=0;i<5;i++){
        [model setShipClock:i state:[[shipClockMatrix cellWithTag:i] state]];
    }
}

- (IBAction) softLatchAction:(id)sender
{
	@try {
		[model softLatch];
		NSLog(@"Trigger card soft Latch.\n");
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to send soft Latch to trigger card.\n");
		ORRunAlertPanel([localException name], @"%@\nSoft Latch FAILED\n", @"OK", nil, nil,
						localException);
    }	
}

- (IBAction) readClocksAction:(id)sender
{
	@try {
        int i;
        for(i=0;i<5;i++){
            uint64_t upper = [model readUpperClock:i];
            uint64_t lower = [model readLowerClock:i];
            uint64_t theValue = (upper<<32) | lower;
            NSLog(@"Clock Reg%d: %lld\n",i,theValue);
        }
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to read clocks.\n");
		ORRunAlertPanel([localException name], @"%@\nRead Clocks FAILED\n", @"OK", nil, nil,
						localException);
    }	
}

- (IBAction) resetClockAction:(id)sender
{
	@try {
        [model resetClock];
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to reset clock.\n");
		ORRunAlertPanel([localException name], @"%@\nReset Clock FAILED\n", @"OK", nil, nil,
						localException);
    }	
}


@end
