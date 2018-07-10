//
//  ORBarGraph.h
//  Orca
//
//  Created by Mark Howe on Mon Mar 31 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ORScale;

@interface ORBarGraph : NSView {
	
	IBOutlet id 		chainedView;
	IBOutlet id 		dataSource;
    IBOutlet id         mXScale;
	NSColor* 			backgroundColor;
	NSColor* 			barColor;
	int 				tag;
}

#pragma mark ¥¥¥Accessors
- (void) setBackgroundColor:(NSColor*)aColor;
- (NSColor*) backgroundColor;
- (void) setBarColor:(NSColor*)aColor;
- (NSColor*) barColor;
- (ORScale*) xScale;

- (int) tag;
- (void) setTag:(int)newTag;

- (void) setNeedsDisplay:(BOOL)flag;

@end

@interface NSObject (ORBarGraph_Catagory)
	- (double) getBarValue:(int)tag;
@end