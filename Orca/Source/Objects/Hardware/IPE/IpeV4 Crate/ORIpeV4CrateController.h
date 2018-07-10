//
//  ORIpeV4CrateController.h
//  Orca
//
//  Created by Mark Howe on Fri Aug 5, 2005.
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

@interface ORIpeV4CrateController : ORCrateController
{
	IBOutlet   NSTextField* connectedField;
	IBOutlet   NSButton* stopButton;
	IBOutlet   NSButton* unlockedStopButtonCB;
	IBOutlet   NSTextField* snmpPowerSupplyIPTextField;
	BOOL connected;
    
}
- (id) init;
- (void) awakeFromNib;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) connectionChanged:(NSNotification*)aNotification;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Interface Management
- (void) unlockedStopButtonChanged:(NSNotification*)aNote;
- (void) snmpPowerSupplyIPChanged:(NSNotification*)aNote;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Actions
- (IBAction) unlockedStopButtonCBAction:(id)sender;
- (IBAction) snmpPowerSupplyIPTextFieldAction:(id)sender;
- (IBAction) snmpStartCrateAction:(id)sender;
- (IBAction) snmpStopCrateAction:(id)sender;

@end
