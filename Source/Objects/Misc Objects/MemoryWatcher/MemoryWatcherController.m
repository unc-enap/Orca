//
//  MemoryWatcherController.m
//  Orca
//
//  Created by Mark Howe on 5/13/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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

#import "MemoryWatcherController.h"
#import "MemoryWatcher.h"
#import "ORCompositePlotView.h"
#import "ORPlot.h"
#import "ORAxis.h"
#import "SynthesizeSingleton.h"

@implementation MemoryWatcherController

SYNTHESIZE_SINGLETON_FOR_CLASS(MemoryWatcherController);


- (id) init
{
    self = [super initWithWindowNibName:@"MemoryWatcher"];
    [self setWindowFrameAutosaveName:@"MemoryWatcher"];
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) awakeFromNib
{
    [self registerNotificationObservers];
    [self upTimeChanged:nil];
	[self taskIntervalChanged:nil];
	
    [[plotView xAxis] setRngLow:0.0 withHigh:200.];
    [[plotView yAxis] setRngLow:0.0 withHigh:300.];

	[[plotView xAxis] setRngLimitsLow:0.0 withHigh:4096. withMinRng:50.];
	[[plotView yAxis] setRngLimitsLow:0.0 withHigh:10000. withMinRng:50.];
	
	
	[plotView setBackgroundColor:[NSColor colorWithCalibratedRed:.9 green:1.0 blue:.9 alpha:1]];
	
	ORPlot* thePlot;
	
	thePlot = [[ORPlot alloc] initWithTag:0 andDataSource:self];
	[thePlot setLineWidth:1];
	[thePlot setLineColor:[NSColor colorWithCalibratedRed:0 green:.5 blue:0 alpha:1]];
	[thePlot setUseConstantColor:YES];
	[thePlot setName:@"CPU(%)"];
	[plotView addPlot: thePlot];
	[thePlot release];
	
	thePlot = [[ORPlot alloc] initWithTag:1 andDataSource:self];
	[thePlot setLineWidth:1];
	[thePlot setLineColor:[NSColor redColor]];
	[thePlot setUseConstantColor:YES];
	[thePlot setName:@"Memory(MB)"];
	[plotView addPlot: thePlot];
	[thePlot release];
		
	[plotView setShowLegend:YES];
	
    [plotView setNeedsDisplay:YES];

}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

	[notifyCenter addObserver : self
				selector : @selector(memoryStatsChanged:)
				name : MemoryWatcherChangedNotification
				object : watcher];

	[notifyCenter addObserver : self
				selector : @selector(upTimeChanged:)
				name : MemoryWatcherUpTimeChanged
				object : watcher];

	[notifyCenter addObserver : self
				selector : @selector(taskIntervalChanged:)
				name : MemoryWatcherTaskIntervalNotification
				object : watcher];


}

- (void)flagsChanged:(NSEvent*)inEvent
{
	[[self window] resetCursorRects];
}


- (void) taskIntervalChanged:(NSNotification*)aNote
{
    if(aNote == nil || [aNote object] == watcher){
		NSTimeInterval interval = [watcher taskInterval];
		NSString* s;
		if(interval == 1.0) s = @"Max 4096 Samples @ 1 Hz Shown";
		else s = [NSString stringWithFormat:@"Max 4096 Samples @ 1/%.0f Hz Shown",[watcher taskInterval]];
		[plotView setXLabel:s];
    }
}


- (void) memoryStatsChanged:(NSNotification*)aNote
{
    if(aNote == nil || [aNote object] == watcher){
        [plotView setNeedsDisplay:YES];
    }
}

- (void) upTimeChanged:(NSNotification*)aNote
{
    if(aNote == nil || [aNote object] == watcher){
        int days,hr,min,sec;
        NSTimeInterval elapsedTime = [watcher upTime];
        days = elapsedTime/(3600*24);
        hr = (elapsedTime - days*(3600*24))/3600;
        min =(elapsedTime - days*(3600*24) - hr*3600)/60;
        sec = elapsedTime - days*(3600*24) - hr*3600 - min*60;
        [upTimeField setStringValue:[NSString stringWithFormat:@"%d %02d:%02d:%02d",days,hr,min,sec]];
    }
}

#pragma mark ***Accessors
- (void) setMemoryWatcher:(MemoryWatcher*)aWatcher
{
    watcher = aWatcher;
}

- (int) numberPointsInPlot:(id)aPlot
{
	int theTag = (int)[aPlot tag];
	if(theTag < kNumWatchedValues) return (int)[watcher timeRateCount:theTag];
	else return 0;
}

- (void) plotter:(id)aPlot index:(int)i x:(double*)xValue y:(double*)yValue;
{
	int theTag = (int)[aPlot tag];
	if(theTag < kNumWatchedValues) *yValue =  [watcher timeRate:theTag value:i];
	else *yValue = 0;
    *xValue = i;
}

@end
