//-------------------------------------------------------------------------
//  ORGretina4Controller.m
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
#import <Cocoa/Cocoa.h>
#import "ORGretina4Controller.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORValueBar.h"
#import "ORTimeRate.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"

@implementation ORGretina4Controller

-(id)init
{
    self = [super initWithWindowNibName:@"Gretina4"];
    
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    settingSize     = NSMakeSize(830,510);
    rateSize		= NSMakeSize(790,340);
    registerTabSize	= NSMakeSize(400,330);
	firmwareTabSize = NSMakeSize(340,187);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
	polarityPU[0] = polarityPU0;
	polarityPU[1] = polarityPU1;
	polarityPU[2] = polarityPU2;
	polarityPU[3] = polarityPU3;
	polarityPU[4] = polarityPU4;
	polarityPU[5] = polarityPU5;
	polarityPU[6] = polarityPU6;
	polarityPU[7] = polarityPU7;
	polarityPU[8] = polarityPU8;
	polarityPU[9] = polarityPU9;
	
	triggerModePU[0] = triggerModePU0;
	triggerModePU[1] = triggerModePU1;
	triggerModePU[2] = triggerModePU2;
	triggerModePU[3] = triggerModePU3;
	triggerModePU[4] = triggerModePU4;
	triggerModePU[5] = triggerModePU5;
	triggerModePU[6] = triggerModePU6;
	triggerModePU[7] = triggerModePU7;
	triggerModePU[8] = triggerModePU8;
	triggerModePU[9] = triggerModePU9;

	// Setup register popup buttons
	[registerIndexPU removeAllItems];
	[registerIndexPU setAutoenablesItems:NO];
	int i;
	for (i=0;i<kNumberOfGretina4Registers;i++) {
        NSString* s = [NSString stringWithFormat:@"(0x%04x) %@",[model registerOffsetAt:i], [model registerNameAt:i]];
        
		[registerIndexPU insertItemWithTitle:s	atIndex:i];
		[[registerIndexPU itemAtIndex:i] setEnabled:![model displayRegisterOnMainPage:i] && ![model displayFPGARegisterOnMainPage:i]];
	}
	// And now the FPGA registers
	for (i=0;i<kNumberOfFPGARegisters;i++) {
        NSString* s = [NSString stringWithFormat:@"(0x%04x) %@",[model fpgaRegisterOffsetAt:i], [model fpgaRegisterNameAt:i]];
        
		[registerIndexPU insertItemWithTitle:s	atIndex:(i+kNumberOfGretina4Registers)];
	}
	
    NSString* key = [NSString stringWithFormat: @"orca.Gretina4%d.selectedtab",[model slot]];
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

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(baseAddressChanged:)
                         name : ORVmeIOCardBaseAddressChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORGretina4SettingsLock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORGretina4RegisterLock
                        object: nil];
	
    [notifyCenter addObserver:self selector:@selector(updateCardInfo:)
                         name:ORGretina4CardInfoUpdated 
                       object:model];
    
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORGretina4RateGroupChangedNotification
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];
	
    //a fake action for the scale objects
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
                     selector : @selector(noiseFloorChanged:)
                         name : ORGretina4NoiseFloorChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorOffsetChanged:)
                         name : ORGretina4ModelNoiseFloorOffsetChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(setFifoStateLabel)
                         name : ORGretina4ModelFIFOCheckChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorIntegrationChanged:)
                         name : ORGretina4ModelNoiseFloorIntegrationTimeChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledChanged:)
                         name : ORGretina4ModelEnabledChanged
                       object : model];
		
    [notifyCenter addObserver : self
                     selector : @selector(cfdEnabledChanged:)
                         name : ORGretina4ModelCFDEnabledChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(poleZeroEnabledChanged:)
                         name : ORGretina4ModelPoleZeroEnabledChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(poleZeroTauChanged:)
                         name : ORGretina4ModelPoleZeroMultChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pzTraceEnabledChanged:)
                         name : ORGretina4ModelPZTraceEnabledChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(debugChanged:)
                         name : ORGretina4ModelDebugChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pileUpChanged:)
                         name : ORGretina4ModelPileUpChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(polarityChanged:)
                         name : ORGretina4ModelPolarityChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(triggerModeChanged:)
                         name : ORGretina4ModelTriggerModeChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ledThresholdChanged:)
                         name : ORGretina4ModelLEDThresholdChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(cfdDelayChanged:)
                         name : ORGretina4ModelCFDDelayChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(cfdFractionChanged:)
                         name : ORGretina4ModelCFDFractionChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(cfdThresholdChanged:)
                         name : ORGretina4ModelCFDThresholdChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataDelayChanged:)
                         name : ORGretina4ModelDataDelayChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataLengthChanged:)
                         name : ORGretina4ModelDataLengthChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(fpgaFilePathChanged:)
                         name : ORGretina4ModelFpgaFilePathChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(mainFPGADownLoadStateChanged:)
                         name : ORGretina4ModelMainFPGADownLoadStateChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(fpgaDownProgressChanged:)
                         name : ORGretina4ModelFpgaDownProgressChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(fpgaDownInProgressChanged:)
                         name : ORGretina4ModelMainFPGADownLoadInProgressChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORGretina4ModelMainFPGADownLoadInProgressChanged
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORGretina4ModelMainFPGADownLoadInProgressChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(registerWriteValueChanged:)
                         name : ORGretina4ModelRegisterWriteValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(registerIndexChanged:)
                         name : ORGretina4ModelRegisterIndexChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(spiWriteValueChanged:)
                         name : ORGretina4ModelSPIWriteValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(downSampleChanged:)
                         name : ORGretina4ModelDownSampleChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histEMultiplierChanged:)
                         name : ORGretina4ModelHistEMultiplierChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(firmwareStatusStringChanged:)
                         name : ORGretina4ModelFirmwareStatusStringChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORGretina4ClockSourceChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(initSerDesStateChanged:)
                         name : ORGretina4ModelInitStateChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORGretina4LockChanged
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
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
    [self updateCardInfo:nil];
	[self enabledChanged:nil];
	[self cfdEnabledChanged:nil];
	[self poleZeroEnabledChanged:nil];
	[self poleZeroTauChanged:nil];
	[self pzTraceEnabledChanged:nil];
	[self debugChanged:nil];
	[self pileUpChanged:nil];
	[self polarityChanged:nil];
	[self triggerModeChanged:nil];
	[self ledThresholdChanged:nil];
	[self cfdDelayChanged:nil];
	[self cfdFractionChanged:nil];
	[self cfdThresholdChanged:nil];
	[self dataDelayChanged:nil];
	[self dataLengthChanged:nil];
	
    [self rateGroupChanged:nil];
    [self integrationChanged:nil];
    [self miscAttributesChanged:nil];
    [self totalRateChanged:nil];
    [self updateTimePlot:nil];
    [self waveFormRateChanged:nil];
	[self noiseFloorChanged:nil];
	[self noiseFloorIntegrationChanged:nil];
	[self noiseFloorOffsetChanged:nil];
		
	[self fpgaFilePathChanged:nil];
	[self mainFPGADownLoadStateChanged:nil];
	[self fpgaDownProgressChanged:nil];
	[self fpgaDownInProgressChanged:nil];

    [self registerLockChanged:nil];

	[self registerIndexChanged:nil];
	[self registerWriteValueChanged:nil];
	[self spiWriteValueChanged:nil];
	[self downSampleChanged:nil];
	[self histEMultiplierChanged:nil];
    
	[self firmwareStatusStringChanged:nil];
	[self clockSourceChanged:nil];
	[self initSerDesStateChanged:nil];
    [self lockChanged:nil];
}

