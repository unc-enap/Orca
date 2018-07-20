//--------------------------------------------------------------------------------
// CLASS:		ORCaen775Model
// Purpose:		Handles hardware interface for those commands specific to the 775.
// Author:		Jan M. Wouters
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
#import "ORCaen775Model.h"

// Address information for this unit.
#define k775DefaultBaseAddress 		0xa00000
#define k775DefaultAddressModifier 	0x9

#define kStartStop	0x400

NSString* ORCaen775ModelFullScaleRangeChanged = @"ORCaen775ModelFullScaleRangeChanged";
NSString* ORCaen775ModelCommonStopModeChanged = @"ORCaen775ModelCommonStopModeChanged";
NSString* ORCaen775ModelModelTypeChanged = @"ORCaen775ModelModelTypeChanged";
NSString* ORCaen775ModelOnlineMaskChanged = @"ORCaen775ModelOnlineMaskChanged";

// Define all the registers available to this unit.
static RegisterNamesStruct reg[kNumRegisters] = {
{@"Output Buffer",		true,	true, 	true,	0x0000,		kReadOnly,	kD32},
{@"FirmWare Revision",	false,	false, 	false,	0x1000,		kReadOnly,	kD16},
{@"Geo Address",		false,	false, 	false,	0x1002,		kReadWrite,	kD16},
{@"MCST CBLT Address",	false,	false, 	true,	0x1004,		kReadWrite,	kD16},
{@"Bit Set 1",			false,	true, 	true,	0x1006,		kReadWrite,	kD16},
{@"Bit Clear 1",		false,	true, 	true,	0x1008,		kReadWrite,	kD16},
{@"Interrupt Level",	false,	true, 	true,	0x100A,		kReadWrite,	kD16},
{@"Interrupt Vector",	false,	true, 	true,	0x100C,		kReadWrite,	kD16},
{@"Status Register 1",	false,	true, 	true,	0x100E,		kReadOnly,	kD16},
{@"Control Register 1",	false,	true, 	true,	0x1010,		kReadWrite,	kD16},
{@"ADER High",			false,	false, 	true,	0x1012,		kReadWrite,	kD16},
{@"ADER Low",			false,	false, 	true,	0x1014,		kReadWrite,	kD16},
{@"Single Shot Reset",	false,	false, 	false,	0x1016,		kWriteOnly,	kD16},
{@"MCST CBLT Ctrl",		false,	false, 	true,	0x101A,		kReadWrite,	kD16},
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
{@"Crate Select",		false,	true, 	true,	0x103C,		kReadWrite,	kD16},
{@"Test Event Write",	false,	false, 	false,	0x103E,		kWriteOnly,	kD16},
{@"Event Counter Reset",false,	false, 	false,	0x1040,		kWriteOnly,	kD16},
{@"Full Scale Range",	false,	true, 	true,	0x1060,		kReadWrite,	kD16},
{@"R Test Address",		false,	true, 	true,	0x1064,		kWriteOnly,	kD16},
{@"SW Comm",			false,	false, 	false,	0x1068,		kWriteOnly,	kD16},
{@"Slide Constant",		false,	false, 	false,	0x106A,		kReadWrite,	kD16},
{@"ADD",				false,	false, 	false,	0x1070,		kReadOnly,	kD16},
{@"BADD",				false,	false, 	false,	0x1072,		kReadOnly,	kD16},
{@"Thresholds",			false,	false, 	false,	0x1080,		kReadWrite,	kD16},
};


@implementation ORCaen775Model

#pragma mark ¥¥¥Initialization
- (id) init //designated initializer
{
    self = [super init];
	[[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress: k775DefaultBaseAddress];
    [self setAddressModifier: k775DefaultAddressModifier];
	[self setOnlineMask:0];
	[[self undoManager] enableUndoRegistration];
    
    return self;
}

#pragma mark ***Accessors

- (unsigned short) fullScaleRange
{
    return fullScaleRange;
}

- (void) setFullScaleRange:(unsigned short)aFullScaleRange
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFullScaleRange:fullScaleRange];
    
    fullScaleRange = aFullScaleRange;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen775ModelFullScaleRangeChanged object:self];
}

