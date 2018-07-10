//
//  ORFanInController.m
//  Orca
//
//  Created by Mark Howe on Wed Jan 1, 2003.
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
#import "ORFanInController.h"
#import "ORFanInModel.h"


@implementation ORFanInController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"FanIn"];
	return self;
}


#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                        selector : @selector(fanInChanged:)
                        name : ORFanInChangedNotification
                        object : model];
    
}

#pragma mark ¥¥¥Actions
-(IBAction)fanInAction:(id)sender
{
    if([sender intValue] != [model numberOfInputs]){
        [[self undoManager] setActionName: @"Set Fan In"];
        [model adjustNumberOfInputs:[sender intValue]];
    }
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
    [self fanInChanged:nil];
}

- (void) fanInChanged:(NSNotification*)aNotification
{
	[fanInStepper setIntValue:[model numberOfInputs]];
	[fanInTextField setIntValue: [model numberOfInputs]];
}



@end
