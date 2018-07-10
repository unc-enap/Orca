
//
//  ORKatrinFLTController.h
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


#pragma mark ¥¥¥Imported Files
#import "ORKatrinFLTModel.h"

@class ORCompositeTimeLineView;
@class ORCompositePlotView;
@class ORValueBarGroupView;

@interface ORKatrinFLTController : OrcaObjectController {
	@private
        IBOutlet NSButton*		settingLockButton; 
		IBOutlet NSTextField*   fltNumberField;
		IBOutlet NSButton*		checkWaveFormEnabledButton;
		IBOutlet NSButton*		checkEnergyEnabledButton;
		IBOutlet NSPopUpButton*	daqRunModeButton;//!<The tag needs to be equal to the daq run mode. See ORKatrinFLTModel.h for values.
		IBOutlet NSMenuItem*    energyDaqModeMenuItem;
		IBOutlet NSMenuItem*    vetoDaqModeMenuItem;
		IBOutlet NSMenuItem*    histogramDaqModeMenuItem;
		IBOutlet NSTextField*   daqRunModeInfoField;
		IBOutlet NSButton*		versionButton;
		IBOutlet NSButton*		versionStdCheckButton;
		IBOutlet NSButton*		versionHistoCheckButton;
		IBOutlet NSButton*		versionVetoCheckButton;
		IBOutlet NSButton*		versionFilterGapCheckButton;
		IBOutlet NSButton*		statusButton;
		IBOutlet NSButton*		readFltModeButton;
		IBOutlet NSTextField*   fltModeField;
		IBOutlet NSButton*		writeFltModeButton;
		IBOutlet NSButton*		resetButton;
		IBOutlet NSButton*		triggerButton; // ak, 3.7.07		
		IBOutlet NSMatrix*		gainTextFields;
		IBOutlet NSMatrix*		thresholdTextFields;
		IBOutlet NSMatrix*		triggerEnabledCBs;
		IBOutlet NSMatrix*		hitRateEnabledCBs;
		IBOutlet NSButton*		readThresholdsGainsButton;
		IBOutlet NSButton*		writeThresholdsGainsButton;
		IBOutlet NSButton*		loadTimeButton;
		IBOutlet NSButton*		readTimeButton;
		IBOutlet NSPopUpButton* shapingTimePU0;
		IBOutlet NSPopUpButton* shapingTimePU1;
		IBOutlet NSPopUpButton* shapingTimePU2;
		IBOutlet NSPopUpButton* shapingTimePU3;
		IBOutlet NSTextField*	shapingTimeEffField0;
		IBOutlet NSTextField*	shapingTimeEffField1;
		IBOutlet NSTextField*	shapingTimeEffField2;
		IBOutlet NSTextField*	shapingTimeEffField3;
		IBOutlet NSPopUpButton* filterGapPopup;
		IBOutlet NSTextField*	filterGapBinsField;
		IBOutlet NSTextField*	maxEnergyField0;
		IBOutlet NSTextField*	hitRateLengthField;
		IBOutlet NSButton*		hitRateAllButton;
		IBOutlet NSButton*		hitRateNoneButton;
        IBOutlet NSButton*		broadcastTimeCB;

		IBOutlet NSTextField*	postTriggTimeField;// -tb-
		IBOutlet NSButton*	    writePostTriggerTimeButton;// -tb-

		
		IBOutlet NSTextField*	readoutPagesField; // ak, 2.7.07
        
