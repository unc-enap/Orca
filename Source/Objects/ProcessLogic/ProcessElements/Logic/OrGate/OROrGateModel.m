//
//  OROrGateModel.m
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
#import "OROrGateModel.h"

@implementation OROrGateModel

#pragma mark ¥¥¥Initialization

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"ORGate"]];
}

-(void) makeConnectors
{
    [super makeConnectors];
    ORConnector* aConnector;
    aConnector = [[self connectors] objectForKey:ORSimpleLogicIn1Connection];
    [aConnector setLocalFrame: NSMakeRect(2,4,kConnectorSize,kConnectorSize)];
    
    aConnector = [[self connectors] objectForKey:ORSimpleLogicIn2Connection];
    [aConnector setLocalFrame: NSMakeRect(2,[self frame].size.height-kConnectorSize-4,kConnectorSize,kConnectorSize)];
}

- (NSString*) elementName
{
	return @"Or Gate";
}
//--------------------------------
//runs in the process logic thread
- (id) eval
{
    if(!alreadyEvaluated){
        alreadyEvaluated = YES;
        [self setState:[[self evalInput1] boolValue] | [[self evalInput2] boolValue]];
    }
    [self setEvaluatedState:[self state]];
	return [ORProcessResult processState: evaluatedState value:evaluatedState];
}
//--------------------------------

@end
