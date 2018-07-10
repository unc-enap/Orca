//
//  ORGpibEnetController.h
//  Orca
//
//  Created by Jan Wouters on Sat Feb 15 2003.
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


#define kNumIbstaBits 14


@interface ORGpibEnetController : OrcaObjectController {
// Setup tab
    IBOutlet NSPopUpButton		*mGpibBoard;
    
// Test tab
    IBOutlet NSPopUpButton	*mPrimaryAddress;
    IBOutlet NSTextField	*mSecondaryAddress;
    IBOutlet NSTextField	*mCommand;
    IBOutlet NSTextView		*mResult;
    IBOutlet NSTextField	*mConfigured;
    
    IBOutlet NSTextField	*mibsta;
    IBOutlet NSTextField	*miberr;
    IBOutlet NSTextField	*mibcntl;
    
    IBOutlet NSMatrix		*mIbstaErrors;
    
    IBOutlet NSButton		*connectButton;
    IBOutlet NSButton		*mQuery;
    IBOutlet NSButton		*mWrite;
    IBOutlet NSButton		*mRead;

    IBOutlet NSButton*		testLockButton;
	
	IBOutlet NSTextView*	monitorView;

    int		mPrimaryAddressValue;
}

#pragma mark ***Initialization
- (id)			init;
- (void) 		updateWindow;

#pragma mark ***Notifications
- (void) writeToMonitor: (NSNotification*) aNote;

#pragma mark ¥¥¥Actions
- (IBAction) 	query: (id) aSender;
- (IBAction) 	write: (id) aSender;
- (IBAction) 	read: (id) aSender;
- (IBAction) 	connect: (id) aSender;
- (IBAction)	changePrimaryAddress: (id) aSender;
- (IBAction) 	changeBoardIndexAction: (id) aSender;
- (IBAction)    testLockAction:(id)sender;
- (IBAction)	changeMonitorRead: (NSButton*) aSender;
- (IBAction)	changeMonitorWrite: (NSButton*) aSender;

#pragma mark ***Support
- (void)    changeIbstaStatus: (int) aStatus;
- (void)    changeStatusSummary: (int) aStatus error: (int) anError count: (long) aCount;
- (void)    populatePullDowns;
- (void)    setTestButtonsEnabled: (BOOL) aValue;
- (void)    testLockChanged: (NSNotification*) aNotification;
- (void)    checkGlobalSecurity;
- (void)	boardIndexChange: (NSNotification*) aNotification;
- (void)    disableAll;


@end
