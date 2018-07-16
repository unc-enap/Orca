//
//  ORXTR6Controller.m
//  Orca
//
//  Created by Mark Howe on Jan 15, 2014 2003.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#import "ORXTR6Controller.h"
#import "ORXTR6Model.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"
#import "ORSerialPortController.h"

@implementation ORXTR6Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"XTR6" ];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(connectionProtocolChanged:)
                         name : ORXTR6ModelConnectionProtocolChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORXTR6ModelIpAddressChanged
						object: model];
		
    [notifyCenter addObserver : self
                     selector : @selector(ipConnectedChanged:)
                         name : ORXTR6ModelIpConnectedChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(canChangeProtocolChanged:)
                         name : ORXTR6ModelCanChangeProtocolChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceAdded
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(interfacesChanged:)
                         name : ORUSBInterfaceRemoved
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORXTR6ModelSerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORXTR6ModelUSBInterfaceChanged
						object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(channelAddressChanged:)
                         name : ORXTR6ModelChannelAddressChanged
						object: model];
    
	[serialPortController registerNotificationObservers];

    [notifyCenter addObserver : self
                     selector : @selector(targetVoltageChanged:)
                         name : ORXTR6ModelTargetVoltageChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(voltageChanged:)
                         name : ORXTR6ModelVoltageChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(currentChanged:)
                         name : ORXTR6ModelCurrentChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(onOffStateChanged:)
                         name : ORXTR6ModelOnOffStateChanged
						object: model];

}

- (void) awakeFromNib
{
	[self populateInterfacePopup];
	[super awakeFromNib];
}

- (void) updateWindow
{
    [ super updateWindow ];
    
	[self ipAddressChanged:nil];
	[self ipConnectedChanged:nil];
	[serialPortController updateWindow];
	[self canChangeProtocolChanged:nil];
	[self serialNumberChanged:nil];
	[self channelAddressChanged:nil];
    [self connectionProtocolChanged:nil];
	[self targetVoltageChanged:nil];
	[self voltageChanged:nil];
	[self currentChanged:nil];
	[self onOffStateChanged:nil];
}

- (void) onOffStateChanged:(NSNotification*)aNote
{
	[onOffStateField setObjectValue: [model onOffState]?@"ON":@"OFF"];
    [onButton setEnabled:![model onOffState]];
    [offButton setEnabled:[model onOffState]];
}

- (void) currentChanged:(NSNotification*)aNote
{
	[currentField setFloatValue: [model current]];
}

- (void) voltageChanged:(NSNotification*)aNote
{
	[voltageField setFloatValue: [model voltage]];
}

- (void) targetVoltageChanged:(NSNotification*)aNote
{
	[targetVoltageField setFloatValue: [model targetVoltage]];
}

- (void) channelAddressChanged:(NSNotification*)aNote
{
	[channelAddressField setIntValue: [model channelAddress]];
}

#pragma mark •••Notifications
- (void) serialNumberChanged:(NSNotification*)aNote
{
	if(![model serialNumber] || ![[model serialNumber] length] || ![model usbInterface])[serialNumberPopup selectItemAtIndex:0];
	else [serialNumberPopup selectItemWithTitle:[model serialNumber]];
	if([model connectionProtocol] == kHPXTR6UseUSB){
		[[self window] setTitle:[model title]];
	}
}

- (void) interfacesChanged:(NSNotification*)aNote
{
	[self populateInterfacePopup];
}

- (void) canChangeProtocolChanged:(NSNotification*)aNote
{
	[connectionProtocolMatrix setEnabled:[model canChangeConnectionProtocol]];
	if([model canChangeConnectionProtocol])[connectionNoteTextField setStringValue:@""];
	else [connectionNoteTextField setStringValue:@"Disconnect Icon to Enable"];
	[self populateInterfacePopup];
}

- (void) ipConnectedChanged:(NSNotification*)aNote
{
	[ipConnectedTextField setStringValue: [model ipConnected]?@"Connected":@"Not Connected"];
}

- (void) ipAddressChanged:(NSNotification*)aNote
{
	[ipAddressTextField setStringValue: [model ipAddress]];
}

- (void) lockChanged: (NSNotification*) aNotification
{	
	[self updateButtons];
}

