//
//  ORUnivVoltController.h
//  Orca
//
//  Created by Jan Wouters on Tues June 24, 2008
//  Copyright (c) 2008, LANS. All rights reserved.
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

#import "OrcaObjectController.h"
@class ORCompositeTimeLineView;
@class ORCircularBufferUV;

@interface ORUnivVoltController : OrcaObjectController {
	IBOutlet NSTableView*			mChnlTable;
	IBOutlet NSButton*				mChnlEnabled;
	IBOutlet NSButton*				mAlarmButton;
	IBOutlet NSTextField*			mAlarmEnabledTextField;
	IBOutlet NSStepper*				mChannelStepperField;
	IBOutlet NSTextField*			mChannelNumberField;
	IBOutlet NSTextField*			mDemandHV;
	IBOutlet NSTextField*			mMeasuredHV;
	IBOutlet NSTextField*			mMeasuredCurrent;
	IBOutlet NSTextField*			mTripCurrent;
	IBOutlet NSTextField*			mStatus;
	IBOutlet NSTextField*			mRampUpRate;
	IBOutlet NSTextField*			mRampDownRate;
	IBOutlet NSTextField*			mMVDZ;				// measured HV dead zone.  Reading has to change by more than this amount for measured HV to update.
	IBOutlet NSTextField*			mMCDZ;				// measured current dead zone.  "
	IBOutlet NSTextField*			mHVLimit;
	IBOutlet NSTextField*			mCmdStatus;			// Status of executed command.
	IBOutlet NSTextField*			mPollingTimeMinsField;	// Number of minutes between refresh of data.
	IBOutlet NSTextField*			mLastPoll;			// Time when last poll conducted.
	IBOutlet NSButton*				mStartStopPolling;  // Button that can start and stop the polling.
	IBOutlet ORCompositeTimeLineView*			mPlottingObj1;
	IBOutlet ORCompositeTimeLineView*			mPlottingObj2;
	char							mStatusByte;
	int								mCurrentChnl;		// Current channel visible in display.
	int								mOrigChnl;			// Channel last displayed in channel view.
}

#pragma mark •••Notifications
- (void) updateWindow;
- (void) channelEnabledChanged: (NSNotification*) aNote;
- (void) measuredCurrentChanged: (NSNotification*) aNote;
- (void) measuredHVChanged: (NSNotification*) aNote;
- (void) demandHVChanged: (NSNotification*) aNote;
- (void) rampUpRateChanged: (NSNotification*) aNote;
- (void) rampDownRateChanged: (NSNotification*) aNote;
- (void) tripCurrentChanged: (NSNotification*) aNote;
- (void) statusChanged: (NSNotification*) aNotes;
- (void) MVDZChanged: (NSNotification*) aNote;
- (void) MCDZChanged: (NSNotification*) aNote;
- (void) hvLimitChanged: (NSNotification*) aNote;
- (void) writeErrorMsg: (NSNotification*) aNote;
- (void) pollingTimeChanged: (NSNotification*) aNote;
- (void) pollingStatusChanged: (NSNotification*) aNote;
- (void) lastPollTimeChanged: (NSNotification*) aNote;
- (void) alarmChanged: (NSNotification*) aNote;
- (void) plotterDataChanged: (NSNotification*) aNotes;
- (void) miscAttributesChanged: (NSNotification* ) aNotes;
- (void) scaleAction: (NSNotification*) aNotes;
- (void) setValues: (NSNotification *) aNote;
- (void) channelChanged: (NSNotification*) aNote;

#pragma mark •••Actions
- (IBAction) enableAllChannels: (id) aSender;
- (IBAction) disableAllChannels: (id) aSender;
- (IBAction) setAlarm: (id) aSender;
- (IBAction) setChannelNumberField: (id) aSender;
- (IBAction) setChannelNumberStepper: (id) aSender;
- (IBAction) setDemandHV: (id) aSender;
- (IBAction) setChnlEnabled: (id) aSender;
- (IBAction) setTripCurrent: (id) aSender;
- (IBAction) setRampUpRate: (id) aSender;
- (IBAction) setRampDownRate: (id) aSender;
- (IBAction) setMVDZ: (id) aSender;
- (IBAction) setMCDZ: (id) aSender;
- (IBAction) setHardwareValesOneChannel: (id ) aSender;
- (IBAction) setHardwareValues: (id) aSender;
- (IBAction) hardwareValuesOneChannel: (id ) aSender;
- (IBAction) hardwareValues: (id) aSender;
- (IBAction) pollTimeAction: (id) aSender;
- (IBAction) startStopPolling: (id ) aSender;
//- (IBAction) updateTable: (id) aSender;

#pragma mark ***Getters
//- (float) demandHV: (int) aChannel;
//- (bool) isChnlEnabled: (int) aChannel;
//- (bool) chnlEnabled: (int) aChannel;
//- (float) measuredCurrent: (int) aChannel;
//- (float) tripCurrent: (int) aChannel;
//- (float) rampUpRate: (int) aChannel;
//- (float) demandHV: (int) aChannel;

#pragma mark ***Data methods
- (int) numberOfRowsInTableView: (NSTableView*) aTableView;
- (void) tableView: (NSTableView*) aTableView
       setObjectValue: (id) anObject
	   forTableColumn: (NSTableColumn*) aTableColumn
	   row: (int) aRowIndex;
- (id) tableView: (NSTableView*) aTableView
	   objectValueForTableColumn: (NSTableColumn*) aTableColumn
	   row: (int) aRowIndex;

#pragma mark ***Accessors

#pragma mark ***Utilities
- (void) setCurrentChnl: (NSNotification *) aNote;      // Helper function
- (void) setChnlValues: (int) aCurrentChannel;

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end

