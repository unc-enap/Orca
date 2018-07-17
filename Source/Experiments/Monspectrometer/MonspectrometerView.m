//
//  MonspectrometerModel.m
//  Orca
//
//  Created by Mark Howe on Wed Dec 8 2010
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "MonspectrometerView.h"
#import "MonspectrometerModel.h"
#import "ORColorScale.h"

@implementation MonspectrometerView

- (void) awakeFromNib
{	
	[theBackground release];
	theBackground = [[NSImage imageNamed:@"monSpecHolder"] retain];
	[prespecColorScale setExcludeZero:YES];
}

- (void) dealloc
{
	[theBackground release];
	[super dealloc];
}

- (void) makeAllSegments
{
	[super makeAllSegments]; //set up -- have to call
	
	float w = [self bounds].size.width;
	float h = [self bounds].size.height;
	float xc = w/2.;
	float yc = h/2.;
	NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:5];
	NSMutableArray* errorPaths = [NSMutableArray arrayWithCapacity:5];
	
#define segSize 100
#define offset 24
	//hardcode the positions relative to the view with some hand tweaking to get it right
	struct  {
		float x,y;
	} position[5] = {
		{w - offset - segSize , yc - segSize/2. + 1 },		//right
		{xc - segSize/2. + 1  , offset + 2 },				//bottom
		{offset + 3			  , yc - segSize/2. + 1 },		//left
		{xc - segSize/2. + 1  , yc - segSize/2. + 1 },		//center
		{xc - segSize/2. + 1  , h - segSize - offset -1 }	//top
	};
	
	NSRect segRect = NSMakeRect(0,0,segSize,segSize);
	int i;
	for(i=0;i<5;i++){
		NSBezierPath* aPath = [NSBezierPath bezierPath];
		NSRect theRect = NSOffsetRect(segRect,position[i].x,position[i].y);
		[aPath appendBezierPathWithRect:theRect];
		[segmentPaths addObject:aPath];

		[labelPathSet addObject:[NSDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithFloat:theRect.origin.x+5],@"X",
											[NSNumber numberWithFloat:theRect.origin.y+3],@"Y",nil]];
		

		theRect = NSInsetRect(theRect,40,40);
		[errorPaths addObject:[NSBezierPath bezierPathWithOvalInRect:theRect]];
	}
	[segmentPathSet addObject:segmentPaths];
	[errorPathSet addObject:errorPaths];
}

- (void)drawRect:(NSRect)rect
{
	[theBackground drawAtPoint:NSZeroPoint fromRect:[theBackground imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];

	[super drawRect:rect];
}

- (NSColor*) getColorForSet:(int)setIndex value:(float)aValue
{
	return [prespecColorScale getColorForValue:aValue];
}

- (void) upArrow
{
	selectedPath++;
	if(selectedSet == 0) selectedPath %= 5;
}

- (void) downArrow
{
	selectedPath--;
	if(selectedSet == 0){
		if(selectedPath < 0) selectedPath = 5-1;
	}
	
}@end
