
//
//  ORAugerFLTController.h
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
#import "ORAugerFLTModel.h"

@class ORPlotter1D;
@class ORValueBar;

@interface ORAugerFLTController : OrcaObjectController {
	@private
        IBOutlet NSButton*		settingLockButton;
		IBOutlet NSButton*		checkWaveFormEnabledButton;
		IBOutlet NSPopUpButton*	modeButton;
		IBOutlet NSButton*		versionButton;
		IBOutlet NSButton*		statusButton;
		IBOutlet NSButton*		readControlButton;
		IBOutlet NSButton*		writeControlButton;
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
		IBOutlet NSTextField*	hitRateLengthField;
		IBOutlet NSButton*		hitRateAllButton;
		IBOutlet NSButton*		hitRateNoneButton;
        IBOutlet NSButton*		broadcastTimeCB;
		
		IBOutlet NSTextField*	readoutPagesField; // ak, 2.7.07

		//rate page
		IBOutlet NSMatrix*		rateTextFields;
		
		IBOutlet ORValueBar*	rate0;
		IBOutlet ORValueBar*	totalRate;
		IBOutlet NSButton*		rateLogCB;
		IBOutlet ORPlotter1D*	timeRatePlot;
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
		NSSize					rateSize;
		NSSize					testSize;
		NSView*					blankView;
		
};
#pragma mark ¥¥¥Initialization
- (id)   init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) checkWaveFormEnabledChanged:(NSNotification*)aNote;
- (void) updateWindow;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) numTestPattersChanged:(NSNotification*)aNote;
- (void) modeChanged:(NSNotification*)aNote;
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

#pragma mark ¥¥¥Actions
- (IBAction) checkWaveFormEnabledAction:(id)sender;
- (IBAction) numTestPatternsAction:(id)sender;
- (IBAction) readThresholdsGains:(id)sender;
- (IBAction) writeThresholdsGains:(id)sender;
- (IBAction) gainAction:(id)sender;
- (IBAction) triggerEnableAction:(id)sender;
- (IBAction) hitRateEnableAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) readControlButtonAction:(id)sender;
- (IBAction) writeControlButtonAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) modeAction: (id) sender;
- (IBAction) versionAction: (id) sender;
- (IBAction) testAction: (id) sender;
- (IBAction) resetAction: (id) sender;
- (IBAction) triggerAction: (id) sender; 
- (IBAction) loadTimeAction: (id) sender;
- (IBAction) readTimeAction: (id) sender;
- (IBAction) shapingTimeAction: (id) sender;
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

#pragma mark ¥¥¥Plot DataSource
- (int)		numberOfPointsInPlot:(id)aPlotter dataSet:(int)set;
- (float)  	plotter:(id) aPlotter dataSet:(int)set dataValue:(int) x ;
- (unsigned long)  	secondsPerUnit:(id) aPlotter;

@end