//--------------------------------------------------------------------------------
// ORCaen792Model.m
//  Created by Mark Howe on Tues June 1 2010.
//  Copyright © 2010 University of North Carolina. All rights reserved.
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
#import "ORCaen792Model.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORRateGroup.h"

#define k792DefaultBaseAddress 		0xa00000
#define k792DefaultAddressModifier 	0x39 //changed from 0x9 12/7/16 MAH. 0x09 works at MJD, but not at UNC or NCS.?!??


// Define all the registers available to this unit.
static RegisterNamesStruct reg[kNumRegisters] = {
	{@"Output Buffer",      true,	true, 	true,	0x0000,		kReadOnly,	kD32},
	{@"FirmWare Revision",	false,  false, 	false,	0x1000,		kReadOnly,	kD16},
	{@"Geo Address",        false,	false, 	false,	0x1002,		kReadWrite,	kD16},
	{@"MCST CBLT Address",	false,	false, 	true,	0x1004,		kReadWrite,	kD16},
	{@"Bit Set 1",          false,	true, 	true,	0x1006,		kReadWrite,	kD16},
	{@"Bit Clear 1",        false,	true, 	true,	0x1008,		kReadWrite,	kD16},
	{@"Interrup Level",     false,	true, 	true,	0x100A,		kReadWrite,	kD16},
	{@"Interrup Vector",	false,	true, 	true,	0x100C,		kReadWrite,	kD16},
	{@"Status Register 1",	false,	true, 	true,	0x100E,		kReadOnly,	kD16},
	{@"Control Register 1",	false,	true, 	true,	0x1010,		kReadWrite,	kD16},
	{@"ADER High",          false,	false, 	true,	0x1012,		kReadWrite,	kD16},
	{@"ADER Low",           false,	false, 	true,	0x1014,		kReadWrite,	kD16},
	{@"Single Shot Reset",	false,	false, 	false,	0x1016,		kWriteOnly,	kD16},
	{@"MCST CBLT Ctrl",     false,	false, 	true,	0x101A,		kReadWrite,	kD16},
	{@"Event Trigger Reg",	false,	true, 	true,	0x1020,		kReadWrite,	kD16},
	{@"Status Register 2",	false,	true, 	true,	0x1022,		kReadOnly,	kD16},
	{@"Event Counter L",	true,	true, 	true,	0x1024,		kReadOnly,	kD16},
	{@"Event Counter H",	true,	true, 	true,	0x1026,		kReadOnly,	kD16},
	{@"Increment Event",	false,	false, 	false,	0x1028,		kWriteOnly,	kD16},
	{@"Increment Offset",	false,	false, 	false,	0x102A,		kWriteOnly,	kD16},
	{@"Load Test Register",	false,	false, 	false,	0x102C,		kReadWrite,	kD16},
	{@"FCLR Window",        false,	true, 	true,	0x102E,		kReadWrite,	kD16},
	{@"Bit Set 2",          false,	true, 	true,	0x1032,		kReadWrite,	kD16},
	{@"Bit Clear 2",        false,	true, 	true,	0x1034,		kWriteOnly,	kD16},
	{@"W Mem Test Address",	false,	true, 	true,	0x1036,		kWriteOnly,	kD16},
	{@"Mem Test Word High",	false,	true, 	true,	0x1038,		kWriteOnly,	kD16},
	{@"Mem Test Word Low",	false,	false, 	false,	0x103A,		kWriteOnly,	kD16},
	{@"Crate Select",       false,	true, 	true,	0x103C,		kReadWrite,	kD16},
	{@"Test Event Write",	false,	false, 	false,	0x103E,		kWriteOnly,	kD16},
	{@"Event Counter Reset",false,	false, 	false,	0x1040,		kWriteOnly,	kD16},
	{@"I current pedestal", true,   true,   true,   0x1060,     kReadWrite, kD16},
	{@"R Test Address",     false,	true, 	true,	0x1064,		kWriteOnly,	kD16},
	{@"SW Comm",            false,	false, 	false,	0x1068,		kWriteOnly,	kD16},
	{@"Slide Cons Reg",     false,	true,	true,	0x106A,		kReadWrite, kD16},
	{@"ADD",                false,	false, 	false,	0x1070,		kReadOnly,	kD16},
	{@"BADD",               false,	false, 	false,	0x1072,		kReadOnly,	kD16},
	{@"Thresholds",         false,	false, 	false,	0x1080,		kReadWrite,	kD16},
};

