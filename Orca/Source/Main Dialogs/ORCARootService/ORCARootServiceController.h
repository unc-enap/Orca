//
//  ORCARootServiceController.h
//  Orca
//
//  Created by Mark Howe on Thu Nov 06 2003.
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


#pragma mark ¥¥¥Imported Files
#import "ORTimedTextField.h"

#pragma mark ¥¥¥Forward Declarations
@class ORCARootService;
@class ORScriptView;

@interface ORCARootServiceController : NSWindowController 
{
    IBOutlet NSTextField*	portField;
    IBOutlet NSComboBox*	hostComboBox;
	IBOutlet NSTextField*	statusField;
	IBOutlet NSTextField*	timeField;
    IBOutlet NSButton*      lockButton;
    IBOutlet NSButton*      connectButton;
	IBOutlet NSButton*      connectAtStartButton;
	IBOutlet NSButton*      autoReconnectButton;
	IBOutlet NSButton*      clearHistoryButton;
}

#pragma mark ¥¥¥Initialization
+ (ORCARootServiceController*) sharedORCARootServiceController;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window;
- (void) endEditing;

#pragma mark ¥¥¥Accessors
- (ORCARootService*) orcaRootService;

#pragma mark ¥¥¥Actions
- (IBAction) setPortAction:(id) sender;
- (IBAction) setHostNameAction:(id) sender;
- (IBAction) lockAction:(id)sender;
- (IBAction) connectAction:(id)sender;
- (IBAction) connectAtStartAction:(id)sender;
- (IBAction) autoReconnectAction:(id)sender;
- (IBAction) clearHistory:(id) sender;

#pragma mark ¥¥¥Interface Management
- (void) hostNameChanged:(NSNotification*)aNotification;
- (void) securityStateChanged:(NSNotification*)aNotification;
- (void) checkGlobalSecurity;
- (void) portChanged:(NSNotification*)aNotification;
- (void) connectedChanged:(NSNotification*)aNotification;
- (void) timeConnectedChanged:(NSNotification*)aNotification;
- (void) lockChanged:(NSNotification*)aNotification;
- (void) hostNameChanged:(NSNotification*)aNotification;
- (void) connectAtStartChanged:(NSNotification*)aNote;
- (void) autoReconnectChanged:(NSNotification*)aNote;

@end

