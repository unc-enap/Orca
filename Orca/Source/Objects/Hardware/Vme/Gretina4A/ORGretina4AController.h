//-------------------------------------------------------------------------
//  ORGretina4AController.h
//
//  Created by Mark A. Howe on Wednesday 11/20/14.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//Washington sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files
#import "OrcaObjectController.h"
#import "ORGretina4AModel.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;
@class ORGretinaCntView;

@interface ORGretina4AController : OrcaObjectController 
{
    IBOutlet   NSTabView* 	tabView;
    
    //security
    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      registerLockButton;
    IBOutlet NSTextField*   lockStateField;
    
    //Low-level registers and diagnostics
    IBOutlet NSPopUpButton*	registerIndexPU;
    IBOutlet NSTextField*	selectedChannelField;
    IBOutlet NSTextField*	registerWriteValueField;
    IBOutlet NSTextField*	channelSelectionField;
    IBOutlet NSButton*		writeRegisterButton;
    IBOutlet NSButton*		readRegisterButton;
    IBOutlet NSTextField*	registerStatusField;
    IBOutlet NSTextField*	spiWriteValueField;
    IBOutlet NSButton*		writeSPIButton;
    IBOutlet NSButton*		diagnosticsEnabledCB;
    IBOutlet NSButton*		diagnosticsReportButton;
    IBOutlet NSButton*		diagnosticsClearButton;
    IBOutlet NSButton*		dumpAllRegistersButton;
    IBOutlet NSButton*		snapShotRegistersButton;
    IBOutlet NSButton*		compareRegistersButton;
    IBOutlet NSButton*      doHwCheckButton;

	//Firmware loading
	IBOutlet NSTextField*			fpgaFilePathField;
	IBOutlet NSButton*				loadMainFPGAButton;
	IBOutlet NSButton*				stopFPGALoadButton;
    IBOutlet NSProgressIndicator*	loadFPGAProgress;
	IBOutlet NSTextField*			mainFPGADownLoadStateField;
    IBOutlet NSTextField*           firmwareStatusStringField;

    //rates
    IBOutlet NSMatrix*                  rateTextFields;
    IBOutlet NSStepper*                 integrationStepper;
    IBOutlet NSTextField*               integrationText;
    IBOutlet NSTextField*               totalRateText;
    IBOutlet NSMatrix*                  enabled2Matrix;
    IBOutlet NSButton*                  rateLogCB;
    IBOutlet NSButton*                  totalRateLogCB;
    IBOutlet NSButton*                  timeRateLogCB;
    IBOutlet ORCompositeTimeLineView*   timeRatePlot;
    IBOutlet ORValueBarGroupView*       rate0;
    IBOutlet ORValueBarGroupView*       totalRate;

    //counters
    IBOutlet NSMatrix*                  aHitCountMatrix;
    IBOutlet NSMatrix*                  acceptedEventCountMatrix;
    IBOutlet NSMatrix*                  droppedEventCountMatrix;
    IBOutlet NSMatrix*                  discriminatorCountMatrix;

    
    //SerDes and Clock Distribution
    IBOutlet NSTextField*	initSerDesStateField;
    
    //hardware access
    IBOutlet NSButton*      initButton;
    IBOutlet NSButton*      fullInitButton;
    IBOutlet NSButton*      initButton1;
    IBOutlet NSButton*      resetButton;
    IBOutlet NSButton*      clearFIFOButton;
    IBOutlet NSButton*      probeButton;
    IBOutlet NSButton*      statusButton;

    //hardware setup
    IBOutlet NSButton*		forceFullCardInitCB;
    IBOutlet NSMatrix*		forceFullInitMatrix;

    IBOutlet NSMatrix*      extDiscrSrcMatrix;
    IBOutlet NSMatrix*      extDiscrModeMatrix;
    IBOutlet NSTextField*   userPackageDataField;
    IBOutlet NSTextField*   windowCompMinField;
    IBOutlet NSTextField*   windowCompMaxField;
   
    IBOutlet NSMatrix*      pileupWaveformOnlyModeMatrix;
    IBOutlet NSMatrix*      pileupExtensionModeMatrix;
    IBOutlet NSMatrix*      discCountModeMatrix;
    IBOutlet NSMatrix*      aHitCountModeMatrix;
    IBOutlet NSMatrix*      eventCountModeMatrix;
    IBOutlet NSMatrix*      droppedEventCountModeMatrix;

    IBOutlet NSMatrix*      decimationFactorMatrix;
    IBOutlet NSMatrix*      triggerPolarityMatrix;
    IBOutlet NSMatrix*      pileupModeMatrix;
    IBOutlet NSMatrix*		enabledMatrix;

