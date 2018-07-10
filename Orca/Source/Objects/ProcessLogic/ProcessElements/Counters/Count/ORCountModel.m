//
//  ORCountModel.m
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
#import "ORCountModel.h"
#import "ORProcessInConnector.h"

NSString* ORCountLock							= @"ORCountLock";
NSString* ORCountResetConnection				= @"ORCountResetConnection";
NSString* ORCountInputConnection				= @"ORCountInputConnection";

@implementation ORCountModel

#pragma mark ¥¥¥Initialization

- (void) makeMainController
{
    [self linkToController:@"ORCountController"];
}
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Count"]];
    [self addOverLay];
}

- (BOOL) canImageChangeWithState
{
    return YES;
}

- (NSString*) elementName
{
    return @"Counter";
}

- (id) stateValue
{
    return [NSNumber numberWithInt:count];
}

- (NSString*) description:(NSString*)prefix
{
    NSString* s = [super description:prefix];
    id obj1 = [self objectConnectedTo:ORCountResetConnection];
    id obj2 = [self objectConnectedTo:ORCountInputConnection];
    NSString* nextPrefix = [prefix stringByAppendingString:@"  "];
    NSString* noConnectionString = [NSString stringWithFormat:@"%@--",nextPrefix];
    return [NSString stringWithFormat:@"%@\n%@\n%@",s,
                                    obj1?[obj1 description:nextPrefix]:noConnectionString,
                                    obj2?[obj2 description:nextPrefix]:noConnectionString];
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
    
    theFont = [NSFont messageFontOfSize:10];
    label = [NSString stringWithFormat:@"%d",count];
    n = [[NSAttributedString alloc] 
                    initWithString:label 
                        attributes:[NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName]];
    
    NSSize textSize = [n size];
    float x = theIconSize.width/2 - textSize.width/2 + 5;
    [n drawInRect:NSMakeRect(x,5,textSize.width,textSize.height)];
    [n release];
    
    
    if([self uniqueIdNumber]){
        theFont = [NSFont messageFontOfSize:8];
        n = [[NSAttributedString alloc] 
            initWithString:[NSString stringWithFormat:@"%lu",[self uniqueIdNumber]] 
                attributes:[NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName]];
        
        NSSize textSize = [n size];
        float x = 27;
        [n drawInRect:NSMakeRect(x,theIconSize.height - textSize.height - 5,textSize.width,textSize.height-2)];
        [n release];
    }
    
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
}

-(void)makeConnectors
{
    ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(5,6) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORCountInputConnection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];

    inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(5 ,[self frame].size.height-kConnectorSize-5) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORCountResetConnection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
}
    
- (void) processIsStarting
{
    [super processIsStarting];
    setState = 0;
    resetState = 0;
    count = 0;
    oldCount = 0;
	[self postStateChange];
}

//--------------------------------
//runs in the process logic thread
- (id) eval
{
    if(!alreadyEvaluated){
        alreadyEvaluated = YES;
        int oldSetState   = setState;
        int oldResetState = resetState;
        
        int newResetState = [[[self objectConnectedTo:ORCountResetConnection] eval] boolValue];
        int newSetState   = [[[self objectConnectedTo:ORCountInputConnection] eval] boolValue];
        
        BOOL setStateTransition = NO;
        BOOL resetTransition    = NO;
        
        if(oldSetState == 0 && newSetState == 1)setStateTransition = YES;
        if(oldResetState == 0 && newResetState == 1) resetTransition = YES;
        
        
        setState = newSetState;
        resetState = newResetState;
        
        if(setStateTransition && !resetTransition){
            count++;
        }
        else if(!setStateTransition && resetTransition){
            count = 0;
        }
        else if(setStateTransition && resetTransition){
            count = 0;
        }
        
        if(setStateTransition || resetTransition || count != oldCount){
            oldCount = count;
			[self postStateChange];
        }
        
    }
	return nil; //nothing can connect to this object so just return 0
}

//--------------------------------


#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
        
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
}

@end
