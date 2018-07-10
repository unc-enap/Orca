//
//  ORMJDTestCryoView.m
//  Orca
//
//  Created by Mark Howe on Mon Aug13, 2012.
//  Copyright © 2012 CENPA, University of North Carolina. All rights reserved.
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

#import "ORMJDTestCryoView.h"
#import "ORMJDTestCryostat.h"

@implementation ORMJDTestCryoView
- (int) tag
{
	return tag;
}
- (void) setTag:(int)aValue
{
	tag = aValue;
}

- (void) drawRect:(NSRect)dirtyRect 
{
	[super drawRect:dirtyRect];
	
	[[NSColor grayColor] set];
	[NSBezierPath strokeRect:[self bounds]];
	
	NSImage* stringsImage = [NSImage imageNamed:@"MJDString"];
	NSPoint aPoint = NSMakePoint(85,105);
	[stringsImage drawAtPoint:aPoint fromRect:[stringsImage imageRect] operation:NSCompositeSourceOver fraction:1.0];

    [self drawString:[NSString stringWithFormat:@"Cryo #%d",tag+1] atPoint:NSMakePoint( 3, 167)];
    [self drawString:@"A" atPoint:NSMakePoint( 75, 160)];
    [self drawString:@"B" atPoint:NSMakePoint(115, 160)];
    [self drawString:@"C" atPoint:NSMakePoint( 75, 150)];
    [self drawString:@"D" atPoint:NSMakePoint( 75, 108)];

    
   
}
- (void) drawString:(NSString*)aString atPoint:(NSPoint)aPoint
{
    NSAttributedString* s = [[NSAttributedString alloc] initWithString:aString
                                        attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    [NSFont fontWithName:@"Geneva" size:12],NSFontAttributeName,
                                                    nil]];
    [s drawAtPoint:aPoint];
    [s release];

}
@end
