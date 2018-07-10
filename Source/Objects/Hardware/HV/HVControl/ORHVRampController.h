//
//  ORHVRampContoller.h
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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



@class ORHVSupply;
@class ORCompositeTimeLineView;

@interface ORHVRampController : OrcaObjectController {

    IBOutlet NSMatrix* controlMatrix;
    IBOutlet NSMatrix* timeMatrix;
    IBOutlet NSMatrix* targetMatrix;
    IBOutlet NSMatrix* dacMatrix;
    IBOutlet NSMatrix* adcMatrix;
    IBOutlet NSMatrix* currentMatrix;
    IBOutlet NSMatrix* stateMatrix;
    IBOutlet NSTextField*   settingLockDocField;
    
    IBOutlet NSButton* dirSelectionButton;
    IBOutlet NSButton* onButton;
    IBOutlet NSButton* offButton;
    IBOutlet NSButton* startRampButton;
    IBOutlet NSButton* stopRampButton;
    IBOutlet NSButton* rampToZeroButton;
    IBOutlet NSButton* panicButton;
    IBOutlet NSButton* statusButton;	
    IBOutlet NSPopUpButton* pollingButton;
    IBOutlet NSTextField* hvStateDirField;
    IBOutlet NSImageView* statusImage;
    IBOutlet NSButton* syncButton;	
    IBOutlet NSTextField* pollingAlertField;

    IBOutlet NSMatrix* voltageAdcOffsetMatrix;
    IBOutlet NSMatrix* voltageAdcSlopeMatrix;

    IBOutlet NSButton* calibrationLockButton;
    IBOutlet NSButton* hvLockButton;

    IBOutlet NSButton*		setCurrentToFileButton;
    IBOutlet NSButton*		saveCurrentToFileButton;
    IBOutlet NSTextField*	currentFileField;
	IBOutlet ORCompositeTimeLineView*   currentPlotter;
}

#pragma mark ¥¥¥Notifications
- (void) pollingStateChanged:(NSNotification*)aNotification;
- (void) dirChanged:(NSNotification*)aNotification;
- (void) controllChanged:(NSNotification*)aNotification;
- (void) rampTimeChanged:(NSNotification*)aNotification;
- (void) targetChanged:(NSNotification*)aNotification;
- (void) dacChanged:(NSNotification*)aNotification;
- (void) adcChanged:(NSNotification*)aNotification;
- (void) currentChanged:(NSNotification*)aNotification;
- (void) stateChanged:(NSNotification*)aNotification;
- (void) rampStartedOrStopped:(NSNotification*)aNotification;

- (void) voltageAdcOffsetChanged:(NSNotification*)aNotification;
- (void) voltageAdcSlopeChanged:(NSNotification*)aNotification;
- (void) hvLockChanged:(NSNotification*)aNotification;
- (void) calibrationLockChanged:(NSNotification*)aNotification;
- (void) runStatusChanged:(NSNotification*)aNotification;
- (void) saveCurrentToFileChanged:(NSNotification*)aNotification;
- (void) currentFileChanged:(NSNotification*)aNotification;
- (void) updateTrends:(NSNotification*)aNote;

- (void) updateButtons;
- (void) checkGlobalSecurity;

#pragma mark ¥¥¥Actions
- (IBAction) supplyOnAction:(id)sender;
- (IBAction) supplyOffAction:(id)sender;
- (IBAction) startRampAction:(id)sender;
- (IBAction) stopRampAction:(id)sender;
- (IBAction) rampToZeroAction:(id)sender;
- (IBAction) panicAction:(id)sender;
- (IBAction) panicSystemAction:(id)sender;
- (IBAction) setPollingAction:(id)sender;
- (IBAction) pollNowAction:(id)sender;
- (IBAction) chooseDir:(id)sender;
- (IBAction) controllAction:(id)sender;
- (IBAction) rampTimeAction:(id)sender;
- (IBAction) targetAction:(id)sender;
- (IBAction) syncAction:(id)sender;

- (IBAction) adcOffsetAction:(id)sender;
- (IBAction) adcSlopeAction:(id)sender;

- (IBAction) calibrationLockAction:(id)sender;
- (IBAction) hvLockAction:(id)sender;
- (IBAction) saveCurrentToFileAction:(id)sender;
- (IBAction) setCurrentFileAction:(id)sender;

- (void) setTextColor:(NSTextFieldCell*)aCell supply:(ORHVSupply*)aSupply;
- (int)	numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
