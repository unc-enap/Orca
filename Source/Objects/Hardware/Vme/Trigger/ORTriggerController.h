//
//  ORTriggerController.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 16 2002.
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


@interface ORTriggerController : OrcaObjectController {
	
    IBOutlet NSTabView*		tabView;
    IBOutlet NSTextField*       slotField;
    IBOutlet NSStepper* 	addressStepper;
    IBOutlet NSTextField* 	addressText;

    IBOutlet NSTextField*	gtidLowerText;
    IBOutlet NSStepper*		gtidLowerStepper;
    IBOutlet NSTextField*	gtidUpperText;
    IBOutlet NSStepper*		gtidUpperStepper;

    IBOutlet NSButton*		shipEvt1ClkButton;
    IBOutlet NSButton*		shipEvt2ClkButton;
    IBOutlet NSButton*          initTrig2CB;
    IBOutlet NSButton*		initMultiBoardCB;
    IBOutlet NSButton*		useSoftwareGtIdCB;
    IBOutlet NSButton*		useNoHardwareCB;
    IBOutlet NSButton*		useMSAMCB;

    IBOutlet NSTextField*	gtErrorField;
    IBOutlet NSTextField*	softwareGtIdField;

    IBOutlet NSTextField*	trigger1NameField;
    IBOutlet NSTextField*	trigger2NameField;

    IBOutlet NSButton*		settingLockButton;
    IBOutlet NSButton*		specialLockButton;
    IBOutlet NSTextField*       settingLockDocField;
    IBOutlet NSTextField*       specialLockDocField;

    IBOutlet NSButton*		alteraRegButton;
    IBOutlet NSButton*		gtid1Button;
    IBOutlet NSButton*		gtid2Button;
    IBOutlet NSButton*		boardIDButton;
    IBOutlet NSButton*		getStatusButton;
    IBOutlet NSButton*		enableMultiBoardButton;
    IBOutlet NSButton*		disableMultiBoardButton;
    IBOutlet NSButton*		enableTrig2InhibButton;
    IBOutlet NSButton*		disableTrig2InhibButton;

    IBOutlet NSButton*		loadLowerGTIDButton;
    IBOutlet NSButton*		loadUpperGTIDButton;
    IBOutlet NSButton*		readLowerGTID1Button;
    IBOutlet NSButton*		readUpperGTID1Button;
    IBOutlet NSButton*		readLowerGTID2Button;
    IBOutlet NSButton*		readUpperGTID2Button;
    IBOutlet NSButton*		softGTButton;
    IBOutlet NSButton*		syncClrButton;
    IBOutlet NSButton*		gtSyncClrButton;
    IBOutlet NSButton*		gtSyncClr24Button;
    IBOutlet NSButton*		latchGTID1Button;
    IBOutlet NSButton*		latchGTID2Button;
    IBOutlet NSButton*		pollEventButton;


    //IBOutlet NSTextField*	vmeClkLowerText;
    //IBOutlet NSStepper*		vmeClkLowerStepper;
    //IBOutlet NSTextField*	vmeClkMiddleText;
    //IBOutlet NSStepper*		vmeClkMiddleStepper;
    //IBOutlet NSTextField*	vmeClkUpperText;
    //IBOutlet NSStepper*		vmeClkUpperStepper;
}

- (void) registerNotificationObservers;

#pragma mark ¥¥¥Accessors
- (NSTextField*) slotField;
- (NSStepper*)	 addressStepper;
- (NSTextField*) addressText;

- (NSTextField*) gtidLowerText;
- (NSStepper*)   gtidLowerStepper;
- (NSTextField*) gtidUpperText;
- (NSStepper*) 	 gtidUpperStepper;

//- (NSTextField*) vmeClkLowerText;
//- (NSStepper*) 	 vmeClkLowerStepper;
//- (NSTextField*) vmeClkMiddleText;
//- (NSStepper*) 	 vmeClkMiddleStepper;
//- (NSTextField*) vmeClkUpperText;
//- (NSStepper*) 	 vmeClkUpperStepper;


#pragma mark ¥¥¥Interface Management
- (void) slotChanged:(NSNotification*)aNotification;
- (void) baseAddressChanged:(NSNotification*)aNotification;

