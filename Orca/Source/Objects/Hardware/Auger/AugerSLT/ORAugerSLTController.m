//
//  ORAugerSLTController.m
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
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


#pragma mark ¥¥¥Imported Files
#import "ORAugerSLTController.h"
#import "ORAugerSLTModel.h"
#import "ORFireWireInterface.h"

@implementation ORAugerSLTController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"AugerSLT"];
    
    return self;
}

#pragma mark ¥¥¥Initialization
- (void) dealloc
{
    [super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
	
	// Set title of SLT configuration window, ak 15.6.07
    [[self window] setTitle:[NSString stringWithFormat:@"IPE-DAQ-V3 SLT"]];	
	[self populatePullDown];
    [self updateWindow];
}

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORAugerSLTSettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(serviceChanged:)
                         name : @"ORFireWireInterfaceServiceAliveChanged"
                       object : [model fireWireInterface]];

    [notifyCenter addObserver : self
                     selector : @selector(deviceOpenChanged:)
                         name : @"ORFireWireInterfaceIsOpenChanged"
                       object : [model fireWireInterface]];

    [notifyCenter addObserver : self
                     selector : @selector(controlRegChanged:)
                         name : ORAugerSLTControlRegChanged
                       object : model];

    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : ORAugerSLTSelectedRegIndexChanged
					   object : model];
	
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : ORAugerSLTWriteValueChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(statusRegChanged:)
                         name : ORAugerSLTStatusRegChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(pulserAmpChanged:)
                         name : ORAugerSLTPulserAmpChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(pulserDelayChanged:)
                         name : ORAugerSLTPulserDelayChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(usePBusSimChanged:)
                         name : ORAugerPBusSimChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(nHitChanged:)
                         name : ORAugerSLTModelNHitChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(nHitThresholdChanged:)
                         name : ORAugerSLTModelNHitThresholdChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORAugerSLTModelFpgaVersionChanged
						object: model];

}

#pragma mark ¥¥¥Interface Management

- (void) nHitThresholdChanged:(NSNotification*)aNote
{
	[nHitThresholdField setIntValue: [model nHitThreshold]];
	[nHitThresholdStepper setIntValue: [model nHitThreshold]];
}

- (void) nHitChanged:(NSNotification*)aNote
{
	[nHitField setIntValue: [model nHit]];
	[nHitStepper setIntValue: [model nHit]];
}

- (void) updateWindow
{
    [super updateWindow];
    [self settingsLockChanged:nil];
	[self serviceChanged:nil];
	[self deviceOpenChanged:nil];
	[self controlRegChanged:nil];
	[self statusRegChanged:nil];
    [self writeValueChanged:nil];
    [self pulserAmpChanged:nil];
    [self pulserDelayChanged:nil];
    [self selectedRegIndexChanged:nil];
    [self usePBusSimChanged:nil];
	[self nHitChanged:nil];
	[self nHitThresholdChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORAugerSLTSettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORAugerSLTSettingsLock];
    BOOL locked = [gSecurity isLocked:ORAugerSLTSettingsLock];
	BOOL isRunning = [gOrcaGlobals runInProgress];
	
	BOOL nHitSupported = ([model fpgaVersion] == 3.5);
	
	[readControlButton setEnabled:!lockedOrRunningMaintenance];
	[writeControlButton setEnabled:!lockedOrRunningMaintenance];
    [controlCheckBoxMatrix setEnabled:!lockedOrRunningMaintenance];
    [inhibitCheckBoxMatrix setEnabled:!lockedOrRunningMaintenance];

	[readStatusButton setEnabled:!lockedOrRunningMaintenance];

	[dumpROMButton setEnabled:!locked];
	[versionButton setEnabled:!isRunning];
	[deadTimeButton setEnabled:!isRunning];
	[vetoTimeButton setEnabled:!isRunning];
	[resetHWButton setEnabled:!isRunning];
	[usePBusSimButton setEnabled:!isRunning];

	[pulserAmpField setEnabled:!locked];

	[nHitThresholdField setEnabled:nHitSupported && !lockedOrRunningMaintenance];
	[nHitThresholdStepper setEnabled:nHitSupported && !lockedOrRunningMaintenance];
	[nHitField setEnabled:nHitSupported && !lockedOrRunningMaintenance];
	[nHitStepper setEnabled:nHitSupported && !lockedOrRunningMaintenance];
	
    [settingLockButton setState: lockedOrRunningMaintenance];
	[versionField setFloatValue: [model fpgaVersion]];

	[self enableRegControls];
}

- (void) enableRegControls
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORAugerSLTSettingsLock];
	short index = [model selectedRegIndex];
	BOOL readAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kAugerRegReadable)>0;
	BOOL writeAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kAugerRegWriteable)>0;

	[regWriteButton setEnabled:writeAllowed];
	[regReadButton setEnabled:readAllowed];
	
	[regWriteValueStepper setEnabled:writeAllowed];
	[regWriteValueTextField setEnabled:writeAllowed];
}

