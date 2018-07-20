//
//  ORWaveformController.m
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
#import "ORWaveform.h"
#import "ORWaveformController.h"
#import "OR1dRoiController.h"
#import "OR1dFitController.h"
#import "ORFFTController.h"
#import "ORAxis.h"
#import "ORPlotView.h"
#import "ORPlotWithROI.h"
#import "ORCompositePlotView.h"
#import "ORCalibration.h"

@interface ORWaveformController (private)
- (void) _calibrationDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
@end

@implementation ORWaveformController
#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Waveform"];
    return self;
}

- (void) dealloc
{
	[roiController release];
	[fitController release];
	[fftController release];
	[super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
	[[plotView yAxis] setRngLimitsLow:-5E9 withHigh:5E9 withMinRng:25];
    [[plotView xAxis] setRngLimitsLow:0 withHigh:[model numberBins] withMinRng:25];

	ORPlotWithROI* aPlot = [[ORPlotWithROI alloc] initWithTag:0 andDataSource:self];
	[plotView addPlot: aPlot];
	[aPlot setRoi: [[model rois] objectAtIndex:0]];
	[aPlot release];
	
	roiController = [[OR1dRoiController panel] retain];
	[roiView addSubview:[roiController view]];
	
	fitController = [[OR1dFitController panel] retain];
	[fitView addSubview:[fitController view]];

	fftController = [[ORFFTController panel] retain];
	[fftView addSubview:[fftController view]];

	[self plotOrderDidChange:plotView];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
	

    [notifyCenter addObserver : self
                     selector : @selector(useUnsignedValuesChanged:)
                         name : ORWaveformUseUnsignedChanged
                        object: model];

}

- (void) updateWindow
{
	[super updateWindow];
	[self useUnsignedValuesChanged:nil];
}

- (void) useUnsignedValuesChanged:(NSNotification*)aNote;
{
	[useUnsignedValuesButton setState:[model useUnsignedValues]];
}

#pragma mark ¥¥¥Actions
- (IBAction) useUnsignedValuesAction:(id)sender
{
	[model setUseUnsignedValues:[sender state]];
	[plotView setNeedsDisplay:YES];
}


#pragma mark ¥¥¥Actions
- (IBAction) copy:(id)sender
{
	[plotView copy:sender];
}

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

#pragma mark ¥¥¥Data Source

- (void) plotOrderDidChange:(ORPlot*)aPlotView
{
	id topRoi = [[aPlotView topPlot] roi];
	[roiController setModel:topRoi];
	[fitController setModel:[topRoi fit]];
	[fftController setModel:[topRoi fft]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [model numberBins];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if([[tableColumn identifier] isEqualToString:@"Value"]){
        return [NSNumber numberWithInteger:[model value:(int)row]];
	}
    else if([[tableColumn identifier] isEqualToString:@"Hex"]){
		return [NSString stringWithFormat:@"0x%x",[model value:(int)row]];
	}

	else return [NSNumber numberWithInteger:row];
}

- (BOOL) useUnsignedValues
{
	return [model useUnsignedValues];
}

- (BOOL) plotterShouldShowRoi:(ORPlot*)aPlot
{
	if([analysisDrawer state] == NSDrawerOpenState)return YES;
	else return NO;
}

- (int) numberPointsInPlot:(id)aPlot
{
	int numBins = (int)[model numberBins];
	if(numBins != [[plotView xAxis] maxLimit]){
	   [[plotView xAxis] setRngLimitsLow:0 withHigh:numBins withMinRng:25];
	}
	return numBins;
}

- (void) plotter:(id)aPlot index:(int)index x:(double*)x y:(double*)y
{
	*y =  [model value:index];
	*x = index;
}
- (NSUInteger) plotter:(id)aPlot indexRange:(NSRange)aRange stride:(NSUInteger)stride x:(NSMutableData*)x y:(NSMutableData*)y
{
    return [model plotter:aPlot indexRange:aRange stride:stride x:x y:y];
}
                          
- (NSMutableArray*) roiArrayForPlotter:(id)aPlot
{
	return [model rois];
}

@end

@implementation ORWaveformController (private)

- (void) _calibrationDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	[calibrationPanel release];
	calibrationPanel = nil;
	[plotView setNeedsDisplay:YES];
}

@end









//------------------------------------------------------------------------------------------------------------------------------------
//2017-02-15 -tb- added ORBasicWaveformController to force using the 'slow' plotting methods for KATRIN waveforms (required to take the offset index into account)
// added here for testing, will be moved to own source file after testing -tb-







@interface ORBasicWaveformController (private)
- (void) _calibrationDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
@end

@implementation ORBasicWaveformController
#pragma mark ¥¥¥Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"BasicWaveform"];
    return self;
}

