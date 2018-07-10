//
//  ORRamperView.m
//  test
//
//  Created by Mark Howe on 3/28/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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


#import "ORRamperView.h"
#import "ORRamperController.h"
#import "ORRamperModel.h"
#import "ORRampItem.h"
#import "ORAxis.h"

#define kWayPointSize 8
#define kTargetSelectionHeight 5

@implementation ORRamperView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		rightTargetBug = [[NSImage imageNamed:@"triangleBugRight"] retain];
    }
    return self;
}

- (void) dealloc
{
	[gradient release];
	[rightTargetBug release];
	[super dealloc];
}

- (void) setDelegate:(id)aDelegate
{
    delegate = aDelegate;
}

- (id) delegate 
{
    return delegate;
}

- (void)drawRect:(NSRect)rect 
{

	ORRampItem* model = [delegate selectedRampItem];
	NSRect rampArea = [self bounds];
	
	if(![model targetObject]){
		NSAttributedString* s = [[NSAttributedString alloc] initWithString:@"No Object"];
		NSSize stringSize = [s size];
		[s drawAtPoint:NSMakePoint(rampArea.size.width/2 - stringSize.width/2,rampArea.size.height/2 - stringSize.height/2)];
		[s release];
		
		return;
	}
	if(![model parameterObject]){
		NSAttributedString* s = [[NSAttributedString alloc] initWithString:@"No Selector"];
		NSSize stringSize = [s size];
		[s drawAtPoint:NSMakePoint(rampArea.size.width/2 - stringSize.width/2,rampArea.size.height/2 - stringSize.height/2)];
		[s release];
		
		return;
	}
	
	float bugPadWidth = [rightTargetBug size].width;
	float bugPadHeight = [rightTargetBug size].height+2;
	[[NSColor colorWithCalibratedRed:.75 green:.75 blue:.75 alpha:1] set];
	rampArea.size.width -= bugPadWidth/2;
		
 	if(!gradient){
		NSColor* startingColor = [NSColor colorWithCalibratedRed:.75 green:.75 blue:.75 alpha:1];
		NSColor* endingColor = [NSColor colorWithCalibratedRed:.9 green:.9 blue:.9 alpha:1];
		gradient = [[NSGradient alloc] initWithStartingColor:startingColor endingColor:endingColor];
	}
	[gradient drawInRect:rampArea angle:90.];
	[NSBezierPath setDefaultLineWidth:1];
	[[NSColor grayColor] set];
	[NSBezierPath strokeRect:rampArea];
		
	if(selectedWayPoint){
		[[NSColor colorWithCalibratedRed:.7 green:0 blue:0 alpha:.1] set];
		float y1 = yLowConstraint;
		float y2 = yHighConstraint;
		int index = [[model wayPoints] indexOfObject:selectedWayPoint];
		if(index == [model wayPointCount]-1){
			NSPoint nextToLastPoint = [[model wayPoint:[model wayPointCount]-2] xyPosition];
			float y = [yScale getPixAbs:nextToLastPoint.y];
			float x = [xScale getPixAbs:nextToLastPoint.x];
			[[NSColor colorWithCalibratedRed:.7 green:0 blue:0 alpha:.3] set];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(x,y) 
								      toPoint:NSMakePoint([self bounds].size.width - bugPadWidth,y)];
		}
		else if(index == 0){
			NSPoint secondPoint = [[model wayPoint:1] xyPosition];
			float y = [yScale getPixAbs:secondPoint.y];
			float x = [xScale getPixAbs:secondPoint.x];
			[[NSColor colorWithCalibratedRed:.7 green:0 blue:0 alpha:.3] set];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(0,y) 
								      toPoint:NSMakePoint(x,y)];
		}
		else {
			[NSBezierPath fillRect:rampArea];
			[[NSColor colorWithCalibratedRed:.8 green:.8 blue:.8 alpha:1] set];
			//[NSBezierPath fillRect:NSMakeRect(xLowConstraint,y1,xHighConstraint-xLowConstraint,y2-y1)];
			[gradient drawInRect:NSMakeRect(xLowConstraint,y1,xHighConstraint-xLowConstraint,y2-y1) angle:90.];

			[[NSColor colorWithCalibratedRed:.7 green:0 blue:0 alpha:.3] set];
			[NSBezierPath strokeRect:NSMakeRect(xLowConstraint,y1,xHighConstraint-xLowConstraint,y2-y1)];
		}
		[[NSColor yellowColor] set];
		float y = [yScale getPixAbs:[[model wayPoint:index] xyPosition].y];
		float x = [xScale getPixAbs:[[model wayPoint:index] xyPosition].x];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(0,y) toPoint:NSMakePoint([self bounds].size.width-bugPadWidth,y)];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x,0) toPoint:NSMakePoint(x,[self bounds].size.height-bugPadHeight/2)];

		NSAttributedString* s = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.0f,%.0f",[[model wayPoint:index] xyPosition].x,[[model wayPoint:index] xyPosition].y]];
		NSSize stringSize = [s size];
		x += 5;
		if(x + stringSize.width + 5  > rampArea.size.width){
			x = rampArea.size.width - stringSize.width - 5;
		}
		y += 5;
		if(y + stringSize.height + 5  > rampArea.size.height){
			y = rampArea.size.height - stringSize.height - 5;
		}
		[s drawAtPoint:NSMakePoint(x,y)];
		[s release];
	}


	float targetLineY = [yScale getPixAbs:[model rampTarget]];
	[[NSColor colorWithCalibratedRed:.8 green:.3 blue:.3 alpha:1] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(0,targetLineY+.2) toPoint:NSMakePoint([self bounds].size.width-bugPadWidth,targetLineY+.2)];
	if(![model isRunning]){
		[rightTargetBug drawAtPoint:NSMakePoint([self bounds].size.width - [rightTargetBug size].width,
												 targetLineY-[rightTargetBug size].height/2.) 
						   fromRect:[rightTargetBug imageRect] operation:NSCompositeSourceOver fraction:1.0];

	}
	
	if(mouseIsDown && !selectedWayPoint){
		NSAttributedString* s = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.1f",[model rampTarget]]];
		NSSize stringSize = [s size];
		targetLineY += 5;
		if(targetLineY + stringSize.height + 5  > rampArea.size.height){
			targetLineY = rampArea.size.height - stringSize.height - 5;
		}	
		[s drawAtPoint:NSMakePoint(10,targetLineY)];
		[s release];
	}
	
	int n = [model wayPointCount];
	int i;
	if(![model isRunning]){
		for(i=0;i<n;i++){
			float x = [xScale getPixAbs:[[model wayPoint:i] xyPosition].x];
			float y = [yScale getPixAbs:[[model wayPoint:i] xyPosition].y];
			NSRect wayPointframe = NSMakeRect(x-kWayPointSize/2,y-kWayPointSize/2, kWayPointSize,kWayPointSize);
			[[NSColor yellowColor] set];
			[NSBezierPath fillRect:wayPointframe];
			[[NSColor lightGrayColor] set];
			[NSBezierPath strokeRect:wayPointframe];	
		}
	}
	
	float x = [xScale getPixAbs:[[model currentWayPoint] xyPosition].x];
	float y = [yScale getPixAbs:[[model currentWayPoint] xyPosition].y];
	[[NSColor grayColor] set];
	if([model isRunning] && [model direction] < 0 && [model downRampPath]==0){
		[NSBezierPath strokeLineFromPoint:NSMakePoint(0,0) 
									toPoint:NSMakePoint(x,y)];
	}
	else {
		for(i=1;i<n;i++){
			float x1 = [xScale getPixAbs:[[model wayPoint:i-1] xyPosition].x];
			float y1 = [yScale getPixAbs:[[model wayPoint:i-1] xyPosition].y];
			float x2 = [xScale getPixAbs:[[model wayPoint:i] xyPosition].x];
			float y2 = [yScale getPixAbs:[[model wayPoint:i] xyPosition].y];
			[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,y1) 
									toPoint:NSMakePoint(x2,y2)];
		}
	}

	NSRect valueframe = NSMakeRect(x-kWayPointSize/2,y-kWayPointSize/2, kWayPointSize,kWayPointSize);
	NSBezierPath* path = [NSBezierPath bezierPathWithOvalInRect:valueframe]; 
	[[NSColor redColor] set];
	[path fill];
	[[NSColor grayColor] set];
	[path stroke];
	
}

