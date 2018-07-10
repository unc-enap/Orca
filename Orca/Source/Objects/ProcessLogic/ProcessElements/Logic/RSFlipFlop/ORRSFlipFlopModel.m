//
//  ORRSFlipFlopModel.m
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
#import "ORRSFlipFlopModel.h"
#import "ORInputElement.h"
#import "ORInvertedOutputNub.h"
#import "ORProcessOutConnector.h"

NSString* ORRSFlipFlopInvertedConnection  = @"ORRSFlipFlopInvertedConnection";

@implementation ORRSFlipFlopModel

#pragma mark ¥¥¥Initialization


-(void)dealloc
{
    [invertedOuputNub release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"RSFlipFlop"]];
}

-(void)makeConnectors
{
    [super makeConnectors];

    ORConnector* aConnector;
    aConnector = [[self connectors] objectForKey:ORSimpleLogicIn1Connection];
    [aConnector setLocalFrame: NSMakeRect(5,5,kConnectorSize,kConnectorSize)];
    
    aConnector = [[self connectors] objectForKey:ORSimpleLogicIn2Connection];
    [aConnector setLocalFrame: NSMakeRect(5 ,[self frame].size.height-kConnectorSize-5,kConnectorSize,kConnectorSize)];

    aConnector = [[self connectors] objectForKey:ORSimpleLogicOutConnection];
    [aConnector setLocalFrame: NSMakeRect([self frame].size.width - kConnectorSize-5,[self frame].size.height-kConnectorSize-5,kConnectorSize,kConnectorSize)];

    ORProcessOutConnector* outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize-5 ,5) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORRSFlipFlopInvertedConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];

}

- (NSString*) elementName
{
	return @"RS Flip-Flop";
}


- (void) setUpNubs
{
    if(!invertedOuputNub)invertedOuputNub = [[ORInvertedOutputNub alloc] init];
    [invertedOuputNub setGuardian:self];
    ORConnector* aConnector = [[self connectors] objectForKey: ORRSFlipFlopInvertedConnection];
    [aConnector setObjectLink:invertedOuputNub];
}

- (void) processIsStarting
{
    [super processIsStarting];
    setState = 0;
    resetState = 0;
    [self setState:0];
}


//--------------------------------
//runs in the process logic thread
- (id) eval
{
    if(!alreadyEvaluated){
        alreadyEvaluated = YES;
        int oldSetState   = setState;
        int oldResetState = resetState;
        
        int newResetState = [[self evalInput2] boolValue];
        int newSetState   = [[self evalInput1] boolValue];
        
        BOOL setStateTransition = NO;
        BOOL resetTransition    = NO;
        
        if(oldSetState == 0 && newSetState == 1)	 setStateTransition = YES;
        if(oldResetState == 0 && newResetState == 1) resetTransition    = YES;

        setState = newSetState;
        resetState = newResetState;
        
        if(setStateTransition && !resetTransition)		[self setState:1];
        else if(!setStateTransition && resetTransition)	[self setState:0];
        else if(setStateTransition && resetTransition)	[self setState:0];
		
		[self setEvaluatedState:[self state]];
    }
	return [ORProcessResult processState:evaluatedState value:evaluatedState];
}
//--------------------------------

@end