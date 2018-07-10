//
//  ORContainerFeedThruController.m
//  Orca
//
//  Created by Mark Howe on Wed Oct 12, 2005.
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
#import "ORContainerFeedThruController.h"
#import "ORContainerFeedThru.h"


@implementation ORContainerFeedThruController

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                        selector : @selector(containerFeedThruChanged:)
                        name : ORContainerFeedThruChangedNotification
                        object : model];

    
}

#pragma mark ¥¥¥Actions
-(IBAction)containerFeedThruAction:(id)sender
{
    if([sender intValue] != [model numberOfFeedThrus]){
        [model setNumberOfFeedThrus:[sender intValue]];
    }
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [self containerFeedThruChanged:nil];
}

- (void) containerFeedThruChanged:(NSNotification*)aNotification
{
	[containerFeedThruStepper setIntValue:[model numberOfFeedThrus]];
	[containerFeedThruTextField setIntValue: [model numberOfFeedThrus]];
}

@end
