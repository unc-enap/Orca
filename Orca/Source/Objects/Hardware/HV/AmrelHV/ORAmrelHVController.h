//
//  ORAmrelHVController.h
//  Orca
//
//  Created by Mark Howe on Thursday, Aug 20,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "OrcaObjectController.h"
#import "ORTimedTextField.h"

@interface ORAmrelHVController : OrcaObjectController 
{
	IBOutlet NSButton*		lockButton;
	IBOutlet NSButton*		rampEnabledACB;
	IBOutlet NSButton*		rampEnabledBCB;
	IBOutlet NSButton*		loadValuesAButton;
	IBOutlet NSButton*		loadValuesBButton;
	IBOutlet NSPopUpButton* numberOfChannelsPU;
	IBOutlet NSButton*		sendButton;
    IBOutlet NSTextField*   portStateField;
    IBOutlet NSPopUpButton* portListPopup;
    IBOutlet NSButton*      openPortButton;
	IBOutlet NSTextField*	hvPowerAField;
	IBOutlet NSTextField*	hvPowerBField;
    IBOutlet NSButton*      hvPowerAButton;
    IBOutlet NSButton*      hvPowerBButton;
    IBOutlet NSButton*      clrCurrentTripAButton;
    IBOutlet NSButton*      clrCurrentTripBButton;
	IBOutlet NSPopUpButton* polarityAPU;
	IBOutlet NSPopUpButton* polarityBPU;
	IBOutlet NSTextField*	setVoltageAField;
	IBOutlet NSTextField*	setVoltageBField;
	IBOutlet NSTextField*	actVoltageAField;
	IBOutlet NSTextField*	actVoltageBField;
	IBOutlet NSTextField*	actCurrentAField;
	IBOutlet NSTextField*	actCurrentBField;
	IBOutlet NSTextField*	maxCurrentAField;
	IBOutlet NSTextField*	maxCurrentBField;
	IBOutlet NSTextField*	rampRateAField;
	IBOutlet NSTextField*	rampRateBField;
	IBOutlet NSTextField*	rampStateAField;
	IBOutlet NSTextField*	rampStateBField;
	IBOutlet NSTextField*	setVoltageLabelA;
	IBOutlet NSTextField*	setVoltageLabelB;
	IBOutlet ORTimedTextField*	timeoutField;
	IBOutlet NSProgressIndicator*	rampingAProgress;
	IBOutlet NSProgressIndicator*	rampingBProgress;

	IBOutlet NSButton*      initAButton;
	IBOutlet NSButton*      initBButton;
	IBOutlet NSButton*      panicAButton;
	IBOutlet NSButton*      panicBButton;
	IBOutlet NSButton*      stopAButton;
	IBOutlet NSButton*      stopBButton;
	IBOutlet NSButton*      systemPanicBButton;
	IBOutlet NSProgressIndicator*	pollingProgress;
	IBOutlet NSPopUpButton* pollTimePopup;
	IBOutlet NSButton*      pollNowButton;
	IBOutlet NSImageView*	hvStateAImage;
	IBOutlet NSImageView*	hvStateBImage;
	IBOutlet NSButton*      moduleIDButton;
	IBOutlet NSButton*      syncButton;
	
	NSSize					oneChannelSize;
	NSSize					twoChannelSize;
}

#pragma mark ***Interface Management
- (void) timedOut:(NSNotification*)aNote;
- (void) rampStateChanged:(NSNotification*)aNote;
- (void) rampEnabledChanged:(NSNotification*)aNote;
- (void) rampRateChanged:(NSNotification*)aNote;
- (void) outputStateChanged:(NSNotification*)aNote;
- (void) numberOfChannelsChanged:(NSNotification*)aNote;
- (void) setVoltageChanged:(NSNotification*)aNote;
- (void) actVoltageChanged:(NSNotification*)aNote;
- (void) actCurrentChanged:(NSNotification*)aNote;
- (void) lockChanged:(NSNotification*)aNote;
- (void) portNameChanged:(NSNotification*)aNote;
- (void) portStateChanged:(NSNotification*)aNote;
- (void) pollTimeChanged:(NSNotification*)aNote;
- (void) polarityChanged:(NSNotification*)aNote;
- (void) dataIsValidChanged:(NSNotification*)aNote;
- (void) maxCurrentChanged:(NSNotification*)aNote;
- (void) adjustWindowSize;
- (void) updateButtons;
- (void) updateChannels;
- (void) updateChannelButtons:(int)i;

#pragma mark •••Actions
- (IBAction) stopRampAction:(id)sender;
- (IBAction) rampEnabledAction:(id)sender;
- (IBAction) numberOfChannelsAction:(id)sender;
- (IBAction) lockAction:(id) sender;
- (IBAction) portListAction:(id) sender;
- (IBAction) openPortAction:(id)sender;
- (IBAction) setVoltageAction:(id)sender;
- (IBAction) pollTimeAction:(id)sender;
- (IBAction) panicAction:(id)sender;
- (IBAction) systemPanicAction:(id)sender;
- (IBAction) loadAllValues:(id)sender;
- (IBAction) polarityAction:(id)sender;
- (IBAction) hwPowerAction:(id)sender;
- (IBAction) pollNowAction:(id)sender;
- (IBAction) rateRateAction:(id)sender;
- (IBAction) moduleIDAction:(id)sender;
- (IBAction) syncAction:(id)sender;
- (IBAction) clearCurrentTripAction:(id)sender;
- (IBAction) maxCurrentAction:(id)sender;

@end

