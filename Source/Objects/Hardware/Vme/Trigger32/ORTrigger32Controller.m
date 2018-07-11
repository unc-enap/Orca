//
//  Trigger32Controller.m
//  Orca
//
//  Created by Mark Howe on Tue May 4, 2004.
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


#import "ORTrigger32Controller.h"
#import "ORTrigger32Model.h"

@implementation ORTrigger32Controller

-(id)init
{
    self = [super initWithWindowNibName:@"Trigger32"];
    
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    NSString* key = [NSString stringWithFormat: @"orca.Trigger32%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
}

#pragma mark ¥¥¥Accessors


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
                     selector : @selector(gtIdValueChanged:)
                         name : ORTrigger32GtIdValueChangedNotification
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(shipEvt1ClkChanged:)
                         name : ORTrigger32ShipEvt1ClkChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(shipEvt2ClkChanged:)
                         name : ORTrigger32ShipEvt2ClkChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(gtErrorCountChanged:)
                         name : ORTrigger32GtErrorCountChangedNotification
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(trigger2EventEnabledChanged:)
                         name : ORTrigger32Trigger2EventEnabledNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(trigger2BusyChanged:)
                         name : ORTrigger32Trigger2BusyEnabledNotification
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(useSoftwareGtIdChanged:)
                         name : ORTrigger32UseSoftwareGtIdChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(useNoHardwareChanged:)
                         name : ORTrigger32UseNoHardwareChangedNotification
                       object : model];
    
	
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(trigger1NameChanged:)
                         name : ORTrigger321NameChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(trigger2NameChanged:)
                         name : ORTrigger322NameChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORTrigger32SettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(specialLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(specialLockChanged:)
                         name : ORTrigger32SpecialLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(useMSAMChanged:)
                         name : ORTrigger32MSAMChangedNotification
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(trigger1GTXorChanged:)
                         name : ORTrigger32Trigger1GTXorChangedNotification
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(trigger2GTXorChanged:)
                         name : ORTrigger32Trigger2GTXorChangedNotification
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(clockEnabledChanged:)
                         name : ORTrigger32ClockEnabledChangedNotification
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(liveTimeEnabledChanged:)
                         name : ORTrigger32LiveTimeEnabledChangedNotification
                        object: nil];
	
	
    [notifyCenter addObserver : self
					 selector : @selector(timeClockLowerChanged:)
						 name : ORTrigger32LowerTimeValueChangedNotification
					   object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(timeClockUpperChanged:)
                         name : ORTrigger32UpperTimeValueChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(testRegChanged:)
                         name : ORTrigger32TestValueChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(prescaleChanged:)
                         name : ORTrigger32MSamPrescaleChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(specialLockChanged:)
                         name : ORTrigger32LiveTimeCalcRunningChangedNotification
                       object : model];
	
	
	
    [notifyCenter addObserver : self
                     selector : @selector(restartClkAtRunStartChanged:)
                         name : ORTrigger32ModelRestartClkAtRunStartChanged
						object: model];
	
}

#pragma mark ¥¥¥Interface Management

- (void) restartClkAtRunStartChanged:(NSNotification*)aNote
{
	[restartClkAtRunStartButton setIntValue: [model restartClkAtRunStart]];
}
- (void) updateWindow
{
    [super updateWindow];
    [self prescaleChanged:nil];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self gtIdValueChanged:nil];
    [self shipEvt1ClkChanged:nil];
    [self shipEvt2ClkChanged:nil];
    [self gtErrorCountChanged:nil];
    [self trigger2EventEnabledChanged:nil];
    [self trigger2BusyChanged:nil];
    [self useNoHardwareChanged:nil];
    [self useSoftwareGtIdChanged:nil];
    [self runStatusChanged:nil];
    [self trigger1NameChanged:nil];
    [self trigger2NameChanged:nil];
    [self settingsLockChanged:nil];
    [self specialLockChanged:nil];
    [self useMSAMChanged:nil];
    [self trigger1GTXorChanged:nil];
    [self trigger2GTXorChanged:nil];
    [self clockEnabledChanged:nil];
    [self liveTimeEnabledChanged:nil];
    [self timeClockLowerChanged:nil];
    [self timeClockUpperChanged:nil];
	[self restartClkAtRunStartChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORTrigger32SettingsLock to:secure];
    [gSecurity setLock:ORTrigger32SpecialLock to:secure];
    [settingLockButton setEnabled:secure];
    [specialLockButton setEnabled:secure];
}


- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
    NSString* key = [NSString stringWithFormat: @"orca.ORTrigger32%d.selectedtab",[model slot]];
    NSInteger index = [tabView indexOfTabViewItem:item];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}


- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORTrigger32SettingsLock];
    BOOL locked = [gSecurity isLocked:ORTrigger32SettingsLock];
    
    [settingLockButton setState: locked];
    [addressStepper setEnabled:!locked && !runInProgress];
    [addressText setEnabled:!locked && !runInProgress];
    [trigger1NameField setEnabled:!locked && !runInProgress];
    [trigger2NameField setEnabled:!locked && !runInProgress];
    
    [trigger2eventInputEnableCB setEnabled:!locked && !lockedOrRunningMaintenance];
    [trigger2BusyOutputEnableCB setEnabled:!locked && !lockedOrRunningMaintenance];
    [shipEvt1ClkCB setEnabled:!locked && !lockedOrRunningMaintenance];
    [shipEvt2ClkCB setEnabled:!locked && !lockedOrRunningMaintenance];
    
    [boardIDButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [getStatusButton1 setEnabled:!locked && !lockedOrRunningMaintenance];
    
    [useMSAMCB setEnabled:!locked && !lockedOrRunningMaintenance];
    [prescaleStepper setEnabled:!locked && !lockedOrRunningMaintenance];
    [prescaleText setEnabled:!locked && !lockedOrRunningMaintenance];
    [trigger1GTXorCB setEnabled:!locked && !lockedOrRunningMaintenance];
    [trigger2GTXorCB setEnabled:!locked && !lockedOrRunningMaintenance];
    [enableTimeClockCB setEnabled:!locked && !lockedOrRunningMaintenance];
	
    [initButton setEnabled:!locked && !lockedOrRunningMaintenance];
	
    [enableLiveTimeCB setEnabled:!locked];
	
    [useSoftwareGtIdCB setEnabled:!locked && !lockedOrRunningMaintenance];
    [useNoHardwareCB setEnabled:!locked && !lockedOrRunningMaintenance];
    
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORTrigger32SettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
    
}

