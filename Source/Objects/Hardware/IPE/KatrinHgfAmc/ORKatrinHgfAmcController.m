//
//  ORKatrinHgfAmcController.m
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

#pragma mark •••Imported Files
#import "ORKatrinHgfAmcController.h"
#import "ORKatrinHgfAmcModel.h"
#import "ORKatrinHgfAmcDefs.h"
#import "SLTv4_HW_Definitions.h"
#import "ORPlotView.h"
#import "ORValueBarGroupView.h"
#import "ORCompositePlotView.h"
#import "ORTimeAxis.h"
#import "ORTimeRate.h"
#import "ORTimeLinePlot.h"
#import "ORKatrinHgfAmcRegisters.h"

@implementation ORKatrinHgfAmcController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"KatrinHgfAmc"];
    
    return self;
}

#pragma mark •••Initialization
- (void) dealloc
{
	[rateFormatter release];
	[blankView release];
    [super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
 
	//TODO: DEBUG-REMOVE - -tb-
	//[[filterShapingLengthPU itemAtIndex:0] setHidden: YES];//TODO: remove this line to enable 100 nsec filter shaping length setting -tb-
	//[[filterShapingLengthPU itemAtIndex:0] setEnabled: NO];//TODO: remove this line to enable 100 nsec filter shaping length setting -tb-
	
    settingSize			= NSMakeSize(690,740);
    rateSize			= NSMakeSize(500,710);
    testSize			= NSMakeSize(610,510);
    lowlevelSize		= NSMakeSize(610,540);
	
	rateFormatter = [[NSNumberFormatter alloc] init];
	[rateFormatter setFormat:@"##0.00"];
	[totalHitRateField setFormatter:rateFormatter];
	[rateTextFields setFormatter:rateFormatter];
    blankView = [[NSView alloc] init];
    
    NSString* key = [NSString stringWithFormat: @"orca.ORKatrinHgfAmc%u.selectedtab",(int)[model stationNumber]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
    [[timeRatePlot yAxis] setRngLimitsLow:0 withHigh:24*1000000 withMinRng:5];

	[aPlot release];

	[rate0 setNumber:24 height:10 spacing:6];
    [[rate0 xAxis] setRngLimitsLow:0 withHigh:5000000 withMinRng:5];
    
    [[totalRate xAxis] setRngLimitsLow:0 withHigh:24*1000000 withMinRng:5];
    NSNumberFormatter* valueFormatter = [[[NSNumberFormatter alloc] init] autorelease];
    [valueFormatter setFormat:@"#0.00;0;-#0.00"];
	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		[[fifoDisplayMatrix cellAtRow:i column:0] setTag:i];
        [[thresholdTextFields cellWithTag:i] setFormatter:valueFormatter ];
	}
	[self populatePullDown];
	
	[useSLTtimePU setAutoenablesItems: false];  // seems to be not settable with InterfaceBuilder, do it here -tb-
	[[useSLTtimePU itemAtIndex: 2] setEnabled:false];
	
	
	[self updateWindow];

}

#pragma mark •••Accessors

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORKatrinHgfAmcSettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORIpeCardSlotChangedNotification
					   object : model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(modeChanged:)
                         name : ORKatrinHgfAmcModelModeChanged
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(thresholdChanged:)
						 name : ORKatrinHgfAmcModelThresholdChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(gainChanged:)
						 name : ORKatrinHgfAmcModelGainChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(triggerEnabledChanged:)
						 name : ORKatrinHgfAmcModelTriggerEnabledMaskChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(hitRateEnabledChanged:)
						 name : ORKatrinHgfAmcModelHitRateEnabledMaskChanged
					   object : model];
		
	
    [notifyCenter addObserver : self
					 selector : @selector(gainArrayChanged:)
						 name : ORKatrinHgfAmcModelGainsChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(thresholdArrayChanged:)
						 name : ORKatrinHgfAmcModelThresholdsChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(hitRateLengthChanged:)
						 name : ORKatrinHgfAmcModelHitRateLengthChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(hitRateChanged:)
						 name : ORKatrinHgfAmcModelHitRateChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(scaleAction:)
						 name : ORAxisRangeChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(miscAttributesChanged:)
						 name : ORMiscAttributesChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateAverageChangedNotification
					   object : [model totalRate]];
	
    [notifyCenter addObserver : self
                     selector : @selector(testEnabledArrayChanged:)
                         name : ORKatrinHgfAmcModelTestEnabledArrayChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(testStatusArrayChanged:)
                         name : ORKatrinHgfAmcModelTestStatusArrayChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : ORKatrinHgfAmcModelTestsRunningChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(interruptMaskChanged:)
                         name : ORKatrinHgfAmcModelInterruptMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(analogOffsetChanged:)
                         name : ORKatrinHgfAmcModelAnalogOffsetChanged
						object: model];
		
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : ORKatrinHgfAmcSelectedRegIndexChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : ORKatrinHgfAmcWriteValueChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(selectedChannelValueChanged:)
						 name : ORKatrinHgfAmcSelectedChannelValueChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(fifoBehaviourChanged:)
                         name : ORKatrinHgfAmcModelFifoBehaviourChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(postTriggerTimeChanged:)
                         name : ORKatrinHgfAmcModelPostTriggerTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histRecTimeChanged:)
                         name : ORKatrinHgfAmcModelHistRecTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histMeasTimeChanged:)
                         name : ORKatrinHgfAmcModelHistMeasTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histNofMeasChanged:)
                         name : ORKatrinHgfAmcModelHistNofMeasChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(gapLengthChanged:)
                         name : ORKatrinHgfAmcModelGapLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(filterShapingLengthChanged:)
                         name : ORKatrinHgfAmcModelFilterShapingLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(storeDataInRamChanged:)
                         name : ORKatrinHgfAmcModelStoreDataInRamChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histEMinChanged:)
                         name : ORKatrinHgfAmcModelHistEMinChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histEBinChanged:)
                         name : ORKatrinHgfAmcModelHistEBinChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histModeChanged:)
                         name : ORKatrinHgfAmcModelHistModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histClrModeChanged:)
                         name : ORKatrinHgfAmcModelHistClrModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histFirstEntryChanged:)
                         name : ORKatrinHgfAmcModelHistFirstEntryChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histLastEntryChanged:)
                         name : ORKatrinHgfAmcModelHistLastEntryChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorChanged:)
                         name : ORKatrinHgfAmcNoiseFloorChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(histPageABChanged:)
                         name : ORKatrinHgfAmcModelHistPageABChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histMaxEnergyChanged:)
                         name : ORKatrinHgfAmcModelHistMaxEnergyChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(targetRateChanged:)
                         name : ORKatrinHgfAmcModelTargetRateChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(shipSumHistogramChanged:)
                         name : ORKatrinHgfAmcModelShipSumHistogramChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fifoLengthChanged:)
                         name : ORKatrinHgfAmcModelFifoLengthChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(activateDebuggerDisplaysChanged:)
                         name : ORKatrinHgfAmcModelActivateDebuggingDisplaysChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(fifoFlagsChanged:)
                         name : ORKatrinHgfAmcModeFifoFlagsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(customVariableChanged:)
                         name : ORKatrinHgfAmcModelCustomVariableChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(poleZeroCorrectionChanged:)
                         name : ORKatrinHgfAmcModelPoleZeroCorrectionChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(decayTimeChanged:)
                         name : ORKatrinHgfAmcModelDecayTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useDmaBlockReadChanged:)
                         name : ORKatrinHgfAmcModelUseDmaBlockReadChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(boxcarLengthChanged:)
                         name : ORKatrinHgfAmcModelBoxcarLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useSLTtimeChanged:)
                         name : ORKatrinHgfAmcModelUseSLTtimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(useBipolarEnergyChanged:)
                         name : ORKatrinHgfAmcModelUseBipolarEnergyChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(bipolarEnergyThreshTestChanged:)
                         name : ORKatrinHgfAmcModelBipolarEnergyThreshTestChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(skipFltEventReadoutChanged:)
                         name : ORKatrinHgfAmcModelSkipFltEventReadoutChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(forceFLTReadoutChanged:)
                         name : ORKatrinHgfAmcModelForceFLTReadoutChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(energyOffsetChanged:)
                         name : ORKatrinHgfAmcModelEnergyOffsetChanged
						object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(hitRateModeChanged:)
                         name : ORKatrinHgfAmcModelHitRateModeChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lostEventsChanged:)
                         name : ORKatrinHgfAmcModelLostEventsChanged
                        object: model];

    [notifyCenter addObserver : self
                     selector : @selector(lostEventsTrChanged:)
                         name : ORKatrinHgfAmcModelLostEventsTrChanged
                        object: model];
    
}

