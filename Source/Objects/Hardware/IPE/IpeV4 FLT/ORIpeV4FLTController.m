//
//  ORIpeV4FLTController.m
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
#import "ORIpeV4FLTController.h"
#import "ORIpeV4FLTModel.h"
#import "ORIpeV4FLTDefs.h"
#import "SLTv4_HW_Definitions.h"
#import "ORFireWireInterface.h"
#import "ORTimeRate.h"
#import "ORPlotView.h"
#import "ORTimeLinePlot.h"
#import "ORValueBar.h"
#import "ORTimeAxis.h"
#import "ORValueBarGroupView.h"
#import "ORCompositePlotView.h"

@implementation ORIpeV4FLTController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"IpeV4FLT"];
    
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
	
    settingSize			= NSMakeSize(670,720);
    rateSize			= NSMakeSize(490,690);
    testSize			= NSMakeSize(400,350);
    lowlevelSize		= NSMakeSize(400,350);
	
	rateFormatter = [[NSNumberFormatter alloc] init];
	[rateFormatter setFormat:@"##0.00"];
	[totalHitRateField setFormatter:rateFormatter];
	[rateTextFields setFormatter:rateFormatter];
    blankView = [[NSView alloc] init];
    
    NSString* key = [NSString stringWithFormat: @"orca.ORIpeV4FLT%d.selectedtab",[model stationNumber]];
    int index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	

	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];
	
	[self populatePullDown];
	[self updateWindow];
	
	[rate0 setNumber:24 height:10 spacing:6];

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
                         name : ORIpeV4FLTSettingsLock
                        object: nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORIpeCardSlotChangedNotification
					   object : model];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(modeChanged:)
                         name : ORIpeV4FLTModelModeChanged
                       object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(thresholdChanged:)
						 name : ORIpeV4FLTModelThresholdChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(gainChanged:)
						 name : ORIpeV4FLTModelGainChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(triggerEnabledChanged:)
						 name : ORIpeV4FLTModelTriggerEnabledMaskChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(hitRateEnabledChanged:)
						 name : ORIpeV4FLTModelHitRateEnabledMaskChanged
					   object : model];
		
	
    [notifyCenter addObserver : self
					 selector : @selector(gainArrayChanged:)
						 name : ORIpeV4FLTModelGainsChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(thresholdArrayChanged:)
						 name : ORIpeV4FLTModelThresholdsChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(hitRateLengthChanged:)
						 name : ORIpeV4FLTModelHitRateLengthChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(hitRateChanged:)
						 name : ORIpeV4FLTModelHitRateChanged
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
                         name : ORIpeV4FLTModelTestEnabledArrayChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(testStatusArrayChanged:)
                         name : ORIpeV4FLTModelTestStatusArrayChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(updateWindow)
                         name : ORIpeV4FLTModelTestsRunningChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(interruptMaskChanged:)
                         name : ORIpeV4FLTModelInterruptMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(analogOffsetChanged:)
                         name : ORIpeV4FLTModelAnalogOffsetChanged
						object: model];
		
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : ORIpeV4FLTSelectedRegIndexChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : ORIpeV4FLTWriteValueChanged
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(selectedChannelValueChanged:)
						 name : ORIpeV4FLTSelectedChannelValueChanged
					   object : model];

    [notifyCenter addObserver : self
                     selector : @selector(fifoBehaviourChanged:)
                         name : ORIpeV4FLTModelFifoBehaviourChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(postTriggerTimeChanged:)
                         name : ORIpeV4FLTModelPostTriggerTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histRecTimeChanged:)
                         name : ORIpeV4FLTModelHistRecTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histMeasTimeChanged:)
                         name : ORIpeV4FLTModelHistMeasTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histNofMeasChanged:)
                         name : ORIpeV4FLTModelHistNofMeasChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(gapLengthChanged:)
                         name : ORIpeV4FLTModelGapLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(filterLengthChanged:)
                         name : ORIpeV4FLTModelFilterLengthChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(storeDataInRamChanged:)
                         name : ORIpeV4FLTModelStoreDataInRamChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(runBoxCarFilterChanged:)
                         name : ORIpeV4FLTModelRunBoxCarFilterChanged
						object: model];
    [notifyCenter addObserver : self
                     selector : @selector(histEMinChanged:)
                         name : ORIpeV4FLTModelHistEMinChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histEBinChanged:)
                         name : ORIpeV4FLTModelHistEBinChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histModeChanged:)
                         name : ORIpeV4FLTModelHistModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histClrModeChanged:)
                         name : ORIpeV4FLTModelHistClrModeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histFirstEntryChanged:)
                         name : ORIpeV4FLTModelHistFirstEntryChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histLastEntryChanged:)
                         name : ORIpeV4FLTModelHistLastEntryChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorChanged:)
                         name : ORIpeV4FLTNoiseFloorChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(noiseFloorOffsetChanged:)
                         name : ORIpeV4FLTNoiseFloorOffsetChanged
                       object : model];
    [notifyCenter addObserver : self
                     selector : @selector(histPageABChanged:)
                         name : ORIpeV4FLTModelHistPageABChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(histMaxEnergyChanged:)
                         name : ORIpeV4FLTModelHistMaxEnergyChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(targetRateChanged:)
                         name : ORIpeV4FLTModelTargetRateChanged
						object: model];

}

