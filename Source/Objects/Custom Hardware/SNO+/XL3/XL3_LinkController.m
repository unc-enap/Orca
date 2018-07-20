//
//  XL3_LinkController.m
//  ORCA
//
//  Created by Jarek Kaspar on Sat, Jul 9, 2010.
//  Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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
#import "PacketTypes.h"
#import "XL3_LinkController.h"
#import "XL3_Link.h"
#import "ORXL3Model.h"
#import "ORSNOCrateModel.h"
#import "ORQuadStateBox.h"

static NSArray* xl3RWModes;
static NSDictionary* xl3RWSelects;
static NSDictionary* xl3RWAddresses;
static NSDictionary* xl3Ops;

@implementation XL3_LinkController
@synthesize hvBStatusPanel;
@synthesize hvAStatusPanel;

#pragma mark •••Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"XL3_Link"];
	return self;
}



- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [msbox release];
	[super dealloc];
}

- (void) awakeFromNib
{
	basicSize	= NSMakeSize(485,290);
	compositeSize	= NSMakeSize(485,558);
	blankView = [[NSView alloc] init];
    [tabView setFocusRingType:NSFocusRingTypeNone];
    [self tabView:tabView didSelectTabViewItem:[tabView selectedTabViewItem]];

	[super awakeFromNib];
    
    NSDictionary *statedict = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSColor colorWithCalibratedRed:(30.0/255.0) green:(144.0/255.0) blue:1.0 alpha:1.0], @"closed",
                               [NSColor redColor], @"open",
                               [NSColor blackColor], @"unk",
                               nil];
    msbox = [[ORMultiStateBox alloc] initWithStates:statedict size:20 pad:4 bevel:2];

	NSString* key = [NSString stringWithFormat: @"orca.ORXL3%d.selectedtab",[model crateNumber]]; //uniqueIdNumber?
	NSInteger index = [[NSUserDefaults standardUserDefaults] integerForKey: key];
	if((index<0) || (index>[tabView numberOfTabViewItems]))index = 0;

	[tabView selectTabViewItemAtIndex: index];
	[self populateOps];
	[self populatePullDown];
	[self updateWindow];
}	

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	if(aModel) {
        [[self window] setTitle: [NSString stringWithFormat:@"XL3 Crate %d",[model crateNumber]]];
        [connectionIPAddressField setStringValue:[[model guardian] iPAddress]];
        [connectionIPPortField setStringValue:[NSString stringWithFormat:@"%u", [[model guardian] portNumber]]];
        [connectionCrateNumberField setStringValue:[NSString stringWithFormat:@"%d", [model crateNumber]]];
        [hvPowerSupplyMatrix selectCellAtRow:0 column:0];
        if ([model crateNumber] != 16) {
            [[hvPowerSupplyMatrix cellAtRow:0 column:1] setEnabled:NO];
            [hvPowerSupplyMatrix setHidden:true];
        }
        else {
            [[hvPowerSupplyMatrix cellAtRow:0 column:1] setEnabled:YES];
            [hvPowerSupplyMatrix setHidden:false];
        }
        [self hvChangePowerSupplyChanged:nil];
    }
    else {
        [[self window] setTitle: [NSString stringWithFormat:@"XL3 Crate"]];
        [connectionIPAddressField setStringValue:@"---"];
        [connectionIPPortField setStringValue:@"---"];
        [connectionCrateNumberField setStringValue:@"--"];
    }
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	[super registerNotificationObservers];

    [notifyCenter addObserver : self
                     selector : @selector(xl3LockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(xl3LockChanged:)
                         name : ORXL3Lock
                        object: nil];

	[notifyCenter addObserver : self
			 selector : @selector(linkConnectionChanged:)
			     name : XL3_LinkConnectionChanged
			    object: [model xl3Link]];

	[notifyCenter addObserver : self
			 selector : @selector(selectedRegisterChanged:)
			     name : ORXL3ModelSelectedRegisterChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(repeatCountChanged:)
			     name : ORXL3ModelRepeatCountChanged
			   object : model];
	
	[notifyCenter addObserver : self
			 selector : @selector(repeatDelayChanged:)
			     name : ORXL3ModelRepeatDelayChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(autoIncrementChanged:)
			     name : ORXL3ModelAutoIncrementChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(basicOpsRunningChanged:)
			     name : ORXL3ModelBasicOpsRunningChanged
			   object : model];
	
	[notifyCenter addObserver : self
			 selector : @selector(writeValueChanged:)
			     name : ORXL3ModelWriteValueChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(opsRunningChanged:)
			     name : ORXL3ModelXl3OpsRunningChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(compositeSlotMaskChanged:)
			     name : ORXL3ModelSlotMaskChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(compositeXl3ModeChanged:)
			     name : ORXL3ModelXl3ModeChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(compositeXl3ModeRunningChanged:)
			     name : ORXL3ModelXl3ModeRunningChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(compositeXl3RWAddressChanged:)
			     name : ORXL3ModelXl3RWAddressValueChanged
			   object : model];
	
	[notifyCenter addObserver : self
			 selector : @selector(compositeXL3RWDataChanged:)
			     name : ORXL3ModelXl3RWDataValueChanged
			   object : model];

	[notifyCenter addObserver : self
			 selector : @selector(compositeXl3PedestalMaskChanged:)
			     name : ORXL3ModelXl3PedestalMaskChanged
			   object : model];
		
	[notifyCenter addObserver : self
                     selector : @selector(connectStateChanged:)
                         name : XL3_LinkConnectStateChanged
                       object : [model xl3Link]];

	[notifyCenter addObserver : self
                     selector : @selector(errorTimeOutChanged:)
                         name : XL3_LinkErrorTimeOutChanged
                       object : [model xl3Link]];		

	[notifyCenter addObserver : self
                     selector : @selector(connectionAutoConnectChanged:)
                         name : XL3_LinkAutoConnectChanged
                       object : [model xl3Link]];

    [notifyCenter addObserver : self
                     selector : @selector(compositeXl3ChargeInjChanged:)
                         name : ORXL3ModelXl3ChargeInjChanged
                       object : [model xl3Link]];

    [notifyCenter addObserver : self
                     selector : @selector(monPollXl3TimeChanged:)
                         name : ORXL3ModelPollXl3TimeChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(monIsPollingXl3Changed:)
                         name : ORXL3ModelIsPollingXl3Changed
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(monIsPollingCMOSRatesChanged:)
                         name : ORXL3ModelIsPollingCMOSRatesChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(monPollCMOSRatesMaskChanged:)
                         name : ORXL3ModelPollCMOSRatesMaskChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(monIsPollingPMTCurrentsChanged:)
                         name : ORXL3ModelIsPollingPMTCurrentsChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(monPollPMTCurrentsMaskChanged:)
                         name : ORXL3ModelPollPMTCurrentsMaskChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(monIsPollingFECVoltagesChanged:)
                         name : ORXL3ModelIsPollingFECVoltagesChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(monPollFECVoltagesMaskChanged:)
                         name : ORXL3ModelPollFECVoltagesMaskChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(monIsPollingXl3VoltagesChanged:)
                         name : ORXL3ModelIsPollingXl3VoltagesChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(monIsPollingHVSupplyChanged:)
                         name : ORXL3ModelIsPollingHVSupplyChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(monIsPollingXl3WithRunChanged:)
                         name : ORXL3ModelIsPollingXl3WithRunChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(monPollStatusChanged:)
                         name : ORXL3ModelPollStatusChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(monIsPollingVerboseChanged:)
                         name : ORXL3ModelIsPollingVerboseChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(hvRelayStatusChanged:)
                         name : ORXL3ModelRelayStatusChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(hvRelayMaskChanged:)
                         name : ORXL3ModelRelayMaskChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(hvStatusChanged:)
                         name : ORXL3ModelHvStatusChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(hvTriggerStatusChanged:)
                         name : ORXL3ModelTriggerStatusChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(hvTargetValueChanged:)
                         name : ORXL3ModelHVTargetValueChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(hvCMOSRateLimitChanged:)
                         name : ORXL3ModelHVCMOSRateLimitChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(hvCMOSRateIgnoreChanged:)
                         name : ORXL3ModelHVCMOSRateIgnoreChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(monVltThresholdChanged:)
                         name : ORXL3ModelXl3VltThresholdChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(monVltThresholdInInitChanged:)
                         name : ORXL3ModelXl3VltThresholdInInitChanged
                       object : model];
}

