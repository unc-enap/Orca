//
//  ORSimpleLogicModel.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 18 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORSimpleLogic.h"
#import "ORProcessInConnector.h"
#import "ORProcessOutConnector.h"

NSString* ORSimpleLogicIn1Connection  = @"ORSimpleLogicIn1Connection";
NSString* ORSimpleLogicIn2Connection  = @"ORSimpleLogicIn2Connection";
NSString* ORSimpleLogicOutConnection  = @"ORSimpleLogicOutConnection";

@implementation ORSimpleLogic

#pragma mark ¥¥¥Initialization

-(void)makeConnectors
{
    ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(3,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORSimpleLogicIn1Connection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];

    inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(3,[self frame].size.height-kConnectorSize-2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORSimpleLogicIn2Connection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];

    ORProcessOutConnector* outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize-3,[self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORSimpleLogicOutConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];

}

- (NSString*) description:(NSString*)prefix
{
    NSString* s = [super description:prefix];
    id obj1 = [self objectConnectedTo:ORSimpleLogicIn1Connection];
    id obj2 = [self objectConnectedTo:ORSimpleLogicIn2Connection];
    NSString* nextPrefix = [prefix stringByAppendingString:@"  "];
    NSString* noConnectionString = [NSString stringWithFormat:@"%@--",nextPrefix];
    return [NSString stringWithFormat:@"%@\n%@\n%@",s,
                                    obj1?[obj1 description:nextPrefix]:noConnectionString,
                                    obj2?[obj2 description:nextPrefix]:noConnectionString];
}


- (void) processIsStarting
{
    [super processIsStarting];
    id obj;
    obj = [self objectConnectedTo:ORSimpleLogicIn1Connection];
    [obj processIsStarting];
    obj = [self objectConnectedTo:ORSimpleLogicIn2Connection];
    [obj processIsStarting];
    
}

- (void) processIsStopping
{
    [super processIsStopping];
    id obj;
    obj = [self objectConnectedTo:ORSimpleLogicIn1Connection];
    [obj processIsStopping];
    obj = [self objectConnectedTo:ORSimpleLogicIn2Connection];
    [obj processIsStopping];
}


//--------------------------------
//runs in the process logic thread
- (id) evalInput1
{
    id obj = [self objectConnectedTo:ORSimpleLogicIn1Connection];
	return [obj eval];
}
- (id) evalInput2
{
    id obj = [self objectConnectedTo:ORSimpleLogicIn2Connection];
	return [obj eval];
}
//--------------------------------

@end