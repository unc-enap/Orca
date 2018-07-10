//-------------------------------------------------------------------------
//  ORSIS3801Controller.h
//
//  Created by Mark A. Howe on Thursday 6/9/11.
//  Copyright (c) 2011 CENPA. University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "ORSIS3801Controller.h"

@implementation ORSIS3801Controller

-(id)init
{
    self = [super initWithWindowNibName:@"SIS3801"];
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) awakeFromNib
{
	short i;
	for(i=0;i<16;i++){	
		[[countEnableMatrix0 cellAtRow:i column:0] setTag:i];
		[[countEnableMatrix1 cellAtRow:i column:0] setTag:i+16];
		[[countMatrix0 cellAtRow:i column:0] setTag:i];
		[[countMatrix1 cellAtRow:i column:0] setTag:i+16];
		[[nameMatrix0 cellAtRow:i column:0] setEditable:YES];
		[[nameMatrix1 cellAtRow:i column:0] setEditable:YES];
		[[nameMatrix0 cellAtRow:i column:0] setTag:i];
		[[nameMatrix1 cellAtRow:i column:0] setTag:i+16];
		[[nameMatrix0 cellAtRow:i column:0] setFocusRingType:NSFocusRingTypeNone];
		[[nameMatrix1 cellAtRow:i column:0] setFocusRingType:NSFocusRingTypeNone];
		
	}
	
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
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORSIS3801SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(moduleIDChanged:)
                         name : ORSIS3801ModelIDChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(countEnableMaskChanged:)
                         name : ORSIS3801ModelCountEnableMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(countersChanged:)
                         name : ORSIS3801CountersChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(lemoInModeChanged:)
                         name : ORSIS3801ModelLemoInModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enable25MHzPulsesChanged:)
                         name : ORSIS3801ModelEnable25MHzPulsesChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enableInputTestModeChanged:)
                         name : ORSIS3801ModelEnableInputTestModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enableReferencePulserChanged:)
                         name : ORSIS3801ModelEnableReferencePulserChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(overFlowMaskChanged:)
                         name : ORSIS3801ModelOverFlowMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORSIS3801PollTimeChanged
						object: model];	
    [notifyCenter addObserver : self
                     selector : @selector(clearOnRunStartChanged:)
                         name : ORSIS3801ModelClearOnRunStartChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(syncWithRunChanged:)
                         name : ORSIS3801ModelSyncWithRunChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isCountingChanged:)
                         name : ORSIS3801ModelIsCountingChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(shipAtRunEndOnlyChanged:)
                         name : ORSIS3801ModelShipAtRunEndOnlyChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(channelNameChanged:)
                         name : ORSIS3801ChannelNameChanged
						object: model];	

	[notifyCenter addObserver : self
                     selector : @selector(deadTimeRefChannelChanged:)
                         name : ORSIS3801ModelDeadTimeRefChannelChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(showDeadTimeChanged:)
                         name : ORSIS3801ModelShowDeadTimeChanged
						object: model];}

- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self moduleIDChanged:nil];
	[self countEnableMaskChanged:nil];
	[self countersChanged:nil];
	[self lemoInModeChanged:nil];
	[self enable25MHzPulsesChanged:nil];
	[self enableInputTestModeChanged:nil];
	[self enableReferencePulserChanged:nil];
	[self overFlowMaskChanged:nil];
	[self pollTimeChanged:nil];
	[self clearOnRunStartChanged:nil];
	[self syncWithRunChanged:nil];
	[self isCountingChanged:nil];
	[self shipAtRunEndOnlyChanged:nil];
	[self channelNameChanged:nil];
	[self deadTimeRefChannelChanged:nil];
	[self showDeadTimeChanged:nil];
}

#pragma mark •••Interface Management
- (void) showDeadTimeChanged:(NSNotification*)aNote
{
	[showDeadTimeMatrix selectCellWithTag: [model showDeadTime]];
	[count0DisplayTypeTextField setStringValue:[model showDeadTime]?@"Live Time (%)":@"Counts"];
	[count1DisplayTypeTextField setStringValue:[model showDeadTime]?@"Live Time (%)":@"Counts"];
	[self countersChanged:nil];
}

- (void) deadTimeRefChannelChanged:(NSNotification*)aNote
{
	[deadTimeRefChannelField setIntValue: [model deadTimeRefChannel]];
	[self countersChanged:nil];
}

