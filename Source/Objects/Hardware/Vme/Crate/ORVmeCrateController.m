
//
//  ORVmeCrateController.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORVmeCrateController.h"
#import "ORVmeCrateModel.h"


@implementation ORVmeCrateController

- (id) init
{
    self = [super initWithWindowNibName:@"VmeCrate"];
    return self;
}

- (void) setCrateTitle
{
	[[self window] setTitle:[NSString stringWithFormat:@"VME crate %u",[model crateNumber]]];
}

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   

    [notifyCenter addObserver : self
                     selector : @selector(powerFailed:)
                         name : @"VmePowerFailedNotification"
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(powerRestored:)
                         name : @"VmePowerRestoredNotification"
                       object : nil];

}

#pragma mark ¥¥¥Actions
- (IBAction) printMemoryMap:(id)sender
{
	[model printMemoryMap];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
    [self setCrateTitle];
}


@end
