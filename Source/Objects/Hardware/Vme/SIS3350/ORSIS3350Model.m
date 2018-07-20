//-------------------------------------------------------------------------
//  ORSIS3350Model.h
//
//  Created by Mark A. Howe on Thursday 8/6/09
//  Copyright (c) 2009 Universiy of North Carolina. All rights reserved.
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

#pragma mark ***Imported Files
#import "ORSIS3350Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"
#import "ORVmeTests.h"

NSString* ORSIS3350ModelMemoryWrapLengthChanged			= @"ORSIS3350ModelMemoryWrapLengthChanged";
NSString* ORSIS3350ModelEndAddressThresholdChanged		= @"ORSIS3350ModelEndAddressThresholdChanged";
NSString* ORSIS3350ModelRingBufferPreDelayChanged		= @"ORSIS3350ModelRingBufferPreDelayChanged";
NSString* ORSIS3350ModelRingBufferLenChanged			= @"ORSIS3350ModelRingBufferLenChanged";
NSString* ORSIS3350ModelGateSyncExtendLengthChanged		= @"ORSIS3350ModelGateSyncExtendLengthChanged";
NSString* ORSIS3350ModelGateSyncLimitLengthChanged		= @"ORSIS3350ModelGateSyncLimitLengthChanged";
NSString* ORSIS3350ModelMaxNumEventsChanged				= @"ORSIS3350ModelMaxNumEventsChanged";
NSString* ORSIS3350ModelFreqNChanged					= @"ORSIS3350ModelFreqNChanged";
NSString* ORSIS3350ModelFreqMChanged					= @"ORSIS3350ModelFreqMChanged";
NSString* ORSIS3350ModelMemoryStartModeLengthChanged	= @"ORSIS3350ModelMemoryStartModeLengthChanged";
NSString* ORSIS3350ModelMemoryTriggerDelayChanged		= @"ORSIS3350ModelMemoryTriggerDelayChanged";
NSString* ORSIS3350ModelInvertLemoChanged		= @"ORSIS3350ModelInvertLemoChanged";
NSString* ORSIS3350ModelMultiEventChanged		= @"ORSIS3350ModelMultiEventChanged";
NSString* ORSIS3350ModelTriggerMaskChanged		= @"ORSIS3350ModelTriggerMaskChanged";
NSString* ORSIS3350ModelClockSourceChanged		= @"ORSIS3350ModelClockSourceChanged";
NSString* ORSIS3350ModelOperationModeChanged	= @"ORSIS3350ModelOperationModeChanged";
NSString* ORSIS3350ModelStopTriggerChanged		= @"ORSIS3350ModelStopTriggerChanged";
NSString* ORSIS3350RateGroupChangedNotification	= @"ORSIS3350RateGroupChangedNotification";
NSString* ORSIS3350SettingsLock					= @"ORSIS3350SettingsLock";
NSString* ORSIS3350ModelGainChanged				= @"ORSIS3350ModelGainChanged";
NSString* ORSIS3350ModelDacValueChanged			= @"ORSIS3350ModelDacValueChanged";

NSString* ORSIS3350ModelTriggerModeChanged		= @"ORSIS3350ModelTriggerModeChanged";
NSString* ORSIS3350ModelThresholdChanged		= @"ORSIS3350ModelThresholdChanged";
NSString* ORSIS3350ModelThresholdOffChanged		= @"ORSIS3350ModelThresholdOffChanged";
NSString* ORSIS3350ModelTrigPulseLenChanged		= @"ORSIS3350ModelTrigPulseLenChanged";
NSString* ORSIS3350ModelSumGChanged				= @"ORSIS3350ModelSumGChanged";
NSString* ORSIS3350ModelPeakingTimeChanged		= @"ORSIS3350ModelPeakingTimeChanged";
NSString* ORSIS3350ModelIDChanged				= @"ORSIS3350ModelIDChanged";


//general register offsets
#define kControlStatus                      0x00	  /* read/write*/
#define kModuleIDReg                        0x04	  /* read only*/
#define kAcquisitionControlReg				0x10	  /* read/write*/
#define kDirectMemTriggerDelayReg			0x14	  /* read/write*/
#define kDirectMemStartModeLengthReg		0x18	  /* read/write*/
#define kFrequencySynthReg					0x1C	  /* read/write*/
#define kMaxNumEventsReg					0x20	  /* read/write*/
#define kEventCounterReg					0x24	  /* read/write*/
#define kGateSyncLimitLengthReg				0x28	  /* read/write*/
#define kGateSyncExtendLengthReg			0x2C	  /* read/write*/
#define kAdcMemoryPageRegister				0x34	  /*read/write*/
#define kTemperatureRegister				0x70	  /*read only*/

#define kResetRegister						0x0400   /*write only*/
#define kArmSamplingLogicRegister			0x0410   /*write only*/
#define kDisarmSamplingLogicRegister		0x0414   /*write only*/
#define kVMETriggerRegister					0x0418   /*write only*/
#define kTimeStampClearRegister				0x041C	 /*write only*/

#define kMemoryWrapLengthRegAll				0x01000004
#define kSampleStartAddressAll				0x01000008
#define kRingbufferLengthRegisterAll		0x01000020
#define kRingbufferPreDelayRegisterAll		0x01000024
#define kEndAddressThresholdAll				0x01000028	  

#define kADC12DacControlStatus				0x02000050
#define kADC34DacControlStatus				0x03000050

#define kFirTriggerMode						0x01000000
#define kTriggerGtMode						0x02000000
#define kTriggerEnabled						0x04000000

#define kMaxNumEvents	powf(2.0,19)

#define kAcqStatusEndAddressFlag	       		0x00080000
#define kAcqStatusBusyFlag	        			0x00020000
#define kAcqStatusArmedFlag	        			0x00010000
#define kMaxAdcBufferLength						0x10000

static uint32_t thresholdRegOffsets[4]={
	0x02000034,
	0x0200003C,
	0x03000034,
	0x0300003C
};

static uint32_t addressThresholdRegOffsets[4]={
	0x02000028,
	0x03000028,
	0x02000028,
	0x03000028
};

static uint32_t triggerPulseRegOffsets[4]={
	0x02000030,
	0x02000038,
	0x03000030,
	0x03000038
};

static uint32_t actualSampleAddressOffsets[4]={
	0x02000010,
	0x02000014,
	0x03000010,
	0x03000014
};

static uint32_t adcOffsets[4]={
	0x04000000,
	0x05000000,
	0x06000000,
	0x07000000
};

static uint32_t adcGainOffsets[4]={
	0x02000048,
	0x0200004C,
	0x03000048,
	0x0300004C,
};

#define kMaxNumberWords		 0x1000000   // 64MByte
#define kMaxPageSampleLength 0x800000    // 8 MSample / 16 MByte	  
#define kMaxSampleLength	 0x8000000	 // 128 MSample / 256 MByte

uint32_t rblt_data[kMaxNumberWords];

@interface ORSIS3350Model (private)
- (void) takeDataType1:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo reorder:(BOOL)reorder;
- (void) takeDataType2:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo reorder:(BOOL)reorder;
- (void) readAndShip:(ORDataPacket*)aDataPacket
			 channel: (int) aChannel 
  sampleStartAddress:(uint32_t) aBufferSampleStartAddress 
	sampleEndAddress:(uint32_t) aBufferSampleEndAddress
			 reOrder:(BOOL)reOrder;
- (NSData*) reOrderOneEvent:(NSData*)theSourceData;
@end

@implementation ORSIS3350Model

#pragma mark •••Static Declarations

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x10000000];
	[self setDefaults];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
	[thresholds release];
	[thresholdOffs release];
	[triggerModes release];
	[sumGs release];
	[peakingTimes release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3350Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3350Controller"];
}

- (NSString*) helpURL
{
	return @"VME/SIS3350.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x7FFFFFF);
}

