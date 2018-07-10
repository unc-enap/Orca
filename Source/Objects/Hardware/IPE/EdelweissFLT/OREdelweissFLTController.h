
//
//  OREdelweissFLTController.h
//  Orca
//
//  Created by Mark Howe on Wed Aug 24 2005.
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


#pragma mark ‚Ä¢‚Ä¢‚Ä¢Imported Files
#import "OREdelweissFLTModel.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface OREdelweissFLTController : OrcaObjectController {
	@private
    
        //FLT settings
        IBOutlet NSButton*		settingLockButton;
	IBOutlet   NSButton* saveIonChanFilterOutputRecordsCB;//unused
	IBOutlet   NSProgressIndicator* progressOfChargeBBIndicator;
	IBOutlet   NSTextField* progressOfChargeBBTextField;
	IBOutlet   NSTextField* chargeBBFileForFiberTextField;
	IBOutlet   NSTextField* ionToHeatDelayTextField;
	IBOutlet   NSTextField* wCmdArg2TextField;
	IBOutlet   NSTextField* wCmdArg1TextField;
	IBOutlet   NSTextField* wCmdCodeTextField;
    
    //FIC Tab
	IBOutlet   NSTextField* chargeFICFileTextField;
	IBOutlet   NSProgressIndicator* progressOfChargeFICIndicator;
	IBOutlet   NSTextField* progressOfChargeFICTextField;
    //regs
	IBOutlet   NSTextField* ficCardTriggerCmdTextField;
	IBOutlet   NSTextField* ficCardADC23CtrlRegTextField;
	IBOutlet   NSTextField* ficCardADC01CtrlRegTextField;
	IBOutlet   NSTextField* ficCardCtrlReg2TextField;
	IBOutlet   NSTextField* ficCardCtrlReg1TextField;
    IBOutlet   NSPopUpButton* fiberSelectForFICCardPU;
    //subelements
	IBOutlet   NSTextField* ficCardCtrlReg1BlockLenTextField;
	IBOutlet   NSMatrix*    ficCardCtrlReg1ChanEnableMatrix;
	IBOutlet   NSSlider*    ficCardCtrlReg2AddrOffsetSlider;
	IBOutlet   NSTextField* ficCardCtrlReg2AddrOffsTextField;
	IBOutlet   NSButton*    ficCardCtrlReg2GapCB;
	IBOutlet   NSButton*    ficCardCtrlReg2SyncResCB;
	IBOutlet   NSMatrix*    ficCardCtrlReg2SendChMatrix;
	IBOutlet   NSMatrix*    ficCardADC0123CtrlRegMatrix;
    IBOutlet   NSPopUpButton* ficCardADC0CtrlRegPU;
    IBOutlet   NSPopUpButton* ficCardADC1CtrlRegPU;
    IBOutlet   NSPopUpButton* ficCardADC2CtrlRegPU;
    IBOutlet   NSPopUpButton* ficCardADC3CtrlRegPU;
    
	//IBOutlet   NSTextField* ficCardCtrlReg1BlockLenTextField;
	//IBOutlet   NSMatrix*    ficCardCtrlReg1ChanEnableMatrix;
	IBOutlet   NSTextField* ficCardTriggerCmdDelayTextField;
	IBOutlet   NSMatrix*    ficCardTriggerCmdChanMaskMatrix;
    
    //Trigger Tab
	IBOutlet   NSTextField* heatChannelsTextField;
	IBOutlet   NSTextField* ionChannelsTextField;
	IBOutlet   NSTextField* heatChannelsTextField2;
	IBOutlet   NSTextField* ionChannelsTextField2;
    //IBOutlet NSButton*		settingLockButton;
	IBOutlet   NSMatrix*    channelNameMatrix;
	IBOutlet   NSMatrix*    negPosPolarityMatrix;
	IBOutlet   NSMatrix*    gapMatrix;
	IBOutlet   NSMatrix*    downSamplingMatrix;
	IBOutlet   NSMatrix*    shapingLengthMatrix;
		//hirate settings
	    IBOutlet   NSTextField* hitrateLimitIonTextField;
	    IBOutlet   NSTextField* hitrateLimitHeatTextField;
		IBOutlet NSMatrix*		hitRateEnableMatrix;
		IBOutlet NSPopUpButton*	hitRateLengthPU;
		IBOutlet NSTextField*	hitRateLengthTextField;
		IBOutlet NSButton*		hitRateAllButton;
		IBOutlet NSButton*		hitRateNoneButton;
	IBOutlet   NSMatrix*    heatWindowStartMatrix;
	IBOutlet   NSMatrix*    heatWindowEndMatrix;
    
    //BB access tab
	IBOutlet   NSTextField* RgTextField;
	IBOutlet   NSTextField* RtTextField;
	IBOutlet   NSStepper*   RtStepper;
	IBOutlet   NSTextField* D2TextField;
	IBOutlet   NSTextField* D3TextField;
    
	IBOutlet   NSMatrix* dacbMatrix;
	IBOutlet   NSMatrix* signbMatrix;
	IBOutlet   NSMatrix* dacaMatrix;
	IBOutlet   NSMatrix* signaMatrix;
	IBOutlet   NSMatrix* adcRgForBBAccessMatrix;

	IBOutlet   NSMatrix*    polarDacMatrix;
	IBOutlet   NSMatrix*    triDacMatrix;
	IBOutlet   NSMatrix*    rectDacMatrix;
	IBOutlet   NSTextField* BB0x0ACmdMaskTextField; //Alim/0x0A command
	IBOutlet   NSTextField* temperatureTextField; //Alim/0x0A command
    
	IBOutlet   NSMatrix*    BB0x0ACmdMaskMatrix; //Alim/0x0A command
	IBOutlet   NSTextField* chargeBBFileTextField;
	IBOutlet   NSPopUpButton* pollBBStatusIntervallPU;
    IBOutlet   NSProgressIndicator*	pollBBStatusIntervallIndicator;
	IBOutlet   NSButton*    writeToBBModeCB;
    IBOutlet   NSProgressIndicator*	writeToBBModeIndicator;
    IBOutlet   NSSegmentedControl*	setWriteToBBSegControl;
    
	IBOutlet   NSMatrix* adcValueForBBAccessMatrix;
	IBOutlet   NSMatrix* adcMultForBBAccessMatrix;
	IBOutlet   NSMatrix* adcFreqkHzForBBAccessMatrix;
	IBOutlet   NSButton* useBroadcastIdforBBAccessCB;
	IBOutlet   NSTextField* fiberIsBBv1TextField;
	IBOutlet   NSTextField* idBBforBBAccessTextField;
	IBOutlet   NSTextField* idBBforWCommandTextField;//clone of idBBforBBAccessTextField
	IBOutlet   NSTextField* idBBforAlimCommandTextField;//clone of idBBforBBAccessTextField
	IBOutlet   NSPopUpButton* fiberSelectForBBAccessPU;
	IBOutlet   NSMatrix* relaisStatesBBMatrix;//obsolete
	  IBOutlet   NSButton* refBBCheckBox;//is in relaisState
	  IBOutlet   NSMatrix* adcOnOffBBMatrix;//is in relaisState
      IBOutlet   NSPopUpButton* relais1PU;//is in relaisState
      IBOutlet   NSPopUpButton* relais2PU;//is in relaisState
	  IBOutlet   NSMatrix* mezOnOffBBMatrix;//is in relaisState
    IBOutlet   NSPopUpButton* fiberSelectForBBStatusBitsPU;
	IBOutlet   NSTextField* statusAlimBBTextField;
        
        
	    IBOutlet NSButton*      tpixCB;//TODO: obsolete 2014 -tb-
