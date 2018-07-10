//
//  OROutputCallBackController.h
//  Orca
//
//  Created by Mark Howe on Mon April 9.
//  Copyright (c) 2012 University of Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Carolina reserve all rights in the program. Neither the authors,
//University of Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "ORProcessHwAccessorController.h"

@interface OROutputCallBackController : ORProcessHwAccessorController {
    IBOutlet NSPopUpButton* callBackObjPU;
    IBOutlet NSTextField*	callBackChannelField;
    IBOutlet NSTextField*   callBackSourceField;
    IBOutlet NSTextField*   callBackSourceStateField;
	IBOutlet NSButton*		viewCallBackSourceButton;
	IBOutlet NSMatrix*		callBackLabelTypeMatrix;
	IBOutlet NSTextField*	callBackCustomLabelField;
	
}

#pragma mark •••Initialization
-(id)init;
- (void) populateCallBackObjPU;

#pragma mark •••Notifications
- (void) callBackObjectChanged:(NSNotification*)aNotification;
- (void) callBackChannelChanged:(NSNotification*)aNotification;
- (void) callBackNameChanged:(NSNotification*) aNotification;
- (void) callBackLabelTypeChanged:(NSNotification*)aNote;
- (void) callBackCustomLabelChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) callBackObjPUAction:(id)sender;
- (IBAction) callBackChannelAction:(id)sender;
- (IBAction) viewCallBackSourceAction:(id)sender;
- (IBAction) callBackLabelTypeAction:(id)sender;
- (IBAction) callBackCustomLabelAction:(id)sender;

@end