#pragma mark ***Accessors
- (void) setDefaults
{
	int i;
	for(i=0;i<4;i++){
		[self setThreshold:i	withValue:0];
		[self setThresholdOff:i withValue:0];
		[self setGain:i			withValue:18];
		[self setDacValue:i		withValue:3000];
		[self setTrigPulseLen:i withValue:10];
		[self setPeakingTime:i	withValue:8];
		[self setSumG:i			withValue:15];
		[self setTriggerMode:i	withValue:1];
	}
	[self setOperationMode:0];
	[self setTriggerMask:0x1];
	[self setClockSource:0];
	[self setFreqN:0];
	[self setFreqM:20];
	[self setRingBufferLen:2048];
	[self setRingBufferPreDelay:512];
	[self setMemoryWrapLength:2048];
}

- (int32_t) memoryWrapLength
{
    return memoryWrapLength;
}

- (void) setMemoryWrapLength:(int32_t)aMemoryWrapLength
{
	if(aMemoryWrapLength<0)aMemoryWrapLength=0;
	else if(aMemoryWrapLength>0xffffff)aMemoryWrapLength = 0xffffff;
    [[[self undoManager] prepareWithInvocationTarget:self] setMemoryWrapLength:memoryWrapLength];
    memoryWrapLength = aMemoryWrapLength;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelMemoryWrapLengthChanged object:self];
}

- (int) endAddressThreshold
{
    return endAddressThreshold;
}

- (void) setEndAddressThreshold:(int)aEndAddressThreshold
{
 	if(aEndAddressThreshold<0)aEndAddressThreshold=0;
	else if(aEndAddressThreshold>0xffffff)aEndAddressThreshold = 0xffffff;
   [[[self undoManager] prepareWithInvocationTarget:self] setEndAddressThreshold:endAddressThreshold];
    endAddressThreshold = aEndAddressThreshold;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelEndAddressThresholdChanged object:self];
}

- (int) ringBufferPreDelay
{
    return ringBufferPreDelay;
}

- (void) setRingBufferPreDelay:(int)aRingBufferPreDelay
{
	if(aRingBufferPreDelay<0)			aRingBufferPreDelay = 0;
	else if(aRingBufferPreDelay>0x1fff)	aRingBufferPreDelay = 0x1fff;
	aRingBufferPreDelay &= 0x1fffe;
    [[[self undoManager] prepareWithInvocationTarget:self] setRingBufferPreDelay:ringBufferPreDelay];
    ringBufferPreDelay = aRingBufferPreDelay;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelRingBufferPreDelayChanged object:self];
}

- (int) ringBufferLen
{
    return ringBufferLen;
}

- (void) setRingBufferLen:(int)aRingBufferLen
{
	if(aRingBufferLen<0)			aRingBufferLen = 0;
	else if(aRingBufferLen>0xffff)	aRingBufferLen = 0xffff;
	aRingBufferLen &= 0xfff8;
    [[[self undoManager] prepareWithInvocationTarget:self] setRingBufferLen:ringBufferLen];
    ringBufferLen = aRingBufferLen;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelRingBufferLenChanged object:self];
}

- (int) gateSyncExtendLength
{
    return gateSyncExtendLength;
}

- (void) setGateSyncExtendLength:(int)aGateSyncExtendLength
{
	if(aGateSyncExtendLength<0)			aGateSyncExtendLength = 0;
	else if(aGateSyncExtendLength > 248)	aGateSyncExtendLength = 248;
    [[[self undoManager] prepareWithInvocationTarget:self] setGateSyncExtendLength:gateSyncExtendLength];
    gateSyncExtendLength = aGateSyncExtendLength;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelGateSyncExtendLengthChanged object:self];
}

- (int) gateSyncLimitLength
{
    return gateSyncLimitLength;
}

- (void) setGateSyncLimitLength:(int)aGateSyncLimitLength
{
	if(aGateSyncLimitLength<0)					aGateSyncLimitLength = 0;
	else if(aGateSyncLimitLength > 0xffffff-8)	aGateSyncLimitLength = 0xffffff-8;
    [[[self undoManager] prepareWithInvocationTarget:self] setGateSyncLimitLength:gateSyncLimitLength];
    gateSyncLimitLength = aGateSyncLimitLength;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelGateSyncLimitLengthChanged object:self];
}

- (int32_t) maxNumEvents
{
    return maxNumEvents;
}

- (void) setMaxNumEvents:(int32_t)aMaxNumEvents
{
	if(aMaxNumEvents<0)aMaxNumEvents=0;
	else if(aMaxNumEvents>kMaxNumEvents)aMaxNumEvents = kMaxNumEvents;
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxNumEvents:maxNumEvents];
    maxNumEvents = aMaxNumEvents;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelMaxNumEventsChanged object:self];
}

- (int) freqN;
{
    return freqN;
}

- (void) setFreqN:(int)aFreqN
{
	if(aFreqN < 0)   aFreqN = 0;
	else if(aFreqN>5)aFreqN = 5;
    [[[self undoManager] prepareWithInvocationTarget:self] setFreqN:freqN];
    freqN = aFreqN;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelFreqNChanged object:self];
}

- (int) freqM
{
    return freqM;
}

- (void) setFreqM:(int)aFreqM
{
	if(aFreqM < 0)   aFreqM = 0;
	else if(aFreqM>255)aFreqM = 255;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setFreqM:freqM];
    freqM = aFreqM;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelFreqMChanged object:self];
}

- (int32_t) memoryStartModeLength
{
    return memoryStartModeLength;
}

- (void) setMemoryStartModeLength:(int32_t)aMemoryStartModeLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMemoryStartModeLength:memoryStartModeLength];
    memoryStartModeLength = aMemoryStartModeLength;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelMemoryStartModeLengthChanged object:self];
}

- (int32_t) memoryTriggerDelay
{
    return memoryTriggerDelay;
}

- (void) setMemoryTriggerDelay:(int32_t)aMemoryTriggerDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMemoryTriggerDelay:memoryTriggerDelay];
    memoryTriggerDelay = aMemoryTriggerDelay;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelMemoryTriggerDelayChanged object:self];
}

- (BOOL) invertLemo
{
    return invertLemo;
}

- (void) setInvertLemo:(BOOL)aInvertLemo
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInvertLemo:invertLemo];
    invertLemo = aInvertLemo;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelInvertLemoChanged object:self];
}

- (BOOL) multiEvent
{
    return multiEvent;
}

- (void) setMultiEvent:(BOOL)aMultiEvent
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMultiEvent:multiEvent];
    multiEvent = aMultiEvent;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelMultiEventChanged object:self];
}

- (int) triggerMask
{
    return triggerMask;
}

- (void) setTriggerMask:(int)aTriggerMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerMask:triggerMask];
    triggerMask = aTriggerMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelTriggerMaskChanged object:self];
}

- (int) clockSource
{
    return clockSource;
}

- (void) setClockSource:(int)aClockSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = aClockSource;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelClockSourceChanged object:self];
}

- (NSString*) clockSourceName:(int)aValue
{
	switch (aValue) {
		case 0: return @"Freq Synthesizer";
		case 1: return @"Internal 100MHz";
		case 2: return @"Extern LVDS";
		case 3: return @"External BNC";
		default:return @"Unknown";
	}
}


- (int) operationMode
{
    return operationMode;
}

- (void) setOperationMode:(int)aOperationMode
{
	if(aOperationMode>=0 && aOperationMode<6){
		[[[self undoManager] prepareWithInvocationTarget:self] setOperationMode:operationMode];
		operationMode = aOperationMode;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelOperationModeChanged object:self];
	}
}

- (NSString*) operationModeName:(int)aValue
{
	switch (aValue) {
		case 0: return @"Ring Buffer aSync Mode";
		case 1: return @"Ring Buffer Sync Mode";
		case 2: return @"Direct Memory Gate aSync Mode";
		case 3: return @"Direct Memory Gate Sync Mode";
		case 4: return @"Direct Memory Stop Mode";
		case 5: return @"Direct Memory Start Mode";
		default:return @"Unknown Mode";
	}
}