- (void) channelNameChanged:(NSNotification*)aNotification
{
	if(!aNotification){
		int i;
		for(i=0;i<16;i++){
			[[nameMatrix0 cellWithTag:i] setStringValue:[model channelName:i]];
			[[nameMatrix1 cellWithTag:i+16] setStringValue:[model channelName:i+16]];
		}
	}
	else {
		int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		if(chan<16){
			[[nameMatrix0 cellWithTag:chan] setStringValue:[model channelName:chan]];
		}
		else {
			[[nameMatrix1 cellWithTag:chan] setStringValue:[model channelName:chan]];
		}
	}
}

- (void) updatePollDescription
{
	if([model shipAtRunEndOnly]) [pollDescriptionTextField setStringValue:@"Data shipped at run end ONLY"];
	else						 [pollDescriptionTextField setStringValue:@"Data shipped at every poll"];
}

- (void) shipAtRunEndOnlyChanged:(NSNotification*)aNote
{
	[shipAtRunEndOnlyCB setIntValue: [model shipAtRunEndOnly]];
	[self updatePollDescription];
}

- (void) isCountingChanged:(NSNotification*)aNote
{
	[statusText setStringValue: [model isCounting]?@"Counting":@"NOT Counting"];
}

- (void) syncWithRunChanged:(NSNotification*)aNote
{
	[syncWithRunButton setIntValue: [model syncWithRun]];
}

- (void) clearOnRunStartChanged:(NSNotification*)aNote
{
	[clearOnRunStartButton setIntValue: [model clearOnRunStart]];
}

- (void) overFlowMaskChanged:(NSNotification*)aNote
{
	NSColor* red = [NSColor colorWithCalibratedRed:.8 green:0 blue:0 alpha:1];
	unsigned long aMask = [model overFlowMask];
	int i;
	for(i=0;i<16;i++){
		if(aMask & (0x00000001<<i))	[[countMatrix0 cellWithTag:i] setTextColor:red];
		else						[[countMatrix0 cellWithTag:i] setTextColor:[NSColor blackColor]];
		
		if(aMask & (0x00010000<<i))	[[countMatrix1 cellWithTag:i+16] setTextColor:red];
		else						[[countMatrix1 cellWithTag:i+16] setTextColor:[NSColor blackColor]];
	}
}

- (void) pollTimeChanged:(NSNotification*)aNote
{
	[pollTimePU selectItemAtIndex: [model pollTime]];
}

- (void) enableReferencePulserChanged:(NSNotification*)aNote
{
	[enableReferencePulserButton setIntValue: [model enableReferencePulser]];
}

- (void) enableInputTestModeChanged:(NSNotification*)aNote
{
	[enableInputTestModeButton setIntValue: [model enableInputTestMode]];
}

- (void) enable25MHzPulsesChanged:(NSNotification*)aNote
{
	[enable25MHzPulsesButton setIntValue: [model enable25MHzPulses]];
}

- (void) lemoInModeChanged:(NSNotification*)aNote
{
	[lemoInModePU selectItemAtIndex: [model lemoInMode]];
	
	int theMode = [model lemoInMode];
	NSString* s = @"";
	if(theMode == 0){
		s = [s stringByAppendingString:@"1->external next pulse\n"];
		s = [s stringByAppendingString:@"2->external user bit 1\n"];
		s = [s stringByAppendingString:@"3->external user bit 2\n"];
		s = [s stringByAppendingString:@"4->reset\n"];
	}
	else if(theMode == 1){
		s = [s stringByAppendingString:@"1->external next pulse\n"];
		s = [s stringByAppendingString:@"2->external user bit 1\n"];
		s = [s stringByAppendingString:@"3->disable counting\n"];
		s = [s stringByAppendingString:@"4->reset\n"];
	}	
	else if(theMode == 2){
		s = [s stringByAppendingString:@"1->external next pulse\n"];
		s = [s stringByAppendingString:@"2->external user bit 1\n"];
		s = [s stringByAppendingString:@"3->external user bit 2\n"];
		s = [s stringByAppendingString:@"4->disable counting\n"];
	}
	else if(theMode == 3){
		s = [s stringByAppendingString:@"4->external test\n"];
	}
	
	[lemoInText setStringValue:s];
}

