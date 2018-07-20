/*
 
 File:		ORA3818Controller.m
 
 Usage:		Test PCI Basic I/O Kit Kernel Extension (KEXT) Functions
 for the Bit3 VME Bus Controller
 Author:		Mark A. Howe
 Copyright:		Copyright 3818.  All rights reserved

 Note:		Bit3 PCI Matching is done with
 Vendor ID 0x108a and Device ID codes of the Bit3 devices, i.e. 0x1, 0x10,or 0x40
 */
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


#pragma mark •••Imported Files
#import "ORA3818Controller.h"
#import "ORDualPortLAMModel.h"

#import "ORTimeLinePlot.h"
#import "ORPlotView.h"
#import "ORTimeAxis.h"
#import "ORRate.h"
#import "ORRateGroup.h"
#import "ORTimeRate.h"
#import "ORA3818Commands.h"
#import "ORCompositePlotView.h"

#pragma mark •••Macros
// swap 16 bit quantities in 32 bit value ( |2| |1| -> |1| |2| )
#define Swap16Bits(x)    ((((x) & 0xffff0000) >> 16) | (((x) & 0x0000ffff) << 16))

// swap 8 bit quantities in 32 bit value ( |4| |3| |2| |1| -> |1| |2| |3| |4| )
#define Swap8Bits(x)	((((Swap16Bits(x) & 0x0000ff00) >> 8) | ((Swap16Bits(x) & 0x000000ff) << 8)) \
| (((Swap16Bits(x) & 0xff000000) >> 8) | ((Swap16Bits(x) & 0x00ff0000) << 8)))


// methods
@implementation ORA3818Controller

#pragma mark •••Initialization
-(id)init
{
    self = [super initWithWindowNibName:@"A3818"];
    
    return self;
}

- (void) awakeFromNib
{
    [addressStepper setMaxValue:(double)0x7fffffff];
	[groupView setGroup:model];
 
	[super awakeFromNib];
}

- (void) setModel:(OrcaObject*)aModel
{
    [super setModel:aModel];
    [groupView setGroup:(ORGroup*)model];
	[[self window] setTitle:[NSString stringWithFormat:@"%@ Access",[model objectName]]];
}

#pragma mark •••Notifications
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [super registerNotificationObservers];
	
    [notifyCenter addObserver : self
                     selector : @selector(rwAddressTextChanged:)
                         name : ORA3818RWAddressChangedNotification
                        object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(writeValueTextChanged:)
                         name : ORA3818WriteValueChangedNotification
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(readWriteAddressModifierChanged:)
                         name : ORA3818RWAddressModifierChangedNotification
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(readWriteIOSpaceChanged:)
                         name : ORA3818RWIOSpaceChangedNotification
                        object: model];
    
    [notifyCenter addObserver : self
                     selector : @selector(readWriteTypeChanged:)
                         name : ORA3818RWTypeChangedNotification
                       object : model];
        
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(lockChanged:)
                         name : ORA3818Lock
                        object: nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(deviceNameChanged:)
                         name : ORA3818DeviceNameChangedNotification
                       object : model];
    
    
    [notifyCenter addObserver : self
                     selector : @selector(slotChanged:)
                         name : ORDualPortLAMSlotChangedNotification
                        object: nil];
	    
    [notifyCenter addObserver : self
                     selector : @selector(doRangeChanged:)
                         name : ORA3818ModelDoRangeChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(rangeChanged:)
                         name : ORA3818ModelRangeChanged
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
    
    [groupView setNeedsDisplay:YES];
    
    [self rwAddressTextChanged:nil];
    [self writeValueTextChanged:nil];
    [self readWriteTypeChanged:nil];
    [self readWriteIOSpaceChanged:nil];
    [self readWriteAddressModifierChanged:nil];
    
    [self deviceNameChanged:nil];
    [self slotChanged:nil];
    
    [self lockChanged:nil];
	[self doRangeChanged:nil];
	[self rangeChanged:nil];
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORA3818Lock to:secure];
    [lockButton setEnabled:secure];
}

