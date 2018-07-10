//
//  ORIP220Controller.h
//  Orca
//
//  Created by Mark Howe on Tue Jun 5 2007.
//  Copyright Â© 2002 CENPA, University of Washington. All rights reserved.
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
#import "ORIP220Model.h"

@interface ORIP220Controller : OrcaObjectController  {
	@private
		IBOutlet NSMatrix* 	outputValuesMatrix;
		IBOutlet NSMatrix* 	transferModeMatrix;
		IBOutlet NSButton*	writeButton;
		IBOutlet NSButton*	readButton;
		IBOutlet NSButton*	resetButton;
		IBOutlet NSButton*	settingLockButton;
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;
- (void) outputValuesChanged:(NSNotification*)aNotification;
- (void) transferModeChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) settingsLockChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) settingLockAction:(id) sender;
- (IBAction) transferModeAction:(id)sender;
- (IBAction) outputValuesAction:(id)sender;
- (IBAction) resetAction:(id)sender;
- (IBAction) read:(id)sender;
- (IBAction) write:(id)sender;
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo;
#endif
@end
