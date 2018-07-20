//
//  OR2dRoi.m
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

#import "OR2dRoi.h"
#import "ORPlot.h"
#import "ORPlotView.h"
#import "ORPlotAttributeStrings.h"
#import "ORAxis.h"

NSString* OR2dRoiMinChanged		= @"OR2dRoiMinChanged";
NSString* OR2dRoiMaxChanged		= @"OR2dRoiMaxChanged";
NSString* OR2dRoiAnalysisChanged = @"OR2dRoiAnalysisChanged";
NSString* OR2dRoiCurveFitChanged = @"OR2dRoiCurveFitChanged";

@implementation OR2dRoi

#pragma mark ***Initialization
- (id) initAtPoint:(NSPoint)aPoint
{
	self = [super init];
	[self setPoints:[NSMutableArray array]];
	float x1 = MAX(0,aPoint.x-25);
	float y1 = MAX(0,aPoint.y-25);
	float x2 = aPoint.x+25;
	float y2 = aPoint.y+25;

	[points addObject: [ORPoint point:NSMakePoint(x1,y1)]];
	[points addObject: [ORPoint point:NSMakePoint(x1,y2)]];
	[points addObject: [ORPoint point:NSMakePoint(x2,y2)]];
	[points addObject: [ORPoint point:NSMakePoint(x2,y1)]];
	drawControlPoints = NO;
	return self;

}

- (void) dealloc
{
	[label release];
	[points release];
	[theRoiPath release];
	[super dealloc];
}
- (id) fit { return nil; }
- (id) fft { return nil; }

#pragma mark ***Accessors
- (void) setDataSource:(id)ds
{
 	if(![ds respondsToSelector:@selector(plotter:numberBinsPerSide:)] ||
	   ![ds respondsToSelector:@selector(plotter:xMin:xMax:yMin:yMax:)]){
		ds = nil;
	}
	// Don't retain to avoid cycle retention problems
	dataSource = ds; 
}
- (void)	setLabel:(NSString*)aLabel
{
	[label autorelease];
	label = [aLabel copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:OR2dRoiAnalysisChanged object:self];
}

- (NSString*) label
{
	return label;
}
- (id)		dataSource	{ return dataSource; }
- (double)	average		{ return average; }
- (int)		peakx		{ return peakx; }
- (int)		peaky		{ return peaky; }
- (double)	totalSum	{ return totalSum; }
- (NSArray*) points		{ return points; }

- (void) setPoints:(NSMutableArray*)somePoints
{
	[somePoints retain];
	[points release];
	points = somePoints;
}

#pragma mark ***Analysis
- (void) analyzeData
{
	if(![dataSource respondsToSelector:@selector(plotView)])return;
	id aPlotView = [dataSource plotView];
	if(![aPlotView respondsToSelector:@selector(topPlot)])return;
	id aPlot = [aPlotView topPlot];
		
	NSBezierPath* channelPath = [NSBezierPath bezierPath];
	
	int n = (int)[points count];
	int i;
	
	if(n){
		//make a path that is in the channel coords		
		[channelPath moveToPoint:[[points objectAtIndex:0] xyPosition]];
		for(i=1;i<n;i++)[channelPath lineToPoint:[[points objectAtIndex:i] xyPosition]];
		[channelPath lineToPoint:[[points objectAtIndex:0] xyPosition]];
		[channelPath closePath];
		
		unsigned short numBinsPerSide;
		NSData* data = [dataSource plotter:aPlot numberBinsPerSide:&numBinsPerSide];
		uint32_t* dataPtr = (uint32_t*)[data bytes];
		int32_t sumVal  = 0;
		int32_t maxVal  = 0;
		int32_t xLoc    = 0;
		int32_t yLoc    = 0;
		float aveVal = 0;
		
		NSRect gateBounds = [channelPath bounds];
		unsigned short dataXMin,dataXMax,dataYMin,dataYMax;
		[dataSource plotter:aPlot xMin:&dataXMin xMax:&dataXMax yMin:&dataYMin yMax:&dataYMax];
		int32_t xStart = MAX(gateBounds.origin.x,dataXMin);
		int32_t xEnd   = MIN(gateBounds.origin.x + gateBounds.size.width,dataXMax);
		
		int32_t yStart = MAX(gateBounds.origin.y,dataYMin);
		int32_t yEnd   = MIN(gateBounds.origin.y + gateBounds.size.height,dataYMax);
		

		int32_t x,y;
		int32_t count = 0;
		for (y=yStart; y<yEnd; ++y) {
			for (x=xStart; x<xEnd; ++x) {
				if([channelPath containsPoint:NSMakePoint(x,y)]){
					++count;
					uint32_t z = dataPtr[x + y*numBinsPerSide];
					if(z > maxVal){
						maxVal = z;
						xLoc = x;
						yLoc = y;
					}
					sumVal += z;
				}
			}
		}
		if(count>0)aveVal = sumVal/(float)count;
		else aveVal = 0;
		
		average	 = aveVal;
		totalSum = sumVal;
		peakx	 = xLoc;
		peaky	 = yLoc;
	}

	
	[[NSNotificationCenter defaultCenter] postNotificationName:OR2dRoiAnalysisChanged object:self];
}