- (void) updateWindow
{
    [super updateWindow];

    [self xl3LockChanged:nil];
    [self opsRunningChanged:nil];
    //basic ops
    [self selectedRegisterChanged:nil];
    [self repeatCountChanged:nil];
    [self repeatDelayChanged:nil];
    [self autoIncrementChanged:nil];
    [self basicOpsRunningChanged:nil];
    [self writeValueChanged:nil];
    //composite
    [self compositeSlotMaskChanged:nil];
    [self compositeXl3ModeChanged:nil];
    [self compositeXl3ModeRunningChanged:nil];
    [self compositeXl3PedestalMaskChanged:nil];
    [self compositeXl3RWAddressChanged:nil];
    [self compositeXL3RWDataChanged:nil];
    [self compositeXl3ChargeInjChanged:nil];
    //mon
    [self monPollXl3TimeChanged:nil];
    [self monIsPollingXl3Changed:nil];
    [self monIsPollingCMOSRatesChanged:nil];
    [self monPollCMOSRatesMaskChanged:nil];
    [self monIsPollingPMTCurrentsChanged:nil];
    [self monPollPMTCurrentsMaskChanged:nil];
    [self monIsPollingFECVoltagesChanged:nil];
    [self monPollFECVoltagesMaskChanged:nil];
    [self monIsPollingXl3VoltagesChanged:nil];
    [self monIsPollingHVSupplyChanged:nil];
    [self monIsPollingXl3WithRunChanged:nil];
    [self monPollStatusChanged:nil];
    [self monIsPollingVerboseChanged:nil];
    [self monVltThresholdChanged:nil];
    [self monVltThresholdInInitChanged:nil];
    //hv
    [self hvRelayMaskChanged:nil];
    [self hvRelayStatusChanged:nil];
    [self hvStatusChanged:nil];
    [self hvTriggerStatusChanged:nil];
    [self hvTargetValueChanged:nil];
    [self hvCMOSRateLimitChanged:nil];
    [self hvCMOSRateIgnoreChanged:nil];
    [self hvChangePowerSupplyChanged:nil];
    //ip connection
    [self errorTimeOutChanged:nil];
    [self connectStateChanged:nil];
    [self connectionAutoConnectChanged:nil];
}

- (void) checkGlobalSecurity
{
	BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
	[gSecurity setLock:ORXL3Lock to:secure];
	[lockButton setEnabled:secure];
}

- (void) tabView:(NSTabView*)aTabView didSelectTabViewItem:(NSTabViewItem*)item
{
	if([tabView indexOfTabViewItem:item] > 0 && [tabView indexOfTabViewItem:item] < 4) {
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:compositeSize];
		[[self window] setContentView:xl3View];
	}
	else{
		[[self window] setContentView:blankView];
		[self resizeWindowToSize:basicSize];
		[[self window] setContentView:xl3View];
	}
		
	NSString* key = [NSString stringWithFormat: @"orca.ORXL3%d.selectedtab",[model crateNumber]];
	NSInteger index = [tabView indexOfTabViewItem:item];
	[[NSUserDefaults standardUserDefaults] setInteger:index forKey:key];
}

#pragma mark •••Interface Management
- (void) xl3LockChanged:(NSNotification*)aNotification
{

    BOOL notRunningOrInMaintenance = isNotRunningOrIsInMaintenance();
    BOOL locked						= [gSecurity isLocked:ORXL3Lock];
    BOOL lockedOrNotRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORXL3Lock];
    
    //Basic
    [lockButton setState: locked];
    [basicReadButton setEnabled: !lockedOrNotRunningMaintenance];
    [basicWriteButton setEnabled: !lockedOrNotRunningMaintenance];
    [basicStopButton setEnabled: !lockedOrNotRunningMaintenance];
    [basicStatusButton setEnabled: !lockedOrNotRunningMaintenance];
    [repeatDelayField setEnabled: !lockedOrNotRunningMaintenance];
    [repeatDelayStepper setEnabled: !lockedOrNotRunningMaintenance];
    [repeatCountField setEnabled: !lockedOrNotRunningMaintenance];
    [repeatCountStepper setEnabled: !lockedOrNotRunningMaintenance];
    [writeValueField setEnabled: !lockedOrNotRunningMaintenance];
    [writeValueStepper setEnabled: !lockedOrNotRunningMaintenance];

    //Ops
    [selectAllSlotMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [deselectAllSlotMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [selectSlotMaskButton setEnabled: !lockedOrNotRunningMaintenance];
    [compositeDeselectButton setEnabled: !lockedOrNotRunningMaintenance];
    [compositeSlotMaskMatrix setEnabled: !lockedOrNotRunningMaintenance];
    [compositeSlotMaskField setEnabled: !lockedOrNotRunningMaintenance];
    [compositeXl3ModePU setEnabled: !lockedOrNotRunningMaintenance];
    [compositeXl3RWAddressValueField setEnabled: !lockedOrNotRunningMaintenance];
    [compositeSetXl3ModeButton setEnabled: !lockedOrNotRunningMaintenance];
    [compositeXl3RWModePU setEnabled: !lockedOrNotRunningMaintenance];
    [compositeXl3RWSelectPU setEnabled: !lockedOrNotRunningMaintenance];
    [compositeXl3RWRegisterPU setEnabled: !lockedOrNotRunningMaintenance];
    [compositeXl3RWDataValueField setEnabled: !lockedOrNotRunningMaintenance];
    [compositeXl3RWButton setEnabled: !lockedOrNotRunningMaintenance];
    [compositeQuitButton setEnabled: !lockedOrNotRunningMaintenance];
    [compositeSetPedestalField setEnabled: !lockedOrNotRunningMaintenance];
    [compositeSetPedestalButton setEnabled: !lockedOrNotRunningMaintenance];
    [compositeBoardIDButton setEnabled: !lockedOrNotRunningMaintenance];
    [compositeResetCrateButton setEnabled: !lockedOrNotRunningMaintenance];
    [compositeResetCrateAndXilinXButton setEnabled: !lockedOrNotRunningMaintenance];
    [compositeResetFIFOAndSequencerButton setEnabled: !lockedOrNotRunningMaintenance];
    [compositeResetXL3StateMachineButton setEnabled: !lockedOrNotRunningMaintenance];
    [compositeChargeInjMaskField setEnabled: !lockedOrNotRunningMaintenance];
    [compositeChargeInjChargeField setEnabled: !lockedOrNotRunningMaintenance];
    [compositeChargeInjButton setEnabled: !lockedOrNotRunningMaintenance];

    //Monitor
    [pollNowButton setEnabled: notRunningOrInMaintenance];
    [startPollButton setEnabled: notRunningOrInMaintenance];
    [stopPollButton setEnabled: notRunningOrInMaintenance];
    [pollRunStateLabel setHidden: notRunningOrInMaintenance];

    [monVltThresholdTextField0 setEnabled: !lockedOrNotRunningMaintenance];
    [monVltThresholdTextField1 setEnabled: !lockedOrNotRunningMaintenance];
    [monVltThresholdTextField2 setEnabled: !lockedOrNotRunningMaintenance];
    [monVltThresholdTextField3 setEnabled: !lockedOrNotRunningMaintenance];
    [monVltThresholdTextField4 setEnabled: !lockedOrNotRunningMaintenance];
    [monVltThresholdTextField5 setEnabled: !lockedOrNotRunningMaintenance];
    [monVltThresholdTextField6 setEnabled: !lockedOrNotRunningMaintenance];
    [monVltThresholdTextField7 setEnabled: !lockedOrNotRunningMaintenance];
    [monVltThresholdTextField8 setEnabled: !lockedOrNotRunningMaintenance];
    [monVltThresholdTextField9 setEnabled: !lockedOrNotRunningMaintenance];
    [monVltThresholdTextField10 setEnabled: !lockedOrNotRunningMaintenance];
    [monVltThresholdTextField11 setEnabled: !lockedOrNotRunningMaintenance];
    [monVltThresholdInInitButton setEnabled: !lockedOrNotRunningMaintenance];
    [monVltThresholdSetButton setEnabled: !lockedOrNotRunningMaintenance];

    //HV
    [self hvStatusChanged:nil];
    [self hvTriggerStatusChanged:nil];
    [hvTriggersButton setEnabled:!lockedOrNotRunningMaintenance];

    //Connection
    [toggleConnectButton setEnabled: !lockedOrNotRunningMaintenance];
    [errorTimeOutPU setEnabled: !lockedOrNotRunningMaintenance];
    [connectionIPAddressField setEnabled: !lockedOrNotRunningMaintenance];
    [connectionIPPortField setEnabled: !lockedOrNotRunningMaintenance];
    [connectionCrateNumberField setEnabled: !lockedOrNotRunningMaintenance];
    [connectionAutoConnectButton setEnabled: !lockedOrNotRunningMaintenance];
    [connectionAutoInitCrateButton setEnabled: !lockedOrNotRunningMaintenance];
    
}

- (void) opsRunningChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
	for (id key in xl3Ops) {
		if ([model xl3OpsRunningForKey:key]) {
			[[[xl3Ops objectForKey:key] objectForKey:@"spinner"] startAnimation:model];
		}
		else {
			[[[xl3Ops objectForKey:key] objectForKey:@"spinner"] stopAnimation:model];			
		}
	}
}); }