//	IBOutlet   No Outlet* swTriggerIsRepeatingNo Outlet;
		
	IBOutlet   NSTextField* repeatSWTriggerModeTextField;
	IBOutlet   NSTextField* repeatSWTriggerDelayTextField;
		
		IBOutlet NSPopUpButton*	repeatSWTriggerModePU;
		IBOutlet NSProgressIndicator*	swTriggerProgress;
		//control register
	    IBOutlet   NSTextField* controlRegisterTextField;
		IBOutlet NSPopUpButton* fltModeFlagsPU;
		IBOutlet NSPopUpButton* statusBitPosPU;
	    IBOutlet   NSMatrix*    ficOnFiberMaskMatrix;
		IBOutlet NSPopUpButton* statusLatencyPU;
	    IBOutlet NSButton*      vetoFlagCB;
	IBOutlet   NSTextField* totalTriggerNRegisterTextField;
	    //other registers
	    IBOutlet   NSMatrix*    fiberOutMaskMatrix;
        
	IBOutlet   NSTextField* statusRegisterTextField;
		IBOutlet NSMatrix*		fiberDelaysMatrix;
	    IBOutlet NSTextField*   fiberDelaysTextField;
	    IBOutlet NSButton*      fastWriteCB;
	    IBOutlet NSTextField*   streamMaskTextField;
		IBOutlet NSMatrix*		streamMaskMatrix;
	    IBOutlet NSTextField*   heatTriggerMaskTextField;
		IBOutlet NSMatrix*		heatTriggerMaskMatrix;
	    IBOutlet NSTextField*   ionTriggerMaskTextField;
		IBOutlet NSMatrix*		ionTriggerMaskMatrix;
		
		IBOutlet NSMatrix*		fiberEnableMaskMatrix;
		IBOutlet NSMatrix*		BBv1MaskMatrix;
		IBOutlet NSPopUpButton* selectFiberTrigPU;
		
		IBOutlet NSMatrix*		displayEventRateMatrix;
		IBOutlet NSTextField*	targetRateField;
        IBOutlet NSTextField*   fltSlotNumTextField;
        IBOutlet NSMatrix*      fltSlotNumMatrix;
		IBOutlet NSButton*		storeDataInRamCB;
		IBOutlet NSPopUpButton*	filterLengthPU;
		IBOutlet NSPopUpButton*	gapLengthPU;
		IBOutlet NSTextField*   postTriggerTimeField;
		IBOutlet NSMatrix*		fifoBehaviourMatrix;
		IBOutlet NSTextField*	interruptMaskField;
		IBOutlet NSPopUpButton*	modeButton;
		IBOutlet NSButton*		versionButton;
		IBOutlet NSButton*		statusButton;
		IBOutlet NSButton*		initBoardButton;
		IBOutlet NSButton*		reportButton;
		IBOutlet NSButton*		resetButton;
		IBOutlet NSMatrix*		gainTextFields;
		IBOutlet NSMatrix*		thresholdTextFields;
		IBOutlet NSMatrix*		triggerEnabledCBs;
		IBOutlet NSButton*		triggersAllButton;
		IBOutlet NSButton*		triggersNoneButton;
		IBOutlet NSButton*		defaultsButton;
	
		//rate page
		IBOutlet NSMatrix*		rateTextFields;
		IBOutlet NSMatrix*		rateRegulationCBs;
		
		IBOutlet ORValueBarGroupView*		rate0;
		IBOutlet ORValueBarGroupView*		totalRate;
		IBOutlet NSButton*					rateLogCB;
		IBOutlet ORCompositeTimeLineView*	timeRatePlot;
		IBOutlet NSButton*					timeRateLogCB;
		IBOutlet NSButton*					totalRateLogCB;
		IBOutlet NSTextField*				totalHitRateField;
		IBOutlet NSTabView*					tabView;	
		IBOutlet NSView*					totalView;
		
		//test page
		IBOutlet NSButton*		testButton;
		IBOutlet NSMatrix*		testEnabledMatrix;
		IBOutlet NSMatrix*		testStatusMatrix;
		
		NSNumberFormatter*		rateFormatter;
		NSSize					settingSize;
		NSSize					triggerSize;
		NSSize					rateSize;
		NSSize					BBAccessSize;
		NSSize					ficSize;
		NSSize					testSize;
		NSSize					lowlevelSize;
		NSView*					blankView;
        
        //low level
		IBOutlet NSPopUpButton*	registerPopUp;
		IBOutlet NSPopUpButton*	channelPopUp;
		IBOutlet NSStepper* 	regWriteValueStepper;
		IBOutlet NSTextField* 	regWriteValueTextField;
		IBOutlet NSButton*		regWriteButton;
		IBOutlet NSButton*		regReadButton;
		IBOutlet NSFormatter* 	regWriteValueTextFieldFormatter;
	    IBOutlet NSPopUpButton* lowLevelRegInHexPU;
	
    
    
		IBOutlet NSButton*      noiseFloorButton;
		//offset panel
		IBOutlet NSPanel*				noiseFloorPanel;
		IBOutlet NSTextField*			noiseFloorOffsetField;
		IBOutlet NSTextField*			noiseFloorStateField;
		IBOutlet NSButton*				startNoiseFloorButton;
		IBOutlet NSProgressIndicator*	noiseFloorProgress;
		IBOutlet NSTextField*			noiseFloorStateField2;
		
};
#pragma mark ‚Ä¢‚Ä¢‚Ä¢Initialization
- (id)   init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Notifications
- (void) registerNotificationObservers;
- (void) updateButtons;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Interface Management
- (void) saveIonChanFilterOutputRecordsChanged:(NSNotification*)aNote;
- (void) repeatSWTriggerDelayChanged:(NSNotification*)aNote;
- (void) hitrateLimitIonChanged:(NSNotification*)aNote;
- (void) hitrateLimitHeatChanged:(NSNotification*)aNote;
- (void) chargeFICFileChanged:(NSNotification*)aNote;
- (void) progressOfChargeFICChanged:(NSNotification*)aNote;
//FIC card
- (void) ficCardTriggerCmdChanged:(NSNotification*)aNote;
- (void) ficCardADC23CtrlRegChanged:(NSNotification*)aNote;
- (void) ficCardADC01CtrlRegChanged:(NSNotification*)aNote;
- (void) ficCardCtrlReg2Changed:(NSNotification*)aNote;
- (void) ficCardCtrlReg1Changed:(NSNotification*)aNote;

