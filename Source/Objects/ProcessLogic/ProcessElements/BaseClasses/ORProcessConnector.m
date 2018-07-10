//
//  ORProcessConnector.m
//  Orca
//
//  Created by Mark Howe on 1/11/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


#import "ORProcessConnector.h"


@implementation ORProcessConnector

- (void) dealloc
{
	[stateOnImage release];
	[stateOffImage release];
	[stateOnImage_Highlighted release];
	[stateOffImage_Highlighted release];
	[super dealloc];
}

- (NSImage*) stateOnImage
{
    return stateOnImage;
}

- (void) setStateOnImage:(NSImage *)anImage
{
    [anImage retain];
    [stateOnImage release];
    stateOnImage = anImage;

	stateOnImage_Highlighted = [[NSImage alloc] initWithSize:[stateOnImage size]];
	[stateOnImage_Highlighted lockFocus];
    [stateOnImage drawAtPoint:NSZeroPoint fromRect:[stateOnImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
    
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
	NSRect sourceRect = NSMakeRect(0,0,[stateOnImage size].width,[stateOnImage size].height);
	NSRectFillUsingOperation(sourceRect, NSCompositeSourceAtop);
	[stateOnImage_Highlighted unlockFocus];
}

- (NSImage*) stateOffImage
{
    return stateOffImage;
}

- (void) setStateOffImage:(NSImage *)anImage
{
    [anImage retain];
    [stateOffImage release];
    stateOffImage = anImage;

	stateOffImage_Highlighted = [[NSImage alloc] initWithSize:[stateOffImage size]];
	[stateOffImage_Highlighted lockFocus];
    [stateOffImage drawAtPoint:NSZeroPoint fromRect:[stateOffImage imageRect] operation:NSCompositeSourceOver fraction:1.0];
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
	NSRect sourceRect = NSMakeRect(0,0,[stateOffImage size].width,[stateOffImage size].height);
	NSRectFillUsingOperation(sourceRect, NSCompositeSourceAtop);
	[stateOffImage_Highlighted unlockFocus];

}


@end
