/*
 *  ORAD413AModelController.cpp
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
#import "ORAD413AController.h"
#import "ORCamacExceptions.h"
#import "ORAD413AModel.h"

@implementation ORAD413AController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"AD413A"];
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
						 name : ORAD413ASettingsLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(onlineMaskChanged:)
						 name : ORAD413AOnlineMaskChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(controlReg1Changed:)
						 name : ORAD413AControlReg1ChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(controlReg2Changed:)
						 name : ORAD413AControlReg2ChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(discriminatorChanged:)
						 name : ORAD413ADiscriminatorChangedNotification
					   object : model];
	
}

#pragma mark ¥¥¥Interface Management

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self onlineMaskChanged:nil];
    [self settingsLockChanged:nil];
	[self discriminatorChanged:nil];
	[self controlReg1Changed:nil];
    [self controlReg2Changed:nil];
	
    int i;
    for(i=0;i<4;i++){
        [[discriminatorFieldMatrix cellWithTag:i] setIntValue:[model discriminatorForChan:i]];
    }
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORAD413ASettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORAD413ASettingsLock];
    BOOL locked = [gSecurity isLocked:ORAD413ASettingsLock];
	
    [settingLockButton setState: locked];
    [onlineMaskMatrix setEnabled:!lockedOrRunningMaintenance];
    [discriminatorFieldMatrix setEnabled:!lockedOrRunningMaintenance];
    [discriminatorStepperMatrix setEnabled:!lockedOrRunningMaintenance];
    [clearModuleButton setEnabled:!locked && !runInProgress];
    [controlReg1Matrix setEnabled:!locked && !runInProgress];
    [controlReg2Matrix setEnabled:!locked && !runInProgress];
    [writeControlReg1Button setEnabled:!locked && !runInProgress];
    [readControlReg1Button setEnabled:!lockedOrRunningMaintenance];
    [writeControlReg2Button setEnabled:!locked && !runInProgress];
    [readControlReg2Button setEnabled:!lockedOrRunningMaintenance];
	
}


- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"AD413A (Station %d)",(int)[model stationNumber]+1]];
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


- (void) discriminatorChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
	[[discriminatorFieldMatrix cellWithTag:chan] setIntValue:[model discriminatorForChan:chan]];
	[[discriminatorStepperMatrix cellWithTag:chan] setIntValue:[model discriminatorForChan:chan]];
}


- (void) controlReg1Changed:(NSNotification*)aNotification
{
    [[controlReg1Matrix cellWithTag:kZeroSuppressionBit] setState: [model zeroSuppressionMode]];
    [[controlReg1Matrix cellWithTag:kSinglesBit]		 setState: [model singles]];
    [[controlReg1Matrix cellWithTag:kRandomAccessBit]    setState: [model randomAccessMode]];
    [[controlReg1Matrix cellWithTag:kLAMEnableBit]       setState: [model lamEnable]];
    [[controlReg1Matrix cellWithTag:kOFSuppressionBit]   setState: [model ofSuppressionMode]];
	[CAMACEnabledField setStringValue: [model CAMACMode]?@"CAMAC":@"FERA"];
	[virtualStationField setIntValue:[model vsn]];
	if([model zeroSuppressionMode] && [model randomAccessMode]){
		[conflictField setStringValue:@"Random Access has precedence over zero suppression"];
	}
	else {
		[conflictField setStringValue:@""];
	}
}

- (void) controlReg2Changed:(NSNotification*)aNotification
{
	int bit;
	for(bit=0;bit<5;bit++){
		[[controlReg2Matrix cellWithTag:bit] setState: [model gateEnable:bit]];
	}
}

#pragma mark ¥¥¥Actions
- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORAD413ASettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) onlineAction:(id)sender
{
	if([sender intValue] != [model onlineMaskBit:(int)[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Online Mask"];
		[model setOnlineMaskBit:(int)[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) discriminatorAction:(id)sender
{
	if([sender intValue] != [model discriminatorForChan:(int)[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Discrininator"];
		[model setDiscriminator:[sender intValue] forChan:(int)[[sender selectedCell] tag]];
	}
}

- (IBAction) readDiscriminatorAction:(id)sender
{
    @try {
        [model readDiscriminators];
        NSLog(@"AD413A Read Discriminators Station %d\n",[model stationNumber]+1);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Read Discriminators"];
    }
}

- (IBAction) writeDiscriminatorAction:(id)sender
{
    @try {
		[self endEditing];
        [model writeDiscriminators];
        NSLog(@"AD413A Write Discriminators Station %d\n",[model stationNumber]+1);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Write Discriminators"];
    }
}

- (IBAction) clearModuleAction:(id)sender
{
    @try {
        [model clearModule];
        NSLog(@"AD413A Clear Model for Station %d\n",[model stationNumber]+1);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Clear Model"];
    }
}

- (IBAction) controlReg1Action:(id)sender
{
	int tag = (int)[[sender selectedCell] tag];
	BOOL state = [[sender selectedCell] intValue];
	switch(tag){
		case kSinglesBit:			[model setSingles:state];			break;
		case kZeroSuppressionBit:	[model setZeroSuppressionMode:state];	break;
		case kRandomAccessBit:		[model setRandomAccessMode:state];		break;
		case kLAMEnableBit:			[model setLamEnable:state];				break;
		case kOFSuppressionBit:		[model setOfSuppressionMode:state];		break;
	}
}

- (IBAction) controlReg2Action:(id)sender
{
	int tag = (int)[[sender selectedCell] tag];
	BOOL state = [[sender selectedCell] intValue];
    [model setGateEnable:tag withValue:state];
}


- (IBAction) readControlReg1Action:(id)sender
{
    @try {
        [model readControlReg1];
        NSLog(@"AD413A Read Control Register1 for Station %d\n",[model stationNumber]+1);
		NSLog(@"lamEnable: %@\n",[model lamEnable]?@"YES":@"NO");
		NSLog(@"singles: %@\n",[model singles]?@"YES":@"NO");
		NSLog(@"randomAccessMode: %@\n",[model randomAccessMode]?@"YES":@"NO");
		NSLog(@"ofSuppressionMode: %@\n",[model ofSuppressionMode]?@"YES":@"NO");
		NSLog(@"zeroSuppressionMode: %@\n",[model zeroSuppressionMode]?@"YES":@"NO");
		NSLog(@"Mode: %@\n",[model CAMACMode]?@"CAMAC":@"FERA");
	}
	@catch(NSException* localException) {
        [self showError:localException name:@"Read Control Register1"];
    }
}

- (IBAction) writeControlReg1Action:(id)sender
{
    @try {
        [model writeControlReg1];
        NSLog(@"AD413A Write Control Register1 for Station %d\n",[model stationNumber]+1);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Write Control Register1"];
    }
}


- (IBAction) readControlReg2Action:(id)sender
{
    @try {
        [model readControlReg2];
        NSLog(@"AD413A Read Control Register2 for Station %d result:0x%0x\n",[model stationNumber]+1);
		int bit;
		for(bit=0;bit<5;bit++){
			if(bit<4)NSLog(@"Gate %d Enabled = %@\n",bit,[model gateEnable:bit]?@"NO":@"YES");
			else     NSLog(@"Master Gate Enabled = %@\n",[model gateEnable:bit]?@"NO":@"YES");
		}
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Read Control Register2"];
    }
}

- (IBAction) writeControlReg2Action:(id)sender
{
    @try {
        [model writeControlReg2];
        NSLog(@"AD413A Write Control Register2 for Station %d\n",[model stationNumber]+1);
    }
	@catch(NSException* localException) {
        [self showError:localException name:@"Write Control Register2"];
    }
}

- (void) showError:(NSException*)anException name:(NSString*)name
{
    NSLog(@"Failed Cmd: %@\n",name);
    if([[anException name] isEqualToString: OExceptionNoCamacCratePower]) {
        [[model crate]  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@",name]];
    }
    else {
        ORRunAlertPanel([anException name], @"%@\n%@ (F%d)", @"OK", nil, nil,
                        [anException name],name,[model stationNumber]+1);
    }
}
@end