- (BOOL) commonStopMode
{
    return commonStopMode;
}

- (void) setCommonStopMode:(BOOL)aCommonStopMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCommonStopMode:commonStopMode];
    
    commonStopMode = aCommonStopMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen775ModelCommonStopModeChanged object:self];
}

- (int) modelType
{
    return modelType;
}

- (void) setModelType:(int)aModelType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setModelType:modelType];
    
    modelType = aModelType;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen775ModelModelTypeChanged object:self];
}

- (uint32_t)onlineMask {
	
    return onlineMask;
}

- (void)setOnlineMask:(uint32_t)anOnlineMask 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOnlineMask:[self onlineMask]];
    onlineMask = anOnlineMask;	    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen775ModelOnlineMaskChanged object:self];
}

- (BOOL)onlineMaskBit:(int)bit
{
	return onlineMask&(1<<bit);
}

- (void) setOnlineMaskBit:(int)bit withValue:(BOOL)aValue
{
	uint32_t aMask = onlineMask;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setOnlineMask:aMask];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"775Card"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCaen775Controller"];
}

- (NSString*) helpURL
{
	return @"VME/V775.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x1080);
}

#pragma mark ¥¥¥Register - General routines
- (short) getNumberRegisters
{
	return kNumRegisters;
}

- (uint32_t) getBufferOffset
{
	return reg[kOutputBuffer].addressOffset;
}

- (unsigned short) getDataBufferSize
{
	return kTDCOutputBufferSize;
}

- (int) numberOfChannels
{
	if([self modelType] == kModel775) return 32;
	else							  return 16;
}

- (uint32_t) getThresholdOffset:(int)aChan
{
	if(modelType==kModel775)return reg[kThresholds].addressOffset + (aChan * 2);
	else					return reg[kThresholds].addressOffset + (aChan * 4);
}

- (short) getStatusRegisterIndex: (short) aRegister
{
    if ( aRegister == 1 ) return kStatusRegister1;
    else return kStatusRegister2;
}

- (short) getThresholdIndex
{
    return( kThresholds );
}

- (short) getOutputBufferIndex
{
    return( kOutputBuffer );
}

- (void) setThreshold:(unsigned short) aChnl threshold:(unsigned short) aValue
{
	if(aValue > 0xff)aValue=0xff;
	[super setThreshold:aChnl threshold:aValue];
}
#pragma mark ***Register - Register specific routines
- (NSString*) getRegisterName: (short) anIndex
{
	return reg[anIndex].regName;
}

- (uint32_t) getAddressOffset: (short) anIndex
{
    return( reg[anIndex].addressOffset );
}

- (short) getAccessType: (short) anIndex
{
	return reg[anIndex].accessType;
}

- (short) getAccessSize: (short) anIndex
{
	return reg[anIndex].size;
}

- (BOOL) dataReset: (short) anIndex
{
	return reg[anIndex].dataReset;
}

- (BOOL) swReset: (short) anIndex
{
	return reg[anIndex].softwareReset;
}

- (BOOL) hwReset: (short) anIndex
{
	return reg[anIndex].hwReset;
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 775%@ (Slot %d) ",modelType==0?@"":@"N",[self slot]];
}

- (unsigned short) threshold:(unsigned short) aChnl
{
	return [super threshold:aChnl] & 0xFF;
}

