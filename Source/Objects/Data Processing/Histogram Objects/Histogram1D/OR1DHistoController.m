//
//  OR1DHistoController.m
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
#import "OR1DHisto.h"
#import "OR1DHistoController.h"
#import "ORAxis.h"
#import "ORCalibration.h"
#import "OR1dRoiController.h"
#import "OR1dFitController.h"
#import "ORPlotView.h"
#import "ORCompositePlotView.h"
#import "OR1DHistoPlot.h"

@interface OR1DHistoController (private)
- (void) _calibrationDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
@end

@implementation OR1DHistoController

#pragma mark ¥¥¥Initialization

-(id)init
{
    self = [super initWithWindowNibName:@"OneDHisto"];
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
    [[plotView yAxis] setRngLimitsLow:0 withHigh:5E9 withMinRng:25];
    [[plotView xAxis] setRngLimitsLow:0 withHigh:[model numberBins] withMinRng:25];

	OR1DHistoPlot* histo1 = [[OR1DHistoPlot alloc] initWithTag:0 andDataSource:self];
	[histo1 setRoi: [[model rois] objectAtIndex:0]];
	[plotView addPlot: histo1];
	[histo1 release];
	
	roiController = [[OR1dRoiController panel] retain];
	[roiView addSubview:[roiController view]];

	fitController = [[OR1dFitController panel] retain];
	[fitView addSubview:[fitController view]];

	[self plotOrderDidChange:plotView];
}

- (OR1dRoiController*) roiController
{
	return roiController;
}

- (OR1dFitController*) fitController
{
	return fitController;
}

#pragma mark ¥¥¥Actions
- (IBAction) calibrate:(id)sender
{
	calibrationPanel = [[ORCalibrationPane calibrateForWindow:[self window] 
										   modalDelegate:self 
										  didEndSelector:@selector(_calibrationDidEnd:returnCode:contextInfo:)
											 contextInfo:nil] retain];
}
- (id) calibrationPanel
{
    return calibrationPanel;
}

- (IBAction) copy:(id)sender
{
	[plotView copy:sender];
}

- (id) curve:(int)c roi:(int)g
{
	return [self curve:c gate:g];
}

- (id) curve:(int)c gate:(int)g //for backward compatiblity with scripts
{
	id plot = [plotView plot:c];
	NSArray* roisForPlot = [self  roiArrayForPlotter:plot];
	if([roisForPlot count]>g){
		return [roisForPlot objectAtIndex:g];
	}
	else return nil;

}

#pragma mark ¥¥¥Data Source
- (BOOL) plotterShouldShowRoi:(id)aPlot
{
	if([analysisDrawer state] == NSDrawerOpenState)return YES;
	else return NO;
}

- (int) numberPointsInPlot:(id)aPlot
{
	return (int)[model numberBins];
}

- (void) plotter:(id)aPlot index:(int)i x:(double*)xValue y:(double*)yValue
{
	*yValue = [model value:i];
	*xValue = i;
}

- (NSMutableArray*) roiArrayForPlotter:(id)aPlot
{
	return [model rois];
}

- (void) plotOrderDidChange:(id)aPlotView
{
	id topRoi = [[aPlotView topPlot] roi];
	[roiController setModel:topRoi];
	[fitController setModel:[topRoi fit]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [model numberBins];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if([[tableColumn identifier] isEqualToString:@"Value"])return [NSNumber numberWithInteger:[model value:(uint32_t)row]];
	else return [NSNumber numberWithInteger:row];
}

@end

@implementation OR1DHistoController (private)

- (void) _calibrationDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	[calibrationPanel release];
	calibrationPanel = nil;
	[plotView setNeedsDisplay:YES];
}

@end

