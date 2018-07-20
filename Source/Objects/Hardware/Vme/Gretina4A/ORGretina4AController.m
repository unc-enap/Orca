//-------------------------------------------------------------------------
//  ORGretina4AController.m
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
#import "ORGretina4AController.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORValueBar.h"
#import "ORTimeRate.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"
#import "ORGretina4ARegisters.h"

@implementation ORGretina4AController

-(id)init
{
    self = [super initWithWindowNibName:@"Gretina4A"];
    
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    settingSize     = NSMakeSize(1060,460);
    rateSize		= NSMakeSize(790,340);
    registerTabSize	= NSMakeSize(800,520);
	firmwareTabSize = NSMakeSize(480,187);
    blankView = [[NSView alloc] init];
    
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	

	// Setup register popup buttons
    [registerIndexPU removeAllItems];
	[registerIndexPU setAutoenablesItems:NO];
	int i;
	for (i=0;i<kNumberOfGretina4ARegisters;i++) {
        NSString* s = [NSString stringWithFormat:@"(0x%04x) %@",[Gretina4ARegisters offsetforReg:i], [Gretina4ARegisters registerName:i]];
		[registerIndexPU insertItemWithTitle:s	atIndex:i];
		[[registerIndexPU itemAtIndex:i] setEnabled:YES];
	}
	// And now the FPGA registers
    for (i=0;i<kNumberOfFPGARegisters;i++) {
        NSString* s = [NSString stringWithFormat:@"(0x%04x) %@",[Gretina4AFPGARegisters offsetforReg:i], [Gretina4AFPGARegisters registerName:i]];

		[registerIndexPU insertItemWithTitle:s	atIndex:(i+kNumberOfGretina4ARegisters)];
	}

    for (i=0;i<kNumGretina4AChannels;i++) {
        [[enabledMatrix                 cellAtRow:i column:0] setTag:i];
        [[enabled2Matrix                cellAtRow:i column:0] setTag:i];
        [[extDiscrSrcMatrix             cellAtRow:i column:0] setTag:i];
        [[extDiscrModeMatrix             cellAtRow:i column:0] setTag:i];
        [[pileupWaveformOnlyModeMatrix  cellAtRow:i column:0] setTag:i];
        [[pileupExtensionModeMatrix     cellAtRow:i column:0] setTag:i];
        [[discCountModeMatrix           cellAtRow:i column:0] setTag:i];
        [[aHitCountModeMatrix           cellAtRow:i column:0] setTag:i];
        [[eventCountModeMatrix          cellAtRow:i column:0] setTag:i];
        [[droppedEventCountModeMatrix   cellAtRow:i column:0] setTag:i];
        [[decimationFactorMatrix        cellAtRow:i column:0] setTag:i];
        [[triggerPolarityMatrix         cellAtRow:i column:0] setTag:i];
        [[pileupModeMatrix              cellAtRow:i column:0] setTag:i];
        [[ledThresholdMatrix            cellAtRow:i column:0] setTag:i];
        [[p1WindowMatrix                cellAtRow:i column:0] setTag:i];
        [[mWindowMatrix                 cellAtRow:i column:0] setTag:i];
        [[kWindowMatrix                 cellAtRow:i column:0] setTag:i];
        [[d3WindowMatrix                cellAtRow:i column:0] setTag:i];
        [[dWindowMatrix                 cellAtRow:i column:0] setTag:i];
        [[discWidthMatrix               cellAtRow:i column:0] setTag:i];
        [[baselineStartMatrix           cellAtRow:i column:0] setTag:i];
        
        [[aHitCountMatrix               cellAtRow:i column:0] setTag:i];
        [[acceptedEventCountMatrix      cellAtRow:i column:0] setTag:i];
        [[droppedEventCountMatrix       cellAtRow:i column:0] setTag:i];
        [[discriminatorCountMatrix      cellAtRow:i column:0] setTag:i];

    }
    
    NSString* key = [NSString stringWithFormat: @"orca.Gretina4A%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
	
	[rate0 setNumber:10 height:10 spacing:5];
	
	[super awakeFromNib];
}

#pragma mark •••Boilerplate
- (void) slotChanged:(NSNotification*)aNotification
{
    [[self window] setTitle:[NSString stringWithFormat:@"Gretina4A Card (Slot %d)",[model slot]]];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"Gretina4A Card (Slot %d)",[model slot]]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORGretina4ASettingsLock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORGretina4ARegisterLock
                        object: nil];
	   
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORGretina4AMainFPGADownLoadInProgressChanged
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORGretina4AMainFPGADownLoadInProgressChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORGretina4ARateGroupChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(scaleAction:)
                         name : ORAxisRangeChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateTimePlot:)
                         name : ORRateAverageChangedNotification
                       object : [[model waveFormRateGroup]timeRate]];
    
    [notifyCenter addObserver : self
                     selector : @selector(integrationChanged:)
                         name : ORRateGroupIntegrationChangedNotification
                       object : nil];
		
    [notifyCenter addObserver : self
                     selector : @selector(fpgaFilePathChanged:)
                         name : ORGretina4AFpgaFilePathChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(mainFPGADownLoadStateChanged:)
                         name : ORGretina4AMainFPGADownLoadStateChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(fpgaDownProgressChanged:)
                         name : ORGretina4AFpgaDownProgressChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(fpgaDownInProgressChanged:)
                         name : ORGretina4AMainFPGADownLoadInProgressChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(selectedChannelChanged:)
                         name : ORGretina4ASelectedChannelChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(registerWriteValueChanged:)
                         name : ORGretina4ARegisterWriteValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(registerIndexChanged:)
                         name : ORGretina4ARegisterIndexChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(spiWriteValueChanged:)
                         name : ORGretina4ASPIWriteValueChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(forceFullInitChanged:)
                         name : ORGretina4AForceFullInitChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(forceFullCardInitChanged:)
                         name : ORGretina4AForceFullCardInitChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(extDiscrSrcChanged:)
                         name : ORGretina4AExtDiscrimitorSrcChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(extDiscrModeChanged:)
                         name : ORGretina4AExtDiscriminatorModeChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(userPackageDataChanged:)
                         name : ORGretina4AUserPackageDataChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(windowCompMinChanged:)
                         name : ORGretina4AWindowCompMinChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(windowCompMaxChanged:)
                         name : ORGretina4AWindowCompMaxChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pileupWaveformOnlyModeChanged:)
                         name : ORGretina4APileupWaveformOnlyModeChanged
                        object: model];


    [notifyCenter addObserver : self
                     selector : @selector(pileupExtensionModeChanged:)
                         name : ORGretina4APileupExtensionModeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(discCountModeChanged:)
                         name : ORGretina4ADiscCountModeChanged
                        object: model];
   
    [notifyCenter addObserver : self
                     selector : @selector(aHitCountModeChanged:)
                         name :ORGretina4AAHitCountModeChanged
                        object: model];
  
    [notifyCenter addObserver : self
                     selector : @selector(eventCountModeChanged:)
                         name : ORGretina4AEventCountModeChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(droppedEventCountModeChanged:)
                         name : ORGretina4ADroppedEventCountModeChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(decimationFactorChanged:)
                         name : ORGretina4ADecimationFactorChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(triggerPolarityChanged:)
                         name : ORGretina4ATriggerPolarityChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(pileupModeChanged:)
                         name : ORGretina4APileupModeChanged
                        object: model];
 
    [notifyCenter addObserver : self
                     selector : @selector(enabledChanged:)
                         name : ORGretina4AEnabledChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(ledThresholdChanged:)
                         name : ORGretina4ALedThreshold0Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(triggerConfigChanged:)
                         name : ORGretina4ATriggerConfigChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(rawDataLengthChanged:)
                         name : ORGretina4ARawDataLengthChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(rawDataWindowChanged:)
                         name : ORGretina4ARawDataWindowChanged
                        object: model];
 
    [notifyCenter addObserver : self
                     selector : @selector(dWindowChanged:)
                         name : ORGretina4ADWindowChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(kWindowChanged:)
                         name : ORGretina4AKWindowChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(mWindowChanged:)
                         name : ORGretina4AMWindowChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(d3WindowChanged:)
                         name : ORGretina4AD3WindowChanged
                        object: model];


    [notifyCenter addObserver : self
                     selector : @selector(discWidthChanged:)
                         name : ORGretina4ADiscWidthChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(baselineStartChanged:)
                         name : ORGretina4ABaselineStartChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(baselineDelayChanged:)
                         name : ORGretina4ABaselineDelayChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(trackingSpeedChanged:)
                         name : ORGretina4ATrackingSpeedChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(p1WindowChanged:)
                         name : ORGretina4AP1WindowChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(p2WindowChanged:)
                         name : ORGretina4AP2WindowChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(peakSensitivityChanged:)
                         name : ORGretina4APeakSensitivityChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(holdOffTimeChanged:)
                         name : ORGretina4AHoldOffTimeChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(downSampleHoldOffTimeChanged:)
                         name : ORGretina4ADownSampleHoldOffTimeChanged
                        object: model];

    
    [notifyCenter addObserver : self
                     selector : @selector(autoModeChanged:)
                         name : ORGretina4AAutoModeChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(vetoGateWidthChanged:)
                         name : ORGretina4AVetoGateWidthChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORGretina4AClockSourceChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dacChannelSelectChanged:)
                         name : ORGretina4ADacChannelSelectChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(dacAttenuationChanged:)
                         name : ORGretina4ADacAttenuationChanged
                        object: model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(diagInputChanged:)
                         name : ORGretina4ADiagInputChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(rj45SpareIoMuxSelChanged:)
                         name : ORGretina4ARj45SpareIoMuxSelChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(rj45SpareIoDirChanged:)
                         name : ORGretina4ARj45SpareIoDirChanged
                        object: model];

    
    [notifyCenter addObserver : self
                     selector : @selector(diagIsyncChanged:)
                         name : ORGretina4ADiagIsyncChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(serdesSmLostLockChanged:)
                         name : ORGretina4ASerdesSmLostLockChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(overflowFlagChanChanged:)
                         name : ORGretina4AOverflowFlagChanChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(codeRevisionChanged:)
                         name : ORGretina4ACodeRevisionChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(codeDateChanged:)
                         name : ORGretina4ACodeDateChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(droppedEventCountChanged:)
                         name : ORGretina4ADroppedEventCountChanged
                        object: model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(auxIoWriteChanged:)
                         name : ORGretina4AAuxIoWriteChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(auxIoConfigChanged:)
                         name : ORGretina4AAuxIoConfigChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(sdPemChanged:)
                         name : ORGretina4ASdPemChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(sdSmLostLockFlagChanged:)
                         name : ORGretina4ASdSmLostLockFlagChanged
                        object: model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(configMainFpgaChanged:)
                         name : ORGretina4AConfigMainFpgaChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(vmeStatusChanged:)
                         name : ORGretina4AVmeStatusChanged
                        object: model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(clkSelectChanged:)
                         name : ORGretina4AClkSelect0Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(clkSelect1Changed:)
                         name : ORGretina4AClkSelect1Changed
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(flashModeChanged:)
                         name : ORGretina4AFlashModeChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(serialNumChanged:)
                         name : ORGretina4ASerialNumChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(boardRevNumChanged:)
                         name : ORGretina4ABoardRevNumChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(vhdlVerNumChanged:)
                         name : ORGretina4AVhdlVerNumChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(doHwCheckChanged:)
                         name : ORGretina4ADoHwCheckChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(downSamplePauseEnableChanged:)
                         name : ORGretina4ADownSamplePauseEnableChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(aHitCountChanged:)
                         name : ORGretina4AAHitCountChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(droppedEventCountChanged:)
                         name : ORGretina4ADroppedEventCountChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(discCountChanged:)
                         name : ORGretina4ADiscCountChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(acceptedEventCountChanged:)
                         name : ORGretina4AAcceptedEventCountChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(firmwareStatusStringChanged:)
                         name : ORGretina4AModelFirmwareStatusStringChanged
                        object: model];

    
    [self registerRates];

}

