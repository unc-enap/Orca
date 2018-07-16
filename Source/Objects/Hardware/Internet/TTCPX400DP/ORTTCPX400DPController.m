//
//  ORTTCPX400DPController.h
//  Orca
//
//  Created by Michael Marino on Saturday 12 Nov 2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORTTCPX400DPController.h"
#import "ORTTCPX400DPModel.h"

@interface ORTTCPX400DPController (private)
- (void) _buildPopUpButtons;
- (void) _showWarningPanel:(NSString*)astr;
- (void) _updateChannelModes:(unsigned int)bits withTextField:(NSTextField*)tf;
@end

@implementation ORTTCPX400DPController
- (id) init
{
    self = [ super initWithWindowNibName: @"TTCPX400DP" ];
    return self;
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"TT CPX400DP  %@",[model serialNumber]]];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORTTCPX400DPModelLock
						object: nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(ipChanged:)
						 name : ORTTCPX400DPIpHasChanged
						object: nil];  

    [notifyCenter addObserver : self
					 selector : @selector(serialChanged:)
						 name : ORTTCPX400DPSerialNumberHasChanged
						object: nil];      
    
    [notifyCenter addObserver : self
					 selector : @selector(generalReadbackChanged:)
						 name : ORTTCPX400DPGeneralReadbackHasChanged
						object: nil];        
    
    [notifyCenter addObserver : self
					 selector : @selector(connectionChanged:)
						 name : ORTTCPX400DPConnectionHasChanged
						object: nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(verbosityChanged:)
						 name : ORTTCPX400DPVerbosityHasChanged
						object: nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(readbackChanged:)
						 name : ORTTCPX400DPReadBackGetCurrentReadbackIsChanged
						object: nil];    
    
    [notifyCenter addObserver : self
					 selector : @selector(readbackChanged:)
						 name : ORTTCPX400DPReadBackGetVoltageTripSetIsChanged
						object: nil];

    [notifyCenter addObserver : self
					 selector : @selector(setValuesChanged:)
						 name : ORTTCPX_NOTIFY_WRITE_FORM(SetVoltage)
						object: nil];    
    
    [notifyCenter addObserver : self
					 selector : @selector(setValuesChanged:)
						 name : ORTTCPX_NOTIFY_WRITE_FORM(SetCurrentLimit)
						object: nil];    

    [notifyCenter addObserver : self
					 selector : @selector(setValuesChanged:)
						 name : ORTTCPX_NOTIFY_WRITE_FORM(SetOverVoltageProtectionTripPoint)
						object: nil];    
    
    [notifyCenter addObserver : self
					 selector : @selector(setValuesChanged:)
						 name : ORTTCPX_NOTIFY_WRITE_FORM(SetOverCurrentProtectionTripPoint)
						object: nil];        

    [notifyCenter addObserver : self
					 selector : @selector(outputStatusChanged:)
						 name : ORTTCPX_NOTIFY_WRITE_FORM(SetOutput)
						object: nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(hardwareErrorSeen:)
						 name : ORTTCPX400DPErrorSeen
						object: nil];
    
    [notifyCenter addObserver : self
					 selector : @selector(channelModeChanged:)
						 name : ORTTCPX_NOTIFY_READ_FORM(QueryAndClearLSR)
						object: nil];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
    [self _buildPopUpButtons];
//	[ipNumberComboBox reloadData];
}

- (void) updateWindow
{
    [ super updateWindow ];
    [self lockChanged:nil];
    [self ipChanged:nil];
    [self serialChanged:nil];    
    [self generalReadbackChanged:nil];
    [self connectionChanged:nil];
    [self readbackChanged:nil]; 
    [self setValuesChanged:nil];
    [self outputStatusChanged:nil];
    [self channelModeChanged:nil];
    [self verbosityChanged:nil];
    [self serialChanged:nil];
}

