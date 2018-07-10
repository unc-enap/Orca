//-------------------------------------------------------------------------
//  ORSIS3305Controller.h
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

//-------------------------------------------------------------------------

#pragma mark - Imported Files
#import "OrcaObjectController.h"
#import "ORSIS3305Model.h"
@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORSIS3305Controller : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
	IBOutlet NSButton*		pulseModeButton;
	IBOutlet NSTextField*	firmwareVersionTextField;
    IBOutlet NSTextField*   temperatureTextField;
	IBOutlet NSMatrix*		bufferWrapEnabledMatrix;
	IBOutlet NSButton*		shipTimeRecordAlsoCB;
    
    IBOutlet NSButton* 		TDCLogicEnabledCB;
	
    
    IBOutlet NSMatrix*		channelEnabled14Matrix;
    IBOutlet NSMatrix*		channelEnabled58Matrix;
    IBOutlet NSMatrix*      ledEnabledMatrix;
    IBOutlet NSMatrix*      ledApplicationModeMatrix;
    
    IBOutlet NSMatrix*      GTThresholdOn14Matrix;
    IBOutlet NSMatrix*      GTThresholdOn58Matrix;
    IBOutlet NSMatrix*      GTThresholdOff14Matrix;
    IBOutlet NSMatrix*      GTThresholdOff58Matrix;
    IBOutlet NSMatrix*      LTThresholdOn14Matrix;
    IBOutlet NSMatrix*      LTThresholdOn58Matrix;
    IBOutlet NSMatrix*      LTThresholdOff14Matrix;
    IBOutlet NSMatrix*      LTThresholdOff58Matrix;
    
	IBOutlet NSMatrix*		internalTriggerEnabledMatrix;
	IBOutlet NSMatrix*		externalTriggerEnabledMatrix;
	IBOutlet NSMatrix*		internalGateEnabledMatrix;
	IBOutlet NSMatrix*		externalGateEnabledMatrix;
	IBOutlet NSMatrix*		triggerGateLengthMatrix;
    IBOutlet NSMatrix*		preTriggerDelay14Matrix;
    IBOutlet NSMatrix*		preTriggerDelay58Matrix;
	IBOutlet NSMatrix*		sampleStartIndexMatrix;
    IBOutlet NSMatrix*      gain14Matrix;
    IBOutlet NSMatrix*      gain58Matrix;
    IBOutlet NSMatrix*      phase14Matrix;
    IBOutlet NSMatrix*      phase58Matrix;
    IBOutlet NSMatrix*      offset14Matrix;
    IBOutlet NSMatrix*      offset58Matrix;
	IBOutlet NSPopUpButton* runModePU;

	IBOutlet NSTextField*	energyBufferAssignmentField;
	IBOutlet NSTextField*	runSummaryField;

    IBOutlet NSButton* controlLemoTriggerOutButton;
    
    IBOutlet NSMatrix* lemoOutSelectTrigger14Matrix;
    IBOutlet NSMatrix* lemoOutSelectTrigger58Matrix;
    IBOutlet NSButton* lemoOutSelectTriggerInButton;
    IBOutlet NSButton* lemoOutSelectTriggerInPulseButton;
    IBOutlet NSButton* lemoOutSelectTriggerInPulseWithSampleAndTDCButton;
    IBOutlet NSButton* lemoOutSelectSampleLogicArmedButton;
    IBOutlet NSButton* lemoOutSelectSampleLogicEnabledButton;
    IBOutlet NSButton* lemoOutSelectKeyOutputPulseButton;
    IBOutlet NSButton* lemoOutSelectControlLemoTriggerOutButton;
    IBOutlet NSButton* lemoOutSelectExternalVetoButton;
    IBOutlet NSButton* lemoOutSelectInternalKeyVetoButton;
    IBOutlet NSButton* lemoOutSelectExternalVetoLengthButton;
    IBOutlet NSButton* lemoOutSelectMemoryOverrunVetoButton;
    
    IBOutlet NSButton* enableLemoInputTriggerButton;
    IBOutlet NSButton* enableLemoInputCountButton;
    IBOutlet NSButton* enableLemoInputResetButton;
    IBOutlet NSButton* enableLemoInputDirectVetoButton;
    
	//base address
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;
    IBOutlet NSPopUpButton* clockSourcePU;
    IBOutlet NSButton*      writeGainPhaseOffsetEnableCB;
    
    IBOutlet NSMatrix*      thresholdMode14PUMatrix;
    IBOutlet NSMatrix*      thresholdMode58PUMatrix;

	IBOutlet NSMatrix*		inputInvertedMatrix;
	IBOutlet NSMatrix*		triggerOutEnabledMatrix;
	IBOutlet NSMatrix*		gtMatrix;
	IBOutlet NSMatrix*		dacOffsetMatrix;
