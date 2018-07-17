//
//  ORMJDVacuumView.m
//  Orca
//
//  Created by Mark Howe on Tues Mar 27, 2012.
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

#import "ORMJDVacuumView.h"
#import "ORMJDVacuumController.h"
#import "ORMJDVacuumModel.h"
#import "ORVacuumParts.h"


@implementation ORMJDVacuumView
- (void) awakeFromNib
{
	[super awakeFromNib];
	NSArray* gateValves = [[delegate model] gateValves];
	float baseX = [self frame].origin.x;
	float baseY = [self frame].origin.y;
	for(ORVacuumGateValve* aValve in gateValves){		
		if(aValve.controlPreference != kControlNone){
			NSRect theControlRect;
			float x1 = baseX+aValve.location.x;
			float y1 = baseY+aValve.location.y;
			float w  = 75; //button width
			float h  = 26; //button height
			switch(aValve.controlPreference){
				case kControlAbove: theControlRect = NSMakeRect(x1-w/2.,y1+kPipeRadius+2*kPipeThickness+5,w,h);		break;
				case kControlBelow: theControlRect = NSMakeRect(x1-w/2.,y1-h-kPipeRadius-2*kPipeThickness-5,w,h);	break;
				case kControlRight: theControlRect = NSMakeRect(x1+kPipeRadius+2*kPipeThickness+5,y1-h/2.,w,h);	break;
				case kControlLeft:  theControlRect = NSMakeRect(x1-kPipeRadius-2*kPipeThickness-w,y1-h/2.,w,h);	break;
                default: theControlRect = NSZeroRect; break;
			}
		
			int gateValveTag = [aValve partTag];
			NSButton *button = [[NSButton alloc] initWithFrame:theControlRect]; 
			[button setBezelStyle:NSRoundedBezelStyle];
			[button setTag:gateValveTag]; 
			[button setTitle:@"Toggle..."]; 

			[self addSubview:button];
			
			//keep a list of gv buttons so can update them easier
			if(!gvButtons)gvButtons=[[NSMutableArray array] retain];
			[gvButtons addObject:button];
			
			[button setTarget: delegate];
			[button setAction: @selector(openGVControlPanel:)];
			[button release];
		}
	}
}

- (void) dealloc
{
	[hvPlusSign release];
	[biasPath release];
	[gvButtons release];
	[super dealloc];
}

- (BOOL) acceptsFirstResponder
{
    return YES;
}

- (void) keyDown:(NSEvent*)theEvent
{
	unsigned short keyCode = [theEvent keyCode];
    BOOL cmdKeyDown   = ([theEvent modifierFlags] & NSEventModifierFlagCommand)!=0;
	if(cmdKeyDown && keyCode == 5){ //'g'
		[delegate toggleGrid];
		[self setNeedsDisplay:YES];
	}
}

- (void) drawRect:(NSRect)dirtyRect 
{
	if([delegate showGrid]) [self drawGrid];
	NSArray* parts = [[delegate model] parts];
	for(ORVacuumPart* aPart in parts)[aPart draw];
	
	NSImage* stringsImage = [NSImage imageNamed:@"MJDStrings"];
	NSPoint aPoint = NSMakePoint(615,445);
	[stringsImage drawAtPoint:aPoint fromRect:[stringsImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];	
	if([[delegate model] detectorsBiased]){
		if(!biasPath){ 
			biasPath = [[NSBezierPath bezierPath] retain];
			//top
			[biasPath moveToPoint:NSMakePoint(620,510)];
			[biasPath lineToPoint:NSMakePoint(610,510)];
			[biasPath lineToPoint:NSMakePoint(610,490)];
			
			//bottom
			[biasPath moveToPoint:NSMakePoint(620,445)];
			[biasPath lineToPoint:NSMakePoint(610,445)];
			[biasPath lineToPoint:NSMakePoint(610,465)];
			
			hvPlusSign = [[NSAttributedString alloc] initWithString:@"+"
																	 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
																				 [NSColor redColor],NSForegroundColorAttributeName,
																				 [NSFont fontWithName:@"Geneva" size:14],NSFontAttributeName,
																				 nil]]; 			
		}
		[[NSColor redColor] set];
		[biasPath stroke];
		[hvPlusSign drawAtPoint:NSMakePoint( 605, 470)];
	}
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

- (void) updateButtons
{
    BOOL locked = [gSecurity isLocked:ORMJCVacuumLock];
	for(id aButton in gvButtons){
		[aButton setEnabled:!locked];
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