- (void) lockChanged:(NSNotification*)aNotification
{
    
    BOOL lockedOrRunning = [gSecurity runInProgressOrIsLocked:ORA3818Lock];
    BOOL locked = [gSecurity isLocked:ORA3818Lock];
    
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
	[self updateRadioCluster:readWriteTypeMatrix setting:(int)[model readWriteType]];
	
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

- (void) slotChanged:(NSNotification*)aNote
{
	[groupView setNeedsDisplay:YES];
}

-(void)clearError_Bits
{
    unsigned char cdata = [model clearErrorBits]; 	// clear Bit3 error bits
    [model checkStatusErrors];						// check for any remaining errors
    
    NSLog(@"Local Error Bits Cleared\n");
    NSLog(@"Adapter Local Status = 0x%02x\n",cdata);
    
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

- (IBAction) integrationAction:(id)sender
{
    [self endEditing];
    // if([sender doubleValue] != [[model errorRateGroup]integrationTime]){
    [model setIntegrationTime:[sender doubleValue]];		
    //  }
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORA3818Lock to:[sender intValue] forWindow:[self window]];
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
        [model setReadWriteType:(int)[sender selectedTag]];
    }
}

- (IBAction)ioSpaceAction:(id)sender
{
    if ([model readWriteIOSpace] != [sender indexOfSelectedItem]) { 
        [model setReadWriteIOSpace:(int)[sender indexOfSelectedItem]];
    }
}

- (IBAction)addressModifierAction:(id)sender
{
    if ([model rwAddressModifier] != [sender indexOfSelectedItem]) {
        [model setRwAddressModifier:(int)[sender indexOfSelectedItem]];
    }
}


-(IBAction)sysReset:(id)sender
{
    @try {
        [self endEditing];
        unsigned char cdata;
        [model vmeSysReset:&cdata];
    }
	@catch(NSException* localException) {
        NSLog(@"*** Unable To Send VME SYSRESET ***\n");
        NSLog(@"*** Check VME Bus Power and Cables ***\n");
        ORRunAlertPanel([localException name], @"%@", @"OK", nil, nil,
                        localException);
    }
    
}

-(IBAction)reset:(id)sender
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

