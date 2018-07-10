//-------------------------------------------------------------------------
//  ORRaidMonitorController.h
//
//  Created by Mark Howe on Saturday 12/21/2013.
//  Copyright (c) 2013 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "OrcaObjectController.h"

@interface ORRaidMonitorController : OrcaObjectController {
@private
	IBOutlet NSTextField*       userNameField;
	IBOutlet NSTextField*       scriptRanField;
	IBOutlet NSTextField*       lastCheckedField;
	IBOutlet NSTextField*       localPathField;
	IBOutlet NSTextField*       remotePathField;
	IBOutlet NSTextField*       ipAddressField;
	IBOutlet NSSecureTextField* passwordField;
    IBOutlet NSButton*          lockButton;
    
    IBOutlet NSTextField*       availableField;
    IBOutlet NSTextField*       statusField;
    IBOutlet NSTextField*       usedPercentField;
    IBOutlet NSTextField*       usedField;
    
    IBOutlet NSTextField*       disk0;
    IBOutlet NSTextField*       disk1;
    IBOutlet NSTextField*       disk2;
    IBOutlet NSTextField*       disk3;
    IBOutlet NSTextField*       disk4;
    IBOutlet NSTextField*       disk5;
    IBOutlet NSTextField*       disk6;
    IBOutlet NSTextField*       disk7;
    IBOutlet NSTextField*       disk8;
    IBOutlet NSTextField*       disk9;
    IBOutlet NSTextField*       disk10;
    IBOutlet NSTextField*       disk11;
    IBOutlet NSTextField*       disk12;
    IBOutlet NSTextField*       disk13;
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) fillIn:(NSTextField*)aField with:(NSString*)aString;
- (void) fillIn:(NSTextField*)aField with:(NSString*)aString from:(NSString*)dictionaryKey;
- (void) fillInDisk:(NSTextField*)aField index:(int)anIndex with:(NSString*)aKey;
- (void) resultDictionaryChanged:(NSNotification*)aNote;
- (void) localPathChanged:(NSNotification*)aNote;
- (void) remotePathChanged:(NSNotification*)aNote;
- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) passwordChanged:(NSNotification*)aNote;
- (void) userNameChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) testAction:(id)sender;
- (IBAction) localPathAction:(id)sender;
- (IBAction) remotePathAction:(id)sender;
- (IBAction) ipAddressAction:(id)sender;
- (IBAction) passwordAction:(id)sender;
- (IBAction) userNameAction:(id)sender;
- (IBAction) lockAction:(id)sender;

#pragma mark •••Helpers
- (void) fillIn:(NSTextField*)aField with:(NSString*)aString;
@end
