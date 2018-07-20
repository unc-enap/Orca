//
//  ORCV830Controller.m
//  Orca
//
//  Created by Mark Howe on 06/06/2012
// Copyright (c) 2012 University of North Carolina. All rights reserved.
//
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina,or U.S. Government make any warranty,
//express or implied,or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORCV830Controller.h"
#import "ORCV830Model.h"

@implementation ORCV830Controller
-(id)init
{
    self = [super initWithWindowNibName:@"CV830"];
	
    return self;
}

- (void) awakeFromNib
{
	int i;
	for(i=0;i<kNumCV830Channels;i++){
		[[enabledMaskMatrix cellAtRow:i column:0] setTag:i];
		[[scalerValueMatrix cellAtRow:i column:0] setTag:i];
		[[channelLabelMatrix cellAtRow:i column:0] setIntValue:i];
		[[scalerValueMatrix cellAtRow:i column:0] setIntValue:0];
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
					 selector : @selector(basicLockChanged:)
						 name : [self basicLockName]
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledMaskChanged:)
                         name : ORCV830ModelEnabledMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(scalerValueChanged:)
                         name : ORCV830ModelScalerValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollingStateChanged:)
                         name : ORCV830ModelPollingStateChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(shipRecordsChanged:)
                         name : ORCV830ModelShipRecordsChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(allScalerValuesChanged:)
                         name : ORCV830ModelAllScalerValuesChanged
						object: model];	
    [notifyCenter addObserver : self
                     selector : @selector(dwellTimeChanged:)
                         name : ORCV830ModelDwellTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(acqModeChanged:)
                         name : ORCV830ModelAcqModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(testModeChanged:)
                         name : ORCV830ModelTestModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(clearMebChanged:)
                         name : ORCV830ModelClearMebChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(autoResetChanged:)
                         name : ORCV830ModelAutoResetChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(count0OffsetChanged:)
                         name : ORCV830ModelCount0OffsetChanged
						object: model];

}

#pragma mark •••Interface Management

- (void) count0OffsetChanged:(NSNotification*)aNote
{
	[count0OffsetField setIntegerValue: [model count0Offset]];
}

- (void) autoResetChanged:(NSNotification*)aNote
{
	[autoResetCB setIntValue: [model autoReset]];
}

- (void) clearMebChanged:(NSNotification*)aNote
{
	[clearMebCB setIntValue: [model clearMeb]];
}

- (void) testModeChanged:(NSNotification*)aNote
{
	[testModeCB setIntValue: [model testMode]];
}

- (void) acqModeChanged:(NSNotification*)aNote
{
	[acqModePU selectItemAtIndex: [model acqMode]];
	[self thresholdLockChanged:aNote];
}

- (void) dwellTimeChanged:(NSNotification*)aNote
{
	[dwellTimeField setIntegerValue: [model dwellTime]];
}

- (void) enabledMaskChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kNumCV830Channels;i++){
		[[enabledMaskMatrix cellWithTag:i] setIntegerValue:[model enabledMask] & (0x1L<<i)];
	}
}

- (void) updateWindow
{
    [super updateWindow];
	[self enabledMaskChanged:nil];
	[self scalerValueChanged:nil];
	[self shipRecordsChanged:nil];
    [self pollingStateChanged:nil];
	[self dwellTimeChanged:nil];
	[self acqModeChanged:nil];
	[self testModeChanged:nil];
	[self clearMebChanged:nil];
	[self autoResetChanged:nil];
	[self count0OffsetChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:[self basicLockName] to:secure];
    [gSecurity setLock:[self thresholdLockName] to:secure];
    [basicLockButton setEnabled:secure];
    [thresholdLockButton setEnabled:secure];
}

- (void) basicLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self basicLockName]];
    BOOL locked = [gSecurity isLocked:[self basicLockName]];
	
    [basicLockButton setState: locked];
    [addressStepper setEnabled:!locked && !runInProgress];
    [addressTextField setEnabled:!locked && !runInProgress];
    
    [enableAllButton setEnabled:!lockedOrRunningMaintenance];
    [disableAllButton setEnabled:!lockedOrRunningMaintenance];
    [basicReadButton setEnabled:!lockedOrRunningMaintenance];
    [basicWriteButton setEnabled:!lockedOrRunningMaintenance];
	[softwareClearButton setEnabled:!lockedOrRunningMaintenance];
	[softwareResetButton setEnabled:!lockedOrRunningMaintenance];
	[initHWButton setEnabled:!lockedOrRunningMaintenance];
}

- (void) thresholdLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self thresholdLockName]];
    BOOL locked = [gSecurity isLocked:[self thresholdLockName]];
	
    [thresholdLockButton setState: locked];
    [enabledMaskMatrix setEnabled:!locked && !runInProgress];
    
    [softwareClearButton setEnabled:!lockedOrRunningMaintenance];
    [readScalersButton setEnabled:!lockedOrRunningMaintenance];
    [pollingButton setEnabled:!lockedOrRunningMaintenance];
    [shipRecordsButton setEnabled:!lockedOrRunningMaintenance];
	[autoResetCB setEnabled:!lockedOrRunningMaintenance];
	[clearMebCB setEnabled:!lockedOrRunningMaintenance];
	[testModeCB setEnabled:!lockedOrRunningMaintenance];
	[acqModePU setEnabled:!lockedOrRunningMaintenance];
	[dwellTimeField setEnabled:!lockedOrRunningMaintenance && [model acqMode]==2];
    [softwareTriggerButton setEnabled:!lockedOrRunningMaintenance && [model acqMode]==1];
}

