//
//  ORIPCarrierController.m
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
#import "ORIPCarrierController.h"
#import "ORIPCarrierModel.h"


@implementation ORIPCarrierController

#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"IPCarrier"];
    
    return self;
}

- (void) awakeFromNib
{
    [groupView setGroup:model];
    [super awakeFromNib];
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsAdded
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupObjectsRemoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : ORGroupSelectionChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(groupChanged:)
                         name : OROrcaObjectMoved
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(baseAddressChanged:)
                         name : ORVmeIOCardBaseAddressChangedNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : ORVmeCardSlotChangedNotification
                       object : nil];

}


#pragma mark ¥¥¥Accessors
- (ORIPCarrierView *)groupView
{
    return [self groupView];
}


- (void) setModel:(OrcaObject*)aModel
{
    [super setModel:aModel];
    [groupView setGroup:(ORGroup*)model];
}

#pragma mark ¥¥¥Interface Management

- (void) updateWindow
{
    [self baseAddressChanged:nil];
    [self runStatusChanged:nil];
    [self slotChanged:nil];
    [groupView setNeedsDisplay:YES];
}

- (void) isNowKeyWindow:(NSNotification*)aNotification
{
	[[self window] makeFirstResponder:(NSResponder*)groupView];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[[self window] setTitle:[NSString stringWithFormat:@"IP Carrier (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNotification
{
	[self updateStepper:addressStepper setting:[model baseAddress]];
	[addressText setIntValue: [model baseAddress]];
}

- (void) runStatusChanged:(NSNotification*)aNotification
{
    int status = [[[aNotification userInfo] objectForKey:ORRunStatusValue] intValue];
    [probeButton setEnabled:status == eRunStopped];
}

-(void) groupChanged:(NSNotification*)note
{
	[self updateWindow];
}


#pragma mark ¥¥¥Actions
-(IBAction)baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [[self undoManager] setActionName: @"Set Base Address"];
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) probeAction:(id)sender
{
    [model probe];
}




@end
