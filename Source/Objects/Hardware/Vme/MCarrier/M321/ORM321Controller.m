//
//  ORM321Controller.m
//  Orca
//
//  Created by Mark Howe on Mon Feb 10 2003.
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
#import "ORM321Controller.h"
#import "ORM321Model.h"

#import "ORMotorSweeper.h"

#pragma mark ¥¥¥Definitions

@implementation ORM321Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"M321"];
    return self;
}



#pragma mark ¥¥¥Notifications
-(void)registerNotificationObservers
{
	[super registerNotificationObservers];
	
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
	
	[notifyCenter addObserver : self
                     selector : @selector(fourPhaseChanged:)
                         name : ORM321FourPhaseChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : [model guardian]];
	
}


#pragma mark ¥¥¥Accessors


#pragma mark ¥¥¥Interface Management

-(void)updateWindow
{
	[super updateWindow];
    [self slotChanged:nil];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    if([aNotification object] == model || [aNotification object] == [model guardian]){
		[[self window] setTitle:[NSString stringWithFormat:@"M361 (Slot %d, Module %d)",[[model guardian] slot],[model slot]]];
    }
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"M361 (Slot %d, Module %d)",[[model guardian] slot],[model slot]]];
}


- (void) updateButtons:(NSNotification*)aNote
{
}


- (void) fourPhaseChanged:(NSNotification*)aNote
{
	[self updateButtons:nil];
}



#pragma mark ¥¥¥Actions

- (IBAction) statusAction:(id)sender
{
    @try {
        [(ORM321Model*)model status];
    }
	@catch(NSException* localException) {
        NSLog(@"Exception on M321 Status: %@\n",localException);
    }
}

- (IBAction) probeAction:(id)sender
{
    @try {
        [model probe];
    }
	@catch(NSException* localException) {
        NSLog(@"Exception on M321 Probe: %@\n",localException);
    }
}

- (IBAction) syncAction:(id)sender
{
    @try {
        [model sync];
    }
	@catch(NSException* localException) {
        NSLog(@"Exception on M321 Sync: %@\n",localException);
    }
}

@end
