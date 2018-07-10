//
//  ORDGF4cController.h
//  Orca
//
//  Created by Mark Howe on Wed Dec 29 2004.
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
#import "ORDGF4cModel.h"

@class ORCompositePlotView;

@interface ORDGF4cController : OrcaObjectController {
	@private
		IBOutlet ORCompositePlotView*   plotter;
		IBOutlet NSButton*		sampleContinousButton;
        IBOutlet NSMatrix*		ocsChanEnableMatrix;
		IBOutlet NSButton*		sampleWaveformsButton;
		IBOutlet NSTextField*	samplingWarning;
		
        IBOutlet NSButton*    firmWarePathButton;
        IBOutlet NSButton*    loadFirmWareButton;
        IBOutlet NSTextField* firmWarePathField;

        IBOutlet NSButton*    dspCodePathButton;
        IBOutlet NSButton*    bootDSPButton;
        IBOutlet NSTextField* dspCodePathField;
        
        IBOutlet NSTableView* dspParamTableView;
        IBOutlet NSTableView* dspChanTableView;

        IBOutlet NSButton*    loadDefaultsButton;
        IBOutlet NSButton*    saveSetButton;
        IBOutlet NSButton*    loadSetButton;
        IBOutlet NSButton*    mergeSetButton;
        
        IBOutlet NSButton*	  settingLockButton;
        IBOutlet NSTextField* settingLockDocField;

        IBOutlet NSTextField* channelField;
        IBOutlet NSStepper*   channelStepper;

        IBOutlet NSPopUpButton*	  runTypePopup;
        IBOutlet NSPopUpButton*	  decimationPopup;
        IBOutlet NSMatrix*		  runBehaviorMatrix;

        IBOutlet NSMatrix*     triggerFilterFieldMatrix;
        IBOutlet NSMatrix*     triggerFilterStepperMatrix;
        IBOutlet NSMatrix*     energyFilterFieldMatrix;
        IBOutlet NSMatrix*     energyFilterStepperMatrix;

        IBOutlet NSMatrix*     pulseShapeFieldMatrix;
        IBOutlet NSMatrix*     pulseShapeStepperMatrix;

        IBOutlet NSMatrix*     registerFieldMatrix;
        
        IBOutlet NSMatrix*     calibrateFieldMatrix;
        IBOutlet NSMatrix*     calibrateStepperMatrix;
        
        IBOutlet NSMatrix*     histogramFieldMatrix;
        IBOutlet NSMatrix*     histogramStepperMatrix;
 
        IBOutlet NSMatrix*     liveTimeMatrix;
        IBOutlet NSMatrix*     inputCountsMatrix;
        
        IBOutlet NSMatrix*     timeMatrix;
        IBOutlet NSMatrix*     chanCSRAMatrix;
		
        IBOutlet NSTextField*  revisionField;
        IBOutlet NSButton*     loadParamsToHWButton;
        IBOutlet NSButton*     loadParamsToHWButton2;
		
        IBOutlet NSButton*     sampleButton;
        IBOutlet NSButton*     baselineCutButton;
        IBOutlet NSButton*     offsetButton;
        IBOutlet NSButton*     autoTauFindButton;


        IBOutlet NSTextField* xwaitField;
        IBOutlet NSStepper*   xwaitStepper;

		
		BOOL sampling;
		BOOL scheduledToUpdate;
};

- (void) registerNotificationObservers;
- (void) updateUserParams:(NSNotification*)aNote;
- (void) updateDisplayOnlyParams;

#pragma mark ¥¥¥Interface Management
- (void) updateOsc:(NSNotification*)aNotification;
- (void) sampleWaveformsChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) tauChanged:(NSNotification*)aNotification;
- (void) tauSigmaChanged:(NSNotification*)aNotification;
- (void) binFactorChanged:(NSNotification*)aNotification; 
- (void) eMinChanged:(NSNotification*)aNotification;
- (void) psaEndChanged:(NSNotification*)aNotification; 
- (void) psaStartChanged:(NSNotification*)aNotification; 
- (void) traceDelayChanged:(NSNotification*)aNotification; 
- (void) traceLengthChanged:(NSNotification*)aNotification; 
- (void) vOffsetChanged:(NSNotification*)aNotification; 
- (void) vGainChanged:(NSNotification*)aNotification; 
- (void) triggerThresholdChanged:(NSNotification*)aNotification; 
- (void) triggerFlatTopChanged:(NSNotification*)aNotification; 
- (void) triggerRiseTimeChanged:(NSNotification*)aNotification; 
- (void) energyFlatTopChanged:(NSNotification*)aNotification; 
- (void) energyRiseTimeChanged:(NSNotification*)aNotification;
- (void) xwaitChanged:(NSNotification*)aNotification;

- (void) firmWarePathChanged:(NSNotification*)aNotification;
- (void) dspCodePathChanged:(NSNotification*)aNotification;
- (void) dspCodePathChanged:(NSNotification*)aNotification;
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) paramChanged:(NSNotification*)aNotification;
- (void) channelChanged:(NSNotification*)aNotification;
- (void) runTaskChanged:(NSNotification*)aNotification;
- (void) runBehaviorChanged:(NSNotification*)aNotification;
- (void) registersChanged:(NSNotification*)aNotification;
- (void) liveTimeChanged:(NSNotification*)aNotification;
- (void) inputCountsChanged:(NSNotification*)aNotification;
- (void) timeChanged:(NSNotification*)aNotification;
- (void) chanCSRAChanged:(NSNotification*)aNotification;
- (void) revisionChanged:(NSNotification*)aNotification;
- (void) decimationChanged:(NSNotification*)aNotification;
- (void) oscChanEnableChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) xwaitAction:(id) sender;
- (IBAction) sampleWaveformsAction:(id) sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) firmWarePathAction:(id) sender;
- (IBAction) loadFirmWareAction:(id) sender;
- (IBAction) dspCodePathAction:(id) sender;
- (IBAction) bootDSPAction:(id) sender;
- (IBAction) loadDefaults:(id) sender;
- (IBAction) loadSetAction:(id) sender;
- (IBAction) saveSetAction:(id) sender;
- (IBAction) mergeSetAction:(id) sender;
- (IBAction) runTypeAction:(id) sender;
- (IBAction) triggerFilterAction:(id) sender;
- (IBAction) energyFilterAction:(id) sender;
- (IBAction) pulseShapeAction:(id) sender;
- (IBAction) channelAction:(id) sender;
- (IBAction) registerAction:(id) sender;
- (IBAction) calibrateAction:(id) sender;
- (IBAction) histogramAction:(id) sender;
- (IBAction) chanCSRAAction:(id) sender;
- (IBAction) loadParamsToHWAction:(id) sender;
- (IBAction) decimationAction:(id) sender;
- (IBAction) sampleAction:(id)sender;
- (IBAction) oscChanEnableAction:(id)sender;
- (IBAction) baselineCutAction:(id)sender;
- (IBAction) offsetAction:(id)sender;
- (IBAction) autoFindTauAction:(id)sender;
- (IBAction) runBehaviorAction:(id)sender;


- (void) takeSample;

- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end