NSString* ORCaen792ModelUseHWResetChanged             = @"ORCaen792ModelUseHWResetChanged";
NSString* ORCaen792ModelTotalCycleZTimeChanged        = @"ORCaen792ModelTotalCycleZTimeChanged";
NSString* ORCaen792ModelPercentZeroOffChanged         = @"ORCaen792ModelPercentZeroOffChanged";
NSString* ORCaen792ModelCycleZeroSuppressionChanged   = @"ORCaen792ModelCycleZeroSuppressionChanged";
NSString* ORCaen792ModelModelTypeChanged              = @"ORCaen792ModelModelTypeChanged";
NSString* ORCaen792ModelOnlineMaskChanged             = @"ORCaen792ModelOnlineMaskChanged";
NSString* ORCaen792ModelIPedChanged                   = @"ORCaen792ModelIPedChanged";
NSString* ORCaen792ModelSlideConstantChanged          = @"ORCaen792ModelSlideConstantChanged";
NSString* ORCaen792ModelSlidingScaleEnableChanged     = @"ORCaen792ModelSlidingScaleEnableChanged";
NSString* ORCaen792ModelEventCounterIncChanged        = @"ORCaen792ModelEventCounterIncChanged";
NSString* ORCaen792ModelZeroSuppressThresResChanged   = @"ORCaen792ModelZeroSuppressThresResChanged";
NSString* ORCaen792ModelZeroSuppressEnableChanged     = @"ORCaen792ModelZeroSuppressEnableChanged";
NSString* ORCaen792ModelOverflowSuppressEnableChanged = @"ORCaen792ModelOverflowSuppressEnableChanged";
NSString* ORCaen792RateGroupChangedNotification       = @"ORCaen792RateGroupChangedNotification";
NSString* ORCaen792ModelShipTimeStampChanged          = @"ORCaen792ModelShipTimeStampChanged";

// Bit Set 2 Register Masks
#define kTestMem        0x0001
#define kOffline        0x0002
#define kClearData      0x0004
#define kOverRange      0x0008 //used
#define kLowThres       0x0010 //used
#define kTestAcq        0x0040
#define kSlideEnable    0x0080
#define kZeroThresRes   0x0100 //used
#define kAutoInc        0x0800
#define kEmptyEnable    0x1000
#define kSlideSubEnable 0x2000 //used
#define kAllTrg         0x4000 //used
#define kSoftReset      0x0080

@interface ORCaen792Model (private)
- (void) startCyclingZeroSuppression;
- (void) stopCyclingZeroSuppression;
- (void) doCycle;
@end

@implementation ORCaen792Model

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:     k792DefaultBaseAddress];
    [self setAddressModifier: k792DefaultAddressModifier];
	[self setOnlineMask:0];
	
    [[self undoManager] enableUndoRegistration];
   
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [qdcRateGroup release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"C792"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCaen792Controller"];
}

- (NSString*) helpURL
{
	return @"VME/V792.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x10BF);
}

#pragma mark ***Accessors
-(BOOL) shipTimeStamp
{
    return shipTimeStamp;
}

- (void) setShipTimeStamp:(BOOL)aShipTimeStamp
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipTimeStamp:shipTimeStamp];
    
    shipTimeStamp = aShipTimeStamp;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen792ModelShipTimeStampChanged object:self];
}

- (int) totalCycleZTime
{
    return totalCycleZTime;
}

- (void) setTotalCycleZTime:(int)aValue
{
    if(aValue < 1) aValue=1;

    [[[self undoManager] prepareWithInvocationTarget:self] setTotalCycleZTime:totalCycleZTime];
    
    totalCycleZTime = aValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen792ModelTotalCycleZTimeChanged object:self];
}