- (void) registerRates
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter removeObserver:self name:ORRateChangedNotification object:nil];
    
    NSEnumerator* e = [[[model waveFormRateGroup] rates] objectEnumerator];
    id obj;
    while(obj = [e nextObject]){
		
        [notifyCenter removeObserver:self name:ORRateChangedNotification object:obj];
		
        [notifyCenter addObserver : self
                         selector : @selector(waveFormRateChanged:)
                             name : ORRateChangedNotification
                           object : obj];
    }
}

- (void) updateWindow
{
    [super updateWindow];
    
    //Card Movement
    [self slotChanged:nil];
    
    //Security
    [self settingsLockChanged:nil];
    [self registerLockChanged:nil];
    [self lockChanged:nil];

    //Low-level registers and diagnostics
    [self selectedChannelChanged:nil];
    [self registerIndexChanged:nil];
    [self registerWriteValueChanged:nil];
    [self spiWriteValueChanged:nil];
    [self diagnosticsEnabledChanged:nil];

    //firmware loading
    [self fpgaFilePathChanged:nil];
    [self mainFPGADownLoadStateChanged:nil];
    [self fpgaDownProgressChanged:nil];
    [self fpgaDownInProgressChanged:nil];

    //rates
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];
		
    //SerDes and Clock Distribution
    [self initSerDesStateChanged:nil];
    
    //Card Params
    [self forceFullInitChanged:nil];
    [self forceFullCardInitChanged:nil];
    [self extDiscrSrcChanged:nil];
    [self extDiscrModeChanged:nil];
    [self userPackageDataChanged:nil];
    [self windowCompMinChanged:nil];
    [self windowCompMaxChanged:nil];
    [self clockSourceChanged:nil];

    [self pileupWaveformOnlyModeChanged:nil];
    [self pileupExtensionModeChanged:nil];
    [self discCountModeChanged:nil];
    [self aHitCountModeChanged:nil];
    [self eventCountModeChanged:nil];
    [self droppedEventCountModeChanged:nil];