- (void) specialLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORTrigger32SpecialLock];
    BOOL locked = [gSecurity isLocked:ORTrigger32SpecialLock];
    
    [specialLockButton setState: locked];
    
    [getStatusButton2 setEnabled:!locked && !lockedOrRunningMaintenance];
	
    [gtIdValueText setEnabled:!locked && !lockedOrRunningMaintenance];
    [gtIdValueStepper setEnabled:!locked && !lockedOrRunningMaintenance];
    [loadGTIDButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [readGTID1Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [readGTID2Button setEnabled:!locked && !lockedOrRunningMaintenance];
	
    [timeClockLowerText setEnabled:!locked && !lockedOrRunningMaintenance];
    [timeClockLowerStepper setEnabled:!locked && !lockedOrRunningMaintenance];
    [timeClockUpperText setEnabled:!locked && !lockedOrRunningMaintenance];
    [timeClockUpperStepper setEnabled:!locked && !lockedOrRunningMaintenance];
    [loadUpperTimerCounterButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [loadLowerTimerCounterButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [readTimerCounter1Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [readTimerCounter2Button setEnabled:!locked && !lockedOrRunningMaintenance];
	
	
    [testRegText setEnabled:!locked && !lockedOrRunningMaintenance];
    [testRegStepper setEnabled:!locked && !lockedOrRunningMaintenance];
    [loadTestRegButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [readTestRegButton setEnabled:!locked && !lockedOrRunningMaintenance];
	
	
    [softGTButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [syncClrButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [gtSyncClrButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [gtSyncClr24Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [requestSGTIDButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [readSGTIDButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [pollEventButton setEnabled:!locked && !lockedOrRunningMaintenance];
	
	
    [latchGTID1Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [latchGTID2Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [latchClock1Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [latchClock2Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [latchLiveTimeButton setEnabled:!locked && !lockedOrRunningMaintenance];
	
	
    [resetAlteraButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [resetClockButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [resetErrorButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [resetGT1Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [resetGT2Button setEnabled:!locked && !lockedOrRunningMaintenance];
    [resetMSAMButton setEnabled:!locked && !lockedOrRunningMaintenance];
    [resetLiveTimeButton setEnabled:!locked && !lockedOrRunningMaintenance];
	
    [dumpLiveTimeButton setEnabled:!locked && !lockedOrRunningMaintenance && ![model liveTimeCalcRunning]];
	
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORTrigger32SettingsLock])s = @"Not in Maintenance Run.";
    }
    [specialLockDocField setStringValue:s];
    
}

- (void) gtErrorCountChanged:(NSNotification*)aNotification
{
	[gtErrorField setIntegerValue:[model gtErrorCount]];
    
}

- (void) shipEvt1ClkChanged:(NSNotification*)aNotification
{
	[shipEvt1ClkCB setState: [model shipEvt1Clk]];
}

- (void) shipEvt2ClkChanged:(NSNotification*)aNotification
{
	[shipEvt2ClkCB setState: [model shipEvt2Clk]];
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

- (void) prescaleChanged:(NSNotification*)aNotification
{
	[prescaleText setIntValue: [model mSamPrescale]];
	[self updateStepper:prescaleStepper setting:[model mSamPrescale]];
    
}

- (void) gtIdValueChanged:(NSNotification*)aNotification
{
	[gtIdValueText setIntegerValue: [model gtIdValue]];
	[self updateStepper:gtIdValueStepper setting:[model gtIdValue]];
    
}

- (void) trigger1GTXorChanged:(NSNotification*)aNotification
{
	[trigger1GTXorCB setState: [model trigger1GtXor]];
}

- (void) trigger2GTXorChanged:(NSNotification*)aNotification
{
	[trigger2GTXorCB setState: [model trigger2GtXor]];
}

- (void) clockEnabledChanged:(NSNotification*)aNotification
{
	[enableTimeClockCB setState: [model clockEnabled]];
}

- (void) liveTimeEnabledChanged:(NSNotification*)aNotification
{
	[enableLiveTimeCB setState: [model liveTimeEnabled]];
}

- (void) useMSAMChanged:(NSNotification*)aNotification
{
	[useMSAMCB setState: [model useMSAM]];
}


- (void) trigger2EventEnabledChanged:(NSNotification*)aNotification
{
	[trigger2eventInputEnableCB setState: [model trigger2EventInputEnable]];
}

- (void) trigger2BusyChanged:(NSNotification*)aNotification
{
	[trigger2BusyOutputEnableCB setState: [model trigger2BusyEnabled]];
}


- (void) useSoftwareGtIdChanged:(NSNotification*)aNotification
{
	[useSoftwareGtIdCB setState: [model useSoftwareGtId]];        
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

- (void) trigger1NameChanged:(NSNotification*)aNotification
{
	[trigger1NameField setStringValue: [model trigger1Name]];
	[setUpTrigger1Box setTitle:[model trigger1Name]];
	[testingTrigger1Label setStringValue:[model trigger1Name]];
}

- (void) trigger2NameChanged:(NSNotification*)aNotification
{
	[trigger2NameField setStringValue: [model trigger2Name]];
	[setUpTrigger2Box setTitle:[model trigger2Name]];
	[testingTrigger2Label setStringValue:[model trigger2Name]];
}


- (void) timeClockLowerChanged:(NSNotification*)aNotification
{
	[timeClockLowerText setIntegerValue: [model lowerTimeValue]];
	[self updateStepper:timeClockLowerStepper setting:[model lowerTimeValue]];
}

- (void) timeClockUpperChanged:(NSNotification*)aNotification
{
	[timeClockUpperText setIntegerValue: [model upperTimeValue]];
	[self updateStepper:timeClockUpperStepper setting:[model upperTimeValue]];
}

- (void) testRegChanged:(NSNotification*)aNotification
{
	[testRegText setIntegerValue: [model testRegisterValue]];
	[self updateStepper:testRegStepper setting:[model testRegisterValue]];
}

#pragma mark ¥¥¥Actions

- (void) restartClkAtRunStartAction:(id)sender
{
	[model setRestartClkAtRunStart:[sender intValue]];	
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORTrigger32SettingsLock to:[sender intValue] forWindow:[self window]];
}
- (IBAction) specialLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORTrigger32SpecialLock to:[sender intValue] forWindow:[self window]];
}

-(IBAction)baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [[self undoManager] setActionName: @"Set Base Address"];
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) prescaleAction:(id)sender;
{
    if([sender intValue] != [model mSamPrescale]){
        [[self undoManager] setActionName: @"Set M_Sam Prescale"];
        [model setMSamPrescale:[sender intValue]];
    }
}


- (IBAction) gtIdValueAction:(id)sender
{
    if([sender intValue] != [model gtIdValue]){
        [[self undoManager] setActionName: @"Set Gtid"];
        [model setGtIdValue:[sender intValue]];
    }
}

- (IBAction) timeClockLowerAction:(id)sender
{
    if([sender intValue] != [model lowerTimeValue]){
        [[self undoManager] setActionName: @"Set Lower Time Clk"];
        [model setLowerTimeValue:[sender intValue]];
    }
}

- (IBAction) timeClockUpperAction:(id)sender
{
    if([sender intValue] != [model upperTimeValue]){
        [[self undoManager] setActionName: @"Set Upper Time Clk"];
        [model setUpperTimeValue:[sender intValue]];
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

- (IBAction) readStatusAction:(id)sender
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

- (IBAction) resetGT1Action:(id)sender
{
    @try {
        [model resetTrigger1GTStatusBit];
        NSLog(@"Reset Trigger Board %@ Event\n",[model trigger1Name]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset of Trigger Board %@ Event FAILED.\n",[model trigger1Name]);
        ORRunAlertPanel([localException name], @"%@\nReset of Trigger Board %@ Event FAILED", @"OK", nil, nil,
						localException,[model trigger1Name]);
    }
}

- (IBAction) resetGT2Action:(id)sender
{
    @try {
        [model resetTrigger2GTStatusBit];
        NSLog(@"Reset Trigger Board %@ Event\n",[model trigger2Name]);
        
    }
	@catch(NSException* localException) {
		NSLog(@"Reset of Trigger Board %@ Event FAILED.\n",[model trigger2Name]);
        ORRunAlertPanel([localException name], @"%@\nReset of Trigger Board %@ Event FAILED", @"OK", nil, nil,
						localException,[model trigger2Name]);
    }
}


- (IBAction) resetClockAction:(id)sender
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

- (IBAction) resetErrorCountAction:(id)sender;
{
    @try {
        [model resetCountError];
        NSLog(@"Trigger Board Error Count Bit Reset\n");
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset of Trigger Error Count Bit FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nReset of Trigger Board Error Count Bit FAILED", @"OK", nil, nil,
						localException);
    }
}

- (IBAction) resetMSAMAction:(id)sender;
{
    @try {
        [model clearMSAM];
        NSLog(@"Trigger Board MSAM bit Reset\n");
        
    }
	@catch(NSException* localException) {
        NSLog(@"Reset of Trigger MSAM bit FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nReset of Trigger Board MSAM bit FAILED", @"OK", nil, nil,
						localException);
    }
}


- (IBAction) loadGtIdAction:(id)sender
{
    @try {
        [self endEditing];
        [model loadGTID:[model gtIdValue]];
        NSLog(@"Loaded Trigger Lower GTID: 0x%08x\n",[model gtIdValue]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to load Trigger Lower GTID: 0x%08x\n",[model gtIdValue]);
        ORRunAlertPanel([localException name], @"%@\nFAILED to load Trigger Lower GTID: 0x%08lx", @"OK", nil, nil,
						localException,[model gtIdValue]);
    }
}

- (IBAction) readGtId1Action:(id)sender
{
    @try {
        NSLog(@"Read Trigger %@ GTID: 0x%04x\n",[model trigger1Name],[model readTrigger1GTID]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to load Trigger Lower %@ GTID: 0x%04x\n",[model trigger1Name],[model gtIdValue]);
        ORRunAlertPanel([localException name], @"%@\nFAILED to read Trigger Lower %@ GTID 1\n", @"OK", nil, nil,
						localException,[model trigger1Name]);
    }
}


- (IBAction) readGtId2Action:(id)sender
{
    @try {
        NSLog(@"Read Trigger Lower %@ GTID: 0x%04x\n",[model trigger2Name],[model readTrigger2GTID]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to load Trigger %@ GTID: 0x%04x\n",[model trigger2Name],[model gtIdValue]);
        ORRunAlertPanel([localException name], @"%@\nFAILED to read Trigger Lower %@ GTID 2\n", @"OK", nil, nil,
						localException,[model trigger2Name]);
    }
}



- (IBAction) testRegValueAction:(id)sender
{
    if([sender intValue] != [model testRegisterValue]){
        [[self undoManager] setActionName: @"Set Test Register Value"];
        [model setTestRegisterValue:[sender intValue]];
    }
}

- (IBAction) loadTestRegAction:(id)sender
{
    @try {        
		[self endEditing];
        [model loadTestRegister:[model testRegisterValue]];
        NSLog(@"Loaded Trigger test register: 0x%04x\n",[model testRegisterValue]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to load Trigger test register\n");
        ORRunAlertPanel([localException name], @"%@\nFAILED to load trigger %@ test register\n", @"OK", nil, nil,
						localException,[model trigger2Name]);
    }
}

- (IBAction) readTestRegAction:(id)sender
{
    @try {
        NSLog(@"Read Trigger test register: 0x%04x\n",[model readTestRegister]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to read Trigger test register\n");
        ORRunAlertPanel([localException name], @"%@\nFAILED to read Trigger test register\n", @"OK", nil, nil,
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


- (IBAction) loadLowerClockAction:(id)sender
{
    @try {
        [self endEditing];
        [model loadLowerTimerCounter:[model lowerTimeValue]];
        NSLog(@"Loaded trigger lower clock 0x%04x\n",[model lowerTimeValue]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to load trigger lower clock: 0x%04x\n",[model lowerTimeValue]);
        ORRunAlertPanel([localException name], @"%@\nFAILED to load trigger lower clock: 0x%04lx", @"OK", nil, nil,
						localException,[model lowerTimeValue]);
    }
    
}

- (IBAction) loadUpperClockAction:(id)sender
{
    @try {
        [self endEditing];
        [model loadUpperTimerCounter:[model upperTimeValue]];
        NSLog(@"Loaded trigger upper clock 0x%04x\n",[model upperTimeValue]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to load trigger upper clock: 0x%04x\n",[model upperTimeValue]);
        ORRunAlertPanel([localException name], @"%@\nFAILED to load trigger upper clock: 0x%04lx", @"OK", nil, nil,
						localException,[model upperTimeValue]);
    }
}

- (IBAction) readLowerTrigger1ClockAction:(id)sender
{
    @try {
        NSLog(@"Read trigger %@ lower clock: 0x%04x\n",[model trigger1Name],[model readLowerTrigger1Time]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to read trigger %@ lower clock\n",[model trigger1Name]);
        ORRunAlertPanel([localException name], @"%@\nFAILED to read Trigger %@ lower clock", @"OK", nil, nil,
						localException,[model trigger1Name]);
    }
}

- (IBAction) readUpperTrigger1ClockAction:(id)sender
{
    @try {
        NSLog(@"Read Trigger %@ Upper clock: 0x%04x\n",[model trigger1Name],[model readUpperTrigger1Time]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to read trigger %@ upper clock\n",[model trigger1Name]);
        ORRunAlertPanel([localException name], @"%@\nFAILED to read Trigger %@ pper clock", @"OK", nil, nil,
						localException,[model trigger1Name]);
    }
}


- (IBAction) readLowerTrigger2ClockAction:(id)sender
{
    @try {
        NSLog(@"Read trigger %@ lower clock: 0x%04x\n",[model trigger2Name],[model readLowerTrigger2Time]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to read trigger %@ lower clock\n",[model trigger2Name]);
        ORRunAlertPanel([localException name], @"%@\nFAILED to read Trigger %@ lower clock", @"OK", nil, nil,
						localException,[model trigger2Name]);
    }
}

- (IBAction) readUpperTrigger2ClockAction:(id)sender
{
    @try {
        NSLog(@"Read Trigger %@ Upper clock: 0x%04x\n",[model trigger2Name],[model readUpperTrigger2Time]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to read trigger %@  clock\n",[model trigger2Name]);
        ORRunAlertPanel([localException name], @"%@\nFAILED to read Trigger %@ clock", @"OK", nil, nil,
						localException,[model trigger2Name]);
    }
}

- (IBAction) readTrigger1ClockAction:(id)sender
{
    [self readLowerTrigger1ClockAction:self];
    [self readUpperTrigger1ClockAction:self];
}

- (IBAction) readTrigger2ClockAction:(id)sender
{
    [self readLowerTrigger2ClockAction:self];
    [self readUpperTrigger2ClockAction:self];
}


- (IBAction) latchTrigger1ClockAction:(id)sender
{
    @try {
        NSLog(@"Test Latch Trigger %@ clock: 0x%04x\n",[model trigger1Name]);
        [model testLatchTrigger1Time];
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to test latch trigger %@ clock\n",[model trigger1Name]);
        ORRunAlertPanel([localException name], @"%@\nFAILED to test latch Trigger %@ clock", @"OK", nil, nil,
						localException,[model trigger1Name]);
    }
}

- (IBAction) latchTrigger2ClockAction:(id)sender
{
    @try {
        NSLog(@"Test Latch Trigger %@ clock: 0x%04x\n",[model trigger2Name]);
        [model testLatchTrigger2Time];
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to test latch trigger %@ clock\n",[model trigger2Name]);
        ORRunAlertPanel([localException name], @"%@\nFAILED to test latch Trigger %@ clock", @"OK", nil, nil,
						localException,[model trigger2Name]);
    }
}

- (IBAction) useMSAMAction:(id)sender
{
    [model setUseMSAM:[sender state]];
}

- (IBAction) trigger1GTXorAction:(id) sender
{
    [model setTrigger1GtXor:[sender state]];
}

- (IBAction) trigger2GTXorAction:(id) sender
{
    [model setTrigger2GtXor:[sender state]];
}

- (IBAction) trigger2BusyOutputAction:(id) sender
{
    [model setTrigger2BusyEnabled:[sender state]];
}

- (IBAction) trigger2EventInputAction:(id) sender
{
    [model setTrigger2EventInputEnable:[sender state]];
}

- (IBAction) enableTimeClockAction:(id) sender
{
    [model setClockEnabled:[sender state]];
}

- (IBAction) enableLiveTimeAction:(id) sender
{
    [model setLiveTimeEnabled:[sender state]];
}

- (IBAction) dumpLiveTimeAction:(id) sender
{
    [model dumpLiveTimeCounters];
}

- (IBAction) resetLiveTimeAction:(id) sender
{
    [model resetLiveTime];
}

- (IBAction) latchLiveTimeAction:(id) sender
{
    [model latchLiveTime];
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
        [model testLatchTrigger1GTID];
        NSLog(@"Trigger Card Latch %@ GTID.\n",[model trigger1Name]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED to latch trigger card %@ GTID.\n",[model trigger1Name]);
        ORRunAlertPanel([localException name], @"%@\n%@ GTID Latch FAILED\n", @"OK", nil, nil,
						localException,[model trigger1Name]);
    }
}

- (IBAction) latchGtid2Action:(id)sender
{
    @try {
        [model testLatchTrigger2GTID];
        NSLog(@"Trigger Card Latch %@ GTID.\n",[model trigger2Name]);
        
    }
	@catch(NSException* localException) {
		NSLog(@"FAILED to latch trigger card %@ GTID.\n",[model trigger2Name]);
        ORRunAlertPanel([localException name], @"%@\n%@ GTID Latch FAILED\n", @"OK", nil, nil,
						localException,[model trigger2Name]);
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

- (IBAction) initAction:(id)sender
{
    @try {
		[self endEditing];
		[model initBoard];
    }
	@catch(NSException* localException) {
        NSLog(@"Trigger card init sequence FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nTrigger Card Init FAILED\n", @"OK", nil, nil,
						localException);
    } 
}

- (IBAction) requestSGTIDAction:(id)sender
{
    @try {
        [model requestSoftGTID];
        NSLog(@"Trigger 32 Request Soft GTID.\n");
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED Trigger 32 Card Request Soft GTID.\n");
        ORRunAlertPanel([localException name], @"%@\nRequest Soft GTID FAILED\n", @"OK", nil, nil,
						localException);
    }
}


- (IBAction) readSGTIDAction:(id)sender
{
    @try {
        NSLog(@"Trigger 32 Soft GTID Register: 0x%08x\n",[model readSoftGTIDRegister]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"FAILED Trigger Card Read Soft GTID.\n");
        ORRunAlertPanel([localException name], @"%@\nRead Soft GTID FAILED\n", @"OK", nil, nil,
						localException);
    }
}


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
				NSLog(@"----%@----\n",[model trigger1Name]);
				NSLog(@"GTID       : 0x%0x\n",	[model readTrigger1GTID]);
                NSLog(@"Lower Clock: 0x%0x\n",	[model readLowerTrigger1Time]);
                NSLog(@"Upper Clock: 0x%0x\n",	[model readUpperTrigger1Time]);
                [model resetTrigger1GTStatusBit];
                NSLog(@"Reset %@ GtEvent\n",[model trigger1Name]);
            }
            if([model validEvent2GtBitSet:statusReg]){
				NSLog(@"----%@----\n",[model trigger2Name]);
				NSLog(@"GTID       : 0x%0x\n",	[model readTrigger2GTID]);
				NSLog(@"Lower Clock: 0x%0x\n",	[model readLowerTrigger2Time]);
                NSLog(@"Upper Clock: 0x%0x\n",	[model readUpperTrigger2Time]);
				[model resetTrigger2GTStatusBit];
                NSLog(@"Reset %@ GtEvent\n",[model trigger2Name]);
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


- (IBAction) useSoftwareGtIdAction:(id)sender
{
    [model setUseSoftwareGtId:[sender state]];
}

- (IBAction) useNoHardwareAction:(id)sender
{
    [model setUseNoHardware:[sender state]];
}




@end