-(void) keyDown:(NSEvent*)event {
    NSString* keys = [event charactersIgnoringModifiers];
    if([keys length] == 0) {
        return;
    }
    if([keys length] == 1) {
        unichar key = [keys characterAtIndex:0];
        if(key == NSLeftArrowFunctionKey || key == 'h' || key == 'H') {
            [self decXL3Action:self];
            return;
        }
        if(key == NSRightArrowFunctionKey || key == 'l' || key == 'L') {
            [self incXL3Action:self];
            return;
        }
    }
    [super keyDown:event];
}

- (void) cancelOperation:(id)sender {
    [self endEditing];
    [[self window] makeFirstResponder:nil];
}

#pragma mark •basic ops
- (void) repeatCountChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
	[repeatCountField setIntValue: [model repeatOpCount]];
	[repeatCountStepper setIntValue: [model repeatOpCount]];
}); }

- (void) repeatDelayChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
	[repeatDelayField setIntValue:[model repeatDelay]];
	[repeatDelayStepper setIntValue: [model repeatDelay]];
}); }

- (void) autoIncrementChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
	[autoIncrementCB setState:[model autoIncrement]];
}); }

- (void) basicOpsRunningChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
	if ([model basicOpsRunning]) [basicOpsRunningIndicator startAnimation:model];
	else [basicOpsRunningIndicator stopAnimation:model];
}); }

- (void) writeValueChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
	[writeValueField setIntegerValue:[model writeValue]];
	[writeValueStepper setIntegerValue:[model writeValue]];
}); }

- (void) selectedRegisterChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
	[selectedRegisterPU selectItemAtIndex: [model selectedRegister]];
}); }


#pragma mark •composite
- (void) compositeXl3ModeChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
	[compositeXl3ModePU selectItemWithTag:[model xl3Mode]]; 
}); }

- (void) compositeXl3ModeRunningChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
	if ([model xl3ModeRunning]) [compositeXl3ModeRunningIndicator startAnimation:model];
	else [compositeXl3ModeRunningIndicator stopAnimation:model];
}); }

- (void) compositeSlotMaskChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
	uint32_t mask = [model slotMask];
	int i;
	for(i=0; i<16; i++){
		[[compositeSlotMaskMatrix cellWithTag:i] setIntegerValue:(mask & 1UL << i)];
	}
	[compositeSlotMaskField setIntegerValue:mask];
}); }

- (void) compositeXl3RWAddressChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
	[compositeXl3RWAddressValueField setIntegerValue:[model xl3RWAddressValue]];
	[compositeXl3RWModePU selectItemAtIndex:([model xl3RWAddressValue] >> 28)];

	[compositeXl3RWSelectPU selectItemWithTitle:
	 [[xl3RWSelects allKeysForObject:[NSNumber numberWithInt:[model xl3RWAddressValue] >> 20 & 0x0FF]] lastObject]];
	
	[compositeXl3RWRegisterPU selectItemWithTitle:
	 [[xl3RWAddresses allKeysForObject:[NSNumber numberWithInt:[model xl3RWAddressValue] & 0xFFF]] lastObject]];
}); }

- (void) compositeXL3RWDataChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
	[compositeXl3RWDataValueField setIntegerValue:[model xl3RWDataValue]];
}); }

- (void) compositeXl3PedestalMaskChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
	[compositeSetPedestalField setIntegerValue:[model xl3PedestalMask]];
}); }

- (void) compositeXl3ChargeInjChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [compositeChargeInjChargeField setIntValue:[model xl3ChargeInjCharge]];
    [compositeChargeInjMaskField setIntegerValue:[model xl3ChargeInjMask]];
}); }


#pragma mark •mon
- (void) monPollXl3TimeChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [monPollingRatePU selectItemWithTag:[model pollXl3Time]];
}); }

- (void) monIsPollingXl3Changed:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [monPollingStatusField setStringValue:[model pollStatus]];
}); }

- (void) monIsPollingCMOSRatesChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [monIsPollingCMOSRatesButton setIntValue:[model isPollingCMOSRates]];
}); }

- (void) monPollCMOSRatesMaskChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [monPollCMOSRatesMaskField setIntValue:[model pollCMOSRatesMask]];
}); }

- (void) monIsPollingPMTCurrentsChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [monIsPollingPMTCurrentsButton setIntValue:[model isPollingPMTCurrents]];
}); }

- (void) monPollPMTCurrentsMaskChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [monPollPMTCurrentsMaskField setIntValue:[model pollPMTCurrentsMask]];
}); }

- (void) monIsPollingFECVoltagesChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [monIsPollingFECVoltagesButton setIntValue:[model isPollingFECVoltages]];
}); }

- (void) monPollFECVoltagesMaskChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [monPollFECVoltagesMaskField setIntValue:[model pollFECVoltagesMask]];    
}); }

- (void) monIsPollingXl3VoltagesChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [monIsPollingXl3VoltagesButton setIntValue:[model isPollingXl3Voltages]];
}); }

- (void) monIsPollingHVSupplyChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [monIsPollingHVSupplyButton setIntValue:[model isPollingHVSupply]];    
}); }

- (void) monIsPollingXl3WithRunChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [monIsPollingWithRunButton setIntValue:[model isPollingXl3WithRun]];        
}); }

- (void) monPollStatusChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [monPollingStatusField setStringValue:[model pollStatus]];
}); }

- (void) monIsPollingVerboseChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [monIsPollingVerboseButton setIntValue:[model isPollingVerbose]];
}); }

- (void) monVltThresholdChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    
    NSTextField* monVltThresholdTextField[] = {monVltThresholdTextField0, monVltThresholdTextField1,
        monVltThresholdTextField2, monVltThresholdTextField3, monVltThresholdTextField6, monVltThresholdTextField7,
        monVltThresholdTextField8,monVltThresholdTextField9, monVltThresholdTextField4, monVltThresholdTextField5,
        monVltThresholdTextField10, monVltThresholdTextField11};

    unsigned short i;
    for (i=0; i<12; i++) {
        [monVltThresholdTextField[i] setFloatValue:[model xl3VltThreshold:i]];
    }
}); }

- (void) monVltThresholdInInitChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [monVltThresholdInInitButton setIntValue:[model isXl3VltThresholdInInit]];
}); }

#pragma mark •hv