//    [self writeFlagChanged:nil];
    [self decimationFactorChanged:nil];
    [self triggerPolarityChanged:nil];
    [self pileupModeChanged:nil];
    [self enabledChanged:nil];
    [self ledThresholdChanged:nil];
    [self rawDataLengthChanged:nil];
    [self rawDataWindowChanged:nil];
    [self dWindowChanged:nil];
    [self kWindowChanged:nil];
    [self mWindowChanged:nil];
    [self d3WindowChanged:nil];
    [self discWidthChanged:nil];
    [self peakSensitivityChanged:nil];
    [self downSampleHoldOffTimeChanged:nil];
    [self holdOffTimeChanged:nil];
    [self autoModeChanged:nil];
    [self vetoGateWidthChanged:nil];


    [self acqDcmCtrlStatusChanged:nil];
    [self acqDcmLockChanged:nil];
    [self acqDcmResetChanged:nil];
    [self acqPhShiftOverflowChanged:nil];
    [self acqDcmClockStoppedChanged:nil];
    [self adcDcmCtrlStatusChanged:nil];
    [self adcDcmLockChanged:nil];
    [self adcDcmResetChanged:nil];
    [self adcPhShiftOverflowChanged:nil];
    [self adcDcmClockStoppedChanged:nil];
 
    
    [self baselineStartChanged:nil];
    [self baselineDelayChanged:nil];
    [self trackingSpeedChanged:nil];
    [self p1WindowChanged:nil];
    [self p2WindowChanged:nil];
    [self dacChannelSelectChanged:nil];
    [self dacAttenuationChanged:nil];
    [self ilaConfigChanged:nil];
    [self diagMuxControlChanged:nil];
    [self diagInputChanged:nil];
    [self diagChannelEventSelChanged:nil];
    [self rj45SpareIoMuxSelChanged:nil];
    [self rj45SpareIoDirChanged:nil];
    [self ledStatusChanged:nil];
    [self diagIsyncChanged:nil];
    [self serdesSmLostLockChanged:nil];
    [self overflowFlagChanChanged:nil];
    [self codeRevisionChanged:nil];
    [self codeDateChanged:nil];
    
    [self triggerConfigChanged:nil];
    [self phaseErrorCountChanged:nil];
     [self auxIoReadChanged:nil];
    [self auxIoWriteChanged:nil];
    [self auxIoConfigChanged:nil];
    [self sdPemChanged:nil];
    [self sdSmLostLockFlagChanged:nil];
    [self adcConfigChanged:nil];
    [self configMainFpgaChanged:nil];
    [self vmeStatusChanged:nil];
    [self overVoltStatChanged:nil];
    [self underVoltStatChanged:nil];
    [self temp0SensorChanged:nil];
    [self temp1SensorChanged:nil];
    [self temp2SensorChanged:nil];
    [self clkSelectChanged:nil];
    [self clkSelect1Changed:nil];
    [self flashModeChanged:nil];
    [self serialNumChanged:nil];
    [self boardRevNumChanged:nil];
    [self vhdlVerNumChanged:nil];
    [self doHwCheckChanged:nil];
    [self downSamplePauseEnableChanged:nil];

    [self tSErrCntCtrlChanged:nil];
    [self tSErrorCountChanged:nil];
    [self aHitCountChanged:nil];
    [self droppedEventCountChanged:nil];
    [self discCountChanged:nil];
    [self acceptedEventCountChanged:nil];
    [self firmwareStatusStringChanged:nil];

}

#pragma mark •••Interface Management

#pragma mark •••Security
- (void) lockChanged:(NSNotification*) aNote
{
    [lockStateField setStringValue:[model locked]?@"Yes":@"No"];
    [self updateClockLocked];
}
- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORGretina4ASettingsLock to:secure];
    [gSecurity setLock:ORGretina4ARegisterLock to:secure];
    [settingLockButton setEnabled:secure];
    [registerLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress              = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGretina4ASettingsLock];
    BOOL locked                     = [gSecurity isLocked:ORGretina4ASettingsLock];
    BOOL downloading                = [model downLoadMainFPGAInProgress];
    
    [settingLockButton      setState: locked];
    [initButton             setEnabled:!lockedOrRunningMaintenance && !downloading];
    [fullInitButton         setEnabled:!lockedOrRunningMaintenance && !downloading];
    [initButton1            setEnabled:!lockedOrRunningMaintenance && !downloading];
    [clearFIFOButton        setEnabled:!locked && !runInProgress && !downloading];
    [statusButton           setEnabled:!lockedOrRunningMaintenance && !downloading];
    [probeButton            setEnabled:!locked && !runInProgress && !downloading];
    [resetButton            setEnabled:!lockedOrRunningMaintenance && !downloading];
    [loadMainFPGAButton     setEnabled:!locked && !downloading];
    [stopFPGALoadButton     setEnabled:!locked && downloading];
    
    [downSampleHoldOffTimeField setEnabled:!lockedOrRunningMaintenance && !downloading && [model downSamplePauseEnable]];
    [downSamplePauseEnableCB setEnabled:!lockedOrRunningMaintenance && !downloading];
    
    [diagnosticsReportButton setEnabled:[model diagnosticsEnabled]];
    [diagnosticsClearButton  setEnabled:[model diagnosticsEnabled]];
    [clockSourcePU          setEnabled:!lockedOrRunningMaintenance && !downloading];

}