- (int) percentZeroOff
{
    return percentZeroOff;
}

- (void) setPercentZeroOff:(int)aValue
{
    if(aValue < 1)       aValue = 1;
    else if(aValue > 99) aValue = 99;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setPercentZeroOff:percentZeroOff];
    
    percentZeroOff = aValue;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen792ModelPercentZeroOffChanged object:self];
}

- (BOOL) cycleZeroSuppression
{
    return cycleZeroSuppression;
}

- (void) setCycleZeroSuppression:(BOOL)aCycleZeroSuppression
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCycleZeroSuppression:cycleZeroSuppression];
    
    cycleZeroSuppression = aCycleZeroSuppression;
    
    if(!cycleZeroSuppression)[self stopCyclingZeroSuppression];
    else if([gOrcaGlobals runInProgress])[self startCyclingZeroSuppression];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen792ModelCycleZeroSuppressionChanged object:self];
}

- (unsigned short) slideConstant
{
    return slideConstant;
}

- (void) setSlideConstant:(unsigned short)aSlideConstant
{
    if(aSlideConstant > 0xff)aSlideConstant=0xff;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setSlideConstant:slideConstant];
    
    slideConstant = aSlideConstant;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen792ModelSlideConstantChanged object:self];
}
- (BOOL) useHWReset
{
    return useHWReset;
}

- (void) setUseHWReset:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setUseHWReset:useHWReset];
    
    useHWReset = aFlag;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen792ModelUseHWResetChanged object:self];
}

- (BOOL) slidingScaleEnable
{
    return slidingScaleEnable;
}

- (void) setSlidingScaleEnable:(BOOL)aSlidingScaleEnable
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlidingScaleEnable:slidingScaleEnable];
    
    slidingScaleEnable = aSlidingScaleEnable;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen792ModelSlidingScaleEnableChanged object:self];
}

- (BOOL) eventCounterInc
{
    return eventCounterInc;
}

- (void) setEventCounterInc:(BOOL)aEventCounterInc
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEventCounterInc:eventCounterInc];
    
    eventCounterInc = aEventCounterInc;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen792ModelEventCounterIncChanged object:self];
}

 - (BOOL) zeroSuppressThresRes
{
    return zeroSuppressThresRes;
}

- (void) setZeroSuppressThresRes:(BOOL)aZeroSuppressThresRes
{
    [[[self undoManager] prepareWithInvocationTarget:self] setZeroSuppressThresRes:zeroSuppressThresRes];
    
    zeroSuppressThresRes = aZeroSuppressThresRes;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen792ModelZeroSuppressThresResChanged object:self];
}

- (BOOL) zeroSuppressEnable
{
    return zeroSuppressEnable;
}

- (void) setZeroSuppressEnable:(BOOL)aZeroSuppressEnable
{
    [[[self undoManager] prepareWithInvocationTarget:self] setZeroSuppressEnable:zeroSuppressEnable];
    
    zeroSuppressEnable = aZeroSuppressEnable;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen792ModelZeroSuppressEnableChanged object:self];
}

- (BOOL) overflowSuppressEnable
{
    return overflowSuppressEnable;
}

- (void) setOverflowSuppressEnable:(BOOL)aOverflowSuppressEnable
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOverflowSuppressEnable:overflowSuppressEnable];
    
    overflowSuppressEnable = aOverflowSuppressEnable;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen792ModelOverflowSuppressEnableChanged object:self];
}

- (unsigned short) iPed
{
    return iPed;
}

- (void) setIPed:(unsigned short)aIPed
{
    if(aIPed >= 0xff)aIPed = 0xff;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setIPed:iPed];
    
    iPed = aIPed;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen792ModelIPedChanged object:self];
}

- (int) modelType
{
    return modelType;
}

- (void) setModelType:(int)aModelType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setModelType:modelType];
    
    modelType = aModelType;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen792ModelModelTypeChanged object:self];
}
- (uint32_t)onlineMask {
	
    return onlineMask;
}

- (void)setOnlineMask:(uint32_t)anOnlineMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOnlineMask:[self onlineMask]];
    onlineMask = anOnlineMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen792ModelOnlineMaskChanged object:self];
    [self postAdcInfoProvidingValueChanged];
}