- (void) endAllEditing:(NSNotification*)aNotification
{
}

- (void) writeValueChanged:(NSNotification*) aNote
{
	[self updateStepper:regWriteValueStepper setting:[model writeValue]];
	[regWriteValueTextField setIntValue:[model writeValue]];
}

- (void) usePBusSimChanged:(NSNotification*) aNote
{
	[usePBusSimButton setState:[model pBusSim]];
}

- (void) selectedRegIndexChanged:(NSNotification*) aNote
{
	short index = [model selectedRegIndex];
	[self updatePopUpButton:registerPopUp	 setting:index];

	[self enableRegControls];
}

- (void) serviceChanged:(NSNotification*)aNote
{
	if(aNote== nil || [aNote object] == [model fireWireInterface] ){
		//NSLog(@"%@ station %d: firewire service %@\n",[model className],[model stationNumber],[[model fireWireInterface] serviceAlive]?@"OK":@"interrupted");
	}
}

- (void) deviceOpenChanged:(NSNotification*)aNote
{
	if(aNote== nil || [aNote object] == [model fireWireInterface] ){
		//NSLog(@"%@ station %d: firewire service %@\n",[model className],[model stationNumber],[[model fireWireInterface] isOpen]?@"open":@"closed");
		//if(![[model fireWireInterface] isOpen]){
			//[model startConnectionAttempts];
		//}
	}
}

- (void) controlRegChanged:(NSNotification*)aNote
{

	[[controlCheckBoxMatrix cellWithTag:0] setIntValue:[model ledInhibit]];
	[[controlCheckBoxMatrix cellWithTag:1] setIntValue:[model ledVeto]];
	[[controlCheckBoxMatrix cellWithTag:2] setIntValue:[model enableDeadTimeCounter]];

	int value = [model inhibitSource];
	[[inhibitCheckBoxMatrix cellWithTag:0] setIntValue:value&0x1];
	[[inhibitCheckBoxMatrix cellWithTag:1] setIntValue:(value>>1)&0x1];
	[[inhibitCheckBoxMatrix cellWithTag:2] setIntValue:(value>>2)&0x1];

	
	[watchDogPU selectItemAtIndex:[watchDogPU indexOfItemWithTag:[model watchDogStart]]];
	[secStrobeSrcPU selectItemAtIndex:[secStrobeSrcPU indexOfItemWithTag:[model secStrobeSource]]];
	[startSrcPU selectItemAtIndex:[startSrcPU indexOfItemWithTag:[model testPulseSource]]];
	[triggerSrcPU selectItemAtIndex:[triggerSrcPU indexOfItemWithTag:[model triggerSource]]];
		
	
}

- (void) statusRegChanged:(NSNotification*)aNote
{

	[[statusCheckBoxMatrix cellWithTag:0] setIntValue:[model veto]];
	[[statusCheckBoxMatrix cellWithTag:1] setIntValue:[model extInhibit]];
	[[statusCheckBoxMatrix cellWithTag:2] setIntValue:[model nopgInhibit]];
	[[statusCheckBoxMatrix cellWithTag:3] setIntValue:[model swInhibit]];
	[[statusCheckBoxMatrix cellWithTag:4] setIntValue:[model inhibit]];
	[[statusCheckBoxMatrix cellWithTag:5] setIntValue:[model resetTriggerFPGA]];
	[[statusCheckBoxMatrix cellWithTag:6] setIntValue:[model resetFLT]];
	[[statusCheckBoxMatrix cellWithTag:7] setIntValue:[model standbyFLT]];
	[[statusCheckBoxMatrix cellWithTag:8] setIntValue:[model suspendPLL]];
	[[statusCheckBoxMatrix cellWithTag:9] setIntValue:[model suspendClock]];

}


- (void) populatePullDown
{
    short	i;
        
// Clear all the popup items.
    [registerPopUp removeAllItems];
    
// Populate the register popup
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerPopUp insertItemWithTitle:[model getRegisterName:i] atIndex:i];
    }
}

- (void) pulserAmpChanged:(NSNotification*) aNote
{
	[pulserAmpField setFloatValue:[model pulserAmp]];
}

- (void) pulserDelayChanged:(NSNotification*) aNote
{
	[pulserDelayField setFloatValue:[model pulserDelay]];
}


#pragma mark ***Actions

- (void) nHitThresholdAction:(id)sender
{
	[model setNHitThreshold:[sender intValue]];	
}

- (void) nHitAction:(id)sender
{
	[model setNHit:[sender intValue]];	
}

- (IBAction) usePBusSimAction:(id)sender
{
	[model setPBusSim:[sender intValue]];
}

