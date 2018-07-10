
/*
 *  ORL2301ModelController.h
 *  Orca
 *
 *  Created by Sam Meijer, Jason Detwiler, and David Miller, July 2012.
 *  Adapted from AD811 code by Mark Howe, written Sat Nov 16 2002.
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
#import "ORL2301Model.h"

@interface ORL2301Controller : OrcaObjectController {
@private
	IBOutlet NSButton*	settingLockButton;
	IBOutlet NSTextField*   settingLockDocField;
	
	IBOutlet NSButton*	clearAllButton;
	IBOutlet NSButton*	startQVTButton;
	IBOutlet NSButton*	stopQVTButton;
	IBOutlet NSButton*	readAllButton;
	IBOutlet NSButton*	statusButton;
	IBOutlet NSButton*	testButton;
	
	IBOutlet NSButton*	suppressZerosButton;
	IBOutlet NSButton*	includeTimingButton;
	IBOutlet NSButton*      allowOverflowButton;
	
};

- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) settingsLockChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) suppressZerosChanged:(NSNotification*)aNotification;
- (void) includeTimingChanged:(NSNotification*)aNotification;
- (void) allowOverflowChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Actions
- (IBAction) settingLockAction:(id) sender;

- (IBAction) clearAllAction:(id)sender;
- (IBAction) startQVTAction:(id)sender;
- (IBAction) stopQVTAction:(id)sender;
- (IBAction) readAllAction:(id)sender;
- (IBAction) statusAction:(id)sender;
- (IBAction) testAction:(id)sender;

- (IBAction) includeTimingAction:(id)sender;
- (IBAction) suppressZerosAction:(id)sender;
- (IBAction) allowOverflowAction:(id)sender;


- (void) showError:(NSException*)anException name:(NSString*)name fCode:(int)i;

@end
