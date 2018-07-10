//
//  ORCommandCenterController.h
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

#pragma mark •••Imported Files
#import "ORTimedTextField.h"

#pragma mark •••Forward Declarations
@class ORCommandCenter;
@class ORScriptView;

@interface ORCommandCenterController : NSWindowController <NSTextFieldDelegate>
{
    IBOutlet NSTextField* portField;
    IBOutlet NSTableView* clientListView;
    
    IBOutlet NSTextField* cmdField;
    IBOutlet NSTextField* clientCountField;
    NSString* lastPath;

	IBOutlet ORTimedTextField*	statusField;
	IBOutlet ORScriptView*		scriptView;
	IBOutlet NSButton*			checkButton;
	IBOutlet NSButton*			runButton;
	IBOutlet NSView*			panelView;
	IBOutlet id					loadSaveView;
	IBOutlet NSButton*			loadSaveButton;
	IBOutlet NSTextView*		helpView;
	IBOutlet NSDrawer*			helpDrawer;
	IBOutlet NSMatrix*			argsMatrix;
	IBOutlet NSView*			argsView;
	
}

#pragma mark •••Initialization
+ (ORCommandCenterController*) sharedCommandCenterController;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow*)window;
- (void) endEditing;

#pragma mark •••Accessors
- (ORCommandCenter*) commandCenter;
- (NSString *)lastPath;
- (void)setLastPath:(NSString *)aLastPath;

#pragma mark •••Actions
- (void)	 sendCommand:(NSString*)aCmd;
- (IBAction) setPortAction:(id) sender;
- (IBAction) doCmdAction:(id) sender;
- (IBAction) processFileAction:(id) sender;
- (IBAction) scriptIDEAction:(id) sender;

#pragma mark •••Interface Management
- (void) commandChanged:(NSNotification*)aNote;
- (void) portChanged:(NSNotification*)aNotification;
- (void) clientsChanged:(NSNotification*)aNotification;
- (BOOL) control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command;

@end
