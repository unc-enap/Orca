//
//  OR2DHistoPlot.m
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
//University of2DHisto Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "OR2DHistoPlot.h"
#import "OR2dRoi.h"
#import "ORPlotView.h"
#import "ORAxis.h"
#import "ORPlotAttributeStrings.h"
#import "ORColorScale.h"

#define kMaxNumRects kNumColors

@implementation OR2DHistoPlot

- (void) setDataSource:(id)ds
{
	if( ![ds respondsToSelector:@selector(plotter:numberBinsPerSide:)] ||
	   ![ds respondsToSelector:@selector(plotter:xMin:xMax:yMin:yMax:)]){
		ds = nil;
	}
	dataSource = ds;
}

#pragma mark ***Drawing
- (void) drawData
{
	if(!dataSource) return;
	
	NSAssert([NSThread mainThread],@"OR2DHistoPlot drawing from non-gui thread");
		
	ORAxis*    mXScale = [plotView xScale];
	ORAxis*    mYScale = [plotView yScale];
    ORColorScale* colorScale = [plotView colorScale];
    
    unsigned short numBinsPerSide;
    unsigned short dataXMin,dataXMax,dataYMin,dataYMax;
	NSData* data = [dataSource plotter:self numberBinsPerSide:&numBinsPerSide];
    [dataSource plotter:self xMin:&dataXMin xMax:&dataXMax yMin:&dataYMin yMax:&dataYMax];
    
    if(!data)return;
    short xwidth = [plotView bounds].size.width - 1;
    short ywidth = [plotView bounds].size.height - 1;
    
    [NSBezierPath setDefaultLineWidth:.2];
	
    /* get scale limits */
    short minX = MAX(MAX(0,roundToLong([mXScale minValue])),dataXMin);
    short maxX = MIN(MIN(roundToLong([mXScale maxValue]),numBinsPerSide),dataXMax);
	
    short minY = MAX(MAX(0,roundToLong([mYScale minValue])),dataYMin);
    short maxY = MIN(MIN(roundToLong([mYScale maxValue]),numBinsPerSide),dataYMax);
    
    /* calculate the number of channels to display */
    float xinc = xwidth / [mXScale valueRange];
    float yinc = ywidth / [mYScale valueRange];
	
    /* loop through all data in plot window */
    short rectCount[kNumColors];
    memset(rectCount,0,kNumColors*sizeof(short));
    NSRect rectList[kNumColors][kMaxNumRects];
	
	BOOL aLog       = [[colorScale colorAxis] isLog];
	BOOL aInt       = [[colorScale colorAxis] integer];
	double aMinPad  = [[colorScale colorAxis] minPad];
	uint32_t* dataPtr = (uint32_t*)[data bytes];
	int iy;
    for (iy=minY; iy<=maxY;++iy) {
        
        float y = [mYScale getPixAbs:(float)iy-.5];
		int ix;
        for (ix=minX; ix<=maxX;++ix) {	
			float x = [mXScale getPixAbs:(float)ix-.5];
            
            /* Get the data value for this point and increment to next point */
            uint32_t z = dataPtr[ix + iy*numBinsPerSide];
            if(z){
                int colorIndex = [colorScale getFastColorIndexForValue:z log:aLog integer:aInt minPad:aMinPad];
				if(colorIndex<0)colorIndex = 0;
				else if(colorIndex>kNumColors-1)colorIndex=kNumColors-1;
                rectList[colorIndex][rectCount[colorIndex]] = NSMakeRect(x-.5,y-.5,xinc+1,yinc+1);
                ++rectCount[colorIndex];
				if(rectCount[colorIndex]>=kMaxNumRects){
                    [[colorScale getColorForIndex:colorIndex] set];
                    NSRectFillList(rectList[colorIndex],rectCount[colorIndex]);
                    rectCount[colorIndex] = 0;
                }
            }
		}
    }	
    //flush rectsplotView
    int32_t i;
    for(i=0;i<kNumColors;i++){
        if(rectCount[i]){
            [[colorScale getColorForIndex:i] set];
            NSRectFillList(rectList[i],rectCount[i]);
        }
    }	
	
	BOOL roiVisible;
	if([dataSource respondsToSelector:@selector(plotterShouldShowRoi:)]){
		roiVisible = [dataSource plotterShouldShowRoi:self] && ([plotView topPlot] == self);
	}
	else {
		roiVisible = NO;
	}
	
	//draw the roi bounds
	if(roi && roiVisible){
		[roi analyzeData];
		[roi drawRoiInPlot:plotView];
	}
}