#pragma mark •••Interface Management
- (void) targetRateChanged:(NSNotification*)aNote
{
	[targetRateField setIntValue: [model targetRate]];
}

- (void) histMaxEnergyChanged:(NSNotification*)aNote
{
	[histMaxEnergyTextField setIntValue: [model histEMax]];
}

- (void) histPageABChanged:(NSNotification*)aNote
{
	[histPageABTextField setStringValue: [model histPageAB]?@"B":@"A"];
	//[histPageABTextField setIntValue: [model histPageAB]];
}
- (void) histLastEntryChanged:(NSNotification*)aNote
{
	[histLastEntryField setIntValue: [model histLastEntry]];
}

- (void) histFirstEntryChanged:(NSNotification*)aNote
{
	[histFirstEntryField setIntValue: [model histFirstEntry]];
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
	[histEMinTextField setIntValue: [model histEMin]];
}

- (void) runBoxCarFilterChanged:(NSNotification*)aNote
{
	[runBoxCarFilterCB setIntValue: [model runBoxCarFilter]];
}

- (void) storeDataInRamChanged:(NSNotification*)aNote
{
	[storeDataInRamCB setIntValue: [model storeDataInRam]];
}

- (void) filterLengthChanged:(NSNotification*)aNote
{
	[filterLengthPU selectItemAtIndex:[model filterLength]-2];
}

- (void) gapLengthChanged:(NSNotification*)aNote
{
	[gapLengthPU selectItemAtIndex: [model gapLength]];
}

- (void) histNofMeasChanged:(NSNotification*)aNote
{
	[histNofMeasField setIntValue: [model histNofMeas]];
}

- (void) histMeasTimeChanged:(NSNotification*)aNote
{
	[histMeasTimeField setIntValue: [model histMeasTime]];
}

- (void) histRecTimeChanged:(NSNotification*)aNote
{
	[histRecTimeField setIntValue: [model histRecTime]];
}

- (void) postTriggerTimeChanged:(NSNotification*)aNote
{
	[postTriggerTimeField setIntValue: [model postTriggerTime]];
}

- (void) fifoBehaviourChanged:(NSNotification*)aNote
{
	[fifoBehaviourMatrix selectCellWithTag: [model fifoBehaviour]];
}

- (void) analogOffsetChanged:(NSNotification*)aNote
{
	[analogOffsetField setIntValue: [model analogOffset]];
}

- (void) interruptMaskChanged:(NSNotification*)aNote
{
	[interruptMaskField setIntValue: [model interruptMask]];
}

