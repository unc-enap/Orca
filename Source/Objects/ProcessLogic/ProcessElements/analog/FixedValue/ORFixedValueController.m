//
//  ORFixedValueController.m
//  Orca
//
//  Created by Mark Howe on Jan 29 2013.
//  Copyright (c) 2013  University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Imported Files
#import "ORFixedValueController.h"
#import "ORFixedValueModel.h"

@implementation ORFixedValueController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"FixedValue"];
    return self;
}

#pragma mark ***Interface Management
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(fixedValueChanged:)
                         name : ORFixedValueFixedValueChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORFixedValueLock
						object: nil];
}

- (void) updateWindow
{
    [self fixedValueChanged:nil];
    [self lockChanged:nil];
	[super updateWindow];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORFixedValueLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL locked    = [gSecurity isLocked: ORFixedValueLock];
    [lockButton setState: locked];
    [fixedValueField setEnabled: !locked];
}

- (void) fixedValueChanged:(NSNotification*)aNote
{
    [fixedValueField setStringValue:[model fixedValue]];
}

#pragma mark ***Actions
- (IBAction) fixedValueAction:(id)sender
{
    [model setFixedValue:[fixedValueField stringValue]];
}

- (IBAction) lockButtonAction:(id)sender
{
    [gSecurity tryToSetLock:ORFixedValueLock to:[sender intValue] forWindow:[self window]];
}


@end
