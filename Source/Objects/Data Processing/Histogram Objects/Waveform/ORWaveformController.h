//
//  ORWaveformController.h
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
#import "ORDataController.h"
#import "ORPlot.h"
@class OR1dRoiController;
@class OR1dFitController;
@class ORFFTController;

@interface ORWaveformController : ORDataController<ORFastPlotDataSourceMethods> { //-tb- 2016-11-10 removed <ORFastPlotDataSourceMethods> as it broke KATRIN waveform plots (they need startIndex!) -tb- 
	IBOutlet NSView*		roiView;
	IBOutlet NSView*		fitView;
	IBOutlet NSView*		fftView;
	IBOutlet NSButton*		useUnsignedValuesButton;
	id						calibrationPanel;				
    OR1dRoiController*		roiController;
	OR1dFitController*		fitController;
	ORFFTController*		fftController;
}

#pragma mark ¥¥¥Initialzation
- (id)init;
- (void) awakeFromNib;

#pragma mark ¥¥¥Notifications
- (void) useUnsignedValuesChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) useUnsignedValuesAction:(id)sender;
- (IBAction) calibrate:(id)sender;

#pragma mark ¥¥¥Data Source
- (BOOL) useUnsignedValues;
- (void) plotOrderDidChange:(ORPlotView*)aPlotView;
- (BOOL) plotterShouldShowRoi:(ORPlot*)aPlot;
- (int) numberPointsInPlot:(id)aPlot;
- (void) plotter:(id)aPlot index:(int)index x:(double*)x y:(double*)y;
- (NSUInteger) plotter:(id)aPlot indexRange:(NSRange)aRange stride:(NSUInteger)stride x:(NSMutableData*)x y:(NSMutableData*)y;
- (NSMutableArray*) roiArrayForPlotter:(id)aPlot;
@end









//------------------------------------------------------------------------------------------------------------------------------------
//2017-02-15 -tb- added ORBasicWaveformController to force using the 'slow' plotting methods for KATRIN waveforms (required to take the offset index into account)
// added here for testing, will be moved to own source file after testing -tb-







@interface ORBasicWaveformController : ORDataController { //<ORFastPlotDataSourceMethods> -tb- 2016-11-10 removed <ORFastPlotDataSourceMethods> as it broke KATRIN waveform plots (they need startIndex!) -tb- 
	IBOutlet NSView*		roiView;
	IBOutlet NSView*		fitView;
	IBOutlet NSView*		fftView;
	IBOutlet NSButton*		useUnsignedValuesButton;
	id						calibrationPanel;				
    OR1dRoiController*		roiController;
	OR1dFitController*		fitController;
	ORFFTController*		fftController;
}

#pragma mark ¥¥¥Initialzation
- (id)init;
- (void) awakeFromNib;

#pragma mark ¥¥¥Notifications
- (void) useUnsignedValuesChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) useUnsignedValuesAction:(id)sender;
- (IBAction) calibrate:(id)sender;

#pragma mark ¥¥¥Data Source
- (BOOL) useUnsignedValues;
- (void) plotOrderDidChange:(id)aPlotView;
- (BOOL) plotterShouldShowRoi:(id)aPlot;
- (int) numberPointsInPlot:(id)aPlot;
- (void) plotter:(id)aPlot index:(int)index x:(double*)x y:(double*)y;
//- (NSUInteger) plotter:(id)aPlot indexRange:(NSRange)aRange stride:(NSUInteger)stride x:(NSMutableData*)x y:(NSMutableData*)y;
- (NSMutableArray*) roiArrayForPlotter:(id)aPlot;
@end



