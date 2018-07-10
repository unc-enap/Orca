//
//  ORCouchDBController.h
//  Orca
//
//  Created by Thomas Stolz on 05/20/13.
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

@interface ORCouchDBListenerController : OrcaObjectController
{
    //CouchDB configurations
    IBOutlet NSComboBox* databaseListView;
    IBOutlet NSButton* startStopButton;
    IBOutlet NSTextField* heartbeatField;
    IBOutlet NSTextField* hostField;
    IBOutlet NSTextField* userNameField;
    IBOutlet NSTextField* portField;
    IBOutlet NSSecureTextField* pwdField;
    
    //Command Section
    IBOutlet NSTableView* cmdTable;
    IBOutlet NSButton* cmdRemoveButton;
    IBOutlet NSButton* cmdEditButton;
    IBOutlet NSButton* cmdApplyButton;
    IBOutlet NSTextField* cmdLabelField;
    IBOutlet NSComboBox* cmdObjectBox;
    IBOutlet NSComboBox* cmdMethodBox;
    IBOutlet NSTextField* cmdInfoField;
    IBOutlet NSButton* cmdCommonMethodsOnly;
    IBOutlet NSButton* cmdObjectUpdateButton;
    IBOutlet NSButton* cmdTestExecuteButton;
    IBOutlet NSButton* cmdListenOnStart;
    IBOutlet NSButton* cmdSaveHeartbeatsWhileListening;
    IBOutlet NSTextField* cmdValueField;
    IBOutlet NSTextField* updateDesignDocField;
    IBOutlet NSTextField* updateNameField;
    
    //Status Log
    IBOutlet NSTextView* statusLog;
    
}


#pragma mark ***Interface Management
- (void) databaseListChanged:(NSNotification *)aNote;
- (void) listeningChanged:(NSNotification *)aNote;
- (void) objectListChanged:(NSNotification *)aNote;
- (void) commandsChanged:(NSNotification *)aNote;
- (void) statusLogChanged:(NSNotification*)aNote;
- (void) hostChanged:(NSNotification *)aNote;
- (void) portChanged:(NSNotification*)aNote;
- (void) hostChanged:(NSNotification *)aNote;
- (void) databaseChanged:(NSNotification*)aNote;
- (void) usernameChanged:(NSNotification*)aNote;
- (void) passwordChanged:(NSNotification*)aNote;
- (void) heartbeatChanged:(NSNotification*)aNote;
- (void) updatePathChanged:(NSNotification*)aNote;
- (void) listenOnStartChanged:(NSNotification*)aNote;
- (void) saveHeartbeatsWhileListeningChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (void) updateDisplays;
- (void) disableControls;
- (void) enableControls;
- (IBAction) databaseSelected:(id)sender;
- (IBAction) heartbeatSet:(id)sender;
- (IBAction) hostSet:(id)sender;
- (IBAction) portSet:(id)sender;
- (IBAction) userNameSet:(id)Sender;
- (IBAction) pwdSet:(id)Sender;
- (IBAction) changeListening:(id)sender;
- (IBAction) listDB:(id)sender;
- (IBAction) cmdRemoveAction:(id)sender;
- (IBAction) cmdEditAction:(id)sender;
- (IBAction) cmdApplyAction:(id)sender;
- (IBAction) cmdObjectSelected:(id)sender;
- (IBAction) cmdListCommonMethodsAction:(id)sender;
- (IBAction) updateObjectList:(id)sender;
- (IBAction) testExecute:(id)sender;
- (IBAction) clearStatusLog:(id)sender;
- (IBAction) updatePathAction:(id)sender;
- (IBAction) listenOnStartAction:(id)sender;
- (IBAction) saveHeartbeatsWhileListeningAction:(id)sender;




@end