- (void) registerLockChanged:(NSNotification*)aNotification
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGretina4ARegisterLock];
    BOOL locked = [gSecurity isLocked:ORGretina4ARegisterLock];
    BOOL downloading = [model downLoadMainFPGAInProgress];
    
    [registerLockButton setState: locked];
    [registerWriteValueField setEnabled:!lockedOrRunningMaintenance && !downloading];
    [channelSelectionField setEnabled:!lockedOrRunningMaintenance && !downloading];
    [registerIndexPU setEnabled:!lockedOrRunningMaintenance && !downloading];
    [readRegisterButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [writeRegisterButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [spiWriteValueField setEnabled:!lockedOrRunningMaintenance && !downloading];
    [writeSPIButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [dumpAllRegistersButton setEnabled:!downloading];
    [snapShotRegistersButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [compareRegistersButton setEnabled:!lockedOrRunningMaintenance && !downloading];

}

#pragma mark •••Low-level registers and diagnostics
- (void) registerIndexChanged:(NSNotification*)aNote
{
    [registerIndexPU selectItemAtIndex: [model registerIndex]];
    [self setRegisterDisplay:[model registerIndex]];
}

- (void) setRegisterDisplay:(unsigned int)index
{
    if (index < kNumberOfGretina4ARegisters) {
        [writeRegisterButton setEnabled:    [Gretina4ARegisters regIsWriteable:index]];
        [registerWriteValueField setEnabled:[Gretina4ARegisters regIsWriteable:index]];
        [readRegisterButton setEnabled:     [Gretina4ARegisters regIsReadable:index]];
        [selectedChannelField setEnabled:   [Gretina4ARegisters hasChannels:index]];
        
        [registerStatusField setStringValue:@""];
    }
    else {
        index -= kNumberOfGretina4ARegisters;
        [selectedChannelField setEnabled:   NO];
        [writeRegisterButton setEnabled:    [Gretina4AFPGARegisters regIsWriteable:index]];
        [registerWriteValueField setEnabled:[Gretina4AFPGARegisters regIsWriteable:index]];
        [readRegisterButton setEnabled:     [Gretina4AFPGARegisters regIsReadable:index]];
        [registerStatusField setStringValue:@""];
     }
}
- (void) selectedChannelChanged:(NSNotification*)aNote
{
    [selectedChannelField setIntegerValue: [model selectedChannel]];
}

- (void) registerWriteValueChanged:(NSNotification*)aNote
{
    [registerWriteValueField setIntValue: (int)[model registerWriteValue]];
}

- (void) spiWriteValueChanged:(NSNotification*)aNote
{
    [spiWriteValueField setIntValue: (int)[model spiWriteValue]];
}

- (void) diagnosticsEnabledChanged:(NSNotification*)aNote
{
    [diagnosticsEnabledCB setIntValue: [model diagnosticsEnabled]];
}

- (void) aHitCountChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
         [[aHitCountMatrix cellWithTag:i] setIntegerValue:(int)[model aHitCount:i]];
    }
}

- (void) droppedEventCountChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [[droppedEventCountMatrix cellWithTag:i] setIntegerValue:[model droppedEventCount:i]];
    }
}

- (void) discCountChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [[discriminatorCountMatrix cellWithTag:i] setIntegerValue:[model discCount:i]];
    }
}

- (void) acceptedEventCountChanged:(NSNotification*)aNote
{
    int i;
    for(i=0;i<kNumGretina4AChannels;i++){
        [[acceptedEventCountMatrix cellWithTag:i] setIntegerValue:[model acceptedEventCount:i]];
    }
}

#pragma mark •••firmware loading
- (void) fpgaDownInProgressChanged:(NSNotification*)aNote
{
    if([model downLoadMainFPGAInProgress])[loadFPGAProgress startAnimation:self];
    else [loadFPGAProgress stopAnimation:self];
}

- (void) fpgaDownProgressChanged:(NSNotification*)aNote
{
    [loadFPGAProgress setDoubleValue:(double)[model fpgaDownProgress]];
}

- (void) mainFPGADownLoadStateChanged:(NSNotification*)aNote
{
    [mainFPGADownLoadStateField setStringValue: [model mainFPGADownLoadState]];
}

- (void) fpgaFilePathChanged:(NSNotification*)aNote
{
    [fpgaFilePathField setStringValue: [[model fpgaFilePath] stringByAbbreviatingWithTildeInPath]];
}


#pragma mark •••rates
- (void) integrationChanged:(NSNotification*)aNotification
{
    ORRateGroup* theRateGroup = [aNotification object];
    if(aNotification == nil || [model waveFormRateGroup] == theRateGroup || [aNotification object] == model){
        double dValue = [[model waveFormRateGroup] integrationTime];
        [integrationStepper setDoubleValue:dValue];
        [integrationText setDoubleValue: dValue];
    }
}

- (void) scaleAction:(NSNotification*)aNotification
{
    if(aNotification == nil || [aNotification object] == [rate0 xAxis]){
        [model setMiscAttributes:[[rate0 xAxis]attributes] forKey:@"RateXAttributes"];
    };
    
    if(aNotification == nil || [aNotification object] == [totalRate xAxis]){
        [model setMiscAttributes:[[totalRate xAxis]attributes] forKey:@"TotalRateXAttributes"];
    };
    
    if(aNotification == nil || [aNotification object] == [timeRatePlot xAxis]){
        [model setMiscAttributes:[(ORAxis*)[timeRatePlot xAxis]attributes] forKey:@"TimeRateXAttributes"];
    };
    
    if(aNotification == nil || [aNotification object] == [timeRatePlot yAxis]){
        [model setMiscAttributes:[(ORAxis*)[timeRatePlot yAxis]attributes] forKey:@"TimeRateYAttributes"];
    };
    
}

