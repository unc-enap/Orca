//  Orca
//  ORFlashCamMasterModel.m
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

#import "ORFlashCamMasterModel.h"
#import "ORCrate.h"

NSString* ORFlashCamMasterModelBoardAddressChanged = @"ORFlashCamMasterModelBoardAddressChanged";

@implementation ORFlashCamMasterModel

- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setBoardAddress:0];
    ethConnector = nil;
    for(unsigned int i=0; i<kFlashCamMasterConnections; i++) trigConnector[i] = nil;
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if(ethConnector) [ethConnector release];
    for(unsigned int i=0; i<kFlashCamMasterConnections; i++)
        if(trigConnector[i]) [trigConnector[i] release];
    [super dealloc];
}

- (void) setUpImage
{
    NSImage* cimage = [NSImage imageNamed:@"flashcam_master"];
    NSSize size = [cimage size];
    NSSize newsize;
    newsize.width  = 0.1675*5*size.width;
    newsize.height = 0.1475*5*size.height;
    NSImage* image = [[NSImage alloc] initWithSize:newsize];
    [image lockFocus];
    NSRect rect;
    rect.origin = NSZeroPoint;
    rect.size.width = newsize.width;
    rect.size.height = newsize.height;
    [cimage drawInRect:rect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [image unlockFocus];
    [self setImage:image];
}

- (void) makeMainController
{
    [self linkToController:@"ORFlashCamMasterController"];
}

- (void) makeConnectors
{
    [self setEthConnector:[[[ORConnector alloc] initAt:NSZeroPoint
                                          withGuardian:self
                                        withObjectLink:self] autorelease]];
    [ethConnector setConnectorImageType:kSmallDot];
    [ethConnector setConnectorType:'FCEO'];
    [ethConnector addRestrictedConnectionType:'FCEI'];
    [ethConnector setSameGuardianIsOK:YES];
    [ethConnector setOffColor:[NSColor colorWithCalibratedRed:1 green:1 blue:0.3 alpha:1]];
    [ethConnector setOnColor:[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:1 alpha:1]];
    for(unsigned int i=0; i<kFlashCamMasterConnections; i++){
        [self setTrigConnector:[[[ORConnector alloc] initAt:NSZeroPoint
                                               withGuardian:self
                                             withObjectLink:self] autorelease] atIndex:i];
        [trigConnector[i] setConnectorImageType:kSmallDot];
        [trigConnector[i] setConnectorType:'FCTO'];
        [trigConnector[i] addRestrictedConnectionType:'FCTI'];
        [trigConnector[i] setSameGuardianIsOK:YES];
        [trigConnector[i] setOffColor:[NSColor colorWithCalibratedRed:1 green:0.3 blue:1 alpha:1]];
    }
}

- (void) positionConnector:(ORConnector*)aConnector
{
    float xoff = 0.0;
    float yoff = 0.0;
    float xscale = 1.0;
    float yscale = 1.0;
    if([[guardian className] isEqualToString:@"ORFlashCamCrateModel"]){
        xoff = 40;
        yoff = 18;
        xscale = 0.595;
        yscale = 0.5;
    }
    else if([[guardian className] isEqualToString:@"ORFlashCamMiniCrateModel"]){
        xoff = 3;
        yoff = 10;
        xscale = 0.6;
        yscale = 0.522;
    }
    NSRect frame = [aConnector localFrame];
    float x = (xoff + ([self slot] + 0.5) * 25) * xscale - kConnectorSize/4;
    float y = 0.0;
    if(aConnector == ethConnector) y = yoff + [self frame].size.height * yscale * 0.9;
    else{
        bool found = NO;
        for(unsigned int i=0; i<kFlashCamMasterConnections; i++){
            if(aConnector == trigConnector[i]){
                y = yoff + [self frame].size.height*yscale*(0.075+0.5*i/kFlashCamMasterConnections);
                if(i > 7) y += [self frame].size.height*yscale*0.175;
                found = YES;
                break;
            }
        }
        if(!found) return;
    }
    frame.origin = NSMakePoint(x, y);
    [aConnector setLocalFrame:frame];
}

- (void) disconnect
{
    [ethConnector disconnect];
    for(unsigned int i=0; i<kFlashCamMasterConnections; i++) [trigConnector[i] disconnect];
    [super disconnect];
}

- (void) setGuardian:(id)aGuardian
{
    id oldGuardian = guardian;
    [super setGuardian:aGuardian];
    if(oldGuardian != aGuardian) [self guardianRemovingDisplayOfConnectors:oldGuardian];
    [self guardianAssumingDisplayOfConnectors:aGuardian];
    [self guardian:aGuardian positionConnectorsForCard:self];
}

- (void) guardian:(id)aGuardian positionConnectorsForCard:(id)aCard
{
    [aGuardian positionConnector:ethConnector  forCard:self];
    for(unsigned int i=0; i<kFlashCamMasterConnections; i++)
        [aGuardian positionConnector:trigConnector[i] forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:ethConnector];
    for(unsigned int i=0; i<kFlashCamMasterConnections; i++)
        [aGuardian removeDisplayOf:trigConnector[i]];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:ethConnector];
    for(unsigned int i=0; i<kFlashCamMasterConnections; i++)
        [aGuardian assumeDisplayOf:trigConnector[i]];
}