#pragma mark ¥¥¥Interface Management

- (void) lockChanged:(NSNotification*) aNote
{
    [lockStateField setStringValue:[model locked]?@"Yes":@"No"];
    [self updateClockLocked];
}

- (void) updateClockLocked
{
    if([model clockSource] == 1) [clockLockedField setStringValue:@""];
    else [clockLockedField setStringValue:[model locked]?@"":@"NOT Locked"];
}

- (void) initSerDesStateChanged:(NSNotification*) aNote
{
    [initSerDesStateField setStringValue:[model serDesStateName]];
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
	[clockSourcePU selectItemAtIndex: [model clockSource]];
    [self updateClockLocked];
    
}
- (void) firmwareStatusStringChanged:(NSNotification*)aNote
{
	[firmwareStatusStringField setStringValue: [model firmwareStatusString]];
}

- (void) downSampleChanged:(NSNotification*)aNote
{
	[downSamplePU selectItemAtIndex:[model downSample]];
}

- (void) histEMultiplierChanged:(NSNotification*)aNote
{
	[histEMultiplierField setIntValue: [model histEMultiplier]];
}

- (void) registerWriteValueChanged:(NSNotification*)aNote
{
	[registerWriteValueField setIntegerValue: [model registerWriteValue]];
}

- (void) registerIndexChanged:(NSNotification*)aNote
{
	[registerIndexPU selectItemAtIndex: [model registerIndex]];
	[self setRegisterDisplay:[model registerIndex]];
}

