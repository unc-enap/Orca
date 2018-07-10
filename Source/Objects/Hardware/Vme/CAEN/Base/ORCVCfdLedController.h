/*
 *  ORCVCfdLedController.h
 *  Orca
 *
 *  Created by Mark Howe on Tuesday, June 7, 2011.
 *  Copyright (c) 2011 CENPA, University of North Carolina. All rights reserved.
 *
 */
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sonsored in part by the United States 
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

#import "OrcaObjectController.h"

// Definition of class.
@interface ORCVCfdLedController : OrcaObjectController {
    IBOutlet NSMatrix*	  thresholdMatrix;
	IBOutlet NSButton*	  autoInitWithRunCB;
	IBOutlet NSTextField* testPulseField;
	IBOutlet NSTextField* patternInhibitField;
	IBOutlet NSTextField* majorityThresholdField;
	IBOutlet NSTextField* outputWidth0_7Field;
	IBOutlet NSTextField* outputWidth8_15Field;
    IBOutlet NSButton*	  initHWButton;
    IBOutlet NSButton*	  dialogLockButton;
    IBOutlet NSButton*	  probeButton;
    IBOutlet NSTextField* dialogLockDocField;
 	IBOutlet NSTextField* baseAddressField;
    IBOutlet NSMatrix*	  inhibitMaskMatrix;
}

#pragma mark ***Initialization
- (id)		init;
- (NSString*) dialogLockName;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) testPulseChanged:(NSNotification*)aNote;
- (void) patternInhibitChanged:(NSNotification*)aNote;
- (void) majorityThresholdChanged:(NSNotification*)aNote;
- (void) outputWidth0_7Changed:(NSNotification*)aNote;
- (void) outputWidth8_15Changed:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*) aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;

#pragma mark ***Interface Management
- (void) autoInitWithRunChanged:(NSNotification*)aNote;
- (void) thresholdLockChanged:(NSNotification*)aNote;
- (void) updateWindow;

#pragma mark ***Actions
- (IBAction) autoInitWithRunAction:(id)sender;
- (IBAction) inhibitAction:(id)sender;
- (IBAction) baseAddressAction: (id)aSender;
- (IBAction) testPulseAction:(id)sender;
- (IBAction) patternInhibitAction:(id)sender;
- (IBAction) majorityThresholdAction:(id)sender;
- (IBAction) outputWidth0_7Action:(id)sender;
- (IBAction) outputWidth8_15Action:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) initHWAction:(id) aSender;
- (IBAction) probeAction:(id) aSender;
- (IBAction) dialogLockAction:(id)sender;

@end
