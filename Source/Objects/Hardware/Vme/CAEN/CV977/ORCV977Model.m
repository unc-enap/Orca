//--------------------------------------------------------------------------------
//ORCV977Model.m
//Mark A. Howe 20013-09-26
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

#import "ORCV977Model.h"

#define k792DefaultBaseAddress 		0xa00000
#define k792DefaultAddressModifier 	0x9

// Define all the registers available to this unit.
static V977NamesStruct reg[kNumRegisters] = {
	{@"Input Set",              0x0000,		kReadWrite},  
	{@"Input Mask",             0x0002,		kReadWrite},
	{@"Input Read",             0x0004,		kReadOnly},
	{@"Single Hit Read",        0x0006,		kReadOnly},
	{@"Multihit Read",          0x0008,		kReadOnly},
	{@"Output Set",             0x000A,		kReadWrite},
	{@"Output Mask",            0x000C,		kReadWrite},
	{@"Interrupt Mask",         0x000E,		kReadWrite},
	{@"Clear Output",           0x0010,		kWriteOnly},
	{@"Singlehit Read-Clear",   0x0016,		kReadOnly},
	{@"Multihit Read-Clear",    0x0018,		kReadOnly},
	{@"Test Control",           0x001A,		kReadWrite},
	{@"Interrupt Level",        0x0020,		kReadWrite},
	{@"Interrupt Vector",       0x0022,		kReadWrite},
	{@"Serial Number",          0x0024,		kReadOnly},
	{@"Firmware Revision",      0x0026,		kReadOnly},
	{@"Control Register",       0x0028,		kReadWrite},
	{@"Software Reset",         0x002E,		kWriteOnly},
};

NSString* ORCV977ModelOrMaskBitChanged          = @"ORCV977ModelOrMaskBitChanged";
NSString* ORCV977ModelGateMaskBitChanged        = @"ORCV977ModelGateMaskBitChanged";
NSString* ORCV977ModelPatternBitChanged         = @"ORCV977ModelPatternBitChanged";
NSString* ORCV977ModelInputSetChanged           = @"ORCV977ModelInputSetChanged";
NSString* ORCV977ModelInputMaskChanged          = @"ORCV977ModelInputMaskChanged";
NSString* ORCV977ModelOutputSetChanged          = @"ORCV977ModelOutputSetChanged";
NSString* ORCV977ModelOutputMaskChanged         = @"ORCV977ModelOutputMaskChanged";
NSString* ORCV977ModelInterruptMaskChanged      = @"ORCV977ModelInterruptMaskChanged";
NSString* ORCV977BasicOpsLock                   = @"ORCV977BasicOpsLock";
NSString* ORCV977LowLevelOpsLock                = @"ORCV977LowLevelOpsLock";
NSString* ORCV977ModelSelectedRegIndexChanged   = @"ORCV977ModelSelectedRegIndexChanged";
NSString* ORCV977ModelWriteValueChanged         = @"ORCV977ModelWriteValueChanged";

@implementation ORCV977Model

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k792DefaultBaseAddress];
    [self setAddressModifier:k792DefaultAddressModifier];
	
    [[self undoManager] enableUndoRegistration];
	[self registerNotificationObservers];
   
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"C977"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCV977Controller"];
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x2F);
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [ NSNotificationCenter defaultCenter ];
    
    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStart:)
                         name : ORRunAboutToStartNotification
                       object : nil];
}

- (void) runAboutToStart:(NSNotification*)aNote
{
	[self initBoard];
}

#pragma mark ***Accessors

- (BOOL) orMaskBit
{
    return orMaskBit;
}

- (void) setOrMaskBit:(BOOL)aOrMaskBit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOrMaskBit:orMaskBit];
    
    orMaskBit = aOrMaskBit;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV977ModelOrMaskBitChanged object:self];
}

- (BOOL) gateMaskBit
{
    return gateMaskBit;
}

- (void) setGateMaskBit:(BOOL)aGateMaskBit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGateMaskBit:gateMaskBit];
    
    gateMaskBit = aGateMaskBit;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV977ModelGateMaskBitChanged object:self];
}

- (BOOL) patternBit
{
    return patternBit;
}

- (void) setPatternBit:(BOOL)aPatternBit
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPatternBit:patternBit];
    
    patternBit = aPatternBit;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV977ModelPatternBitChanged object:self];
}
- (unsigned short) selectedRegIndex
{
    return selectedRegIndex;
}
- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSelectedRegIndex:[self selectedRegIndex]];
    selectedRegIndex = anIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV977ModelSelectedRegIndexChanged object:self];
}

- (uint32_t) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(uint32_t) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    writeValue = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV977ModelWriteValueChanged object:self];
}

//-----Input Registers ------
- (uint32_t)inputSet       { return inputSet; }
- (BOOL)inputSetBit:(int)bit    { return inputSet&(1<<bit); }
- (uint32_t)inputMask      { return inputMask; }
- (BOOL)inputMaskBit:(int)bit   { return inputMask&(1<<bit); }

- (void)setInputSet:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInputSet:inputSet];
    inputSet = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV977ModelInputSetChanged object:self];
}

