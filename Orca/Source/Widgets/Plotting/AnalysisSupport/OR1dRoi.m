//
//  OR1dRoi.m
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

#import "OR1dRoi.h"
#import "ORPlot.h"
#import "OR1dFit.h"
#import "ORPlotAttributeStrings.h"
#import "ORFFT.h"
#import "ORAxis.h"

NSString* OR1dRoiMinChanged		= @"OR1dRoiMinChanged";
NSString* OR1dRoiMaxChanged		= @"OR1dRoiMaxChanged";
NSString* OR1dRoiAnalysisChanged = @"OR1dRoiAnalysisChanged";
NSString* OR1dRoiCurveFitChanged = @"OR1dRoiCurveFitChanged";

@implementation OR1dRoi

#pragma mark ***Initialization
- (id) initWithMin:(int)aMin max:(int)aMax
{
	self = [super init];
	[self setMaxChannel:aMax];
	[self setMinChannel:aMin];
	[self setFit:[self makeFitObject]];
	[self setFFT:[self makeFFTObject]];
	[self setUseRoiRate:NO];
	return self;
}

- (void) dealloc
{
	[label release];
	[fit release];
	[fft release];
	[super dealloc];
}

#pragma mark ***Accessors
- (void) setDataSource:(id)ds
{
 	if( ![ds respondsToSelector:@selector(plotter:index:x:y:)]){
		ds = nil;
	}
	
	// Don't retain to avoid cycle retention problems
	dataSource = ds; 
	[fit setDataSource:ds];
	[fft setDataSource:ds];
}

- (id) dataSource 
{
    return dataSource;
}

- (void)	setLabel:(NSString*)aLabel
{
	[label autorelease];
	label = [aLabel copy];
	[[NSNotificationCenter defaultCenter] postNotificationName:OR1dRoiAnalysisChanged object:self];
}

- (NSString*) label
{
	if(!label)return @"";
	else return label;
}

- (id) fit
{
	return fit;
}

- (void) setFit:(id)aFit
{
	[aFit retain];
	[fit release];
	fit = aFit;
	[[NSNotificationCenter defaultCenter] postNotificationName:OR1dFitChanged object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPlotViewRedrawEvent object:self];
}

- (id) fft
{
	return fft;
}

- (void) setFFT:(id)aFFT
{
	[aFFT retain];
	[fft release];
	fft = aFFT;
}

- (long) minChannel
{
    return minChannel;
}
- (void) setDefaultMin:(long)aMinChannel max:(long)aMaxChannel
{
	[self setMinChannel:aMinChannel];
	[self setMaxChannel:aMaxChannel];
}
- (void) setMinChannel:(long)aChannel
{
	minChannel = aChannel;
    [[NSNotificationCenter defaultCenter] postNotificationName:OR1dRoiMinChanged object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPlotViewRedrawEvent object:self];
}

- (long) maxChannel
{
    return maxChannel;
}

- (void) setMaxChannel:(long)aChannel
{
	maxChannel = aChannel;
    [[NSNotificationCenter defaultCenter] postNotificationName:OR1dRoiMaxChanged object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORPlotViewRedrawEvent object:self];
}


//these we just set in the anaysis and put out a general notification. 
//Interested objects can just grab the values with the following accessors
- (double)	average		{return centroid; }
- (double)	centroid	{return centroid; }
- (double)	sigma		{return sigma; }
- (double)	totalSum	{return totalSum; }
- (double)  peaky		{return peaky; }
- (double)  peakx		{return peakx; }
- (void)	setCentroid:(double)aValue { centroid = aValue; }
- (void)	setSigma:(double)aValue    { sigma = aValue; }
- (void)	setTotalSum:(double)aValue { totalSum = aValue; }
- (void)	setPeaky:(double)aValue    { peaky = aValue; }
- (void)	setPeakx:(double)aValue    { peakx = aValue; }

- (double)	roiRate 
{
	if([gOrcaGlobals runInProgress]){
		if(rateValid)return roiRate;
		else		return 0;
	}
	else {
		rateValid = NO;
		return 0;
	}
}

- (BOOL)	useRoiRate { return useRoiRate; }
- (void)	setUseRoiRate:(BOOL)aState
{
	useRoiRate = aState;
}