- (void) pollBBStatusIntervallChanged:(NSNotification*)aNote;
- (void) progressOfChargeBBChanged:(NSNotification*)aNote;
- (void) chargeBBFileForFiberChanged:(NSNotification*)aNote;
- (void) BB0x0ACmdMaskChanged:(NSNotification*)aNote;

- (void) chargeBBFileChanged:(NSNotification*)aNote;
- (void) ionToHeatDelayChanged:(NSNotification*)aNote;
- (void) heatTriggerMaskChanged:(NSNotification*)aNote;
- (void) ionTriggerMaskChanged:(NSNotification*)aNote;
- (void) channelNameMatrixChanged:(NSNotification*)aNote;
- (void) triggerParameterChanged:(NSNotification*)aNote;
- (void) lowLevelRegInHexChanged:(NSNotification*)aNote;
- (void) writeToBBModeChanged:(NSNotification*)aNote;
- (void) wCmdArg2Changed:(NSNotification*)aNote;
- (void) wCmdArg1Changed:(NSNotification*)aNote;
- (void) wCmdCodeChanged:(NSNotification*)aNote;
- (void) RgRtChanged:(NSNotification*)aNote;
- (void) D2Changed:(NSNotification*)aNote;
- (void) D3Changed:(NSNotification*)aNote;
- (void) dacbChanged:(NSNotification*)aNote;
- (void) signbChanged:(NSNotification*)aNote;
- (void) dacaChanged:(NSNotification*)aNote;
- (void) signaChanged:(NSNotification*)aNote;
- (void) adcRgForBBAccessChanged:(NSNotification*)aNote;
- (void) adcValueForBBAccessChanged:(NSNotification*)aNote;
- (void) adcMultForBBAccessChanged:(NSNotification*)aNote;
- (void) adcFreqkHzForBBAccessChanged:(NSNotification*)aNote;
- (void) useBroadcastIdforBBAccessChanged:(NSNotification*)aNote;
- (void) polarDacChanged:(NSNotification*)aNote;
- (void) triDacChanged:(NSNotification*)aNote;
- (void) rectDacChanged:(NSNotification*)aNote;
- (void) temperatureChanged:(NSNotification*)aNote;


