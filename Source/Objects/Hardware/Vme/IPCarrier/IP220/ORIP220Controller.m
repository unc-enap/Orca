//
//  ORIP220Controller.m
//  Orca
//
//  Created by Mark Howe on Tue Jun 5 2007.
//  Copyright Â© 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORIP220Controller.h"
#import "ORIP220Model.h"


#pragma mark ¥¥¥Definitions

@implementation ORIP220Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"IP220"];
    
    return self;
}



#pragma mark ¥¥¥Notifications
-(void)registerNotificationObservers
{
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(outputValuesChanged:)
                         name : ORIP220VoltageChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(transferModeChanged:)
                         name : ORIP220TransferModeChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORVmeCardSlotChangedNotification
                       object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORIP220SettingsLock
						object: nil];
}

#pragma mark ¥¥¥Interface Management
-(void)updateWindow
{
	[super updateWindow];
    [self outputValuesChanged:nil];
    [self transferModeChanged:nil];
	[self slotChanged:nil];
    [self settingsLockChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORIP220SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORIP220SettingsLock];
    BOOL locked = [gSecurity isLocked:ORIP220SettingsLock];
	
    [settingLockButton setState: locked];
    [outputValuesMatrix setEnabled:!lockedOrRunningMaintenance];
    [transferModeMatrix setEnabled:!lockedOrRunningMaintenance];
    [writeButton setEnabled:!lockedOrRunningMaintenance];
    [readButton setEnabled:!lockedOrRunningMaintenance];
    [resetButton setEnabled:!lockedOrRunningMaintenance];
}


- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"IP220 (%@)",[model identifier]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"IP220 (%@)",[model identifier]]];
}

- (void) transferModeChanged:(NSNotification*)aNotification
{
	[transferModeMatrix selectCellWithTag:[model transferMode]];
}

- (void) outputValuesChanged:(NSNotification*)aNotification
{
	if(aNotification){
		int index = [[[aNotification userInfo] objectForKey:@"Channel"] intValue];
		[[outputValuesMatrix cellWithTag:index] setFloatValue:[model outputVoltage:index]];
	}
	else {
		int i;
		for(i=0;i<16;i++){
			[[outputValuesMatrix cellWithTag:i] setFloatValue:[model outputVoltage:i]];
		}
	}
}


#pragma mark ¥¥¥Actions
- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORIP220SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) transferModeAction:(id)sender
{
	[model setTransferMode:[[sender selectedCell] tag]];
}

- (IBAction) outputValuesAction:(id)sender
{
	[model setOutputVoltage:[[sender selectedCell] tag] withValue:[sender floatValue]];
}

- (IBAction) read:(id)sender
{
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"IP220 Read"];
    [alert setInformativeText:@"Really read the IP220 Values into this dialog. Current values will be lost!"];
    [alert addButtonWithTitle:@"Yes/Read"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model readBoard];
        }
    }];
#else
    NSBeginAlertSheet(@"IP220 Read",@"Cancel",@"YES/Read",nil,[self window],self,@selector(sheetDidEnd:returnCode:contextInfo:),nil,nil, @"Really read the IP220 Values into this dialog. Current values will be lost!");
#endif
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode == NSAlertAlternateReturn){
		[model readBoard];
	}
}
#endif
- (IBAction) write:(id)sender
{
	@try {
		[self endEditing];
		[model initBoard];
	}
	@catch(NSException* localException) {
        NSLog(@"Write Op of IP220 Values FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed IP220 Write Op", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) resetAction:(id)sender
{
	@try {
		[model resetBoard];
	}
	@catch(NSException* localException) {
        NSLog(@"Reset Op of IP220 Values FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed IP220 Reset Op", @"OK", nil, nil,
                        localException);
	}
}

@end
