//
//  ORMJDPumpCartView.m
//  Orca
//
//  Created by Mark Howe on Mon Aug13, 2012.
//  Copyright © 2012 CENPA, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORMJDPumpCartView.h"
#import "ORMJDPumpCartController.h"
#import "ORMJDPumpCartModel.h"
#import "ORVacuumParts.h"

@implementation ORMJDPumpCartView
- (void) setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}

- (BOOL) acceptsFirstResponder
{
    return YES;
}

- (void) keyDown:(NSEvent*)theEvent
{
	unsigned short keyCode = [theEvent keyCode];
    BOOL cmdKeyDown   = ([theEvent modifierFlags] & NSCommandKeyMask)!=0;
	if(cmdKeyDown && keyCode == 5){ //'g'
		[delegate toggleGrid];
		[self setNeedsDisplay:YES];
	}
}

- (void) drawRect:(NSRect)dirtyRect 
{
	[super drawRect:dirtyRect];
	if([delegate showGrid]) {
		[[NSColor whiteColor] set];
		[NSBezierPath fillRect:[self bounds]];
		[self drawGrid];
	}
	NSArray* parts = [[delegate model] parts];
	for(ORVacuumPart* aPart in parts)[aPart draw];
}

- (void) resetCursorRects
{
	[super resetCursorRects];
	
	NSArray* valueLabels = [[delegate model] valueLabels];
	for(ORVacuumDynamicLabel* aLabel in valueLabels){	
		if(![[aLabel label] isEqualToString:@"Assumed"]){
			[self addCursorRect:aLabel.bounds cursor:[NSCursor pointingHandCursor]];
		}
	}	
	
	NSArray* statusLabels = [[delegate model] statusLabels];
	for(ORVacuumStatusLabel* aLabel in statusLabels){	
		if(![[aLabel label] isEqualToString:@"Assumed"]){
			[self addCursorRect:aLabel.bounds cursor:[NSCursor pointingHandCursor]];
		}
	}	
}

- (void) drawGrid
{
	float width  = [self bounds].size.width;
	float height = [self bounds].size.height;
	[NSBezierPath setDefaultLineWidth:0];
	
	int count = 0;
	int i;
	for(i=0;i<width;i+=10){
		if(count%10 == 0)[[NSColor blackColor] set];
		else [[NSColor lightGrayColor] set];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(i, 0) toPoint:NSMakePoint(i,height)];
		count++;
	}
	
	count = 0;
	for(i=0;i<height;i+=10){
		if(count%10 == 0)[[NSColor blackColor] set];
		else [[NSColor lightGrayColor] set];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(0,i) toPoint:NSMakePoint(width,i)];
		count++;
	}
}

- (void) mouseDown:(NSEvent*) anEvent
{
	if ([anEvent clickCount] > 1) {
		NSPoint localPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
		NSArray* valueLabels = [[delegate model] valueLabels];
		for(ORVacuumValueLabel* aLabel in valueLabels){	
			if(NSPointInRect(localPoint, [aLabel bounds])){
				int component = [aLabel component];
				if(component >=0 && component<=4){
					[[delegate model] openDialogForComponent:component];
				}
				return;
			}
		} 
		NSArray* statusLabels = [[delegate model] statusLabels];
		for(ORVacuumStatusLabel* aLabel in statusLabels){	
			if(NSPointInRect(localPoint, [aLabel bounds])){
				int component = [aLabel component];
				if(component >=0 && component<=4){
					[[delegate model] openDialogForComponent:component];
				}
				return;
			}
		} 
	}
}

@end