#pragma mark •••Interface Management

- (void) hitRateModeChanged:(NSNotification*)aNote
{
    [hitRateModePU selectItemAtIndex:[model hitRateMode]];
}

- (void) energyOffsetChanged:(NSNotification*)aNote
{
	[energyOffsetTextField setIntValue: [model energyOffset] / [model filterLengthInBins]];
}

- (void) forceFLTReadoutChanged:(NSNotification*)aNote
{
	[forceFLTReadoutCB setIntValue: [model forceFLTReadout]];
}

- (void) skipFltEventReadoutChanged:(NSNotification*)aNote
{
	[skipFltEventReadoutCB setIntValue: [model skipFltEventReadout]];
}

- (void) bipolarEnergyThreshTestChanged:(NSNotification*)aNote
{
	[bipolarEnergyThreshTestTextField setIntegerValue: [model bipolarEnergyThreshTest]];
}

- (void) useBipolarEnergyChanged:(NSNotification*)aNote
{
	[useBipolarEnergyCB setIntValue: [model useBipolarEnergy]];
}

- (void) useSLTtimeChanged:(NSNotification*)aNote
{
	//[useSLTtimeCB setState: [model useSLTtime]];
	[useSLTtimePU selectItemAtIndex: [model useSLTtime]];
	//[useSLTtimePU setAutoenablesItems: false];
	//[[useSLTtimePU itemAtIndex: 2] setEnabled:false];
}
- (void) useDmaBlockReadChanged:(NSNotification*)aNote
{
	[useDmaBlockReadPU selectItemWithTag: [model useDmaBlockRead]];
	//[useDmaBlockReadButton setIntValue: [model useDmaBlockRead]];//obsolete -tb-
}

- (void) recommendedPZCChanged:(NSNotification*)aNote
{
    double att = [model poleZeroCorrectionHint];
	[recommendedPZCTextField setStringValue: [NSString stringWithFormat:@"%.3f -> %i",att,[model poleZeroCorrectionSettingHint:att]]];
}

- (void) decayTimeChanged:(NSNotification*)aNote
{
	[decayTimeTextField setDoubleValue: [model decayTime]];
	[self recommendedPZCChanged:nil];
}

- (void) poleZeroCorrectionChanged:(NSNotification*)aNote
{
	[poleZeroCorrectionPU selectItemAtIndex: [model poleZeroCorrection]];
}

- (void) customVariableChanged:(NSNotification*)aNote
{
	[customVariableTextField setIntValue: [model customVariable]];
}

- (void) activateDebuggerDisplaysChanged:(NSNotification*)aNote
{
	[activateDebuggerCB setIntValue: [model activateDebuggingDisplays]];
	[fifoDisplayMatrix setHidden: ![model activateDebuggingDisplays]];
}

