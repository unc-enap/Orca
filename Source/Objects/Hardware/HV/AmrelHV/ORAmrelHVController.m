//
//  ORAmrelHVController.m
//  Orca
//
//  Created by Mark Howe on Thursday, Aug 20,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORAmrelHVController.h"
#import "ORAmrelHVModel.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"

@interface ORAmrelHVController (private)
- (void) populatePortListPopup;
- (void) panicToZero:(unsigned short)aChannel;
- (void) syncDialog;
#if !defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
- (void) _panicRampSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(NSDictionary*)userInfo;
- (void) _syncSheetDidEnd:(id)sheet returnCode:(int)returnCode contextInfo:(id)info;
#endif
@end

@implementation ORAmrelHVController
- (id) init
{
    self = [ super initWithWindowNibName: @"AmrelHV" ];
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

- (void) awakeFromNib
{
    [self populatePortListPopup];

    oneChannelSize	= NSMakeSize(523,400);
    twoChannelSize	= NSMakeSize(523,636);
		
	[super awakeFromNib];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [super registerNotificationObservers];
	
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORAmrelHVLock
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(setVoltageChanged:)
						 name : ORAmrelHVSetVoltageChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(actVoltageChanged:)
						 name : ORAmrelHVActVoltageChanged
						object: model];
	
	[notifyCenter addObserver : self
					 selector : @selector(pollTimeChanged:)
						 name : ORAmrelHVPollTimeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(actCurrentChanged:)
                         name : ORAmrelHVActCurrentChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORAmrelHVModelPortNameChanged
                        object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(numberOfChannelsChanged:)
                         name : ORAmrelHVModelNumberOfChannelsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(outputStateChanged:)
                         name : ORAmrelHVModelOutputStateChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(rampRateChanged:)
                         name : ORAmrelHVModelRampRateChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(rampEnabledChanged:)
                         name : ORAmrelHVModelRampEnabledChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(rampStateChanged:)
                         name : ORAmrelHVModelRampStateChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(timedOut:)
                         name : ORAmrelHVModelTimeout
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(dataIsValidChanged:)
                         name : ORAmrelHVModelDataIsValidChanged
						object: model];
	
	[notifyCenter addObserver : self
                     selector : @selector(maxCurrentChanged:)
                         name : ORAmrelHVMaxCurrentChanged
						object: model];	
}

- (void) updateWindow
{
    [ super updateWindow ];
    [self lockChanged:nil];
	[self portStateChanged:nil];
    [self portNameChanged:nil];
	[self setVoltageChanged:nil];
	[self pollTimeChanged:nil];
	[self numberOfChannelsChanged:nil];
	[self outputStateChanged:nil];
	[self polarityChanged:nil];
	[self rampRateChanged:nil];
	[self rampEnabledChanged:nil];
	[self rampStateChanged:nil];
	[self dataIsValidChanged:nil];
	[self maxCurrentChanged:nil];
	[self updateButtons];
}

- (void) timedOut:(NSNotification*)aNote
{
	[timeoutField setStringValue:@"Time Out"];
}

- (void) dataIsValidChanged:(NSNotification*)aNote
{
	[self updateButtons];
	[self actVoltageChanged:aNote];
	[self actCurrentChanged:aNote];
	[self outputStateChanged:aNote];
}

- (void) rampStateChanged:(NSNotification*)aNote
{
	[rampStateAField setIntValue: [model rampState:0]];
	[rampStateBField setIntValue: [model rampState:1]];
	if(aNote) {
		[self updateChannelButtons:0];
		[self updateChannelButtons:1];
	}
}

- (void) rampEnabledChanged:(NSNotification*)aNote
{
	[rampEnabledACB setIntValue: [model rampEnabled:0]];
	[rampEnabledBCB setIntValue: [model rampEnabled:1]];
	if(aNote)[self updateButtons];
}

