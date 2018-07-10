//-------------------------------------------------------------------------
//  ORSIS3316Controller.h
//  Orca
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2015 CENPA. University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolinaponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "OrcaObjectController.h"
#import "ORSIS3316Model.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORSIS3316Controller : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;
    IBOutlet NSTextField*   moduleIDField;
    IBOutlet NSTextField*   hwVersionField;
    IBOutlet NSTextField*   gammaRevisionField;
    IBOutlet NSTextField*   revisionField;
    IBOutlet NSTextField*   serialNumberField;
	
	//base address
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;
    IBOutlet NSPopUpButton* gainPU;
    IBOutlet NSPopUpButton* terminationPU;
    IBOutlet NSPopUpButton* sharingPU;
    
    IBOutlet NSMatrix*      enabledMatrix;
    IBOutlet NSMatrix*      enabled1Matrix;
    IBOutlet NSMatrix*      formatMatrix;
    IBOutlet NSMatrix*		heSuppressTrigModeMatrix;
    IBOutlet NSMatrix*		cfdControlMatrix;
    IBOutlet NSMatrix*		thresholdMatrix;
    IBOutlet NSMatrix*      endAddressMatrix;
    IBOutlet NSMatrix*      endAddressSuppressionMatrix;
    IBOutlet NSMatrix*      dacOffsetMatrix;

    IBOutlet NSMatrix*		energyDividerMatrix;
    IBOutlet NSMatrix*		energyOffsetMatrix;
    IBOutlet NSMatrix*		tauFactorMatrix;
    IBOutlet NSMatrix*		gapTimeMatrix;
    IBOutlet NSMatrix*		riseTimeMatrix;
    IBOutlet NSMatrix*      extraFilterMatrix;
    IBOutlet NSMatrix*      tauTableMatrix;
    IBOutlet NSMatrix*      triggerDelayMatrix;
    IBOutlet NSMatrix*      eventConfigMatrix;
    IBOutlet NSButton*      extendedEventConfigButton;
    
    IBOutlet NSMatrix*      enableSumMatrix;
    IBOutlet NSMatrix*      heTrigThresholdSumMatrix;
    IBOutlet NSMatrix*      thresholdSumMatrix;
    IBOutlet NSMatrix*      riseTimeSumMatrix;
    IBOutlet NSMatrix*      gapTimeSumMatrix;
    IBOutlet NSMatrix*      cfdControlBitsSumMatrix;
    
    IBOutlet NSMatrix*		heTrigThresholdMatrix;
    IBOutlet NSMatrix*		trigBothEdgesMatrix;
    IBOutlet NSMatrix*		intHeTrigOutPulseMatrix;
    IBOutlet NSMatrix*		intTrigOutPulseBitsMatrix;
    IBOutlet NSMatrix*      activeTrigGateWindowLenMatrix;
    IBOutlet NSMatrix*      preTriggerDelayMatrix;
    IBOutlet NSMatrix*      accGate1LenMatrix;
    IBOutlet NSMatrix*      accGate1StartMatrix;
    IBOutlet NSMatrix*      accGate2LenMatrix;
    IBOutlet NSMatrix*      accGate2StartMatrix;
    IBOutlet NSMatrix*      accGate3LenMatrix;
    IBOutlet NSMatrix*      accGate3StartMatrix;
    IBOutlet NSMatrix*      accGate4LenMatrix;
    IBOutlet NSMatrix*      accGate4StartMatrix;
    IBOutlet NSMatrix*      accGate5LenMatrix;
    IBOutlet NSMatrix*      accGate5StartMatrix;
    IBOutlet NSMatrix*      accGate6LenMatrix;
    IBOutlet NSMatrix*      accGate6StartMatrix;
    IBOutlet NSMatrix*      accGate7LenMatrix;
    IBOutlet NSMatrix*      accGate7StartMatrix;
    IBOutlet NSMatrix*      accGate8LenMatrix;
    IBOutlet NSMatrix*      accGate8StartMatrix;
    IBOutlet NSMatrix*      mawBufferLengthMatrix;
    IBOutlet NSMatrix*      mawPretrigDelayMatrix;

    
    IBOutlet NSMatrix*		histogramsEnabledMatrix;
    IBOutlet NSMatrix*		pileupEnabledMatrix;
    IBOutlet NSMatrix*		clrHistogramWithTSMatrix;
    IBOutlet NSMatrix*		writeHitsIntoEventMemoryMatrix;

    IBOutlet NSTextField*      rawDataBufferLenField;
    IBOutlet NSTextField*      rawDataBufferStartField;

	IBOutlet NSMatrix*		acquisitionControlMatrix;
    IBOutlet NSMatrix*      nimControlStatusMatrix;
	
    IBOutlet NSButton*      loadDefaultsButton;
    IBOutlet NSPopUpButton* clockSourcePU;
