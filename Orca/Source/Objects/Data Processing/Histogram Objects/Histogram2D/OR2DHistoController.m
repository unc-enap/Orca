//
//  OR2DHistoController.m
//  Orca
//
//  Created by Mark Howe on Thurs Dec 23 2004.
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
#import "OR2DHisto.h"
#import "OR2DHistoController.h"
#import "OR2DHistoPlot.h"
#import "ORAxis.h"
#import "ORPlotView.h"
#import "OR2DRoiController.h"
#import "ORComposite2DPlotView.h"

@implementation OR2DHistoController

#pragma mark ¥¥¥Initialization

-(id)init
{
    self = [super initWithWindowNibName:@"TwoDHisto"];
    return self;
}

- (void) dealloc
{
	[roiController release];
	[super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [[plotView xAxis] setRngLimitsLow:0 withHigh:1024 withMinRng:16];
    [[plotView yAxis] setRngLimitsLow:0 withHigh:1024 withMinRng:16];
    [[plotView zAxis] setRngLimitsLow:0 withHigh:0xffffffff withMinRng:16];
    [[plotView yAxis] setLog:NO];
	
	[plotView setBackgroundColor:[NSColor colorWithCalibratedRed:1. green:1. blue:1. alpha:1]];
	
    NSSize minSize = [[self window] minSize];
    minSize.width = 335;
    minSize.height = 335;
    [[self window] setMinSize:minSize];
	[plotView setPlotTitle:[model fullNameWithRunNumber]];
	
	[plotView setShowGrid: NO];
	OR2DHistoPlot* aPlot = [[OR2DHistoPlot alloc] initWithTag:0 andDataSource:self];
	[aPlot setRoi: [[model rois] objectAtIndex:0]];
	[plotView addPlot: aPlot];
	[aPlot release];
	
	roiController = [[OR2dRoiController panel] retain];
	[roiView addSubview:[roiController view]];
	
	[self plotOrderDidChange:plotView];

}
- (NSMutableArray*) roiArrayForPlotter:(id)aPlot
{
	return [model rois];
}
- (void) dataSetChanged:(NSNotification*)aNotification
{
	//[titleField setStringValue:[model fullNameWithRunNumber]];
	[super dataSetChanged:aNotification];
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

- (IBAction) hideShowControls:(id)sender
{
    unsigned int oldResizeMask = [containingView autoresizingMask];
    [containingView setAutoresizingMask:NSViewMinYMargin];

    NSRect aFrame = [NSWindow contentRectForFrameRect:[[self window] frame] 
                styleMask:[[self window] styleMask]];
    NSSize minSize = [[self window] minSize];
    if([hideShowButton state] == NSOnState){
        aFrame.size.height += 90;
        minSize.height = 335;
    }
    else {
        aFrame.size.height -= 90;
        minSize.height = 335-90;
    }
    [[self window] setMinSize:minSize];
    [self resizeWindowToSize:aFrame.size];
    [containingView setAutoresizingMask:oldResizeMask];

}


#pragma mark ¥¥¥Actions
- (IBAction) copy:(id)sender
{
	[plotView copy:sender];
}

#pragma mark ¥¥¥Data Source
- (NSData*) plotter:(id)aPlotter numberBinsPerSide:(unsigned short*)xValue
{
    return [model getDataSetAndNumBinsPerSize:xValue];
}

- (void) plotter:(id)aPlotter xMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY
{
    [model getXMin:aMinX xMax:aMaxX yMin:aMinY yMax:aMaxY];
}

@end