- (void) drawExtras 
{	
	NSAttributedString* s;
	NSSize labelSize;
	
	float height = [plotView bounds].size.height;
	float width  = [plotView bounds].size.width;
	NSFont* font = [NSFont systemFontOfSize:12.0];
	NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName,[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:.8],NSBackgroundColorAttributeName,nil];
	
	if([plotView commandKeyIsDown] && showCursorPosition){

		float x = MAX(0,cursorPosition.x);
		float y = MAX(0,cursorPosition.y);
		
		uint32_t z = 0;
		unsigned short dataXMin,dataXMax,dataYMin,dataYMax;
		[dataSource plotter:self xMin:&dataXMin xMax:&dataXMax yMin:&dataYMin yMax:&dataYMax];
		unsigned short numBinsPerSide;
		NSData* data = [dataSource plotter:self numberBinsPerSide:&numBinsPerSide];
        uint32_t* dataPtr = (uint32_t*)[data bytes];
		if(x>=dataXMin && x<=dataXMax && y>=dataYMin && y<=dataYMax){
			z = dataPtr[(int)x + (int)y*numBinsPerSide];
		}
		NSString* cursorPositionString = [NSString stringWithFormat:@"x:%3.0f y:%3.0f z:%u",x,y,z];
		s = [[NSAttributedString alloc] initWithString:cursorPositionString attributes:attrsDictionary];
		labelSize = [s size];
		[s drawAtPoint:NSMakePoint(width - labelSize.width - 10,height-labelSize.height-5)];
		[s release];
		
		x = [[plotView xScale] getPixAbs:x];
		y = [[plotView yScale] getPixAbs:y];
		
		[[NSColor blackColor] set];
		[NSBezierPath setDefaultLineWidth:.75];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x,0) toPoint:NSMakePoint(x,height)];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(0,y) toPoint:NSMakePoint(width,y)];
	}
}

#pragma mark ***Helpers
- (id) roiAtPoint:(NSPoint)aPoint;
{
	NSPoint p = [plotView convertPoint:aPoint fromView:nil];
	ORAxis* mXScale = [plotView xScale];
	ORAxis* mYScale = [plotView yScale];
	float chanWidth = [plotView bounds].size.width / [mXScale valueRange];
	float chanHeight = [plotView bounds].size.height / [mYScale valueRange];
	NSPoint convertedPoint = NSMakePoint([mXScale getValAbs:p.x + chanWidth/2.],[mYScale getValAbs:p.y + chanHeight/2.]);
	
	return [[[OR2dRoi alloc] initAtPoint:convertedPoint] autorelease];
}

- (void) showCrossHairsForEvent:(NSEvent*)theEvent
{
	//get the x position from the conversion method
	NSPoint plotPoint = [self convertFromWindowToPlot:[theEvent locationInWindow]];
	float x = plotPoint.x;
	
	//do the y position ourselves
	ORAxis* mYScale = [plotView yScale];
	float width		= [plotView bounds].size.width;
	float chanWidth = width / [mYScale valueRange];
	NSPoint p = [plotView convertPoint:[theEvent locationInWindow] fromView:nil];
	float y = floor([mYScale getValAbs:p.y + chanWidth/2.]);
	showCursorPosition = YES;
	cursorPosition = NSMakePoint(x,y);
	[plotView setNeedsDisplay:YES];
}

- (void) getyMin:(double*)aYMin yMax:(double*)aYMax;
{
	unsigned short minX,maxX,minY,maxY;
	[dataSource plotter:self xMin:&minX xMax:&maxX yMin:&minY yMax:&maxY];
	*aYMin = (unsigned short)minY;
	*aYMax = (unsigned short)maxY;
}

- (void) getxMin:(double*)aXMin xMax:(double*)aXMax;
{
	unsigned short minX,maxX,minY,maxY;
	[dataSource plotter:self xMin:&minX xMax:&maxX yMin:&minY yMax:&maxY];
	*aXMin = (unsigned short)minX;
	*aXMax = (unsigned short)maxX;
}

