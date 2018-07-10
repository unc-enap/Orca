//-------------------------------------------------------------------------
//  ORGretina4MController.h
//
//  Created by Mark A. Howe on Wednesday 02/07/2007.
//  Copyright (c) 2007 CENPA. University of Washington. All rights reserved.
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

#pragma mark ***Imported Files
#import "OrcaObjectController.h"
#import "ORGretina4MModel.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;
@class ORGretinaCntView;

@interface ORGretina4MController : OrcaObjectController 
{
    IBOutlet   NSTabView* 	tabView;
	IBOutlet   NSTextField* baselineRestoredDelayField;
	IBOutlet   NSTextField* firmwareStatusStringField;
	IBOutlet   NSTextField* noiseWindowField;
    
	IBOutlet   NSTextField* integrateTimeField;
	IBOutlet   NSTextField* collectionTimeField;
	IBOutlet   NSTextField* extTrigLengthField;
	IBOutlet   NSTextField* pileUpWindowField;
	IBOutlet   NSTextField* externalWindowField;
	IBOutlet   NSTextField* clockLockedField;

    //basic ops page
    IBOutlet NSMatrix*		enabledMatrix;
    IBOutlet NSMatrix*		forceFullInitMatrix;
    IBOutlet NSButton*      forceFullInitCardButton;
    IBOutlet NSButton*      viewPreampButton;
    IBOutlet NSButton*      doHwCheckButton;
    
	IBOutlet NSMatrix*		trapEnabledMatrix;
	IBOutlet NSMatrix*		poleZeroEnabledMatrix;
	IBOutlet NSMatrix*		poleZeroTauMatrix;
	IBOutlet NSMatrix*		pzTraceEnabledMatrix;
    IBOutlet NSMatrix*      baselineRestoreEnabledMatrix;
	IBOutlet NSMatrix*		pileUpMatrix;
	IBOutlet NSMatrix*		presumEnabledMatrix;
	IBOutlet NSMatrix*		ledThresholdMatrix;
	IBOutlet NSMatrix*		trapThresholdMatrix;
	IBOutlet NSMatrix*      tpolMatrix;
	IBOutlet NSMatrix*      triggerModeMatrix;
    IBOutlet NSMatrix*		chpsdvMatrix;
    IBOutlet NSMatrix*		ftCntMatrix;
    IBOutlet NSMatrix*		mrpsrtMatrix;
    IBOutlet NSMatrix*		mrpsdvMatrix;
    IBOutlet NSMatrix*		chpsrtMatrix;
    IBOutlet NSMatrix*		prerecntMatrix;
    IBOutlet NSMatrix*		postrecntMatrix;
	IBOutlet NSMatrix*		easySelectMatrix;

    IBOutlet NSPopUpButton* clockSourcePU;
    IBOutlet NSPopUpButton* clockPhasePU;

    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      initButton;
    IBOutlet NSButton*      fullInitButton;
    IBOutlet NSButton*      initButton1;
    IBOutlet NSButton*      resetButton;
    IBOutlet NSButton*      clearFIFOButton;
    IBOutlet NSButton*      probeButton;
    IBOutlet NSButton*      statusButton;
    IBOutlet NSButton*      noiseFloorButton;
    IBOutlet NSButton*      easySetButton;
    IBOutlet NSButton*      loadThresholdsButton;
    IBOutlet NSButton*      compareHwNowButton;

	IBOutlet NSPopUpButton* downSamplePU;
	
	//FPGA download
	IBOutlet NSTextField*			fpgaFilePathField;
	IBOutlet NSButton*				loadMainFPGAButton;
	IBOutlet NSButton*				stopFPGALoadButton;
    IBOutlet NSProgressIndicator*	loadFPGAProgress;
	IBOutlet NSTextField*			mainFPGADownLoadStateField;

    //rate page
    IBOutlet NSMatrix*      rateTextFields;
    IBOutlet NSStepper*     integrationStepper;
    IBOutlet NSTextField*   integrationText;
    IBOutlet NSTextField*   totalRateText;
    IBOutlet NSMatrix*      enabled2Matrix;

    IBOutlet ORValueBarGroupView*    rate0;
    IBOutlet ORValueBarGroupView*    totalRate;
    IBOutlet NSButton*      rateLogCB;
    IBOutlet NSButton*      totalRateLogCB;
    IBOutlet ORCompositeTimeLineView*    timeRatePlot;
    IBOutlet NSButton*      timeRateLogCB;
	
