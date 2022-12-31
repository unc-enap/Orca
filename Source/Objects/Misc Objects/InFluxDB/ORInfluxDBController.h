//
//  ORInFluxDBController.h
//  Orca
//
// Created by Mark Howe on 12/7/2022.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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
@interface ORInFluxDBController : OrcaObjectController
{
    IBOutlet NSTextField*       hostNameField;
    IBOutlet NSTextField*       portField;
    IBOutlet NSTextField*       orgField;
    IBOutlet NSTextField*       bucketNameField;
    IBOutlet NSTextField*       authTokenField;
    IBOutlet NSTextField*       rateField;
    IBOutlet NSButton*          InFluxDBLockButton;
    IBOutlet NSButton*          stealthModeButton;
    IBOutlet NSTextField*       dbStatusField;
    IBOutlet NSTableView*       bucketTableView;
}

#pragma mark ***Interface Management
- (void) registerNotificationObservers;
- (void) hostNameChanged:(NSNotification*)aNote;
- (void) portChanged:(NSNotification*)aNote;
- (void) authTokenChanged:(NSNotification*)aNote;
- (void) orgChanged:(NSNotification*)aNote;
- (void) bucketNameChanged:(NSNotification*)aNote;
- (void) inFluxDBLockChanged:(NSNotification*)aNote;
- (void) rateChanged:(NSNotification*)aNote;
- (void) stealthModeChanged:(NSNotification*)aNote;
- (void) bucketArrayChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) hostNameAction:(id)sender;
- (IBAction) authTokenAction:(id)sender;
- (IBAction) orgAction:(id)sender;
- (IBAction) bucketNameAction:(id)sender;
- (IBAction) listBucketsAction:(id)sender;
- (IBAction) deleteBucketsAction:(id)sender;
- (IBAction) InFluxDBLockAction:(id)sender;
- (IBAction) stealthModeAction:(id)sender;
- (IBAction) listBucketsAction:(id)sender;
- (IBAction) listOrgsAction:(id)sender;
- (IBAction) createBucketsAction:(id)sender;

- (NSInteger)numberOfRowsInTableView:(NSTableView*)aTableView;
- (id) tableView:(NSTableView*) aTableView objectValueForTableColumn:(NSTableColumn*) aTableColumn row:(NSInteger) rowIndex;
@end