    IBOutlet NSMatrix*      ledThresholdMatrix;
    IBOutlet NSMatrix*      p1WindowMatrix;
    IBOutlet NSMatrix*      dWindowMatrix;
    IBOutlet NSMatrix*      kWindowMatrix;
    IBOutlet NSMatrix*      mWindowMatrix;
    IBOutlet NSMatrix*      d3WindowMatrix;
    IBOutlet NSTextField*   p2WindowField;
    IBOutlet NSMatrix*      discWidthMatrix;

    IBOutlet NSTextField*   downSampleHoldOffTimeField;
    IBOutlet NSButton*      downSamplePauseEnableCB;
    IBOutlet NSTextField*   holdOffTimeField;
    IBOutlet NSButton*		autoModeCB;
    IBOutlet NSTextField*   vetoGateWidthField;

    IBOutlet NSTextField*   rawDataLengthField; //bad name in docs. really raw_data_offset
    IBOutlet NSTextField*   rawDataWindowField; //bad name in docs. really max length of event packet
    IBOutlet NSMatrix*      baselineStartMatrix;
    IBOutlet NSTextField*   baselineDelayField;
    IBOutlet NSTextField*   trackingSpeedField;
    IBOutlet NSTextField*   peakSensitivityField;
    IBOutlet NSPopUpButton* triggerConfigPU;
    IBOutlet NSPopUpButton* clockSourcePU;
    IBOutlet NSTextField*   clockLockedField;

    NSView *blankView;
    NSSize settingSize;
    NSSize rateSize;
    NSSize registerTabSize;
	NSSize firmwareTabSize;
}

- (id)   init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark - Notification Registration
- (void) registerNotificationObservers;
- (void) registerRates;
- (void) updateWindow;

#pragma mark - Boilerplate
- (void) slotChanged:(NSNotification*)aNote;

#pragma mark - Security
- (void) checkGlobalSecurity;
- (void) lockChanged:(NSNotification*) aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) registerLockChanged:(NSNotification*)aNote;

#pragma mark - Low-level registers and diagnostics
- (void) selectedChannelChanged:(NSNotification*)aNote;
- (void) registerIndexChanged:(NSNotification*)aNote;
- (void) setRegisterDisplay:(unsigned int)index;
- (void) registerWriteValueChanged:(NSNotification*)aNote;
- (void) spiWriteValueChanged:(NSNotification*)aNote;
- (void) diagnosticsEnabledChanged:(NSNotification*)aNote;

#pragma mark - firmware loading
- (void) fpgaDownInProgressChanged:(NSNotification*)aNote;
- (void) fpgaDownProgressChanged:(NSNotification*)aNote;
- (void) mainFPGADownLoadStateChanged:(NSNotification*)aNote;
- (void) fpgaFilePathChanged:(NSNotification*)aNote;
- (void) firmwareStatusStringChanged:(NSNotification*)aNote;

#pragma mark - rates
- (void) scaleAction:(NSNotification*)aNote;
- (void) integrationChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;

#pragma mark - SerDes and Clock Distribution
- (void) updateClockLocked;
- (void) initSerDesStateChanged:(NSNotification*) aNote;

#pragma mark - Card Params
- (void) enabledChanged:(NSNotification*)aNote;
- (void) forceFullCardInitChanged:(NSNotification*)aNote;
- (void) forceFullInitChanged:(NSNotification*)aNote;
- (void) extDiscrSrcChanged:(NSNotification*)aNote;
- (void) extDiscrModeChanged:(NSNotification*)aNote;
- (void) userPackageDataChanged:(NSNotification*)aNote;
- (void) downSampleHoldOffTimeChanged:(NSNotification*)aNote;
- (void) holdOffTimeChanged:(NSNotification*)aNote;
- (void) autoModeChanged:(NSNotification*)aNote;
- (void) vetoGateWidthChanged:(NSNotification*)aNote;
- (void) clockSourceChanged:(NSNotification*)aNote;