#pragma mark ***Event Handling
- (void)flagsChanged:(NSEvent *)theEvent
{
	cmdKeyIsDown = ([theEvent modifierFlags] & NSEventModifierFlagControl)!=0;
	optionKeyIsDown = ([theEvent modifierFlags] & NSEventModifierFlagOption)!=0;
	if(cmdKeyIsDown) drawControlPoints = !drawControlPoints;	
}

- (BOOL) mouseDown:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotter
{
	mouseIsDown = YES;
	selectedPoint = nil;
	dragInProgress = NO;
	NSPoint localPoint = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
	if(drawControlPoints || optionKeyIsDown) {
		dragWholePath = NO;
		for(ORPoint* aPoint in points){
			
			float x = [[aPlotter xScale] getPixAbs:[aPoint xyPosition].x];
			float y = [[aPlotter yScale] getPixAbs:[aPoint xyPosition].y];
			NSRect pointframe = NSMakeRect(x-kPointSize/2,y-kPointSize/2, kPointSize,kPointSize);
			
			if(NSPointInRect(localPoint ,pointframe)){
				selectedPoint = aPoint;
				dragInProgress = YES;
				if(optionKeyIsDown){
					ORPoint* p = [[ORPoint alloc] initWithPoint:[selectedPoint xyPosition]];
					[points insertObject:p atIndex:[points indexOfObject: selectedPoint]+1];
					selectedPoint = p;
					[p release];
					break;
				}
			}
		}
		
		[aPlotter setNeedsDisplay:YES];	
	}
	
	if(!selectedPoint){
		if([theRoiPath containsPoint:localPoint]){
			dragStartPoint.y = [[aPlotter yScale] getValAbs:localPoint.y];
			dragStartPoint.x = [[aPlotter xScale] getValAbs:localPoint.x];
			
			dragWholePath = YES;
			dragInProgress = YES;
		}
	}
	return dragInProgress;
}

- (void) mouseDragged:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotter
{
	if(dragInProgress){
		NSPoint localPoint = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
		localPoint.y = [[aPlotter yScale] getValAbs:localPoint.y];
		localPoint.x = [[aPlotter xScale] getValAbs:localPoint.x];
		if(selectedPoint){
			[selectedPoint setXyPosition:localPoint];
		}
		else if(dragWholePath){
			float deltaX = localPoint.x - dragStartPoint.x;
			float deltaY = localPoint.y - dragStartPoint.y;
			for(ORPoint* aPoint in points){
				float x = [aPoint xyPosition].x + deltaX;
				float y = [aPoint xyPosition].y + deltaY;
				[aPoint setXyPosition:NSMakePoint(x,y)];
			}
			dragStartPoint = localPoint;
		}
		[theRoiPath release];
		theRoiPath = nil;

		[aPlotter setNeedsDisplay:YES];	
	}
}
- (void) mouseUp:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotter
{
	mouseIsDown = NO;
	dragInProgress = NO;
	NSPoint localPoint = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
	if(selectedPoint){

		localPoint.y = [[aPlotter yScale] getValAbs:localPoint.y];
		localPoint.x = [[aPlotter xScale] getValAbs:localPoint.x];
		[selectedPoint setXyPosition:localPoint];
		
		NSPoint theSelectedPoint = NSMakePoint([[aPlotter xScale] getPixAbs:[selectedPoint xyPosition].x],[[aPlotter yScale] getPixAbs:[selectedPoint xyPosition].y]);
		for(ORPoint* aPoint in points){
			if(aPoint != selectedPoint){
				float x = [[aPlotter xScale] getPixAbs:[aPoint xyPosition].x];
				float y = [[aPlotter yScale] getPixAbs:[aPoint xyPosition].y];
				NSRect pointframe = NSMakeRect(x-kPointSize/2,y-kPointSize/2, kPointSize,kPointSize);
				if(NSPointInRect(theSelectedPoint ,pointframe)){
					if([points count]>3)[points removeObject:aPoint];
					break;
				}
			}
		}
	}
	
	dragWholePath = NO;
	selectedPoint = nil;
	
	[theRoiPath release];
	theRoiPath = nil;
	
	[aPlotter setNeedsDisplay:YES];	

}

