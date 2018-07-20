/*
 *  ORShaperModel.cpp
 *  Orca
 *
 *  Created by Mark Howe on Sat Nov 16 2002.
 *  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
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
#pragma mark ¥¥¥Imported Files
#import "ORShaperModel.h"

#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORAxis.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORDataTypeAssigner.h"
#include "VME_HW_Definitions.h"
#import <sys/timeb.h>

#pragma mark ¥¥¥Definitions
#define kDefaultAddressModifier			0x29
#define kDefaultBaseAddress				0x00008000
#define kDefaultVThreshold_1_4_Value  	0x3f	// 400 mV default
#define kDefaultVThreshold_5_8_Value  	0x3f	// 400 mV default
#define kMaxConversionTime  			.0333

#define kDefaultGain					0xff	// 532 Ohm default

#define    	kScalersEnabledBit 			0x01
#define   	kMultiBoardEnabledBit 		0x02

#pragma mark ¥¥¥Static Declarations
//offsets from the base address (kDefaultBaseAddress)
static uint32_t register_offsets[kNumberOfADCSRegisters] = {
0x1f,		// [0]  kConversionStatusRegister
0x1d,		// [1]	kModeSelectRegister
0x1b,		// [2]  kThresholdAddressRegister
0x13,		// [3]  kGain1Register
0x19,		// [4]  kThresholdReadRegister
0x03,		// [5]  kFastClearRegister
0x01,		// [6]	kResetRegister
0x09,		// [7]  kScalerEnableRegister
0x0f,		// [8]	kScalerSelectionRegister
0x0b,		// [9]	kScalarClearRegister
0x0d,		// [10]	kDiscrimOutputEnableRegister
0x1f,		// [11]	kMiscRegister
0x00,		// [12]	kADC1OutputRegister
0x02,		// [13]	kADC2OutputRegister
0x04,		// [14]	kADC3OutputRegister
0x06,		// [15]	kADC4OutputRegister
0x08,		// [16]	kADC5OutputRegister
0x0a,		// [17]	kADC6OutputRegister
0x0c,		// [18]	kADC7OutputRegister
0x0e,		// [19]	kADC8OutputRegister
0x15,		// [20]	kGainWriteRegister
0x31,		// [21] kGainReadRegister
0x07,		// [22] kThreshold_1_4_Register
0x05,		// [23] kThreshold_5_8_Register
0x33,		// [24] kThresholdConversionRegister
0x12,		// [25] kOverAllCounter1
0x14,		// [26] kOverAllCounter2
0x20,		// [27] kScaler1
0x22,		// [28] kScaler2
0x24,		// [29] kScaler3
0x26,		// [30] kScaler4
0x28,		// [31] kScaler5
0x2a,		// [32] kScaler6
0x2c,		// [33] kScaler7
0x2e,		// [34] kScaler8
0x10,		// [35]	kBoardIdRegister
0x1b,		// [36] kDacAddressMonitor
0x16,		// [37] kFloatingCounterMonitor
};


//all reg defs should come from ADCS
static unsigned short kThreshWriteSelectionBits[8]={
0x00,	//sel VT1
0x01,	//sel VT2
0x02,	//sel VT3
0x03,	//sel VT4
0x00,	//sel VT5
0x04,	//sel VT6
0x08,	//sel VT7
0x0C	//sel VT8
};



#pragma mark ¥¥¥Notification Strings
NSString* ORShaperModelShipTimeStampChanged				= @"ORShaperModelShipTimeStampChanged";
NSString* ORShaperChan									= @"Shaper Channel Value";
NSString* ORShaperThresholdArrayChangedNotification		= @"Shaper Thresholds Array Changed Notification";
NSString* ORShaperThresholdAdcArrayChangedNotification	= @"Shaper Threshold Adc Array Changed Notification";
NSString* ORShaperGainArrayChangedNotification			= @"Shaper Gains Array Changed Notification";
NSString* ORShaperThresholdChangedNotification			= @"Shaper Threshold Value Changed Notification";
NSString* ORShaperThresholdAdcChangedNotification		= @"Shaper Threshold Adc Value Changed Notification";
NSString* ORShaperGainChangedNotification				= @"Shaper Gain Value Changed Notification";
NSString* ORShaperContinousChangedNotification			= @"Shaper Continous Changed Notification";
NSString* ORShaperScalersEnabledChangedNotification		= @"Shaper Scalers Enabled Changed Notification";
NSString* ORShaperMultiBoardEnabledChangedNotification	= @"Shaper MultiBoard Changed Notification";
NSString* ORShaperScalerMaskChangedNotification			= @"Shaper Scaler Mask Changed Notification";
NSString* ORShaperOnlineMaskChangedNotification			= @"Shaper Online Mask Changed Notification";

NSString* ORShaperScanStartChangedNotification			= @"Shaper ScanStart Changed Notification";
NSString* ORShaperScanDeltaChangedNotification			= @"Shaper ScanDelta Changed Notification";
NSString* ORShaperScanNumChangedNotification			= @"Shaper ScanNum Changed Notification";

NSString* ORShaperScalerGroupChangedNotification		= @"ORShaperScalerGroupChangedNotification";
NSString* ORShaperRateGroupChangedNotification			= @"ORShaperRateGroupChangedNotification";

NSString* ORShaperDisplayRawChangedNotification			= @"ORShaperDisplayRawChangedNotification";
NSString* ORShaperSettingsLock							= @"ORShaperSettingsLock";

@implementation ORShaperModel

- (id) init //designated initializer
{
    short i;
    self = [super init];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setThresholds:[NSMutableArray arrayWithCapacity:kNumShaperChannels]];
    [self setThresholdAdcs:[NSMutableArray arrayWithCapacity:kNumShaperChannels]];
    [self setGains:[NSMutableArray arrayWithCapacity:kNumShaperChannels]];
	
    for(i=0;i<kNumShaperChannels;i++){
        [thresholds addObject:[NSNumber numberWithInt:50]];
        [thresholdAdcs addObject:[NSNumber numberWithInt:0]];
        [gains addObject:[NSNumber numberWithInt:100]];
    }
	
    [self setBaseAddress:kDefaultBaseAddress];
    [self setAddressModifier:kDefaultAddressModifier];
	[self setOnlineMask:0xff];
	
	[self setAdcRateGroup:[[[ORRateGroup alloc] initGroup:kNumShaperChannels groupTag:0] autorelease]];
	[self setScalerRateGroup:[[[ORRateGroup alloc] initGroup:kNumShaperChannels groupTag:1] autorelease]];
	
	[adcRateGroup setIntegrationTime:5];
	[scalerRateGroup setIntegrationTime:5];
	
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    [adcRateGroup quit];
    [scalerRateGroup quit];
	[thresholdAdcs release];
    [thresholds release];
    [gains release];
    [adcRateGroup release];
    [scalerRateGroup release];
    [super dealloc];
}

- (void) setUpImage
{
    //---------------------------------------------------------------------------------------------------
    //arghhh....NSImage caches one image. The NSImage setCachMode:NSImageNeverCache appears to not work.
    //so, we cache the image here so that each crate can have its own version for drawing into.
    //---------------------------------------------------------------------------------------------------
    NSImage* aCachedImage = [NSImage imageNamed:@"ShaperCard"];
    NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
    [i lockFocus];
    [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositingOperationSourceOver fraction:1.0];	
    int chan;
    for(chan=0;chan<kNumShaperChannels;chan++){
		NSBezierPath* circle = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(6,12+chan*12.5,7,7)];
		if(onlineMask & (1<<(kNumShaperChannels-chan-1)))[[NSColor colorWithCalibratedRed:0. green:.7 blue:0. alpha:.5] set];
		else			  [[NSColor colorWithCalibratedRed:0.7 green:0. blue:0. alpha:.5] set];
		[circle fill];
		[[NSColor blackColor] set];
		[circle stroke];
    }
    [i unlockFocus];		
    [self setImage:i];
    [i release];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:OROrcaObjectImageChanged
	 object:self];
	
}


- (void) makeMainController
{
    [self linkToController:@"ORShaperController"];
}

- (NSString*) helpURL
{
	return @"VME/Shaper.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x2e);
}

#pragma mark ¥¥¥Accessors

- (BOOL) shipTimeStamp
{
    return shipTimeStamp;
}

- (void) setShipTimeStamp:(BOOL)aShipTimeStamp
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipTimeStamp:shipTimeStamp];
    shipTimeStamp = aShipTimeStamp;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORShaperModelShipTimeStampChanged object:self];
}

- (NSMutableArray*) thresholds
{
    return thresholds;
}

- (void) setThresholds:(NSMutableArray*)someThresholds
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThresholds:[self thresholds]];
	
    [someThresholds retain];
    [thresholds release];
    thresholds = someThresholds;
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperThresholdArrayChangedNotification
	 object:self];
}

- (NSMutableArray*) thresholdAdcs
{
    return thresholdAdcs;
}

- (void) setThresholdAdcs:(NSMutableArray*)someThresholdAdcs
{
    //[[[self undoManager] prepareWithInvocationTarget:self] setThresholdAdcs:[self thresholdAdcs]];
    
    [someThresholdAdcs retain];
    [thresholdAdcs release];
    thresholdAdcs = someThresholdAdcs;
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperThresholdAdcArrayChangedNotification
	 object:self];
}

- (NSMutableArray*) gains
{
    return gains;
}

- (void) setGains:(NSMutableArray*)someGains
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGains:[self gains]];
	
    [someGains retain];
    [gains release];
    gains = someGains;
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperGainArrayChangedNotification
	 object:self];
}

-(unsigned short)threshold:(unsigned short) aChan
{
    return [[thresholds objectAtIndex:aChan] shortValue];
}

-(unsigned short)thresholdAdc:(unsigned short) aChan
{
    return [[thresholdAdcs objectAtIndex:aChan] shortValue];
}

-(unsigned short)gain:(unsigned short) aChan
{
    return [[gains objectAtIndex:aChan] shortValue];
}


-(void) setThreshold:(unsigned short) aChan withValue:(unsigned short) aThreshold
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aThreshold]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORShaperChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperThresholdChangedNotification
	 object:self
	 userInfo: userInfo];
	
	
	[self postAdcInfoProvidingValueChanged];
	
}

- (void) postAdcInfoProvidingValueChanged
{
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORAdcInfoProvidingValueChanged
	 object:self
	 userInfo: nil];
}


-(void) setThresholdAdc:(unsigned short) aChan withValue:(unsigned short) aThreshold
{
	if(aThreshold>1200)aThreshold = 1200;
    [thresholdAdcs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aThreshold]];
    
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORShaperChan];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperThresholdAdcChangedNotification
	 object:self
	 userInfo: userInfo];
}


- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain
{
	if(aGain>255)aGain = 255;
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:aChan withValue:[self gain:aChan]];
	[gains replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aGain]];
	
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:[NSNumber numberWithInt:aChan] forKey: ORShaperChan];
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperGainChangedNotification
	 object:self
	 userInfo: userInfo];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

- (BOOL) continous
{
    return continous;
}

- (void) setContinous:	(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setContinous:[self continous]];
    continous = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperContinousChangedNotification
	 object:self];
}

- (BOOL) scalersEnabled
{
    return scalersEnabled;
	
}

- (void) setScalersEnabled:	(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setScalersEnabled:[self scalersEnabled]];
    scalersEnabled = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperScalersEnabledChangedNotification
	 object:self];
}

- (BOOL) multiBoardEnabled
{
    return multiBoardEnabled;
	
}

- (void) setMultiBoardEnabled:	(BOOL)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMultiBoardEnabled:[self multiBoardEnabled]];
    multiBoardEnabled = aValue;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperMultiBoardEnabledChangedNotification
	 object:self];
	
}


- (unsigned char) scalerMask
{
    return scalerMask;
}

- (BOOL)scalerMaskBit:(int)bit
{
	return scalerMask&(1<<bit);
}

- (unsigned short) scalerCount:(unsigned short)chan
{
	if(chan < kNumShaperChannels){
		return scalerCount[chan];
	}
	else return 0;
}


- (void) setScalerMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned char aMask = scalerMask;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setScalerMask:aMask];
}


-(void)setScalerMask:(unsigned char) aScalerMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setScalerMask:[self scalerMask]];
    scalerMask = aScalerMask;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperScalerMaskChangedNotification
	 object:self];
}

- (unsigned char)onlineMask {
	
    return onlineMask;
}

- (void)setOnlineMask:(unsigned char)anOnlineMask {
    [[[self undoManager] prepareWithInvocationTarget:self] setOnlineMask:[self onlineMask]];
	
    onlineMask = anOnlineMask;
	
    [self setUpImage];
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperOnlineMaskChangedNotification
	 object:self];
	
}

- (BOOL)onlineMaskBit:(int)bit
{
	return onlineMask&(1<<bit);
}

- (void) setOnlineMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned char aMask = onlineMask;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setOnlineMask:aMask];
	
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

- (uint32_t) scanStart
{
    return scanStart;
}

- (void) setScanStart:(uint32_t)value
{
	[[[self undoManager] prepareWithInvocationTarget:self] setScanStart:[self scanStart]];
    scanStart = value;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperScanStartChangedNotification
	 object:self];
}

- (uint32_t) scanDelta
{
    return scanDelta;
}

- (void) setScanDelta:(uint32_t)value
{
	[[[self undoManager] prepareWithInvocationTarget:self] setScanDelta:[self scanDelta]];
    scanDelta = value;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperScanDeltaChangedNotification
	 object:self];
}

- (unsigned short) scanNumber
{
    return scanNumber;
}

- (void) setScanNumber:(unsigned short)value
{
    if(value==0)value = 1;
    else if(value>16)value = 16;
    [[[self undoManager] prepareWithInvocationTarget:self] setScanNumber:[self scanNumber]];
    scanNumber = value;
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperScanNumChangedNotification
	 object:self];    
}

- (id) rateObject:(int)channel
{
	return [adcRateGroup rateObject:channel];
}

- (ORRateGroup*) adcRateGroup
{
	return adcRateGroup;
}
- (void) setAdcRateGroup:(ORRateGroup*)newAdcRateGroup
{
	[newAdcRateGroup retain];
	[adcRateGroup release];
	adcRateGroup = newAdcRateGroup;
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperRateGroupChangedNotification
	 object:self];    
}


- (ORRateGroup*) scalerRateGroup
{
	return scalerRateGroup;
}
- (void) setScalerRateGroup:(ORRateGroup*)newScalerRateGroup
{
	[newScalerRateGroup retain];
	[scalerRateGroup release];
	scalerRateGroup=newScalerRateGroup;
	
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperScalerGroupChangedNotification
	 object:self];    
}



- (void) setIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setIntegrationTime:[adcRateGroup integrationTime]];
	[adcRateGroup setIntegrationTime:newIntegrationTime];
}


- (BOOL) displayRaw
{
	return displayRaw;
}
- (void) setDisplayRaw:(BOOL)newDisplayRaw
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDisplayRaw:displayRaw];
	displayRaw=newDisplayRaw;
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORShaperDisplayRawChangedNotification
	 object:self];    
}

- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

- (uint32_t) scalerDataId { return scalerDataId; }
- (void) setScalerDataId: (uint32_t) ScalerDataId
{
    scalerDataId = ScalerDataId;
}


#pragma mark ¥¥¥Compound Accessors
-(unsigned char)modeMask
{
    return [self continous]?0xff:0x00;
}

- (unsigned char) miscRegister
{
    unsigned char value = 0;
	
    if([self scalersEnabled])	value |= kScalersEnabledBit;
    if([self multiBoardEnabled])value |= kMultiBoardEnabledBit;
    return value;
}


#pragma mark ¥¥¥Hardware Access
- (void) initBoard
{
    [self writeReset:0];
    [self writeMiscReg:[self miscRegister]];	//must setup the Miscreg because a reset clears it
    [self writeFastClear:0];			//do a fast clear
    [self writeScalerClear:0];			//clear the global scaler values
    [self writeMode:[self modeMask]];
    [self writeScalerEnable:[self scalerMask]];
	[self loadThresholdsAndGains];
}

- (void) loadThresholdsAndGains
{
    [self loadThresholds];
    [self readThresholds];
    [self loadGains];
    //NSLog(@"Loaded constants for Shaper (Slot %d <%p>)\n",[self slot],[self baseAddress]);
}

//---------------------------------------------------------------------------------
// writeGain
//		write a value to one of the gain registers
//---------------------------------------------------------------------------------
-(void) writeGain:(unsigned short) aChannel
        withValue:(unsigned char) aValue
{
    [self selectGainReg:aChannel];
    [self writeGainReg:aValue];
}

//---------------------------------------------------------------------------------
// readGain
//		read one of the gain registers
//---------------------------------------------------------------------------------
-(unsigned char) readGain:(unsigned short) aChannel
{
    [self selectGainReg:aChannel];
    return [self readGainReg];
}

//---------------------------------------------------------------------------------
// writeThreshold
//		write a value to one of the threshold registers
//---------------------------------------------------------------------------------
-(void) writeThreshold:(unsigned short) aChannel withValue:(unsigned char) aValue
{
    [self setThresholdAddress:aChannel];
    if(aChannel<4)	[self writeThres1_4:aValue];
    else 			[self writeThres5_8:aValue];
}

//---------------------------------------------------------------------------------
// loadThresholds
//      write out the thresholds to hw.
//---------------------------------------------------------------------------------
- (void) loadThresholds
{
    short chan;
    for(chan = 0;chan<kNumShaperChannels;chan++){
        [self writeThreshold:chan withValue:[[thresholds objectAtIndex:chan] shortValue]];
    }
}


//---------------------------------------------------------------------------------
// readThresholds
//      read out the thresholds from hw.
//---------------------------------------------------------------------------------
- (void) readThresholds
{
    short chan;
    for(chan = 0;chan<kNumShaperChannels;chan++){
        [self readThreshold:chan];
		
    }
}

//---------------------------------------------------------------------------------
// loadGains
//		load the gains to hw.
//---------------------------------------------------------------------------------
- (void) loadGains
{
    short chan;
    for(chan = 0;chan<kNumShaperChannels;chan++){
        [self writeGain:chan withValue:[[gains objectAtIndex:chan] shortValue]];
    }
}



//---------------------------------------------------------------------------------
// readThreshold
//		read one of the threshold registers
//---------------------------------------------------------------------------------
-(unsigned char) readThreshold:(unsigned short) aChannel
{
    NSTimeInterval startTime;
    [self selectThresholdReg:aChannel];
    [self readThresholdConversion];					//initiate a conversion
    startTime = [NSDate timeIntervalSinceReferenceDate];
    while(true){										//wait for the conversion
        if(!([self readThresholdReg] & 0x01))break;					//done?
        else if([NSDate timeIntervalSinceReferenceDate] - startTime > kMaxConversionTime){
			[self setThresholdAdc:aChannel withValue:0];
            return 0;
        }
    }
    unsigned char value = [self readThresholdConversion];
    [self setThresholdAdc:aChannel withValue:value];
    return value;
}

- (unsigned char)	readConversionReg
{
    unsigned char aValue = 0;
    [[self adapter] readByteBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kConversionStatusRegister]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return aValue;
}

- (unsigned short) 	readAdc:(unsigned short) aChan
{
    unsigned short aValue = 0;
	
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kADC1OutputRegister+aChan]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
    return aValue;
}

- (unsigned short) 	readBoardID
{
    unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kBoardIdRegister]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	
    return aValue;
}

- (unsigned short) 	readScaler:(unsigned short) aChan
{
    unsigned short aValue = 0;
	if(aChan<kNumShaperChannels){
		[[self adapter] readWordBlock:&aValue
							atAddress:[self baseAddress]+register_offsets[kScaler1+aChan]
							numToRead:1
						   withAddMod:[self addressModifier]
						usingAddSpace:0x01];
		scalerCount[aChan] = aValue;
	}
    return aValue;
}

- (void) readScalers
{
    [[self adapter] readWordBlock:scalerCount
						atAddress:[self baseAddress]+register_offsets[kScaler1]
						numToRead:kNumShaperChannels
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
}


- (unsigned char)   readThresholdConversion
{
    unsigned char aValue = 0;
    [[self adapter] readByteBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kThresholdConversionRegister]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return aValue;
}

- (unsigned char) 	readThresholdReg
{
    unsigned char aValue = 0;
    [[self adapter] readByteBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kThresholdReadRegister]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return aValue;
}

- (void)writeFastClear:(unsigned char) aVal
{
    [[self adapter] writeByteBlock:&aVal
						 atAddress:[self baseAddress]+register_offsets[kFastClearRegister]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void)writeMode:(unsigned char) aVal
{
    [[self adapter] writeByteBlock:&aVal
						 atAddress:[self baseAddress]+register_offsets[kModeSelectRegister]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void)writeScalerEnable:(unsigned char) aVal
{
    [[self adapter] writeByteBlock:&aVal
						 atAddress:[self baseAddress]+register_offsets[kScalerEnableRegister]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void)writeReset:(unsigned char) aVal
{
    [[self adapter] writeByteBlock:&aVal
						 atAddress:[self baseAddress]+register_offsets[kResetRegister]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void)writeMiscReg:(unsigned char) aVal
{
    [[self adapter] writeByteBlock:&aVal
						 atAddress:[self baseAddress]+register_offsets[kMiscRegister]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void)writeScalerSelect:(unsigned char) aVal
{
    [[self adapter] writeByteBlock:&aVal
						 atAddress:[self baseAddress]+register_offsets[kScalerSelectionRegister]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void)writeScalerClear:(unsigned char) aVal
{
    [[self adapter] writeByteBlock:&aVal
						 atAddress:[self baseAddress]+register_offsets[kScalarClearRegister]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
	
    short i;
    for(i=0;i<kNumShaperChannels;i++)scalerCount[i]=0;
}

- (void) writeDiscriminatorEnable:(unsigned char) aVal
{
    [[self adapter] writeByteBlock:&aVal
						 atAddress:[self baseAddress]+register_offsets[kDiscrimOutputEnableRegister]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}


- (unsigned char)  readAdcDac
{
    unsigned char aValue = 0;
    [[self adapter] readByteBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kDacAddressMonitor]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return aValue;
}

- (unsigned short) readCounter1
{
    unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kOverAllCounter1]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return aValue;
}

- (unsigned short) readCounter2
{
    unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kOverAllCounter2]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return aValue;
}

- (unsigned short) readFloatingCounter
{
    unsigned short aValue = 0;
    [[self adapter] readWordBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kOverAllCounter2]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return aValue;
}


- (void) writeThres1_4:(unsigned char) aVal
{
    [[self adapter] writeByteBlock:&aVal
						 atAddress:[self baseAddress]+register_offsets[kThreshold_1_4_Register]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) writeThres5_8:(unsigned char) aVal
{
    [[self adapter] writeByteBlock:&aVal
						 atAddress:[self baseAddress]+register_offsets[kThreshold_5_8_Register]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) selectThresholdReg:(unsigned char) aChan
{
    [[self adapter] writeByteBlock:&aChan
						 atAddress:[self baseAddress]+register_offsets[kThresholdReadRegister]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) selectGainReg:(unsigned char) aChan
{
    unsigned char aVal = 0x01<<aChan;
    [[self adapter] writeByteBlock:&aVal
						 atAddress:[self baseAddress]+register_offsets[kGain1Register]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) setThresholdAddress:(unsigned char) aChan
{
    unsigned char aVal = kThreshWriteSelectionBits[aChan];
    [[self adapter] writeByteBlock:&aVal
						 atAddress:[self baseAddress]+register_offsets[kThresholdAddressRegister]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (void) writeGainReg:(unsigned char) aChan
{
    [[self adapter] writeByteBlock:&aChan
						 atAddress:[self baseAddress]+register_offsets[kGainWriteRegister]
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];
}

- (unsigned char) readGainReg
{
    unsigned char aValue = 0;
    [[self adapter] readByteBlock:&aValue
						atAddress:[self baseAddress]+register_offsets[kGainReadRegister]
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
    return aValue;
}

-(unsigned short)thresholdmV:(unsigned short) aChan
{
    return [self thresholdRawtomV:[self threshold:aChan]];
}

-(void) setThresholdmV:(unsigned short) aChan withValue:(unsigned short) aThreshold
{
    [self setThreshold:aChan withValue:[self thresholdmVtoRaw:aThreshold]];
}



-(unsigned short)thresholdmVtoRaw:(unsigned short) aValueInMV
{
    return (unsigned short) (((aValueInMV + 6.2)/6.45)+.5) ;
}

-(unsigned short)thresholdRawtomV:(unsigned short) aRawValue
{
    if(aRawValue == 0)return 0;
    else return (unsigned short) (((aRawValue * 6.45) - 6.2)+.5) ;
}

- (void) saveAllThresholds
{
    short chan;
    for(chan = 0;chan<kNumShaperChannels;chan++){
        savedThresholds[chan] = [[thresholds objectAtIndex:chan] shortValue];
    }
}

- (void) restoreAllThresholds
{
    short chan;
    for(chan = 0;chan<kNumShaperChannels;chan++){
		[self setThreshold:chan withValue:savedThresholds[chan]];      
    }
}

- (void) setAllThresholdsTo:(NSNumber*)mvValue
{
    short chan;
    for(chan = 0;chan<kNumShaperChannels;chan++){
        [self setThresholdmV:chan withValue:[mvValue shortValue]];
    }
}

#pragma mark ¥¥¥Board ID Decoders
-(NSString*) boardIdString
{
    unsigned short aBoardId = [self readBoardID];
    unsigned short id       = [self decodeBoardId:aBoardId];
    unsigned short type     = [self decodeBoardType:aBoardId];
    unsigned short rev      =  [self decodeBoardRev:aBoardId];
    NSString* name	    = [NSString stringWithString:[self decodeBoardName:aBoardId]];
	
    return [NSString stringWithFormat:@"id:%d type:%d rev:%d name:%@",id,type,rev,name];
}


-(unsigned short) decodeBoardId:(unsigned short) aBoardIDWord
{
    return aBoardIDWord & 0x00FF;
}

-(unsigned short) decodeBoardType:(unsigned short) aBoardIDWord
{
    return (aBoardIDWord & 0x0700) >> 8;
}

-(unsigned short) decodeBoardRev:(unsigned short) aBoardIDWord
{
    return (aBoardIDWord & 0xF800) >> 11;	// updated to post Jan 02 definitions
}

-(NSString*) decodeBoardName:(unsigned short) aBoardIDWord
{
    switch(	[self decodeBoardType:aBoardIDWord] ) {
        case 0: 	return @"Test";
        case 1: 	return @"EMIT";
        case 2: 	return @"NCD";
        case 3: 	return @"Time Tag";
        case 5: 	return @"KATRIN";
        default: 	return @"Unknown";
    }
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	int len;
	if(shipTimeStamp) len = 4;
	else {
		if(IsShortForm(dataId))len = 1;
		else len = 2;
	}
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORShaperDecoderForShaper",               @"decoder",
								 [NSNumber numberWithLong:dataId],          @"dataId",
								 [NSNumber numberWithBool:NO],              @"variable",
								 [NSNumber numberWithLong:len],				@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Shaper"];
 	
	
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORShaperDecoderForScalers",			    @"decoder",
				   [NSNumber numberWithLong:scalerDataId],     @"dataId",
				   [NSNumber numberWithBool:YES],              @"variable",
				   [NSNumber numberWithLong:-1],               @"length",
				   nil];
    [dataDictionary setObject:aDictionary forKey:@"Scaler"];
    return dataDictionary;
}

- (void) appendEventDictionary:(NSMutableDictionary*)anEventDictionary topLevel:(NSMutableDictionary*)topLevel
{
	NSDictionary* aDictionary;
	aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"Adc",								@"name",
				   [NSNumber numberWithLong:dataId],	@"dataId",
				   [NSNumber numberWithLong:8],			@"maxChannels",
				   nil];
	
	[anEventDictionary setObject:aDictionary forKey:@"Shaper"];
}


- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	
    if(![[self adapter] controllerCard]){
		[NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
	
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORShaperModel"];    
    
    //----------------------------------------------------------------------------------------
    controller = [[self adapter] controllerCard]; //cache the controller for alittle bit more speed.
    slotMask   =  (([self crateNumber]&0xf)<<21) | (([self slot]& 0x1f)<<16);
	
    [self clearExceptionCount];
	
	[self initBoard];
    if([[(NSDictionary*)userInfo objectForKey:@"doinit"]intValue]){
		[self loadThresholdsAndGains];
    }
	
    [self startRates];
	isRunning = NO;
    
    [self timedShipScalers];
    
}

//**************************************************************************************
// Function:	TakeData
// Description: Read data from a card
//**************************************************************************************
-(void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	isRunning = YES;
	
    NSString* errorLocation = @"";
    @try {
		unsigned char theConversionMask = 0;
		errorLocation = @"Reading Conversion Mask";
		[controller readByteBlock:&theConversionMask
						atAddress:baseAddress+register_offsets[kConversionStatusRegister]
						numToRead:1
					   withAddMod:addressModifier
					usingAddSpace:0x01];
		
		
		if(theConversionMask){
            if(theConversionMask == 0xff){
                [controller readByteBlock:&theConversionMask
								atAddress:baseAddress+register_offsets[kConversionStatusRegister]
								numToRead:1
							   withAddMod:addressModifier
							usingAddSpace:0x01];
            }
            
			short channel;
			errorLocation = @"Reading Adc";
			for (channel=0; channel<kNumShaperChannels; ++channel) {
				unsigned char chanMask = (1L<<channel) & onlineMask;
				if(theConversionMask & chanMask){
					
					unsigned short aValue;
					
					[controller readWordBlock:&aValue
									atAddress:baseAddress+register_offsets[kADC1OutputRegister+channel]
									numToRead:1
								   withAddMod:addressModifier
								usingAddSpace:0x01];
					
                    
                    if(IsShortForm(dataId)){
                        uint32_t data = dataId | slotMask | ((channel & 0x0000000f) << 12) | (aValue & 0x0fff);
                        [aDataPacket addLongsToFrameBuffer:&data length:1];
                    }
                    else {
                        uint32_t data[4];
						short len = 2;
						if(shipTimeStamp) {
							len = 4;
                            /*
							struct timeb mt;
							if (ftime(&mt) == 0) {
								data[2] = mt.time;
								data[3] = mt.millitm;
							}
							else {
								data[2] = 0xffffffff;
								data[3] = 0xffffffff;
							}
                             */
                            struct timeval ts;
                            if(gettimeofday(&ts,NULL) ==0){
  								data[2] = (uint32_t)ts.tv_sec;
								data[3] = (uint32_t)ts.tv_usec;
                            }
							else {
								data[2] = 0xFFFFFFFF;
								data[3] = 0xFFFFFFFF;
							}

						}
						data[0] = dataId | len;
                        data[1] =  slotMask | ((channel & 0x0000000f) << 12) | (aValue & 0x0fff);

                        [aDataPacket addLongsToFrameBuffer:data length:len];
                    }
										
					++adcCount[channel]; 
					++eventCount[channel];
				}
			}
		}
	}
	@catch(NSException* localException) {
		NSLogError(@"",@"Shaper Card Error",errorLocation,nil);
		[self incExceptionCount];
		[localException raise];
	}
}


- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [adcRateGroup stop];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timedShipScalers) object:nil];
    [self shipScalerRecords];
    [self initBoard];
	isRunning = NO;
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
	if(isRunning)return NO;
	++eventCount[channel];
    ++adcCount[channel];
    return YES;
}

- (uint32_t) adcCount:(int)aChannel
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
    for(i=0;i<kNumShaperChannels;i++){
		adcCount[i]=0;
    }
}

- (void) reset
{
	[self initBoard]; 
	[self loadThresholdsAndGains];
    
}

//this is the obsolete data structure for the VME147
- (int) load_eCPU_HW_Config_Structure:(VME_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id = 'SHPR';			//should be unique
	configStruct->card_info[index].hw_mask[0] 	 = dataId;	//better be unique
	configStruct->card_info[index].slot 	 = [self slot];
	configStruct->card_info[index].add_mod 	 = [self addressModifier];
	configStruct->card_info[index].base_add  = [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0] = onlineMask;
	
	configStruct->card_info[index].num_Trigger_Indexes = 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}


//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id = kShaper; //should be unique
	configStruct->card_info[index].hw_mask[0] = dataId; //better be unique
	configStruct->card_info[index].slot 	  = [self slot];
	configStruct->card_info[index].crate 	  = [self crateNumber];
	configStruct->card_info[index].add_mod 	  = [self addressModifier];
	configStruct->card_info[index].base_add   = [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0] = onlineMask;
	configStruct->card_info[index].deviceSpecificData[1] = register_offsets[kConversionStatusRegister];
	configStruct->card_info[index].deviceSpecificData[2] = register_offsets[kADC1OutputRegister];
	configStruct->card_info[index].deviceSpecificData[3] = shipTimeStamp;
	configStruct->card_info[index].num_Trigger_Indexes = 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