- (void) updateHVButtons
{

    BOOL lockedOrNotRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORXL3Lock];
    BOOL notRunningOrInMaintenance = isNotRunningOrIsInMaintenance();

    if ([hvPowerSupplyMatrix selectedColumn] == 0) { //A
        bool unlock = ![model hvANeedsUserIntervention] && [model hvEverUpdated] && [model hvSwitchEverUpdated] && ![model hvASwitch] && [model hvAFromDB] && !lockedOrNotRunningMaintenance;
        [hvOnButton setEnabled:unlock];

        unlock = ![model hvANeedsUserIntervention] && [model hvEverUpdated] && [model hvSwitchEverUpdated] && [model hvASwitch] && [model hvAFromDB] && notRunningOrInMaintenance;
        [hvOffButton setEnabled:unlock];

        unlock = ![model hvANeedsUserIntervention] && [model hvEverUpdated] && [model hvSwitchEverUpdated] && [model hvASwitch] && ![model hvARamping] && [model hvAFromDB] && !lockedOrNotRunningMaintenance;
        [hvStepUpButton setEnabled:unlock];
        [hvStepDownButton setEnabled:unlock];
        [hvRampToTargetButton setEnabled:unlock];
        [hvTargetValueStepper setEnabled:unlock];
        [hvTargetValueField setEnabled:unlock];
        
        unlock = ![model hvANeedsUserIntervention] && [model hvEverUpdated] && [model hvSwitchEverUpdated] && [model hvASwitch] && [model hvARamping] && [model hvAFromDB] && !lockedOrNotRunningMaintenance;
        [hvStopRampButton setEnabled:unlock];
        
        unlock = ![model hvANeedsUserIntervention] && [model hvEverUpdated] && [model hvSwitchEverUpdated] && [model hvASwitch] && ![model hvARamping] && [model hvAFromDB] && notRunningOrInMaintenance;
        [hvRampDownButton setEnabled:unlock];

        unlock = [model hvANeedsUserIntervention] && [model hvAFromDB] && notRunningOrInMaintenance;
        [hvAcceptReadbackButton setEnabled:unlock];

        [hvRunStateLabel setHidden: notRunningOrInMaintenance];

    } else {
        bool unlock = ![model hvBNeedsUserIntervention] && [model hvEverUpdated] && [model hvSwitchEverUpdated] && ![model hvBSwitch] && [model hvBFromDB] && !lockedOrNotRunningMaintenance;
        [hvOnButton setEnabled:unlock];
        
        unlock = ![model hvBNeedsUserIntervention] && [model hvEverUpdated] && [model hvSwitchEverUpdated] && [model hvBSwitch] && [model hvBFromDB] && notRunningOrInMaintenance;
        [hvOffButton setEnabled:unlock];
        
        unlock = ![model hvBNeedsUserIntervention] && [model hvEverUpdated] && [model hvSwitchEverUpdated] && [model hvBSwitch] && ![model hvBRamping] && [model hvBFromDB] && !lockedOrNotRunningMaintenance;
        [hvStepUpButton setEnabled:unlock];
        [hvStepDownButton setEnabled:unlock];
        [hvRampToTargetButton setEnabled:unlock];
        [hvTargetValueStepper setEnabled:unlock];
        [hvTargetValueField setEnabled:unlock];

        unlock = ![model hvBNeedsUserIntervention] && [model hvEverUpdated] && [model hvSwitchEverUpdated] && [model hvBSwitch] && [model hvBRamping] && [model hvBFromDB] && !lockedOrNotRunningMaintenance;
        [hvStopRampButton setEnabled:unlock];
        
        unlock = ![model hvBNeedsUserIntervention] && [model hvEverUpdated] && [model hvSwitchEverUpdated] && [model hvBSwitch] && ![model hvBRamping] && [model hvBFromDB] && notRunningOrInMaintenance;
        [hvRampDownButton setEnabled:unlock];

        unlock = [model hvBNeedsUserIntervention] && [model hvBFromDB] && notRunningOrInMaintenance;
        [hvAcceptReadbackButton setEnabled:unlock];

        [hvRunStateLabel setHidden: notRunningOrInMaintenance];

    }

}

- (void) hvRelayMaskChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    uint64_t relayMask = [model relayMask];
    uint64_t relayViewMask = [model relayViewMask];

    [hvRelayMaskLowField setIntValue:relayViewMask & 0xffffffff];
    [hvRelayMaskHighField setIntValue:relayViewMask >> 32];

    unsigned char slot;
    unsigned char pmtic;
    for (slot = 0; slot<16; slot++) {
        for (pmtic=0; pmtic<4; pmtic++) {
            int modelval = (relayMask >> (slot*4 + pmtic)) & 0x1;
            int viewval = (relayViewMask >> (slot*4 + pmtic)) & 0x1;
            
            NSString *ulstate = viewval ? @"closed" : @"open";
            NSString *brstate = [[model relayStatus]  isEqual: @"status: UNKNOWN"] ? @"unk" : (modelval ? @"closed" : @"open");
            
            [[hvRelayMaskMatrix cellAtRow:pmtic column:15-slot] setIntValue:viewval];
            [[hvRelayMaskMatrix cellAtRow:pmtic column:15-slot] setImage:[msbox upLeft:ulstate botRight:brstate]];
        }
    }
}); }

- (void) hvRelayStatusChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [hvRelayStatusField setStringValue:[model relayStatus]];
}); }

- (void) updateStatusFields
{
    [owlStatus setHidden:!([model isOwlCrate] && [ORXL3Model owlSupplyOn])];
    if ([hvPowerSupplyMatrix selectedColumn] == 0) { //A
        [nominalStatus setStringValue:[NSString stringWithFormat:@"Nominal: %u V",(uint32_t)[model hvNominalVoltageA]]];
        [rampUpStatus setStringValue:[NSString stringWithFormat:@"Ramp Up: %u V/s",(uint32_t)[model hvramp_a_up]]];
        [rampDownStatus setStringValue:[NSString stringWithFormat:@"Ramp Down: %u V/s",(uint32_t)[model hvramp_a_down]]];
        [correctionStatus setStringValue:[NSString stringWithFormat:@"Correction: %3.2f V/s",(float)[model hvReadbackCorrA]]];
        [overCurentStatus setStringValue:[NSString stringWithFormat:@"Over Current: > %3.1f mA",(float)[model ihighalarm_a_imax]]];
        [overVoltageStatus setStringValue:[NSString stringWithFormat:@"Over Voltage: > %u V",(uint32_t)[model vhighalarm_a_vmax]]];
        [currentZeroStatus setStringValue:[NSString stringWithFormat:@"Current Near Zero: < %2.1f mA",(float)[model ilowalarm_a_imin]]];
        [currentZeroWhenStatus setStringValue:[NSString stringWithFormat:@"When: > %u V",(uint32_t)[model ilowalarm_a_vmin]]];
        [setpointTolStatus setStringValue:[NSString stringWithFormat:@"Setpoint Tolerance: %u V",(uint32_t)[model vsetalarm_a_vtol]]];
    } else { //B
        [nominalStatus setStringValue:[NSString stringWithFormat:@"Nominal: %u V",(uint32_t)[model hvNominalVoltageB]]];
        [rampUpStatus setStringValue:[NSString stringWithFormat:@"Ramp Up: %u V/s",(uint32_t)[model hvramp_b_up]]];
        [rampDownStatus setStringValue:[NSString stringWithFormat:@"Ramp Down: %u V/s",(uint32_t)[model hvramp_b_down]]];
        [correctionStatus setStringValue:[NSString stringWithFormat:@"Correction: %3.2f V/s",(float)[model hvReadbackCorrB]]];
        [overCurentStatus setStringValue:[NSString stringWithFormat:@"Over Current: > %3.1f mA",(float)[model ihighalarm_b_imax]]];
        [overVoltageStatus setStringValue:[NSString stringWithFormat:@"Over Voltage: > %u V",(uint32_t)[model vhighalarm_b_vmax]]];
        [currentZeroStatus setStringValue:[NSString stringWithFormat:@"Current Near Zero: < %2.1f mA",(float)[model ilowalarm_b_imin]]];
        [currentZeroWhenStatus setStringValue:[NSString stringWithFormat:@"When: > %u V",(uint32_t)[model ilowalarm_b_vmin]]];
        [setpointTolStatus setStringValue:[NSString stringWithFormat:@"Setpoint Tolerance: %u V",(uint32_t)[model vsetalarm_b_vtol]]];
    }
}

