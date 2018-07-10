
//
//  ORIpeV4FLTController.h
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORIpeV4FLTModel.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORIpeV4FLTController : OrcaObjectController {
	@private
        IBOutlet NSButton*		settingLockButton;
		IBOutlet NSMatrix*		displayEventRateMatrix;
		IBOutlet NSTextField*	targetRateField;
        IBOutlet NSTextField*   histMaxEnergyTextField;
        IBOutlet NSTextField*   histPageABTextField;
        IBOutlet NSTextField*   fltSlotNumTextField;
		IBOutlet NSTextField*	histLastEntryField;
		IBOutlet NSTextField*	histFirstEntryField;
		IBOutlet NSPopUpButton* histClrModePU;
		IBOutlet NSPopUpButton* histModePU;
		IBOutlet NSPopUpButton* histEBinPU;
		IBOutlet NSTextField*	histEMinTextField;
		IBOutlet NSButton*		runBoxCarFilterCB;
		IBOutlet NSButton*		storeDataInRamCB;
		IBOutlet NSPopUpButton*	filterLengthPU;
		IBOutlet NSPopUpButton*	gapLengthPU;
		IBOutlet NSTextField*	histNofMeasField;
		IBOutlet NSTextField*	histMeasTimeField;
		IBOutlet NSTextField*	histRecTimeField;
		IBOutlet NSTextField*   postTriggerTimeField;
		IBOutlet NSMatrix*		fifoBehaviourMatrix;
		IBOutlet NSTextField*	analogOffsetField;
		IBOutlet NSTextField*	interruptMaskField;
		IBOutlet NSPopUpButton*	modeButton;
		IBOutlet NSButton*		versionButton;
		IBOutlet NSButton*		statusButton;
		IBOutlet NSButton*		initBoardButton;
		IBOutlet NSButton*		reportButton;
		IBOutlet NSButton*		resetButton;
		IBOutlet NSMatrix*		gainTextFields;
		IBOutlet NSMatrix*		thresholdTextFields;
		IBOutlet NSMatrix*		triggerEnabledCBs;
		IBOutlet NSMatrix*		hitRateEnabledCBs;
		IBOutlet NSPopUpButton*	hitRateLengthPU;
		IBOutlet NSButton*		hitRateAllButton;
		IBOutlet NSButton*		hitRateNoneButton;
		IBOutlet NSButton*		triggersAllButton;
		IBOutlet NSButton*		triggersNoneButton;
		IBOutlet NSButton*		defaultsButton;
	
		//rate page
		IBOutlet NSMatrix*		rateTextFields;
		
		IBOutlet ORValueBarGroupView*		rate0;
		IBOutlet ORValueBarGroupView*		totalRate;
		IBOutlet NSButton*					rateLogCB;
		IBOutlet ORCompositeTimeLineView*	timeRatePlot;
		IBOutlet NSButton*					timeRateLogCB;
		IBOutlet NSButton*					totalRateLogCB;
		IBOutlet NSTextField*				totalHitRateField;
		IBOutlet NSTabView*					tabView;	
		IBOutlet NSView*					totalView;
		
		//test page
		IBOutlet NSButton*		testButton;
		IBOutlet NSMatrix*		testEnabledMatrix;
		IBOutlet NSMatrix*		testStatusMatrix;
		
		NSNumberFormatter*		rateFormatter;
		NSSize					settingSize;
		NSSize					rateSize;
		NSSize					testSize;
		NSSize					lowlevelSize;
		NSView*					blankView;
        
        //low level
		IBOutlet NSPopUpButton*	registerPopUp;
		IBOutlet NSPopUpButton*	channelPopUp;
		IBOutlet NSStepper* 	regWriteValueStepper;
		IBOutlet NSTextField* 	regWriteValueTextField;
		IBOutlet NSButton*		regWriteButton;
		IBOutlet NSButton*		regReadButton;
	
		IBOutlet NSButton*      noiseFloorButton;
		//offset panel
		IBOutlet NSPanel*				noiseFloorPanel;
		IBOutlet NSTextField*			noiseFloorOffsetField;
		IBOutlet NSTextField*			noiseFloorStateField;
		IBOutlet NSButton*				startNoiseFloorButton;
		IBOutlet NSProgressIndicator*	noiseFloorProgress;
		IBOutlet NSTextField*			noiseFloorStateField2;
		
};
#pragma mark •••Initialization
- (id)   init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) updateButtons;

