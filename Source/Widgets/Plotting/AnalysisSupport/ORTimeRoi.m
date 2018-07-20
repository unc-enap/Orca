//
//  ORTimeRoi.m
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

#import "ORTimeRoi.h"
#import "ORCompositePlotView.h"
#import "ORTimeLinePlot.h"
#import "ORTimeLine.h"
#import "OR1dFit.h"
#import "ORPlotAttributeStrings.h"
#import "ORFFT.h"
#import "ORAxis.h"

NSString* ORTimeRoiMinChanged		= @"ORTimeRoiMinChanged";
NSString* ORTimeRoiMaxChanged		= @"ORTimeRoiMaxChanged";
NSString* ORTimeRoiAnalysisChanged = @"ORTimeRoiAnalysisChanged";
NSString* ORTimeRoiCurveFitChanged = @"ORTimeRoiCurveFitChanged";

@implementation ORTimeRoi

#pragma mark ***Initialization
- (id) initWithMin:(int32_t)aMin max:(int32_t)aMax
{
	self = [super init];
	[self setMaxChannel:aMax];
	[self setMinChannel:aMin];
	return self;
}

- (void) dealloc
{
	[label release];
	[super dealloc];
}
- (id) fit
{
	return nil;
}
#pragma mark ***Accessors
- (void) setDataSource:(id)ds
{
 	if( ![ds respondsToSelector:@selector(plotter:index:x:y:)]){
		ds = nil;
	}
	// Don't retain to avoid cycle retention problems
	dataSource = ds; 
}

- (id) dataSource 
{
    return dataSource;
}

- (void)	setLabel:(NSString*)aLabel
{
	[label autorelease];
	label = [aLabel copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORTimeRoiAnalysisChanged object:self];
}

- (NSString*) label
{
	if(!label)return @"";
	else return label;
}

- (int32_t) minChannel
{
    return minChannel;
}

- (void) setDefaultMin:(int32_t)aMinChannel max:(int32_t)aMaxChannel
{
	[self setMinChannel:aMinChannel];
	[self setMaxChannel:aMaxChannel];
}

- (void) setMinChannel:(int32_t)aChannel
{
	minChannel = aChannel;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTimeRoiMinChanged object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPlotViewRedrawEvent object:self];
}

- (int32_t) maxChannel
{
    return maxChannel;
}

- (void) setMaxChannel:(int32_t)aChannel
{
	maxChannel = aChannel;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORTimeRoiMaxChanged object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPlotViewRedrawEvent object:self];
}


//these we just set in the anaysis and put out a general notification. 
//Interested objects can just grab the values with the following accessors
- (double)	average				{return average; }
- (double)	standardDeviation	{return standardDeviation; }
- (double)  minValue			{return minValue; }
- (double)  maxValue			{return maxValue; }

#pragma mark ***Analysis
- (void) analyzeData
{
	if(![dataSource respondsToSelector:@selector(plotView)])return;
	id aPlotView = [dataSource plotView];
	if(![aPlotView respondsToSelector:@selector(topPlot)])return;
	id aPlot = [aPlotView topPlot];
	double yDummy;
	double startingTime;
	[dataSource plotter:aPlot index:0 x:&startingTime y:&yDummy];

	double sumY				 = 0.0;
	int32_t startTimeOffset	 = [self minChannel];
	int32_t endTimeOffset		 = [self maxChannel];
	NSTimeInterval startTime = startingTime - startTimeOffset;
	NSTimeInterval endTime	 = startingTime - endTimeOffset;
	int32_t numPts				 = (uint32_t)labs(endTimeOffset-startTimeOffset);
											  
	int32_t count = 0;
	double minY = 9.9E99;
	double maxY = -9.9E99;
	if(numPts){
		
		double timeStamp,y;
		int x = 0;
		do {
			[dataSource plotter:aPlot index:x x:&timeStamp y:&y];
			if(timeStamp >= endTime && timeStamp <= startTime) {
				sumY	+= y;
				if (y < minY) minY = y;
				if (y > maxY) maxY = y;
				++count;
			}
			++x;
		} while(x<numPts);
		
		if(count){
			average = sumY / (double)count;
			double diffSum = 0;
			x = 0;
			do {
				if(timeStamp >= endTime && timeStamp <= startTime) {
					[dataSource plotter:aPlot index:x x:&timeStamp y:&y];
					diffSum += (y - average)*(y - average);
				}
				++x;
			} while(x<numPts);
			if(count>=2)standardDeviation = sqrtf((1/(double)(count-1)) * diffSum);
			else standardDeviation = 0;
		}
		else {
			average			  = 0;
			standardDeviation = 0;
		}
		maxValue = maxY;
		minValue = minY;
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:ORTimeRoiAnalysisChanged object:self];
}