- (void) hvStatusChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    
    [self updateStatusFields];
    [hvAOnStatusField setStringValue:[model hvASwitch]?@"ON":@"OFF"];
    [hvAVoltageSetField setStringValue:[NSString stringWithFormat:@"%u V",[model hvAVoltageDACSetValue]*3000/4096]];
    [hvAVoltageReadField setStringValue:[NSString stringWithFormat:@"%d V",(unsigned int)[model hvAVoltageReadValue]]];
    [hvACurrentReadField setStringValue:[NSString stringWithFormat:@"%3.1f mA",[model hvACurrentReadValue]]];
    
    // Only crate 16 has an HV B
    if ([model crateNumber] == 16) {
        [hvAStatusPanel setHidden:(![model hvEverUpdated] || ![model hvSwitchEverUpdated])];
        [hvBStatusPanel setHidden:(![model hvEverUpdated] || ![model hvSwitchEverUpdated])];
        [hvBOnStatusField setStringValue:[model hvBSwitch]?@"ON":@"OFF"];
        [hvBVoltageSetField setStringValue:[NSString stringWithFormat:@"%u V",[model hvBVoltageDACSetValue]*3000/4096]];
        [hvBVoltageReadField setStringValue:[NSString stringWithFormat:@"%d V",(unsigned int)[model hvBVoltageReadValue]]];
        [hvBCurrentReadField setStringValue:[NSString stringWithFormat:@"%3.1f mA",[model hvBCurrentReadValue]]];
    } else {
        [hvAStatusPanel setHidden:(![model hvEverUpdated] || ![model hvSwitchEverUpdated])];
        [hvBStatusPanel setHidden:true];
        [hvBOnStatusField setStringValue:@"N/A"];
        [hvBVoltageSetField setStringValue:@""];
        [hvBVoltageReadField setStringValue:@""];
        [hvBCurrentReadField setStringValue:@""];
    }

    BOOL lockedOrNotRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORXL3Lock];

    if ([model hvASwitch] || ([model isOwlCrate] && [ORXL3Model owlSupplyOn]) || lockedOrNotRunningMaintenance) {
        [hvRelayMaskHighField setEnabled:NO];
        [hvRelayMaskLowField setEnabled:NO];
        [hvRelayMaskMatrix setEnabled:NO];
        [hvRelayOpenButton setEnabled:NO];
        [hvRelayCloseButton setEnabled:NO];
    }
    else {
        [hvRelayMaskHighField setEnabled:YES];
        [hvRelayMaskLowField setEnabled:YES];
        [hvRelayMaskMatrix setEnabled:YES];
        [hvRelayOpenButton setEnabled:YES];
        [hvRelayCloseButton setEnabled:YES];        
    }
    
    [self updateHVButtons];

}); }

- (void) hvTriggerStatusChanged:(NSNotification*)aNote
{
    BOOL notRunningOrInMaintenance = isNotRunningOrIsInMaintenance();

    if ([model isTriggerON]) {
        [hvATriggerStatusField setStringValue:@"ON"];
        [hvBTriggerStatusField setStringValue:@"ON"];
        [loadNominalSettingsButton setEnabled:notRunningOrInMaintenance];
        [hvTriggersButton setState:NSOnState];
    } else {
        [hvATriggerStatusField setStringValue:@"OFF"];
        [hvBTriggerStatusField setStringValue:@"OFF"];
        [loadNominalSettingsButton setEnabled:NO];
        [hvTriggersButton setState:NSOffState];
    }
}

- (void) hvTargetValueChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    if ([hvPowerSupplyMatrix selectedColumn] == 0) { //A
        [hvTargetValueField setFloatValue:[model hvAVoltageTargetValue] * 3000. / 4096.];
        [hvTargetValueStepper setIntegerValue:[model hvAVoltageTargetValue]];
    }
    else {
        [hvTargetValueField setFloatValue:[model hvBVoltageTargetValue] * 3000. / 4096.];
        [hvTargetValueStepper setIntegerValue:[model hvBVoltageTargetValue]];
    }
}); }

- (void) hvCMOSRateLimitChanged:(NSNotification *)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    if ([hvPowerSupplyMatrix selectedColumn] == 0) { //A
        [hvCMOSRateLimitField setIntegerValue:[model hvACMOSRateLimit]];
        [hvCMOSRateLimitStepper setIntegerValue:[model hvACMOSRateLimit]];
    }
    else {
        [hvCMOSRateLimitField setIntegerValue:[model hvBCMOSRateLimit]];
        [hvCMOSRateLimitStepper setIntegerValue:[model hvBCMOSRateLimit]];
    }    
}); }

- (void) hvCMOSRateIgnoreChanged:(NSNotification *)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    if ([hvPowerSupplyMatrix selectedColumn] == 0) { //A
        [hvCMOSRateIgnoreField setIntegerValue:[model hvACMOSRateIgnore]];
        [hvCMOSRateIgnoreStepper setIntegerValue:[model hvACMOSRateIgnore]];
    }
    else {
        [hvCMOSRateIgnoreField setIntegerValue:[model hvBCMOSRateIgnore]];
        [hvCMOSRateIgnoreStepper setIntegerValue:[model hvBCMOSRateIgnore]];
    }    
}); }

- (void) hvChangePowerSupplyChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [self updateStatusFields];
    [self hvTargetValueChanged:aNote];
    [self hvCMOSRateLimitChanged:aNote];
    [self hvCMOSRateIgnoreChanged:aNote];
    [self hvStatusChanged:aNote];
}); }

#pragma mark •ip connection

- (void) linkConnectionChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    [self connectStateChanged:aNote];
}); }

- (void) connectStateChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
    /*
	BOOL runInProgress = [gOrcaGlobals runInProgress];
	BOOL locked = [gSecurity isLocked:[model xl3LockName]];
	if(runInProgress) {
		[toggleConnectButton setTitle:@"---"];
		[toggleConnectButton setEnabled:NO];
	}
	else {
		if([[model xl3Link] connectState] == kDisconnected){
			[toggleConnectButton setTitle:@"Connect"];
			
		}
		else {
			[toggleConnectButton setTitle:@"Disconnect"];
		}
		[toggleConnectButton setEnabled:!locked];
	}
     */
    
    //we need the control
    if([[model xl3Link] connectState] == kDisconnected){
        
        //Start thread to wait for the XL3 to connect and be initilized
        [model safeHvInit];
        [toggleConnectButton setTitle:@"Connect"];
        
    }
    else {
        [toggleConnectButton setTitle:@"Disconnect"];
    }
}); }

- (void) errorTimeOutChanged:(NSNotification*)aNote
{ dispatch_async(dispatch_get_main_queue(), ^{
	[errorTimeOutPU selectItemAtIndex:[[model xl3Link] errorTimeOut]];
}); }

- (void) connectionAutoConnectChanged:(NSNotification*)aNote;
{ dispatch_async(dispatch_get_main_queue(), ^{
    [connectionAutoConnectButton setIntValue:[[model xl3Link] autoConnect]];
}); }

#pragma mark •••Helper
- (void) populateOps
{
	xl3Ops = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeDeselectButton, @"button",
									deselectCompositeRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(deselectComposite)), @"selector",
			 nil], @"compositeDeselect",
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeQuitButton, @"button",
									compositeQuitRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(compositeQuit)), @"selector",
			 nil], @"compositeQuit",
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeSetPedestalButton, @"button",
									compositeSetPedestalRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(compositeSetPedestal)), @"selector",
			 nil], @"compositeSetPedestal",
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeBoardIDButton, @"button",
									compositeBoardIDRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(getBoardIDs)), @"selector",
			 nil], @"compositeBoardID",
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeXl3RWButton, @"button",
									compositeXl3RWRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(compositeXl3RW)), @"selector",
			 nil], @"compositeXl3RW",
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeResetCrateButton, @"button",
									compositeResetCrateRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(compositeResetCrate)), @"selector",
			 nil], @"compositeResetCrate",
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeResetCrateAndXilinXButton, @"button",
									compositeResetCrateAndXilinXRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(compositeResetCrateAndXilinX)), @"selector",
			 nil], @"compositeResetCrateAndXilinX",
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeResetFIFOAndSequencerButton, @"button",
									compositeResetFIFOAndSequencerRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(compositeResetFIFOAndSequencer)), @"selector",
			 nil], @"compositeResetFIFOAndSequencer",
			[NSDictionary dictionaryWithObjectsAndKeys:	compositeResetXL3StateMachineButton, @"button",
									compositeResetXL3StateMachineRunningIndicator, @"spinner",
									NSStringFromSelector(@selector(compositeResetXL3StateMachine)), @"selector",
			 nil], @"compositeResetXL3StateMachine",
              [NSDictionary dictionaryWithObjectsAndKeys: compositeChargeInjButton, @"button",
               compositeChargeRunningIndicator, @"spinner",
               NSStringFromSelector(@selector(compositeEnableChargeInjection)), @"selector",
               nil], @"compositeEnableChargeInjection",
		  nil];
}

