//
//  ORPulser33500Controller.m
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


#import "ORPulser33500Controller.h"
#import "ORPulser33500Model.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"

@implementation ORPulser33500Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"Pulser33500" ];
    return self;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];    
    [ super registerNotificationObservers ];
	
    [notifyCenter addObserver : self
                     selector : @selector(connectionProtocolChanged:)
                         name : ORPulser33500ConnectionProtocolChanged
                       object : model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ipAddressChanged:)
                         name : ORPulser33500IpAddressChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(ipConnectedChanged:)
                         name : ORPulser33500IpConnectedChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(canChangeConnectionProtocolChanged:)
                         name : ORPulser33500CanChangeConnectionProtocolChanged
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
                         name : ORPulser33500SerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORPulser33500USBInterfaceChanged
						object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORPulser33500Lock
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(setButtonStates)
                         name : ORPulser33500LoadingChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(showInKHzChanged:)
                         name : ORPulser33500ShowInKHzChanged
                       object : model];

    
}

- (void) awakeFromNib
{
	[self populateInterfacePopup];
	[super awakeFromNib];
}

- (void) updateWindow
{
    [super updateWindow];
    
    [self connectionProtocolChanged:nil];
	[self ipAddressChanged:nil];
	[self ipConnectedChanged:nil];
	[self canChangeConnectionProtocolChanged:nil];
    [self serialNumberChanged:nil];
    [self showInKHzChanged:nil];
    [self lockChanged:nil];
}

- (void) setModel:(id)aModel
{
	[super setModel:aModel];
	[chan1Controller setModel:[[aModel channels] objectAtIndex:0]];
	[chan2Controller setModel:[[aModel channels] objectAtIndex:1]];
}
#pragma mark •••Notifications
- (void) checkGlobalSecurity
{
    BOOL secure = [gSecurity globalSecurityEnabled];
    [gSecurity setLock:ORPulser33500Lock to:secure];
    [lockButton setEnabled:secure];
}

- (void) showInKHzChanged:(NSNotification*) aNotification
{
    [showInKHzCB setIntValue:[model showInKHz]];
}

- (void) lockChanged: (NSNotification*) aNotification
{
	[self setButtonStates];
}

- (void) serialNumberChanged:(NSNotification*)aNote
{
	if(![model serialNumber] || ![[model serialNumber] length] || ![model usbInterface])[serialNumberPopup selectItemAtIndex:0];
	else [serialNumberPopup selectItemWithTitle:[model serialNumber]];
	if([model connectionProtocol] == kPulser33500UseUSB){
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

- (void) connectionProtocolChanged:(NSNotification*)aNote
{
	[connectionProtocolMatrix selectCellWithTag:[model connectionProtocol]];
	[connectionProtocolTabView selectTabViewItemAtIndex:[model connectionProtocol]];
	[[self window] setTitle:[model title]];
	[self populateInterfacePopup];
}

- (void) setButtonStates
{	
    BOOL runInProgress  = [gOrcaGlobals runInProgress];
    BOOL locked			= [gSecurity isLocked:ORPulser33500Lock];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORPulser33500Lock];
	BOOL loading		= [model loading];
		  
	[connectionProtocolMatrix setEnabled:!runInProgress || !locked];
	[ipConnectButton setEnabled:!runInProgress || !locked];
	[ipAddressTextField setEnabled:!locked];
	[serialNumberPopup setEnabled:!locked];
	[initHardwareButton setEnabled:!lockedOrRunningMaintenance];
	
	[commandField setEnabled:!loading && !lockedOrRunningMaintenance];
    [sendCommandButton setEnabled:!loading && !lockedOrRunningMaintenance];
    [readIdButton setEnabled:!loading && !lockedOrRunningMaintenance];	
    [testButton setEnabled:!loading && !lockedOrRunningMaintenance];	
    [resetButton setEnabled:!loading && !lockedOrRunningMaintenance];	
    [clearMemoryButton setEnabled:!loading && !lockedOrRunningMaintenance];	
	
	
	[chan1Controller setButtonStates];
	[chan2Controller setButtonStates];

	
	NSString* s = @"";
	if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORPulser33500Lock])s = @"Not in Maintenance Run.";
    }
    [lockDocField setStringValue:s];
	
}

#pragma mark •••Actions
- (IBAction) showInKHzAction:(id)sender
{
    [model setShowInKHz:[sender intValue]];
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
	NSArray* interfaces = [[model getUSBController] interfacesForVenders:[model vendorIDs] products:[model productIDs]];
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

-(IBAction) readIdAction:(id)sender
{
	@try {
		NSLog(@"Pulser33500 Id: %@\n",[model readIDString]);
	}
	@catch(NSException* localException) {
		[self showExceptionAlert:localException];
	}
}

-(IBAction) resetAction:(id)sender
{
	@try {
	    [model resetAndClear];
	    NSLog(@"Pulser 33500 Reset and Clear successful.\n");
	}
	@catch(NSException* localException) {
		[self showExceptionAlert:localException];
	}
}

-(IBAction) testAction:(id)sender
{
	NSLog(@"Testing 33500 Pulser (takes a few seconds...).\n");
	[self performSelector:@selector(systemTest) withObject:nil afterDelay:0];
}

- (IBAction) sendCommandAction:(id)sender
{
	@try {
		[self endEditing];
		NSString* cmd = [commandField stringValue];
		if(cmd){
			if([cmd rangeOfString:@"?"].location != NSNotFound){
				char reply[1024];
				int32_t n = [model writeReadDevice:cmd data:reply maxLength:1024];
				if(n>0)reply[n-1]='\0';
				NSLog(@"%s\n",reply);
			}
			else {
				[model writeToDevice:[commandField stringValue]];
			}
		}
	}
	@catch(NSException* localException) {
		[self showExceptionAlert:localException];
	}
}

- (IBAction) lockAction:(id)sender
{
    [gSecurity tryToSetLock:ORPulser33500Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) systemTest
{
	@try {
	    [model systemTest];
	}
	@catch(NSException* localException) {
		[self showExceptionAlert:localException];
	}
}

- (IBAction) initHardware:(id)sender
{
	[model initHardware];
}


- (IBAction) showExceptionAlert:(NSException*) localException
{
	NSLog( @"%@\n",[ localException reason ] );
    ORRunAlertPanel( [ localException name ], 	// Name of panel
                    @"%@",	// Reason for error
                    @"OK",	// Okay button
                    nil,	// alternate button
                    nil,    // other button
                    [localException reason ]);
}


@end


