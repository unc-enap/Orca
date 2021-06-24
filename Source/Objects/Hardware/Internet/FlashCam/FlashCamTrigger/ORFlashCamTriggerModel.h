//  Orca
//  ORFlashCamTriggerModel.h
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

#import "ORFlashCamCard.h"
#import "ORConnector.h"

#define kFlashCamTriggerConnections 12

@interface ORFlashCamTriggerModel : ORFlashCamCard
{
    @private
    ORConnector* trigConnector[kFlashCamTriggerConnections];
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;
- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian;

#pragma mark •••Accessors
- (ORConnector*) ethConnector;
- (ORConnector*) trigConnector:(unsigned int)index;
- (void) setEthConnector:(ORConnector*)connector;
- (void) setTrigConnector:(ORConnector*)connector atIndex:(unsigned int)index;

#pragma mark •••Connection management
- (NSMutableDictionary*) connectedADCAddresses;

#pragma mark •••Run control flags
- (NSMutableArray*) runFlags;

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

#pragma mark •••Externals
extern NSString* ORFlashCamTriggerModelBoardAddressChanged;
