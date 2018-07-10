//
//  ORRemoteCommander.m
//  Orca
//
//  Created by Mark Howe on Thurs Sept 3, 2015.
//  Copyright (c) 2015  University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORRemoteCommander.h"
#import "ORRemoteSocketModel.h"

@implementation ORRemoteCommander

@synthesize remoteOpStatus;

- (void) dealloc
{
    self.remoteOpStatus = nil;
    [super dealloc];
}

- (void) sendCommand:(NSString*)aCmd remoteSocket:(ORRemoteSocketModel*)aSocketObj
{
    [self sendCommands:[NSArray arrayWithObject:aCmd] remoteSocket:aSocketObj];
}

- (void) sendCommands:(NSArray*)cmdArray remoteSocket:(ORRemoteSocketModel*)aSocketObj
{
    [aSocketObj sendStrings:cmdArray delegate:self];
}

- (id) getResponseForKey:(NSString*)aKey remoteSocket:(ORRemoteSocketModel*)aSocketObj
{
    if([aSocketObj responseExistsForKey:aKey]){
        id response = [aSocketObj responseForKey:aKey];
        return response;
    }
    else return nil;
}

- (void) setRemoteOpStatus:(NSDictionary*)aDictionary
{
    [aDictionary retain];
    [remoteOpStatus release];
    remoteOpStatus = aDictionary;
}

@end

