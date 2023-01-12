//  Orca
//  ORFlashCamTriggerController.h
//
//  Created by Tom Caldwell on Monday Jan 1, 2020
//  Copyright (c) 2020 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORFlashCamCardController.h"

@interface ORFlashCamTriggerController : ORFlashCamCardController
{
    IBOutlet NSMatrix* connectedADCMatrix;
    IBOutlet NSTextField* fcioIDTextField1;
    IBOutlet NSTextField* statusEventTextField1;
    IBOutlet NSTextField* statusPPSTextField1;
    IBOutlet NSTextField* statusTicksTextField1;
    IBOutlet NSTextField* totalErrorsTextField1;
    IBOutlet NSTextField* envErrorsTextField1;
    IBOutlet NSTextField* ctiErrorsTextField1;
    IBOutlet NSTextField* linkErrorsTextField1;
    IBOutlet NSPopUpButton* majorityLevelPU;
    IBOutlet NSTextField* majorityWidthTextField;
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;

#pragma mark •••Interface management
- (void) connectionChanged:(NSNotification*)note;
- (void) majorityLevelChanged:(NSNotification*)note;
- (void) majorityWidthChanged:(NSNotification*)note;

#pragma mark •••Actions
- (IBAction) printFlagsAction:(id)sender;
- (IBAction) majorityLevelAction:(id)sender;
- (IBAction) majorityWidthAction:(id)sender;

@end
