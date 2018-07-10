
/*
 *  ORL2551ModelController.h
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
 *
 */
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
#import "ORL2551Model.h"

@class ORValueBarGroupView;

@interface ORL2551Controller : OrcaObjectController {
	@private
        IBOutlet NSMatrix*		onlineMaskMatrix;
        IBOutlet NSMatrix*		countsMatrix;
        IBOutlet NSMatrix*		rateMatrix;
        IBOutlet NSButton*		settingLockButton;
        IBOutlet NSTextField*   settingLockDocField;
        IBOutlet ORValueBarGroupView*	rate0;
        
        IBOutlet NSButton*		readNoResetButton;
        IBOutlet NSButton*		readResetButton;
        IBOutlet NSButton*		testLAMButton;
        IBOutlet NSButton*		disableLAMButton;
        IBOutlet NSButton*		enableLAMButton;
        IBOutlet NSButton*		clearButton;
        IBOutlet NSButton*		incAllButton;
        
        IBOutlet NSButton*		clearOnStartButton;
        IBOutlet NSButton*		shipButton;
        IBOutlet NSButton*		pollWhenRunningButton;
        IBOutlet NSPopUpButton*	pollRatePopup;
        IBOutlet NSProgressIndicator*	pollRunningIndicator;

        IBOutlet NSButton*		showHideTestButton;
};

- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) onlineMaskChanged:(NSNotification*)aNotification;
- (void) pollRateChanged:(NSNotification*)aNotification;
- (void) scalerCountChanged:(NSNotification*)aNotification;
- (void) pollRunningChanged:(NSNotification*)aNotification;
- (void) shipScalersChanged:(NSNotification*)aNotification;
- (void) clearOnStartChanged:(NSNotification*)aNotification;
- (void) pollWhenRunningChanged:(NSNotification*)aNotification;
- (void) scalerRateChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Actions
- (IBAction) settingLockAction:(id) sender;
- (IBAction) onlineAction:(id)sender;
- (IBAction) readNoResetAction:(id)sender;
- (IBAction) readResetAction:(id)sender;
- (IBAction) testLAMAction:(id)sender;
- (IBAction) disableLAMAction:(id)sender;
- (IBAction) enableLAMAction:(id)sender;
- (IBAction) incAllAction:(id)sender;
- (IBAction) clearAllAction:(id)sender;
- (IBAction) pollRateAction:(id)sender;
- (IBAction) shipScalersAction:(id)sender;
- (IBAction) pollWhenRunningAction:(id)sender;
- (IBAction) clearOnStartAction:(id)sender;
- (IBAction) showHideTestAction:(id)sender;
- (IBAction) pollNowAction:(id)sender;

 - (void) showError:(NSException*)anException name:(NSString*)name fCode:(int)i;

@end