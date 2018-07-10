/*
File:			ORFifoModel.m

Description:		Object Methods for a Fifo Module For a
Greenspring IP Board  - VME Bus Resident

SUPERCLASS = CVmeIO

Author:		FM

Copyright:		Copyright 2001-2002 F. McGirt.  All rights reserved.

Change History:	1/22/02, 2/2/02, 2/12/02
2/13/02 MAH CENPA. converted to Objective-C

-----------------------------------------------------------
This program was prepared for the Regents of the University of
Washington at the Center for Experimental Nuclear Physics and
Astrophysics (CENPA) sponsored in part by the United States
Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
The University has certain rights in the program pursuant to
the contract and the program should not be copied or distributed
outside your organization.  The DOE and the University of
Washington reserve all rights in the program. Neither the authors,
University of Washington, or U.S. Government make any warranty,
express or implied, or assume any liability or responsibility
for the use of this software.
-------------------------------------------------------------


*/


//	Note:	Fifo Buffer States and CSR Status:
//
//			1.	No data in Fifo (and after Fifo reset), status = 0x10, Fifo Empty Bit Set
//			2.	For Fifo word count >= 1 and Fifo word count <= 2048, status = 0x00
//			3.	For Fifo word count > 2048 and Fifo word count < 4095, status = 0x20,
//					Fifo Half Full Bit Set
//			4.	For Fifo word count = 4095, status = 0x60, Fifo Half Full and Full-1 Bit Set
//			5.  For Fifo word count = 4096, status = 0xe0, Fifo Full, Full-1, and Half Full
//					Bits Set



#pragma mark ¥¥¥Imported Files
#import "ORFifoModel.h"
#import "ORVmeBusProtocol.h"
#import "ORVmeCrateController.h"
#import "ORIPCarrierModel.h"


#pragma mark ¥¥¥Definitions
#define DEFAULT_FIFO_ADDRESS_MODIFIER	0x29
#define DEFAULT_FIFO_INTERRUPT_LEVEL	0		// no interrupt
#define DEFAULT_FIFO_BASE_ADDRESS		0x00006000
#define FIFO_TEST_DATA_SIZE				4096	// 16-bit fifo words

#pragma mark ¥¥¥CSR Register Definitions
#define FIFO_CSR_INT_ENABLE			0x01	// interrupt enable for receive fifo full
#define FIFO_CSR_INTERNAL_MODE		0x00	// internal test mode, data from VME bus
#define FIFO_CSR_EXTERNAL_MODE		0x02	// normal mode, data from external source
#define FIFO_CST_TEST_INT			0x08	// generate an interrupt for test
#define FIFO_CSR_FIFO_EMPTY			0x10	// fifo empty
#define FIFO_CSR_FIFO_LESS_HALF_FULL 0x00	// fifo <= half full
#define FIFO_CSR_FIFO_HALF_FULL		0x20	// fifo > half full
#define FIFO_CSR_FIFO_FULL_MINUS_1	0x40	// fifo full - 1
#define FIFO_CSR_FIFO_FULL			0x80	// fifo full, generate interrupt

#pragma mark ¥¥¥Other Register Definitions
#define FIFO_INTERRUPT_VECTOR_REGISTER		0
#define FIFO_CSR_REGISTER					1
#define FIFO_DATA_REGISTER					2
#define FIFO_RESET_REGISTER					3

#define FIFO_DELAY 0.02

#pragma mark ¥¥¥Static Variables
static short register_offset[] = { 0x01,0x03,0x04,0x09 };
//static double t0;


@implementation ORFifoModel

#pragma mark ¥¥¥Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    
    [self setAddressModifier:DEFAULT_FIFO_ADDRESS_MODIFIER];
    [self setBaseAddress:DEFAULT_FIFO_BASE_ADDRESS];
    [self setInterruptLevel:DEFAULT_FIFO_INTERRUPT_LEVEL];
    
    [[self undoManager] enableUndoRegistration];
    
    
    return self;
    
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"IPFifo"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORFifoController"];
}

