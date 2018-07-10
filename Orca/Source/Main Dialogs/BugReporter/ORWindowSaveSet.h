//----------------------------------------------------------
//  ORWindowSaveSet.m
//
//  Created by Mark Howe on Thurs Mar 20, 2008.
//  Copyright  © 2008 CENPA. All rights reserved.
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

@class ORTimedTextField;

@interface ORWindowSaveSet : NSWindowController
{
	IBOutlet NSTableView*		savedSetsTableView;
	IBOutlet NSTextField*		newSetNameField;
	IBOutlet NSTextField*		cmdOneSetField;
	IBOutlet ORTimedTextField*	messageField;
	IBOutlet NSButton*			restoreButton;
	IBOutlet NSButton*			cmdOneSaveButton;
	
	//cache of file names so we don't have to keep going back to the disk
	NSMutableArray* saveSetNames;
}

- (id) init;
- (NSUndoManager *) windowWillReturnUndoManager:(NSWindow*)window;
- (void) loadFileNames;
- (NSString*) suggestName; 
- (void) registerNotificationObservers;
- (void) tableSelectionDidChange:(NSNotification *)notification;
- (id) document;
- (void) restoreSaveSetWithName:(NSString*) theSaveSetName;

#pragma mark •••Actions
- (IBAction) showWindowSaveSet:(id)sender;
- (IBAction) saveWindowSet:(id)sender;
- (IBAction) restoreWindowSet:(id)sender;
- (IBAction) setCmdOneSet:(id)sender;
- (IBAction) restoreToCmdOneSet:(id)sender;
- (IBAction) cancel:(id)sender;
@end