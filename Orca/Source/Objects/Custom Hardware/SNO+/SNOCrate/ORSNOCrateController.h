//
//  ORSNOCrateController.h
//  Orca
//
//  Created by Mark Howe on Tue, Apr 30, 2008.
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

@interface ORSNOCrateController : ORCrateController
{
	IBOutlet NSTextField* memBaseAddressField;
	IBOutlet NSTextField* regBaseAddressField;
	IBOutlet NSTextField* iPBaseAddressField;
	IBOutlet NSTextField* crateNumberField;
	IBOutlet NSButton*  resetCrateButton;
	IBOutlet NSButton*  loadHardwareButton;
	IBOutlet NSButton*  fetchECALSettingsButton;
}

#pragma mark •••Initializations
- (id) init;
- (void) setCrateTitle;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) slotChanged:(NSNotification*)aNote;
- (void) setModel:(id)aModel;
- (void)keyDown:(NSEvent*)event;

#pragma mark •••Actions
- (IBAction) incCrateAction:(id)sender;
- (IBAction) decCrateAction:(id)sender;
- (IBAction) resetCrateAction:(id)sender;
- (IBAction) fetchECALSettingsAction:(id)sender;
- (IBAction) loadHardwareAction:(id)sender;

@end
