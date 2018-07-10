//
//  ORVmeDaughterCard.h
//  Orca
//
//  Created by Mark Howe on 3/2/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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



#import "ORVmeIOCard.h"

@class ORCardData;
@class ORConnector;

@interface ORVmeDaughterCard : ORVmeIOCard {
	@protected
        NSString* connectorName;
        ORConnector*  connector; //we won't draw this connector.
        NSString* connectorName2;
        ORConnector*  connector2; //we won't draw this connector.

}

- (int) crateNumber;
- (ORConnector*) connector;
- (void)         setConnector:(ORConnector*)aConnector;
- (NSString*)    connectorName;
- (void)         setConnectorName:(NSString*)aName;
- (ORConnector*) connector2;
- (void)         setConnector2:(ORConnector*)aConnector;
- (NSString*)    connectorName2;
- (void)         setConnectorName2:(NSString*)aName;
- (int)          slotConv;
- (void)         probe;
- (void)         guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void)         guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void)         guardianAssumingDisplayOfConnectors:(id)aGuardian;
@end

