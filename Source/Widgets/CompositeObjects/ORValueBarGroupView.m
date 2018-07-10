//
//  ORValueBarGroupView.m
//  Orca
//
//  Created by Mark Howe on 2/20/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
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

#import "ORValueBarGroupView.h"
#import "ORAxis.h"
#import "ORValueBar.h"

#define kBarHeight 10

@implementation ORValueBarGroupView

@synthesize xAxis,dataSource,numberBars,barHeight,barSpacing,chainedView;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
	}
    return self;
}

- (void) dealloc
{
	[xAxis release];
	[valueBars release];
	[super dealloc];
}

- (void) awakeFromNib
{
	//set some defaults
	[self setNumber:1 height:10 spacing:10];
	[xAxis awakeFromNib];
}

- (BOOL) isFlipped
{
	return YES;
}
- (NSArray*) valueBars
{
    return valueBars;
}

- (void) setNumber:(int)n height:(float)aHeight spacing:(float)aSpacing
{	
	self.numberBars = n;
	self.barHeight  = aHeight;
	self.barSpacing = aSpacing;
	
	[self setUpViews];
}

- (void) setUpViews
{
	if(!valueBars)valueBars = [[NSMutableArray array] retain];
	else {
		//must be second time around
		[valueBars removeAllObjects];
		[[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
	}
	//set up the *rough* positions of the various parts
	NSRect boundsRect = [self bounds];
	int i;
	for(i=0;i<numberBars;i++){
		//do the ValueBar(s) -- frame size will be fixed when we know more
		ORValueBar* aBar = [[ORValueBar alloc] initWithFrame:NSMakeRect(0,0,boundsRect.size.width,kBarHeight)];
		[aBar setAutoresizingMask:NSViewWidthSizable];
		[self addSubview:aBar];
		[valueBars addObject:aBar];
		[aBar release];
	}
	//do the xAxis -- frame size will be fixed when we know more
	ORAxis* anAxis = [[ORAxis alloc] initWithFrame:NSMakeRect(0,kBarHeight,boundsRect.size.width,0)];
	[anAxis setAutoresizingMask:NSViewWidthSizable];
	[self addSubview:anAxis];
	self.xAxis = anAxis;
	[anAxis release];
	i = 0;
	for(id aValueBar in valueBars){
		[aValueBar setXScale:xAxis];
		[aValueBar setTag:i];
		[aValueBar setDataSource:dataSource];
		i++;
	}
	i = 0;
	id previousValueBar = nil;
	for(id aValueBar in [valueBars reverseObjectEnumerator]){
		//only the one on the bottom is connected to the x axis for scaling	
		//the rest are chained to the first
		if(i==0) [xAxis setViewToScale:[valueBars objectAtIndex:numberBars-1]];
		else	 [aValueBar setChainedView:previousValueBar];
		previousValueBar = aValueBar;
		i++;
	}
	
	[self adjustPositionsAndSizes];
}

- (void) adjustPositionsAndSizes
{
	NSRect axisRect = [xAxis frame];
	int i = 0;
	float delta;
	//adjust position of valueBar to line up with the axis
	for(id aValueBar in valueBars){
		delta = i * (barHeight + barSpacing); 
		[aValueBar setFrame:NSMakeRect([xAxis lowOffset], 
									  delta,
									  [xAxis highOffset]-[xAxis lowOffset], 
									  barHeight) ];
		i++;
	}
	NSRect finalBarRect = [[valueBars lastObject] frame];
	[xAxis setFrame:NSMakeRect(axisRect.origin.x, 
								  finalBarRect.origin.y+barHeight+1, 
								  axisRect.size.width, 
								  axisRect.size.height) ];
	
	float oldY = [self frame].origin.y + [self frame].size.height;
	
	[self setFrame:NSMakeRect([self frame].origin.x,[self frame].origin.y,[self frame].size.width,[xAxis frame].size.height + numberBars*(barHeight+barSpacing))];
	

	[self setFrameOrigin:NSMakePoint([self frame].origin.x,oldY - [self frame].size.height)];
}
/*
- (void) drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	[NSBezierPath strokeRect:[self bounds]];
}
*/
- (void) setXLabel:(NSString*)aLabel { [xAxis setLabel:aLabel]; }

- (IBAction) setLogX:(id)sender  { [xAxis setLog:[sender intValue]]; }
@end
