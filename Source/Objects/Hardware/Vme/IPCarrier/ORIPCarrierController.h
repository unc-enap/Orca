//
//  ORIPCarrierController.h
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "ORIPCarrierModel.h"

#pragma mark ¥¥¥Forward Declarations
@class ORIPCarrierView;

@interface ORIPCarrierController : OrcaObjectController  {
    IBOutlet ORIPCarrierView* groupView;
    IBOutlet NSStepper* addressStepper;
    IBOutlet NSTextField* addressText;
    IBOutlet NSButton* probeButton;
 }

#pragma mark ¥¥¥Accessors
- (ORIPCarrierView *)groupView;

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers;

#pragma mark ¥¥¥Interface Management
- (void) baseAddressChanged:(NSNotification*)aNotification;
- (void) groupChanged:(NSNotification*)note;
- (void) runStatusChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) probeAction:(id)sender;

@end