- (void) idBBforBBAccessChanged:(NSNotification*)aNote;
- (void) statusBitsBBDataChanged:(NSNotification*)aNote;
- (void) fiberSelectForBBAccessChanged:(NSNotification*)aNote;
- (void) relaisStatesBBChanged:(NSNotification*)aNote;
- (void) fiberSelectForBBStatusBitsChanged:(NSNotification*)aNote;
- (void) fiberOutMaskChanged:(NSNotification*)aNote;
- (void) swTriggerIsRepeatingChanged:(NSNotification*)aNote;
- (void) repeatSWTriggerModeChanged:(NSNotification*)aNote;
- (void) controlRegisterChanged:(NSNotification*)aNote;
- (void) totalTriggerNRegisterChanged:(NSNotification*)aNote;
- (void) statusRegisterChanged:(NSNotification*)aNote;
- (void) fastWriteChanged:(NSNotification*)aNote;
- (void) fiberDelaysChanged:(NSNotification*)aNote;
- (void) streamMaskChanged:(NSNotification*)aNote;
- (void) selectFiberTrigChanged:(NSNotification*)aNote;
- (void) BBv1MaskChanged:(NSNotification*)aNote;
- (void) fiberEnableMaskChanged:(NSNotification*)aNote;
- (void) fltModeFlagsChanged:(NSNotification*)aNote;
- (void) tpixChanged:(NSNotification*)aNote;
- (void) statusBitPosChanged:(NSNotification*)aNote;
- (void) ficOnFiberMaskChanged:(NSNotification*)aNote;