- (void) setInputSetBit:(int)bit withValue:(BOOL)aValue
{
	uint32_t aMask = inputSet;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setInputSet:aMask];
}

- (void)setInputMask:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInputMask:inputMask];
    inputMask = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV977ModelInputMaskChanged object:self];
}

- (void) setInputMaskBit:(int)bit withValue:(BOOL)aValue
{
	uint32_t aMask = inputMask;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setInputMask:aMask];
}

//-----Output Registers ------
- (uint32_t)outputSet      { return outputSet; }
- (BOOL)outputSetBit:(int)bit   { return outputSet&(1<<bit); }
- (uint32_t)outputMask      { return outputMask; }
- (BOOL)outputMaskBit:(int)bit   { return outputMask&(1<<bit); }

- (void)setOutputSet:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOutputSet:outputSet];
    outputSet = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV977ModelOutputSetChanged object:self];
}

- (void) setOutputSetBit:(int)bit withValue:(BOOL)aValue
{
	uint32_t aMask = outputSet;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setOutputSet:aMask];
}

- (void)setOutputMask:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOutputMask:outputMask];
    outputMask = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV977ModelOutputMaskChanged object:self];
}

- (void) setOutputMaskBit:(int)bit withValue:(BOOL)aValue
{
	uint32_t aMask = outputMask;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setOutputMask:aMask];
}

//-----Interrupt Mask ------
- (uint32_t)interruptMask      { return interruptMask; }
- (BOOL)interruptMaskBit:(int)bit   { return interruptMask&(1<<bit); }

- (void)setInterruptMask:(uint32_t)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInterruptMask:interruptMask];
    interruptMask = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCV977ModelInterruptMaskChanged object:self];
}


- (void) setInterruptMaskBit:(int)bit withValue:(BOOL)aValue
{
	uint32_t aMask = interruptMask;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setInterruptMask:aMask];
}

#pragma mark ***Register - General routines
- (short) getNumberRegisters
{
    return kNumRegisters;
}
- (short)		getThresholdIndex			    { return 9999; } //use a high number so our register table will work. Problem is that we inherit from a base class that assumes all cards have thresholds.

#pragma mark ***Register - Register specific routines
- (NSString*) getRegisterName:(short) anIndex       { return reg[anIndex].regName; }
- (uint32_t) getAddressOffset:(short) anIndex  { return(reg[anIndex].addressOffset); }
- (short) getAccessType:(short) anIndex             { return reg[anIndex].accessType; }

#pragma mark ***Hardware Commands
- (void) clearOutputRegister
{
    unsigned short 	theValue    = 0;
    [[self adapter] writeWordBlock:&theValue
                         atAddress:[self baseAddress] + [self getAddressOffset:kClearOutput]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];

}

