//
//SNOCaenController.m
//Orca
//
//Created by Mark Howe on Mon Apr 14 2008.
//Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//
//-------------------------------------------------------------
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

#import "SNOCaenController.h"
#import "ORCaenDataDecoder.h"
#import "SNOCaenModel.h"
#import "ORValueBar.h"
#import "ORTimeRate.h"
#import "ORRate.h"
#import "ORRateGroup.h"
#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORCompositePlotView.h"
#import "ORValueBarGroupView.h"

#define kNumChanConfigBits 5
#define kNumTrigSourceBits 10

static int chanConfigToMaskBit[kNumChanConfigBits] = {1,3,4,6,11};

@implementation SNOCaenController

#pragma mark ***Initialization
- (id) init
{
    self = [ super initWithWindowNibName: @"Caen1720" ];
    return self;
}

- (void) dealloc
{
	[blankView release];
	[super dealloc];
}

- (void) awakeFromNib
{
	
    basicSize      = NSMakeSize(280,400);
    settingsSize   = NSMakeSize(780,450);
    monitoringSize = NSMakeSize(783,320);
    
    blankView = [[NSView alloc] init];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];
	
    [registerAddressPopUp setAlignment:NSTextAlignmentCenter];
    [channelPopUp setAlignment:NSTextAlignmentCenter];
	
    [self populatePullDown];
   
	ORTimeLinePlot* aPlot = [[ORTimeLinePlot alloc] initWithTag:0 andDataSource:self];
	[timeRatePlot addPlot: aPlot];
	[(ORTimeAxis*)[timeRatePlot xAxis] setStartTime: [[NSDate date] timeIntervalSince1970]];
	[aPlot release];	
	
    [super awakeFromNib];
	
    NSString* key = [NSString stringWithFormat: @"orca.ORCaenCard%d.selectedtab",[model slot]];
    NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
    if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;
    [tabView selectTabViewItemAtIndex: index];
	
	[rate0 setNumber:8 height:10 spacing:5];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [ super registerNotificationObservers ];
	
    [notifyCenter addObserver : self
					 selector : @selector(baseAddressChanged:)
						 name : ORVmeIOCardBaseAddressChangedNotification
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegIndexChanged:)
						 name : SNOCaenSelectedRegIndexChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(selectedRegChannelChanged:)
						 name : SNOCaenSelectedChannelChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(writeValueChanged:)
						 name : SNOCaenWriteValueChanged
					   object : model];
	
    [notifyCenter addObserver : self
					 selector : @selector(thresholdChanged:)
						 name : SNOCaenChnlThresholdChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(dacChanged:)
						 name : SNOCaenChnlDacChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(overUnderChanged:)
						 name : SNOCaenOverUnderThresholdChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(channelConfigMaskChanged:)
                         name : SNOCaenModelChannelConfigMaskChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(customSizeChanged:)
                         name : SNOCaenModelCustomSizeChanged
					   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(isCustomSizeChanged:)
			     name : SNOCaenModelIsCustomSizeChanged
			   object : model];
	
	[notifyCenter addObserver : self
			 selector : @selector(isFixedSizeChanged:)
			     name : SNOCaenModelIsFixedSizeChanged
			   object : model];
	
	[notifyCenter addObserver : self
                     selector : @selector(countAllTriggersChanged:)
                         name : SNOCaenModelCountAllTriggersChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(acquisitionModeChanged:)
                         name : SNOCaenModelAcquisitionModeChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(coincidenceLevelChanged:)
                         name : SNOCaenModelCoincidenceLevelChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(triggerSourceMaskChanged:)
                         name : SNOCaenModelTriggerSourceMaskChanged
					   object : model];
	[notifyCenter addObserver : self
			 selector : @selector(triggerOutMaskChanged:)
			     name : SNOCaenModelTriggerOutMaskChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(fpIOControlChanged:)
			     name : SNOCaenModelFrontPanelControlMaskChanged
			   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(postTriggerSettingChanged:)
                         name : SNOCaenModelPostTriggerSettingChanged
					   object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(enabledMaskChanged:)
                         name : SNOCaenModelEnabledMaskChanged
					   object : model];
	
	[notifyCenter addObserver : self
					 selector : @selector(basicLockChanged:)
						 name : SNOCaenBasicLock
					   object : nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : SNOCaenSettingsLock
					   object : nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(basicLockChanged:)
						 name : SNOCaenBasicLock
					   object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(integrationChanged:)
                         name : ORRateGroupIntegrationChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(totalRateChanged:)
						 name : ORRateGroupTotalRateChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(settingsLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(basicLockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
	
	
    [notifyCenter addObserver : self
                     selector : @selector(setBufferStateLabel)
                         name : SNOCaenModelBufferCheckChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(eventSizeChanged:)
                         name : SNOCaenModelEventSizeChanged
						object: model];
	
    [notifyCenter addObserver : self
					 selector : @selector(slotChanged:)
						 name : ORVmeCardSlotChangedNotification
					   object : model];

    [notifyCenter addObserver : self
					 selector : @selector(continousRunsChanged:)
						 name : SNOCaenModelContinuousModeChanged
					   object : model];

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
		
        [notifyCenter addObserver:self
                         selector:@selector(waveFormRateChanged:)
                             name:ORRateChangedNotification
                           object:obj];
    }
}


#pragma mark ***Interface Management
- (void) updateWindow
{
	[super updateWindow];
    [self integrationChanged:nil];
    [self writeValueChanged:nil];
    [self totalRateChanged:nil];
    [self selectedRegIndexChanged:nil];
    [self selectedRegChannelChanged:nil];
	[self baseAddressChanged:nil];
	[self dacChanged:nil];
	[self thresholdChanged:nil];
	[self overUnderChanged:nil];
	[self channelConfigMaskChanged:nil];
	[self customSizeChanged:nil];
	[self isCustomSizeChanged:nil];
	[self isFixedSizeChanged:nil];
	[self countAllTriggersChanged:nil];
	[self acquisitionModeChanged:nil];
	[self coincidenceLevelChanged:nil];
	[self triggerSourceMaskChanged:nil];
	[self triggerOutMaskChanged:nil];
	[self fpIOControlChanged:nil];
	[self postTriggerSettingChanged:nil];
	[self enabledMaskChanged:nil];
    [self waveFormRateChanged:nil];
 	[self eventSizeChanged:nil];
 	[self slotChanged:nil];
    [self continousRunsChanged:nil];
	
	[self settingsLockChanged:nil];
    [self basicLockChanged:nil];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[slot1Field setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"%@",[model identifier]]];
}