- (NSString*) helpURL
{
	return @"VME/IPFifo.html";
}


#pragma mark ¥¥¥Accessors

// SetInterruptLevel - Set interrupt level instance variable
-(void) setInterruptLevel:(short) anInterruptLevel
{
    interruptLevel = anInterruptLevel;
}

// GetInterruptLevel - Get interrupt level instance variable
-(short) interruptLevel
{
    return interruptLevel;
}


#pragma mark ¥¥¥Hardware Access
// read Parallel Fifo register
-(void) readFifo:(short) xregister
           atPtr:(unsigned short *)value
{
    // check for crate power
    [[self adapter] checkStatusErrors];
    
    
    // setup address for read operation
    unsigned int address = [self baseAddress] + [self slotConv]*0x100 + (unsigned int)register_offset[xregister];
    
    
    // read Fifo
    if( xregister == FIFO_DATA_REGISTER ) {
        [[self adapter] readWordBlock:value
                            atAddress:address
                            numToRead:1L
                           withAddMod:[self addressModifier]
                        usingAddSpace:kAccessRemoteIO];
    }
    else {
        unsigned char bval;
        [[self adapter] readByteBlock:&bval
                            atAddress:address
                            numToRead:1L
                           withAddMod:[self addressModifier]
                        usingAddSpace:kAccessRemoteIO];
        *value = (unsigned short)bval;
    }
}



// write Parallel Fifo register
-(void) writeFifo:(short) xregister
        withValue:(unsigned short) value
{
    
    // check for crate power
    [[self adapter] checkStatusErrors];
    
    // setup address for write operation
    unsigned int address = [self baseAddress] + [self slotConv]*0x100 + (unsigned int)register_offset[xregister];
    
    // write Fifo
    if( xregister == FIFO_DATA_REGISTER ) {
        [[self adapter] writeWordBlock:&value
                             atAddress:address
                            numToWrite:1L
                            withAddMod:[self addressModifier]
                         usingAddSpace:kAccessRemoteIO];
    }
    else {
        unsigned char bval;
        bval = (unsigned char)value;
        [[self adapter] writeByteBlock:&bval
                             atAddress:address
                            numToWrite:1L
                            withAddMod:[self addressModifier]
                         usingAddSpace:kAccessRemoteIO];
    }
}



// reset Parallel Fifo
-(void) resetFifo
{
    [self writeFifo:(short int)FIFO_RESET_REGISTER
          withValue:(unsigned short)1];
}


#pragma mark ¥¥¥Tests
// unload length data words from Parallel Fifo
-(void) unloadFifo:(unsigned short *)value
        withLength:(unsigned int) length
{
    short i;
    
    // check for crate power
    [[self adapter] checkStatusErrors];
    
    unsigned int address = [self baseAddress] + [self slotConv]*0x100 + (unsigned int)register_offset[FIFO_DATA_REGISTER];
    
    // read Fifo
    // NOTE: ReadVMEWordBlock does not work to Fifo Data register - perhaps a
    //			timing problem with Fifo or Greenspring card???
    for(i = 0; i < (short)length; i++ ) {
        
        [[self adapter] readWordBlock:&value[i]
                            atAddress:address
                            numToRead:1L
                           withAddMod:[self addressModifier]
                        usingAddSpace:kAccessRemoteIO];
    }
    
}



