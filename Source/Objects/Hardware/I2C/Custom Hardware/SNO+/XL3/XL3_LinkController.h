//
//  XL3_LinkController.h
//  ORCA
//
//  Created by Jarek Kaspar on Sat, Jul 9, 2010.
//  Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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
#import "ORMultiStateBox.h"

@interface XL3_LinkController : OrcaObjectController
{
    ORMultiStateBox *msbox;
    bool HVAramping, HVBramping;
	NSView* blankView;
    IBOutlet NSView* xl3View;
	NSSize  basicSize;
	NSSize  compositeSize;
	IBOutlet NSTabView*		tabView;
	IBOutlet NSButton*		lockButton;
	//basic
	IBOutlet NSButton*              basicLockButton;
	IBOutlet NSPopUpButton*         selectedRegisterPU;
	IBOutlet NSButton*              basicReadButton;
	IBOutlet NSButton*              basicWriteButton;
	IBOutlet NSButton*              basicStopButton;
	IBOutlet NSButton*              basicStatusButton;
	IBOutlet NSProgressIndicator*	basicOpsRunningIndicator;
	IBOutlet NSButton*		autoIncrementCB;
	IBOutlet NSTextField*		repeatDelayField;
	IBOutlet NSStepper*		repeatDelayStepper;
	IBOutlet NSTextField*		repeatCountField;
	IBOutlet NSStepper*		repeatCountStepper;
	IBOutlet NSTextField*		writeValueField;
	IBOutlet NSStepper*		writeValueStepper;
	//composite
    IBOutlet NSButton *selectAllSlotMaskButton;
    IBOutlet NSButton *deselectAllSlotMaskButton;
    IBOutlet NSButton *selectSlotMaskButton;    
	IBOutlet NSProgressIndicator*	deselectCompositeRunningIndicator;
	IBOutlet NSButton*              compositeDeselectButton;
	IBOutlet NSMatrix*              compositeSlotMaskMatrix;
	IBOutlet NSTextField*           compositeSlotMaskField;
	IBOutlet NSPopUpButton*         compositeXl3ModePU;
	IBOutlet NSButton*              compositeSetXl3ModeButton;
	IBOutlet NSProgressIndicator*	compositeXl3ModeRunningIndicator;
	IBOutlet NSTextField*           compositeXl3RWAddressValueField;
	IBOutlet NSPopUpButton*         compositeXl3RWModePU;
	IBOutlet NSPopUpButton*         compositeXl3RWSelectPU;
	IBOutlet NSPopUpButton*         compositeXl3RWRegisterPU;
	IBOutlet NSTextField*           compositeXl3RWDataValueField;	
	IBOutlet NSButton*              compositeXl3RWButton;	
	IBOutlet NSProgressIndicator*	compositeXl3RWRunningIndicator;
	IBOutlet NSButton*              compositeQuitButton;	
	IBOutlet NSProgressIndicator*	compositeQuitRunningIndicator;
	IBOutlet NSTextField*           compositeSetPedestalField;	
	IBOutlet NSButton*              compositeSetPedestalButton;	
	IBOutlet NSProgressIndicator*	compositeSetPedestalRunningIndicator;
	IBOutlet NSButton*              compositeBoardIDButton;	
	IBOutlet NSProgressIndicator*	compositeBoardIDRunningIndicator;
	IBOutlet NSButton*              compositeResetCrateButton;	
	IBOutlet NSProgressIndicator*	compositeResetCrateRunningIndicator;
	IBOutlet NSButton*              compositeResetCrateAndXilinXButton;	
	IBOutlet NSProgressIndicator*	compositeResetCrateAndXilinXRunningIndicator;
	IBOutlet NSButton*              compositeResetFIFOAndSequencerButton;	
	IBOutlet NSProgressIndicator*	compositeResetFIFOAndSequencerRunningIndicator;
	IBOutlet NSButton*              compositeResetXL3StateMachineButton;	
	IBOutlet NSProgressIndicator*	compositeResetXL3StateMachineRunningIndicator;
	IBOutlet NSTextField*           compositeChargeInjMaskField;
	IBOutlet NSTextField*           compositeChargeInjChargeField;
	IBOutlet NSButton*              compositeChargeInjButton;
	IBOutlet NSProgressIndicator*	compositeChargeRunningIndicator;
    //mon
    IBOutlet NSButton*              monIsPollingCMOSRatesButton;
    IBOutlet NSButton*              monIsPollingPMTCurrentsButton;
    IBOutlet NSButton*              monIsPollingFECVoltagesButton;
    IBOutlet NSButton*              monIsPollingXl3VoltagesButton;
    IBOutlet NSButton*              monIsPollingHVSupplyButton;
    IBOutlet NSTextField*           monPollCMOSRatesMaskField; 
    IBOutlet NSTextField*           monPollPMTCurrentsMaskField; 
    IBOutlet NSTextField*           monPollFECVoltagesMaskField;

