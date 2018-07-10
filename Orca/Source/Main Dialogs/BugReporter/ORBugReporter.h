//----------------------------------------------------------
//  ORBugReporter.m
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
@interface ORBugReporter : NSWindowController
{
    IBOutlet NSTextField* toField;
    IBOutlet NSTextField* subjectField;
    IBOutlet NSTextField* ccField;
    IBOutlet NSTextField* submitField;
    IBOutlet NSTextField* institutionField;
	IBOutlet NSTextView* bodyField;
	IBOutlet NSMatrix* categoryMatrix;
    IBOutlet NSButton* startDebugging;
    IBOutlet NSButton* stopDebugging;
    IBOutlet NSButton* clearDebugging;
    IBOutlet NSTextField* debugMessageField;
}

- (id) init;
- (NSUndoManager *) windowWillReturnUndoManager:(NSWindow*)window;
- (void) mailSent:(NSString*)to;
- (NSArray*) allEMailLists;
- (void) putAlarmEMailsIntoArray:(NSMutableArray*)anArray;
- (void) putProcess:(id)aProcess eMailsIntoArray:(NSMutableArray*)anArray;
- (void) sendStartMessage:(NSArray*)addresses;
- (void) sendStopMessage:(NSArray*)addresses;
- (void) setDebugging:(BOOL)state;

#pragma mark •••Actions
- (IBAction) showBugReporter:(id)sender;
- (IBAction) send:(id)sender;
- (IBAction) startDebugging:(id)sender;
- (IBAction) stopDebugging:(id)sender;

@end