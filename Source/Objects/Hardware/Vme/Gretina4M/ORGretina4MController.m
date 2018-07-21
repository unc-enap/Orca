//-------------------------------------------------------------------------
//  ORGretina4MController.m
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
#import "ORGretina4MController.h"
#import "ORRateGroup.h"
#import "ORRate.h"
#import "ORRunningAverage.h"
#import "ORValueBar.h"
#import "ORTimeRate.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"
#import "ORGretinaCntView.h"

@implementation ORGretina4MController

-(id)init
{
    self = [super initWithWindowNibName:@"Gretina4M"];
    
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
    settingSize     = NSMakeSize(950,460);
    rateSize		= NSMakeSize(790,340);
    registerTabSize	= NSMakeSize(400,490);
	firmwareTabSize = NSMakeSize(340,187);
	definitionsTabSize = NSMakeSize(1200,350);
    blankView = [[NSView alloc] init];
    
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	

	// Setup register popup buttons
	[registerIndexPU removeAllItems];
	[registerIndexPU setAutoenablesItems:NO];
    
	int i;
    for(i=0;i<kNumberOfGretina4MRegisters;i++){
        [[enabledMatrix cellAtRow:i column:0] setTag:i];
        [[easySelectMatrix cellAtRow:i column:0] setTag:i];
        [[trapEnabledMatrix cellAtRow:i column:0] setTag:i];
        [[poleZeroEnabledMatrix cellAtRow:i column:0] setTag:i];
        [[baselineRestoreEnabledMatrix cellAtRow:i column:0] setTag:i];
        [[poleZeroTauMatrix cellAtRow:i column:0] setTag:i];
        [[pzTraceEnabledMatrix cellAtRow:i column:0] setTag:i];
        [[pileUpMatrix cellAtRow:i column:0] setTag:i];
        [[presumEnabledMatrix cellAtRow:i column:0] setTag:i];
        [[ledThresholdMatrix cellAtRow:i column:0] setTag:i];
        [[tpolMatrix cellAtRow:i column:0] setTag:i];
        [[triggerModeMatrix cellAtRow:i column:0] setTag:i];
        [[ftCntMatrix cellAtRow:i column:0] setTag:i];
        [[mrpsrtMatrix cellAtRow:i column:0] setTag:i];
        [[mrpsdvMatrix cellAtRow:i column:0] setTag:i];
        [[chpsrtMatrix cellAtRow:i column:0] setTag:i];
        [[chpsdvMatrix cellAtRow:i column:0] setTag:i];
        [[prerecntMatrix cellAtRow:i column:0] setTag:i];
        [[postrecntMatrix cellAtRow:i column:0] setTag:i];
    }
	for (i=0;i<kNumberOfGretina4MRegisters;i++) {
        NSString* s = [NSString stringWithFormat:@"(0x%04x) %@",[model registerOffsetAt:i], [model registerNameAt:i]];
        
		[registerIndexPU insertItemWithTitle:s	atIndex:i];
		[[registerIndexPU itemAtIndex:i] setEnabled:![model displayRegisterOnMainPage:i] && ![model displayFPGARegisterOnMainPage:i]];
	}
	// And now the FPGA registers
	for (i=0;i<kNumberOfFPGARegisters;i++) {
        NSString* s = [NSString stringWithFormat:@"(0x%04x) %@",[model fpgaRegisterOffsetAt:i], [model fpgaRegisterNameAt:i]];

		[registerIndexPU insertItemWithTitle:s	atIndex:(i+kNumberOfGretina4MRegisters)];
	}

    NSString* key = [NSString stringWithFormat: @"orca.Gretina4M%d.selectedtab",[model slot]];
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
                         name : ORGretina4MSettingsLock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORGretina4MRegisterLock
                        object: nil];
	   
    [notifyCenter addObserver : self
                     selector : @selector(rateGroupChanged:)
                         name : ORGretina4MRateGroupChangedNotification
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
    
   /* [notifyCenter addObserver : self
                     selector : @selector(updateTimePlot:)
                         name : ORRunningverageChangedNotification
                       object : [[model waveFormRunningAverageGroup]timeRate]];
    */
    [notifyCenter addObserver : self
                     selector : @selector(integrationChanged:)
                         name : ORRateGroupIntegrationChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorChanged:)
                         name : ORGretina4MNoiseFloorChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorOffsetChanged:)
                         name : ORGretina4MNoiseFloorOffsetChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorIntegrationChanged:)
                         name : ORGretina4MNoiseFloorIntegrationTimeChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(forceFullInitChanged:)
                         name : ORGretina4MForceFullInitChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(forceFullInitCardChanged:)
                         name : ORGretina4MForceFullInitCardChanged
                       object : model];

    
    [notifyCenter addObserver : self
                     selector : @selector(enabledChanged:)
                         name : ORGretina4MEnabledChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(easySelectChanged:)
                         name : ORGretina4MEasySelectedChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(trapEnabledChanged:)
                         name : ORGretina4MTrapEnabledChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(poleZeroEnabledChanged:)
                         name : ORGretina4MPoleZeroEnabledChanged
                       object : model];
    
    [notifyCenter addObserver: self
                     selector: @selector(baselineRestoreEnabledChanged:)
                         name: ORGretina4MBaselineRestoreEnabledChanged
                       object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(poleZeroTauChanged:)
                         name : ORGretina4MPoleZeroMultChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pzTraceEnabledChanged:)
                         name : ORGretina4MPZTraceEnabledChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(presumEnabledChanged:)
                         name : ORGretina4MPresumEnabledChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(tpolChanged:)
                         name : ORGretina4MTpolChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(triggerModeChanged:)
                         name : ORGretina4MTriggerModeChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ledThresholdChanged:)
                         name : ORGretina4MLEDThresholdChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(trapThresholdChanged:)
                         name : ORGretina4ModelTrapThresholdChanged
                       object : model];

    
    [notifyCenter addObserver : self
                     selector : @selector(fpgaFilePathChanged:)
                         name : ORGretina4MFpgaFilePathChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(mainFPGADownLoadStateChanged:)
                         name : ORGretina4MMainFPGADownLoadStateChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(fpgaDownProgressChanged:)
                         name : ORGretina4MFpgaDownProgressChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(fpgaDownInProgressChanged:)
                         name : ORGretina4MMainFPGADownLoadInProgressChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORGretina4MMainFPGADownLoadInProgressChanged
                       object : nil];

	[notifyCenter addObserver : self
                     selector : @selector(registerLockChanged:)
                         name : ORGretina4MMainFPGADownLoadInProgressChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(registerWriteValueChanged:)
                         name : ORGretina4MRegisterWriteValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(registerIndexChanged:)
                         name : ORGretina4MRegisterIndexChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(spiWriteValueChanged:)
                         name : ORGretina4MSPIWriteValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(downSampleChanged:)
                         name : ORGretina4MDownSampleChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(clockSourceChanged:)
                         name : ORGretina4MClockSourceChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(clockPhaseChanged:)
                         name : ORGretina4MClockPhaseChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(externalWindowChanged:)
                         name : ORGretina4MExternalWindowChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(pileUpWindowChanged:)
                         name : ORGretina4MPileUpWindowChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pileUpChanged:)
                         name : ORGretina4MPileUpChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(extTrigLengthChanged:)
                         name : ORGretina4MExtTrigLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(collectionTimeChanged:)
                         name : ORGretina4MCollectionTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(integrateTimeChanged:)
                         name : ORGretina4MIntegrateTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(chpsdvChanged:)
                         name : ORGretina4MChpsdvChanged
						object: model];
 
    [notifyCenter addObserver : self
                     selector : @selector(mrpsrtChanged:)
                         name : ORGretina4MMrpsrtChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(ftCntChanged:)
                         name : ORGretina4MFtCntChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(mrpsdvChanged:)
                         name : ORGretina4MMrpsdvChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(chsrtChanged:)
                         name : ORGretina4MChpsrtChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(prerecntChanged:)
                         name : ORGretina4MPrerecntChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(postrecntChanged:)
                         name : ORGretina4MPostrecntChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(noiseWindowChanged:)
                         name : ORGretina4MNoiseWindowChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(firmwareStatusStringChanged:)
                         name : ORGretina4MModelFirmwareStatusStringChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(baselineRestoredDelayChanged:)
                         name : ORGretina4MModelBaselineRestoredDelayChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(diagnosticsEnabledChanged:)
                         name : ORVmeDiagnosticsEnabledChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(histEMultiplierChanged:)
                         name : ORGretina4MModelHistEMultiplierChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(initSerDesStateChanged:)
                         name : ORGretina4MModelInitStateChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORGretina4MLockChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORConnectionChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(doHwCheckChanged:)
                         name : ORGretina4MDoHwCheckChanged
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
    /*
    
    [notifyCenter removeObserver:self name:ORRunningAverageChangedNotification object:nil];
    
//    NSEnumerator* e_av = [[[model waveFormRunningAverageGroup] runningAverages] objectEnumerator];
//    id obj_av;
//    while(obj_av = [e_av nextObject]){
//    
//        [notifyCenter removeObserver:self name:ORRunningAverageChangedNotification object:obj_av];
//        
//        [notifyCenter addObserver : self
//                         selector : @selector(waveFormRunningAverageChanged:)
//                             name : ORRunningAverageChangedNotification
//                           object : obj_av];
//    }
    id obj_av=[model waveFormRunningAverageGroup];
    [notifyCenter addObserver : self
                     selector : @selector(waveFormRunningAverageChanged:)
                         name : ORRunningAverageChangedNotification
                       object : obj_av];*/

}


- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
    [self forceFullInitCardChanged:nil];
    [self forceFullInitChanged:nil];
    [self enabledChanged:nil];
	[self easySelectChanged:nil];
	[self trapEnabledChanged:nil];
	[self poleZeroEnabledChanged:nil];
	[self baselineRestoreEnabledChanged:nil];
	[self poleZeroTauChanged:nil];
	[self pzTraceEnabledChanged:nil];
	[self presumEnabledChanged:nil];
	[self tpolChanged:nil];
	[self triggerModeChanged:nil];
	[self ledThresholdChanged:nil];
	[self trapThresholdChanged:nil];
	[self pileUpChanged:nil];

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
	[self clockSourceChanged:nil];
    [self clockPhaseChanged:nil];
    
	[self externalWindowChanged:nil];
	[self pileUpWindowChanged:nil];
	[self extTrigLengthChanged:nil];
	[self collectionTimeChanged:nil];
	[self integrateTimeChanged:nil];
    
    [self chpsdvChanged:nil];
    [self mrpsrtChanged:nil];
    [self ftCntChanged:nil];
    [self mrpsdvChanged:nil];
    [self chsrtChanged:nil];
    [self prerecntChanged:nil];
    [self postrecntChanged:nil];
	[self noiseWindowChanged:nil];
	[self baselineRestoredDelayChanged:nil];
    [self diagnosticsEnabledChanged:nil];
    
	[self histEMultiplierChanged:nil];
    [self initSerDesStateChanged:nil];
    [self doHwCheckChanged:nil];
    [self lockChanged:nil];
}