    IBOutlet NSTextField *pollRunStateLabel;
    IBOutlet NSButton *pollNowButton;
    IBOutlet NSButton *startPollButton;
    IBOutlet NSButton *stopPollButton;
    IBOutlet NSPopUpButton*         monPollingRatePU;
    IBOutlet NSButton*              monIsPollingVerboseButton;
    IBOutlet NSButton*              monIsPollingWithRunButton;
    IBOutlet NSTextField*           monPollingStatusField;
    IBOutlet NSTextField* monVltThresholdTextField0;
    IBOutlet NSTextField* monVltThresholdTextField1;
    IBOutlet NSTextField* monVltThresholdTextField2;
    IBOutlet NSTextField* monVltThresholdTextField3;
    IBOutlet NSTextField* monVltThresholdTextField4;
    IBOutlet NSTextField* monVltThresholdTextField5;
    IBOutlet NSTextField* monVltThresholdTextField6;
    IBOutlet NSTextField* monVltThresholdTextField7;
    IBOutlet NSTextField* monVltThresholdTextField8;
    IBOutlet NSTextField* monVltThresholdTextField9;
    IBOutlet NSTextField* monVltThresholdTextField10;
    IBOutlet NSTextField* monVltThresholdTextField11;
    IBOutlet NSButton* monVltThresholdInInitButton;
    IBOutlet NSButton* monVltThresholdSetButton;
    //hv
    IBOutlet NSTextField *hvRunStateLabel;
    IBOutlet NSButtonCell *hvAcceptReadbackButton;
    IBOutlet NSButton *hvOnButton;
    IBOutlet NSButton *hvOffButton;
    IBOutlet NSButton *hvStepUpButton;
    IBOutlet NSButton *hvStepDownButton;
    IBOutlet NSButton *hvRampToTargetButton;
    IBOutlet NSButton *hvRampDownButton;
    IBOutlet NSButton *hvStopRampButton;
    IBOutlet NSButton *loadNominalSettingsButton;
    IBOutlet NSButton *hvTriggersButton;
    IBOutlet NSTextField *hvRelayMaskLowField;
    IBOutlet NSTextField *hvRelayMaskHighField;
    IBOutlet NSTextField *hvRelayStatusField;
    IBOutlet NSMatrix *hvRelayMaskMatrix;
    IBOutlet NSButton *hvRelayOpenButton;
    IBOutlet NSButton *hvRelayCloseButton;
    IBOutlet NSMatrix *hvPowerSupplyMatrix;
    IBOutlet NSTextField *hvAOnStatusField;
    IBOutlet NSTextField *hvBOnStatusField;    
    IBOutlet NSTextField *hvATriggerStatusField;
    IBOutlet NSTextField *hvBTriggerStatusField;
    IBOutlet NSTextField *hvAVoltageSetField;
    IBOutlet NSTextField *hvBVoltageSetField;
    IBOutlet NSTextField *hvAVoltageReadField;
    IBOutlet NSTextField *hvBVoltageReadField;
    IBOutlet NSTextField *hvACurrentReadField;
    IBOutlet NSTextField *hvBCurrentReadField;
    IBOutlet NSTextField *hvTargetValueField;
    IBOutlet NSStepper *hvTargetValueStepper;
    IBOutlet NSTextField *hvCMOSRateLimitField;
    IBOutlet NSStepper *hvCMOSRateLimitStepper;
    IBOutlet NSTextField *hvCMOSRateIgnoreField;
    IBOutlet NSStepper *hvCMOSRateIgnoreStepper;
    
    IBOutlet NSTextField *owlStatus;
    IBOutlet NSTextField *nominalStatus;
    IBOutlet NSTextField *rampUpStatus;
    IBOutlet NSTextField *rampDownStatus;
    IBOutlet NSTextField *correctionStatus;
    IBOutlet NSTextField *overCurentStatus;
    IBOutlet NSTextField *overVoltageStatus;
    IBOutlet NSTextField *currentZeroStatus;
    IBOutlet NSTextField *currentZeroWhenStatus;
    IBOutlet NSTextField *setpointTolStatus;
    
