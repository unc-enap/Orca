//
//  ORLabelController.h
//  Orca
//
//  Created by Mark Howe on Sat Nov 19 2005.
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


@interface ORLabelController : OrcaObjectController
{
    IBOutlet NSTextView*  labelField;
	IBOutlet NSTextField* controllerStringField;
	IBOutlet NSTextView* displayFormatField;
    IBOutlet NSTextField* textSizeField;
    IBOutlet NSButton*    labelLockButton;
	IBOutlet NSMatrix*	  labelTypeMatrix;
	IBOutlet NSPopUpButton*	  updateIntervalPU;
}

#pragma mark ¥¥¥Initialization
- (id) init;

#pragma mark ¥¥¥Interface Management
- (void) controllerStringChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) labelLockChanged:(NSNotification *)aNote;
- (void) checkGlobalSecurity;
- (void) labelTypeChanged:(NSNotification*)aNote;
- (void) labelLockChanged:(NSNotification*)aNote;
- (void) textSizeChanged:(NSNotification*)aNote;
- (void) textDidChange:(NSNotification *)aNote;
- (void) updateIntervalChanged:(NSNotification*)aNote;
- (void) displayFormatChanged:(NSNotification*)aNote;
- (void) labelChanged:(NSNotification*)aNote;

#pragma mark ¥¥¥Actions
- (IBAction) openAltDialogAction:(id)sender;
- (IBAction) applyAction:(id)sender;
- (IBAction) controllerStringAction:(id)sender;
- (IBAction) textSizeAction:(id)sender;
- (IBAction) labelLockAction:(id)sender;
- (IBAction) labelTypeAction:(id)sender;
- (IBAction) updateIntervalAction:(id)sender;
- (IBAction) displayFormatAction:(id)sender;

@end