#pragma mark ***Event Handling
- (void) flagsChanged:(NSEvent *)theEvent
{
}

- (BOOL) mouseDown:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotter
{
	gate1 = (int)minChannel;
	gate2 = (int)maxChannel;
	NSEventModifierFlags modifierKeys = [theEvent modifierFlags];
	if((modifierKeys & NSEventModifierFlagCommand) != NSEventModifierFlagCommand){
		
		NSPoint p = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
		ORAxis* xScale = [aPlotter xScale];
		int mouseChan = floor([xScale convertPoint:p.x]+.5);
		startChan = mouseChan;
		
		if(([theEvent modifierFlags] & NSEventModifierFlagOption) || (gate1 == 0 && gate2 == 0)){
			dragType = kInitialDrag;
			gate1 = mouseChan;
			gate2 = gate1;
			[self setMinChannel:MIN(gate1,gate2)];
			[self setMaxChannel:MAX(gate1,gate2)];
		}
		else if(!([theEvent modifierFlags] & NSEventModifierFlagCommand)){
			if(fabs([xScale getPixAbs:startChan]-[xScale getPixAbs:[self minChannel]])<3){
				dragType = kMinDrag;
				gate1 = (int)[self maxChannel];
				gate2 = (int)[self minChannel];
			}
			else if(fabs([xScale getPixAbs:startChan]-[xScale getPixAbs:[self maxChannel]])<3){
				dragType = kMaxDrag;
				gate1 = (int)[self minChannel];
				gate2 = (int)[self maxChannel];
			}
			else if([xScale getPixAbs:startChan]>[xScale getPixAbs:[self minChannel]] && [xScale getPixAbs:startChan]<[xScale getPixAbs:[self maxChannel]]){
				dragType = kCenterDrag;
			}
			else dragType = kNoDrag;
		}
		else if(([theEvent modifierFlags] & NSEventModifierFlagCommand) &&
				([xScale getPixAbs:startChan]>=[xScale getPixAbs:[self minChannel]] && [xScale getPixAbs:startChan]<=[xScale getPixAbs:[self maxChannel]])){
			dragType = kCenterDrag;
		}
		else dragType = kNoDrag;
		
		if(dragType!=kNoDrag){
			dragInProgress = YES;
			[[NSCursor closedHandCursor] push];
		}
		else dragInProgress = NO;

		[aPlotter setNeedsDisplay:YES];
		
	}
	return dragInProgress;
}

- (void) mouseDragged:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotter
{
	if(dragInProgress){
        ORAxis* xScale = [aPlotter xScale];
        NSPoint p = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
        int delta;
        int mouseChan = ceil([xScale convertPoint:p.x]+.5);
        switch(dragType){
            case kInitialDrag:
                gate2 = mouseChan;
   				if(gate2<0) break;
				[self setMinChannel:MIN(gate1,gate2)];
                [self setMaxChannel:MAX(gate1,gate2)];
				break;
				
            case kMinDrag:
                gate2 = mouseChan;
   				if(gate2<0) break;
				[self setMinChannel:MIN(gate1,gate2)];
                [self setMaxChannel:MAX(gate1,gate2)];
				break;
				
            case kMaxDrag:
                gate2 = mouseChan;
   				if(gate2<0) break;
				[self setMinChannel:MIN(gate1,gate2)];
                [self setMaxChannel:MAX(gate1,gate2)];
				break;
				
            case kCenterDrag:
                delta = startChan-mouseChan;
                int new1 = gate1 - delta;
                int new2 = gate2 - delta;
                //int w = abs(new1-new2-1);
 				if(new1 < 0 || new2<0) break;
				startChan = mouseChan;
				gate1 = new1;
				gate2 = new2;
				[self setMinChannel:MIN(gate1,gate2)];
				[self setMaxChannel:MAX(gate1,gate2)];
                
				break;
        }
        [aPlotter setNeedsDisplay:YES];
    }
}

- (void) mouseUp:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotter
{
}

- (void) shiftRight
{
	[self setMaxChannel:maxChannel+1];
	[self setMinChannel:minChannel+1];
}

- (void) shiftLeft
{
	[self setMinChannel:minChannel-1];
	[self setMaxChannel:maxChannel-1];
}

- (id) makeFitObject
{
	return [[[OR1dFit alloc] init] autorelease];
}

- (id) makeFFTObject
{
	return [[[ORFFT alloc] init] autorelease];
}

#pragma mark ***Archival

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    
    [self setMinChannel:[decoder decodeIntForKey:@"minChannel"]];
    [self setMaxChannel:[decoder decodeIntForKey:@"maxChannel"]];

    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt:minChannel forKey:@"minChannel"];
    [encoder encodeInt:maxChannel forKey:@"maxChannel"];
}

@end