#pragma mark •••Interface Management
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

- (void) doHwCheckChanged:(NSNotification*)aNote
{
   	[doHwCheckButton setIntValue: [model doHwCheck]];
}


- (void) initSerDesStateChanged:(NSNotification*) aNote
{
    [initSerDesStateField setStringValue:[model serDesStateName]];
}

- (void) histEMultiplierChanged:(NSNotification*)aNote
{
	[histEMultiplierField setIntValue: [model histEMultiplier]];
}
- (void) diagnosticsEnabledChanged:(NSNotification*)aNote
{
	[diagnosticsEnabledCB setIntValue: [model diagnosticsEnabled]];
}

- (void) baselineRestoredDelayChanged:(NSNotification*)aNote
{
	[baselineRestoredDelayField setFloatValue: [model BLRDelayConverted]];
}

- (void) firmwareStatusStringChanged:(NSNotification*)aNote
{
	[firmwareStatusStringField setStringValue: [model firmwareStatusString]];
}

- (void) noiseWindowChanged:(NSNotification*)aNote
{
	[noiseWindowField setFloatValue: [model noiseWindowConverted]];
}

- (void) pileUpChanged:(NSNotification*)aNote
{
	short i;
	for(i=0;i<kNumGretina4MChannels;i++){
		[[pileUpMatrix cellWithTag:i] setState:[model pileUp:i]];
	}
}
- (void) chpsdvChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[chpsdvMatrix cellAtRow:i column:0] selectItemAtIndex:[model chpsdv:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[chpsdvMatrix cellAtRow:chan column:0] selectItemAtIndex:[model chpsdv:chan]];
    }
}

- (void) mrpsrtChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[mrpsrtMatrix cellAtRow:i column:0] selectItemAtIndex:[model mrpsrt:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[mrpsrtMatrix cellAtRow:chan column:0] selectItemAtIndex:[model mrpsrt:chan]];
    }
}

- (void) ftCntChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[ftCntMatrix cellAtRow:i column:0] setIntValue:[model ftCnt:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[ftCntMatrix cellAtRow:chan column:0] setIntValue:[model ftCnt:chan]];
    }
}

- (void) mrpsdvChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[mrpsdvMatrix cellAtRow:i column:0] selectItemAtIndex:[model mrpsdv:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[mrpsdvMatrix cellAtRow:chan column:0] selectItemAtIndex:[model mrpsdv:chan]];
    }
}

- (void) chsrtChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[chpsrtMatrix cellAtRow:i column:0] selectItemAtIndex:[model chpsrt:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[chpsrtMatrix cellAtRow:chan column:0] selectItemAtIndex:[model chpsrt:chan]];
    }
}

- (void) prerecntChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[prerecntMatrix cellAtRow:i column:0] setIntValue:[model prerecnt:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[prerecntMatrix cellAtRow:chan column:0] setIntValue:[model prerecnt:chan]];
    }
}

- (void) postrecntChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[postrecntMatrix cellAtRow:i column:0] setIntValue:[model postrecnt:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[postrecntMatrix cellAtRow:chan column:0] setIntValue:[model postrecnt:chan]];
    }
}


- (void) integrateTimeChanged:(NSNotification*)aNote
{
	[integrateTimeField setFloatValue: [model integrateTimeConverted]];
}

- (void) collectionTimeChanged:(NSNotification*)aNote
{
	[collectionTimeField setFloatValue: [model collectionTimeConverted]];
}

- (void) extTrigLengthChanged:(NSNotification*)aNote
{
	[extTrigLengthField setFloatValue: [model extTrigLengthConverted]];
}

- (void) pileUpWindowChanged:(NSNotification*)aNote
{
	[pileUpWindowField setFloatValue: [model pileUpWindowConverted]];
}

- (void) externalWindowChanged:(NSNotification*)aNote
{
	[externalWindowField setFloatValue: [model externalWindowConverted]];
}

- (void) clockSourceChanged:(NSNotification*)aNote
{
	[clockSourcePU selectItemAtIndex: [model clockSource]];
    [self updateClockLocked];
}

