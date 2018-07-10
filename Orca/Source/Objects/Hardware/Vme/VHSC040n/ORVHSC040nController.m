//
//  ORVHSC040nController.m
//  Orca
//
//  Created by Mark Howe on Mon Sept 13,2010.
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and Department sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#import "ORVHSC040nController.h"
#import "ORVHSC040nModel.h"

@interface ORVHSC040nController (private)
- (void) panicToZero:(unsigned short)aChannel;
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _panicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
@end

@implementation ORVHSC040nController

-(id)init
{
    self = [super initWithWindowNibName:@"VHSC040n"];
	
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
	int i;
	NSNumberFormatter* f2 = [[[NSNumberFormatter alloc] init] autorelease];
	[f2 setFormat:@"#0.00"];
	NSNumberFormatter* f1 = [[[NSNumberFormatter alloc] init] autorelease];
	[f1 setFormat:@"#0.0"];
	for(i=0;i<kNumVHSC040nChannels;i++){
		[[onOffMatrix			cellAtRow:i column:0] setTag:i];
		[[hvStateMatrix			cellAtRow:i column:0] setTag:i];
		[[voltageSetMatrix		cellAtRow:i column:0] setTag:i];
		[[currentSetMatrix		cellAtRow:i column:0] setTag:i];
		[[voltageBoundsMatrix	cellAtRow:i column:0] setTag:i];
		[[currentBoundsMatrix	cellAtRow:i column:0] setTag:i];
		[[voltageMeasureMatrix	cellAtRow:i column:0] setTag:i];
		[[currentMeasureMatrix	cellAtRow:i column:0] setTag:i];
		[[iErrorMatrix			cellAtRow:i column:0] setTag:i];	
		[[loadStartButtonMatrix cellAtRow:i column:0] setTag:i];
		[[stopButtonMatrix		cellAtRow:i column:0] setTag:i];
		[[panicButtonMatrix		cellAtRow:i column:0] setTag:i];

		[[currentSetMatrix		cellAtRow:i column:0] setFormatter:f1];
		[[currentBoundsMatrix	cellAtRow:i column:0] setFormatter:f2];
		[[voltageMeasureMatrix	cellAtRow:i column:0] setFormatter:f1];
		[[currentMeasureMatrix	cellAtRow:i column:0] setFormatter:f1];

	}
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
					 selector : @selector(baseAddressChanged:)
						 name : ORVmeIOCardBaseAddressChangedNotification
					   object : model];
					
	[notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORVHSC040nSettingsLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(voltageSetChanged:)
						 name : ORVHSC040nVoltageSetChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(currentSetChanged:)
						 name : ORVHSC040nCurrentSetChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(voltageMeasureChanged:)
						 name : ORVHSC040nVoltageMeasureChanged
						object: model];
			
	[notifyCenter addObserver : self
					 selector : @selector(pollTimeChanged:)
						 name : ORVHSC040nPollTimeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(channelStatusChanged:)
                         name : ORVHSC040nChannelStatusChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(channelEventStatusChanged:)
                         name : ORVHSC040nChannelEventStatusChanged
						object: model];
		
    [notifyCenter addObserver : self
                     selector : @selector(currentMeasureChanged:)
                         name : ORVHSC040nCurrentMeasureChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(pollingErrorChanged:)
                         name : ORVHSC040nPollingErrorChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(moduleStatusChanged:)
                         name : ORVHSC040nModuleStatusChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(moduleControlChanged:)
                         name : ORVHSC040nModuleControlChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(moduleEventStatusChanged:)
                         name : ORVHSC040nModuleEventStatusChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(moduleEventMaskChanged:)
                         name : ORVHSC040nModuleEventMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(voltageRampSpeedChanged:)
                         name : ORVHSC040nVoltageRampSpeedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(supplyP5Changed:)
                         name : ORVHSC040nSupplyP5Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(supplyP12Changed:)
                         name : ORVHSC040nSupplyP12Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(supplyN12Changed:)
                         name : ORVHSC040nSupplyN12Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(temperatureChanged:)
                         name : ORVHSC040nTemperatureChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(voltageMaxChanged:)
                         name : ORVHSC040nVoltageMaxChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(currentMaxChanged:)
                         name : ORVHSC040nCurrentMaxChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(voltageBoundsChanged:)
                         name : ORVHSC040nVoltageBoundsChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(currentBoundsChanged:)
                         name : ORVHSC040nCurrentBoundsChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(killEnabledChanged:)
                         name : ORVHSC040nModelKillEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fineAdjustEnabledChanged:)
                         name : ORVHSC040nModelFineAdjustEnabledChanged
						object: model];

}

