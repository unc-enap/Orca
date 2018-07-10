//
//  ORSwitchImage.m
//  Orca
//
//  Created by Mark Howe on Fri Oct 22, 2004.
//  Copyright 2008 University of North Carolina. All rights reserved.
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
#import "ORSwitchImage.h"
#import "NSImage+Extensions.h"
#import "SynthesizeSingleton.h"

@implementation ORSwitchImages

SYNTHESIZE_SINGLETON_FOR_ORCLASS(SwitchImages);

- (ORSwitchImage *) switchWithState:(BOOL)aState angle:(float)anAngle
{
	id theStateKey = [NSNumber numberWithBool:aState];
	id theAngleKey = [NSNumber numberWithInt:(int)anAngle];
	id anImage = [[switchImages objectForKey:theStateKey] objectForKey:theAngleKey];
	if(anImage) return anImage;
	else {																				//couldn't find one already made.
		if(!aState) anImage = [ORSwitchImage openSwitchWithAngle:anAngle];
		else	   anImage = [ORSwitchImage closedSwitchWithAngle:anAngle];
		
		if(!switchImages) switchImages = [[NSMutableDictionary dictionary] retain];		//check the top level dictionary
		NSMutableDictionary* stateGroup = [switchImages objectForKey:theStateKey];		//check the top level entry
		if(!stateGroup) {																//couldn't find anything for this color
			stateGroup = [NSMutableDictionary dictionary];						//make an dictionary
			[switchImages setObject:stateGroup forKey:theStateKey];								//enter it
		}
		[stateGroup setObject:anImage forKey:[NSNumber numberWithInt:(int)anAngle]];
	}
	return anImage;
}
@end


@implementation ORSwitchImage
//assumes a 20x20 area to draw into
+ (id) closedSwitchWithAngle:(float)anAngle
{
	NSPoint switchPoints[2] = {
		{0,10},
		{18,10}
	};
	return [ORSwitchImage switchWithAngle:anAngle points:switchPoints];
}

+ (id) openSwitchWithAngle:(float)anAngle
{
	NSPoint switchPoints[2] = {
		{5,19},
		{18,9}
	};	
	return [ORSwitchImage switchWithAngle:anAngle points:switchPoints];
}

	
+ (id) switchWithAngle:(float)anAngle points:(NSPoint*)switchPoints
{
	NSImage *anImage = [[[NSImage alloc] initWithSize:NSMakeSize(20,20)] autorelease];        
	
	[anImage lockFocus];

	float oldLineWidth = [NSBezierPath defaultLineWidth];
	[NSBezierPath setDefaultLineWidth:1];

	[[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(0,8,4,4)] fill]; //right side dot	
	[[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(15,8,4,4)] fill]; //left side dot

	NSBezierPath* sw = [NSBezierPath bezierPath];
	[sw appendBezierPathWithPoints:switchPoints count:2];
	[sw stroke];
	[anImage unlockFocus];
		
	[NSBezierPath setDefaultLineWidth:oldLineWidth];
	return [anImage rotateIndividualImage: anImage angle:anAngle];
}

@end


