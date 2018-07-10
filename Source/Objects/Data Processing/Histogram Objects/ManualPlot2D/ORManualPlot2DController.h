//
//  ORManualPlot2DController.h
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
#import "ORDataController.h"

@class OR2dRoiController;
@class ORXYPlot;

@interface ORManualPlot2DController : ORDataController
{
	IBOutlet NSView*		roiView;
    OR2dRoiController*		roiController;
	BOOL					scheduledToUpdate;
}

#pragma mark •••Initialization
- (id) init;

#pragma mark •••Interface Management
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) dataChanged:(NSNotification*)aNote;
- (void) xTitleChanged:(NSNotification*)aNotification;
- (void) yTitleChanged:(NSNotification*)aNotification;
- (void) plotTitleChanged:(NSNotification*)aNotification;
- (NSMutableArray*) roiArrayForPlotter:(id)aPlot;
- (void) plotOrderDidChange:(id)aPlotView;
- (BOOL) plotterShouldShowRoi:(id)aPlot;
- (void) scheduledUpdate;

#pragma mark •••Actions
- (IBAction) refreshPlot:(id)sender;
- (IBAction) copy:(id)sender;
- (IBAction) logLin:(NSToolbarItem*)item;
- (IBAction) zoomIn:(id)sender;
- (IBAction) zoomOut:(id)sender;

#pragma mark •••Data Source
- (NSData*) plotter:(id)aPlotter numberBinsPerSide:(unsigned short*)xValue;
- (void) plotter:(id)aPlotter xMin:(unsigned short*)aMinX xMax:(unsigned short*)aMaxX yMin:(unsigned short*)aMinY yMax:(unsigned short*)aMaxY;

@end
