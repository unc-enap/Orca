//
//  ORVHQ224LController.m
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


#import "ORVHQ224LController.h"
#import "ORVHQ224LModel.h"

@interface ORVHQ224LController (private)
- (void) panicToZero:(unsigned short)aChannel;
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _panicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
#endif
@end

@implementation ORVHQ224LController

-(id)init
{
    self = [super initWithWindowNibName:@"VHQ224L"];
	
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
						 name : ORVHQ224LSettingsLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(setVoltageChanged:)
						 name : ORVHQ224LSetVoltageChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(actVoltageChanged:)
						 name : ORVHQ224LActVoltageChanged
						object: model];
		
	[notifyCenter addObserver : self
					 selector : @selector(rampRateChanged:)
						 name : ORVHQ224LRampRateChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(pollTimeChanged:)
						 name : ORVHQ224LPollTimeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(statusReg1Changed:)
                         name : ORVHQ224LModelStatusReg1Changed
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(statusReg2Changed:)
                         name : ORVHQ224LModelStatusReg2Changed
						object: model];
	
//    [notifyCenter addObserver : self
//                     selector : @selector(timeOutErrorChanged:)
//                         name : ORVHQ224LModelTimeOutErrorChanged
//						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(actCurrentChanged:)
                         name : ORVHQ224LActCurrentChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(maxCurrentChanged:)
                         name : ORVHQ224LMaxCurrentChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(pollingErrorChanged:)
                         name : ORVHQ224LModelPollingErrorChanged
						object: model];

}

#pragma mark •••Interface Management
- (void) updateWindow
{
    [super updateWindow];
    [self baseAddressChanged:nil];
    [self slotChanged:nil];
    [self settingsLockChanged:nil];
	[self setVoltageChanged:nil];
	[self actVoltageChanged:nil];
	[self actCurrentChanged:nil];
	[self maxCurrentChanged:nil];
	[self rampRateChanged:nil];
	[self pollTimeChanged:nil];
	[self statusReg1Changed:nil];
	[self statusReg2Changed:nil];
	[self pollingErrorChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORVHQ224LSettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORVHQ224LSettingsLock];
    BOOL locked = [gSecurity isLocked:ORVHQ224LSettingsLock];
	
    [settingLockButton setState: locked];
    [addressText setEnabled:!locked && !runInProgress];
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORVHQ224LSettingsLock])s = @"Not in Maintenance Run.";
    }
    [settingLockDocField setStringValue:s];
	
	BOOL chanAInControl = [model controlState:0];
	BOOL rampingA = [model rampingState:0]>kHVStableLow;
	[setVoltageAField setEnabled:!lockedOrRunningMaintenance & chanAInControl];
	[maxCurrentAField setEnabled:!lockedOrRunningMaintenance & chanAInControl];
	[setRampRateAField setEnabled:!lockedOrRunningMaintenance & chanAInControl];
	[setRampRateAField setEnabled:!lockedOrRunningMaintenance & chanAInControl];
	[initAButton setEnabled:!lockedOrRunningMaintenance & chanAInControl];
	[panicAButton setEnabled: chanAInControl];
	[manualAField setStringValue:!chanAInControl?@"Manual":@""];
	[stopAButton setEnabled:!locked & rampingA];

	BOOL chanBInControl = [model controlState:1];
	BOOL rampingB = [model rampingState:1]>kHVStableLow;
	[setVoltageBField setEnabled:!lockedOrRunningMaintenance & chanBInControl];
	[maxCurrentBField setEnabled:!lockedOrRunningMaintenance & chanBInControl];
	[setRampRateBField setEnabled:!lockedOrRunningMaintenance & chanBInControl];
	[initBButton setEnabled:!lockedOrRunningMaintenance & chanBInControl];
	[panicBButton setEnabled: chanBInControl];
	[systemPanicBButton setEnabled: chanAInControl || chanBInControl];
	[manualBField setStringValue:!chanBInControl?@"Manual":@""];
	[stopBButton setEnabled:!locked & rampingB];
}