-(void)dpmTest
{
    unsigned int vmeAddress;
    unsigned int numberLongs;
    unsigned short addressModifier;
    unsigned short addressSpace;
    uint32_t data;
    unsigned int i;
    uint32_t dataBlockIn[64];
    unsigned int numberWords;
    unsigned short dataBlockWordOut[64];
    unsigned short dataBlockWordIn[64];
    unsigned int numberBytes;
    unsigned char dataBlockByteOut[64];
    unsigned char dataBlockByteIn[64];
    uint32_t dataBlockOut[64];
    
    NSString* progressString = @"";
    
    @try {
        NSLog(@"Starting dpm Tests\n");
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		
        [self endEditing];
        progressString = @"Checking Status";
        [model checkStatusErrors];
        
        // write a 32 bit value to dual port memory
        vmeAddress      = kDualPortAddress;
        numberLongs     = 1L;
        addressModifier = kRemoteDualPortAddressModifier;
        addressSpace    = kAccessRemoteDRAM;
        data = 0x12345678;
        progressString = @"Writing Dual Port Memory";
        [model writeLongBlock:&data
					atAddress:vmeAddress
				   numToWrite:numberLongs
				   withAddMod:addressModifier
				usingAddSpace:addressSpace];
        
        
        // read 32 bit value just written
        progressString = @"Reading Dual Port Memory";
        data = 0x00000000;
        [model readLongBlock:&data
				   atAddress:vmeAddress
				   numToRead:numberLongs
				  withAddMod:addressModifier
			   usingAddSpace:addressSpace];
        
        
        progressString = @"32 Bit Block Write Dual Port Memory";
        // write a data block of 32 bit values to dual port memory
        vmeAddress = kDualPortAddress;
        numberLongs = 64L;
        addressModifier = kRemoteDualPortAddressModifier;
        addressSpace = kAccessRemoteDRAM;
        for( i = 0; i < 64; i++ ) {
            dataBlockOut[i] = ( i << 24 ) | ( i << 16 ) | ( 1 << 8 ) | i;
        }
        [model writeLongBlock:dataBlockOut
					atAddress:vmeAddress
				   numToWrite:numberLongs
				   withAddMod:addressModifier
				usingAddSpace:addressSpace];
        
        progressString = @"32 Bit Block Read Dual Port Memory";
        for( i = 0; i < 64; i++ ) {
            dataBlockIn[i] = 0x00000000;
        }
        [model readLongBlock:dataBlockIn
				   atAddress:vmeAddress
				   numToRead:numberLongs
				  withAddMod:addressModifier
			   usingAddSpace:addressSpace];
        
        for( i = 0; i < 64; i++ ) {
            if( dataBlockIn[i] != dataBlockOut[i] ) {
                NSLog(@" *** Data Mismatch, i = %d, Data Out = 0x%08lx, Data In = 0x%08lx ***\n",
                      i,dataBlockOut[i],dataBlockIn[i] );
                break;
            }
        }
        if( i >= 64 ) {
            NSLog(@"DPRAM 32 Bit Block Access OK\n");
        }
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		
        
        
        // write a data block of 16 bit values to dual port memory
        vmeAddress = kDualPortAddress;
        numberWords = 64L;
        addressModifier = kRemoteDualPortAddressModifier;
        addressSpace = kAccessRemoteDRAM;
        for( i = 0; i < 64; i++ ) {
            dataBlockWordOut[i] = ( 1 << 8 ) | i;
        }
        
        progressString = @"Word Block Write Dual Port Memory";
        [model writeWordBlock:dataBlockWordOut
					atAddress:vmeAddress
				   numToWrite:numberWords
				   withAddMod:addressModifier
				usingAddSpace:addressSpace];
        
        for( i = 0; i < 64; i++ ) {
            dataBlockWordIn[i] = 0x0000;
        }
        progressString = @"Word Block Read Dual Port Memory";
        [model readWordBlock:dataBlockWordIn
				   atAddress:vmeAddress
				   numToRead:numberWords
				  withAddMod:addressModifier
			   usingAddSpace:addressSpace];
        for( i = 0; i < 64; i++ ) {
            if( dataBlockWordIn[i] != dataBlockWordOut[i] ) {
                NSLog(@"*** Data Mismatch, i = %d, Data Out = 0x%04x, Data In = 0x%04x **\n*",
                      i,dataBlockWordOut[i],dataBlockWordIn[i] );
                break;
            }
        }
        if( i >= 64 ) {
            NSLog(@"DPRAM 16 Bit Block Access OK\n");
        }
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		
        
        
        // write a data block of bytes to dual port memory
        vmeAddress = kDualPortAddress;
        numberBytes = 64L;
        addressModifier = kRemoteDualPortAddressModifier;
        addressSpace = kAccessRemoteDRAM;
        for( i = 0; i < 64; i++ ) {
            dataBlockByteOut[i] = i;
        }
        progressString = @"Byte Block Write Dual Port Memory";
        [model writeByteBlock:dataBlockByteOut
					atAddress:vmeAddress
				   numToWrite:numberBytes
				   withAddMod:addressModifier
				usingAddSpace:addressSpace];
        for( i = 0; i < 64; i++ ) {
            dataBlockByteIn[i] = 0x00;
        }
        progressString = @"Byte Block Read Dual Port Memory";
        [model readByteBlock:dataBlockByteIn
				   atAddress:vmeAddress
				   numToRead:numberBytes
				  withAddMod:addressModifier
			   usingAddSpace:addressSpace];
        for( i = 0; i < 64; i++ ) {
            if( dataBlockByteIn[i] != dataBlockByteOut[i] ) {
                NSLog(@"*** Data Mismatch, i = %d, Data Out = 0x%02x, Data In = 0x%02x ***\n",
                      i,dataBlockByteOut[i],dataBlockByteIn[i] );
                break;
            }
        }
        if( i >= 64 ) {
            NSLog(@"DPRAM Byte Block Access OK\n");
        }
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		
	}
	@catch(NSException* localException) {
		NSLog(@"DPM Test Failed %@",progressString);
		[localException raise]; //rethrow it
	}
}



// start tests
-(IBAction)doTests:(id)sender
{
    //unsigned char cdata;
    
    NSLog(@"Starting %@ Driver Tests.\n",[model objectName]);
	[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                             beforeDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
	
    
    @try {
        
        [self endEditing];
        
        //NSLog(@"No errors.\n");
        [model printConfigurationData];
        /*
        NSLog(@"Checking for Hardware errors.\n");
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		
        [model checkStatusErrors];
        
        NSLog(@"Checking Status.\n");
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		
        [model printStatus];
        
        NSLog(@"Clearing Error bits.\n");
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		
        [self clearError_Bits];
        NSLog(@"Doing Sys Reset (~2 seconds).\n");
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		
        [model vmeSysReset:&cdata];
        NSLog(@"Doing Controller Reset.\n");
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
								 beforeDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		
        [model resetContrl];
        
        [self dpmTest];
        NSLog(@"All %@ Tests Complete.\n",[model objectName]);
        */
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

-(IBAction)write:(id)sender
{
    unsigned short sdata;
    unsigned char  cdata;
    
    [self endEditing];
    uint32_t 	startAddress 	= [model rwAddress];
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