- (void) shipRecordsChanged:(NSNotification*)aNote
{
	[shipRecordsButton setIntValue: [model shipRecords]];
}

- (void) pollingStateChanged:(NSNotification*)aNotification
{
	[pollingButton selectItemAtIndex:[pollingButton indexOfItemWithTag:[model pollingState]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"CV830 Card (Slot %d)",[model slot]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"CV830 Card (Slot %d)",[model slot]]];
}

- (void) allScalerValuesChanged:(NSNotification*)aNotification
{
	[self scalerValueChanged:nil];
}

- (void) scalerValueChanged:(NSNotification*)aNotification
{
	if(aNotification==nil){
		int i;
		for(i=0;i<kNumCV830Channels;i++){
			[[scalerValueMatrix cellAtRow:i column:0] setDoubleValue:[model scalerValue:i]];
		}
	}
	else {
		int index = [[[aNotification userInfo]objectForKey:@"Channel"] intValue];
		if(index>=0 && index < kNumCV830Channels){
			[[scalerValueMatrix cellAtRow:index column:0] setDoubleValue:[model scalerValue:index]];
		}
	}
}

#pragma mark •••Actions

- (void) count0OffsetAction:(id)sender
{
	[model setCount0Offset:[sender intValue]];	
}

- (IBAction) autoResetAction:(id)sender
{
	[model setAutoReset:[sender intValue]];	
}

- (IBAction) clearMebAction:(id)sender
{
	[model setClearMeb:[sender intValue]];	
}

- (IBAction) testModeAction:(id)sender
{
	[model setTestMode:[sender intValue]];	
}

- (IBAction) acqModeAction:(id)sender
{
	[model setAcqMode:[sender indexOfSelectedItem]];	
}

- (IBAction) dwellTimeAction:(id)sender
{
	[model setDwellTime:[sender intValue]];	
}

- (IBAction) initHWAction:(id)sender
{
	[model initBoard];
}

- (IBAction) enabledMaskAction:(id)sender
{
	int i;
	uint32_t aMask = 0;
	for(i=0;i<kNumCV830Channels;i++){
		int state = [[enabledMaskMatrix cellWithTag:i] intValue];
		if(state)aMask |= (0x1L<<i);
	}
	[model setEnabledMask:aMask];	
}

- (IBAction)enableAllAction:(id)sender
{
	[model setEnabledMask:0xFFFFFFFF];
}

- (IBAction) disableAllAction:(id)sender
{
	[model setEnabledMask:0];
}

- (IBAction) softwareTriggerAction:(id)sender
{
	@try {
		NSLog(@"Software trigger on CV830 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
		[model softwareTrigger];
	}
	@catch(NSException* localException) {
        NSLog(@"Software trigger of CV830 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed CV830 Software Trigger", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) softwareClearAction:(id)sender
{
	@try {
		NSLog(@"Software clear on CV830 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
		[model softwareClear];
	}
	@catch(NSException* localException) {
        NSLog(@"Software clear of CV830 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed CV830 Software Clear", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) softwareResetAction:(id)sender
{
	@try {
		NSLog(@"Software reet on CV830 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
		[model softwareReset];
	}
	@catch(NSException* localException) {
        NSLog(@"Software reset of CV830 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed CV830 Software Reset", @"OK", nil, nil,
                        localException);
    }
}



- (IBAction) readScalers:(id)sender
{
	@try {
        [model readScalers];
		NSLog(@"Read Scalers on CV830 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
		int i;
		for(i=0;i<kNumCV830Channels;i++){
			if([model enabledMask] & (0x1L<<i)) NSLog(@"%d: %d\n",i,[model scalerValue:i]);
		}
    }
	@catch(NSException* localException) {
        NSLog(@"Read Scalers of CV830 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed CV830 Read Scalers", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readStatus:(id)sender
{
	@try {
        [model readStatus];
    }
	@catch(NSException* localException) {
        NSLog(@"Read Status of CV830 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed CV830 Read Status", @"OK", nil, nil,
                        localException);
    }
}


- (IBAction) shipRecordsAction:(id)sender
{
	[model setShipRecords:[sender intValue]];	
}

- (IBAction) setPollingAction:(id)sender
{
    [model setPollingState:(NSTimeInterval)[[sender selectedItem] tag]];
}

- (void) populatePullDown
{
    [registerAddressPopUp removeAllItems];
    
    short	i;
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerAddressPopUp insertItemWithTitle:[NSString stringWithFormat:@"%2d %@",i,[model getRegisterName:i]] atIndex:i];
    }
    
}
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:NSMakeSize(268,420)];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:NSMakeSize(357,648)];
		[[self window] setContentView:tabView];
    }
	
    NSString* key = [NSString stringWithFormat: @"orca.ORCaenCard%d.selectedtab",[model slot]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

@end
