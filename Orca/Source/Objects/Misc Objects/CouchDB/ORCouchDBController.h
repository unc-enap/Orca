//
//  ORCouchDBController.h
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

@interface ORCouchDBController : OrcaObjectController 
{	
	IBOutlet NSTextField* remoteHostNameField;
	IBOutlet NSTextField* localHostNameField;
	IBOutlet NSTextField* replicationRunningTextField;
	IBOutlet NSButton*	  keepHistoryCB;
	IBOutlet NSTextField* userNameField;
	IBOutlet NSTextField* passwordField;
	IBOutlet NSTextField* portField;
	IBOutlet NSTextField* dataBaseNameField;
	IBOutlet NSTextField* historyDataBaseNameField;
    IBOutlet NSButton*    couchDBLockButton;
    IBOutlet NSMatrix*    queueCountsMatrix;
    IBOutlet ORValueBarGroupView*  queueValueBars;
	IBOutlet NSButton*	  stealthModeButton;
	IBOutlet NSTextField* dbSizeField;
	IBOutlet NSTextField* dbHistorySizeField;
	IBOutlet NSTextField* keepHistoryStatusField;
	IBOutlet NSTextField* dbStatusField;
    IBOutlet NSTextField* usingUpdateHandlerField;
    IBOutlet NSTextField* alertMessageField;
    IBOutlet NSPopUpButton* alertTypePU;
    IBOutlet NSButton*	  skipDataSetsCB;
    IBOutlet NSButton*    useHttpsCB;
}

#pragma mark ***Interface Management
- (void) alertMessageChanged:(NSNotification*)aNote;
- (void) replicationRunningChanged:(NSNotification*)aNote;
- (void) keepHistoryChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) stealthModeChanged:(NSNotification*)aNote;
- (void) useHttpsChanged:(NSNotification*)aNote;
- (void) remoteHostNameChanged:(NSNotification*)aNote;
- (void) localHostNameChanged:(NSNotification*)aNote;
- (void) userNameChanged:(NSNotification*)aNote;
- (void) passwordChanged:(NSNotification*)aNote;
- (void) portChanged:(NSNotification*)aNote;
- (void) dataBaseNameChanged:(NSNotification*)aNote;
- (void) couchDBLockChanged:(NSNotification*)aNote;
- (void) setQueCount:(NSNumber*)n;
- (void) dataBaseInfoChanged:(NSNotification*)aNote;
- (void) usingUpdateHandlerChanged:(NSNotification*)aNote;
- (void) skipDataSetsChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) startReplicationAction:(id)sender;
- (IBAction) createRemoteDBAction:(id)sender;
- (IBAction) keepHistoryAction:(id)sender;
- (IBAction) stealthModeAction:(id)sender;
- (IBAction) remoteHostNameAction:(id)sender;
- (IBAction) localHostNameAction:(id)sender;
- (IBAction) userNameAction:(id)sender;
- (IBAction) passwordAction:(id)sender;
- (IBAction) portAction:(id)sender;
- (IBAction) couchDBLockAction:(id)sender;
- (IBAction) createAction:(id)sender;
- (IBAction) deleteAction:(id)sender;
- (IBAction) listAction:(id)sender;
- (IBAction) infoAction:(id)sender;
- (IBAction) compactAction:(id)sender;
- (IBAction) listTasks:(id)sender;
- (IBAction) alertMessageAction:(id)sender;
- (IBAction) alertTypeAction:(id)sender;
- (IBAction) postAlertAction:(id)sender;
- (IBAction) skipDataSetsAction:(id)sender;
- (IBAction) useHttpsAction:(id)sender;
@end
