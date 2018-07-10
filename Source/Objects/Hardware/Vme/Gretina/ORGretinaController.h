//-------------------------------------------------------------------------
//  ORGretinaController.h
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark ***Imported Files
#import "OrcaObjectController.h";
#import "ORGretinaModel.h"
@class ORValueBar;
@class ORPlotter1D;

@interface ORGretinaController : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
    //basic ops page
	IBOutlet NSMatrix*		enabledMatrix;
	IBOutlet NSMatrix*		debugMatrix;
	IBOutlet NSMatrix*		pileUpMatrix;
	IBOutlet NSMatrix*		ledThresholdMatrix;
	IBOutlet NSMatrix*		cfdDelayMatrix;
	IBOutlet NSMatrix*		cfdFractionMatrix;
	IBOutlet NSMatrix*		cfdThresholdMatrix;
	IBOutlet NSMatrix*		dataDelayMatrix;
	IBOutlet NSMatrix*		dataLengthMatrix;

	//arrggg! why can't you put a popup into a NSMatrix????
	IBOutlet NSPopUpButton*	polarityPU0;
	IBOutlet NSPopUpButton*	polarityPU1;
	IBOutlet NSPopUpButton*	polarityPU2;
	IBOutlet NSPopUpButton*	polarityPU3;
	IBOutlet NSPopUpButton*	polarityPU4;
	IBOutlet NSPopUpButton*	polarityPU5;
	IBOutlet NSPopUpButton*	polarityPU6;
	IBOutlet NSPopUpButton*	polarityPU7;
	NSPopUpButton* polarityPU[kNumGretinaChannels];
	
	IBOutlet NSPopUpButton*	triggerModePU0;
	IBOutlet NSPopUpButton*	triggerModePU1;
	IBOutlet NSPopUpButton*	triggerModePU2;
	IBOutlet NSPopUpButton*	triggerModePU3;
	IBOutlet NSPopUpButton*	triggerModePU4;
	IBOutlet NSPopUpButton*	triggerModePU5;
	IBOutlet NSPopUpButton*	triggerModePU6;
	IBOutlet NSPopUpButton*	triggerModePU7;
	NSPopUpButton* triggerModePU[kNumGretinaChannels];

	
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;
    IBOutlet NSMatrix*      cardInfoMatrix;

    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      initButton;
    IBOutlet NSButton*      clearFIFOButton;
    IBOutlet NSButton*      probeButton;
    IBOutlet NSButton*      statusButton;
    IBOutlet NSButton*      noiseFloorButton;
    IBOutlet NSTextField*   fifoState;

    //rate page
    IBOutlet NSMatrix*      rateTextFields;
    IBOutlet NSStepper*     integrationStepper;
    IBOutlet NSTextField*   integrationText;
    IBOutlet NSTextField*   totalRateText;
    IBOutlet NSMatrix*      enabled2Matrix;

    IBOutlet ORValueBar*    rate0;
    IBOutlet ORValueBar*    totalRate;
    IBOutlet NSButton*      rateLogCB;
    IBOutlet NSButton*      totalRateLogCB;
    IBOutlet ORPlotter1D*   timeRatePlot;
    IBOutlet NSButton*      timeRateLogCB;


    //offset panel
    IBOutlet NSPanel*				noiseFloorPanel;
    IBOutlet NSTextField*			noiseFloorOffsetField;
    IBOutlet NSTextField*			noiseFloorIntegrationField;
    IBOutlet NSButton*				startNoiseFloorButton;
    IBOutlet NSProgressIndicator*	noiseFloorProgress;

    NSView *blankView;
    NSSize settingSize;
    NSSize rateSize;

}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ¥¥¥Interface Management
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) updateCardInfo:(NSNotification*)aNote;
- (void) registerRates;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) noiseFloorChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) noiseFloorOffsetChanged:(NSNotification*)aNote;
- (void) setFifoStateLabel;
- (void) enabledChanged:(NSNotification*)aNote;
- (void) debugChanged:(NSNotification*)aNote;
- (void) pileUpChanged:(NSNotification*)aNote;
- (void) polarityChanged:(NSNotification*)aNote;
- (void) triggerModeChanged:(NSNotification*)aNote;
- (void) ledThresholdChanged:(NSNotification*)aNote;
- (void) cfdDelayChanged:(NSNotification*)aNote;
- (void) cfdFractionChanged:(NSNotification*)aNote;
- (void) cfdThresholdChanged:(NSNotification*)aNote;
- (void) dataDelayChanged:(NSNotification*)aNote;
- (void) dataLengthChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;

- (void) scaleAction:(NSNotification*)aNote;
- (void) integrationChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) noiseFloorIntegrationChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) cardInfoAction:(id) sender;
- (IBAction) probeBoard:(id)sender;
- (IBAction) readStatus:(id)sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) clearFIFO:(id)sender;
- (IBAction) integrationAction:(id)sender;
- (IBAction) findNoiseFloors:(id)sender;
- (IBAction) noiseFloorOffsetAction:(id)sender;
- (IBAction) openNoiseFloorPanel:(id)sender;
- (IBAction) closeNoiseFloorPanel:(id)sender;
- (IBAction) noiseFloorIntegrationAction:(id)sender;

- (IBAction) enabledAction:(id)sender;
- (IBAction) debugAction:(id)sender;
- (IBAction) pileUpAction:(id)sender;
- (IBAction) polarityAction:(id)sender;
- (IBAction) triggerModeAction:(id)sender;
- (IBAction) ledThresholdAction:(id)sender;
- (IBAction) cfdFractionAction:(id)sender;
- (IBAction) cfdDelayAction:(id)sender;
- (IBAction) cfdThresholdAction:(id)sender;
- (IBAction) dataDelayAction:(id)sender;
- (IBAction) dataLengthAction:(id)sender;

#pragma mark ¥¥¥Data Source
- (double)  getBarValue:(int)tag;
- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x;
- (unsigned long)  	secondsPerUnit:(id) aPlotter;

@end
