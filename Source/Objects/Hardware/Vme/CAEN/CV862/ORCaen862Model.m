/*
 *  ORCaen862Model.m
 *  Orca
 *
 *  Created by Mark Howe on Thurs May 29 2008.
 *  Copyright (c) 2008 CENPA, University of Washington. All rights reserved.
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
#import "ORCaen862Model.h"

// Address information for this unit.
#define k862DefaultBaseAddress 		0xa00000
#define k862DefaultAddressModifier 	0x9

NSString* ORCaen862ModelIPedChanged                   = @"ORCaen862ModelIPedChanged";
NSString* ORCaen862ModelEventCounterIncChanged        = @"ORCaen862ModelEventCounterIncChanged";
NSString* ORCaen862ModelSlideConstantChanged          = @"ORCaen862ModelSlideConstantChanged";
NSString* ORCaen862ModelSlidingScaleEnableChanged     = @"ORCaen862ModelSlidingScaleEnableChanged";
NSString* ORCaen862ModelZeroSuppressThresResChanged   = @"ORCaen862ModelZeroSuppressThresResChanged";
NSString* ORCaen862ModelZeroSuppressEnableChanged     = @"ORCaen862ModelZeroSuppressEnableChanged";
NSString* ORCaen862ModelOverflowSuppressEnableChanged = @"ORCaen862ModelOverflowSuppressEnableChanged";


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
	{@"I current pedestal", false,  true, true,		0x1060,		kReadWrite, kD16},
	{@"R Test Address",     false,	true, 	true,	0x1064,		kWriteOnly,	kD16},
	{@"SW Comm",			false,	false, 	false,	0x1068,		kWriteOnly,	kD16},
	{@"Slide Cons Reg",     false,	true,	true,	0x106A,		kReadWrite, kD16},
	{@"ADD",				false,	false, 	false,	0x1070,		kReadOnly,	kD16},
	{@"BADD",				false,	false, 	false,	0x1072,		kReadOnly,	kD16},
	{@"Thresholds",			false,	false, 	false,	0x1080,		kReadWrite,	kD16},
};

// Bit Set 2 Register Masks
#define kMemTest            0x0001
#define kOffline            0x0002
#define kClearData          0x0004
#define kOverRange          0x0008
#define kLowThres           0x0010
#define kTestAcq            0x0040
#define kSlideEnable        0x0080
#define kZeroThresRes       0x0100
#define kAutoInc            0x0800
#define kEmptyPrg           0x1000
#define kSlideSubEnable     0x2000
#define kAllTrg             0x4000

#define kSoftReset      0x0080


@implementation ORCaen862Model

#pragma mark ***Initialization
- (id) init //designated initializer
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
	
    [self setBaseAddress:k862DefaultBaseAddress];
    [self setAddressModifier:k862DefaultAddressModifier];
	
    [[self undoManager] enableUndoRegistration];
   
    return self;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"C862"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORCaen862Controller"];
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x1080);
}

- (NSString*) helpURL
{
	return @"VME/V862.html";
}

#pragma mark ***Register - General routines
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
    return k862OutputBufferSize;
}

- (uint32_t) getThresholdOffset
{
    return reg[kThresholds].addressOffset;
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

- (short) getOutputBufferIndex
{
    return(kOutputBuffer);
}

- (short) iPed
{
    return iPed;
}

- (void) setIPed:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIPed:iPed];
    iPed = aValue & 0xff;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen862ModelIPedChanged object:self];
}

- (BOOL) eventCounterInc
{
    return eventCounterInc;
}

- (void) setEventCounterInc:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEventCounterInc:eventCounterInc];
    
    eventCounterInc = aFlag;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen862ModelEventCounterIncChanged object:self];
}

- (BOOL) slidingScaleEnable
{
    return slidingScaleEnable;
}

- (void) setSlidingScaleEnable:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSlidingScaleEnable:slidingScaleEnable];
    
    slidingScaleEnable = aFlag;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen862ModelSlidingScaleEnableChanged object:self];
}

- (short) slideConstant
{
    return slideConstant;
}

- (void) setSlideConstant:(short)aValue
{
    aValue &= 0xff;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setSlideConstant:slideConstant];
    
    slideConstant = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen862ModelSlideConstantChanged object:self];
}

- (BOOL) zeroSuppressThresRes
{
    return zeroSuppressThresRes;
}

- (void) setZeroSuppressThresRes:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setZeroSuppressThresRes:zeroSuppressThresRes];
    
    zeroSuppressThresRes = aFlag;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen862ModelZeroSuppressThresResChanged object:self];
}

- (BOOL) zeroSuppressEnable
{
    return zeroSuppressEnable;
}

- (void) setZeroSuppressEnable:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setZeroSuppressEnable:zeroSuppressEnable];
    
    zeroSuppressEnable = aFlag;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen862ModelZeroSuppressEnableChanged object:self];
}
- (BOOL) overflowSuppressEnable
{
    return overflowSuppressEnable;
}

- (void) setOverflowSuppressEnable:(BOOL)aFlag
{
    [[[self undoManager] prepareWithInvocationTarget:self] setOverflowSuppressEnable:overflowSuppressEnable];
    
    overflowSuppressEnable = aFlag;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCaen862ModelOverflowSuppressEnableChanged object:self];
}

- (void) writeBit2Register
{
    unsigned short setBitMask = 0;
    unsigned short clrBitMask = 0;
    
    if(overflowSuppressEnable)  setBitMask |= kOverRange;
    else                        clrBitMask |= kOverRange;
    
    if(eventCounterInc)         setBitMask |= kAllTrg;
    else                        clrBitMask |= kAllTrg;
    
    if(slidingScaleEnable)      setBitMask |= kSlideEnable;
    else                        clrBitMask |= kSlideEnable;
    
    if(zeroSuppressEnable)      setBitMask |= kLowThres;
    else                        clrBitMask |= kLowThres;
    
    if(zeroSuppressThresRes)    setBitMask |= kZeroThresRes;
    else                        clrBitMask |= kZeroThresRes;

    [self write:kBitSet2  sendValue:setBitMask];
    [self write:kBitClear2 sendValue:clrBitMask];
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

#pragma mark ***HW Access
- (void) initBoard
{
    [self doSoftClear];
    [self clearEventCount];
    [self writeIPed];
    [self writeBit2Register];
    [self writeSlideConstReg];
    [self writeThresholds];
}

- (void) writeSlideConstReg
{
    [self write:kSlideConsReg sendValue:slideConstant];
}

- (void) doSoftClear
{
    [self write:kBitSet1   sendValue:kSoftReset];   // set Soft Reset bit,
    [self write:kBitClear1 sendValue:kSoftReset];   // Clear "Soft Reset" bit of status reg.
}

- (void) clearEventCount
{
    [self write:kEventCounterReset sendValue:0x0000];	// Clear event counter
}

- (void) writeIPed
{
    [self write:kIpedReg sendValue:iPed & 0xff];
}

#pragma mark ***DataTaker
- (void) runTaskStarted:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
    [super runTaskStarted:aDataPacket userInfo:userInfo];
    
    BOOL doInit = [[userInfo objectForKey:@"doinit"] boolValue];
    if(doInit){
        [self initBoard];
    }
}

- (void) runTaskStopped:(ORDataPacket*) aDataPacket userInfo:(NSDictionary*)userInfo
{
    [super runTaskStopped:aDataPacket userInfo:userInfo];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"CAEN 862 (Slot %d) ",[self slot]];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:[NSNumber numberWithShort:iPed]                    forKey:@"iPed"];
    [objDictionary setObject:[NSNumber numberWithBool:eventCounterInc]          forKey:@"eventCounterInc"];
    [objDictionary setObject:[NSNumber numberWithShort:slidingScaleEnable]      forKey:@"slidingScaleEnable"];
    [objDictionary setObject:[NSNumber numberWithBool:slideConstant]            forKey:@"slideConstant"];
    [objDictionary setObject:[NSNumber numberWithBool:zeroSuppressThresRes]     forKey:@"zeroSuppressThresRes"];
    [objDictionary setObject:[NSNumber numberWithBool:zeroSuppressEnable]       forKey:@"zeroSuppressEnable"];
    [objDictionary setObject:[NSNumber numberWithBool:overflowSuppressEnable]   forKey:@"overflowSuppressEnable"];
    return objDictionary;
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*) aDecoder
{
    self = [super initWithCoder:aDecoder];

    [[self undoManager] disableUndoRegistration];
    
    [self setIPed:                  [aDecoder decodeIntegerForKey:@"iPed"]];
    [self setEventCounterInc:       [aDecoder decodeBoolForKey: @"eventCounterInc"]];
    [self setSlideConstant:         [aDecoder decodeIntegerForKey:  @"slideConstant"]];
    [self setSlidingScaleEnable:    [aDecoder decodeBoolForKey: @"slidingScaleEnable"]];
    [self setZeroSuppressThresRes:  [aDecoder decodeBoolForKey: @"zeroSuppressThresRes"]];
    [self setZeroSuppressEnable:    [aDecoder decodeBoolForKey: @"zeroSuppressEnable"]];
    [self setOverflowSuppressEnable:[aDecoder decodeBoolForKey: @"overflowSuppressEnable"]];

    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*) anEncoder
{
    [super encodeWithCoder:anEncoder];
    [anEncoder encodeInteger:  iPed                   forKey:@"iPed"];
    [anEncoder encodeBool: eventCounterInc        forKey:@"eventCounterInc"];
    [anEncoder encodeInteger:  slideConstant          forKey:@"slideConstant"];
    [anEncoder encodeBool: slidingScaleEnable     forKey:@"slidingScaleEnable"];
    [anEncoder encodeBool: zeroSuppressThresRes   forKey:@"zeroSuppressThresRes"];
    [anEncoder encodeBool: zeroSuppressEnable     forKey:@"zeroSuppressEnable"];
    [anEncoder encodeBool: overflowSuppressEnable forKey:@"overflowSuppressEnable"];
}

@end

@implementation ORCaen862DecoderForCAEN : ORCaenDataDecoder
- (NSString*) identifier
{
    return @"CAEN 862 QDC";
}
@end

