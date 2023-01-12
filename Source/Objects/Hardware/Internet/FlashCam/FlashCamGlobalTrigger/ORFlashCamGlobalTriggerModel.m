//  Orca
//  ORFlashCamGlobalTriggerModel.m
//
//  Created by Tom Caldwell on Sunday, November 7, 2021
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

#import "ORFlashCamGlobalTriggerModel.h"
#import "ORCrate.h"


@implementation ORFlashCamGlobalTriggerModel

#pragma mark •••Initialization

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) setUpImage
{
    NSImage* cimage = [NSImage imageNamed:@"flashcam_trigger"];
    NSSize size = [cimage size];
    NSSize newsize;
    newsize.width  = 0.155 * 5 * size.width;
    newsize.height = 0.135 * 5 * size.height;
    NSImage* image = [[NSImage alloc] initWithSize:newsize];
    [image lockFocus];
    NSRect rect;
    rect.origin = NSZeroPoint;
    rect.size.width = newsize.width;
    rect.size.height = newsize.height;
    [cimage drawInRect:rect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [image unlockFocus];
    [self setImage:image];
    [image release]; //MAH 9/18/22
}

- (void) makeMainController
{
    [self linkToController:@"ORFlashCamGlobalTriggerController"];
}

- (void) makeConnectors
{
    [super makeConnectors];
    [trigConnector release];
    trigConnector = NULL;
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++){
        [[self ctiConnector:i] setConnectorType:'FCGO'];
        [[[self ctiConnector:i] restrictedList] removeAllObjects];
        [[self ctiConnector:i] addRestrictedConnectionType:'FCTI'];
        [[self ctiConnector:i] addRestrictedConnectionType:'FCGI'];
        [[self ctiConnector:i] setOffColor:[NSColor colorWithCalibratedRed:0.1 green:0.5 blue:0.5 alpha:1]];
        [[self ctiConnector:i] setOnColor:[NSColor  colorWithCalibratedRed:0.1 green:0.1 blue:1   alpha:1]];
    }
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
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++)
        [aGuardian positionConnector:[self ctiConnector:i] forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:ethConnector];
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++)
        [aGuardian removeDisplayOf:[self ctiConnector:i]];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:ethConnector];
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++)
        [aGuardian assumeDisplayOf:[self ctiConnector:i]];
}


#pragma mark •••Accessors



#pragma mark •••Run control flags

- (NSMutableArray*) runFlags
{
    unsigned int mask = 0;
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++){
        ORConnector* cti = [self ctiConnector:i];
        if(!cti) continue;
        if([cti isConnected]) mask += 1 << i;
    }
    NSMutableArray* flags = [NSMutableArray array];
    [flags addObjectsFromArray:@[@"-mm",   [NSString stringWithFormat:@"%x", mask]]];
    [flags addObjectsFromArray:@[@"-mmaj", [NSString stringWithFormat:@"%d,%d", majorityLevel, majorityWidth]]];
    return flags;
}

- (void) printRunFlags
{
    NSLog(@"%@\n", [[self runFlags] componentsJoinedByString:@" "]);
}


#pragma mark •••Archival

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
}



@end