#pragma mark ***Analysis
- (void) analyzeData
{
	if(![dataSource respondsToSelector:@selector(plotView)])return;
	id aPlotView = [dataSource plotView];
	if(![aPlotView respondsToSelector:@selector(topPlot)])return;
	id aPlot = [aPlotView topPlot];
	
	//init some values
	double sumY		= 0.0;
	double sumXY	= 0.0;
	double sumX2Y	= 0.0;
	double maxX		= 0;
	double minY		= 3.402e+38;
	double maxY		= -3.402e+38;
	long xStart		= [self minChannel];
	long xEnd		= [self maxChannel];
	
	long x = xStart;
	do {
		double xDummy,y;
		[dataSource plotter:aPlot index:x x:&xDummy y:&y];
		sumY	+= y;
		sumXY	+= x*y;
		sumX2Y	+= x*x*y;
		
		if (y < minY) minY = y;
		if (y > maxY) {
			maxY = y;
			maxX = x;
		}
		++x;
	} while(x<=xEnd);
	
	
	if(sumY){
		double theXAverage = sumXY / sumY;
		sigma	 = sqrt((sumX2Y/sumY) - (theXAverage*theXAverage));
		centroid = theXAverage;
	}
	else {
		sigma   = 0;
		centroid = 0;
	}
	
	peakx	 = maxX;
	peaky	 = maxY;
	totalSum = sumY;
	
	if(useRoiRate){
		if(!rateValid){
			lastSum = totalSum;
			tLast   = [NSDate timeIntervalSinceReferenceDate];
			rateValid = YES;
		}
		else {
			if(totalSum != lastSum){
				tCurrent = [NSDate timeIntervalSinceReferenceDate];
				NSTimeInterval deltaTime = tCurrent - tLast;
				if(deltaTime>1){
					roiRate = (totalSum-lastSum)/(tCurrent - tLast);
					lastSum = totalSum;
					tLast = tCurrent;
				}
			}
		}
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:OR1dRoiAnalysisChanged object:self];
}

#pragma mark ***Event Handling
- (void) flagsChanged:(NSEvent *)theEvent
{
}

- (BOOL) mouseDown:(NSEvent*)theEvent inPlotView:(ORPlotView*)aPlotter
{
	gate1 = minChannel;
	gate2 = maxChannel;
	NSEventType modifierKeys = [theEvent modifierFlags];
	if((modifierKeys & NSCommandKeyMask) != NSCommandKeyMask){
		
		NSPoint p = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
		ORAxis* xScale = [aPlotter xScale];
		int mouseChan = floor([xScale convertPoint:p.x]+.5);
		startChan = mouseChan;
		
		if(([theEvent modifierFlags] & NSAlternateKeyMask) || (gate1 == 0 && gate2 == 0)){
			dragType = kInitialDrag;
			gate1 = mouseChan;
			gate2 = gate1;
			[self setMinChannel:MIN(gate1,gate2)];
			[self setMaxChannel:MAX(gate1,gate2)];
		}
		else if(!([theEvent modifierFlags] & NSCommandKeyMask)){
			if(fabs([xScale getPixAbs:startChan]-[xScale getPixAbs:[self minChannel]])<3){
				dragType = kMinDrag;
				gate1 = [self maxChannel];
				gate2 = [self minChannel];
			}
			else if(fabs([xScale getPixAbs:startChan]-[xScale getPixAbs:[self maxChannel]])<3){
				dragType = kMaxDrag;
				gate1 = [self minChannel];
				gate2 = [self maxChannel];
			}
			else if([xScale getPixAbs:startChan]>[xScale getPixAbs:[self minChannel]] && [xScale getPixAbs:startChan]<[xScale getPixAbs:[self maxChannel]]){
				dragType = kCenterDrag;
			}
			else dragType = kNoDrag;
		}
		else if(([theEvent modifierFlags] & NSCommandKeyMask) &&
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
		rateValid = NO;
        ORAxis* xScale = [aPlotter xScale];
        NSPoint p = [aPlotter convertPoint:[theEvent locationInWindow] fromView:nil];
        int delta;
        int mouseChan = ceil([xScale convertPoint:p.x]+.5);
        switch(dragType){
            case kInitialDrag:
                gate2 = mouseChan;
   				if(gate2<0 && ![xScale allowNegativeValues]) break;
				[self setMinChannel:MIN(gate1,gate2)];
                [self setMaxChannel:MAX(gate1,gate2)];
				break;
				
            case kMinDrag:
				gate2 = mouseChan;
   				if(gate2<0 && ![xScale allowNegativeValues]) break;
				[self setMinChannel:MIN(gate1,gate2)];
                [self setMaxChannel:MAX(gate1,gate2)];
				break;
				
            case kMaxDrag:
                gate2 = mouseChan;
   				if(gate2<0 && ![xScale allowNegativeValues]) break;
				[self setMinChannel:MIN(gate1,gate2)];
                [self setMaxChannel:MAX(gate1,gate2)];
				break;
				
            case kCenterDrag:
                delta = startChan-mouseChan;
                int new1 = gate1 - delta;
                int new2 = gate2 - delta;
                //int w = abs(new1-new2-1);
				if(![xScale allowNegativeValues]){
					if(new1 < 0 || new2<0) break;
				}
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
    
    [self setMinChannel:[decoder decodeInt32ForKey:@"minChannel"]];
    [self setMaxChannel:[decoder decodeInt32ForKey:@"maxChannel"]];
	[self setFit:[decoder decodeObjectForKey:@"fit"]];
	[self setFFT:[decoder decodeObjectForKey:@"fft"]];
	if(!fit)[self setFit:[self makeFitObject]];
	if(!fft)[self setFFT:[self makeFFTObject]];

    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt32:minChannel forKey:@"minChannel"];
    [encoder encodeInt32:maxChannel forKey:@"maxChannel"];
	[encoder encodeObject:fit forKey:@"fit"];
	[encoder encodeObject:fft forKey:@"fft"];
}

@end
