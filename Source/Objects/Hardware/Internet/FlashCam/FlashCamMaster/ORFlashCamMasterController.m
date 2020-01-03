//  Orca
//  ORFlashCamMasterController.m
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


#import "ORFlashCamMasterController.h"
#import "ORFlashCamMasterModel.h"
#import "ORFlashCamADCModel.h"

@implementation ORFlashCamMasterController

#pragma mark •••Initialization

- (id) init
{
    self = [super initWithWindowNibName:@"FlashCamMaster"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"FlasCam Master (%x Slot %d)", [model boardAddress], [model slot]]];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(boardAddressChanged:)
                         name : ORFlashCamMasterModelBoardAddressChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(cardSlotChanged:)
                         name : ORFlashCamCardSlotChangedNotification
                       object : nil];
    [notifyCenter addObserver : self
                     selector :@selector(connectionChanged:)
                         name :ORFlashCamADCModelBoardAddressChanged
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
    [self boardAddressChanged:nil];
    [self connectionChanged:nil];
}

#pragma mark •••Interface management

- (void) boardAddressChanged:(NSNotification*)note
{
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam Master (0x%x, Slot %d)", [model boardAddress], [model slot]]];
    [boardAddressTextField setIntValue:[model boardAddress]];
}

- (void) cardSlotChanged:(NSNotification*)note
{
    [[self window] setTitle:[NSString stringWithFormat:@"FlashCam Master (0x%x, Slot %d)", [model boardAddress], [model slot]]];
}

- (void) connectionChanged:(NSNotification*)note
{
    NSMutableDictionary* addresses = [model connectedADCAddresses];
    NSLog(@"%d addresses\n", [addresses count]);
    for(unsigned int i=0; i<kFlashCamMasterConnections; i++){
        NSNumber* a = [addresses objectForKey:[NSString stringWithFormat:@"trigConnection%d",i]];
        if(a) [[connectedADCMatrix cellWithTag:i] setIntValue:(int)[a unsignedIntValue]];
    }
}

#pragma mark •••Actions

- (IBAction) boardAddressAction:(id)sender
{
    [model setBoardAddress:[sender intValue]];
}

@end
