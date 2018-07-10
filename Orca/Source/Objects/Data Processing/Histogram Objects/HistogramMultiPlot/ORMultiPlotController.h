//
//  ORMultiPlotController.h
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

@class OR1dRoiController;
@class OR1dFitController;

@interface ORMultiPlotController : ORDataController {
	@protected
		IBOutlet NSTextField* plotNameField;
		IBOutlet NSView*		roiView;
		IBOutlet NSView*		fitView;
		BOOL	scheduledForUpdate;
		id		calibrationPanel;
		OR1dRoiController*		roiController;
		OR1dFitController*		fitController;
}

- (id)   init;
- (void) modelRemoved:(NSNotification*)aNote;
- (void) setLegend;
- (void) postUpdate;
- (void) dataChanged:(NSNotification*)aNote;
- (void) modelRecached:(NSNotification*)aNote;
- (void) plotNameChanged:(NSNotification*)aNote;

- (IBAction) plotNameAction:(id)sender;
- (IBAction) calibrate:(id)sender;

#pragma mark ¥¥¥Data Source
- (BOOL) plotterShouldShowRoi:(id)aPlot;
- (void) plotOrderDidChange:(id)aPlotView;
- (int) numberPointsInPlot:(id)aPlot;
- (void) plotter:(id)aPlot index:(int)i x:(double*)xValue y:(double*)yValue;
- (NSMutableArray*) roiArrayForPlotter:(id)aPlot;

@end