- (unsigned short) moduleID;
{
	return moduleID;
}

- (ORRateGroup*) waveFormRateGroup
{
    return waveFormRateGroup;
}
- (void) setWaveFormRateGroup:(ORRateGroup*)newRateGroup
{
    [newRateGroup retain];
    [waveFormRateGroup release];
    waveFormRateGroup = newRateGroup;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350RateGroupChangedNotification object:self];    
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

#pragma mark •••Rates
- (uint32_t) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumSIS3350Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}

- (int) triggerMode:(short)chan	
{ 
	if(!triggerModes){
		triggerModes = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[triggerModes addObject:[NSNumber numberWithInt:0]];
    }
	return [[triggerModes objectAtIndex:chan] intValue]; 
}

- (void) setTriggerMode:(short)aChan withValue:(int32_t)aValue	
{ 
	if(!triggerModes){
		triggerModes = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[triggerModes addObject:[NSNumber numberWithInt:0]];
    }
	if(aValue<0)aValue = 0;
	if(aValue>4)aValue = 4;
	[[[self undoManager] prepareWithInvocationTarget:self] setTriggerMode:aChan withValue:[self triggerMode:aChan]];
	[triggerModes replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInteger:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelTriggerModeChanged object:self userInfo:userInfo];	
}

- (int32_t) gain:(int)aChan
{
	if(!gains){
		gains = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[gains addObject:[NSNumber numberWithInt:0]];
    }
    return [[gains objectAtIndex:aChan] intValue];
}

- (void) setGain:(int)aChan withValue:(int32_t)aValue 
{ 
	if(!gains){
		gains = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[gains addObject:[NSNumber numberWithInt:0]];
    }
	if(aValue<0)aValue = 0;
	if(aValue>0x7f)aValue = 0x7f;
    [[[self undoManager] prepareWithInvocationTarget:self] setGain:aChan withValue:[self gain:aChan]];
    [gains replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInteger:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelGainChanged object:self userInfo:userInfo];
}

- (int32_t) dacValue:(int)aChan
{
	if(!dacValues){
		dacValues = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[dacValues addObject:[NSNumber numberWithInt:0]];
    }
    return [[dacValues objectAtIndex:aChan] intValue];
}

- (void) setDacValue:(int)aChan withValue:(int32_t)aValue 
{ 
	if(!dacValues){
		dacValues = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[dacValues addObject:[NSNumber numberWithInt:0]];
    }
	if(aValue<0)aValue = 0;
	if(aValue>0xffff)aValue = 0xffff;
    [[[self undoManager] prepareWithInvocationTarget:self] setDacValue:aChan withValue:[self dacValue:aChan]];
    [dacValues replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInteger:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelDacValueChanged object:self userInfo:userInfo];
}
- (int) threshold:(short)aChan
{
	if(!thresholds){
		thresholds = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[thresholds addObject:[NSNumber numberWithInt:0]];
    }
    return [[thresholds objectAtIndex:aChan] intValue];
}

- (void) setThreshold:(short)aChan withValue:(int)aValue 
{ 
	if(!thresholds){
		thresholds = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[thresholds addObject:[NSNumber numberWithInt:0]];
    }
	if(aValue<0)aValue = 0;
	if(aValue>0x3FFF)aValue = 0x3FFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelThresholdChanged object:self userInfo:userInfo];
}

- (int) thresholdOff:(short)aChan
{
	if(!thresholdOffs){
		thresholdOffs = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[thresholdOffs addObject:[NSNumber numberWithInt:0]];
    }
    return [[thresholdOffs objectAtIndex:aChan] intValue];
}

- (void) setThresholdOff:(short)aChan withValue:(int)aValue 
{ 
	if(!thresholdOffs){
		thresholdOffs = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[thresholdOffs addObject:[NSNumber numberWithInt:0]];
    }
	if(aValue<0)aValue = 0;
	if(aValue>0x3FFF)aValue = 0x3FFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setThresholdOff:aChan withValue:[self thresholdOff:aChan]];
    [thresholdOffs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelThresholdOffChanged object:self userInfo:userInfo];
}


- (int) trigPulseLen:(short)aChan
{
	if(!trigPulseLens){
		trigPulseLens = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[trigPulseLens addObject:[NSNumber numberWithInt:0]];
    }
    return [[trigPulseLens objectAtIndex:aChan] intValue];
}

- (void) setTrigPulseLen:(short)aChan withValue:(int)aValue 
{ 
	if(!trigPulseLens){
		trigPulseLens = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[trigPulseLens addObject:[NSNumber numberWithInt:0]];
	}
	if(aValue<0)aValue = 0;
	if(aValue>0xff)aValue = 0xff;
	[[[self undoManager] prepareWithInvocationTarget:self] setTrigPulseLen:aChan withValue:[self trigPulseLen:aChan]];
	[trigPulseLens replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelTrigPulseLenChanged object:self userInfo:userInfo];
}

- (int) sumG:(short)aChan
{
	if(!sumGs)return 0;
    return [[sumGs objectAtIndex:aChan] intValue];
}

- (void) setSumG:(short)aChan withValue:(int)aValue
{
	if(!sumGs){
		sumGs = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[sumGs addObject:[NSNumber numberWithInt:0]];
	}
	if(aValue<0)aValue = 0;
	if(aValue>16)aValue = 16;
	[[[self undoManager] prepareWithInvocationTarget:self] setSumG:aChan withValue:[self sumG:aChan]];
	[sumGs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelSumGChanged object:self userInfo:userInfo];
}

- (int) peakingTime:(short)aChan
{
	if(!peakingTimes)return 0;
    return [[peakingTimes objectAtIndex:aChan] intValue];
}

- (void) setPeakingTime:(short)aChan withValue:(int)aValue
{
	if(!peakingTimes){
		peakingTimes = [[NSMutableArray arrayWithCapacity:kNumSIS3350Channels] retain];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++)[peakingTimes addObject:[NSNumber numberWithInt:0]];
	}
	if(aValue<0)aValue = 0;
	if(aValue>16)aValue = 16;
	[[[self undoManager] prepareWithInvocationTarget:self] setPeakingTime:aChan withValue:[self peakingTime:aChan]];
	[peakingTimes replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelPeakingTimeChanged object:self userInfo:userInfo];
}


#pragma mark •••Hardware Access
- (void) readModuleID:(BOOL)verbose
{	
	uint32_t result = 0;
	[[self adapter] readLongBlock:&result
                         atAddress:baseAddress + kModuleIDReg
                        numToRead:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
	moduleID = result >> 16;
	unsigned short majorRev = (result >> 8) & 0xff;
	unsigned short minorRev = result & 0xff;
	if(verbose)NSLog(@"%@ ID: %x  Firmware:%x.%x\n",[self fullID],moduleID,majorRev,minorRev);
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3350ModelIDChanged object:self];
}

- (float) readTemperature:(BOOL)verbose
{	
	uint32_t result = 0;
	[[self adapter] readLongBlock:&result
						atAddress:baseAddress + kTemperatureRegister
                        numToRead:1
					   withAddMod:addressModifier
					usingAddSpace:0x01];
	float temperature = (float) ( ((result*9)/5) / 4.0); 
	
	if(verbose)NSLog(@"%@ Temperature:%.0f\n",[self fullID], temperature);
	return temperature;
}

- (void) initBoard
{  
	[self writeControlStatusRegister];
	[self writeAcquisitionRegister];
	[self writeFreqSynthRegister];
	[self writeValue:memoryTriggerDelay		offset:kDirectMemTriggerDelayReg];
	[self writeValue:memoryStartModeLength	offset:kDirectMemStartModeLengthReg];
	[self writeValue:gateSyncLimitLength	offset:kGateSyncLimitLengthReg];
	[self writeValue:gateSyncExtendLength	offset:kGateSyncExtendLengthReg];
	[self writeValue:maxNumEvents			offset:kMaxNumEventsReg];
	[self writeRingBufferParams];
	[self writeValue:memoryWrapLength		offset:kMemoryWrapLengthRegAll];
	[self writeValue:endAddressThreshold	offset:kEndAddressThresholdAll];
	
	[self writeTriggerSetupRegisters];
	[self writeGains];
	[self writeDacOffsets];
	[self writeAdcMemoryPage:0];
	runningOperationMode = operationMode;
}


