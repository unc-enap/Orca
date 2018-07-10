//
//  BamDetectorView.m
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

#import "BamDetectorView.h"
#import "BamDetectorModel.h"
#import "ORColorScale.h"

@implementation BamDetectorView

- (void) makeAllSegments
{
	[super makeAllSegments]; //set up -- have to call
	
	float w = [self bounds].size.width;
	float h = [self bounds].size.height;
	float xc = w/2.;
	float yc = h/2.;
	NSMutableArray* segmentPaths = [NSMutableArray arrayWithCapacity:5];
	NSMutableArray* errorPaths = [NSMutableArray arrayWithCapacity:5];
	int i;
	float r = 139;
	float angle = 0;
	//float deltaAngle = 360/12.;
	float deltaAngle = 360/12.;
	float angleTweak[12] = {0,1,1,1,.5,1,1,0,0,0,0,0};
	float radiusTweak[12] = {0,0,-2,-2,-1,0,0,0,0,0,0,-2};
	for(i=0;i<12;i++){
		NSAffineTransform *transform = [NSAffineTransform transform];
		[transform translateXBy: xc yBy: h-xc];
		[transform rotateByDegrees:angle+angleTweak[i]];
		NSRect segRect = NSMakeRect(r+radiusTweak[i],-14,29,26);
		NSBezierPath* segPath = [NSBezierPath bezierPathWithRect:segRect];
		[segPath transformUsingAffineTransform: transform];
		[segmentPaths addObject:segPath];
		NSBezierPath* errorPath = [NSBezierPath bezierPathWithRect:NSInsetRect(segRect, 4, 2)];
		[errorPath transformUsingAffineTransform: transform];
		[errorPaths addObject:errorPath];
		angle += deltaAngle;
	}
	//the center one on the right
	NSRect segRect = NSMakeRect(xc+2,yc-13,26,26);
	NSBezierPath* segPath = [NSBezierPath bezierPathWithRect:segRect];
	[segmentPaths addObject:segPath];
	NSBezierPath* errorPath = [NSBezierPath bezierPathWithRect:NSInsetRect(segRect, 4, 2)];
	[errorPaths addObject:errorPath];

	//the center one on the left
	segRect = NSMakeRect(xc-37,yc-13,26,26);
	segPath = [NSBezierPath bezierPathWithRect:segRect];
	[segmentPaths addObject:segPath];
	errorPath = [NSBezierPath bezierPathWithRect:NSInsetRect(segRect, 4, 2)];
	[errorPaths addObject:errorPath];


	[segmentPathSet addObject:segmentPaths];
	[errorPathSet addObject:errorPaths];
}

- (void)drawRect:(NSRect)rect
{
	[super drawRect:rect];
	NSBezierPath* path = [NSBezierPath bezierPathWithOvalInRect:[self bounds]];
	[[NSColor blackColor] set];
	[path stroke];
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