- (void) targetRateChanged:(NSNotification*)aNote;
- (void) noiseFloorChanged:(NSNotification*)aNote;
- (void) noiseFloorOffsetChanged:(NSNotification*)aNote;
- (void) storeDataInRamChanged:(NSNotification*)aNote;
- (void) filterLengthChanged:(NSNotification*)aNote;
- (void) gapLengthChanged:(NSNotification*)aNote;
- (void) postTriggerTimeChanged:(NSNotification*)aNote;
- (void) fifoBehaviourChanged:(NSNotification*)aNote;

- (void) interruptMaskChanged:(NSNotification*)aNote;
- (void) populatePullDown;
- (void) updateWindow;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) enableRegControls;
- (void) slotChanged:(NSNotification*)aNote;
- (void) modeChanged:(NSNotification*)aNote;
- (void) gainChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) gainArrayChanged:(NSNotification*)aNote;
- (void) thresholdArrayChanged:(NSNotification*)aNote;
- (void) triggersEnabledArrayChanged:(NSNotification*)aNote;
- (void) triggerEnabledChanged:(NSNotification*)aNote;

- (void) hitRateLengthChanged:(NSNotification*)aNote;
- (void) hitRateEnabledMaskChanged:(NSNotification*)aNote;
- (void) hitRateChanged:(NSNotification*)aNote;
- (void) scaleAction:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) testStatusArrayChanged:(NSNotification*)aNote;
- (void) testEnabledArrayChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) selectedRegIndexChanged:(NSNotification*) aNote;
- (void) writeValueChanged:(NSNotification*) aNote;
- (void) selectedChannelValueChanged:(NSNotification*) aNote;

#pragma mark ‚Ä¢‚Ä¢‚Ä¢Actions
- (IBAction) saveIonChanFilterOutputRecordsCBAction:(id)sender;
- (IBAction) repeatSWTriggerDelayTextFieldAction:(id)sender;
- (IBAction) hitrateLimitIonTextFieldAction:(id)sender;
- (IBAction) hitrateLimitHeatTextFieldAction:(id)sender;
- (IBAction) chargeFICFileTextFieldAction:(id)sender;
//- (IBAction) progressOfChargeFICIndicatorAction:(id)sender;
- (IBAction) selectChargeFICFileButtonAction:(id) sender;
- (IBAction) chargeFICFileButtonAction:(id) sender;
- (IBAction) killChargeFICJobButtonAction:(id) sender;

//FIC card regs
- (IBAction) ficCardTriggerCmdTextFieldAction:(id)sender;
- (IBAction) ficCardADC23CtrlRegTextFieldAction:(id)sender;
- (IBAction) ficCardADC01CtrlRegTextFieldAction:(id)sender;
- (IBAction) ficCardCtrlReg1TextFieldAction:(id)sender;
//FIC buttons
- (IBAction) sendFICCtrl1RegButtonAction:(id)sender;
- (IBAction) sendFICCtrl2RegButtonAction:(id)sender;
- (IBAction) sendFICADC01CtrlRegButtonAction:(id)sender;
- (IBAction) sendFICADC23CtrlRegButtonAction:(id)sender;
- (IBAction) sendFICTriggerCmdButtonAction:(id)sender;

