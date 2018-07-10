//-------------------------------------------------------------------------
//  ORMultiplierModel.m
//
//  Created by Mark A. Howe on Thursday 06/14/2018.
//  Copyright (c) 2018 University of North Carolina. All rights reserved.
//
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
#pragma mark ***Imported Files
#import "ORMultiplierModel.h"
#import "ORProcessOutConnector.h"
#import "ORProcessInConnector.h"

NSString* ORMultiplierAxBConnection       = @"ORMultiplierAxBConnection";

@implementation ORMultiplierModel

#pragma mark ***Initialization
- (NSString*) elementName
{
	return @"Multiplier";
}

- (void) makeMainController
{
    [self linkToController:@"ORMultiplierController"];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Multiplier"]];
}

-(void) makeConnectors
{
    ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORSimpleLogicIn1Connection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
    
    inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,[self frame].size.height-kConnectorSize-2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORSimpleLogicIn2Connection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];

	ORProcessOutConnector* outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize, [self frame].size.height/2 - kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORMultiplierAxBConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];
}

#pragma mark ***Accessors
- (id) eval
{
    float hwValue = 0;
    if(!alreadyEvaluated){
		alreadyEvaluated = YES;
		float a  = [[self evalInput1] analogValue];
		float b  = [[self evalInput2] analogValue];
        hwValue = a*b;
        [self setState: ((int)hwValue)==1];
        [self setEvaluatedState: ((int)hwValue)==1];
	}
	return [ORProcessResult processState:evaluatedState value:hwValue];
}
@end
