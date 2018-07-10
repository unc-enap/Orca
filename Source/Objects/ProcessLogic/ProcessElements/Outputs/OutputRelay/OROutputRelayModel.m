//
//  OROutputRelayModel.m
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
#import "OROutputRelayModel.h"

@interface OROutputRelayModel (private)
- (NSImage*) composeIcon;
- (NSImage*) composeLowLevelIcon;
- (NSImage*) composeHighLevelIcon;
- (NSImage*) composeHighLevelIconAsLed;
@end

@implementation OROutputRelayModel

#pragma mark ¥¥¥Initialization
- (BOOL) canBeInAltView
{
	return YES;
}

- (void) setUpImage
{
	[self setImage:[self composeIcon]];
}

- (void) makeMainController
{
    [self linkToController:@"OROutputRelayController"];
}

- (NSString*) elementName
{
	return @"Output relay";
}


@end

@implementation OROutputRelayModel (private)
- (NSImage*) composeIcon
{
	if(![self useAltView])	return [self composeLowLevelIcon];
	else					return [self composeHighLevelIcon];
}

- (NSImage*) composeLowLevelIcon
{
	NSImage* anImage;
	if([self state]) anImage = [NSImage imageNamed:@"OutputRelayOn"];
	else             anImage = [NSImage imageNamed:@"OutputRelayOff"];
	
	NSSize theIconSize = [anImage size];
    NSImage* finalImage = [[NSImage alloc] initWithSize:theIconSize];
    [finalImage lockFocus];
    [anImage drawAtPoint:NSZeroPoint fromRect:[anImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
	NSAttributedString* idLabel   = [self idLabelWithSize:9 color:[NSColor blackColor]];
	NSAttributedString* iconLabel = [self iconLabelWithSize:9 color:[NSColor blackColor]];
	if(iconLabel){
		NSSize textSize = [iconLabel size];
		float x = theIconSize.width/2 - textSize.width/2;
		[iconLabel drawInRect:NSMakeRect(x,0,textSize.width,textSize.height)];
	}
	
	if(idLabel){
		NSSize textSize = [idLabel size];
		[idLabel drawInRect:NSMakeRect(0,theIconSize.height-textSize.height-2,textSize.width,textSize.height)];
	}
	
	[finalImage unlockFocus];
	return [finalImage autorelease];

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
    [anImage drawAtPoint:NSMakePoint(iconStart,0) fromRect:[anImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
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
		if(hwName){
			if(labelType ==2) return [self customLabel];
			else return [NSString stringWithFormat:@"%@,%d",hwName,bit];
		}
		else return @""; 
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
