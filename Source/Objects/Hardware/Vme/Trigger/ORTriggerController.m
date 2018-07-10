//
//  ORTriggerController.m
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


#import "ORTriggerController.h"
#import "ORTriggerModel.h"

@implementation ORTriggerController

-(id)init
{
    self = [super initWithWindowNibName:@"Trigger"];
	
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    NSString* key = [NSString stringWithFormat: @"orca.Trigger%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
}

#pragma mark ¥¥¥Accessors
- (NSTextField*) slotField
{
    return slotField;
}

- (NSStepper*) addressStepper
{
	return addressStepper;
}

- (NSTextField*) addressText
{
	return addressText;
}

- (NSTextField*)  gtidLowerText
{
	return gtidLowerText;
}

- (NSStepper*)  gtidLowerStepper
{
	return gtidLowerStepper;
}

- (NSTextField*)  gtidUpperText
{
	return gtidUpperText;
}

- (NSStepper*)  gtidUpperStepper
{
	return gtidUpperStepper;
}

/*
 - (NSTextField*)  vmeClkLowerText
 {
 return vmeClkLowerText;
 }
 
 - (NSStepper*)  vmeClkLowerStepper
 {
 return vmeClkLowerStepper;
 }
 
 - (NSTextField*)  vmeClkMiddleText
 {
 return vmeClkMiddleText;
 }
 
 - (NSStepper*)  vmeClkMiddleStepper
 {
 return vmeClkMiddleStepper;
 }
 
 - (NSTextField*)  vmeClkUpperText
 {
 return vmeClkUpperText;
 }
 
 - (NSStepper*)  vmeClkUpperStepper
 {
 return vmeClkUpperStepper;
 }
 */


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
					 selector : @selector(gtidLowerChanged:)
						 name : ORTriggerGtidLowerChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(gtidUpperChanged:)
						 name : ORTriggerGtidUpperChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(shipEvt1ClkChanged:)
						 name : ORTriggerShipEvt1ClkChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(shipEvt2ClkChanged:)
						 name : ORTriggerShipEvt2ClkChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(gtErrorCountChanged:)
						 name : ORTriggerShipGtErrorCountChangedNotification
					   object : model];
	
	
    [notifyCenter addObserver : self
					 selector : @selector(initMultiBoardChanged:)
						 name : ORTriggerInitMultiBoardChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(initTrig2Changed:)
						 name : ORTriggerInitTrig2ChangedNotification
					   object : model];
	
	
    [notifyCenter addObserver : self
					 selector : @selector(useSoftwareGtIdChanged:)
						 name : ORTriggerUseSoftwareGtIdChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(useNoHardwareChanged:)
						 name : ORTriggerUseNoHardwareChangedNotification
					   object : model];
	
	
    [notifyCenter addObserver : self
					 selector : @selector(softwareGtIdChanged:)
						 name : ORTriggerSoftwareGtIdChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(runStatusChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(trigger1NameChanged:)
						 name : ORTrigger1NameChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(trigger2NameChanged:)
						 name : ORTrigger2NameChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORTriggerSettingsLock
						object: nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(specialLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(specialLockChanged:)
						 name : ORTriggerSpecialLock
						object: nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(useMSAMChanged:)
						 name : ORTriggerMSAMChangedNotification
						object: nil];
	
	
	/*	[notifyCenter addObserver : self
	 selector : @selector(vmeClkLowerChanged:)
	 name : ORTriggerVmeClkLowerChangedNotification
	 object : model];
	 
	 [notifyCenter addObserver : self
	 selector : @selector(vmeClkMiddleChanged:)
	 name : ORTriggerVmeClkMiddleChangedNotification
	 object : model];
	 
	 [notifyCenter addObserver : self
	 selector : @selector(vmeClkUpperChanged:)
	 name : ORTriggerVmeClkUpperChangedNotification
	 object : model];
	 */	
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self gtidLowerChanged:nil];
    [self gtidUpperChanged:nil];
    [self shipEvt1ClkChanged:nil];
    [self shipEvt2ClkChanged:nil];
    [self gtErrorCountChanged:nil];
    [self initMultiBoardChanged:nil];
    [self initTrig2Changed:nil];
    [self softwareGtIdChanged:nil];
    [self useNoHardwareChanged:nil];
    [self useSoftwareGtIdChanged:nil];
    [self runStatusChanged:nil];
    [self trigger1NameChanged:nil];
    [self trigger2NameChanged:nil];
    [self settingsLockChanged:nil];
    [self specialLockChanged:nil];
    [self useMSAMChanged:nil];
	
    //[self vmeClkLowerChanged:nil];
    //[self vmeClkMiddleChanged:nil];
    //[self vmeClkUpperChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORTriggerSettingsLock to:secure];
    [gSecurity setLock:ORTriggerSpecialLock to:secure];
    [settingLockButton setEnabled:secure];
    [specialLockButton setEnabled:secure];
}


- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    NSString* key = [NSString stringWithFormat: @"orca.ORTrigger%d.selectedtab",[model slot]];
    NSUInteger index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
}


- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORTriggerSettingsLock];
    BOOL locked = [gSecurity isLocked:ORTriggerSettingsLock];
	
    [settingLockButton setState: locked];
    [addressStepper setEnabled:!locked && !runInProgress];
    [addressText setEnabled:!locked && !runInProgress];
    [trigger1NameField setEnabled:!locked && !runInProgress];
    [trigger2NameField setEnabled:!locked && !runInProgress];
	
    [initTrig2CB setEnabled:!locked && !lockedOrRunningMaintenance];
    [initMultiBoardCB setEnabled:!locked && !lockedOrRunningMaintenance];
    [shipEvt1ClkButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [shipEvt2ClkButton setEnabled:!locked && !lockedOrRunningMaintenance];
	
    [alteraRegButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [gtid1Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [gtid2Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [boardIDButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [getStatusButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [enableMultiBoardButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [disableMultiBoardButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [enableTrig2InhibButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [disableTrig2InhibButton setEnabled:!locked && !lockedOrRunningMaintenance];
	
    [useMSAMCB setEnabled:!locked && !lockedOrRunningMaintenance];
	
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORTriggerSettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
	
}

- (void) specialLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORTriggerSpecialLock];
    BOOL locked = [gSecurity isLocked:ORTriggerSpecialLock];
	
    [specialLockButton setState: locked];
	
    [gtidLowerText setEnabled:!locked && !lockedOrRunningMaintenance];
    [gtidLowerStepper setEnabled:!locked && !lockedOrRunningMaintenance];
    [gtidUpperText setEnabled:!locked && !lockedOrRunningMaintenance];
    [gtidUpperStepper setEnabled:!locked && !lockedOrRunningMaintenance];
	
    [loadLowerGTIDButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [loadUpperGTIDButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [readLowerGTID1Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [readUpperGTID1Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [readLowerGTID2Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [readUpperGTID2Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [softGTButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [syncClrButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [gtSyncClrButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [gtSyncClr24Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [latchGTID1Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [latchGTID2Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [pollEventButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [useSoftwareGtIdCB setEnabled:!locked && !lockedOrRunningMaintenance];
    [useNoHardwareCB setEnabled:!locked && !lockedOrRunningMaintenance];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORTriggerSettingsLock])s = @"Not in Maintenance Run.";
    }
    [specialLockDocField setStringValue:s];
	
}

- (void) gtErrorCountChanged:(NSNotification*)aNotification
{
	[gtErrorField setIntegerValue:[model gtErrorCount]];
}

- (void) shipEvt1ClkChanged:(NSNotification*)aNotification
{
	[shipEvt1ClkButton setState: [model shipEvt1Clk]];
}

- (void) shipEvt2ClkChanged:(NSNotification*)aNotification
{
	[shipEvt2ClkButton setState: [model shipEvt2Clk]];
}


- (void) slotChanged:(NSNotification*)aNotification
{
	[[self slotField] setIntValue: [model slot]];
}

- (void) baseAddressChanged:(NSNotification*)aNotification
{
	[[self addressText] setIntegerValue: [model baseAddress]];
	[self updateStepper:[self addressStepper] setting:[model baseAddress]];
}

- (void) gtidLowerChanged:(NSNotification*)aNotification
{
	[[self gtidLowerText] setIntValue: [model gtidLower]];
	[self updateStepper:[self gtidLowerStepper] setting:[model gtidLower]];
}

- (void) gtidUpperChanged:(NSNotification*)aNotification
{
	[[self gtidUpperText] setIntValue: [model gtidUpper]];
	[self updateStepper:[self gtidUpperStepper] setting:[model gtidUpper]];
}

- (void) useMSAMChanged:(NSNotification*)aNotification
{
	[useMSAMCB setState: [model useMSAM]];
}


- (void) initMultiBoardChanged:(NSNotification*)aNotification
{
	[initMultiBoardCB setState: [model initWithMultiBoardEnabled]];
}

- (void) initTrig2Changed:(NSNotification*)aNotification
{
	[initTrig2CB setState: [model initWithTrig2InhibitEnabled]];
}


- (void) useSoftwareGtIdChanged:(NSNotification*)aNotification
{
	[useSoftwareGtIdCB setState: [model useSoftwareGtId]];
	if(![model useSoftwareGtId])[softwareGtIdField setStringValue:@"--"];
	else [softwareGtIdField setIntegerValue:[model softwareGtId]];
}

- (void) useNoHardwareChanged:(NSNotification*)aNotification
{
	[useNoHardwareCB setState: [model useNoHardware]];	
}

- (void) runStatusChanged:(NSNotification*)aNotification
{
    int status = [[[aNotification userInfo] objectForKey:ORRunStatusValue] intValue];
    [useSoftwareGtIdCB setEnabled:status == eRunStopped];
    [useNoHardwareCB setEnabled:status == eRunStopped];
    
}

- (void) softwareGtIdChanged:(NSNotification*)aNotification
{
	[softwareGtIdField setIntegerValue:[model softwareGtId]];
}

- (void) trigger1NameChanged:(NSNotification*)aNotification
{
	[trigger1NameField setStringValue: [model trigger1Name]];
}

- (void) trigger2NameChanged:(NSNotification*)aNotification
{
	[trigger2NameField setStringValue: [model trigger2Name]];
}


/*- (void) vmeClkLowerChanged:(NSNotification*)aNotification
 {
 [[self vmeClkLowerText] setIntValue: [model vmeClkLower]];
 [self updateStepper:[self vmeClkLowerStepper] setting:[model vmeClkLower]];
 }
 
 - (void) vmeClkMiddleChanged:(NSNotification*)aNotification
 {
 [[self vmeClkMiddleText] setIntValue: [model vmeClkMiddle]];
 [self updateStepper:[self vmeClkMiddleStepper] setting:[model vmeClkMiddle]];
 }
 
 - (void) vmeClkUpperChanged:(NSNotification*)aNotification
 {
 [[self vmeClkUpperText] setIntValue: [model vmeClkUpper]];
 [self updateStepper:[self vmeClkUpperStepper] setting:[model vmeClkUpper]];
 }
 */
#pragma mark ¥¥¥Actions

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORTriggerSettingsLock to:[sender intValue] forWindow:[self window]];
}
- (IBAction) specialLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORTriggerSpecialLock to:[sender intValue] forWindow:[self window]];
}

-(IBAction)baseAddressAction:(id)sender
{
	if([sender intValue] != [model baseAddress]){
		[[self undoManager] setActionName: @"Set Base Address"];
		[model setBaseAddress:[sender intValue]];
	}
}


- (IBAction) gtidLowerAction:(id)sender
{
	if([sender intValue] != [model gtidLower]){
		[[self undoManager] setActionName: @"Set Lower Gtid"];
		[model setGtidLower:[sender intValue]];
	}	
}

- (IBAction) gtidUpperAction:(id)sender
{
	if([sender intValue] != [model gtidUpper]){
		[[self undoManager] setActionName: @"Set Upper Gtid"];
		[model setGtidUpper:[sender intValue]];
	}
}
/*
 - (IBAction) vmeClkLowerAction:(id)sender
 {
 if([sender intValue] != [model vmeClkLower]){
 [[self undoManager] setActionName: @"Set Lower VME Clk"];
 [model setVmeClkLower:[sender intValue]];
 }	
 }
 
 - (IBAction) vmeClkMiddleAction:(id)sender
 {
 if([sender intValue] != [model vmeClkMiddle]){
 [[self undoManager] setActionName: @"Set Middle VME Clk"];
 [model setVmeClkMiddle:[sender intValue]];
 }
 }
 
 - (IBAction) vmeClkUpperAction:(id)sender
 {
 if([sender intValue] != [model vmeClkUpper]){
 [[self undoManager] setActionName: @"Set Upper VME Clk"];
 [model setVmeClkUpper:[sender intValue]];
 }
 }
 
 */



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
		NSLog(@"Trigger 1 Event : %s\n",[model eventBit1Set:status]?"true":"false");
		NSLog(@"Trigger 2 Event : %s\n",[model eventBit2Set:status]?"true":"false");
		NSLog(@"Valid Gt 1 Latch: %s\n",[model validEvent1GtBitSet:status]?"true":"false");
		NSLog(@"Valid Gt 2 Latch: %s\n",[model validEvent2GtBitSet:status]?"true":"false");
		NSLog(@"Count Error     : %s\n",[model countErrorBitSet:status]?"true":"false");
		//NSLog(@"Clock Enabled   : %s\n",[model clockEnabledBitSet:status]?"true":"false");
		NSLog(@"--------------------------\n");
		
		
    }
	@catch(NSException* localException) {
        NSLog(@"Read of Trigger Board Status FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nRead of Trigger Board Status FAILED", @"OK", nil, nil,
                        localException);
    }	
}

- (IBAction) resetAlteraAction:(id)sender
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

- (IBAction) resetEvent1:(id)sender
{
	@try {
        [model resetGtEvent1];
        NSLog(@"Reset Trigger Board Event 1\n");
		
    }
	@catch(NSException* localException) {
        NSLog(@"Reset of Trigger Board Event 1 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nReset of Trigger Board Event 1 FAILED", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) resetEvent2:(id)sender
{
	@try {
        [model resetGtEvent2];
        NSLog(@"Reset Trigger Board Event 2\n");
		
    }
	@catch(NSException* localException) {
        NSLog(@"Reset of Trigger Board Event 2 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nReset of Trigger Board Event 2 FAILED", @"OK", nil, nil,
                        localException);
    }
}


/*- (IBAction) resetClockAction:(id)sender
 {
 @try {
 [model resetClock];
 NSLog(@"Trigger Board Clock Reset\n");
 
 }
 @catch(NSException* localException) {
 NSLog(@"Reset of Trigger Board Clock FAILED.\n");
 ORRunAlertPanel([localException name], @"%@\nReset of Trigger Board Clock FAILED", @"OK", nil, nil,
 localException);
 }
 }
 */
- (IBAction) loadLowerGtidAction:(id)sender
{
	@try {
		[self endEditing];
		[model loadLowerGtId:[model gtidLower]];
		NSLog(@"Loaded Trigger Lower GTID: 0x%04x\n",[model gtidLower]);
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to load Trigger Lower GTID: 0x%04x\n",[model gtidLower]);
		ORRunAlertPanel([localException name], @"%@\nFAILED to load Trigger Lower GTID: 0x%04x", @"OK", nil, nil,
						localException,[model gtidLower]);
    }
}

- (IBAction) loadUpperGtidAction:(id)sender
{
	@try {
		[self endEditing];
		[model loadUpperGtId:[model gtidUpper]];
		NSLog(@"Loaded Trigger Upper GTID: 0x%04x\n",[model gtidUpper]);
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to load Trigger Upper GTID: 0x%04x\n",[model gtidUpper]);
		ORRunAlertPanel([localException name], @"%@\nFAILED to load Trigger Upper GTID: 0x%04x", @"OK", nil, nil,
						localException,[model gtidUpper]);
    }	
}

- (IBAction) readLowerGtid1Action:(id)sender
{
	@try {
		NSLog(@"Read Trigger Lower GTID 1: 0x%04x\n",[model readLowerEvent1GtId]);
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to load Trigger Lower GTID 1: %d\n",[model gtidLower]);
		ORRunAlertPanel([localException name], @"%@\nFAILED to read Trigger Lower GTID 1\n", @"OK", nil, nil,
						localException);
    }
}

- (IBAction) readUpperGtid1Action:(id)sender
{
	@try {
		NSLog(@"Read Trigger Upper GTID 1: 0x%04x\n",[model readUpperEvent1GtId]);
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to read Trigger Upper GTID 1\n");
		ORRunAlertPanel([localException name], @"%@\nFAILED to read Trigger Upper GTID 1", @"OK", nil, nil,
						localException);
    }
}


- (IBAction) readLowerGtid2Action:(id)sender
{
	@try {
		NSLog(@"Read Trigger Lower GTID 2: 0x%04x\n",[model readLowerEvent2GtId]);
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to load Trigger Lower GTID 2: %d\n",[model gtidLower]);
		ORRunAlertPanel([localException name], @"%@\nFAILED to read Trigger Lower GTID 2\n", @"OK", nil, nil,
						localException);
    }
}

- (IBAction) readUpperGtid2Action:(id)sender
{
    @try {
		NSLog(@"Read Trigger Upper GTID 2: 0x%04x\n",[model readUpperEvent2GtId]);
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to read Trigger Upper GTID 2\n");
		ORRunAlertPanel([localException name], @"%@\nFAILED to read Trigger Upper GTID 2", @"OK", nil, nil,
						localException);
    }
}


- (IBAction) trigger1NameAction:(id)sender
{
    [self endEditing];
    [model setTrigger1Name:[trigger1NameField stringValue]];
}

- (IBAction) trigger2NameAction:(id)sender
{
    [self endEditing];
    [model setTrigger2Name:[trigger2NameField stringValue]];
}


/*- (IBAction) loadLowerClockAction:(id)sender
 {
 @try {
 [self endEditing];
 [model loadLowerVmeClock:[model vmeClkLower]];
 NSLog(@"Loaded Trigger Lower VME Clock 0x%04x\n",[model vmeClkLower]);
 
 }
 @catch(NSException* localException) {
 NSLog(@"FAILED to load Trigger Lower VME Clock: 0x%04x\n",[model vmeClkLower]);
 ORRunAlertPanel([localException name], @"%@\nFAILED to load Trigger Lower VME clock: 0x%04x", @"OK", nil, nil,
 localException,[model vmeClkLower]);
 }
 
 }
 
 - (IBAction) loadMiddleClockAction:(id)sender
 {
 @try {
 [self endEditing];
 [model loadMiddleVmeClock:[model vmeClkMiddle]];
 NSLog(@"Loaded Trigger Middle VME Clock 0x%04x\n",[model vmeClkMiddle]);
 
 }
 @catch(NSException* localException) {
 NSLog(@"FAILED to load Trigger Middle VME Clock: 0x%04x\n",[model vmeClkMiddle]);
 ORRunAlertPanel([localException name], @"%@\nFAILED to load Trigger Middle VME clock: 0x%04x", @"OK", nil, nil,
 localException,[model vmeClkMiddle]);
 }
 }
 
 - (IBAction) loadUpperClockAction:(id)sender
 {
 @try {
 [self endEditing];
 [model loadUpperVmeClock:[model vmeClkUpper]];
 NSLog(@"Loaded Trigger Upper VME Clock 0x%04x\n",[model vmeClkUpper]);
 
 }
 @catch(NSException* localException) {
 NSLog(@"FAILED to load Trigger Upper VME Clock: 0x%04x\n",[model vmeClkUpper]);
 ORRunAlertPanel([localException name], @"%@\nFAILED to load Trigger Upper VME clock: 0x%04x", @"OK", nil, nil,
 localException,[model vmeClkUpper]);
 }
 }
 
 - (IBAction) readLowerClockAction:(id)sender
 {
 @try {
 NSLog(@"Read Trigger Lower VME clock: 0x%04x\n",[model readLowerVmeClock]);
 
 }
 @catch(NSException* localException) {
 NSLog(@"FAILED to read Trigger Lower VME clock\n");
 ORRunAlertPanel([localException name], @"%@\nFAILED to read Trigger Lower VME clock: 0x%0x", @"OK", nil, nil,
 localException);
 }
 }
 - (IBAction) readMiddleClockAction:(id)sender
 {
 @try {
 NSLog(@"Read Trigger Middle VME clock: 0x%04x\n",[model readMiddleVmeClock]);
 
 }
 @catch(NSException* localException) {
 NSLog(@"FAILED to read Trigger Middle VME clock\n");
 ORRunAlertPanel([localException name], @"%@\nFAILED to read Trigger Middle VME clock: 0x%0x", @"OK", nil, nil,
 localException);
 }
 }
 
 - (IBAction) readUpperClockAction:(id)sender
 {
 @try {
 NSLog(@"Read Trigger Upper VME clock: 0x%04x\n",[model readUpperVmeClock]);
 
 }
 @catch(NSException* localException) {
 NSLog(@"FAILED to read Trigger Upper VME clock\n");
 ORRunAlertPanel([localException name], @"%@\nFAILED to read Trigger Upper VME clock: 0x%0x", @"OK", nil, nil,
 localException);
 }
 }
 
 - (IBAction) enableClockAction:(id)sender
 {
 [self enableClock:YES];
 }
 - (IBAction) disableClockAction:(id)sender
 {
 [self enableClock:NO];
 }
 */
- (IBAction) enableMultiBoardAction:(id)sender
{
	[self enableMultiBoard:YES];	
}
- (IBAction) disableMultiBoardAction:(id)sender
{
	[self enableMultiBoard:NO];	
}

- (IBAction) useMSAMAction:(id)sender
{
    [model setUseMSAM:[sender state]];
}

- (IBAction) enableBusyAction:(id)sender
{
	[self enableBusy:YES];	
}
- (IBAction) disableBusyAction:(id)sender
{
	[self enableBusy:NO];	
}


- (IBAction) softGtAction:(id)sender
{
	@try {
		[model softGT];
		NSLog(@"Trigger card soft gt.\n");
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to send soft GT to trigger card.\n");
		ORRunAlertPanel([localException name], @"%@\nSoft GT FAILED\n", @"OK", nil, nil,
						localException);
    }	
}

- (IBAction) gtSyncClrAction:(id)sender
{
	@try {
		[model softGTSyncClear];
		NSLog(@"Trigger card soft GT sync clear.\n");
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to GT sync clear trigger card.\n");
		ORRunAlertPanel([localException name], @"%@\nGT Sync Clear FAILED\n", @"OK", nil, nil,
						localException);
    }
}

- (IBAction) syncClrAction:(id)sender
{
	@try {
		[model syncClear];
		NSLog(@"Trigger card sync clear.\n");
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to sync clear trigger card.\n");
		ORRunAlertPanel([localException name], @"%@\nSync Clear FAILED\n", @"OK", nil, nil,
						localException);
    }
}

- (IBAction) latchGtid1Action:(id)sender
{
	@try {
		[model testLatchGtId1];
		NSLog(@"Trigger Card Latch GTID 1.\n");
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to latch trigger card GTID 1.\n");
		ORRunAlertPanel([localException name], @"%@\nGTID 1 Latch FAILED\n", @"OK", nil, nil,
						localException);
    }
}

- (IBAction) latchGtid2Action:(id)sender
{
	@try {
		[model testLatchGtId2];
		NSLog(@"Trigger Card Latch GTID 2.\n");
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to latch trigger card GTID 2.\n");
		ORRunAlertPanel([localException name], @"%@\nGTID 2 Latch FAILED\n", @"OK", nil, nil,
						localException);
    }
}

- (IBAction) syncClr24Action:(id)sender
{
	@try {
		[model syncClear24];
		NSLog(@"Trigger Card Sync Clear 24.\n");
		
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to sync clear 24 trigger card.\n");
		ORRunAlertPanel([localException name], @"%@\nSync Clear 24 FAILED\n", @"OK", nil, nil,
						localException);
    }
}

/*
 - (IBAction) latchClkAction:(id)sender
 {
 @try {
 [model testLatchVmeClockCount];
 NSLog(@"Trigger Card Latch Clock.\n");
 
 }
 @catch(NSException* localException) {
 NSLog(@"FAILED to latch clock on trigger card.\n");
 ORRunAlertPanel([localException name], @"%@\nLatch Clock FAILED\n", @"OK", nil, nil,
 localException);
 }
 
 }
 */
- (IBAction) testPollSeqAction:(id)sender
{
	@try {
		unsigned short statusReg = [model readStatus];
		if([model eventBit1Set:statusReg] || [model eventBit2Set:statusReg]){
			NSLog(@"********************************\n");
			if([model eventBit1Set:statusReg])   NSLog(@"Event on trigger 1!\n");
			if([model eventBit2Set:statusReg])	NSLog(@"Event on trigger 2!\n");
			[model softGT];
			NSLog(@"SoftGT\n");
			statusReg = [model readStatus];
			if([model validEvent1GtBitSet:statusReg]){
				NSLog(@"Lower GTID 1      : 0x%0x\n",	[model readLowerEvent1GtId]);
				NSLog(@"Upper GTID 1     : 0x%0x\n",	[model readUpperEvent1GtId]);
				//NSLog(@"Lower Vme Clock : 0x%0x\n",	[model readLowerVmeClock]);
				//NSLog(@"Middle Vme Clock: 0x%0x\n",	[model readMiddleVmeClock]);
				//NSLog(@"Upper Vme Clock : 0x%0x\n",	[model readUpperVmeClock]);
				[model resetGtEvent1];
				NSLog(@"Reset GtEvent 1\n");
			}
			if([model validEvent2GtBitSet:statusReg]){
				NSLog(@"Lower GTID 2      : 0x%0x\n",	[model readLowerEvent2GtId]);
				NSLog(@"Upper GTID 2      : 0x%0x\n",	[model readUpperEvent2GtId]);
				//NSLog(@"Lower Vme Clock : 0x%0x\n",	[model readLowerVmeClock]);
				//NSLog(@"Middle Vme Clock: 0x%0x\n",	[model readMiddleVmeClock]);
				//NSLog(@"Upper Vme Clock : 0x%0x\n",	[model readUpperVmeClock]);
				[model resetGtEvent2];
				NSLog(@"Reset GtEvent 2\n");
			}
			NSLog(@"********************************\n");
		}
		else NSLog(@"no event\n");
		
	}
	@catch(NSException* localException) {
		NSLog(@"Test Poll sequence FAILED.\n");
		ORRunAlertPanel([localException name], @"%@\nTest Poll FAILED\n", @"OK", nil, nil,
						localException);
    }
	
}

- (IBAction) shipEvt1ClkAction:(id)sender
{
    [model setShipEvt1Clk:[sender state]];
}

- (IBAction) shipEvt2ClkAction:(id)sender
{
    [model setShipEvt2Clk:[sender state]];
}

- (IBAction) initMultiBoardAction:(id)sender
{
    [model setInitWithMultiBoardEnabled:[sender state]];    
}

- (IBAction) initTrig2Action:(id)sender
{
    [model setInitWithTrig2InhibitEnabled:[sender state]];    
}

- (IBAction) useSoftwareGtIdAction:(id)sender
{
    [model setUseSoftwareGtId:[sender state]];    
}

- (IBAction) useNoHardwareAction:(id)sender
{
    [model setUseNoHardware:[sender state]];    
}


#pragma mark ¥¥¥Helper Methods
- (void) enableClock:(BOOL)enable
{
    @try {
        [model enableClock:enable];
        NSLog(@"%@ Trigger Clock\n",enable?@"Enabled":@"Disabled");
		
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to %@ Clock.\n",enable?@"enable":@"disable");
        ORRunAlertPanel([localException name], @"%@\nFAILED to %@ Clock.\n", @"OK", nil, nil,
						localException,enable?@"enable":@"disable");
    }
}

- (void) enableMultiBoard:(BOOL)enable
{
    @try {
        [model enableMultiBoardOutput:enable];
        NSLog(@"%@ Trigger MultiBoard output\n",enable?@"Enabled":@"Disabled");
		
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to %@ trigger multiboard output.\n",enable?@"enable":@"disable");
        ORRunAlertPanel([localException name], @"%@\nFAILED to %@ multiboard output.\n", @"OK", nil, nil,
						localException,enable?@"enable":@"disable");
    }
}

- (void) enableBusy:(BOOL)enable
{
    @try {
        [model enableBusyOutput:enable];
        NSLog(@"%@ Trigger Busy\n",enable?@"Enabled":@"Disabled");
		
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to %@ trigger Busy.\n",enable?@"enable":@"disable");
        ORRunAlertPanel([localException name], @"%@\nFAILED to %@ Busy.\n", @"OK", nil, nil,
						localException,enable?@"enable":@"disable");
    }
}




@end