- (void) moduleIDChanged:(NSNotification*)aNote
{
	unsigned short moduleID = [model moduleID];
	if(moduleID) [moduleIDField setStringValue:[NSString stringWithFormat:@"%x",moduleID]];
	else		 [moduleIDField setStringValue:@"---"];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORSIS3801SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSIS3801SettingsLock];
    BOOL locked = [gSecurity isLocked:ORSIS3801SettingsLock];
    
    [settingLockButton		setState: locked];
    [addressText			setEnabled:!locked && !runInProgress];
    [initButton				setEnabled:!lockedOrRunningMaintenance];
	
    [pollTimePU				setEnabled:!lockedOrRunningMaintenance];
    [syncWithRunButton		setEnabled:!locked && !runInProgress];
    [clearOnRunStartButton	setEnabled:!locked && !runInProgress];
    [lemoInModePU			setEnabled:!lockedOrRunningMaintenance];
	[enableReferencePulserButton setEnabled:!locked && !runInProgress];
    [enableInputTestModeButton	 setEnabled:!locked && !runInProgress];
    [enable25MHzPulsesButton	 setEnabled:!locked && !runInProgress];
	
    [countEnableMatrix0	 setEnabled:!locked && !runInProgress];
    [countEnableMatrix1	 setEnabled:!locked && !runInProgress];
	
    [enableAllInGroupButton0	setEnabled:!locked && !runInProgress];
    [enableAllInGroupButton1	setEnabled:!locked && !runInProgress];
	
	[disableAllInGroupButton0	 setEnabled:!locked && !runInProgress];
    [disableAllInGroupButton1	 setEnabled:!locked && !runInProgress];
	
    [disableAllButton	 setEnabled:!locked && !runInProgress];
    [enableAllButton	 setEnabled:!locked && !runInProgress];
	
	[clearAllButton			setEnabled:!lockedOrRunningMaintenance];
	[startCountingButton	setEnabled:!lockedOrRunningMaintenance];
	[stopCountingButton		setEnabled:!lockedOrRunningMaintenance];
	[readAndClearButton		setEnabled:!lockedOrRunningMaintenance];
	[readNow				setEnabled:!lockedOrRunningMaintenance];
	[probeButton			setEnabled:!lockedOrRunningMaintenance];
	[clearOverFlowButton	setEnabled:!lockedOrRunningMaintenance];
	[resetButton			setEnabled:!locked && !runInProgress];
	[shipAtRunEndOnlyCB		setEnabled:!locked && !runInProgress];
	[deadTimeRefChannelField setEnabled:!locked && !runInProgress];
}


- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3801 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3801 Card (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
    [addressText setIntValue: [model baseAddress]];
}

- (void) countEnableMaskChanged:(NSNotification*)aNote
{
	short i;
	unsigned long theMask = [model countEnableMask];

	for(i=0;i<32;i++){
		BOOL bitSet = (theMask&(1L<<i))>0;
		if(i>=0 && i<16)		[[countEnableMatrix0 cellWithTag:i] setState:bitSet];
		else if(i>=16 && i<32)	[[countEnableMatrix1 cellWithTag:i] setState:bitSet];
	}	
}
- (void) countersChanged:(NSNotification*)aNote
{
	short i;	
	if([model showDeadTime]){
		int refChan = [model deadTimeRefChannel];
		unsigned long refCounts = [model counts:refChan];
		for(i=0;i<16;i++){
			if(i == refChan) [[countMatrix0  cellWithTag:i] setStringValue: @"Reference"];
			else {
				if(refCounts){
					unsigned long theCounts = [model counts:i];
					double liveTime = 100.0 *(theCounts/(double)refCounts);
					[[countMatrix0  cellWithTag:i] setStringValue:[NSString stringWithFormat:@"%.6f",liveTime]];
				}
				else [[countMatrix0  cellWithTag:i] setStringValue:@"?"];
				
			}
		}
		for(i=16;i<32;i++){
			if(i == refChan) [[countMatrix1  cellWithTag:i] setStringValue: @"Reference"];
			else {
				if(refCounts){
					unsigned long theCounts = [model counts:i];
					double liveTime = 100.0 *(theCounts/(double)refCounts);
					[[countMatrix1  cellWithTag:i] setStringValue:[NSString stringWithFormat:@"%.6f",liveTime]];
				}
				else [[countMatrix1  cellWithTag:i] setStringValue:@"?"];
				
			}
		}
	}
	else {
		for(i=0;i<16;i++)	[[countMatrix0  cellWithTag:i] setDoubleValue:[model counts:i]];
		for(i=16;i<32;i++)	[[countMatrix1  cellWithTag:i] setDoubleValue:[model counts:i]];
	}
}

