//
//  OR2dRoi.h
//  Orca
//
//  Created by Mark Howe on 2/13/10.
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
@class ORPlotView;
@class ORPlot;
@class ORPoint;

@interface NSObject (OR2dRoiDataSourceMethods)
- (int)   numberPointsInPlot:(id)aPlot;
- (void) plotter:(id)aPlot index:(int)index x:(double*)x y:(double*)y;
- (NSData*) plotter:(id)aPlotter numberBinsPerSide:(unsigned short*)xValue;
- (void) plotter:(id) aPlotter xMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY;
- (id)    plotView;
- (id)    topPlot;
@end

@interface OR2dRoi : NSObject {
    id				dataSource;
	double			totalSum;
	float			peaky;
	float			peakx;
	float			average;
	NSMutableArray* points;
	BOOL			drawControlPoints;
	BOOL			dragInProgress;
	BOOL			dragWholePath;
	NSPoint			dragStartPoint;
	ORPoint*		selectedPoint;
	NSBezierPath*   theRoiPath;
	BOOL			cmdKeyIsDown;
	BOOL			optionKeyIsDown;
	BOOL			mouseIsDown;
	NSString*		label;
}

#pragma mark ***Initialization
- (id) initAtPoint:(NSPoint)aPoint;
- (void) dealloc;

#pragma mark ***Accessors
- (NSArray*)points;
- (void)	setPoints:(NSMutableArray*)somePoints;
- (void)	setDataSource:(id)ds;
- (id)		dataSource ;
- (void)	setLabel:(NSString*)aLabel;
- (NSString*) label;
- (double)	average;
- (double)	totalSum;
- (int)		peakx;
- (int)		peaky;

#pragma mark ***Analysis
- (void) analyzeData;

#pragma mark ***Event Handling
- (BOOL) mouseDown:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotView;
- (void) mouseDragged:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotView;
- (void) mouseUp:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotter;
- (void) shiftRight;
- (void) shiftLeft;
- (void) shiftDown;
- (void) shiftUp;
- (void) centerOnX:(double)centerX y:(double) centerY;

#pragma mark ***Drawing
- (void) drawRoiInPlot:(ORPlotView*)aPlot;

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

#define kPointSize 6

@interface ORPoint : NSObject {
	NSPoint xyPosition;
}
+ (id) point:(NSPoint)aPoint;

- (id) initWithPoint:(NSPoint)aPoint;
- (NSPoint) xyPosition;
- (void) setXyPosition:(NSPoint)aPoint;
- (void) drawPointInPlot:(ORPlotView*)aPlotter;
- (BOOL) containsPoint:(NSPoint)aPoint;

@end

extern NSString* ORPointChanged;
extern NSString* OR2dRoiAnalysisChanged;
