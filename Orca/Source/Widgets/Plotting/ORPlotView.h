//
//  ORPlotView.h
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
@class ORPlot;
@class ORAxis;

@interface NSObject (NRTPlotViewDelegateMethods)
- (void) plotViewWillDraw:(ORPlotView*) view;
- (void) plotViewDidDraw:(ORPlotView*) view;
- (void) plotOrderDidChange:(id)aPlot;
- (id) fit;
@end

@interface ORPlotView : NSView {
	@private
		NSMutableArray*			plotArray;
		NSMutableDictionary*	attributes;
		NSGradient*				gradient;
		BOOL					shiftKeyIsDown;
		BOOL					commandKeyIsDown;
		BOOL					optionKeyIsDown;
		BOOL					controlKeyIsDown;
		NSImage*				backgroundImage;
	
		BOOL					dragInProgress;
		float					startDragXValue;
		float					startDragYValue;
		float					currentDragXValue;
		float					currentDragYValue;
		NSString*				comment;
		IBOutlet id				delegate;
		IBOutlet ORAxis*		xScale;
		IBOutlet ORAxis*		yScale;
		IBOutlet ORAxis*		zScale;
		IBOutlet ORAxis*		colorScale;
		IBOutlet NSView*		viewForPDF;
		IBOutlet NSTextField*	titleField;
}

#pragma mark ***Initialization
- (id)   initWithFrame:(NSRect)frame; 
- (void) dealloc;
- (void) setDefaults;
- (BOOL) isOpaque;
- (void) setBackgroundImage:(NSImage*)anImage;

#pragma mark ***Accessors
- (BOOL) shiftKeyIsDown;
- (BOOL) commandKeyIsDown;
- (void) setDelegate:(id)aDelegate;
- (id) delegate;
- (NSMutableDictionary*) attributes;
- (void) setAttributes:(NSMutableDictionary *)anAttributes;
- (id) dataSource; //temp until conversion complete
- (void) setComment:(NSString*)aComment;
- (void) setViewForPDF:(NSView*)aView;
 
#pragma mark ***Parts
- (NSTextField*) titleField;
- (id) xScale;
- (id) yScale;
- (id) zScale;
- (id) colorScale;
- (void) setXScale:(id)anAxis;
- (void) setYScale:(id)anAxis;
- (void) setZScale:(id)anAxis;
- (void) setColorScale:(id)colorScale;

#pragma mark ***Plots
- (ORPlot*) topPlot;
- (void) addPlot:(id)aPlot;
- (void) removePlot:(id)aPlot;
- (void) removeAllPlots; 
- (int) numberOfPlots;
- (id)  plot:(int)i;
- (id)  plotWithTag:(int)aTag;

#pragma mark ***Attributes
- (void) setDefaults;
- (void) setBackgroundColor:(NSColor *)aColor;
- (NSColor*) backgroundColor;
- (void) setGridColor:(NSColor *)aColor;
- (NSColor*) gridColor;
- (BOOL) useGradient;
- (void) setUseGradient:(BOOL)aFlag;
- (BOOL) showGrid;
- (void) setShowGrid:(BOOL)aFlag;
- (NSDictionary*) textAttributes;

#pragma mark ***Drawing
- (void) drawBackground;
- (void) drawRect:(NSRect)rect; 
- (NSData*) plotAsPDFData:(NSRect)aRect;
- (void) drawComment;

#pragma mark ***Component Switching
- (void) orderChanged;
- (void) nextComponent;
- (void) lastComponent;

#pragma mark ***Event Handling
- (BOOL) acceptsFirstMouse:(NSEvent*)theEvent;
- (BOOL) acceptsFirstResponder;
- (void) keyDown:(NSEvent*)theEvent;
- (void) mouseDown:(NSEvent*)theEvent;
- (void) mouseDragged:(NSEvent*)theEvent;
- (void) mouseUp:(NSEvent*)theEvent;
- (void) resetCursorRects;
- (void) redrawEvent:(NSNotification*)aNote;
- (void) enableCursorRects;
- (void) disableCursorRects;
- (BOOL) plotterShouldShowRoi:(id)aPlot;

#pragma mark ***Actions
- (IBAction) resetScales:(id)sender; 
- (IBAction) autoscaleAll:(id)sender;	 
- (IBAction) resetScales:(id)sender;
- (IBAction) centerOnPeak:(id)sender;
- (IBAction) autoScaleX:(id)sender;
- (IBAction) autoScaleY:(id)sender;
- (IBAction) autoScaleZ:(id)sender;
- (IBAction) refresh:(id)sender;
- (IBAction)logLin:(id)sender;
- (IBAction) copy:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;   
- (IBAction) zoomXYIn:(id)sender;
- (IBAction) zoomXYOut:(id)sender;
- (IBAction) autoScale:(id)sender; 
- (IBAction) writeToFile:(id)sender;
- (void) savePlotDataAs:(NSString*)aPath;

@end
