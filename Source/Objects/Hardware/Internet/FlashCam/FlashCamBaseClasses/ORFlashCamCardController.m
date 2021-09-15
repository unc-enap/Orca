//  Orca
//  ORFlashCamCardController.m
//
//  Created by Tom Caldwell on Wednesday, Sep 15,2021
//  Copyright (c) 2021 University of North Carolina. All rights reserved.
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

#import "ORFlashCamCardController.h"
#import "ORFlashCamCard.h"

@implementation ORFlashCamCardController

#pragma mark •••Initialization

- (id) init
{
    self = [super initWithWindowNibName:@"FlashCamADC"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [promSlotPUButton removeAllItems];
    for(int i=0; i<3; i++) [promSlotPUButton addItemWithTitle:[NSString stringWithFormat:@"Slot %d", i]];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(cardAddressChanged:)
                         name : ORFlashCamCardAddressChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(promSlotChanged:)
                         name : ORFlashCamCardPROMSlotChanged
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(firmwareVerRequest:)
                         name : ORFlashCamCardFirmwareVerRequest
                       object : model];
    [notifyCenter addObserver : self
                     selector : @selector(firmwareVerChanged:)
                         name : ORFlashCamCardFirmwareVerChanged
                       object : model];
    [notifyCenter addObserver : self
                     selector : @selector(cardSlotChanged:)
                         name : ORFlashCamCardSlotChangedNotification
                       object : self];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) updateWindow
{
    [super updateWindow];
    [self promSlotChanged:nil];
    [self firmwareVerChanged:nil];
}


#pragma mark •••Interface Management

- (void) cardAddressChanged:(NSNotification*)note
{
    [cardAddressTextField setIntValue:[model cardAddress]];
    [model taskFinished:nil];
}

- (void) promSlotChanged:(NSNotification*)note
{
    [promSlotPUButton selectItemAtIndex:[model promSlot]];
}

- (void) firmwareVerRequest:(NSNotification*)note
{
    [getFirmwareVerButton setEnabled:NO];
}

- (void) firmwareVerChanged:(NSNotification*)note
{
    if([model firmwareVer])
        [firmwareVerTextField setStringValue:[[model firmwareVer] componentsJoinedByString:@" / "]];
    else [firmwareVerTextField setStringValue:@""];
    [getFirmwareVerButton setEnabled:YES];
}

- (void) cardSlotChanged:(NSNotification*)note
{
}

- (void) settingsLock:(bool)lock
{
    [cardAddressTextField setEnabled:!lock];
    [promSlotPUButton     setEnabled:!lock];
    [rebootCardButton     setEnabled:!lock];
    [getFirmwareVerButton setEnabled:!lock];
}


#pragma mark •••Actions

- (IBAction) cardAddressAction:(id)sender
{
    [model setCardAddress:[sender intValue]];
}

- (IBAction) promSlotAction:(id)sender
{
    [model setPROMSlot:(unsigned int)[sender indexOfSelectedItem]];
}

- (IBAction) rebootCardAction:(id)sender
{
    [model requestReboot];
}

- (IBAction) firmwareVerAction:(id)sender
{
    [model requestFirmwareVersion];
}

- (IBAction) printFlagsAction:(id)sender
{
}

@end
