//
//  ORManualPlotController.h
//  Orca
//
//  Created by Mark Howe on Fri Apr 27 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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
#import "ORDataController.h"

@class OR1dRoiController;
@class OR1dFitController;
@class ORXYPlot;

@interface ORManualPlotController : ORDataController
{
    IBOutlet NSTableView* dataTableView;
	IBOutlet NSPopUpButton* col3KeyPU;
	IBOutlet NSPopUpButton* col2KeyPU;
	IBOutlet NSPopUpButton* col1KeyPU;
	IBOutlet NSPopUpButton* col0KeyPU;
	IBOutlet NSTextField*   col0LabelField;
	IBOutlet NSTextField*   col1LabelField;
	IBOutlet NSTextField*   col2LabelField;
	IBOutlet NSTextField*   col3LabelField;
	id						calibrationPanel;
    IBOutlet NSDrawer*		dataDrawer;
	IBOutlet NSView*		roiView;
	IBOutlet NSView*		fitView;
    OR1dRoiController*		roiController;
	OR1dFitController*		fitController;

}

#pragma mark •••Initialization
- (id) init;
- (void) deferredAxisSetup;

#pragma mark •••Interface Management
- (void) commentChanged:(NSNotification*)aNote;
- (void) col0TitleChanged:(NSNotification*)aNote;
- (void) col1TitleChanged:(NSNotification*)aNote;
- (void) col2TitleChanged:(NSNotification*)aNote;
- (void) col3TitleChanged:(NSNotification*)aNote;
- (void) colKey0Changed:(NSNotification*)aNote;
- (void) colKey1Changed:(NSNotification*)aNote;
- (void) colKey2Changed:(NSNotification*)aNote;
- (void) colKey3Changed:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) dataChanged:(NSNotification*)aNote;
- (void) drawDidOpen:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) refreshPlot:(id)sender;
- (IBAction) col3KeyAction:(id)sender;
- (IBAction) col2KeyAction:(id)sender;
- (IBAction) col1KeyAction:(id)sender;
- (IBAction) col0KeyAction:(id)sender;
- (IBAction) writeDataFileAction:(id)sender;
- (IBAction) calibrate:(id)sender;
- (IBAction) copy:(id)sender;

#pragma mark •••Data Source
- (void) plotOrderDidChange:(id)aPlotView;
- (BOOL) plotterShouldShowRoi:(id)aPlot;
- (NSMutableArray*) roiArrayForPlotter:(id)aPlot;
- (int) numberPointsInPlot:(id)aPlotter;
- (BOOL) plotter:(id)aPlotter index:(unsigned long)index x:(double*)xValue y:(double*)yValue;
- (int) numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;

@end