- (void) eventSizeChanged:(NSNotification*)aNote
{
    [eventSizePopUp selectItemAtIndex: [model eventSize]];
    /* Set the text field in samples. For the conversion between the buffer
     * organization register and the number of samples see Section 4.15 in the
     * user manual. */
    [eventSizeTextField setIntValue: (1 << (20-[model eventSize]))];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:SNOCaenBasicLock to:secure];
    [basicLockButton setEnabled:secure];
    [gSecurity setLock:SNOCaenSettingsLock to:secure];
    [settingsLockButton setEnabled:secure];
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

- (void) setBufferStateLabel
{
	if(![gOrcaGlobals runInProgress]){
		[bufferStateField setTextColor:[NSColor blackColor]];
		[bufferStateField setStringValue:@"--"];
	}
	else {
		int val = [model bufferState];
		if(val) {
			[bufferStateField setTextColor:[NSColor redColor]];
			[bufferStateField setStringValue:@"Full"];
		}
		else {
			[bufferStateField setTextColor:[NSColor blackColor]];
			[bufferStateField setStringValue:@"Ready"];
		}
	}
}

- (void) totalRateChanged:(NSNotification*)aNotification
{
	ORRateGroup* theRateObj = [aNotification object];
	if(aNotification == nil || [model waveFormRateGroup] == theRateObj){
		
		[totalRateText setFloatValue: [theRateObj totalRate]];
		[totalRate setNeedsDisplay:YES];
	}
}

- (void) waveFormRateChanged:(NSNotification*)aNote
{
    ORRate* theRateObj = [aNote object];		
    [[rateTextFields cellWithTag:[theRateObj tag]] setFloatValue: [theRateObj rate]];
    [rate0 setNeedsDisplay:YES];
}

- (void) writeValueChanged:(NSNotification*) aNotification
{
	//  Set value of both text and stepper
	[self updateStepper:writeValueStepper setting:[model writeValue]];
	[writeValueTextField setIntegerValue:[model writeValue]];
}

