//
//  OR1DHistoPlot.m
//  plotterDev
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

#import "OR1DHistoPlot.h"
#import "ORPlotView.h"
#import "ORAxis.h"
#import "ORPlotAttributeStrings.h"
#import "OR1dFit.h"
#import "OR1dRoi.h"

@implementation OR1DHistoPlot

- (void) setRoi:(id)anRoi
{
	[super setRoi:anRoi];
	[anRoi setUseRoiRate:YES];
}

#pragma mark ***Drawing
- (void) drawData
{
	if(!dataSource) return;
	NSAssert([NSThread mainThread],@"OR1HistoPlot drawing from non-gui thread");
		
	int numPoints = [dataSource numberPointsInPlot:self];
	if(numPoints == 0) return;
		
	//cache some things that we'll use below
	ORAxis* mXScale = [plotView xScale];
	ORAxis* mYScale = [plotView yScale];
	BOOL aLog		= [mYScale isLog];
	BOOL aInt		= [mYScale integer];
	double aMinPad  = [mYScale minPad];
	double aMinPadx = [mXScale minPad];
	float height	= [plotView bounds].size.height;
	float width		= [plotView bounds].size.width;
	float chanWidth = width / [mXScale valueRange];
	double x,xl,y,yl;
	
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

		long minChan = MAX(0,[roi minChannel]);
		long maxChan = MIN([roi maxChannel],numPoints-1);
		NSColor* fillColor = [[self lineColor] highlightWithLevel:.7];
		fillColor = [fillColor colorWithAlphaComponent:.3];
		[fillColor set];
		
		x	= [mXScale getPixAbs:minChan]-chanWidth/2.;
		xl	= x;
		double xValue,yValue;
		[dataSource plotter:self index:minChan x:&xValue y:&yValue];
		yl	= [mYScale getPixAbs:yValue];
		long ix;
		for (ix=minChan; ix<=maxChan+1;++ix) {
			double xValue;
			double yValue;
			[dataSource plotter:self index:ix x:&xValue y:&yValue];

			x = [mXScale getPixAbsFast:ix log:NO integer:YES minPad:aMinPadx] - chanWidth/2.;
			y = [mYScale getPixAbsFast:yValue log:aLog integer:aInt minPad:aMinPad];
			[NSBezierPath fillRect:NSMakeRect(xl,1,x-xl+1,yl)];
			xl = x;
			yl = y;
		}	
	}
	
	//draw the data 
	int minX = MAX(0,roundToLong([mXScale minValue]));
	int maxX = MIN(roundToLong([mXScale maxValue]+1),numPoints);
	x  = [mXScale getPixAbs:minX]-chanWidth/2.;
	xl = x;
	double xValue,yValue;
	[dataSource plotter:self index:minX x:&xValue y:&yValue];
	yl = [mYScale getPixAbs:yValue];

	if([self useConstantColor] || [plotView topPlot] == self)	[[self lineColor] set];
	else [[[self lineColor] highlightWithLevel:.5]set];

	NSBezierPath* theDataPath = [NSBezierPath bezierPath];
	[theDataPath setLineWidth:[self lineWidth]];
	
	long ix;
	for (ix=minX; ix<maxX;++ix) {	
		[dataSource plotter:self index:ix x:&xValue y:&yValue];
		x = [mXScale getPixAbsFast:ix log:NO integer:YES minPad:aMinPadx] + chanWidth/2.;
		y = [mYScale getPixAbsFast:yValue log:aLog integer:aInt minPad:aMinPad];
		[theDataPath moveToPoint:NSMakePoint(xl,yl)];
		[theDataPath lineToPoint:NSMakePoint(xl,y)];
		[theDataPath lineToPoint:NSMakePoint(x,y)];
		xl = x;
		yl = y;
	}
	[theDataPath stroke];
	
	//draw the roi bounds
	if(roi && roiVisible){
		long minChan = MAX(0,[roi minChannel]);
		long maxChan = MIN([roi maxChannel],[mXScale maxLimit]);
		
		[[NSColor redColor] set];
		[NSBezierPath setDefaultLineWidth:.5];
		float x1 = [mXScale getPixAbsFast:minChan log:NO integer:YES minPad:aMinPadx] - chanWidth/2.;
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,0) toPoint:NSMakePoint(x1, height)];
		float x2 = [mXScale getPixAbsFast:maxChan log:NO integer:YES minPad:aMinPadx] + chanWidth/2.;
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x2,0) toPoint:NSMakePoint(x2, height)];
	}
	if(roiVisible){
		[[roi fit] drawFit:plotView];
		
	}
}

- (void) drawExtras 
{		
	NSAssert([NSThread mainThread],@"ORAxis drawing from non-gui thread");
	NSString* positionString; 
	NSAttributedString* s;
	NSSize labelSize;
	
	float height = [plotView bounds].size.height;
	float width  = [plotView bounds].size.width;
	NSDictionary* attrsDictionary = [plotView textAttributes];
	
	if(roiDragInProgress){
		positionString = [NSString stringWithFormat:@"Min: %ld",[roi minChannel]];
		s			   = [[NSAttributedString alloc] initWithString:positionString attributes:attrsDictionary];
		labelSize = [s size];
		[s drawAtPoint:NSMakePoint(width - labelSize.width - 10,height-labelSize.height-5)];
		[s release];
		positionString = [NSString stringWithFormat:@"Max: %ld",[roi maxChannel]];
		s			   = [[NSAttributedString alloc] initWithString:positionString attributes:attrsDictionary];
		labelSize = [s size];
		[s drawAtPoint:NSMakePoint(width - labelSize.width - 10,height-2*labelSize.height-5)];
		[s release];
	}
		
	else [super drawExtras];
}

#pragma mark ***Conversions
- (NSPoint) convertFromWindowToPlot:(NSPoint)aWindowLocation
{
	ORAxis* mXScale = [plotView xScale];
	ORAxis* mYScale = [plotView yScale];
	float width		= [plotView bounds].size.width;
	float chanWidth = width / [mXScale valueRange];
	NSPoint p = [plotView convertPoint:aWindowLocation fromView:nil];
	NSPoint result;
	result.x = floor([mXScale getValAbs:p.x + chanWidth/2.]);
	result.y = [mYScale getValAbs:p.y];
	return result;
}

			
@end					
