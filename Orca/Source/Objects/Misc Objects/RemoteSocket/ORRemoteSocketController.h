//
//  ORRemoteSocketController.h
//  Orca
//
//  Created by Mark Howe on 10/18/06.
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

@interface ORRemoteSocketController : OrcaObjectController 
{	
    IBOutlet NSTextField* connectedField;
    IBOutlet NSTextField* remoteHostField;
	IBOutlet NSTextField* remotePortField;
    IBOutlet NSButton*    remoteSocketLockButton;
    IBOutlet NSTextField* queueCountField;
}

#pragma mark ***Interface Management
- (void) remoteHostNameChanged:(NSNotification*)aNote;
- (void) remotePortChanged:(NSNotification*)aNote;
- (void) remoteSocketLockChanged:(NSNotification*)aNote;
- (void) connectionChanged:(NSNotification*)aNote;
- (void) queueCountChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) remoteHostNameAction:(id)sender;
- (IBAction) remoteSocketLockAction:(id)sender;
- (IBAction) connectionAction:(id)sender;
- (IBAction) remotePortAction:(id)sender;

@end
