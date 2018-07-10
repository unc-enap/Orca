/*
    
    File:		ORPciBit3Controller.h
    
    Usage:		Test PCI Basic I/O Kit Kernel Extension (KEXT) Functions
                                for the Bit3 VME Bus Controller

    Author:		FM
    
    Copyright:		Copyright 2001-2002 F. McGirt.  All rights reserved.
    
    Change History:	1/22/02, 2/2/02, 2/12/02
                    11/20/02 MAH CENPA. converted to Objective-C
                    11/3/04 MAH CENPA. converted to generic Bit3 controller
                             
-----------------------------------------------------------
This program was prepared for the Regents of the University of 
Washington at the Center for Experimental Nuclear Physics and 
Astrophysics (CENPA) sponsored in part by the United States 
Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
The University has certain rights in the program pursuant to 
the contract and the program should not be copied or distributed 
outside your organization.  The DOE and the University of 
Washington reserve all rights in the program. Neither the authors,
University of Washington, or U.S. Government make any warranty, 
express or implied, or assume any liability or responsibility 
for the use of this software.
-------------------------------------------------------------

    
*/

#pragma mark ¥¥¥Imported Files
#import "ORPciBit3Model.h"

@class ORCompositeTimeLineView;
@class ORGroupView;
 
@interface ORPciBit3Controller : OrcaObjectController {
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
	IBOutlet ORCompositeTimeLineView*	errorRatePlot;
	IBOutlet NSButton*      errorRateLogCB;
	IBOutlet NSStepper* 	integrationStepper;
	IBOutlet NSTextField* 	integrationText;
    IBOutlet ORGroupView*	groupView;
};

- (void) registerNotificationObservers;
- (void) registerRates;

#pragma mark ¥¥¥Interface Management
- (void) rangeChanged:(NSNotification*)aNote;
- (void) doRangeChanged:(NSNotification*)aNote;
- (void) rwAddressTextChanged:(NSNotification*)aNotification;
- (void) writeValueTextChanged:(NSNotification*)aNotification;
- (void) readWriteTypeChanged:(NSNotification*)aNotification;
- (void) readWriteIOSpaceChanged:(NSNotification*)aNotification;
- (void) readWriteAddressModifierChanged:(NSNotification*)aNotification;
- (void) lockChanged:(NSNotification*)aNotification;
- (void) deviceNameChanged:(NSNotification*)aNotification;

- (void) integrationChanged:(NSNotification*)aNotification;
- (void) rateGroupChanged:(NSNotification*)aNotification;

- (void) errorRateXAttributesChanged:(NSNotification*)aNote;
- (void) errorRateYAttributesChanged:(NSNotification*)aNote;
- (void) updateErrorPlot:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;

- (void) clearError_Bits;
- (void) dpmTest;

#pragma mark ¥¥¥Actions
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

- (IBAction) integrationAction:(id)sender;

- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
- (NSColor*) colorForDataSet:(int)set;


@end