//FIC subelements
- (IBAction) ficCardCtrlReg1BlockLenTextFieldAction:(id)sender;
- (IBAction) ficCardCtrlReg1ChanEnableMatrixAction:(id)sender;

- (IBAction) ficCardTriggerCmdDelayTextFieldAction:(id)sender;
- (IBAction) ficCardTriggerCmdChanMaskMatrixAction:(id)sender;

- (IBAction) ficCardCtrlReg2AddrOffsetSliderAction:(id)sender;
- (IBAction) ficCardCtrlReg2TextFieldAction:(id)sender;
- (IBAction) ficCardCtrlReg2AddrOffsTextFieldAction:(id)sender;
- (IBAction) ficCardCtrlReg2GapCBAction:(id)sender;
- (IBAction) ficCardCtrlReg2SyncResCBAction:(id)sender;
- (IBAction) ficCardCtrlReg2SendChMatrixAction:(id)sender;

- (IBAction) ficCardADC0CtrlRegPUAction:(id)sender;
- (IBAction) ficCardADC1CtrlRegPUAction:(id)sender;
- (IBAction) ficCardADC2CtrlRegPUAction:(id)sender;
- (IBAction) ficCardADC3CtrlRegPUAction:(id)sender;
- (IBAction) ficCardADC0123CtrlRegMatrixAction:(id)sender;



- (IBAction) pollBBStatusIntervallPUAction:(id)sender;
- (IBAction) devTabButtonAction:(id) sender;
- (IBAction) killChargeBBJobButtonAction:(id) sender;
- (IBAction) selectChargeBBFileForFiberAction:(id) sender;
- (IBAction) chargeBBFileForFiberTextFieldAction:(id)sender;
- (void) chargeBBFileForFiberButtonAction:(id) sender;
- (IBAction) sendBB0x0ABloqueAction:(id)sender;
- (IBAction) sendBB0x0ADebloqueAction:(id)sender;
- (IBAction) sendBB0x0ADemarrageAction:(id)sender;
- (IBAction) sendBB0x0ACmdAction:(id)sender;
- (IBAction) BB0x0ACmdMaskTextFieldAction:(id)sender;
- (IBAction) BB0x0ACmdMaskMatrixAction:(id)sender;
- (IBAction) chargeBBFileCommandSendButtonAction:(id)sender;
- (IBAction) chargeBBFileTextFieldAction:(id)sender;
- (IBAction) ionToHeatDelayTextFieldAction:(id)sender;
- (IBAction) heatTriggerMaskTextFieldAction:(id)sender;
- (IBAction) ionTriggerMaskTextFieldAction:(id)sender;
- (IBAction) lowLevelRegInHexPUAction:(id)sender;
- (IBAction) writeToBBModeCBAction:(id)sender;
- (IBAction) writeAllToBBButtonAction:(id)sender;
- (IBAction) setDefaultsToBBButtonAction:(id)sender;
- (IBAction) setAndWriteDefaultsToBBButtonAction:(id)sender;
- (IBAction) wCmdArg2TextFieldAction:(id)sender;
- (IBAction) wCmdArg1TextFieldAction:(id)sender;
- (IBAction) wCmdCodeTextFieldAction:(id)sender;
- (IBAction) sendWCommandButtonAction:(id)sender;

- (IBAction) RgTextFieldAction:(id)sender;
- (IBAction) RtTextFieldAction:(id)sender;
- (IBAction) RtStepperAction:(id)sender;

- (IBAction) D2TextFieldAction:(id)sender;
- (IBAction) D3TextFieldAction:(id)sender;


- (IBAction) dacbMatrixAction:(id)sender;
- (IBAction) signbMatrixAction:(id)sender;
- (IBAction) dacaMatrixAction:(id)sender;
- (IBAction) signaMatrixAction:(id)sender;
- (IBAction) readBBStatusBBAccessButtonAction:(id)sender;
- (IBAction) dumpBBStatusBBAccessTextFieldAction:(id)sender;
- (IBAction) adcRgForBBAccessMatrixAction:(id)sender;
- (IBAction) adcValueForBBAccessMatrixAction:(id)sender;

