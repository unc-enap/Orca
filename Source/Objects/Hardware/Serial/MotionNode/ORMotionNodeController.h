//
//  ORHPMotionNodeController.h
//  Orca
//
//  Created by Mark Howe on Fri Apr 24, 2009.
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

#import "ORHPPulserController.h"

@class ORSerialPortController;
@class ORPlotView;
@class ORLongTermView;
@class ORCompositeTimeLineView;

@interface ORMotionNodeController : OrcaObjectController 
{
	IBOutlet NSButton*		startButton;
	IBOutlet NSTextField*	totalShippedField;
	IBOutlet NSTextField*	lastRecordShippedField;
	IBOutlet NSTextField*	outOfBandField;
	IBOutlet NSButton*		shipExcursionsCB;
	IBOutlet NSSlider*		shipThresholdSlider;
	IBOutlet NSTextField*	shipThresholdField;
    IBOutlet NSButton*		keepHistoryCB;
    IBOutlet NSButton*		autoStartCB;
    IBOutlet NSButton*		autoStartWithOrcaCB;
	IBOutlet NSButton*		showLongTermDeltaCB;
	IBOutlet NSTextField*   startTimeField;
	IBOutlet NSButton*		showDeltaFromAveCB;
	IBOutlet NSTextField*	temperatureField;
	IBOutlet NSButton*		stopButton;
	IBOutlet NSButton*		lockButton;
	IBOutlet NSTextField*	nodeRunningField;
	IBOutlet NSTextField*	packetLengthField;
	IBOutlet NSTextField*	isAccelOnlyField;
	IBOutlet NSTextField*	versionField;
	IBOutlet ORSerialPortController* serialPortController;
	IBOutlet ORPlotView*	tracePlot;
	IBOutlet NSMatrix*		displayComponentsMatrix;
	IBOutlet NSTextField*	xLabel;
	IBOutlet NSTextField*	yLabel;
	IBOutlet NSTextField*	zLabel;
	IBOutlet ORLongTermView*	longTermView;
	IBOutlet NSSlider*		sensitivitySlider;
	IBOutlet NSTextField*	sensitivityField;
    
    IBOutlet NSTextField*   historyFolderField;
    IBOutlet NSButton*      setHistoryFolderButton;
    IBOutlet NSButton*      viewPastHistoryButton;
    IBOutlet ORCompositeTimeLineView*   plotter0;
    
    //some cached values
    NSTimeInterval deltaTime;
    NSTimeInterval oldHistoryStartTime;
}

#pragma mark ***Interface Management
- (void) totalShippedChanged:(NSNotification*)aNote;
- (void) lastRecordShippedChanged:(NSNotification*)aNote;
- (void) outOfBandChanged:(NSNotification*)aNote;
- (void) shipExcursionsChanged:(NSNotification*)aNote;
- (void) shipThresholdChanged:(NSNotification*)aNote;
- (void) keepHistoryChanged:(NSNotification*)aNote;
- (void) autoStartChanged:(NSNotification*)aNote;
- (void) autoStartWithOrcaChanged:(NSNotification*)aNote;
- (void) showLongTermDeltaChanged:(NSNotification*)aNote;
- (void) longTermSensitivityChanged:(NSNotification*)aNote;
- (void) startTimeChanged:(NSNotification*)aNote;
- (void) showDeltaFromAveChanged:(NSNotification*)aNote;
- (void) temperatureChanged:(NSNotification*)aNote;
- (void) nodeRunningChanged:(NSNotification*)aNote;
- (void) traceIndexChanged:(NSNotification*)aNote;
- (void) packetLengthChanged:(NSNotification*)aNote;
- (void) isAccelOnlyChanged:(NSNotification*)aNote;
- (void) versionChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) updateButtons;
- (void) portStateChanged:(NSNotification*)aNote;
- (void) dispayComponentsChanged:(NSNotification*)aNote;
- (void) updateLongTermView:(NSNotification*)aNote;
- (void) updateHistoryPlot:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) shipExcursionsAction:(id)sender;
- (IBAction) shipThresholdAction:(id)sender;
- (IBAction) keepHistoryAction:(id)sender;
- (IBAction) autoStartAction:(id)sender;
- (IBAction) autoStartWithOrcaAction:(id)sender;
- (IBAction) showLongTermDeltaAction:(id)sender;
- (IBAction) longTermSensitivityAction:(id)sender;
- (IBAction) showDeltaFromAveAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) readOnboardMemory:(id)sender;
- (IBAction) readConnect:(id)sender;
- (IBAction) start:(id)sender;
- (IBAction) stop:(id)sender;
- (IBAction) displayComponentsAction:(id)sender;
- (IBAction) viewPastHistoryAction:(id)sender;
- (IBAction) setHistoryFolderAction:(id)sender;

- (int) maxLinesInLongTermView:(id)aLongTermView;
- (int) startingLineInLongTermView:(id)aLongTermView;
- (int) numLinesInLongTermView:(id)aLongTermView;
- (int) numPointsPerLineInLongTermView:(id)aLongTermView;
- (float) longTermView:(id)aLongTermView line:(int)m point:(int)i;

- (int)	numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end

