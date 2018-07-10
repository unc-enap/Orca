//
//  ORCountDownModel.m
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
#import "ORCountDownModel.h"
#import "ORInputElement.h"
#import "ORProcessOutConnector.h"
#import "ORInvertedOutputNub.h"

NSString* ORCountDownInvertedConnection				= @"ORCountDownInvertedConnection";
NSString* ORCountDownStartCountChangedNotification	= @"ORCountDownStartCountChangedNotification";
NSString* ORCountDownLock							= @"ORCountDownLock";

@implementation ORCountDownModel

#pragma mark ¥¥¥Initialization


-(void)dealloc
{
    [invertedOuputNub release];
    [super dealloc];
}
- (void) makeMainController
{
    [self linkToController:@"ORCountDownController"];
}
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"CountDown"]];
    [self addOverLay];
}

- (BOOL) canImageChangeWithState
{
    return YES;
}

- (NSString*) elementName
{
    return @"Count Down";
}

- (id) stateValue
{
    return [NSNumber numberWithInt:startCount-count];
}

- (void) addOverLay
{
    if(!guardian) return;
    
    NSImage* aCachedImage = [self image];
    NSSize theIconSize = [aCachedImage size];
    NSImage* i = [[NSImage alloc] initWithSize:theIconSize];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    
    NSString* label;
    NSFont* theFont;
    NSAttributedString* n;
    
    theFont = [NSFont messageFontOfSize:8];
    label = [NSString stringWithFormat:@"%d",startCount - count];
    n = [[NSAttributedString alloc] 
                    initWithString:label 
                        attributes:[NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName]];
    
    NSSize textSize = [n size];
    float x = theIconSize.width/2 - textSize.width/2;
    [n drawInRect:NSMakeRect(x,5,textSize.width,textSize.height)];
    [n release];
    
    
    if([self uniqueIdNumber]){
        theFont = [NSFont messageFontOfSize:8];
        n = [[NSAttributedString alloc] 
            initWithString:[NSString stringWithFormat:@"%lu",[self uniqueIdNumber]] 
                attributes:[NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName]];
        
        NSSize textSize = [n size];
        float x = theIconSize.width/2 - textSize.width/2;
        [n drawInRect:NSMakeRect(x,theIconSize.height - textSize.height - 5,textSize.width,textSize.height)];
        [n release];
    }
    
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
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
    [[self connectors] setObject:outConnector forKey:ORCountDownInvertedConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];
    
}

- (void) setUpNubs
{
    if(!invertedOuputNub)invertedOuputNub = [[ORInvertedOutputNub alloc] init];
    [invertedOuputNub setGuardian:self];
    ORConnector* aConnector = [[self connectors] objectForKey: ORCountDownInvertedConnection];
    [aConnector setObjectLink:invertedOuputNub];
}

- (void) processIsStarting
{
    [super processIsStarting];
    setState = 0;
    resetState = 0;
    count = 0;
    oldCount = 0;
    [self setState:0];
}

- (int) startCount
{
    return startCount;
}

- (void) setStartCount:(int)value
{
    if(value<=0)value = 1;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setStartCount:startCount];
    
    startCount = value;
    
    [self postStateChange];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORCountDownStartCountChangedNotification
                      object: self];
    
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
        
        if(oldSetState == 0 && newSetState == 1)setStateTransition = YES;
        if(oldResetState == 0 && newResetState == 1) resetTransition = YES;
        
        
        setState = newSetState;
        resetState = newResetState;
        
        if(setStateTransition && !resetTransition){
            count++;
            if(count>=startCount){
                [self setState:1];
                count = startCount;
            }
        }
        else if(!setStateTransition && resetTransition){
            count = 0;
            [self setState:0];
        }
        else if(setStateTransition && resetTransition){
            count = 0;
            [self setState:0];
        }
        
        if(setStateTransition || resetTransition || count != oldCount){
            oldCount = count;
			[self postStateChange];
        }
        
    }
    [self setEvaluatedState:[self state]];
	return [ORProcessResult processState:evaluatedState value:evaluatedState];
}

//--------------------------------


#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setStartCount:[decoder decodeIntForKey:@"startCount"]];
    
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:startCount forKey:@"startCount"];
}

@end
