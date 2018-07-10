//
//  ORPciBit3View.m
//  Orca
//
//  Created by Mark Howe on Mon Dec 09 2002.
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

#import "ORPciBit3View.h"

@implementation ORPciBit3View

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
	[[NSColor blackColor]set];
	[NSBezierPath strokeRect:[self bounds]];

    float x1 = [self bounds].origin.x;
    float x2 = x1+[self bounds].size.width;
    float y = [self bounds].origin.y;
    for(;y<[self bounds].size.height;y+=16){
        [NSBezierPath strokeLineFromPoint:NSMakePoint(x1,y) toPoint:NSMakePoint(x2,y)];
    }
}

@end