#pragma mark •••Actions
- (IBAction) showDeadTimeAction:(id)sender
{
	[model setShowDeadTime:[[sender selectedCell]tag]];	
}

- (IBAction) deadTimeRefChannelAction:(id)sender
{
	[model setDeadTimeRefChannel:[sender intValue]];	
}

- (IBAction) shipAtRunEndOnlyAction:(id)sender
{
	[model setShipAtRunEndOnly:[sender intValue]];	
}
- (IBAction) syncWithRunAction:(id)sender
{
	[model setSyncWithRun:[sender intValue]];	
}

- (IBAction) clearOnRunStartAction:(id)sender
{
	[model setClearOnRunStart:[sender intValue]];	
}

- (IBAction) enableReferencePulserAction:(id)sender
{
	[model setEnableReferencePulser:[sender intValue]];	
}

- (IBAction) enableInputTestModeAction:(id)sender
{
	[model setEnableInputTestMode:[sender intValue]];	
}

- (IBAction) enable25MHzPulsesAction:(id)sender
{
	[model setEnable25MHzPulses:[sender intValue]];	
}

- (IBAction) lemoInModeAction:(id)sender
{
	[model setLemoInMode:[sender indexOfSelectedItem]];	
}

- (IBAction) countEnableMask1Action:(id)sender
{
	[model setCountEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) countEnableMask2Action:(id)sender
{
	[model setCountEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) probeBoardAction:(id)sender;
{
	@try {
		[model readModuleID:YES];
	}
	@catch (NSException* localException) {
		NSLog(@"Probe of SIS 3300 board ID failed\n");
	}
}

- (IBAction) baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) enableAll:(id)sender
{
	[model setCountEnableMask:0xFFFFFFFF];
}

- (IBAction) disableAll:(id)sender
{
	[model setCountEnableMask:0x00000000];
}

- (IBAction) enableAllInGroup:(id)sender
{
	unsigned long aMask = [model countEnableMask];
	switch ([sender tag]) {
		case 0: aMask |= 0x0000ffff; break;
		case 1: aMask |= 0xffff0000; break;
	}
	[model setCountEnableMask:aMask];
}

- (IBAction) disableAllInGroup:(id)sender
{
	unsigned long aMask = [model countEnableMask];
	switch ([sender tag]) {
		case 0: aMask &= ~0x0000ffff; break;
		case 1: aMask &= ~0xffff0000; break;
	}
	[model setCountEnableMask:aMask];
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORSIS3801SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) initBoard:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];		//initialize and load hardward
        NSLog(@"Initialized SIS3801 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Init of SIS3801 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed SIS3801 Init", @"OK", nil, nil,
                        localException);
    }
}
- (IBAction) dumpBoard:(id)sender
{
	[model dumpCounts];
}

- (IBAction) resetBoard:(id)sender
{
    @try {
        [self endEditing];
        [model reset];
        NSLog(@"Reset SIS3801 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset of SIS3801 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed SIS3801 Reset", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readNoClear:(id)sender
{
    @try {
		[model readCounts:NO];
    }
	@catch(NSException* localException) {
        NSLog(@"Read Scalers of SIS3801 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed SIS3801 Read No Clear", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readAndClear:(id)sender
{
    @try {
		[model readCounts:YES];
    }
	@catch(NSException* localException) {
        NSLog(@"Read Scalers of SIS3801 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed SIS3801 Read And clear", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) clearAll:(id)sender;
{
    @try {
		[model clearAll];
    }
	@catch(NSException* localException) {
        NSLog(@"Clear Scalers of SIS3801 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed SIS3801 Clear", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) startAction:(id)sender
{
	@try {
		[model initBoard];
		[model startCounting];
    }
	@catch(NSException* localException) {
        NSLog(@"Start Counting of SIS3801 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed SIS3801 Start", @"OK", nil, nil,
                        localException);
    }
	
}

- (IBAction) stopAction:(id)sender
{
	@try {
		[model stopCounting];
    }
	@catch(NSException* localException) {
        NSLog(@"Stop Counting of SIS3801 FAILED.\n");
        NSRunAlertPanel([localException name], @"%@\nFailed SIS3801 Stop", @"OK", nil, nil,
                        localException);
    }
	
}
- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:[sender indexOfSelectedItem]];
}

- (IBAction) channelNameAction:(id)sender
{
	[model setChannel:[[sender selectedCell] tag] name:[[sender selectedCell] stringValue]];
}


@end