- (void) mouseDown:(NSEvent*)event
{
	ORRampItem* model = [[delegate model] selectedRampItem];
	if([model isRunning])return;

	float bugPadWidth = [rightTargetBug size].width;
	float bugPadHeight = [rightTargetBug size].height+2;
    BOOL cmdKeyDown   = ([event modifierFlags] & NSCommandKeyMask)!=0;
    NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	NSEnumerator* e = [[model wayPoints] objectEnumerator];
	ORWayPoint* aWayPoint;
	NSMutableArray* wayPoints = [model wayPoints];
	mouseIsDown = YES;
	while(aWayPoint = [e nextObject]){
	
		float x = [xScale getPixAbs:[aWayPoint xyPosition].x];
		float y = [yScale getPixAbs:[aWayPoint xyPosition].y];
		NSRect wayPointframe = NSMakeRect(x-kWayPointSize/2,y-kWayPointSize/2, kWayPointSize,kWayPointSize);

		if(NSPointInRect(localPoint ,wayPointframe)){
			selectedWayPoint = aWayPoint;
			if(cmdKeyDown){
				ORWayPoint* p = [[ORWayPoint alloc] initWithPosition:[selectedWayPoint xyPosition]];
				[wayPoints insertObject:p atIndex:[wayPoints indexOfObject: selectedWayPoint]+1];
				selectedWayPoint = p;
				[p release];
			}
			
			int index = [wayPoints indexOfObject:selectedWayPoint];
			if(index == 0){
				ORWayPoint* more = [wayPoints objectAtIndex:index+1];
				xLowConstraint  = 0;
				yLowConstraint  = 0;
				xHighConstraint = 0;
				yHighConstraint = [yScale getPixAbs:[more xyPosition].y];
			}
			else if(index == [model wayPointCount]-1){
				ORWayPoint* less = [wayPoints objectAtIndex:index-1];
				xLowConstraint  = [self bounds].size.width-bugPadWidth;
				yLowConstraint  = [yScale getPixAbs:[less xyPosition].y];
				xHighConstraint = [self bounds].size.width-bugPadWidth;
				yHighConstraint = [self bounds].size.height-bugPadHeight/2;
			}
			else {
				ORWayPoint* less = [wayPoints objectAtIndex:index-1];
				ORWayPoint* more = [wayPoints objectAtIndex:index+1];
				xLowConstraint  = [xScale getPixAbs:[less xyPosition].x];
				yLowConstraint  = [yScale getPixAbs:[less xyPosition].y];
				xHighConstraint = [xScale getPixAbs:[more xyPosition].x];
				yHighConstraint = [yScale getPixAbs:[more xyPosition].y];
			}
			break;
		}
	}
	if(!selectedWayPoint){
		float convertedY = [yScale getValRel:localPoint.y]; 
		float grabWidth  = [yScale getValRel:kTargetSelectionHeight]; 
		if(convertedY < [model rampTarget]+grabWidth && convertedY > [model rampTarget]-grabWidth){
			[model setTargetSelected:YES];
		}
	}
	if(selectedWayPoint || [model targetSelected]){
		[[NSCursor closedHandCursor] set];
	}
	[self setNeedsDisplay:YES];
}

