//
//  ORVmeDaughterCard.m
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


#import "ORVmeDaughterCard.h"
#import "ORVmeCarrierCard.h"

@implementation ORVmeDaughterCard

#pragma mark •••Initialization
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [connectorName release];
    [connectorName2 release];
    [connector release];
    [connector2 release];
    [super dealloc];
}

#pragma mark •••Accessors
- (NSString*) connectorName
{
    return connectorName;
}
- (void) setConnectorName:(NSString*)aName
{
    [aName retain];
    [connectorName release];
    connectorName = aName;
    
}

- (NSString*) fullID
{
    return [NSString stringWithFormat:@"%@,%d,%d,%d",NSStringFromClass([self class]),[[self guardian] crateNumber],[[self guardian] slot], [self slot]];
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


- (NSString*) connectorName2
{
    return connectorName2;
}
- (void) setConnectorName2:(NSString*)aName
{
    [aName retain];
    [connectorName2 release];
    connectorName2 = aName;
    
}

- (ORConnector*) connector2
{
    return connector2;
}

- (void) setConnector2:(ORConnector*)aConnector
{
    [aConnector retain];
    [connector2 release];
    connector2 = aConnector;
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    [self guardian:guardian positionConnectorsForCard:self];
    
    [[NSNotificationCenter defaultCenter]
			postNotificationName:ORVmeCardSlotChangedNotification
                          object: self];
}

- (int) slotConv
{
    return [self slot];
}

- (int) crateNumber
{
    return [guardian crateNumber];
}

- (void) setGuardian:(id)aGuardian
{
    
    id oldGuardian = guardian;
    [super setGuardian:aGuardian];
    
    if(oldGuardian != aGuardian){
        [oldGuardian removeDisplayOf:[self connector]];
        [oldGuardian removeDisplayOf:[self connector2]];
    }
    
    [aGuardian assumeDisplayOf:[self connector]];
    [aGuardian assumeDisplayOf:[self connector2]];
    [self guardian:aGuardian positionConnectorsForCard:self];
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    [aGuardian positionConnector:[self connector] forCard:self];
    [aGuardian positionConnector:[self connector2] forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:[self connector]];
    [aGuardian removeDisplayOf:[self connector2]];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:[self connector]];
    [aGuardian assumeDisplayOf:[self connector2]];
}

- (NSComparisonResult)	slotCompare:(id)otherCard
{
	return [self slotConv] - [otherCard slotConv];
}


#pragma mark •••Archival

//note that the names start with IP for historical reasons and must not be changed
//for backward compatiblity
static NSString *ORIPConnectorName 	= @"IP Connector Name";
static NSString *ORIPConnector 		= @"IP Connector";
static NSString *ORIPConnectorName2 = @"IP Connector Name2";
static NSString *ORIPConnector2 	= @"IP Connector2";
static NSString *ORIPSlot 			= @"IP Slot";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setConnectorName:[decoder decodeObjectForKey:ORIPConnectorName]];
    [self setConnector:[decoder decodeObjectForKey:ORIPConnector]];
    [self setConnectorName2:[decoder decodeObjectForKey:ORIPConnectorName2]];
    [self setConnector2:[decoder decodeObjectForKey:ORIPConnector2]];
	[self setSlot:[decoder decodeIntForKey:ORIPSlot]];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:[self connectorName] forKey:ORIPConnectorName];
    [encoder encodeObject:[self connector] forKey:ORIPConnector];
    [encoder encodeObject:[self connectorName2] forKey:ORIPConnectorName2];
    [encoder encodeObject:[self connector2] forKey:ORIPConnector2];
    [encoder encodeInteger:[self slot] forKey:ORIPSlot];
}

- (void) probe
{
    NSLog(@"Probe not implemented for %@\n",[self className]);
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[self identifier] forKey:@"SlotName"];
    return objDictionary;
}

@end
