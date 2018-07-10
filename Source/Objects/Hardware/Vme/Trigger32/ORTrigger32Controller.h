//
//  Trigger32Controller.h
//  Orca
//
//  Created by Mark Howe on Tue May 4, 2004.
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


@interface ORTrigger32Controller : OrcaObjectController {
	
    //Setup tab
    IBOutlet NSTabView*		tabView;
	IBOutlet NSButton*		restartClkAtRunStartButton;
    IBOutlet NSTextField*   slotField;
    IBOutlet NSStepper* 	addressStepper;
    IBOutlet NSTextField* 	addressText;

    IBOutlet NSButton*		boardIDButton;
    IBOutlet NSButton*		getStatusButton1;

    IBOutlet NSTextField*	trigger1NameField;
    IBOutlet NSTextField*	trigger2NameField;

    IBOutlet NSButton*		trigger1GTXorCB;
    IBOutlet NSButton*		shipEvt1ClkCB;
    
    IBOutlet NSButton*		trigger2GTXorCB;
    IBOutlet NSButton*      trigger2eventInputEnableCB;
    IBOutlet NSButton*		trigger2BusyOutputEnableCB;
    IBOutlet NSButton*		shipEvt2ClkCB;

    IBOutlet NSButton*		useSoftwareGtIdCB;
    IBOutlet NSButton*		useNoHardwareCB;
    IBOutlet NSButton*		enableLiveTimeCB;
    IBOutlet NSButton*		useMSAMCB;
    IBOutlet NSStepper* 	prescaleStepper;
    IBOutlet NSTextField* 	prescaleText;

    IBOutlet NSButton*		enableTimeClockCB;

    IBOutlet NSButton*		initButton;

    IBOutlet NSTextField*	gtErrorField;

    IBOutlet NSButton*		settingLockButton;
    IBOutlet NSTextField*   settingLockDocField;

    IBOutlet NSBox*		setUpTrigger1Box;
    IBOutlet NSBox*		setUpTrigger2Box;

    IBOutlet NSButton*	latchLiveTimeButton;
    IBOutlet NSButton*	dumpLiveTimeButton;
    IBOutlet NSButton*	resetLiveTimeButton;

    
    //Testing tab
    IBOutlet NSButton*		specialLockButton;
    IBOutlet NSTextField*       specialLockDocField;

    IBOutlet NSTextField*       testingTrigger1Label;
    IBOutlet NSTextField*       testingTrigger2Label;
    
    IBOutlet NSButton*		getStatusButton2;
    IBOutlet NSButton*		softGTButton;
    IBOutlet NSButton*		syncClrButton;
    IBOutlet NSButton*		gtSyncClrButton;
    IBOutlet NSButton*		gtSyncClr24Button;
    IBOutlet NSButton*		latchGTID1Button;
    IBOutlet NSButton*		latchGTID2Button;
    IBOutlet NSButton*		latchClock1Button;
    IBOutlet NSButton*		latchClock2Button;
    IBOutlet NSButton*		pollEventButton;
    IBOutlet NSButton*		requestSGTIDButton;
    IBOutlet NSButton*		readSGTIDButton;

    IBOutlet NSTextField*	gtIdValueText;
    IBOutlet NSStepper*		gtIdValueStepper;
    IBOutlet NSButton*		loadGTIDButton;
    IBOutlet NSButton*		readGTID1Button;
    IBOutlet NSButton*		readGTID2Button;
    
    IBOutlet NSTextField*	timeClockLowerText;
    IBOutlet NSStepper*		timeClockLowerStepper;
    IBOutlet NSTextField*	timeClockUpperText;
    IBOutlet NSStepper*		timeClockUpperStepper;
    IBOutlet NSButton*		loadUpperTimerCounterButton;
    IBOutlet NSButton*		loadLowerTimerCounterButton;
    IBOutlet NSButton*		readTimerCounter1Button;
    IBOutlet NSButton*		readTimerCounter2Button;

    IBOutlet NSTextField*	testRegText;
    IBOutlet NSStepper*		testRegStepper;
    IBOutlet NSButton*		loadTestRegButton;
    IBOutlet NSButton*		readTestRegButton;

    IBOutlet NSButton*		resetAlteraButton;
    IBOutlet NSButton*		resetClockButton;
    IBOutlet NSButton*		resetErrorButton;
    IBOutlet NSButton*		resetGT1Button;
    IBOutlet NSButton*		resetGT2Button;
    IBOutlet NSButton*		resetMSAMButton;

}

- (void) registerNotificationObservers;

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Interface Management
- (void) restartClkAtRunStartChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) baseAddressChanged:(NSNotification*)aNotification;

- (void) shipEvt1ClkChanged:(NSNotification*)aNotification;
- (void) shipEvt2ClkChanged:(NSNotification*)aNotification;