- (void) mouseDragged:(NSEvent*)event
{
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	ORRampItem* model = [[delegate model] selectedRampItem];

	if(selectedWayPoint){
		
		if(localPoint.y < yLowConstraint)		localPoint.y = yLowConstraint;
		else if(localPoint.y > yHighConstraint)	localPoint.y = yHighConstraint;
		if(localPoint.x < xLowConstraint)		localPoint.x = xLowConstraint;
		else if(localPoint.x > xHighConstraint)	localPoint.x = xHighConstraint;

		localPoint.y = [yScale getValAbs:localPoint.y];
		localPoint.x = [xScale getValAbs:localPoint.x];
		[selectedWayPoint setXyPosition:localPoint];
		[model placeCurrentValue];
	}
	else if([model targetSelected]){
		float bugPadHeight = [rightTargetBug size].height+2;
		if(localPoint.y<0)localPoint.y = 0;
		else if(localPoint.y>[self bounds].size.height-bugPadHeight/2)localPoint.y = [self bounds].size.height-bugPadHeight/2;
		[model setRampTarget:[yScale getValAbs:localPoint.y]];
	}
	[self setNeedsDisplay:YES];	
}

- (void) mouseUp:(NSEvent*)event
{
	mouseIsDown = NO;
	NSPoint localPoint = [self convertPoint:[event locationInWindow] fromView:nil];
	ORRampItem* model = [[delegate model] selectedRampItem];
	if(selectedWayPoint){

		if(localPoint.y < yLowConstraint)		localPoint.y = yLowConstraint;
		else if(localPoint.y > yHighConstraint)	localPoint.y = yHighConstraint;
		if(localPoint.x < xLowConstraint)		localPoint.x = xLowConstraint;
		else if(localPoint.x > xHighConstraint)	localPoint.x = xHighConstraint;

		localPoint.y = [yScale getValAbs:localPoint.y];
		localPoint.x = [xScale getValAbs:localPoint.x];
		[selectedWayPoint setXyPosition:localPoint];
		[model placeCurrentValue];

		NSPoint selectedPoint = NSMakePoint([selectedWayPoint xyPosition].x,[yScale getPixAbs:[selectedWayPoint xyPosition].y]);
		NSEnumerator* e = [[model wayPoints] objectEnumerator];
		ORWayPoint* aWayPoint;
		while(aWayPoint = [e nextObject]){
			if(aWayPoint != selectedWayPoint){
				float x = [aWayPoint xyPosition].x;
				float y = [yScale getPixAbs:[aWayPoint xyPosition].y];
				NSRect wayPointframe = NSMakeRect(x-kWayPointSize/2,y-kWayPointSize/2, kWayPointSize,kWayPointSize);
				if(NSPointInRect(selectedPoint ,wayPointframe)){
					[model removeWayPoint:aWayPoint];
					break;
				}
			}
		}
	}
	if(selectedWayPoint || [model targetSelected]){
		[[NSCursor openHandCursor] set];

	}
	
	selectedWayPoint = nil;
	[model setTargetSelected:NO];
	[self setNeedsDisplay:YES];
    [[self window] resetCursorRects];
}

