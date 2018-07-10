//-------------------------------------------------------------------------
//  ORComparatorController.h
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
#import "ORComparatorController.h"
#import "ORComparatorModel.h"

@implementation ORComparatorController

-(id)init
{
    self = [super initWithWindowNibName:@"Comparator"];

    return self;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];

    [notifyCenter addObserver : self
                     selector : @selector(rangeForEqualChanged:)
                         name : ORComparatorRangeForEqualChanged
						object: model];

}

- (void) updateWindow
{
	[super updateWindow];
	[self rangeForEqualChanged:nil];
}

#pragma mark ¥¥¥Interface Management

- (void) rangeForEqualChanged:(NSNotification*)aNote
{
	[rangeForEqualTextField setFloatValue: [model rangeForEqual]];
}

#pragma mark ¥¥¥Actions

- (void) rangeForEqualTextFieldAction:(id)sender
{
	[model setRangeForEqual:[sender floatValue]];	
}

@end
