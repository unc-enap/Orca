//
//  ORDataPipeController.h
//  Orca
//
//  Created by Mark Howe on Wed Feb 15, 2017.
//  Copyright (c) 2017 University of North Carolina. All rights reserved.
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
#import "OrcaObjectController.h"

@interface ORDataPipeController : OrcaObjectController {
    IBOutlet NSButton*      lockButton;
    IBOutlet NSTextField*   pipeNameField;
    IBOutlet NSTextField*   readerPathField;
    IBOutlet NSTextField*   readerStatusField;
    IBOutlet NSTextField*   byteCountField;
    IBOutlet NSTextField*   runTypeValidField;
    IBOutlet NSTextField*   runStatusField;
    IBOutlet NSMatrix*      runTypeMatrix;
 }

#pragma mark •••Initialization
- (void) registerNotificationObservers;
- (void) setupRunTypeNames:(NSNotification*)aNote;

#pragma mark •••Interface Management
- (void) lockChanged:(NSNotification*)aNotification;
- (void) runTypeChanged:(NSNotification *)notification;
- (void) pipeNameChanged:(NSNotification*)aNote;
- (void) readerPathChanged:(NSNotification*)aNote;
- (void) updateStatus:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) lockAction:(id)sender;
- (IBAction) readerPathAction:(id) sender;
- (IBAction) pipeNameAction:(id) sender;
- (IBAction) runTypeAction:(id)sender;

@end

