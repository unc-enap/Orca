//
//  ORProcessPulserModel.m
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
#import "ORProcessPulserModel.h"
#import "ORProcessInConnector.h"
#import "ORProcessOutConnector.h"

NSString* ORProcessPulserInConnection    = @"ORProcessPulserInConnection";
NSString* ORProcessPulserOutConnection   = @"ORProcessPulserOutConnection";
NSString* ORProcessPulseCycleTimeChangedNotification = @"ORProcessPulseCycleTimeChangedNotification";
NSString* ORProcessPulseLock					= @"ORProcessPulseLock";

@implementation ORProcessPulserModel

#pragma mark ¥¥¥Initialization

-(void)makeConnectors
{
    ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORProcessPulserInConnection];
    [inConnector setConnectorType: 'LP1 ' ];
    [inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];


    ORProcessOutConnector* outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,0) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORProcessPulserOutConnection];
    [outConnector setConnectorType: 'LP2 ' ];
    [outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];
}

- (void) setUpImage
{
   [self setImage:[NSImage imageNamed:@"ProcessPulser"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORProcessPulserController"];
}
- (NSString*) elementName
{
	return @"Pulser";
}

- (NSString*) description:(NSString*)prefix
{
    NSString* s = [super description:prefix];
    id obj1 = [self objectConnectedTo:ORProcessPulserInConnection];
    NSString* nextPrefix = [prefix stringByAppendingString:@"  "];
    NSString* noConnectionString = [NSString stringWithFormat:@"%@--",nextPrefix];
    return [NSString stringWithFormat:@"%@\n%@",s,
                                    obj1?[obj1 description:nextPrefix]:noConnectionString];
}
#pragma mark ¥¥¥Accessors
- (NSTimeInterval) cycleTime
{
    return cycleTime;
}

- (void) setCycleTime:(NSTimeInterval)aCycleTime
{
    if(aCycleTime<=0)aCycleTime = 1;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setCycleTime:cycleTime];
	
    cycleTime = aCycleTime;
	
    [[NSNotificationCenter defaultCenter]
		postNotificationName:ORProcessPulseCycleTimeChangedNotification
					  object:self];
}


- (void) processIsStarting
{
    [super processIsStarting];
    t0 = [NSDate timeIntervalSinceReferenceDate];
    [self setState:0];
}

- (id) eval
{

    NSTimeInterval t1 = [NSDate timeIntervalSinceReferenceDate];
    if((t1 - t0) >= cycleTime){
        t0 = t1;
		timerState = !timerState;
    }
    
    id obj = [self objectConnectedTo:ORProcessPulserInConnection];
    if(obj){										//something is connected to our input
        if([obj eval])	[self setState:timerState];	//if its evaluated state is YES then we are allowed to return timerstate
        else			[self setState:0];			//otherwise we are blocked and return 0
    }
    else				[self setState:timerState]; //nothing connected..return timerState
	[self setEvaluatedState:[self state]];
	return [ORProcessResult processState:evaluatedState value:evaluatedState] ;
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setCycleTime:[decoder decodeFloatForKey:@"cycleTime"]];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeFloat:cycleTime forKey:@"cycleTime"];    
}

@end
