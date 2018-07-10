/*
 *  ORCaen965Model.m
 *  Orca
 *
 *  Created by Mark Howe on Friday June 19 2009.
 *  Copyright (c) 2009 UNC. All rights reserved.
 *
 */
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
#import "ORCaen965Model.h"
#import "ORCaen965Decoder.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORRateGroup.h"

// Address information for this unit.
#define k965DefaultBaseAddress 		0xd0000
#define k965DefaultAddressModifier 	0x39

// Define all the registers available to this unit.
static RegisterNamesStruct reg[kNumRegisters] = {
	{@"Output Buffer",      true,	true, 	true,	0x0000,		kReadOnly,	kD32},
	{@"FirmWare Revision",	false,  false, 	false,	0x1000,		kReadOnly,	kD16},
	{@"Geo Address",		false,	false, 	false,	0x1002,		kReadWrite,	kD16},
	{@"MCST CBLT Address",	false,	false, 	true,	0x1004,		kReadWrite,	kD16},
	{@"Bit Set 1",			false,	true, 	true,	0x1006,		kReadWrite,	kD16},
	{@"Bit Clear 1",		false,	true, 	true,	0x1008,		kReadWrite,	kD16},
	{@"Interrup Level",     false,	true, 	true,	0x100A,		kReadWrite,	kD16},
	{@"Interrup Vector",	false,	true, 	true,	0x100C,		kReadWrite,	kD16},
	{@"Status Register 1",	false,	true, 	true,	0x100E,		kReadOnly,	kD16},
	{@"Control Register 1",	false,	true, 	true,	0x1010,		kReadWrite,	kD16},
	{@"ADER High",			false,	false, 	true,	0x1012,		kReadWrite,	kD16},
	{@"ADER Low",			false,	false, 	true,	0x1014,		kReadWrite,	kD16},
	{@"Single Shot Reset",	false,	false, 	false,	0x1016,		kWriteOnly,	kD16},
	{@"MCST CBLT Ctrl",     false,	false, 	true,	0x101A,		kReadWrite,	kD16},
	{@"Event Trigger Reg",	false,	true, 	true,	0x1020,		kReadWrite,	kD16},
	{@"Status Register 2",	false,	true, 	true,	0x1022,		kReadOnly,	kD16},
	{@"Event Counter L",	true,	true, 	true,	0x1024,		kReadOnly,	kD16},
	{@"Event Counter H",	true,	true, 	true,	0x1026,		kReadOnly,	kD16},
	{@"Increment Event",	false,	false, 	false,	0x1028,		kWriteOnly,	kD16},
	{@"Increment Offset",	false,	false, 	false,	0x102A,		kWriteOnly,	kD16},
	{@"Load Test Register",	false,	false, 	false,	0x102C,		kReadWrite,	kD16},
	{@"FCLR Window",		false,	true, 	true,	0x102E,		kReadWrite,	kD16},
	{@"Bit Set 2",			false,	true, 	true,	0x1032,		kReadWrite,	kD16},
	{@"Bit Clear 2",		false,	true, 	true,	0x1034,		kWriteOnly,	kD16},
	{@"W Mem Test Address",	false,	true, 	true,	0x1036,		kWriteOnly,	kD16},
	{@"Mem Test Word High",	false,	true, 	true,	0x1038,		kWriteOnly,	kD16},
	{@"Mem Test Word Low",	false,	false, 	false,	0x103A,		kWriteOnly,	kD16},
	{@"Crate Select",       false,	true, 	true,	0x103C,		kReadWrite,	kD16},
	{@"Test Event Write",	false,	false, 	false,	0x103E,		kWriteOnly,	kD16},
	{@"Event Counter Reset",false,	false, 	false,	0x1040,		kWriteOnly,	kD16},
	{@"I current pedestal", false,  true,   true,	0x1060,		kReadWrite, kD16},
	{@"R Test Address",     false,	true, 	true,	0x1064,		kWriteOnly,	kD16},
	{@"SW Comm",			false,	false, 	false,	0x1068,		kWriteOnly,	kD16},
	{@"ADD",				false,	false, 	false,	0x1070,		kReadOnly,	kD16},
	{@"BADD",				false,	false, 	false,	0x1072,		kReadOnly,	kD16},
	{@"Hi Thresholds",		false,	false, 	false,	0x1080,		kReadWrite,	kD16},
	{@"Low Thresholds",		false,	false, 	false,	0x1082,		kReadWrite,	kD16},
};

