//
//  ORFifoController.h
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
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


#pragma mark ¥¥¥Imported Files
#import "ORFifoModel.h"

#pragma mark ¥¥¥Forward Declarations
@class ORFifoView;
@class ThreadWorker;

@interface ORFifoController : OrcaObjectController  {

    IBOutlet NSProgressIndicator* progressView;
    IBOutlet NSButton* readWriteTestControl;
    IBOutlet NSButton* blockLoadTestControl;

	ThreadWorker* readWriteTestThread;
 }
 
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) slotChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) reset:(id)sender;
- (IBAction) status:(id)sender;
- (IBAction) loadUnloadTest:(id)sender;
- (IBAction) readWriteTest:(id)sender;

#pragma mark ¥¥¥Thread Worker Methods
- (id) runWriteReadTest:(NSDictionary*)userInfo thread:tw;
- (void) writeReadTestFinished:(NSDictionary*)userInfo;


@end
