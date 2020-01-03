//  Orca
//  ORFlashCamCrate.h
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

#import "ORCrate.h"

@interface ORFlashCamCrate : ORCrate {
}

#pragma mark •••Initialization
- (void) makeConnectors;

#pragma mark •••Accessors
- (NSString*) adapterArchiveKey;
- (NSString*) createAdapterConnectorKey;
- (id) cardInSlot:(int)aSlot;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
@end

@interface ORFlashCamCrate (OROrderedObjHolding)
- (int) maxNumberOfObjects;
- (int) objWidth;
@end

