//
//  OROscBaseController.h
//  Orca
//
//  Created by Jan Wouters on Wed Feb 19 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
//

#pragma mark ¥¥¥Imported Files
#import <Cocoa/Cocoa.h>
#import "ORGpibDeviceController.h"


@interface OROscBaseController : ORGpibDeviceController {
        IBOutlet NSMatrix*	mChnlAcquire;
        IBOutlet NSMatrix*	mChnlCoupling;
        IBOutlet NSMatrix*	mChnlPos;
        IBOutlet NSMatrix*	mChnlScale;    
}

#pragma mark ***Initialization
- (id) 		initWithWindowNibName: (NSString*) aNibName;
- (void) 	dealloc;

#pragma mark ¥¥¥Interface Management
- (void) oscChnlAcquireChanged: (NSNotification*) aNotification;

#pragma mark ***Commands
- (IBAction) loadOscFromDialog: (id) aSender;
@end