- (BOOL)onlineMaskBit:(int)bit
{
	return (onlineMask&(1<<bit))!=0;
}

- (void) setOnlineMaskBit:(int)bit withValue:(BOOL)aValue
{
	uint32_t aMask = onlineMask;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setOnlineMask:aMask];
}

- (ORRateGroup*) qdcRateGroup
{
    return qdcRateGroup;
}
- (void) setQdcRateGroup:(ORRateGroup*)newRateGroup
{
    [newRateGroup retain];
    [qdcRateGroup release];
    qdcRateGroup = newRateGroup;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORCaen792RateGroupChangedNotification
	 object:self];
}

- (id) rateObject:(int)channel
{
    return [qdcRateGroup rateObject:channel];
}
- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[qdcRateGroup integrationTime]];
    [qdcRateGroup setIntegrationTime:newIntegrationTime];
}

#pragma mark ***Register - General routines
- (void) setThreshold:(unsigned short) aChnl threshold:(unsigned short) aValue
{
    [super setThreshold:aChnl threshold:aValue];
    [self postAdcInfoProvidingValueChanged];
}
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
    return kADCOutputBufferSize;
}

- (int) numberOfChannels
{
	if([self modelType] == kModel792) return 32;
	else							  return 16;
}

- (uint32_t) getThresholdOffset:(int)aChan
{
	if(modelType==kModel792)return reg[kThresholds].addressOffset + (aChan * 2);
	else					return reg[kThresholds].addressOffset + (aChan * 4);
}

- (short) getStatusRegisterIndex:(short) aRegister
{
    if (aRegister == 1) return kStatusRegister1;
    else		return kStatusRegister2;
}

- (short) getThresholdIndex
{
    return(kThresholds);
}