//	IBOutlet NSMatrix*		thresholdMatrix;
//	IBOutlet NSMatrix*		highThresholdMatrix;
	IBOutlet NSMatrix*		gateLengthMatrix;
	IBOutlet NSMatrix*		pulseLengthMatrix;
	IBOutlet NSMatrix*		internalTriggerDelayMatrix;
	IBOutlet NSMatrix*		sampleLengthMatrix;

	IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      initButton;
    IBOutlet NSButton*      briefReportButton;
    IBOutlet NSButton*      regDumpButton;
    IBOutlet NSButton*      probeButton;
    IBOutlet NSButton*      forceTriggerButton;

    
// low level page
    // key address buttons
    IBOutlet NSButton*      generalResetButton;
    IBOutlet NSButton*      armSampleLogicButton;
    IBOutlet NSButton*      disarmSampleLogicButton;
    IBOutlet NSButton*      triggerButton;
    IBOutlet NSButton*      enableSampleLogicButton;
    IBOutlet NSButton*      setVetoButton;
    IBOutlet NSButton*      clearVetoButton;
    IBOutlet NSButton*      ADCClockSynchButton;
    IBOutlet NSButton*      ResetADCFPGALogicButton;
    IBOutlet NSButton*      externalTriggerOutPulseButton;

    // register access
    IBOutlet NSPopUpButton*	registerIndexPU;
    IBOutlet NSTextField*	registerWriteValueField;
    IBOutlet NSButton*		writeRegisterButton;
    IBOutlet NSButton*		readRegisterButton;
    IBOutlet NSTextField*	registerStatusField;

    
    
    // event config things
    IBOutlet NSPopUpButton* eventSavingMode14PU;
    IBOutlet NSPopUpButton* eventSavingMode58PU;
    IBOutlet NSButton*      ADCGateModeEnabled14Button;
    IBOutlet NSButton*      ADCGateModeEnabled58Button;
    IBOutlet NSButton*      globalTriggerEnable14Button;
    IBOutlet NSButton*      globalTriggerEnable58Button;
    IBOutlet NSButton*      internalTriggerEnabled14Button;
    IBOutlet NSButton*      internalTriggerEnabled58Button;
    IBOutlet NSButton*      startEventSamplingWithExtTrigEnabled14Button;
    IBOutlet NSButton*      startEventSamplingWithExtTrigEnabled58Button;
    IBOutlet NSButton*      clearTimestampWhenSamplingEnabledEnabled14Button;
    IBOutlet NSButton*      clearTimestampWhenSamplingEnabledEnabled58Button;
    IBOutlet NSButton*      clearTimestampDisabled14Button;
    IBOutlet NSButton*      clearTimestampDisabled58Button;
    IBOutlet NSButton*      grayCodeEnable14Button;
    IBOutlet NSButton*      grayCodeEnable58Button;
    IBOutlet NSButton*      disableDirectMemoryHeader14Button;
    IBOutlet NSButton*      disableDirectMemoryHeader58Button;
    IBOutlet NSButton*      waitPreTrigTimeBeforeDirectMemTrig14Button;
    IBOutlet NSButton*      waitPreTrigTimeBeforeDirectMemTrig58Button;
    
    
    // ADC SPI Settings
    IBOutlet NSPopUpButton* channelMode14PU;
    IBOutlet NSPopUpButton* channelMode58PU;
    IBOutlet NSPopUpButton* bandwidth14PU;
    IBOutlet NSPopUpButton* bandwidth58PU;
    IBOutlet NSPopUpButton* testMode14PU;
    IBOutlet NSPopUpButton* testMode58PU;

	
    //rate page
    IBOutlet NSMatrix*      rateTextFields;
    IBOutlet NSStepper*     integrationStepper;
    IBOutlet NSTextField*   integrationText;
    IBOutlet NSTextField*   totalRateText;

    IBOutlet ORValueBarGroupView*       rate0;
    IBOutlet ORValueBarGroupView*       totalRate;
    IBOutlet NSButton*				    rateLogCB;
    IBOutlet NSButton*				    totalRateLogCB;
    IBOutlet ORCompositeTimeLineView*   timeRatePlot;
    IBOutlet NSButton*					timeRateLogCB;
		
    NSView *blankView;
    NSSize basicSize;
    NSSize settingSize;
    NSSize rateSize;
    NSSize miscSize;
    
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark - Interface Management
- (void) pulseModeChanged:(NSNotification*)aNote;
//- (void) tapDelayChanged:(NSNotification*)aNote;
- (void) firmwareVersionChanged:(NSNotification*)aNote;
- (void) bufferWrapEnabledChanged:(NSNotification*)aNote;
//- (void) cfdControlChanged:(NSNotification*)aNote;
- (void) shipTimeRecordAlsoChanged:(NSNotification*)aNote;
- (void) TDCLogicEnabledChanged:(NSNotification*)aNote;