- (void) selectedRegIndexChanged:(NSNotification*) aNotification
{
	
	//  Set value of popup
	short index = [model selectedRegIndex];
	[self updatePopUpButton:registerAddressPopUp setting:index];
	[self updateRegisterDescription:index];
	
	
	BOOL readAllowed = [model getAccessType:index] == kReadOnly || [model getAccessType:index] == kReadWrite;
	BOOL writeAllowed = [model getAccessType:index] == kWriteOnly || [model getAccessType:index] == kReadWrite;
	
	[basicWriteButton setEnabled:writeAllowed];
	[basicReadButton setEnabled:readAllowed];
	
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:SNOCaenBasicLock];
	if ([model selectedRegIndex] >= kZS_Thres && [model selectedRegIndex]<=kAdcConfig){
		[channelPopUp setEnabled:!lockedOrRunningMaintenance];
	}
	else [channelPopUp setEnabled:NO];
	
}

- (void) selectedRegChannelChanged:(NSNotification*) aNotification
{
	[self updatePopUpButton:channelPopUp setting:[model selectedChannel]];
}

- (void) enabledMaskChanged:(NSNotification*)aNote
{
	int i;
	unsigned short mask = [model enabledMask];
	for(i=0;i<[model numberOfChannels];i++){
		[[enabledMaskMatrix cellWithTag:i] setIntValue:(mask & (1<<i)) !=0];
		[[enabled2MaskMatrix cellWithTag:i] setIntValue:(mask & (1<<i)) !=0];
	}
}

- (void) postTriggerSettingChanged:(NSNotification*)aNote
{
	//todo *4 in std mode *5 in packed mode
	[postTriggerSettingTextField setIntegerValue:([model postTriggerSetting] * 4)];
}

- (void) triggerSourceMaskChanged:(NSNotification*)aNote
{
	int i;
	uint32_t mask = [model triggerSourceMask];
	for(i=0;i<8;i++){
		[[chanTriggerMatrix cellWithTag:i] setIntValue:(mask & (1L << i)) !=0];
	}
	[[otherTriggerMatrix cellWithTag:0] setIntValue:(mask & (1L << 30)) !=0];
	[[otherTriggerMatrix cellWithTag:1] setIntValue:(mask & (1L << 31)) !=0];
}

- (void) triggerOutMaskChanged:(NSNotification*)aNote
{
	int i;
	uint32_t mask = [model triggerOutMask];
	for(i=0;i<8;i++){
		[[chanTriggerOutMatrix cellWithTag:i] setIntValue:(mask & (1L << i)) !=0];
	}
	[[otherTriggerOutMatrix cellWithTag:0] setIntValue:(mask & (1L << 30)) !=0];
	[[otherTriggerOutMatrix cellWithTag:1] setIntValue:(mask & (1L << 31)) !=0];
}

- (void) fpIOControlChanged:(NSNotification*)aNote
{
	[fpIOModeMatrix selectCellWithTag:([model frontPanelControlMask] >> 6) & 0x3UL];
	[fpIOPatternLatchMatrix selectCellWithTag:([model frontPanelControlMask] >> 9) & 0x1UL];
	[fpIOTrgInMatrix selectCellWithTag:([model frontPanelControlMask] & 0x1UL)];
	[fpIOTrgOutMatrix selectCellWithTag:([model frontPanelControlMask] >> 1) & 0x1UL];
	[fpIOLVDS0Matrix selectCellWithTag:([model frontPanelControlMask] >> 2) & 0x1UL];
	[fpIOLVDS1Matrix selectCellWithTag:([model frontPanelControlMask] >> 3) & 0x1UL];
	[fpIOLVDS2Matrix selectCellWithTag:([model frontPanelControlMask] >> 4) & 0x1UL];
	[fpIOLVDS3Matrix selectCellWithTag:([model frontPanelControlMask] >> 5) & 0x1UL];
	[fpIOTrgOutModeMatrix selectCellWithTag:([model frontPanelControlMask] >> 14) & 0x3UL];
}

- (void) coincidenceLevelChanged:(NSNotification*)aNote
{
	[coincidenceLevelTextField setIntValue: [model coincidenceLevel]];
}

- (void) acquisitionModeChanged:(NSNotification*)aNote
{
	[acquisitionModeMatrix selectCellWithTag:[model acquisitionMode]];
}

- (void) countAllTriggersChanged:(NSNotification*)aNote
{
	[countAllTriggersMatrix selectCellWithTag: [model countAllTriggers]];
}

