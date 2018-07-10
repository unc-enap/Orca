//
//  ORSPSTRelayModel.m
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
#import "ORSPSTRelayModel.h"

@implementation ORSPSTRelayModel

#pragma mark ¥¥¥Initialization


- (void) makeMainController
{
    [self linkToController:@"ORSPSTRelayController"];
}
- (NSString*) elementName
{
	return @"SPST Input relay";
}
- (BOOL) canBeInAltView
{
	return YES;
}
- (NSImage*) composeLowLevelIcon
{
	NSImage* anImage;
	if([self state]) anImage = [NSImage imageNamed:@"SPSTRelayOn"];
	else             anImage = [NSImage imageNamed:@"SPSTRelayOff"];
    if([self state]) [self setImage:[NSImage imageNamed:@"SPSTRelayOn"]];
    else               [self setImage:[NSImage imageNamed:@"SPSTRelayOff"]];
	
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


@end
