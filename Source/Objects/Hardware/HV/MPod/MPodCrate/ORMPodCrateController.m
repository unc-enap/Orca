
//
//  ORMPodCrateController.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
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
#import "ORMPodCrateController.h"
#import "ORMPodCrateModel.h"

@implementation ORMPodCrateController

- (id) init
{
    self = [super initWithWindowNibName:@"MPodCrate"];
    return self;
}

- (void) setCrateTitle
{
	[[self window] setTitle:[NSString stringWithFormat:@"MPod Crate %d",[model crateNumber]]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
	[super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   

	
    [notifyCenter addObserver : self
                     selector : @selector(powerFailed:)
                         name : @"MPodPowerFailedNotification"
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(powerRestored:)
                         name : @"MPodPowerRestoredNotification"
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(constraintsChanged:)
                         name : ORMPodCrateConstraintsChanged
						object: nil];
}

- (void) updateWindow
{
	[super updateWindow];
	[self constraintsChanged:nil];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
    [self setCrateTitle];
}

- (void) constraintsChanged:(NSNotification*)aNote
{
	NSImage* smallLockImage = [NSImage imageNamed:@"smallLock"];
	if([[model hvConstraints] count]){
		[hvConstraintImage setImage:smallLockImage];
	}
	else [hvConstraintImage setImage:nil];
    [groupView setNeedsDisplay:YES];
    
}

#pragma mark •••Actions
- (IBAction) listConstraintsAction:(id)sender
{
	if([[model hvConstraints] count]){
        ORRunAlertPanel(@"Constraints", @"The Following Constraints are in place:\n%@", @"OK", nil, nil,
                        @"test constraint");
 
    }
}

@end