- (void) acqDcmCtrlStatusChanged:(NSNotification*)aNote;
- (void) acqDcmLockChanged:(NSNotification*)aNote;
- (void) acqDcmResetChanged:(NSNotification*)aNote;
- (void) acqPhShiftOverflowChanged:(NSNotification*)aNote;
- (void) acqDcmClockStoppedChanged:(NSNotification*)aNote;
- (void) adcDcmCtrlStatusChanged:(NSNotification*)aNote;
- (void) adcDcmLockChanged:(NSNotification*)aNote;
- (void) adcDcmResetChanged:(NSNotification*)aNote;
- (void) adcPhShiftOverflowChanged:(NSNotification*)aNote;
- (void) adcDcmClockStoppedChanged:(NSNotification*)aNote;
- (void) decimationFactorChanged:(NSNotification*)aNote;
- (void) pileupModeChanged:(NSNotification*)aNote;
- (void) droppedEventCountModeChanged:(NSNotification*)aNote;
- (void) eventCountModeChanged:(NSNotification*)aNote;
- (void) ledThresholdChanged:(NSNotification*)aNote;
- (void) triggerPolarityChanged:(NSNotification*)aNote;
- (void) aHitCountModeChanged:(NSNotification*)aNote;
- (void) discCountModeChanged:(NSNotification*)aNote;
- (void) pileupExtensionModeChanged:(NSNotification*)aNote;
- (void) pileupWaveformOnlyModeChanged:(NSNotification*)aNote;
- (void) triggerConfigChanged:(NSNotification*)aNote;
- (void) rawDataLengthChanged:(NSNotification*)aNote;
- (void) rawDataWindowChanged:(NSNotification*)aNote;
- (void) dWindowChanged:(NSNotification*)aNote;
- (void) kWindowChanged:(NSNotification*)aNote;
- (void) mWindowChanged:(NSNotification*)aNote;
- (void) d3WindowChanged:(NSNotification*)aNote;
- (void) baselineStartChanged:(NSNotification*)aNote;
- (void) baselineDelayChanged:(NSNotification*)aNote;
- (void) trackingSpeedChanged:(NSNotification*)aNote;
- (void) windowCompMinChanged:(NSNotification*)aNote;
- (void) windowCompMaxChanged:(NSNotification*)aNote;
- (void) p1WindowChanged:(NSNotification*)aNote;
- (void) p2WindowChanged:(NSNotification*)aNote;
- (void) dacChannelSelectChanged:(NSNotification*)aNote;
- (void) dacAttenuationChanged:(NSNotification*)aNote;
- (void) peakSensitivityChanged:(NSNotification*)aNote;
- (void) diagInputChanged:(NSNotification*)aNote;
- (void) rj45SpareIoMuxSelChanged:(NSNotification*)aNote;
- (void) rj45SpareIoDirChanged:(NSNotification*)aNote;
- (void) diagIsyncChanged:(NSNotification*)aNote;
- (void) serdesSmLostLockChanged:(NSNotification*)aNote;
- (void) overflowFlagChanChanged:(NSNotification*)aNote;
- (void) codeRevisionChanged:(NSNotification*)aNote;
- (void) codeDateChanged:(NSNotification*)aNote;
- (void) droppedEventCountChanged:(NSNotification*)aNote;
- (void) acceptedEventCountChanged:(NSNotification*)aNote;
- (void) ahitCountChanged:(NSNotification*)aNote;

- (void) auxIoReadChanged:(NSNotification*)aNote;
- (void) auxIoWriteChanged:(NSNotification*)aNote;
- (void) auxIoConfigChanged:(NSNotification*)aNote;
- (void) sdPemChanged:(NSNotification*)aNote;
- (void) sdSmLostLockFlagChanged:(NSNotification*)aNote;
- (void) adcConfigChanged:(NSNotification*)aNote;
- (void) configMainFpgaChanged:(NSNotification*)aNote;
- (void) vmeStatusChanged:(NSNotification*)aNote;
- (void) overVoltStatChanged:(NSNotification*)aNote;
- (void) underVoltStatChanged:(NSNotification*)aNote;
- (void) temp0SensorChanged:(NSNotification*)aNote;
- (void) temp1SensorChanged:(NSNotification*)aNote;
- (void) temp2SensorChanged:(NSNotification*)aNote;
- (void) clkSelectChanged:(NSNotification*)aNote;
- (void) clkSelect1Changed:(NSNotification*)aNote;
- (void) flashModeChanged:(NSNotification*)aNote;
- (void) serialNumChanged:(NSNotification*)aNote;
- (void) boardRevNumChanged:(NSNotification*)aNote;
- (void) vhdlVerNumChanged:(NSNotification*)aNote;
- (void) doHwCheckChanged:(NSNotification*)aNote;
- (void) aHitCountChanged:(NSNotification*)aNote;
- (void) droppedEventCountChanged:(NSNotification*)aNote;
- (void) discCountChanged:(NSNotification*)aNote;
- (void) acceptedEventCountChanged:(NSNotification*)aNote;

- (IBAction) decimationFactorAction:(id)sender;

