//
//  ORHPLabJackU6Controller.h
//  Orca
//
//  Created by Mark Howe on Fri Jan 20,2017.
//  Copyright (c) 2017 University of North Carolina. All rights reserved.
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


@interface ORLabJackU6Controller : OrcaObjectController 
{
	IBOutlet NSTabView*		tabView;	
    IBOutlet NSTextField*   deviceSerialNumberField;
    IBOutlet NSTextField*   openCloseStatusField;
    IBOutlet NSButton*		probeButton;
    IBOutlet NSButton*		openCloseButton;

	IBOutlet NSView*		totalView;
	IBOutlet NSTextField*	aOut1Field;
	IBOutlet NSTextField*	aOut0Field;
	IBOutlet NSButton*		shipDataCB;
    IBOutlet NSButton*		resetCounter0Button;
    IBOutlet NSButton*		resetCounter1Button;
	IBOutlet NSButton*		digitalOutputEnabledButton;
	IBOutlet NSButton*		lockButton;
    IBOutlet NSMatrix*		nameMatrix;
    IBOutlet NSMatrix*		nameMatrix1;
	IBOutlet NSMatrix*		unitMatrix;
	IBOutlet NSMatrix*		adcMatrix;
	IBOutlet NSMatrix*		doNameMatrix;
	IBOutlet NSMatrix*		doDirectionMatrix;
	IBOutlet NSMatrix*		doValueOutMatrix;
	IBOutlet NSMatrix*		doValueInMatrix;
	IBOutlet NSPopUpButton* pollTimePopup;
	IBOutlet NSMatrix*		lowLimitMatrix;
	IBOutlet NSMatrix*		hiLimitMatrix;
	IBOutlet NSMatrix*		slopeMatrix;
	IBOutlet NSMatrix*		interceptMatrix;
	IBOutlet NSMatrix*		adcDiffMatrix;
	IBOutlet NSMatrix*      adcRangeMatrix;
	IBOutlet NSSlider*		aOut0Slider;
	IBOutlet NSSlider*		aOut1Slider;
	IBOutlet NSMatrix*		minValueMatrix;
	IBOutlet NSMatrix*		maxValueMatrix;
    IBOutlet NSMatrix*		enabledMatrix;
    IBOutlet NSMatrix*      counterMatrix;
    IBOutlet NSMatrix*		counterEnabledMatrix;

	NSSize					ioSize;
	NSSize					setupSize;
	NSView*					blankView;
}

#pragma mark •••Notifications
- (void) lockChanged:(NSNotification*)aNote;
- (void) deviceSerialNumberChanged:(NSNotification*)aNote;
- (void) deviceHandleChanged:(NSNotification*)aNote;
- (void) involvedInProcessChanged:(NSNotification*)aNote;
- (void) enabledChanged:(NSNotification*)aNote;
- (void) counterEnabledChanged:(NSNotification*)aNote;
- (void) aOut1Changed:(NSNotification*)aNote;
- (void) aOut0Changed:(NSNotification*)aNote;
- (void) adcRangeChanged:(NSNotification*)aNote;
- (void) adcDiffChanged:(NSNotification*)aNote;
- (void) lowLimitChanged:(NSNotification*)aNote;
- (void) hiLimitChanged:(NSNotification*)aNote;
- (void) shipDataChanged:(NSNotification*)aNote;
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) digitalOutputEnabledChanged:(NSNotification*)aNote;
- (void) counterChanged:(NSNotification*)aNote;
- (void) channelNameChanged:(NSNotification*)aNote;
- (void) channelUnitChanged:(NSNotification*)aNote;
- (void) doNameChanged:(NSNotification*)aNote;
- (void) adcChanged:(NSNotification*)aNote;
- (void) doDirectionChanged:(NSNotification*)aNote;
- (void) setDoEnabledState;
- (void) doValueOutChanged:(NSNotification*)aNote;
- (void) doValueInChanged:(NSNotification*)aNote;
- (void) slopeChanged:(NSNotification*)aNote;
- (void) interceptChanged:(NSNotification*)aNote;
- (void) minValueChanged:(NSNotification*)aNote;
- (void) maxValueChanged:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) enabledAction:(id)sender;
- (IBAction) counterEnabledAction:(id)sender;
- (IBAction) probeAction:(id)sender;
- (IBAction) toggleOpenAction:(id)sender;
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

- (IBAction) updateAllAction:(id)sender;
- (IBAction) resetCounter0:(id)sender;
- (IBAction) resetCounter1:(id)sender;

- (IBAction) minValueAction:(id)sender;
- (IBAction) maxValueAction:(id)sender;
- (IBAction) lowLimitAction:(id)sender;
- (IBAction) hiLimitAction:(id)sender;
- (IBAction) adcRangeAction:(id)sender;
- (IBAction) slopeAction:(id)sender;
- (IBAction) interceptAction:(id)sender;

@end