- (void) miscAttributesChanged:(NSNotification*)aNote
{
    NSString*				key = [[aNote userInfo] objectForKey:ORMiscAttributeKey];
    NSMutableDictionary* attrib = [model miscAttributesForKey:key];
    
    if(aNote == nil || [key isEqualToString:@"RateXAttributes"]){
        if(aNote==nil)attrib = [model miscAttributesForKey:@"RateXAttributes"];
        if(attrib){
            [[rate0 xAxis] setAttributes:attrib];
            [rate0 setNeedsDisplay:YES];
            [[rate0 xAxis] setNeedsDisplay:YES];
            [rateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
        }
    }
    if(aNote == nil || [key isEqualToString:@"TotalRateXAttributes"]){
        if(aNote==nil)attrib = [model miscAttributesForKey:@"TotalRateXAttributes"];
        if(attrib){
            [[totalRate xAxis] setAttributes:attrib];
            [totalRate setNeedsDisplay:YES];
            [[totalRate xAxis] setNeedsDisplay:YES];
            [totalRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
        }
    }
    if(aNote == nil || [key isEqualToString:@"TimeRateXAttributes"]){
        if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateXAttributes"];
        if(attrib){
            [(ORAxis*)[timeRatePlot xAxis] setAttributes:attrib];
            [timeRatePlot setNeedsDisplay:YES];
            [[timeRatePlot xAxis] setNeedsDisplay:YES];
        }
    }
    if(aNote == nil || [key isEqualToString:@"TimeRateYAttributes"]){
        if(aNote==nil)attrib = [model miscAttributesForKey:@"TimeRateYAttributes"];
        if(attrib){
            [(ORAxis*)[timeRatePlot yAxis] setAttributes:attrib];
            [timeRatePlot setNeedsDisplay:YES];
            [[timeRatePlot yAxis] setNeedsDisplay:YES];
            [timeRateLogCB setState:[[attrib objectForKey:ORAxisUseLog] boolValue]];
        }
    }
}

- (void) updateTimePlot:(NSNotification*)aNote
{
    if(!aNote || ([aNote object] == [[model waveFormRateGroup]timeRate])){
        [timeRatePlot setNeedsDisplay:YES];
    }
}
- (void) waveFormRateChanged:(NSNotification*)aNote
{
    ORRate* theRateObj = [aNote object];
    [[rateTextFields cellWithTag:[theRateObj tag]] setFloatValue: [theRateObj rate]];
    [rate0 setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)aNotification
{
    ORRateGroup* theRateObj = [aNotification object];
    if(aNotification == nil || [model waveFormRateGroup] == theRateObj){
        
        [totalRateText setFloatValue: [theRateObj totalRate]];
        [totalRate setNeedsDisplay:YES];
    }
}

- (void) rateGroupChanged:(NSNotification*)aNote
{
    [self registerRates];
}


#pragma mark •••SerDes and Clock Distribution
- (void) updateClockLocked
{
    if([model clockSource] == 1) [clockLockedField setStringValue:@""];
    else [clockLockedField setStringValue:[model locked]?@"":@"NOT Locked"];
}
//single values
- (void) forceFullCardInitChanged:  (NSNotification*)aNote  { [forceFullCardInitCB setIntValue:[model forceFullCardInit]];      }
- (void) initSerDesStateChanged:    (NSNotification*)aNote  { [initSerDesStateField setStringValue:[model serDesStateName]];    }
- (void) userPackageDataChanged:    (NSNotification*)aNote  { [userPackageDataField setIntegerValue:[model userPackageData]];       }
- (void) windowCompMinChanged:      (NSNotification*)aNote  { [windowCompMinField   setIntValue:[model windowCompMin]];         }
- (void) windowCompMaxChanged:      (NSNotification*)aNote  { [windowCompMaxField   setIntValue:[model windowCompMax]];         }
- (void) rawDataLengthChanged:      (NSNotification*)aNote  { [rawDataLengthField   setIntValue:[model rawDataLength]];         }
- (void) rawDataWindowChanged:      (NSNotification*)aNote  { [rawDataWindowField   setIntValue:[model rawDataWindow]];         }
- (void) baselineDelayChanged:      (NSNotification*)aNote  { [baselineDelayField   setIntValue:[model baselineDelay]];         }
- (void) trackingSpeedChanged:      (NSNotification*)aNote  { [trackingSpeedField   setIntValue:[model trackingSpeed]];         }
- (void) p2WindowChanged:           (NSNotification*)aNote  { [p2WindowField        setIntValue:[model p2Window]];              }
- (void) peakSensitivityChanged:    (NSNotification*)aNote  { [peakSensitivityField setIntValue:[model peakSensitivity]];       }
- (void) downSampleHoldOffTimeChanged:(NSNotification*)aNote{ [downSampleHoldOffTimeField setIntValue:[model downSampleHoldOffTime]];  }
- (void) holdOffTimeChanged:        (NSNotification*)aNote  { [holdOffTimeField     setIntValue:[model holdOffTime]];           }
- (void) autoModeChanged:           (NSNotification*)aNote  { [autoModeCB           setIntValue:[model autoMode]];              }
- (void) vetoGateWidthChanged:      (NSNotification*)aNote  { [vetoGateWidthField   setIntValue:[model vetoGateWidth]];         }
- (void) triggerConfigChanged:      (NSNotification*)aNote  { [triggerConfigPU selectItemAtIndex:[model triggerConfig]];        }
- (void) downSamplePauseEnableChanged:(NSNotification*)aNote
{
    [downSamplePauseEnableCB    setState:   [model downSamplePauseEnable]];
    [self settingsLockChanged:nil];
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
    [clockSourcePU selectItemAtIndex: [model clockSource]];
    [self updateClockLocked];
}
//following are non-implemented values
- (void) acqDcmCtrlStatusChanged:   (NSNotification*)aNote  {}
- (void) acqDcmLockChanged:         (NSNotification*)aNote  {}
- (void) acqDcmResetChanged:        (NSNotification*)aNote  {}
- (void) acqPhShiftOverflowChanged: (NSNotification*)aNote  {}
- (void) acqDcmClockStoppedChanged: (NSNotification*)aNote  {}
- (void) adcDcmCtrlStatusChanged:   (NSNotification*)aNote  {}
- (void) adcDcmLockChanged:         (NSNotification*)aNote  {}
- (void) adcDcmResetChanged:        (NSNotification*)aNote  {}
- (void) adcPhShiftOverflowChanged: (NSNotification*)aNote  {}
- (void) adcDcmClockStoppedChanged: (NSNotification*)aNote  {}
- (void) dacChannelSelectChanged:   (NSNotification*)aNote  {}
- (void) dacAttenuationChanged:     (NSNotification*)aNote  {}
- (void) ilaConfigChanged:          (NSNotification*)aNote  {}
- (void) diagMuxControlChanged:     (NSNotification*)aNote  {}
- (void) diagInputChanged:          (NSNotification*)aNote  {}
- (void) diagChannelEventSelChanged:(NSNotification*)aNote  {}
- (void) rj45SpareIoMuxSelChanged:  (NSNotification*)aNote  {}
- (void) rj45SpareIoDirChanged:     (NSNotification*)aNote  {}
- (void) ledStatusChanged:          (NSNotification*)aNote  {}
- (void) diagIsyncChanged:          (NSNotification*)aNote  {}
- (void) serdesSmLostLockChanged:   (NSNotification*)aNote  {}
- (void) overflowFlagChanChanged:   (NSNotification*)aNote  {}
- (void) codeRevisionChanged:       (NSNotification*)aNote  {}
- (void) codeDateChanged:           (NSNotification*)aNote  {}
- (void) phaseErrorCountChanged:    (NSNotification*)aNote  {}
- (void) serdesPhaseValueChanged:   (NSNotification*)aNote  {}
- (void) tSErrCntCtrlChanged:       (NSNotification*)aNote  {}
- (void) tSErrorCountChanged:       (NSNotification*)aNote  {}
- (void) ahitCountChanged:          (NSNotification*)aNote  {}
- (void) auxIoReadChanged:          (NSNotification*)aNote  {}
- (void) auxIoWriteChanged:         (NSNotification*)aNote  {}
- (void) auxIoConfigChanged:        (NSNotification*)aNote  {}
- (void) sdPemChanged:              (NSNotification*)aNote  {}
- (void) sdSmLostLockFlagChanged:   (NSNotification*)aNote  {}
- (void) adcConfigChanged:          (NSNotification*)aNote  {}
- (void) configMainFpgaChanged:     (NSNotification*)aNote  {}
- (void) vmeStatusChanged:          (NSNotification*)aNote  {}
- (void) overVoltStatChanged:       (NSNotification*)aNote  {}
- (void) underVoltStatChanged:      (NSNotification*)aNote  {}
- (void) temp0SensorChanged:        (NSNotification*)aNote  {}
- (void) temp1SensorChanged:        (NSNotification*)aNote  {}
- (void) temp2SensorChanged:        (NSNotification*)aNote  {}
- (void) clkSelectChanged:          (NSNotification*)aNote  {}
- (void) clkSelect1Changed:         (NSNotification*)aNote  {}
- (void) flashModeChanged:          (NSNotification*)aNote  {}
- (void) serialNumChanged:          (NSNotification*)aNote  {}
- (void) boardRevNumChanged:        (NSNotification*)aNote  {}
- (void) vhdlVerNumChanged:         (NSNotification*)aNote  {}
- (void) fifoAccessChanged:         (NSNotification*)aNote  {}

//channel related values
- (void) forceFullInitChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[forceFullInitMatrix cellWithTag:chan] setState:[model forceFullInit:chan]];
    }
}

