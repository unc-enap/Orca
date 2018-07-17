//
//  ORInputElement.m
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


#import "ORInputElement.h"
#import "ORProcessInConnector.h"
#import "ORProcessOutConnector.h"
#import "ORProcessModel.h"
#import "ORProcessThread.h"

NSString* ORInputElementInConnection     = @"ORInputElementInConnection";
NSString* ORInputElementOutConnection  = @"ORInputElementOutConnection";

@interface ORInputElement (private)
- (NSImage*) composeIcon;
- (NSImage*) composeLowLevelIcon;
- (NSImage*) composeHighLevelIcon;
- (NSImage*) composeHighLevelIconAsLed;
@end

@implementation ORInputElement
- (NSString*) description:(NSString*)prefix
{
    NSString* s = [super description:prefix];
    id obj = [self objectConnectedTo:ORInputElementInConnection];
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


- (void) doCmdClick:(id)sender atPoint:(NSPoint)aPoint
{
    if([guardian inTestMode]){
        int currentState = [self state];
        [self setState:!currentState];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORProcessElementForceUpdateNotification object:self userInfo:nil]; 
    }
}

-(void)makeConnectors
{
    ORProcessInConnector* inConnector = [[ORProcessInConnector alloc] initAt:NSMakePoint(0,10) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:inConnector forKey:ORInputElementInConnection];
    [ inConnector setConnectorType: 'LP1 ' ];
    [ inConnector addRestrictedConnectionType: 'LP2 ' ]; //can only connect to processor outputs
    [inConnector release];
    
    
    ORProcessOutConnector* outConnector = [[ORProcessOutConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,10) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:outConnector forKey:ORInputElementOutConnection];
    [ outConnector setConnectorType: 'LP2 ' ];
    [ outConnector addRestrictedConnectionType: 'LP1 ' ]; //can only connect to processor inputs
    [outConnector release];
}

- (void) processIsStarting
{
    [super processIsStarting];
    id obj = [self objectConnectedTo:ORInputElementInConnection];
    [obj processIsStarting];
    [ORProcessThread registerInputObject:self];
}

- (void) processIsStopping
{
    [super processIsStopping];
    id obj = [self objectConnectedTo:ORInputElementInConnection];
    [obj processIsStopping];
}
- (int) connectedObjState
{
	return connectedObjState;
}

- (void) setUpImage
{
	[self setImage:[self composeIcon]];
}

//--------------------------------
//runs in the process logic thread
- (id) eval
{
	id obj = [self objectConnectedTo:ORInputElementInConnection];
	if(!alreadyEvaluated){
		if(![guardian inTestMode] && hwObject!=nil){
			[self setState:[hwObject processValue:bit]];
		}
		if(obj) {
			connectedObjState =  [[obj eval] boolValue];
		}
	}
	int theState = [self state];
	if(!obj)		  [self setEvaluatedState:theState];
	else {
		if(!theState) [self setEvaluatedState: theState];
		else		  [self setEvaluatedState: connectedObjState];
	}
	return [ORProcessResult processState:evaluatedState value:evaluatedState];
}
//--------------------------------

@end

@implementation ORInputElement (private)

- (NSImage*) composeIcon
{
	if(![self useAltView])	return [self composeLowLevelIcon];
	else					return [self composeHighLevelIcon];
}

- (NSImage*) composeLowLevelIcon
{
	return nil;
}

- (NSImage*) composeHighLevelIcon
{
	return [self composeHighLevelIconAsLed];
}

- (NSImage*) composeHighLevelIconAsLed
{
	NSImage* anImage;
	
	if(viewIconType == 0){
		if([self state]) anImage = [NSImage imageNamed:@"greenled"];
		else             anImage = [NSImage imageNamed:@"redled"];
	}
	else {
		if([self state]) anImage = [NSImage imageNamed:@"OnText"];
		else             anImage = [NSImage imageNamed:@"OffText"];
	}
	
	NSAttributedString* idLabel   = [self idLabelWithSize:12 color:[NSColor blackColor]];
	NSAttributedString* iconLabel = [self iconLabelWithSize:12 color:[NSColor blackColor]];
	
	NSSize theIconSize	= [anImage size];
	float iconStart		= MAX([iconLabel size].width+3,[idLabel size].width+3);
	
	theIconSize.width += iconStart;
	
    NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
    [finalImage lockFocus];
	[anImage drawAtPoint:NSMakePoint(iconStart,0) fromRect:[anImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];
	if(iconLabel){		
		NSSize textSize = [iconLabel size];
		[iconLabel drawInRect:NSMakeRect(iconStart-textSize.width-1,3,textSize.width,textSize.height)];
	}
	
	if(idLabel){		
		NSSize textSize = [idLabel size];
		[idLabel drawInRect:NSMakeRect(iconStart-[idLabel size].width-1,theIconSize.height-textSize.height,textSize.width,textSize.height)];
	}
	
    [finalImage unlockFocus];
	return [finalImage autorelease];
}

- (NSString*) iconLabel
{
	if(![self useAltView]){
		if(hwName)	{
			if(labelType ==2) return [self customLabel];
			else return [NSString stringWithFormat:@"%@,%d",hwName,bit];
		}
		else		return @""; 
	}
	else {
		if(labelType == 1)return @"";
		else if(labelType ==2)return [self customLabel];
		else {
			if(hwName)	return [NSString stringWithFormat:@"%@,%d",hwName,bit];
			else		return @""; 
		}
	}
}


@end

