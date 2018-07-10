//
//  SBCLamView.m
//  Orca
//
//  Created by Mark Howe on Fri Jan 04, 2007.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#import "SBCLamView.h"
#import "ORSBC_LAMModel.h"

@implementation SBCLamView

- (void) dealloc
{
	[gradient release];
	[super dealloc];
}


- (void)drawRect:(NSRect)rect
{
 	if(!gradient){
		NSColor* color = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1];
		NSColor* endingColor = [NSColor colorWithCalibratedRed:.75 green:.75 blue:.75 alpha:1];
		gradient = [[NSGradient alloc] initWithStartingColor:color endingColor:endingColor];
	}
	[gradient drawInRect:[self bounds] angle:270.];
	
	float y1 = [self bounds].origin.y;
    float y2 = y1+[self bounds].size.height;
    float x = [self bounds].origin.x + 48;
    for(;x<[self bounds].size.width;x+=48){
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x,y1) toPoint:NSMakePoint(x,y2)];
    }
	
	[super drawContents:rect];
}


@end