- (IBAction) adcMultForBBAccessMatrixAction:(id)sender;    //gain (gain+freq=filter)
- (IBAction) adcFreqkHzForBBAccessMatrixAction:(id)sender; //freq (gain+freq=filter)

- (IBAction) polarDacMatrixAction:(id)sender;
- (IBAction) triDacMatrixAction:(id)sender;
- (IBAction) rectDacMatrixAction:(id)sender;


- (IBAction) useBroadcastIdforBBAccessCBAction:(id)sender;
- (IBAction) idBBforBBAccessTextFieldAction:(id)sender;
- (IBAction) fiberSelectForBBAccessPUAction:(id)sender;
- (IBAction) relaisStatesBBMatrixAction:(id)sender;
- (IBAction) refBBCheckBoxAction:(id)sender;
- (IBAction) adcOnOffBBMatrixAction:(id)sender;
- (IBAction) relais1PUAction:(id)sender;
- (IBAction) relais2PUAction:(id)sender;
- (IBAction) mezOnOffBBMatrixAction:(id)sender;
- (IBAction) fiberSelectForBBStatusBitsPUAction:(id)sender;
- (IBAction) readBBStatusBitsButtonAction:(id)sender;
- (IBAction) readAllBBStatusBitsButtonAction:(id)sender;
- (IBAction) fiberOutMaskMatrixAction:(id)sender;
- (IBAction) readFiberOutMaskButtonAction:(id)sender;
- (IBAction) writeFiberOutMaskButtonAction:(id)sender;
- (IBAction) tpixCBAction:(id)sender;
- (IBAction) statusBitPosPUAction:(id)sender;
- (IBAction) ficOnFiberMaskMatrixAction:(id)sender;

- (IBAction) repeatSWTriggerModePUAction:(id)sender;
- (IBAction) repeatSWTriggerModeTextFieldAction:(id)sender;
- (IBAction) controlRegisterTextFieldAction:(id)sender;
- (IBAction) writeControlRegisterButtonAction:(id)sender;
- (IBAction) readControlRegisterButtonAction:(id)sender;

- (IBAction) statusLatencyPUAction:(id)sender;
- (IBAction) vetoFlagCBAction:(id)sender;

- (IBAction) totalTriggerNRegisterTextFieldAction:(id)sender;
- (void) readStatusButtonAction:(id)sender;
- (IBAction) statusRegisterTextFieldAction:(id)sender;
- (IBAction) fastWriteCBAction:(id)sender;
- (void) writeFiberDelaysButtonAction:(id)sender;
- (void) readFiberDelaysButtonAction:(id)sender;
- (IBAction) fiberDelaysTextFieldAction:(id)sender;
- (IBAction) fiberDelaysMatrixAction:(id)sender;

//streaming
- (IBAction) streamMaskEnableAllAction:(id)sender;
- (IBAction) streamMaskEnableNoneAction:(id)sender;
- (IBAction) streamMaskTextFieldAction:(id)sender;
- (IBAction) streamMaskMatrixAction:(id)sender;
- (IBAction) writeStreamMaskRegisterButtonAction:(id)sender;
- (IBAction) readStreamMaskRegisterButtonAction:(id)sender;

//trigger
- (IBAction) writeAllTriggerParameterButtonAction:(id)sender;

- (IBAction) heatTriggerMaskEnableAllAction:(id)sender;
- (IBAction) heatTriggerMaskEnableNoneAction:(id)sender;
- (IBAction) heatTriggerMaskTextFieldAction:(id)sender;
- (IBAction) heatTriggerMaskMatrixAction:(id)sender;
- (IBAction) writeHeatTriggerMaskRegisterButtonAction:(id)sender;
- (IBAction) readHeatTriggerMaskRegisterButtonAction:(id)sender;

- (IBAction) ionTriggerMaskEnableAllAction:(id)sender;
- (IBAction) ionTriggerMaskEnableNoneAction:(id)sender;
- (IBAction) ionTriggerMaskTextFieldAction:(id)sender;
- (IBAction) ionTriggerMaskMatrixAction:(id)sender;
- (IBAction) writeIonTriggerMaskRegisterButtonAction:(id)sender;
- (IBAction) readIonTriggerMaskRegisterButtonAction:(id)sender;

