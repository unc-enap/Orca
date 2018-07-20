//
//  ORSIS3150Controller.m
//  Orca
//
//  Created by Mark Howe on Wed Nov 20 2002.
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


#pragma mark •••Imported Files
#import "ORSIS3150Controller.h"
#import "ORSIS3150Model.h"
#import "ORVmeCrateModel.h"
#import "ORUSB.h"
#import "ORUSBInterface.h"


@implementation ORSIS3150Controller

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"SIS3150"];
	return self;
}
- (void) awakeFromNib
{
	[self populateInterfacePopup:[model getUSBController]];
	[super awakeFromNib];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [super registerNotificationObservers];
    
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
                         name : ORSIS3150SerialNumberChanged
						object: nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(serialNumberChanged:)
                         name : ORSIS3150USBInterfaceChanged
						object: nil];

	[notifyCenter addObserver : self
                     selector : @selector(rwAddressTextChanged:)
                         name : ORSIS3150RWAddressChanged
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(writeValueTextChanged:)
                         name : ORSIS3150WriteValueChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(readWriteAddressModifierChanged:)
                         name : ORSIS3150RWAddressModifierChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(readWriteIOSpaceChanged:)
                         name : ORSIS3150RWIOSpaceChanged
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(readWriteTypeChanged:)
                         name : ORSIS3150RWTypeChanged
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORSIS3150Lock
                        object: nil];
 	    
    [notifyCenter addObserver : self
                     selector : @selector(doRangeChanged:)
                         name : ORSIS3150DoRangeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(rangeChanged:)
                         name : ORSIS3150RangeChanged
						object: model];
	
}

#pragma mark •••Actions

#pragma mark •••Interface Management
- (void) updateWindow
{
	[super updateWindow];
	[self serialNumberChanged:nil];
    [self rwAddressTextChanged:nil];
    [self writeValueTextChanged:nil];
    [self readWriteTypeChanged:nil];
    [self readWriteIOSpaceChanged:nil];
    [self readWriteAddressModifierChanged:nil];
    [self lockChanged:nil];
	[self doRangeChanged:nil];
	[self rangeChanged:nil];
}
- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORSIS3150Lock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    BOOL lockedOrRunning = [gSecurity runInProgressOrIsLocked:ORSIS3150Lock];
    BOOL locked = [gSecurity isLocked:ORSIS3150Lock];
    
    [lockButton setState: locked];
    
    [writeButton setEnabled:!lockedOrRunning];
    [readButton setEnabled:!lockedOrRunning];
    [resetButton setEnabled:!lockedOrRunning];
    [sysResetButton setEnabled:!lockedOrRunning];
    [testButton setEnabled:!lockedOrRunning];
    
    [addressStepper setEnabled:!lockedOrRunning];
    [addressValueField setEnabled:!lockedOrRunning];
    [writeValueStepper setEnabled:!lockedOrRunning];
    [writeValueField setEnabled:!lockedOrRunning];
    [readWriteTypeMatrix setEnabled:!lockedOrRunning];
    [readWriteIOSpacePopUp setEnabled:!lockedOrRunning];
    [readWriteAddressModifierPopUp setEnabled:!lockedOrRunning];	
    [addressStepper setEnabled:!lockedOrRunning];
    [rangeStepper setEnabled:!lockedOrRunning];
}

- (void) rangeChanged:(NSNotification*)aNote
{
	[rangeTextField setIntValue: [model rangeToDo]];
	[rangeStepper setIntValue:	 [model rangeToDo]];
}

- (void) doRangeChanged:(NSNotification*)aNote
{
	[doRangeButton setIntValue: [model doRange]];
}

- (void) interfacesChanged:(NSNotification*)aNote
{
	[self populateInterfacePopup:[aNote object]];
}

- (void) serialNumberChanged:(NSNotification*)aNote
{
	if(![model serialNumber] || ![model usbInterface])[serialNumberPopup selectItemAtIndex:0];
	else [serialNumberPopup selectItemWithTitle:[model serialNumber]];
	[[self window] setTitle:[model title]];
}
- (void) rwAddressTextChanged:(NSNotification*)aNotification
{
	[addressValueField setIntegerValue:[model rwAddress]];
	[addressStepper setIntegerValue:[model rwAddress]];
}

- (void) writeValueTextChanged:(NSNotification*)aNotification
{
	[writeValueField setIntegerValue:[model writeValue]];
	[writeValueStepper setIntegerValue:[model writeValue]];
}

- (void) readWriteTypeChanged:(NSNotification*)aNotification
{
	[self updateRadioCluster:readWriteTypeMatrix setting:[model readWriteType]];
	
	switch([model readWriteType]){
		case 0: default: [addressStepper setIncrement:1]; break;
		case 1: [addressStepper setIncrement:2]; break;
		case 2: [addressStepper setIncrement:4]; break;
	}
}

- (void) readWriteIOSpaceChanged:(NSNotification*)aNotification
{
	[readWriteIOSpacePopUp selectItemAtIndex:[model readWriteIOSpace]];
}

