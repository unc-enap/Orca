//
//  ORPlot.h
//  Orca
//
//  Created by Mark Howe on 2/20/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
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

#import <Cocoa/Cocoa.h>

@class ORPlotView;

@protocol ORPlotDataSourceMethods
- (int)   numberPointsInPlot:(id)aPlot;
- (void) plotter:(id)aPlot index:(int)i x:(double*)xValue y:(double*)yValue;
@end

@protocol ORFastPlotDataSourceMethods
- (NSUInteger) plotter:(id)aPlot indexRange:(NSRange)aRange stride:(NSUInteger)stride x:(NSMutableData*)x y:(NSMutableData*)y;
@end

#define kSymbolSize 10

@interface ORPlot : NSObject {
	ORPlotView*				plotView;
    id						dataSource;
    NSUInteger						tag;
 	NSMutableDictionary*	attributes;
	BOOL					showCursorPosition;
	NSPoint					cursorPosition;
	NSImage*				symbolNormal;
	NSImage*				symbolLight;
	NSColor*				savedColor;
}

- (id) initWithTag:(int)aTag andDataSource:(id)dataSource;
- (id) initWithTag:(int)aTag;
- (id) init;
- (void) dealloc;

- (NSMutableDictionary*) attributes;
- (void) setAttributes:(NSMutableDictionary *)anAttributes;

- (void) setTag:(NSUInteger)aTag;
- (NSUInteger) tag;
- (NSString*) name;
- (void) setName:(NSString*)aName;

- (void) setDataSource:(id)ds;
- (id)	 dataSource;
- (BOOL) dataSourceIsSetupToAllowDrawing;
- (void) setPlotView:(ORPlotView*)aPlotView;
- (void) drawData;
- (void) drawExtras;
- (void) saveColor;
- (void) restoreColor;

#pragma mark ***Attributes
- (void) setUpSymbol;
- (void) setDefaults;
- (void) setShowLine:(BOOL)aState;
- (BOOL) showLine;
- (void) setShowSymbols:(BOOL)aState;
- (BOOL) showSymbols;
- (NSColor*) lineColor;
- (void) setLineColor:(NSColor*)aColor;
- (void) setLineWidth:(float)aWidth;
- (float) lineWidth;
- (void) setUseConstantColor:(BOOL)aState;
- (BOOL) useConstantColor;
- (void) setSymbolNormal:(NSImage*)aSymbol;
- (void) setSymbolLight:(NSImage*)aSymbol;
- (BOOL) canScaleY;
- (BOOL) canScaleX;
- (BOOL) canScaleZ;

#pragma mark ***Event Handling
- (void) flagsChanged:(NSEvent *)theEvent;
- (void) keyDown:(NSEvent*)theEvent;
- (BOOL) mouseDown:(NSEvent*)theEvent;
- (void) mouseDragged:(NSEvent*)theEvent;
- (void) mouseUp:(NSEvent*)theEvent;
- (void) resetCursorRects;
- (BOOL) redrawEvent:(NSNotification*)aNote;

#pragma mark ***Drawing
- (void) drawData;
- (void) drawExtras;

#pragma mark ***Conversions
- (NSPoint) convertFromWindowToPlot:(NSPoint)aWindowLocation;
- (void) showCrossHairsForEvent:(NSEvent*)theEvent;

#pragma mark ***Component Switching
- (BOOL) nextComponent;
- (BOOL) lastComponent;

#pragma mark ***Scaling (Abstract)
- (void) logLin;

- (int32_t) numberPoints;
- (NSString*) valueAsStringAtPoint:(int32_t)i;

- (void) getyMin:(double*)yMin yMax:(double*)yMax;
- (void) getxMin:(double*)xMin xMax:(double*)xMax;
- (float) getzMax;

- (int32_t) maxValueChannelinXRangeFrom:(int32_t)minChannel to:(int32_t)maxChannel;

@end