#pragma mark •••Interface Management
- (void) targetRateChanged:(NSNotification*)aNote;
- (void) histMaxEnergyChanged:(NSNotification*)aNote;
- (void) histPageABChanged:(NSNotification*)aNote;
- (void) noiseFloorChanged:(NSNotification*)aNote;
- (void) noiseFloorOffsetChanged:(NSNotification*)aNote;
- (void) histLastEntryChanged:(NSNotification*)aNote;
- (void) histFirstEntryChanged:(NSNotification*)aNote;
- (void) histClrModeChanged:(NSNotification*)aNote;
- (void) histModeChanged:(NSNotification*)aNote;
- (void) histEBinChanged:(NSNotification*)aNote;
- (void) histEMinChanged:(NSNotification*)aNote;
- (void) runBoxCarFilterChanged:(NSNotification*)aNote;
- (void) storeDataInRamChanged:(NSNotification*)aNote;
- (void) filterLengthChanged:(NSNotification*)aNote;
- (void) gapLengthChanged:(NSNotification*)aNote;
- (void) histNofMeasChanged:(NSNotification*)aNote;
- (void) histMeasTimeChanged:(NSNotification*)aNote;
- (void) histRecTimeChanged:(NSNotification*)aNote;
- (void) postTriggerTimeChanged:(NSNotification*)aNote;
- (void) fifoBehaviourChanged:(NSNotification*)aNote;
- (void) analogOffsetChanged:(NSNotification*)aNote;
- (void) interruptMaskChanged:(NSNotification*)aNote;
- (void) populatePullDown;
- (void) updateWindow;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) enableRegControls;
- (void) slotChanged:(NSNotification*)aNote;
- (void) modeChanged:(NSNotification*)aNote;
- (void) gainChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) gainArrayChanged:(NSNotification*)aNote;
- (void) thresholdArrayChanged:(NSNotification*)aNote;
- (void) triggersEnabledArrayChanged:(NSNotification*)aNote;
- (void) triggerEnabledChanged:(NSNotification*)aNote;
- (void) hitRatesEnabledArrayChanged:(NSNotification*)aNote;
- (void) hitRateEnabledChanged:(NSNotification*)aNote;
- (void) hitRateLengthChanged:(NSNotification*)aNote;
- (void) hitRateChanged:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) testStatusArrayChanged:(NSNotification*)aNote;
- (void) testEnabledArrayChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) selectedRegIndexChanged:(NSNotification*) aNote;
- (void) writeValueChanged:(NSNotification*) aNote;
- (void) selectedChannelValueChanged:(NSNotification*) aNote;

#pragma mark •••Actions
- (IBAction) targetRateAction:(id)sender;
- (IBAction) histClrModeAction:(id)sender;
- (IBAction) histModeAction:(id)sender;
- (IBAction) histEBinAction:(id)sender;
- (IBAction) histEMinAction:(id)sender;
- (IBAction) runBoxCarFilterAction:(id)sender;
- (IBAction) storeDataInRamAction:(id)sender;
- (IBAction) filterLengthAction:(id)sender;
- (IBAction) gapLengthAction:(id)sender;
- (IBAction) histNofMeasAction:(id)sender;
- (IBAction) histMeasTimeAction:(id)sender;
- (IBAction) setTimeToMacClock:(id)sender;
- (IBAction) postTriggerTimeAction:(id)sender;
- (IBAction) fifoBehaviourAction:(id)sender;
- (IBAction) analogOffsetAction:(id)sender;
- (IBAction) interruptMaskAction:(id)sender;
- (IBAction) initBoardButtonAction:(id)sender;
- (IBAction) reportButtonAction:(id)sender;
- (IBAction) gainAction:(id)sender;
- (IBAction) triggerEnableAction:(id)sender;
- (IBAction) hitRateEnableAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) modeAction: (id) sender;
- (IBAction) versionAction: (id) sender;
- (IBAction) testAction: (id) sender;
- (IBAction) resetAction: (id) sender;
- (IBAction) hitRateLengthAction: (id) sender;
- (IBAction) hitRateAllAction: (id) sender;
- (IBAction) hitRateNoneAction: (id) sender;
- (IBAction) testEnabledAction:(id)sender;
- (IBAction) statusAction:(id)sender;
- (IBAction) enableAllTriggersAction: (id) sender;
- (IBAction) enableNoTriggersAction: (id) sender;
- (IBAction) readThresholdsGains:(id)sender;
- (IBAction) writeThresholdsGains:(id)sender;
- (IBAction) selectRegisterAction:(id) aSender;
- (IBAction) selectChannelAction:(id) aSender;
- (IBAction) writeValueAction:(id) aSender;
- (IBAction) readRegAction: (id) sender;
- (IBAction) writeRegAction: (id) sender;
- (IBAction) setDefaultsAction: (id) sender;
- (IBAction) openNoiseFloorPanel:(id)sender;
- (IBAction) closeNoiseFloorPanel:(id)sender;
- (IBAction) findNoiseFloors:(id)sender;
- (IBAction) noiseFloorOffsetAction:(id)sender;

- (IBAction) testButtonAction: (id) sender; //temp routine to hook up to any on a temp basis

	
#pragma mark •••Plot DataSource
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end