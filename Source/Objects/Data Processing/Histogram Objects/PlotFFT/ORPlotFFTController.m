//
//  ORPlotFFTController.m
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
#import "ORPlotFFTController.h"
#import "ORPlotFFT.h"
#import "ORAxis.h"
#import "ORCompositePlotView.h"
#import "ORPlotWithROI.h"
#import "ORPlotView.h"

@implementation ORPlotFFTController

#pragma mark ¥¥¥Initialization

-(id)init
{
    self = [super initWithWindowNibName:@"PlotFFT"];
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [[plotView yAxis] setRngLimitsLow:0 withHigh:5E9 withMinRng:25];
	
	ORPlotWithROI* aPlot;
	aPlot = [[ORPlotWithROI alloc] initWithTag:0 andDataSource:self];
	[plotView addPlot: aPlot];
	[aPlot setLineColor:[NSColor blueColor]];
	[aPlot release];

	aPlot = [[ORPlotWithROI alloc] initWithTag:1 andDataSource:self];
	[plotView addPlot: aPlot];
	[aPlot setLineColor:[NSColor redColor]];
	[aPlot release];

	aPlot = [[ORPlotWithROI alloc] initWithTag:2 andDataSource:self];
	[plotView addPlot: aPlot];
	[aPlot setLineColor:[NSColor blackColor]];
	[aPlot release];
		
	[self plotOrderDidChange:plotView];
	
	[self updateWindow];

}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
     [notifyCenter addObserver : self
                     selector : @selector(showChanged:)
                         name : ORPlotFFTShowChanged
                       object : model];

}

- (void) updateWindow
{
	[super updateWindow];
	[self showChanged:nil];
}

- (void) plotOrderDidChange:(id)aPlotView
{
	[aPlotView setNeedsDisplay:YES];
}

- (void) showChanged:(NSNotification*) aNote
{
	[[showMatrix cellWithTag:0] setIntValue:[model showReal]];
	[[showMatrix cellWithTag:1] setIntValue:[model showImaginary]];
	[[showMatrix cellWithTag:2] setIntValue:[model showPowerSpectrum]];
	[plotView setNeedsDisplay:YES];
}

- (IBAction) showAction:(id)sender
{
	if([[sender selectedCell] tag] == 0) [model setShowReal:[[sender selectedCell] intValue]];
	else if([[sender selectedCell] tag] == 1) [model setShowImaginary:[[sender selectedCell] intValue]];
	else [model setShowPowerSpectrum:[[sender selectedCell] intValue]];
}

- (int) numberPointsInPlot:(id)aPlotter
{
    return [model numberPointsInPlot:aPlotter];
}

- (void) plotter:(id)aPlotter index:(int)index x:(double*)xValue y:(double*)yValue
{
    return [model plotter:aPlotter index:index x:xValue y:yValue];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [model numberChans];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if([[tableColumn identifier] isEqualToString:@"Real"]){
		return [NSNumber numberWithFloat:[model plotter:nil dataSet:0 dataValue:(int)row]];
	}
	else if([[tableColumn identifier] isEqualToString:@"Imaginary"]){
		return [NSNumber numberWithFloat:[model plotter:nil dataSet:1 dataValue:(int)row]];
	}
	else if([[tableColumn identifier] isEqualToString:@"PowerSpectrum"]){
		return [NSNumber numberWithFloat:[model plotter:nil dataSet:2 dataValue:(int)row]];
	}
	else return [NSNumber numberWithInteger:row];
}

@end