- (void) populatePullDown
{
    short	i;
	
	// Clear all the popup items.
    [registerPopUp removeAllItems];
    
	// Populate the register popup
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerPopUp insertItemWithTitle:[model getRegisterName:i] atIndex:i];
    }
    
    
	// Clear all the popup items.
    [channelPopUp removeAllItems];
    
	// Populate the register popup
    for (i = 0; i < 24; i++) {
        [channelPopUp insertItemWithTitle: [NSString stringWithFormat: @"%i",i+1 ] atIndex:i];
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
	[self filterLengthChanged:nil];
	[self storeDataInRamChanged:nil];
	[self runBoxCarFilterChanged:nil];
	[self histEMinChanged:nil];
	[self histEBinChanged:nil];
	[self histModeChanged:nil];
	[self histClrModeChanged:nil];
	[self histFirstEntryChanged:nil];
	[self histLastEntryChanged:nil];
	[self noiseFloorChanged:nil];
	[self noiseFloorOffsetChanged:nil];
	[self histPageABChanged:nil];
	[self histMaxEnergyChanged:nil];
	[self targetRateChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORIpeV4FLTSettingsLock to:secure];
    [settingLockButton setEnabled:secure];	
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (void) updateButtons
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORIpeV4FLTSettingsLock];
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL locked = [gSecurity isLocked:ORIpeV4FLTSettingsLock];
	BOOL testsAreRunning = [model testsRunning];
	BOOL testingOrRunning = testsAreRunning | runInProgress;
    
    [testEnabledMatrix setEnabled:!locked && !testingOrRunning];
    [settingLockButton setState: locked];
	[initBoardButton setEnabled:!lockedOrRunningMaintenance];
	[reportButton setEnabled:!lockedOrRunningMaintenance];
	[modeButton setEnabled:!lockedOrRunningMaintenance];
	[resetButton setEnabled:!lockedOrRunningMaintenance];
    [gainTextFields setEnabled:!lockedOrRunningMaintenance];
    [thresholdTextFields setEnabled:!lockedOrRunningMaintenance];
    [triggerEnabledCBs setEnabled:!lockedOrRunningMaintenance];
    [hitRateEnabledCBs setEnabled:!lockedOrRunningMaintenance];
	
	[versionButton setEnabled:!runInProgress];
	[testButton setEnabled:!runInProgress];
	[statusButton setEnabled:!runInProgress];
	
    [hitRateLengthPU setEnabled:!lockedOrRunningMaintenance];
    [hitRateAllButton setEnabled:!lockedOrRunningMaintenance];
    [hitRateNoneButton setEnabled:!lockedOrRunningMaintenance];
		
	if(testsAreRunning){
		[testButton setEnabled: YES];
		[testButton setTitle: @"Stop"];
	}
    else {
		[testButton setEnabled: !runInProgress];	
		[testButton setTitle: @"Test"];
	}
	
	int fltRunMode = [model fltRunMode];
	[histNofMeasField setEnabled: !locked & (fltRunMode == kIpeFltV4Katrin_Histo_Mode)];
	[histMeasTimeField setEnabled: !locked & (fltRunMode == kIpeFltV4Katrin_Histo_Mode)];

	[startNoiseFloorButton setEnabled: runInProgress || [model noiseFloorRunning]];
	
 	[self enableRegControls];
}

- (void) enableRegControls
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORIpeV4FLTSettingsLock];
	short index = [model selectedRegIndex];
	BOOL readAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegReadable)>0;
	BOOL writeAllowed = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegWriteable)>0;
	BOOL needsChannel = !lockedOrRunningMaintenance && ([model getAccessType:index] & kIpeRegNeedsChannel)>0;

	
	[regWriteButton setEnabled:writeAllowed];
	[regReadButton setEnabled:readAllowed];
	
	[regWriteValueStepper setEnabled:writeAllowed];
	[regWriteValueTextField setEnabled:writeAllowed];
    
    //TODO: extend the accesstype to "channel" and "block64" -tb-
    [channelPopUp setEnabled: needsChannel];
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

- (void) noiseFloorOffsetChanged:(NSNotification*)aNote
{
	[noiseFloorOffsetField setIntValue:[model noiseFloorOffset]];
}


- (void) testEnabledArrayChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumIpeV4FLTTests;i++){
		[[testEnabledMatrix cellWithTag:i] setIntValue:[model testEnabled:i]];
	}    
}