- (void) pollingErrorChanged:(NSNotification*)aNote
{
	[pollingErrorTextField setStringValue:[model pollingError]?@"Exceptions":@""];
}

- (void) statusReg1Changed:(NSNotification*)aNote
{
	int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
	NSImageView* theImageView = (chan==0?hvStateAImage:hvStateBImage);
	eVHQ224LRampingState state = [model rampingState:chan];
	switch (state) {
		case kHVOff:			[theImageView setImage:nil]; break;
		case kHVStableLow:	[theImageView setImage:[NSImage imageNamed:@"lowVoltage"]]; break;
		case kHVStableHigh:	[theImageView setImage:[NSImage imageNamed:@"highVoltage"]]; break;
		case kHVRampingUp:	[theImageView setImage:[NSImage imageNamed:@"upRamp"]];	  break;
		case kHVRampingDn:	[theImageView setImage:[NSImage imageNamed:@"downRamp"]]; break;
		default: break;
	}
	
	
	//update the Polarity Field
	NSTextField* theTextField = (chan==0?polarityAField:polarityBField);
	if([model polarity:chan])[theTextField setStringValue:@"Pos"];
	else [theTextField setStringValue:@"Neg"];

	//update the HV On Switch Field
	theTextField = (chan==0?hvPowerAField:hvPowerBField);
	if([model hvPower:chan])[theTextField setStringValue:@"On"];
	else [theTextField setStringValue:@"Off"];

	//update the Kill Switch Field
	theTextField = (chan==0?killSwitchAField:killSwitchBField);
	if([model killSwitch:chan])[theTextField setStringValue:@"Enabled"];
	else [theTextField setStringValue:@"Off"];
	
	[self settingsLockChanged:nil];
}

- (void) statusReg2Changed:(NSNotification*)aNote
{
	int chan = [[[aNote userInfo] objectForKey:@"Channel"] intValue];
	//update the Current Trip Field
	NSTextField* theTextField = (chan==0?currentTripAField:currentTripBField);
	if([model currentTripped:chan]){
		[theTextField setTextColor:[NSColor redColor]];
		[theTextField setStringValue:@"Current Trip"];
		NSLogColor([NSColor redColor], @"%@: Current Tripped on channel %d\n",[model fullID],chan );
	}
	else {
		[theTextField setTextColor:[NSColor blackColor]];
		[theTextField setStringValue:@"Max Current:"];
	}

	//update the Ext Inhibit Field
	theTextField = (chan==0?extInhibitAField:extInhibitBField);
	if([model extInhibitActive:chan])[theTextField setStringValue:@"Active"];
	else [theTextField setStringValue:@"No"];
}

- (void) baseAddressChanged:(NSNotification*)aNotification
{
	[addressText setIntValue: [model baseAddress]];
}

- (void) slotChanged:(NSNotification*)aNotification
{
	[slotField setIntValue: [model slot]];
	[[self window] setTitle:[NSString stringWithFormat:@"VHQ224L Card (Slot %d)",[model slot]]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"VHQ224L Card (Slot %d)",[model slot]]];
}

- (void) setVoltageChanged:(NSNotification*)aNote
{
	[setVoltageAField setFloatValue:[model voltage:0]];
	[setVoltageBField setFloatValue:[model voltage:1]];
}

- (void) actVoltageChanged:(NSNotification*)aNote
{
	[actVoltageAField setFloatValue:[model actVoltage:0]];
	[actVoltageBField setFloatValue:[model actVoltage:1]];
}

- (void) actCurrentChanged:(NSNotification*)aNote
{
	[actCurrentAField setFloatValue:[model actCurrent:0]];
	[actCurrentBField setFloatValue:[model actCurrent:1]];
}

