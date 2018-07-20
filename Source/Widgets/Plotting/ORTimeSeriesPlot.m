//
//  ORTimeSeriesPlot.m
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
//University of1DHisto Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORTimeSeriesPlot.h"
#import "ORPlotView.h"
#import "ORTimeLine.h"
#import "ORPlotAttributeStrings.h"
#import "ORTimeRoi.h"

@implementation ORTimeSeriesPlot

#pragma mark ***Data Source Setup
- (void) setDataSource:(id)ds
{
	if( ![ds respondsToSelector:@selector(numberPointsInPlot:)] || 
	    ![ds respondsToSelector:@selector(plotterStartTime:)]   ||
	    ![ds respondsToSelector:@selector(plotter:index:x:y:)]) {
		ds = nil;
	}
	dataSource = ds;
}

- (id) roiAtPoint:(NSPoint)aPoint
{
	NSPoint plotPoint = [self convertFromWindowToPlot:aPoint];
	int32_t mouseChannel  = plotPoint.x;
	ORAxis* mXScale = [plotView xScale];
	
	int32_t aMinChannel = MAX([mXScale minLimit],mouseChannel-3);
	int32_t aMaxChannel = MIN([mXScale maxLimit],mouseChannel+3);
	return [[[ORTimeRoi alloc] initWithMin:aMinChannel max:aMaxChannel] autorelease];
}

#pragma mark ***Drawing
- (void) drawData
{
	NSAssert([NSThread mainThread],@"ORTimeSeriesPlot drawing from non-gui thread");

	int numPoints = [dataSource numberPointsInPlot:self];
    //if(numPoints == 0) return;

	ORAxis*    mXScale = [plotView xScale];
	ORAxis*    mYScale = [plotView yScale];
				
    NSTimeInterval startTime = [dataSource plotterStartTime:self];
	[(ORTimeLine*)mXScale setStartTime: startTime];
    NSBezierPath* theDataPath = [NSBezierPath bezierPath];
    
	BOOL aLog = [mYScale isLog];
	BOOL aInt = [mYScale integer];
	double aMinPad = [mYScale minPad];
	double aMinPadx = [mXScale minPad];
	float width		= [plotView bounds].size.width;
	float height	= [plotView bounds].size.height;
	float chanWidth = width / [mXScale valueRange];

	int i;
	double xValue;
	double yValue;    
	float xl = 0;
	float yl = 0;
	double x,y;
	BOOL roiVisible;
	if([dataSource respondsToSelector:@selector(plotterShouldShowRoi:)]){
		roiVisible = [dataSource plotterShouldShowRoi:self] && ([plotView topPlot] == self);
	}
	else {
		roiVisible = NO;
	}
	
	//fill in the roi area
	if(roi && roiVisible){
		
		[roi analyzeData];
		
		int32_t minChan = MAX(0,[roi minChannel]);
		int32_t maxChan = MIN([roi maxChannel],numPoints-1);
		NSColor* fillColor = [[self lineColor] highlightWithLevel:.7];
		fillColor = [fillColor colorWithAlphaComponent:.3];
		[fillColor set];
		
		x	= [mXScale getPixAbs:minChan]-chanWidth/2.;
		xl	= x;
		double xValue,yValue;
		[dataSource plotter:self index:(int)minChan x:&xValue y:&yValue];
		yl	= [mYScale getPixAbs:yValue];
		int32_t ix;
		for (ix=minChan; ix<=maxChan+1;++ix) {
			if(ix > numPoints)break;
			double xValue;
			double yValue;
			[dataSource plotter:self index:(int)ix x:&xValue y:&yValue];
			
			x = [mXScale getPixAbsFast:ix log:NO integer:YES minPad:aMinPadx] - chanWidth/2.;
			y = [mYScale getPixAbsFast:yValue log:aLog integer:aInt minPad:aMinPad];
			[NSBezierPath fillRect:NSMakeRect(xl,1,x-xl+1,yl)];
			xl = x;
			yl = y;
		}	
	}

	for (i=0; i<numPoints;++i) {
		[dataSource plotter:self index:i x:&xValue y:&yValue];
		float y = [mYScale getPixAbsFast:yValue log:aLog integer:aInt minPad:aMinPad];
		float x = [mXScale getPixAbs:(double)(xValue - startTime)];
		if(i==0)[theDataPath moveToPoint:NSMakePoint(x,y)];
		else [theDataPath lineToPoint:NSMakePoint(x,y)];
	}
	
	if([self useConstantColor] || [plotView topPlot] == self)	[[self lineColor] set];
	else [[[self lineColor] highlightWithLevel:.5]set];

	[theDataPath setLineWidth:[self lineWidth]];
	[theDataPath stroke];
	
	//draw the roi bounds
	if(roi && roiVisible){
		int32_t minChan = MAX(0,[roi minChannel]);
		int32_t maxChan = MIN([roi maxChannel],[mXScale maxLimit]);
		
		[[NSColor blackColor] set];
		[NSBezierPath setDefaultLineWidth:.5];
		float x1 = [mXScale getPixAbsFast:minChan log:NO integer:YES minPad:aMinPadx];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,0) toPoint:NSMakePoint(x1, height)];
		float x2 = [mXScale getPixAbsFast:maxChan log:NO integer:YES minPad:aMinPadx];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x2,0) toPoint:NSMakePoint(x2, height)];
		
		[[roi fit] drawFit:plotView];
	}
	
}

- (void) drawExtras 
{		
	
	float height = [plotView bounds].size.height;
	float width  = [plotView bounds].size.width;
	NSFont* font = [NSFont systemFontOfSize:12.0];
	NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:.8],NSBackgroundColorAttributeName,nil];
	
	if([plotView commandKeyIsDown] && showCursorPosition){
		int numPoints = [dataSource numberPointsInPlot:self];
				 
		ORAxis*    mXScale = [plotView xScale];
		ORAxis*    mYScale = [plotView yScale];
		double xValue;
		double yValue;    
		NSTimeInterval startTime = [dataSource plotterStartTime:self];
		int index = cursorPosition.x;
		[dataSource plotter:self index:index x:&xValue y:&yValue];
		double y = [mYScale getPixAbs:yValue];
		double x = [mXScale getPixAbs:(double)(xValue - startTime)];
		
		[[NSColor blackColor] set];
		[NSBezierPath setDefaultLineWidth:.75];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x,0) toPoint:NSMakePoint(x,height)];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(0,y) toPoint:NSMakePoint(width,y)];
		
		if(index>=0 && index<numPoints){
			NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)(index+ startTime)];
			NSString* cursorPositionString = [NSString stringWithFormat:@"Time:%@   y:%.3f  ",date,cursorPosition.x<numPoints?cursorPosition.y:0.0];
			NSAttributedString* s = [[NSAttributedString alloc] initWithString:cursorPositionString attributes:attrsDictionary];
			NSSize labelSize = [s size];
			[s drawAtPoint:NSMakePoint(width - labelSize.width - 10,height-labelSize.height-5)];
			[s release];
		}		
	}
}

#pragma mark ***Conversions
- (void) showCrossHairsForEvent:(NSEvent*)theEvent
{
	NSPoint plotPoint = [self convertFromWindowToPlot:[theEvent locationInWindow]];
	int index = plotPoint.x;
	double x;
	double y;
	[dataSource plotter:self index:index x:&x y:&y];
	x = index;
	
	showCursorPosition = YES;
	cursorPosition = NSMakePoint(x,y);
	[plotView setNeedsDisplay:YES];	
}

@end					