//    IBOutlet NSPopUpButton* hsDivPU;
//    IBOutlet NSTextField*   n1DivField;
    IBOutlet NSTextField*   sampleFreqField;
    IBOutlet NSTextField*   pileUpWindowLenField;
    IBOutlet NSTextField*   rePileUpWindowLenField;

    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      initButton;
    IBOutlet NSButton*      statusButton;

    //rate page
    IBOutlet NSMatrix*      rateTextFields;
    IBOutlet NSStepper*     integrationStepper;
    IBOutlet NSTextField*   integrationText;
    IBOutlet NSTextField*   totalRateText;

    IBOutlet NSMatrix*      lemoToMaskMatrix;
    IBOutlet NSMatrix*      lemoUoMaskMatrix;
    IBOutlet NSMatrix*      lemoCoMaskMatrix;

    
    IBOutlet ORValueBarGroupView*     rate0;
    IBOutlet ORValueBarGroupView*     totalRate;
    IBOutlet NSButton*		 		  rateLogCB;
    IBOutlet NSButton*				  totalRateLogCB;
    IBOutlet ORCompositeTimeLineView* timeRatePlot;
    IBOutlet NSButton*				  timeRateLogCB;
    IBOutlet NSTextField*             temperatureField;
    IBOutlet NSButton*                dumpThresholdsButton;
    IBOutlet NSButton*                dumpTriggerSetupButton;
    IBOutlet NSButton*                dumpAllRegsButton;
    NSView* blankView;
    NSSize  settingSize;
    NSSize  rateSize;
    
    IBOutlet NSMatrix* internalGateLengthMatrix;
    IBOutlet NSMatrix* internalCoinGateLengthMatrix;
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) setButtonStates;

#pragma mark •••Interface Management
- (void) enabledChanged:(NSNotification*)aNote;
- (void) formatChanged:(NSNotification*)aNote;
- (void) thresholdChanged:(NSNotification*)aNote;
- (void) endAddressChanged: (NSNotification*)aNote;
- (void) endAddressSuppressionChanged: (NSNotification*)aNote;
- (void) gainChanged:(NSNotification*)aNote;
- (void) terminationChanged:(NSNotification*)aNote;
- (void) energyDividerChanged:(NSNotification*)aNote;
- (void) energyOffsetChanged:(NSNotification*)aNote;
- (void) histogramsEnabledChanged:(NSNotification*)aNote;
- (void) pileupEnabledChanged:(NSNotification*)aNote;
- (void) clrHistogramWithTSChanged:(NSNotification*)aNote;
- (void) writeHitsIntoEventMemoryChanged:(NSNotification*)aNote;
- (void) acquisitionControlChanged: (NSNotification*)aNote;
- (void) nimControlStatusChanged: (NSNotification*)aNote;
- (void) triggerDelayChanged: (NSNotification*)aNote;
- (void) dacOffsetChanged:(NSNotification*)aNote;
- (void) sharingChanged:(NSNotification*)aNote;
- (void) lemoToMaskChanged:(NSNotification*)aNote;
- (void) lemoUoMaskChanged:(NSNotification*)aNote;
- (void) lemoCoMaskChanged:(NSNotification*)aNote;
//- (void) hsDivChanged:(NSNotification*)aNote;
//- (void) n1DivChanged:(NSNotification*)aNote;
- (void) pileUpWindowLenChanged:(NSNotification*)aNote;
- (void) rePileUpWindowLenChanged:(NSNotification*)aNote;

