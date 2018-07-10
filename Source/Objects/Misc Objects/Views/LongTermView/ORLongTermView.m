//
//  ORLongTermView.m
//  Orca
//
//  Created by Mark Howe on 5/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ORLongTermView.h"


@implementation ORLongTermView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}


- (void)drawRect:(NSRect)rect 
{
	
	int m;
	float h = [self bounds].size.height;
	float w = [self bounds].size.width;
	int numLines  = [dataSource numLinesInLongTermView:self];
	int numPoints = [dataSource numPointsPerLineInLongTermView:self];
	int maxLines = [dataSource maxLinesInLongTermView:self];
	int startingLine = [dataSource startingLineInLongTermView:self];
	
	float dh =  h/(float)maxLines;
	float yOffset = dh/2;
	float xscale = w/(float)numPoints;

	[[NSColor colorWithCalibratedRed:.8 green:.8 blue:.8 alpha:1] set];
	[NSBezierPath fillRect:NSMakeRect(0,0,w,h)];
	[[NSColor blackColor] set];
	[NSBezierPath setDefaultLineWidth:.5];
	[NSBezierPath strokeRect:NSMakeRect(1,1,w-1,h-1)];

	NSBezierPath* thePath = [NSBezierPath bezierPath];
	for(m=0;m<numLines;m++){
		[thePath setLineWidth:.5];
		int i;
		[thePath moveToPoint:NSMakePoint( 0, yOffset)];
		for(i=1;i<numPoints;i++){
			float y = [dataSource longTermView:self line:startingLine point:i];
			[thePath lineToPoint:NSMakePoint( i * xscale, yOffset+y)];
		}
		yOffset += dh;
		startingLine--;
		if(startingLine<0)startingLine = maxLines-1;
	}
	[[NSColor redColor] set];
	[thePath stroke];
	
}

@end