- (void) shipEvt1ClkChanged:(NSNotification*)aNotification;
- (void) shipEvt2ClkChanged:(NSNotification*)aNotification;

- (void) gtidLowerChanged:(NSNotification*)aNotification;
- (void) gtidUpperChanged:(NSNotification*)aNotification;

- (void) gtErrorCountChanged:(NSNotification*)aNotification;
- (void) initMultiBoardChanged:(NSNotification*)aNotification;
- (void) initTrig2Changed:(NSNotification*)aNotification;

- (void) useSoftwareGtIdChanged:(NSNotification*)aNotification;
- (void) useNoHardwareChanged:(NSNotification*)aNotification;
- (void) softwareGtIdChanged:(NSNotification*)aNotification;
- (void) runStatusChanged:(NSNotification*)aNotification;

- (void) trigger1NameChanged:(NSNotification*)aNotification;
- (void) trigger2NameChanged:(NSNotification*)aNotification;

//- (void) vmeClkLowerChanged:(NSNotification*)aNotification;
//- (void) vmeClkMiddleChanged:(NSNotification*)aNotification;
//- (void) vmeClkUpperChanged:(NSNotification*)aNotification;

- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) specialLockChanged:(NSNotification*)aNotification;
- (void) useMSAMChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) baseAddressAction:(id)sender;

- (IBAction) gtidLowerAction:(id)sender;
- (IBAction) gtidUpperAction:(id)sender;
- (IBAction) useSoftwareGtIdAction:(id)sender;
- (IBAction) useNoHardwareAction:(id)sender;

//- (IBAction) vmeClkLowerAction:(id)sender;
//- (IBAction) vmeClkMiddleAction:(id)sender;
//- (IBAction) vmeClkUpperAction:(id)sender;


- (IBAction) boardIDAction:(id)sender;
- (IBAction) statusReadAction:(id)sender;

- (IBAction) resetAlteraAction:(id)sender;
- (IBAction) resetEvent1:(id)sender;
- (IBAction) resetEvent2:(id)sender;
//- (IBAction) resetClockAction:(id)sender;

- (IBAction) loadLowerGtidAction:(id)sender;
- (IBAction) loadUpperGtidAction:(id)sender;

- (IBAction) readLowerGtid1Action:(id)sender;
- (IBAction) readUpperGtid1Action:(id)sender;
- (IBAction) readLowerGtid2Action:(id)sender;
- (IBAction) readUpperGtid2Action:(id)sender;

- (IBAction) shipEvt1ClkAction:(id)sender;
- (IBAction) shipEvt2ClkAction:(id)sender;
- (IBAction) initMultiBoardAction:(id)sender;
- (IBAction) initTrig2Action:(id)sender;

- (IBAction) trigger1NameAction:(id)sender;
- (IBAction) trigger2NameAction:(id)sender;
- (IBAction) useMSAMAction:(id)sender;


//- (IBAction) loadLowerClockAction:(id)sender;
//- (IBAction) loadMiddleClockAction:(id)sender;
//- (IBAction) loadUpperClockAction:(id)sender;
//- (IBAction) readLowerClockAction:(id)sender;
//- (IBAction) readMiddleClockAction:(id)sender;
//- (IBAction) readUpperClockAction:(id)sender;

//- (IBAction) enableClockAction:(id)sender;
//- (IBAction) disableClockAction:(id)sender;

- (IBAction) enableMultiBoardAction:(id)sender;
- (IBAction) disableMultiBoardAction:(id)sender;

- (IBAction) softGtAction:(id)sender;
- (IBAction) gtSyncClrAction:(id)sender;
- (IBAction) syncClrAction:(id)sender;
- (IBAction) latchGtid1Action:(id)sender;
- (IBAction) latchGtid2Action:(id)sender;
- (IBAction) syncClr24Action:(id)sender;
//- (IBAction) latchClkAction:(id)sender;
- (IBAction) testPollSeqAction:(id)sender;

- (IBAction) enableBusyAction:(id)sender;
- (IBAction) disableBusyAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) specialLockAction:(id) sender;


#pragma mark ¥¥¥Helper Methods
- (void) enableBusy:(BOOL)enable;
- (void) enableMultiBoard:(BOOL)enable;

@end
