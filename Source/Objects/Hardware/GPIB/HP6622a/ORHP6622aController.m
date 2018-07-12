//
//  ORHP6622aController.m
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORHP6622aController.h"
#import "ORHP6622aModel.h"
#import "ORAxis.h"


@interface ORHP6622aController (private)
- (void) _clearSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) systemTest;
@end

@implementation ORHP6622aController
- (id) init
{
    self = [ super initWithWindowNibName: @"HP6622a" ];
    return self;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
	
    [ notifyCenter addObserver: self
                      selector: @selector( lockChanged: )
                          name: ORRunStatusChangedNotification
                        object: nil];
    
	[notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORHP6622aLock
                        object: model];
	
	[notifyCenter addObserver : self
					  selector: @selector(lockChanged:)
						  name: ORHP6622aModelLockGUIChanged
					   object : model];
	
	
	[notifyCenter addObserver : self
					  selector: @selector(lockChanged:)
						  name: ORHP6622aModelLockGUIChanged
					   object : model];
	
	[notifyCenter addObserver : self
					  selector: @selector(outputOnChanged:)
						  name: ORHP6622aOutputOnChanged
					   object : model];
	
	
	[notifyCenter addObserver : self
					  selector: @selector(ocProtectionOnChanged:)
						  name: ORHP6622aOcProtectionOnChanged
					   object : model];
	
	[notifyCenter addObserver : self
					  selector: @selector(setVoltageChanged:)
						  name: ORHP6622aSetVolageChanged
					   object : model];
	
	[notifyCenter addObserver : self
					  selector: @selector(actVoltageChanged:)
						  name: ORHP6622aActVolageChanged
					   object : model];
	
	[notifyCenter addObserver : self
					  selector: @selector(overVoltageChanged:)
						  name: ORHP6622aOverVolageChanged
					   object : model];
	
	[notifyCenter addObserver : self
					  selector: @selector(setCurrentChanged:)
						  name: ORHP6622aSetCurrentChanged
					   object : model];
	
	[notifyCenter addObserver : self
					  selector: @selector(actCurrentChanged:)
						  name: ORHP6622aActCurrentChanged
					   object : model];
}

- (void) updateWindow
{
    [ super updateWindow ];
    [self lockChanged:nil];
    [self outputOnChanged:nil];
    [self ocProtectionOnChanged:nil];
    [self setVoltageChanged:nil];
    [self actVoltageChanged:nil];
    [self setCurrentChanged:nil];
    [self overVoltageChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORHP6622aLock to:secure];
    
    [lockButton setEnabled:secure];
}

- (void) lockChanged: (NSNotification*) aNotification
{
	[self setButtonStates];
	
}

- (void) primaryAddressChanged:(NSNotification*)aNotification
{
	[super primaryAddressChanged:aNotification];
	[[self window] setTitle:[model title]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[model title]];
}

- (void) setButtonStates
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORHP6622aLock];
	BOOL runInProgress  = [gOrcaGlobals runInProgress];
	
	//BOOL locked		= [gSecurity isLocked:ORHP6622aLock];
	
	[sendCommandButton setEnabled:!lockedOrRunningMaintenance];
	[commandField setEnabled:!lockedOrRunningMaintenance];
	
	[outputOnMatrix     setEnabled:!lockedOrRunningMaintenance];
	[setVoltageMatrix   setEnabled:!lockedOrRunningMaintenance];
	[setCurrentMatrix   setEnabled:!lockedOrRunningMaintenance];
	[overVoltageMatrix  setEnabled:!lockedOrRunningMaintenance];
	[ocProtectionMatrix setEnabled:!lockedOrRunningMaintenance];
	[ocProtectionMatrix setEnabled:!lockedOrRunningMaintenance];
	[sendToHWButton     setEnabled:!lockedOrRunningMaintenance];
	[readFromHWButton   setEnabled:!lockedOrRunningMaintenance];
	
	NSString* s = @"";
	if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORHP6622aLock])s = @"Not in Maintenance Run.";
    }
    [lockDocField setStringValue:s];
}

- (void) actCurrentChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[[actCurrentMatrix cellWithTag:i] setFloatValue:[model actCurrent:i]];
	}
}


- (void) setCurrentChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[[setCurrentMatrix cellWithTag:i] setFloatValue:[model setCurrent:i]];
	}
}

- (void) overVoltageChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[[overVoltageMatrix cellWithTag:i] setFloatValue:[model overVoltage:i]];
	}
}

- (void) actVoltageChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[[actVoltageMatrix cellWithTag:i] setFloatValue:[model actVoltage:i]];
	}
}


- (void) outputOnChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[[outputOnMatrix cellWithTag:i] setState:[model outputOn:i]];
	}
}

- (void) ocProtectionOnChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[[ocProtectionMatrix cellWithTag:i] setState:[model ocProtectionOn:i]];
	}
}

- (void) setVoltageChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<kHP6622aNumberSupplies;i++){
		[[setVoltageMatrix cellWithTag:i] setFloatValue:[model setVoltage:i]];
	}
}


#pragma mark ¥¥¥Actions
- (IBAction) sendCommandAction:(id)sender
{
	@try {
		[self endEditing];
		if([commandField stringValue]){
			[model writeToGPIBDevice:[commandField stringValue]];
		}
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
 		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
	
}


- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORHP6622aLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) idAction:(id)sender
{
	@try {
		[model readIDString];
		
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
 		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}
- (IBAction) testAction:(id)sender
{
	@try {
		[model doSelfTest];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}

- (IBAction) sendToHWAction:(id)sender
{
	@try {
		[self endEditing];
		[model sendAllToHW];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}

- (IBAction) readHWAction:(id)sender
{
	@try {
		[self endEditing];
		[model readAllHW];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);

	}
}

- (IBAction) outputOnAction:(id)sender
{
	@try {
		[model setOutputOn:(int)[[sender selectedCell] tag] withValue:[[sender selectedCell] intValue]];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}

- (IBAction) ocProtectionOnAction:(id)sender
{
	@try {
		[model setOcProtectionOn:(int)[[sender selectedCell] tag] withValue:[[sender selectedCell] intValue]];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}

- (IBAction) setVoltageAction:(id)sender
{
	@try {
		[model setSetVoltage:(int)[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}

- (IBAction) setCurrentAction:(id)sender
{
	@try {
		[model setSetCurrent:(int)[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}

- (IBAction) setOverVoltageAction:(id)sender
{
	@try {
		[model setOverVoltage:(int)[[sender selectedCell] tag] withValue:[[sender selectedCell] floatValue]];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}

- (IBAction) resetOverVoltageAction:(id)sender
{
	@try {
		[model resetOverVoltage:(int)[[sender selectedCell] tag]];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}

- (IBAction) resetOcProtectionAction:(id)sender
{
	@try {
		[model resetOcProtection:(int)[[sender selectedCell] tag]];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
}

- (IBAction) setClearAction:(id)sender
{
	@try {
		[model sendClear];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",				// Okay button
						nil,				// alternate button
						nil, 				// other button
                        [localException reason]);
	}
}


@end
