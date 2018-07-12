//
//  ORMultiPlotController.m
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
#import "ORMultiPlotController.h"
#import "ORMultiPlot.h"
#import "ORAxis.h"
#import "ORDataSet.h"
#import "ORCalibration.h"
#import "ORPlotView.h"
#import "ORPlotWithROI.h"
#import "OR1DHistoPlot.h"
#import "ORPlotWithROI.h"
#import "OR1dRoiController.h"
#import "OR1dFitController.h"
#import "ORPlot.h"
#import "ORCompositePlotView.h"

@interface ORMultiPlotController (private)
- (void) _calibrationDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) setUpPlots;
@end

@implementation ORMultiPlotController

#pragma mark ¥¥¥Initialization

-(id)init
{
    self = [super initWithWindowNibName:@"MultiPlot"];
    return self;
}

- (void) dealloc
{
	[roiController release];
	[fitController release];
	[super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self plotNameChanged:nil];
	
	[plotView setBackgroundColor:[NSColor colorWithCalibratedRed:230/255. green:1 blue:253/255. alpha:1]];
    [[plotView yAxis] setRngLimitsLow:0 withHigh:5E9 withMinRng:25];

    [self setUpPlots];
	
	roiController = [[OR1dRoiController panel] retain];
	[roiView addSubview:[roiController view]];
	
	fitController = [[OR1dFitController panel] retain];
	[fitView addSubview:[fitController view]];
	
	[self plotOrderDidChange:plotView];
	[plotView setShowLegend:YES];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(modelRemoved:)
                         name : ORMultiPlotRemovedNotification
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(modelRecached:)
                         name : ORMultiPlotReCachedNotification
                        object: model];
        
    [notifyCenter addObserver : self
                     selector : @selector(plotNameChanged:)
                         name : ORMultiPlotNameChangedNotification
                        object: model];

    int n = (int)[model cachedCount];
    int i;
    for(i=0;i<n;i++){
        [notifyCenter addObserver : self
                         selector : @selector(dataChanged:)
                             name : ORDataSetDataChanged
                            object: [model cachedObjectAtIndex:i]];
    }
}

- (void) setModel:(id)aModel
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super setModel:aModel];
	[self setUpPlots];
    [self plotNameChanged:nil];
    [self registerNotificationObservers];
}

- (void) setLegend
{
	int i;
    for(i=0;i<[model cachedCount];i++){
        if(model && plotView){
            NSString* s = [NSString stringWithFormat:@"%@%@",i==[[plotView topPlot] tag]?@"+ ":@"  ",[model objectAtIndex:i]];
			[(ORPlot*)[plotView plotWithTag:i] setName:s];
        }
     }
	[plotView setShowLegend:YES];
}

- (void) plotNameChanged:(NSNotification*)aNote
{
    if(![model plotName]){
        [model setPlotName:@"MultiPlot"];
        [[self window] setTitle:@"MultiPlot"];
    }
    else {
        [plotNameField setStringValue:[model plotName]];
        [[self window] setTitle:[model plotName]];
    }
	[plotNameField resignFirstResponder];
}

- (void) modelRemoved:(NSNotification*)aNote
{
    if([aNote object] == model){
        [[self window] close];
    }
}

- (void) modelRecached:(NSNotification*)aNote
{
    if(([aNote object] == model) || ![aNote object]){
        [[NSNotificationCenter defaultCenter] removeObserver:self];
		[self setUpPlots];
        [self registerNotificationObservers];
    }
}

- (void) dataChanged:(NSNotification*)aNote
{
	if(!scheduledForUpdate){
        if([model dataSetInCache:[aNote object]]){
            scheduledForUpdate = YES;
            [self performSelector:@selector(postUpdate) withObject:nil afterDelay:1.0];
        }
	}
}

- (void) postUpdate
{
    [plotView setNeedsDisplay:YES];
	scheduledForUpdate = NO;
}

- (IBAction) plotNameAction:(id)sender;
{
    [model setPlotName:[sender stringValue]];
}


#pragma mark ¥¥¥Actions
- (IBAction) calibrate:(id)sender
{
	NSDictionary* aContextInfo = [NSDictionary dictionaryWithObjectsAndKeys: model, @"ObjectToCalibrate",
																	         model , @"ObjectToUpdate",
																	         nil];
	calibrationPanel = [[ORCalibrationPane calibrateForWindow:[self window] 
										   modalDelegate:self 
										  didEndSelector:@selector(_calibrationDidEnd:returnCode:contextInfo:)
											 contextInfo:aContextInfo] retain];
}

- (IBAction) copy:(id)sender
{
	[plotView copy:sender];
}

#pragma mark ¥¥¥Data Source
- (BOOL) plotterShouldShowRoi:(id)aPlot
{
	if([analysisDrawer state] == NSDrawerOpenState)return YES;
	else return NO;
}

- (void) plotOrderDidChange:(id)aPlotView
{
	ORPlotWithROI* topRoi = [(ORPlotWithROI*)[aPlotView topPlot] roi];
	[roiController setModel:topRoi];
	[fitController setModel:[topRoi fit]];
	[self setLegend];
}

- (int) numberPointsInPlot:(id)aPlot
{
	NSUInteger tag = [aPlot tag];
	if(tag<[model cachedCount]){
		return (int)[[model cachedObjectAtIndex:(int)tag] numberBins];
	}
	else return 0;
}

- (void) plotter:(id)aPlot index:(int)i x:(double*)xValue y:(double*)yValue;
{
	*xValue = (double)i;
	*yValue =  [[model cachedObjectAtIndex:(int)[aPlot tag]] value:i];
}

- (NSMutableArray*) roiArrayForPlotter:(id)aPlot
{
	return [model rois:(int)[aPlot tag]];
}
@end

@implementation ORMultiPlotController (private)

- (void) _calibrationDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	[calibrationPanel release];
	calibrationPanel = nil;
}

- (void) setUpPlots
{
	[plotView removeAllPlots];
	int n = (int)[model cachedCount];
    int i;
    for(i=0;i<n;i++){
		
		NSColor* theColor;
		switch (i%10){
			case 0: theColor = [NSColor redColor]; break;
			case 1: theColor = [NSColor blueColor]; break;
			case 2: theColor = [NSColor purpleColor]; break;
			case 3: theColor = [NSColor brownColor]; break;
			case 4: theColor = [NSColor greenColor]; break;
			case 5: theColor = [NSColor blackColor]; break;
			case 6: theColor = [NSColor cyanColor]; break;
			case 7: theColor = [NSColor orangeColor]; break;
			case 8: theColor = [NSColor magentaColor]; break;
			case 9: theColor = [NSColor yellowColor]; break;
			default: theColor = [NSColor redColor]; break;
		}
		if([[model cachedObjectAtIndex:i] isKindOfClass:NSClassFromString(@"OR1DHisto")]){
			OR1DHistoPlot* aPlot = [[OR1DHistoPlot alloc] initWithTag:i andDataSource:self];
			[aPlot setLineColor:theColor];
			[aPlot setRoi: [[model rois:i] objectAtIndex:0]];
			[plotView addPlot: aPlot];
			[aPlot release];
		}
		else if([[model cachedObjectAtIndex:i] isKindOfClass:NSClassFromString(@"ORWaveform")]){
			ORPlotWithROI* aPlot = [[ORPlotWithROI alloc] initWithTag:i andDataSource:self];
			[aPlot setLineColor:theColor];
			[aPlot setRoi: [[model rois:i] objectAtIndex:0]];
			[plotView addPlot: aPlot];
			[aPlot release];
		}
	}
	[self setLegend];
}

@end

