//
//  ORColorScale.m
//  Orca
//
//  Created by Mark Howe on Mon Sep 08 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORColorScale.h"
#import "ORAxis.h"


@interface ORColorScale (private)
	- (void) _makeColors;
@end

@implementation ORColorScale

- (id)initWithFrame:(NSRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
		[self setNumColors:kNumColors];
		[self setSpectrumRange:0.7];
		[self setStartColor:[NSColor blueColor]];
		[self setEndColor:[NSColor redColor]];
        [self setUseRainBow:YES];
        
		makeColors  = YES;
        excludeZero = NO;

    }
    return self;
}

- (void) dealloc
{
	[colors release];
    [startColor release];
    [endColor release];
	[super dealloc];
}

#pragma mark ¥¥¥Accessors
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
-  (void) setNumColors:(short)newNumColors
{
	numColors=newNumColors;
}

- (ORAxis*) colorAxis
{	
	return colorAxis;
}

- (void) setColorAxis:(ORAxis*)anAxis
{
	colorAxis = anAxis; //don't retain
}

- (BOOL) excludeZero
{
    return excludeZero;
}

- (void) setExcludeZero:(BOOL)aFlag
{
    excludeZero = aFlag;
    [self setNeedsDisplay:YES];
}

- (BOOL) useRainBow
{

    return useRainBow;
}

- (void) setUseRainBow: (BOOL) flag
{
    useRainBow = flag;
    scaleIsXAxis = [colorAxis isXAxis];
	makeColors = YES;
	[self setNeedsDisplay:YES];
}


- (NSColor *) startColor
{
    return startColor; 
}

- (void) setStartColor: (NSColor *) aStartColor
{
    [aStartColor retain];
    [startColor release];
    startColor = aStartColor;
	makeColors = YES;
	[self setNeedsDisplay:YES];
}


- (NSColor *) endColor
{
    return endColor; 
}

- (void) setEndColor: (NSColor *) anEndColor
{
    [anEndColor retain];
    [endColor release];
    endColor = anEndColor;
	makeColors = YES;
	[self setNeedsDisplay:YES];
}

- (NSColor*) getColorForValue:(float)aValue
{	
	float h=[self bounds].size.height;
	float w=[self bounds].size.width;
	float i;
	aValue = [colorAxis getPixAbs:aValue];

	if(w>h)i = aValue * numColors/w;
	else   i = aValue * numColors/h;
	
	if(i>=0 && i<numColors-1){
        if(i==0 && excludeZero) return nil;
        else                    return [colors objectAtIndex:(int)i];
    }
	else if(i<0)return nil;
	else return [colors lastObject];
}


- (NSColor*) getColorForIndex:(unsigned short)index
{
    return [colors objectAtIndex:index];
}

- (unsigned short) getFastColorIndexForValue:(uint32_t)aValue log:(BOOL)aLog integer:(BOOL)aInt minPad:(double)aMinPad
{	 

	aValue = [colorAxis getPixAbsFast:aValue log:aLog integer:aInt minPad:aMinPad];
	if(aValue <= 0)return 0;
    
	unsigned short i;
    NSRect theBounds = [self bounds];
	if(!scaleIsXAxis)i = aValue * numColors/theBounds.size.height;
	else   i = aValue * numColors/theBounds.size.width;
	
	if(i<numColors)return i;
    else return numColors-1;
}


- (unsigned short) getColorIndexForValue:(uint32_t)aValue 
{	
	aValue = [colorAxis getPixAbs:aValue];
	if(aValue <= 0)return 0;
    
	unsigned short i;
    NSRect theBounds = [self bounds];
	if(!scaleIsXAxis)i = aValue * numColors/theBounds.size.height;
	else   i = aValue * numColors/theBounds.size.width;
	
	if(i<numColors)return i;
    else return numColors-1;
}


