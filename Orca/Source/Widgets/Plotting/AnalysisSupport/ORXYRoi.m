//
//  ORXYRoi.m
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

#import "ORXYRoi.h"
#import "ORPlot.h"
#import "OR1dFit.h"
#import "ORPlotAttributeStrings.h"
#import "ORXYFit.h"

@implementation ORXYRoi

#pragma mark ***Accessors
- (void) setDataSource:(id)ds
{
 	if( ![ds respondsToSelector:@selector(numberPointsInPlot:)] || 
	    ![ds respondsToSelector:@selector(plotter:index:x:y:)]){
		ds = nil;
	}
	
	// Don't retain to avoid cycle retention problems
	dataSource = ds; 
	[fit setDataSource:ds];
}

#pragma mark ***Analysis
- (void) analyzeData
{
	if(![dataSource respondsToSelector:@selector(plotView)])return;
	id aPlotView = [dataSource plotView];
	if(![aPlotView respondsToSelector:@selector(topPlot)])return;
	id aPlot = [aPlotView topPlot];
	int numPoints = [dataSource numberPointsInPlot:aPlot];
	//init some values
	double sumY		= 0.0;
	double sumXY	= 0.0;
	double sumX2Y	= 0.0;
	float maxX		= 0;
	float minY		= 3.402e+38;
	float maxY		= -3.402e+38;
	long xStart		= [self minChannel];
	long xEnd		= [self maxChannel];
	long totalNum	= xEnd - xStart+1;
	
	int i;
	for(i=0;i<numPoints;i++){
		double x;
		double y;
		[dataSource plotter:aPlot index:i x:&x y:&y];
		if(x>=xStart && x<xEnd){
			sumY	+= y;
			sumXY	+= x*y;
			sumX2Y	+= x*x*y;

			if (y < minY) minY = y;
			if (y > maxY) {
				maxY = y;
				maxX = x;
			}
		}
	}
	
	if(totalNum){
		double theXAverage = sumXY / sumY;
		sigma	= sqrt((sumX2Y/sumY) - (theXAverage*theXAverage));
		centroid = sumXY/sumY;	
	}
	else {
		centroid = 0;
		sigma   = 0;
	}
	
	peakx    = maxX;
	peaky    = maxY;
	totalSum = sumY;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:OR1dRoiAnalysisChanged object:self];
}

- (id) makeFitObject
{
	return [[[ORXYFit alloc] init] autorelease];
}

@end
