//  Orca
//  ORFlashCamTriggerModel.m
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

#import "ORFlashCamTriggerModel.h"
#import "ORCrate.h"

NSString* ORFlashCamTriggerModelMajorityLevelChanged = @"ORFlashCamTriggerModelMajorityLevelChanged";
NSString* ORFlashCamTriggerModelMajorityWidthChanged = @"ORFlashCamTriggerModelMajorityWidthChanged";

@implementation ORFlashCamTriggerModel

- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++) ctiConnector[i] = nil;
    majorityLevel = 1;
    majorityWidth = 1;
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++) if(ctiConnector[i]) [ctiConnector[i] release];
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
    [image release]; //MAH 2/18/22
}

- (void) makeMainController
{
    [self linkToController:@"ORFlashCamTriggerController"];
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
    [self setTrigConnector:[[[ORConnector alloc] initAt:NSZeroPoint
                                           withGuardian:self
                                         withObjectLink:self] autorelease]];
    [trigConnector setConnectorImageType:kSmallDot];
    [trigConnector setConnectorType:'FCGI'];
    [trigConnector addRestrictedConnectionType:'FCGO'];
    [trigConnector setSameGuardianIsOK:YES];
    [trigConnector setOffColor:[NSColor colorWithCalibratedRed:0.1 green:1 blue:0.1 alpha:1]];
    [trigConnector setOnColor:[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:1 alpha:1]];
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++){
        [self setCTIConnector:[[[ORConnector alloc] initAt:NSZeroPoint
                                              withGuardian:self
                                            withObjectLink:self] autorelease] atIndex:i];
        [ctiConnector[i] setConnectorImageType:kSmallDot];
        [ctiConnector[i] setConnectorType:'FCTO'];
        [ctiConnector[i] addRestrictedConnectionType:'FCTI'];
        [ctiConnector[i] setSameGuardianIsOK:YES];
        [ctiConnector[i] setOffColor:[NSColor colorWithCalibratedRed:1 green:0.3 blue:1 alpha:1]];
        [ctiConnector[i] setOnColor:[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:1 alpha:1]];
    }
}

- (void) positionConnector:(ORConnector*)aConnector
{
    float xoff = 0.0;
    float yoff = 0.0;
    float xscale = 1.0;
    float yscale = 1.0;
    if([[guardian className] isEqualToString:@"ORFlashCamCrateModel"]){
        xoff = 30;
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
    float x = (xoff + ([self slot] + 0.5) * 25) * xscale - kConnectorSize/2;
    float y = 0.0;
    if(ethConnector && aConnector == ethConnector)        y = yoff + [self frame].size.height * yscale * 0.9;
    else if(trigConnector && aConnector == trigConnector) y = yoff + [self frame].size.height * yscale * 0.855;
    else{
        bool found = NO;
        for(unsigned int i=0; i<kFlashCamTriggerConnections; i++){
            if(aConnector == ctiConnector[i]){
                y = yoff + [self frame].size.height*yscale*(0.07+0.5*(1-(i+1)/(float)kFlashCamTriggerConnections));
                if(i < 4) y += [self frame].size.height*yscale*0.18;
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
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++)
        if(ctiConnector[i]) [ctiConnector[i] disconnect];
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
    [aGuardian positionConnector:trigConnector forCard:self];
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++)
        [aGuardian positionConnector:ctiConnector[i] forCard:self];
}

- (void) guardianRemovingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian removeDisplayOf:ethConnector];
    [aGuardian removeDisplayOf:trigConnector];
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++)
        [aGuardian removeDisplayOf:ctiConnector[i]];
}

- (void) guardianAssumingDisplayOfConnectors:(id)aGuardian
{
    [aGuardian assumeDisplayOf:ethConnector];
    [aGuardian assumeDisplayOf:trigConnector];
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++)
        [aGuardian assumeDisplayOf:ctiConnector[i]];
}

#pragma mark •••Accessors
- (int) majorityLevel
{
    return majorityLevel;
}

- (int) majorityWidth
{
    return majorityWidth;
}

- (void) setMajorityLevel:(int)level
{
    if(majorityLevel == level) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setMajorityLevel:majorityLevel];
    majorityLevel = MAX(1, level);
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamTriggerModelMajorityLevelChanged object:self];
}

- (void) setMajorityWidth:(int)width
{
    if(majorityWidth == width) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setMajorityWidth:majorityWidth];
    majorityWidth = MAX(1, width);
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamTriggerModelMajorityWidthChanged object:self];
}

- (ORConnector*) ctiConnector:(unsigned int)index
{
    return ctiConnector[index];
}

- (void) setSlot:(int)aSlot
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlot:[self slot]];
    [self setTag:aSlot];
    [self guardian:guardian positionConnectorsForCard:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamCardSlotChangedNotification object:self];
}

- (void) setCTIConnector:(ORConnector*)connector atIndex:(unsigned int)index
{
    [connector retain];
    [ctiConnector[index] release];
    ctiConnector[index] = connector;
}

#pragma mark •••Connection management

- (NSMutableDictionary*) connectedAddresses
{
    NSMutableDictionary* addresses = [NSMutableDictionary dictionary];
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++){
        if([ctiConnector[i] isConnected]){
            unsigned int a = [[ctiConnector[i] connectedObject] cardAddress];
            [addresses setObject:[NSNumber numberWithUnsignedInt:a]
                          forKey:[NSString stringWithFormat:@"trigConnection%d",i]];
        }
    }
    return addresses;
}

#pragma mark •••Run control flags

- (NSMutableArray*) runFlagsForCardIndex:(unsigned int)index
{
    unsigned int mask = 0;
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++){
        ORConnector* cti = [self ctiConnector:i];
        if(!cti) continue;
        if([cti isConnected]) mask += 1 << i;
    }
    NSMutableArray* flags = [NSMutableArray array];
    [flags addObjectsFromArray:@[@"-smm", [NSString stringWithFormat:@"%x,%d,1", mask, index]]];
    
    //-----------------*****Double check these flags******-----------------------------------
    [flags addObjectsFromArray:@[@"-mm",   [NSString stringWithFormat:@"%x", mask]]];
    [flags addObjectsFromArray:@[@"-mmaj", [NSString stringWithFormat:@"%d,%d", majorityLevel, majorityWidth]]];
    //---------------------------------------------------------------------------------------

    return flags;
}

- (void) printRunFlagsForCardIndex:(unsigned int)index
{
    NSLog(@"%@\n", [[self runFlagsForCardIndex:0] componentsJoinedByString:@" "]);
}

#pragma mark •••Archival

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    for(int i=0; i<kFlashCamTriggerConnections; i++)
        [self setCTIConnector:[decoder decodeObjectForKey:[NSString stringWithFormat:@"trigConnector%d",i]] atIndex:i];
    [self setMajorityLevel:[decoder decodeIntForKey:@"majorityLevel"]];
    [self setMajorityWidth:[decoder decodeIntForKey:@"majorityWidth"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    for(unsigned int i=0; i<kFlashCamTriggerConnections; i++)
        [encoder encodeObject:ctiConnector[i] forKey:[NSString stringWithFormat:@"trigConnector%d",i]];
    [encoder encodeInt:majorityLevel forKey:@"majorityLevel"];
    [encoder encodeInt:majorityWidth forKey:@"majorityWidth"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* dict = [super addParametersToDictionary:dictionary];
    [dict setObject:[NSNumber numberWithInt:majorityLevel]   forKey:@"MajorityLevel"];
    [dict setObject:[NSNumber numberWithInt:majorityWidth]   forKey:@"MajorityWidth"];
    return dict;
}
@end