- (uint32_t) getThresholdOffset
{
    return reg[kThresholds].addressOffset;
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

- (uint32_t) getAddressOffset:(short) anIndex
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

- (void) writeThresholds
{
	int i;
	int n = (modelType==kModel792?16:32);
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

- (void) writeBit2Register
{
    unsigned short setBitMask = 0;
    unsigned short clrBitMask = 0;
    
    if(overflowSuppressEnable)  setBitMask |= kOverRange;
    else                        clrBitMask |= kOverRange;
    
    if(zeroSuppressEnable)      setBitMask |= kLowThres;
    else                        clrBitMask |= kLowThres;

    if(zeroSuppressThresRes)    setBitMask |= kZeroThresRes;
    else                        clrBitMask |= kZeroThresRes;
 
    if(eventCounterInc)         setBitMask |= kAllTrg;
    else                        clrBitMask |= kAllTrg;

    if(slidingScaleEnable)      setBitMask |= kSlideSubEnable;
    else                        clrBitMask |= kSlideSubEnable;

    
    [[self adapter] writeWordBlock:&setBitMask
                         atAddress:[self baseAddress] + reg[kBitSet2].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
 
    [[self adapter] writeWordBlock:&clrBitMask
                         atAddress:[self baseAddress] + reg[kBitClear2].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) writeOneShotReset
{
    unsigned short aValue = 0;
    [[self adapter] writeWordBlock:&aValue
                         atAddress:[self baseAddress] + reg[kSingleShotReset].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
}


- (void) writeSlideConstReg
{
    unsigned short aValue = slideConstant;
    [[self adapter] writeWordBlock:&aValue
                         atAddress:[self baseAddress] + reg[kSlideConsReg].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];

}

- (void) writeIPed
{
    unsigned short aValue = [self iPed] & 0xff;
    [[self adapter] writeWordBlock:&aValue
                         atAddress:[self baseAddress] + reg[kIpedReg].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	
}
- (unsigned short) readIPed
{
    unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
                         atAddress:[self baseAddress] + reg[kIpedReg].addressOffset
                        numToRead:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    return aValue & 0xff;
   
}

- (void) setToDefaults
{
    [self setOverflowSuppressEnable:NO];
    [self setZeroSuppressEnable:NO];
    [self setEventCounterInc:YES];
    [self setSlidingScaleEnable:YES];
    [self setZeroSuppressThresRes:NO];
}

- (void) initBoard
{
    if(!useHWReset)[self doSoftClear];
    [self writeThresholds];
    [self writeIPed];
    [self writeBit2Register];
    [self writeSlideConstReg];
}

- (void) resetEventCounter
{
    unsigned short aValue = 0;
    [[self adapter] writeWordBlock:&aValue
                         atAddress:[self baseAddress] + reg[kEventCounterReset].addressOffset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];

}

- (void) doSoftClear
{
    // Clear unit
    [self write:kBitSet1   sendValue:kSoftReset];   // set Soft Reset bit,
    [self write:kBitClear1 sendValue:kSoftReset];   // Clear "Soft Reset" bit of status reg.
}

- (void) clearData
{
    // Clear unit
    [self write:kBitSet2   sendValue:kClearData];		// set Clear data bit,
    [self write:kBitClear2 sendValue:kClearData];       // Clear "Clear data" bit of status reg.
}

#pragma mark ***DataTaker
- (void) setDataIds:(id)assigner
{
    dataId      = [assigner assignDataIds:kLongForm];
    dataIdN     = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
    [self setDataIdN:[anotherObj dataIdN]];
}

- (uint32_t) dataIdN { return dataIdN; }
- (void) setDataIdN: (uint32_t) aValue
{
    dataIdN = aValue;
}

- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
    [super runTaskStarted:aDataPacket userInfo:userInfo];
    
    // Set options
 	location =  (([self crateNumber]&0xf)<<21) | (([self slot]& 0x0000001f)<<16) && (shipTimeStamp & 0x1); //doesn't change so do it here.

    BOOL doInit = [[userInfo objectForKey:@"doinit"] boolValue];
    if(doInit){
        [self initBoard];
    
        if(cycleZeroSuppression){
            [self startCyclingZeroSuppression];
        }
    }
	isRunning = NO;
    [self startRates];
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
{
    
    unsigned short 	theStatus1;
	isRunning = YES;
    
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
                    if(shipTimeStamp) {
                        struct timeval ts;
                        if(gettimeofday(&ts,NULL) ==0){
                            dataRecord[index++] = (uint32_t)ts.tv_sec;
                            dataRecord[index++] = (uint32_t)ts.tv_usec;
                        }
                    }
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
                            int channel;
                            if([self modelType] == kModel792)   channel = ShiftAndExtract(dataValue,16,0x3f);
                            else                                channel = ShiftAndExtract(dataValue,17,0xF);

                            if(channel>=0 && channel<32) eventCounter[channel]++;
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
                            if(modelType == kModel792) dataRecord[0] = dataId  | index; //see.... filled it in here....
                            else					   dataRecord[0] = dataIdN | index; //see.... filled it in here....
                            
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

- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
	[qdcRateGroup stop];
	isRunning = NO;
    
    BOOL doInit = [[userInfo objectForKey:@"doinit"] boolValue];
    if(doInit){
        [self stopCyclingZeroSuppression];
        [self clearData];
    }
    [super runTaskStopped:aDataPacket userInfo:userInfo];
}

#pragma mark ¥¥¥Rates
- (BOOL) bumpRateFromDecodeStage:(short)channel
{
	if(isRunning)return NO;
    ++eventCounter[channel];
    return YES;
}

- (uint32_t) eventCount:(int)aChannel
{
    return eventCounter[aChannel];
}

-(void) startRates
{
	[self clearEventCounts];
    [qdcRateGroup start:self];
}

- (void) clearEventCounts
{
    int i;
    for(i=0;i<[self numberOfChannels];i++){
		eventCounter[i]=0;
    }
}

- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<[self numberOfChannels]){
			return eventCounter[counterTag];
		}
		else return 0;
	}
	else return 0;
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 792 (Slot %d) ",[self slot]];
}

- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id = kCaen792; //should be unique
    if(modelType == kModel792)	configStruct->card_info[index].hw_mask[0] 	 = (uint32_t)dataId; //better be unique
    else						configStruct->card_info[index].hw_mask[0] 	 = (uint32_t)dataIdN;
	configStruct->card_info[index].slot 	 = [self slot];
	configStruct->card_info[index].crate 	 = [self crateNumber];
	configStruct->card_info[index].add_mod 	 = [self addressModifier];
	configStruct->card_info[index].base_add  = [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0] = modelType;
	configStruct->card_info[index].deviceSpecificData[1] = ([self baseAddress]+reg[kStatusRegister1].addressOffset);
	configStruct->card_info[index].deviceSpecificData[2] = ([self baseAddress]+reg[kStatusRegister2].addressOffset);
	configStruct->card_info[index].deviceSpecificData[3] = ([self baseAddress]+reg[kOutputBuffer].addressOffset);
    configStruct->card_info[index].deviceSpecificData[4] = [self getDataBufferSize]/sizeof(uint32_t);
    configStruct->card_info[index].deviceSpecificData[5] = shipTimeStamp;
	configStruct->card_info[index].num_Trigger_Indexes = 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;
	
	return index+1;
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORCAEN792DecoderForQdc",					@"decoder",
								 [NSNumber numberWithLong:dataId],          @"dataId",
								 [NSNumber numberWithBool:YES],             @"variable",
								 [NSNumber numberWithLong:-1],              @"length",
								 nil];
	[dataDictionary setObject:aDictionary forKey:@"Qdc"];
 

    
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                   @"ORCAEN792NDecoderForQdc",                  @"decoder",
                   [NSNumber numberWithLong:dataIdN],           @"dataId",
                   [NSNumber numberWithBool:YES],               @"variable",
                   [NSNumber numberWithLong:-1],				@"length",
                   nil];
	[dataDictionary setObject:aDictionary forKey:@"QdcN"];

    
    return dataDictionary;
}