- (void) readThreshold:(unsigned short) pChan
{
    
    unsigned short		value;
    
    // Read the threshold
    [[self adapter] readWordBlock:&value
                        atAddress:[self baseAddress] + [self getThresholdOffset:pChan]
                        numToRead:1
                       withAddMod:[self addressModifier]
                    usingAddSpace:0x01];
    
    // Store new value
	// [self setThreshold:pChan threshold:value];
    
}
- (void) writeThresholds
{
	int i;
	int n = (modelType==kModel775?32:16);
	for(i=0;i<n;i++){
		int kill = ((onlineMask & (1<<i))!=0)?0x0:0x100;
		unsigned short aValue = [self threshold:i] | kill;
		[[self adapter] writeWordBlock:&aValue
							 atAddress:[self baseAddress] + [self getThresholdOffset:i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}

- (void) writeFullScaleRange:(unsigned short)aValue
{
		[[self adapter] writeWordBlock:&aValue
							 atAddress:[self baseAddress] + reg[kFullScaleRange].addressOffset
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
}

- (unsigned short)   readFullScaleRange
{
	unsigned short aValue =0;
	[[self adapter] readWordBlock:&aValue
						 atAddress:[self baseAddress] + reg[kFullScaleRange].addressOffset
						numToRead:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	return aValue;
}

- (void) writeThreshold:(unsigned short) pChan
{
 	int kill = ((onlineMask & (1<<pChan))!=0)?0x0:0x100;
    unsigned short 	threshold = [self threshold:pChan] | kill;
	
    [[self adapter] writeWordBlock:&threshold
                         atAddress:[self baseAddress] + [self getThresholdOffset:pChan]
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) setDataIds:(id)assigner
{
    dataId = [assigner assignDataIds:kLongForm];
    dataIdN = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
    [self setDataIdN:[anotherObj dataIdN]];
}

- (uint32_t) dataIdN { return dataIdN; }
- (void) setDataIdN: (uint32_t) DataId
{
    dataIdN = DataId;
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORCAEN775DecoderForTdc",					@"decoder",
								 [NSNumber numberWithLong:dataId],          @"dataId",
								 [NSNumber numberWithBool:YES],             @"variable",
								 [NSNumber numberWithLong:-1],              @"length",
								 nil];
	[dataDictionary setObject:aDictionary forKey:@"Tdc"];

	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORCAEN775NDecoderForTdc",				@"decoder",
								 [NSNumber numberWithLong:dataIdN],          @"dataId",
								 [NSNumber numberWithBool:YES],             @"variable",
								 [NSNumber numberWithLong:-1],				@"length",
								 nil];
	[dataDictionary setObject:aDictionary forKey:@"TdcN"];
		
    return dataDictionary;
}

- (void) initBoard
{
	[self writeThresholds];
	[self writeFullScaleRange: fullScaleRange];
    if(commonStopMode){
        [self write: kBitSet2 sendValue: kCommonStopMode];
    }
    else {
        [self write: kBitClear2 sendValue: kCommonStopMode];
    }
    [self write: kEventCounterReset sendValue: 0x0000];		// Clear event counter
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithUnsignedShort:fullScaleRange] forKey:@"fullScaleRange"];
    return objDictionary;
}

#pragma mark ***DataTaker
- (void) runTaskStarted: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
	[self initBoard];
 	location =  (([self crateNumber]&0xf)<<21) | (([self slot]& 0x0000001f)<<16); //doesn't change so do it here.
    [super runTaskStarted:aDataPacket userInfo:userInfo];
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
{
    
    unsigned short 	theStatus1;
    
    @try {
        
        //first read the status resisters to see if there is anything to read.
        [self read:[self getStatusRegisterIndex:1] returnValue:&theStatus1];
        
        // Get some values from the status register using the decoder.
        BOOL dataIsReady 		= [dataDecoder isDataReady:theStatus1];
        uint32_t bufferAddress = [self baseAddress] + [self getBufferOffset];
        
        // Read the buffer.
        if (dataIsReady) {
			
			//OK, at least one data value is ready
			uint32_t dataValue;
			[controller readLongBlock:&dataValue
							atAddress:bufferAddress
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
					uint32_t dataRecord[0xffff];
					//we fill in dataRecord[0] below once we know the final size
					dataRecord[1] = location;
					int index = 2;
					for(i=0;i<numMemorizedChannels;i++){
						[controller readLongBlock:&dataValue
										atAddress:bufferAddress
										numToRead:1
									   withAddMod:[self addressModifier]
									usingAddSpace:0x01];
						int dataType = ShiftAndExtract(dataValue,24,0x7);
						if(dataType == 0x000){
							dataRecord[index] = dataValue;
							index++;
						}
						else {
							validData = NO;
							break;
						}
					}
					if(validData){
						//OK we read the data, get the end of block
						[controller readLongBlock:&dataValue
										atAddress:bufferAddress
										numToRead:1
									   withAddMod:[self addressModifier]
									usingAddSpace:0x01];
						//make sure it really is an end of block
						int dataType = ShiftAndExtract(dataValue,24,0x7);
						if(dataType == 0x4){
							dataRecord[index] = dataValue; //we don't ship the end of block for now
							index++;
							//got a end of block fill in the ORCA header and ship the data
							if(modelType == kModel775) dataRecord[0] = dataId  | index; //see.... filled it in here....
							else					  dataRecord[0] = dataIdN | index; //see.... filled it in here....
							[aDataPacket addLongsToFrameBuffer:dataRecord length:index];
						}
						else {
							validData = NO;
						}
					}
				}
			}
			if(!validData){
				[self flushBuffer];
			}
		}
	}
	@catch(NSException* localException) {
		errorCount++;
	}
}

- (void) runTaskStopped: (ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
    [super runTaskStopped:aDataPacket userInfo:userInfo];
}

- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id = kCaen775; //should be unique
	if(modelType == kModel775)	configStruct->card_info[index].hw_mask[0] 	 = (int32_t)dataId; //better be unique
	else						configStruct->card_info[index].hw_mask[0] 	 = (int32_t)dataIdN;
	configStruct->card_info[index].slot 	 = [self slot];
	configStruct->card_info[index].crate 	 = [self crateNumber];
	configStruct->card_info[index].add_mod 	 = [self addressModifier];
	configStruct->card_info[index].base_add  = (int32_t)[self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0] = (int32_t)reg[kStatusRegister1].addressOffset;
	configStruct->card_info[index].deviceSpecificData[1] = (int32_t)reg[kOutputBuffer].addressOffset;
	configStruct->card_info[index].deviceSpecificData[2] = (int32_t)reg[kStatusRegister2].addressOffset;
	configStruct->card_info[index].deviceSpecificData[3] = (int32_t)[self getDataBufferSize]/sizeof(int32_t);
	configStruct->card_info[index].num_Trigger_Indexes = 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}
#pragma mark ¥¥¥Archival
- (id) initWithCoder: (NSCoder*) aDecoder
{
    self = [super initWithCoder: aDecoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setFullScaleRange:[aDecoder decodeIntegerForKey:@"fullScaleRange"]];
    [self setCommonStopMode:	[aDecoder decodeBoolForKey:@"commonStopMode"]];
    [self setModelType:			[aDecoder decodeIntForKey:@"modelType"]];
   	[self setOnlineMask:		[aDecoder decodeIntForKey:@"onlineMask"]];
 
    [[self undoManager] enableUndoRegistration];
    return self;
}


- (void) encodeWithCoder: (NSCoder*) anEncoder
{
    [super encodeWithCoder: anEncoder];
	[anEncoder encodeInteger:(int32_t)fullScaleRange forKey:@"fullScaleRange"];
	[anEncoder encodeBool:commonStopMode	forKey:@"commonStopMode"];
	[anEncoder encodeInteger:modelType			forKey:@"modelType"];
	[anEncoder encodeInt:onlineMask		forKey:@"onlineMask"];
}

@end