- (void) drawRect:(NSRect)rect 
{
	if(makeColors){
		[self _makeColors];
		makeColors = NO;
	}

    [super drawRect:rect];
	float x=[self bounds].origin.x;
	float y=[self bounds].origin.y;
	float h=[self bounds].size.height;
	float w=[self bounds].size.width;
	float delta;
	if(w>h){
		delta = w/(float)numColors;
	}
	else {
		delta = h/(float)numColors;
	}
	short i;
	for (i=0; i<numColors; i++){
		[(NSColor*)[colors objectAtIndex:i] set];
		if(w>h){
			[NSBezierPath fillRect:NSMakeRect(x,y,delta+1,h)];
			x+=delta;
		}
		else {
			[NSBezierPath fillRect:NSMakeRect(x,y,w,delta+1)];
			y+=delta;
		}
	}
	[[NSColor blackColor]set];
	[NSBezierPath strokeRect:[self bounds]];

}


#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    if([decoder allowsKeyedCoding]){
        [self setNumColors:[decoder decodeIntegerForKey:@"ORColorScaleNumColors"]];
        [self setSpectrumRange:[decoder decodeFloatForKey:@"ORColorScaleSpectrumRange"]];
        [self setStartColor:[decoder decodeObjectForKey:@"ORColorScaleStartColor"]]; 
        [self setEndColor:[decoder decodeObjectForKey:@"ORColorScaleEndColor"]]; 
        [self setUseRainBow:[decoder decodeIntegerForKey:@"ORColorScaleUseRainBow"]];
		

    }
    else {
		BOOL userRainBowFlag;
        [decoder decodeValueOfObjCType:@encode(short) at: &numColors];
        [decoder decodeValueOfObjCType:@encode(float) at: &spectrumRange];
        [decoder decodeValueOfObjCType:@encode(BOOL) at: &userRainBowFlag];
		[self setUseRainBow:userRainBowFlag];
        [self setStartColor:[decoder decodeObject]]; 
        [self setEndColor:[decoder decodeObject]]; 
    }
  
	[self _makeColors];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    if([encoder allowsKeyedCoding]){
        [encoder encodeInteger:numColors forKey:@"ORColorScaleNumColors"];
        [encoder encodeFloat:spectrumRange forKey:@"ORColorScaleSpectrumRange"];
        [encoder encodeInteger:useRainBow forKey:@"ORColorScaleUseRainBow"];
        [encoder encodeObject:startColor forKey:@"ORColorScaleStartColor"];
        [encoder encodeObject:endColor forKey:@"ORColorScaleEndColor"];
    }
    else {
        [encoder encodeValueOfObjCType:@encode(short) at: &numColors];
        [encoder encodeValueOfObjCType:@encode(float) at: &spectrumRange];
        [encoder encodeValueOfObjCType:@encode(BOOL) at: &useRainBow];
        [encoder encodeObject:startColor];
        [encoder encodeObject:endColor];
    }
}



#pragma mark ¥¥¥private
- (void) _makeColors
{
	[self setColors:[NSMutableArray arrayWithCapacity:numColors]];	
    if(useRainBow){
        short i;
        for (i=0; i<numColors; i++){
            float hue = (float)(numColors - i)*(1.0*spectrumRange)/numColors; 
            NSColor* aColorHue = [NSColor colorWithDeviceHue:hue saturation:1.0 brightness:1.0 alpha:1.0];
            [colors addObject:aColorHue];
        }
    }
    else {
		NSColor* s = [startColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];
		NSColor* e = [endColor colorUsingColorSpaceName:NSDeviceRGBColorSpace];

        short i;
        CGFloat startRed      = [s redComponent];
        CGFloat startGreen    = [s greenComponent];
        CGFloat startBlue     = [s blueComponent];
        CGFloat startAlpha    = [s alphaComponent];
        CGFloat endRed        = [e redComponent];
        CGFloat endGreen      = [e greenComponent];
        CGFloat endBlue       = [e blueComponent];
        CGFloat endAlpha      = [e alphaComponent];
        CGFloat red,green,blue,alpha;
        if(numColors==0)numColors = 256;
        for (i=0; i<numColors; i++){
            float factor = i/(float)numColors;
            red     = (1.0-factor)*startRed    + factor*endRed;
            green   = (1.0-factor)*startGreen  + factor*endGreen;
            blue    = (1.0-factor)*startBlue   + factor*endBlue;
            alpha   = (1.0-factor)*startAlpha  + factor*endAlpha;
            [colors addObject:[NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha]];
        }
    }
}


@end