- (void) resetCursorRects
{
	ORRampItem* model = [[delegate model] selectedRampItem];
	
	NSEnumerator* e = [[model wayPoints] objectEnumerator];
	ORWayPoint* aWayPoint;
	while(aWayPoint = [e nextObject]){
		float x = [xScale getPixAbs:[aWayPoint xyPosition].x];
		float y = [yScale getPixAbs:[aWayPoint xyPosition].y];
		NSRect wayPointframe = NSMakeRect(x-kWayPointSize/2,y-kWayPointSize/2, kWayPointSize,kWayPointSize);
        [self addCursorRect:wayPointframe cursor:[NSCursor openHandCursor]];
	}    
	float y = [yScale getPixAbs:[model rampTarget]];
	float dy = [rightTargetBug size].height;
	NSRect rampTargetRect = NSMakeRect(0,y-dy/2., [self bounds].size.width,dy);
	[self addCursorRect:rampTargetRect cursor:[NSCursor openHandCursor]];
}

- (void) setViewForPDF:(NSView*)aView
{
	viewForPDF = aView; //don't retain
}

- (void) setXScale:(id)anAxis
{
	xScale = anAxis; //don't retain
}

- (void) setYScale:(id)anAxis
{
	yScale = anAxis; //don't retain
}

- (id) xScale
{
	return xScale; 
}

- (id) yScale
{ 
	return yScale; 
}

@end


