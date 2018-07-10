//
//  ORCountDownController.m
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
#import "ORCountDownController.h"
#import "ORCountDownModel.h"


@implementation ORCountDownController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"CountDown"];
    return self;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver: self
                     selector: @selector(countDownLockChanged:)
                         name: ORCountDownLock
                       object: nil];
    
    [notifyCenter addObserver: self
                     selector: @selector(countDownTextChanged:)
                         name: ORCountDownStartCountChangedNotification
                       object: nil];


}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self countDownLockChanged:nil];
    [self countDownTextChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORCountDownLock to:secure];
    [countDownLockButton setEnabled:secure];
}

- (void) countDownLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORCountDownLock];
    [countDownLockButton setState: locked];
    [startCountField setEnabled: !locked];
}

- (void) countDownTextChanged:(NSNotification *)aNotification
{
	[startCountField setIntValue:[model startCount]];
}

#pragma mark ¥¥¥Actions
-(IBAction)countDownLockAction:(id)sender
{
    [gSecurity tryToSetLock:ORCountDownLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) countDownTextAction:(id)sender
{
	[model setStartCount:[sender intValue]];
}


@end
