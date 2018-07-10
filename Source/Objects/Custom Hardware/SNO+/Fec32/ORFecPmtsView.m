//
//  ORFecPmtsView.m
//  Orca
//
//  Created by Mark Howe on 10/16/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
//
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

#import "ORFecPmtsView.h"
#import "ORFec32Model.h"
#import "ORFec32Controller.h"

@implementation ORFecPmtsView

- (void)awakeFromNib
{
	//have to make sure that the card view is on top
	[anchorView retain];
	[anchorView removeFromSuperview];
	[self addSubview:anchorView];
	[anchorView release];
}

- (BOOL) acceptsFirstMouse
{
	return NO;
}

- (void) drawRect:(NSRect)rect 
{
	ORFec32Model* model		 = [controller model];
	
	NSRect anchorFrame = [anchorView frame];
	float dc_height  = 39;
	float x1,x2,y1,y2,deltaX1,deltaX2,deltaY1,deltaY2;
	
	float oldLineWidth = [NSBezierPath defaultLineWidth];
	[NSBezierPath setDefaultLineWidth:.5];
	
	int i;
	//0 - 7 (bottom)
	if(![model dcPresent:0])[[NSColor lightGrayColor] set];		
	else [[NSColor blackColor] set];		
	x1 = anchorFrame.origin.x + anchorFrame.size.width-5;
	y1 = anchorFrame.origin.y;
	x2 = [self bounds].size.width;
	y2 = 0;
	deltaX1 = (anchorFrame.size.width)/8.;
	deltaX2 = 20 + 18;
	for(i=0;i<8;i++){	
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,y1) toPoint:NSMakePoint(x2,y2)];
		x1 -= deltaX1;
		x2 -= deltaX2;
	}
	
	//8 - 15 (bottom left)
	if(![model dcPresent:1])[[NSColor lightGrayColor] set];		
	else [[NSColor blackColor] set];		
	x1 = anchorFrame.origin.x;
	y1 = anchorFrame.origin.y + dc_height;
	x2 = anchorFrame.origin.x - 55;
	y2 = 0;
	deltaY1 = (dc_height)/8.;
	deltaY2 = 20 + 3;
	for(i=0;i<8;i++){	
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,y1) toPoint:NSMakePoint(x2,y2)];
		y1 += deltaY1;
		y2 += deltaY2;
	}
	
	//16 - 23 (top left)
	if(![model dcPresent:2])[[NSColor lightGrayColor] set];		
	else [[NSColor blackColor] set];		
	x1 = anchorFrame.origin.x;
	y1 = anchorFrame.origin.y + anchorFrame.size.height - dc_height;
	x2 = anchorFrame.origin.x - 55;
	y2 = [self bounds].size.height;
	for(i=0;i<8;i++){	
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,y1) toPoint:NSMakePoint(x2,y2)];
		y1 -= deltaY1;
		y2 -= deltaY2;
	}
	
	//24 - 31 (top)
	if(![model dcPresent:3])[[NSColor lightGrayColor] set];		
	else [[NSColor blackColor] set];		
	x1 = anchorFrame.origin.x + anchorFrame.size.width-5;
	y1 = anchorFrame.origin.y + anchorFrame.size.height+2;
	x2 = [self bounds].size.width;
	y2 = [self bounds].size.height;
	for(i=0;i<8;i++){	
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,y1) toPoint:NSMakePoint(x2,y2) ];
		x1 -= deltaX1;
		x2 -= deltaX2;
	}
	[NSBezierPath setDefaultLineWidth:oldLineWidth];
	
}


@end