    //register page
	IBOutlet NSPopUpButton*	registerIndexPU;
	IBOutlet NSTextField*	registerWriteValueField;
	IBOutlet NSButton*		writeRegisterButton;
	IBOutlet NSButton*		readRegisterButton;
	IBOutlet NSTextField*	registerStatusField;
	IBOutlet NSTextField*	spiWriteValueField;
	IBOutlet NSButton*		writeSPIButton;
	IBOutlet NSButton*		dumpAllRegistersButton;
	IBOutlet NSButton*		snapShotRegistersButton;
    IBOutlet NSButton*		compareRegistersButton;
    IBOutlet NSButton*		printThresholdsButton;
	
    IBOutlet NSButton*		diagnosticsEnabledCB;
    IBOutlet NSButton*		diagnosticsReportButton;
    IBOutlet NSButton*		diagnosticsClearButton;
    
    IBOutlet NSTextField*	initSerDesStateField;
    IBOutlet NSTextField*   lockStateField;
    
    //offset panel
    IBOutlet NSPanel*				noiseFloorPanel;
    IBOutlet NSTextField*			noiseFloorOffsetField;
    IBOutlet NSTextField*			noiseFloorIntegrationField;
    IBOutlet NSButton*				startNoiseFloorButton;
    IBOutlet NSProgressIndicator*	noiseFloorProgress;
	IBOutlet NSButton*				registerLockButton;
	
    //Easy Set Panel
    IBOutlet NSPanel*				easySetPanel;
    IBOutlet ORGretinaCntView*      dataWindowView;
    IBOutlet NSButton*              flatTopStepperUp;
    IBOutlet NSButton*              flatTopStepperDwn;
    IBOutlet NSButton*              postReStepperUp;
    IBOutlet NSButton*              postReStepperDwn;
    IBOutlet NSButton*              preReStepperUp;
    IBOutlet NSButton*              preReStepperDwn;
    IBOutlet NSTextField*			preCountField;
    IBOutlet NSTextField*			postCountField;
    IBOutlet NSTextField*			flatTopField;
	IBOutlet NSTextField*           histEMultiplierField;

    NSView *blankView;
    NSSize settingSize;
    NSSize rateSize;
    NSSize registerTabSize;
	NSSize firmwareTabSize;
	NSSize definitionsTabSize;

}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark •••Interface Management
- (void) updateClockLocked;
- (void) histEMultiplierChanged:(NSNotification*)aNote;
- (void) baselineRestoredDelayChanged:(NSNotification*)aNote;
- (void) firmwareStatusStringChanged:(NSNotification*)aNote;
- (void) noiseWindowChanged:(NSNotification*)aNote;
- (void) chpsdvChanged:(NSNotification*)aNote;
- (void) mrpsrtChanged:(NSNotification*)aNote;
- (void) ftCntChanged:(NSNotification*)aNote;
- (void) mrpsdvChanged:(NSNotification*)aNote;
- (void) chsrtChanged:(NSNotification*)aNote;
- (void) prerecntChanged:(NSNotification*)aNote;
- (void) postrecntChanged:(NSNotification*)aNote;
- (void) forceFullInitChanged:(NSNotification*)aNote;
- (void) forceFullInitCardChanged:(NSNotification*)aNote;
- (void) doHwCheckChanged:(NSNotification*)aNote;

- (void) pileUpChanged:(NSNotification*)aNote;
- (void) integrateTimeChanged:(NSNotification*)aNote;
- (void) collectionTimeChanged:(NSNotification*)aNote;
- (void) extTrigLengthChanged:(NSNotification*)aNote;
- (void) pileUpWindowChanged:(NSNotification*)aNote;
- (void) externalWindowChanged:(NSNotification*)aNote;
- (void) clockSourceChanged:(NSNotification*)aNote;
- (void) clockPhaseChanged:(NSNotification*)aNote;
- (void) downSampleChanged:(NSNotification*)aNote;
- (void) registerIndexChanged:(NSNotification*)aNote;
- (void) fpgaDownInProgressChanged:(NSNotification*)aNote;
- (void) fpgaDownProgressChanged:(NSNotification*)aNote;
- (void) mainFPGADownLoadStateChanged:(NSNotification*)aNote;
- (void) fpgaFilePathChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) registerRates;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) noiseFloorChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) noiseFloorOffsetChanged:(NSNotification*)aNote;
- (void) enabledChanged:(NSNotification*)aNote;
- (void) trapEnabledChanged:(NSNotification*)aNote;
- (void) poleZeroEnabledChanged:(NSNotification*)aNote;
- (void) baselineRestoreEnabledChanged:(NSNotification*)aNote;
- (void) poleZeroTauChanged:(NSNotification*)aNote;
- (void) pzTraceEnabledChanged:(NSNotification*)aNote;
- (void) presumEnabledChanged:(NSNotification*)aNote;
- (void) tpolChanged:(NSNotification*)aNote;
- (void) triggerModeChanged:(NSNotification*)aNote;
- (void) ledThresholdChanged:(NSNotification*)aNote;
- (void) trapThresholdChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;
- (void) easySelectChanged:(NSNotification*)aNote;
- (void) diagnosticsEnabledChanged:(NSNotification*)aNote;