// Bit Set 2 Register Masks
#define kClearData	0x04


NSString* ORCaen965ModelModelTypeChanged = @"ORCaen965ModelModelTypeChanged";
NSString* ORCaen965ModelOnlineMaskChanged   = @"ORCaen965ModelOnlineMaskChanged";
NSString* ORCaen965LowThresholdChanged		= @"ORCaen965LowThresholdChanged";
NSString* ORCaen965HighThresholdChanged		= @"ORCaen965HighThresholdChanged";
NSString* ORCaen965BasicLock				= @"ORCaen965BasicLock";
NSString* ORCaen965SelectedRegIndexChanged	= @"ORCaen965SelectedRegIndexChanged";
NSString* ORCaen965SelectedChannelChanged	= @"ORCaen965SelectedChannelChanged";
NSString* ORCaen965WriteValueChanged		= @"ORCaen965WriteValueChanged";

@implementation ORCaen965Model

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k965DefaultBaseAddress];
    [self setAddressModifier:k965DefaultAddressModifier];
	[self setOnlineMask:0xffff];
	
    [[self undoManager] enableUndoRegistration];
   
    return self;
}

- (NSString*) helpURL
{
	return @"VME/V965.html";
}

#pragma mark ***Accessors

- (int) modelType
{
    return modelType;
}

- (void) setModelType:(int)aModelType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setModelType:modelType];
    
    modelType = aModelType;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen965ModelModelTypeChanged object:self];
}
- (unsigned short) selectedRegIndex
{
    return selectedRegIndex;
}
- (void) setSelectedRegIndex:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self]setSelectedRegIndex:[self selectedRegIndex]];
    selectedRegIndex = anIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen965SelectedRegIndexChanged object:self];
}

- (unsigned short) selectedChannel
{
    return selectedChannel;
}
- (void) setSelectedChannel:(unsigned short) anIndex
{
    [[[self undoManager] prepareWithInvocationTarget:self]setSelectedChannel:[self selectedChannel]];
    selectedChannel = anIndex;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen965SelectedChannelChanged object:self];
}

- (unsigned long) writeValue
{
    return writeValue;
}

- (void) setWriteValue:(unsigned long) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setWriteValue:[self writeValue]];
    writeValue = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen965WriteValueChanged object:self];
}
- (unsigned long) lowThreshold:(unsigned short) aChnl
{
    return lowThresholds[aChnl];
}

- (void) setLowThreshold:(unsigned short) aChnl withValue:(unsigned long) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLowThreshold:aChnl withValue:[self lowThreshold:aChnl]];
    lowThresholds[aChnl] = aValue;
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:@"channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen965LowThresholdChanged object:self userInfo:userInfo];
}

- (unsigned long) highThreshold:(unsigned short) aChnl
{
    return highThresholds[aChnl];
}

- (void) setHighThreshold:(unsigned short) aChnl withValue:(unsigned long) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHighThreshold:aChnl withValue:[self highThreshold:aChnl]];
    highThresholds[aChnl] = aValue;
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
	[userInfo setObject:[NSNumber numberWithInt:aChnl] forKey:@"channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen965HighThresholdChanged object:self userInfo:userInfo];
}

- (unsigned short)onlineMask {
	
    return onlineMask;
}

- (void)setOnlineMask:(unsigned short)anOnlineMask {
    [[[self undoManager] prepareWithInvocationTarget:self] setOnlineMask:[self onlineMask]];
    onlineMask = anOnlineMask;	    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen965ModelOnlineMaskChanged object:self];
}

- (BOOL)onlineMaskBit:(int)bit
{
	return onlineMask&(1<<bit);
}

- (void) setOnlineMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = onlineMask;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setOnlineMask:aMask];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"Caen965"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCaen965Controller"];
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x1080);
}

