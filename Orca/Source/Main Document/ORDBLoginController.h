//
//  ORDBLoginController.h
//  Orca
//
//  Created by Mark Howe on Tue Feb 04 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>


@interface ORDBLoginController : NSWindowController {
	IBOutlet NSWindow* mainWindow;
	IBOutlet NSPanel* dbLogInSheet;
	IBOutlet NSTextField* userTextField;
	IBOutlet NSTextField* passwordTextField;
	IBOutlet NSTextField* dbTextField;
	IBOutlet NSTextField* hostTextField;
}
#pragma mark •••Accessors
- (NSWindow*) mainWindow;
- (NSPanel*) dbLogInSheet;

#pragma mark •••Actions
- (IBAction) startLoginSheet:(id)sender;
- (IBAction) endLoginSheet:(id)sender;
@end
