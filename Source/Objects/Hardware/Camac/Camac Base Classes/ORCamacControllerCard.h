//
//  ORCamacControllerCard.h
//  Orca
//
//  Created by Mark Howe on Wed Dec 29 2004.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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



#import "ORCamacCard.h"

@interface ORCamacControllerCard : ORCamacCard
{
    @protected
        int cmdSelection;
        int cmdStation;
        int cmdSubAddress;
        int cmdWriteValue;
        int moduleWriteValue;
		ORConnector*  connector; //we won't draw this connector.
}

#pragma mark ¥¥¥Accessors
- (ORConnector*) connector;
- (void)         setConnector:(ORConnector*)aConnector;

- (void) setGuardian:(id)aGuardian;
- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard;
- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian;
- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian;
- (void) positionConnector:(ORConnector*)aConnector;

- (id) controller;
- (void) setGuardian:(id)aGuardian;
- (int) cmdSelection;
- (void) setCmdSelection:(int)aCmd;
- (int) cmdSelection;
- (void) setCmdSelection: (int) aCmdSelection;
- (int) cmdStation;
- (void) setCmdStation: (int) aCmdStation;
- (int) cmdSubAddress;
- (void) setCmdSubAddress: (int) aCmdSubAddress;
- (int) cmdWriteValue;
- (void) setCmdWriteValue: (int) aCmdWriteValue;
- (int) moduleWriteValue;
- (void) setModuleWriteValue: (int) aCmdWriteValue;
@end

extern NSString* ORCamacControllerCmdSelectedChangedNotification;
extern NSString* ORCamacControllerCmdStationChangedNotification;
extern NSString* ORCamacControllerCmdSubAddressChangedNotification;
extern NSString* ORCamacControllerCmdWriteAddressChangedNotification;
extern NSString* ORCamacControllerModuleWriteValueChangedNotification;
extern NSString* ORCamacControllerCmdValuesChangedNotification;
