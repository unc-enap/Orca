//
//  ORColorBar.h
//  Orca
//
//  Created by Mark Howe on Mon Sep 08 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@class ORScale;


@interface ORColorBar : NSView {
    IBOutlet ORScale*		scale;
	
	NSMutableArray* colors;
	float	spectrumRange;
	short 	numColors;
}

#pragma mark •••Accessors
- (ORScale*) scale;
- (NSMutableArray*) colors;
- (void) setColors:(NSMutableArray*)newColors;
- (NSColor*) getColorForValue:(float)aValue;

- (float) spectrumRange;
- (void) setSpectrumRange:(float)newSpectrumRange;
- (short) numColors;
- (void) setNumColors:(short)newNumColors;

@end