- (void) channelEnabledChanged:(NSNotification*)aNote;
//- (void) ledEnabledChanged:(NSNotification*)aNote;
//- (void) ledApplicationModeChanged:(NSNotification*)aNote;
- (void) writeGainPhaseOffsetEnableChanged:(NSNotification*)aNote;



//event config changed updaters
- (void) eventSavingModeChanged:(NSNotification*)aNote;
- (void) ADCGateModeEnabledChanged:(NSNotification*)aNote;
- (void) globalTriggerEnabledChanged:(NSNotification*)aNote;
- (void) internalTriggerEnabledChanged:(NSNotification*)aNote;
- (void) externalTriggerEnabledChanged:(NSNotification*)aNote;
- (void) startEventSamplingWithExtTrigEnabledChanged:(NSNotification*)aNote;
- (void) clearTimestampWhenSamplingEnabledEnabledChanged:(NSNotification*)aNote;
- (void) clearTimestampDisabledChanged:(NSNotification*)aNote;
- (void) grayCodeEnabledChanged:(NSNotification*)aNote;
- (void) disableDirectMemoryHeaderChanged:(NSNotification*)aNote;
- (void) waitPreTrigTimeBeforeDirectMemTrigChanged:(NSNotification*)aNote;



- (void) channelModeChanged:(NSNotification*)aNote;
- (void) bandwidthChanged:(NSNotification*)aNote;
- (void) testModeChanged:(NSNotification*)aNote;

- (void) adcOffsetChanged:(NSNotification*)aNote;
- (void) adcGainChanged:(NSNotification*)aNote;
- (void) adcPhaseChanged:(NSNotification*)aNote;



//- (void) internalExternalTriggersOredChanged:(NSNotification*)aNote;
- (void) internalTriggerEnabledChanged:(NSNotification*)aNote;
- (void) externalTriggerEnabledChanged:(NSNotification*)aNote;
- (void) internalGateEnabledChanged:(NSNotification*)aNote;
- (void) externalGateEnabledChanged:(NSNotification*)aNote;
- (void) lemoInEnabledMaskChanged:(NSNotification*)aNote;
- (void) runModeChanged:(NSNotification*)aNote;


- (void) triggerGateLengthChanged:(NSNotification*)aNote;
- (void) preTriggerDelayChanged:(NSNotification*)aNote;
- (void) sampleStartIndexChanged:(NSNotification*)aNote;
- (void) sampleLengthChanged:(NSNotification*)aNote;
- (void) dacOffsetChanged:(NSNotification*)aNote;
//- (void) lemoInModeChanged:(NSNotification*)aNote;
//- (void) lemoOutModeChanged:(NSNotification*)aNote;


- (void) lemoOutSelectTriggerChanged:(NSNotification*)aNote;
- (void) lemoOutSelectTriggerInChanged:(NSNotification*)aNote;
- (void) lemoOutSelectTriggerInPulseChanged:(NSNotification*)aNote;
- (void) lemoOutSelectTriggerInPulseWithSampleAndTDCChanged:(NSNotification*)aNote;
- (void) lemoOutSelectSampleLogicArmedChanged:(NSNotification*)aNote;
- (void) lemoOutSelectSampleLogicEnabledChanged:(NSNotification*)aNote;
- (void) lemoOutSelectKeyOutputPulseChanged:(NSNotification*)aNote;
- (void) lemoOutSelectControlLemoTriggerOutChanged:(NSNotification*)aNote;
- (void) lemoOutSelectExternalVetoChanged:(NSNotification*)aNote;
- (void) lemoOutSelectInternalKeyVetoChanged:(NSNotification*)aNote;
- (void) lemoOutSelectExternalVetoLengthChanged:(NSNotification*)aNote;
- (void) lemoOutSelectMemoryOverrunVetoChanged:(NSNotification*)aNote;

