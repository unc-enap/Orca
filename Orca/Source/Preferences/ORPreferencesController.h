//
//  ORPreferencesController.h
//  Orca
//
//  Created by Mark Howe on Sat Dec 28 2002.
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

@interface ORPreferencesController : NSWindowController <NSTextViewDelegate>
{	
    IBOutlet NSColorWell* 	backgroundColorWell;
    IBOutlet NSColorWell* 	lineColorWell;
    IBOutlet NSMatrix*		openingDocPrefMatrix;
    IBOutlet NSMatrix*		lineTypeMatrix;
    IBOutlet NSTextField*	nextTimeTextField;

    IBOutlet NSMatrix*		openingDialogMatrix;

    IBOutlet NSButton*      lockButton;
    IBOutlet NSButton*      passwordButton;
    IBOutlet NSTextField*   lockTextField;
    
    IBOutlet NSPanel*		passWordPanel;
    IBOutlet NSTextField*   passWordField;
    
    IBOutlet NSPanel*       changePassWordPanel;
    IBOutlet NSTextField*   oldPassWordField;
    IBOutlet NSTextField*   newPassWordField;
    IBOutlet NSTextField*   confirmPassWordField;
    
    IBOutlet NSPanel*       setPassWordPanel;
    IBOutlet NSTextField*   setPassWordField;
    IBOutlet NSTextField*   confirmSetPassWordField;

    IBOutlet NSTextView*	bugReportEMailField;
    IBOutlet NSButton*      sendBugReportButton;

    IBOutlet NSColorWell* 	scriptBackgroundColorWell;
    IBOutlet NSColorWell* 	scriptCommentColorWell;
    IBOutlet NSColorWell* 	scriptStringColorWell;
    IBOutlet NSColorWell* 	scriptIdentifier1ColorWell;
    IBOutlet NSColorWell* 	scriptIdentifier2ColorWell;
    IBOutlet NSColorWell* 	scriptConstantsColorWell;

    IBOutlet NSMatrix*		helpFileLocationMatrix;
    IBOutlet NSTextField*	helpFileLocationPathField;

	IBOutlet NSTextField*	heartbeatPathField;
    IBOutlet NSButton*      activateHeartbeatCB;
    IBOutlet NSButton*      activatePostLogCB;
    
    IBOutlet NSMatrix*		mailSelectionMatrix;
    IBOutlet NSTextField*   mailAddressField;
    IBOutlet NSTextField*   mailServerField;
    IBOutlet NSSecureTextField* mailPasswordField;

    BOOL disallowStateChange;
}

#pragma mark ¥¥¥Initialization
+ (ORPreferencesController*) sharedPreferencesController;
- (id) init;

#pragma mark ¥¥¥Accessors
- (void) setLockButtonState:(BOOL)state;
- (void) setLockState:(BOOL)state;

#pragma mark ¥¥¥Actions
- (IBAction) changeBackgroundColor:(id)sender;
- (IBAction) changeLineColor:(id)sender;
- (IBAction) openingDocPrefAction:(id)sender;
- (IBAction) lineTypeAction:(id)sender;
- (IBAction) openingDialogAction:(id)sender;

- (IBAction) lockAction:(id)sender;
- (IBAction) changePassWordAction:(id)sender;

- (IBAction) closeChangePassWordPanel:(id)sender;
- (IBAction) closePassWordPanel:(id)sender;
- (IBAction) closeSetPassWordPanel:(id)sender;

- (IBAction) enableBugReportSendAction:(id)sender;

- (IBAction)changeScriptBackgroundColor:(id)sender;
- (IBAction) changeScriptCommentColor:(id)sender;
- (IBAction) changeScriptStringColor:(id)sender;
- (IBAction) changeScriptIndentifier1Color:(id)sender;
- (IBAction) changeScriptIndentifier2Color:(id)sender;
- (IBAction) changeScriptConstantsColor:(id)sender;

- (void) textDidChange:(NSNotification*)aNote;

- (IBAction) helpFileLocationPrefAction:(id)sender;
- (IBAction) helpFilePathAction:(id)sender;

- (IBAction) activateHeatbeatAction:(id)sender;
- (IBAction) activatePostLogAction:(id)sender;
- (IBAction) selectHeartbeatPathAction:(id)sender;


- (IBAction) mailSelectionAction:(id)sender;
- (IBAction) mailServerAction:(id)sender;
- (IBAction) mailAddressAction:(id)sender;
- (IBAction) mailPasswordAction:(id)sender;

@end