- (void) outputStateChanged:(NSNotification*)aNote
{
	if([model allDataIsValid:0]){
		[hvPowerAField setTextColor:[NSColor blackColor]];
		if([model outputState:0])	[hvPowerAField setStringValue:@"On"];
		else						[hvPowerAField setStringValue:@"Off"];
	}
	else {
		[hvPowerAField setTextColor:[NSColor redColor]];
		[hvPowerAField setStringValue:@"??"];
	}
	if([model allDataIsValid:1]){
		[hvPowerBField setTextColor:[NSColor blackColor]];
		if([model outputState:1])	[hvPowerBField setStringValue:@"On"];
		else						[hvPowerBField setStringValue:@"Off"];
	}
	else {
		[hvPowerBField setTextColor:[NSColor redColor]];
		[hvPowerBField setStringValue:@"??"];
	}
	[self performSelector:@selector(updateChannels) withObject:nil afterDelay:0];
	[self performSelector:@selector(updateButtons) withObject:nil afterDelay:0];
}

- (void) numberOfChannelsChanged:(NSNotification*)aNote
{
	[numberOfChannelsPU selectItemAtIndex: [model numberOfChannels]-1];
	[self updateButtons];
	[self adjustWindowSize];
}

- (void) rampRateChanged:(NSNotification*)aNote
{
	[rampRateAField setFloatValue:[model rampRate:0]];
	[rampRateBField setFloatValue:[model rampRate:1]];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
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

- (void) setVoltageChanged:(NSNotification*)aNote
{
	[setVoltageAField setFloatValue:[model voltage:0]];
	[setVoltageBField setFloatValue:[model voltage:1]];
}

- (void) actVoltageChanged:(NSNotification*)aNote
{
	[actVoltageAField setTextColor:[model allDataIsValid:0]?[NSColor blackColor]:[NSColor redColor]];
	[actVoltageAField setFloatValue:[model actVoltage:0]];
	[actVoltageBField setTextColor:[model allDataIsValid:1]?[NSColor blackColor]:[NSColor redColor]];
	[actVoltageBField setFloatValue:[model actVoltage:1]];

	[self updateChannelButtons:0];
	[self updateChannelButtons:1];
}

- (void) polarityChanged:(NSNotification*)aNote
{
	[polarityAPU selectItemAtIndex:[model polarity:0]];
	[polarityBPU selectItemAtIndex:[model polarity:1]];
}

- (void) actCurrentChanged:(NSNotification*)aNote
{
	[actCurrentAField setTextColor:[model allDataIsValid:0]?[NSColor blackColor]:[NSColor redColor]];
	[actCurrentBField setTextColor:[model allDataIsValid:1]?[NSColor blackColor]:[NSColor redColor]];
	[actCurrentAField setFloatValue:[model actCurrent:0]];
	[actCurrentBField setFloatValue:[model actCurrent:1]];
}

- (void) maxCurrentChanged:(NSNotification*)aNote
{
	[maxCurrentAField setFloatValue:[model maxCurrent:0]];
	[maxCurrentBField setFloatValue:[model maxCurrent:1]];
}

- (void)adjustWindowSize
{
    switch([model numberOfChannels]){
        case  1: [self resizeWindowToSize:oneChannelSize];    break;
		case  2: [self resizeWindowToSize:twoChannelSize];	  break;
    }
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORAmrelHVLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
	[self updateButtons];
}

- (void) pollTimeChanged:(NSNotification*)aNote
{
	[pollTimePopup selectItemWithTag: [model pollTime]];
	if([model pollTime])[pollingProgress startAnimation:self];
	else [pollingProgress stopAnimation:self];
}

#pragma mark •••Notifications

- (void) updateButtons
{
    //BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORAmrelHVLock];
    BOOL portOpen		= [[model serialPort] isOpen];
	
    [lockButton setState: locked];
	
	[pollTimePopup		setEnabled: !locked && portOpen];
	[pollNowButton		setEnabled: !locked && portOpen];
	
	if([model channelIsValid:0]){
		BOOL dataIsValid = [model allDataIsValid:0];
		[polarityAPU		setEnabled: !locked && portOpen];
		[setVoltageAField	setEnabled: !locked && portOpen];
		[maxCurrentAField	setEnabled: !locked && portOpen];
		[loadValuesAButton	setEnabled: !locked && portOpen];
		[rampRateAField		setEnabled: !locked && portOpen && [model rampEnabled:0]];
		[clrCurrentTripAButton setEnabled: !locked && portOpen];
		if([model rampEnabled:0])[setVoltageLabelA setStringValue:@"Ramp To:"];
		else					 [setVoltageLabelA setStringValue:@"Set To:"];
		[hvPowerAButton setEnabled:dataIsValid];
		if(dataIsValid){
			if([model outputState:0]) [hvPowerAButton setTitle:@"Turn Off"];
			else					  [hvPowerAButton setTitle:@"Turn On"];
		}
		else {
			[hvPowerAButton setTitle:@"--"];
		}
		[self updateChannelButtons:0];
	}
	
	if([model channelIsValid:1]){
		BOOL dataIsValid = [model allDataIsValid:1];
		[polarityBPU		setEnabled: !locked && portOpen];
		[setVoltageBField	setEnabled: !locked && portOpen];
		[maxCurrentBField	setEnabled: !locked && portOpen];
		[loadValuesBButton	setEnabled: !locked && portOpen];
		[rampRateBField		setEnabled: !locked && portOpen && [model rampEnabled:1]];
		[clrCurrentTripBButton setEnabled: !locked && portOpen];
		if([model rampEnabled:1])[setVoltageLabelB setStringValue:@"Ramp To:"];
		else					 [setVoltageLabelB setStringValue:@"Set To:"];
		
		[hvPowerBButton setEnabled:dataIsValid];
		if(dataIsValid){
			if([model outputState:1]) [hvPowerBButton setTitle:@"Turn Off"];
			else					  [hvPowerBButton setTitle:@"Turn On"];
		}
		else {
			[hvPowerBButton setTitle:@"--"];
		}
		[self updateChannelButtons:1];
	}
	
	[moduleIDButton		setEnabled: !locked && portOpen];
	[syncButton 	    setEnabled: !locked && portOpen];
}

- (void) updateChannels
{
	[self updateChannelButtons:0];
	[self updateChannelButtons:1];
}

- (void) updateChannelButtons:(int)i
{
	BOOL locked				= [gSecurity isLocked:ORAmrelHVLock];
	BOOL portOpen			= [[model serialPort] isOpen];
	BOOL OKForPowerEnable	= !locked && portOpen;
	BOOL dataIsValid		= [model allDataIsValid:i];
	
	if([model channelIsValid:i]){
		if([model outputState:i]){
			//power is on. power can only be turned off if act voltage low
			OKForPowerEnable &= ([model actVoltage:i]<1);
		}
		NSImageView* theImageView = ((i==0) ? hvStateAImage:hvStateBImage);
		NSProgressIndicator* theRampProgress = ((i==0) ? rampingAProgress:rampingBProgress);
		if(![model outputState:i])[theImageView setImage:nil];
		else {
			if([model rampState:i] == kAmrelHVNotRamping){
				[theRampProgress stopAnimation:self];
				if([model actVoltage:i]<1) {
					[theImageView setImage:nil];
				}
				else if([model actVoltage:i]>1 && [model actVoltage:i]<99){
					[theImageView setImage:[NSImage imageNamed:@"lowVoltage"]];
				}
				else {
					[theImageView setImage:[NSImage imageNamed:@"highVoltage"]];
				}
			}
			else if([model rampState:i] == kAmrelHVRampingUp){
				[theImageView setImage:[NSImage imageNamed:@"upRamp"]];
				[theRampProgress setDoubleValue:[model rampProgress:i]];
				[theRampProgress startAnimation:self];
			}
			else if([model rampState:i] == kAmrelHVRampingDn){
				[theImageView setImage:[NSImage imageNamed:@"downRamp"]];
				[theRampProgress setDoubleValue:[model rampProgress:i]];
				[theRampProgress startAnimation:self];
			}
		}
		NSButton* powerButton = (i==0?hvPowerAButton:hvPowerBButton);
		[powerButton setEnabled: OKForPowerEnable && dataIsValid];
		
		if(i==0){
			[stopAButton		setEnabled: !locked && portOpen && [model rampState:0]!=kAmrelHVNotRamping];
			[rampEnabledACB		setEnabled: !locked && portOpen && [model rampState:1]==kAmrelHVNotRamping];
			[panicAButton		setEnabled: !locked && portOpen && dataIsValid && ([model actVoltage:0]>0)];
		}
		else if(i==1){
			[stopBButton		setEnabled: !locked && portOpen && [model rampState:1]!=kAmrelHVNotRamping];
			[rampEnabledBCB		setEnabled: !locked && portOpen && [model rampState:1]==kAmrelHVNotRamping];
			[panicBButton		setEnabled: !locked && portOpen && dataIsValid && ([model actVoltage:1]>0)];
		}
	}

	[systemPanicBButton setEnabled: (!locked && portOpen && dataIsValid && (([model actVoltage:0]>0) || ([model actVoltage:1]>0))) ];
		
}

- (NSString*) windowNibName
{
	return @"AmrelHV";
}

- (NSString*) rampItemNibFileName
{
	//subclasses can specify a differant RampItem nib file if needed.
	return @"HVRampItem";
}

#pragma mark •••Actions
- (IBAction) rampEnabledAction:(id)sender
{
	[model setRampEnabled:[sender tag] withValue:[sender intValue]];	
}

- (IBAction) rateRateAction:(id)sender
{
	[model setRampRate:[sender tag] withValue:[sender floatValue]];	
}

- (IBAction) numberOfChannelsAction:(id)sender
{
	[model setNumberOfChannels:[sender indexOfSelectedItem]+1];	
}

- (IBAction) polarityAction:(id)sender
{
	[model setPolarity:[sender tag] withValue:[sender indexOfSelectedItem]];	
}

- (IBAction) setVoltageAction:(id)sender
{
	[model setVoltage:[sender tag] withValue:[sender floatValue]];
}

- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:[[sender selectedItem] tag]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORAmrelHVLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) loadAllValues:(id)sender
{
	[self endEditing];
	[model loadHardware:[sender tag]];
}

