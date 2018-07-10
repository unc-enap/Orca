//-------------------------------------------------------------------------
//  ORSIS3302Controller.h
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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
#import "OrcaObjectController.h"
#import "ORSIS3302GenericModel.h"
@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORSIS3302GenericController : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
	IBOutlet NSTextField*	firmwareVersionTextField;

	
    // Trigger Setup
	IBOutlet NSMatrix*		gtMatrix;
	IBOutlet NSMatrix*		trapezoidalTriggerMatrix;    
	IBOutlet NSMatrix*		thresholdMatrix;
	IBOutlet NSMatrix*		dacOffsetMatrix;
	IBOutlet NSMatrix*		sumGMatrix;
	IBOutlet NSMatrix*		peakingTimeMatrix;
	IBOutlet NSMatrix*		pulseLengthMatrix;    
	IBOutlet NSMatrix*		preTriggerDelayMatrix;

	//base address
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;
	IBOutlet NSPopUpButton* clockSourcePU;


    // Buffer setup
	IBOutlet NSMatrix*		sampleLengthMatrix;
	IBOutlet NSMatrix*		averagingMatrix;
	IBOutlet NSMatrix*		stopAtEventLengthMatrix;
	IBOutlet NSMatrix*		enablePageWrapMatrix;    
	IBOutlet NSMatrix*		pageWrapSizeMatrix;
	IBOutlet NSMatrix*		testDataEnableMatrix;    
	IBOutlet NSMatrix*		testDataTypeMatrix;    
    
	IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      initButton;
    IBOutlet NSButton*      briefReportButton;
    IBOutlet NSButton*      regDumpButton;
    IBOutlet NSButton*      probeButton;
    
    // Trigger/Lemo configuration
    IBOutlet NSTextField*   startDelay;
    IBOutlet NSTextField*   stopDelay;
    IBOutlet NSTextField*   maxEvents;    
	IBOutlet NSButton*      lemoTimestampClearButton;
    IBOutlet NSButton*      lemoStartStopButton;
    IBOutlet NSButton*      internalTrigStartButton;
    IBOutlet NSButton*      internalTrigStopButton;
    IBOutlet NSButton*      multiEventModeButton;
    IBOutlet NSButton*      autostartModeButton;
	
    
    //rate page
    IBOutlet NSMatrix*      rateTextFields;
    IBOutlet NSStepper*     integrationStepper;
    IBOutlet NSTextField*   integrationText;
    IBOutlet NSTextField*   totalRateText;

    IBOutlet ORValueBarGroupView*       rate0;
    IBOutlet ORValueBarGroupView*       totalRate;
    IBOutlet NSButton*				    rateLogCB;
    IBOutlet NSButton*				    totalRateLogCB;
    IBOutlet ORCompositeTimeLineView*   timeRatePlot;
    IBOutlet NSButton*					timeRateLogCB;
		
    NSView *blankView;
    NSSize settingSize;
    NSSize rateSize;
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) firmwareVersionChanged:(NSNotification*)aNote;


- (void) clockSourceChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) registerRates;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;

// Trigger
- (void) gtChanged:(NSNotification*)aNote;
- (void) trapFilterTriggerChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) dacOffsetChanged:(NSNotification*)aNote;
- (void) sumGChanged:(NSNotification*)aNote;
- (void) peakingTimeChanged:(NSNotification*)aNote;
- (void) pulseLengthChanged:(NSNotification*)aNote;
- (void) preTriggerDelayChanged:(NSNotification*)aNote;

// Buffer
- (void) sampleLengthChanged:(NSNotification*)aNote;
- (void) averagingChanged:(NSNotification*)aNote;
- (void) stopAtEventLengthChanged:(NSNotification*)aNote;
- (void) enablePageWrapChanged:(NSNotification*)aNote;    
- (void) pageWrapSizeChanged:(NSNotification*)aNote;
- (void) testDataEnableChanged:(NSNotification*)aNote;    
- (void) testDataTypeChanged:(NSNotification*)aNote; 

// Trigger/Lemo configuration
- (void) startDelayChanged:(NSNotification*)aNote;
- (void) stopDelayChanged:(NSNotification*)aNote;
- (void) maxEventsChanged:(NSNotification*)aNote;   
- (void) lemoTimestampClearChanged:(NSNotification*)aNote;
- (void) lemoStartStopChanged:(NSNotification*)aNote;
- (void) internalTrigStartChanged:(NSNotification*)aNote;
- (void) internalTrigStopChanged:(NSNotification*)aNote;
- (void) multiEventModeChanged:(NSNotification*)aNote;
- (void) autostartModeChanged:(NSNotification*)aNote;

- (void) scaleAction:(NSNotification*)aNote;
- (void) integrationChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;



#pragma mark •••Actions

- (IBAction) forceTriggerAction:(id)sender;
- (IBAction) resetAction:(id)sender;

- (IBAction) clockSourceAction:(id)sender;
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) integrationAction:(id)sender;
- (IBAction) probeBoardAction:(id)sender;

//Trigger
- (IBAction) gtAction:(id)sender;
- (IBAction) trapezoidTriggerAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) dacOffsetAction:(id)sender;
- (IBAction) sumGAction:(id)sender;
- (IBAction) peakingTimeAction:(id)sender;
- (IBAction) pulseLengthAction:(id)sender;
- (IBAction) preTriggerDelayAction:(id)sender;

// Buffer
- (IBAction) sampleLengthAction:(id)sender;
- (IBAction) averagingAction:(id)sender;
- (IBAction) stopAtEventLengthAction:(id)sender;
- (IBAction) enablePageWrapAction:(id)sender;    
- (IBAction) pageWrapSizeAction:(id)sender;
- (IBAction) testDataEnableAction:(id)sender;    
- (IBAction) testDataTypeAction:(id)sender; 

// Trigger/Lemo configuration
- (IBAction) startDelayAction:(id)sender;
- (IBAction) stopDelayAction:(id)sender;
- (IBAction) maxEventsAction:(id)sender;    
- (IBAction) lemoTimestampClearAction:(id)sender;
- (IBAction) lemoStartStopAction:(id)sender;
- (IBAction) internalTrigStartAction:(id)sender;
- (IBAction) internalTrigStopAction:(id)sender;
- (IBAction) multiEventModeAction:(id)sender;
- (IBAction) autostartModeAction:(id)sender;

- (IBAction) briefReport:(id)sender;
- (IBAction) regDump:(id)sender;

#pragma mark •••Data Source
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (double)  getBarValue:(int)tag;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