- (void) writeControlStatusRegister
{
	// The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.	
	uint32_t aMask = 0x0;
	
	aMask |= (invertLemo & 0x1)<<4;  //Invert Lemo trigger input
	aMask |= (ledOn		 & 0x1);
	//put the inverse in the top bits to turn off everything else
	aMask = ((~aMask & 0x0000ffff)<<16) | aMask;
	aMask &= ~0xffeeffee; //just leave the reserved bits zero
	[[self adapter] writeLongBlock:&aMask
                         atAddress:baseAddress + kControlStatus
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) writeAcquisitionRegister
{
	// The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.	
	uint32_t aMask = 0x0;
	
	aMask |= (operationMode & 0x7);
	aMask |= (multiEvent    & 0x1)<<5;  //Multi-Event Mode
	if(triggerMask   & 0x1)aMask |= 0x1<<6; //internal trigger
	if(triggerMask   & 0x2)aMask |= 0x1<<8; //Lemo trigger
	if(triggerMask   & 0x4)aMask |= 0x1<<9; //LDVS trigger
	aMask |= (clockSource   & 0x3)<<12;
	
	
	//put the inverse in the top bits to turn off everything else
	aMask = ((~aMask & 0x0000ffff)<<16) | aMask;
	aMask &= ~0xcc98cc98; //just leave the reserved bits zero
	[[self adapter] writeLongBlock:&aMask
                         atAddress:baseAddress + kAcquisitionControlReg
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) writeFreqSynthRegister
{
	uint32_t aMask = 0x0;
	aMask |= (freqM & 0x1FF);
	aMask |= (freqN & 0x3) << 9;  
	
	[[self adapter] writeLongBlock:&aMask
                         atAddress:baseAddress + kFrequencySynthReg
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (uint32_t) readAcqRegister
{
	uint32_t aValue;
	[[self adapter] readLongBlock:&aValue
                         atAddress:baseAddress + kAcquisitionControlReg
                        numToRead:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
	return aValue;
}

- (uint32_t) readEventCounter
{
	uint32_t aValue;
	[[self adapter] readLongBlock:&aValue
						atAddress:baseAddress + kEventCounterReg
                        numToRead:1
					   withAddMod:addressModifier
					usingAddSpace:0x01];
	return aValue;
}


- (void) writeAdcMemoryPage:(uint32_t)aPage
{
	[[self adapter] writeLongBlock:&aPage
						 atAddress:baseAddress + kAdcMemoryPageRegister
						numToWrite:1
						withAddMod:addressModifier
					 usingAddSpace:0x01];
}


- (void) writeGains
{
	int i;
	for(i=0;i<kNumSIS3350Channels;i++){
		uint32_t aGain = [self gain:i];
		[[self adapter] writeLongBlock:&aGain
							 atAddress:baseAddress + adcGainOffsets[i]
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
	}	
}

- (void) writeDacOffsets
{
	uint32_t data, addr;
	uint32_t max_timeout, timeout_cnt;
	int i;
	for(i=0;i<kNumSIS3350Channels;i++){
		uint32_t dac_select_no = i%2;
		uint32_t module_dac_control_status_addr = baseAddress + (i<=1 ? kADC12DacControlStatus : kADC34DacControlStatus);
		data =  [self dacValue:i];
		addr = module_dac_control_status_addr + 4; // DAC_DATA
		[[self adapter] writeLongBlock:&data
							 atAddress:addr
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		data =  1 + (dac_select_no << 4); // write to DAC Register
		addr = module_dac_control_status_addr;
		[[self adapter] writeLongBlock:&data
							 atAddress:addr
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		max_timeout = 5000;
		timeout_cnt = 0;
		addr = module_dac_control_status_addr;
		do {
			[[self adapter] readLongBlock:&data
								atAddress:addr
								numToRead:1
							   withAddMod:addressModifier
							usingAddSpace:0x01];
			timeout_cnt++;
		} while ( ((data & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) );
		
		if (timeout_cnt >=  max_timeout) {
			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i); 
			continue;
		}
		
		data =  2 + (dac_select_no << 4); // Load DACs 
		addr = module_dac_control_status_addr;
		[[self adapter] writeLongBlock:&data
							 atAddress:addr
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		timeout_cnt = 0;
		addr = module_dac_control_status_addr;
		do {
			[[self adapter] readLongBlock:&data
								atAddress:addr
								numToRead:1
							   withAddMod:addressModifier
							usingAddSpace:0x01];
			timeout_cnt++;
		} while ( ((data & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) );
		
		if (timeout_cnt >=  max_timeout) {
			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i); 
			continue;
		}
	}
}

- (void) writeSampleStartAddress:(uint32_t)aValue
{
	[[self adapter] writeLongBlock:&aValue
						 atAddress:baseAddress + kSampleStartAddressAll
						numToWrite:1
						withAddMod:addressModifier
					 usingAddSpace:0x01];
}

- (void) writeValue:(uint32_t)aValue offset:(int32_t)anOffset
{
	[[self adapter] writeLongBlock:&aValue
                         atAddress:baseAddress + anOffset
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) writeRingBufferParams
{
	uint32_t aValue = ringBufferLen;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:baseAddress + kRingbufferLengthRegisterAll
						numToWrite:1
						withAddMod:addressModifier
					 usingAddSpace:0x01];
	
	aValue = ringBufferPreDelay;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:baseAddress + kRingbufferPreDelayRegisterAll
						numToWrite:1
						withAddMod:addressModifier
					 usingAddSpace:0x01];
}


- (void) writeTriggerSetupRegisters
{
	
	int i;
	for(i=0;i<kNumSIS3350Channels;i++){
		uint32_t aMask = 0x0;
		uint32_t triggerModeMask = 0x0;
		int triggerMode = [[triggerModes objectAtIndex:i]intValue];
		if      (triggerMode == 0) {  triggerModeMask = 0; }
		else if (triggerMode == 1) {  triggerModeMask = kTriggerEnabled; }
		else if (triggerMode == 2) {  triggerModeMask = kTriggerEnabled + kTriggerGtMode; }
		else if (triggerMode == 3) {  triggerModeMask = kTriggerEnabled + kFirTriggerMode; }
		else if (triggerMode == 4) {  triggerModeMask = kTriggerEnabled + kFirTriggerMode  + kTriggerGtMode; }
		aMask |= triggerModeMask;
		aMask |= ([self trigPulseLen:i] & 0xFF) << 16;
		aMask |= ([self sumG:i]         & 0x1F) <<  8;
		aMask |= ([self peakingTime:i]  & 0x1F) <<  0;
		[[self adapter] writeLongBlock:&aMask
							 atAddress:baseAddress + triggerPulseRegOffsets[i]
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
	}
	
	for(i = 0; i < 4; i++) {
		uint32_t thresValue = (uint32_t)((([[thresholdOffs objectAtIndex:i] longValue] & 0xfff) << 16) | ([[thresholds objectAtIndex:i] longValue] &0xfff));
		[[self adapter] writeLongBlock:&thresValue
							 atAddress:baseAddress + thresholdRegOffsets[i]
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
	}
	
}

- (uint32_t) readAcquisitionRegister
{
	uint32_t aValue = 0x0;
	[[self adapter] readLongBlock:&aValue
                         atAddress:baseAddress + kAcquisitionControlReg
                        numToRead:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
	return aValue;
}

- (void) printReport
{   
	NSFont* font = [NSFont fontWithName:@"Monaco" size:12];
	NSLogFont(font,@"%@:\n",[self fullID]);
	NSLogFont(font,@"-------------------------------------------\n");
	NSLogFont(font,@"        OFF          ON      End Address\n");
	NSLogFont(font,@"Chan Thresholds   Thresholds  Threshold\n");
	int i;
	for(i =0; i < 4; i++) {
		uint32_t aThreshold;
		[[self adapter] readLongBlock: &aThreshold
							atAddress: baseAddress + thresholdRegOffsets[i]
							numToRead: 1
						   withAddMod: addressModifier
						usingAddSpace: 0x01];
		
		uint32_t aEndThreshold;
		[[self adapter] readLongBlock: &aEndThreshold
							atAddress: baseAddress + addressThresholdRegOffsets[i]
							numToRead: 1
						   withAddMod: addressModifier
						usingAddSpace: 0x01];
		
		NSLogFont(font,@" %2d %8d     %8d    %8d\n",i,(aThreshold&0x0fff0000)>>16, aThreshold&0x0fff,aEndThreshold);
	}
	
	NSLogFont(font,@"-------------------------------------------\n");
	NSLogFont(font,@"Chan   Trigger   PulseLen  SumGap  PeakTime\n");
	for(i =0; i < 4; i++) {
		uint32_t aValue;
		[[self adapter] readLongBlock: &aValue
							atAddress: baseAddress + triggerPulseRegOffsets[i]
							numToRead: 1
						   withAddMod: addressModifier
						usingAddSpace: 0x01];
				
		NSLogFont(font,@" %2d      0x%x   %8d    %4d     %4d\n",i,(aValue>>24)&0x7, (aValue>>16)&0xff,(aValue>>8)&0x1f,aValue&0x1f);
	}
	
	NSLogFont(font,@"-------------------------------------------\n");
	uint32_t aValue = [self readAcqRegister];
	NSLogFont(font,@"Status Mode      : %@\n",[self operationModeName:aValue & 0x7]);
	NSLogFont(font,@"Clock Source     : %@\n",[self clockSourceName:(aValue>>12 & 0x3)]);
	NSLogFont(font,@"MultiEvent       : %@\n",((aValue>>5) & 0x1)   ? @"YES":@"NO");
	NSLogFont(font,@"Internal Triggers: %@\n",((aValue>>6) & 0x1) ? @"Enabled":@"Disabled");
}

#pragma mark •••Data Taker
- (uint32_t) dataId { return dataId; }

- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm]; //short form preferred
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORSIS3350WaveformDecoder",            @"decoder",
								 [NSNumber numberWithLong:dataId],       @"dataId",
								 [NSNumber numberWithBool:YES],          @"variable",
								 [NSNumber numberWithLong:-1],			 @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Waveform"];
    
    return dataDictionary;
}

#pragma mark •••HW Wizard
-(BOOL) hasParmetersToRamp
{
	return YES;
}

- (int) numberOfChannels
{
    return kNumSIS3350Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Operation Mode"];
    [p setFormat:@"##0" upperLimit:5 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setOperationMode:) getMethod:@selector(operationMode)];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Source"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockSource:) getMethod:@selector(clockSource)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Ring Buffer Size"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:8 units:@""];
    [p setSetMethod:@selector(setRingBufferLen:) getMethod:@selector(ringBufferLen)];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Ring Buffer PreDelay"];
    [p setFormat:@"##0" upperLimit:0x1fff lowerLimit:0 stepSize:2 units:@""];
    [p setSetMethod:@selector(setRingBufferPreDelay:) getMethod:@selector(ringBufferPreDelay)];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Memory Wrap Length"];
    [p setFormat:@"##0" upperLimit:0xffffff lowerLimit:0 stepSize:8 units:@""];
    [p setSetMethod:@selector(setMemoryWrapLength:) getMethod:@selector(memoryWrapLength)];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"End Threshold Address"];
    [p setFormat:@"##0" upperLimit:0xffffff lowerLimit:0 stepSize:8 units:@""];
    [p setSetMethod:@selector(setEndAddressThreshold:) getMethod:@selector(endAddressThreshold)];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Freq M"];
    [p setFormat:@"##0" upperLimit:255 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setFreqM:) getMethod:@selector(freqM)];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Freq N"];
    [p setFormat:@"##0" upperLimit:5 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setFreqN:) getMethod:@selector(freqN)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Memory Gate Extend"];
    [p setFormat:@"##0" upperLimit:248 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setGateSyncExtendLength:) getMethod:@selector(gateSyncExtendLength)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Memory Gate Length"];
    [p setFormat:@"##0" upperLimit:0xffffff-8 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setGateSyncLimitLength:) getMethod:@selector(gateSyncLimitLength)];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Memory Start Length"];
    [p setFormat:@"##0" upperLimit:0xfffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setMemoryStartModeLength:) getMethod:@selector(memoryStartModeLength)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Memory Trigger Delay"];
    [p setFormat:@"##0" upperLimit:0xffffff-8 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setMemoryTriggerDelay:) getMethod:@selector(memoryTriggerDelay)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Mask"];
    [p setFormat:@"##0" upperLimit:0x7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTriggerMask:) getMethod:@selector(triggerMask)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Max Events"];
    [p setFormat:@"##0" upperLimit:0x3fff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setMaxNumEvents:) getMethod:@selector(maxNumEvents)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Multi Event"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setMultiEvent:) getMethod:@selector(multiEvent)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Invert Lemo"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setInvertLemo:) getMethod:@selector(invertLemo)];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Trigger Mode"];
    [p setFormat:@"##0" upperLimit:4 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTriggerMode:withValue:) getMethod:@selector(triggerMode:)];
    [a addObject:p];
    
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold ON"];
    [p setFormat:@"##0" upperLimit:0x3fff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold OFF"];
    [p setFormat:@"##0" upperLimit:0x3fff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThresholdOff:withValue:) getMethod:@selector(thresholdOff:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gain"];
    [p setFormat:@"##0" upperLimit:0x7f lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setGain:withValue:) getMethod:@selector(gain:)];
	[p setCanBeRamped:YES];
    [a addObject:p];

	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Dac Value"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setDacValue:withValue:) getMethod:@selector(dacValue:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pulse Length"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setTrigPulseLen:withValue:) getMethod:@selector(trigPulseLen:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Gap Length"];
    [p setFormat:@"##0" upperLimit:16 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setSumG:withValue:) getMethod:@selector(sumG:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Peak Length"];
    [p setFormat:@"##0" upperLimit:16 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPeakingTime:withValue:) getMethod:@selector(peakingTime:)];
	[p setCanBeRamped:YES];
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
	if(     [param isEqualToString:@"Threshold ON"])	return [[cardDictionary objectForKey:@"thresholds"]		objectAtIndex:aChannel];
    else if([param isEqualToString:@"Threshold OFF"])	return [[cardDictionary objectForKey:@"thresholdOffs"]	objectAtIndex:aChannel];
    else if([param isEqualToString:@"Gain"])			return [[cardDictionary objectForKey:@"gains"]			objectAtIndex:aChannel];
    else if([param isEqualToString:@"Dac Value"])		return [[cardDictionary objectForKey:@"dacValues"]		objectAtIndex:aChannel];
	else if([param isEqualToString:@"Pulse Length"])	return [[cardDictionary objectForKey:@"trigPulseLens"]	objectAtIndex:aChannel];
	else if([param isEqualToString:@"Gap Length"])		return [[cardDictionary objectForKey:@"sumGs"]			objectAtIndex:aChannel];
	else if([param isEqualToString:@"Peak Length"])		return [[cardDictionary objectForKey:@"peakingTimes"]	objectAtIndex:aChannel];
	else if([param isEqualToString:@"Trigger Mode"])	return [[cardDictionary objectForKey:@"triggerModes"]	objectAtIndex:aChannel];
	else if([param isEqualToString:@"Operation Mode"])	return [cardDictionary objectForKey:@"operationMode"];
	else if([param isEqualToString:@"Clock Source"])	return [cardDictionary objectForKey:@"clockSource"];
	else if([param isEqualToString:@"Ring Buffer Length"])		return [cardDictionary objectForKey:@"ringBufferLen"];
	else if([param isEqualToString:@"Ring Buffer preDelay"])	return [cardDictionary objectForKey:@"ringBufferPreDelay"];
	else if([param isEqualToString:@"Memory Wrap Length"])		return [cardDictionary objectForKey:@"memoryWrapLength"];
	else if([param isEqualToString:@"End Threshold Address"])	return [cardDictionary objectForKey:@"endAddressThreshold"];
	else if([param isEqualToString:@"Freq M"])					return [cardDictionary objectForKey:@"freqM"];
	else if([param isEqualToString:@"Freq N"])					return [cardDictionary objectForKey:@"freqN"];
	else if([param isEqualToString:@"Memory Gate Extend"])		return [cardDictionary objectForKey:@"gateSyncExtendLength"];
	else if([param isEqualToString:@"Memory Gate Length"])		return [cardDictionary objectForKey:@"gateSyncLimitLength"];
	else if([param isEqualToString:@"Memory Start Length"])		return [cardDictionary objectForKey:@"memoryStartModeLength"];
	else if([param isEqualToString:@"Memory Trigger Delay"])	return [cardDictionary objectForKey:@"memoryTriggerDelay"];
	else if([param isEqualToString:@"Trigger Mask"])			return [cardDictionary objectForKey:@"triggerMask"];
	else if([param isEqualToString:@"Invert Lemo"])				return [cardDictionary objectForKey:@"invertLemo"];
	else if([param isEqualToString:@"Max Events"])				return [cardDictionary objectForKey:@"maxEvents"];
	else if([param isEqualToString:@"Multi Event"])				return [cardDictionary objectForKey:@"multiEvent"];
	
    else return nil;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate"   className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel    name:@"Card"    className:@"ORSIS3350Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel   name:@"Channel" className:@"ORSIS3350Model"]];
    return a;
}