#pragma mark •••Interface Management

- (void) fineAdjustEnabledChanged:(NSNotification*)aNote
{
	[fineAdjustEnabledCB setIntValue: [model fineAdjustEnabled]];
}

- (void) killEnabledChanged:(NSNotification*)aNote
{
	[killEnabledCB setIntValue: [model killEnabled]];
}

- (void) baseAddressChanged:(NSNotification*)aNotification 
{ 
	[addressText setIntValue: [model baseAddress]]; 
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"VHSC040n Card (Slot %d)",[model slot]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"VHSC040n Card (Slot %d)",[model slot]]];
}

//Module values
- (void) voltageMaxChanged:(NSNotification*)aNote		{ [voltageMaxField setFloatValue:		[model voltageMax]]; }
- (void) currentMaxChanged:(NSNotification*)aNote		{ [currentMaxField setFloatValue:		[model currentMax]]; }
- (void) temperatureChanged:(NSNotification*)aNote		{ [temperatureField setFloatValue:		[model temperature]]; }
- (void) supplyN12Changed:(NSNotification*)aNote		{ [supplyN12Field setFloatValue:		[model supplyN12]]; }
- (void) supplyP12Changed:(NSNotification*)aNote		{ [supplyP12Field setFloatValue:		[model supplyP12]]; }
- (void) supplyP5Changed:(NSNotification*)aNote			{ [supplyP5Field setFloatValue:			[model supplyP5]]; }
- (void) voltageRampSpeedChanged:(NSNotification*)aNote	{ [voltageRampSpeedField setFloatValue: [model voltageRampSpeed]]; }


- (void) moduleEventMaskChanged:(NSNotification*)aNote
{
}

- (void) moduleEventStatusChanged:(NSNotification*)aNote
{
	[self settingsLockChanged:aNote];
}

- (void) moduleControlChanged:(NSNotification*)aNote
{
}

- (void) moduleStatusChanged:(NSNotification*)aNote
{
	
	NSColor* red = [NSColor colorWithCalibratedRed:.8 green:.0 blue:.0 alpha:1.];
	NSColor* green = [NSColor colorWithCalibratedRed:0 green:.6 blue:.0 alpha:1.];
	
	unsigned short moduleStatus = [model moduleStatus];
	
	BOOL moduleWithoutFailure		= (moduleStatus & kModuleWithoutFailure) != 0;
	[[moduleStatusMatrix cellAtRow:0 column:0] setTextColor:moduleWithoutFailure   ? green:red];
	[[moduleStatusMatrix cellAtRow:0 column:0] setStringValue:moduleWithoutFailure ? @"Module OK":@"Failure"];

	BOOL moduleInStateGood		= (moduleStatus & kModuleInStateGood) != 0;
	[[moduleStatusMatrix cellAtRow:1 column:0] setTextColor:moduleInStateGood   ? green:red];
	[[moduleStatusMatrix cellAtRow:1 column:0] setStringValue:moduleInStateGood ? @"State OK":@"State BAD"];
	
	BOOL allChannelsStable			= (moduleStatus & kAllChannelsStable) != 0;
	[[moduleStatusMatrix cellAtRow:2 column:0] setTextColor:allChannelsStable   ? green:red];
	[[moduleStatusMatrix cellAtRow:2 column:0] setStringValue:allChannelsStable ? @"Stable":@"Ramping"];

	BOOL anyEventIsActiveAndMaskSet = (moduleStatus & kAnyEventIsActiveAndMaskSet) != 0;
	[[moduleStatusMatrix cellAtRow:3 column:0] setTextColor:anyEventIsActiveAndMaskSet   ? red:green];
	[[moduleStatusMatrix cellAtRow:3 column:0] setStringValue:anyEventIsActiveAndMaskSet ? @"Event Active":@"No Events"];

	BOOL safetyLoopClosed			= (moduleStatus & kSafetyLoopClosed) != 0;
	[[moduleStatusMatrix cellAtRow:4 column:0] setTextColor:safetyLoopClosed   ? green:[NSColor blackColor]];
	[[moduleStatusMatrix cellAtRow:4 column:0] setStringValue:safetyLoopClosed ? @"Loop Closed":@"Loop Open"];
	
	BOOL temperatureGood = (moduleStatus & kTemperatureGood) != 0;
	[temperatureField setTextColor: temperatureGood ? [NSColor blackColor]:red];

	BOOL powerSupplyGood = (moduleStatus & kPowerSupplyGood) != 0;
	[supplyP5Field setTextColor  : powerSupplyGood ? [NSColor blackColor] : red];
	[supplyP12Field setTextColor : powerSupplyGood ? [NSColor blackColor] : red];
	[supplyN12Field setTextColor : powerSupplyGood ? [NSColor blackColor] : red];
}

- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];

	[self supplyP5Changed:nil];
	[self supplyP12Changed:nil];
	[self supplyN12Changed:nil];
	[self temperatureChanged:nil];
	[self voltageMaxChanged:nil];
	[self currentMaxChanged:nil];
	
	[self voltageSetChanged:nil];
	[self voltageMeasureChanged:nil];
	[self currentSetChanged:nil];
	[self currentMeasureChanged:nil];
	[self channelStatusChanged:nil];
	[self channelEventStatusChanged:nil];
	
	[self moduleStatusChanged:nil];
	[self moduleControlChanged:nil];
	[self moduleEventStatusChanged:nil];
	[self moduleEventMaskChanged:nil];
	[self voltageBoundsChanged:nil];
	[self currentBoundsChanged:nil];

	[self voltageRampSpeedChanged:nil];
	
	[self pollTimeChanged:nil];
	[self pollingErrorChanged:nil];
	[self killEnabledChanged:nil];
	[self fineAdjustEnabledChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORVHSC040nSettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORVHSC040nSettingsLock];
    BOOL locked = [gSecurity isLocked:ORVHSC040nSettingsLock];
	
    [settingLockButton setState: locked];
    [addressText setEnabled:!locked && !runInProgress];
	BOOL isEmergency = NO;
	BOOL anyPowerOn = NO;
	int i;
	for(i=0;i<kNumVHSC040nChannels;i++){
		[[onOffMatrix cellAtRow:i column:0] setEnabled: !lockedOrRunningMaintenance && [model voltageMeasure:i]<20 && ![model isEmergency:i]];
		[[loadStartButtonMatrix cellAtRow:i column:0] setEnabled: !lockedOrRunningMaintenance && [model hvPower:i] && ![model isEmergency:i]];
		[[stopButtonMatrix cellAtRow:i column:0] setEnabled: [model isRamping:i]];
		[[panicButtonMatrix cellAtRow:i column:0] setEnabled: [model hvPower:i]];
		anyPowerOn |= [model hvPower:i];
		isEmergency |= [model isEmergency:i];
	}
	[clearButton setEnabled: isEmergency];
	
	[systemPanicButton setEnabled:anyPowerOn];
	
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORVHSC040nSettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
}

- (void) pollingErrorChanged:(NSNotification*)aNote
{
	[pollingErrorField setStringValue:[model pollingError]?@"Exceptions":@""];
}

- (void) channelStatusChanged:(NSNotification*)aNote
{
	unsigned short redMask = kIsEmergency | kIsExtInhibit | kIsTripSet | kIsCurrentLimitExceeded | kIsVoltageLimitExceeded;
	
	int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
	if(!aNote){
		int i; 
		for(i=0;i<kNumVHSC040nChannels;i++) {
			BOOL hvOn = [model hvPower:i];
			[[hvStateMatrix cellAtRow:i column:0] setStringValue:hvOn ? @"*ON*":@"Off"];
			[[hvStateMatrix cellAtRow:i column:0] setTextColor:hvOn ? [NSColor redColor]:[NSColor blueColor]];
			[[onOffMatrix cellAtRow:i column:0] setTitle:hvOn ? @"Turn Off":@"Turn On"];
			[[iErrorMatrix cellAtRow:i column:0] setStringValue:[model channelStatusString:i]];
			if([model channelStatus:i] & redMask) {
				[[iErrorMatrix cellAtRow:i column:0] setTextColor:[NSColor redColor]];
			}
			else {
				[[iErrorMatrix cellAtRow:i column:0] setTextColor:[NSColor blackColor]];
			}
		}
	}
	else {
		BOOL hvOn = [model hvPower:chan];
		[[hvStateMatrix cellAtRow:chan column:0] setStringValue:hvOn ? @"*ON*":@"Off"];
		[[hvStateMatrix cellAtRow:chan column:0] setTextColor:hvOn ? [NSColor redColor]:[NSColor blueColor]];
		[[onOffMatrix cellAtRow:chan column:0] setTitle:hvOn ? @"Turn Off":@"Turn On"];
		[[iErrorMatrix cellAtRow:chan column:0] setStringValue:[model channelStatusString:chan]];
		if([model channelStatus:chan] & redMask) {
			[[iErrorMatrix cellAtRow:chan column:0] setTextColor:[NSColor redColor]];
		}
		else {
			[[iErrorMatrix cellAtRow:chan column:0] setTextColor:[NSColor blackColor]];
		}
	}
	
	[self settingsLockChanged:nil];
}

