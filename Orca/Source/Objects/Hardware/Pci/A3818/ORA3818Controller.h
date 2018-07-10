/*
    
    File:		ORA3818Controller.h
    
    Usage:		Test PCI Basic I/O Kit Kernel Extension (KEXT) Functions
                                for the A3818 Controller
    Author:		Mark A. Howe
    Copyright:		Copyright 3818.  All rights reserved
    
*/
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "ORA3818Model.h"

@class ORGroupView;
 
@interface ORA3818Controller : OrcaObjectController {
    @private
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
	IBOutlet NSButton*      lockButton;
    IBOutlet ORGroupView*	groupView;
};

- (void) registerNotificationObservers;

#pragma mark •••Interface Management
- (void) rangeChanged:(NSNotification*)aNote;
- (void) doRangeChanged:(NSNotification*)aNote;
- (void) rwAddressTextChanged:(NSNotification*)aNotification;
- (void) writeValueTextChanged:(NSNotification*)aNotification;
- (void) readWriteTypeChanged:(NSNotification*)aNotification;
- (void) readWriteIOSpaceChanged:(NSNotification*)aNotification;
- (void) readWriteAddressModifierChanged:(NSNotification*)aNotification;
- (void) lockChanged:(NSNotification*)aNotification;
- (void) deviceNameChanged:(NSNotification*)aNotification;
- (void) slotChanged:(NSNotification*)aNote;

- (void) clearError_Bits;
- (void) dpmTest;

#pragma mark •••Actions
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
- (IBAction) doTests:(id)sender;
- (IBAction) read:(id)sender;
- (IBAction) write:(id)sender;

@end