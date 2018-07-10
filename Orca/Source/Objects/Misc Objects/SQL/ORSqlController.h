//
//  ORSqlController.h
//  Orca
//
//  Created by Mark Howe on 10/18/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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

@class ORValueBarGroupView;

@interface ORSqlController : OrcaObjectController 
{	
	IBOutlet NSTextField* hostNameField;
	IBOutlet NSButton*	  stealthModeButton;
	IBOutlet NSTextField* userNameField;
	IBOutlet NSTextField* passwordField;
	IBOutlet NSTextField* dataBaseNameField;
	IBOutlet NSTextField* connectionValidField;
    IBOutlet NSButton*    sqlLockButton;
    IBOutlet NSButton*    connectionButton;
    IBOutlet ORValueBarGroupView*  queueValueBar;
	IBOutlet NSButton*    dropAllTablesButton;

	double queueCount;
}

#pragma mark ***Interface Management
- (void) registerNotificationObservers;
- (void) stealthModeChanged:(NSNotification*)aNote;
- (void) hostNameChanged:(NSNotification*)aNote;
- (void) userNameChanged:(NSNotification*)aNote;
- (void) passwordChanged:(NSNotification*)aNote;
- (void) dataBaseNameChanged:(NSNotification*)aNote;
- (void) sqlLockChanged:(NSNotification*)aNote;
- (void) connectionValidChanged:(NSNotification*)aNote;
- (void) updateConnectionValidField;
- (void) setQueCount:(NSNumber*)n;

#pragma mark ¥¥¥Actions
- (IBAction) stealthModeAction:(id)sender;
- (IBAction) hostNameAction:(id)sender;
- (IBAction) userNameAction:(id)sender;
- (IBAction) passwordAction:(id)sender;
- (IBAction) databaseNameAction:(id)sender;
- (IBAction) sqlLockAction:(id)sender;
- (IBAction) connectionAction:(id)sender;
- (IBAction) createAction:(id)sender;
- (IBAction) removeEntryAction:(id)sender;
- (IBAction) dropAllTablesAction:(id)sender;

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) createActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
- (void) dropActionDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)userInfo;
#endif
@end
