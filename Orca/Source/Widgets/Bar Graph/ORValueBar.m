//
//  ORValueBar.m
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


#import "ORValueBar.h"
#import "ORAxis.h"

#ifndef NSAppKitVersionNumber10_5
#define NSAppKitVersionNumber10_5 949
#endif

#ifndef NSAppKitVersionNumber10_4
#define NSAppKitVersionNumber10_4 824
#endif

@implementation ORValueBar

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
	[gradient release];
	[backgroundColor release];
	[barColor release];
	[super dealloc];
}

- (void) awakeFromNib
{
	if(!backgroundColor)[self setBackgroundColor:[NSColor whiteColor]];
	if(!barColor)[self setBarColor:[NSColor greenColor]];
}

#pragma mark ¥¥¥Accessors
- (ORAxis*) xScale
{
	return mXScale;
}

- (void) setXScale:(id)aScale
{
	mXScale = aScale;
}

- (void) setDataSource:(id)aSource
{
	dataSource = aSource;
}

- (ORValueBar*) chainedView
{
	return chainedView;
}

- (void) setChainedView:(id)aView
{
	chainedView = aView;
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
	
	CGFloat red,green,blue,alpha;
	[barColor getRed:&red green:&green blue:&blue alpha:&alpha];
	
	red *= .5;
	green *= .5;
	blue *= .5;
	//alpha = .75;
	
	NSColor* endingColor = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
	
	[gradient release];
	gradient = [[NSGradient alloc] initWithStartingColor:barColor endingColor:endingColor];

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
	//Argg.... before 10.5 the calling the superclass would break the update chain for some reason
	if((floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_5)){
		[super setNeedsDisplay:flag];
	}
	[chainedView setNeedsDisplay:flag];
}

#pragma mark ¥¥¥Drawing

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
		double theValue;
		if([dataSource isKindOfClass:[NSMatrix class]]) theValue = [[dataSource cellWithTag:[self tag]] doubleValue];
		else theValue = [dataSource doubleValue];
		
		float x = [mXScale getPixAbs:theValue];
		[gradient drawInRect:NSMakeRect(1,1,x,b.size.height-2) angle:180.];

	}
	else {
		[NSBezierPath fillRect:NSMakeRect(1,1,b.size.width/3-2,b.size.height-2)];
	}
}


#pragma mark ¥¥¥Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    if([decoder allowsKeyedCoding]){
        [self setBackgroundColor:[decoder decodeObjectForKey:@"backgroundColor"]]; 
        [self setBarColor:[decoder decodeObjectForKey:@"barColor"]]; 
	}
	else {
        [self setBackgroundColor:[decoder decodeObject]]; 
        [self setBarColor:[decoder decodeObject]]; 
	}
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    if([encoder allowsKeyedCoding]){
        [encoder encodeObject:backgroundColor forKey:@"backgroundColor"];
        [encoder encodeObject:barColor forKey:@"barColor"];
	}
	else {
        [encoder encodeObject:backgroundColor];
        [encoder encodeObject:barColor];
	}
}

@end