- (void) channelEventStatusChanged:(NSNotification*)aNote
{
//	int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
}


- (void) voltageSetChanged:(NSNotification*)aNote
{
	if(!aNote){
		int i; 
		for(i=0;i<kNumVHSC040nChannels;i++) [[voltageSetMatrix cellAtRow:i column:0] setFloatValue:[model voltageSet:i]];	
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];	
		[[voltageSetMatrix cellAtRow:chan column:0] setFloatValue:[model voltageSet:chan]];
	}
}

- (void) voltageMeasureChanged:(NSNotification*)aNote
{
	if(!aNote){
		int i; 
		for(i=0;i<kNumVHSC040nChannels;i++) [[voltageMeasureMatrix cellAtRow:i column:0] setFloatValue:[model voltageMeasure:i]];	
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];	
		[[voltageMeasureMatrix cellAtRow:chan column:0] setFloatValue:[model voltageMeasure:chan]];
	}					   
	[self channelStatusChanged:aNote];
}

- (void) currentMeasureChanged:(NSNotification*)aNote
{
	if(!aNote){
		int i; 
		for(i=0;i<kNumVHSC040nChannels;i++) [[currentMeasureMatrix cellAtRow:i column:0] setFloatValue:[model currentMeasure:i]*1000.];	
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];	
		[[currentMeasureMatrix cellAtRow:chan column:0] setFloatValue:[model currentMeasure:chan]*1000.];
	}
}

- (void) currentSetChanged:(NSNotification*)aNote
{	
	if(!aNote){
		int i; 
		for(i=0;i<kNumVHSC040nChannels;i++) [[currentSetMatrix cellAtRow:i column:0] setFloatValue:[model currentSet:i]*1000.];	
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];	
		[[currentSetMatrix cellAtRow:chan column:0] setFloatValue:[model currentSet:chan]*1000.];
	}
}

- (void) voltageBoundsChanged:(NSNotification*)aNote
{
	if(!aNote){
		int i; 
		for(i=0;i<kNumVHSC040nChannels;i++) [[voltageBoundsMatrix cellAtRow:i column:0] setFloatValue:[model voltageBounds:i]];	
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];	
		[[voltageBoundsMatrix cellAtRow:chan column:0] setFloatValue:[model voltageBounds:chan]];
	}
}

- (void) currentBoundsChanged:(NSNotification*)aNote
{
	if(!aNote){
		int i; 
		for(i=0;i<kNumVHSC040nChannels;i++) [[currentBoundsMatrix cellAtRow:i column:0] setFloatValue:[model currentBounds:i]*1000.];	
	}
	else {
		int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];	
		[[currentBoundsMatrix cellAtRow:chan column:0] setFloatValue:[model currentBounds:chan]*1000.];
	}
}

- (void) pollTimeChanged:(NSNotification*)aNote
{
	[pollTimePopup selectItemWithTag: [model pollTime]];
	if([model pollTime])[pollingProgress startAnimation:self];
	else [pollingProgress stopAnimation:self];
}

#pragma mark •••Actions

- (IBAction) toggleHVOnOffAction:(id)sender
{
	@try {
		[model toggleHVOnOff:[[sender selectedCell]tag]];
	}
	@catch(NSException* localException) {
        NSLog(@"HV power toggle of VHSC040n FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed HV power toggle of VHSC040n", @"OK", nil, nil,
                        localException);
    }
	
}