#pragma mark ***Register - General routines
- (void) read
{
    
    unsigned short 	theValue   = 0;
    short		start;
    short		end;
    short		i;
    // Get register and channel from dialog box.
    short theChannelIndex	= [self selectedChannel];
    short theRegIndex 		= [self selectedRegIndex];
    
    @try {
        
        if (theRegIndex == kLowThresholds || theRegIndex == kHiThresholds){
            start = theChannelIndex;
            end = theChannelIndex;
            if(theChannelIndex >= [self numberOfChannels]) {
                start = 0;
                end = [self numberOfChannels] - 1;
            }
            
            // Loop through the thresholds and read them.
			if(theRegIndex == kLowThresholds){
				unsigned short m  = (modelType==kModel965A)?2:1;
				for(i = start; i <= end; i++){
					unsigned short aValue = [self readLowThreshold:i];
					NSLog(@"Low Threshold %2d = 0x%04lx\n", i*m, aValue);
				}
			}
			else {
				unsigned short m  = (modelType==kModel965A)?2:1;
				for(i = start; i <= end; i++){
					unsigned short aValue = [self readHighThreshold:i];
					NSLog(@"Hi Threshold %2d = 0x%04lx\n", i*m, aValue);
				}
            }
        }
        
        // If user selected the output buffer then read it.
        else if (theRegIndex == [self getOutputBufferIndex]){
            ORDataPacket* tempDataPacket = [[ORDataPacket alloc]init];
			
			statusAddress		= [self baseAddress]+reg[kStatusRegister1].addressOffset;
			dataBufferAddress   = [self baseAddress]+[self getBufferOffset];;
			location			=  (([self crateNumber]&0xf)<<21) | (([self slot]& 0x0000001f)<<16); //doesn't change so do it here.
			controller			= [self adapter]; //cache for speed
			
            [self takeData:tempDataPacket userInfo:nil];
			[tempDataPacket addFrameBuffer:YES];
			isRunning = NO;

            if([[tempDataPacket dataArray]count]){
				NSData* theData = [[tempDataPacket dataArray] objectAtIndex:0];
				unsigned long* someData = (unsigned long*)[theData bytes];
                ORCaen965DecoderForQdc* aDecoder;
				if(modelType==kModel965){
					aDecoder = [[ORCaen965DecoderForQdc alloc] init];
				}
				else {
					aDecoder = [[ORCaen965ADecoderForQdc alloc] init];
				}
                [aDecoder printData:@"CAEN 965" data:someData];
                [aDecoder release];
            }
			else NSLog(@"No Data in buffer\n");
        }
        
        // Handle all other registers.  Just read them.
        else {
            [self read:theRegIndex returnValue:&theValue];
            NSLog(@"CAEN reg [%@]:0x%04lx\n", [self getRegisterName:theRegIndex], theValue);
        }
        
	}
	@catch(NSException* localException) {
		NSLog(@"Can't Read [%@] on the %@.\n",
			  [self getRegisterName:theRegIndex], [self identifier]);
		[localException raise];
	}
}


- (void) write
{
    // Get the value - Already validated by stepper.
    unsigned long theValue =  [self writeValue];
    // Get register and channel from dialog box.
    short theChannelIndex	= [self selectedChannel];
    short theRegIndex 		= [self selectedRegIndex];
	short		start;
    short		end;
    short		i;
	
    @try {
        
        NSLog(@"Register is:%d\n", theRegIndex);
        NSLog(@"Index is   :%d\n", theChannelIndex);
        NSLog(@"Value is   :0x%04x\n", theValue);
		if (theRegIndex == kLowThresholds || theRegIndex == kHiThresholds){
            start = theChannelIndex;
            end = theChannelIndex;
            if(theChannelIndex >= [self numberOfChannels]) {
                start = 0;
                end = kCV965NumberChannels - 1;
            }
            
            // Loop through the thresholds and read them.
			if(theRegIndex == kLowThresholds){
				for(i = start; i <= end; i++){
					[self setLowThreshold:i withValue:theValue];
					[self writeLowThreshold:i];
					NSLog(@"Low Threshold %2d = 0x%04lx\n", i, [self lowThreshold:i]);
				}
			}
			else {
				for(i = start; i <= end; i++){
					[self setHighThreshold:i withValue:theValue];
					[self writeHighThreshold:i];
					NSLog(@"Hi Threshold %2d = 0x%04lx\n", i, [self highThreshold:i]);
				}
            }
        }
		
		else if ([self getAccessSize:theRegIndex] == kD16){
			unsigned short sValue = (unsigned short)theValue;
			[[self adapter] writeWordBlock:&sValue
								 atAddress:[self baseAddress] + [self getAddressOffset:theRegIndex]
								numToWrite:1
								withAddMod:[self addressModifier]
							 usingAddSpace:0x01];
        }
		else {
			[[self adapter] writeLongBlock:&theValue
								 atAddress:[self baseAddress] + [self getAddressOffset:theRegIndex]
								numToWrite:1
								withAddMod:[self addressModifier]
							 usingAddSpace:0x01];
		}
	}
	@catch(NSException* localException) {
		NSLog(@"Can't write 0x%04lx to [%@] on the %@.\n",
			  theValue, [self getRegisterName:theRegIndex],[self identifier]);
		[localException raise];
	}
}


