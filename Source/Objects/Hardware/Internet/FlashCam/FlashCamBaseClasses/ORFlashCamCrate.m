//  Orca
//  ORFlashCamCrate.m
//
//  Created by Tom Caldwell on Monday Dec 16,2019
//  Copyright (c) 2019 University of North Carolina. All rights reserved.
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

#import "ORFlashCamCrate.h"
#import "ORFlashCamCard.h"

@implementation ORFlashCamCrate
- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) makeConnectors
{
}

#pragma mark •••Accessors

- (NSString*) adapterArchiveKey
{
    return @"FlashCam Adapter";
}

- (NSString*) createAdapterConnectorKey
{
    return @"FlashCam Crate Adapter Connector";
}

- (void) setAdapter:(id)anAdapter
{
    [super setAdapter:anAdapter];
}

- (id) cardInSlot:(int)aSlot
{
    for(id anObj in [self orcaObjects]){
        if([(ORFlashCamCard*)anObj isKindOfClass:NSClassFromString(@"ORFlashCamCard")]){
            if([(ORFlashCamCard*)anObj slot] == aSlot) return anObj;
        }
    }
    return nil;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(viewChanged:)
                         name : ORFlashCamCardSlotChangedNotification
                       object : nil];
}

@end
