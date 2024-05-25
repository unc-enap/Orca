//  Orca
//  ORFlashCamEthLinkModel.m
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

#import "ORFlashCamEthLinkModel.h"

NSString* ORFlashCamEthLinkNConnectionsChanged = @"ORFlashCamEthLinkNConnectionsChanged";
static NSString* ORFlashCamEthLinkInputConnection  = @"ORFlashCamEthLinkInputConnection";
static NSString* ORFlashCamEthLinkOutputConnection = @"ORFlashCamEthLinkOutputConnection";

@implementation ORFlashCamEthLinkModel

#pragma mark •••Initialization

- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setNConnections:8];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) makeMainController
{
    [self linkToController:@"ORFlashCamEthLinkController"];
}

- (NSString*) helpURL
{
    return @"FlashCam/FlashCamEthLink.html";
}

- (void) setUpImage
{
}

- (void) makeConnectors
{
    float width  = [self frame].size.width;
    float height = [self frame].size.height;
    float dx = (width-kConnectorSize) / (nconnections - 1);
    // create the output connector
    ORConnector* connector = [[self connectors] objectForKey:ORFlashCamEthLinkOutputConnection];
    id obj = nil, connection = nil;
    if(connector){
        obj = [connector objectLink];
        connection = [connector connector];
        [connector disconnect];
    }
    NSPoint point = NSMakePoint(width/2-kConnectorSize/3, height-kConnectorSize);
    if(obj) connector = [[ORConnector alloc] initAt:point withGuardian:self withObjectLink:obj];
    else connector = [[ORConnector alloc] initAt:point withGuardian:self];
    if(connection){
        [connector setConnection:connection];
        [connection setConnection:connector];
    }
    [connector setConnectorImageType:kSmallDot];
    [connector setConnectorType:'FCEO'];
    [connector addRestrictedConnectionType:'FCEI'];
    [connector setOffColor:[NSColor colorWithCalibratedRed:1 green:1 blue:0.3 alpha:1]];
    [connector setOnColor:[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:1 alpha:1]];
    [[self connectors] setObject:connector forKey:ORFlashCamEthLinkOutputConnection];
    [connector release];
    // create the input connectors
    for(unsigned int i=0; i<nconnections; i++){
        NSString* s = [NSString stringWithFormat:@"%@%d",ORFlashCamEthLinkInputConnection,i];
        connector = [[self connectors] objectForKey:s];
        obj = nil;
        connection = nil;
        if(connector){
            obj = [connector objectLink];
            connection = [connector connector];
            [connector disconnect];
        }
        point = NSMakePoint(i*dx+kConnectorSize/4, 0.0);
        if(obj) connector = [[ORConnector alloc] initAt:point withGuardian:self withObjectLink:obj];
        else connector = [[ORConnector alloc] initAt:point withGuardian:self];
        if(connection){
            [connector setConnection:connection];
            [connection setConnection:connector];
        }
        [connector setConnectorImageType:kSmallDot];
        [connector setConnectorType:'FCEI'];
        [connector addRestrictedConnectionType:'FCEO'];
        [connector setOffColor:[NSColor colorWithCalibratedRed:1 green:1 blue:0.3 alpha:1]];
        [connector setOnColor:[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:1 alpha:1]];
        [[self connectors] setObject:connector forKey:s];
        [connector release];
    }
}

- (void) drawSelf:(NSRect)aRect withTransparency:(float)aTransparency
{
    float x0 = [self frame].origin.x;
    float y0 = [self frame].origin.y;
    float width  = [self frame].size.width;
    float height = [self frame].size.height;
    float dx = (width-kConnectorSize) / (nconnections - 1);
    NSBezierPath* path = [NSBezierPath bezierPath];
    [path moveToPoint:NSMakePoint(x0+width/2, y0+height-kConnectorSize/2)];
    [path lineToPoint:NSMakePoint(x0+width/2, y0+height/2)];
    [path moveToPoint:NSMakePoint(x0+kConnectorSize/2, y0+height/2)];
    [path lineToPoint:NSMakePoint(x0+width-kConnectorSize/2, y0+height/2)];
    for(unsigned int i=0; i<nconnections; i++){
        [path moveToPoint:NSMakePoint(x0+kConnectorSize/2+i*dx, y0+kConnectorSize/2)];
        [path lineToPoint:NSMakePoint(x0+kConnectorSize/2+i*dx, y0+height/2)];
    }
    [colorForData([[NSUserDefaults standardUserDefaults] objectForKey:ORLineColor]) set];
    [path stroke];
    [self drawConnections:aRect withTransparency:aTransparency];
    //[self makeConnectors]; //causes severe slow down
}

#pragma mark •••Accessors

- (unsigned int) nconnections
{
    return nconnections;
}

- (void) setNConnections:(unsigned int)n
{
    if(nconnections == n || n < 2) return;
    [self setFrame:NSMakeRect([self frame].origin.x, [self frame].origin.y,
                              n*1.5*kConnectorSize, 3*kConnectorSize)];
    for(unsigned int i=n; i<nconnections; i++){
        NSString* s = [NSString stringWithFormat:@"%@%d", ORFlashCamEthLinkInputConnection,i];
        ORConnector* connector = [[self connectors] objectForKey:s];
        if(connector) [connector disconnect];
        [[self connectors] removeObjectForKey:s];
    }
    nconnections = n;
    [self makeConnectors];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamEthLinkNConnectionsChanged object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORConnectionChanged object:self];
}

- (NSMutableArray*) connectedObjects:(NSString*)cname
{
    NSMutableArray* objs = [NSMutableArray array];
    for(id key in connectors){
        ORConnector* connector = [connectors objectForKey:key];
        if(!connector) continue;
        if(![connector isConnected]) continue;
        id obj = [connector connectedObject];
        if(!obj) continue;
        if([[obj className] isEqualToString:cname]) [objs addObject:obj];
    }
    return objs;
}

#pragma mark •••Archival

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    nconnections = [[decoder decodeObjectForKey:@"nconnections"] unsignedIntValue];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:[NSNumber numberWithUnsignedInt:nconnections] forKey:@"nconnections"];
}

@end
