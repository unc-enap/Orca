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
@class ORValueBarGroupView;

@interface ORInFluxDBController : OrcaObjectController
{	
	IBOutlet NSTextField* remoteHostNameField;
	IBOutlet NSTextField* localHostNameField;
	IBOutlet NSTextField* userNameField;
	IBOutlet NSTextField* passwordField;
	IBOutlet NSTextField* portField;
	IBOutlet NSTextField* dataBaseNameField;
    IBOutlet NSButton*    InFluxDBLockButton;
    IBOutlet NSMatrix*    queueCountsMatrix;
    IBOutlet ORValueBarGroupView*  queueValueBars;
	IBOutlet NSTextField* dbSizeField;
	IBOutlet NSTextField* dbStatusField;
}

#pragma mark ***Interface Management
- (void) registerNotificationObservers;
- (void) remoteHostNameChanged:(NSNotification*)aNote;
- (void) localHostNameChanged:(NSNotification*)aNote;
- (void) userNameChanged:(NSNotification*)aNote;
- (void) passwordChanged:(NSNotification*)aNote;
- (void) portChanged:(NSNotification*)aNote;
- (void) dataBaseNameChanged:(NSNotification*)aNote;
- (void) InFluxDBLockChanged:(NSNotification*)aNote;
- (void) setQueCount:(NSNumber*)n;

#pragma mark •••Actions
- (IBAction) remoteHostNameAction:(id)sender;
- (IBAction) localHostNameAction:(id)sender;
- (IBAction) userNameAction:(id)sender;
- (IBAction) passwordAction:(id)sender;
- (IBAction) portAction:(id)sender;
- (IBAction) InFluxDBLockAction:(id)sender;

@end
