//
//  OROutputCallBackModel.m
//  Orca
//
//  Created by Mark Howe on Mon April 9.
//  Copyright (c) 2012 University of Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Carolina reserve all rights in the program. Neither the authors,
//University of Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "OROutputCallBackModel.h"
#import "ORProcessInConnector.h"
#import "ORProcessModel.h"

NSString* ORCallBackNameChangedNotification	   = @"ORCallBackNameChangedNotification";
NSString* ORCallBackObjectChangedNotification  = @"ORCallBackObjectChangedNotification";
NSString* ORCallBackChannelChangedNotification = @"ORCallBackChannelChangedNotification";
NSString* ORCallBackCustomLabelChanged		   = @"ORCallBackCustomLabelChanged";
NSString* ORCallBackLabelTypeChanged		   = @"ORCallBackLabelTypeChanged";

@interface OROutputCallBackModel (private)
- (NSImage*) composeIcon;
- (NSImage*) composeLowLevelIcon;
@end

@implementation OROutputCallBackModel
#pragma mark •••Initialization
- (void) awakeAfterDocumentLoaded
{
    [self useCallBackObjectWithName:callBackName]; 
    [super awakeAfterDocumentLoaded];
}
-(void) makeConnectors
{
	ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,17) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:OROutputElementInConnection];
    [inConnector setConnectorType: 'LP1 ' ];
    [inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
}
- (BOOL) canBeInAltView
{
	return NO;
}

- (void) setUpImage
{
	[self setImage:[self composeIcon]];
}

- (void) makeMainController
{
    [self linkToController:@"OROutputCallBackController"];
}

- (NSString*) elementName
{
	return @"Output Callback";
}

- (NSString*) callBackName
{
	return callBackName;
}

- (void) setCallBackName:(NSString*) aName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCallBackName:callBackName];
    [callBackName autorelease];
    callBackName = [aName copy];
	
    [self postStateChange];
        
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCallBackNameChangedNotification object:self];
}

- (id) callBackObject
{
	return callBackObject;
}

- (void) setCallBackObject:(id) anObject
{
	[[[self undoManager] prepareWithInvocationTarget:self] setCallBackObject:callBackObject];
    callBackObject = anObject;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCallBackObjectChangedNotification object:self];
}

- (int) callBackChannel
{
	return callBackChannel;
}

- (void) setCallBackChannel:(int)aChannel
{
	[[[self undoManager] prepareWithInvocationTarget:self] setCallBackChannel:callBackChannel];
    callBackChannel = aChannel;
    [self postStateChange];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCallBackChannelChangedNotification object:self];
}

- (NSArray*) validCallBackObjects
{
    return [[self document] collectObjectsConformingTo:@protocol(ORBitProcessor)];
}

- (void) viewCallBackSource
{
	[callBackObject showMainInterface];
}

- (void) objectsRemoved:(NSNotification*) aNotification
{
	[super objectsRemoved:aNotification];
	if(callBackObject && callBackName){
        //we have a callBackObject. make sure that our hwObj still exists
        NSArray* validObjs = [self validCallBackObjects];  
        BOOL stillExists = NO; //assume the worst
        id obj;
        NSEnumerator* e = [validObjs objectEnumerator];
        while(obj = [e nextObject]){
            if(callBackObject == obj){
                stillExists = YES;
                break;
            }
        }
        if(!stillExists){
            [self setCallBackObject:nil];
        }
    }
	
}

- (void) objectsAdded:(NSNotification*) aNotification
{
	[super objectsAdded:aNotification];
    if(!callBackObject && callBackName){
        //we have a callBackObject but no valid object. try to match up with on of the new objects
        NSArray* validObjs = [self validCallBackObjects];  
        id obj;
        NSEnumerator* e = [validObjs objectEnumerator];
        while(obj = [e nextObject]){
            if([callBackName isEqualToString:[obj processingTitle]]){
                [self setCallBackObject:obj];
                break;
            }
        }
    }
}

- (int) callBackLabelType
{
    return callBackLabelType;
}

- (void) setCallBackLabelType:(int)aLabelType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCallBackLabelType:callBackLabelType];
    callBackLabelType = aLabelType;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCallBackLabelTypeChanged object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:OROrcaObjectImageChanged object:self];	
}

- (NSString*) callBackCustomLabel
{
	if(!callBackCustomLabel)return @"";
    return callBackCustomLabel;
}

- (void) setCallBackCustomLabel:(NSString*)aCustomLabel
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCallBackCustomLabel:callBackCustomLabel];
    
    [callBackCustomLabel autorelease];
    callBackCustomLabel = [aCustomLabel copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCallBackCustomLabelChanged object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:OROrcaObjectImageChanged object:self];	
}

