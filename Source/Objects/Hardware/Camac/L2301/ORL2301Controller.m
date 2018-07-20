/*
 *  ORL2301ModelController.m
 *  Orca
 *
 *  Created by Sam Meijer, Jason Detwiler, and David Miller, July 2012.
 *  Adapted from AD811 code by Mark Howe, written Sat Nov 16 2002.
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
#import "ORL2301Controller.h"
#import "ORCamacExceptions.h"
#import "ORCamacExceptions.h"

#pragma mark ¥¥¥Macros


// methods
@implementation ORL2301Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"L2301"];
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
						 name : ORL2301SettingsLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(suppressZerosChanged:)
						 name : ORL2301SuppressZerosChangedNotification
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(includeTimingChanged:)
						 name : ORL2301ModelIncludeTimingChanged
					   object : model];	
	
	[notifyCenter addObserver : self
					 selector : @selector(allowOverflowChanged:)
						 name : ORL2301AllowOverflowChangedNotification
					   object : model];
	
}

#pragma mark ¥¥¥Interface Management

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
    [self suppressZerosChanged:nil];
    [self includeTimingChanged:nil];
    [self allowOverflowChanged:nil];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORL2301SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORL2301SettingsLock];
    BOOL locked = [gSecurity isLocked:ORL2301SettingsLock];
	
    [settingLockButton setState: locked];
	
    [clearAllButton setEnabled:!lockedOrRunningMaintenance];
    [startQVTButton setEnabled:!lockedOrRunningMaintenance];
    [stopQVTButton setEnabled:!lockedOrRunningMaintenance];
    [readAllButton setEnabled:!lockedOrRunningMaintenance];
    [statusButton setEnabled:!lockedOrRunningMaintenance];
    [testButton setEnabled:!lockedOrRunningMaintenance];
	
    [suppressZerosButton setEnabled:!lockedOrRunningMaintenance];
    [includeTimingButton setEnabled:!runInProgress];
    [allowOverflowButton setEnabled:!lockedOrRunningMaintenance];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORL2301SettingsLock]) s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
	
}


- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"L2301 (Station %d)",(int)[model stationNumber]]];
}


- (void) suppressZerosChanged:(NSNotification*)aNotification
{
	[suppressZerosButton setState:[model suppressZeros]];
}

- (void) includeTimingChanged:(NSNotification*)aNotification
{
	[includeTimingButton setState:[model includeTiming]];
}

- (void) allowOverflowChanged:(NSNotification*)aNotification;
{
	[allowOverflowButton setState:[model allowOverflow]];
}



#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Actions
- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORL2301SettingsLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) clearAllAction:(id)sender
{   
    @try {                               
        [model checkCratePower];                 
        [model reset];                          
        NSLog(@"L2301 Clear All for Station %d\n",[model stationNumber]);
    }   
    @catch(NSException* localException) {
        [self showError:localException name:@"Clear All" fCode:9];
    }                                      
}

- (IBAction) startQVTAction:(id)sender   
{
    @try {
        [model startQVT];
        NSLog(@"Started L2301 in station %d\n",[model stationNumber]);
    }
    @catch(NSException* localException) {
        [self showError:localException name:@"Read/Reset" fCode:9];
    }
}

- (IBAction) stopQVTAction:(id)sender
{
    @try {
        [model stopQVT];
        NSLog(@"Stopped L2301 in station %d\n",[model stationNumber]);
    }
    @catch(NSException* localException) {
        [self showError:localException name:@"Stop QVT" fCode:24];
    }
}

- (IBAction) readAllAction:(id)sender
{
    @try {
        NSLog(@"Reading All from L2301 station %d...\n",[model stationNumber]);
        [model setReadWriteBin:0];
        [model setReadWriteBin:0];
        unsigned int iBin;
        for(iBin = 0; iBin < kNBins; iBin++) {
            // read the counts for this bin
            // note: the internal read/write bin is set to iBin+1 after this call
            unsigned short counts = [model readQVT];
            if(!([model suppressZeros] && counts == 0)) {
                NSLog(@"L2301 station %d, bin %d: %d\n",[model stationNumber], iBin, counts);
            }
        }
    }
    @catch(NSException* localException) {
        [self showError:localException name:@"Read All" fCode:2];
    }
}

- (IBAction) statusAction:(id)sender
{
    @try {
        unsigned short status = [model readStatusRegister];
        NSLog(@"L2301 (Station %d) Status Register = 0x%04x\n",[model stationNumber],status);
        NSLog(@"LAM         : %@\n",status&0x1?@"ON":@"OFF");
        NSLog(@"LAM Enabled : %@\n",status&0x2?@"ON":@"OFF");
        NSLog(@"MEM Enabled : %@\n",status&0x4?@"ON":@"OFF");
        NSLog(@"CLUSTER     : %@\n",status&0x8?@"ON":@"OFF");
        
    }  
    @catch(NSException* localException) {
        [self showError:localException name:@"Status" fCode:0];
    }
}


- (IBAction) testAction:(id)sender
{
    @try {
        NSLog(@"L2301 Performing spot test on random channel\n");
        unsigned short randBin = arc4random()%1024;
        unsigned short randValue = arc4random()%65536;
        [model writeQVT:randValue atBin:randBin];
        NSLog(@"L2301 Value %d written to bin %d.\n",randValue, randBin);
        unsigned short returnValue = [model readQVTAt:randBin];
        NSLog(@"L2301 Value %d read from bin %d.\n", returnValue, randBin);
        if(randValue == returnValue){
            NSLog(@"L2301 passed test on channel %d\n",randBin);
        }
        else {
            NSLog(@"L2301 failed test on channel %d\n",randBin);
        }
    }
    @catch(NSException* localException) {
        [self showError:localException name:@"Test" fCode:25];
    }
}



- (IBAction) suppressZerosAction:(id)sender
{
	[model setSuppressZeros:[sender state]];
}

- (IBAction) includeTimingAction:(id)sender
{
	[model setIncludeTiming:[sender state]];
}

- (IBAction) allowOverflowAction:(id)sender
{
	[model setAllowOverflow:[sender state]];
}


- (void) showError:(NSException*)anException name:(NSString*)name fCode:(int)i
{
    NSLog(@"Failed Cmd: %@ (F%d)\n",name,i);
    if([[anException name] isEqualToString: OExceptionNoCamacCratePower]) {
        [[model crate]  doNoPowerAlert:anException action:[NSString stringWithFormat:@"%@ (F%d)",name,i]];
    }
    else {
        ORRunAlertPanel([anException name], @"%@\n%@ (F%d)", @"OK", nil, nil,
                        [anException name],name,i);
    }
}
@end



