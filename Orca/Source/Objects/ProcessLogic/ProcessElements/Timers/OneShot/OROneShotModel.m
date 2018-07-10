//
//  OROneShotModel.m
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
#import "OROneShotModel.h"
#import "ORInvertedOutputNub.h"
#import "ORProcessInConnector.h"
#import "ORProcessOutConnector.h"

NSString* OROneShotInvertedConnection	= @"OROneShotInvertedConnection";
NSString* OROneShotInConnection			= @"OROneShotInConnection";
NSString* OROneShotResetConnection		= @"OROneShotResetConnection";
NSString* OROneShotOutConnection		= @"OROneShotOutConnection";
NSString* OROneShotTimeChangedNotification = @"OROneShotTimeChangedNotification";
NSString* OROneShotLock					= @"OROneShotLock";

@implementation OROneShotModel

#pragma mark ¥¥¥Initialization

-(void)dealloc
{
    [invertedOuputNub release];
    [super dealloc];
}

-(void)makeConnectors
{
    
    ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,[self frame].size.height-kConnectorSize-5) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:OROneShotResetConnection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
    
    inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,5) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:OROneShotInConnection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
    
    
    ORProcessOutConnector* outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,5) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:OROneShotInvertedConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];
    
    
    outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize ,[self frame].size.height-kConnectorSize-5) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:OROneShotOutConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];
    
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"OneShot"]];
}

- (void) makeMainController
{
    [self linkToController:@"OROneShotController"];
}
- (NSString*) elementName
{
    return @"One Shot";
}

- (NSString*) description:(NSString*)prefix
{
    NSString* s = [super description:prefix];
    id obj1 = [self objectConnectedTo:OROneShotInConnection];
    NSString* nextPrefix = [prefix stringByAppendingString:@"  "];
    NSString* noConnectionString = [NSString stringWithFormat:@"%@--",nextPrefix];
    return [NSString stringWithFormat:@"%@\n%@",s,
                                    obj1?[obj1 description:nextPrefix]:noConnectionString];
}
- (void) setUpNubs
{
    if(!invertedOuputNub)invertedOuputNub = [[ORInvertedOutputNub alloc] init];
    [invertedOuputNub setGuardian:self];
    ORConnector* aConnector = [[self connectors] objectForKey: OROneShotInvertedConnection];
    [aConnector setObjectLink:invertedOuputNub];
}

#pragma mark ¥¥¥Accessors
- (NSTimeInterval) oneShotTime
{
    return oneShotTime;
}

- (void) setOneShotTime:(NSTimeInterval)aoneShotTime
{
    if(aoneShotTime<=0)aoneShotTime = 1;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setOneShotTime:oneShotTime];
    
    oneShotTime = aoneShotTime;
    
    [[NSNotificationCenter defaultCenter]
		postNotificationName:OROneShotTimeChangedNotification
                              object:self];
}


- (void) processIsStarting
{
    [super processIsStarting];
    setState = 0;
    resetState = 0;
    timerRunning = NO;
    [self setState:0];
}

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
        
        if(oldSetState == 0 && newSetState == 1)setStateTransition = YES;
        if(oldResetState == 0 && newResetState == 1) resetTransition = YES;
        
        setState = newSetState;
        resetState = newResetState;
        
        if(setStateTransition && !resetTransition){
            if(!timerRunning){
                [self setState:1];
                timerRunning = YES;
                t0 = [NSDate timeIntervalSinceReferenceDate];
            }
        }
        else if(!setStateTransition && resetTransition){
            timerRunning = NO;
            [self setState:0];
        }
        else if(timerRunning){
            NSTimeInterval t1 = [NSDate timeIntervalSinceReferenceDate];
            if(t1-t0 >= oneShotTime){
                [self setState:0];
                timerRunning = NO;
            }
        }
        alreadyEvaluated = YES;
		[self setEvaluatedState:[self state]];
    }
	return [ORProcessResult processState: evaluatedState value:evaluatedState];
}

- (id) evalInput1
{
    id obj1 = [self objectConnectedTo:OROneShotInConnection];
    return [obj1 eval];
}

- (id) evalInput2
{
    id obj1 = [self objectConnectedTo:OROneShotResetConnection];
    return [obj1 eval];
}

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setOneShotTime:[decoder decodeFloatForKey:@"oneShotTime"]];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeFloat:oneShotTime forKey:@"oneShotTime"];    
}

@end

