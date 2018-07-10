//
//  ORA3818View.m
//  Orca
//
//Author:         Mark A. Howe
//Copyright:		Copyright 3818.  All rights reserved
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

#import "ORA3818View.h"

@implementation ORA3818View

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
