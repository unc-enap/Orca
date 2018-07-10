//
//  ORXYPlot.m
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
//University of2DHisto Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORXYPlot.h"
#import "ORPlotView.h"
#import "ORAxis.h"
#import "ORPlotAttributeStrings.h"
#import "ORColorScale.h"
#import "OR1dFit.h"
#import "OR1dRoi.h"

#define kMaxNumRects 100

@implementation ORXYPlot

- (void) setDataSource:(id)ds
{
	if( ![ds respondsToSelector:@selector(numberPointsInPlot:)] || 
	   ![ds respondsToSelector:@selector(plotter:index:x:y:)]){
		ds = nil;
	}
	dataSource = ds;	
}

#pragma mark ***Drawing
- (void) drawData
{
	NSAssert([NSThread mainThread],@"ORXYPlot drawing from non-gui thread");
	int numPoints = [dataSource numberPointsInPlot:self];
    if(numPoints == 0) return;

	BOOL roiVisible;
	if([dataSource respondsToSelector:@selector(plotterShouldShowRoi:)]){
		roiVisible = [dataSource plotterShouldShowRoi:self] && ([plotView topPlot] == self);
	}
	else {
		roiVisible = NO;
	}
	
	ORAxis*    mXScale = [plotView xScale];
	ORAxis*    mYScale = [plotView yScale];
	
	if(roi && roiVisible){
		[roi analyzeData];
		short startGate = [roi minChannel];
		short endGate   = [roi maxChannel];
		
		float xl  = [mXScale getPixAbs:startGate];
		
		NSColor* fillColor = [[self lineColor] highlightWithLevel:.7];
		fillColor = [fillColor colorWithAlphaComponent:.3];
		[fillColor set];
	
		int i;
		double xValue,yValue;
		BOOL first = YES;
		BOOL lastPtInROI = NO;
		BOOL gotData = NO;
		NSBezierPath* theDataPath = [NSBezierPath bezierPath];
		for (i=0; i<numPoints;++i) {
			
			[dataSource plotter:self index:i x:&xValue y:&yValue];
			float x = [mXScale getPixAbs:xValue];
			float y = [mYScale getPixAbs:yValue];
			if(xValue>=startGate && xValue<=endGate){
				if(first){
					[theDataPath moveToPoint:NSMakePoint(x,0)];
					[theDataPath lineToPoint:NSMakePoint(x,y)];
					first = NO;
				}
				else {
					[theDataPath lineToPoint:NSMakePoint(x,y)];
					gotData = YES;
				}
			}
			else if(xValue>=endGate && gotData){
				[theDataPath lineToPoint:NSMakePoint(xl,y)];
				[theDataPath lineToPoint:NSMakePoint(xl,0)];
				lastPtInROI = YES;
				break;
			}
			// save previous x and y values
			xl = x;
			
		}
		if(!lastPtInROI && gotData){
			[theDataPath lineToPoint:NSMakePoint(xl,0)];
		}
		if(gotData)[theDataPath fill];
	
	}
	
	BOOL useSymbol = [self showSymbols];
	BOOL useLine   = [self showLine];
	
    NSBezierPath* theDataPath = [NSBezierPath bezierPath];

	int i;
	double xValue;
	double yValue;    
	for (i=0; i<numPoints;++i) {
		[dataSource plotter:self index:i x:&xValue y:&yValue];
		float x = [mXScale getPixAbs:xValue];
		float y = [mYScale getPixAbs:yValue];
		if(useLine){
			if(i==0)[theDataPath moveToPoint:NSMakePoint(x,y)];
			else	[theDataPath lineToPoint:NSMakePoint(x,y)];
		}
		if(useSymbol){
			NSImage* symbol;
			if([self useConstantColor] || [plotView topPlot] == self) symbol = symbolNormal;
			else													   symbol = symbolLight;
			[symbol drawAtPoint:NSMakePoint(x-kSymbolSize/2,y-kSymbolSize/2) fromRect:[symbol imageRect] operation:NSCompositeSourceOver fraction:1.0];
		}
	}
	
	if([self useConstantColor] || [plotView topPlot] == self)	[[self lineColor] set];
	else [[[self lineColor] highlightWithLevel:.5]set];
	
	if(useLine){
		[theDataPath setLineWidth:[self lineWidth]];
		[theDataPath stroke];
	}
	
	//draw the roi bounds
	if(roi && roiVisible){
		float height	= [plotView bounds].size.height;
		long minChan = MAX([mXScale minLimit],[roi minChannel]);
		long maxChan = MIN([roi maxChannel],[mXScale maxLimit]);
		
		[[NSColor redColor] set];
		[NSBezierPath setDefaultLineWidth:.5];
		float x1 = [mXScale getPixAbs:minChan];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,0) toPoint:NSMakePoint(x1, height)];
		float x2 = [mXScale getPixAbs:maxChan];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x2,0) toPoint:NSMakePoint(x2, height)];
	}
	if(roiVisible){
		[[roi fit] drawFit:plotView];
		
	}
}

- (void) drawExtras
{
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
	else if([plotView commandKeyIsDown] && showCursorPosition){
		
		int numPoints = [dataSource numberPointsInPlot:self];
		double xValue;
		double yValue;
		double y = 0;
		double x = 0;
		if(cursorPosition.x < numPoints){
			[dataSource plotter:self index:cursorPosition.x x:&xValue y:&yValue];
			x = [[plotView xScale] getPixAbs:xValue];
			y = [[plotView yScale] getPixAbs:yValue];
			
			NSString* cursorPositionString = [NSString stringWithFormat:@"x:%.0f y:%.0f",xValue,yValue];
			s = [[NSAttributedString alloc] initWithString:cursorPositionString attributes:attrsDictionary];
			labelSize = [s size];
			[s drawAtPoint:NSMakePoint(width - labelSize.width - 10,height-labelSize.height-5)];
			[s release];
			
		}
		
		[[NSColor blackColor] set];
		[NSBezierPath setDefaultLineWidth:.75];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x,0) toPoint:NSMakePoint(x,height)];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(0,y) toPoint:NSMakePoint(width,y)];
	}
	
}


#pragma mark ***Helpers

- (void) showCrossHairsForEvent:(NSEvent*)theEvent
{
	NSPoint plotPoint = [self convertFromWindowToPlot:[theEvent locationInWindow]];
	float x = plotPoint.x;
	
	//do the y position ourselves
	ORAxis* mYScale = [plotView yScale];
	NSPoint p = [plotView convertPoint:[theEvent locationInWindow] fromView:nil];
	float y = floor([mYScale getValAbs:p.y]);
	showCursorPosition = YES;
	cursorPosition = NSMakePoint(x,y);
	[plotView setNeedsDisplay:YES];
}

- (void) logLin  { [[plotView yScale] setLog:![[plotView yScale] isLog]]; }

#pragma mark ***Conversions
- (NSPoint) convertFromWindowToPlot:(NSPoint)aWindowLocation
{
	ORAxis* mXScale = [plotView xScale];
	ORAxis* mYScale = [plotView yScale];
	NSPoint p = [plotView convertPoint:aWindowLocation fromView:nil];
	NSPoint result;
	result.x = floor([mXScale getValAbs:p.x]);
	result.y = floor([mYScale getValAbs:p.y]);
	return result;
}
@end					
