//-------------------------------------------------------------------------
//  ORSensorPushController.h
//
//  Created by Mark Howe on Friday 08/04/2023.
//  Copyright (c) 2023 University of North Carolina. All rights reserved.
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

@interface ORSensorPushController : OrcaObjectController {
@private
	IBOutlet NSTextField*       userNameField;
	IBOutlet NSSecureTextField* passwordField;
    IBOutlet NSButton*          lockButton;
    IBOutlet NSTableView*       sensorTable;
    IBOutlet NSOutlineView*     sensorList;
    IBOutlet NSTextField*       lastPolledField;
    IBOutlet NSTextField*       nextPollField;
    IBOutlet NSTextField*       pollingField;
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) passwordChanged:(NSNotification*)aNote;
- (void) userNameChanged:(NSNotification*)aNote;
- (void) sensorDataChanged:(NSNotification*)aNote;
- (void) sensorListChanged:(NSNotification*)aNote;

- (void) lockChanged:(NSNotification*)aNote;

#pragma mark •••Table Data Source Methods
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex;

#pragma mark •••Outline Data Source Methods
- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;
- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)theColumn byItem:(id)item;

#pragma mark •••Actions
- (IBAction) passwordAction:(id)sender;
- (IBAction) userNameAction:(id)sender;

- (IBAction) requestSensorData:(id)sender;
- (IBAction) requestGatewaysAction:(id)sender;

- (IBAction) lockAction:(id)sender;

@end
