//
//  ORPlotTimeSeriesController.m
//  Orca
//
//  Created by Mark Howe on Mon Jan 06 2003.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORPlotTimeSeriesController.h"
#import "ORPlotTimeSeries.h"
#import "ORAxis.h"
#import "ORTimeSeries.h"
#import "ORPlotView.h"
#import "ORTimeSeriesPlot.h"
#import "ORCompositePlotView.h"

@implementation ORPlotTimeSeriesController

#pragma mark ¥¥¥Initialization

-(id)init
{
    self = [super initWithWindowNibName:@"PlotTimeSeries"];
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
	[[plotView yAxis]  setInteger:NO];
	[[plotView yAxis] setRngLimitsLow:-5E9 withHigh:5E9 withMinRng:25];
	
	ORTimeSeriesPlot* aPlot = [[ORTimeSeriesPlot alloc] initWithTag:0 andDataSource:self];
	[plotView addPlot: aPlot];
	[aPlot release];
	
	[self updateWindow];

}

#pragma mark ¥¥¥Actions
- (IBAction) copy:(id)sender
{
	[plotView copy:sender];
}

#pragma mark ¥¥¥Data Source
- (NSTimeInterval) plotterStartTime:(id)aPlotter
{
	return (NSTimeInterval)[[model timeSeries] startTime];
}

- (int)	numberPointsInPlot:(id)aPlotter
{
	return [[model timeSeries] count];
}

- (float)  plotter:(id) aPlotter dataValue:(int)i
{
	ORTimeSeries* ts = [model timeSeries];
	unsigned long theTime;
	double y;
	[ts index:i time:&theTime value:&y];
	return y;
}

- (void)  plotter:(id) aPlotter index:(int)i x:(double*)x y:(double*)y
{
	unsigned long theTime;
	[[model timeSeries] index:i time:&theTime value:y];
	*x = (double)theTime;
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[model timeSeries] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row
{
	if([[tableColumn identifier] isEqualToString:@"Value"])return [NSNumber numberWithFloat:[[model timeSeries] valueAtIndex:row]];
	else return [NSDate dateWithTimeIntervalSince1970:[[model timeSeries] timeAtIndex:row]];
}


@end
