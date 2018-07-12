//
//  ORCaen265Controller.m
//  Orca
//
//  Created by Mark Howe on 12/7/07
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nug Physics and 
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


#import "ORCaen265Controller.h"
#import "ORCaen265Model.h"


@implementation ORCaen265Controller

-(id)init
{
    self = [super initWithWindowNibName:@"Caen265"];
	
    return self;
}

- (void) awakeFromNib
{
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
						 name : ORCaen265SettingsLock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledMaskChanged:)
                         name : ORCaen265ModelEnabledMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(suppressZerosChanged:)
                         name : ORCaen265ModelSuppressZerosChanged
						object: model];
	
}

#pragma mark •••Interface Management

- (void) suppressZerosChanged:(NSNotification*)aNote
{
	[suppressZerosButton setIntValue: [model suppressZeros]];
}

- (void) enabledMaskChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kNumCaen265Channels;i++){
		[[enabledMaskMatrix cellWithTag:i] setIntValue:[model enabledMask] & (1<<i)];
	}
}

- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
	[self slotChanged:nil];
	[self settingsLockChanged:nil];
	[self enabledMaskChanged:nil];
	[self suppressZerosChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORCaen265SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORCaen265SettingsLock];
    BOOL locked = [gSecurity isLocked:ORCaen265SettingsLock];
	
    [settingLockButton setState: locked];
    [addressStepper setEnabled:!locked && !runInProgress];
    [addressText setEnabled:!locked && !runInProgress];
    
    [initButton setEnabled:!lockedOrRunningMaintenance];
    [suppressZerosButton setEnabled:!lockedOrRunningMaintenance];
    [enableAllButton setEnabled:!lockedOrRunningMaintenance];
    [disableAllButton setEnabled:!lockedOrRunningMaintenance];
    [triggerButton setEnabled:!lockedOrRunningMaintenance];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"Caen265 Card (Slot %d)",[model slot]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Caen265 Card (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNotification
{
	[self updateStepper:addressStepper setting:[model baseAddress]];
	[addressText setIntegerValue: [model baseAddress]];
}

#pragma mark •••Actions

- (void) suppressZerosAction:(id)sender
{
	[model setSuppressZeros:[sender intValue]];	
}

- (void) enabledMaskAction:(id)sender
{
	int i;
	unsigned short aMask = 0;
	for(i=0;i<kNumCaen265Channels;i++){
		int state = [[enabledMaskMatrix cellWithTag:i] intValue];
		if(state)aMask |= (1<<i);
	}
	[model setEnabledMask:aMask];	
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORCaen265SettingsLock to:[sender intValue] forWindow:[self window]];
}

-(IBAction)baseAddressAction:(id)sender
{
	if([sender intValue] != [model baseAddress]){
		[[self undoManager] setActionName: @"Set Base Address"];
		[model setBaseAddress:[sender intValue]];		
	}
}

- (IBAction)enableAllAction:(id)sender
{
	[model setEnabledMask:0xFFFF];
}

- (IBAction)disableAllAction:(id)sender
{
	[model setEnabledMask:0];
}


-(IBAction)initBoard:(id)sender
{
    @try {
		[self endEditing];
        [model reset];		//initialize and load hardward
		NSLog(@"Initialized Caen265 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset and Init of Caen265 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Caen265 Reset and Init", @"OK", nil, nil,
                        localException);
    }
}

-(IBAction) probeBoard:(id)sender
{
	[self endEditing];    
	@try {
		unsigned short fixedCode	= [model readFixedCode];
		NSLog(@"Probing CAEN V265,%d,%d\n",[model crateNumber],[model slot]);
		if(fixedCode == 0xFAF5){
			unsigned short boardID		= [model readBoardID];
			unsigned short boardVersion = [model readBoardVersion];
			NSLog(@"Board Manufacturer Code: 0x%x %@\n",boardID>>10,[model decodeManufacturerCode:boardID>>10]);
			NSLog(@"Board Module Code: 0x%x %@\n",boardID&0x3ff,[model decodeModuleCode:boardID&0x3ff]);
			NSLog(@"Board Series Number: 0x%x\n",boardVersion&0xfff);
			NSLog(@"Board Version: 0x%x (%@)\n",boardVersion>>12,boardVersion>>12 == 0?@"NIM":@"ECL");
		}
		else {
			NSLog(@"Fixed Code Readback == 0x%x (should have been 0xFAF5)\n",fixedCode);
		}
	}
	@catch(NSException* localException) {
        NSLog(@"Probe Caen265 Board FAILED.\n");
		ORRunAlertPanel([localException name], @"%@\nFailed Probe", @"OK", nil, nil,
						localException);
    }
}

- (IBAction) triggerAction:(id)sender
{
    @try {
        [model trigger];		//force trigger
		NSLog(@"Triggered Caen265 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Trigger of Caen265 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Caen265 Trigger", @"OK", nil, nil,
                        localException);
    }
	
}

@end