- (void) fifoLengthChanged:(NSNotification*)aNote
{
	//NSLog(@"%@::%@: fifoLength is %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[model fifoLength]);//-tb-NSLog-tb-
	[fifoLengthPU selectItemAtIndex: [model fifoLength]];
}

- (void) shipSumHistogramChanged:(NSNotification*)aNote
{
	[shipSumHistogramPU selectItemWithTag: [model shipSumHistogram]];
}

- (void) targetRateChanged:(NSNotification*)aNote
{
	[targetRateField setIntValue: [model targetRate]];
}

- (void) histMaxEnergyChanged:(NSNotification*)aNote
{
	[histMaxEnergyTextField setIntValue: [model histEMax] / [model filterShapingLengthInBins] ];
}

- (void) histPageABChanged:(NSNotification*)aNote
{
	[histPageABTextField setStringValue: [model histPageAB]?@"B":@"A"];
	//[histPageABTextField setIntValue: [model histPageAB]];
}
- (void) histLastEntryChanged:(NSNotification*)aNote
{
	[histLastEntryField setIntegerValue: [model histLastEntry]];
}

- (void) histFirstEntryChanged:(NSNotification*)aNote
{
	[histFirstEntryField setIntegerValue: [model histFirstEntry]];
}

- (void) histClrModeChanged:(NSNotification*)aNote
{
	[histClrModePU selectItemAtIndex: [model histClrMode]];
}

- (void) histModeChanged:(NSNotification*)aNote
{
	[histModePU selectItemAtIndex: [model histMode]];
}

- (void) histEBinChanged:(NSNotification*)aNote
{
	[histEBinPU selectItemAtIndex: [model histEBin]];
}

- (void) histEMinChanged:(NSNotification*)aNote
{
	[histEMinTextField setIntegerValue: [model histEMin] / [model filterShapingLengthInBins] ];
}

- (void) storeDataInRamChanged:(NSNotification*)aNote
{
	[storeDataInRamCB setIntValue: [model storeDataInRam]];
}

- (void) filterShapingLengthChanged:(NSNotification*)aNote
{
	[filterShapingLengthPU selectItemWithTag:[model filterShapingLength]];
	[self recommendedPZCChanged:nil];
	bool useBoxcar=([model filterShapingLength]==0);
	[boxcarLengthPU     setEnabled: useBoxcar];
	[boxcarLengthLabel  setEnabled: useBoxcar];
}

- (void) gapLengthChanged:(NSNotification*)aNote
{
	[gapLengthPU selectItemAtIndex: [model gapLength]];
}

- (void) boxcarLengthChanged:(NSNotification*)aNote
{
	//[boxcarLength<custom> setIntValue: [model boxcarLength]];
	[boxcarLengthPU selectItemWithTag:[model boxcarLength]];
}


- (void) histNofMeasChanged:(NSNotification*)aNote
{
	[histNofMeasField setIntegerValue: [model histNofMeas]];
}

- (void) histMeasTimeChanged:(NSNotification*)aNote
{
	[histMeasTimeField setIntegerValue: [model histMeasTime]];
}

- (void) histRecTimeChanged:(NSNotification*)aNote
{
	[histRecTimeField setIntegerValue: [model histRecTime]];
}

- (void) postTriggerTimeChanged:(NSNotification*)aNote
{
	[postTriggerTimeField setIntegerValue: [model postTriggerTime]];
}

- (void) fifoBehaviourChanged:(NSNotification*)aNote
{
	[fifoBehaviourMatrix selectCellWithTag: [model fifoBehaviour]];
}

- (void) analogOffsetChanged:(NSNotification*)aNote
{
	[analogOffsetField setIntValue: [model scaledAnalogOffset]];
}

- (void) interruptMaskChanged:(NSNotification*)aNote
{
	[interruptMaskField setIntegerValue: [model interruptMask]];
}

- (void) populatePullDown
{
    short	i;
	
	// Clear all the popup items.
    [registerPopUp removeAllItems];
    
	// Populate the register popup
    for (i = 0; i < [KatrinHgfAmcRegisters numRegisters]; i++) {
        [registerPopUp insertItemWithTitle:[KatrinHgfAmcRegisters registerName:i] atIndex:i];
    }
    
    
	// Clear all the popup items.
    [channelPopUp removeAllItems];
    
	// Populate the register popup
	for(i=0;i<kNumV4FLTChannels;i++){
        [channelPopUp insertItemWithTitle: [NSString stringWithFormat: @"%i",i ] atIndex:i];
        [[channelPopUp itemAtIndex:i] setTag: i];
    }
    [channelPopUp insertItemWithTitle: @"All" atIndex:i];
    [[channelPopUp itemAtIndex:i] setTag: 0x1f];// chan 31 = broadcast to all channels
}