- (void) connectionProtocolChanged:(NSNotification*)aNote
{
	[connectionProtocolMatrix selectCellWithTag:[model connectionProtocol]];
	[connectionProtocolTabView selectTabViewItemAtIndex:[model connectionProtocol]];
	[[self window] setTitle:[model title]];
	[self populateInterfacePopup];
}

- (void) updateButtons
{
	
    BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORXTR6Lock];
    
    [serialPortController updateButtons:locked];

	[connectionProtocolMatrix setEnabled:[model canChangeConnectionProtocol]];
	[ipConnectButton setEnabled:!runInProgress || !locked];
    [remoteButton setEnabled:!locked];
	[ipAddressTextField setEnabled:!locked];
	[serialNumberPopup setEnabled:!locked];
}

#pragma mark •••Actions

- (IBAction) targetVoltageAction:(id)sender
{
	[model setTargetVoltage:[sender floatValue]];
}

- (IBAction) channelAddressAction:(id)sender
{
	[model setChannelAddress:[sender intValue]];	
}
- (IBAction) ipAddressTextFieldAction:(id)sender
{
	[model setIpAddress:[sender stringValue]];	
}

- (IBAction) connectionProtocolAction:(id)sender
{
	[model setConnectionProtocol:(int)[[connectionProtocolMatrix selectedCell] tag]];
	
	BOOL undoWasEnabled = [[model undoManager] isUndoRegistrationEnabled];
    if(undoWasEnabled)[[model undoManager] disableUndoRegistration];
	[model adjustConnectors:NO];
	if(undoWasEnabled)[[model undoManager] enableUndoRegistration];
	
}

- (void) populateInterfacePopup
{
	NSArray* interfaces = [model usbInterfaces];
	[serialNumberPopup removeAllItems];
	[serialNumberPopup addItemWithTitle:@"N/A"];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([serialNumber length]){
			[serialNumberPopup addItemWithTitle:serialNumber];
		}
	}
	[self validateInterfacePopup];
	if([[model serialNumber] length] > 0){
		if([serialNumberPopup indexOfItemWithTitle:[model serialNumber]]>=0){
			[serialNumberPopup selectItemWithTitle:[model serialNumber]];
		}
		else [serialNumberPopup selectItemAtIndex:0];
	}
	else [serialNumberPopup selectItemAtIndex:0];
}

- (void) validateInterfacePopup
{
	NSArray* interfaces = [[model getUSBController] interfacesForVender:[model vendorID] product:[model productID]];
	NSEnumerator* e = [interfaces objectEnumerator];
	ORUSBInterface* anInterface;
	while(anInterface = [e nextObject]){
		NSString* serialNumber = [anInterface serialNumber];
		if([anInterface registeredObject] == nil || [serialNumber isEqualToString:[model serialNumber]]){
			[[serialNumberPopup itemWithTitle:serialNumber] setEnabled:YES];
		}
		else [[serialNumberPopup itemWithTitle:serialNumber] setEnabled:NO];
	}
}

- (IBAction) serialNumberAction:(id)sender
{
	if([serialNumberPopup indexOfSelectedItem] == 0){
		[model setSerialNumber:nil];
	}
	else {
		[model setSerialNumber:[serialNumberPopup titleOfSelectedItem]];
	}
}
- (IBAction) loadParamsAction:(id)sender
{
	@try {
		[self endEditing];
        [model loadParams];
    }
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
		ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,    // other button
                        [localException reason ]);
	}
	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORXTR6Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) sendCommandAction:(id)sender
{
	@try {
		[self endEditing];
		NSString* cmd = [commandField stringValue];
        [model writeToDevice:cmd];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,	// other button
                        [localException reason ]);
	}
	
}
- (IBAction) test:(id)sender
{
	NSLog(@"Testing XTR6 (takes a few seconds...).\n");
	[model performSelector:@selector(systemTest) withObject:nil afterDelay:0];
    
}

-(IBAction) readIdAction:(id)sender
{
	@try {
		[model readIDString];
	}
	@catch(NSException* localException) {
        NSLog( [ localException reason ] );
        ORRunAlertPanel( [ localException name ], 	// Name of panel
						@"%@",	// Reason for error
						@"OK",	// Okay button
						nil,	// alternate button
						nil,	// other button
                        [localException reason ]);
	}
}

@end
