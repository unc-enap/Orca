//-------------------------------------------------------------------------
//  ORSIS3820Controller.h
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
#import "ORSIS3820Controller.h"

@implementation ORSIS3820Controller

-(id)init
{
    self = [super initWithWindowNibName:@"SIS3820"];
    
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
                         name : ORSIS3820SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(moduleIDChanged:)
                         name : ORSIS3820ModelIDChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(countEnableMaskChanged:)
                         name : ORSIS3820ModelCountEnableMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(countersChanged:)
                         name : ORSIS3820CountersChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(lemoInModeChanged:)
                         name : ORSIS3820ModelLemoInModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enable25MHzPulsesChanged:)
                         name : ORSIS3820ModelEnable25MHzPulsesChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enableCounterTestModeChanged:)
                         name : ORSIS3820ModelEnableCounterTestModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(enableReferencePulserChanged:)
                         name : ORSIS3820ModelEnableReferencePulserChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(overFlowMaskChanged:)
                         name : ORSIS3820ModelOverFlowMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORSIS3820PollTimeChanged
						object: model];	
    [notifyCenter addObserver : self
                     selector : @selector(clearOnRunStartChanged:)
                         name : ORSIS3820ModelClearOnRunStartChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(syncWithRunChanged:)
                         name : ORSIS3820ModelSyncWithRunChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(isCountingChanged:)
                         name : ORSIS3820ModelIsCountingChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lemoOutModeChanged:)
                         name : ORSIS3820ModelLemoOutModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(invertLemoInChanged:)
                         name : ORSIS3820ModelInvertLemoInChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(invertLemoOutChanged:)
                         name : ORSIS3820ModelInvertLemoOutChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(shipAtRunEndOnlyChanged:)
                         name : ORSIS3820ModelShipAtRunEndOnlyChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(channelNameChanged:)
                         name : ORSIS3820ChannelNameChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(deadTimeRefChannelChanged:)
                         name : ORSIS3820ModelDeadTimeRefChannelChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(showDeadTimeChanged:)
                         name : ORSIS3820ModelShowDeadTimeChanged
						object: model];

}

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
	[self enableCounterTestModeChanged:nil];
	[self enableReferencePulserChanged:nil];
	[self overFlowMaskChanged:nil];
	[self pollTimeChanged:nil];
	[self clearOnRunStartChanged:nil];
	[self syncWithRunChanged:nil];
	[self isCountingChanged:nil];
	[self lemoOutModeChanged:nil];
	[self invertLemoInChanged:nil];
	[self invertLemoOutChanged:nil];
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

- (void) invertLemoOutChanged:(NSNotification*)aNote
{
	[invertLemoOutButton setIntValue: [model invertLemoOut]];
}

