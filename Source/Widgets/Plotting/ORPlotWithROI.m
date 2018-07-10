//
//  ORPlotWithROI.m
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

#import "ORPlotWithROI.h"
#import "ORPlotView.h"
#import "ORAxis.h"
#import "OR1dRoi.h"

@implementation ORPlotWithROI
#pragma mark ***Initialization 
- (void) dealloc
{
    [roi setDataSource:nil];
	[roi release];
    roi = nil; //because the super class accesses the roi indirectly later in the dealloc process
	[super dealloc];
}

- (void) setDataSource:(id)ds
{
	[roi setDataSource:ds];
	[super setDataSource:ds];
}

- (id) roi	{ return roi; }
- (void) setRoi:(id)anRoi
{
	[anRoi retain];
	[roi release];
	roi = anRoi;
	[roi setDataSource:dataSource];
	if(roi){
		NSArray* rois =  [dataSource roiArrayForPlotter:self];
		int index = [rois indexOfObject:roi];
		NSString* s;
		if([[self name] length]>0)s = [self name];
		else s = [NSString stringWithFormat:@"Plot %d",tag+1];;
		[roi setLabel:[NSString stringWithFormat:@"%@ Roi %d of %d",s,index+1,[rois count]]];
	}
}

#pragma mark ***Component Switching
- (BOOL) nextComponent
{
	if([dataSource respondsToSelector:@selector(plotterShouldShowRoi:)]){
		if(![dataSource plotterShouldShowRoi:self])return YES;
	}
	if([dataSource respondsToSelector:@selector(roiArrayForPlotter:)]){
		NSMutableArray* rois =  [dataSource roiArrayForPlotter:self];
		BOOL didWrap = NO;
		int roiIndex = [rois indexOfObject:roi];
		roiIndex++;
		if(roiIndex>=[rois count]){
			roiIndex=0;
			didWrap = YES;
		}
		[self setRoi:[rois objectAtIndex:roiIndex]];	
		return didWrap;
	}
	else return YES;
}

- (BOOL) lastComponent
{
	if([dataSource respondsToSelector:@selector(plotterShouldShowRoi:)]){
		if(![dataSource plotterShouldShowRoi:self])return YES;
	}
	if([dataSource respondsToSelector:@selector(roiArrayForPlotter:)]){
		NSArray* rois =  [dataSource roiArrayForPlotter:self];
		BOOL didWrap = NO;
		int roiIndex = [rois indexOfObject:roi]-1;
		if(roiIndex<0){
			roiIndex= [rois count]-1;
			didWrap = YES;
		}
		[self setRoi:[rois objectAtIndex:roiIndex]];
		return didWrap;
	}
	else return YES;
}

- (void) removeRoi
{
	if([dataSource respondsToSelector:@selector(roiArrayForPlotter:)]){
		NSMutableArray* rois =  [dataSource roiArrayForPlotter:self];
		if([rois count] > 1){
			[rois removeObject:roi];
			[self setRoi:[rois objectAtIndex:0]];
		}
	}
}

- (void) addRoi:(id)anRoi
{
	if([dataSource respondsToSelector:@selector(roiArrayForPlotter:)]){
		NSMutableArray* rois =  [dataSource roiArrayForPlotter:self];
		[rois addObject:anRoi];
		[self setRoi:anRoi];
	}
}
#pragma mark ***Roi Management
- (void) shiftRoiRight
{
	ORAxis* mXScale = [plotView xScale];
	if([roi maxChannel] < [mXScale maxLimit]){
		[roi shiftRight];
	}
}

- (void) shiftRoiLeft
{
	ORAxis* mXScale = [plotView xScale];
	if([roi minChannel] > [mXScale minLimit]){
		[roi shiftLeft];
	}
}

- (void) moveRoiToCenter
{
	ORAxis* mXScale = [plotView xScale];
	long numberVisibleChannels  = [mXScale maxValue] - [mXScale minValue] +1;
	long centerChannel			= [mXScale minValue] + numberVisibleChannels/2;
	[roi setMinChannel:centerChannel - numberVisibleChannels*.1];
	[roi setMaxChannel:centerChannel + numberVisibleChannels*.1];
}

#pragma mark ***Event Handling
- (BOOL) redrawEvent:(NSNotification*)aNote
{
	if([aNote object] == [self roi] || [aNote object] == [[self roi] fit]){
		return YES;
	}
	else return [super redrawEvent:aNote]; 
}

- (void) keyDown:(NSEvent*)theEvent
{
	//tab will shift to next plot curve -- shift/tab goes backward.
	unsigned short keyCode = [theEvent keyCode];
	if(keyCode == 51)	{  //delete key
        [self  removeRoi];
		[plotView orderChanged];
    }
	else if(keyCode == 124) {	//Right Arrow key
		[self shiftRoiRight];
	}
	else if(keyCode == 123) {	//Left Arrow key
		[self shiftRoiLeft];
	}
	else if(keyCode == 3) {	//'f'
		[self  moveRoiToCenter];
	}
	else  [super keyDown:theEvent];
}

- (id) roiAtPoint:(NSPoint)aPoint
{
	NSPoint plotPoint = [self convertFromWindowToPlot:aPoint];
	long mouseChannel  = plotPoint.x;
	ORAxis* mXScale = [plotView xScale];
	
	long aMinChannel = MAX([mXScale minLimit],mouseChannel-3);
	long aMaxChannel = MIN([mXScale maxLimit],mouseChannel+3);
	return [[[OR1dRoi alloc] initWithMin:aMinChannel max:aMaxChannel] autorelease];
}

