//
//  ORCountDownController.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 18 2005.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//

#pragma mark ¥¥¥Imported Files
#import <Cocoa/Cocoa.h>
#import "ORProcessElementController.h"

@interface ORCountDownController : ORProcessElementController {
    IBOutlet NSTextField*   startCountField;
    IBOutlet NSButton*      countDownLockButton;
}

#pragma mark ¥¥¥Initialization
- (void) registerNotificationObservers;

#pragma mark ¥¥¥Accessors

#pragma mark ¥¥¥Actions


#pragma mark ¥¥¥Interface Management
- (void) checkGlobalSecurity;
- (void) countDownLockChanged:(NSNotification *)notification;
- (void) countDownTextChanged:(NSNotification *)notification;

#pragma mark ¥¥¥Actions
- (IBAction) countDownTextAction:(id)sender;
- (IBAction) countDownLockAction:(id)sender;

@end
