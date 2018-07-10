//
//  ORCamacControllerCard.m
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



#pragma mark ¥¥¥imports
#import "ORCamacControllerCard.h"

NSString* ORCamacControllerCmdSelectedChangedNotification      = @"ORCamacControllerCmdSelectedChangedNotification";
NSString* ORCamacControllerCmdStationChangedNotification       = @"ORCamacControllerCmdStationChangedNotification";
NSString* ORCamacControllerCmdSubAddressChangedNotification    = @"ORCamacControllerCmdSubAddressChangedNotification";
NSString* ORCamacControllerCmdWriteAddressChangedNotification  = @"ORCamacControllerCmdWriteAddressChangedNotification";
NSString* ORCamacControllerModuleWriteValueChangedNotification  = @"ORCamacControllerModuleWriteValueChangedNotification";
NSString* ORCamacControllerCmdValuesChangedNotification        = @"ORCamacControllerCmdValuesChangedNotification";

@implementation ORCamacControllerCard

- (void) dealloc
{
	[connector release];
	[super dealloc];
}

#pragma mark ¥¥¥Accessors
- (void) makeConnectors
{	
   //make and cache our connector. However this connector will be 'owned' by another object (the crate)
    //so we don't add it to our list of connectors. It will be added to the true owner later.
    [self setConnector: [[[ORConnector alloc] initAt:NSZeroPoint withGuardian:self withObjectLink:self] autorelease]];
    [connector setOffColor:[NSColor blueColor]];
	[connector setConnectorType:'CamA'];
}

- (ORConnector*) connector
{
    return connector;
}

- (void) setConnector:(ORConnector*)aConnector
{
    [aConnector retain];
    [connector release];
    connector = aConnector;
}

- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
    [super setGuardian:aGuardian];
    
    if(oldGuardian != aGuardian){
        [oldGuardian removeDisplayOf:connector];
    }
    
    [aGuardian assumeDisplayOf:connector];
	[aGuardian setAdapter:self];
    [self guardian:aGuardian positionConnectorsForCard:self];
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    [aGuardian positionConnector:connector forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:connector];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:connector];
}

- (void) positionConnector:(ORConnector*)aConnector
{
	if(aConnector == connector){
		//position our managed connectors.
		NSRect aFrame = [aConnector localFrame];
		aFrame.origin = NSMakePoint(2,2);
		[aConnector setLocalFrame:aFrame];
	}
}


- (id) controller
{
	id controller = [[connector connector] objectLink];
	if(!controller)controller = [[self crate] controllerCard]; //depreciated (11/29/06)....for backward capatibility.. remove this line someday 
    return controller;
}

- (int) cmdSelection
{
    return cmdSelection;
}

- (void) setCmdSelection:(int)aCmd
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCmdSelection:cmdSelection];
	
    cmdSelection = aCmd;
	
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORCamacControllerCmdSelectedChangedNotification
					  object:self];
}


- (int) cmdStation
{
    return cmdStation;
}

- (void) setCmdStation: (int) aCmdStation
{
    if(aCmdStation<0)        aCmdStation = 0;
    else if(aCmdStation>25)  aCmdStation = 25;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setCmdStation:cmdStation];
    cmdStation = aCmdStation;
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORCamacControllerCmdStationChangedNotification
					  object:self];
}


- (int) cmdSubAddress
{
    return cmdSubAddress;
}

- (void) setCmdSubAddress: (int) aCmdSubAddress
{
    if(aCmdSubAddress<0)        aCmdSubAddress = 0;
    else if(aCmdSubAddress>15)  aCmdSubAddress = 15;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setCmdSubAddress:cmdSubAddress];
    cmdSubAddress = aCmdSubAddress;
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORCamacControllerCmdSubAddressChangedNotification
					  object:self];
}


- (int) cmdWriteValue
{
    return cmdWriteValue;
}

- (void) setCmdWriteValue: (int) aCmdWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCmdWriteValue:cmdWriteValue];
    cmdWriteValue = aCmdWriteValue;
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORCamacControllerCmdWriteAddressChangedNotification
					  object:self];
}

- (int) moduleWriteValue
{
    return moduleWriteValue;
}

- (void) setModuleWriteValue: (int) aWriteValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setModuleWriteValue:moduleWriteValue];
    moduleWriteValue = aWriteValue;
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORCamacControllerModuleWriteValueChangedNotification
					  object:self];
}

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [self setCmdSelection:  [decoder decodeIntForKey:@"ORCamacCardCmdSelection"]];
    [self setCmdStation:    [decoder decodeIntForKey:@"ORCamacCardCmdStation"]];
    [self setCmdSubAddress: [decoder decodeIntForKey:@"ORCamacCardCmdSubAddress"]];
    [self setCmdWriteValue: [decoder decodeIntForKey:@"ORCamacCardCmdWriteValue"]];
    [self setModuleWriteValue: [decoder decodeIntForKey:@"ORCamacCardModuleWriteValue"]];
    [self setConnector:[decoder decodeObjectForKey:@"Connector"]];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [[self undoManager] disableUndoRegistration];
    [encoder encodeInt:cmdSelection  forKey:@"ORCamacCardCmdSelection"];
    [encoder encodeInt:cmdStation    forKey:@"ORCamacCardCmdStation"];
    [encoder encodeInt:cmdSubAddress forKey:@"ORCamacCardCmdSubAddress"];
    [encoder encodeInt:cmdWriteValue forKey:@"ORCamacCardCmdWriteValue"];
    [encoder encodeInt:moduleWriteValue forKey:@"ORCamacCardModuleWriteValue"];
    [encoder encodeObject:[self connector] forKey:@"Connector"];
    [[self undoManager] enableUndoRegistration];
}

@end