        //histogram page/tab view -tb-
        IBOutlet NSButton*		startCalibrationHistogramButton;
        IBOutlet NSButton*		stopCalibrationHistogramButton;
        IBOutlet NSButton*		readCalibrationHistogramDataButton;
        IBOutlet NSButton*		startSelfCalibrationHistogramButton;
        IBOutlet NSButton*		readHistogramStatusRegButton;
        IBOutlet NSButton*		helloButton; // -tb- 2008/1/17
        IBOutlet NSTextField*	eMinField;
        IBOutlet NSTextField*	eMaxField;
        IBOutlet NSTextField*	histoMessageAboutFPGAVersionField;
        //EMax buttons missing - up to now not necessary -tb-
        IBOutlet NSTextField*	tRunField;
        IBOutlet NSTextField*	tRecField;
        // TRun buttons missing - up to now not necessary -tb-
        IBOutlet NSTextField*	firstBinField;
        IBOutlet NSTextField*	lastBinField;
        IBOutlet ORCompositePlotView*    histogramPlotterId;
        IBOutlet NSPopUpButton* eSamplePopUpButton;////eSample=BW TODO: rename to binWidth -tb-
        IBOutlet NSProgressIndicator* histoProgressIndicator;
        IBOutlet NSTextField*	histoElapsedTimeField;
        IBOutlet NSPopUpButton* histoCalibrationChanNumPopUpButton;
        IBOutlet NSTextField*	histoPageField;
        IBOutlet NSTextField*	histoSelfCalibrationPercentField;
        IBOutlet NSButton*		showHitratesDuringHistoCalibrationButton;
        IBOutlet NSButton*		histoClearAtStartButton;
        IBOutlet NSButton*		histoClearAfterReadoutButton;        
        IBOutlet NSButton*		histoStopIfNotClearedButton;//TODO: removed -remove actions -tb-
        IBOutlet NSPopUpButton*	histoStopIfNotClearedPopUpButton;

        //veto page/tab view -tb-
        IBOutlet NSButton*		vetoEnableButton;
        IBOutlet NSButton*		readEnableVetoButton;
        IBOutlet NSButton*		writeEnableVetoButton;
        IBOutlet NSButton*		readVetoDataButton;
        	
		//rate page
		IBOutlet NSMatrix*		rateTextFields;
		
		IBOutlet ORValueBarGroupView*	rate0;
		IBOutlet ORValueBarGroupView*	totalRate;
		IBOutlet NSButton*		rateLogCB;
		IBOutlet ORCompositeTimeLineView*	timeRatePlot;
		IBOutlet NSButton*		timeRateLogCB;
		IBOutlet NSButton*		totalRateLogCB;
		IBOutlet NSTextField*	totalHitRateField;
		IBOutlet NSTabView*		tabView;	
		IBOutlet NSView*		totalView;

		//test page
		IBOutlet NSButton*		testButton;
		IBOutlet NSMatrix*		testEnabledMatrix;
		IBOutlet NSMatrix*		testStatusMatrix;
		IBOutlet NSMatrix*		testParamsMatrix;
		IBOutlet NSTableView*	patternTable;
		IBOutlet NSMatrix*		tModeMatrix;
		IBOutlet NSButton*		initTPButton;
		IBOutlet NSTextField*	numTestPatternsField;
		IBOutlet NSStepper*		numTestPatternsStepper;

		
		NSNumberFormatter*		rateFormatter;
		NSSize					settingSize;
		NSSize					histogramSize;
		NSSize					rateSize;
		NSSize					testSize;
		NSView*					blankView;
        