    //connection
	IBOutlet NSButton*              toggleConnectButton;
	IBOutlet NSPopUpButton*         errorTimeOutPU;
    IBOutlet NSTextField*           connectionIPAddressField;
    IBOutlet NSTextField*           connectionIPPortField;
    IBOutlet NSTextField*           connectionCrateNumberField;
    IBOutlet NSButton*              connectionAutoConnectButton;
    IBOutlet NSButton*              connectionAutoInitCrateButton;
    
    NSBox *hvBStatusPanel;
    NSBox *hvAStatusPanel;
}	

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;
- (void) setModel:(id)aModel;

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) updateHVButtons;
- (void) checkGlobalSecurity;
- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item;

#pragma mark •••Interface Management
- (void) xl3LockChanged:(NSNotification*)aNotification;
- (void) opsRunningChanged:(NSNotification*)aNote;
- (void) keyDown:(NSEvent*)event;
- (void) cancelOperation:(id)sender;

//basic ops
- (void) selectedRegisterChanged:(NSNotification*)aNote;
- (void) repeatCountChanged:(NSNotification*)aNote;
- (void) repeatDelayChanged:(NSNotification*)aNote;
- (void) autoIncrementChanged:(NSNotification*)aNote;
- (void) basicOpsRunningChanged:(NSNotification*)aNote;
- (void) writeValueChanged:(NSNotification*)aNote;
//composite
- (void) compositeXl3ModeRunningChanged:(NSNotification*)aNote;
- (void) compositeXl3ModeChanged:(NSNotification*)aNote;
- (void) compositeSlotMaskChanged:(NSNotification*)aNote;
- (void) compositeXl3RWAddressChanged:(NSNotification*)aNote;
- (void) compositeXL3RWDataChanged:(NSNotification*)aNote;
- (void) compositeXl3PedestalMaskChanged:(NSNotification*)aNote;
- (void) compositeXl3ChargeInjChanged:(NSNotification*)aNote;
//mon
- (void) monPollXl3TimeChanged:(NSNotification*)aNote;
- (void) monIsPollingXl3Changed:(NSNotification*)aNote;
- (void) monIsPollingCMOSRatesChanged:(NSNotification*)aNote;
- (void) monPollCMOSRatesMaskChanged:(NSNotification*)aNote;
- (void) monIsPollingPMTCurrentsChanged:(NSNotification*)aNote;
- (void) monPollPMTCurrentsMaskChanged:(NSNotification*)aNote;
- (void) monIsPollingFECVoltagesChanged:(NSNotification*)aNote;
- (void) monPollFECVoltagesMaskChanged:(NSNotification*)aNote;
- (void) monIsPollingXl3VoltagesChanged:(NSNotification*)aNote;
- (void) monIsPollingHVSupplyChanged:(NSNotification*)aNote;
- (void) monIsPollingXl3WithRunChanged:(NSNotification*)aNote;
- (void) monPollStatusChanged:(NSNotification*)aNote;
- (void) monIsPollingVerboseChanged:(NSNotification*)aNote;
- (void) monVltThresholdChanged:(NSNotification*)aNote;
- (void) monVltThresholdInInitChanged:(NSNotification*)aNote;
//hv
- (void) hvRelayMaskChanged:(NSNotification*)aNote;
- (void) hvRelayStatusChanged:(NSNotification*)aNote;
- (void) hvStatusChanged:(NSNotification*)aNote;
- (void) hvTriggerStatusChanged:(NSNotification*)aNote;
- (void) hvTargetValueChanged:(NSNotification*)aNote;
- (void) hvCMOSRateLimitChanged:(NSNotification*)aNote;
- (void) hvCMOSRateIgnoreChanged:(NSNotification*)aNote;
- (void) hvChangePowerSupplyChanged:(NSNotification*)aNote;
//ip connection
- (void) connectStateChanged:(NSNotification*)aNote;
- (void) linkConnectionChanged:(NSNotification*)aNote;
- (void) errorTimeOutChanged:(NSNotification*)aNote;
- (void) connectionAutoConnectChanged:(NSNotification*)aNote;

#pragma mark •••Helper
- (void) populateOps;
- (void) populatePullDown;

