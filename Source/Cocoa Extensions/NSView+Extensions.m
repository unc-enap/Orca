//
//  NSView+Extensions.m
//  Orca
//
//  Created by Mark Howe on 4/6/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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


@implementation NSView (ScaleUtilities)

const NSSize unitSize = { 1.0, 1.0 };

// This method makes the scaling of the receiver equal to the window's
// base coordinate system.
- (void) resetScaling 
{ 
	[self scaleUnitSquareToSize: [self convertSize: unitSize fromView: nil]];  
}

// This method sets the scale in absolute terms.
- (void) setScale:(NSSize) newScale
{
	[self resetScaling];  // First, match our scaling to the window's coordinate system
	[self scaleUnitSquareToSize:newScale]; // Then, set the scale.
}

// This method returns the scale of the receiver's coordinate system, relative to
// the window's base coordinate system.
- (NSSize) scale 
{ 
	return [self convertSize:unitSize toView:nil]; 
}

// Use these if you'd rather work with percentages.
- (float) scalePercent 
{ 
	return [self scale].width * 100; 
}

- (void) setScalePercent:(float) scale
{
	scale = scale/100.0;
	[self setScale:NSMakeSize(scale, scale)];
	[self setNeedsDisplay:YES];
}

@end

