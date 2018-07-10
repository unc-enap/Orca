//
//  ORHPLabJackUE9Controller.h
//  Orca
//
//  Created by Mark Howe on Fri Nov 11,2011.
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
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
#import "ORLabJackUE9Model.h"

@class ORCardContainerView;

@interface ORLabJackUE9Controller : OrcaObjectController 
{
	IBOutlet ORCardContainerView* groupView;
	IBOutlet NSTextField*	localIDField;

	IBOutlet NSButton*      changeIPNumberButton;
	IBOutlet NSButton*      changeIDNumberButton;
	IBOutlet NSTextField*	ipConnectedTextField;
	IBOutlet NSTextField*	clockDivisorField;
	IBOutlet NSMatrix*		clockSelectionMatrix;
	IBOutlet NSMatrix*		timerEnableMaskMatrix;
	IBOutlet NSTextField*	ipAddressTextField;
	IBOutlet NSButton*		ipConnectButton;
	IBOutlet NSTabView*		tabView;	
	IBOutlet NSView*		totalView;
	IBOutlet NSTextField*	aOut1Field;
	IBOutlet NSTextField*	aOut0Field;
	IBOutlet NSButton*		shipDataCB;
	IBOutlet NSButton*		resetCounterButton;
	IBOutlet NSButton*		digitalOutputEnabledButton;
	IBOutlet NSTextField*	counter0Field;
	IBOutlet NSTextField*	counter1Field;
	IBOutlet NSMatrix*		timerMatrix;
	IBOutlet NSButton*		lockButton;
	IBOutlet NSMatrix*		nameMatrix;
	IBOutlet NSMatrix*		name1Matrix;
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
	IBOutlet NSSlider*		aOut0Slider;
	IBOutlet NSSlider*		aOut1Slider;
	IBOutlet NSMatrix*		minValueMatrix;
	IBOutlet NSMatrix*		maxValueMatrix;
	IBOutlet NSMatrix*		counterEnableMatrix;
	IBOutlet NSMatrix*		counterInputLineMatrix;
	IBOutlet NSMatrix*		timerInputLineMatrix;
	IBOutlet NSButton*		initTimersButton;
	IBOutlet NSMatrix*		timerResultMatrix;
	IBOutlet NSMatrix*		adcEnabledMatrix;

	//arggggg-- why oh why can't NSPopUpButtons live in NSMatrixes
	IBOutlet NSPopUpButton*		gainPU0;
	IBOutlet NSPopUpButton*		gainPU1;
	IBOutlet NSPopUpButton*		gainPU2;
	IBOutlet NSPopUpButton*		gainPU3;
	IBOutlet NSPopUpButton*		gainPU4;
	IBOutlet NSPopUpButton*		gainPU5;
	IBOutlet NSPopUpButton*		gainPU6;
	IBOutlet NSPopUpButton*		gainPU7;
	IBOutlet NSPopUpButton*		gainPU8;
	IBOutlet NSPopUpButton*		gainPU9;
	IBOutlet NSPopUpButton*		gainPU10;
	IBOutlet NSPopUpButton*		gainPU11;
	IBOutlet NSPopUpButton*		gainPU12;
	IBOutlet NSPopUpButton*		gainPU13;
	
	IBOutlet NSPopUpButton*		bipolarPU0;
	IBOutlet NSPopUpButton*		bipolarPU1;
	IBOutlet NSPopUpButton*		bipolarPU2;
	IBOutlet NSPopUpButton*		bipolarPU3;
	IBOutlet NSPopUpButton*		bipolarPU4;
	IBOutlet NSPopUpButton*		bipolarPU5;
	IBOutlet NSPopUpButton*		bipolarPU6;
	IBOutlet NSPopUpButton*		bipolarPU7;
	IBOutlet NSPopUpButton*		bipolarPU8;
	IBOutlet NSPopUpButton*		bipolarPU9;
	IBOutlet NSPopUpButton*		bipolarPU10;
	IBOutlet NSPopUpButton*		bipolarPU11;
	IBOutlet NSPopUpButton*		bipolarPU12;
	IBOutlet NSPopUpButton*		bipolarPU13;

	
	IBOutlet NSPopUpButton*		timerOptionPU0;
	IBOutlet NSPopUpButton*		timerOptionPU1;
	IBOutlet NSPopUpButton*		timerOptionPU2;
	IBOutlet NSPopUpButton*		timerOptionPU3;
	IBOutlet NSPopUpButton*		timerOptionPU4;
	IBOutlet NSPopUpButton*		timerOptionPU5;
    IBOutlet NSView*            mux80View;

