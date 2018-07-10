//
//  ORColorBar.m
//  Orca
//
//  Created by Mark Howe on Mon Sep 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "ORColorBar.h"
#import "ORScale.h"

@interface ORColorBar (private)
	- (void) _makeColors;
@end

@implementation ORColorBar

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		[self setNumColors:256];
		[self setSpectrumRange:0.7];
		
		[self _makeColors];
    }
    return self;
}

- (void) dealloc
{
	[colors release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[self _makeColors];
}

#pragma mark •••Accessors
- (NSMutableArray*) colors
{
	return colors;
}
- (void) setColors:(NSMutableArray*)newColors
{
	[colors autorelease];
	colors=[newColors retain];
}

- (float) spectrumRange
{
	return spectrumRange;
}
- (void) setSpectrumRange:(float)newSpectrumRange
{
	spectrumRange=newSpectrumRange;
}

- (short) numColors
{
	return numColors;
}
- (void) setNumColors:(short)newNumColors
{
	numColors=newNumColors;
}

- (ORScale*) scale
{	
	return scale;
}

- (NSColor*) getColorForValue:(float)aValue
{	
	float h=[self bounds].size.height;
	float w=[self bounds].size.width;
	
	short i;
	aValue = [scale getPixAbs:aValue];

	if(aValue == 0)return nil;

	if(w>h)i = aValue * [colors count]/w;
	else   i = aValue * [colors count]/h;
	
	if(i<0)return [colors objectAtIndex:0];
	else if(i>=[colors count])return [colors lastObject];
	else {
		return [colors objectAtIndex:i];
	}	
}


- (void)drawRect:(NSRect)rect {
	float x=[self bounds].origin.x;
	float y=[self bounds].origin.y;
	float h=[self bounds].size.height;
	float w=[self bounds].size.width;
	short num = [colors count];
	float delta;
	if(w>h){
		delta = w/(float)num;
	}
	else {
		delta = h/(float)num;
	}
	short i;
	for (i=0; i<num; i++){
		[[colors objectAtIndex:i] set];
		if(w>h){
			[NSBezierPath fillRect:NSMakeRect(x,y,delta,h)];
			x+=delta;
		}
		else {
			[NSBezierPath fillRect:NSMakeRect(x,y,w,delta)];
			y+=delta;
		}
	}
	[[NSColor blackColor]set];
	[NSBezierPath strokeRect:[self bounds]];
}


#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [decoder decodeValueOfObjCType:@encode(short) at: &numColors];
    [decoder decodeValueOfObjCType:@encode(float) at: &spectrumRange];

    [self setColors:[decoder decodeObject]]; 

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeValueOfObjCType:@encode(short) at: &numColors];
    [encoder encodeValueOfObjCType:@encode(float) at: &spectrumRange];
	[encoder encodeObject:colors];
}



#pragma mark •••private
- (void) _makeColors
{
	[self setColors:[NSMutableArray arrayWithCapacity:numColors]];	
	short i;
	for (i=0; i<numColors; i++){
		float hue = (float)(numColors - i)*(1.0*spectrumRange)/numColors; 
		NSColor* aColorHue = [NSColor colorWithDeviceHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
		[colors addObject:aColorHue];
	}
}

@end