#pragma mark •••Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3350Model"];    
        
    [self startRates];
	//cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    theController   = [self adapter];
	ledOn = YES;
	
	[self reset];
	[self initBoard];
	
	[self clearTimeStamps];
	[self armSamplingLogic];
	
	isRunning		= NO;
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    @try {	
		isRunning		= YES;
		switch(runningOperationMode){
			case kOperationRingBufferSync:			[self takeDataType1:(ORDataPacket*)aDataPacket	userInfo:(NSDictionary*)userInfo reorder:NO];	break;
			case kOperationDirectMemoryGateSync:	[self takeDataType1:(ORDataPacket*)aDataPacket	userInfo:(NSDictionary*)userInfo reorder:NO];	break;
			case kOperationDirectMemoryStart:		[self takeDataType1:(ORDataPacket*)aDataPacket	userInfo:(NSDictionary*)userInfo reorder:NO];	break;
			case kOperationDirectMemoryStop:		[self takeDataType1:(ORDataPacket*)aDataPacket	userInfo:(NSDictionary*)userInfo reorder:YES];	break;
			
			case kOperationRingBufferAsync:			[self takeDataType2:(ORDataPacket*)aDataPacket	userInfo:(NSDictionary*)userInfo reorder:NO];	break;
			case kOperationDirectMemoryGateAsync:	[self takeDataType2:(ORDataPacket*)aDataPacket	userInfo:(NSDictionary*)userInfo reorder:NO];	break;
		}
	}
	@catch(NSException* localException) {
		[self incExceptionCount];
		[localException raise];
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	ledOn = NO;
	[self writeControlStatusRegister];
	
	[self disarmSamplingLogic];
	isRunning = NO;
    [waveFormRateGroup stop];
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id				= kSIS3350; //should be unique
	configStruct->card_info[index].hw_mask[0]				= dataId;	//better be unique
	configStruct->card_info[index].slot						= [self slot];
	configStruct->card_info[index].crate					= [self crateNumber];
	configStruct->card_info[index].add_mod					= addressModifier;
	configStruct->card_info[index].base_add					= baseAddress;
    configStruct->card_info[index].deviceSpecificData[0]	= operationMode;
    configStruct->card_info[index].deviceSpecificData[1]	= [self memoryWrapLength];
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

- (void) reset
{
	uint32_t aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						atAddress: baseAddress + kResetRegister
						numToWrite: 1
					   withAddMod: addressModifier
					usingAddSpace: 0x01];
	
}

