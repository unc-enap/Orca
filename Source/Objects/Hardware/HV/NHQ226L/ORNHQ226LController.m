//
//  ORNHQ226LController.m
//  Orca
//
//  Created by Mark Howe on Tues Sept 14,2010.
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


#import "ORNHQ226LController.h"
#import "ORNHQ226LModel.h"
#import "ORSerialPort.h"
#import "ORSerialPortList.h"

@interface ORNHQ226LController (private)
- (void) populatePortListPopup;
- (void) panicToZero:(unsigned short)aChannel;
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _panicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) syncDialog;
- (void) _syncSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info;
#endif
@end

@implementation ORNHQ226LController

-(id)init
{
    self = [super initWithWindowNibName:@"NHQ226L"];
	
    return self;
}

- (void) awakeFromNib
{
    [self populatePortListPopup];
    [super awakeFromNib];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORNHQ226LModelPortNameChanged
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
	
	[notifyCenter addObserver : self
                     selector : @selector(timedOut:)
                         name : ORNHQ226LModelTimeout
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(settingsLockChanged:)
						 name : ORNHQ226LSettingsLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(setVoltageChanged:)
						 name : ORNHQ226LSetVoltageChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(actVoltageChanged:)
						 name : ORNHQ226LActVoltageChanged
						object: model];
		
	[notifyCenter addObserver : self
					 selector : @selector(rampRateChanged:)
						 name : ORNHQ226LRampRateChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(pollTimeChanged:)
						 name : ORNHQ226LPollTimeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(statusReg1Changed:)
                         name : ORNHQ226LModelStatusReg1Changed
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(statusReg2Changed:)
                         name : ORNHQ226LModelStatusReg2Changed
						object: model];
		
    [notifyCenter addObserver : self
                     selector : @selector(actCurrentChanged:)
                         name : ORNHQ226LActCurrentChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(maxCurrentChanged:)
                         name : ORNHQ226LMaxCurrentChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(pollingErrorChanged:)
                         name : ORNHQ226LModelPollingErrorChanged
						object: model];

}

#pragma mark •••Interface Management
- (void) updateWindow
{
    [super updateWindow];
	[self portStateChanged:nil];
    [self portNameChanged:nil];
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
	[self updateButtons];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORNHQ226LSettingsLock to:secure];
    [settingLockButton setEnabled:secure];
}

- (void) updateButtons
{
}

- (void) timedOut:(NSNotification*)aNote
{
	[timeoutField setStringValue:@"Time Out"];
}
- (void) portStateChanged:(NSNotification*)aNote
{
    if(aNote == nil || [aNote object] == [model serialPort]){
        if([model serialPort]){
            [openPortButton setEnabled:YES];
			
            if([[model serialPort] isOpen]){
                [openPortButton setTitle:@"Close"];
                [portStateField setTextColor:[NSColor colorWithCalibratedRed:0.0 green:.8 blue:0.0 alpha:1.0]];
                [portStateField setStringValue:@"Open"];
				
            }
            else {
                [openPortButton setTitle:@"Open"];
                [portStateField setStringValue:@"Closed"];
                [portStateField setTextColor:[NSColor redColor]];
            }
        }
        else {
            [openPortButton setEnabled:NO];
            [portStateField setTextColor:[NSColor blackColor]];
            [portStateField setStringValue:@"---"];
            [openPortButton setTitle:@"---"];
        }
		if(aNote)[self updateButtons];
    }
}

- (void) portNameChanged:(NSNotification*)aNotification
{
    NSString* portName = [model portName];
    
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
	
    [portListPopup selectItemAtIndex:0]; //the default
    while (aPort = [enumerator nextObject]) {
        if([portName isEqualToString:[aPort name]]){
            [portListPopup selectItemWithTitle:portName];
            break;
        }
	}  
    [self portStateChanged:nil];
}