- (void) spiWriteValueChanged:(NSNotification*)aNote
{
	[spiWriteValueField setIntegerValue: [model spiWriteValue]];
}

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

- (void) enabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[[enabledMatrix cellWithTag:i] setState:[model enabled:i]];
		[[enabled2Matrix cellWithTag:i] setState:[model enabled:i]];
	}
}


- (void) cfdEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[[cfdEnabledMatrix cellWithTag:i] setState:[model cfdEnabled:i]];
	}
}

- (void) poleZeroEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[[poleZeroEnabledMatrix cellWithTag:i] setState:[model poleZeroEnabled:i]];
	}
}

- (void) poleZeroTauChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[[poleZeroTauMatrix cellWithTag:i] setFloatValue:[model poleZeroTauConverted:i]];
	}
}

- (void) pzTraceEnabledChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[[pzTraceEnabledMatrix cellWithTag:i] setState:[model pzTraceEnabled:i]];
	}
}


- (void) debugChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[[debugMatrix cellWithTag:i] setState:[model debug:i]];
	}
}

- (void) pileUpChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[[pileUpMatrix cellWithTag:i] setState:[model pileUp:i]];
	}
}

- (void) polarityChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[polarityPU[i] selectItemAtIndex:[model polarity:i]];
	}
}

- (void) triggerModeChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[triggerModePU[i] selectItemAtIndex:[model triggerMode:i]];
	}
}

- (void) ledThresholdChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[[ledThresholdMatrix cellWithTag:i] setIntValue:[model ledThreshold:i]];
	}
}

- (void) cfdDelayChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[[cfdDelayMatrix cellWithTag:i] setFloatValue:[model cfdDelayConverted:i]];
	}
}

- (void) cfdFractionChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[[cfdFractionMatrix cellWithTag:i] setIntValue:[model cfdFraction:i]];
	}
}

- (void) cfdThresholdChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[[cfdThresholdMatrix cellWithTag:i] setFloatValue:[model cfdThresholdConverted:i]];
	}
}

- (void) dataDelayChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[[dataDelayMatrix cellWithTag:i] setFloatValue:[model dataDelayConverted:i]];
	}
}

- (void) dataLengthChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4Channels;i++){
		[[dataLengthMatrix cellWithTag:i] setFloatValue:[model traceLengthConverted:i]];
	}
}

- (void) noiseFloorIntegrationChanged:(NSNotification*)aNote
{
	[noiseFloorIntegrationField setFloatValue:[model noiseFloorIntegrationTime]];
}

- (void) noiseFloorChanged:(NSNotification*)aNote
{
	if([model noiseFloorRunning]){
		[noiseFloorProgress startAnimation:self];
	}
	else {
		[noiseFloorProgress stopAnimation:self];
	}
	[startNoiseFloorButton setTitle:[model noiseFloorRunning]?@"Stop":@"Start"];
}

