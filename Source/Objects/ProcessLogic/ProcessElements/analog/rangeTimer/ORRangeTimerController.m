//
//  ORRangeTimerController.m
//  Orca
//
//  Created by Mark Howe on Fri Sept 8, 2006.
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
#import "ORRangeTimerController.h"
#import "ORRangeTimerModel.h"


@implementation ORRangeTimerController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"RangeTimer"];
    return self;
}

#pragma mark ¥¥¥Interface Management
- (BOOL)validateMenuItem:(NSMenuItem*)menuItem
{
    if ([menuItem action] == @selector(cut:)) {
        return [addressList selectedRow] >= 0 ;
    }
    else if ([menuItem action] == @selector(delete:)) {
        return [addressList selectedRow] >= 0;
    }
    else if ([menuItem action] == @selector(copy:)) {
        return NO; //enable when cut/paste is finished
    }
    else if ([menuItem action] == @selector(paste:)) {
        return NO; //enable when cut/paste is finished
    }
    return YES;
}


- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
        
    [notifyCenter addObserver : self
                     selector : @selector(directionChanged:)
                         name : ORRangeTimerModelDirectionChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(limitChanged:)
                         name : ORRangeTimerModelLimitChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(deadBandChanged:)
                         name : ORRangeTimerModelDeadbandChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(enableMailChanged:)
                         name : ORRangeTimerModelEnableMailChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(addressesChanged:)
                         name : ORRangeTimerModelAddressesChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(selectionChanged:)
                         name : NSTableViewSelectionIsChangingNotification
                       object : addressList];
}

- (void) updateWindow
{
    [super updateWindow];
	[self directionChanged:nil];
	[self limitChanged:nil];
	[self deadBandChanged:nil];
	[self enableMailChanged:nil];
	[self addressesChanged:nil];
	[self selectionChanged:nil];
}

- (void)setButtonStates
{
	[super setButtonStates];
    BOOL locked = [gSecurity isLocked:ORHWAccessLock];
    [deadBandTextField setEnabled: !locked];
    [enableMailButton setEnabled: !locked];
    [directionPU setEnabled: !locked];
    [limitTextField setEnabled: !locked];
    [addressList setEnabled: !locked];
    [removeAddressButton setEnabled: !locked && [addressList selectedRow]>=0];
    [addAddressButton setEnabled: !locked];	
}

- (void) enableMailChanged:(NSNotification*)aNote
{
	[enableMailButton setState: [model enableMail]];
}

- (void) selectionChanged:(NSNotification*)aNote
{
    BOOL locked = [gSecurity isLocked:ORHWAccessLock];
    [removeAddressButton setEnabled: !locked && [addressList selectedRow]>=0];
    [addAddressButton setEnabled: !locked];
}

- (void) addressesChanged:(NSNotification*)aNote
{
	[addressList reloadData];
}

- (void) directionChanged:(NSNotification*)aNote
{
	[deadBandTextField setIntValue:[model deadband]];
}

- (void) limitChanged:(NSNotification*)aNote
{
	[limitTextField setFloatValue:[model limit]];
}

- (void) deadBandChanged:(NSNotification*)aNote
{
	[directionPU selectItemAtIndex:[model direction]];
}

#pragma mark ¥¥¥Actions
- (IBAction) addAddressAction:(id)sender
{
	[model addAddress];
}

- (IBAction) removeAddressAction:(id)sender
{
}

- (void) enableMailAction:(id)sender
{
	[model setEnableMail:[sender intValue]];	
}
- (IBAction) deadBandAction:(id)sender
{
	[model setDeadband:[sender intValue]];
}

- (IBAction) limitAction:(id)sender
{
	[model setLimit:[sender floatValue]];
}

- (IBAction) directionAction:(id)sender
{
	[model setDirection:[sender indexOfSelectedItem]];
}

- (IBAction) delete:(id)sender
{
	if([addressList selectedRow]>=0){
		[model removeAddressAtIndex:[addressList selectedRow]];
		[addressList reloadData];
	}
}

- (IBAction) cut:(id)sender
{
	if([addressList selectedRow]>=0){
		[model removeAddressAtIndex:[addressList selectedRow]];
		[addressList reloadData];
	}
}

#pragma mark ¥¥¥DataSource
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
    NSParameterAssert(rowIndex >= 0 && rowIndex < [model addressCount]);
    id entry = [model addressEntry:rowIndex];
    return [entry objectForKey:[aTableColumn identifier]];
}

// just returns the number of items we have.
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [model addressCount];
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    NSParameterAssert(rowIndex >= 0 && rowIndex < [model addressCount]);
    id entry = [model addressEntry:rowIndex];
    [entry setObject:anObject forKey:[aTableColumn identifier]];
}@end
