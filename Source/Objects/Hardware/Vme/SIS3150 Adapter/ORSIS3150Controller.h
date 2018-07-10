//
//  ORSIS3150Controller.h
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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

@class ORUSB;

@interface ORSIS3150Controller : OrcaObjectController {
 	IBOutlet NSPopUpButton* serialNumberPopup;
	IBOutlet NSButton*      writeButton;
	IBOutlet NSTextField*	rangeTextField;
	IBOutlet NSStepper* 	rangeStepper;
	IBOutlet NSButton*		doRangeButton;
	IBOutlet NSButton*      readButton;
	IBOutlet NSButton*      resetButton;
	IBOutlet NSButton*      sysResetButton;
	IBOutlet NSButton*      testButton;
	IBOutlet NSStepper* 	addressStepper;
	IBOutlet NSTextField* 	addressValueField;
	IBOutlet NSStepper* 	writeValueStepper;
	IBOutlet NSTextField* 	writeValueField;
	IBOutlet NSMatrix*      readWriteTypeMatrix;
	IBOutlet NSPopUpButton* readWriteIOSpacePopUp;
	IBOutlet NSPopUpButton* readWriteAddressModifierPopUp;	
	IBOutlet NSButton*      lockButton;}

#pragma mark •••Initialization
- (id)   init;
- (void) rangeChanged:(NSNotification*)aNote;
- (void) doRangeChanged:(NSNotification*)aNote;
- (void) rwAddressTextChanged:(NSNotification*)aNotification;
- (void) writeValueTextChanged:(NSNotification*)aNotification;
- (void) readWriteTypeChanged:(NSNotification*)aNotification;
- (void) readWriteIOSpaceChanged:(NSNotification*)aNotification;
- (void) readWriteAddressModifierChanged:(NSNotification*)aNotification;
- (void) lockChanged:(NSNotification*)aNotification;

#pragma mark •••Notifications
- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) updateWindow;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) populateInterfacePopup:(ORUSB*)usb;
- (void) validateInterfacePopup;

#pragma mark •••Actions
- (IBAction) serialNumberAction:(id)sender;
- (IBAction) rangeTextFieldAction:(id)sender;
- (IBAction) doRangeAction:(id)sender;
- (IBAction) rwAddressTextAction:(id)sender;
- (IBAction) writeValueTextAction:(id)sender;
- (IBAction) readWriteTypeMatrixAction:(id)sender;
- (IBAction) ioSpaceAction:(id)sender;
- (IBAction) addressModifierAction:(id)sender;
- (IBAction) lockAction:(id) sender;

- (IBAction) reset:(id)sender;
- (IBAction) sysReset:(id)sender;
- (IBAction) read:(id)sender;
- (IBAction) write:(id)sender;

@end
