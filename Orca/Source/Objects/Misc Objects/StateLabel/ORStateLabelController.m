
//
//  ORStateLabelController.m
//  Orca
//
//  Created by Mark Howe on Fri Dec 4,2009.
//  Copyright © 2009 University of North Carolina. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORStateLabelController.h"
#import "ORStateLabelModel.h"

@implementation ORStateLabelController

#pragma mark •••Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"StateLabel"];
    return self;
}


#pragma mark •••Interface Management

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    

	[notifyCenter addObserver : self
                     selector : @selector(boolTypeChanged:)
                         name : ORLabelModelBoolTypeChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(trueColorChanged:)
                         name : ORLabelModelTrueColorChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(falseColorChanged:)
                         name : ORLabelModelFalseColorChanged
						object: model];
	
}

- (void) updateWindow
{
	[super updateWindow];
	[self boolTypeChanged:nil];
	[self trueColorChanged:nil];
	[self falseColorChanged:nil];
}

- (void) boolTypeChanged:(NSNotification*)aNotification
{
	[boolTypePU selectItemAtIndex:[model boolType]];
}

- (void) labelLockChanged:(NSNotification*)aNotification
{
    BOOL locked = [gSecurity isLocked:ORLabelLock];
    [boolTypePU setEnabled: !locked];
	[super labelLockChanged:aNotification];
}

- (void) trueColorChanged:(NSNotification*)aNotification
{
	[trueColorWell setColor:[model trueColor]];
}

- (void) falseColorChanged:(NSNotification*)aNotification
{
	[falseColorWell setColor:[model falseColor]];
}

#pragma mark •••Actions
- (IBAction) boolTypeAction:(id)sender
{
	[model setBoolType:[sender indexOfSelectedItem]];
}

- (IBAction) trueColorAction:(id)sender
{
	[model setTrueColor:[sender color]];
}

- (IBAction) falseColorAction:(id)sender
{
	[model setFalseColor:[sender color]];
}


@end
