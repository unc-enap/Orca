//
//  ORVHS4030Controller.m
//  Orca
//
//  Created by Mark Howe on Sat Nov 16 2002.
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


#import "ORVHS4030Controller.h"
#import "ORVHS4030Model.h"

@interface ORVHS4030Controller (private)
- (void) panicToZero:(unsigned short)aChannel;
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _panicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
@end

@implementation ORVHS4030Controller

-(id)init
{
    self = [super initWithWindowNibName:@"VHS4030"];
	
    return self;
}

- (void) awakeFromNib
{
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
					 selector : @selector(baseAddressChanged:)
						 name : ORVmeIOCardBaseAddressChangedNotification
					   object : model];
					
	[notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORVHS4030SettingsLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(voltageSetChanged:)
						 name : ORVHS4030VoltageSetChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(currentSetChanged:)
						 name : ORVHS4030CurrentSetChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(voltageMeasureChanged:)
						 name : ORVHS4030VoltageMeasureChanged
						object: model];
			
	[notifyCenter addObserver : self
					 selector : @selector(pollTimeChanged:)
						 name : ORVHS4030PollTimeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(channelStatusChanged:)
                         name : ORVHS4030ChannelStatusChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(channelEventStatusChanged:)
                         name : ORVHS4030ChannelEventStatusChanged
						object: model];
	
//    [notifyCenter addObserver : self
//					selector : @selector(timeOutErrorChanged:)
 //                        name : ORVHS4030TimeOutErrorChanged
//						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(currentMeasureChanged:)
                         name : ORVHS4030CurrentMeasureChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(pollingErrorChanged:)
                         name : ORVHS4030PollingErrorChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(moduleStatusChanged:)
                         name : ORVHS4030ModuleStatusChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(moduleControlChanged:)
                         name : ORVHS4030ModuleControlChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(moduleEventStatusChanged:)
                         name : ORVHS4030ModuleEventStatusChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(moduleEventMaskChanged:)
                         name : ORVHS4030ModuleEventMaskChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(voltageRampSpeedChanged:)
                         name : ORVHS4030VoltageRampSpeedChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(supplyP5Changed:)
                         name : ORVHS4030SupplyP5Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(supplyP12Changed:)
                         name : ORVHS4030SupplyP12Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(supplyN12Changed:)
                         name : ORVHS4030SupplyN12Changed
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(temperatureChanged:)
                         name : ORVHS4030TemperatureChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(voltageMaxChanged:)
                         name : ORVHS4030VoltageMaxChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(currentMaxChanged:)
                         name : ORVHS4030CurrentMaxChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(voltageBoundsChanged:)
                         name : ORVHS4030VoltageBoundsChanged
						object: model];

	[notifyCenter addObserver : self
                     selector : @selector(currentBoundsChanged:)
                         name : ORVHS4030CurrentBoundsChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(killEnabledChanged:)
                         name : ORVHS4030ModelKillEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(fineAdjustEnabledChanged:)
                         name : ORVHS4030ModelFineAdjustEnabledChanged
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
	[addressText setIntegerValue: [model baseAddress]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"VHS4030 Card (Slot %d)",[model slot]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"VHS4030 Card (Slot %d)",[model slot]]];
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
    [gSecurity setLock:ORVHS4030SettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORVHS4030SettingsLock];
    BOOL locked = [gSecurity isLocked:ORVHS4030SettingsLock];
	
    [settingLockButton setState: locked];
    [addressText setEnabled:!locked && !runInProgress];
	BOOL isEmergency = NO;
	BOOL anyPowerOn = NO;
	int i;
	for(i=0;i<kNumVHS4030Channels;i++){
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
		if(runInProgress && ![gSecurity isLocked:ORVHS4030SettingsLock])s = @"Not in Maintenance Run.";
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
		for(i=0;i<kNumVHS4030Channels;i++) {
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
		for(i=0;i<kNumVHS4030Channels;i++) [[voltageSetMatrix cellAtRow:i column:0] setFloatValue:[model voltageSet:i]];	
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
		for(i=0;i<kNumVHS4030Channels;i++) [[voltageMeasureMatrix cellAtRow:i column:0] setFloatValue:[model voltageMeasure:i]];	
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
		for(i=0;i<kNumVHS4030Channels;i++) [[currentMeasureMatrix cellAtRow:i column:0] setFloatValue:[model currentMeasure:i]*1000.];	
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
		for(i=0;i<kNumVHS4030Channels;i++) [[currentSetMatrix cellAtRow:i column:0] setFloatValue:[model currentSet:i]*1000.];	
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
		for(i=0;i<kNumVHS4030Channels;i++) [[voltageBoundsMatrix cellAtRow:i column:0] setFloatValue:[model voltageBounds:i]];	
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
		for(i=0;i<kNumVHS4030Channels;i++) [[currentBoundsMatrix cellAtRow:i column:0] setFloatValue:[model currentBounds:i]*1000.];	
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
        NSLog(@"HV power toggle of VHS4030 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed HV power toggle of VHS4030", @"OK", nil, nil,
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
        NSLog(@"Module Info Read of VHS4030 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Module Info Read of VHS4030", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) doClearAction:(id)sender
{
	@try {
		[model doClear];
	}
	@catch(NSException* localException) {
        NSLog(@"Do Clear of VHS4030 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Do Clear of VHS4030", @"OK", nil, nil,
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
    [gSecurity tryToSetLock:ORVHS4030SettingsLock to:[sender intValue] forWindow:[self window]];
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
	[model setPollTime:(int)[[sender selectedItem] tag]];	
}

- (IBAction) loadStartAction:(id)sender
{
	@try {
		[self endEditing];
		[model loadValues:[[sender selectedCell]tag]];
	}
	@catch(NSException* localException) {
        NSLog(@"Hardware access of VHS4030 FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed HW Access of VHS4030", @"OK", nil, nil,
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
					  
@implementation ORVHS4030Controller (private)
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
    [alert setAlertStyle:NSAlertStyleWarning];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            @try {
                int i;
                for(i=0;i<kNumVHS4030Channels;i++){
                    if(aChannel == 0xFFFF || aChannel == i)[model panicToZero:i];
                }
            }
            @catch(NSException* e){
                NSLog(@"vhW224L Panic failed because of exception\n");
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
	if(returnCode == NSAlertFirstButtonReturn){
		@try {
			int i;
			for(i=0;i<kNumVHS4030Channels;i++){
				if(channel == 0xFFFF || channel == i)[model panicToZero:i];
			}
		}
		@catch(NSException* e){
			NSLog(@"vhW224L Panic failed because of exception\n");
		}
	}
	[theChannelNumber release];
}
#endif
@end