	IBOutlet NSPanel*				ipChangePanel;
	IBOutlet NSTextField*			newIpAddressField;
	IBOutlet NSPanel*				idChangePanel;
	IBOutlet NSTextField*			newLocalIDField;
	
	NSPopUpButton* gainPU[kUE9NumAdcs];
	NSPopUpButton* bipolarPU[kUE9NumAdcs];
	NSPopUpButton* timerOptionPU[kUE9NumTimers];
	
	NSSize					ioSize;
	NSSize					timersSize;
	NSSize					setupSize;
	NSSize					mux80Size;
	NSView*					blankView;
}

#pragma mark •••Notifications
- (void) lockChanged:(NSNotification*)aNote;
- (void) updateButtons;

#pragma mark ***Interface Management
- (void) localIDChanged:(NSNotification*)aNote;
- (void) groupChanged:(NSNotification*)note;
- (void) adcEnabledChanged:(NSNotification*)aNote;
- (void) clockDivisorChanged:(NSNotification*)aNote;
- (void) counterEnableMaskChanged:(NSNotification*)aNote;
- (void) clockSelectionChanged:(NSNotification*)aNote;
- (void) timerEnableMaskChanged:(NSNotification*)aNote;
- (void) timerOptionChanged:(NSNotification*)aNote;
- (void) timerChanged:(NSNotification*)aNote;
- (void) isConnectedChanged:(NSNotification*)aNote;
- (void) ipAddressChanged:(NSNotification*)aNote;
- (void) involvedInProcessChanged:(NSNotification*)aNote;
- (void) aOut1Changed:(NSNotification*)aNote;
- (void) aOut0Changed:(NSNotification*)aNote;
- (void) gainChanged:(NSNotification*)aNote;
- (void) bipolarChanged:(NSNotification*)aNote;
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
- (void) timerResultChanged:(NSNotification*)aNote;
- (void) tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;

#pragma mark •••Actions
- (IBAction) openIDChangePanel:(id)sender;
- (IBAction) closeIDChangePanel:(id)sender;
- (IBAction) changeLocalIDAction:(id)sender;
- (IBAction) clockDivisorAction:(id)sender;
- (IBAction) counterEnableMaskAction:(id)sender;
- (IBAction) clockSelectionAction:(id)sender;
- (IBAction) timerEnableMaskAction:(id)sender;
- (IBAction) timerOptionAction:(id)sender;
- (IBAction) testAction:(id)sender;
- (IBAction) ipAddressAction:(id)sender;
- (IBAction) connectAction:(id)sender;
- (IBAction) aOut1Action:(id)sender;
- (IBAction) aOut0Action:(id)sender;
- (IBAction) shipDataAction:(id)sender;
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) digitalOutputEnabledAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) channelNameAction:(id)sender;
- (IBAction) channelUnitAction:(id)sender;
- (IBAction) timerAction:(id)sender;
- (IBAction) adcEnabledAction:(id)sender;

- (IBAction) doNameAction:(id)sender;
- (IBAction) doDirectionBitAction:(id)sender;
- (IBAction) doValueOutBitAction:(id)sender;

- (IBAction) updateAllAction:(id)sender;
- (IBAction) resetCounter:(id)sender;

- (IBAction) minValueAction:(id)sender;
- (IBAction) maxValueAction:(id)sender;
- (IBAction) lowLimitAction:(id)sender;
- (IBAction) hiLimitAction:(id)sender;
- (IBAction) slopeAction:(id)sender;
- (IBAction) interceptAction:(id)sender;
- (IBAction) bipolarAction:(id)sender;
- (IBAction) gainAction:(id)sender;
- (IBAction) initTimersAction:(id)sender;
- (IBAction) changeIPNumber:(id)sender;

- (IBAction) openIPChangePanel:(id)sender;
- (IBAction) closeIPChangePanel:(id)sender;
- (IBAction) printChannelLocations:(id)sender;

@end