// load length data words to Parallel Fifo
-(void) loadFifo:(unsigned short *)value
      withLength:(unsigned int) length;
{
    // setup address for write Fifo operation
    short i;
    
    // check for crate power
    [[self adapter] checkStatusErrors];
    
    
    // setup address for write Fifo operation
    unsigned int address = [self baseAddress] + [self slotConv]*0x100 + (unsigned int)register_offset[FIFO_DATA_REGISTER];
    
    // write Fifo
    // NOTE: WriteVMEWordBlock does not work to Fifo Data register - perhaps a
    //			timing problem ???
    for( i  = 0; i < (short)length; i++ ) {
        [[self adapter] writeWordBlock:&value[i]
                             atAddress:address
                            numToWrite:1L
                            withAddMod:[self addressModifier]
                         usingAddSpace:kAccessRemoteIO];
        
    }
}


- (void) setupTestMode
{
    
    [self resetFifo];
    
    unsigned short sdata;
    [self readFifo:FIFO_CSR_REGISTER atPtr:&sdata];
    
    // set Fifo internal test mode
    [self writeFifo:FIFO_CSR_REGISTER
          withValue:FIFO_CSR_INTERNAL_MODE];
    
    // check Fifo status for empty state
    unsigned short fifo_status;
    [self readFifo:FIFO_CSR_REGISTER
             atPtr:&fifo_status];
    
    if( (unsigned char)fifo_status != FIFO_CSR_FIFO_EMPTY ) {
        [NSException raise: OExceptionFifoTestError
                    format: @"Fifo Read/Write Levels Not as expected"];
    }
}

//assumes that the fifo has been filled with values from 0 thru 4095 and this method is called increcmentally
//with j = 0 thru 4095.
-(void) readLocationTest:(unsigned short) j
{
    unsigned short fifo_data = 0;
    
    [self readFifo:FIFO_DATA_REGISTER atPtr:&fifo_data];
    
    if( j != fifo_data) {
        [NSException raise: OExceptionFifoTestError format: @"Read (%d) / Write (%d) Mismatch",fifo_data,j];
        
    }
    
    // check Fifo status. Seems to be unreliable so try up to three times in case of error
    unsigned short fifo_status;
    [self readFifo:FIFO_CSR_REGISTER atPtr:&fifo_status];
    
    unsigned short level = 4096 - j;
    if(![self checkLevel:level status:fifo_status]){
        [self readFifo:FIFO_CSR_REGISTER atPtr:&fifo_status];
        if(![self checkLevel:level status:fifo_status]){
            [self readFifo:FIFO_CSR_REGISTER atPtr:&fifo_status];
            if(![self checkLevel:level status:fifo_status]){
                [NSException raise: OExceptionFifoTestError format: @"Fifo Read/Write Levels Not as expected"];
            }
        }
    }
    
}


-(void) writeLocationTest:(unsigned short) j
{
    
    [self writeFifo:FIFO_DATA_REGISTER withValue:j];
    
    unsigned short level =  j;
    unsigned short fifo_status;
    [self readFifo:FIFO_CSR_REGISTER atPtr:&fifo_status];
    if(![self checkLevel:level status:fifo_status]){
        [self readFifo:FIFO_CSR_REGISTER atPtr:&fifo_status];
        if(![self checkLevel:level status:fifo_status]){
            [self readFifo:FIFO_CSR_REGISTER atPtr:&fifo_status];
            if(![self checkLevel:level status:fifo_status]){
                [NSException raise: OExceptionFifoTestError format: @"Fifo Read/Write Levels Not as expected"];
            }
        }
    }
}



//assumes that the fifo is being filled/unfilled with 4096 values
- (BOOL) checkLevel:(int)level status:(unsigned short)fifo_status
{
    unsigned char status  = fifo_status & (FIFO_CSR_FIFO_EMPTY | FIFO_CSR_FIFO_HALF_FULL | FIFO_CSR_FIFO_FULL_MINUS_1 | FIFO_CSR_FIFO_FULL);
    if( (level==0) && (status == FIFO_CSR_FIFO_EMPTY)){
        return YES;
    }
    else if((level>=1) && (level<=2048) && (status == FIFO_CSR_FIFO_LESS_HALF_FULL)) {
        return YES;
    }
    else if((level>2048) && (level<=4094) && (status == FIFO_CSR_FIFO_HALF_FULL)) {
        return YES;
    }
    else if((level==4095) && (status == (FIFO_CSR_FIFO_FULL_MINUS_1 |
                FIFO_CSR_FIFO_HALF_FULL))) {
        return YES;
    }
    else if((level==4096) && (status == (FIFO_CSR_FIFO_HALF_FULL |
                FIFO_CSR_FIFO_FULL_MINUS_1 |
                FIFO_CSR_FIFO_FULL))) {
        return YES;
    }
    
    return NO;
}