- (void) doHwCheckChanged:(NSNotification*)aNote
{
   	[doHwCheckButton setIntValue: [model doHwCheck]];
}
- (void) extDiscrSrcChanged:(NSNotification*)aNote
{
    int chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[extDiscrSrcMatrix cellAtRow:chan column:0] selectItemAtIndex:([model extDiscriminatorSrc]>>(chan*3)) & 0x7];
    }
}

- (void) extDiscrModeChanged:(NSNotification*)aNote
{
    int chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[extDiscrModeMatrix cellAtRow:chan column:0] selectItemAtIndex:([model extDiscriminatorMode]>>(chan*2)) & 0x3];
    }
}

- (void) pileupWaveformOnlyModeChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[pileupWaveformOnlyModeMatrix cellWithTag:chan] setIntValue:[model pileupWaveformOnlyMode:chan]];
    }
}

- (void) pileupExtensionModeChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[pileupExtensionModeMatrix cellWithTag:chan] setIntValue:[model pileupExtensionMode:chan]];
    }
}

- (void) discCountModeChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[discCountModeMatrix cellWithTag:chan] setIntValue:[model discCountMode:chan]];
    }
}

- (void) aHitCountModeChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[aHitCountModeMatrix cellWithTag:chan] setIntValue:[model aHitCountMode:chan]];
    }
}

- (void) eventCountModeChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[eventCountModeMatrix cellWithTag:chan] setIntValue:[model eventCountMode:chan]];
    }
}

- (void) droppedEventCountModeChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[droppedEventCountModeMatrix cellWithTag:chan] setIntValue:[model droppedEventCountMode:chan]];
    }
}

//- (void) writeFlagChanged:(NSNotification*)aNote
//{
//    [writeFlagCB  setIntValue:[model writeFlag]];
//}

- (void) decimationFactorChanged:(NSNotification*)aNote
{
    int chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[decimationFactorMatrix cellAtRow:chan column:0] selectItemAtIndex:[model decimationFactor:chan]];
    }
}
- (void) triggerPolarityChanged:(NSNotification*)aNote;
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[triggerPolarityMatrix cellAtRow:chan column:0] selectItemAtIndex:[model triggerPolarity:chan]];
    }
}



- (void) pileupModeChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[pileupModeMatrix cellWithTag:chan] setIntValue:[model pileupMode:chan]];
    }
}

- (void) enabledChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[enabledMatrix cellWithTag:chan] setIntValue:[model enabled:chan]];
        [[enabled2Matrix cellWithTag:chan] setIntValue:[model enabled:chan]];
    }
}

- (void) ledThresholdChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[ledThresholdMatrix cellWithTag:chan] setIntValue:[model ledThreshold:chan]];
    }
}


- (void) p1WindowChanged:(NSNotification*)aNote
{
    unsigned short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[p1WindowMatrix cellWithTag:chan] setIntValue:[model p1Window:chan]];
    }
 }

- (void) dWindowChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[dWindowMatrix cellWithTag:chan] setIntValue:[model dWindow:chan]];
    }
}

- (void) kWindowChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[kWindowMatrix cellWithTag:chan] setIntValue:[model kWindow:chan]];
    }
}

- (void) mWindowChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[mWindowMatrix cellWithTag:chan] setIntValue:[model mWindow:chan]];
    }
}

- (void) d3WindowChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[d3WindowMatrix cellWithTag:chan] setIntValue:[model d3Window:chan]];
    }
}

- (void) discWidthChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[discWidthMatrix cellWithTag:chan] setIntValue:[model discWidth:chan]];
    }
}

- (void) baselineStartChanged:(NSNotification*)aNote
{
    short chan;
    for(chan=0;chan<kNumGretina4AChannels;chan++){
        [[baselineStartMatrix cellWithTag:chan] setIntValue:[model baselineStart:chan]];
    }
}
- (void) firmwareStatusStringChanged:(NSNotification*)aNote
{
    [firmwareStatusStringField setStringValue: [model firmwareStatusString]];
}

#pragma mark •••Actions
- (IBAction) doHwCheckButtonAction:(id)sender;
{
    [model setDoHwCheck:[sender intValue]];
}
- (IBAction) compareHwNowAction:(id)sender
{
    [model checkBoard:YES];
}

- (IBAction) extDiscrSrcAction:(id)sender
{
    uint32_t regValue = [model extDiscriminatorSrc];
    unsigned short chan    = [sender selectedRow];
    uint32_t value   = (uint32_t)[[sender selectedCell] indexOfSelectedItem];
    regValue &= ~(0x00000007<<(chan*3));
    regValue |= ((value&0x7)<<(chan*3));
    [model setExtDiscriminatorSrc:regValue];
}

- (IBAction) extDiscrModeAction:(id)sender
{
    uint32_t regValue = [model extDiscriminatorMode];
    unsigned short chan    = [sender selectedRow];
    uint32_t value   = (uint32_t)[[sender selectedCell] indexOfSelectedItem];
    regValue &= ~(0x00000003<<(chan*2));
    regValue |= ((value&0x3)<<(chan*2));
    [model setExtDiscriminatorMode:regValue];
}


- (IBAction) userPackageDataAction:(id)sender
{
    [model setUserPackageData:[sender intValue]];
}

- (IBAction) windowCompMinAction:  (id)sender
{
    [model setWindowCompMin:[sender intValue]];
}

- (IBAction) windowCompMaxAction:  (id)sender
{
    [model setWindowCompMax:[sender intValue]];
}