- (void) settingsLockChanged:(NSNotification*)aNotification
{
	
    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORNHQ226LSettingsLock];
    BOOL locked = [gSecurity isLocked:ORNHQ226LSettingsLock];
	
    [settingLockButton setState: locked];
    
    NSString* s = @"";
    if(lockedOrRunningMaintenance){
		if(runInProgress && ![gSecurity isLocked:ORNHQ226LSettingsLock])s = @"Not in Maintenance Run.";
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
	eNHQ226LRampingState state = [model rampingState:chan];
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
	NSTextField* theTextField = (chan==0?statusAField:statusBField);
    [theTextField setStringValue:[model status2String:chan]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"NHQ226L (%lu)",[model uniqueIdNumber]]];
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
- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

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
    [gSecurity tryToSetLock:ORNHQ226LSettingsLock to:[sender intValue] forWindow:[self window]];
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
        NSLog(@"Module ID Read of NHQ226L FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Module ID Read of NHQ226L", @"OK", nil, nil,
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
        NSLog(@"Hardware access of NHQ226L FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed HW Access of NHQ226L", @"OK", nil, nil,
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
		
		[model readStatusWord:0];
		[model readStatusWord:1];
		
		/// must move to an async change method
		
		unsigned short status1A = [model statusReg1Chan:0];
		unsigned short status1B = [model statusReg1Chan:1];
				
		NSFont* f = [NSFont fontWithName:@"Monaco" size:12];
		NSLogFont(f,@"-------------------------------\n");
		NSLogFont(f,@"Channel           A\t     B\n");
		NSLogFont(f,@"-------------------------------\n");
		NSLogFont(f,@"Status         : %@\t    %@\n",[model status2String:0],[model status2String:1]);
		NSLogFont(f,@"-------------------------------\n");
		
		NSLogFont(f,@"Quality Given  : %@\t%@\n", (status1A & kQuality)		  ? @"YES     ":@"NO      ", (status1B & kError)			? @"Err     ":@"OK      ");
		NSLogFont(f,@"V or I exceeded: %@\t%@\n", (status1A & kError)		  ? @"YES     ":@"NO      ", (status1B & kError)			? @"Err     ":@"OK      ");
		NSLogFont(f,@"Inh was active : %@\t%@\n", (status1A & kInhibit)       ? @"YES     ":@"NO      ", (status1B & kKillSwitch)	? @"Enabled ":@"Disabled");
		NSLogFont(f,@"Kill Switch    : %@\t%@\n", (status1A & kKillSwitch)	  ? @"Enabled ":@"Disabled", (status1B & kKillSwitch)	? @"Enabled ":@"Disabled");
		NSLogFont(f,@"HV Switch      : %@\t%@\n", (status1A & kHVSwitch)      ? @"Off     ":@"On      ", (status1B & kHVSwitch)		? @"Off     ":@"On      ");
		NSLogFont(f,@"HV Polarity    : %@\t%@\n", (status1A & kHVPolarity)	  ? @"Positive":@"Negative", (status1B & kHVPolarity)	? @"Positive":@"Negative");
		NSLogFont(f,@"Control        : %@\t%@\n", (status1A & kHVControl)	  ? @"Manual  ":@"DAC     ", (status1B & kHVControl)		? @"Manual  ":@"DAC     ");

		NSLogFont(f,@"-------------------------------\n");
	}
	@catch(NSException* localException) {
        NSLog(@"Status Read of NHQ226L FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nFailed Status Read of NHQ226L", @"OK", nil, nil,
                        localException);
    }
}
@end
					  
@implementation ORNHQ226LController (private)
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
#else
    //******contextInfo is released when the sheet closes.
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
- (void) populatePortListPopup
{
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
    [portListPopup removeAllItems];
    [portListPopup addItemWithTitle:@"--"];
	
	while (aPort = [enumerator nextObject]) {
        [portListPopup addItemWithTitle:[aPort name]];
	}    
}
- (void) syncDialog
{
	[self endEditing];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Sync Dialog to Hardware"];
    [alert setInformativeText:@"This will make Target Voltage == Actual Voltage\nAnd sync the rest of the values also."];
    [alert addButtonWithTitle:@"Yes/Do It"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model syncDialog];
        }
    }];
#else
    NSBeginAlertSheet(@"Sync Dialog to Hardware",
					  @"YES/Do it",
					  @"Cancel",
					  nil,
					  [self window],
					  self,
					  @selector(_syncSheetDidEnd:returnCode:contextInfo:),
					  nil,
					  nil,
					  @"This will make Target Voltage == Actual Voltage\nAnd sync the rest of the values also.");
#endif
}

#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _syncSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info
{
	if(returnCode == NSAlertDefaultReturn){
		[model syncDialog];
	}
}
#endif
@end