#pragma mark ¥¥¥Rates
- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumShaperChannels){
			return adcCount[counterTag];
		}	
		else return 0;
	}
	else if(groupTag == 1){
		if(counterTag>=0 && counterTag<kNumShaperChannels){
			return scalerCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}

#pragma mark ¥¥¥Archival
static NSString *ORShaperThresholds 		= @"Shaper Thresholds Array";
static NSString *ORShaperThresholdAdcs 		= @"Shaper ThresholdAdcs Array";
static NSString *ORShaperGains				= @"Shaper Gains Array";
static NSString *ORShaperContinous			= @"Shaper Continous";
static NSString *ORShaperScalersEnabled 	= @"Shaper Scalers Enabled";
static NSString *ORShaperMultiBoardEnabled 	= @"Shaper MultiBoard Enabled";
static NSString *ORShaperScalerMask			= @"Shaper Scaler Enabled Mask";
static NSString *ORShaperOnlineMask			= @"Shaper Online Mask";

static NSString *ORShaperScanStart			= @"ORShaper Scan Start";
static NSString *ORShaperScanDelta			= @"ORShaper Scan Delta";
static NSString *ORShaperScanNumber			= @"ORShaper Scan Number";
static NSString *ORShaperAdcRateGroup		= @"ORShaper Rate Group";

static NSString *ORShaperDisplayRaw 		= @"ORShaper DisplayRaw";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
	
    [[self undoManager] disableUndoRegistration];
	
    [self setShipTimeStamp:		[decoder decodeBoolForKey:@"shipTimeStamp"]];
    [self setThresholds:		[decoder decodeObjectForKey:ORShaperThresholds]];
    [self setThresholdAdcs:		[decoder decodeObjectForKey:ORShaperThresholdAdcs]];
    [self setGains:				[decoder decodeObjectForKey:ORShaperGains]];
    [self setContinous:			[decoder decodeBoolForKey:ORShaperContinous]];
    [self setScalersEnabled:	[decoder decodeBoolForKey:ORShaperScalersEnabled]];
    [self setMultiBoardEnabled:	[decoder decodeBoolForKey:ORShaperMultiBoardEnabled]];
    [self setScalerMask:		[decoder decodeIntegerForKey:ORShaperScalerMask]];
    if([decoder containsValueForKey:ORShaperOnlineMask]){
		[self setOnlineMask:[decoder decodeIntegerForKey:ORShaperOnlineMask]];
    }
    else {
		[self setOnlineMask:0xff];
    }
    [self setScanStart:[decoder decodeIntForKey:ORShaperScanStart]];
    [self setScanDelta:[decoder decodeIntForKey:ORShaperScanDelta]];
    [self setScanNumber:[decoder decodeIntegerForKey:ORShaperScanNumber]];
	
    [self setAdcRateGroup:[decoder decodeObjectForKey:ORShaperAdcRateGroup]];
    [self setDisplayRaw:[decoder decodeBoolForKey:ORShaperDisplayRaw]];
	
    if(!adcRateGroup){
	    [self setAdcRateGroup:[[[ORRateGroup alloc] initGroup:kNumShaperChannels groupTag:0] autorelease]];
	    [adcRateGroup setIntegrationTime:5];
    }
    [self startRates];
    [adcRateGroup resetRates];
    [adcRateGroup calcRates];
	
	
    if(!thresholdAdcs){
		[self setThresholdAdcs:[NSMutableArray arrayWithCapacity:kNumShaperChannels]];
		
		int i;
		for(i=0;i<kNumShaperChannels;i++){
			[thresholdAdcs addObject:[NSNumber numberWithInt:0]];
		}
    }
	
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:shipTimeStamp			forKey:@"shipTimeStamp"];
    [encoder encodeObject:[self thresholds]		forKey:ORShaperThresholds];
    [encoder encodeObject:[self thresholdAdcs]	forKey:ORShaperThresholdAdcs];
    [encoder encodeObject:[self gains]			forKey:ORShaperGains];
    [encoder encodeBool:[self continous]		forKey:ORShaperContinous];
    [encoder encodeBool:[self scalersEnabled]	forKey:ORShaperScalersEnabled];
    [encoder encodeBool:[self multiBoardEnabled] forKey:ORShaperMultiBoardEnabled];
    [encoder encodeInteger:[self scalerMask]		forKey:ORShaperScalerMask];
    [encoder encodeInteger:[self onlineMask]		forKey:ORShaperOnlineMask];
	
    [encoder encodeInt:[self scanStart]		forKey:ORShaperScanStart];
    [encoder encodeInt:[self scanDelta]			forKey:ORShaperScanDelta];
    [encoder encodeInteger:[self scanNumber]		forKey:ORShaperScanNumber];
	
    [encoder encodeObject:[self adcRateGroup] forKey:ORShaperAdcRateGroup];
	
    [encoder encodeBool:[self displayRaw] forKey:ORShaperDisplayRaw];
	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    [objDictionary setObject:thresholds forKey:@"thresholds"];
    [objDictionary setObject:thresholdAdcs forKey:@"thresholdAdcs"];
    [objDictionary setObject:gains forKey:@"gains"];
    [objDictionary setObject:[NSNumber numberWithInt:scalerMask] forKey:@"scalerMask"];
    [objDictionary setObject:[NSNumber numberWithInt:onlineMask] forKey:@"onlineMask"];
    [objDictionary setObject:[NSNumber numberWithBool:continous] forKey:@"continous"];
    [objDictionary setObject:[NSNumber numberWithBool:scalersEnabled] forKey:@"scalersEnabled"];
    [objDictionary setObject:[NSNumber numberWithBool:multiBoardEnabled] forKey:@"multiBoardEnabled"];
    [objDictionary setObject:[NSNumber numberWithBool:shipTimeStamp] forKey:@"shipTimeStamp"];
    
    @try {
        unsigned short aValue;
        [[self adapter] readWordBlock:&aValue
                            atAddress:[self baseAddress]+register_offsets[kBoardIdRegister]
                            numToRead:1
                           withAddMod:[self addressModifier]
                        usingAddSpace:0x01];
        
        [objDictionary setObject:[NSNumber numberWithInt:[self decodeBoardId:aValue]] forKey:@"Id"];
        [objDictionary setObject:[NSNumber numberWithInt:[self decodeBoardType:aValue]]  forKey:@"Type"];
        [objDictionary setObject:[NSNumber numberWithInt:[self decodeBoardRev:aValue]]   forKey:@"Rev"];
        
    }
	@catch(NSException* localException) {
	}
	
	return objDictionary;
}