- (void) tauFactorChanged:(NSNotification*)aNote;
- (void) gapTimeChanged:(NSNotification*)aNote;
- (void) riseTimeChanged:(NSNotification*)aNote;
- (void) heTrigThresholdChanged:(NSNotification*)aNote;


- (void) enableSumChanged: (NSNotification*)aNote;
- (void) heTrigThresholdSumChanged: (NSNotification*)aNote;
- (void) thresholdSumChanged: (NSNotification*)aNote;
- (void) gapTimeSumChanged: (NSNotification*)aNote;
- (void) riseTimeSumChanged: (NSNotification*)aNote;
- (void) cfdControlBitsSumChanged: (NSNotification*)aNote;


- (void) trigBothEdgesChanged:(NSNotification*)aNote;
- (void) intHeTrigOutPulseChanged:(NSNotification*)aNote;
- (void) intTrigOutPulseBitsChanged:(NSNotification*)aNote;
- (void) activeTrigGateWindowLenChanged:(NSNotification*)aNote;
- (void) rawDataBufferLenChanged:(NSNotification*)aNote;
- (void) rawDataBufferStartChanged:(NSNotification*)aNote;

- (void) accGate1LenChanged:(NSNotification*)aNote;
- (void) accGate1StartChanged:(NSNotification*)aNote;
- (void) accGate2LenChanged:(NSNotification*)aNote;
- (void) accGate2StartChanged:(NSNotification*)aNote;
- (void) accGate3LenChanged:(NSNotification*)aNote;
- (void) accGate3StartChanged:(NSNotification*)aNote;
- (void) accGate4LenChanged:(NSNotification*)aNote;
- (void) accGate4StartChanged:(NSNotification*)aNote;
- (void) accGate5LenChanged:(NSNotification*)aNote;
- (void) accGate5StartChanged:(NSNotification*)aNote;
- (void) accGate6LenChanged:(NSNotification*)aNote;
- (void) accGate6StartChanged:(NSNotification*)aNote;
- (void) accGate7LenChanged:(NSNotification*)aNote;
- (void) accGate7StartChanged:(NSNotification*)aNote;
- (void) accGate8LenChanged:(NSNotification*)aNote;
- (void) accGate8StartChanged:(NSNotification*)aNote;

- (void) eventConfigChanged:(NSNotification*)aNote;
- (void) extendedEventConfigChanged:(NSNotification*)aNote;

- (void) clockSourceChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) registerRates;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) moduleIDChanged:(NSNotification*)aNote;
- (void) hwVersionChanged:(NSNotification*)aNote;

- (void) temperatureChanged:(NSNotification*)aNote;
- (void) serialNumberChanged:(NSNotification*)aNote;
- (void) internalGateLenChanged:(NSNotification*)aNote;
- (void) internalCoinGateLenChanged:(NSNotification*)aNote;
- (void) mawBufferLengthChanged:(NSNotification*)aNote;
- (void) mawPretrigDelayChanged:(NSNotification*)aNote;

- (void) scaleAction:(NSNotification*)aNote;
- (void) integrationChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;

#pragma mark •••Actions
- (IBAction) histogramsEnabledAction:(id)sender;
- (IBAction) pileupEnabledAction:(id)sender;
- (IBAction) clrHistogramsWithTSAction:(id)sender;
- (IBAction) writeHitsIntoEventMemoryAction:(id)sender;
- (IBAction) enabledAction:(id)sender;
- (IBAction) formatAction:(id)sender;
- (IBAction) heSuppressTrigModeAction:(id)sender;
- (IBAction) cfdControlAction:(id)sender;
- (IBAction) eventConfigAction:(id)sender;
- (IBAction) extendedEventConfigAction:(id)sender;
- (IBAction) endAddressSuppressionAction:(id)sender;

