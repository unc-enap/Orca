//
//  ORBarGraph.m
//  Orca
//
//  Created by Mark Howe on Mon Mar 31 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
//

#import "ORBarGraph.h"
#import "ORScale.h"


@implementation ORBarGraph

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[NSColor whiteColor]];
        [self setBarColor:[NSColor greenColor]];
    }
    return self;
}

- (void) dealloc
{
	[backgroundColor release];
	[barColor release];
	[super dealloc];
}

#pragma mark ¥¥¥Accessors
- (ORScale*) xScale
{
	return mXScale;
}


- (void) setBackgroundColor:(NSColor*)aColor
{
	[aColor retain];
	[backgroundColor release];
	backgroundColor = aColor;
    [self setNeedsDisplay: YES];
}

- (NSColor*) backgroundColor
{
	return backgroundColor;
}

- (void) setBarColor:(NSColor*)aColor
{
	[aColor retain];
	[barColor release];
	barColor = aColor;
    [self setNeedsDisplay: YES];	
}

- (NSColor*) barColor
{
	return barColor;
}

- (int) tag
{
	return tag;
}

- (void) setTag:(int)newTag
{
	tag=newTag;
}

- (void) setNeedsDisplay:(BOOL)flag
{
    //MAH commented out 10/22/03 Note: seems like this line needs to be used, but groups of bargraphs
    //break then.
	//[super setNeedsDisplay:flag];
	[chainedView setNeedsDisplay:flag];
}

#pragma mark ¥¥¥Drawing
- (BOOL)isOpaque
{
	return YES;
}

- (void)drawRect:(NSRect)rect 
{
	NSRect b = [self bounds];
	[backgroundColor set];
	[NSBezierPath fillRect:b];
	[[NSColor blackColor] set];
	[NSBezierPath setDefaultLineWidth:1];
	[NSBezierPath strokeRect:b];
	[barColor set];
	if(dataSource){
		float x = [mXScale getPixAbs:[dataSource doubleValue]];
		[NSBezierPath fillRect:NSMakeRect(1,1,x,b.size.height-2)];
	}
	else {
		[NSBezierPath fillRect:NSMakeRect(1,1,b.size.width/3-2,b.size.height-2)];
	}
}


#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [self setBackgroundColor:[decoder decodeObject]];
    [self setBarColor:[decoder decodeObject]];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:backgroundColor];
    [encoder encodeObject:barColor];
}

@end
