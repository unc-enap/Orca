//
//  ORHPPulser33220Controller.m
//  Orca
//
//  Created by Mark Howe on Tue May 13 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#import "ORPulser33220Controller.h"
#import "ORPulser33220Model.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"

@implementation ORPulser33220Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"HPPulser33220" ];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
    [notifyCenter addObserver : self
                     selector : @selector(connectionProtocolChanged:)
                         name : ORPulser33220ModelConnectionProtocolChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORPulser33220ModelIpAddressChanged
						object: model];
		
    [notifyCenter addObserver : self
                     selector : @selector(ipConnectedChanged:)
                         name : ORPulser33220ModelIpConnectedChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(canChangeConnectionProtocolChanged:)
                         name : ORPulser33220ModelCanChangeConnectionProtocolChanged
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
                         name : ORPulser33220ModelSerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORPulser33220ModelUSBInterfaceChanged
						object: nil];
	
}

- (void) awakeFromNib
{
	[self populateInterfacePopup];
	[super awakeFromNib];
}

- (void) updateWindow
{
    [ super updateWindow ];
    
    [self connectionProtocolChanged:nil];
	[self ipAddressChanged:nil];
	[self ipConnectedChanged:nil];
	[self canChangeConnectionProtocolChanged:nil];
	[self serialNumberChanged:nil];
}

#pragma mark ¥¥¥Notifications
- (void) serialNumberChanged:(NSNotification*)aNote
{
	if(![model serialNumber] || ![[model serialNumber] length] || ![model usbInterface])[serialNumberPopup selectItemAtIndex:0];
	else [serialNumberPopup selectItemWithTitle:[model serialNumber]];
	if([model connectionProtocol] == kHPPulserUseUSB){
		[[self window] setTitle:[model title]];
	}
}

- (void) interfacesChanged:(NSNotification*)aNote
{
	[self populateInterfacePopup];
}

- (void) canChangeConnectionProtocolChanged:(NSNotification*)aNote
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
	[super lockChanged:aNotification];
	
	[self setButtonStates];
	
}

- (void) connectionProtocolChanged:(NSNotification*)aNote
{
	[connectionProtocolMatrix selectCellWithTag:[model connectionProtocol]];
	[connectionProtocolTabView selectTabViewItemAtIndex:[model connectionProtocol]];
	[[self window] setTitle:[model title]];
	[self populateInterfacePopup];
}

- (void) setButtonStates
{
	[super setButtonStates];
	
    BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:[model dialogLock]] || [model lockGUI];
    BOOL loading		= [model loading];
    
	locked |= [model lockGUI];
	
	[connectionProtocolMatrix setEnabled:!runInProgress || !locked];
	[ipConnectButton setEnabled:!runInProgress || !locked];
    [remoteButton setEnabled:!locked && !loading];
	[ipAddressTextField setEnabled:!locked];
	[serialNumberPopup setEnabled:!locked];
}

#pragma mark ¥¥¥Actions
- (void) ipAddressTextFieldAction:(id)sender
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

- (IBAction) remoteAction:(id)sender
{
	@try {
		[model sendRemoteCommand];
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

@end