#pragma mark •••Accessors

- (unsigned int) boardAddress
{
    return boardAddress;
}

- (ORConnector*) ethConnector
{
    return ethConnector;
}

- (ORConnector*) trigConnector:(unsigned int)index
{
    return trigConnector[index];
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    [self guardian:guardian positionConnectorsForCard:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamCardSlotChangedNotification object:self];
}

- (void) setBoardAddress:(unsigned int)address
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBoardAddress:boardAddress];
    boardAddress = address;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamMasterModelBoardAddressChanged object:self];
}

- (void) setEthConnector:(ORConnector*)connector
{
    [connector retain];
    [ethConnector release];
    ethConnector = connector;
}

- (void) setTrigConnector:(ORConnector*)connector atIndex:(unsigned int)index
{
    [connector retain];
    [trigConnector[index] release];
    trigConnector[index] = connector;
}

#pragma mark •••Connection management

- (NSMutableDictionary*) connectedADCAddresses
{
    NSMutableDictionary* addresses = [NSMutableDictionary dictionary];
    for(unsigned int i=0; i<kFlashCamMasterConnections; i++){
        if([trigConnector[i] isConnected]){
            unsigned int a = [[trigConnector[i] connectedObject] boardAddress];
            [addresses setObject:[NSNumber numberWithUnsignedInt:a]
                          forKey:[NSString stringWithFormat:@"trigConnection%d",i]];
        }
    }
    return addresses;
}

#pragma mark •••Run control flags

- (NSMutableArray*) runFlags
{
    NSMutableArray* flags = [NSMutableArray array];
    if([[self connectedADCAddresses] count] > 0)
        [flags addObjectsFromArray:@[@"-ma", [NSString stringWithFormat:@"%x", boardAddress]]];
    return flags;
}

#pragma mark •••Archival

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setBoardAddress:[[decoder decodeObjectForKey:@"boardAddress"] unsignedIntValue]];
    [self setEthConnector:[decoder decodeObjectForKey:@"ethConnector"]];
    for(int i=0; i<kFlashCamMasterConnections; i++)
        [self setTrigConnector:[decoder decodeObjectForKey:[NSString stringWithFormat:@"trigConnector%d",i]] atIndex:i];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:[NSNumber numberWithUnsignedInt:boardAddress] forKey:@"boardAddress"];
    [encoder encodeObject:ethConnector  forKey:@"ethConnector"];
    for(unsigned int i=0; i<kFlashCamMasterConnections; i++)
        [encoder encodeObject:trigConnector[i] forKey:[NSString stringWithFormat:@"trigConnector%d",i]];

}

@end