- (IBAction) pileupWaveformOnlyModeAction:(id)sender
{
    [model setPileupWaveformOnlyMode:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) pileupExtensionModeAction:(id)sender
{
    [model setPileupExtensionMode:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) discCountModeAction:(id)sender
{
    [model setDiscCountMode:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) aHitCountModeAction:(id)sender
{
    [model setAHitCountMode:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) eventCountModeAction:(id)sender
{
    [model setEventCountMode:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) droppedEventCountModeAction:(id)sender
{
    [model setDroppedEventCountMode:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) decimationFactorAction:(id)sender
{
    [model setDecimationFactor:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) triggerPolarityAction:(id)sender
{
    [model setTriggerPolarity:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) pileupModeAction:(id)sender
{
    [model setPileupMode:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) enabledAction:(id)sender
{
    [model setEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) ledThresholdAction:(id)sender
{
    [model setLedThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) rawDataLengthAction:(id)sender
{
    [model setRawDataLength:[sender intValue]];
}

- (IBAction) rawDataWindowAction:(id)sender
{
    [model setRawDataWindow:[sender intValue]];
}

- (IBAction) discWidthAction:(id)sender
{
    [model setDiscWidth:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) baselineDelayAction:(id)sender
{
    [model setBaselineDelay:[sender intValue]];
}

- (IBAction) trackingSpeedAction:(id)sender
{
    [model setTrackingSpeed:[sender intValue]];
}

- (IBAction) p1WindowAction:(id)sender
{
    [model setP1Window:[[sender selectedCell] tag] withValue:[sender intValue]];
}
- (IBAction) dWindowAction:(id)sender
{
    [model setDWindow:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) kWindowAction:(id)sender
{
    [model setKWindow:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) mWindowAction:(id)sender
{
    [model setMWindow:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) d3WindowAction:(id)sender
{
    [model setD3Window:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) p2WindowAction:(id)sender
{
   [model setP2Window:[sender intValue]];
}

- (IBAction) baselineStartAction:(id)sender
{
    [model setBaselineStart:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) peakSensitivityAction:(id)sender;
{
    [model setPeakSensitivity:[sender intValue]];
}

- (IBAction) downSampleHoldOffTimeAction:(id)sender;
{
    [model setDownSampleHoldOffTime:[sender intValue]];
}

- (IBAction) downSampleHoldOffPauseEnableAction:(id)sender
{
    [model setDownSamplePauseEnable:[sender intValue]];
}

- (IBAction) clockSourceAction:(id)sender
{
    [model setClockSource:[sender indexOfSelectedItem]];
}

- (IBAction) holdOffTimeAction:(id)sender;
{
    [model setHoldOffTime:[sender intValue]];
}

- (IBAction) autoModeAction:(id)sender;
{
    [model setAutoMode:[sender boolValue]];
}

- (IBAction) vetoGateWidthAction:(id)sender
{
    [model setVetoGateWidth:[sender intValue]];
}

- (IBAction) loadThresholdsAction:(id)sender;
{
    [self endEditing];
    [model writeThresholds];
}

- (IBAction) diagnosticsClearAction:(id)sender
{
    [model clearDiagnosticsReport];
    NSLog(@"%@: Cleared Diagnostics Report\n",[model fullID]);
}

- (IBAction) diagnosticsReportAction:(id)sender
{
    [model printDiagnosticsReport];
}

- (IBAction) diagnosticsEnableAction:(id)sender
{
    [model setDiagnosticsEnabled:[sender intValue]];
    [self settingsLockChanged:nil]; //update buttons
}


- (IBAction) registerIndexPUAction:(id)sender
{
	 int index = (int)[sender indexOfSelectedItem];
	[model setRegisterIndex:index];
	[self setRegisterDisplay:index];
}

- (IBAction) forceFullCardInitAction:(id)sender;
{
    if([sender intValue] != [model forceFullCardInit]){
        [model setForceFullCardInit:[sender intValue]];
    }
}

- (IBAction) forceFullInitAction:(id)sender;
{
    if([sender intValue] != [model forceFullInit:[[sender selectedCell] tag]]){
        [model setForceFullInit:[[sender selectedCell] tag] withValue:[sender intValue]];
    }
}

- (IBAction) readCounters:(id)sender;
{
    [model readaHitCounts];
    [model readAcceptedEventCounts];
    [model readDroppedEventCounts];
    [model readDiscriminatorCounts];
}
- (IBAction) clearCounters:(id)sender
{
    [model clearCounters];
}

- (IBAction) readRegisterAction:(id)sender
{
	[self endEditing];
	uint32_t aValue = 0;
	unsigned int index = [model registerIndex];
	if (index < kNumberOfGretina4ARegisters) {
        uint32_t address   = [Gretina4ARegisters offsetforReg:index];
        NSString* chanString;
        if([Gretina4ARegisters hasChannels:index]){
            int chan = (int)[model selectedChannel];
            address += chan*0x04;
            chanString = [NSString stringWithFormat:@",%d",chan];
        }
        else chanString = @"";
        aValue = [model readFromAddress:address];

        NSLog(@"Gretina4A(%d,%d%@) %@: %u (0x%08x)\n",[model crateNumber],[model slot], chanString, [Gretina4ARegisters registerName:index],aValue,aValue);
	} 
	else {
		index -= kNumberOfGretina4ARegisters;
		aValue = [model readFPGARegister:index];	
		NSLog(@"Gretina4A(%d,%d) %@: %u (0x%08x)\n",[model crateNumber],[model slot], [Gretina4AFPGARegisters registerName:index],aValue,aValue);
	}
}

- (IBAction) writeRegisterAction:(id)sender
{
	[self endEditing];
	uint32_t aValue    = [model registerWriteValue];
	unsigned int index      = [model registerIndex];
    
	if (index < kNumberOfGretina4ARegisters) {
        uint32_t address   = [Gretina4ARegisters offsetforReg:index];
        NSString* chanString;
        if([Gretina4ARegisters hasChannels:index]){
            int chan = (int)[model selectedChannel];
            address += chan*0x04;
            chanString = [NSString stringWithFormat:@"%d",chan];
        }
        else chanString = @"*";
        [model writeToAddress:address aValue:aValue];
        NSLog(@"Wrote to Gretina4A(%d,%d,%@) %@: %u (0x%08x)\n",[model crateNumber],[model slot],chanString, [Gretina4ARegisters registerName:index],aValue,aValue);
	}
	else {
		index -= kNumberOfGretina4ARegisters;
		[model writeFPGARegister:index withValue:aValue];	
        NSLog(@"Wrote to Gretina4A(%d,%d) %@: %u (0x%08x)\n",[model crateNumber],[model slot], [Gretina4AFPGARegisters registerName:index],aValue,aValue);
	}
}
- (IBAction) selectedChannelAction:(id)sender
{
    [model setSelectedChannel:[sender intValue]];
}

- (IBAction) registerWriteValueAction:(id)sender
{
	[model setRegisterWriteValue:[sender intValue]];
}

- (IBAction) spiWriteValueAction:(id)sender
{
	[model setSPIWriteValue:[sender intValue]];
}

- (IBAction) writeSPIAction:(id)sender
{
	[self endEditing];
	uint32_t aValue = [model spiWriteValue];
	uint32_t readback = [model writeAuxIOSPI:aValue];
	NSLog(@"Gretina4A(%d,%d) writeSPI(%u) readback: (0x%0x)\n",[model crateNumber],[model slot], aValue, readback);
}


- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGretina4ASettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) registerLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGretina4ARegisterLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) resetBoard:(id) sender
{
    @try {
        [model resetBoard];
        NSLog(@"Reset Gretina4A Board (Slot %d <%p>)\n",[model slot],[model baseAddress]);
    }
	@catch(NSException* localException) {
        NSLog(@"Reset of Gretina4A Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4A Reset", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) initBoardAction:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];
        NSLog(@"Initialized Gretina4A (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Init of Gretina4A FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4A Init", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) fullInitBoardAction:(id)sender
{
    @try {
        [self endEditing];
        [model clearOldUserValues];
        [model initBoard];
        NSLog(@"Initialized Gretina4A (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
    @catch(NSException* localException) {
        NSLog(@"Init of Gretina4A FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4A Init", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readLiveTimeStamp:(id)sender
{
    uint64_t ts = [model readLiveTimeStamp];
    NSLog(@"Gretina4A (Slot %d <%p>) Live Timestamp: 0x%llx\n",[model slot],[model baseAddress],ts);

}

- (IBAction) readLatTimeStamp:(id)sender
{
    uint64_t ts = [model readLatTimeStamp];
    NSLog(@"Gretina4A (Slot %d <%p>) Lat Timestamp: 0x%llx\n",[model slot],[model baseAddress],ts);
    
}


- (IBAction) clearFIFO:(id)sender
{
    @try {  
        [model resetFIFO];
        NSLog(@"Gretina4A (Slot %d <%p>) FIFO reset\n",[model slot],[model baseAddress]);
    }
	@catch(NSException* localException) {
        NSLog(@"Clear of Gretina4A FIFO FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4A FIFO Clear", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model waveFormRateGroup]integrationTime]){
        [model setRateIntegrationTime:[sender doubleValue]];		
    }
}

- (IBAction) probeBoard:(id)sender
{
    [self endEditing];
    @try {
        unsigned short theID = [model readBoardIDReg];
        NSLog(@"Gretina BoardID (slot %d): 0x%x\n",[model slot],theID);
        if(theID == ([model baseAddress]>>16)){
            NSLog(@"VME slot matches the ORCA configuration\n");
            [model readFPGAVersions];
            [model checkFirmwareVersion:YES];
        }
        else {
            NSLogColor([NSColor redColor],@"Gretina Board 0x%x doesn't match dip settings 0x%x\n", theID, [model baseAddress]>>16);
            NSLogColor([NSColor redColor],@"Apparently it is not in the right slot in the ORCA configuration\n");
        }
    }
	@catch(NSException* localException) {
        NSLog(@"Probe Gretina4A Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Probe", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readStatus:(id)sender
{    
    [self endEditing];
    @try {
        NSLog(@"Gretina BoardID (slot %d): [0x%x] ID = 0x%x\n",[model slot],[model baseAddress],[model readBoardIDReg]);
    }
	@catch(NSException* localException) {
        NSLog(@"Probe Gretina4A Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Probe", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) downloadMainFPGAAction:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setPrompt:@"Select FPGA Binary File"];
    [openPanel beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            [model setFpgaFilePath:[[openPanel URL]path]];
            [model startDownLoadingMainFPGA];
        }
    }];
}

- (IBAction) stopLoadingMainFPGAAction:(id)sender   { [model stopDownLoadingMainFPGA];                      }
- (IBAction) dumpAllRegisters:(id)sender            { [model dumpAllRegisters];                             }
- (IBAction) snapShotRegistersAction:(id)sender     { [model snapShotRegisters];                            }
- (IBAction) compareToSnapShotAction:(id)sender     { [model compareToSnapShot];                            }
- (IBAction) triggerConfigAction:(id)sender         { [model setTriggerConfig:[sender indexOfSelectedItem]];}
- (IBAction) readFPGAVersions:(id)sender
{
    [model readFPGAVersions];
    [model readCodeRevision];
    [model readFPGAVersions];
}

- (IBAction) readVmeAuxStatus:(id)sender
{
    uint32_t status = [model readVmeAuxStatus];
    NSLog(@"Gretina4A %d Aux VME Status: 0x%08x\n",[model slot],status);
    NSLog(@"Power: %@\n",       ((status>>0)&01)?@"FAULT":@"OK");
    NSLog(@"Over Volt: %@\n",   ((status>>1)&01)?@"FAULT":@"OK");
    NSLog(@"Under Volt: %@\n",  ((status>>2)&01)?@"FAULT":@"OK");
    NSLog(@"Temp0: %@\n",       ((status>>3)&01)?@"FAULT":@"OK");
    NSLog(@"Temp1: %@\n",       ((status>>4)&01)?@"FAULT":@"OK");
    NSLog(@"Temp2: %@\n",       ((status>>5)&01)?@"FAULT":@"OK");
}

- (IBAction) dumpCounters:(id)sender
{
    [model dumpCounters];
}

- (IBAction) openPreampDialog:(id)sender
{
    [model openPreampDialog];
}

- (IBAction) softwareTriggerAction:(id)sender
{
    [model softwareTrigger];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:settingSize];
        [[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:registerTabSize];
        [[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:rateSize];
        [[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 3){
        [[self window] setContentView:blankView];
        [self resizeWindowToSize:firmwareTabSize];
        [[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 4){
        [[self window] setContentView:blankView];
        [[self window] setContentView:tabView];
    }
    
    NSString* key = [NSString stringWithFormat: @"orca.ORGretina4A%d.selectedtab",[model slot]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}

#pragma mark •••Data Source
- (double) getBarValue:(int)tag
{
	return [[[[model waveFormRateGroup]rates] objectAtIndex:tag] rate];
}

- (int) numberPointsInPlot:(id)aPlotter
{
	return (int)[[[model waveFormRateGroup]timeRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue;
{
	int count = (int)[[[model waveFormRateGroup]timeRate] count];
	int index = count-i-1;
	*yValue = [[[model waveFormRateGroup] timeRate] valueAtIndex:index];
	*xValue = [[[model waveFormRateGroup] timeRate] timeSampledAtIndex:index];
}
@end
