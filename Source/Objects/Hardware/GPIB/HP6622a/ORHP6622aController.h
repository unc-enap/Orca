//
//  ORHP6622aController.h
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
@interface ORHP6622aController : ORGpibDeviceController {
    IBOutlet NSButton* 		readIdButton;	
    IBOutlet NSProgressIndicator* progress;

    IBOutlet NSTextField*   lockDocField;
    IBOutlet NSButton*		lockButton;

    IBOutlet NSTextField*   commandField;
    IBOutlet NSButton*		sendCommandButton;
    IBOutlet NSMatrix*		outputOnMatrix;
    IBOutlet NSMatrix*		setVoltageMatrix;
    IBOutlet NSMatrix*		actVoltageMatrix;
    IBOutlet NSMatrix*		overVoltageMatrix;
    IBOutlet NSMatrix*		ocProtectionMatrix;
    IBOutlet NSMatrix*		setCurrentMatrix;
    IBOutlet NSMatrix*		actCurrentMatrix;
    IBOutlet NSButton*		sendClearButton;

    IBOutlet NSMatrix*		resetOverVoltageMatrix;
    IBOutlet NSMatrix*		resetOcProctectionMatrix;

    IBOutlet NSButton*		sendToHWButton;
    IBOutlet NSButton*		readFromHWButton;

}

- (void) setButtonStates;


#pragma mark ¥¥¥Notifications
- (void) lockChanged: (NSNotification*) aNote;
- (void) checkGlobalSecurity;
- (void) actCurrentChanged:(NSNotification*)aNote;
- (void) setCurrentChanged:(NSNotification*)aNote;
- (void) overVoltageChanged:(NSNotification*)aNote;
- (void) actVoltageChanged:(NSNotification*)aNote;
- (void) outputOnChanged:(NSNotification*)aNote;
- (void) ocProtectionOnChanged:(NSNotification*)aNote;
- (void) setVoltageChanged:(NSNotification*)aNote;


#pragma mark ¥¥¥Actions
- (IBAction) idAction:(id)sender;
- (IBAction) testAction:(id)sender;
- (IBAction) sendCommandAction:(id)sender;
- (IBAction) sendToHWAction:(id)sender;
- (IBAction) readHWAction:(id)sender;
- (IBAction) outputOnAction:(id)sender;
- (IBAction) setVoltageAction:(id)sender;
- (IBAction) setCurrentAction:(id)sender;
- (IBAction) setOverVoltageAction:(id)sender;
- (IBAction) ocProtectionOnAction:(id)sender;
- (IBAction) resetOverVoltageAction:(id)sender;
- (IBAction) resetOcProtectionAction:(id)sender;
- (IBAction) setClearAction:(id)sender;

@end

