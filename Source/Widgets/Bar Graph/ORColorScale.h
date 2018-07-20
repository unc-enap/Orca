//
//  ORColorScale.h
//  Orca
//
//  Created by Mark Howe on Mon Sep 08 2003.
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




@class ORAxis;

#define kNumColors 128


@interface ORColorScale : NSView {
    IBOutlet ORAxis* colorAxis;
	
	NSMutableArray* colors;
	float	spectrumRange;
	short 	numColors;
    BOOL    useRainBow;
    NSColor* startColor;
    NSColor* endColor;
    BOOL    scaleIsXAxis;
	BOOL	makeColors;
    BOOL    excludeZero;
}

- (id)initWithFrame:(NSRect)frame;
- (void) dealloc;

#pragma mark ¥¥¥Accessors
- (BOOL) excludeZero;
- (void) setExcludeZero:(BOOL)aFlag;
- (void) setColorAxis:(ORAxis*)anAxis;
- (ORAxis*) colorAxis;
- (NSMutableArray*) colors;
- (void) setColors:(NSMutableArray*)newColors;
- (NSColor*) getColorForValue:(float)aValue;
- (unsigned short) getFastColorIndexForValue:(uint32_t)aValue log:(BOOL)aLog integer:(BOOL)aInt minPad:(double)aMinPad;
- (unsigned short) getColorIndexForValue:(uint32_t)aValue;
- (NSColor*) getColorForIndex:(unsigned short)index;

- (BOOL) useRainBow;
- (void) setUseRainBow: (BOOL) flag;
- (NSColor *) startColor;
- (void) setStartColor: (NSColor *) aStartColor;
- (NSColor *) endColor;
- (void) setEndColor: (NSColor *) anEndColor;
- (float) spectrumRange;
- (void) setSpectrumRange:(float)newSpectrumRange;
- (short) numColors;
- (void) setNumColors:(short)newNumColors;

@end
