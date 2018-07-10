//
//  ORSelectionTask.m
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
#import "ORSelectionTask.h"
#import "ORGroupView.h"

#pragma mark ¥¥¥Private Methods
@interface ORSelectionTask (private)
- (void) _checkForSelectionChanges;
- (void) _makeSelectionRect;
@end

@implementation ORSelectionTask

#pragma mark ¥¥¥Class Methods
+ (ORSelectionTask*) getTaskForEvent:(NSEvent *)event inView:(ORGroupView*)aView
{
    return [[[ORSelectionTask alloc]initWithEvent:event inView:aView]autorelease];
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
    [self _makeSelectionRect];
}

- (void) mouseDragged:(NSEvent *)event
{
    currentLoc 		= [view convertPoint:[event locationInWindow] fromView:nil];
    [view setNeedsDisplayInRect:NSInsetRect(theSelectionRect,-5,-5)];
    [self _makeSelectionRect];
    [self _checkForSelectionChanges];
    [view setNeedsDisplayInRect:NSInsetRect(theSelectionRect,-5,-5)];
}

- (void) mouseUp:(NSEvent *)event
{
    [view setNeedsDisplay:YES];
}


#pragma mark ¥¥¥Drawing
- (void)drawRect:(NSRect)aRect
{
    if(NSHeight(theSelectionRect)>0 && NSWidth(theSelectionRect)>0){
        [[NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:.1] set];
        [NSBezierPath fillRect:theSelectionRect];

        [[NSColor redColor] set];
        NSFrameRectWithWidth(theSelectionRect, .5);
        
    }
}


#pragma mark ¥¥¥Private Methods
-(void)_checkForSelectionChanges
{
	if([view respondsToSelector:@selector(checkSelectionRect:inView:)]){
		[view checkSelectionRect:theSelectionRect inView:view];
		//[view checkRedrawRect:theSelectionRect inView:view];
	}
}


//-------------------------------------------------------------------------------
// makeSelectionRect
// compute the current selection rect being dragged on the view.
//-------------------------------------------------------------------------------
-(void)_makeSelectionRect
{

    theSelectionRect = NSMakeRect(currentLoc.x>=startLoc.x?startLoc.x:currentLoc.x,
                                  currentLoc.y>=startLoc.y?startLoc.y:currentLoc.y,
                                  fabs(currentLoc.x-startLoc.x),
                                  fabs(currentLoc.y-startLoc.y));
}





@end
