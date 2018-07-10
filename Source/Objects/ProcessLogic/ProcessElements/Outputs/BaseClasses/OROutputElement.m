//
//  OROutputElement.m
//  Orca
//
//  Created by Mark Howe on 11/25/05.
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


#import "OROutputElement.h"
#import "ORProcessThread.h"
#import "ORProcessModel.h"
#import "ORProcessInConnector.h"
#import "ORProcessOutConnector.h"

NSString* OROutputElementInConnection   = @"OROutputElementInConnection";
NSString* OROutputElementOutConnection  = @"OROutputElementOutConnection";

@implementation OROutputElement


-(void)makeConnectors
{
     ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,10) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:OROutputElementInConnection];
    [inConnector setConnectorType: 'LP1 ' ];
    [inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];


    ORProcessOutConnector* outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,10) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:OROutputElementOutConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];

}

- (NSString*) description:(NSString*)prefix
{
    NSString* s = [super description:prefix];
    id obj = [self objectConnectedTo:OROutputElementInConnection];
    NSString* nextPrefix = [prefix stringByAppendingString:@"  "];
    NSString* noConnectionString = [NSString stringWithFormat:@"%@--",nextPrefix];
    return [NSString stringWithFormat:@"%@\n%@%@",s,prefix,obj?[obj description:nextPrefix]:noConnectionString];
}

- (NSString*) report
{	
	NSString* s =  [NSString stringWithFormat:@"%@: %@",[self iconLabel],[self state]?@"High":@"Low"];
	return s;
}

- (id) description
{
	NSString* s =  [super description];
	s =  [s stringByAppendingFormat:@"[State: %d]",[self evaluatedState]];
	return s;
}

- (BOOL) isTrueEndNode
{
    return [self objectConnectedTo:OROutputElementOutConnection] == nil;
}

- (void) processIsStarting
{
    [super processIsStarting];
    id obj = [self objectConnectedTo:OROutputElementInConnection];
    [obj processIsStarting];
	[ORProcessThread registerOutputObject:self];
}

- (void) processIsStopping
{
    [super processIsStopping];
    id obj = [self objectConnectedTo:OROutputElementInConnection];
    [obj processIsStopping];
}
//--------------------------------
//runs in the process logic thread
- (id) eval
{
    id obj = [self objectConnectedTo:OROutputElementInConnection];
    int value = [[obj eval] boolValue];
    [self setState:value];
	
	if(![guardian inTestMode] && hwObject!=nil){
		[hwObject setProcessOutput:bit value:value];
	} 

    [self setEvaluatedState:value];
	return [ORProcessResult processState:evaluatedState value:evaluatedState];
}
//--------------------------------

@end
