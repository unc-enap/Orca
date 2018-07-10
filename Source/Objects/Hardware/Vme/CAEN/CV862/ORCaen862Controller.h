/*
 *  ORCaen862Controller.h
 *  Orca
 *
 *  Created by Mark Howe on Thurs May 29 2008.
 *  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
 *
 */
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

#import "ORCaenCardController.h"

// Definition of class.
@interface ORCaen862Controller : ORCaenCardController {
    IBOutlet NSTextField*  iPedField;
    IBOutlet NSMatrix*     eventCounterIncMatrix;
    IBOutlet NSTextField*   slideConstantField;
    IBOutlet NSMatrix*      slidingScaleEnableMatrix;
    IBOutlet NSMatrix*      zeroSuppressThresResMatrix;
    IBOutlet NSMatrix*      zeroSuppressEnableMatrix;
    IBOutlet NSMatrix*      overflowSuppressEnableMatrix;
}

#pragma mark ***Initialization
- (id)		init;
 	
#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) iPedChanged:(NSNotification*)aNote;
- (void) eventCounterIncChanged:(NSNotification*)aNote;
- (void) slideConstantChanged:(NSNotification*)aNote;
- (void) slidingScaleEnableChanged:(NSNotification*)aNote;
- (void) zeroSuppressThresResChanged:(NSNotification*)aNote;
- (void) zeroSuppressEnableChanged:(NSNotification*)aNote;
- (void) overflowSuppressEnableChanged:(NSNotification*)aNote;

#pragma mark ***Interface Management
- (IBAction) iPedAction:(id)sender;
- (IBAction) eventCounterIncAction:(id)sender;
- (IBAction) slideConstantAction:(id)sender;
- (IBAction) slidingScaleEnableAction:(id)sender;
- (IBAction) zeroSuppressThresResAction:(id)sender;
- (IBAction) zeroSuppressEnableAction:(id)sender;
- (IBAction) overflowSuppressEnableAction:(id)sender;

@end
