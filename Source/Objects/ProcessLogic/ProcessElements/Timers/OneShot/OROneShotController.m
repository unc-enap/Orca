//
//  OROneShotController.m
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
#import "OROneShotController.h"
#import "OROneShotModel.h"


@implementation OROneShotController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"OneShot"];
    return self;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(oneShotTimeChanged:)
                         name : OROneShotTimeChangedNotification
                       object : model];
    
    [notifyCenter addObserver: self
                     selector: @selector(oneShotLockChanged:)
                         name: OROneShotLock
                       object: nil];
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self oneShotTimeChanged:nil];
    [self oneShotLockChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:OROneShotLock to:secure];
    [oneShotLockButton setEnabled:secure];
}

- (void) oneShotLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:OROneShotLock];
    [oneShotLockButton setState: locked];
    [oneShotTimeField setEnabled: !locked];
}

- (void) oneShotTimeChanged:(NSNotification*)aNote;
{
	[oneShotTimeField setFloatValue:[model oneShotTime]];
}

#pragma mark ¥¥¥Actions
- (void) oneShotTimeAction:(id)sender
{
    [model setOneShotTime:[sender floatValue]];
}

-(IBAction)oneShotLockAction:(id)sender
{
    [gSecurity tryToSetLock:OROneShotLock to:[sender intValue] forWindow:[self window]];
}


@end
