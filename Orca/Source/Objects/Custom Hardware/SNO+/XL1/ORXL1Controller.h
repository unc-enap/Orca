//
//  ORXL1Controller.h
//  Orca
//
//  Created by Mark Howe on 10/30/08.
//  Copyright 2008 University of North Carolina. All rights reserved.
//
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

#import "OrcaObjectController.h"

@interface ORXL1Controller : OrcaObjectController {
	IBOutlet NSTextField*	xlinixFileField;
	IBOutlet NSTextField* clockFileTextField;
	IBOutlet NSTextField* cableFileTextField;
	IBOutlet NSButton*		xlinixSelectFileButton;
	IBOutlet NSButton*		clockSelectFileButton;
	IBOutlet NSButton*		cableSelectFileButton;
	IBOutlet NSTextField*	adcClockField;
	IBOutlet NSStepper*		adcClockStepper;
	IBOutlet NSTextField*	sequencerClockField;
	IBOutlet NSStepper*		sequencerClockStepper;
	IBOutlet NSTextField*	memoryClockField;
	IBOutlet NSStepper*		memoryClockStepper;
	IBOutlet NSButton*		lockButton;
}

- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) clockFileChanged:(NSNotification*)aNote;
- (void) updateButtons;
- (void) xlinixFileChanged:(NSNotification*)aNote;
- (void) cableFileChanged:(NSNotification*)aNote;
- (void) adcClockChanged:(NSNotification*)aNote;
- (void) sequencerClockChanged:(NSNotification*)aNote;
- (void) memoryClockChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) clockFileAction:(id) sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) xlinixFileAction:(id) sender;
- (IBAction) cableFileAction:(id) sender;
- (IBAction) adcClockAction:(id) sender;
- (IBAction) sequencerClockAction:(id) sender;
- (IBAction) memoryClockAction:(id) sender;

@end