- (void) enableLemoInputTriggerChanged:(NSNotification*)aNote;
- (void) enableLemoInputCountChanged:(NSNotification*)aNote;
- (void) enableLemoInputResetChanged:(NSNotification*)aNote;
- (void) enableLemoInputDirectVetoChanged:(NSNotification*)aNote;



- (void) clockSourceChanged:(NSNotification*)aNote;

- (void) thresholdModeChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) registerRates;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) triggerOutEnabledChanged:(NSNotification*)aNote;
- (void) inputInvertedChanged:(NSNotification*)aNote;

- (void) gateLengthChanged:(NSNotification*)aNote;
- (void) pulseLengthChanged:(NSNotification*)aNote;
- (void) internalTriggerDelayChanged:(NSNotification*)aNote;

- (void) ORSIS3305LEDEnabledChanged:(NSNotification*)aNote;

- (void) scaleAction:(NSNotification*)aNote;
- (void) integrationChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;

#pragma mark - Actions
- (IBAction) pulseModeAction:(id)sender;
- (IBAction) bufferWrapEnabledAction:(id)sender;
- (IBAction) shipTimeRecordAlsoAction:(id)sender;
- (IBAction) TDCLogicEnabledAction:(id)sender;
//- (IBAction) tapDelayAction:(id)sender;

- (IBAction) writeGainPhaseOffsetEnableAction:(id)sender;
- (IBAction) channelEnabledMaskAction:(id)sender;

- (IBAction) internalExternalTriggersOredAction:(id)sender;
//- (IBAction) internalTriggerEnabledMaskAction:(id)sender;
//- (IBAction) externalTriggerEnabledMaskAction:(id)sender;
- (IBAction) internalGateEnabledMaskAction:(id)sender;
- (IBAction) externalGateEnabledMaskAction:(id)sender;
- (IBAction) lemoInEnabledMaskAction:(id)sender;
- (IBAction) lemoInEnabledMaskAction:(id)sender;
- (IBAction) runModeAction:(id)sender;

//- (IBAction) triggerGateLengthAction:(id)sender;
- (IBAction) preTriggerDelay14Action:(id)sender;
- (IBAction) preTriggerDelay58Action:(id)sender;
- (IBAction) sampleStartIndexAction:(id)sender;
- (IBAction) sampleLengthAction:(id)sender;
- (IBAction) dacOffsetAction:(id)sender;
- (IBAction) lemoInModeAction:(id)sender;
- (IBAction) lemoOutModeAction:(id)sender;

- (IBAction) controlLemoTriggerOutAction:(id)sender;
- (IBAction) lemoOutSelectTrigger14Action:(id)sender;
- (IBAction) lemoOutSelectTrigger58Action:(id)sender;
- (IBAction) lemoOutSelectTriggerInAction:(id)sender;
- (IBAction) lemoOutSelectTriggerInPulseAction:(id)sender;
- (IBAction) lemoOutSelectTriggerInPulseWithSampleAndTDCAction:(id)sender;
- (IBAction) lemoOutSelectSampleLogicArmedAction:(id)sender;
- (IBAction) lemoOutSelectSampleLogicEnabledAction:(id)sender;
- (IBAction) lemoOutSelectKeyOutputPulseAction:(id)sender;
- (IBAction) lemoOutSelectControlLemoTriggerOutAction:(id)sender;
- (IBAction) lemoOutSelectExternalVetoAction:(id)sender;
- (IBAction) lemoOutSelectInternalKeyVetoAction:(id)sender;
- (IBAction) lemoOutSelectExternalVetoLengthAction:(id)sender;
- (IBAction) lemoOutSelectMemoryOverrunVetoAction:(id)sender;
- (IBAction) enableLemoInputTriggerAction:(id)sender;
- (IBAction) enableLemoInputCountAction:(id)sender;
- (IBAction) enableLemoInputResetAction:(id)sender;
- (IBAction) enableLemoInputDirectVetoAction:(id)sender;