- (void) populatePullDown
{
	xl3RWModes = [[NSArray alloc] initWithObjects:@"0: REG_WRITE",@"1: REG_READ",
		       @"2: MEM_WRITE",@"3: MEM_READ", nil];

	xl3RWSelects = [[NSDictionary alloc] initWithObjectsAndKeys:
			[NSNumber numberWithInt:0x00], @"FEC 0", 
			[NSNumber numberWithInt:0x01], @"FEC 1",
			[NSNumber numberWithInt:0x02], @"FEC 2",
			[NSNumber numberWithInt:0x03], @"FEC 3",
			[NSNumber numberWithInt:0x04], @"FEC 4",
			[NSNumber numberWithInt:0x05], @"FEC 5",
			[NSNumber numberWithInt:0x06], @"FEC 6",
			[NSNumber numberWithInt:0x07], @"FEC 7",
			[NSNumber numberWithInt:0x08], @"FEC 8",
			[NSNumber numberWithInt:0x09], @"FEC 9",
			[NSNumber numberWithInt:0x0A], @"FEC 10",
			[NSNumber numberWithInt:0x0B], @"FEC 11",
			[NSNumber numberWithInt:0x0C], @"FEC 12",
			[NSNumber numberWithInt:0x0D], @"FEC 13",
			[NSNumber numberWithInt:0x0E], @"FEC 14",
			[NSNumber numberWithInt:0x0F], @"FEC 15",
			[NSNumber numberWithInt:0x10], @"CTC",
			[NSNumber numberWithInt:0x20], @"XL3",
			nil];

	xl3RWAddresses = [[NSDictionary alloc] initWithObjectsAndKeys:
			  [NSNumber numberWithInt:0x00], @"xl3 select",
			  [NSNumber numberWithInt:0x01], @"xl3 data avail",
			  [NSNumber numberWithInt:0x02], @"xl3 ctrl&stat",
			  [NSNumber numberWithInt:0x03], @"xl3 slot mask",
			  [NSNumber numberWithInt:0x04], @"xl3 dac clock",
			  [NSNumber numberWithInt:0x05], @"xl3 hv relay",
			  [NSNumber numberWithInt:0x06], @"xl3 xilinx csr",
			  [NSNumber numberWithInt:0x07], @"xl3 test",
			  [NSNumber numberWithInt:0x08], @"xl3 hv csr",
			  [NSNumber numberWithInt:0x09], @"xl3 hv setpoints",
			  [NSNumber numberWithInt:0x0A], @"xl3 hv vlt read",
			  [NSNumber numberWithInt:0x0B], @"xl3 hv crnt read",
			  [NSNumber numberWithInt:0x0C], @"xl3 vm",
			  [NSNumber numberWithInt:0x0E], @"xl3 vr",
			  [NSNumber numberWithInt:0x20], @"fec ctrl&stat",
			  [NSNumber numberWithInt:0x21], @"fec adc value",
			  [NSNumber numberWithInt:0x22], @"fec vlt mon",
			  [NSNumber numberWithInt:0x23], @"fec ped enable",
			  [NSNumber numberWithInt:0x24], @"fec dac prg",
			  [NSNumber numberWithInt:0x25], @"fec caldac prg",
			  [NSNumber numberWithInt:0x26], @"fec hvc csr",
			  [NSNumber numberWithInt:0x27], @"fec cmos spy out",
			  [NSNumber numberWithInt:0x28], @"fec cmos full",
			  [NSNumber numberWithInt:0x29], @"fec cmos select",
			  [NSNumber numberWithInt:0x2A], @"fec cmos 1_16",
			  [NSNumber numberWithInt:0x2B], @"fec cmos 17_32",
			  [NSNumber numberWithInt:0x2C], @"fec cmos lgisel",
			  [NSNumber numberWithInt:0x2D], @"fec board id",
			  [NSNumber numberWithInt:0x80], @"fec seq out csr",
			  [NSNumber numberWithInt:0x84], @"fec seq in csr",
			  [NSNumber numberWithInt:0x88], @"fec cmos dt avl",
			  [NSNumber numberWithInt:0x8C], @"fec cmos chp sel",
			  [NSNumber numberWithInt:0x90], @"fec cmos chp dis",
			  [NSNumber numberWithInt:0x94], @"fec cmos dat out",
			  [NSNumber numberWithInt:0x9C], @"fec fifo read",
			  [NSNumber numberWithInt:0x9D], @"fec fifo write",
			  [NSNumber numberWithInt:0x9E], @"fec fifo diff",
			  [NSNumber numberWithInt:0x101], @"fec cmos msd cnt",
			  [NSNumber numberWithInt:0x102], @"fec cmos busy rg",
			  [NSNumber numberWithInt:0x103], @"fec cmos tot cnt",
			  [NSNumber numberWithInt:0x104], @"fec cmos test id",
			  [NSNumber numberWithInt:0x105], @"fec cmos shft rg",
			  [NSNumber numberWithInt:0x106], @"fec cmos arry pt",
			  [NSNumber numberWithInt:0x107], @"fec cmos cnt inf",
			  nil];

	short	i;
	[selectedRegisterPU removeAllItems];
	for (i = 0; i < [model getNumberRegisters]; i++) {
		[selectedRegisterPU insertItemWithTitle:[model getRegisterName:i] atIndex:i];
	}
	[self selectedRegisterChanged:nil];

	[compositeXl3RWModePU removeAllItems];
	[compositeXl3RWModePU addItemsWithTitles:xl3RWModes];
	
	[compositeXl3RWSelectPU removeAllItems];
	[compositeXl3RWSelectPU addItemsWithTitles:[xl3RWSelects keysSortedByValueUsingSelector:@selector(compare:)]];
	
	[compositeXl3RWRegisterPU removeAllItems];
	[compositeXl3RWRegisterPU addItemsWithTitles:[xl3RWAddresses keysSortedByValueUsingSelector:@selector(compare:)]];
	//for (id key in xl3RWAddresses) [compositeXl3RWRegisterPU addItemWithTitle:key]; // doesn't guarantee the order
}


#pragma mark •••Actions
- (IBAction) incXL3Action:(id)sender
{
    bool isXL3Locked = [gSecurity isLocked:ORXL3Lock];
	[self incModelSortedBy:@selector(XL3NumberCompare:)];
    [gSecurity setLock:ORXL3Lock to:isXL3Locked];
}

- (IBAction) decXL3Action:(id)sender
{
    bool isXL3Locked = [gSecurity isLocked:ORXL3Lock];
	[self decModelSortedBy:@selector(XL3NumberCompare:)];
    [gSecurity setLock:ORXL3Lock to:isXL3Locked];
}