- (IBAction) readTriggerParametersButtonAction:(id)sender;
- (IBAction) writeTriggerParametersButtonAction:(id)sender;
- (IBAction) dumpTriggerParametersButtonAction:(id)sender;

- (IBAction) readPostTriggerTimeAndIonToHeatDelayButtonAction:(id)sender;
- (IBAction) writePostTriggerTimeAndIonToHeatDelayButtonAction:(id)sender;

- (IBAction) triggerEnabledMatrixAction:(id)sender;
- (IBAction) enableAllTriggersAction: (id) sender;
- (IBAction) enableNoTriggersAction: (id) sender;

- (IBAction) negPosPolarityMatrixAction:(id)sender;
- (IBAction) gapMatrixAction:(id)sender;
- (IBAction) downSamplingMatrixAction:(id)sender;
- (IBAction) shapingLengthMatrixAction:(id)sender;

- (IBAction) heatWindowStartMatrixAction:(id)sender;
- (IBAction) heatWindowEndMatrixAction:(id)sender;

- (IBAction) selectFiberTrigPUAction:(id)sender;
- (IBAction) BBv1MaskMatrixAction:(id)sender;
- (IBAction) fiberEnableMaskMatrixAction:(id)sender;
- (IBAction) fltModeFlagsPUAction:(id)sender;

- (IBAction) writeCommandResyncAction:(id)sender;
- (IBAction) writeCommandTrigEvCounterResetAction:(id)sender;
- (IBAction) writeSWTriggerAction:(id)sender;
- (IBAction) readTriggerDataAction:(id)sender;

- (IBAction) targetRateAction:(id)sender;

- (IBAction) storeDataInRamAction:(id)sender;
- (IBAction) filterLengthAction:(id)sender;
- (IBAction) gapLengthAction:(id)sender;

- (IBAction) postTriggerTimeAction:(id)sender;
- (IBAction) fifoBehaviourAction:(id)sender;
- (IBAction) analogOffsetAction:(id)sender;
- (IBAction) interruptMaskAction:(id)sender;
- (IBAction) initBoardButtonAction:(id)sender;
- (IBAction) readAllButtonAction:(id)sender;
- (IBAction) reportButtonAction:(id)sender;
- (IBAction) gainAction:(id)sender;
- (IBAction) triggerEnableAction:(id)sender;

- (IBAction) thresholdAction:(id)sender;
- (IBAction) readThresholdsButtonAction:(id)sender;
- (IBAction) writeThresholdsButtonAction:(id)sender;

- (IBAction) settingLockAction:(id) sender;
- (IBAction) modeAction: (id) sender;
- (IBAction) versionAction: (id) sender;
- (IBAction) testAction: (id) sender;
- (IBAction) resetAction: (id) sender;
- (IBAction) hitRateEnableMatrixAction: (id) sender;
- (IBAction) hitRateLengthAction: (id) sender;
- (IBAction) hitRateLengthTextFieldAction: (id) sender;
- (IBAction) writeHitRateLengthButtonAction: (id) sender;
- (IBAction) hitRateAllAction: (id) sender;
- (IBAction) hitRateNoneAction: (id) sender;
- (IBAction) testEnabledAction:(id)sender;
- (IBAction) statusAction:(id)sender;
- (IBAction) readThresholdsGains:(id)sender;
- (IBAction) writeThresholdsGains:(id)sender;
- (IBAction) selectRegisterAction:(id) aSender;
- (IBAction) selectChannelAction:(id) aSender;
- (IBAction) writeValueAction:(id) aSender;
- (IBAction) readRegAction: (id) sender;
- (IBAction) writeRegAction: (id) sender;
- (IBAction) setDefaultsAction: (id) sender;
- (IBAction) openNoiseFloorPanel:(id)sender;
- (IBAction) closeNoiseFloorPanel:(id)sender;
- (IBAction) findNoiseFloors:(id)sender;
- (IBAction) noiseFloorOffsetAction:(id)sender;

- (IBAction) testButtonAction: (id) sender; //temp routine to hook up to any on a temp basis
	
#pragma mark ‚Ä¢‚Ä¢‚Ä¢Plot DataSource
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end