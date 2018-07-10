//-------------------------------------------------------------------------
//  ORAdcRateController.h
//
//  Created by Mark A. Howe on Thursday 05/12/2011.
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//
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

#pragma mark ***Imported Files
#import "ORAdcRateController.h"
#import "ORAdcRateModel.h"

@implementation ORAdcRateController

-(id)init
{
    self = [super initWithWindowNibName:@"AdcRate"];

    return self;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];

    [notifyCenter addObserver : self
                     selector : @selector(rateLimitChanged:)
                         name : ORAdcRateModelRateLimitChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(validChanged:)
                         name : ORAdcRateModelValidChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(integrationTimeChanged:)
                         name : ORAdcRateModelIntegrationTimeChanged
						object: model];

}

- (void) updateWindow
{
	[super updateWindow];
	[self rateLimitChanged:nil];
	[self validChanged:nil];
	[self integrationTimeChanged:nil];
}

#pragma mark •••Interface Management

- (void) integrationTimeChanged:(NSNotification*)aNote
{
	[integrationTimeField setFloatValue: [model integrationTime]];
}

- (void) validChanged:(NSNotification*)aNote
{
	[validField setIntValue: [model valid]];
}

- (void) rateLimitChanged:(NSNotification*)aNote
{
	[rateLimitField setFloatValue: [model rateLimit]];
}

#pragma mark •••Actions

- (void) integrationTimeAction:(id)sender
{
	[model setIntegrationTime:[sender floatValue]];	
}

- (void) rateLimitAction:(id)sender
{
	[model setRateLimit:[sender floatValue]];	
}

@end
