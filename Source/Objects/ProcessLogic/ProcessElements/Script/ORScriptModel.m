//
//  ORScriptModel.m
//  Orca
//
//  Created by Mark Howe on Sun Sept 16, 2007.
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
#import "ORScriptModel.h"
#import "ORProcessInConnector.h"
#import "ORScriptRunner.h"

NSString* ORScriptLock							= @"ORScriptLock";
NSString* ORScriptInputConnection				= @"ORScriptInputConnection";
NSString* ORScriptPathChanged					= @"ORScriptPathChanged";

@implementation ORScriptModel

#pragma mark ¥¥¥Initialization

- (void) dealloc
{
	[scriptRunner release];
	[super dealloc];
}

- (void) makeMainController
{
    [self linkToController:@"ORScriptController"];
}
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Script"]];
    [self addOverLay];
}

- (BOOL) canImageChangeWithState
{
    return YES;
}

- (NSString*) elementName
{
    return @"Script";
}

- (NSString*) scriptPath
{
	return scriptPath;
}

- (void) setScriptPath:(NSString*)aPath
{
	[[[self undoManager] prepareWithInvocationTarget:self] setScriptPath:scriptPath];
    
	if(!aPath)aPath = @"";
	
    [scriptPath autorelease];
    scriptPath = [aPath copy];
    
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORScriptPathChanged
                      object:self];
}

- (id) stateValue
{
   // return [NSNumber numberWithInt:running];
   return [NSNumber numberWithInt:0];
}

- (NSString*) description:(NSString*)prefix
{
    NSString* s = [super description:prefix];
    id obj2 = [self objectConnectedTo:ORScriptInputConnection];
    NSString* nextPrefix = [prefix stringByAppendingString:@"  "];
    NSString* noConnectionString = [NSString stringWithFormat:@"%@--",nextPrefix];
    return [NSString stringWithFormat:@"%@\n%@\n",s,
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
    if([self uniqueIdNumber]){
        NSFont* theFont = [NSFont messageFontOfSize:8];
        NSAttributedString*n = [[NSAttributedString alloc] 
								initWithString:[NSString stringWithFormat:@"%lu",[self uniqueIdNumber]] 
								attributes:[NSDictionary dictionaryWithObject:theFont forKey:NSFontAttributeName]];
        
        NSSize textSize = [n size];
        float x = 20;
        [n drawInRect:NSMakeRect(x,theIconSize.height - textSize.height - 10,textSize.width,textSize.height-2)];
        [n release];
    }
    
    [i unlockFocus];
    
    [self setImage:i];
    [i release];
    
}

-(void)makeConnectors
{
    ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(5,6) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORScriptInputConnection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
}
    
- (void) processIsStarting
{
    [super processIsStarting];
    setState = 0;
    resetState = 0;
	[self postStateChange];
}

//--------------------------------
//runs in the process logic thread
- (id) eval
{
    if(!alreadyEvaluated){
        alreadyEvaluated = YES;
        int oldSetState   = setState;
        
        int newSetState   = [[[self objectConnectedTo:ORScriptInputConnection] eval] boolValue];
                
        setState = newSetState;
			
        if(oldSetState != newSetState){
			if(!scriptRunner){
				scriptRunner = [[ORScriptRunner alloc] init];
			}
			if(newSetState == 1 && [scriptPath length]>0){
				if(![scriptRunner running]){
					[scriptRunner parseFile:scriptPath];
					[scriptRunner run:nil sender:self];
				}
			}
			else {
				[scriptRunner stop];
			}
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
	[self setScriptPath:[decoder decodeObjectForKey:@"scriptPath"]];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeObject:scriptPath forKey:@"scriptPath"];
}

@end