- (void) clockPhaseChanged:(NSNotification*)aNote
{
    [clockPhasePU selectItemAtIndex: [model clockPhase]];
}

- (void) downSampleChanged:(NSNotification*)aNote
{
	[downSamplePU selectItemAtIndex:[model downSample]];
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
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[enabledMatrix cellWithTag:i] setState:[model enabled:i]];
            [[enabled2Matrix cellWithTag:i] setState:[model enabled:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[enabledMatrix cellWithTag:chan] setState:[model enabled:chan]];
        [[enabled2Matrix cellWithTag:chan] setState:[model enabled:chan]];
    }
}

- (void) forceFullInitCardChanged:(NSNotification*)aNote
{
    [forceFullInitCardButton setIntValue:[model forceFullInitCard]];
}


- (void) forceFullInitChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[forceFullInitMatrix cellWithTag:i] setState:[model forceFullInit:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[forceFullInitMatrix cellWithTag:chan] setState:[model forceFullInit:chan]];
    }
}

- (void) easySelectChanged:(NSNotification*)aNote
{
    short i;
    for(i=0;i<kNumGretina4MChannels;i++){
        [[easySelectMatrix cellWithTag:i] setState:[model easySelected:i]];
    }
    [dataWindowView initBugs];
    [dataWindowView setNeedsDisplay:YES];
}

- (void) trapEnabledChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[trapEnabledMatrix cellWithTag:i] setState:[model trapEnabled:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[trapEnabledMatrix cellWithTag:chan] setState:[model trapEnabled:chan]];
    }
    [self settingsLockChanged:nil];
}

- (void) poleZeroEnabledChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[poleZeroEnabledMatrix cellWithTag:i] setState:[model poleZeroEnabled:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[poleZeroEnabledMatrix cellWithTag:chan] setState:[model poleZeroEnabled:chan]];
    }
}

- (void) baselineRestoreEnabledChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[baselineRestoreEnabledMatrix cellWithTag:i] setState:[model baselineRestoreEnabled:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[baselineRestoreEnabledMatrix cellWithTag:chan] setState:[model baselineRestoreEnabled:chan]];
    }
    
    [self settingsLockChanged:nil];
}

- (void) poleZeroTauChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[poleZeroTauMatrix cellWithTag:i] setFloatValue:[model poleZeroTauConverted:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[poleZeroTauMatrix cellWithTag:chan] setFloatValue:[model poleZeroTauConverted:chan]];
    }
}

- (void) pzTraceEnabledChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[pzTraceEnabledMatrix cellWithTag:i] setState:[model pzTraceEnabled:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[pzTraceEnabledMatrix cellWithTag:chan] setState:[model pzTraceEnabled:chan]];
    }
}

- (void) presumEnabledChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[presumEnabledMatrix cellWithTag:i] setState:[model presumEnabled:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[presumEnabledMatrix cellWithTag:chan] setState:[model presumEnabled:chan]];
    }
    [self settingsLockChanged:nil];
}

- (void) tpolChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[tpolMatrix cellAtRow:i column:0] selectItemAtIndex:[model tpol:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[tpolMatrix cellAtRow:chan column:0] selectItemAtIndex:[model tpol:chan]];
    }
}

- (void) triggerModeChanged:(NSNotification*)aNote
{
    
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[triggerModeMatrix cellAtRow:i column:0] selectItemAtIndex:[model triggerMode:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[triggerModeMatrix cellAtRow:chan column:0] selectItemAtIndex:[model triggerMode:chan]];
    }
}

- (void) ledThresholdChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[ledThresholdMatrix cellWithTag:i] setIntValue:[model ledThreshold:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[ledThresholdMatrix cellWithTag:chan] setIntValue:[model ledThreshold:chan]];
    }
}