- (void) read:(unsigned short) pReg returnValue:(void*) pValue
{
    // Make sure that register is valid
    if (pReg >= [self getNumberRegisters]) {
        [NSException raise:@"Illegal Register" format:@"Register index out of bounds on %@",[self identifier]];
    }
    
    // Make sure that one can read from register
    if([self getAccessType:pReg] != kReadOnly
       && [self getAccessType:pReg] != kReadWrite) {
        [NSException raise:@"Illegal Operation" format:@"Illegal operation (read not allowed) on reg [%@] %@",[self getRegisterName:pReg],[self identifier]];
    }
    
    // Perform the read operation.
	if ([self getAccessSize:pReg] == kD16){
		unsigned short aValue;
		[[self adapter] readWordBlock:&aValue
							atAddress:[self baseAddress] + [self getAddressOffset:pReg]
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		*((unsigned short*)pValue) = aValue;
	}
	else {
		unsigned long aValue;
		[[self adapter] readLongBlock:&aValue
							atAddress:[self baseAddress] + [self getAddressOffset:pReg]
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		*((unsigned long*)pValue) = aValue;
	}
}



- (void) writeThresholds
{
	short n = (modelType==kModel965A)?8:16;
    short i;
    for (i = 0; i < n; i++){
        [self writeLowThreshold:i];
        [self writeHighThreshold:i];
    }
}

- (void) readThresholds
{
    short i;
	short n = (modelType==kModel965A)?8:16;
    for (i = 0; i < n; i++){
        [self readLowThreshold:i];
        [self readHighThreshold:i];
    }
}

- (void) writeLowThreshold:(unsigned short) pChan
{    
	int kill = ((onlineMask & (1<<pChan))!=0)?0x0:0x100;

	unsigned short lowThreshold = lowThresholds[pChan] | kill;
	if(modelType==kModel965A)pChan *= 2;
    [[self adapter] writeWordBlock:&lowThreshold
                         atAddress:[self baseAddress] + [self lowThresholdOffset:pChan]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}

- (void) writeHighThreshold:(unsigned short) pChan
{    
	int kill = ((onlineMask & (1<<pChan))!=0)?0x0:0x100;
	unsigned short highThreshold = highThresholds[pChan] | kill;
	if(modelType==kModel965A)pChan *= 2;
    [[self adapter] writeWordBlock:&highThreshold
                         atAddress:[self baseAddress] + [self highThresholdOffset:pChan]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}
- (unsigned short) readLowThreshold:(unsigned short) pChan
{    
	if(modelType==kModel965A)pChan *= 2;
	int lowOffset = [self lowThresholdOffset:pChan];
	unsigned short lowThreshold;
    [[self adapter] readWordBlock:&lowThreshold
						atAddress:[self baseAddress] + lowOffset
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
	return lowThreshold;
}

- (unsigned short) readHighThreshold:(unsigned short) pChan
{    
	
	if(modelType==kModel965A)pChan *= 2;
	unsigned short highThreshold;
    [[self adapter] readWordBlock:&highThreshold
						atAddress:[self baseAddress] + [self highThresholdOffset:pChan]
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	return highThreshold;
}

- (int) lowThresholdOffset:(unsigned short)aChan
{	
	if(modelType==kModel965)return reg[kLowThresholds].addressOffset + (aChan * 4);
	else					return reg[kLowThresholds].addressOffset + (aChan * 4) + 2;
}

- (int) highThresholdOffset:(unsigned short)aChan
{
	return reg[kHiThresholds].addressOffset + (aChan * 4);
}

- (short) getNumberRegisters
{
    return kNumRegisters;
}

- (unsigned long) getBufferOffset
{
    return reg[kOutputBuffer].addressOffset;
}

- (unsigned short) getDataBufferSize
{
    return k965OutputBufferSize;
}

- (short) getStatusRegisterIndex:(short) aRegister
{
    if (aRegister == 1) return kStatusRegister1;
    else		return kStatusRegister2;
}

- (short) getOutputBufferIndex
{
    return(kOutputBuffer);
}

#pragma mark ***Register - Register specific routines
- (NSString*) getRegisterName:(short) anIndex
{
    return reg[anIndex].regName;
}
- (unsigned long) getAddressOffset:(short) anIndex
{
    return(reg[anIndex].addressOffset);
}

- (short) getAccessType:(short) anIndex
{
    return reg[anIndex].accessType;
}

- (short) getAccessSize:(short) anIndex
{
    return reg[anIndex].size;
}

- (BOOL) dataReset:(short) anIndex
{
    return reg[anIndex].dataReset;
}

- (BOOL) swReset:(short) anIndex
{
    return reg[anIndex].softwareReset;
}

- (BOOL) hwReset:(short) anIndex
{
    return reg[anIndex].hwReset;
}

- (void) initBoard
{
	[self writeThresholds];
}

- (void) clearData
{
	unsigned short aValue = kClearData;
	[[self adapter] writeWordBlock:&aValue
						 atAddress:[self baseAddress] + [self getAddressOffset:kBitSet2]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
	aValue = kClearData;
	[[self adapter] writeWordBlock:&aValue
						 atAddress:[self baseAddress] + [self getAddressOffset:kBitClear2]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) resetEventCounter
{
	unsigned short aValue = 0x0;
	[[self adapter] writeWordBlock:&aValue
						 atAddress:[self baseAddress] + [self getAddressOffset:kEventCounterReset]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

#pragma mark ***DataTaker

- (void) setDataIds:(id)assigner
{
    dataId = [assigner assignDataIds:kLongForm];
    dataIdA = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
    [self setDataIdA:[anotherObj dataIdA]];
}

- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (unsigned long) dataIdA { return dataIdA; }
- (void) setDataIdA: (unsigned long) DataId
{
    dataIdA = DataId;
}

- (NSDictionary*) dataRecordDescription
{
	
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"ORCaen965DecoderForQdc",				@"decoder",
							 [NSNumber numberWithLong:dataId],		@"dataId",
							 [NSNumber numberWithBool:YES],			@"variable",
							 [NSNumber numberWithLong:-1],			@"length",
							 nil];

	[dataDictionary setObject:aDictionary forKey:@"Qdc"];
	
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"ORCaen965ADecoderForQdc",			@"decoder",
							 [NSNumber numberWithLong:dataIdA],		@"dataId",
							 [NSNumber numberWithBool:YES],			@"variable",
							 [NSNumber numberWithLong:-1],			@"length",
							 nil];

	[dataDictionary setObject:aDictionary forKey:@"965AQdc"];
	
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	
	NSDictionary* aDictionary;
	if(modelType == kModel965){
		aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					   @"Qdc",								@"name",
					   [NSNumber numberWithLong:dataId],	@"dataId",
					   [NSNumber numberWithLong:16],		@"maxChannels",
					   nil];
		
		[anEventDictionary setObject:aDictionary forKey:@"Caen965"];
	}
	else {
		aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
					   @"965AQdc",							@"name",
					   [NSNumber numberWithLong:dataIdA],   @"dataId",
					   [NSNumber numberWithLong:8],			@"maxChannels",
					   nil];
		
		[anEventDictionary setObject:aDictionary forKey:@"Caen965A"];
	}
}

- (void) reset
{	
}

- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{  
	
	[aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:NSStringFromClass([self class])]; 

	
    //Cache some values
	statusAddress		= [self baseAddress]+reg[kStatusRegister1].addressOffset;
	dataBufferAddress   = [self baseAddress]+[self getBufferOffset];;
	location			=  (([self crateNumber]&0xf)<<21) | (([self slot]& 0x0000001f)<<16); //doesn't change so do it here.
    controller			= [self adapter]; //cache for speed

    // Set thresholds in unit
    [self initBoard];
	
    // Clear unit
	[self clearData];
	[self resetEventCounter];
	
	isRunning = NO;
	
    [self startRates];
  
}

-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	isRunning = YES;
	
    @try {
		unsigned short statusValue = 0;
		[controller readWordBlock:&statusValue
						atAddress:statusAddress
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
		
		if(statusValue & 0x0001){
			
			//OK, at least one data value is ready
			unsigned long dataValue;
			[controller readLongBlock:&dataValue
							atAddress:dataBufferAddress
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
			
			//if this is a header, must be valid data.
			BOOL validData = YES; //assume OK until shown otherwise
			if(ShiftAndExtract(dataValue,24,0x7) == 0x2){
				//get the number of memorized channels
				int numMemorizedChannels = ShiftAndExtract(dataValue,8,0x3f);
				int i;
				if((numMemorizedChannels>0)){
					unsigned long dataRecord[0xffff];
					//we fill in dataRecord[0] below once we know the final size
					dataRecord[1] = location;
					int index = 2;
					for(i=0;i<numMemorizedChannels;i++){
						[controller readLongBlock:&dataValue
										atAddress:dataBufferAddress
										numToRead:1
									   withAddMod:[self addressModifier]
									usingAddSpace:0x01];
						int dataType = ShiftAndExtract(dataValue,24,0x7);
						int channel;
						if(modelType == kModel965){
							channel = ShiftAndExtract(dataValue,17,0xf);
						}
						else {
							channel = ShiftAndExtract(dataValue,18,0x7);
						}
						if(dataType == 0x000){
							dataRecord[index] = dataValue;
							index++;
						}
						else {
							validData = NO;
							break;
						}
						++adcCount[channel]; 
					}
					if(validData){
						//OK we read the data, get the end of block
						[controller readLongBlock:&dataValue
										atAddress:dataBufferAddress
										numToRead:1
									   withAddMod:[self addressModifier]
									usingAddSpace:0x01];
						//make sure it really is an end of block
						int dataType = ShiftAndExtract(dataValue,24,0x7);
						if(dataType == 0x4){
							//dataRecord[index] = dataValue; //we don't ship the end of block for now
							//index++;
							//got a end of block fill in the ORCA header and ship the data
							if(modelType == kModel965) dataRecord[0] = dataId  | index; //see.... filled it in here....
							else					  dataRecord[0] = dataIdA | index; //see.... filled it in here....
							[aDataPacket addLongsToFrameBuffer:dataRecord length:index];
						}
						else {
							validData = NO;
						}
					}
				}
			}
			if(!validData){
				//flush the buffer, read until not valid datum
				int i;
				for(i=0;i<0x07FC;i++) {
					unsigned long dataValue;
					[controller readLongBlock:&dataValue
									atAddress:dataBufferAddress
									numToRead:1
								   withAddMod:[self addressModifier]
								usingAddSpace:0x01];
					if(ShiftAndExtract(dataValue,24,0x7) == 0x6) {
						break;
					}
				}
			}
		}
	}
	@catch(NSException* localException) {
		NSLogError(@"",@"Caen965 Card Error",nil);
		[self incExceptionCount];
		[localException raise];
	}
}

- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
	[adcRateGroup stop];
    controller = nil;
	isRunning = NO;
}

- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id = kCaen965; //should be unique
	if(modelType == kModel965)	configStruct->card_info[index].hw_mask[0] 	 = dataId; //better be unique
	else						configStruct->card_info[index].hw_mask[0] 	 = dataIdA;
	configStruct->card_info[index].slot 	 = [self slot];
	configStruct->card_info[index].crate 	 = [self crateNumber];
	configStruct->card_info[index].add_mod 	 = [self addressModifier];
	configStruct->card_info[index].base_add  = [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0] = reg[kStatusRegister1].addressOffset;
	configStruct->card_info[index].deviceSpecificData[1] = reg[kOutputBuffer].addressOffset;
	configStruct->card_info[index].num_Trigger_Indexes = 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
	if(isRunning)return NO;
    ++adcCount[channel];
    return YES;
}

- (unsigned long) adcCount:(int)aChannel
{
    return adcCount[aChannel];
}

-(void) startRates
{
	[self clearAdcCounts];
    [adcRateGroup start:self];
}

- (void) clearAdcCounts
{
    int i;
    for(i=0;i<kCV965NumberChannels;i++){
		adcCount[i]=0;
    }
}

- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kCV965NumberChannels){
			return adcCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    int i;
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:kCV965NumberChannels];
    for(i=0;i<kCV965NumberChannels;i++)[array addObject:[NSNumber numberWithShort:lowThresholds[i]]];
    [objDictionary setObject:array forKey:@"lowThresholds"];
	
	array = [NSMutableArray arrayWithCapacity:kCV965NumberChannels];
    for(i=0;i<kCV965NumberChannels;i++)[array addObject:[NSNumber numberWithShort:highThresholds[i]]];
    [objDictionary setObject:array forKey:@"highThresholds"];
	
	array = [NSMutableArray arrayWithCapacity:kCV965NumberChannels];
    for(i=0;i<kCV965NumberChannels;i++)[array addObject:[NSNumber numberWithBool:[self onlineMaskBit:i]]];
    [objDictionary setObject:array forKey:@"online"];
	
    return objDictionary;
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 965%@ QDC (Slot %d) ",modelType==0?@"":@"A",[self slot]];
}

#pragma mark ***HWWizard Support
- (int) numberOfChannels
{
	if([self modelType] == kModel965) return kCV965NumberChannels;
	else							  return kCV965ANumberChannels;
}

- (BOOL) hasParmetersToRamp
{
	return YES;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:NSStringFromClass([self class])]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:NSStringFromClass([self class])]];
    return a;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Low Threshold"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setLowThreshold:withValue:) getMethod:@selector(lowThreshold:)];
	//[p setCanBeRamped:YES];
	//[p setInitMethodSelector:@selector(writeLowThresholds)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"High Threshold"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setHighThreshold:withValue:) getMethod:@selector(highThreshold:)];
	//[p setCanBeRamped:YES];
	//[p setInitMethodSelector:@selector(writeLHighThresholds)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Online"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setOnlineMaskBit:withValue:) getMethod:@selector(onlineMaskBit:)];
    [p setActionMask:kAction_Set_Mask|kAction_Restore_Mask];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
	[p setUseValue:NO];
	[p setName:@"Init"];
	[p setSetMethodSelector:@selector(initBoard)];
	[a addObject:p];
    
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"Low Threshold"])return [[cardDictionary objectForKey:@"lowThresholds"] objectAtIndex:aChannel];
    if([param isEqualToString:@"High Threshold"])return [[cardDictionary objectForKey:@"highThresholds"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Online"]) return [cardDictionary objectForKey:@"onlineMask"];
    else return nil;
}
- (void) logThresholds
{
    short	i;
    NSLog(@"%@ Thresholds\n",[self identifier]);
	int n = (modelType==kModel965A)?8:16;
    for (i = 0; i < n; i++){
        NSLog(@"chan:%d low:0x%04x high:0x%04x\n",i,[self lowThreshold:i],[self highThreshold:i]);
    }
    
}
#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];
    [[self undoManager] disableUndoRegistration];
	int i;
    for (i = 0; i < kCV965NumberChannels; i++){
        [self setLowThreshold:i withValue:[aDecoder decodeIntForKey: [NSString stringWithFormat:@"CAENLowThresholdChnl%d", i]]];
        [self setHighThreshold:i withValue:[aDecoder decodeIntForKey: [NSString stringWithFormat:@"CAENHighThresholdChnl%d", i]]];
    }    
	
	[self setModelType:[aDecoder decodeIntForKey:@"modelType"]];
	[self setOnlineMask:[aDecoder decodeIntForKey:@"onlineMask"]];
    [self setSelectedRegIndex:[aDecoder decodeIntForKey:@"selectedRegIndex"]];
    [self setSelectedChannel:[aDecoder decodeIntForKey:@"selectedChannel"]];
    [self setWriteValue:[aDecoder decodeInt32ForKey:@"writeValue"]];

    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
    [anEncoder encodeInt:modelType forKey:@"modelType"];
    [anEncoder encodeInt:onlineMask forKey:@"onlineMask"];
	int i;
	for (i = 0; i < kCV965NumberChannels; i++){
        [anEncoder encodeInt:lowThresholds[i] forKey:[NSString stringWithFormat:@"CAENLowThresholdChnl%d", i]];
        [anEncoder encodeInt:highThresholds[i] forKey:[NSString stringWithFormat:@"CAENHighThresholdChnl%d", i]];
    }
	[anEncoder encodeInt:selectedRegIndex forKey:@"selectedRegIndex"];
    [anEncoder encodeInt:selectedChannel forKey:@"selectedChannel"];
    [anEncoder encodeInt32:writeValue forKey:@"writeValue"];
	
}

@end


