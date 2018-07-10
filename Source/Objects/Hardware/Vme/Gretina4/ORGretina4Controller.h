//-------------------------------------------------------------------------
//  ORGretina4Controller.h
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
#import "ORGretina4Model.h"

@class ORValueBarGroupView;
@class ORCompositeTimeLineView;

@interface ORGretina4Controller : OrcaObjectController 
{
    IBOutlet NSTabView* 	tabView;

    //basic ops page
	IBOutlet NSMatrix*		enabledMatrix;
	IBOutlet NSMatrix*		cfdEnabledMatrix;
	IBOutlet NSMatrix*		poleZeroEnabledMatrix;
	IBOutlet NSMatrix*		poleZeroTauMatrix;
	IBOutlet NSMatrix*		pzTraceEnabledMatrix;
	IBOutlet NSMatrix*		debugMatrix;
	IBOutlet NSMatrix*		pileUpMatrix;
	IBOutlet NSMatrix*		ledThresholdMatrix;
	IBOutlet NSMatrix*		cfdDelayMatrix;
	IBOutlet NSMatrix*		cfdFractionMatrix;
	IBOutlet NSMatrix*		cfdThresholdMatrix;
	IBOutlet NSMatrix*		dataDelayMatrix;
	IBOutlet NSMatrix*		dataLengthMatrix;
	IBOutlet NSTextField*   clockLockedField;
    IBOutlet NSPopUpButton* clockSourcePU;

	//arrggg! why can't you put a popup into a NSMatrix????
	IBOutlet NSPopUpButton*	polarityPU0;
	IBOutlet NSPopUpButton*	polarityPU1;
	IBOutlet NSPopUpButton*	polarityPU2;
	IBOutlet NSPopUpButton*	polarityPU3;
	IBOutlet NSPopUpButton*	polarityPU4;
	IBOutlet NSPopUpButton*	polarityPU5;
	IBOutlet NSPopUpButton*	polarityPU6;
	IBOutlet NSPopUpButton*	polarityPU7;
	IBOutlet NSPopUpButton*	polarityPU8;
	IBOutlet NSPopUpButton*	polarityPU9;
	NSPopUpButton* polarityPU[kNumGretina4Channels];
	
	IBOutlet NSPopUpButton*	triggerModePU0;
	IBOutlet NSPopUpButton*	triggerModePU1;
	IBOutlet NSPopUpButton*	triggerModePU2;
	IBOutlet NSPopUpButton*	triggerModePU3;
	IBOutlet NSPopUpButton*	triggerModePU4;
	IBOutlet NSPopUpButton*	triggerModePU5;
	IBOutlet NSPopUpButton*	triggerModePU6;
	IBOutlet NSPopUpButton*	triggerModePU7;
	IBOutlet NSPopUpButton*	triggerModePU8;
	IBOutlet NSPopUpButton*	triggerModePU9;
	NSPopUpButton* triggerModePU[kNumGretina4Channels];
	
    IBOutlet NSTextField*   slotField;
    IBOutlet NSTextField*   addressText;
    IBOutlet NSMatrix*      cardInfoMatrix;

    IBOutlet NSButton*      settingLockButton;
    IBOutlet NSButton*      initButton;
    IBOutlet NSButton*      resetButton;
    IBOutlet NSButton*      clearFIFOButton;
    IBOutlet NSButton*      probeButton;
    IBOutlet NSButton*      statusButton;
    IBOutlet NSButton*      noiseFloorButton;
    IBOutlet NSTextField*   fifoState;

	IBOutlet NSPopUpButton* downSamplePU;
	IBOutlet NSTextField*	histEMultiplierField;
    IBOutlet NSTextField*	initSerDesStateField;
    IBOutlet NSTextField*   lockStateField;
	
	//FPGA download
	IBOutlet NSTextField*			fpgaFilePathField;
	IBOutlet NSButton*				loadMainFPGAButton;
	IBOutlet NSButton*				stopFPGALoadButton;
    IBOutlet NSProgressIndicator*	loadFPGAProgress;
	IBOutlet NSTextField*			mainFPGADownLoadStateField;
	IBOutlet NSTextField*           firmwareStatusStringField;

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
	
    //offset panel
    IBOutlet NSPanel*				noiseFloorPanel;
    IBOutlet NSTextField*			noiseFloorOffsetField;
    IBOutlet NSTextField*			noiseFloorIntegrationField;
    IBOutlet NSButton*				startNoiseFloorButton;
    IBOutlet NSProgressIndicator*	noiseFloorProgress;
	IBOutlet NSButton*				registerLockButton;
	
    NSView *blankView;
    NSSize settingSize;
    NSSize rateSize;
    NSSize registerTabSize;
	NSSize firmwareTabSize;
}

- (id)   init;
- (void) registerNotificationObservers;
- (void) updateWindow;

