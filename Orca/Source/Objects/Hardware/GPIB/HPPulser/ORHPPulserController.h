//
//  ORHPPulserController.h
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
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



#import "ORGpibDeviceController.h"

@class ORCompositePlotView;

@interface ORHPPulserController : ORGpibDeviceController {
    IBOutlet NSButton* 		readIdButton;	
    IBOutlet NSMatrix*		negativePulseMatrix;
    IBOutlet NSButton* 		resetButton;	
    IBOutlet NSButton* 		testButton;	
    IBOutlet NSButton* 		clearButton;	
    IBOutlet NSButton* 		downloadButton;	
    IBOutlet NSPopUpButton*     selectionPopUpButton;	
    IBOutlet NSTextField* 	voltageField;
    IBOutlet NSStepper* 	voltageStepper;
    IBOutlet NSTextField* 	voltageOffsetField;
    IBOutlet NSStepper* 	voltageOffsetStepper;
    IBOutlet NSTextField* 	frequencyField;
    IBOutlet NSStepper* 	frequencyStepper;
    IBOutlet NSTextField* 	burstRateField;
    IBOutlet NSStepper* 	burstRateStepper;
    IBOutlet NSTextField* 	burstPhaseField;
    IBOutlet NSStepper* 	burstPhaseStepper;
    IBOutlet NSTextField* 	burstCyclesField;
    IBOutlet NSStepper* 	burstCyclesStepper;
    IBOutlet NSMatrix*      triggerModeMatrix;
    IBOutlet NSButton* 		triggerButton;	

    IBOutlet NSButton*		enableRandomButton;
    IBOutlet NSTextField*	minTimeField;
    IBOutlet NSTextField*	maxTimeField;
    IBOutlet NSStepper*		minTimeStepper;
    IBOutlet NSStepper*		maxTimeStepper;
    IBOutlet NSTextField*	randomCountField;


    IBOutlet NSTextField* 	voltageDisplay;
    IBOutlet NSTextField* 	burstRateDisplay;
    IBOutlet NSButton*		loadParamsButton;	

    IBOutlet ORCompositePlotView*	plotter;

    IBOutlet NSTextField* 	downloadTypeField;
    IBOutlet NSProgressIndicator* progress;

    IBOutlet NSTextField*   lockDocField;
    IBOutlet NSButton*		lockButton;

    IBOutlet NSTextField*   commandField;
    IBOutlet NSButton*		sendCommandButton;
    IBOutlet NSButton*		verboseCB;

}

#pragma mark •••Actions
- (IBAction) verboseAction:(id)sender;
- (IBAction) negativePulseAction:(id)sender;
- (IBAction) triggerAction:(id)sender;
- (IBAction) triggerModeAction:(id)sender;
- (IBAction) readIdAction:(id)sender;
- (IBAction) resetAction:(id)sender;
- (IBAction) testAction:(id)sender;
- (IBAction) downloadWaveformAction:(id)sender;
- (IBAction) loadParamsAction:(id)sender;
- (IBAction) selectWaveformAction:(id)sender; 
- (IBAction) clearMemory:(id)sender;
- (IBAction) setVoltageAction:(id)sender;
- (IBAction) setVoltageOffsetAction:(id)sender;
- (IBAction) setFrequencyAction:(id)sender;
- (IBAction) setBurstRateAction:(id)sender;
- (IBAction) setBurstCyclesAction:(id)sender;
- (IBAction) setBurstPhaseAction:(id)sender;
- (IBAction) lockAction:(id)sender;
- (IBAction) enableRandomAction:(id)sender;
- (IBAction) minTimeAction:(id)sender;
- (IBAction) maxTimeAction:(id)sender;
- (IBAction) sendCommandAction:(id)sender;

- (void) downloadWaveform;

- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

- (void) setButtonStates;

#pragma mark ***Interface Management
- (void) verboseChanged:(NSNotification*)aNote;
- (void) volatileChanged:(NSNotification*)aNotification;
- (void) nonVolatileChanged:(NSNotification*)aNotification;
- (void) enableRandomChanged:(NSNotification*)note;
- (void) minTimeChanged:(NSNotification*)note;
- (void) maxTimeChanged:(NSNotification*)note;
- (void) randomCountChanged:(NSNotification*)note;

- (void) selectedWaveformChanged:(NSNotification*)aNotification;
- (void) triggerModeChanged:(NSNotification*)aNotification;
- (void) voltageChanged:(NSNotification*)aNotification;
- (void) voltageOffsetChanged:(NSNotification*)aNotification;
- (void) frequencyChanged:(NSNotification*)aNotification;
- (void) burstRateChanged:(NSNotification*)aNotification;
- (void) burstCyclesChanged:(NSNotification*)aNotification;
- (void) burstPhaseChanged:(NSNotification*)aNotification;
- (void) loadConstantsChanged:(NSNotification*)aNotification;
- (void) waveformLoadStarted:(NSNotification*)aNotification;
- (void) waveformLoadProgressing:(NSNotification*)aNotification;
- (void) waveformLoadFinished:(NSNotification*)aNotification;
- (void) lockChanged: (NSNotification*) aNotification;
- (void) checkGlobalSecurity;
- (void) negativePulseChanged:(NSNotification*)aNote;


@end


