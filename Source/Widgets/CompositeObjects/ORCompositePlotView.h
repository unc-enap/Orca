//
//  ORCompositePlotView.h
//  Orca
//
//  Created by Mark Howe on 2/20/10.
//  Copyright 2010 University of North Carolina. All rights reserved.
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
@class ORAxis;
@class ORPlotView;
@class ORLegend;
@class ORPlot;
@class ORColorBar;

@interface ORCompositePlotView : NSView {
	ORLegend*		legend;
	ORAxis*			xAxis;
	ORAxis*			yAxis;
	id				plotView;
	id				delegate;
	BOOL			showLegend;
	NSTextField*	titleField;
}

- (void) makeTitle;
- (void) setUpViews;
- (void) makeXAxis;
- (void) makeYAxis;
- (void) makePlotView;
- (void) makeLegend;

#pragma mark •••Pass-thru Methods
- (id)  plotWithTag:(int)aTag;
- (int) numberOfPlots;
- (void) enableCursorRects;
- (void) disableCursorRects;
- (NSData*) plotAsPDFData;
- (void) adjustPositionsAndSizes;
- (void) setBackgroundColor:(NSColor*)aColor;
- (void) setUseGradient:(BOOL)state;
- (void) addPlot:(id)aPlot;
- (void) setXLabel:(NSString*)aLabel;
- (void) setYLabel:(NSString*)aLabel;
- (void) setPlotTitle:(NSString*)aTitle;
- (ORPlot*) topPlot;
- (void) removeAllPlots;
- (void) setComment:(NSString*)aComment;
- (id)  plot:(int)aTag;
- (void) setPlot:(int)aTag name:(NSString*)aName;
- (void) setShowGrid:(BOOL)aFlag;
- (void) setBackgroundImage:(NSImage*)anImage;
- (void) setGridColor:(NSColor*)aColor;
- (void) setXTempLabel:(NSString*)aLabel;
- (void) setYTempLabel:(NSString*)aLabel;

#pragma mark ***Actions
- (IBAction) setLogX:(id)sender;
- (IBAction) setLogY:(id)sender;
- (IBAction) centerOnPeak:(id)sender;
- (IBAction) autoScaleX:(id)sender;
- (IBAction) autoScaleY:(id)sender;
- (IBAction) resetScales:(id)sender; 
- (IBAction) autoscaleAll:(id)sender;
- (IBAction) resetScales:(id)sender;
- (IBAction) publishToPDF:(id)sender;
- (IBAction) refresh:(id)sender;
- (IBAction) logLin:(id)sender;
- (IBAction) copy:(id)sender;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;   
- (IBAction) zoomXYIn:(id)sender;
- (IBAction) zoomXYOut:(id)sender;
- (IBAction) shiftXLeft:(id)sender;
- (IBAction) shiftXRight:(id)sender;
- (IBAction) publishToPDF:(id)sender;
- (IBAction) autoScale:(id)sender;

@property (nonatomic,assign) BOOL			showLegend;
@property (retain) NSTextField*	titleField;
@property (retain) ORAxis*		xAxis;
@property (retain) ORAxis*		yAxis;
@property (retain) id			plotView;
@property (retain) ORLegend*	legend;
@property (assign) IBOutlet id  delegate;

@end

@interface ORCompositeMultiPlotView : ORCompositePlotView {
}
- (void) makeTitle;
@end

@interface ORCompositeTimeLineView : ORCompositePlotView {
}
- (void) makeXAxis;
@end

@interface ORCompositeTimeSeriesView : ORCompositePlotView {
}
- (void) makeXAxis;
@end

@interface ORCompositeRamperView : ORCompositePlotView {
}
- (void) makePlotView;
@end

