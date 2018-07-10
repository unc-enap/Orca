//
//  ORRemoteRunController.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 23 2002.
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



@interface ORRemoteRunController : OrcaObjectController  {
        
    IBOutlet NSButton*  startRunButton;
    IBOutlet NSButton*  restartRunButton;
    IBOutlet NSButton*  stopRunButton;
    IBOutlet NSButton*  quickStartCB;
    IBOutlet NSButton*  offlineCB;
    IBOutlet NSButton*  connectButton;
	IBOutlet NSTextField*   connectionStatusField;
    
    IBOutlet NSProgressIndicator* 	runProgress;
    IBOutlet NSProgressIndicator* 	runBar;
    IBOutlet NSTextField*		runNumberField;
    
    IBOutlet NSButton*      timedRunCB;
    IBOutlet NSButton*      repeatRunCB;
    IBOutlet NSTextField*   timeLimitField;
    IBOutlet NSStepper*     timeLimitStepper;
    
    IBOutlet NSTextField* statusField;
    IBOutlet NSTextField* timeStartedField;
    IBOutlet NSTextField* elapsedTimeField;
    IBOutlet NSTextField* timeToGoField;
    IBOutlet NSTextField* elapsedSubRunTimeField;
    IBOutlet NSTextField* elapsedBetweenSubRunTimeField;
 
    IBOutlet NSTextField* remoteHostField;
    IBOutlet NSTextField* remotePortField;

	IBOutlet NSButton*      connectAtStartButton;
	IBOutlet NSButton*      autoReconnectButton;
    IBOutlet NSButton*      lockButton;
	
	IBOutlet NSPopUpButton* startUpScripts;
	IBOutlet NSPopUpButton* shutDownScripts;
	
	IBOutlet NSButton*  endSubRunButton;
	IBOutlet NSButton*  startSubRunButton;

    BOOL retainingRunNotice;
}

#pragma mark ¥¥¥Accessors

#pragma  mark ¥¥¥Actions
- (IBAction) lockAction:(id)sender;
- (IBAction) startRunAction:(id)sender;
- (IBAction) newRunAction:(id)sender;
- (IBAction) stopRunAction:(id)sender;
- (IBAction) timeLimitStepperAction:(id)sender;
- (IBAction) timeLimitTextAction:(id)sender;
- (IBAction) timedRunCBAction:(id)sender;
- (IBAction) repeatRunCBAction:(id)sender;
- (IBAction) quickStartCBAction:(id)sender;
- (IBAction) offlineCBAction:(id)sender;
- (IBAction) remoteHostAction:(id)sender;
- (IBAction) remotePortAction:(id)sender;
- (IBAction) connectAction:(id)sender;
- (IBAction) connectAtStartAction:(id)sender;
- (IBAction) autoReconnectAction:(id)sender;
- (IBAction) selectStartUpScript:(id)sender;
- (IBAction) selectShutDownScript:(id)sender;
- (IBAction) resynce:(id)sender;
- (IBAction) startNewSubRunAction:(id)sender;
- (IBAction) prepareForSubRunAction:(id)sender;

#pragma mark ¥¥¥Interface Management
- (void) updateButtons;
- (void) isConnectedChanged:(NSNotification*)note;
- (void) lockChanged:(NSNotification*)aNotification;
- (void) registerNotificationObservers;
- (void) remoteHostChanged:(NSNotification*)aNotification;
- (void) remotePortChanged:(NSNotification*)aNotification;
- (void) runStatusChanged:(NSNotification*)aNotification;
- (void) timeLimitStepperChanged:(NSNotification*)aNotification;
- (void) timedRunChanged:(NSNotification*)aNotification;
- (void) repeatRunChanged:(NSNotification*)aNotification;
- (void) elapsedTimeChanged:(NSNotification*)aNotification;
- (void) startTimeChanged:(NSNotification*)aNotification;
- (void) timeToGoChanged:(NSNotification*)aNotification;
- (void) runNumberChanged:(NSNotification*)aNotification;
- (void) quickStartChanged:(NSNotification *)notification;
- (void) offlineChanged:(NSNotification *)notification;
- (void) connectAtStartChanged:(NSNotification*)note;
- (void) autoReconnectChanged:(NSNotification*)note;
- (void) scriptNamesChanged:(NSNotification*)aNote;
- (void) startScriptNameChanged:(NSNotification*)aNote;
- (void) shutDownScriptNameChanged:(NSNotification*)aNote;
- (IBAction) prepareForSubRunAction:(id)sender;
- (IBAction) startNewSubRunAction:(id)sender;

@end