// Fifo Block Load/Unload Test
-(void) blockLoadUnloadTest;
{
    int testCount = 1;
    short j;
    unsigned short fifo_status;
    unsigned short testBufferIn[FIFO_TEST_DATA_SIZE];
    unsigned short testBufferOut[FIFO_TEST_DATA_SIZE];
    unsigned short sdata;
    
    NSLog(@"Starting FIFO Block Load/Unload Test\n");
    
    do {
        
        // generate test data for this pass
        for( j = 0; j < FIFO_TEST_DATA_SIZE; j++ ) {
            testBufferIn[j] = (unsigned short)(testCount + j);
        }
        
        [self readFifo:FIFO_CSR_REGISTER atPtr:&sdata];
        
        // reset FIFO
        [self resetFifo];
        
        // set FIFO internal test mode
        [self writeFifo:FIFO_CSR_REGISTER withValue:FIFO_CSR_INTERNAL_MODE];
        
        // check Fifo status for empty state
        [self readFifo:FIFO_CSR_REGISTER atPtr:&fifo_status];
        
        if( (unsigned char)fifo_status != FIFO_CSR_FIFO_EMPTY ) {
            [NSException raise: OExceptionFifoTestError
                        format: @"Fifo Not Empty as Expected."];
        }
        
        // load FIFO with data words
        [self loadFifo:testBufferIn withLength:(unsigned long)FIFO_TEST_DATA_SIZE];
        
        // delay .02 seconds for slow Fifo response
        //t0 = [NSDate timeIntervalSinceReferenceDate];
        //while([NSDate timeIntervalSinceReferenceDate]-t0 < FIFO_DELAY);
        
        // check Fifo status for full state
        [self readFifo:FIFO_CSR_REGISTER atPtr:&fifo_status];
        if( (unsigned char)fifo_status != ( FIFO_CSR_FIFO_HALF_FULL |
                FIFO_CSR_FIFO_FULL_MINUS_1 |  FIFO_CSR_FIFO_FULL ) ) {
            [NSException raise: OExceptionFifoTestError
                        format: @"Fifo Levels NOT as Expected."];
        }
        
        // unload Fifo
        [self unloadFifo:testBufferOut withLength:(unsigned long)FIFO_TEST_DATA_SIZE];
        
        // delay .05 seconds for slow FIFO response
        //t0 = [NSDate timeIntervalSinceReferenceDate];
        //while([NSDate timeIntervalSinceReferenceDate]-t0 < FIFO_DELAY);
        
        // check Fifo status for empty state
        [self readFifo:FIFO_CSR_REGISTER atPtr:&fifo_status];
        
        if( (unsigned char)fifo_status != FIFO_CSR_FIFO_EMPTY )  {
            [NSException raise: OExceptionFifoTestError
                        format: @"Fifo NOT empty as Expected."];
        }
        
        testCount++;
    } while( testCount <= 5 );
    
    NSLog(@"FIFO Block Load/Unload Test Complete\n");
    
}


#pragma mark ¥¥¥Archival
static NSString *ORFifoInterruptLevel 	= @"Fifo interrupt Level";
short interruptLevel;

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setInterruptLevel:[decoder decodeIntForKey:ORFifoInterruptLevel]];
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:[self interruptLevel] forKey:ORFifoInterruptLevel];
}



@end
