//
//  ORUnivVoltHVCrateController.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 22 2002.
//  Copyright © 2002 CENPA, University of Washington. All rights reserved.
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

#import "ORCrateController.h"

#pragma mark •••Forward Declarations
@class ORGroup;
@class ORGroupView;

@interface ORUnivVoltHVCrateController : ORCrateController
{
    IBOutlet NSButton*		ethernetConnectButton;
	IBOutlet NSTextField*	ipConnectedTextField;
	IBOutlet NSTextView*	outputArea;
	IBOutlet NSTextField*	ipAddressTextField;
	IBOutlet NSTextField*	hvStatusField;
//	IBOutlet NSTextField*	generalDialog;
}

#pragma mark *Accessors

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) isConnectedChanged: (NSNotification *) aNote;
- (void) ipAddressChanged: (NSNotification *) aNotes;
- (void) displayHVStatus: (NSNotification *) aNotes;
- (void) displayConfig: (NSNotification *) aNotes;
- (void) displayEnet: (NSNotification *) aNotes;
- (void) writeErrorMsg: (NSNotification*) aNote;

#pragma mark •••Actions
- (IBAction) ipAddressTextFieldAction: (id) aSender;
- (IBAction) connectAction: (id) aSender;
- (IBAction) getEthernetParamAction: (id) aSender;
- (IBAction) getConfigParamAction: (id) aSender;
- (IBAction) hvOnAction: (id) aSender;
- (IBAction) hvOffAction: (id) aSender;
- (IBAction) panicAction: (id) aSender;
//- (IBAction) setInhibitOffAction:(id)sender;
- (IBAction) showHVStatusAction: (id) aSender;
- (void) showError: (NSException*) anException name: (NSString*)name;
@end
