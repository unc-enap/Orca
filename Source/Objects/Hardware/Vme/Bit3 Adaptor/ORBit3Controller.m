//
//  ORBit3Controller.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
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
#import "ORBit3Controller.h"
#import "ORBit3Model.h"
#import "ORVmeCrateModel.h"



@implementation ORBit3Controller

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Bit3"];
	return self;
}


#pragma mark ¥¥¥Accessors
- (NSButton*) 		mainAdapterButton
{
	return mainAdapterButton;
}

- (NSTextField*) 	statusText
{
	return statusText;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [super registerNotificationObservers];
	[notifyCenter addObserver : self
				selector : @selector(statusChanged:)
				name : ORCrateAdapterChangedNotification
				object : [model crate]];

}

#pragma mark ¥¥¥Actions
- (IBAction) becomeCrateAdapter:(id) sender
{
	if([model isMaster] != YES){
		[[self undoManager] setActionName: @"Set Bit3 Adapter"];
		[model becomeMaster];
	}
	
}

#pragma mark ¥¥¥Interface Management
- (void) updateWindow
{
	[self statusChanged:nil];
}

- (void) statusChanged:(NSNotification*)aNotification
{
	[[self statusText] setStringValue: [model isMaster]?@"Primary Bit3 Adapter":@"Aux Bit 3 Adapter"];
	[mainAdapterButton setEnabled:![model isMaster]];
}

@end