#pragma mark ¥¥¥Interface Management
- (void) clockSourceChanged:(NSNotification*)aNote;
- (void) initSerDesStateChanged:(NSNotification*) aNote;
- (void) lockChanged:(NSNotification*) aNote;
- (void) updateClockLocked;
- (void) clockSourceChanged:(NSNotification*)aNote;
- (void) firmwareStatusStringChanged:(NSNotification*)aNote;
- (void) downSampleChanged:(NSNotification*)aNote;
- (void) histEMultiplierChanged:(NSNotification*)aNote;
- (void) registerIndexChanged:(NSNotification*)aNote;
- (void) fpgaDownInProgressChanged:(NSNotification*)aNote;
- (void) fpgaDownProgressChanged:(NSNotification*)aNote;
- (void) mainFPGADownLoadStateChanged:(NSNotification*)aNote;
- (void) fpgaFilePathChanged:(NSNotification*)aNote;
- (void) slotChanged:(NSNotification*)aNote;
- (void) baseAddressChanged:(NSNotification*)aNote;
- (void) settingsLockChanged:(NSNotification*)aNote;
- (void) updateCardInfo:(NSNotification*)aNote;
- (void) registerRates;
- (void) rateGroupChanged:(NSNotification*)aNote;
- (void) waveFormRateChanged:(NSNotification*)aNote;
- (void) noiseFloorChanged:(NSNotification*)aNote;
- (void) totalRateChanged:(NSNotification*)aNote;
- (void) noiseFloorOffsetChanged:(NSNotification*)aNote;
- (void) setFifoStateLabel;
- (void) enabledChanged:(NSNotification*)aNote;
- (void) cfdEnabledChanged:(NSNotification*)aNote;
- (void) poleZeroEnabledChanged:(NSNotification*)aNote;
- (void) poleZeroTauChanged:(NSNotification*)aNote;
- (void) pzTraceEnabledChanged:(NSNotification*)aNote;
- (void) debugChanged:(NSNotification*)aNote;
- (void) pileUpChanged:(NSNotification*)aNote;
- (void) polarityChanged:(NSNotification*)aNote;
- (void) triggerModeChanged:(NSNotification*)aNote;
- (void) ledThresholdChanged:(NSNotification*)aNote;
- (void) cfdDelayChanged:(NSNotification*)aNote;
- (void) cfdFractionChanged:(NSNotification*)aNote;
- (void) cfdThresholdChanged:(NSNotification*)aNote;
- (void) dataDelayChanged:(NSNotification*)aNote;
- (void) dataLengthChanged:(NSNotification*)aNote;
- (void) miscAttributesChanged:(NSNotification*)aNote;

- (void) scaleAction:(NSNotification*)aNote;
- (void) integrationChanged:(NSNotification*)aNote;
- (void) updateTimePlot:(NSNotification*)aNote;
- (void) noiseFloorIntegrationChanged:(NSNotification*)aNote;
- (void) registerLockChanged:(NSNotification*)aNote;
- (void) registerWriteValueChanged:(NSNotification*)aNote;
- (void) spiWriteValueChanged:(NSNotification*)aNote;

- (void) setRegisterDisplay:(unsigned int)index;

#pragma mark ¥¥¥Actions
- (IBAction) downSampleAction:(id)sender;
- (IBAction) histEMultiplierAction:(id)sender;
- (IBAction) baseAddressAction:(id)sender;
- (IBAction) settingLockAction:(id) sender;
- (IBAction) cardInfoAction:(id) sender;
- (IBAction) probeBoard:(id)sender;
- (IBAction) readStatus:(id)sender;
- (IBAction) resetBoard:(id)sender;
- (IBAction) initBoardAction:(id)sender;
- (IBAction) clearFIFO:(id)sender;
- (IBAction) integrationAction:(id)sender;
- (IBAction) findNoiseFloors:(id)sender;
- (IBAction) noiseFloorOffsetAction:(id)sender;
- (IBAction) openNoiseFloorPanel:(id)sender;
- (IBAction) closeNoiseFloorPanel:(id)sender;
- (IBAction) noiseFloorIntegrationAction:(id)sender;

- (IBAction) enabledAction:(id)sender;
- (IBAction) cfdEnabledAction:(id)sender;
- (IBAction) poleZeroEnabledAction:(id)sender;
- (IBAction) poleZeroTauAction:(id)sender;
- (IBAction) pzTraceEnabledAction:(id)sender;
- (IBAction) debugAction:(id)sender;
- (IBAction) pileUpAction:(id)sender;
- (IBAction) polarityAction:(id)sender;
- (IBAction) triggerModeAction:(id)sender;
- (IBAction) ledThresholdAction:(id)sender;
- (IBAction) cfdFractionAction:(id)sender;
- (IBAction) cfdDelayAction:(id)sender;
- (IBAction) cfdThresholdAction:(id)sender;
- (IBAction) dataDelayAction:(id)sender;
- (IBAction) dataLengthAction:(id)sender;
- (IBAction) downloadMainFPGAAction:(id)sender;
- (IBAction) stopLoadingMainFPGAAction:(id)sender;

- (IBAction) registerIndexPUAction:(id)sender;
- (IBAction) readRegisterAction:(id)sender;
- (IBAction) writeRegisterAction:(id)sender;
- (IBAction) registerLockAction:(id) sender;
- (IBAction) registerWriteValueAction:(id)sender;
- (IBAction) spiWriteValueAction:(id)sender;
- (IBAction) writeSPIAction:(id)sender;
- (IBAction) clockSourceAction:(id)sender;

#pragma mark ¥¥¥Data Source
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (double)  getBarValue:(int)tag;
- (int) numberPointsInPlot:(id)aPlotter;
- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;

@end
