//
//  OR1dRoi.h
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
@class ORPlot;
@class ORPlotView;

@interface NSObject (OR1dRoiDataSourceMethods)
- (int)   numberPointsInPlot:(id)aPlot;
- (void) plotter:(id)aPlot index:(int)index x:(double*)x y:(double*)y;
- (id)    plotView;
- (id)    topPlot;
@end

enum {
    kInitialDrag,
    kMinDrag,
    kMaxDrag,
    kCenterDrag,
    kNoDrag
};

@interface OR1dRoi : NSObject {
    id			dataSource;
	long		minChannel;
	long		maxChannel;
	double		centroid;
	double		sigma;
	double		totalSum;
	double		peaky;
	double		peakx;
	id			fit;
	id			fft;
	
	double			startChan;
	BOOL			dragInProgress;
	int				dragType;
	int             gate1,gate2;
	NSString*		label;
	
	BOOL			useRoiRate;
	BOOL			rateValid;
	NSTimeInterval  tLast;
	NSTimeInterval  tCurrent;
	double			lastSum;
	double			roiRate;
}

#pragma mark ***Initialization
- (id) initWithMin:(int)aMin max:(int)aMax;
- (void) dealloc;

#pragma mark ***Accessors
- (void)	setDataSource:(id)ds;
- (void)	setLabel:(NSString*)aLabel;
- (NSString*) label;
- (id)		dataSource ;
- (BOOL)	useRoiRate;
- (void)	setUseRoiRate:(BOOL)aState;
- (long)	minChannel;
- (void)	setMinChannel:(long)aChannel;
- (long)	maxChannel;
- (void)	setMaxChannel:(long)aChannel;
- (void) setDefaultMin:(long)aMinChannel max:(long)aMaxChannel;
- (double)	average;	
- (double)	centroid;	
- (double)	sigma;	
- (double)	totalSum;	
- (double)   peaky;	
- (double)   peakx;	
- (double)	roiRate;
- (void)	setCentroid:(double)aValue;
- (void)	setSigma:(double)aValue;   
- (void)	setTotalSum:(double)aValue; 
- (void)	setPeaky:(double)aValue;  
- (void)	setPeakx:(double)aValue;    
- (void)	setFit:(id)aFit;
- (id)		fit;
- (id)		makeFitObject;
- (id)		fft;
- (void)	setFFT:(id)aFFT;
- (id)		makeFFTObject;

#pragma mark ***Analysis
- (void) analyzeData;

#pragma mark ***Event Handling
- (void) flagsChanged:(NSEvent *)theEvent;
- (BOOL) mouseDown:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotView;
- (void) mouseDragged:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotView;
- (void) mouseUp:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotter;
- (void) shiftRight;
- (void) shiftLeft;

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* OR1dRoiMinChanged;
extern NSString* OR1dRoiMaxChanged;
extern NSString* OR1dRoiAnalysisChanged;
