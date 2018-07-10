//
//  ORReplayFileController.h
//  Orca
//
//  Created by Rielage on Thu Oct 02 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#pragma mark •••Imported Files
#import <Cocoa/Cocoa.h>
#import "OrcaObjectController.h"



@interface ORReplayFileController : OrcaObjectController  {
	@private
	IBOutlet NSButton* 		chooseDirButton;
	IBOutlet NSTextField* 	dirTextField;
	IBOutlet NSTextField* 	fileTextField;
	IBOutlet NSTextField* 	statusTextField;
	IBOutlet NSTextField* 	sizeTextField;
	
	IBOutlet NSButton* 		copyButton;
	IBOutlet NSButton* 		deleteButton;
	IBOutlet NSButton* 		copyStatusButton;
	IBOutlet NSButton* 		deleteStatusButton;
	IBOutlet NSTextField* 	remoteHostField;
	IBOutlet NSTextField* 	remotePathField;
	IBOutlet NSTextField* 	userNameField;
	IBOutlet NSSecureTextField* 	passWordField;

	IBOutlet NSTextField* 	copyStateField;
	IBOutlet NSTextField* 	deleteStateField;

	IBOutlet NSTextField* 	copyStatusField;
	IBOutlet NSTextField* 	deleteStatusField;

	IBOutlet NSMatrix* 		transferTypeMatrix;
	IBOutlet NSButton* 		verboseButton;

}

#pragma mark •••Accessors
- (NSButton*) 		chooseDirButton;
- (NSTextField*) 	dirTextField;
- (NSTextField*) 	fileTextField;
- (NSTextField*) 	statusTextField;

- (NSTextField*) 	remotePathField;
- (NSTextField*) 	remoteHostField;
- (NSTextField*) 	userNameField;
- (NSSecureTextField*) passWordField;

- (NSTextField*) copyStateField;
- (NSTextField*) deleteStateField;

- (NSTextField*) copyStatusField;
- (NSTextField*) deleteStatusField;


- (NSMatrix*) transferTypeMatrix;
- (NSButton*) verboseButton;

#pragma  mark •••Actions
- (IBAction) chooseDir:(id)sender;
- (IBAction) copyEnableAction:(id)sender;
- (IBAction) deleteWhenDoneAction:(id)sender;
- (IBAction) copyStatusEnableAction:(id)sender;
- (IBAction) deleteStatusWhenDoneAction:(id)sender;
- (IBAction) userNameAction:(id)sender;
- (IBAction) remoteHostAction:(id)sender;
- (IBAction) remotePathAction:(id)sender;
- (IBAction) passWordAction:(id)sender;
- (IBAction) transferTypeAction:(id)sender;
- (IBAction) verboseAction:(id)sender;

- (IBAction) sendAllAction:(id)sender;
- (IBAction) deleteAllAction:(id)sender;

#pragma mark •••Interface Management
- (void) registerNotificationObservers;
- (void) openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;


#pragma mark •••Interface Management
- (void) dirChanged:(NSNotification*)note;
- (void) fileChanged:(NSNotification*)note;
- (void) fileStatusChanged:(NSNotification*)note;
- (void) fileSizeChanged:(NSNotification*)note;

- (void) copyEnabledChanged:(NSNotification*)note;
- (void) deleteWhenCopiedChanged:(NSNotification*)note;
- (void) copyStatusEnabledChanged:(NSNotification*)note;
- (void) deleteStatusWhenCopiedChanged:(NSNotification*)note;
- (void) remotePathChanged:(NSNotification*)note;
- (void) remoteHostChanged:(NSNotification*)note;
- (void) passWordChanged:(NSNotification*)note;
- (void) userNameChanged:(NSNotification*)note;
- (void) transferTypeChanged:(NSNotification*)note;
- (void) verboseChanged:(NSNotification*)note;

@end