- (IBAction) lockAction:(id)sender
{
	[gSecurity tryToSetLock:ORXL3Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) opsAction:(id)sender
{
    [self endEditing];
	NSString* theKey = @"";
	for (id key in xl3Ops) {
		if ((id) [[xl3Ops objectForKey:key] objectForKey:@"button"] == sender) {
			theKey = [NSString stringWithString: key];
			//NSLog(@"%@ found in keys\n", theKey);
			break;
		}
	}
	
	[model performSelector:NSSelectorFromString([[xl3Ops objectForKey:theKey] objectForKey:@"selector"])];
}


- (void) basicSelectedRegisterAction:(id)sender
{
	[model setSelectedRegister:(int)[sender indexOfSelectedItem]];
}

- (IBAction) basicReadAction:(id)sender
{
	[model readBasicOps];
}

- (IBAction) basicWriteAction:(id)sender
{
	[model writeBasicOps];
}

- (IBAction) basicStopAction:(id)sender
{
	[model stopBasicOps];
}

- (IBAction) basicStatusAction:(id) sender
{
	[model reportStatus];
}

- (IBAction) repeatCountAction:(id) sender
{
	[model setRepeatOpCount:[sender intValue]];	
}

- (IBAction) repeatDelayAction:(id) sender
{
	[model setRepeatDelay:[sender intValue]];
}

- (IBAction) autoIncrementAction:(id) sender
{
	[model setAutoIncrement:[sender intValue]];
}

- (IBAction) writeValueAction:(id) sender;
{
	[model setWriteValue:[sender intValue]];
}


//composite
- (IBAction) compositeSlotMaskAction:(id) sender 
{
    [self endEditing];
	uint32_t mask = 0;
	int i;
	for(i=0;i<16;i++){
		if([[sender cellWithTag:i] intValue]){	
			mask |= (1L << i);
		}
	}
	[model setSlotMask:mask];	
}

- (IBAction) compositeSlotMaskFieldAction:(id) sender
{
    [self endEditing];
	uint32_t mask = [sender intValue];
	if (mask > 0xFFFFUL) mask = 0xFFFF;
	[model setSlotMask:mask];
}

- (IBAction) compositeSlotMaskSelectAction:(id) sender
{
	[model setSlotMask:0xffffUL];
}

- (IBAction) compositeSlotMaskDeselectAction:(id) sender
{
	[model setSlotMask:0UL];
}

- (IBAction) compositeSlotMaskPresentAction:(id) sender
{
	NSArray* fecs = [[model guardian] collectObjectsOfClass:NSClassFromString(@"ORFec32Model")];
	unsigned int msk = 0UL;
	for (id key in fecs) {
		msk |= 1 << [key stationNumber];
	}
	[model setSlotMask:msk];
}

- (IBAction) compositeDeselectAction:(id) sender
{
	[model deselectComposite];
}

- (IBAction) compositeXl3ModeAction:(id) sender
{
	[model setXl3Mode:(int)[[sender selectedItem] tag]];
}

- (IBAction) compositeXl3ModeSetAction:(id) sender
{
	[model writeXl3Mode:[model xl3Mode] withSlotMask:(int)[model slotMask]];
}

- (IBAction) compositeXl3RWAddressValueAction:(id)sender
{
    [self endEditing];
	[model setXl3RWAddressValue:[sender intValue]];
}	

- (IBAction) compositeXl3RWModeAction:(id)sender
{
    [self endEditing];
	uint32_t addressValue = [model xl3RWAddressValue];
	addressValue = (uint32_t)((addressValue & 0x0FFFFFFF) | [sender indexOfSelectedItem] << 28);
	[model setXl3RWAddressValue:addressValue];
}

- (IBAction) compositeXl3RWSelectAction:(id)sender
{
    [self endEditing];
	uint32_t addressValue = [model xl3RWAddressValue];
	addressValue = (addressValue & 0xF00FFFFF) | [[xl3RWSelects objectForKey:[[sender selectedItem] title]] intValue] << 20;
	[model setXl3RWAddressValue:addressValue];
}

- (IBAction) compositeXl3RWRegisterAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
	uint32_t addressValue = [model xl3RWAddressValue];
	addressValue = (addressValue & 0xFFF00000) | [[xl3RWAddresses objectForKey:[[sender selectedItem] title]] intValue];
	[model setXl3RWAddressValue:addressValue];
}

- (IBAction) compositeXl3RWDataValueAction:(id)sender;
{
    [[sender window] makeFirstResponder:tabView];
	[model setXl3RWDataValue:[sender intValue]];
}

- (IBAction) compositeSetPedestalValue:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
	[model setXl3PedestalMask:[sender intValue]];
}

- (IBAction) compositeXl3ChargeInjMaskAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
    [model setXl3ChargeInjMask:[sender intValue]];
}

- (IBAction) compositeXl3ChargeInjChargeAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
    [model setXl3ChargeInjCharge:[sender intValue]];
}

//mon
- (IBAction) monIsPollingCMOSRatesAction:(id)sender
{
    [model setIsPollingCMOSRates:[sender intValue]];
    [self endEditing];
}

- (IBAction) monIsPollingPMTCurrentsAction:(id)sender
{
    [model setIsPollingPMTCurrents:[sender intValue]];
    [self endEditing];
}

- (IBAction) monIsPollingFECVoltagesAction:(id)sender
{
    [model setIsPollingFECVoltages:[sender intValue]];
    [self endEditing];
}

- (IBAction) monIsPollingXl3VoltagesAction:(id)sender
{
    [model setIsPollingXl3Voltages:[sender intValue]];
    [self endEditing];
}

- (IBAction) monIsPollingHVSupplyAction:(id)sender
{
    [model setIsPollingHVSupply:[sender intValue]];
    [self endEditing];
}

- (IBAction) monPollCMOSRatesMaskAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
    [model setPollCMOSRatesMask:[sender intValue]];
}

- (IBAction) monPollPMTCurrentsMaskAction:(id)sender
{   
    [[sender window] makeFirstResponder:tabView];
    [model setPollPMTCurrentsMask:[sender intValue]];
}

- (IBAction) monPollFECVoltagesMaskAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
    [model setPollFECVoltagesMask:[sender intValue]];
}

- (IBAction) monPollingRateAction:(id)sender
{
    [self endEditing];
    [model setPollXl3Time:[[sender selectedItem] tag]];
}

- (IBAction) monIsPollingVerboseAction:(id)sender
{
    [self endEditing];
    [model setIsPollingVerbose:[sender intValue]];
}

- (IBAction) monIsPollingWithRunAction:(id)sender
{
    [self endEditing];
    [model setIsPollingXl3WithRun:[sender intValue]];
}

- (IBAction) monPollNowAction:(id)sender
{
    [model pollXl3:true];
}

- (IBAction) monVltThresholdAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
    float aValue;
    aValue = [sender floatValue];
    if (aValue < -99) {
        aValue = -99;
    }
    if (aValue > 99) {
        aValue = 99;
    }
    [model setXl3VltThreshold:[sender tag] withValue:aValue];
}

- (IBAction) monVltThresholdInInitAction:(id)sender
{
    [model setIsXl3VltThresholdInInit:[sender intValue]];
}

- (IBAction) monVltThresholdSetAction:(id)sender
{
    [self endEditing];
    [model setVltThreshold];
}

- (IBAction) monStartPollingAction:(id)sender
{
    [model setIsPollingXl3:true];
}

- (IBAction) monStopPollingAction:(id)sender
{
    [model setIsPollingXl3:false];
}

//hv
- (IBAction)hvRelayMaskHighAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
    uint64_t newRelayMask = [model relayViewMask] & 0xFFFFFFFFULL;
    newRelayMask |= ((uint64_t)[sender intValue]) << 32;
    [model setRelayViewMask:newRelayMask];
}

- (IBAction)hvRelayMaskLowAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
    uint64_t newRelayMask = [model relayViewMask] & (0xFFFFFFFFULL << 32);
    newRelayMask |= [sender intValue] & 0xFFFFFFFF;
    [model setRelayViewMask:newRelayMask];
}

- (IBAction)hvRelayMaskMatrixAction:(id)sender
{
    uint64_t newRelayMask = 0ULL;
    unsigned char slot;
    unsigned char pmtic;
    for (slot = 0; slot<16; slot++) {
        for (pmtic=0; pmtic<4; pmtic++) {
            newRelayMask |= ([[sender cellAtRow:pmtic column:15-slot] intValue]?1ULL:0ULL) << (slot*4 + pmtic);
        }
    }
    [model setRelayViewMask:newRelayMask];
}

- (IBAction)hvRelaySetAction:(id)sender
{
    [self endEditing];
    [model setRelayMask:[model relayViewMask]];
    [model closeHVRelays];
}

- (IBAction)hvRelayOpenAllAction:(id)sender
{
    [self endEditing];
    [model openHVRelays];
}

- (IBAction)hvCheckInterlockRelaysAction:(id)sender
{
    uint64_t relays;
    BOOL known;

    [self endEditing];
    [model readHVInterlock];
    @try {
        [model readHVRelays:&relays isKnown:&known];
        if(known) {
            NSLog(@"Relay mask = %llu\n", (uint64_t) relays);
        } else {
            NSLog(@"Relays are unknown!\n");
        }
    }@catch (NSException *exception) {
        NSLogColor([NSColor redColor],@"%@ error in readHVRelays. Error: %@ Reason: %@\n",[[model xl3Link] crateName], [exception name], [exception reason]);
    }
}