- (void) testStatusArrayChanged:(NSNotification*)aNotification
{
	int i;
	for(i=0;i<kNumIpeV4FLTTests;i++){
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
	int chan = [[[aNotification userInfo] objectForKey:ORIpeV4FLTChan] intValue];
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
	int chan = [[[aNotification userInfo] objectForKey:ORIpeV4FLTChan] intValue];
	[[thresholdTextFields cellWithTag:chan] setIntValue: [(ORIpeV4FLTModel*)model threshold:chan]];
}


- (void) slotChanged:(NSNotification*)aNotification
{
	// Set title of FLT configuration window, ak 15.6.07
	[[self window] setTitle:[NSString stringWithFormat:@"IPE-DAQ-V4 FLT Card (Slot %d, FLT# %d)",[model slot]+1,[model stationNumber]]];
    [fltSlotNumTextField setStringValue: [NSString stringWithFormat:@"FLT# %d",[model stationNumber]]];
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
		[[thresholdTextFields cellWithTag:chan] setIntValue: [(ORIpeV4FLTModel*)model threshold:chan]];
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
	[modeButton selectItemAtIndex:[model runMode]];
	[self updateButtons];
}

- (void) hitRateLengthChanged:(NSNotification*)aNote
{
	[hitRateLengthPU selectItemWithTag:[model hitRateLength]];
}

- (void) hitRateChanged:(NSNotification*)aNote
{
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
	if(aNote==nil || [aNote object] == [model totalRate]){
		[timeRatePlot setNeedsDisplay:YES];
	}
}

- (void) selectedRegIndexChanged:(NSNotification*) aNote
{
	//	NSLog(@"This is v4FLT selectedRegIndexChanged\n" );
    //[registerPopUp selectItemAtIndex: [model selectedRegIndex]];
	[self updatePopUpButton:registerPopUp	 setting:[model selectedRegIndex]];
	
	[self enableRegControls];
}

- (void) writeValueChanged:(NSNotification*) aNote
{
    [regWriteValueTextField setIntValue: [model writeValue]];
}

- (void) selectedChannelValueChanged:(NSNotification*) aNote
{
    [channelPopUp selectItemWithTag: [model selectedChannelValue]];
	//[self updatePopUpButton:channelPopUp	 setting:[model selectedRegIndex]];
	
	[self enableRegControls];
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    [[self window] setContentView:blankView];
    switch([tabView indexOfTabViewItem:tabViewItem]){
        case  0: [self resizeWindowToSize:settingSize];     break;
		case  1: [self resizeWindowToSize:rateSize];	    break;
		case  2: [self resizeWindowToSize:testSize];        break;
		case  3: [self resizeWindowToSize:lowlevelSize];	break;
		default: [self resizeWindowToSize:testSize];	    break;
    }
    [[self window] setContentView:totalView];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORIpeV4FLT%d.selectedtab",[model stationNumber]];
    int index = [tabView indexOfTabViewItem:tabViewItem];
    [[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
    
}

#pragma mark •••Actions

- (void) targetRateAction:(id)sender
{
	[model setTargetRate:[sender intValue]];	
}

- (IBAction) openNoiseFloorPanel:(id)sender
{
	[self endEditing];
    [NSApp beginSheet:noiseFloorPanel modalForWindow:[self window]
		modalDelegate:self didEndSelector:NULL contextInfo:nil];
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
        NSLog(@"IPE V4 FLT (StationNumber %d) Finding Thresholds \n",[model stationNumber]);
		[model findNoiseFloors];
    }
	@catch(NSException* localException) {
        NSLog(@"Threshold Finder for IPE V4 FLT Board FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Threshold finder", @"OK", nil, nil,
                        localException);
    }
}
- (IBAction) noiseFloorOffsetAction:(id)sender
{
    if([sender intValue] != [model noiseFloorOffset]){
        [model setNoiseFloorOffset:[sender intValue]];
    }
}

- (IBAction) histClrModeAction:(id)sender
{
	[model setHistClrMode:[sender indexOfSelectedItem]];	
}

- (IBAction) histModeAction:(id)sender
{
	[model setHistMode:[sender indexOfSelectedItem]];	
}

- (IBAction) histEBinAction:(id)sender
{
	[model setHistEBin:[sender indexOfSelectedItem]];	
}

- (IBAction) histEMinAction:(id)sender
{
	[model setHistEMin:[sender intValue]];	
}

- (IBAction) runBoxCarFilterAction:(id)sender
{
	[model setRunBoxCarFilter:[sender intValue]];	
}

- (IBAction) storeDataInRamAction:(id)sender
{
	[model setStoreDataInRam:[sender intValue]];	
}

- (IBAction) filterLengthAction:(id)sender
{
	[model setFilterLength:[sender indexOfSelectedItem]+2];	 //tranlate back to range of 2 to 8
}

- (IBAction) gapLengthAction:(id)sender
{
	[model setGapLength:[sender indexOfSelectedItem]];	
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
		[model setFifoBehaviour:[[sender selectedCell]tag]];	
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
		[model setAnalogOffset:[sender intValue]];	
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
	for(i=0;i<kNumIpeV4FLTTests;i++){
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
	if([sender intValue] != [model gain:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Gain"];
		[model setGain:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
}

- (IBAction) thresholdAction:(id)sender
{
	if([sender intValue] != [(ORIpeV4FLTModel*)model threshold:[[sender selectedCell] tag]]){
		[[self undoManager] setActionName: @"Set Threshold"];
		[model setThreshold:[[sender selectedCell] tag] withValue:[sender intValue]];
	}
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
		//[model printPixelRegs];
		[model printValueTable];
		//[model printStatistics];
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
    [gSecurity tryToSetLock:ORIpeV4FLTSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) modeAction: (id) sender
{
	[model setRunMode:[modeButton indexOfSelectedItem]];
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
	NSLog(@"HW tests are currently not available!\n");//TODO: test mode does not exist any more ... -tb- 7/2010
	return;
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
		unsigned long value;
        if(([model getAccessType:index] & kIpeRegNeedsChannel)){
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
	int index = [registerPopUp indexOfSelectedItem];
	@try {
		unsigned long val = [model writeValue];
        if(([model getAccessType:index] & kIpeRegNeedsChannel)){
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

#pragma mark •••Plot DataSource
- (int) numberPointsInPlot:(id)aPlotter
{
	return [[model  totalRate]count];
}

- (void) plotter:(id)aPlotter index:(int)i x:(double*)xValue y:(double*)yValue
{
	int count = [[model totalRate]count];
	int index = count-i-1;
	*yValue =  [[model totalRate] valueAtIndex:index];
	*xValue =  [[model totalRate] timeSampledAtIndex:index];
}

@end



