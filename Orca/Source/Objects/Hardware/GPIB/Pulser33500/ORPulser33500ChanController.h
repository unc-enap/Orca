//
//  ORPulser33500ChanController.h
//  Orca
//
//  Created by Mark Howe on Thurs, Oct 25 2012.
//  Copyright (c) 2012 University of North Carolina. All rights reserved.
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
@class ORPulser33500Controller;
@class ORCompositePlotView;

@interface ORPulser33500ChanController : NSObject
{
	id							model;
	IBOutlet ORPulser33500Controller*				owner;
    IBOutlet NSView*			controlsContent;
	IBOutlet NSBox*				controlsView;
    IBOutlet NSTextField*		voltageField;
    IBOutlet NSTextField*		voltageOffsetField;
    IBOutlet NSTextField*       frequencyField;
    IBOutlet NSTextField*       dutyCycleField;
    IBOutlet NSTextField*		burstRateField;
    IBOutlet NSTextField*		burstPhaseField;
    IBOutlet NSTextField*		burstCountField;
    IBOutlet NSTextField*		triggerTimerField;
	IBOutlet NSMatrix*			triggerSourceMatrix;
	IBOutlet NSPopUpButton*		selectedWaveformPU;
    IBOutlet NSButton*			loadParametersButton;
    IBOutlet NSButton*			triggerButton;	
    IBOutlet NSProgressIndicator* progress;
    IBOutlet NSButton*			downloadButton;	
    IBOutlet NSMatrix*			negativePulseMatrix;
    IBOutlet NSTextField*		voltageDisplay;
    IBOutlet NSTextField*		burstRateDisplay;
    IBOutlet NSTextField*		freqLabel;
    IBOutlet ORCompositePlotView*	plotter;
    IBOutlet NSButton*            burstModeCB;
    NSArray*                    topLevelObjects;
}

#pragma mark •••Initialization
- (id) model;
- (void) setModel:(id)aModel;
- (void) awakeFromNib;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) setButtonStates;
- (void) downloadWaveform;

#pragma mark ***Interface Management
- (void) updateFreqLabels;
- (void) loadConstantsChanged:(NSNotification*)aNote;
- (void) voltageChanged:(NSNotification*)aNote;
- (void) voltageOffsetChanged:(NSNotification*)aNote;
- (void) frequencyChanged:(NSNotification*)aNote;
- (void) burstModeChanged:(NSNotification*)aNote;
- (void) dutyCycleChanged:(NSNotification*)aNote;
- (void) burstRateChanged:(NSNotification*)aNote;
- (void) burstPhaseChanged:(NSNotification*)aNote;
- (void) burstCountChanged:(NSNotification*)aNote;
- (void) triggerSourceChanged:(NSNotification*)aNote;
- (void) triggerTimerChanged:(NSNotification*)aNote;
- (void) selectedWaveformChanged:(NSNotification*)aNote;
- (void) negativePulseChanged:(NSNotification*)aNote;
- (void) waveformLoadStarted:(NSNotification*)aNote;
- (void) waveformLoadProgressing:(NSNotification*)aNote;
- (void) waveformLoadFinished:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) loadParametersAction:(id)sender;
- (IBAction) selectWaveformAction:(id)sender;
- (IBAction) voltageAction:(id)sender;
- (IBAction) voltageOffsetAction:(id)sender;
- (IBAction) frequencyAction:(id)sender;
- (IBAction) dutyCycleAction:(id)sender;
- (IBAction) burstModeAction:(id)sender;
- (IBAction) burstRateAction:(id)sender;
- (IBAction) burstPhaseAction:(id)sender;
- (IBAction) burstCountAction:(id)sender;
- (IBAction) triggerSourceAction:(id)sender;
- (IBAction) triggerTimerAction:(id)sender;
- (IBAction) triggerAction:(id)sender;
- (IBAction) downloadWaveformAction:(id)sender;
- (IBAction) negativePulseAction:(id)sender;
- (IBAction) clearMemory:(id)sender;
- (void) showExceptionAlert:(NSException*) localException;

#pragma mark •••Data Source
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end