- (void) updateWindow
{
    [super updateWindow];
    [self slotChanged:nil];
	[self modeChanged:nil];
	[self gainArrayChanged:nil];
	[self thresholdArrayChanged:nil];
	[self triggersEnabledArrayChanged:nil];
	[self hitRatesEnabledArrayChanged:nil];
	[self hitRateLengthChanged:nil];
	[self hitRateChanged:nil];
    [self updateTimePlot:nil];
    [self totalRateChanged:nil];
	[self scaleAction:nil];
    [self testEnabledArrayChanged:nil];
	[self testStatusArrayChanged:nil];
    [self miscAttributesChanged:nil];
	[self interruptMaskChanged:nil];
	[self analogOffsetChanged:nil];
	[self selectedRegIndexChanged:nil];
	[self writeValueChanged:nil];
	[self selectedChannelValueChanged:nil];
	[self fifoBehaviourChanged:nil];
	[self postTriggerTimeChanged:nil];
	[self histRecTimeChanged:nil];
	[self histMeasTimeChanged:nil];
	[self histNofMeasChanged:nil];
    [self settingsLockChanged:nil];
	[self gapLengthChanged:nil];
	[self filterShapingLengthChanged:nil];
	[self storeDataInRamChanged:nil];
	[self histEMinChanged:nil];
	[self histEBinChanged:nil];
	[self histModeChanged:nil];
	[self histClrModeChanged:nil];
	[self histFirstEntryChanged:nil];
	[self histLastEntryChanged:nil];
	[self noiseFloorChanged:nil];
	[self histPageABChanged:nil];
	[self histMaxEnergyChanged:nil];
	[self targetRateChanged:nil];
	[self shipSumHistogramChanged:nil];
	[self fifoLengthChanged:nil];
	[self activateDebuggerDisplaysChanged:nil];
	[self fifoFlagsChanged:nil];
	[self customVariableChanged:nil];
	[self poleZeroCorrectionChanged:nil];
	[self decayTimeChanged:nil];
	[self recommendedPZCChanged:nil];
	[self useDmaBlockReadChanged:nil];
	[self boxcarLengthChanged:nil];
	[self useSLTtimeChanged:nil];
	[self useBipolarEnergyChanged:nil];
	[self bipolarEnergyThreshTestChanged:nil];
	[self skipFltEventReadoutChanged:nil];
    [self forceFLTReadoutChanged:nil];
	[self energyOffsetChanged:nil];
    [self hitRateModeChanged:nil];
    [self lostEventsChanged:nil];
    [self lostEventsTrChanged:nil];
    [self thresholdChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORKatrinHgfAmcSettingsLock to:secure];
    [settingLockButton setEnabled:secure];	
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (void) updateButtons
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORKatrinHgfAmcSettingsLock];
    BOOL runInProgress    = [gOrcaGlobals runInProgress];
    BOOL locked           = [gSecurity isLocked:ORKatrinHgfAmcSettingsLock];
	BOOL testsAreRunning  = [model testsRunning];
	BOOL testingOrRunning = testsAreRunning | runInProgress;
    bool isVetoMode       = ([(ORKatrinHgfAmcModel*)model runMode] == 3) || ([(ORKatrinHgfAmcModel*)model runMode] == 4);
    bool useBoxcar        = isVetoMode;

    //MAH. put in casts below to clear warning from XCode 5
//    if([(ORKatrinHgfAmcModel*)model runMode] < 3 || [(ORKatrinHgfAmcModel*)model runMode] > 6)    [modeTabView selectTabViewItemAtIndex:0];
//    else                                            [modeTabView selectTabViewItemAtIndex:1];
    
    [forceFLTReadoutCB           setEnabled: !lockedOrRunningMaintenance && [(ORKatrinHgfAmcModel*)model fltRunMode] != kKatrinV4Flt_VetoEnergyTraceDaqMode];
	[gapLengthPU                 setEnabled: !lockedOrRunningMaintenance && (([(ORKatrinHgfAmcModel*)model runMode]<3) || ([(ORKatrinHgfAmcModel*)model runMode]>6))];
	[filterShapingLengthPU       setEnabled: !lockedOrRunningMaintenance && (([(ORKatrinHgfAmcModel*)model runMode]<3) || ([(ORKatrinHgfAmcModel*)model runMode]>6))];
	[boxcarLengthPU              setEnabled: !lockedOrRunningMaintenance && useBoxcar];
	[boxcarLengthLabel           setEnabled: !lockedOrRunningMaintenance && useBoxcar];
    [testEnabledMatrix           setEnabled: !locked && !testingOrRunning];
    [settingLockButton           setState: locked];
	[initBoardButton             setEnabled: !lockedOrRunningMaintenance];
	[reportButton                setEnabled: !lockedOrRunningMaintenance];
	//[modeButton                setEnabled: !lockedOrRunningMaintenance]; //as per Florian's request 3/19/2013
	[resetButton                 setEnabled: !lockedOrRunningMaintenance];
    [gainTextFields              setEnabled: !lockedOrRunningMaintenance];
    [thresholdTextFields         setEnabled: !lockedOrRunningMaintenance];
    [triggerEnabledCBs           setEnabled: !lockedOrRunningMaintenance];
    [hitRateEnabledCBs           setEnabled: !lockedOrRunningMaintenance];
    
    [hideVetoBox                 setHidden:!isVetoMode];
    if (isVetoMode) [self enableVetoChannels:isVetoMode];
    
    [versionButton               setEnabled: !runInProgress];
	[testButton                  setEnabled: !runInProgress];
	[statusButton                setEnabled: !runInProgress];
	
    [hitRateLengthPU             setEnabled: !lockedOrRunningMaintenance];
    [hitRateAllButton            setEnabled: !lockedOrRunningMaintenance];
    [hitRateNoneButton           setEnabled: !lockedOrRunningMaintenance];
		
	if(testsAreRunning){
		[testButton setEnabled: YES];
		[testButton setTitle: @"Stop"];
	}
    else {
		[testButton setEnabled: !runInProgress];	
		[testButton setTitle: @"Test"];
	}
	
	int daqMode = [model runMode];
	//[histNofMeasField setEnabled: !locked & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	[histMeasTimeField setEnabled:               !lockedOrRunningMaintenance & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	[histEMinTextField setEnabled:               !lockedOrRunningMaintenance & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	[histEBinPU setEnabled:                      !lockedOrRunningMaintenance & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	[shipSumHistogramPU setEnabled:              !lockedOrRunningMaintenance & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	[histModePU setEnabled:                      !lockedOrRunningMaintenance & (daqMode == kIpeFltV4_Histogram_DaqMode)];
	[histClrModePU setEnabled:                   !lockedOrRunningMaintenance & (daqMode == kIpeFltV4_Histogram_DaqMode)];
    
    [compareRegistersButton setEnabled:!lockedOrRunningMaintenance];
    
    [startNoiseFloorButton setEnabled: !runInProgress];
	
 	[self enableRegControls];
}