- (void) customSizeChanged:(NSNotification*)aNote
{
	//todo: *4 in std mode, *5 in packed mode
	[customSizeTextField setIntegerValue:([model customSize] * 4)];
}

- (void) isCustomSizeChanged:(NSNotification*)aNote
{
	[customSizeButton setIntValue:[model isCustomSize]];
	[customSizeTextField setEnabled:[model isCustomSize]];
}

- (void) isFixedSizeChanged:(NSNotification*)aNote
{
	[fixedSizeButton setIntValue:[model isFixedSize]];
}

- (void) channelConfigMaskChanged:(NSNotification*)aNote
{
	int i;
	unsigned short mask = [model channelConfigMask];
	for(i=0;i<kNumChanConfigBits;i++){
		[[channelConfigMaskMatrix cellWithTag:i] setIntValue:(mask & (1<<chanConfigToMaskBit[i])) !=0];
	}
}

- (void) baseAddressChanged:(NSNotification*) aNotification
{
	//  Set value of both text and stepper
	[self updateStepper:addressStepper setting:[model baseAddress]];
	[addressTextField setIntegerValue:[model baseAddress]];
}

- (void) thresholdChanged:(NSNotification*) aNotification
{
	// Get the channel that changed and then set the GUI value using the model value.
	if(aNotification){
		int chnl = [[[aNotification userInfo] objectForKey:SNOCaenChnl] intValue];
		[[thresholdMatrix cellWithTag:chnl] setIntValue:[model threshold:chnl]];
	}
	else {
		int i;
		for (i = 0; i < [model numberOfChannels]; i++){
			[[thresholdMatrix cellWithTag:i] setIntValue:[model threshold:i]];
		}
	}
}

- (void) dacChanged: (NSNotification*) aNotification
{
	if(aNotification){
		int chnl = [[[aNotification userInfo] objectForKey:SNOCaenChnl] intValue];
		[[dacMatrix cellWithTag:chnl] setFloatValue:[model convertDacToVolts:[model dac:chnl]]];
	}
	else {
		int i;
		for (i = 0; i < [model numberOfChannels]; i++){
			[[dacMatrix cellWithTag:i] setFloatValue:[model convertDacToVolts:[model dac:i]]];
		}
	}
}

- (void) overUnderChanged: (NSNotification*) aNotification
{
	if(aNotification){
		int chnl = [[[aNotification userInfo] objectForKey:SNOCaenChnl] intValue];
		[[overUnderMatrix cellWithTag:chnl] setIntValue:[model overUnderThreshold:chnl]];
	}
	else {
		int i;
		for (i = 0; i < [model numberOfChannels]; i++){
			[[overUnderMatrix cellWithTag:i] setIntValue:[model overUnderThreshold:i]];
		}
	}
}

- (void) continousRunsChanged:(NSNotification *)aNote
{
    [continousRunsButton setIntValue:[model continuousMode]];
}

