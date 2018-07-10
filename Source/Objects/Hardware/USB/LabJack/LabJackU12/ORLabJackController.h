//
//  ORHPLabJackController.h
//  Orca
//
//  Created by Mark Howe on Tues Nov 09,2010.
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and Department sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

@class ORUSB;

@interface ORLabJackController : OrcaObjectController 
{
	IBOutlet NSTabView*		tabView;	
	IBOutlet NSTextField* deviceSerialNumberField;
	IBOutlet NSView*		totalView;
	IBOutlet NSPopUpButton* serialNumberPopup;
	IBOutlet NSTextField*	aOut1Field;
	IBOutlet NSTextField*	aOut0Field;
	IBOutlet NSButton*		shipDataCB;
	IBOutlet NSButton*		resetCounterButton;
	IBOutlet NSButton*		digitalOutputEnabledButton;
	IBOutlet NSTextField*	counterField;
	IBOutlet NSButton*		lockButton;
	IBOutlet NSMatrix*		nameMatrix;
	IBOutlet NSMatrix*		unitMatrix;
	IBOutlet NSMatrix*		adcMatrix;
	IBOutlet NSMatrix*		doNameMatrix;
	IBOutlet NSMatrix*		ioNameMatrix;
	IBOutlet NSMatrix*		doDirectionMatrix;
	IBOutlet NSMatrix*		ioDirectionMatrix;
	IBOutlet NSMatrix*		doValueOutMatrix;
	IBOutlet NSMatrix*		ioValueOutMatrix;
	IBOutlet NSMatrix*		ioValueInMatrix;
	IBOutlet NSMatrix*		doValueInMatrix;
	IBOutlet NSPopUpButton* pollTimePopup;
	IBOutlet NSMatrix*		lowLimitMatrix;
	IBOutlet NSMatrix*		hiLimitMatrix;
	IBOutlet NSMatrix*		slopeMatrix;
	IBOutlet NSMatrix*		interceptMatrix;
	IBOutlet NSMatrix*		adcDiffMatrix;
	IBOutlet NSPopUpButton* gainPU0;
	IBOutlet NSPopUpButton* gainPU1;
	IBOutlet NSPopUpButton* gainPU2;
	IBOutlet NSPopUpButton* gainPU3;
	IBOutlet NSSlider*		aOut0Slider;
	IBOutlet NSSlider*		aOut1Slider;
	IBOutlet NSMatrix*		minValueMatrix;
	IBOutlet NSMatrix*		maxValueMatrix;

	NSSize					ioSize;
	NSSize					setupSize;
	NSView*					blankView;
}

#pragma mark •••Notifications
- (void) interfacesChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;

#pragma mark ***Interface Management
- (void) deviceSerialNumberChanged:(NSNotification*)aNote;
- (void) involvedInProcessChanged:(NSNotification*)aNote;
- (void) aOut1Changed:(NSNotification*)aNote;
- (void) aOut0Changed:(NSNotification*)aNote;
- (void) gainChanged:(NSNotification*)aNote;
- (void) adcDiffChanged:(NSNotification*)aNote;
- (void) lowLimitChanged:(NSNotification*)aNote;
- (void) hiLimitChanged:(NSNotification*)aNote;
- (void) shipDataChanged:(NSNotification*)aNote;
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) digitalOutputEnabledChanged:(NSNotification*)aNote;
- (void) counterChanged:(NSNotification*)aNote;
- (void) populateInterfacePopup:(ORUSB*)usb;
- (void) validateInterfacePopup;
- (void) channelNameChanged:(NSNotification*)aNote;
- (void) channelUnitChanged:(NSNotification*)aNote;
- (void) doNameChanged:(NSNotification*)aNote;
- (void) ioNameChanged:(NSNotification*)aNote;
- (void) adcChanged:(NSNotification*)aNote;
- (void) doDirectionChanged:(NSNotification*)aNote;
- (void) ioDirectionChanged:(NSNotification*)aNote;
- (void) setDoEnabledState;
- (void) setIoEnabledState;
- (void) doValueOutChanged:(NSNotification*)aNote;
- (void) ioValueOutChanged:(NSNotification*)aNote;
- (void) doValueInChanged:(NSNotification*)aNote;
- (void) ioValueInChanged:(NSNotification*)aNote;
- (void) slopeChanged:(NSNotification*)aNote;
- (void) interceptChanged:(NSNotification*)aNote;
- (void) minValueChanged:(NSNotification*)aNote;
- (void) maxValueChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) probeAction:(id)sender;
- (IBAction) aOut1Action:(id)sender;
- (IBAction) aOut0Action:(id)sender;
- (IBAction) adcDiffBitAction:(id)sender;
- (IBAction) shipDataAction:(id)sender;
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) digitalOutputEnabledAction:(id)sender;
- (IBAction) serialNumberAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) channelNameAction:(id)sender;
- (IBAction) channelUnitAction:(id)sender;

- (IBAction) doNameAction:(id)sender;
- (IBAction) doDirectionBitAction:(id)sender;
- (IBAction) doValueOutBitAction:(id)sender;

- (IBAction) ioNameAction:(id)sender;
- (IBAction) ioDirectionBitAction:(id)sender;
- (IBAction) ioValueOutBitAction:(id)sender;

- (IBAction) updateAllAction:(id)sender;
- (IBAction) resetCounter:(id)sender;

- (IBAction) minValueAction:(id)sender;
- (IBAction) maxValueAction:(id)sender;
- (IBAction) lowLimitAction:(id)sender;
- (IBAction) hiLimitAction:(id)sender;
- (IBAction) gainAction:(id)sender;
- (IBAction) slopeAction:(id)sender;
- (IBAction) interceptAction:(id)sender;

@end

