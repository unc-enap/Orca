//
//  SubviewTableViewCell.m
//  SubviewTableViewRuleEditor
//
//  Created by Mark Howe on Tue Dec 02 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "SubviewTableViewCell.h"

#import "SubviewTableViewController.h"

@implementation SubviewTableViewCell

- (void) addSubview:(NSView *) view
{
    // Weak reference
    subview = view;
}

- (void) dealloc
{
    subview = nil;

    [super dealloc];
}

- (NSView *) view
{
    return subview;
}

- (void) drawWithFrame:(NSRect) cellFrame inView:(NSView *) controlView
{
    [super drawWithFrame: cellFrame inView: controlView];

    [[self view] setFrame: cellFrame];

    if ([[self view] superview] != controlView)
    {
	[controlView addSubview: [self view]];
    }
}

@end