- (void) scaleAction:(NSNotification*)aNote;
- (void) integrationChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) noiseFloorIntegrationChanged:(NSNotification*)aNote;
- (void) registerLockChanged:(NSNotification*)aNote;
- (void) registerWriteValueChanged:(NSNotification*)aNote;
- (void) spiWriteValueChanged:(NSNotification*)aNote;

- (void) setRegisterDisplay:(unsigned int)index;
- (void) initSerDesStateChanged:(NSNotification*) aNote;

#pragma mark •••Actions
- (IBAction) forceFullInitCardAction:(id)sender;
- (IBAction) clockSourceAction:(id)sender;
- (IBAction) clockPhaseAction:(id)sender;
- (IBAction) diagnosticsClearAction:(id)sender;
- (IBAction) diagnosticsReportAction:(id)sender;
- (IBAction) diagnosticsEnableAction:(id)sender;
- (IBAction) baselineRestoredDelayAction:(id)sender;
- (IBAction) noiseWindowAction:(id)sender;
- (IBAction) integrateTimeFieldAction:(id)sender;
- (IBAction) collectionTimeFieldAction:(id)sender;
- (IBAction) extTrigLengthFieldAction:(id)sender;
- (IBAction) pileUpWindowFieldAction:(id)sender;
- (IBAction) externalWindowFieldAction:(id)sender;
- (IBAction) downSampleAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) probeBoard:(id)sender;
- (IBAction) readStatus:(id)sender;
- (IBAction) resetBoard:(id)sender;
- (IBAction) initBoardAction:(id)sender;
- (IBAction) fullInitBoardAction:(id)sender;
- (IBAction) clearFIFO:(id)sender;
- (IBAction) integrationAction:(id)sender;
- (IBAction) findNoiseFloors:(id)sender;
- (IBAction) noiseFloorOffsetAction:(id)sender;
- (IBAction) openNoiseFloorPanel:(id)sender;
- (IBAction) closeNoiseFloorPanel:(id)sender;
- (IBAction) noiseFloorIntegrationAction:(id)sender;
- (IBAction) pileUpAction:(id)sender;

- (IBAction) chpsdvAction:(id)sender;
- (IBAction) mrpsrtAction:(id)sender;
- (IBAction) ftCntAction:(id)sender;
- (IBAction) mrpsdvAction:(id)sender;
- (IBAction) chsrtAction:(id)sender;
- (IBAction) prerecntAction:(id)sender;
- (IBAction) postrecntAction:(id)sender;


- (IBAction) enabledAction:(id)sender;
- (IBAction) forceFullInitAction:(id)sender;
- (IBAction) trapEnabledAction:(id)sender;
- (IBAction) baselineRestoreEnabledAction:(id)sender;
- (IBAction) poleZeroEnabledAction:(id)sender;
- (IBAction) poleZeroTauAction:(id)sender;
- (IBAction) pzTraceEnabledAction:(id)sender;
- (IBAction) presumEnabledAction:(id)sender;
- (IBAction) tpolAction:(id)sender;
- (IBAction) triggerModeAction:(id)sender;
- (IBAction) ledThresholdAction:(id)sender;
- (IBAction) trapThresholdAction:(id)sender;
- (IBAction) downloadMainFPGAAction:(id)sender;
- (IBAction) stopLoadingMainFPGAAction:(id)sender;
- (IBAction) easySelectAction:(id)sender;

- (IBAction) registerIndexPUAction:(id)sender;
- (IBAction) readRegisterAction:(id)sender;
- (IBAction) writeRegisterAction:(id)sender;
- (IBAction) registerLockAction:(id) sender;
- (IBAction) registerWriteValueAction:(id)sender;
- (IBAction) spiWriteValueAction:(id)sender;
- (IBAction) writeSPIAction:(id)sender;
- (IBAction) dumpAllRegisters:(id)sender;
- (IBAction) printThresholds:(id)sender;

- (IBAction) openEasySetPanel:(id)sender;
- (IBAction) closeEasySetPanel:(id)sender;
- (IBAction) selectAllInEasySet:(id)sender;
- (IBAction) selectNoneInEasySet:(id)sender;
- (IBAction) histEMultiplierAction:(id)sender;
- (IBAction) snapShotRegistersAction:(id)sender;
- (IBAction) compareToSnapShotAction:(id)sender;
- (IBAction) viewPreampAction:(id)sender;
- (IBAction) loadThresholdsAction:(id)sender;
- (IBAction) doHwCheckButtonAction:(id)sender;
- (IBAction) compareHwNowAction:(id)sender;


#pragma mark •••Data Source
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (double)  getBarValue:(int)tag;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