- (void) enableRegControls
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORKatrinHgfAmcSettingsLock];
	short index = [model selectedRegIndex];
	BOOL readAllowed = !lockedOrRunningMaintenance  && ([model accessTypeOfReg:index] & kRead);
	BOOL writeAllowed = !lockedOrRunningMaintenance && ([model accessTypeOfReg:index] & kWrite);
	BOOL needsChannel = !lockedOrRunningMaintenance && ([model accessTypeOfReg:index] & kChanReg);
	
	[regWriteButton setEnabled:writeAllowed];
	[regReadButton setEnabled:readAllowed];
	
	[regWriteValueStepper setEnabled:writeAllowed];
	[regWriteValueTextField setEnabled:writeAllowed];
    
    //TODO: extend the accesstype to "channel" and "block64" -tb-
    [channelPopUp setEnabled: needsChannel];
}

- (void) enableVetoChannels:(BOOL) isVeto
{
    int i;
    //int nonVetoChannel[9] = {7,14,23,3,5,10,12,19,21}; // numbering 0...23
    int nonVetoChannel[6] = {7,14,23,5,12,21}; // numbering 0...23
    int nNonVetoChannels = sizeof(nonVetoChannel)/sizeof(int);
    
    for (i=0; i<nNonVetoChannels; i++)
    {
        [[gainTextFields cellWithTag:nonVetoChannel[i]] setEnabled: !isVeto];
        [[thresholdTextFields cellWithTag:nonVetoChannel[i]] setEnabled: !isVeto];
        [[triggerEnabledCBs cellWithTag:nonVetoChannel[i]] setEnabled: !isVeto];
        [[hitRateEnabledCBs cellWithTag:nonVetoChannel[i]] setEnabled: !isVeto];
       
        // Disable hardware trigger and hitrate
        if (isVeto){
            [model setTriggerEnabled:nonVetoChannel[i] withValue: 0];
            [model setHitRateEnabled:nonVetoChannel[i] withValue: 0];
        }
    }

}

- (void) fifoFlagsChanged:(NSNotification*)aNote
{
	if(!aNote){
		int i;
		for(i=0;i<kNumV4FLTChannels;i++){
			[[fifoDisplayMatrix cellWithTag:i] setStringValue:[model fifoFlagString:i]];
		}
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
		[[fifoDisplayMatrix cellWithTag:chan] setStringValue:[model fifoFlagString:chan]];
	}
}

- (void) noiseFloorChanged:(NSNotification*)aNote
{
	if([model noiseFloorRunning]){
		[noiseFloorProgress startAnimation:self];
		[startNoiseFloorButton setTitle:@"Stop"];
	}
	else {
		[noiseFloorProgress stopAnimation:self];
		[startNoiseFloorButton setTitle:@"Start"];
	}
	[noiseFloorStateField setStringValue:[model noiseFloorStateString]];
	[noiseFloorStateField2 setStringValue:[model noiseFloorStateString]];
}


- (void) testEnabledArrayChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumKatrinHgfAmcTests;i++){
		[[testEnabledMatrix cellWithTag:i] setIntValue:[model testEnabled:i]];
	}    
}

- (void) testStatusArrayChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumKatrinHgfAmcTests;i++){
		[[testStatusMatrix cellWithTag:i] setStringValue:[model testStatus:i]];
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
	//if(!aNote || ([aNote object] == [[model adcRateGroup]timeRate])){
	//	[timeRatePlot setNeedsDisplay:YES];
	//}
}


- (void) gainChanged:(NSNotification*)aNotification
{
	int chan = [[[aNotification userInfo] objectForKey:ORKatrinHgfAmcChan] intValue];
	[[gainTextFields cellWithTag:chan] setIntValue: [model gain:chan]];
}

- (void) triggerEnabledChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		[[triggerEnabledCBs cellWithTag:i] setState: [model triggerEnabled:i]];
	}
}

- (void) hitRateEnabledChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumV4FLTChannels;i++){
		[[hitRateEnabledCBs cellWithTag:i] setState: [model hitRateEnabled:i]];
	}
}

- (void) thresholdChanged:(NSNotification*)aNotification
{
    if(!aNotification){
        int chan;
        for(chan=0;chan<kNumV4FLTChannels;chan++){
            [[thresholdTextFields cellWithTag:chan] setFloatValue: [model scaledThreshold:chan]];
        }
    }
    else {
        int chan = [[[aNotification userInfo] objectForKey:ORKatrinHgfAmcChan] intValue];
        [[thresholdTextFields cellWithTag:chan] setFloatValue: [model scaledThreshold:chan]];
    }
}

- (void) slotChanged:(NSNotification*)aNotification
{
	// Set title of FLT configuration window, ak 15.6.07
	// for FLTv4 'slot' go from 0-9, 11-20 (SLTv4 has slot 10)
	[[self window] setTitle:[NSString stringWithFormat:@"IPE-DAQ V4 KATRIN FLT Card (Slot %d, FLT# %u)",(int)[model slot]+1,(int)[model stationNumber]]];
    [fltSlotNumTextField setStringValue: [NSString stringWithFormat:@"FLT# %u",(int)[model stationNumber]]];
}

- (void) gainArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		[[gainTextFields cellWithTag:chan] setIntValue: [model gain:chan]];
	}
}

- (void) thresholdArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		[[thresholdTextFields cellWithTag:chan] setIntValue: [(ORKatrinHgfAmcModel*)model scaledThreshold:chan]];
	}
}

- (void) triggersEnabledArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		[[triggerEnabledCBs cellWithTag:chan] setIntValue: [model triggerEnabled:chan]];
	}
}

- (void) hitRatesEnabledArrayChanged:(NSNotification*)aNotification
{
	short chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		[[hitRateEnabledCBs cellWithTag:chan] setIntValue: [model hitRateEnabled:chan]];
	}
}