- (void) basicLockChanged:(NSNotification*)aNotification
{	
    BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL locked						= [gSecurity isLocked:SNOCaenBasicLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:SNOCaenBasicLock];
	
    [basicLockButton setState: locked];
    
    [addressStepper setEnabled:!locked && !runInProgress];
    [addressTextField setEnabled:!locked && !runInProgress];
	
    [writeValueStepper setEnabled:!lockedOrRunningMaintenance];
    [writeValueTextField setEnabled:!lockedOrRunningMaintenance];
    [registerAddressPopUp setEnabled:!lockedOrRunningMaintenance];
	
    [self selectedRegIndexChanged:nil];
	
    [basicWriteButton setEnabled:!lockedOrRunningMaintenance];
    [basicReadButton setEnabled:!lockedOrRunningMaintenance]; 
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:SNOCaenBasicLock])s = @"Not in Maintenance Run.";
    }
    [basicLockDocField setStringValue:s];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{	
    BOOL runInProgress				= [gOrcaGlobals runInProgress];
    BOOL locked						= [gSecurity isLocked:SNOCaenSettingsLock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:SNOCaenSettingsLock];
    [settingsLockButton setState: locked];
	[self setBufferStateLabel];
    [thresholdMatrix setEnabled:!locked];
    [overUnderMatrix setEnabled:!locked];
    [otherTriggerMatrix setEnabled:!locked];
    [chanTriggerMatrix setEnabled:!locked];
	[otherTriggerOutMatrix setEnabled:!locked];
	[chanTriggerOutMatrix setEnabled:!locked];
	[fpIOModeMatrix setEnabled:!locked];
	[fpIOLVDS0Matrix setEnabled:!locked];
	[fpIOLVDS1Matrix setEnabled:!locked];
	[fpIOLVDS2Matrix setEnabled:!locked];
	[fpIOLVDS3Matrix setEnabled:!locked];
	[fpIOPatternLatchMatrix setEnabled:!locked];
	[fpIOTrgInMatrix setEnabled:!locked];
    [fpIOTrgOutMatrix setEnabled:!locked];
    [fpIOTrgOutModeMatrix setEnabled:!locked];
	[fpIOGetButton setEnabled:!locked];
	[fpIOSetButton setEnabled:!lockedOrRunningMaintenance];
    [postTriggerSettingTextField setEnabled:!locked];
    [triggerSourceMaskMatrix setEnabled:!locked];
    [coincidenceLevelTextField setEnabled:!locked];
    [dacMatrix setEnabled:!locked];
    [acquisitionModeMatrix setEnabled:!locked];
    [countAllTriggersMatrix setEnabled:!locked];
    [channelConfigMaskMatrix setEnabled:!locked];
    [eventSizePopUp setEnabled:!locked];
    [customSizeTextField setEnabled:!locked && [model isCustomSize]];
    [customSizeButton setEnabled:!locked];
    [fixedSizeButton setEnabled:!locked];
    [eventSizePopUp setEnabled:!locked];
    [enabledMaskMatrix setEnabled:!locked];

	//these must NOT or can not be changed when run in progress
    [loadThresholdsButton setEnabled:!lockedOrRunningMaintenance];
    [initButton setEnabled:!lockedOrRunningMaintenance];
    [softwareTriggerButton setEnabled:!lockedOrRunningMaintenance];

    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:SNOCaenSettingsLock])s = @"Not in Maintenance";
    }
    [settingsLockDocField setStringValue:s];
	
	
}

#pragma mark •••Actions

- (void) eventSizeAction:(id)sender
{
	[model setEventSize:(int)[sender indexOfSelectedItem]];	
}

- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    if([sender doubleValue] != [[model waveFormRateGroup]integrationTime]){
        [model setRateIntegrationTime:[sender doubleValue]];		
    }
}
- (IBAction) baseAddressAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender intValue] != [model baseAddress]){
		[[[model document] undoManager] setActionName:@"Set Base Address"]; // Set undo name.
		[model setBaseAddress:[aSender intValue]]; // set new value.
    }
} 

- (IBAction) basicRead:(id) pSender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		[model read];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nRead of %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:[model selectedRegIndex]]);
    }
}

- (IBAction) basicWrite:(id) pSender
{
	@try {
		[self endEditing];		// Save in memory user changes before executing command.
		[model write];
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nWrite to %@ failed", @"OK", nil, nil,
                        localException,[model getRegisterName:[model selectedRegIndex]]);
    }
}

- (IBAction) writeValueAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender intValue] != [model writeValue]){
		[[[model document] undoManager] setActionName:@"Set Write Value"]; // Set undo name.
		[model setWriteValue:[aSender intValue]]; // Set new value
    }
}

- (IBAction) selectRegisterAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender indexOfSelectedItem] != [model selectedRegIndex]){
	    [[[model document] undoManager] setActionName:@"Select Register"]; // Set undo name
	    [model setSelectedRegIndex:[aSender indexOfSelectedItem]]; // set new value
    }
}

- (IBAction) selectChannelAction:(id) aSender
{
    // Make sure that value has changed.
    if ([aSender indexOfSelectedItem] != [model selectedChannel]){
		[[[model document] undoManager] setActionName:@"Select Channel"]; // Set undo name
		[model setSelectedChannel:[aSender indexOfSelectedItem]]; // Set new value
    }
}
- (IBAction) basicLockAction:(id)sender
{
    [gSecurity tryToSetLock:SNOCaenBasicLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) settingsLockAction:(id)sender
{
    [gSecurity tryToSetLock:SNOCaenSettingsLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) report: (id) sender
{
	@try {
		[model report];
	}
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nRead failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) loadThresholds: (id) sender
{
	@try {
		[model writeThresholds];
		NSLog(@"Caen 1720 Card %d thresholds loaded\n",[model slot]);
	}
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nThreshold loading failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) initBoard: (id) sender
{
    [self endEditing];

	@try {
		[model initBoard];
	}
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nInit failed", @"OK", nil, nil,
                        localException);
	}
}


