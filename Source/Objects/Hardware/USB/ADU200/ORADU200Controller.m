//
//  ORHPADU200Controller.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 26 2007.
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


#import "ORADU200Controller.h"
#import "ORADU200Model.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"
#import "ORSerialPortList.h"

@implementation ORADU200Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"ADU200" ];
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
                         name : ORADU200ModelSerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORADU200ModelUSBInterfaceChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(relayStateChanged:)
                         name : ORADU200ModelRelayChanged
						object: nil];
	
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORADU200ModelLock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(portAChanged:)
                         name : ORADU200ModelPortAChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(eventCounterChanged:)
                         name : ORADU200ModelEventCounterChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(debounceChanged:)
                         name : ORADU200ModelDebounceChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(pollTimeChanged:)
                         name : ORADU200ModelPollTimeChanged
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
	[self relayStateChanged:nil];
    [self lockChanged:nil];
	[self portAChanged:nil];
	[self eventCounterChanged:nil];
	[self debounceChanged:nil];
	[self pollTimeChanged:nil];
}

- (void) pollTimeChanged:(NSNotification*)aNote
{
	[pollTimePopup selectItemWithTag: [model pollTime]];
}

- (void) debounceChanged:(NSNotification*)aNote
{
	[debouncePopup selectItemAtIndex: [model debounce]];
}


- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORADU200ModelLock to:secure];
    [lockButton setEnabled:secure];
}


#pragma mark ¥¥¥Notifications

- (void) eventCounterChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<4;i++){
		[[eventCounterMatrix cellWithTag:i] setIntValue: [model eventCounter:i]];
	}
}

- (void) portAChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<4;i++){
		[[portAMatrix cellWithTag:i] setIntValue: ([model portA] & (0x1L<<i))!=0];
	}
}

- (void) relayStateChanged:(NSNotification*)aNote
{
	int i;
	for(i=0;i<4;i++){
		[[relayStateMatrix cellWithTag:i] setStringValue:[model relayState:i]?@"Closed":@"Open"];
	}
}


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

- (void) lockChanged:(NSNotification*)aNote
{
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORADU200ModelLock];
    BOOL locked = [gSecurity isLocked:ORADU200ModelLock];
	
    [lockButton setState: locked];
	[serialNumberPopup setEnabled:!locked];
	[relayControlMatrix setEnabled:!lockedOrRunningMaintenance ]; 
	[queryButton setEnabled:!lockedOrRunningMaintenance];
	[debouncePopup setEnabled:!lockedOrRunningMaintenance];
	[pollTimePopup setEnabled:!lockedOrRunningMaintenance];
	[readClearButton setEnabled:!lockedOrRunningMaintenance];
}

#pragma mark ¥¥¥Actions
- (IBAction) pollTimeAction:(id)sender
{
	[model setPollTime:(int)[[sender selectedItem] tag]];
}

- (IBAction) debounceAction:(id)sender
{
	@try {
		[model setDebounce:(int)[sender indexOfSelectedItem]];
		[model sendDebounce];	
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

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORADU200ModelLock to:[sender intValue] forWindow:[self window]];
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
	if([model serialNumber])[serialNumberPopup selectItemWithTitle:[model serialNumber]];
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

- (IBAction) relayControlAction:(id)sender
{
	@try {
		[model toggleRelay:(unsigned int)[[sender selectedCell]tag]];
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

- (IBAction) readClearAction:(id)sender
{
	@try {
		[model readAndClear];
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

- (IBAction) queryAction:(id)sender
{
	@try {
		[model queryAll];
		int i;
		for(i=0;i<4;i++){
			NSLog(@"ADU200: Relay %d: %@\n",i,[model relayState:i]?@"Closed":@"Open");
		}
		NSLog(@"ADU200: PortA: 0x%0x\n",[model portA]);
		for(i=0;i<4;i++){
			NSLog(@"ADU200: Event Counter %d: %d\n",i,[model eventCounter:i]);
		}
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

- (IBAction) sendCommandAction:(id)sender
{
	@try {
		[self endEditing];
		if([commandField stringValue]){
			[model writeCommand:[commandField stringValue]];
		}
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



@end
