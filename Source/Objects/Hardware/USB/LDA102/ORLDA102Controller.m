//
//  ORHPLDA102Controller.m
//  Orca
//
//  Created by Mark Howe on Wed Feb 18, 2009.
//  Copyright (c) 2009 CENPA, University of Washington. All rights reserved.
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

#import "ORLDA102Controller.h"
#import "ORLDA102Model.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"

@implementation ORLDA102Controller
- (id) init
{
    self = [ super initWithWindowNibName: @"LDA102" ];
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
                         name : ORLDA102ModelSerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORLDA102ModelUSBInterfaceChanged
						object: nil];
		
	[notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORRunStatusChangedNotification
					   object : nil];
	
    [notifyCenter addObserver : self
					 selector : @selector(lockChanged:)
						 name : ORLDA102ModelLock
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(attenuationChanged:)
                         name : ORLDA102ModelAttenuationChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(stepSizeChanged:)
                         name : ORLDA102ModelStepSizeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(rampStartChanged:)
                         name : ORLDA102ModelRampStartChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(rampEndChanged:)
                         name : ORLDA102ModelRampEndChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(dwellTimeChanged:)
                         name : ORLDA102ModelDwellTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(idleTimeChanged:)
                         name : ORLDA102ModelIdleTimeChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(repeatRampChanged:)
                         name : ORLDA102ModelRepeatRampChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(rampValueChanged:)
                         name : ORLDA102ModelRampValueChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(rampRunningChanged:)
                         name : ORLDA102ModelRampRunningChanged
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
    [self lockChanged:nil];
	[self attenuationChanged:nil];
	[self stepSizeChanged:nil];
	[self rampStartChanged:nil];
	[self rampEndChanged:nil];
	[self dwellTimeChanged:nil];
	[self idleTimeChanged:nil];
	[self repeatRampChanged:nil];
	[self rampValueChanged:nil];
	[self rampRunningChanged:nil];
}

- (void) rampRunningChanged:(NSNotification*)aNote
{
	if([model rampRunning]){
		[rampRunningProgress startAnimation:self];
	}
	else {
		[rampRunningProgress stopAnimation:self];
	}
	[self lockChanged:nil];
}

- (void) repeatRampChanged:(NSNotification*)aNote
{
	[repeatRampButton setIntValue: [model repeatRamp]];
}

- (void) rampValueChanged:(NSNotification*)aNote
{
	[rampValueField setFloatValue: [model rampValue]];
}

- (void) idleTimeChanged:(NSNotification*)aNote
{
	[idleTimeField setIntValue: [model idleTime]];
}

- (void) dwellTimeChanged:(NSNotification*)aNote
{
	[dwellTimeField setIntValue: [model dwellTime]];
}

- (void) rampEndChanged:(NSNotification*)aNote
{
	[rampEndField setFloatValue: [model rampEnd]];
}

- (void) rampStartChanged:(NSNotification*)aNote
{
	[rampStartField setFloatValue: [model rampStart]];
}

- (void) stepSizeChanged:(NSNotification*)aNote
{
	[stepSizeField setFloatValue: [model stepSize]];
}

- (void) attenuationChanged:(NSNotification*)aNote
{
	[attenuationField setFloatValue: [model attenuation]];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORLDA102ModelLock to:secure];
    [lockButton setEnabled:secure];
}

#pragma mark •••Notifications
- (void) interfacesChanged:(NSNotification*)aNote
{
	[self populateInterfacePopup:[aNote object]];
}

- (void) lockChanged:(NSNotification*)aNote
{
	BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORLDA102ModelLock];
    BOOL locked = [gSecurity isLocked:ORLDA102ModelLock];
	BOOL rampRunning = [model rampRunning];
    [lockButton setState: locked];
	[serialNumberPopup setEnabled:!locked];
	[repeatRampButton setEnabled:!lockedOrRunningMaintenance && !rampRunning];
	[idleTimeField setEnabled:!lockedOrRunningMaintenance && !rampRunning];
	[dwellTimeField setEnabled:!lockedOrRunningMaintenance && !rampRunning];
	[rampEndField setEnabled:!lockedOrRunningMaintenance && !rampRunning];
	[rampStartField setEnabled:!lockedOrRunningMaintenance && !rampRunning];
	[attenuationField setEnabled:!lockedOrRunningMaintenance && !rampRunning];
	[loadAttenuationButton setEnabled:!lockedOrRunningMaintenance && !rampRunning];
	[rampStartStopButton setEnabled:!lockedOrRunningMaintenance];
	[rampStartStopButton setTitle:[model rampRunning]?@"Stop":@"Start"];
}

- (void) serialNumberChanged:(NSNotification*)aNote
{
	if(![model serialNumber] || ![model usbInterface])[serialNumberPopup selectItemAtIndex:0];
	else [serialNumberPopup selectItemWithTitle:[model serialNumber]];
	[[self window] setTitle:[model title]];
}

#pragma mark •••Actions
- (IBAction) repeatRampAction:(id)sender
{
	[model setRepeatRamp:[sender intValue]];	
}

- (IBAction) idleTimeAction:(id)sender
{
	[model setIdleTime:[sender intValue]];	
}

- (IBAction) dwellTimeAction:(id)sender
{
	[model setDwellTime:[sender intValue]];	
}

- (IBAction) rampEndAction:(id)sender
{
	[model setRampEnd:[sender floatValue]];	
}

- (IBAction) rampStartAction:(id)sender
{
	[model setRampStart:[sender floatValue]];	
}

- (IBAction) stepSizeAction:(id)sender
{
	[model setStepSize:[sender floatValue]];	
}

- (IBAction) attenuationAction:(id)sender
{
	[model setAttenuation:[sender floatValue]];	
}

- (IBAction) loadAttenuationAction:(id)sender
{
	[self endEditing];
	[model loadAttenuation];	
}

- (IBAction) settingLockAction:(id) sender
{
    [gSecurity tryToSetLock:ORLDA102ModelLock to:[sender intValue] forWindow:[self window]];
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



@end
