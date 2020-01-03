//  Orca
//  ORFlashCamEthLinkController.m
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

#import "ORFlashCamEthLinkController.h"
#import "ORFlashCamEthLinkModel.h"

@implementation ORFlashCamEthLinkController

#pragma mark •••Initialization

- (id) init
{
    self = [super initWithWindowNibName:@"FlashCamEthLink"];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(nconnectionsChanged:)
                         name : ORFlashCamEthLinkNConnectionsChanged
                       object : nil];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) updateWindow
{
    [super updateWindow];
    [self nconnectionsChanged:nil];
}

#pragma mark •••Interface Management

- (void) nconnectionsChanged:(NSNotification*)note
{
    [nconnectionsTextField setIntValue:(int)[model nconnections]];
}

#pragma mark •••Actions

- (IBAction) nconnectionsAction:(id)sender
{
    [model setNConnections:[sender intValue]];
}

@end