- (void) modeChanged:(NSNotification*)aNote
{
	[modeButton selectItemWithTag:[model runMode]];
	[self updateButtons];
}

- (void) hitRateLengthChanged:(NSNotification*)aNote
{
	[hitRateLengthPU selectItemWithTag:[model hitRateLength]];
}

- (void) hitRateChanged:(NSNotification*)aNote
{
    if(![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(hitRateChanged:) withObject:aNote waitUntilDone:NO];
        return;
    }
	int chan;
	for(chan=0;chan<kNumV4FLTChannels;chan++){
		id theCell = [rateTextFields cellWithTag:chan];
		if([model hitRateOverFlow:chan]){
			[theCell setFormatter: nil];
			[theCell setTextColor:[NSColor redColor]];
			[theCell setObjectValue: @"OverFlow"];
		}
		else {
			[theCell setFormatter: rateFormatter];
			[theCell setTextColor:[NSColor blackColor]];
			[theCell setFloatValue: [model hitRate:chan]];
		}
	}
	[rate0 setNeedsDisplay:YES];
	[totalHitRateField setFloatValue:[model hitRateTotal]];
	[totalRate setNeedsDisplay:YES];
}

- (void) totalRateChanged:(NSNotification*)aNote
{
    if(![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(totalRateChanged:) withObject:aNote waitUntilDone:NO];
        return;
    }
	if(aNote==nil || [aNote object] == [model totalRate]){
		[timeRatePlot setNeedsDisplay:YES];
	}
}
     
- (void) lostEventsChanged:(NSNotification*)aNote
{
    [lostEventField setIntegerValue: [model lostEvents]];
}

- (void) lostEventsTrChanged:(NSNotification*)aNote
{
    [lostEventTrField setIntegerValue: [model lostEventsTr]];
}


- (void) selectedRegIndexChanged:(NSNotification*) aNote
{
	[self updatePopUpButton:registerPopUp	 setting:[model selectedRegIndex]];
	
	[self enableRegControls];
}

- (void) writeValueChanged:(NSNotification*) aNote
{
    [regWriteValueTextField setIntegerValue: [model writeValue]];
}

- (void) selectedChannelValueChanged:(NSNotification*) aNote
{
    [channelPopUp selectItemWithTag: [model selectedChannelValue]];
	[self enableRegControls];
}

- (void) tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:settingSize];		break;
		case  1: [self resizeWindowToSize:rateSize];	    break;
		case  2: [self resizeWindowToSize:testSize];        break;
		case  3: [self resizeWindowToSize:lowlevelSize];	break;
		default: [self resizeWindowToSize:testSize];	    break;
    }
    [[self window] setContentView:totalView];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORKatrinHgfAmc%u.selectedtab",(int)[model stationNumber]];
    NSInteger index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}

#pragma mark •••Actions

- (IBAction) energyOffsetTextFieldAction:(id)sender
{
	[model setEnergyOffset:[sender intValue] * [model filterLengthInBins]];
}

- (IBAction) forceFLTReadoutCBAction:(id)sender
{
	[model setForceFLTReadout:[sender intValue]];	
}

- (IBAction) skipFltEventReadoutCBAction:(id)sender
{
	[model setSkipFltEventReadout:[sender intValue]];	
}

- (IBAction) bipolarEnergyThreshTestTextFieldAction:(id)sender
{
	[model setBipolarEnergyThreshTest:[sender intValue]];
}

- (IBAction) useBipolarEnergyCBAction:(id)sender
{
	[model setUseBipolarEnergy:[sender intValue]];	
}

- (IBAction) useSLTtimePUAction:(id)sender
{
	//DEBUG -tb-    	NSLog(@"Called %@::%@! selected %i\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd),[sender indexOfSelectedItem]);//TODO: DEBUG -tb-
	//[model setUseSLTtime:[sender intValue]];	
	[model updateUseSLTtime];	
}

- (IBAction) hitRateModeAction:(id)sender
{
    [model setHitRateMode:(int)[sender indexOfSelectedItem]];
}

- (IBAction) useDmaBlockReadPUAction:(id)sender
{
	[model setUseDmaBlockRead:(int)[[useDmaBlockReadPU selectedItem] tag]];
}

- (IBAction) useDmaBlockReadButtonAction:(id)sender
{
	[model setUseDmaBlockRead:[sender intValue]];	
}

- (IBAction) decayTimeTextFieldAction:(id)sender
{
	[model setDecayTime:[sender doubleValue]];	
}

- (IBAction) poleZeroCorrectionPUAction:(id)sender
{
	[model setPoleZeroCorrection:(int)[poleZeroCorrectionPU indexOfSelectedItem]];
}

- (IBAction) customVariableTextFieldAction:(id)sender
{
	[model setCustomVariable:[sender intValue]];	
}

- (IBAction) fifoLengthPUAction:(id)sender
{
	[model setFifoLength:(int)[fifoLengthPU indexOfSelectedItem]];
}

- (IBAction) shipSumHistogramPUAction:(id)sender
{
    [model setShipSumHistogram:(int)[sender indexOfSelectedItem]];

}

- (IBAction) targetRateAction:(id)sender
{
	[model setTargetRate:[sender intValue]];	
}

- (IBAction) activateDebuggingDisplayAction:(id)sender
{
    [model setActivateDebuggingDisplays:[sender intValue]];
}


- (IBAction) openNoiseFloorPanel:(id)sender
{
	[self endEditing];
    [[self window] beginSheet:noiseFloorPanel completionHandler:nil];
}

- (IBAction) closeNoiseFloorPanel:(id)sender
{
    [noiseFloorPanel endEditingFor:nil];
    [noiseFloorPanel orderOut:nil];
    [NSApp endSheet:noiseFloorPanel];
}

