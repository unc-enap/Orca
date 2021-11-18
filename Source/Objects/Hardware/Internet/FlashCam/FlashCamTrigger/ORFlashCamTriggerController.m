//  Orca
//  ORFlashCamTriggerController.m
//
//  Created by Tom Caldwell on Monday Jan 1, 2020
//  Copyright (c) 2020 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORFlashCamTriggerController.h"
#import "ORFlashCamTriggerModel.h"
#import "ORFlashCamADCModel.h"

@implementation ORFlashCamTriggerController

#pragma mark •••Initialization

- (id) init
{
    self = [super initWithWindowNibName:@"FlashCamTrigger"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"FlasCam Trigger (%x Slot %d)", [model cardAddress], [model slot]]];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(connectionChanged:)
                         name : ORFlashCamCardAddressChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(connectionChanged:)
                         name : ORConnectionChanged
                       object : nil];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) updateWindow
{
    [super updateWindow];
    [self connectionChanged:nil];
}

#pragma mark •••Interface management

- (void) cardAddressChanged:(NSNotification*)note
{
    [super cardAddressChanged:note];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam Trigger (0x%x, Slot %d)", [model cardAddress], [model slot]]];
}

- (void) cardSlotChanged:(NSNotification*)note
{
    [super cardSlotChanged:note];
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam Trigger (0x%x, Slot %d)", [model cardAddress], [model slot]]];
}

- (void) connectionChanged:(NSNotification*)note
{
    NSMutableDictionary* addresses = [model connectedAddresses];
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++){
        NSNumber* a = [addresses objectForKey:[NSString stringWithFormat:@"trigConnection%d",i]];
        if(a) [[connectedADCMatrix cellWithTag:i] setIntValue:(int)[a unsignedIntValue]];
    }
}

#pragma mark •••Actions

@end