- (void) clearSingleHitRegister
{
    unsigned short 	theValue    = 0;
    [[self adapter] writeWordBlock:&theValue
                         atAddress:[self baseAddress] + [self getAddressOffset:kSinglehitReadClear]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}
- (void) clearMultiHitRegister
{
    unsigned short 	theValue    = 0;
    [[self adapter] writeWordBlock:&theValue
                         atAddress:[self baseAddress] + [self getAddressOffset:kMultihitReadClear]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}
- (void) readVersion
{
    unsigned short serialNumber = 0;
    [[self adapter] readWordBlock:&serialNumber
                        atAddress:[self baseAddress] + [self getAddressOffset:kSerialNumber]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];

    unsigned short firmwareVersion = 0;
    [[self adapter] readWordBlock:&firmwareVersion
                        atAddress:[self baseAddress] + [self getAddressOffset:kFirmwareRevision]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    NSLog(@"%@ SerialNumber: 0x%x Firmware: %d.%d\n", [self identifier], serialNumber,firmwareVersion>>8,firmwareVersion&0xFF);
}

- (void) writeControlReg
{
    unsigned short 	theValue =  (patternBit  << 0 ) |
                                (gateMaskBit << 1 ) |
                                (orMaskBit   << 2 );
    [[self adapter] writeWordBlock:&theValue
                         atAddress:[self baseAddress] + [self getAddressOffset:kControlRegister]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (void) writeInputSetReg
{
    unsigned short 	theValue =  inputSet;
    [[self adapter] writeWordBlock:&theValue
                         atAddress:[self baseAddress] + [self getAddressOffset:kInputSet]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeInputMaskReg
{
    unsigned short 	theValue =  inputMask;
    [[self adapter] writeWordBlock:&theValue
                         atAddress:[self baseAddress] + [self getAddressOffset:kInputMask]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeOutputSetReg
{
    unsigned short 	theValue =  outputSet;
    [[self adapter] writeWordBlock:&theValue
                         atAddress:[self baseAddress] + [self getAddressOffset:kOutputSet]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}
- (void) writeOutputMaskReg
{
    unsigned short 	theValue =  outputMask;
    [[self adapter] writeWordBlock:&theValue
                         atAddress:[self baseAddress] + [self getAddressOffset:kOutputMask]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeInterruptMaskReg
{
    unsigned short 	theValue =  interruptMask;
    [[self adapter] writeWordBlock:&theValue
                         atAddress:[self baseAddress] + [self getAddressOffset:kInterruptMask]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) reset
{
    unsigned short 	theValue =  0;
    [[self adapter] writeWordBlock:&theValue
                         atAddress:[self baseAddress] + [self getAddressOffset:kSoftwareReset]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}

- (void) initBoard
{
    [self writeControlReg];
    [self writeInputSetReg];
    [self writeInputMaskReg];
    [self writeOutputSetReg];
    [self writeOutputMaskReg];
    [self writeInterruptMaskReg];
}

- (void) read
{
    unsigned short 	theValue    = 0;
    short theRegIndex           = [self selectedRegIndex];
    
    @try {
        [self read:theRegIndex returnValue:&theValue];
        NSLog(@"%@ reg [%@]:0x%04lx\n", [self identifier],[self getRegisterName:theRegIndex], theValue);
	}
	@catch(NSException* localException) {
		NSLog(@"Can't Read [%@] on the %@.\n",
			  [self getRegisterName:theRegIndex], [self identifier]);
		[localException raise];
	}
}

- (void) write
{    
    int32_t theValue     = [self writeValue];
    short theRegIndex = [self selectedRegIndex];
    
    @try {
        
        NSLog(@"Register is:%d\n", theRegIndex);
        NSLog(@"Value is   :0x%04x\n", theValue);
        
        [self write:theRegIndex sendValue:(short) theValue];
	}
	@catch(NSException* localException) {
		NSLog(@"Can't write 0x%04lx to [%@] on the %@.\n",
			  theValue, [self getRegisterName:theRegIndex],[self identifier]);
		[localException raise];
	}
}


- (void) read:(unsigned short) pReg returnValue:(void*) pValue
{
    if (pReg >= [self getNumberRegisters]) {
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    if([self getAccessType:pReg] != kReadOnly
       && [self getAccessType:pReg] != kReadWrite) {
        [NSException raise:@"Illegal Operation" format:@"Illegal operation (read not allowed) on reg [%@] %@",[self getRegisterName:pReg],[self identifier]];
    }
    
    unsigned short aValue;
    [[self adapter] readWordBlock:&aValue
                        atAddress:[self baseAddress] + [self getAddressOffset:pReg]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    *((unsigned short*)pValue) = aValue;

}

- (void) write:(unsigned short) pReg sendValue:(uint32_t) pValue
{
    if (pReg >= [self getNumberRegisters]){
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    if([self getAccessType:pReg] != kWriteOnly
       && [self getAccessType:pReg] != kReadWrite) {
        [NSException raise:@"Illegal Operation" format:@"Illegal operation (write not allowed) on reg [%@] %@",[self getRegisterName:pReg],[self identifier]];
    }
    
    @try {
        unsigned short aValue = (unsigned short)pValue;
        [[self adapter] writeWordBlock:&aValue
                             atAddress:[self baseAddress] + [self getAddressOffset:pReg]
                            numToWrite:1
                            withAddMod:[self addressModifier]
                         usingAddSpace:0x01];
	}
	@catch(NSException* localException) {
	}
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 977 (Slot %d) ",[self slot]];
}


#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];

    [[self undoManager] disableUndoRegistration];
    [self setOrMaskBit:         [aDecoder decodeBoolForKey:@"orMaskBit"]];
    [self setGateMaskBit:       [aDecoder decodeBoolForKey:@"gateMaskBit"]];
    [self setPatternBit:        [aDecoder decodeBoolForKey:@"patternBit"]];
    [self setSelectedRegIndex:  [aDecoder decodeIntegerForKey:  @"selectedRegIndex"]];
    [self setWriteValue:        [aDecoder decodeIntForKey:@"writeValue"]];
   	[self setInputSet:          [aDecoder decodeIntForKey:@"inputSet"]];
   	[self setInputMask:         [aDecoder decodeIntForKey:@"inputMask"]];
   	[self setOutputSet:         [aDecoder decodeIntForKey:@"outputSet"]];
   	[self setOutputMask:        [aDecoder decodeIntForKey:@"outputMask"]];
   	[self setInterruptMask:     [aDecoder decodeIntForKey:@"interruptMask"]];
    [self registerNotificationObservers];

    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
    [anEncoder encodeBool:orMaskBit         forKey:@"orMaskBit"];
    [anEncoder encodeBool:gateMaskBit       forKey:@"gateMaskBit"];
    [anEncoder encodeBool:patternBit        forKey:@"patternBit"];
    [anEncoder encodeInteger:selectedRegIndex   forKey:@"selectedRegIndex"];
    [anEncoder encodeInt:writeValue       forKey:@"writeValue"];
	[anEncoder encodeInt:inputSet         forKey:@"inputSet"];
	[anEncoder encodeInt:inputMask        forKey:@"inputMask"];
	[anEncoder encodeInt:outputSet        forKey:@"outputSet"];
	[anEncoder encodeInt:outputMask       forKey:@"outputMask"];
	[anEncoder encodeInt:interruptMask    forKey:@"interruptMask"];
}
@end