- (void) dealloc
{
	[roiController release];
	[fitController release];
	[fftController release];
	[super dealloc];
}

- (void) awakeFromNib
{
    [super awakeFromNib];
	[[plotView yAxis] setRngLimitsLow:-5E9 withHigh:5E9 withMinRng:25];
    [[plotView xAxis] setRngLimitsLow:0 withHigh:[model numberBins] withMinRng:25];

	ORPlotWithROI* aPlot = [[ORPlotWithROI alloc] initWithTag:0 andDataSource:self];
	[plotView addPlot: aPlot];
	[aPlot setRoi: [[model rois] objectAtIndex:0]];
	[aPlot release];
	
	roiController = [[OR1dRoiController panel] retain];
	[roiView addSubview:[roiController view]];
	
	fitController = [[OR1dFitController panel] retain];
	[fitView addSubview:[fitController view]];

	fftController = [[ORFFTController panel] retain];
	[fftView addSubview:[fftController view]];

	[self plotOrderDidChange:plotView];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
	

    [notifyCenter addObserver : self
                     selector : @selector(useUnsignedValuesChanged:)
                         name : ORWaveformUseUnsignedChanged
                        object: model];

}

- (void) updateWindow
{
	[super updateWindow];
	[self useUnsignedValuesChanged:nil];
}

- (void) useUnsignedValuesChanged:(NSNotification*)aNote;
{
	[useUnsignedValuesButton setState:[model useUnsignedValues]];
}

#pragma mark ¥¥¥Actions
- (IBAction) useUnsignedValuesAction:(id)sender
{
	[model setUseUnsignedValues:[sender state]];
	[plotView setNeedsDisplay:YES];
}


#pragma mark ¥¥¥Actions
- (IBAction) copy:(id)sender
{
	[plotView copy:sender];
}

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

#pragma mark ¥¥¥Data Source

- (void) plotOrderDidChange:(ORPlotView*)aPlotView
{
    if([[aPlotView topPlot] isKindOfClass:NSClassFromString(@"ORPlotWithROI")]){
        id topRoi = [[(ORPlotWithROI*)aPlotView topPlot] roi];
        [roiController setModel:topRoi];
        [fitController setModel:[topRoi fit]];
        [fftController setModel:[topRoi fft]];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [model numberBins];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if([[tableColumn identifier] isEqualToString:@"Value"]){
		return [NSNumber numberWithInteger:[model value:(uint32_t)row]];
	}
    else if([[tableColumn identifier] isEqualToString:@"Hex"]){
		return [NSString stringWithFormat:@"0x%x",[model value:(uint32_t)row]];
	}

	else return [NSNumber numberWithInteger:row];
}

- (BOOL) useUnsignedValues
{
	return [model useUnsignedValues];
}

- (BOOL) plotterShouldShowRoi:(id)aPlot
{
	if([analysisDrawer state] == NSDrawerOpenState)return YES;
	else return NO;
}

- (int) numberPointsInPlot:(id)aPlot
{
	int numBins = (int)[model numberBins];
	if(numBins != [[plotView xAxis] maxLimit]){
	   [[plotView xAxis] setRngLimitsLow:0 withHigh:numBins withMinRng:25];
	}
	return numBins;
}

- (void) plotter:(id)aPlot index:(int)index x:(double*)x y:(double*)y
{
	*y =  [model value:index];
	*x = index;
}

//#if 0
//2017-02-15 -tb- commented out to force using the 'slow' plotting methods for KATRIN waveforms (required to take the offset index into account)
- (NSUInteger) plotter:(id)aPlot indexRange:(NSRange)aRange stride:(NSUInteger)stride x:(NSMutableData*)x y:(NSMutableData*)y
{
    return [model plotter:aPlot indexRange:aRange stride:stride x:x y:y];
}
//#endif
                          
- (NSMutableArray*) roiArrayForPlotter:(id)aPlot
{
	return [model rois];
}

@end

@implementation ORBasicWaveformController (private)

- (void) _calibrationDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo
{
	[calibrationPanel release];
	calibrationPanel = nil;
	[plotView setNeedsDisplay:YES];
}

@end


