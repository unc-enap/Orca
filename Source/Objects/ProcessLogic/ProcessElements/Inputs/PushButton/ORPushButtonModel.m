//
//  ORPushButtonModel.m
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
#import "ORPushButtonModel.h"
#import "ORProcessModel.h"
@interface ORPushButtonModel (private)
- (NSImage*) composeIcon;
- (NSImage*) composeLowLevelIcon;
- (NSImage*) composeHighLevelIcon;
@end

@implementation ORPushButtonModel

#pragma mark ¥¥¥Initialization

- (void) setUpImage
{
	[self setImage:[self composeIcon]];
}

- (void) makeMainController
{
    [self linkToController:@"ORPushButtonController"];
}

- (NSString*) elementName
{
	return @"Push Button";
}

- (void) doCmdClick:(id)sender atPoint:(NSPoint)aPoint
{
	BOOL currentState = [self state];
	[self setState:!currentState];
}

- (BOOL) canBeInAltView
{
	return YES;
}

- (BOOL)  canImageChangeWithState 
{ 
	return YES; 
}

//--------------------------------
//runs in the process logic thread
- (id) eval
{
	id obj = [self objectConnectedTo:ORInputElementInConnection];
	if(!alreadyEvaluated){
		int theState = [self state];
		if(!obj)		  [self setEvaluatedState:theState];
		else {
			if(!theState) [self setEvaluatedState: theState];
			else		  [self setEvaluatedState: [[obj eval] boolValue]];
		}
	}
	return [ORProcessResult processState:evaluatedState value:evaluatedState];
}
//--------------------------------

@end

@implementation ORPushButtonModel (private)

- (NSImage*) composeIcon
{
	if(![self useAltView])	return [self composeLowLevelIcon];
	else					return [self composeHighLevelIcon];
}
- (NSImage*) composeLowLevelIcon
{
	if([self state]) return [NSImage imageNamed:@"PushButtonOn"];
	else             return [NSImage imageNamed:@"PushButtonOff"];
}

- (NSImage*) composeHighLevelIcon
{
	NSImage* anImage;
	if([self state]) anImage = [NSImage imageNamed:@"OnSwitch"];
	else             anImage = [NSImage imageNamed:@"OffSwitch"];
	NSAttributedString* idLabel   = [self idLabelWithSize:12 color:[NSColor blackColor]];
	
	NSSize theIconSize = [anImage size];
	float iconStart		= [idLabel size].width + 1;
	theIconSize.width += iconStart;

	NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
	[finalImage lockFocus];
    [anImage drawAtPoint:NSMakePoint(iconStart,0) fromRect:[anImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];	
	if(idLabel){		
		NSSize textSize = [idLabel size];
		[idLabel drawInRect:NSMakeRect(iconStart-[idLabel size].width-1,theIconSize.height-textSize.height,textSize.width,textSize.height)];
	}
	
    [finalImage unlockFocus];
	return [finalImage autorelease];
}
@end