#pragma mark •••Actions
- (IBAction) incXL3Action:(id)sender;
- (IBAction) decXL3Action:(id)sender;
- (IBAction) lockAction:(id)sender;
- (IBAction) opsAction:(id)sender;
//basic
- (IBAction) basicSelectedRegisterAction:(id)sender;
- (IBAction) basicReadAction:(id)sender;
- (IBAction) basicWriteAction:(id)sender;
- (IBAction) basicStopAction:(id)sender;
- (IBAction) basicStatusAction:(id) sender;
- (IBAction) repeatCountAction:(id) sender;
- (IBAction) repeatDelayAction:(id) sender;
- (IBAction) autoIncrementAction:(id) sender;
- (IBAction) writeValueAction:(id) sender;
//composite
- (IBAction) compositeSlotMaskAction:(id)sender;
- (IBAction) compositeSlotMaskFieldAction:(id)sender;
- (IBAction) compositeSlotMaskSelectAction:(id)sender;
- (IBAction) compositeSlotMaskDeselectAction:(id)sender;
- (IBAction) compositeSlotMaskPresentAction:(id)sender;
- (IBAction) compositeXl3ModeAction:(id)sender;
- (IBAction) compositeXl3ModeSetAction:(id)sender;
- (IBAction) compositeXl3RWAddressValueAction:(id)sender;
- (IBAction) compositeXl3RWModeAction:(id)sender;
- (IBAction) compositeXl3RWSelectAction:(id)sender;
- (IBAction) compositeXl3RWRegisterAction:(id)sender;
- (IBAction) compositeXl3RWDataValueAction:(id)sender;
- (IBAction) compositeSetPedestalValue:(id)sender;
- (IBAction) compositeXl3ChargeInjMaskAction:(id)sender;
- (IBAction) compositeXl3ChargeInjChargeAction:(id)sender;
//mon
- (IBAction) monIsPollingCMOSRatesAction:(id)sender;
- (IBAction) monIsPollingPMTCurrentsAction:(id)sender;
- (IBAction) monIsPollingFECVoltagesAction:(id)sender;
- (IBAction) monIsPollingXl3VoltagesAction:(id)sender;
- (IBAction) monIsPollingHVSupplyAction:(id)sender;
- (IBAction) monPollCMOSRatesMaskAction:(id)sender;
- (IBAction) monPollPMTCurrentsMaskAction:(id)sender;
- (IBAction) monPollFECVoltagesMaskAction:(id)sender;
- (IBAction) monPollingRateAction:(id)sender;
- (IBAction) monIsPollingVerboseAction:(id)sender;
- (IBAction) monIsPollingWithRunAction:(id)sender;
- (IBAction) monPollNowAction:(id)sender;
- (IBAction) monStartPollingAction:(id)sender;
- (IBAction) monStopPollingAction:(id)sender;
- (IBAction) monVltThresholdAction:(id)sender;
- (IBAction) monVltThresholdInInitAction:(id)sender;
- (IBAction) monVltThresholdSetAction:(id)sender;
//hv
@property (assign) IBOutlet NSBox *hvBStatusPanel;
@property (assign) IBOutlet NSBox *hvAStatusPanel;
	

- (IBAction)hvRelayMaskHighAction:(id)sender;
- (IBAction)hvRelayMaskLowAction:(id)sender;
- (IBAction)hvRelayMaskMatrixAction:(id)sender;
- (IBAction)hvRelaySetAction:(id)sender;
- (IBAction)hvRelayOpenAllAction:(id)sender;
- (IBAction)hvCheckInterlockRelaysAction:(id)sender;
- (IBAction)hvTurnOnAction:(id)sender;
- (IBAction)hvTurnOffAction:(id)sender;
- (IBAction)hvAcceptReadback:(id)sender;
- (IBAction)hvTargetValueAction:(id)sender;
- (IBAction)hvCMOSRateLimitAction:(id)sender;
- (IBAction)hvCMOSRateIgnoreAction:(id)sender;
- (IBAction)hvChangePowerSupplyAction:(id)sender;
- (IBAction)hvStepUpAction:(id)sender;
- (IBAction)hvStepDownAction:(id)sender;
- (IBAction)hvRampToTargetAction:(id)sender;
- (IBAction)hvRampDownAction:(id)sender;
- (IBAction)hvRampPauseAction:(id)sender;
- (IBAction)hvPanicAction:(id)sender;
- (IBAction)hvTriggerAction:(id)sender;
- (IBAction)loadNominalSettingsAction:(id)sender;

//connection
- (IBAction) toggleConnectAction:(id)sender;
- (IBAction) errorTimeOutAction:(id)sender;
- (IBAction) connectionAutoConnectAction:(id)sender;

@end