        IBOutlet NSPopUpButton* readWriteRegisterChanPopUpButton;// -tb-
        IBOutlet NSPopUpButton* readWriteRegisterNamePopUpButton;// -tb-
		IBOutlet NSTextField*	readWriteRegisterField;// -tb-
		IBOutlet NSTextField*	readWriteRegisterAdressField;// -tb-
		
};
#pragma mark ¥¥¥Initialization
- (id)   init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) checkWaveFormEnabledChanged:(NSNotification*)aNote;
- (void) checkEnergyEnabledChanged:(NSNotification*)aNote;
- (void) updateWindow;
- (void) versionRevisionChanged:(NSNotification*)aNote;
- (void) updateGUI:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) numTestPattersChanged:(NSNotification*)aNote;
- (void) fltRunModeChanged:(NSNotification*)aNote;
- (void) daqRunModeChanged:(NSNotification*)aNote;
- (void) postTriggerTimeChanged:(NSNotification*)aNote;
- (void) gainChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) gainArrayChanged:(NSNotification*)aNote;
- (void) thresholdArrayChanged:(NSNotification*)aNote;
- (void) triggersEnabledArrayChanged:(NSNotification*)aNote;
- (void) triggerEnabledChanged:(NSNotification*)aNote;
- (void) hitRatesEnabledArrayChanged:(NSNotification*)aNote;
- (void) hitRateEnabledChanged:(NSNotification*)aNote;
- (void) shapingTimesArrayChanged:(NSNotification*)aNote;
- (void) shapingTimeChanged:(NSNotification*)aNote;
- (void) filterGapChanged:(NSNotification*)aNote;
- (void) filterGapBinsChanged:(NSNotification*)aNote;
- (void) hitRateLengthChanged:(NSNotification*)aNote;
- (void) hitRateChanged:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) broadcastTimeChanged:(NSNotification*)aNote;
- (void) testStatusArrayChanged:(NSNotification*)aNote;
- (void) testEnabledArrayChanged:(NSNotification*)aNote;
- (void) testParamChanged:(NSNotification*)aNote;
- (void) patternChanged:(NSNotification*) aNote;
- (void) tModeChanged:(NSNotification*) aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) readoutPagesChanged:(NSNotification*)aNote;
//from here: hardware histogramming -tb- 2008-02-08
- (void) histoBinWidthChanged:(NSNotification*)aNote;
- (void) histoMinEnergyChanged:(NSNotification*)aNote;
- (void) histoMaxEnergyChanged:(NSNotification*)aNote;
- (void) histoFirstBinChanged:(NSNotification*)aNote;
- (void) histoLastBinChanged:(NSNotification*)aNote;
- (void) histoRunTimeChanged:(NSNotification*)aNote;
- (void) histoRecordingTimeChanged:(NSNotification*)aNote;
- (void) histoCalibrationValuesChanged:(NSNotification*)aNote;
- (void) histoCalibrationPlotterChanged:(NSNotification*)aNote;
- (void) histoCalibrationChanChanged:(NSNotification*)aNote;
- (void) histoPageNumChanged:(NSNotification*)aNote;
- (void) showHitratesDuringHistoCalibrationChanged:(NSNotification*)aNote;
- (void) histoClearAtStartChanged:(NSNotification*)aNote;
- (void) histoClearAfterReadoutChanged:(NSNotification*)aNote;
- (void) histoStopIfNotClearedChanged:(NSNotification*)aNote;
- (void) histoSelfCalibrationPercentChanged:(NSNotification*)aNote;

//low level -tb-
- (void) readWriteRegisterChanChanged:(NSNotification*)aNote;
- (void) readWriteRegisterNameChanged:(NSNotification*)aNote;


