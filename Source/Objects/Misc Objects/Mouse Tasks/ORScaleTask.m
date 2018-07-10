//
//  ORScaleTask.m
//  Orca
//
//  this object handles selection of icons using a drag rect
//
//  Created by Mark Howe on Sun Apr 28 2002.
//  Copyright © 2001 CENPA, University of Washington. All rights reserved.
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
#import "ORScaleTask.h"

@implementation ORScaleTask

#pragma mark ¥¥¥Class Methods
+ (ORScaleTask*) getTaskForEvent:(NSEvent *)event inView:(ORGroupView*)aView
{
    return [[[ORScaleTask alloc]initWithEvent:event inView:aView]autorelease];
}

#pragma mark ¥¥¥Initialization
- (id)   initWithEvent:(NSEvent*)event inView:(ORGroupView*)aView
{
    self = [super init];
	view = aView;
	return self;
}

#pragma mark ¥¥¥Mouse Events
- (void) mouseDown:(NSEvent*) event
{
    startLoc 	= [view convertPoint:[event locationInWindow] fromView:nil];
    currentLoc 	= startLoc;
	scaleFactor = [view scalePercent];
    [[(ORAppDelegate*)[NSApp delegate] undoManager] disableUndoRegistration];
}

- (void) mouseDragged:(NSEvent *)event
{
	int delta  = currentLoc.y - startLoc.y;
	if(abs(delta) > 5){
		if(delta>0)delta = 1;
		else       delta = -1;
		scaleFactor += delta;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:scaleFactor] forKey:@"ScaleFactor"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ScaleView" object:view userInfo:userInfo];
		startLoc = currentLoc;
	}
	currentLoc = [view convertPoint:[event locationInWindow] fromView:nil];
}

- (void) mouseUp:(NSEvent *)event
{
    [view setNeedsDisplay:YES];
    [[(ORAppDelegate*)[NSApp delegate] undoManager] enableUndoRegistration];
}


#pragma mark ¥¥¥Drawing
- (void)drawRect:(NSRect)aRect
{
}

@end
