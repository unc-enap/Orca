//
//  ORICS8065Controller.h
//  Orca
//
//  Created by Mark Howe on Friday, June 20, 2008.
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

@interface ORICS8065Controller : OrcaObjectController {
// Setup tab
	IBOutlet NSTextField*	ipConnectedTextField;
 	IBOutlet NSTextField*	ipAddressTextField;
	IBOutlet NSButton*		ipConnectButton;
      
// Test tab
    IBOutlet NSPopUpButton	*primaryAddressPU;
    IBOutlet NSTextField	*commandTextField;
    IBOutlet NSTextView		*mResult;
    IBOutlet NSTextField	*mConfigured;
        
    IBOutlet NSButton		*connectButton;
    IBOutlet NSButton		*mQuery;
    IBOutlet NSButton		*mWrite;
    IBOutlet NSButton		*mRead;

    IBOutlet NSButton*		testLockButton;
	
	IBOutlet NSTextView*	monitorView;

}

#pragma mark ***Initialization
- (id)		init;
- (void) 	updateWindow;
- (void)	populatePullDowns;
- (void)    setTestButtonsEnabled: (BOOL) aValue;

#pragma mark •••Actions
- (IBAction) commandTextFieldAction:(id)sender;
- (IBAction) 	query: (id) aSender;
- (IBAction) 	write: (id) aSender;
- (IBAction) 	read: (id) aSender;
- (IBAction) 	connect: (id) aSender;
- (IBAction)	primaryAddressAction: (id) aSender;
- (IBAction)    testLockAction:(id)sender;
- (IBAction)	changeMonitorRead: (id) aSender;
- (IBAction)	changeMonitorWrite: (id) aSender;
- (IBAction)	ipAddressTextFieldAction:(id)sender;
- (IBAction)	connectAction:(id)sender;

#pragma mark ***Interface Management
- (void) commandChanged:(NSNotification*)aNote;
- (void)	primaryAddressChanged:(NSNotification*)aNote;
- (void)	isConnectedChanged:(NSNotification*)aNote;
- (void)	ipAddressChanged:(NSNotification*)aNote;
- (void)	testLockChanged: (NSNotification*) aNote;
- (void)	writeToMonitor: (NSNotification*) aNote;

- (void)    checkGlobalSecurity;
- (void)    disableAll;

@end