- (IBAction) readControlButtonAction:(id)sender
{
	[self endEditing];
	NS_DURING
		[model readControlReg];
	NS_HANDLER
		NSLog(@"Exception reading SLT reg: controlReg\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) writeControlButtonAction:(id)sender
{
	[self endEditing];
	NS_DURING
		[model writeControlReg];
	NS_HANDLER
		NSLog(@"Exception writing SLT reg: controlReg\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) readStatusButtonAction:(id)sender
{
	NS_DURING
		[model readStatusReg];
	NS_HANDLER
		NSLog(@"Exception reading SLT reg: statusReg\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORAugerSLTSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) dumpROMAction:(id)sender
{
	NS_DURING
		[model dumpROM];
	NS_HANDLER
		NSLog(@"Exception reading SLT ROM\n");
        NSRunAlertPanel([localException name], @"%@\nSLT Access failed", @"OK", nil, nil,
                        localException);
	NS_ENDHANDLER
}

- (IBAction) controlRegAction:(id)sender
{
	int tag		= [sender tag];
	int value	= [[sender itemAtIndex:[sender indexOfSelectedItem]] tag];
	switch(tag){
		case 0:	[model setWatchDogStart:value]; break;
		case 1:	[model setSecStrobeSource:value]; break;
		case 2:	[model setTestPulseSource:value]; break;
		case 4:	[model setTriggerSource:value]; break;

	}
}

- (IBAction) selectRegisterAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[model undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
		[self settingsLockChanged:nil];
    }
}

- (IBAction) writeValueAction:(id) aSender
{
	[self endEditing];
    // Make sure that value has changed.
    if ([aSender intValue] != [model writeValue]){
		[[model undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}

- (IBAction) readRegAction: (id) sender
{
	int index = [registerPopUp indexOfSelectedItem];
	NS_DURING
		unsigned long value = [model readReg:index];
		NSLog(@"SLT reg: %@ value: 0x%x\n",[model getRegisterName:index],value);
	NS_HANDLER
		NSLog(@"Exception reading SLT reg: %@\n",[model getRegisterName:index]);
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}
- (IBAction) writeRegAction: (id) sender
{
	[self endEditing];
	int index = [registerPopUp indexOfSelectedItem];
	NS_DURING
		[model writeReg:index value:[model writeValue]];
		NSLog(@"wrote 0x%x to SLT reg: %@ \n",[model writeValue],[model getRegisterName:index]);
	NS_HANDLER
		NSLog(@"Exception writing SLT reg: %@\n",[model getRegisterName:index]);
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) versionAction: (id) sender
{
	NS_DURING
		NSLog(@"SLT Hardware Model Version: %.1f\n",[model readVersion]);
	NS_HANDLER
		NSLog(@"Exception reading SLT HW Model Version\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) deadTimeAction: (id) sender
{
	NS_DURING
		NSLog(@"SLT Dead Time: %lld\n",[model readDeadTime]);
	NS_HANDLER
		NSLog(@"Exception reading SLT Dead Time\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) vetoTimeAction: (id) sender
{
	NS_DURING
		NSLog(@"SLT Veto Time: %lld\n",[model readVetoTime]);
	NS_HANDLER
		NSLog(@"Exception reading SLT Veto Time\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) resetHWAction: (id) pSender
{
	NS_DURING
		[model hw_config];
		[model hw_reset];
	NS_HANDLER
		NSLog(@"Exception reading SLT HW Reset\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

- (IBAction) controlCheckBoxAction:(id) sender
{
	switch([[sender selectedCell]tag]){
		case 0: [model setLedInhibit:[[sender selectedCell]state]]; break;
		case 1: [model setLedVeto:[[sender selectedCell]state]]; break;
		case 2: [model setEnableDeadTimeCounter:[[sender selectedCell]state]]; break;
		default: break;
	}
}

- (IBAction) inhibitCheckBoxAction:(id) sender
{
	int tag = [[sender selectedCell]tag];
	int value = [model inhibitSource];
	
	if([[sender selectedCell]state])value |= (1<<tag);
	else	 value &= ~(1<<tag);
	[model setInhibitSource:value];
}

- (IBAction) pulserAmpAction: (id) sender
{
	[model setPulserAmp:[sender floatValue]];
}

- (IBAction) pulserDelayAction: (id) sender
{
	[model setPulserDelay:[sender floatValue]];
}

- (IBAction) loadPulserAction: (id) sender
{
	NS_DURING
		[model loadPulserValues];
	NS_HANDLER
		NSLog(@"Exception loading SLT pulser values\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d load pulser failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
	
}

- (IBAction) pulseOnceAction: (id) sender
{
	NS_DURING
		[model pulseOnce];
	NS_HANDLER
		NSLog(@"Exception doing SLT pulse\n");
        NSRunAlertPanel([localException name], @"%@\nSLT%d pulse failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	NS_ENDHANDLER
}

@end



