//  ORLineNumberingRulerView.h
//  ORCA
//
//  Created by Mark Howe on 1/3/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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

@class ORLineMarker;

@interface ORLineNumberingRulerView : NSRulerView
{
    NSMutableArray      *lineIndices;		//Array of character indices for the beginning of each line
	NSMutableDictionary	*linesToMarkers;	//Maps line numbers to markers
	NSFont              *font;
	NSColor				*textColor;
	NSColor				*alternateTextColor;
	NSColor				*backgroundColor;
	NSImage				*markerImage;
	BOOL				showBreakpoints;
}

- (id) initWithScrollView:(NSScrollView *)aScrollView;

- (void) showBreakpoints:(BOOL)aState;

- (void) setFont:(NSFont *)aFont;
- (NSFont*) font;

- (void) setTextColor:(NSColor*)color;
- (NSColor*) textColor;

- (void) setAlternateTextColor:(NSColor*) color;
- (NSColor*) alternateTextColor;

- (void) setBackgroundColor:(NSColor*) color;
- (NSColor*) backgroundColor;

- (NSUInteger) lineNumberForLocation:(float)location;
- (ORLineMarker*) markerAtLine:(NSUInteger)line;
- (void) loadLineMarkers:(NSDictionary*)someLineMarkers;

@end

extern NSString* ORBreakpointsAction;
