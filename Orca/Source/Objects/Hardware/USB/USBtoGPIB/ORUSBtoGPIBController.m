//
//  ORHPUSBtoGPIBController.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 26 2007.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG03-97ER41020/A000. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#import "ORUSBtoGPIBController.h"
#import "ORUSBtoGPIBModel.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"
#import "ORSerialPortList.h"

@implementation ORUSBtoGPIBController
- (id) init
{
    self = [ super initWithWindowNibName: @"USBtoGPIB" ];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
    
					   
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
                         name : ORUSBtoGPIBModelSerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORUSBtoGPIBModelUSBInterfaceChanged
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(addressChanged:)
                         name : ORUSBtoGPIBModelAddressChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(commandChanged:)
                         name : ORUSBtoGPIBModelCommandChanged
						object: model];

}

- (void) awakeFromNib
{
	[self populateInterfacePopup:[model getUSBController]];
	[super awakeFromNib];
}

- (void) updateWindow
{
    [ super updateWindow ];
    
	[self serialNumberChanged:nil];
	[self addressChanged:nil];
	[self commandChanged:nil];
}

- (void) commandChanged:(NSNotification*)aNote
{
	[commandTextField setStringValue: [model command]];
}

- (void) addressChanged:(NSNotification*)aNote
{
	[addressTextField setIntValue: [model gpibAddress]];
}


#pragma mark ¥¥¥Notifications

- (void) serialNumberChanged:(NSNotification*)aNote
{
	if(![model serialNumber] || ![model usbInterface])[serialNumberPopup selectItemAtIndex:0];
	else [serialNumberPopup selectItemWithTitle:[model serialNumber]];
	[[self window] setTitle:[model title]];
}

- (void) interfacesChanged:(NSNotification*)aNote
{
	[self populateInterfacePopup:[aNote object]];
}


#pragma mark ¥¥¥Actions

- (void) commandTextFieldAction:(id)sender
{
	[model setCommand:[sender stringValue]];	
}

- (void) addressTextFieldAction:(id)sender
{
	[model setGpibAddress:[sender intValue]];	
}

- (void) populateInterfacePopup:(ORUSB*)usb
{
	NSArray* interfaces = [usb interfacesForVender:[model vendorID] product:[model productID]];
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
	if([model serialNumber]){
		[serialNumberPopup selectItemWithTitle:[model serialNumber]];
	}
	else {
		[serialNumberPopup selectItemAtIndex:0];
	}
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

- (IBAction) sendAction:(id)sender
{
	[self endEditing];
	[model sendCommand];
}


@end