- (void) enabledMaskAction:(id)sender
{
	int i;
	unsigned short mask = 0;
	for(i=0;i<[model numberOfChannels];i++){
		if([[sender cellWithTag:i] intValue]) mask |= (1 << i);
	}
	[model setEnabledMask:mask];	
	
}

- (void) postTriggerSettingTextFieldAction:(id)sender
{
	//todo /4 in std mode /5 in packed mode
	[model setPostTriggerSetting:([sender intValue] / 4)];	
}

- (IBAction) triggerSourceMaskAction:(id)sender
{
	int i;
	uint32_t mask = 0;
	for(i=0;i<8;i++){
		if([[chanTriggerMatrix cellWithTag:i] intValue]) mask |= (1L << i);
	}
	if([[otherTriggerMatrix cellWithTag:0] intValue]) mask |= (1L << 30);
	if([[otherTriggerMatrix cellWithTag:1] intValue]) mask |= (1L << 31);
	[model setTriggerSourceMask:mask];	
}

- (IBAction) triggerOutMaskAction:(id)sender
{
	int i;
	uint32_t mask = 0;
	for(i=0;i<8;i++){
		if([[chanTriggerOutMatrix cellWithTag:i] intValue]) mask |= (1L << i);
	}
	if([[otherTriggerOutMatrix cellWithTag:0] intValue]) mask |= (1L << 30);
	if([[otherTriggerOutMatrix cellWithTag:1] intValue]) mask |= (1L << 31);
	[model setTriggerOutMask:mask];	
}

- (IBAction) fpIOControlAction:(id)sender
{
	
	uint32_t mask = 0;
	mask |= [[fpIOModeMatrix selectedCell] tag] << 6;
	mask |= [[fpIOPatternLatchMatrix selectedCell] tag] << 9;
	mask |= [[fpIOTrgInMatrix selectedCell] tag];
	mask |= [[fpIOTrgOutMatrix selectedCell] tag] << 1;
	mask |= [[fpIOLVDS0Matrix selectedCell] tag] << 2;
	mask |= [[fpIOLVDS1Matrix selectedCell] tag] << 3;
	mask |= [[fpIOLVDS2Matrix selectedCell] tag] << 4;
	mask |= [[fpIOLVDS3Matrix selectedCell] tag] << 5;
	mask |= [[fpIOTrgOutModeMatrix selectedCell] tag] << 14;
	
	[model setFrontPanelControlMask:mask];	
}

- (IBAction) fpIOGetAction:(id)sender
{
	@try {
		[model readFrontPanelControl];
	}
	@catch(NSException* localException) {
		ORRunAlertPanel([localException name], @"%@\nGet Front Panel Failed", @"OK", nil, nil,
				localException);
	}
}

- (IBAction) fpIOSetAction:(id)sender
{
	@try {
		[model writeFrontPanelControl];
	}
	@catch(NSException* localException) {
		ORRunAlertPanel([localException name], @"%@\nSet Front Panel Failed", @"OK", nil, nil,
				localException);
	}
}

- (IBAction) coincidenceLevelTextFieldAction:(id)sender
{
	[model setCoincidenceLevel:[sender intValue]];	
}

- (IBAction) generateTriggerAction:(id)sender
{
	@try {
		[model generateSoftwareTrigger];
	}
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nSoftware Trigger Failed", @"OK", nil, nil,
                        localException);
	}
}

- (IBAction) acquisitionModeAction:(id)sender
{
	[model setAcquisitionMode:[[sender selectedCell] tag]];	
}

- (IBAction) countAllTriggersAction:(id)sender
{
	[model setCountAllTriggers:[[sender selectedCell] tag]];	
}

- (IBAction) customSizeAction:(id)sender
{
	uint32_t maxNumSamples =  1024 * 1024./powf(2.,(float)[model eventSize]) / 2;
	if(maxNumSamples > [sender intValue]) {
		//todo /4 in std mode /5 in packed mode
		[model setCustomSize:([sender intValue] / 4)];
	}
	else {
		[model setCustomSize:maxNumSamples / 4];
	}
}

