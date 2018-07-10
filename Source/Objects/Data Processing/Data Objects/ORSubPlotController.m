//
//  ORSubPlotController.m
//  Orca
//
//  Created by Mark Howe on Mon Nov 03 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORSubPlotController.h"
#import "ORPlotView.h"
#import "OR1DHistoPlot.h"
#import "OR2DHistoPlot.h"
#import "ORWaveform.h"
#import "ORAxis.h"
#import "ORDataSetModel.h"
#import "ORCompositePlotView.h"

@implementation ORSubPlotController

+ (ORSubPlotController*) panel
{
    return [[[ORSubPlotController alloc] init] autorelease];
}

// This method initializes a new instance of this class which loads in nibs and facilitates the communcation between the nib and the controller of the main window.
- (id) init 
{
    if(self = [super init]){
#if !defined(MAC_OS_X_VERSION_10_9)
        [NSBundle loadNibNamed:@"PlotSubview" owner:self];
#else
        [[NSBundle mainBundle] loadNibNamed:@"PlotSubview" owner:self topLevelObjects:&topLevelObjects];
#endif
        [topLevelObjects retain];

    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [view removeFromSuperview];
    [topLevelObjects release];
    [super dealloc];
}

- (void) awakeFromNib
{
    [self registerNotificationObservers];
}

- (ORPlotView*) plotView
{
    return [plotView plotView];
}

- (void) setModel:(id)aModel
{
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    if(aModel){
        [nc postNotificationName:@"DecoderWatching" object:[aModel dataSet] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[aModel shortName],@"DataSetKey",nil]];
        
    }
    else {
        [nc postNotificationName:@"DecoderNotWatching" object:[aModel dataSet] userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[aModel shortName],@"DataSetKey",nil]];
     }

	[plotView removeAllPlots];

	if([aModel isKindOfClass:NSClassFromString(@"OR1DHisto")]){
		OR1DHistoPlot* aPlot = [[OR1DHistoPlot alloc] initWithTag:0 andDataSource:aModel];
		[plotView addPlot: aPlot];
		[aPlot release];
	}
	else if([aModel isKindOfClass:NSClassFromString(@"ORWaveform")]){
		ORPlot* aPlot = [[ORPlot alloc] initWithTag:0 andDataSource:aModel];
		[plotView addPlot: aPlot];
		[aPlot release];
	}
	else if([aModel isKindOfClass:NSClassFromString(@"OR2DHisto")]){
		OR2DHistoPlot* aPlot = [[OR2DHistoPlot alloc] initWithTag:0 andDataSource:aModel];
		[plotView addPlot: aPlot];
		[aPlot release];
	}
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self registerNotificationObservers];
    [plotView setPlotTitle:[aModel shortName]];
}

- (void) registerNotificationObservers
{

    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[notifyCenter removeObserver: self];
    [notifyCenter addObserver : self
                     selector : @selector(dataChanged:)
                         name : ORDataSetDataChanged
                       object : [[plotView topPlot] dataSource]];
 
}

- (void) dataChanged:(NSNotification*)aNotification
{
    [plotView setNeedsDisplay:YES];
}

// This method returns a pointer to the view in the nib loaded.
-(NSView*)view
{
	return view;
}

- (IBAction) centerOnPeak:(id)sender
{
   [plotView centerOnPeak:sender]; 
}

- (IBAction) autoScaleX:(id)sender
{
    [plotView autoScaleX:sender];
}
- (IBAction) autoScaleY:(id)sender
{
    [plotView autoScaleY:sender];
}

- (IBAction) toggleLog:(id)sender
{
    [[plotView yAxis] setLog:![[plotView yAxis] isLog]];
}

@end