- (IBAction) stopRampAction:(id)sender
{
	[model stopRamp:[sender tag]];
}

- (IBAction) panicAction:(id)sender
{
	[self panicToZero:[sender tag]];
}

- (IBAction) systemPanicAction:(id)sender
{
	[model panicToZero:0xFFFF];
}

- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) hwPowerAction:(id)sender
{
	[self endEditing];
	[model togglePower:[sender tag]];
}

- (IBAction) pollNowAction:(id)sender
{
	[model getAllValues];
}

- (IBAction) moduleIDAction:(id)sender
{
	[model getID];
}

- (IBAction) syncAction:(id)sender
{
	[self syncDialog];
}

- (IBAction) maxCurrentAction:(id)sender
{
	[self endEditing];
	[model setMaxCurrent:[sender tag] withValue:[sender floatValue]];
}

- (IBAction) clearCurrentTripAction:(id)sender
{
	[model clearCurrentTrip:[sender tag]];
}

@end

@implementation ORAmrelHVController (private)

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

- (void) panicToZero:(unsigned short)aChannel
{
	[self endEditing];
	//******contextInfo is released when the sheet closes.
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:[NSString stringWithFormat:@"HV Panic %@",aChannel==0xffff?@"(All Channels)":aChannel==0?@"Channel 0":@"Channel 1"]];
    [alert setInformativeText:@"Really Panic Selected High Voltage OFF?"];
    [alert addButtonWithTitle:@"YES/Do it NOW"];
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
    NSNumber* contextInfo =  [[NSDecimalNumber numberWithInt:aChannel] retain];
    NSBeginAlertSheet([NSString stringWithFormat:@"HV Panic %@",aChannel==0xffff?@"(All Channels)":aChannel==0?@"Channel 0":@"Channel 1"],
					  @"YES/Do it NOW",
					  @"Canel",
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
- (void) syncDialog
{
	[self endEditing];
#if defined(MAC_OS_X_VERSION_10_10) && MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_10 // 10.10-specific
    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:@"Sync Dialog to Hardware"];
    [alert setInformativeText:@"This will make Target Voltage == Actual Voltage\nAnd sync the rest of the values also."];
    [alert addButtonWithTitle:@"YES/Do it"];
    [alert addButtonWithTitle:@"Cancel"];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    [alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse result){
        if (result == NSAlertFirstButtonReturn){
            [model syncDialog];
       }
    }];
#else
    NSBeginAlertSheet([NSString stringWithFormat:@"Sync Dialog to Hardware"],
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


