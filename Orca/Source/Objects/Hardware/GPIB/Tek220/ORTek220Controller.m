//
//  ORTek220Controller.m
//  test
//
//  Created by Mark Howe on Thurs Apr 2, 2009.
//  Copyright 2009 CENPA, University of Washington. All rights reserved.
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


#import "ORTek220Controller.h"
#import "ORTek220Model.h"


@implementation ORTek220Controller

#pragma mark •••Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"ORTek220" ];
    return self;
}

- (void) registerNotificationObservers
{
//    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
}

#pragma mark ***Interface Management
- (void) updateWindow
{
    [ super updateWindow ];
}

- (NSString*) settingsLockName
{
    return ORTek220Lock;
}

- (NSString*) gpibLockName
{
    return ORTek220GpibLock;
}

@end
