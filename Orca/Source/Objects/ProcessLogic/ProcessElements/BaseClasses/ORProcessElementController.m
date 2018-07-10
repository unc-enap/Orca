//
//  ORProcessElementController.m
//  Orca
//
//  Created by Mark Howe on 11/20/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORProcessElementController.h"
#import "ORProcessElementModel.h"
#import "ORBitProcessing.h"

@implementation ORProcessElementController

#pragma mark ¥¥¥Interface Management
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
        
    [notifyCenter addObserver : self
                     selector : @selector(commentChanged:)
                         name : ORProcessCommentChangedNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(stateChanged:)
                         name : ORProcessElementStateChangedNotification
                       object : model];
}

- (void) updateWindow
{
    [super updateWindow];
	[self commentChanged:nil];
	[self stateChanged:nil];
}

- (void) setModel:(id)aModel
{    
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"%@-%lu",[model className],[(OrcaObject*)model processID]]];
    if(model)[self updateWindow];
}

- (void) commentChanged:(NSNotification*)aNote
{
	if([model comment]){
		[commentField setStringValue:[model comment]];
	}
}

- (void) stateChanged:(NSNotification*)aNote
{
	//subclasses can override if needed.
}


#pragma mark ¥¥¥Actions
- (IBAction) commentFieldAction:(id)sender
{
	[model setComment:[sender stringValue]];
}

@end