#pragma mark ¥¥¥Actions
- (IBAction) checkWaveFormEnabledAction:(id)sender;
- (IBAction) checkEnergyEnabledAction:(id)sender;
- (IBAction) numTestPatternsAction:(id)sender;
- (IBAction) readThresholdsGains:(id)sender;
- (IBAction) writeThresholdsGains:(id)sender;
- (IBAction) gainAction:(id)sender;
- (IBAction) triggerEnableAction:(id)sender;
- (IBAction) hitRateEnableAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) readFltModeButtonAction:(id)sender;
- (IBAction) writeFltModeButtonAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) daqRunModeAction: (id) sender;
- (IBAction) versionAction: (id) sender;
- (IBAction) versionFeatureCheckButtonAction: (id) sender;
- (IBAction) testAction: (id) sender;
- (IBAction) resetAction: (id) sender;
- (IBAction) triggerAction: (id) sender; 
- (IBAction) loadTimeAction: (id) sender;
- (IBAction) readTimeAction: (id) sender;
- (IBAction) shapingTimeAction: (id) sender;
- (IBAction) filterGapAction: (id) sender;
- (IBAction) hitRateLengthAction: (id) sender;
- (IBAction) hitRateAllAction: (id) sender;
- (IBAction) hitRateNoneAction: (id) sender;
- (IBAction) broadcastTimeAction: (id) sender;
- (IBAction) testEnabledAction:(id)sender;
- (IBAction) testParamAction:(id)sender;
- (IBAction) statusAction:(id)sender;
- (IBAction) tModeAction: (id) sender;
- (IBAction) initTPAction: (id) sender;
- (IBAction) readoutPagesAction: (id) sender; // ak 2.7.07
- (IBAction) postTriggTimeAction: (id) sender; // -tb- tmp
- (IBAction) readPostTriggTimeAction: (id) sender; // -tb- tmp
- (IBAction) writePostTriggTimeAction: (id) sender; // -tb- tmp
- (IBAction) helloButtonAction:(id)sender;//from here: hardware histogramming -tb- 2008-1-17
- (IBAction) readTRecButtonAction:(id)sender;
- (IBAction) readTRunAction:(id)sender;
- (IBAction) writeTRunAction:(id)sender;
- (IBAction) readFirstBinButtonAction:(id)sender;
- (IBAction) readLastBinButtonAction:(id)sender;
- (IBAction) changedBinWidthPopupButtonAction:(id)sender;//TODO: rename -tb-
- (IBAction) changedHistoMinEnergyAction:(id)sender;
- (IBAction) changedHistoMaxEnergyAction:(id)sender;
- (IBAction) changedHistoFirstBinAction:(id)sender;
- (IBAction) changedHistoLastBinAction:(id)sender;
- (IBAction) changedHistoRunTimeAction:(id)sender;
- (IBAction) changedHistoRecordingTimeAction:(id)sender;

- (IBAction) histoSetStandardButtonAction:(id)sender;
- (IBAction) startHistogramButtonAction:(id)sender;
- (IBAction) stopHistogramButtonAction:(id)sender;
- (IBAction) histoSelfCalibrationButtonAction:(id)sender;
- (IBAction) histoSelfCalibrationPercentAction:(id)sender;
- (IBAction) readHistogramDataButtonAction:(id)sender;
- (IBAction) readCurrentStatusButtonAction:(id)sender;
- (IBAction) changedHistoCalibrationChanPopupButtonAction:(id)sender;
- (IBAction) clearCurrentHistogramPageButtonAction:(id)sender;
- (IBAction) showHitratesDuringHistoCalibrationAction:(id)sender;
- (IBAction) histoClearAtStartAction:(id)sender;
- (IBAction) histoStopIfNotClearedAction:(id)sender;
- (IBAction) histoClearAtStartAction:(id)sender;
- (IBAction) histoClearAfterReadoutAction:(id)sender;
- (IBAction) vetoTestButtonAction:(id)sender;
- (IBAction) readVetoStateButtonAction:(id)sender;
- (IBAction) readEnableVetoButtonAction:(id)sender;
- (IBAction) writeEnableVetoButtonAction:(id)sender;
- (IBAction) readVetoDataButtonAction:(id)sender;

- (IBAction) readWriteRegisterChanPopUpButtonAction:(id)sender;
- (IBAction) readWriteRegisterNamePopUpButtonAction:(id)sender;
- (IBAction) readRegisterAdressButtonAction:(id)sender;
- (IBAction) readRegisterButtonAction:(id)sender;
- (IBAction) writeRegisterButtonAction:(id)sender;
- (IBAction) readRegisterWithAdressButtonAction:(id)sender;
- (IBAction) writeRegisterWithAdressButtonAction:(id)sender;

#pragma mark ¥¥¥Plot DataSource
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