- (void) noiseFloorOffsetChanged:(NSNotification*)aNote
{
	[noiseFloorOffsetField setIntValue:[model noiseFloorOffset]];
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

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORGretina4SettingsLock to:secure];
    [gSecurity setLock:ORGretina4RegisterLock to:secure];
    [settingLockButton setEnabled:secure];
    [registerLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGretina4SettingsLock];
    BOOL locked = [gSecurity isLocked:ORGretina4SettingsLock];
    BOOL downloading = [model downLoadMainFPGAInProgress];
	
	[self setFifoStateLabel];
	
    [settingLockButton setState: locked];
    [addressText setEnabled:!locked && !runInProgress && !downloading];
    [initButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [clearFIFOButton setEnabled:!locked && !runInProgress && !downloading];
	[noiseFloorButton setEnabled:!locked && !runInProgress && !downloading];
	[statusButton setEnabled:!lockedOrRunningMaintenance && !downloading];
	[probeButton setEnabled:!locked && !runInProgress && !downloading];
	[enabledMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[cfdEnabledMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[poleZeroEnabledMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[poleZeroTauMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[pzTraceEnabledMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[debugMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[pileUpMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[ledThresholdMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[cfdDelayMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[cfdFractionMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[cfdThresholdMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[dataDelayMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[dataLengthMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[cardInfoMatrix setEnabled:!lockedOrRunningMaintenance && !downloading];
	[resetButton setEnabled:!lockedOrRunningMaintenance && !downloading];
	[loadMainFPGAButton setEnabled:!locked && !downloading];
	[stopFPGALoadButton setEnabled:!locked && downloading];
	[downSamplePU setEnabled:!lockedOrRunningMaintenance && !downloading];
	[histEMultiplierField setEnabled:!lockedOrRunningMaintenance && !downloading];
	
	int i;
	for(i=0;i<kNumGretina4Channels;i++){
		[polarityPU[i] setEnabled:!lockedOrRunningMaintenance && !downloading];
		[triggerModePU[i] setEnabled:!lockedOrRunningMaintenance && !downloading];
	}		
}

- (void) registerLockChanged:(NSNotification*)aNotification
{
    
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGretina4RegisterLock];
    BOOL locked = [gSecurity isLocked:ORGretina4RegisterLock];
    BOOL downloading = [model downLoadMainFPGAInProgress];
		
    [registerLockButton setState: locked];
    [registerWriteValueField setEnabled:!lockedOrRunningMaintenance && !downloading];
    [registerIndexPU setEnabled:!lockedOrRunningMaintenance && !downloading];
    [readRegisterButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [writeRegisterButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [spiWriteValueField setEnabled:!lockedOrRunningMaintenance && !downloading];
    [writeSPIButton setEnabled:!lockedOrRunningMaintenance && !downloading];
}

- (void) setFifoStateLabel
{
	if(![gOrcaGlobals runInProgress]){
		[fifoState setTextColor:[NSColor blackColor]];
		[fifoState setStringValue:@"--"];
	}
	else {
		uint32_t val = [model fifoState];
		if((val & kGretina4FIFOAllFull)!=0) {
			[fifoState setTextColor:[NSColor redColor]];
			[fifoState setStringValue:@"Full"];
		} else if((val & kGretina4FIFOAlmostFull)!=0) {
			[fifoState setTextColor:[NSColor redColor]];
			[fifoState setStringValue:@"Almost Full"];
		} else {
			[fifoState setTextColor:[NSColor blackColor]];
            if((val & kGretina4FIFOEmpty)!=0)               [fifoState setStringValue:@"Empty"];
			else if((val & kGretina4FIFOAlmostEmpty)!=0)    [fifoState setStringValue:@"Almost Empty"];
            else                                            [fifoState setStringValue:@"Half Full"];
			
		}
	}
}


- (void) updateCardInfo:(NSNotification*)aNote
{
    int i;
    for(i=0;i<kNumGretina4CardParams;i++){
        [[cardInfoMatrix cellWithTag:i] setObjectValue:[model convertedCardValue:i]];
    }
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"Gretina4 Card (Slot %d)",[model slot]]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [slotField setIntValue: [model slot]];
    [[self window] setTitle:[NSString stringWithFormat:@"Gretina4 Card (Slot %d)",[model slot]]];
}

- (void) baseAddressChanged:(NSNotification*)aNote
{
    [addressText setIntegerValue: [model baseAddress]];
}

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

- (void) setRegisterDisplay:(unsigned int)index
{
	if (index < kNumberOfGretina4Registers) {
		if (![model displayRegisterOnMainPage:index]) {
			[writeRegisterButton setEnabled:[model canWriteRegister:index]];
			[registerWriteValueField setEnabled:[model canWriteRegister:index]];
			[readRegisterButton setEnabled:[model canReadRegister:index]];
			[registerStatusField setStringValue:@""];
		} else {
			[writeRegisterButton setEnabled:NO];
			[registerWriteValueField setEnabled:NO];
			[readRegisterButton setEnabled:NO];
			[registerStatusField setTextColor:[NSColor redColor]];
			[registerStatusField setStringValue:@"Set value in Basic Ops."];
		}
	} 
	else {
		if (![model displayFPGARegisterOnMainPage:index]) {
			index -= kNumberOfGretina4Registers;
			[writeRegisterButton setEnabled:[model canWriteFPGARegister:index]];
			[registerWriteValueField setEnabled:[model canWriteFPGARegister:index]];
			[readRegisterButton setEnabled:[model canReadFPGARegister:index]];
			[registerStatusField setStringValue:@""];
		} else {
			[writeRegisterButton setEnabled:NO];
			[registerWriteValueField setEnabled:NO];
			[readRegisterButton setEnabled:NO];
			[registerStatusField setTextColor:[NSColor redColor]];
			[registerStatusField setStringValue:@"Set value in Basic Ops."];
		}
	}
	
}

#pragma mark ¥¥¥Actions
- (IBAction) downSampleAction:(id)sender
{
	if([sender indexOfSelectedItem] != [model downSample]){
		[model setDownSample:(int)[sender indexOfSelectedItem]];
	}
}

- (IBAction) histEMultiplierAction:(id)sender
{
	[model setHistEMultiplier:[sender intValue]];
}

- (IBAction) clockSourceAction:(id)sender
{
	[model setClockSource:[sender indexOfSelectedItem]];
}
- (IBAction) registerIndexPUAction:(id)sender
{
	int index = (int)[sender indexOfSelectedItem];
	[model setRegisterIndex:index];
	[self setRegisterDisplay:index];
}

- (IBAction) enabledAction:(id)sender
{
	if([sender intValue] != [model enabled:[[sender selectedCell] tag]]){
		[model setEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) cfdEnabledAction:(id)sender
{
	if([sender intValue] != [model cfdEnabled:[[sender selectedCell] tag]]){
		[model setCFDEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) poleZeroEnabledAction:(id)sender
{
	if([sender intValue] != [model poleZeroEnabled:[[sender selectedCell] tag]]){
		[model setPoleZeroEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) poleZeroTauAction:(id)sender
{
	if([sender intValue] != [model poleZeroTauConverted:[[sender selectedCell] tag]]){
		[model setPoleZeroTauConverted:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}
- (IBAction) pzTraceEnabledAction:(id)sender
{
	if([sender intValue] != [model pzTraceEnabled:[[sender selectedCell] tag]]){
		[model setPZTraceEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) debugAction:(id)sender
{
	if([sender intValue] != [model debug:[[sender selectedCell] tag]]){
		[model setDebug:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) pileUpAction:(id)sender
{
	if([sender intValue] != [model pileUp:[[sender selectedCell] tag]]){
		[model setPileUp:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) polarityAction:(id)sender
{
	if([sender indexOfSelectedItem] != [model polarity:[sender tag]]){
		[model setPolarity:(int)[sender tag] withValue:(int)[sender indexOfSelectedItem]];
	}
}

- (IBAction) triggerModeAction:(id)sender
{
	if([sender indexOfSelectedItem] != [model triggerMode:[sender tag]]){
		[model setTriggerMode:(int)[sender tag] withValue:(int)[sender indexOfSelectedItem]];
	}
}

- (IBAction) ledThresholdAction:(id)sender
{
	if([sender intValue] != [model ledThreshold:[[sender selectedCell] tag]]){
		[model setLEDThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) cfdFractionAction:(id)sender
{
	if([sender intValue] != [model cfdFraction:[[sender selectedCell] tag]]){
		[model setCFDFraction:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) cfdDelayAction:(id)sender
{
	if([sender intValue] != [model cfdDelay:[[sender selectedCell] tag]]){
		[model setCFDDelayConverted:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}

- (IBAction) cfdThresholdAction:(id)sender
{
	if([sender intValue] != [model cfdThreshold:[[sender selectedCell] tag]]){
		[model setCFDThresholdConverted:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}

- (IBAction) dataDelayAction:(id)sender
{
	if([sender intValue] != [model dataDelay:[[sender selectedCell] tag]]){
		[model setDataDelayConverted:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}

- (IBAction) dataLengthAction:(id)sender
{
	if([sender intValue] != [model dataLength:[[sender selectedCell] tag]]){
		[model setTraceLengthConverted:[[sender selectedCell] tag] withValue:[sender floatValue]];
	}
}

-(IBAction) noiseFloorOffsetAction:(id)sender
{
    if([sender intValue] != [model noiseFloorOffset]){
        [model setNoiseFloorOffset:[sender intValue]];
    }
}

- (IBAction) noiseFloorIntegrationAction:(id)sender
{
    if([sender floatValue] != [model noiseFloorIntegrationTime]){
        [model setNoiseFloorIntegrationTime:[sender floatValue]];
    }
}

- (IBAction) baseAddressAction:(id)sender
{
    if([sender intValue] != [model baseAddress]){
        [model setBaseAddress:[sender intValue]];
    }
}

- (IBAction) readRegisterAction:(id)sender
{
	[self endEditing];
	uint32_t aValue = 0;
	unsigned int index = [model registerIndex];
	if (index < kNumberOfGretina4Registers) {
		aValue = [model readRegister:index];
		NSLog(@"Gretina4(%d,%d) %@: %u (0x%0x)\n",[model crateNumber],[model slot], [model registerNameAt:index],aValue,aValue);
	} 
	else {
		index -= kNumberOfGretina4Registers;
		aValue = [model readFPGARegister:index];	
		NSLog(@"Gretina4(%d,%d) %@: %u (0x%0x)\n",[model crateNumber],[model slot], [model fpgaRegisterNameAt:index],aValue,aValue);
	}
	
}

- (IBAction) writeRegisterAction:(id)sender
{
	[self endEditing];
	uint32_t aValue = [model registerWriteValue];
	unsigned int index = [model registerIndex];
	if (index < kNumberOfGretina4Registers) {
		[model writeRegister:index withValue:aValue];
	} 
	else {
		index -= kNumberOfGretina4Registers;
		[model writeFPGARegister:index withValue:aValue];	
	}
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
	NSLog(@"Gretina4(%d,%d) writeSPI(%u) readback: (0x%0x)\n",[model crateNumber],[model slot], aValue, readback);
}


- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGretina4SettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) registerLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGretina4RegisterLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) resetBoard:(id) sender
{
    @try {
        [model resetBoard];
        NSLog(@"Reset Gretina4 Board (Slot %d <%p>)\n",[model slot],[model baseAddress]);
    }
	@catch(NSException* localException) {
        NSLog(@"Reset of Gretina4 Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4 Reset", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) initBoardAction:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard:false];		//initialize and load hardware, but don't enable channels
        NSLog(@"Initialized Gretina4 (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Init of Gretina4 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4 Init", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) clearFIFO:(id)sender
{
    @try {  
        [model clearFIFO];
        NSLog(@"Gretina4 (Slot %d <%p>) FIFO cleared\n",[model slot],[model baseAddress]);
    }
	@catch(NSException* localException) {
        NSLog(@"Clear of Gretina4 FIFO FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4 FIFO Clear", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) cardInfoAction:(id) sender
{
    int index = (int)[[sender selectedCell] tag];
    id theRawValue = [model rawCardValue:index value:[sender objectValue]];
    [model cardInfo:index setObject: theRawValue];
}

- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model waveFormRateGroup]integrationTime]){
        [model setRateIntegrationTime:[sender doubleValue]];		
    }
}

-(IBAction)probeBoard:(id)sender
{
    [self endEditing];
    @try {
        unsigned short theID = [model readBoardID];
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
        NSLog(@"Probe Gretina4 Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Probe", @"OK", nil, nil,
                        localException);
    }

}

- (IBAction) openNoiseFloorPanel:(id)sender
{
	[self endEditing];
    [[self window] beginSheet:noiseFloorPanel completionHandler:nil];
}

- (IBAction) closeNoiseFloorPanel:(id)sender
{
    [noiseFloorPanel orderOut:nil];
    [NSApp endSheet:noiseFloorPanel];
}

- (IBAction) findNoiseFloors:(id)sender
{
	[noiseFloorPanel endEditingFor:nil];		
    @try {
        NSLog(@"Gretina (slot %d) Finding LED Thresholds \n",[model slot]);
		[model findNoiseFloors];
    }
	@catch(NSException* localException) {
        NSLog(@"LED Threshold Finder for Gretina4 Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed LED Threshold finder", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) readStatus:(id)sender
{    
    [self endEditing];
    @try {
        NSLog(@"Gretina BoardID (slot %d): [0x%x] ID = 0x%x\n",[model slot],[model baseAddress],[model readBoardID]);
        int chan;
        for(chan = 0;chan<kNumGretina4Channels;chan++){
            uint32_t value = [model readControlReg:chan];
            NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"chan: %d Enabled: %@ Debug: %@  PileUp: %@ CFD: %@ Pole-zero: %@ Polarity: 0x%02x TriggerMode: 0x%02x\n",
                      chan, 
                      (value&0x1)?@"[YES]":@"[ NO]",		//enabled
                      ((value>>1)&0x1)?@"[YES]":@"[ NO]",	//debug
                      ((value>>2)&0x1)?@"[YES]":@"[ NO]", //pileup
                      ((value>>12)&0x1)?@"[YES]":@"[ NO]", //CFD
                      ((value>>13)&0x1)?@"[YES]":@"[ NO]", //pole-zero
                      (value>>10)&0x3, (value>>3)&0x3);
        }
        unsigned short fifoStatus = [model readFifoState];
        if(fifoStatus == kFull)			    NSLog(@"FIFO = Full\n");
        else if(fifoStatus == kAlmostFull)	NSLog(@"FIFO = Almost Full\n");
        else if(fifoStatus == kEmpty)		NSLog(@"FIFO = Empty\n");
        else if(fifoStatus == kAlmostEmpty)	NSLog(@"FIFO = Almost Empty\n");
        else if(fifoStatus == kHalfFull)	NSLog(@"FIFO = Half Full\n");
		
		NSLog(@"External Window: %g us\n", 0.01*[model readExternalWindow]);
		NSLog(@"Pileup Window: %g us\n", 0.01*[model readPileUpWindow]);
		NSLog(@"Noise Window: %g ns\n", 10.*[model readNoiseWindow]);
		NSLog(@"Ext Trig Length: %g us\n", 0.01*[model readExtTrigLength]);
		NSLog(@"Collection: %g us\n", 0.01*[model readCollectionTime]);
		NSLog(@"Integration Time: %g us\n", 0.01*[model readIntegrationTime]);
		NSLog(@"Down sample: x%d\n", (int) pow(2,[model readDownSample]));
        
    }
	@catch(NSException* localException) {
        NSLog(@"Probe Gretina4 Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Probe", @"OK", nil, nil,
                        localException);
    }
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
		[self resizeWindowToSize:rateSize];
		[[self window] setContentView:tabView];
    }     
	else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:registerTabSize];
		[[self window] setContentView:tabView];
    }	
	else if([tabView indexOfTabViewItem:tabViewItem] == 3){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:firmwareTabSize];
		[[self window] setContentView:tabView];
    }  
	
    NSString* key = [NSString stringWithFormat: @"orca.ORGretina4%d.selectedtab",[model slot]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
	
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

- (IBAction) stopLoadingMainFPGAAction:(id)sender
{
	[model stopDownLoadingMainFPGA];
}

#pragma mark ¥¥¥Data Source
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