- (void) shiftRight
{
	for(ORPoint* aPoint in points){
		float x = [aPoint xyPosition].x + 1;
		float y = [aPoint xyPosition].y;
		[aPoint setXyPosition:NSMakePoint(x,y)];
	}
}
- (void) shiftUp
{
	for(ORPoint* aPoint in points){
		float x = [aPoint xyPosition].x ;
		float y = [aPoint xyPosition].y+ 1;
		[aPoint setXyPosition:NSMakePoint(x,y)];
	}
}
- (void) shiftLeft
{
	for(ORPoint* aPoint in points){
		float x = [aPoint xyPosition].x - 1;
		float y = [aPoint xyPosition].y;
		[aPoint setXyPosition:NSMakePoint(x,y)];
	}
}

- (void) shiftDown
{
	for(ORPoint* aPoint in points){
		float x = [aPoint xyPosition].x ;
		float y = [aPoint xyPosition].y- 1;
		[aPoint setXyPosition:NSMakePoint(x,y)];
	}
}

- (void) centerOnX:(double)centerX y:(double) centerY
{
	double aveX = 0;
	double aveY = 0;
	for(ORPoint* aPoint in points){
		aveX += [aPoint xyPosition].x ;
		aveY += [aPoint xyPosition].y;
	}
	int count = (int)[points count];
	if(count){
		
		double deltaX = centerX - aveX/(double)count;
		double deltaY = centerY - aveY/(double)count;
	
		for(ORPoint* aPoint in points){
			float x = [aPoint xyPosition].x ;
			float y = [aPoint xyPosition].y;
			[aPoint setXyPosition:NSMakePoint(x+deltaX,y+deltaY)];
		}
	}
}

#pragma mark ***Drawing
- (void) drawRoiInPlot:(ORPlotView*)aPlot
{
	ORAxis* yAxis = [aPlot yScale];
	ORAxis* xAxis = [aPlot xScale];
	
	if(drawControlPoints){
		[points makeObjectsPerformSelector:@selector(drawPointInPlot:) withObject:aPlot];
	}
	else {
		drawControlPoints = NO;
	}
	
	[theRoiPath release];
	theRoiPath = [[NSBezierPath bezierPath] retain];

	int n = (int)[points count];
	int i;
	
	NSPoint aPoint = [[points objectAtIndex:0] xyPosition];
	NSPoint aConvertedPoint1 = NSMakePoint([xAxis getPixAbs:aPoint.x],
										   [yAxis getPixAbs:aPoint.y]);
	
	[theRoiPath moveToPoint:aConvertedPoint1];
	
	for(i=1;i<n;i++){
		NSPoint aPoint = [[points objectAtIndex:i] xyPosition];
		NSPoint aConvertedPoint = NSMakePoint([xAxis getPixAbs:aPoint.x],
											  [yAxis getPixAbs:aPoint.y]);
		[theRoiPath lineToPoint:aConvertedPoint];
	}
	[theRoiPath lineToPoint:aConvertedPoint1];
	
	
	[[NSColor redColor] set];
	[theRoiPath setLineWidth:1];
	[theRoiPath stroke];
	
}

#pragma mark ***Archival
- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeObject:points forKey:@"points"];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
	[self setPoints:[coder decodeObjectForKey:@"points"]];    
    return self;
}
@end


@implementation ORPoint

NSString* ORPointChanged = @"ORPointChanged";

+ (id) point:(NSPoint)aPoint
{
	return [[[ORPoint alloc] initWithPoint:aPoint] autorelease];
}

- (id) initWithPoint:(NSPoint)aPoint
{
	self=[super init];
	[self setXyPosition:aPoint];
	return self;
}

- (NSPoint) xyPosition
{
	return xyPosition;
}

- (void) setXyPosition:(NSPoint)aPoint
{
	xyPosition = aPoint;
}

- (BOOL) containsPoint:(NSPoint)aPoint 
{
	NSRect r = NSMakeRect(xyPosition.x-3,xyPosition.y-kPointSize/2,kPointSize,kPointSize);
	return NSPointInRect(aPoint,r);
}

- (void) drawPointInPlot:(ORPlotView*)aPlotter
{
	NSPoint aConvertedPoint = NSMakePoint([[aPlotter xScale] getPixAbs:xyPosition.x],
										  [[aPlotter yScale] getPixAbs:xyPosition.y]);
	NSRect r = NSMakeRect(aConvertedPoint.x-3,aConvertedPoint.y-kPointSize/2,kPointSize,kPointSize);
	[[NSColor yellowColor] set];
	[NSBezierPath fillRect:r];
	[[NSColor blackColor] set];
	[NSBezierPath strokeRect:r];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
	xyPosition.x = [decoder decodeFloatForKey:@"x"];
	xyPosition.y = [decoder decodeFloatForKey:@"y"];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeFloat:xyPosition.x forKey:@"x"];
    [encoder encodeFloat:xyPosition.y forKey:@"y"];
}

@end