- (void) maxCurrentChanged:(NSNotification*)aNote
{
	[maxCurrentAField setFloatValue:[model maxCurrent:0]];
	[maxCurrentBField setFloatValue:[model maxCurrent:1]];
	
	int i;
	for(i=0;i<2;i++){
		NSTextField* theField = (i==0?currentTripAField2:currentTripBField2);
		
		if([model maxCurrent:i] == 0){
			[theField setTextColor:[NSColor redColor]];
			[theField setStringValue:@"Disabled: I==0"];
		}
		else {
			[theField setTextColor:[NSColor blackColor]];
			[theField setStringValue:@"Enabled"];
		}
	}
}

- (void) rampRateChanged:(NSNotification*)aNote
{
	[setRampRateAField setIntValue:[model rampRate:0]];
	[setRampRateBField setIntValue:[model rampRate:1]];
}

- (void) pollTimeChanged:(NSNotification*)aNote
{
	[pollTimePopup selectItemWithTag: [model pollTime]];
	if([model pollTime])[pollingProgress startAnimation:self];
	else [pollingProgress stopAnimation:self];
}


#pragma mark •••Actions

- (IBAction) setVoltageAction:(id)sender
{
	[self endEditing];
	[model setVoltage:[sender tag] withValue:[sender floatValue]];
}

- (IBAction) maxCurrentAction:(id)sender
{
	[self endEditing];
	[model setMaxCurrent:[sender tag] withValue:[sender floatValue]];
}

- (IBAction) setRampRateAction:(id)sender
{
	[self endEditing];
	[model setRampRate:[sender tag] withValue:[sender intValue]];
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORVHQ224LSettingsLock to:[sender intValue] forWindow:[self window]];
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