#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];

    [[self undoManager] disableUndoRegistration];
    [self setUseHWReset:            [aDecoder decodeBoolForKey: @"useHWReset"]];
    [self setTotalCycleZTime:       [aDecoder decodeIntForKey:  @"totalCycleZTime"]];
    [self setPercentZeroOff:        [aDecoder decodeIntForKey:  @"percentZeroOff"]];
    [self setCycleZeroSuppression:  [aDecoder decodeBoolForKey: @"cycleZeroSuppression"]];
    [self setSlideConstant:         [aDecoder decodeIntegerForKey:  @"slideConstant"]];
    [self setSlidingScaleEnable:    [aDecoder decodeBoolForKey: @"slidingScaleEnable"]];
    [self setEventCounterInc:       [aDecoder decodeBoolForKey: @"eventCounterInc"]];
    [self setZeroSuppressThresRes:  [aDecoder decodeBoolForKey: @"zeroSuppressThresRes"]];
    [self setZeroSuppressEnable:    [aDecoder decodeBoolForKey: @"zeroSuppressEnable"]];
    [self setOverflowSuppressEnable:[aDecoder decodeBoolForKey: @"overflowSuppressEnable"]];
    [self setIPed:                  [aDecoder decodeIntegerForKey:  @"iPed"]];
    [self setModelType:             [aDecoder decodeIntForKey:  @"modelType"]];
   	[self setOnlineMask:            [aDecoder decodeIntForKey:@"onlineMask"]];
    [self setShipTimeStamp:         [aDecoder decodeBoolForKey:@"shipTimeStamp"]];

    [self setQdcRateGroup:[aDecoder decodeObjectForKey:@"qdcRateGroup"]];
    
    if(!qdcRateGroup){
        [self setQdcRateGroup:[[[ORRateGroup alloc] initGroup:[self numberOfChannels] groupTag:0] autorelease]];
        [qdcRateGroup setIntegrationTime:5];
    }
    [qdcRateGroup resetRates];
    [qdcRateGroup calcRates];

    
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
    [anEncoder encodeBool:useHWReset              forKey:@"useHWReset"];
	[anEncoder encodeInteger:totalCycleZTime          forKey:@"totalCycleZTime"];
	[anEncoder encodeInteger:percentZeroOff           forKey:@"percentZeroOff"];
	[anEncoder encodeBool:cycleZeroSuppression    forKey:@"cycleZeroSuppression"];
	[anEncoder encodeInteger:  slideConstant          forKey:@"slideConstant"];
	[anEncoder encodeBool: slidingScaleEnable     forKey:@"slidingScaleEnable"];
	[anEncoder encodeBool: eventCounterInc        forKey:@"eventCounterInc"];
	[anEncoder encodeBool: zeroSuppressThresRes   forKey:@"zeroSuppressThresRes"];
	[anEncoder encodeBool: zeroSuppressEnable     forKey:@"zeroSuppressEnable"];
	[anEncoder encodeBool: overflowSuppressEnable forKey:@"overflowSuppressEnable"];
	[anEncoder encodeInteger:  iPed                   forKey:@"iPed"];
	[anEncoder encodeInteger:  modelType              forKey:@"modelType"];
	[anEncoder encodeInt:onlineMask             forKey:@"onlineMask"];
    [anEncoder encodeObject: qdcRateGroup         forKey:@"qdcRateGroup"];
    [anEncoder encodeBool: shipTimeStamp          forKey:@"shipTimeStamp"];
}

