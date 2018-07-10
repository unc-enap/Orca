
//
//  ORManualPlot2DController.m
//  Orca
//
//  Created by Mark Howe on Fri Mar 23,2012.
//  Copyright (c) 2012  University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#pragma mark •••Imported Files
#import "ORManualPlot2DController.h"
#import "ORManualPlot2DModel.h"
#import "OR2DHistoPlot.h"
#import "ORPlotView.h"
#import "ORColorScale.h"
#import "OR2DRoiController.h"
#import "ORComposite2DPlotView.h"
#import "ORAxis.h"

@implementation ORManualPlot2DController
#pragma mark •••Initialization
- (id) init
{
    self = [super initWithWindowNibName:@"ManualPlot2D"];
    return self;
}
- (void) dealloc 
{
	[roiController release];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [[plotView xAxis] setRngLimitsLow:0 withHigh:256 withMinRng:5];
    [[plotView yAxis] setRngLimitsLow:0 withHigh:256 withMinRng:5];
    [[plotView zAxis] setRngLimitsLow:0 withHigh:0xffffffff withMinRng:16];
    [[plotView yAxis] setLog:NO];
	
	[plotView setBackgroundColor:[NSColor colorWithCalibratedRed:1. green:1. blue:1. alpha:1]];
	//[[(ORComposite2DPlotView*)plotView colorScale] setUseRainBow:NO];
	//[[(ORComposite2DPlotView*)plotView colorScale] setStartColor:[NSColor greenColor]];
	//[[(ORComposite2DPlotView*)plotView colorScale] setEndColor:[NSColor redColor]];
    NSSize minSize = [[self window] minSize];
    minSize.width = 335;
    minSize.height = 335;
    [[self window] setMinSize:minSize];
	
	[plotView setShowGrid: NO];
	OR2DHistoPlot* aPlot = [[OR2DHistoPlot alloc] initWithTag:0 andDataSource:self];
	[aPlot setRoi: [[model rois] objectAtIndex:0]];
	[plotView addPlot: aPlot];
	[aPlot release];
	
	roiController = [[OR2dRoiController panel] retain];
	[roiView addSubview:[roiController view]];
	
	scheduledToUpdate = NO;
	
	[self plotOrderDidChange:plotView];
}

- (void) plotOrderDidChange:(id)aPlotView
{
	id topRoi = [(ORPlotWithROI*)[aPlotView topPlot] roi];
	[roiController setModel:topRoi];
}

- (BOOL) plotterShouldShowRoi:(id)aPlot
{
	if([analysisDrawer state] == NSDrawerOpenState)return YES;
	else return NO;
}

- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];   
    
    [notifyCenter addObserver: self
                     selector: @selector(dataChanged:)
                         name: ORManualPlot2DDataChanged
                       object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(xTitleChanged:)
                         name : ORManualPlot2DModelXTitleChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(yTitleChanged:)
                         name : ORManualPlot2DModelYTitleChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(plotTitleChanged:)
                         name : ORManualPlot2DModelPlotTitleChanged
						object: model];

}


- (void) updateWindow
{
	[super updateWindow];
	[self yTitleChanged:nil];
	[self xTitleChanged:nil];
	[self plotTitleChanged:nil];
}

- (NSMutableArray*) roiArrayForPlotter:(id)aPlot
{
	return [model rois];
}

#pragma mark •••Interface Management
- (void) xTitleChanged:(NSNotification*)aNotification
{
	[plotView setXLabel:[model xTitle]];
}

- (void) yTitleChanged:(NSNotification*)aNotification
{
	[plotView setYLabel:[model yTitle]];
}

- (void) plotTitleChanged:(NSNotification*)aNotification
{
	[plotView setPlotTitle:[model plotTitle]];
}

- (void) dataChanged:(NSNotification*)aNotification
{
	if(!scheduledToUpdate){
		scheduledToUpdate = YES;
		[self performSelector:@selector(scheduledUpdate) withObject:nil afterDelay:.2];
	}
}


- (void) scheduledUpdate
{
	[plotView setNeedsDisplay:YES];
	scheduledToUpdate = NO;
}

- (void) refreshModeChanged:(NSNotification*)aNotification
{
	//we don't have refresh modes
}
- (void) pausedChanged:(NSNotification*)aNotification
{
	//we don't have paused modes
}

#pragma mark •••Actions
- (IBAction) copy:(id)sender
{
	[plotView copy:sender];
}

- (IBAction) refreshPlot:(id)sender
{
	[plotView setNeedsDisplay:YES];
}

- (IBAction) logLin:(NSToolbarItem*)item
{
	[[plotView zAxis] setLog:![[plotView zAxis] isLog]];
}

- (IBAction) zoomIn:(id)sender      
{ 
    [[plotView xAxis] zoomIn:sender];
    [[plotView yAxis] zoomIn:sender];
}

- (IBAction) zoomOut:(id)sender     
{ 
    [[plotView xAxis] zoomOut:sender];
    [[plotView yAxis] zoomOut:sender];
}

#pragma mark •••Data Source
- (NSData*) plotter:(id)aPlotter numberBinsPerSide:(unsigned short*)xValue
{
    return [model getDataSetAndNumBinsPerSize:xValue];
}

- (void) plotter:(id)aPlotter xMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY
{
    [model getXMin:aMinX xMax:aMaxX yMin:aMinY yMax:aMaxY];
}
@end


