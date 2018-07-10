/*
    
    File:		ORTRS1Controller.h
    
    Usage:		Test PCI Basic I/O Kit Kernel Extension (KEXT) Functions
                                for the Camac TRS1 VME Bus Controller

    Author:		FM
    
    Copyright:		Copyright 2001-2002 F. McGirt.  All rights reserved.
    
    Change History:	1/22/02, 2/2/02, 2/12/02
                        2/13/02 MAH CENPA. converted to Objective-C
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

#pragma mark ¥¥¥Imported Files
#import "ORTRS1Model.h"

@interface ORTRS1Controller : OrcaObjectController {
	@private
		IBOutlet NSButton*		initButton;
		IBOutlet NSButton*		moduleIDButton;
		IBOutlet NSTextField*	offsetRegisterTextField;
		IBOutlet NSTextField*	controlRegisterTextField;
		IBOutlet NSButton*		testLAMButton;
		IBOutlet NSButton*		clearLAMButton;
		IBOutlet NSButton*		triggerButton;
};

#pragma mark ¥¥¥Interface Management
- (void) offsetRegisterChanged:(NSNotification*)aNote;
- (void) controlRegisterChanged:(NSNotification*)aNote;
- (void) registerNotificationObservers;
- (void) runStatusChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNotification;

#pragma mark ¥¥¥Actions
- (IBAction) initAction:(id)sender;
- (IBAction) offsetRegisterAction:(id)sender;
- (IBAction) controlRegisterAction:(id)sender;
- (IBAction) moduleIDAction:(id)sender;
- (IBAction) testLAMAction:(id)sender;
- (IBAction) clearLAMAction:(id)sender;
- (IBAction) triggerAction:(id)sender;


- (void) showError:(NSException*)anException name:(NSString*)name fCode:(int)i;
@end