- (IBAction) isCustomSizeAction:(id)sender
{
	[model setIsCustomSize:[sender intValue]];	
}

- (IBAction) isFixedSizeAction:(id)sender
{
	
	//incompatible with overlapping triggers, gate acq, and zero length encoding
	//trigger overlap || sync-in gate
	if (([model channelConfigMask] & 0x2UL) || ([model acquisitionMode] == 2)) {
		ORRunAlertPanel(@"You will loose data! Fixed Event Size is not compatible with Trigger Overlap and Sync-In Gate acq mode",
					@"Fixed event size doesn't poll the card to get the next event size, and doesn't flush CAEN buffer on memory full. It's faster and fits better heavy bursts. Disable trigger overlap and sync-in gate.",
					@"OK", nil, nil);
		[model setIsFixedSize:NO];
	}
	else {
		[model setIsFixedSize:[sender intValue]];
	}

}

- (IBAction) channelConfigMaskAction:(id)sender
{
	int i;
	unsigned short mask = 0;
	for(i=0;i<kNumChanConfigBits;i++){
		if([[sender cellWithTag:i] intValue]) mask |= (1 << chanConfigToMaskBit[i]);
	}
	[model setChannelConfigMask:mask];	
}

- (IBAction) dacAction:(id) aSender
{
	[[[model document] undoManager] setActionName:@"Set dacs"]; // Set name of undo.
	[model setDac:[[aSender selectedCell] tag] withValue:[model convertVoltsToDac:[[aSender selectedCell] floatValue]]]; // Set new value
}

- (IBAction) overUnderAction: (id) aSender
{
	[[[model document] undoManager] setActionName:@"Set Over_Under"]; // Set name of undo.
	[model setOverUnderThreshold:[[aSender selectedCell] tag] withValue:[[aSender selectedCell] intValue]]; // Set new value
}

- (IBAction) thresholdAction:(id) aSender
{
    if ([aSender intValue] != [model threshold:[[aSender selectedCell] tag]]){
        [[[model document] undoManager] setActionName:@"Set thresholds"]; // Set name of undo.
        [model setThreshold:[[aSender selectedCell] tag] withValue:[aSender intValue]]; // Set new value
    }
}

- (IBAction)countinuousRunsAction:(id)sender
{
    [model setContinuousMode:[sender intValue]];
}

#pragma mark ***Misc Helpers
- (void) populatePullDown
{
    short	i;
	
    [registerAddressPopUp removeAllItems];
    [channelPopUp removeAllItems];
    
    for (i = 0; i < [model getNumberRegisters]; i++) {
        [registerAddressPopUp insertItemWithTitle:[model 
												   getRegisterName:i] 
										  atIndex:i];
    }
	
	for (i = 0; i < 8 ; i++) {
        [channelPopUp insertItemWithTitle:[NSString stringWithFormat:@"%d", i] 
								  atIndex:i];
    }
    [channelPopUp insertItemWithTitle:@"All" atIndex:8];
    
    [self selectedRegIndexChanged:nil];
    [self selectedRegChannelChanged:nil];
	
}

- (void) updateRegisterDescription:(short) aRegisterIndex
{
    NSString* types[] = {
		@"[ReadOnly]",
		@"[WriteOnly]",
		@"[ReadWrite]"
    };
	
    [registerOffsetTextField setStringValue:
	 [NSString stringWithFormat:@"0x%04x",
	  [model getAddressOffset:aRegisterIndex]]];
	
    [registerReadWriteTextField setStringValue:types[[model getAccessType:aRegisterIndex]]];
    [regNameField setStringValue:[model getRegisterName:aRegisterIndex]];
	
    [drTextField setStringValue:[model dataReset:aRegisterIndex] ? @"Y" :@"N"];
    [srTextField setStringValue:[model swReset:aRegisterIndex]   ? @"Y" :@"N"];
    [hrTextField setStringValue:[model hwReset:aRegisterIndex]   ? @"Y" :@"N"];    
}

- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([tabView indexOfTabViewItem:tabViewItem] == 0){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:basicSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 1){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:settingsSize];
		[[self window] setContentView:tabView];
    }
    else if([tabView indexOfTabViewItem:tabViewItem] == 2){
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:monitoringSize];
		[[self window] setContentView:tabView];
    }
	
    NSString* key = [NSString stringWithFormat: @"orca.ORCaenCard%d.selectedtab",[model slot]];
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
