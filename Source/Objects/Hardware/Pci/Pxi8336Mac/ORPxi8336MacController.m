//
//  ORPxi8336MacController.m
//  Orca
//
//  Created by Mark Howe on Thurs Aug 26 2010
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
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

#pragma mark •••Imported Files
#import "ORPxi8336MacController.h"

#pragma mark •••Macros
// swap 16 bit quantities in 32 bit value ( |2| |1| -> |1| |2| )
#define Swap16Bits(x)    ((((x) & 0xffff0000) >> 16) | (((x) & 0x0000ffff) << 16))

// swap 8 bit quantities in 32 bit value ( |4| |3| |2| |1| -> |1| |2| |3| |4| )
#define Swap8Bits(x)	((((Swap16Bits(x) & 0x0000ff00) >> 8) | ((Swap16Bits(x) & 0x000000ff) << 8)) \
| (((Swap16Bits(x) & 0xff000000) >> 8) | ((Swap16Bits(x) & 0x00ff0000) << 8)))


// methods
@implementation ORPxi8336MacController

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"Pxi8336Mac"];
    return self;
}

- (void) setModel:(OrcaObject*)aModel
{
    [super setModel:aModel];
	[[self window] setTitle:[NSString stringWithFormat:@"%@ Access",[model objectName]]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(rwAddressTextChanged:)
                         name : ORPxi8336MacRWAddressChangedNotification
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(writeValueTextChanged:)
                         name : ORPxi8336MacWriteValueChangedNotification
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(readWriteTypeChanged:)
                         name : ORPxi8336MacRWTypeChangedNotification
                       object : model];

    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORPxi8336MacLock
                        object: nil];
        
    [notifyCenter addObserver : self
                     selector : @selector(deviceNameChanged:)
                         name : ORPxi8336MacDeviceNameChangedNotification
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(doRangeChanged:)
                         name : ORPxi8336MacModelDoRangeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(rangeChanged:)
                         name : ORPxi8336MacModelRangeChanged
						object: model];
	
}


#pragma mark •••Interface Management
- (void) rangeChanged:(NSNotification*)aNote
{
	[rangeTextField setIntValue: [model rangeToDo]];
	[rangeStepper setIntValue:	 [model rangeToDo]];
}

- (void) doRangeChanged:(NSNotification*)aNote
{
	[doRangeButton setIntValue: [model doRange]];
}

- (void) updateWindow
{
    [super updateWindow];
        
    [self rwAddressTextChanged:nil];
    [self writeValueTextChanged:nil];
    [self readWriteTypeChanged:nil];
    
    [self deviceNameChanged:nil];
    
    [self lockChanged:nil];
	[self doRangeChanged:nil];
	[self rangeChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORPxi8336MacLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    
    BOOL lockedOrRunning = [gSecurity runInProgressOrIsLocked:ORPxi8336MacLock];
    BOOL locked = [gSecurity isLocked:ORPxi8336MacLock];
    
    [lockButton setState: locked];
    
    [writeButton setEnabled:!lockedOrRunning];
    [readButton setEnabled:!lockedOrRunning];
    [resetButton setEnabled:!lockedOrRunning];
    [sysResetButton setEnabled:!lockedOrRunning];
    
    [addressStepper setEnabled:!lockedOrRunning];
    [addressValueField setEnabled:!lockedOrRunning];
    [writeValueStepper setEnabled:!lockedOrRunning];
    [writeValueField setEnabled:!lockedOrRunning];
    [readWriteTypeMatrix setEnabled:!lockedOrRunning];
	[addressStepper setEnabled:!lockedOrRunning];
    [rangeStepper setEnabled:!lockedOrRunning];
}

- (void) deviceNameChanged:(NSNotification*)aNotification
{
	[[self window]setTitle:[model deviceName]];;
}

- (void) rwAddressTextChanged:(NSNotification*)aNotification
{
	[self updateIntText:addressValueField setting:[model rwAddress]];
	[self updateStepper:addressStepper setting:[model rwAddress]];
}

- (void) writeValueTextChanged:(NSNotification*)aNotification
{
	[self updateIntText:writeValueField setting:[model writeValue]];
	[self updateStepper:writeValueStepper setting:[model writeValue]];
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

#pragma mark •••Actions
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
    [gSecurity tryToSetLock:ORPxi8336MacLock to:[sender intValue] forWindow:[self window]];
}

-(IBAction)rwAddressTextAction:(id)sender
{
	[model setRwAddress:[sender intValue]];		
}

-(IBAction)writeValueTextAction:(id)sender
{
    if([model writeValue] != [sender intValue]){
        [model setWriteValue:[sender intValue]];
    }
}

- (IBAction)readWriteTypeMatrixAction:(id)sender
{ 
    if ([model readWriteType] != [sender selectedTag]){
        [model setReadWriteType:(unsigned int)[sender selectedTag]];
    }
}

-(IBAction)sysReset:(id)sender
{
    @try {
        [self endEditing];
        unsigned char cdata;
        [model pxiSysReset:&cdata];
    }
	@catch(NSException* localException) {
        NSLog(@"*** Unable To Send PXI SYSRESET ***\n");
        NSLog(@"*** Check PXI Bus Power and Cables ***\n");
        ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
                        localException);
    }
}

-(IBAction)reset:(id)sender
{
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

-(IBAction)read:(id)sender
{
    uint32_t ldata;
    unsigned short sdata;
    unsigned char cdata;
    
    [self endEditing];
    uint32_t 	startAddress 	= [model rwAddress];
	uint32_t	endAddress		= [model doRange]?startAddress + [model rangeToDo]*[addressStepper increment] : startAddress;
	
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
							   numToRead:1];
					ldata = cdata;
					break;
					
				case 1: //short
					[model readWordBlock:&sdata
							   atAddress:address
							   numToRead:1];
					
					ldata = sdata;
					
					break;
					
				case 2: //int32_t
					[model readLongBlock:&ldata
							   atAddress:address
							   numToRead:1];
					
					break;
			}
			NSLog(@"PXI Read @ (0x%08x): 0x%08x\n",address,ldata);
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
    uint32_t 	startAddress 	= [model rwAddress];
	uint32_t	endAddress		= [model doRange]?startAddress + [model rangeToDo] : startAddress;
    uint32_t  	ldata			= [model writeValue];
    
	uint32_t   address = startAddress;
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
							   numToWrite:1];
					ldata = cdata;
					break;
					
				case 1:	//short
					sdata = (unsigned short)ldata;
					[model writeWordBlock:&sdata
								atAddress:address
							   numToWrite:1];
					
					ldata = sdata;
					break;
					
				case 2: //int32_t
					[model writeLongBlock:&ldata
								atAddress:address
							   numToWrite:1];
					
					break;
			}
			address+=[addressStepper increment];
			
		}while(address<endAddress);
		if([model doRange]) NSLog(@"PXI Write Range @ (0x%08x-0x%08x): 0x%08x\n",startAddress,endAddress,ldata);
		else				NSLog(@"PXI Write @ (0x%08x): 0x%08x\n",startAddress,ldata);
		
    }
	@catch(NSException* localException) {
        ORRunAlertPanel([localException name], @"%@\nAddress: 0x%08X", @"OK", nil, nil,
                        localException,address);
    }
}

@end



