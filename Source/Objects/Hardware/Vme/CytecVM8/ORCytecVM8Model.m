//
//  ORCytecVM8Model.m
//  Orca
//
//  Created by Mark Howe on Mon 22 Aug 2016
//  Copyright © 2016, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States
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
#import "ORCytecVM8Model.h"

#define  kCytecVM8DigitalOutputBase     0x10
#define  kCytecVM8BoardId               0xFF4A
#define  kCytecVM8DeviceType            0xFF00

NSString* ORCytecVM8WriteValueChanged	= @"ORCytecVM8WriteValueChanged";
NSString* ORCytectVM8BoardIdChanged		= @"ORCytectVM8BoardIdChanged";
NSString* ORCytectVM8DeviceTypeChanged	= @"ORCytectVM8DeviceTypeChanged";
NSString* ORCytectVM8FormCChanged       = @"ORCytectVM8FormCChanged";

@interface ORCytecVM8Model (private)
- (void) writeValue:(unsigned short)aValue toOffset:(unsigned short)anOffset;
- (unsigned short) readAtOffset:(int)anOffset;
@end

@implementation ORCytecVM8Model

#pragma mark •••Initialization
- (id) init //designated initializer
{
    self = [super init];
    
    [[self undoManager] disableUndoRegistration];
    hwLock = [[NSLock alloc] init];
    [self setAddressModifier:0x29];
    [self setBaseAddress:0xC1C0];
    [[self undoManager] enableUndoRegistration];

    return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [hwLock release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"CytecVM8"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCytecVM8Controller"];
}

- (NSString*) helpURL
{
	return @"VME/CytecVM8.html";
}

#pragma mark •••Accessors
- (uint32_t) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:writeValue];
    writeValue = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCytecVM8WriteValueChanged object:self];
}

- (BOOL) formC
{
    return formC;
}

- (void) setFormC:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFormC:formC];
    formC = aFlag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCytectVM8FormCChanged object:self];
}

- (unsigned short) boardId
{
    return boardId;
}
- (unsigned short) deviceType
{
    return deviceType;
}


#pragma mark •••Hardware Access
- (unsigned short) readBoardId
{
    boardId = [self readAtOffset:0];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCytectVM8BoardIdChanged object:self];
    return boardId;
}

- (unsigned short) readDeviceType
{
    deviceType = [self readAtOffset:2];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCytectVM8DeviceTypeChanged object:self];
    return boardId;
}

- (void) syncWithHardware
{
    [self setWriteValue:[self readRelays]];
    [self setFormC:[self readFormC]];
}

- (void) reset
{
    [self writeValue:0x1 toOffset:4];
    [self writeValue:0x0 toOffset:4];
    [self syncWithHardware];
 }


- (void) writeFormC:(BOOL)aValue
{
    [self writeValue:aValue toOffset:6];
}
- (uint32_t) readFormC
{
    unsigned short temp = [self readAtOffset:6];
     return ~temp & 0x1;
}

- (uint32_t) readRelays
{
    uint32_t value = 0x0;
    
    value =  [self read0_7];
    value |= [self read8_15]<<8;
    value |= [self read16_23]<<16;
    value |= [self read24_31]<<24;
    
    return ~value;
}

- (uint32_t) read0_7
{
    return [self readAtOffset:8] & 0xFF;
}

- (uint32_t) read8_15
{
    return [self readAtOffset:10] & 0xFF;
}

- (uint32_t) read16_23
{
    return [self readAtOffset:12] & 0xFF;

}

- (uint32_t) read24_31
{
    return [self readAtOffset:14] & 0xFF;
}

- (void) dump
{
    [self readBoardId];
    [self readDeviceType];
    if(boardId != kCytecVM8BoardId){
        NSLogColor([NSColor redColor], @"Warning: HW mismatch. %@ is 0x%x HW, expected 0x%x\n",[self fullID],boardId,kCytecVM8BoardId);
        return;
    }
    if(boardId != kCytecVM8BoardId){
        NSLogColor([NSColor redColor], @"Warning: HW mismatch. %@ device type is 0x%x HW, expected 0x%x\n",[self fullID],deviceType,kCytecVM8DeviceType);
        return;
    }
    NSLog(@"HW State of %@\n",[self fullID]);
    NSLog(@"form_C state: 0x%0x: \n" ,[self readFormC]);

    uint32_t states = [self readRelays];
    NSLog(@"relay states: 0x%08x: \n",states);
    NSFont* font = [NSFont fontWithName:@"Monaco" size:11];
    int i,j;
    for(j=0;j<4;j++){
        NSMutableString* s = [NSMutableString stringWithFormat:@"%2d - %2d : ",7+j*8,0+j*8];
        for(i=0;i<8;i++){
            unsigned group = (states>>(j*8)) & 0xFF;
            [s appendFormat:@"%@ ",((group>>(7-i))&0x1) ? @"X":@"O"];
        }
        NSLogFont(font,@"%@  | 0x%02x\n",s,(states>>(j*8)) & 0xFF);
    }
}

- (void) writeRelays:(uint32_t) aValueMask
{
    [hwLock lock];
    @try {
        
        [self writeFormC:formC];
        
        [self writeValue:((aValueMask>>0)  & 0xFF) toOffset:8];
        [self writeValue:((aValueMask>>8)  & 0xFF) toOffset:10];
        [self writeValue:((aValueMask>>16) & 0xFF) toOffset:12];
        [self writeValue:((aValueMask>>24) & 0xFF) toOffset:14];
        
        [self syncWithHardware];
	}
	@catch(NSException* localException) {
	}
	[hwLock unlock];
}

- (void) closeRelay:(int) aRelay
{
    uint32_t currentState = ~[self readRelays] | (0x1 << aRelay);
    [self writeRelays:currentState];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setWriteValue:[decoder decodeIntForKey:@"writeValue"]];
    [self setFormC:[decoder decodeBoolForKey:@"formC"]];
    [[self undoManager] enableUndoRegistration];
    
    hwLock = [[NSLock alloc] init];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:writeValue  forKey:@"writeValue"];
    [encoder encodeBool:formC          forKey:@"formC"];
}
@end

@implementation ORCytecVM8Model (private)
- (void) writeValue:(unsigned short)aValue toOffset:(unsigned short)anOffset
{
    [[self adapter] writeWordBlock:&aValue
                         atAddress: [self baseAddress] + anOffset
                        numToWrite: 1
                        withAddMod: [self addressModifier]
                     usingAddSpace: 0x01];
}

- (unsigned short) readAtOffset:(int)anOffset
{
    unsigned short temp = 0x0;
    [[self adapter] readWordBlock:&temp
                        atAddress:[self baseAddress] + anOffset
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    return temp;
}
@end
