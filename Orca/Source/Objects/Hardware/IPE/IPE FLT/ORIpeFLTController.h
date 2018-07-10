
//
//  ORIpeFLTController.h
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
#import "ORIpeFLTModel.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORIpeFLTController : OrcaObjectController {
	@private
        IBOutlet NSButton*		settingLockButton;
		IBOutlet NSTextField*	dataMaskTextField;
		IBOutlet NSTextField*	thresholdOffsetField;
		IBOutlet NSTextField*	ledOffField;
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
		IBOutlet NSButton*      calibrateButton;
		
		IBOutlet NSTextField*	readoutPagesField; // ak, 2.7.07

		//rate page
		IBOutlet NSMatrix*		rateTextFields;
		
		IBOutlet ORValueBarGroupView*		rate0;
		IBOutlet ORValueBarGroupView*		totalRate;
		IBOutlet NSButton*					rateLogCB;
		IBOutlet ORCompositeTimeLineView*	timeRatePlot;
		IBOutlet NSButton*		timeRateLogCB;
		IBOutlet NSButton*		totalRateLogCB;
		IBOutlet NSTextField*	totalHitRateField;
		IBOutlet NSTabView*		tabView;	
		IBOutlet NSView*		totalView;
		IBOutlet NSTextField*   integrationTimeField;
		IBOutlet NSTextField*   coinTimeField;
		
		//test page
		IBOutlet NSButton*		testButton;
		IBOutlet NSMatrix*		testEnabledMatrix;
		IBOutlet NSMatrix*		testStatusMatrix;
		IBOutlet NSMatrix*		testParamsMatrix;
		
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
- (void) dataMaskChanged:(NSNotification*)aNote;
- (void) integrationTimeChanged:(NSNotification*)aNote;
- (void) coinTimeChanged:(NSNotification*)aNote;
- (void) thresholdOffsetChanged:(NSNotification*)aNote;
- (void) ledOffChanged:(NSNotification*)aNote;
- (void) interruptMaskChanged:(NSNotification*)aNote;
- (void) updateWindow;
- (void) settingsLockChanged:(NSNotification*)aNote;
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
- (void) testParamChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) readoutPagesChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) dataMaskTextFieldAction:(id)sender;
- (IBAction) coinTimeAction:(id)sender;
- (IBAction) integrationTimeAction:(id)sender;
- (IBAction) thresholdOffsetAction:(id)sender;
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
- (IBAction) testParamAction:(id)sender;
- (IBAction) statusAction:(id)sender;
- (IBAction) readoutPagesAction: (id) sender; // ak 2.7.07
- (IBAction) enableAllTriggersAction: (id) sender;
- (IBAction) enableNoTriggersAction: (id) sender;
- (IBAction) readThresholdsGains:(id)sender;
- (IBAction) writeThresholdsGains:(id)sender;
- (IBAction) calibrateAction:(id)sender;
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) calibrationSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
#pragma mark ¥¥¥Plot DataSource
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