- (void) armSamplingLogic
{
	uint32_t aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						atAddress: baseAddress + kArmSamplingLogicRegister
						numToWrite: 1
					   withAddMod: addressModifier
					usingAddSpace: 0x01];
	
}

- (void) disarmSamplingLogic
{
	uint32_t aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						atAddress: baseAddress + kDisarmSamplingLogicRegister
						numToWrite: 1
					   withAddMod: addressModifier
					usingAddSpace: 0x01];
	
}

- (void) fireTrigger
{
	uint32_t aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						atAddress: baseAddress + kVMETriggerRegister
						numToWrite: 1
					   withAddMod: addressModifier
					usingAddSpace: 0x01];
	
}

- (void) clearTimeStamps;
{
	uint32_t aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						atAddress: baseAddress + kTimeStampClearRegister
						numToWrite: 1
					   withAddMod: addressModifier
					usingAddSpace: 0x01];
	
}


- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(isRunning)return NO;
    
    ++waveFormCount[channel];
    return YES;
}

- (uint32_t) waveFormCount:(int)aChannel
{
    return waveFormCount[aChannel];
}

-(void) startRates
{
    [self clearWaveFormCounts];
    [waveFormRateGroup start:self];
}

- (void) clearWaveFormCounts
{
    int i;
    for(i=0;i<kNumSIS3350Channels;i++){
        waveFormCount[i]=0;
    }
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setMemoryWrapLength:		[decoder decodeIntForKey:@"memoryWrapLength"]];
    [self setEndAddressThreshold:	[decoder decodeIntForKey:@"endAddressThreshold"]];
    [self setRingBufferPreDelay:	[decoder decodeIntForKey:@"ringBufferPreDelay"]];
    [self setRingBufferLen:			[decoder decodeIntForKey:@"ringBufferLen"]];
    [self setGateSyncExtendLength:	[decoder decodeIntForKey:@"gateSyncExtendLength"]];
    [self setGateSyncLimitLength:	[decoder decodeIntForKey:@"gateSyncLimitLength"]];
    [self setMaxNumEvents:			[decoder decodeIntForKey:@"maxNumEvents"]];
    [self setFreqN:					[decoder decodeIntForKey:@"freqN"]];
    [self setFreqM:					[decoder decodeIntForKey:@"freqM"]];
    [self setMemoryStartModeLength:	[decoder decodeIntForKey:@"memoryStartModeLength"]];
    [self setMemoryTriggerDelay:	[decoder decodeIntForKey:@"memoryTriggerDelay"]];
    [self setInvertLemo:			[decoder decodeBoolForKey:@"invertLemo"]];
    [self setMultiEvent:			[decoder decodeBoolForKey:@"multiEvent"]];
    [self setTriggerMask:			[decoder decodeIntForKey:@"triggerMask"]];
    [self setClockSource:			[decoder decodeIntForKey:@"clockSource"]];
    [self setOperationMode:			[decoder decodeIntForKey:@"operationMode"]];
 	
	triggerModes	= [[decoder decodeObjectForKey:@"triggerMode"] retain];
	peakingTimes	= [[decoder decodeObjectForKey:@"peakingTimes"] retain];
	thresholds		= [[decoder decodeObjectForKey:@"thresholds"] retain];
	thresholdOffs	= [[decoder decodeObjectForKey:@"thresholdOffs"] retain];
	sumGs			= [[decoder decodeObjectForKey:@"sumGs"] retain];
	trigPulseLens	= [[decoder decodeObjectForKey:@"trigPulseLens"] retain];
	gains			= [[decoder decodeObjectForKey:@"gains"] retain];
	dacValues		= [[decoder decodeObjectForKey:@"dacValues"] retain];

    [self setWaveFormRateGroup:[decoder decodeObjectForKey:@"waveFormRateGroup"]];
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3350Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:memoryWrapLength		forKey:@"memoryWrapLength"];
    [encoder encodeInteger:endAddressThreshold		forKey:@"endAddressThreshold"];
    [encoder encodeInteger:ringBufferPreDelay		forKey:@"ringBufferPreDelay"];
    [encoder encodeInteger:ringBufferLen			forKey:@"ringBufferLen"];
    [encoder encodeInteger:gateSyncExtendLength		forKey:@"gateSyncExtendLength"];
    [encoder encodeInteger:gateSyncLimitLength		forKey:@"gateSyncLimitLength"];
    [encoder encodeInt:maxNumEvents			forKey:@"maxNumEvents"];
    [encoder encodeInteger:freqN					forKey:@"freqN"];
    [encoder encodeInteger:freqM					forKey:@"freqM"];
    [encoder encodeInt:memoryStartModeLength	forKey:@"memoryStartModeLength"];
    [encoder encodeInt:memoryTriggerDelay		forKey:@"memoryTriggerDelay"];
    [encoder encodeBool:invertLemo				forKey:@"invertLemo"];
    [encoder encodeBool:multiEvent				forKey:@"multiEvent"];
    [encoder encodeInteger:triggerMask				forKey:@"triggerMask"];
    [encoder encodeInteger:clockSource				forKey:@"clockSource"];
    [encoder encodeInteger:operationMode			forKey:@"operationMode"];
	
    if(gains)			[encoder encodeObject:gains			forKey:@"gains"];
	if(dacValues)		[encoder encodeObject:dacValues		forKey:@"dacValues"];
	if(thresholds)		[encoder encodeObject:thresholds	forKey:@"thresholds"];
	if(thresholdOffs)	[encoder encodeObject:thresholdOffs	forKey:@"thresholdOffs"];
	if(peakingTimes)	[encoder encodeObject:peakingTimes	forKey:@"peakingTimes"];
	if(sumGs)			[encoder encodeObject:sumGs			forKey:@"sumGs"];
	if(trigPulseLens)	[encoder encodeObject:trigPulseLens	forKey:@"trigPulseLens"];
	if(triggerModes)	[encoder encodeObject:triggerModes	forKey:@"triggerMode"];
	
	[encoder encodeObject:waveFormRateGroup		forKey:@"waveFormRateGroup"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    if(thresholds)		[objDictionary setObject:thresholds						forKey:@"thresholds"];	
    if(thresholdOffs)	[objDictionary setObject:thresholdOffs					forKey:@"thresholdOffs"];	
    if(gains)			[objDictionary setObject:gains							forKey:@"gains"];	
    if(dacValues)		[objDictionary setObject:dacValues						forKey:@"dacValues"];	
    if(trigPulseLens)	[objDictionary setObject:trigPulseLens					forKey:@"trigPulseLens"];	
    if(peakingTimes)	[objDictionary setObject:peakingTimes					forKey:@"peakingTimes"];	
    if(sumGs)			[objDictionary setObject:sumGs							forKey:@"sumGs"];	
    if(triggerModes)	[objDictionary setObject:triggerModes						forKey:@"triggerModes"];
    [objDictionary setObject:[NSNumber numberWithLong:memoryWrapLength]			forKey:@"memoryWrapLength"];	
    [objDictionary setObject:[NSNumber numberWithLong:endAddressThreshold]		forKey:@"endAddressThreshold"];
    [objDictionary setObject:[NSNumber numberWithLong:ringBufferPreDelay]		forKey:@"ringBufferPreDelay"];
    [objDictionary setObject:[NSNumber numberWithLong:ringBufferLen]			forKey:@"ringBufferLen"];
    [objDictionary setObject:[NSNumber numberWithLong:gateSyncExtendLength]		forKey:@"gateSyncExtendLength"];
    [objDictionary setObject:[NSNumber numberWithLong:gateSyncLimitLength]		forKey:@"gateSyncLimitLength"];
    [objDictionary setObject:[NSNumber numberWithLong:maxNumEvents]				forKey:@"maxNumEvents"];
    [objDictionary setObject:[NSNumber numberWithLong:freqN]					forKey:@"freqN"];
    [objDictionary setObject:[NSNumber numberWithLong:freqM]					forKey:@"freqM"];
    [objDictionary setObject:[NSNumber numberWithLong:memoryStartModeLength]	forKey:@"memoryStartModeLength"];
    [objDictionary setObject:[NSNumber numberWithLong:memoryTriggerDelay]		forKey:@"memoryTriggerDelay"];
    [objDictionary setObject:[NSNumber numberWithLong:invertLemo]				forKey:@"invertLemo"];
    [objDictionary setObject:[NSNumber numberWithLong:multiEvent]				forKey:@"multiEvent"];
    [objDictionary setObject:[NSNumber numberWithLong:triggerMask]				forKey:@"triggerMask"];
    [objDictionary setObject:[NSNumber numberWithLong:clockSource]				forKey:@"clockSource"];
    [objDictionary setObject:[NSNumber numberWithLong:operationMode]			forKey:@"operationMode"];
	
	return objDictionary;
}

