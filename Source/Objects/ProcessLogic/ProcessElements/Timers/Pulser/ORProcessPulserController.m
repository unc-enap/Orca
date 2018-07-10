//
//  ORProcessPulserController.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 18 2005.
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
#import "ORProcessPulserController.h"
#import "ORProcessPulserModel.h"


@implementation ORProcessPulserController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"ProcessPulser"];
    return self;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(cycleTimeChanged:)
                         name : ORProcessPulseCycleTimeChangedNotification
                       object : model];
    

    [notifyCenter addObserver: self
                     selector: @selector(pulserLockChanged:)
                         name: ORProcessPulseLock
                       object: nil];
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self cycleTimeChanged:nil];
    [self pulserLockChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORProcessPulseLock to:secure];
    [pulserLockButton setEnabled:secure];
}

- (void) pulserLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORProcessPulseLock];
    [pulserLockButton setState: locked];
    [cycleTimeField setEnabled: !locked];
}

- (void) cycleTimeChanged:(NSNotification*)aNote;
{
	[cycleTimeField setFloatValue:[model cycleTime]];
}

#pragma mark ¥¥¥Actions
- (void) cycleTimeAction:(id)sender
{
    [model setCycleTime:[sender floatValue]];
}

-(IBAction)pulserLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORProcessPulseLock to:[sender intValue] forWindow:[self window]];
}



@end
