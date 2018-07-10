//
//  NcdMuxController.m
//  Orca
//
//  Created by Mark Howe on Thurs Feb 20 2003.
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
#import "NcdMuxController.h"
#import "NcdMuxModel.h"


#pragma mark ¥¥¥Definitions

@implementation NcdMuxController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"NcdMux"];

	return self;
}


#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{	

	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(scopeSelectionChanged:)
                         name : NcdMuxScopeSelectionChangedNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(errorCountChanged:)
                         name : NcdMuxErrorCountChangedNotification
                       object : model];

					
}

- (void) scopeSelectionChanged:(NSNotification*)aNotification
{
	if([model scopeSelection] != [[scopeSelectionMatrix selectedCell] tag]){
		[scopeSelectionMatrix selectCellWithTag:[model scopeSelection]];
	}
}

- (void) errorCountChanged:(NSNotification*)aNotification
{
	[armErrorField setIntValue: [model armError]];
	[eventReadErrorField setIntValue: [model eventReadError]];
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
	[self scopeSelectionChanged:nil];
	[self scopeSelectionChanged:nil];
}


#pragma mark ¥¥¥Actions
- (IBAction) scopeSelectionAction:(id)sender
{
	if([model scopeSelection] != [[scopeSelectionMatrix selectedCell] tag]){
		[[self undoManager] setActionName: @"Set Mux Scope Selection"];
		[model setScopeSelection:[[sender selectedCell] tag]];
	}
}

- (IBAction) reArmAction:(id)sender
{
    [model reArm];
	NSLog(@"Mux forced reArm\n");
}

@end