#pragma mark •••AutoTesting
- (NSArray*) autoTests 
{
	NSMutableArray* myTests = [NSMutableArray array];
	[myTests addObject:[ORVmeReadOnlyTest test:kControlStatus wordSize:4 name:@"Control Status"]];
	[myTests addObject:[ORVmeReadOnlyTest test:kModuleIDReg wordSize:4 name:@"Module ID"]];
	[myTests addObject:[ORVmeReadWriteTest test:kDirectMemTriggerDelayReg wordSize:4 validMask:0x07fffffe name:@"Dir Memory Trig Delay"]];
	[myTests addObject:[ORVmeReadWriteTest test:kFrequencySynthReg wordSize:4 validMask:0x000007ff name:@"Freq Synth"]];
	[myTests addObject:[ORVmeReadWriteTest test:kMaxNumEventsReg wordSize:4 validMask:0x000fffff name:@"Max Events"]];
	[myTests addObject:[ORVmeReadOnlyTest test:kEventCounterReg wordSize:4 name:@"Event Counter"]];
	[myTests addObject:[ORVmeReadWriteTest test:kGateSyncLimitLengthReg wordSize:4 validMask:0x03fffff8 name:@"Gate Sync Limit Len"]];
	[myTests addObject:[ORVmeReadWriteTest test:kGateSyncExtendLengthReg wordSize:4 validMask:0x000000f8 name:@"Gate Sync Len Extend"]];
	[myTests addObject:[ORVmeReadWriteTest test:kAdcMemoryPageRegister wordSize:4 validMask:0x0000000f name:@"Page Reg"]];

	[myTests addObject:[ORVmeReadOnlyTest test:kTemperatureRegister wordSize:4 name:@"temperature"]];
	[myTests addObject:[ORVmeReadOnlyTest test:kAcquisitionControlReg wordSize:4 name:@"Acquisition Control"]];
	[myTests addObject:[ORVmeReadWriteTest test:addressThresholdRegOffsets[0] wordSize:4 validMask:0x00FFFFFC name:@"ADC1/2 address threshold"]];
	[myTests addObject:[ORVmeReadWriteTest test:addressThresholdRegOffsets[1] wordSize:4 validMask:0x00FFFFFC name:@"ADC3/4 address threshold"]];
	[myTests addObject:[ORVmeWriteOnlyTest test:kTimeStampClearRegister wordSize:4 name:@"Clear TimeStamp"]];

	int i;
	for(i=0;i<4;i++){
		[myTests addObject:[ORVmeReadWriteTest test:thresholdRegOffsets[i] wordSize:4 validMask:0xfff name:@"Thresholds"]];
		[myTests addObject:[ORVmeReadWriteTest test:adcGainOffsets[i] wordSize:4 validMask:0x0000007f name:@"AdcGain"]];
		[myTests addObject:[ORVmeReadWriteTest test:triggerPulseRegOffsets[i] wordSize:4 validMask:0x0fff1f1f name:@"Trigger Setup"]];
		[myTests addObject:[ORVmeReadOnlyTest test:actualSampleAddressOffsets[i] wordSize:4 name:@"Adc sample"]];
		[myTests addObject:[ORVmeReadOnlyTest test:adcOffsets[i] length:64*1024 wordSize:4 name:@"Adc Memory"]]; //limit to 64K
	}
	return myTests;
	
}