- (IBAction) readModuleID:(id)sender
{
	@try {
		[model readModuleID];
	}
	@catch(NSException* localException) {
        NSLog(@"Module ID Read of VHQ224L FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Module ID Read of VHQ224L", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) loadAllValues:(id)sender
{
	@try {
		[self endEditing];
		[model loadValues:[sender tag]];
	}
	@catch(NSException* localException) {
        NSLog(@"Hardware access of VHQ224L FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed HW Access of VHQ224L", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) panic:(id)sender
{
	[self panicToZero:[sender tag]];
}

- (IBAction) systemPanic:(id)sender
{
	[self panicToZero:0xFFFF];
}

- (IBAction) stopHere:(id)sender
{
	[model stopRamp:[sender tag]];
}

- (IBAction) readStatus:(id)sender
{
	@try {
		
		[model readStatus1Word];
		unsigned short status1A = [model statusReg1Chan:0];
		unsigned short status1B = [model statusReg1Chan:1];
		
		[model readStatus2Word];
		unsigned short status2A = [model statusReg2Chan:0];
		unsigned short status2B = [model statusReg2Chan:1];
		
		NSFont* f = [NSFont fontWithName:@"Monaco" size:12];
		NSLogFont(f,@"-------------------------------\n");
		NSLogFont(f,@"Channel           A\t  B\n");
		NSLogFont(f,@"-------------------------------\n");
		NSLogFont(f,@"Status1 word  : 0x%02x\t    0x%02x\n",status2A,status2B);
		NSLogFont(f,@"Status2 word  : 0x%02x\t    0x%02x\n",status2A,status2B);
		NSLogFont(f,@"-------------------------------\n");
		
		NSLogFont(f,@"Status        : %@\t%@\n", (status1A & kError)		  ? @"Err     ":@"OK      ",(status1B & kError)			? @"Err     ":@"OK      ");
		NSLogFont(f,@"Voltage Status: %@\t%@\n", (status1A & kStatV)		  ? @"Changing":@"Stable  ",(status1B & kStatV)			? @"Changing":@"Stable  ");
		NSLogFont(f,@"Ramping       : %@\t%@\n", [model rampStateString:0],[model rampStateString:1]);
		NSLogFont(f,@"Kill Switch   : %@\t%@\n", (status1A & kKillSwitch)	  ? @"Enabled ":@"Disabled",(status1B & kKillSwitch)	? @"Enabled ":@"Disabled");
		NSLogFont(f,@"HV Switch     : %@\t%@\n", (status1A & kHVSwitch)		  ? @"Off     ":@"On      ",(status1B & kHVSwitch)		? @"Off     ":@"On      ");
		NSLogFont(f,@"HV Polarity   : %@\t%@\n", (status1A & kHVPolarity)	  ? @"Positive":@"Negative",(status1B & kHVPolarity)	? @"Positive":@"Negative");
		NSLogFont(f,@"Control       : %@\t%@\n", (status1A & kHVControl)	  ? @"Manual  ":@"DAC     ",(status1B & kHVControl)		? @"Manual  ":@"DAC     ");
		NSLogFont(f,@"V Out         : %@\t%@\n", (status1A & kVZOut)		  ? @"Vout==0 ":@"Vout!=0 ",(status1B & kVZOut)			? @"Vout==0 ":@"Vout!=0 ");

		NSLogFont(f,@"Current Trip  : %@\t%@\n", (status2A & kCurrentTripBit) ? @"YES     ":@"NO     ",(status2B & kCurrentTripBit) ? @"YES     ":@"NO      ");
		NSLogFont(f,@"Ramping       : %@\t%@\n", (status2A & kRunningRamp)    ? @"YES     ":@"NO     ",(status2B & kRunningRamp)    ? @"YES     ":@"NO      ");
		NSLogFont(f,@"Switch Changed: %@\t%@\n", (status2A & kSwitchChanged)  ? @"YES     ":@"NO     ",(status2B & kSwitchChanged)  ? @"YES     ":@"NO      ");
		NSLogFont(f,@"Voltage > Max : %@\t%@\n", (status2A & kVMaxExceeded)   ? @"YES     ":@"NO     ",(status2B & kVMaxExceeded)   ? @"YES     ":@"NO      ");
		NSLogFont(f,@"Inibit Active : %@\t%@\n", (status2A & kInibitActive)   ? @"YES     ":@"NO     ",(status2B & kInibitActive)   ? @"YES     ":@"NO      ");
		NSLogFont(f,@"Current > Max : %@\t%@\n", (status2A & kCurrentExceeded)? @"YES     ":@"NO     ",(status2B & kCurrentExceeded)? @"YES     ":@"NO      ");
		NSLogFont(f,@"Output Quality: %@\t%@\n", (status2A & kQualityNotGiven)? @"NO      ":@"YES    ",(status2B & kQualityNotGiven)? @"YES     ":@"NO      ");
		NSLogFont(f,@"-------------------------------\n");
	}
	@catch(NSException* localException) {
        NSLog(@"Status Read of VHQ224L FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Status Read of VHQ224L", @"OK", nil, nil,
                        localException);
    }
}
@end
					  
@implementation ORVHQ224LController (private)
- (void) panicToZero:(unsigned short)aChannel
{
	[self endEditing];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:[NSString stringWithFormat:@"HV Panic %@",aChannel==0xffff?@"(All Channels)":aChannel==0?@"A":@"B"]];
    [alert setInformativeText:@"Really Panic Selected High Voltage OFF?"];
    [alert addButtonWithTitle:@"Yes/Do it NOW"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            @try {
                if(aChannel == 0xFFFF || aChannel == 0)[model panicToZero:0];
                if(aChannel == 0xFFFF || aChannel == 1)[model panicToZero:1];
            }
            @catch(NSException* e){
                NSLog(@"vhW224L Panic failed because of exception\n");
            }
        }
    }];
#else	//******contextInfo is released when the sheet closes.
	NSNumber* contextInfo =  [[NSDecimalNumber numberWithInt:aChannel] retain];
    NSBeginAlertSheet([NSString stringWithFormat:@"HV Panic %@",aChannel==0xffff?@"(All Channels)":aChannel==0?@"A":@"B"],
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
			if(channel == 0xFFFF || channel == 0)[model panicToZero:0];
			if(channel == 0xFFFF || channel == 1)[model panicToZero:1];
		}
		@catch(NSException* e){
			NSLog(@"vhW224L Panic failed because of exception\n");
		}
	}
	[theChannelNumber release];
}
#endif
@end