- (int32_t) maxValueChannelinXRangeFrom:(int32_t)minChannel to:(int32_t)maxChannel;
{
    double maxValue = -9E99;
	double maxXChannel = 0;
	unsigned short dataXMin,dataXMax,dataYMin,dataYMax;
    unsigned short numberBinsPerSide;
	NSData* data = [dataSource plotter:self numberBinsPerSide:&numberBinsPerSide];
    uint32_t* dataPtr = (uint32_t*)[data bytes];
	[dataSource plotter:self xMin:&dataXMin xMax:&dataXMax yMin:&dataYMin yMax:&dataYMax];
	unsigned short val = 0;
    int x,y;
	for (y=dataYMin; y<dataYMax;++y) {	
		for (x=dataXMin; x<dataXMax;++x) {	
			val = dataPtr[x+y*numberBinsPerSide];
			if(val>maxValue){
				maxValue = val;
				maxXChannel = x;
			}
		}
	}
	return maxXChannel;
}

- (float) getzMax
{
    double maxValue = -9E99;
    int x,y;
    unsigned short numberBinsPerSide;
	unsigned short dataXMin,dataXMax,dataYMin,dataYMax;
	NSData* data = [dataSource plotter:self numberBinsPerSide:&numberBinsPerSide];
    uint32_t* dataPtr = (uint32_t*)[data bytes];
	[dataSource plotter:self xMin:&dataXMin xMax:&dataXMax yMin:&dataYMin yMax:&dataYMax];
	unsigned short val = 0;
	for (y=dataYMin; y<dataYMax;++y) {	
		for (x=dataXMin; x<dataXMax;++x) {	
			val = dataPtr[x+y*numberBinsPerSide];
			if(val>maxValue)maxValue = val;
		}
	}
	return maxValue;
}

- (void) logLin  { [[plotView zScale] setLog:![[plotView zScale] isLog]]; }

- (int32_t) numberPoints
{
	unsigned short dataXMin,dataXMax,dataYMin,dataYMax;
	[dataSource plotter:self xMin:&dataXMin xMax:&dataXMax yMin:&dataYMin yMax:&dataYMax];
	return dataYMax-dataYMin;
}

- (NSString*) valueAsStringAtPoint:(int32_t)y
{		
    unsigned short numberBinsPerSide = 256; //default
    int x;
	unsigned short dataXMin,dataXMax,dataYMin,dataYMax;
	NSData* data = [dataSource plotter:self numberBinsPerSide:&numberBinsPerSide];
    uint32_t* dataPtr = (uint32_t*)[data bytes];
	[dataSource plotter:self xMin:&dataXMin xMax:&dataXMax yMin:&dataYMin yMax:&dataYMax];
	y +=  dataYMin;
	NSMutableString* s = [NSMutableString stringWithFormat:@"%d ",y];
	unsigned short val = 0;
	for (x=dataXMin; x<dataXMax;++x) {	
		val = dataPtr[x+y*numberBinsPerSide];
		[s appendFormat:@"%d ",val];
	}
	[s appendString:@"\n"];
	return s; 	
}

- (void) resetCursorRects
{
    if(roi){
		/*
        //if(!shiftKeyIsDown && !commandKeyIsDown){
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
		
		//  }
		//else {
		//  [self addCursorRect:[self bounds] cursor:[NSCursor arrowCursor]];
		//	}
		 */
    }
}
- (void) keyDown:(NSEvent*)theEvent
{
	//tab will shift to next plot curve -- shift/tab goes backward.
	unsigned short keyCode = [theEvent keyCode];
	if(keyCode == 126) {	//Up Arrow key
		[self shiftRoiUp];
	}
	else if(keyCode == 125) {	//Down Arrow key
		[self shiftRoiDown];
	}
	else if(keyCode == 3) {	//'f'
		[self  moveRoiToCenter];
	}
	else  [super keyDown:theEvent];
}

- (void) shiftRoiUp
{
	[roi shiftUp];
	[plotView setNeedsDisplay:YES];
}

- (void) shiftRoiDown
{
	[roi shiftDown];
	[plotView setNeedsDisplay:YES];
}

- (void) shiftRoiRight
{
	[roi shiftRight];
	[plotView setNeedsDisplay:YES];
}

- (void) shiftRoiLeft
{
	[roi shiftLeft];
	[plotView setNeedsDisplay:YES];
}

- (void) moveRoiToCenter
{
	ORAxis* mXScale = [plotView xScale];
	ORAxis* mYScale = [plotView yScale];
	int32_t centerX = [mXScale minValue] + ([mXScale maxValue] - [mXScale minValue] +1)/2;
	int32_t centerY = [mYScale minValue] + ([mYScale maxValue] - [mYScale minValue] +1)/2;
	[(OR2dRoi*)roi centerOnX:centerX y:centerY];
	[plotView setNeedsDisplay:YES];
}
@end					