#define kTimeStampClearRegister				0x041C	 /*write only*/

#define kMemoryWrapLengthRegAll				0x01000004
#define kSampleStartAddressAll				0x01000008
#define kRingbufferLengthRegisterAll		0x01000020
#define kRingbufferPreDelayRegisterAll		0x01000024
@end

@implementation ORSIS3350Model (private)
- (void) takeDataType1:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo reorder:(BOOL)reorder
{
	uint32_t status = [self readAcqRegister];
	if((status & kAcqStatusArmedFlag) != kAcqStatusArmedFlag){
		int i;
		for(i=0;i<kNumSIS3350Channels;i++){
			
			uint32_t stop_next_sample_addr = 0;
			[[self adapter] readLongBlock:&stop_next_sample_addr
								atAddress:baseAddress + actualSampleAddressOffsets[i]
								numToRead:1
							   withAddMod:addressModifier
							usingAddSpace:0x01];
			
			if (stop_next_sample_addr > 65536)  {
				stop_next_sample_addr = 65536;
			}
			if (stop_next_sample_addr != 0) {
				int n = 1;
				if(multiEvent)n = (int)[self readEventCounter];
				if(n>0){
					int event;
					uint32_t start = 0;
					uint32_t eventSize = stop_next_sample_addr/n;
					for(event=0;event<n;event++){
						[self readAndShip:aDataPacket channel:i sampleStartAddress:start sampleEndAddress:start+eventSize reOrder:reorder];
						start += eventSize;
					}
				}
			}
		}
		[self armSamplingLogic];
	}
} 

- (void) takeDataType2:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo reorder:(BOOL)reorder
{
	uint32_t status = [self readAcqRegister];
	if((status & kAcqStatusEndAddressFlag) == kAcqStatusEndAddressFlag){
		[self disarmSamplingLogic];
		int i;
		for(i=0;i<kNumSIS3350Channels;i++){
			uint32_t stop_next_sample_addr;
			[[self adapter] readLongBlock:&stop_next_sample_addr
								atAddress:baseAddress + actualSampleAddressOffsets[i]
								numToRead:1
							   withAddMod:addressModifier
							usingAddSpace:0x01];
			
			if (stop_next_sample_addr > 65536)  {
				stop_next_sample_addr = 65536;
			}
			if (stop_next_sample_addr != 0) {
				[self readAndShip:aDataPacket channel:i sampleStartAddress:0x0 sampleEndAddress:stop_next_sample_addr reOrder:reorder];
			}
		}
		[self armSamplingLogic];
	}
}

- (void) readAndShip:(ORDataPacket*)aDataPacket
			 channel:(int) aChannel 
  sampleStartAddress:(uint32_t) aBufferSampleStartAddress 
	sampleEndAddress:(uint32_t) aBufferSampleEndLength
			 reOrder:(BOOL)reOrder
{
	
	uint32_t numLongWords = (aBufferSampleEndLength - aBufferSampleStartAddress)/2;
	NSMutableData* theData = [NSMutableData dataWithLength:numLongWords*4 + 4 + 4]; //data + ORCA header
	uint32_t* dataPtr = (uint32_t*)[theData bytes];
	dataPtr[0] = dataId | numLongWords + 2;
	dataPtr[1] = location | aChannel;
		
	[theController readLongBlock:&dataPtr[2]
						atAddress: baseAddress + adcOffsets[aChannel]
						numToRead:numLongWords
					   withAddMod:0x09
					usingAddSpace:0x01];
	if(!reOrder){
		[aDataPacket addData:theData];
		++waveFormCount[aChannel];
	}
	else {
		NSData* reOrderedData = [self reOrderOneEvent:theData];
		if(reOrderedData){
			[aDataPacket addData:reOrderedData];
			++waveFormCount[aChannel];
		}
	}
}


- (NSData*) reOrderOneEvent:(NSData*)theOriginalData
{
	uint32_t i;
	uint32_t  wrap_length	= [self memoryWrapLength];
	uint32_t* inDataPtr    = (uint32_t*)[theOriginalData bytes];
	uint32_t  dataLength   = (uint32_t)[theOriginalData length];
	
	NSMutableData* theRearrangedData = [NSMutableData dataWithLength:dataLength];
	uint32_t* outDataPtr		 = (uint32_t*)[theRearrangedData bytes];
	
	uint32_t lword_length     = 0;
	uint32_t lword_stop_index = 0;
	uint32_t lword_wrap_index = 0;
	
	uint32_t wrapped	   = 0;
	uint32_t stopDelayCounter=0;
	
	uint32_t event_sample_length = wrap_length;
	
	if (dataLength != 0) {
		outDataPtr[0] = inDataPtr[0]; //copy ORCA header
		outDataPtr[1] = inDataPtr[1]; //copy ORCA header
		
		uint32_t index = 2;
		
		outDataPtr[index] = inDataPtr[index];	// copy Timestamp	
		outDataPtr[index+1] = inDataPtr[index+1];	// copy Timestamp	    
		
		wrapped			 =   ((inDataPtr[4]  & 0x08000000) >> 27); 
		stopDelayCounter =   ((inDataPtr[4]  & 0x03000000) >> 24); 
		
		uint32_t stopAddress =   ((inDataPtr[index+2]  & 0x7) << 24)  
									+ ((inDataPtr[index+3]  & 0xfff0000 ) >> 4) 
									+  (inDataPtr[index+3]  & 0xfff);
		
		
		// write event length 
		outDataPtr[index+3] = (((event_sample_length) & 0xfff000) << 4)			// bit 23:12
							 + ((event_sample_length) & 0xfff);					// bit 11:0 

		outDataPtr[index+2] = (((event_sample_length) & 0x7000000) >> 24)		// bit 23:12
							  + (inDataPtr[index+2]  & 0x0F000000);				// Wrap arround flag and stopDelayCounter
		
		
		lword_length = event_sample_length/2;
		// stop delay correction
		if ((stopAddress/2) < stopDelayCounter) {
			lword_stop_index = lword_length + (stopAddress/2) - stopDelayCounter;
		}
		else {
			lword_stop_index = (stopAddress/2) - stopDelayCounter;
		}
		
		// rearange
		if (wrapped) { // all samples are vaild
			for (i=0;i<lword_length;i++){
				lword_wrap_index =   lword_stop_index + i;
				if  (lword_wrap_index >= lword_length) {
					lword_wrap_index = lword_wrap_index - lword_length; 
				} 
				outDataPtr[index+4+i] =  inDataPtr[index+4+lword_wrap_index]; 
			}
		}
		else { // only samples from "index" to "stopAddress" are valid
			for (i=0;i<lword_length-lword_stop_index;i++){
				lword_wrap_index =   lword_stop_index + i;
				if  (lword_wrap_index >= lword_length) {lword_wrap_index = lword_wrap_index - lword_length; } 
				outDataPtr[index+4+i] =  0; 
			}
			for (i=lword_length-lword_stop_index;i<lword_length;i++){
				lword_wrap_index =   lword_stop_index + i;
				if  (lword_wrap_index >= lword_length) {lword_wrap_index = lword_wrap_index - lword_length; } 
				outDataPtr[index+4+i] =  inDataPtr[index+4+lword_wrap_index]; 
			}
		}
	}
	
	return theRearrangedData;
}

@end