- (void) trapThresholdChanged:(NSNotification*)aNote
{
    if(aNote == nil){
        short i;
        for(i=0;i<kNumGretina4MChannels;i++){
            [[trapThresholdMatrix cellWithTag:i] setIntegerValue:[model trapThreshold:i]];
        }
    }
    else {
        int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
        [[trapThresholdMatrix cellWithTag:chan] setIntegerValue:[model trapThreshold:chan]];
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


- (void) totalRateChanged:(NSNotification*)aNote
{
	ORRateGroup* theRateObj = [aNote object];
	if(aNote == nil || [model waveFormRateGroup] == theRateObj){
		
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
    [gSecurity setLock:ORGretina4MSettingsLock to:secure];
    [gSecurity setLock:ORGretina4MRegisterLock to:secure];
    [settingLockButton setEnabled:secure];
    [registerLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    
    BOOL runInProgress              = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGretina4MSettingsLock];
    BOOL locked                     = [gSecurity isLocked:ORGretina4MSettingsLock];
    BOOL downloading                = [model downLoadMainFPGAInProgress];
	
    	
    [settingLockButton      setState: locked];
    [initButton             setEnabled:!lockedOrRunningMaintenance && !downloading];
    [fullInitButton         setEnabled:!lockedOrRunningMaintenance && !downloading];
    [initButton1            setEnabled:!lockedOrRunningMaintenance && !downloading];
    [clearFIFOButton        setEnabled:!locked && !runInProgress && !downloading];
	[noiseFloorButton       setEnabled:!locked && !runInProgress && !downloading];
	[statusButton           setEnabled:!lockedOrRunningMaintenance && !downloading];
	[probeButton            setEnabled:!locked && !runInProgress && !downloading];
	[poleZeroEnabledMatrix  setEnabled:!lockedOrRunningMaintenance && !downloading];
    [baselineRestoreEnabledMatrix  setEnabled:!lockedOrRunningMaintenance && !downloading];
	[poleZeroTauMatrix      setEnabled:!lockedOrRunningMaintenance && !downloading];
	[pzTraceEnabledMatrix   setEnabled:!lockedOrRunningMaintenance && !downloading];
	[pileUpMatrix           setEnabled:!lockedOrRunningMaintenance && !downloading];
	[presumEnabledMatrix    setEnabled:!lockedOrRunningMaintenance && !downloading];
	[enabledMatrix          setEnabled:!lockedOrRunningMaintenance && !downloading];
	[trapEnabledMatrix      setEnabled:!lockedOrRunningMaintenance && !downloading];
	[resetButton            setEnabled:!lockedOrRunningMaintenance && !downloading];
	[loadMainFPGAButton     setEnabled:!locked && !downloading];
	[stopFPGALoadButton     setEnabled:!locked && downloading];
    [downSamplePU           setEnabled:!lockedOrRunningMaintenance && !downloading];
    [clockSourcePU          setEnabled:!lockedOrRunningMaintenance && !downloading];
    [clockPhasePU           setEnabled:!lockedOrRunningMaintenance && !downloading];
	[pileUpMatrix           setEnabled:!lockedOrRunningMaintenance && !downloading];
	[dumpAllRegistersButton setEnabled:!lockedOrRunningMaintenance && !downloading];
	[snapShotRegistersButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [compareRegistersButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [printThresholdsButton  setEnabled:!downloading];
    [loadThresholdsButton   setEnabled:!lockedOrRunningMaintenance && !downloading];

    [baselineRestoredDelayField setEnabled:!lockedOrRunningMaintenance && !downloading];
    [collectionTimeField        setEnabled:!lockedOrRunningMaintenance && !downloading];
    [integrateTimeField         setEnabled:!lockedOrRunningMaintenance && !downloading];
    [pileUpWindowField          setEnabled:!lockedOrRunningMaintenance && !downloading];
    [noiseWindowField           setEnabled:!lockedOrRunningMaintenance && !downloading];
    [externalWindowField        setEnabled:!lockedOrRunningMaintenance && !downloading];
    [extTrigLengthField         setEnabled:!lockedOrRunningMaintenance && !downloading];

    [mrpsdvMatrix       setEnabled:!lockedOrRunningMaintenance && !downloading];
    [mrpsrtMatrix       setEnabled:!lockedOrRunningMaintenance && !downloading];
    [prerecntMatrix     setEnabled:!lockedOrRunningMaintenance && !downloading];
    [postrecntMatrix    setEnabled:!lockedOrRunningMaintenance && !downloading];
    [ftCntMatrix        setEnabled:!lockedOrRunningMaintenance && !downloading];

    [forceFullInitMatrix        setEnabled:!lockedOrRunningMaintenance && !downloading];
    [forceFullInitCardButton    setEnabled:!lockedOrRunningMaintenance && !downloading];
    
    [tpolMatrix         setEnabled:!lockedOrRunningMaintenance && !downloading];
    [triggerModeMatrix  setEnabled:!lockedOrRunningMaintenance && !downloading];
    
    [easySetButton      setEnabled:!lockedOrRunningMaintenance && !downloading];
    [easySelectMatrix   setEnabled:!lockedOrRunningMaintenance && !downloading];
    [postReStepperUp    setEnabled:!lockedOrRunningMaintenance && !downloading];
    [postReStepperDwn   setEnabled:!lockedOrRunningMaintenance && !downloading];
    [postReStepperUp    setEnabled:!lockedOrRunningMaintenance && !downloading];
    [postReStepperDwn   setEnabled:!lockedOrRunningMaintenance && !downloading];
    [flatTopStepperUp   setEnabled:!lockedOrRunningMaintenance && !downloading];
    [flatTopStepperDwn  setEnabled:!lockedOrRunningMaintenance && !downloading];
    [flatTopField       setEnabled:!lockedOrRunningMaintenance && !downloading];
    [postCountField     setEnabled:!lockedOrRunningMaintenance && !downloading];
    [preCountField      setEnabled:!lockedOrRunningMaintenance && !downloading];
	[histEMultiplierField setEnabled:!lockedOrRunningMaintenance && !downloading];

    [diagnosticsReportButton setEnabled:[model diagnosticsEnabled]];
    [diagnosticsClearButton  setEnabled:[model diagnosticsEnabled]];
    
    
    [viewPreampButton setEnabled:(int)[model spiConnector]];
    
    if(lockedOrRunningMaintenance || downloading){
        [ledThresholdMatrix setEnabled:NO];
        [trapThresholdMatrix setEnabled:NO];
        [chpsrtMatrix setEnabled:NO];
        [chpsdvMatrix setEnabled:NO];
    }
    else {
        int i;
        for(i=0;i<kNumGretina4MChannels;i++){
            BOOL usingTrap      = [model trapEnabled:i];
            BOOL presumEnabled  = [model presumEnabled:i];
            BOOL baselineRestoreEnabled = [model baselineRestoreEnabled:i];
            
            [[ledThresholdMatrix cellWithTag:i] setEnabled:!usingTrap];
            [[trapThresholdMatrix cellWithTag:i] setEnabled:usingTrap];
            //            [[chpsrtMatrix cellWithTag:i] setEnabled:presumEnabled];
            //            [[chpsdvMatrix cellWithTag:i] setEnabled:presumEnabled];
            [[chpsrtMatrix cellAtRow:i column:0] setEnabled:presumEnabled];
            [[chpsdvMatrix cellAtRow:i column:0] setEnabled:presumEnabled];
            
            // The following lines force BLR to be enabled for PZ to be enabled.
            [[poleZeroEnabledMatrix  cellWithTag:i] setEnabled:baselineRestoreEnabled];
            if (!baselineRestoreEnabled) {
                [model setPoleZeroEnabled:i withValue:NO];
            }
        }
    }
}

- (void) registerLockChanged:(NSNotification*)aNotification
{
    
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORGretina4MRegisterLock];
    BOOL locked = [gSecurity isLocked:ORGretina4MRegisterLock];
    BOOL downloading = [model downLoadMainFPGAInProgress];
		
    [registerLockButton setState: locked];
    [registerWriteValueField setEnabled:!lockedOrRunningMaintenance && !downloading];
    [registerIndexPU setEnabled:!lockedOrRunningMaintenance && !downloading];
    [readRegisterButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [writeRegisterButton setEnabled:!lockedOrRunningMaintenance && !downloading];
    [spiWriteValueField setEnabled:!lockedOrRunningMaintenance && !downloading];
    [writeSPIButton setEnabled:!lockedOrRunningMaintenance && !downloading];
}

- (void) setModel:(id)aModel
{
    [super setModel:aModel];
    [[self window] setTitle:[NSString stringWithFormat:@"Gretina4M (Crate %d Slot %d)",[model crateNumber],[model slot]]];
    [dataWindowView initBugs];
    [dataWindowView setNeedsDisplay:YES];
}

- (void) slotChanged:(NSNotification*)aNotification
{
    [[self window] setTitle:[NSString stringWithFormat:@"Gretina4M (Crate %d Slot %d)",[model crateNumber],[model slot]]];
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
	if (index < kNumberOfGretina4MRegisters) {
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
			index -= kNumberOfGretina4MRegisters;
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

#pragma mark •••Actions
- (void) histEMultiplierAction:(id)sender
{
	[model setHistEMultiplier:[sender intValue]];
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

- (IBAction) baselineRestoredDelayAction:(id)sender
{
	[model setBLRDelayConverted:[sender floatValue]];
}

- (IBAction) noiseWindowAction:(id)sender
{
	[model setNoiseWindowConverted:[sender floatValue]];
}

- (IBAction) pileUpAction:(id)sender
{
	if([sender intValue] != [model pileUp:[[sender selectedCell] tag]]){
		[model setPileUp:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) chpsdvAction:(id)sender
{
    [model setChpsdv:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) mrpsrtAction:(id)sender
{
    [model setMrpsrt:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) ftCntAction:(id)sender
{
    [model setFtCnt:[sender selectedRow] withValue:[[sender selectedCell] intValue]];
}

- (IBAction) mrpsdvAction:(id)sender
{
    [model setMrpsdv:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) chsrtAction:(id)sender
{
    [model setChpsrt:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) prerecntAction:(id)sender
{
    [model setPrerecnt:[sender selectedRow] withValue:[[sender selectedCell] intValue]];
}

- (IBAction) postrecntAction:(id)sender
{
    [model setPostrecnt:[sender selectedRow] withValue:[[sender selectedCell] intValue]];
}

- (IBAction) integrateTimeFieldAction:(id)sender
{
	[model setIntegrateTimeConverted:[sender floatValue]];
}

- (IBAction) collectionTimeFieldAction:(id)sender
{
	[model setCollectionTimeConverted:[sender floatValue]];	
}

- (IBAction) extTrigLengthFieldAction:(id)sender
{
	[model setExtTrigLengthConverted:[sender floatValue]];	
}

- (IBAction) pileUpWindowFieldAction:(id)sender
{
	[model setPileUpWindowConverted:[sender floatValue]];	
}

- (IBAction) externalWindowFieldAction:(id)sender
{
	[model setExternalWindowConverted:[sender floatValue]];
}

- (IBAction) clockSourceAction:(id)sender
{
	[model setClockSource:[sender indexOfSelectedItem]];
}

- (IBAction) clockPhaseAction:(id)sender
{
    [model setClockPhase:[sender indexOfSelectedItem]];
}

- (IBAction) downSampleAction:(id)sender
{
	if([sender indexOfSelectedItem] != [model downSample]){
		[model setDownSample:[sender indexOfSelectedItem]];
	}
}

- (IBAction) registerIndexPUAction:(id)sender
{
    int index = (int)[sender indexOfSelectedItem];
	[model setRegisterIndex:index];
	[self setRegisterDisplay:index];
}

- (IBAction) forceFullInitAction:(id)sender;
{
    if([sender intValue] != [model forceFullInit:[[sender selectedCell] tag]]){
        [model setForceFullInit:[[sender selectedCell] tag] withValue:[sender intValue]];
    }
}

- (IBAction) enabledAction:(id)sender
{
	if([sender intValue] != [model enabled:[[sender selectedCell] tag]]){
		[model setEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) easySelectAction:(id)sender
{
	if([sender intValue] != [model easySelected:[[sender selectedCell] tag]]){
		[model setEasySelected:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) selectAllInEasySet:(id)sender
{
    int i;
    for(i=0;i<kNumberOfGretina4MRegisters;i++){
        [model setEasySelected:i withValue:YES];
    }
}
- (IBAction) selectNoneInEasySet:(id)sender
{
    int i;
    for(i=0;i<kNumberOfGretina4MRegisters;i++){
        [model setEasySelected:i withValue:NO];
    }
}

- (IBAction) trapEnabledAction:(id)sender
{
	if([sender intValue] != [model trapEnabled:[[sender selectedCell] tag]]){
		[model setTrapEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) poleZeroEnabledAction:(id)sender
{
	if([sender intValue] != [model poleZeroEnabled:[[sender selectedCell] tag]]){
		[model setPoleZeroEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) baselineRestoreEnabledAction:(id)sender
{
	if([sender intValue] != [model baselineRestoreEnabled:[[sender selectedCell] tag]]){
		[model setBaselineRestoreEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
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

- (IBAction) presumEnabledAction:(id)sender
{
	if([sender intValue] != [model presumEnabled:[[sender selectedCell] tag]]){
		[model setPresumEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}


- (IBAction) tpolAction:(id)sender
{
    [model setTpol:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) triggerModeAction:(id)sender
{
    [model setTriggerMode:[sender selectedRow] withValue:[[sender selectedCell] indexOfSelectedItem]];
}

- (IBAction) ledThresholdAction:(id)sender
{
	if([sender intValue] != [model ledThreshold:[[sender selectedCell] tag]]){
		[model setLEDThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}
- (IBAction) trapThresholdAction:(id)sender
{
    int32_t value = [sender intValue];
    short channel = [[sender selectedCell] tag];
    
	if(value != [model trapThreshold:channel]){
		[model setTrapThreshold:channel withValue:value];
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

- (IBAction) readRegisterAction:(id)sender
{
	[self endEditing];
	uint32_t aValue = 0;
	unsigned int index = [model registerIndex];
	if (index < kNumberOfGretina4MRegisters) {
		aValue = [model readRegister:index];
		NSLog(@"Gretina4M(%d,%d) %@: %u (0x%0x)\n",[model crateNumber],[model slot], [model registerNameAt:index],aValue,aValue);
	} 
	else {
		index -= kNumberOfGretina4MRegisters;
		aValue = [model readFPGARegister:index];	
		NSLog(@"Gretina4M(%d,%d) %@: %u (0x%0x)\n",[model crateNumber],[model slot], [model fpgaRegisterNameAt:index],aValue,aValue);
	}
	
}

- (IBAction) writeRegisterAction:(id)sender
{
	[self endEditing];
	uint32_t aValue = [model registerWriteValue];
	unsigned int index = [model registerIndex];
	if (index < kNumberOfGretina4MRegisters) {
		[model writeRegister:index withValue:aValue];
	} 
	else {
		index -= kNumberOfGretina4MRegisters;
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

- (IBAction) printThresholds:(id)sender
{
    [model printThresholds];
}

- (IBAction) writeSPIAction:(id)sender
{
	[self endEditing];
	uint32_t aValue = [model spiWriteValue];
	uint32_t readback = [model writeAuxIOSPI:aValue];
	NSLog(@"Gretina4M(%d,%d) writeSPI(%u) readback: (0x%0x)\n",[model crateNumber],[model slot], aValue, readback);
}


- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGretina4MSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) registerLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORGretina4MRegisterLock to:[sender intValue] forWindow:[self window]];
}


- (IBAction) resetBoard:(id) sender
{
    @try {
        [model resetBoard];
        NSLog(@"Reset Gretina4M Board (Slot %d <%p>)\n",[model slot],[model baseAddress]);
    }
	@catch(NSException* localException) {
        NSLog(@"Reset of Gretina4M Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4M Reset", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) initBoardAction:(id)sender
{
    @try {
        [self endEditing];
        [model initBoard];		//initialize and load hardware, but don't enable channels
        NSLog(@"Initialized Gretina4M (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
	@catch(NSException* localException) {
        NSLog(@"Init of Gretina4M FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4M Init", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) fullInitBoardAction:(id)sender
{
    @try {
        [self endEditing];
        [model clearOldUserValues];
        [model initBoard];		//initialize and load hardware, but don't enable channels
        NSLog(@"Initialized Gretina4M (Slot %d <%p>)\n",[model slot],[model baseAddress]);
        
    }
    @catch(NSException* localException) {
        NSLog(@"Init of Gretina4M FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4M Init", @"OK", nil, nil,
                        localException);
    }
}


- (IBAction) clearFIFO:(id)sender
{
    @try {  
        [model resetFIFO];
        NSLog(@"Gretina4M (Slot %d <%p>) FIFO reset\n",[model slot],[model baseAddress]);
    }
	@catch(NSException* localException) {
        NSLog(@"Clear of Gretina4M FIFO FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Gretina4M FIFO Clear", @"OK", nil, nil,
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
        NSLog(@"Probe Gretina4M Board FAILED.\n");
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
        NSLog(@"Gretina (slot %d) Finding Thresholds \n",[model slot]);
		[model findNoiseFloors];
    }
	@catch(NSException* localException) {
        NSLog(@"Threshold Finder for Gretina4M Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Threshold finder", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) openEasySetPanel:(id)sender
{
	[self endEditing];
    [[self window] beginSheet:easySetPanel completionHandler:nil];
}

- (IBAction) closeEasySetPanel:(id)sender
{
    [easySetPanel orderOut:nil];
    [NSApp endSheet:easySetPanel];
}

- (IBAction) readStatus:(id)sender
{    
    [self endEditing];
    @try {
        NSLog(@"Gretina BoardID (slot %d): [0x%x] ID = 0x%x\n",[model slot],[model baseAddress],[model readBoardID]);
        int chan;
        for(chan = 0;chan<kNumGretina4MChannels;chan++){
            uint32_t value = [model readControlReg:chan];
			
			int pol=(value>>10)&0x3;
			NSString* polString = @"  ?  ";
			if(pol==0)polString = @"None";
			else if(pol==1) polString = @" Pos";
			else if(pol==2) polString = @" Neg";
			else if(pol==3) polString = @"Both";
			
            NSLogFont([NSFont fontWithName:@"Monaco" size:10],@"chan: %d Enabled: %@ Pileup: %@ Presum: %@ BL-Restorer: %@ Pole-zero: %@ Polarity: [%@] TriggerMode: %@\n",
                      chan, 
                      (value&0x1)?@"[YES]":@"[ NO]",		//enabled
                      ((value>>2)&0x1)?@"[YES]":@"[ NO]",   //pile up
                      ((value>>3)&0x1)?@"[YES]":@"[ NO]",   //presum
                      ((value>>22)&0x1)?@"[YES]":@"[ NO]",  //baseline restorer
                      ((value>>13)&0x1)?@"[YES]":@"[ NO]",  //pole-zero
                      polString, (value>>4)&0x1?@"[External]":@"[Internal]");
        }
        unsigned short fifoStatus = [model readFifoState];
        if(fifoStatus == kFull)			    NSLog(@"FIFO = Full\n");
        else if(fifoStatus == kAlmostFull)	NSLog(@"FIFO = Almost Full\n");
        else if(fifoStatus == kEmpty)		NSLog(@"FIFO = Empty\n");
        else if(fifoStatus == kAlmostEmpty)	NSLog(@"FIFO = Almost Empty\n");
        else if(fifoStatus == kHalfFull)	NSLog(@"FIFO = Half Full\n");
		
		NSLog(@"External Window: %g us\n",  [model externalWindowConverted]);
		NSLog(@"Pileup Window: %g us\n",    [model pileUpWindowConverted]);
		NSLog(@"Clock Source: %@\n",           [model readClockSource]?@"Internal":@"External");
		NSLog(@"Ext Trig Length: %g us\n",  [model extTrigLengthConverted]);
		NSLog(@"Collection: %g us\n",       [model collectionTimeConverted]);
		NSLog(@"Integration Time: %g us\n", [model integrateTimeConverted]);
		NSLog(@"Down sample: x%d\n", (int) pow(2,[model readDownSample]));
        
        
        
        
    }
	@catch(NSException* localException) {
        NSLog(@"Probe Gretina4M Board FAILED.\n");
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
		[self resizeWindowToSize:definitionsTabSize];
		[[self window] setContentView:tabView];
    }  
	
    NSString* key = [NSString stringWithFormat: @"orca.ORGretina4M%d.selectedtab",[model slot]];
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
- (IBAction) dumpAllRegisters:(id)sender
{
    [model dumpAllRegisters];
}

- (IBAction) snapShotRegistersAction:(id)sender
{
    [model snapShotRegisters];
}

- (IBAction) compareToSnapShotAction:(id)sender
{
    [model compareToSnapShot];
}

- (IBAction) doHwCheckButtonAction:(id)sender;
{
    [model setDoHwCheck:[sender intValue]];
}

- (IBAction) forceFullInitCardAction:(id)sender
{
    [model setForceFullInitCard:[sender intValue]];
}

- (IBAction) viewPreampAction:(id)sender
{
    [model openPreampDialog];
}

- (IBAction) loadThresholdsAction:(id)sender
{
    [self endEditing];
    [model loadThresholds];
}
- (IBAction) compareHwNowAction:(id)sender
{
    [model checkBoard:YES];
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