- (IBAction)hvTurnOnAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
    [model setHVSwitch:YES forPowerSupply:[hvPowerSupplyMatrix selectedColumn]];
}

- (IBAction)hvTurnOffAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
    unsigned int sup = (unsigned int)[hvPowerSupplyMatrix selectedColumn];

    if (sup == 0 && [model hvASwitch]) {
        if ([model hvAVoltageDACSetValue] > 30) {
            ORRunAlertPanel (@"Not turning OFF",@"Voltage too high. Ramp down first.",@"OK",nil,nil);
            return;
        }
    }
    else if (sup == 1 && [model hvBSwitch]) {
        if ([model hvBVoltageDACSetValue] > 30) {
            ORRunAlertPanel (@"Not turning OFF",@"Voltage too high. Ramp down first.",@"OK",nil,nil);
            return;
        }
    }
    [model setHVSwitch:NO forPowerSupply:sup];
}

- (IBAction)hvAcceptReadback:(id)sender
{
    [model hvUserIntervention:([hvPowerSupplyMatrix selectedColumn] ? false : true)];
}

- (IBAction)hvTargetValueAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
    char sup = [hvPowerSupplyMatrix selectedColumn];
    int nextTargetValue = 0;
    if (sender == hvTargetValueField) {
        nextTargetValue = (int) ([sender floatValue] * 4096 / 3000);
        if (nextTargetValue < 0) nextTargetValue = 0;
        if (sup == 0 && nextTargetValue > [model hvNominalVoltageA] / 3000. * 4096) {//A
            nextTargetValue = (int)[model hvNominalVoltageA] * 4096 / 3000;
        }
        else if (sup == 1 && nextTargetValue > [model hvNominalVoltageB] / 3000. * 4096) {//B
            nextTargetValue = (int)[model hvNominalVoltageB] * 4096 / 3000;
        }
    }
    else if (sender == hvTargetValueStepper) {
        nextTargetValue = [sender intValue];
        if (nextTargetValue < 0) nextTargetValue = 0;
        if (sup == 0 && nextTargetValue > [model hvNominalVoltageA] / 3000. * 4096) {//A
            nextTargetValue = (int)[model hvNominalVoltageA] * 4096 / 3000;
        }
        else if (sup == 1 && nextTargetValue > [model hvNominalVoltageB] / 3000. * 4096) {//B
            nextTargetValue = (int)[model hvNominalVoltageB] * 4096 / 3000;
        }
    }
    else {
        return;
    }
    if (sup == 0) {
        [model setHvAVoltageTargetValue:nextTargetValue];
    }
    else {
        [model setHvBVoltageTargetValue:nextTargetValue];
    }
}

- (IBAction)hvCMOSRateLimitAction:(id)sender
{
    uint32_t nextCMOSRateLimit = [sender intValue];
    if (nextCMOSRateLimit > 200) {
        nextCMOSRateLimit = 200;
    }
    if ([hvPowerSupplyMatrix selectedColumn] == 0) {
        [model setHvACMOSRateLimit:nextCMOSRateLimit];
    }
    else {
        [model setHvBCMOSRateLimit:nextCMOSRateLimit];
    }
}

- (IBAction)hvCMOSRateIgnoreAction:(id)sender
{
    uint32_t nextCMOSRateIgnore = [sender intValue];
    if (nextCMOSRateIgnore > 20) {
        nextCMOSRateIgnore = 20;
    }
    if ([hvPowerSupplyMatrix selectedColumn] == 0) {
        [model setHvACMOSRateIgnore:nextCMOSRateIgnore];
    }
    else {
        [model setHvBCMOSRateIgnore:nextCMOSRateIgnore];
    }
}

- (IBAction)hvChangePowerSupplyAction:(id)sender
{
    if ([hvPowerSupplyMatrix selectedColumn] == 0) {
        [[hvPowerSupplyMatrix cellAtRow:0 column:0] setIntValue:YES];
        [[hvPowerSupplyMatrix cellAtRow:0 column:1] setIntValue:NO];
    }
    else {
        [[hvPowerSupplyMatrix cellAtRow:0 column:0] setIntValue:NO];
        [[hvPowerSupplyMatrix cellAtRow:0 column:1] setIntValue:YES];
    }

    [self hvChangePowerSupplyChanged:nil];
}

- (IBAction)hvStepUpAction:(id)sender;
{
    [[sender window] makeFirstResponder:tabView];
    uint32_t aVoltageDACValue;
    if ([hvPowerSupplyMatrix selectedColumn] == 0) {
        aVoltageDACValue = [model hvANextStepValue];
        aVoltageDACValue += 50 * 4096/3000.;
        if (aVoltageDACValue > [model hvAVoltageTargetValue]) aVoltageDACValue = [model hvAVoltageTargetValue];
        [model setHvANextStepValue:aVoltageDACValue];
    }
    else {
        aVoltageDACValue = [model hvBNextStepValue];
        aVoltageDACValue += 50 * 4096/3000.;
        if (aVoltageDACValue > [model hvBVoltageTargetValue]) aVoltageDACValue = [model hvBVoltageTargetValue];
        [model setHvBNextStepValue:aVoltageDACValue];
    }
}

- (IBAction)hvStepDownAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
    uint32_t aVoltageDACValue;
    if ([hvPowerSupplyMatrix selectedColumn] == 0) {
        aVoltageDACValue = [model hvANextStepValue];
        if (aVoltageDACValue < 50 * 4096/3000.) aVoltageDACValue = 0;
        else aVoltageDACValue -= 50 * 4096/3000.;
        [model setHvANextStepValue:aVoltageDACValue];
    }
    else {
        aVoltageDACValue = [model hvBNextStepValue];
        if (aVoltageDACValue < 50 * 4096/3000.) aVoltageDACValue = 0;
        else aVoltageDACValue -= 50 * 4096/3000.;
        [model setHvBNextStepValue:aVoltageDACValue];
    }    
}

- (IBAction)hvRampToTargetAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
    if ([hvPowerSupplyMatrix selectedColumn] == 0) {
        [model setHvANextStepValue:[model hvAVoltageTargetValue]];
    }
    else {
        [model setHvBNextStepValue:[model hvBVoltageTargetValue]];
    }
}

- (IBAction)hvRampDownAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
    if ([hvPowerSupplyMatrix selectedColumn] == 0) {
        if ([model isTriggerON]) {
            [model hvTriggersOFF];
        }
        [model setHvANextStepValue:0];
    } else {
        //FIXME: do we handle triggers for supply B?
        [model setHvBNextStepValue:0];
    }
}

- (IBAction)hvRampPauseAction:(id)sender
{
    [[sender window] makeFirstResponder:tabView];
    if ([hvPowerSupplyMatrix selectedColumn] == 0) {
        [model setHvANextStepValue:[model hvAVoltageDACSetValue]];
    }
    else {
        [model setHvBNextStepValue:[model hvBVoltageDACSetValue]];
    }
}

- (IBAction)hvPanicAction:(id)sender
{
    [model hvPanicDown];
}

- (IBAction) hvTriggerAction:(id)sender
{
    if ([sender state]) {
        [model hvTriggersON];
    } else {
        [model hvTriggersOFF];
    }
    /* Need to update button because the user is sometimes given a choice to
     * cancel turning triggers on, in which case the button will seem to be
     * on, but in fact the triggers weren't turned on. */
    [self hvTriggerStatusChanged:nil];
}

- (IBAction) loadNominalSettingsAction: (id) sender
{
    [model loadNominalSettings];
}

//connection
- (void) toggleConnectAction:(id)sender
{
	[[model xl3Link] toggleConnect];
}

- (IBAction) errorTimeOutAction:(id)sender
{
	[[model xl3Link] setErrorTimeOut:(int)[sender indexOfSelectedItem]];
}

- (IBAction) connectionAutoConnectAction:(id)sender
{
    [[model xl3Link] setAutoConnect:[sender intValue]];
}

@end