- (IBAction) enableSumAction:(id)sender;
- (IBAction) thresholdAction:(id)sender;
- (IBAction) thresholdSumAction:(id)sender;
- (IBAction) endAddressAction:(id)sender;

- (IBAction) triggerDelayAction:(id)sender;

- (IBAction) energyDividerAction:(id)sender;
- (IBAction) energyOffsetAction:(id)sender;
- (IBAction) tauFactorAction:(id)sender;
- (IBAction) gapTimeAction:(id)sender;
- (IBAction) riseTimeAction:(id)sender;
- (IBAction) extraFilterAction:(id)sender;
- (IBAction) tauTableAction:(id)sender;
- (IBAction) heTrigThresholdAction:(id)sender;
- (IBAction) heTrigThresholdSumAction:(id)sender;
- (IBAction) trigBothEdgesAction:(id)sender;
- (IBAction) intHeTrigOutPulseAction:(id)sender;
- (IBAction) intTrigOutPulseBitsAction:(id)sender;
- (IBAction) activeTrigGateWindowLenActive:(id)sender;
- (IBAction) preTriggerDelayAction:(id)sender;
- (IBAction) rawDataBufferLenAction:(id)sender;
- (IBAction) rawDataBufferStartAction:(id)sender;
- (IBAction) accGate1LenAction:(id)sender;
- (IBAction) accGate1StartAction:(id)sender;
- (IBAction) accGate2LenAction:(id)sender;
- (IBAction) accGate2StartAction:(id)sender;
- (IBAction) accGate3LenAction:(id)sender;
- (IBAction) accGate3StartAction:(id)sender;
- (IBAction) accGate4LenAction:(id)sender;
- (IBAction) accGate4StartAction:(id)sender;
- (IBAction) accGate5LenAction:(id)sender;
- (IBAction) accGate5StartAction:(id)sender;
- (IBAction) accGate6LenAction:(id)sender;
- (IBAction) accGate6StartAction:(id)sender;
- (IBAction) accGate7LenAction:(id)sender;
- (IBAction) accGate7StartAction:(id)sender;
- (IBAction) accGate8LenAction:(id)sender;
- (IBAction) accGate8StartAction:(id)sender;
- (IBAction) acquisitionControlAction:(id)sender;
- (IBAction) nimControlStatusAction:(id)sender;
- (IBAction) writeAccumulatorGateAction:(id)sender;
- (IBAction) readAccumulatorGateAction:(id)sender;
- (IBAction) trigger:(id)sender;

- (IBAction) dumpThresholdsAction:(id)sender;

- (IBAction) clockSourceAction:(id)sender;
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) initBoard:(id)sender;
- (IBAction) integrationAction:(id)sender;
- (IBAction) probeBoardAction:(id)sender;
- (IBAction) gainAction:(id)sender;
- (IBAction) terminationAction:(id)sender;
- (IBAction) dacOffsetAction:(id)sender;
- (IBAction) sharingAction:(id)sender;
- (IBAction) lemoToMaskAction:(id)sender;
- (IBAction) lemoUoMaskAction:(id)sender;
- (IBAction) lemoCoMaskAction:(id)sender;
- (IBAction) loadDefaults:(id)sender;
- (IBAction) internalGateLenAction:(id)sender;
- (IBAction) internalCoinGateLenAction:(id)sender;
//- (IBAction) hsDivAction:(id)sender;
//- (IBAction) n1DivAction:(id)sender;
- (IBAction) pileUpWindowLenAction:(id)sender;
- (IBAction) rePileUpWindowLenAction:(id)sender;
- (IBAction) dumpChan0Action:(id)sender;
- (IBAction) dumpFirTriggerAction:(id)sender;
- (IBAction) mawBufferLengthAction:(id)sender;
- (IBAction) mawPretrigDelayAction:(id)sender;

#pragma mark •••Data Source
- (double)  getBarValue:(int)tag;
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