#pragma mark ***Event Handling
- (BOOL) mouseDown:(NSEvent*)theEvent
{
	BOOL roiVisible = NO;
	if([dataSource respondsToSelector:@selector(plotterShouldShowRoi:)]){
		roiVisible = [dataSource plotterShouldShowRoi:self];
	}
	
	if(([theEvent modifierFlags] & NSShiftKeyMask) && !([theEvent modifierFlags] & NSCommandKeyMask)){
		id anRoi = [self roiAtPoint:[theEvent locationInWindow]];
		if(anRoi){
			[self addRoi:anRoi];
			[plotView orderChanged];
		}
	}
	
	else if(([theEvent modifierFlags] & NSCommandKeyMask) && !([theEvent modifierFlags] & NSShiftKeyMask)) {		
		[self showCrossHairsForEvent:theEvent];
		[NSCursor hide];
	}
	
	else if(roiVisible){
		roiDragInProgress = [roi mouseDown:theEvent inPlotView:plotView];
	}
	return NO;
}

- (void) mouseDragged:(NSEvent*)theEvent
{
	showCursorPosition	= NO;
	if(roiDragInProgress){
		[roi mouseDragged:theEvent inPlotView:plotView];
	}
	else [super mouseDragged:theEvent];
}

-(void)	mouseUp:(NSEvent*)theEvent
{
	if(roiDragInProgress){
		[roi mouseUp:theEvent inPlotView:plotView];
	}
	[super mouseUp:theEvent];
	roiDragInProgress = NO;
}

- (void) resetCursorRects
{
	BOOL roiVisible = NO;
	if([dataSource respondsToSelector:@selector(plotterShouldShowRoi:)]){
		roiVisible = [dataSource plotterShouldShowRoi:self];
	}
	
    if(roi && roiVisible){
		NSRect aRect;
		ORAxis* mXScale = [plotView xScale];
		float x1 = [mXScale getPixAbs:[roi minChannel]];
		float x2 = [mXScale getPixAbs:[roi maxChannel]];
		float height = [plotView bounds].size.height;
		aRect = NSMakeRect(x1-2,0,4,height);
		[plotView addCursorRect:aRect cursor:[NSCursor resizeLeftRightCursor]];
		
		aRect = NSMakeRect(x1+1,0,x2-x1-4,height);
		[plotView addCursorRect:aRect cursor:[NSCursor openHandCursor]];
		
		aRect = NSMakeRect(x2-2,0,4,height);
		[plotView addCursorRect:aRect cursor:[NSCursor resizeLeftRightCursor]];
		
		aRect = NSMakeRect(x1-2,0,x2-x1+4,height);
		[plotView addCursorRect:aRect cursor:[NSCursor arrowCursor]];
	}
	[[plotView window] enableCursorRects];
}
#pragma mark ***Drawing
- (void) drawData
{
	NSAssert([NSThread mainThread],@"ORPlotWithROI drawing from non-gui thread");

	//default is to draw to the center of each point. 
	//Subclasses can over-ride for different drawing behaviour
	if(!dataSource) return;
	
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
	double x,xl,y,yl;
	
	BOOL roiVisible;
	if([dataSource respondsToSelector:@selector(plotterShouldShowRoi:)]){
		roiVisible = [dataSource plotterShouldShowRoi:self] && ([plotView topPlot] == self);
	}
	else {
		roiVisible = NO;
	}
	
	//fill in the roi area
	if(roi && roiVisible ){
		
		[roi analyzeData];
		
		long minChan = MAX(0,[roi minChannel]);
		long maxChan = MIN([roi maxChannel],numPoints-1);
		NSColor* fillColor = [[self lineColor] highlightWithLevel:.7];
		fillColor = [fillColor colorWithAlphaComponent:.3];
		[fillColor set];
		
		x	= [mXScale getPixAbs:minChan];
		xl	= x;
		double xValue,yValue;
		[dataSource plotter:self index:minChan x:&xValue y:&yValue];
		yl	= [mYScale getPixAbs:yValue];
		long ix;
		for (ix=minChan; ix<=maxChan+1;++ix) {		
			[dataSource plotter:self index:ix x:&xValue y:&yValue];
			x = [mXScale getPixAbsFast:ix log:NO integer:YES minPad:aMinPadx];
			y = [mYScale getPixAbsFast:yValue log:aLog integer:aInt minPad:aMinPad];
			[NSBezierPath fillRect:NSMakeRect(xl,1,x-xl+1,yl)];
			xl = x;
			yl = y;
		}	
	}
	
	[super drawData];
	
	//draw the roi bounds
	if(roi && roiVisible){
		long minChan = MAX(0,[roi minChannel]);
		long maxChan = MIN([roi maxChannel],[mXScale maxLimit]);
		
		[[NSColor blackColor] set];
		[NSBezierPath setDefaultLineWidth:.5];
		float x1 = [mXScale getPixAbsFast:minChan log:NO integer:YES minPad:aMinPadx];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x1,0) toPoint:NSMakePoint(x1, height)];
		float x2 = [mXScale getPixAbsFast:maxChan log:NO integer:YES minPad:aMinPadx];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x2,0) toPoint:NSMakePoint(x2, height)];
		
		[[roi fit] drawFit:plotView];
	}

}

- (void) flagsChanged:(NSEvent *)theEvent
{
	[roi flagsChanged:theEvent];
}


@end					
