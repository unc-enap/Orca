//  Orca
//  ORFlashCamADCController.h
//
//  Created by Tom Caldwell on Monday Dec 17,2019
//  Copyright (c) 2019 University of North Carolina. All rights reserved.
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

#import "OrcaObjectController.h"

@interface ORFlashCamADCController : OrcaObjectController
{
    IBOutlet NSTextField* boardAddressTextField;
    IBOutlet NSMatrix* chanEnabledMatrix;
    IBOutlet NSMatrix* baselineMatrix;
    IBOutlet NSMatrix* thresholdMatrix;
    IBOutlet NSMatrix* adcGainMatrix;
    IBOutlet NSMatrix* trigGainMatrix;
    IBOutlet NSMatrix* shapeTimeMatrix;
    IBOutlet NSMatrix* filterTypeMatrix;
    IBOutlet NSMatrix* poleZeroTimeMatrix;
    IBOutlet NSButton* printFlagsButton;
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) registerNotificationObservers;
- (void) awakeFromNib;
- (void) updateWindow;

#pragma mark •••Interface management
- (void) boardAddressChanged:(NSNotification*)note;
- (void) cardSlotChanged:(NSNotification*)note;
- (void) chanEnabledChanged:(NSNotification*)note;
- (void) baselineChanged:(NSNotification*)note;
- (void) thresholdChanged:(NSNotification*)note;
- (void) adcGainChanged:(NSNotification*)note;
- (void) trigGainChanged:(NSNotification*)note;
- (void) shapeTimeChanged:(NSNotification*)note;
- (void) filterTypeChanged:(NSNotification*)note;
- (void) poleZeroTimeChanged:(NSNotification*)note;

#pragma mark •••Actions
- (IBAction) boardAddressAction:(id)sender;
- (IBAction) chanEnabledAction:(id)sender;
- (IBAction) baselineAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) adcGainAction:(id)sender;
- (IBAction) trigGainAction:(id)sender;
- (IBAction) shapeTimeAction:(id)sender;
- (IBAction) filterTypeAction:(id)sender;
- (IBAction) poleZeroTimeAction:(id)sender;
- (IBAction) printFlagsAction:(id)sender;

@end

