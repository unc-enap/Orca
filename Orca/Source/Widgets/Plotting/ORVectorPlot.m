//
//  ORVectorPlot.m
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

#import "ORVectorPlot.h"
#import "ORPlotView.h"
#import "ORAxis.h"

@implementation ORVectorPlot

- (void) setDataSource:(id)ds
{
	if( ![ds respondsToSelector:@selector(numberPointsInPlot:)] || 
	    ![ds respondsToSelector:@selector(plotter:index:x:y:)] ||
	    ![ds respondsToSelector:@selector(plotter:crossHairX:crossHairY:)]){
		ds = nil;
	}
	dataSource = ds;	
}

#pragma mark ***Drawing
- (void) drawData
{
	if(!dataSource) return;

	NSAssert([NSThread mainThread],@"ORVectorPlot drawing from non-gui thread");
	
	int n = [dataSource numberPointsInPlot:self];
	if(n == 0) return;
 	
	ORAxis*    mXScale = [plotView xScale];
	ORAxis*    mYScale = [plotView yScale];
	    
	double xValue;
	double yValue;
	[[self lineColor] set];
	int i;
	for(i=0;i<n;i++){
		[dataSource plotter:self index:i x:&xValue y:&yValue];        
		float x = [mXScale getPixAbs:xValue];
		float y = [mYScale getPixAbs:yValue];
		[NSBezierPath fillRect:NSMakeRect(x-1,y-1,2,2)];
	}
	
	if([dataSource plotter:self crossHairX:&xValue crossHairY:&yValue]){
		[[NSColor redColor] set];
		float x = [mXScale getPixAbs:xValue];
		float y = [mYScale getPixAbs:yValue];
		short xwidth = [plotView bounds].size.width - 1;
		short ywidth = [plotView bounds].size.height - 1;
		
		[NSBezierPath strokeLineFromPoint:NSMakePoint(0,y) toPoint:NSMakePoint(xwidth,y)];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x,0) toPoint:NSMakePoint(x,ywidth)];
	}
}

- (void) drawExtras
{
	//this type draws nothing extra
}
		  
@end					