#pragma mark ¥¥¥Specialized storage methods
- (NSData*) gainMemento
{
    NSMutableData* memento = [NSMutableData data];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:memento];
    [archiver encodeObject:[self gains] forKey:@"Shaper Gains"];
    [archiver finishEncoding];
	[archiver release];
    return memento;
}

- (void) restoreGainsFromMemento:(NSData*)aMemento
{
	if(aMemento){
		NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:aMemento];
		[self setGains:[unarchiver decodeObjectForKey:@"Shaper Gains"]];
		[unarchiver finishDecoding];
		[unarchiver release];
		@try {
			[self initBoard];
		}
		@catch(NSException* localException) {
			NSLog(@"Restore of Shaper Gains FAILED.\n");
		}
	}
}

- (NSData*) thresholdMemento
{
    NSMutableData* memento = [NSMutableData data];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:memento];
    [archiver encodeObject:[self thresholds] forKey:@"Shaper Thresholds"];
    [archiver finishEncoding];
	[archiver release];
    return memento;
}

- (void) restoreThresholdsFromMemento:(NSData*)aMemento
{
	if(aMemento){
		NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:aMemento];
		[self setThresholds:[unarchiver decodeObjectForKey:@"Shaper Thresholds"]];
		[unarchiver finishDecoding];
		[unarchiver release];
		@try {
			[self initBoard];
		}
		@catch(NSException* localException) {
			NSLog(@"Restore of Shaper Thresholds FAILED.\n");
		}
	}
}