#pragma mark - Security
- (IBAction) settingLockAction:(id) sender;
- (IBAction) registerLockAction:(id) sender;

#pragma mark - Firmware loading
- (IBAction) downloadMainFPGAAction:(id)sender;
- (IBAction) stopLoadingMainFPGAAction:(id)sender;


#pragma mark - Register Actions
- (IBAction) enabledAction:(id)sender;
- (IBAction) extDiscrSrcAction:(id)sender;
- (IBAction) extDiscrModeAction:(id)sender;
- (IBAction) userPackageDataAction:(id)sender;


- (IBAction) ledThresholdAction:    (id)sender;
//- (IBAction) writeFlagAction: (id)sender;
- (IBAction) pileupModeAction:(id)sender;
- (IBAction) droppedEventCountModeAction:(id)sender;
- (IBAction) eventCountModeAction:(id)sender;
- (IBAction) triggerPolarityAction:(id)sender;
- (IBAction) aHitCountModeAction:(id)sender;
- (IBAction) discCountModeAction:(id)sender;
- (IBAction) pileupExtensionModeAction:(id)sender;
- (IBAction) pileupWaveformOnlyModeAction:(id)sender;
- (IBAction) rawDataLengthAction:(id)sender;
- (IBAction) rawDataWindowAction:(id)sender;
- (IBAction) dWindowAction:(id)sender;
- (IBAction) kWindowAction:(id)sender;
- (IBAction) mWindowAction:(id)sender;
- (IBAction) d3WindowAction:(id)sender;
- (IBAction) discWidthAction:(id)sender;
- (IBAction) baselineStartAction:(id)sender;
- (IBAction) baselineDelayAction:(id)sender;
- (IBAction) trackingSpeedAction:(id)sender;
- (IBAction) p1WindowAction:(id)sender;
- (IBAction) p2WindowAction:(id)sender;
- (IBAction) triggerConfigAction:(id)sender;
- (IBAction) windowCompMinAction:(id)sender;
- (IBAction) windowCompMaxAction:(id)sender;
- (IBAction) downSampleHoldOffPauseEnableAction:(id)sender;
- (IBAction) downSampleHoldOffTimeAction:(id)sender;
- (IBAction) holdOffTimeAction:(id)sender;
- (IBAction) autoModeAction:(id)sender;
- (IBAction) vetoGateWidthAction:(id)sender;
- (IBAction) loadThresholdsAction:(id)sender;

#pragma mark - Low-level registers and diagnostics
- (IBAction) selectedChannelAction:(id)sender;
- (IBAction) registerIndexPUAction:(id)sender;
- (IBAction) readRegisterAction:(id)sender;
- (IBAction) writeRegisterAction:(id)sender;
- (IBAction) registerWriteValueAction:(id)sender;
- (IBAction) spiWriteValueAction:(id)sender;
- (IBAction) writeSPIAction:(id)sender;
- (IBAction) dumpAllRegisters:(id)sender;
- (IBAction) snapShotRegistersAction:(id)sender;
- (IBAction) compareToSnapShotAction:(id)sender;
- (IBAction) diagnosticsClearAction:(id)sender;
- (IBAction) diagnosticsReportAction:(id)sender;
- (IBAction) diagnosticsEnableAction:(id)sender;
- (IBAction) peakSensitivityAction:(id)sender;

#pragma mark - Hardware access
- (IBAction) probeBoard:(id)sender;
- (IBAction) readStatus:(id)sender;
- (IBAction) resetBoard:(id)sender;
- (IBAction) initBoardAction:(id)sender;
- (IBAction) fullInitBoardAction:(id)sender;
- (IBAction) clearFIFO:(id)sender;
- (IBAction) forceFullInitAction:(id)sender;
- (IBAction) forceFullCardInitAction:(id)sender;
- (IBAction) readLiveTimeStamp:(id)sender;
- (IBAction) readLatTimeStamp:(id)sender;
- (IBAction) readFPGAVersions:(id)sender;
- (IBAction) readVmeAuxStatus:(id)sender;
- (IBAction) dumpCounters:(id)sender;
- (IBAction) doHwCheckButtonAction:(id)sender;
- (IBAction) compareHwNowAction:(id)sender;
- (IBAction) openPreampDialog:(id)sender;
- (IBAction) clockSourceAction:(id)sender;
- (IBAction) readCounters:(id)sender;
- (IBAction) clearCounters:(id)sender;
- (IBAction) softwareTriggerAction:(id)sender;

#pragma mark - Data Source
- (void)    tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (double)  getBarValue:(int)tag;
- (int)     numberPointsInPlot:(id)aPlotter;
- (void)    plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
