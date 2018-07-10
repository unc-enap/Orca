//
//  ORHP3458aController.h
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORGpibDeviceController.h"
@interface ORHP3458aController : ORGpibDeviceController {
    IBOutlet NSButton* 		readIdButton;	
	IBOutlet NSPopUpButton* maxInputPU;
	IBOutlet NSPopUpButton* functionDefPU;
    IBOutlet NSProgressIndicator* progress;

    IBOutlet NSTextField*   lockDocField;
    IBOutlet NSButton*		lockButton;

    IBOutlet NSTextField*   commandField;
    IBOutlet NSButton*		sendCommandButton;

    IBOutlet NSButton*		resetButton;
    IBOutlet NSButton*		sendToHWButton;
    IBOutlet NSButton*		readFromHWButton;

}

- (void) setButtonStates;


#pragma mark •••Notifications
- (void) lockChanged: (NSNotification*) aNote;
- (void) checkGlobalSecurity;

#pragma mark ***Interface Management
- (void) maxInputChanged:(NSNotification*)aNote;
- (void) functionDefChanged:(NSNotification*)aNote;
- (void) populatePullDown;

#pragma mark •••Actions
- (IBAction) maxInputAction:(id)sender;
- (IBAction) functionDefAction:(id)sender;
- (IBAction) idAction:(id)sender;
- (IBAction) testAction:(id)sender;
- (IBAction) sendCommandAction:(id)sender;
- (IBAction) sendToHWAction:(id)sender;
- (IBAction) readHWAction:(id)sender;
- (IBAction) resetAction:(id)sender;

@end