- (void) scanForShapers
{
    NSLog(@"Scanning for %d Shaper Boards starting @ 0x%04x inc of 0x%04x\n",scanNumber,scanStart,scanDelta);
    uint32_t anAddress;
    for(anAddress = scanStart;anAddress<scanStart+(scanDelta*scanNumber);anAddress+=scanDelta){
        @try {
			unsigned short aValue = 0;
			[[self adapter] readWordBlock:&aValue
								atAddress:anAddress+register_offsets[kBoardIdRegister]
								numToRead:1
							   withAddMod:[self addressModifier]
							usingAddSpace:0x01];
			
			unsigned short id       = [self decodeBoardId:aValue];
			unsigned short type 	= [self decodeBoardType:aValue];
			unsigned short rev      = [self decodeBoardRev:aValue];
			NSString* name		= [NSString stringWithString:[self decodeBoardName:aValue]];
			
			NSLog(@"<0x%04x>  %@\n",anAddress,[NSString stringWithFormat:@"id:%d type:%d rev:%d name:%@",id,type,rev,name]);
			
        }
		@catch(NSException* localException) {
            NSLog(@"<0x%04x>  ----\n",anAddress);            
        }
    }
}

#pragma mark ¥¥¥HW Wizard

- (int) numberOfChannels
{
    return kNumShaperChannels;
}
- (BOOL) hasParmetersToRamp
{
	return YES;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0.00" upperLimit:1200 lowerLimit:0 stepSize:.01 units:@"mv"];
    [p setSetMethod:@selector(setThresholdmV:withValue:) getMethod:@selector(thresholdmV:)];
	[p setInitMethodSelector:@selector(loadThresholdsAndGains)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gain"];
    //[p setFormatter:[[[OHexFormatter alloc] init] autorelease]];
    [p setFormat:@"##0" upperLimit:255 lowerLimit:0 stepSize:1 units:@"raw"];
    [p setSetMethod:@selector(setGain:withValue:) getMethod:@selector(gain:)];
	[p setInitMethodSelector:@selector(loadThresholdsAndGains)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Set Continuous"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setContinous:) getMethod:@selector(continous)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Set MultiBoard"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setMultiBoardEnabled:) getMethod:@selector(multiBoardEnabled)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Enable Scalers"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setScalersEnabled:) getMethod:@selector(scalersEnabled)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Online"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setOnlineMaskBit:withValue:) getMethod:@selector(onlineMaskBit:)];
    [p setActionMask:kAction_Set_Mask|kAction_Restore_Mask];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Ship Time"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setShipTimeStamp:) getMethod:@selector(shipTimeStamp)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setUseValue:NO];
    [p setName:@"Init"];
    [p setSetMethodSelector:@selector(initBoard)];
    [a addObject:p];
    
    return a;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate" className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORShaperModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORShaperModel"]];
    return a;
	
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if([param isEqualToString:@"Threshold"]){
        int rawValue = [[[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel] intValue];
        return [NSNumber numberWithInt:[self thresholdRawtomV:rawValue]];
    }
    else if([param isEqualToString:@"Gain"])return [[cardDictionary objectForKey:@"gains"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Online"]) return [cardDictionary objectForKey:@"onlineMask"];
    else if([param isEqualToString:@"Set Continuous"]) return [cardDictionary objectForKey:@"continous"];
    else if([param isEqualToString:@"Set MultiBoard"]) return [cardDictionary objectForKey:@"multiBoardEnabled"];
    else if([param isEqualToString:@"Enable Scalers"]) return [cardDictionary objectForKey:@"scalersEnabled"];
    else if([param isEqualToString:@"Ship Time"]) return [cardDictionary objectForKey:@"shipTimeStamp"];
    else return nil;
}


- (void) setDataIds:(id)assigner
{
	if(!shipTimeStamp)  dataId       = [assigner assignDataIds:kShortForm]; //short form preferred
	else				dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
    scalerDataId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherShaper
{
    [self setDataId:[anotherShaper dataId]];
    [self setScalerDataId:[anotherShaper scalerDataId]];
}


#pragma mark ¥¥¥RecordShipper
- (void) timedShipScalers
{
    [self shipScalerRecords];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timedShipScalers) object:nil];
    [self performSelector:@selector(timedShipScalers) withObject:nil afterDelay:60*30];
}

- (void) shipScalerRecords
{ 
    short channel;
    if([self scalersEnabled] && [self scalerMask]){
        uint32_t dataWord[16]; 
        int index;
        @try {
            //create the crate card info (used twice below)
            uint32_t crateAndCard 	= ([self crateNumber]&0x0000000f)<<25 | ([self slot]& 0x0000001f)<<20;
			
            //add the gtid
            uint32_t gtid = [[self crate] requestGTID];
			NSLog(@"Soft GTID requested for Scaler record: %d\n",gtid);
            dataWord[1] = gtid;
            dataWord[2] = crateAndCard;
            dataWord[3] = [self readCounter2]<<16 | [self readCounter1];
			index = 4; 
            //get and load up each enabled scaler value
            for(channel=0;channel<kNumShaperChannels;channel++){
                if([self scalerMask] & (1<<channel)){
                    [self readScaler:channel];
                    dataWord[index++]= crateAndCard | ((channel & 0x0000000f) << 16) | (scalerCount[channel]&0x0000ffff);
                }	
            }
            //now that we know the size we fill in the header and ship
            dataWord[0] = scalerDataId | (index & kLongFormLengthMask);
            [[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:dataWord length:index*sizeof(int32_t)]];
        }
		@catch(NSException* localException) {
		}
    }
}
- (BOOL) partOfEvent:(unsigned short)aChannel
{
	//included to satisfy the protocal... change if needed
	return NO;
}
- (uint32_t) eventCount:(int)aChannel
{
    return eventCount[aChannel];
}

- (void) clearEventCounts
{
    int i;
    for(i=0;i<kNumShaperChannels;i++){
		eventCount[i]=0;
    }
}
- (uint32_t) thresholdForDisplay:(unsigned short) aChan
{
	return [self threshold:aChan];
}
- (unsigned short) gainForDisplay:(unsigned short) aChan
{
	return [self gain:aChan];
}
@end