- (IBAction) fineAdjustEnabledAction:(id)sender
{
	[model setFineAdjustEnabled:[sender intValue]];	
}

- (IBAction) killEnabledAction:(id)sender
{
	[model setKillEnabled:[sender intValue]];	
}

- (IBAction) reportAction:(id)sender
{
	@try {

		[model readModuleInfo];
	}
	@catch(NSException* localException) {
        NSLog(@"Module Info Read of VHSC040n FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Module Info Read of VHSC040n", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) doClearAction:(id)sender
{
	@try {
		[model doClear];
	}
	@catch(NSException* localException) {
        NSLog(@"Do Clear of VHSC040n FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Do Clear of VHSC040n", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) voltageBoundsAction:(id)sender
{
	[model setVoltageBounds:[[sender selectedCell]tag] withValue:[sender floatValue]];	
}

- (IBAction) currentBoundsAction:(id)sender
{
	[model setCurrentBounds:[[sender selectedCell]tag] withValue:[sender floatValue]/1000.];	
}

- (IBAction) voltageRampSpeedAction:(id)sender
{
	[model setVoltageRampSpeed:[sender floatValue]];	
}

- (IBAction) voltageSetAction:(id)sender
{
	[model setVoltageSet:[[sender selectedCell]tag] withValue:[sender floatValue]];
}

- (IBAction) currentSetAction:(id)sender
{
	[model setCurrentSet:[[sender selectedCell]tag] withValue:[sender floatValue]/1000.];
}


- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORVHSC040nSettingsLock to:[sender intValue] forWindow:[self window]];
}

-(IBAction) baseAddressAction:(id)sender
{
	if([sender intValue] != [model baseAddress]){
		[[self undoManager] setActionName: @"Set Base Address"];
		[model setBaseAddress:[sender intValue]];		
	}
}

- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:[[sender selectedItem] tag]];	
}

- (IBAction) loadStartAction:(id)sender
{
	@try {
		[self endEditing];
		[model loadValues:[[sender selectedCell]tag]];
	}
	@catch(NSException* localException) {
        NSLog(@"Hardware access of VHSC040n FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed HW Access of VHSC040n", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) panicAction:(id)sender
{
	[self panicToZero:[[sender selectedCell]tag]];
}

- (IBAction) systemPanicAction:(id)sender
{
	[self panicToZero:0xFFFF];
}

- (IBAction) stopAction:(id)sender
{
	[model stopRamp:[[sender selectedCell]tag]];
}

@end
					  
@implementation ORVHSC040nController (private)
- (void) panicToZero:(unsigned short)aChannel
{
	[self endEditing];
	//******contextInfo is released when the sheet closes.
	NSString* n = [NSString stringWithFormat:@"%d",aChannel];
	NSString* s = [NSString stringWithFormat:@"HV Panic %@",aChannel==0xffff?@"(All Channels)":n];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:s];
    [alert setInformativeText:@"Really Panic Selected High Voltage OFF?"];
    [alert addButtonWithTitle:@"Yes/Do it NOW"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            @try {
                int i;
                for(i=0;i<kNumVHSC040nChannels;i++){
                    if(aChannel == 0xFFFF || aChannel == i)[model panicToZero:i];
                }
            }
            @catch(NSException* e){
                NSLog(@"vhs040n Panic failed because of exception\n");
            }
        }
    }];
#else
    NSNumber* contextInfo =  [[NSDecimalNumber numberWithInt:aChannel] retain];
    NSBeginAlertSheet(s,
					  @"YES/Do it NOW",
					  @"Cancel",
					  nil,
					  [self window],
					  self,
					  @selector(_panicRampSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  contextInfo,
					  @"Really Panic Selected High Voltage OFF?");
#endif
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _panicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info
{
	NSDecimalNumber* theChannelNumber = (NSDecimalNumber*)info;
	int channel = [theChannelNumber intValue] ;
	if(returnCode == NSAlertDefaultReturn){
		@try {
			int i;
			for(i=0;i<kNumVHSC040nChannels;i++){
				if(channel == 0xFFFF || channel == i)[model panicToZero:i];
			}
		}
		@catch(NSException* e){
			NSLog(@"vhs040n Panic failed because of exception\n");
		}
	}
	[theChannelNumber release];
}
#endif
@end