- (void) readWriteAddressModifierChanged:(NSNotification*)aNotification
{
	[readWriteAddressModifierPopUp selectItemAtIndex:[model rwAddressModifier]];
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

#pragma mark •••Actions
- (IBAction) serialNumberAction:(id)sender
{
	if([serialNumberPopup indexOfSelectedItem] == 0){
		[model setSerialNumber:nil];
	}
	else {
		[model setSerialNumber:[serialNumberPopup titleOfSelectedItem]];
	}
}
- (void) rangeTextFieldAction:(id)sender
{
	[model setDoRange:[sender intValue]];	
}

- (void) doRangeAction:(id)sender
{
	[model setDoRange:[sender intValue]];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORSIS3150Lock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) rwAddressTextAction:(id)sender
{
	[model setRwAddress:[sender intValue]];		
}

- (IBAction) writeValueTextAction:(id)sender
{
    if([model writeValue] != [sender intValue]){
        [model setWriteValue:[sender intValue]];
    }
}


- (IBAction) readWriteTypeMatrixAction:(id)sender
{ 
    if ([model readWriteType] != [sender selectedTag]){
        [model setReadWriteType:(int)[sender selectedTag]];
    }
}

- (IBAction) ioSpaceAction:(id)sender
{
    if ([model readWriteIOSpace] != [sender indexOfSelectedItem]) { 
        [model setReadWriteIOSpace:(int)[sender indexOfSelectedItem]];
    }
}

- (IBAction) addressModifierAction:(id)sender
{
    if ([model rwAddressModifier] != [sender indexOfSelectedItem]) {
        [model setRwAddressModifier:(int)[sender indexOfSelectedItem]];
    }
}


- (IBAction) sysReset:(id)sender
{
    @try {
        [self endEditing];
        //unsigned char cdata;
        //[model vmeSysReset:&cdata];
    }
	@catch(NSException* localException) {
        NSLog(@"*** Unable To Send VME SYSRESET ***\n");
        NSLog(@"*** Check VME Bus Power and Cables ***\n");
        ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
                        localException);
    }
    
}

- (IBAction) reset:(id)sender
{
    // try to reset Bit3
    @try {
        [self endEditing];
        [model resetContrl];
        NSLog(@"%@ Reset\n",[model objectName]);
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
                        localException);
    }
}

- (IBAction) read:(id)sender
{
    uint32_t ldata;
    unsigned short sdata;
    unsigned char cdata;
    
    [self endEditing];
    uint32_t 	startAddress 	= [model rwAddress];
	uint32_t	endAddress		= [model doRange]?startAddress + [model rangeToDo]*[addressStepper increment] : startAddress;
    unsigned short 	addressModifier = [model rwAddressModifierValue];
    unsigned short 	addressSpace	= [model rwIOSpaceValue];
	
	uint32_t address = startAddress;
	if([model doRange] && [model rangeToDo]==0){
		NSLog(@"Range == 0: nothing to do\n");
		return;
	}
    @try {
		do {
			switch([model readWriteType]){
				case 0: //byte
					[model readByteBlock:&cdata
							   atAddress:address
							   numToRead:1
							  withAddMod:addressModifier
						   usingAddSpace:addressSpace];
					ldata = cdata;
					break;
					
				case 1: //short
					[model readWordBlock:&sdata
							   atAddress:address
							   numToRead:1
							  withAddMod:addressModifier
						   usingAddSpace:addressSpace];
					
					ldata = sdata;
					
					break;
					
				case 2: //int32_t
					[model readLongBlock:&ldata
							   atAddress:address
							   numToRead:1
							  withAddMod:addressModifier
						   usingAddSpace:addressSpace];
					
					break;
			}
			NSLog(@"Vme Read @ (0x%08x 0x%x %d): 0x%08x\n",address,addressModifier,addressSpace,ldata);
			address+=[addressStepper increment];
		}while(address<endAddress);
		
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nAddress: 0x%08lX", @"OK", nil, nil,
                        localException,address);
    }
}

- (IBAction) write:(id)sender
{
    unsigned short sdata;
    unsigned char  cdata;
    
    [self endEditing];
    uint32_t   startAddress 	= [model rwAddress];
	uint32_t	endAddress		= [model doRange]?startAddress + [model rangeToDo] : startAddress;
    unsigned short 	addressModifier = [model rwAddressModifierValue];
    unsigned short 	addressSpace	= [model rwIOSpaceValue];
    uint32_t  	ldata			= [model writeValue];
    
	uint32_t address = startAddress;
	if([model doRange] && [model rangeToDo]==0){
		NSLog(@"Range == 0: nothing to do\n");
		return;
	}
    @try {
		do {
			switch([model readWriteType]){
				case 0: //byte
					cdata = (unsigned char)ldata;
					[model writeByteBlock:&cdata
								atAddress:address
							   numToWrite:1
							   withAddMod:addressModifier
							usingAddSpace:addressSpace];
					ldata = cdata;
					break;
					
				case 1:	//short
					sdata = (unsigned short)ldata;
					[model writeWordBlock:&sdata
								atAddress:address
							   numToWrite:1
							   withAddMod:addressModifier
							usingAddSpace:addressSpace];
					
					ldata = sdata;
					break;
					
				case 2: //int32_t
					[model writeLongBlock:&ldata
								atAddress:address
							   numToWrite:1
							   withAddMod:addressModifier
							usingAddSpace:addressSpace];
					
					break;
			}
			address+=[addressStepper increment];
			
		}while(address<endAddress);
		if([model doRange]) NSLog(@"Vme Write Range @ (0x%08x-0x%08x 0x%x 0x%x): 0x%08x\n",startAddress,endAddress,addressModifier,addressSpace,ldata);
		else				NSLog(@"Vme Write @ (0x%08x 0x%x 0x%x): 0x%08x\n",startAddress,addressModifier,addressSpace,ldata);
		
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nAddress: 0x%08X", @"OK", nil, nil,
                        localException,address);
    }
}

@end