#pragma mark ¥¥¥AdcProviding Protocol

- (BOOL) partOfEvent:(unsigned short)aChannel
{
	//included to satisfy the protocal... change if needed
	return NO;
}

- (uint32_t) thresholdForDisplay:(unsigned short) aChan
{
	return [self threshold:aChan];
}

- (unsigned short) gainForDisplay:(unsigned short) aChan
{
	return 0;
}
- (void) postAdcInfoProvidingValueChanged
{
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORAdcInfoProvidingValueChanged
	 object:self
	 userInfo: nil];
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:threshold:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
	[p setInitMethodSelector:@selector(writeThresholds)];
    [a addObject:p];
    
	p = [[[ORHWWizParam alloc] init] autorelease];
	[p setUseValue:NO];
	[p setName:@"Init"];
	[p setSetMethodSelector:@selector(writeThresholds)];
	[a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel  name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel     name:@"Card" className:NSStringFromClass([self class])]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel    name:@"Channel" className:NSStringFromClass([self class])]];
    return a;
    
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
    if([param isEqualToString:@"Threshold"])return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
    else return nil;
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];

    [objDictionary setObject:[NSNumber numberWithBool:useHWReset]             forKey:@"useHWReset"];
    [objDictionary setObject:[NSNumber numberWithInt:slideConstant]           forKey:@"slideConstant"];
    [objDictionary setObject:[NSNumber numberWithBool:slidingScaleEnable]     forKey:@"slidingScaleEnable"];
    [objDictionary setObject:[NSNumber numberWithBool:overflowSuppressEnable] forKey:@"overflowSuppressEnable"];
    [objDictionary setObject:[NSNumber numberWithBool:zeroSuppressEnable]     forKey:@"zeroSuppressEnable"];
    [objDictionary setObject:[NSNumber numberWithBool:eventCounterInc]        forKey:@"eventCounterInc"];
    [objDictionary setObject:[NSNumber numberWithBool:shipTimeStamp]          forKey:@"shipTimeStamp"];

    return objDictionary;
}
@end

@implementation ORCaen792Model (private)
- (void) startCyclingZeroSuppression
{
    [self setZeroSuppressEnable:NO];
    [self doCycle];
}

- (void) doCycle
{
    [self setZeroSuppressEnable:!zeroSuppressEnable];
    [self writeBit2Register];
    
    float timeUntilNextCycle;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doCycle) object:nil];
    if(zeroSuppressEnable == YES){ //YES is actually zero suppression OFF
        timeUntilNextCycle = totalCycleZTime * (percentZeroOff/100.);
    }
    else {
        timeUntilNextCycle = totalCycleZTime * (1. - (percentZeroOff/100.));
    }
    [self performSelector:@selector(doCycle) withObject:nil afterDelay:timeUntilNextCycle];
}

- (void) stopCyclingZeroSuppression
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(doCycle) object:nil];
    
}
@end