- (IBAction) findNoiseFloors:(id)sender
{
	[noiseFloorPanel endEditingFor:nil];		
    @try {
		[model findNoiseFloors];
    }
	@catch(NSException* localException) {
        NSLog(@"Threshold Finder for IPE V4 FLT Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Threshold finder", @"OK", nil, nil,
                        localException);
    }
}
- (IBAction) histClrModeAction:(id)sender
{
	[model setHistClrMode:(int)[sender indexOfSelectedItem]];
}

- (IBAction) histModeAction:(id)sender
{
	[model setHistMode:(int)[sender indexOfSelectedItem]];
}

- (IBAction) histEBinAction:(id)sender
{
	[model setHistEBin:(uint32_t)[sender indexOfSelectedItem]];	
}

- (IBAction) histEMinAction:(id)sender
{
	[model setHistEMin: ([sender intValue] * [model filterShapingLengthInBins] ) ];
}


- (IBAction) storeDataInRamAction:(id)sender
{
	[model setStoreDataInRam:[sender intValue]];	
}

- (IBAction) filterShapingLengthAction:(id)sender
{
	[model setFilterShapingLength:(int)[[sender selectedCell] tag]];
}

- (IBAction) gapLengthAction:(id)sender
{
	[model setGapLength:(int)[sender indexOfSelectedItem]];
}

- (void) boxcarLengthPUAction:(id)sender
{
	[model setBoxcarLength:(int)[[sender selectedCell] tag]];
}

- (IBAction) histNofMeasAction:(id)sender
{
	[model setHistNofMeas:[sender intValue]];	
}

- (IBAction) histMeasTimeAction:(id)sender
{
	[model setHistMeasTime:[sender intValue]];	
}