- (void) gtIdValueChanged:(NSNotification*)aNotification;

- (void) gtErrorCountChanged:(NSNotification*)aNotification;
- (void) trigger2EventEnabledChanged:(NSNotification*)aNotification;
- (void) trigger2BusyChanged:(NSNotification*)aNotification;

- (void) useSoftwareGtIdChanged:(NSNotification*)aNotification;
- (void) useNoHardwareChanged:(NSNotification*)aNotification;
- (void) runStatusChanged:(NSNotification*)aNotification;

- (void) trigger1NameChanged:(NSNotification*)aNotification;
- (void) trigger2NameChanged:(NSNotification*)aNotification;

- (void) trigger1GTXorChanged:(NSNotification*)aNotification;
- (void) trigger2GTXorChanged:(NSNotification*)aNotification;
- (void) clockEnabledChanged:(NSNotification*)aNotification;
- (void) liveTimeEnabledChanged:(NSNotification*)aNotification;

- (void) timeClockLowerChanged:(NSNotification*)aNotification;
- (void) timeClockUpperChanged:(NSNotification*)aNotification;
- (void) testRegChanged:(NSNotification*)aNotification;

- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) specialLockChanged:(NSNotification*)aNotification;
- (void) useMSAMChanged:(NSNotification*)aNotification;
- (void) prescaleChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) restartClkAtRunStartAction:(id)sender;
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) prescaleAction:(id)sender;

- (IBAction) useSoftwareGtIdAction:(id)sender;
- (IBAction) useNoHardwareAction:(id)sender;

- (IBAction) timeClockLowerAction:(id)sender;
- (IBAction) timeClockUpperAction:(id)sender;


- (IBAction) boardIDAction:(id)sender;
- (IBAction) readStatusAction:(id)sender;

- (IBAction) resetAlteraAction:(id)sender;
- (IBAction) resetGT1Action:(id)sender;
- (IBAction) resetGT2Action:(id)sender;
- (IBAction) resetClockAction:(id)sender;
- (IBAction) resetErrorCountAction:(id)sender;
- (IBAction) resetMSAMAction:(id)sender;

- (IBAction) gtIdValueAction:(id)sender;
- (IBAction) loadGtIdAction:(id)sender;
- (IBAction) readGtId1Action:(id)sender;
- (IBAction) readGtId2Action:(id)sender;


- (IBAction) testRegValueAction:(id)sender;
- (IBAction) loadTestRegAction:(id)sender;
- (IBAction) readTestRegAction:(id)sender;

- (IBAction) shipEvt1ClkAction:(id)sender;
- (IBAction) shipEvt2ClkAction:(id)sender;

- (IBAction) trigger1NameAction:(id)sender;
- (IBAction) trigger2NameAction:(id)sender;
- (IBAction) useMSAMAction:(id)sender;
- (IBAction) trigger1GTXorAction:(id) sender;
- (IBAction) trigger2GTXorAction:(id) sender;
- (IBAction) trigger2BusyOutputAction:(id) sender;
- (IBAction) trigger2EventInputAction:(id) sender;
- (IBAction) enableTimeClockAction:(id) sender;
- (IBAction) enableLiveTimeAction:(id) sender;

- (IBAction) loadLowerClockAction:(id)sender;
- (IBAction) loadUpperClockAction:(id)sender;
- (IBAction) latchTrigger1ClockAction:(id)sender;
- (IBAction) latchTrigger2ClockAction:(id)sender;
- (IBAction) readLowerTrigger1ClockAction:(id)sender;
- (IBAction) readUpperTrigger1ClockAction:(id)sender;
- (IBAction) readLowerTrigger2ClockAction:(id)sender;
- (IBAction) readUpperTrigger2ClockAction:(id)sender;
- (IBAction) readTrigger1ClockAction:(id)sender;
- (IBAction) readTrigger2ClockAction:(id)sender;

- (IBAction) softGtAction:(id)sender;
- (IBAction) gtSyncClrAction:(id)sender;
- (IBAction) syncClrAction:(id)sender;
- (IBAction) latchGtid1Action:(id)sender;
- (IBAction) latchGtid2Action:(id)sender;
- (IBAction) syncClr24Action:(id)sender;
- (IBAction) testPollSeqAction:(id)sender;
- (IBAction) requestSGTIDAction:(id)sender;
- (IBAction) readSGTIDAction:(id)sender;

- (IBAction) dumpLiveTimeAction:(id) sender;
- (IBAction) resetLiveTimeAction:(id) sender;
- (IBAction) latchLiveTimeAction:(id) sender;


- (IBAction) initAction:(id)sender;

- (IBAction) settingLockAction:(id) sender;
- (IBAction) specialLockAction:(id) sender;


@end