- (void) updateButtons
{
    BOOL locked = [gSecurity isLocked:ORTTCPX400DPModelLock] || [model userLocked];
    BOOL connected = [model isConnected];
    
    [serialNumberBox setEnabled:(!connected && !locked)];
    [ipAddressBox setEnabled:(!connected && !locked)];

    
#define LOCK_ALL_BUTTONS(opt)                       \
    [writeVolt ## opt setEnabled:!locked];          \
    [writeVoltTrip ## opt setEnabled:!locked];      \
    [writeCurrent ## opt setEnabled:!locked];       \
    [writeCurrentTrip ## opt setEnabled:!locked];   \
    [outputOn ## opt setEnabled:!locked];
    
    LOCK_ALL_BUTTONS(One);
    LOCK_ALL_BUTTONS(Two);
    
    [syncButton setEnabled:(!locked && connected)];
    [syncOutButton setEnabled:(!locked && connected)];
    [sendCommandButton setEnabled:(!locked && connected)];
    [readButton setEnabled:(!locked && connected)];
    [resetButton setEnabled:(!locked && connected)];
    [resetTripsButton setEnabled:(!locked && connected)];
    [clearButton setEnabled:(!locked && connected)];
    [checkErrorsButton setEnabled:(!locked && connected)];
    
    [connectButton setEnabled:!locked];
    
    if ([model userLocked]) {
        [lockText setStringValue:[NSString stringWithFormat:@"Locked by: %@",[model userLockedString]]];
    } else {
        [lockText setStringValue:@""];
    }
    
}

#pragma mark •••Notifications
- (void) lockChanged:(NSNotification*)aNote
{   
    BOOL locked = [gSecurity isLocked:ORTTCPX400DPModelLock];
    [lockButton setState: locked];
    [self updateButtons];
}

- (void) ipChanged:(NSNotification*)aNote
{   
    [ipAddressBox setStringValue:[model ipAddress]];
}

- (void) serialChanged:(NSNotification*)aNote
{   
    [serialNumberBox setStringValue:[model serialNumber]];
}

- (void) generalReadbackChanged:(NSNotification *)aNote
{
    [readBackText setStringValue:[model generalReadback]];
    //[sendCommandButton setEnabled:YES];    
}

- (void) connectionChanged:(NSNotification *)aNote
{
    BOOL isConnected = [model isConnected];
    if (isConnected) {
        [connectButton setTitle:@"Disconnect"];

    } else {
        [connectButton setTitle:@"Connect"];
        [self _updateChannelModes:0
                    withTextField:channelOneModeText];
        [self _updateChannelModes:0
                    withTextField:channelTwoModeText];
    }
    [self updateButtons];
    [[self window] setTitle:[NSString stringWithFormat:@"TT CPX400DP  %@",[model serialNumber]]];
}

- (void) readbackChanged:(NSNotification *)aNote
{
    [readBackVoltOne setFloatValue:[model readBackGetVoltageReadbackWithOutput:0]];
    [readBackVoltTripOne setFloatValue:[model readBackGetVoltageTripSetWithOutput:0]];    
    [readBackCurrentOne setFloatValue:[model readBackGetCurrentReadbackWithOutput:0]];
    [readBackCurrentTripOne setFloatValue:[model readBackGetCurrentTripSetWithOutput:0]];   

    [readBackVoltTwo setFloatValue:[model readBackGetVoltageReadbackWithOutput:1]];
    [readBackVoltTripTwo setFloatValue:[model readBackGetVoltageTripSetWithOutput:1]];    
    [readBackCurrentTwo setFloatValue:[model readBackGetCurrentReadbackWithOutput:1]];
    [readBackCurrentTripTwo setFloatValue:[model readBackGetCurrentTripSetWithOutput:1]];    

}

- (void) setValuesChanged:(NSNotification*)aNote
{
    if (aNote == nil) {
        [writeVoltOne setFloatValue:[model writeToSetVoltageWithOutput:0]];
        [writeVoltTripOne setFloatValue:[model writeToSetOverVoltageProtectionTripPointWithOutput:0]];    
        [writeCurrentOne setFloatValue:[model writeToSetCurrentLimitWithOutput:0]];
        [writeCurrentTripOne setFloatValue:[model writeToSetOverCurrentProtectionTripPointWithOutput:0]];   
        
        [writeVoltTwo setFloatValue:[model writeToSetVoltageWithOutput:1]];
        [writeVoltTripTwo setFloatValue:[model writeToSetOverVoltageProtectionTripPointWithOutput:1]];    
        [writeCurrentTwo setFloatValue:[model writeToSetCurrentLimitWithOutput:1]];
        [writeCurrentTripTwo setFloatValue:[model writeToSetOverCurrentProtectionTripPointWithOutput:1]];
        return;
    }
    if ([[aNote name] isEqualToString:ORTTCPX_NOTIFY_WRITE_FORM(SetVoltage)]) {
        [writeVoltOne setFloatValue:[model writeToSetVoltageWithOutput:0]];
        [writeVoltTwo setFloatValue:[model writeToSetVoltageWithOutput:1]];        
    } else if ([[aNote name] isEqualToString:ORTTCPX_NOTIFY_WRITE_FORM(SetOverVoltageProtectionTripPoint)]) {
        [writeVoltTripOne setFloatValue:[model writeToSetOverVoltageProtectionTripPointWithOutput:0]];
        [writeVoltTripTwo setFloatValue:[model writeToSetOverVoltageProtectionTripPointWithOutput:1]];        
    } else if ([[aNote name] isEqualToString:ORTTCPX_NOTIFY_WRITE_FORM(SetOverCurrentProtectionTripPoint)]) {
        [writeCurrentTripOne setFloatValue:[model writeToSetOverCurrentProtectionTripPointWithOutput:0]];
        [writeCurrentTripTwo setFloatValue:[model writeToSetOverCurrentProtectionTripPointWithOutput:1]];        
    } else if ([[aNote name] isEqualToString:ORTTCPX_NOTIFY_WRITE_FORM(SetCurrentLimit)]) {
        [writeCurrentOne setFloatValue:[model writeToSetCurrentLimitWithOutput:0]];
        [writeCurrentTwo setFloatValue:[model writeToSetCurrentLimitWithOutput:1]];        
    }
}

- (void) outputStatusChanged:(NSNotification *)aNote
{
    [outputOnOne setState:[model writeToSetOutputWithOutput:0]];
    [outputOnTwo setState:[model writeToSetOutputWithOutput:1]];    
}

- (void) hardwareErrorSeen:(NSNotification *)aNote
{
    if ([aNote object] != model) return;
    if (![model currentErrorCondition]) return;
    NSMutableString* mutableStr = [NSMutableString stringWithString:@"ESR Errors:\n"];
    NSArray* tempArray = [model explainStringsForESRBits:[model readBackValueESR]];
    for (id obj in tempArray) [mutableStr appendString:[NSString stringWithFormat:@"  %@\n",obj]];
    
    [mutableStr appendString:[NSString stringWithFormat:@"EER Error: %@\n",[model explainStringForEERBits:[model readBackValueEER]]]];
    [mutableStr appendString:[NSString stringWithFormat:@"QER Error: %@\n",[model explainStringForQERBits:[model readBackValueQER]]]];

    BOOL addExplainTest = NO;
    tempArray = [model explainStringsForLSRBits:[model readBackValueLSR:0]];
    [mutableStr appendString:@"LSR Errors(Output 1): \n"];
    for (id obj in tempArray) [mutableStr appendString:[NSString stringWithFormat:@"  %@\n",obj]];
    addExplainTest = ([tempArray count] != 0);
    
    tempArray = [model explainStringsForLSRBits:[model readBackValueLSR:1]];
    [mutableStr appendString:@"LSR Errors(Output 2): \n"];
    for (id obj in tempArray) [mutableStr appendString:[NSString stringWithFormat:@"  %@\n",obj]];
    
    addExplainTest |= ([tempArray count] != 0);
    
    if (addExplainTest) [mutableStr appendString:@"TRIP Errors MUST be explicitly reset.\n"];
    [self performSelectorOnMainThread:@selector(_showWarningPanel:)
                           withObject:mutableStr
                        waitUntilDone:NO];
    
}

- (void) verbosityChanged:(NSNotification*)aNote
{
    [verbosity setState:[model verbose]];
}

- (void) channelModeChanged:(NSNotification *)aNote
{
    [self _updateChannelModes:[model readBackValueLSR:0] withTextField:channelOneModeText];
    [self _updateChannelModes:[model readBackValueLSR:1] withTextField:channelTwoModeText];
    
}

#pragma mark •••Actions
- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORTTCPX400DPModelLock to:[sender intValue] forWindow:[self window]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORTTCPX400DPModelLock to:secure];
    [lockButton setEnabled:secure];
	[self updateButtons];
}

- (IBAction) commandPulldownAction:(id)sender
{
    int selectedRow = (int)[[sender selectedItem] tag];
    [inputValueText setEnabled:[model commandTakesInput:selectedRow]];
    [outputNumberPopUp setEnabled:[model commandTakesOutputNumber:selectedRow ]];    
}

- (IBAction) sendCommandAction:(id)sender
{
    [self endEditing];
    int cmd = (int)[[commandPopUp selectedItem] tag];
    int output = (int)[[outputNumberPopUp selectedItem] tag];
    float input = [inputValueText floatValue];
    [model writeCommand:cmd withInput:input withOutputNumber:output];
    //[sendCommandButton setEnabled:NO];
}

- (IBAction)connectAction:(id)sender
{
    [model toggleConnection];
}

- (IBAction)setSerialNumberAction:(id)sender
{
    [model setSerialNumber:[serialNumberBox stringValue]];
}

- (IBAction)setIPAddressAction:(id)sender
{
    [model setIpAddress:[ipAddressBox stringValue]];
}

- (IBAction)readBackAction:(id)sender
{
    [model readback:NO];
    [self checkAndClearErrorsAction:sender];
}

- (IBAction) syncValuesAction:(id)sender
{
#define DEF_TMP_VARS(val) \
    float vt ## val = [writeVoltTrip ## val floatValue];    \
    float ct ## val = [writeCurrentTrip ## val floatValue]; \
    float v ## val = [writeVolt ## val floatValue];         \
    float c ## val = [writeCurrent ## val floatValue];

#define SYNCALL(val)                                                                        \
    [model setWriteToSetOverVoltageProtectionTripPoint:vt ## val                            \
                                            withOutput:(unsigned int)[writeVoltTrip ## val tag]];         \
    [model setWriteToSetOverCurrentProtectionTripPoint:ct ## val                            \
                                            withOutput:(unsigned int)[writeCurrentTrip ## val tag]];      \
    [model setWriteToSetCurrentLimit:c ## val                                               \
                          withOutput:(unsigned int)[writeCurrent ## val tag]];                            \
    [model setWriteToSetVoltage:v ## val                                                    \
                     withOutput:(unsigned int)[writeVolt ## val tag]];

    DEF_TMP_VARS(One)
    DEF_TMP_VARS(Two)
    SYNCALL(One)
    SYNCALL(Two)
    
    [self performSelector:@selector(readBackAction:)
               withObject:nil
               afterDelay:0.5];
}

- (IBAction) writeOutputStatusAction:(id)sender
{
    if ([outputOnOne state] == [outputOnTwo state]) {
        [model setAllOutputToBeOn:[outputOnOne state]];
    } else {
        BOOL oneState = [outputOnOne state];
        BOOL twoState = [outputOnTwo state];
        [model setOutput:0 toBeOn:oneState];
        [model setOutput:1 toBeOn:twoState];
    }
    [self performSelector:@selector(readBackAction:)
               withObject:nil
               afterDelay:0.5];
}

- (IBAction) changeVerbosityAction:(id)sender
{
    [model setVerbose:[sender state]];
}

- (IBAction) clearAction:(id)sender
{
    [model clearStatus];
    [self readBackAction:nil];
}

- (IBAction) resetAction:(id)sender
{
    [model reset];
    [self readBackAction:nil];
}

- (IBAction) resetTripsAction:(id)sender
{
    [model resetTrips];
    [self readBackAction:nil];
}

- (IBAction) checkAndClearErrorsAction:(id)sender
{
    [model performSelectorInBackground:@selector(checkAndClearErrors) withObject:nil];
}

@end

@implementation ORTTCPX400DPController (private)

- (void) _buildPopUpButtons
{
    if ([commandPopUp numberOfItems] == [model numberOfCommands]) return;
    [commandPopUp removeAllItems];
    int i;
    for (i=0; i<[model numberOfCommands]; i++) {
        [commandPopUp addItemWithTitle:[model commandName:i]];
        [[commandPopUp itemAtIndex:i] setTag:i];
    }
}

- (void) _showWarningPanel:(NSString *)astr
{
    ORRunAlertPanel([NSString stringWithFormat:@"HW Error Seen in %@ (%@, %@)",[model objectName],
                     [model ipAddress],[model serialNumber]],
                    @"%@",
                    @"OK",nil,nil,astr);
}

- (void) _updateChannelModes:(unsigned int)bits withTextField:(NSTextField*)tf
{
    if (bits == 0) {
        [tf setTextColor:[NSColor blackColor]];
        [tf setStringValue:@"Not Set"];
    }
    else if (bits & 0x1) {
        [tf setTextColor:[NSColor greenColor]];
        [tf setStringValue:@"CV Mode"];
    } else if (bits & 0x2) {
        [tf setTextColor:[NSColor greenColor]];
        [tf setStringValue:@"CC Mode"];
    } else {
        [tf setTextColor:[NSColor redColor]];
        [tf setStringValue:@"TRIP"];
    }
}
@end