- (IBAction) setTimeToMacClock:(id)sender
{
	@try {
		[model setTimeToMacClock];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception setting FLT clock\n");
		ORRunAlertPanel([localException name], @"%@\nSetClock of FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) postTriggerTimeAction:(id)sender
{
	@try {
		[model setPostTriggerTime:[sender intValue]];	
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT post trigger time\n");
		ORRunAlertPanel([localException name], @"%@\nSet post trigger time of FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) fifoBehaviourAction:(id)sender
{
	@try {
		[model setFifoBehaviour:(int)[[sender selectedCell]tag]];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception setting FLT behavior\n");
		ORRunAlertPanel([localException name], @"%@\nSetting Behaviour of FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) analogOffsetAction:(id)sender
{
	@try {
		[model setScaledAnalogOffset:[sender intValue]];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception setting FLT analog offset\n");
		ORRunAlertPanel([localException name], @"%@\nSet analog offset FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) interruptMaskAction:(id)sender
{
	@try {
		[model setInterruptMask:[sender intValue]];	
	}
	@catch(NSException* localException) {
		NSLog(@"Exception setting FLT interrupt mask\n");
		ORRunAlertPanel([localException name], @"%@\nSet of interrupt mask of FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) testEnabledAction:(id)sender
{
	NSMutableArray* anArray = [NSMutableArray array];
	int i;
	for(i=0;i<kNumKatrinHgfAmcTests;i++){
		if([[testEnabledMatrix cellWithTag:i] intValue])[anArray addObject:[NSNumber numberWithBool:YES]];
		else [anArray addObject:[NSNumber numberWithBool:NO]];
	}
	[model setTestEnabledArray:anArray];
}

- (IBAction) setDefaultsAction: (id) sender
{
	@try {
		[model setToDefaults];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception setting FLT default Values\n");
		ORRunAlertPanel([localException name], @"%@\nSet Defaults for FLT%d failed", @"OK", nil, nil,
						localException,[model stationNumber]);
	}
}

- (IBAction) readThresholdsGains:(id)sender
{
	@try {
		int i;
		NSFont* aFont = [NSFont userFixedPitchFontOfSize:10];
		NSLogFont(aFont,   @"FLT (station %d)\n",[model stationNumber]); // ak, 5.10.07
		NSLogFont(aFont,   @"chan | Gain | Threshold\n");
		NSLogFont(aFont,   @"-----------------------\n");
		for(i=0;i<kNumV4FLTChannels;i++){
			NSLogFont(aFont,@"%4d | %4d | %4d \n",i,[model readGain:i],[model readThreshold:i]);
			//NSLog(@"%d: %d\n",i,[model readGain:i]);
		}
		NSLogFont(aFont,   @"-----------------------\n");
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT gains and thresholds\n");
        ORRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) writeThresholdsGains:(id)sender
{
	[self endEditing];
	@try {
		[model loadThresholdsAndGains];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception writing FLT gains and thresholds\n");
        ORRunAlertPanel([localException name], @"%@\nWrite of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) gainAction:(id)sender
{
    [[self undoManager] setActionName: @"Set Gain"];
    [model setGain:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) thresholdAction:(id)sender
{
    [[self undoManager] setActionName: @"Set Threshold"];
    [model setScaledThreshold:[[sender selectedCell] tag] withValue:[sender floatValue]];
}


- (IBAction) triggerEnableAction:(id)sender
{
	[[self undoManager] setActionName: @"Set TriggerEnabled"];
	[model setTriggerEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}

- (IBAction) hitRateEnableAction:(id)sender
{
	[[self undoManager] setActionName: @"Set HitRate Enabled"];
	[model setHitRateEnabled:[[sender selectedCell] tag] withValue:[sender intValue]];
}


- (IBAction) reportButtonAction:(id)sender
{
	[self endEditing];
	@try {
		[model printVersions];
		[model printStatusReg];
		[model printPStatusRegs];
		[model printValueTable];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT (%d) status\n",[model stationNumber]);
        ORRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) initBoardButtonAction:(id)sender
{
	[self endEditing];
	@try {
		[model initBoard];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception intitBoard FLT (%d) status\n",[model stationNumber]);
        ORRunAlertPanel([localException name], @"%@\nWrite of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORKatrinHgfAmcSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) modeAction: (id) sender
{
	[model setRunMode:(int)[[modeButton selectedItem] tag]];
}

- (IBAction) versionAction: (id) sender
{
	@try {
		[model printVersions];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT HW Model Version\n");
        ORRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) testAction: (id) sender
{
	@try {
		[model runTests];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT HW Model Test\n");
        ORRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}


- (IBAction) resetAction: (id) sender
{
	@try {
		[model reset];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception during FLT reset\n");
        ORRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) hitRateLengthAction: (id) sender
{
	if([sender indexOfSelectedItem] != [model hitRateLength]){
		[[self undoManager] setActionName: @"Set Hit Rate Length"]; 
		[model setHitRateLength:[[sender selectedItem] tag]];
	}
}

- (IBAction) hitRateAllAction: (id) sender
{
	[model enableAllHitRates:YES];
}

- (IBAction) hitRateNoneAction: (id) sender
{
	[model enableAllHitRates:NO];
}

- (IBAction) enableAllTriggersAction: (id) sender
{
	[model enableAllTriggers:YES];
}

- (IBAction) enableNoTriggersAction: (id) sender
{
	[model enableAllTriggers:NO];
}

- (IBAction) fireSoftwareTriggerAction: (id) sender
{
	NSLog(@"Fire Software Trigger!\n");
	@try {
	    [model fireSoftwareTrigger];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception during FLT read status\n");
        ORRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) statusAction:(id)sender
{
	@try {
		[model printStatusReg];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception during FLT read status\n");
        ORRunAlertPanel([localException name], @"%@\nRead of FLT%d failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) selectRegisterAction:(id) aSender
{
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[model undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
    }
}

- (IBAction) selectChannelAction:(id) aSender
{
    if ([[aSender selectedItem] tag] != [model selectedChannelValue]){
	    [[model undoManager] setActionName:@"Select Channel Number"]; // Set undo name do it at model side -tb-
	    [model setSelectedChannelValue:[[aSender selectedItem] tag]]; // set new value
    }
}

- (IBAction) writeValueAction:(id) aSender
{
	[self endEditing];
    if ([aSender intValue] != [model writeValue]){
		[[model undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}

- (IBAction) readRegAction: (id) sender
{
	int index = [model selectedRegIndex];
	@try {
		uint32_t value;
        if(([model accessTypeOfReg:index] & kChanReg)){
            int chan = [model selectedChannelValue];
		    value = [model readReg:index channel: chan ];
		    NSLog(@"FLTv4 reg: %@ for channel %i has value: 0x%x (%i)\n",[model getRegisterName:index], chan, value, value);
        }
		else {
		    value = [model readReg:index ];
		    NSLog(@"FLTv4 reg: %@ has value: 0x%x (%i)\n",[model getRegisterName:index],value, value);
        }
	}
	@catch(NSException* localException) {
		NSLog(@"Exception reading FLT reg: %@\n",[model getRegisterName:index]);
        ORRunAlertPanel([localException name], @"%@\nSLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) writeRegAction: (id) sender
{
	[self endEditing];
	int index = (int)[registerPopUp indexOfSelectedItem];
	@try {
		uint32_t val = [model writeValue];
        if(([model accessTypeOfReg:index] & kChanReg)){
            int chan = [model selectedChannelValue];
     		[model writeReg:index  channel: chan value: val];//TODO: allow hex values, e.g. 0x23 -tb-
    		NSLog(@"wrote 0x%x (%i) to FLTv4 reg: %@ channel %i\n", val, val, [model getRegisterName:index], chan);
        }
		else{
    		[model writeReg:index value: val];//TODO: allow hex values, e.g. 0x23 -tb-
    		NSLog(@"wrote 0x%x (%i) to FLTv4 reg: %@ \n",val,val,[model getRegisterName:index]);
        }
	}
	@catch(NSException* localException) {
		NSLog(@"Exception writing FLTv4 reg: %@\n",[model getRegisterName:index]);
        ORRunAlertPanel([localException name], @"%@\nFLTv4%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) testButtonAction: (id) sender //temp routine to hook up to any on a temp basis
{
	@try {
		[model testReadHisto];
	}
	@catch(NSException* localException) {
		NSLog(@"Exception running FLT test code\n");
        ORRunAlertPanel([localException name], @"%@\nFLT%d Access failed", @"OK", nil, nil,
                        localException,[model stationNumber]);
	}
}

- (IBAction) devTest1ButtonAction: (id) sender
{
    NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
	//ORRunAboutToChangeState
	[model devTest1ButtonAction];
}

- (IBAction) devTest2ButtonAction: (id) sender
{
    NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
	[model devTest2ButtonAction];
}

- (IBAction) testButtonLowLevelAction: (id) sender
{
    NSLog(@"Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
    if(sender==configTPButton){
        NSLog(@"   configTPButton: Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
	    [model testButtonLowLevelConfigTP];
	}

    if(sender==fireTPButton){
        NSLog(@"   fireTPButton: Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
	    [model testButtonLowLevelFireTP];
	}

    if(sender==resetTPButton){
        NSLog(@"   resetTPButton: Called %@::%@\n",NSStringFromClass([self class]),NSStringFromSelector(_cmd));//DEBUG -tb-
	    [model testButtonLowLevelResetTP];
	}
}

- (IBAction) compareRegisters:(id)sender
{
    [(ORKatrinHgfAmcModel*) model compareRegisters:YES];
 }

#pragma mark •••Plot DataSource
- (int) numberPointsInPlot:(id)aPlotter
{
	return (int)[[model  totalRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int count = (int)[[model totalRate]count];
	int index = count-i-1;
	*yValue =  [[model totalRate] valueAtIndex:index];
	*xValue =  [[model totalRate] timeSampledAtIndex:index];
}

@end