- (IBAction) clockSourceAction:(id)sender;


//event config actions
- (IBAction) eventSavingMode14Action:(id)sender;
- (IBAction) eventSavingMode58Action:(id)sender;
- (IBAction) ADCGateModeEnabled14Action:(id)sender;
- (IBAction) ADCGateModeEnabled58Action:(id)sender;
- (IBAction) globalTriggerEnabled14Action:(id)sender;
- (IBAction) globalTriggerEnabled58Action:(id)sender;
- (IBAction) internalTriggerEnabled14Action:(id)sender;
- (IBAction) internalTriggerEnabled58Action:(id)sender;
- (IBAction) externalTriggerEnabled14Action:(id)sender;
- (IBAction) externalTriggerEnabled58Action:(id)sender;
- (IBAction) startEventSamplingWithExtTrigEnabled14Action:(id)sender;
- (IBAction) startEventSamplingWithExtTrigEnabled58Action:(id)sender;
- (IBAction) clearTimestampWhenSamplingEnabledEnabled14Action:(id)sender;
- (IBAction) clearTimestampWhenSamplingEnabledEnabled58Action:(id)sender;
- (IBAction) clearTimestampDisabled14Changed:(id)sender;    // FIX: These methods names should end in "ACTION"....
- (IBAction) clearTimestampDisabled58Changed:(id)sender;
- (IBAction) disableDirectMemoryHeader14Changed:(id)sender;
- (IBAction) disableDirectMemoryHeader58Changed:(id)sender;
- (IBAction) waitPreTrigTimeBeforeDirectMemTrig14Changed:(id)sender;
- (IBAction) waitPreTrigTimeBeforeDirectMemTrig58Changed:(id)sender;


- (IBAction) channelMode14Action:(id)sender;
- (IBAction) channelMode58Action:(id)sender;
- (IBAction) bandwidth14Action:(id)sender;
- (IBAction) bandwidth58Action:(id)sender;
- (IBAction) testMode14Action:(id)sender;
- (IBAction) testMode58Action:(id)sender;
- (IBAction) adcGain14Action:(id)sender;
- (IBAction) adcGain58Action:(id)sender;
- (IBAction) adcOffset14Action:(id)sender;
- (IBAction) adcOffset58Action:(id)sender;
- (IBAction) adcPhase14Action:(id)sender;
- (IBAction) adcPhase58Action:(id)sender;


//- (IBAction) thresholdModeAction:(id)sender;
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) integrationAction:(id)sender;
- (IBAction) probeBoardAction:(id)sender;

- (IBAction) inputInvertedAction:(id)sender;
- (IBAction) triggerOutEnabledAction:(id)sender;
//- (IBAction) gtAction:(id)sender;
//- (IBAction) thresholdAction:(id)sender;

- (IBAction) GTThresholdOn14Action:(id)sender;
- (IBAction) GTThresholdOn58Action:(id)sender;
- (IBAction) GTThresholdOff14Action:(id)sender;
- (IBAction) GTThresholdOff58Action:(id)sender;
- (IBAction) LTThresholdOn14Action:(id)sender;
- (IBAction) LTThresholdOn58Action:(id)sender;
- (IBAction) LTThresholdOff14Action:(id)sender;
- (IBAction) LTThresholdOff58Action:(id)sender;


- (IBAction) gateLengthAction:(id)sender;
- (IBAction) pulseLengthAction:(id)sender;
- (IBAction) internalTriggerDelayAction:(id)sender;
- (IBAction) briefReport:(id)sender;
- (IBAction) regDump:(id)sender;
- (IBAction) forceTriggerAction:(id)sender;

// key actions
- (IBAction) generalResetAction:(id)sender;
- (IBAction) armSampleLogicAction:(id)sender;
- (IBAction) disarmSampleLogicAction:(id)sender;
- (IBAction) triggerAction:(id)sender;
- (IBAction) enableSampleLogicAction:(id)sender;
- (IBAction) setVetoAction:(id)sender;
- (IBAction) clearVetoAction:(id)sender;
- (IBAction) ADCClockSynchAction:(id)sender;
- (IBAction) resetADCFPGALogicAction:(id)sender;
- (IBAction) externalTriggerOutPulseAction:(id)sender;




#pragma mark - Data Source
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (double)  getBarValue:(int)tag;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
