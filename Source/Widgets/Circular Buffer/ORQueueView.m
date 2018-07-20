//
//  ORQueueView.m
//  Orca
//
//  Created by Mark Howe on Mon Mar 31 2003.
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


#import "ORQueueView.h"
@interface ORQueueView (Private)
- (void)drawUnsigned;
- (void)drawSigned;
@end


@implementation ORQueueView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setBackgroundColor:[NSColor whiteColor]];
        [self setBarColor:[NSColor darkGrayColor]];
        useSignedValues = NO; //default
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
- (BOOL)useSignedValues
{
    return useSignedValues;
}
- (void)setUseSignedValues:(BOOL)flag
{
    useSignedValues = flag;
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


#pragma mark ¥¥¥Drawing
- (void)drawRect:(NSRect)rect 
{
	[NSBezierPath setDefaultLineWidth:1];
	NSRect b = [self bounds];
	[backgroundColor set];
	[NSBezierPath fillRect:b];
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:b];
	if(!dataSource){
		[barColor set];
		[NSBezierPath fillRect:NSMakeRect(b.origin.x+30,1,b.origin.x+30+30,b.size.height-2)];
		
	}

    if(useSignedValues)[self drawSigned];
    else [self drawUnsigned];
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

@implementation ORQueueView (Private)
- (void)drawUnsigned
{

	float oldLineWidth = [NSBezierPath defaultLineWidth];
	NSRect b = [self bounds];
	uint32_t aMinValue;	
	uint32_t aMaxValue;
	uint32_t aHeadValue;
	uint32_t aTailValue;
	
	[dataSource getQueMinValue:&aMinValue maxValue:&aMaxValue head:&aHeadValue tail:&aTailValue];
	
	float queue_size = aMaxValue - aMinValue;
	aHeadValue -= aMinValue;
	aTailValue -= aMinValue;
	if(queue_size > 0) {	
		[barColor set];
		float theWidth = b.size.width;
		float theHeight = b.size.height;
		
		float head_x = theWidth*aHeadValue/queue_size;
		if(head_x > theWidth) head_x = theWidth;
		else if(head_x < 0)   head_x = 0;
		
		float tail_x = theWidth*aTailValue/queue_size;
		if(tail_x > theWidth) tail_x = theWidth;
		else if(tail_x < 0)   tail_x = 0;
		
		if(aTailValue < aHeadValue ){
			[NSBezierPath fillRect:NSMakeRect(tail_x,1,head_x-tail_x,theHeight-2)];
		}
		else if(aTailValue > aHeadValue ){
			[NSBezierPath fillRect:NSMakeRect(0,1,head_x,theHeight-2)];
			[NSBezierPath fillRect:NSMakeRect(tail_x,1,theWidth-tail_x,theHeight-2)];
		}
		
		[[NSColor blackColor]set];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(head_x,0) toPoint:NSMakePoint(head_x,theHeight)];
		if(head_x!=tail_x){
			[NSBezierPath strokeLineFromPoint:NSMakePoint(tail_x,0) toPoint:NSMakePoint(tail_x,theHeight)];
		}
		
	}
	[NSBezierPath setDefaultLineWidth:oldLineWidth];
}

- (void)drawSigned
{
	float oldLineWidth = [NSBezierPath defaultLineWidth];
	NSRect b = [self bounds];
    uint32_t aMinValue;	
	uint32_t aMaxValue;
	uint32_t aHeadValue;
	uint32_t aTailValue;
	
	[dataSource getQueMinValue:&aMinValue maxValue:&aMaxValue head:&aHeadValue tail:&aTailValue];
	
	float queue_size = aMaxValue - aMinValue;
	aHeadValue -= aMinValue;
	aTailValue -= aMinValue;
	if(queue_size > 0) {	
		[barColor set];
		float theWidth = b.size.width;
		float theHeight = b.size.height;
		
		float head_x = theWidth*aHeadValue/queue_size;
		if(head_x > theWidth) head_x = theWidth;
		else if(head_x < 0)   head_x = 0;
		
		float tail_x = theWidth*aTailValue/queue_size;
		if(tail_x > theWidth) tail_x = theWidth;
		else if(tail_x < 0)   tail_x = 0;
		
		if(aTailValue < aHeadValue ){
			[NSBezierPath fillRect:NSMakeRect(tail_x,1,head_x-tail_x,theHeight-2)];
		}
		else if(aTailValue > aHeadValue ){
			[NSBezierPath fillRect:NSMakeRect(0,1,head_x,theHeight-2)];
			[NSBezierPath fillRect:NSMakeRect(tail_x,1,theWidth-tail_x,theHeight-2)];
		}
		
		[[NSColor blackColor]set];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(head_x,0) toPoint:NSMakePoint(head_x,theHeight)];
		if(head_x!=tail_x){
			[NSBezierPath strokeLineFromPoint:NSMakePoint(tail_x,0) toPoint:NSMakePoint(tail_x,theHeight)];
		}
		
	}
	[NSBezierPath setDefaultLineWidth:oldLineWidth];

}


@end
