//
//  ORCytecVM8Controller.h
//  Created by Mark Howe on Mon 22 Aug 2016
//  Copyright © 2016, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina  sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "ORCytecVM8Model.h"
#import "OrcaObjectController.h"

@interface ORCytecVM8Controller : OrcaObjectController  {
	@private
	IBOutlet NSMatrix*    writeHexField;
	IBOutlet NSMatrix* 	  writeBitMatrix;
    IBOutlet NSTextField* baseAddress;
    IBOutlet NSTextField* boardIdField;
    IBOutlet NSTextField* deviceTypeField;
    IBOutlet NSButton*    formCCB;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) writeValueChanged:(NSNotification*)aNotification;
- (void) baseAddressChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;
- (void) boardIdChanged:(NSNotification*)aNotification;
- (void) deviceTypeChanged:(NSNotification*)aNotification;
- (void) formCChanged:(NSNotification*)aNotification;

#pragma mark •••Actions
- (IBAction) write:(id)sender;
- (IBAction) dump:(id)sender;
- (IBAction) sync:(id)sender;
- (IBAction) reset:(id)sender;
- (IBAction) formCAction:(id)sender;
- (IBAction) writeValueHexAction:(id)sender;
- (IBAction) writeValueBitAction:(id)sender;
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) probeBoardAction:(id)sender;

@end