- (void) invertLemoInChanged:(NSNotification*)aNote
{
	[invertLemoInButton setIntValue: [model invertLemoIn]];
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
	uint32_t aMask = [model overFlowMask];
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

- (void) enableCounterTestModeChanged:(NSNotification*)aNote
{
	[enableCounterTestModeButton setIntValue: [model enableCounterTestMode]];
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
		s = [s stringByAppendingString:@"1->no function\n"];
		s = [s stringByAppendingString:@"2->no function\n"];
		s = [s stringByAppendingString:@"3->no function\n"];
		s = [s stringByAppendingString:@"4->no function\n"];
	}
	else if(theMode == 1){
		s = [s stringByAppendingString:@"1->ext next pulse\n"];
		s = [s stringByAppendingString:@"2->ext user bit 1\n"];
		s = [s stringByAppendingString:@"3->ext user bit 2\n"];
		s = [s stringByAppendingString:@"4->inhibite LNE\n"];
	}	
	else if(theMode == 2){
		s = [s stringByAppendingString:@"1->ext next pulse\n"];
		s = [s stringByAppendingString:@"2->ext user bit 1\n"];
		s = [s stringByAppendingString:@"3->inhibit counting\n"];
		s = [s stringByAppendingString:@"4->inhibite LNE\n"];
	}	
	else if(theMode == 3){
		s = [s stringByAppendingString:@"1->ext next pulse\n"];
		s = [s stringByAppendingString:@"2->ext user bit 1\n"];
		s = [s stringByAppendingString:@"3->ext user bit 2\n"];
		s = [s stringByAppendingString:@"4->inhibit counting\n"];
	}	
	else if(theMode == 4){
		s = [s stringByAppendingString:@"1->inhibit cnt chan 1-8\n"];
		s = [s stringByAppendingString:@"2->inhibit cnt chan 9-16\n"];
		s = [s stringByAppendingString:@"3->inhibit cnt chan 17-24\n"];
		s = [s stringByAppendingString:@"4->inhibit cnt chan 25-32\n"];
	}
	else {
		s = [s stringByAppendingString:@"1->no function\n"];
		s = [s stringByAppendingString:@"2->no function\n"];
		s = [s stringByAppendingString:@"3->no function\n"];
		s = [s stringByAppendingString:@"4->no function\n"];
	}
	
	[lemoInText setStringValue:s];
}
- (void) lemoOutModeChanged:(NSNotification*)aNote
{
	[lemoOutModePU selectItemAtIndex: [model lemoOutMode]];
	
	int theMode = [model lemoOutMode];
	NSString* s = @"";
	if(theMode == 0){
		s = [s stringByAppendingString:@"5->scaler mode\n"];
		s = [s stringByAppendingString:@"6->SDRAM empty\n"];
		s = [s stringByAppendingString:@"7->SDRAM threshold\n"];
		s = [s stringByAppendingString:@"8->user output\n"];
	}
	else if(theMode == 1){
		s = [s stringByAppendingString:@"5->scaler mode\n"];
		s = [s stringByAppendingString:@"6->enabled\n"];
		s = [s stringByAppendingString:@"7->50MHz\n"];
		s = [s stringByAppendingString:@"8->user output\n"];
	}	
	
	[lemoOutText setStringValue:s];
}



- (void) moduleIDChanged:(NSNotification*)aNote
{
	unsigned short moduleID = [model moduleID];
	if(moduleID) {
		NSString* type = @"(Unsupported)";
		if([model majorRevision] == 1)type = @"Generic Scaler";
		[moduleIDField setStringValue:[NSString stringWithFormat:@"%x %@",moduleID,type]];
	}
	else		 [moduleIDField setStringValue:@"---"];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORSIS3820SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORSIS3820SettingsLock];
    BOOL locked = [gSecurity isLocked:ORSIS3820SettingsLock];
    
    [settingLockButton		setState: locked];
    [addressText			setEnabled:!locked && !runInProgress];
    [initButton				setEnabled:!lockedOrRunningMaintenance];
	
    [pollTimePU				setEnabled:!lockedOrRunningMaintenance];
    [syncWithRunButton		setEnabled:!locked && !runInProgress];
    [clearOnRunStartButton	setEnabled:!locked && !runInProgress];
    [lemoInModePU			setEnabled:!lockedOrRunningMaintenance];
    [lemoOutModePU			setEnabled:!lockedOrRunningMaintenance];
	[invertLemoOutButton	setEnabled:!lockedOrRunningMaintenance];
	[invertLemoInButton		setEnabled:!lockedOrRunningMaintenance];
	[enableReferencePulserButton setEnabled:!locked && !runInProgress];
    [enableCounterTestModeButton	 setEnabled:!locked && !runInProgress];
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
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3820 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"SIS3820 Card (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
    [addressText setIntegerValue: [model baseAddress]];
}

