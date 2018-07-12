//
//  ORCaen260Controller.m
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

#import "ORCaen260Controller.h"
#import "ORCaen260Model.h"

@implementation ORCaen260Controller
-(id)init
{
    self = [super initWithWindowNibName:@"Caen260"];
	
    return self;
}

- (void) awakeFromNib
{
	int i;
	for(i=0;i<kNumCaen260Channels;i++){
		[[enabledMaskMatrix cellAtRow:i column:0] setTag:i];
		[[channelLabelMatrix cellAtRow:i column:0] setIntValue:i];
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
                         name : ORCaen260ModelEnabledMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(scalerValueChanged:)
                         name : ORCaen260ModelScalerValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollingStateChanged:)
                         name : ORCaen260ModelPollingStateChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(shipRecordsChanged:)
                         name : ORCaen260ModelShipRecordsChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(autoInhibitChanged:)
                         name : ORCaen260ModelAutoInhibitChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(allScalerValuesChanged:)
                         name : ORCaen260ModelAllScalerValuesChanged
						object: model];	

    [notifyCenter addObserver : self
                     selector : @selector(shipOnChangeChanged:)
                         name : ORCaen260ModelShipOnChangeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(channelForTriggeredShipChanged:)
                         name : ORCaen260ModelChannelForTriggeredShipChanged
						object: model];

}

#pragma mark •••Interface Management

- (void) channelForTriggeredShipChanged:(NSNotification*)aNote
{
	[channelForTriggeredShipField setIntValue: [model channelForTriggeredShip]];
}

- (void) shipOnChangeChanged:(NSNotification*)aNote
{
	[shipOnChangeCB setIntValue: [model shipOnChange]];
}

- (void) autoInhibitChanged:(NSNotification*)aNote
{
	[autoInhibitButton setIntValue: [model autoInhibit]];
}
- (void) enabledMaskChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kNumCaen260Channels;i++){
		[[enabledMaskMatrix cellWithTag:i] setIntValue:[model enabledMask] & (1<<i)];
	}
}

- (void) updateWindow
{
    [super updateWindow];
	[self enabledMaskChanged:nil];
	[self scalerValueChanged:nil];
	[self shipRecordsChanged:nil];
    [self pollingStateChanged:nil];
	[self autoInhibitChanged:nil];
	[self shipOnChangeChanged:nil];
	[self channelForTriggeredShipChanged:nil];
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
}

- (void) thresholdLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:[self thresholdLockName]];
    BOOL locked = [gSecurity isLocked:[self thresholdLockName]];
	
    [thresholdLockButton setState: locked];
    [enabledMaskMatrix setEnabled:!locked && !runInProgress];
    [setInhibitButton setEnabled:!locked && !runInProgress];
    
    [resetInhibitButton setEnabled:!lockedOrRunningMaintenance];
    [clearScalersButton setEnabled:!lockedOrRunningMaintenance];
    [clear1ScalersButton setEnabled:!lockedOrRunningMaintenance];
    [incScalersButton setEnabled:!lockedOrRunningMaintenance];
    [readScalersButton setEnabled:!lockedOrRunningMaintenance];
    [pollingButton setEnabled:!lockedOrRunningMaintenance];
    [shipRecordsButton setEnabled:!lockedOrRunningMaintenance];
	
    [channelForTriggeredShipField setEnabled:!lockedOrRunningMaintenance];
    [shipOnChangeCB setEnabled:!lockedOrRunningMaintenance];
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
	[[self window] setTitle:[NSString stringWithFormat:@"Caen260 Card (Slot %d)",[model slot]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"Caen260 Card (Slot %d)",[model slot]]];
}

- (void) allScalerValuesChanged:(NSNotification*)aNotification
{
	[self scalerValueChanged:nil];
}

- (void) scalerValueChanged:(NSNotification*)aNotification
{
	if(aNotification==nil){
		int i;
		for(i=0;i<kNumCaen260Channels;i++){
			[[scalerValueMatrix cellAtRow:i column:0] setIntegerValue:[model scalerValue:i]];
		}
	}
	else {
		int index = [[[aNotification userInfo]objectForKey:@"Channel"] intValue];
		if(index>=0 && index < kNumCaen260Channels){
			[[scalerValueMatrix cellAtRow:index column:0] setIntegerValue:[model scalerValue:index]];
		}
	}
}

#pragma mark •••Actions

- (void) channelForTriggeredShipAction:(id)sender
{
	[model setChannelForTriggeredShip:[sender intValue]];	
}

- (void) shipOnChangeAction:(id)sender
{
	[model setShipOnChange:[sender intValue]];	
}

- (void) autoInhibitAction:(id)sender
{
	[model setAutoInhibit:[sender intValue]];	
}

- (void) enabledMaskAction:(id)sender
{
	int i;
	unsigned short aMask = 0;
	for(i=0;i<kNumCaen260Channels;i++){
		int state = [[enabledMaskMatrix cellWithTag:i] intValue];
		if(state)aMask |= (1<<i);
	}
	[model setEnabledMask:aMask];	
}

- (IBAction)enableAllAction:(id)sender
{
	[model setEnabledMask:0xFFFF];
}

- (IBAction)disableAllAction:(id)sender
{
	[model setEnabledMask:0];
}

- (IBAction) setInhibitAction:(id)sender
{
	@try {
        [model setInhibit];
		NSLog(@"Set Inhibit on Caen260 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Set Inhibit of Caen260 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Caen260 Set Inhibit", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) resetInhibitAction:(id)sender
{
	@try {
        [model resetInhibit];
		NSLog(@"Reset Inhibit on Caen260 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset Inhibit of Caen260 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Caen260 reset Inhibit", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) clearScalers:(id)sender
{
	@try {
        [model clearScalers];
		NSLog(@"Clear Scalers on Caen260 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Clear Scalers of Caen260 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Caen260 Clear Scalers", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readScalers:(id)sender
{
	@try {
        [model readScalers];
		NSLog(@"Read Scalers on Caen260 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Read Scalers of Caen260 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Caen260 Read Scalers", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) incScalers:(id)sender
{
	@try {
        [model incScalers];
		NSLog(@"Inc Scalers on Caen260 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Inc Scalers of Caen260 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Caen260 Inc Scalers", @"OK", nil, nil,
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
    short	i;
	
    [registerAddressPopUp removeAllItems];
    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerAddressPopUp insertItemWithTitle:[model 
												   getRegisterName:i] 
										  atIndex:i];
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
		[self resizeWindowToSize:NSMakeSize(357,452)];
		[[self window] setContentView:tabView];
    }
	
    NSString* key = [NSString stringWithFormat: @"orca.ORCaenCard%d.selectedtab",[model slot]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}

@end
