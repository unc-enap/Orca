//
//  ORConnectionTask.m
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
#import "ORConnectionTask.h"
#import "ORGroupView.h"

@implementation ORConnectionTask

#pragma mark ¥¥¥Class Methods
+ (ORConnectionTask*) getTaskForEvent:(NSEvent *)event inView:(ORGroupView*)aView
{
    return [[[ORConnectionTask alloc]initWithEvent:event inView:aView]autorelease];
}

#pragma mark ¥¥¥Initialization
- (id)   initWithEvent:(NSEvent*)event inView:(ORGroupView*)aView
{
    self = [super init];
	view = aView;
    return self;
}

#pragma mark ¥¥¥Accessors
-(void)setView:(ORGroupView*)aView
{
	view = aView;
}

- (NSPoint) startLoc
{
	return startLoc;
}

- (void) setStartLoc:(NSPoint)aPoint
{
	startLoc = aPoint;
}

- (NSPoint) currentLoc
{
	return currentLoc;
}

- (void) setCurrentLoc:(NSPoint)aPoint
{
	currentLoc = aPoint;
}

#pragma mark ¥¥¥Mouse Events
- (void) mouseDown:(NSEvent*) event
{
    [self setStartLoc:[view convertPoint:[event locationInWindow] fromView:nil]];
    [self setCurrentLoc:[self startLoc]];
}

- (void) mouseDragged:(NSEvent *)event
{
    NSRect originalRect = [self makeBoundsRect];
    [view setNeedsDisplayInRect:originalRect];
    [self setCurrentLoc:[view convertPoint:[event locationInWindow] fromView:nil]];
	if([view respondsToSelector:@selector(checkRedrawRect:inView:)]){
		[view checkRedrawRect:originalRect inView:view];
	}

    [view setNeedsDisplayInRect:[self makeBoundsRect]];
}

- (void) mouseUp:(NSEvent *)event
{
    [self setCurrentLoc:[view convertPoint:[event locationInWindow] fromView:nil]];
	[view doConnectionFrom:[self startLoc] to:[self currentLoc]];
    [view setNeedsDisplay:YES];
}


#pragma mark ¥¥¥Drawing
- (void)drawRect:(NSRect)aRect
{
	NSBezierPath* path = [NSBezierPath bezierPath];
	[[NSColor redColor] set];
	[path setLineWidth:.5];
	[path moveToPoint:[self startLoc]];
	[path lineToPoint:[self currentLoc]];
	[path stroke];
}


- (NSRect) makeBoundsRect
{

    return NSInsetRect(NSMakeRect(currentLoc.x>=startLoc.x?startLoc.x:currentLoc.x,
                                  currentLoc.y>=startLoc.y?startLoc.y:currentLoc.y,
                                  fabs(currentLoc.x-startLoc.x),
                                  fabs(currentLoc.y-startLoc.y)),-10,-10);
}

@end