- (void) countEnableMaskChanged:(NSNotification*)aNote
{
	short i;
	uint32_t theMask = [model countEnableMask];
	
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
		uint32_t refCounts = [model counts:refChan];
		for(i=0;i<16;i++){
			if(i == refChan) [[countMatrix0  cellWithTag:i] setStringValue: @"Reference"];
			else {
				if(refCounts){
					uint32_t theCounts = [model counts:i];
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
					uint32_t theCounts = [model counts:i];
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

- (void) invertLemoOutAction:(id)sender
{
	[model setInvertLemoOut:[sender intValue]];	
}

- (void) invertLemoInAction:(id)sender
{
	[model setInvertLemoIn:[sender intValue]];	
}

- (void) lemoOutModeAction:(id)sender
{
	[model setLemoOutMode:(int)[sender indexOfSelectedItem]];	
}
- (void) syncWithRunAction:(id)sender
{
	[model setSyncWithRun:[sender intValue]];	
}

- (void) clearOnRunStartAction:(id)sender
{
	[model setClearOnRunStart:[sender intValue]];	
}

- (IBAction) enableReferencePulserAction:(id)sender
{
	[model setEnableReferencePulser:[sender intValue]];	
}

- (IBAction) enableCounterTestModeAction:(id)sender
{
	[model setEnableCounterTestMode:[sender intValue]];	
}

- (IBAction) enable25MHzPulsesAction:(id)sender
{
	[model setEnable25MHzPulses:[sender intValue]];	
}

- (IBAction) lemoInModeAction:(id)sender
{
	[model setLemoInMode:(int)[sender indexOfSelectedItem]];
}

- (IBAction) countEnableMask1Action:(id)sender
{
	[model setCountEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) countEnableMask2Action:(id)sender
{
	NSLog(@"--- %d\n",[[sender selectedCell] tag]);
	[model setCountEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) countEnableMask3Action:(id)sender
{
	[model setCountEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) countEnableMask4Action:(id)sender
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
	uint32_t aMask = [model countEnableMask];
	switch ([sender tag]) {
		case 0: aMask |= 0x0000ffff; break;
		case 1: aMask |= 0xffff0000; break;
	}
	[model setCountEnableMask:aMask];
}

- (IBAction) disableAllInGroup:(id)sender
{
	uint32_t aMask = [model countEnableMask];
	switch ([sender tag]) {
		case 0: aMask &= ~0x0000ffff; break;
		case 1: aMask &= ~0xffff0000; break;
	}
	[model setCountEnableMask:aMask];
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORSIS3820SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) initBoard:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];		//initialize and load hardward
        NSLog(@"Initialized SIS3820 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Init of SIS3820 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3820 Init", @"OK", nil, nil,
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
        NSLog(@"Reset SIS3820 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset of SIS3820 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3820 Reset", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readNoClear:(id)sender
{
    @try {
		[model readCounts:NO];
    }
	@catch(NSException* localException) {
        NSLog(@"Read Scalers of SIS3820 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3820 Read No Clear", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readAndClear:(id)sender
{
    @try {
		[model readCounts:YES];
    }
	@catch(NSException* localException) {
        NSLog(@"Read Scalers of SIS3820 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3820 Read And clear", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) clearAll:(id)sender;
{
    @try {
		[model clearAll];
    }
	@catch(NSException* localException) {
        NSLog(@"Clear Scalers of SIS3820 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3820 Clear", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) clearAllOverFlowFlags:(id)sender;
{
    @try {
		[model clearAllOverFlowFlags];
    }
	@catch(NSException* localException) {
        NSLog(@"Clear Overflow of SIS3820 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3820 Clear Overflow", @"OK", nil, nil,
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
        NSLog(@"Start Counting of SIS3820 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3820 Start", @"OK", nil, nil,
                        localException);
    }
	
}

- (IBAction) stopAction:(id)sender
{
	@try {
		[model stopCounting];
    }
	@catch(NSException* localException) {
        NSLog(@"Stop Counting of SIS3820 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed SIS3820 Stop", @"OK", nil, nil,
                        localException);
    }
	
}
- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:(int)[sender indexOfSelectedItem]];
}

- (IBAction) channelNameAction:(id)sender
{
	[model setChannel:(int)[[sender selectedCell] tag] name:[[sender selectedCell] stringValue]];
}

@end
