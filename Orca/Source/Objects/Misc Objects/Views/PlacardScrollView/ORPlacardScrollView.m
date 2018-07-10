//
//  ORPlacardScrollView.m
//  Orca
//
//  Created by Mark Howe on Fri Feb 20 2004. Actually, copied from the net. 
//  True author is unknown.
//  Copyright (c) 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORPlacardScrollView.h"

@implementation ORPlacardScrollView

/*"	Release all the objects held by self, then call superclass.
"*/

- (void) dealloc
{
    [placard release];
    [super dealloc];
}

/*"	Set the side (!{PlacardLeft} or !{PlacardRight}) that the placard will appear on.
"*/

- (void) setSide:(int) inSide
{
    side = inSide;
}

/*"	This setter puts it into the superview.  Therefore, if you hook it up from Interface Builder,
	the view will be installed automagically. "*/

- (void) setPlacard:(NSView *)inView
{
    [inView retain];
    if (nil != placard) {
	[placard removeFromSuperview];
	[placard release];
    }
    placard = inView;
    [self addSubview:placard];
}

/*"	Return the placard view
"*/

- (NSView *) placard
{
    return placard;
}

/*"	Tile the view.  This invokes super to do most of its work, but then fits the placard into place.
"*/

- (void)tile
{
    [super tile];
    if (placard && [self hasHorizontalScroller]) {
	NSScroller *horizScroller;
	NSRect horizScrollerFrame, placardFrame;

	horizScroller = [self horizontalScroller];
	horizScrollerFrame = [horizScroller frame];
	placardFrame = [placard frame];

	// Now we'll just adjust the horizontal scroller size and set the placard size and location.
	horizScrollerFrame.size.width -= placardFrame.size.width;
	[horizScroller setFrameSize:horizScrollerFrame.size];

	if (PlacardLeft == side){
	    // Put placard where the horizontal scroller is
	    placardFrame.origin.x = NSMinX(horizScrollerFrame);
	    
	    // Move horizontal scroller over to the right of the placard
	    horizScrollerFrame.origin.x = NSMaxX(placardFrame);
	    [horizScroller setFrameOrigin:horizScrollerFrame.origin];
	}
	else {	// on right
		// Put placard to the right of the new scroller frame
		placardFrame.origin.x = NSMaxX(horizScrollerFrame);
	}
	// Adjust height of placard
	placardFrame.size.height = horizScrollerFrame.size.height + 1.0;
	placardFrame.origin.y = [self bounds].size.height - placardFrame.size.height ;//+ 2.0;
	
	// Move the placard into place
	[placard setFrame:placardFrame];
    }
}

- (void) drawRect:(NSRect)aRect
{
	NSRect bounds = [self bounds];
	float red,green,blue,alpha;
	NSColor* color = [[self backgroundColor] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
	[color getRed:&red green:&green blue:&blue alpha:&alpha];

	red *= .75;
	green *= .75;
	blue *= .75;
	//alpha = .75;

	NSColor* endingColor = [NSColor colorWithCalibratedRed:red green:green blue:blue alpha:alpha];

	NSGradient* gradient = [[[NSGradient alloc] initWithStartingColor:color endingColor:endingColor] autorelease];

	[gradient drawInRect:bounds angle:90.];

	[super drawRect:aRect];
}


@end