- (void) useCallBackObjectWithName:(NSString*)aName
{
    id objectToUse      = nil;
    NSString* nameOfObj = nil;
    NSArray* validObjs = [self validCallBackObjects];    
    if([validObjs count]){
        id obj;
        NSEnumerator* e = [validObjs objectEnumerator];
        while(obj = [e nextObject]){
            if([aName isEqualToString:[obj processingTitle]]){
                objectToUse = obj;
                nameOfObj = [obj processingTitle];
                break;
            }
        }
        [self setCallBackName:nameOfObj];
    }
    [self setCallBackObject:objectToUse];
}

- (void) processIsStarting
{
    [super processIsStarting];
	[callBackObject mapChannel:callBackChannel toHWObject:[hwObject processingTitle] hwChannel:[self bit]];
}

- (void) processIsStopping
{
    [super processIsStopping];
	[callBackObject unMapChannel:callBackChannel fromHWObject:[hwObject processingTitle] hwChannel:[self bit]];
}

//--------------------------------
//runs in the process logic thread
- (id) eval
{
    id obj = [self objectConnectedTo:OROutputElementInConnection];
	BOOL vetoInPlace;
	
	if(!obj) vetoInPlace = NO;
    else     vetoInPlace = [[obj eval] boolValue];
	
	if([guardian inTestMode])vetoInPlace = YES;
	
    [self setState:vetoInPlace];
	
	[callBackObject vetoChangesOnChannel:callBackChannel state:vetoInPlace];
	
    [self setEvaluatedState:vetoInPlace];
	return nil; //we have no output, so just return nil
}
//--------------------------------

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setCallBackName:			[decoder decodeObjectForKey:@"callBackName"]];
    [self setCallBackChannel:		[decoder decodeIntForKey:	@"callBackChannel"]];
    [self setCallBackLabelType:		[decoder decodeIntForKey:	@"callBackLabelType"]];
    [self setCallBackCustomLabel:	[decoder decodeObjectForKey:@"callBackCustomLabel"]];
	
    [[self undoManager] enableUndoRegistration];
    
    [self registerNotificationObservers];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:callBackName			forKey:@"callBackName"];
    [encoder encodeInt:callBackChannel			forKey:@"callBackChannel"];
    [encoder encodeInt:callBackLabelType		forKey:@"callBackLabelType"];
    [encoder encodeObject:callBackCustomLabel	forKey:@"callBackCustomLabel"];
}

- (NSString*) callBackLabel
{
	if(callBackName){
		if(callBackLabelType == 0)	return [NSString stringWithFormat:@"%@,%d",callBackName,callBackChannel];
		if(callBackLabelType == 1)	return @"";
		else						return [self callBackCustomLabel];
	}
	else return @""; 	
}

- (NSAttributedString*) callBackLabelWithSize:(int)theSize color:(NSColor*) textColor
{
	NSString* iconLabel = [self callBackLabel];
	if([iconLabel length]){
		NSFont* theFont = [NSFont messageFontOfSize:theSize];
		return [[[NSAttributedString alloc] 
				 initWithString:iconLabel
				 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
							 theFont,NSFontAttributeName,
							 textColor,NSForegroundColorAttributeName,nil]] autorelease];
	}
	else return nil;
}

@end

@implementation OROutputCallBackModel (private)
- (NSImage*) composeIcon
{
	return [self composeLowLevelIcon];
}

- (NSImage*) composeLowLevelIcon
{
	NSImage* anImage;
	if([self evaluatedState]) anImage = [NSImage imageNamed:@"OutputCallBackVeto"];
	else					  anImage = [NSImage imageNamed:@"OutputCallBack"];
	
	NSSize theIconSize = [anImage size];
    NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
    [finalImage lockFocus];
    [anImage drawAtPoint:NSZeroPoint fromRect:[anImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
	
	NSAttributedString* idLabel   = [self idLabelWithSize:9 color:[NSColor blackColor]];
	NSAttributedString* iconLabel = [self iconLabelWithSize:9 color:[NSColor blackColor]];
	NSAttributedString* callBackLabel = [self callBackLabelWithSize:9 color:[NSColor blackColor]];
	
	if(idLabel){
		NSSize textSize = [idLabel size];
		[idLabel drawInRect:NSMakeRect(10,textSize.height-2,textSize.width,textSize.height)];
	}
	
	if(iconLabel){
		NSSize textSize = [iconLabel size];
		float x = theIconSize.width/2 - textSize.width/2;
		[iconLabel drawInRect:NSMakeRect(x,0,textSize.width,textSize.height)];
	}
	
	if(callBackLabel){
		NSSize textSize = [callBackLabel size];
		float x = theIconSize.width/2 - textSize.width/2;
		[callBackLabel drawInRect:NSMakeRect(x,theIconSize.height-textSize.height-2,textSize.width,textSize.height)];
	}
	
	[finalImage unlockFocus];
	return [finalImage autorelease];
	
}

- (NSString*) iconLabel
{
	if(hwName){
		if(labelType == 0)		return [NSString stringWithFormat:@"%@,%d",hwName,bit];
		else if(labelType == 1) return @"";
		else					return [self customLabel];
	}
	else return @""; 
}


@end
