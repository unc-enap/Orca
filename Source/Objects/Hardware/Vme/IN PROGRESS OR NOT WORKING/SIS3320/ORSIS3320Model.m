//-------------------------------------------------------------------------
//  ORSIS3320Model.h
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


//THIS CARD DOES NOT WORK

#pragma mark ***Imported Files
#import "ORSIS3320Model.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"
#import "ORVmeTests.h"

NSString* ORSIS3320ModelSampleStartAddressChanged		= @"ORSIS3320ModelSampleStartAddressChanged";
NSString* ORSIS3320ModelSampleLengthChanged				= @"ORSIS3320ModelSampleLengthChanged";
NSString* ORSIS3320ModelEnableUserInAccumGateChanged	= @"ORSIS3320ModelEnableUserInAccumGateChanged";
NSString* ORSIS3320ModelEnableUserInDataStreamChanged	= @"ORSIS3320ModelEnableUserInDataStreamChanged";
NSString* ORSIS3320ModelEnableSampleLenStopChanged		= @"ORSIS3320ModelEnableSampleLenStopChanged";
NSString* ORSIS3320ModelEnablePageWrapChanged			= @"ORSIS3320ModelEnablePageWrapChanged";
NSString* ORSIS3320ModelPageWrapSizeChanged				= @"ORSIS3320ModelPageWrapSizeChanged";
NSString* ORSIS3320ModelStopDelayChanged				= @"ORSIS3320ModelStopDelayChanged";
NSString* ORSIS3320ModelStartDelayChanged				= @"ORSIS3320ModelStartDelayChanged";
NSString* ORSIS3320ModelLemoStartStopLogicChanged		= @"ORSIS3320ModelLemoStartStopLogicChanged";
NSString* ORSIS3320ModelInternalTriggerAsStopChanged	= @"ORSIS3320ModelInternalTriggerAsStopChanged";
NSString* ORSIS3320ModelAutoStartModeChanged			= @"ORSIS3320ModelAutoStartModeChanged";

NSString* ORSIS3320ModelGtMaskChanged					= @"ORSIS3320ModelGtMaskChanged";
NSString* ORSIS3320ModelLtMaskChanged					= @"ORSIS3320ModelLtMaskChanged";

NSString* ORSIS3320ModelMaxNumEventsChanged				= @"ORSIS3320ModelMaxNumEventsChanged";
NSString* ORSIS3320ModelMultiEventChanged				= @"ORSIS3320ModelMultiEventChanged";
NSString* ORSIS3320ModelClockSourceChanged				= @"ORSIS3320ModelClockSourceChanged";
NSString* ORSIS3320ModelStopTriggerChanged				= @"ORSIS3320ModelStopTriggerChanged";
NSString* ORSIS3320RateGroupChangedNotification			= @"ORSIS3320RateGroupChangedNotification";
NSString* ORSIS3320ModelDacValueChanged					= @"ORSIS3320ModelDacValueChanged";

NSString* ORSIS3320ModelThresholdChanged				= @"ORSIS3320ModelThresholdChanged";
NSString* ORSIS3320ModelTrigPulseLenChanged				= @"ORSIS3320ModelTrigPulseLenChanged";
NSString* ORSIS3320ModelSumGChanged						= @"ORSIS3320ModelSumGChanged";
NSString* ORSIS3320ModelPeakingTimeChanged				= @"ORSIS3320ModelPeakingTimeChanged";
NSString* ORSIS3320ModelIDChanged						= @"ORSIS3320ModelIDChanged";
NSString* ORSIS3320SettingsLock							= @"ORSIS3320SettingsLock";
NSString* ORSIS3320ModelTriggerModeMaskChanged			= @"ORSIS3320ModelTriggerModeMaskChanged";


//general register offsets
#define kControlStatus                      0x00	  /* read/write*/
#define kModuleIDReg                        0x04	  /* read only*/
#define kInterruptConfigReg                 0x08	  /* read/write*/
#define kInterruptControlReg                0x0C	  /* read/write*/
#define kAcquisitionControlReg				0x10	  /* read/write*/
#define kExternStartDelayReg				0x14	  /* read/write*/
#define kExternStopDelayReg					0x18	  /* read/write*/
#define kMaxNumEventsReg					0x20	  /* read/write*/
#define kEventCounterReg					0x24	  /* read*/
#define kCBLTBroadcastSetup					0x30	  /*read/write*/
#define kAdcMemoryPageReg					0x34	  /*read/write*/
#define kDacStatusReg						0x50	  /*read/write*/
#define kGainRegister						0x58	  /*read/write*/
#define kDacDataReg							0x54	  /*read/write*/
#define kXilinxJtagTestReg					0x60	  /*read/write*/
#define kXilinxJtagControl					0x64	  /*write*/

#define kResetRegister						0x0400   /*write only*/
#define kArmSamplingLogic					0x0410   /*write only*/
#define kDisarmSamplingLogic				0x0414   /*write only*/
#define kVMEStartSampling					0x0418   /*write only*/
#define kVMEStopSampling					0x041C   /*write only*/
#define kResetDDR2MemoryLogic				0x0428   /*write only*/

#define kEventConfigAll						0x01000000 /*write only*/
#define kSampleLengthAll					0x01000004 /*write only*/
#define kSampleStartAddressAll				0x01000008 /*write only*/
#define kAdcInputModeAll					0x0100000C /*write only*/


#define kDisableLemoStartStop         0x01000000
#define kEnableLemoStartStop          0x00000100
#define kDisableInternalTrigger       0x00400000
#define kEnableInternalTrigger        0x00000040
#define kDisableMultiEvent            0x00200000
#define kEnableMultiEvent             0x00000020
#define kDisableAutoStart             0x00100000
#define kEnableAutoStart              0x00000010

#define kEnablePageWrapMode			 0x10
#define kEnableSampleLenStopMode	 0x20
#define kEnableUserInAccumGateMode   0x400
#define kEnableUserInDataStreamMode  0x1000


#define kSetClockTo200MHz				0x70000000  /* default after Reset  */
#define kSetClockTo100MHz				0x60001000
#define kSetClockTo50MHz				0x50002000
#define kSetClockToLemoX5ClockIn		0x40003000
#define kSetClockToLemoDoubleClockIn	0x30004000
#define kSetClockToLemoClockIn			0x10006000
#define kSetClockToP2ClockIn			0x00007000

#define kMaxNumEvents	0x000fffff

static unsigned long adcOffset[8] = { //read
	0x04000000,	  
	0x04800000,	  
	0x05000000,	  
	0x05800000,	  
	0x06000000,	  
	0x06800000,	  
	0x07000000,	  
	0x07800000,	
};

static unsigned long triggerSetupRegOffsets[48] = { //read/write
	0x02000030,
	0x02000038,
	0x02800030,
	0x02800038,
	0x03000030,
	0x03000038,
	0x03800030,
	0x03800038
};


static unsigned long triggerFlagClearCounter[8] = { //read/write
	0x0200002C,
	0x0200002C,
	0x0280002C,
	0x0280002C,
	0x0300002C,
	0x0300002C,
	0x0380002C,
	0x0380002C
};

static unsigned long triggerThresholdRegOffsets[8] = { //read/write
	0x02000034,
	0x0200003C,
	0x02800034,
	0x0280003C,
	0x03000034,
	0x0300003C,
	0x03800034,
	0x0380003C
};

static unsigned long eventDirectoryRegOffsets[8] = { //read
	0x02010000,
	0x02018000,
	0x02810000,
	0x02818000,
	0x03010000,
	0x03018000,
	0x03810000,
	0x03818000,
};




#define kMaxNumberWords		 0x1000000   // 64MByte
#define kMaxPageSampleLength 0x800000    // 8 MSample / 16 MByte	  
#define kMaxSampleLength	 0x8000000	 // 128 MSample / 256 MByte
#define kAcqStatusArmedFlag	 0x00010000

unsigned long rblt_data[kMaxNumberWords];

@interface ORSIS3320Model (private)
- (void) readAndShip:(ORDataPacket*)aDataPacket
			 channel: (int) aChannel 
  sampleStartAddress:(unsigned long) aBufferSampleStartAddress 
	sampleEndAddress:(unsigned long) aBufferSampleEndAddress
			 reOrder:(BOOL)reOrder;
- (NSData*) reOrderOneEvent:(NSData*)theSourceData;
- (void) readAdcChannel:(ORDataPacket*)aDataPacket channel:(int)adc_channel;

@end

@implementation ORSIS3320Model

#pragma mark •••Static Declarations

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x30000000];
	[self setDefaults];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
	[thresholds release];
	[sumGs release];
	[peakingTimes release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3320Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3320Controller"];
}

- (NSString*) helpURL
{
	return @"VME/SIS3320.html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress,0x07800000+8*1024*1024);
}

#pragma mark ***Accessors

- (int) sampleStartAddress
{
    return sampleStartAddress;
}

- (void) setSampleStartAddress:(int)aSampleStartAddress
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleStartAddress:sampleStartAddress];
    sampleStartAddress = aSampleStartAddress;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelSampleStartAddressChanged object:self];
}

- (int) sampleLength
{
    return sampleLength;
}

- (void) setSampleLength:(int)aSampleLength
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleLength:sampleLength];
    sampleLength = aSampleLength;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelSampleLengthChanged object:self];
}

- (BOOL) enableUserInAccumGate
{
    return enableUserInAccumGate;
}

- (void) setEnableUserInAccumGate:(BOOL)aEnableUserInAccumGate
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableUserInAccumGate:enableUserInAccumGate];
    enableUserInAccumGate = aEnableUserInAccumGate;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelEnableUserInAccumGateChanged object:self];
}

- (BOOL) enableUserInDataStream
{
    return enableUserInDataStream;
}

- (void) setEnableUserInDataStream:(BOOL)aEnableUserInDataStream
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableUserInDataStream:enableUserInDataStream];
    enableUserInDataStream = aEnableUserInDataStream;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelEnableUserInDataStreamChanged object:self];
}


- (BOOL) enableSampleLenStop
{
    return enableSampleLenStop;
}

- (void) setEnableSampleLenStop:(BOOL)aEnableSampleLenStop
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnableSampleLenStop:enableSampleLenStop];
    enableSampleLenStop = aEnableSampleLenStop;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelEnableSampleLenStopChanged object:self];
}

- (BOOL) enablePageWrap
{
    return enablePageWrap;
}

- (void) setEnablePageWrap:(BOOL)aEnablePageWrap
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEnablePageWrap:enablePageWrap];
    enablePageWrap = aEnablePageWrap;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelEnablePageWrapChanged object:self];
}

- (int) pageWrapSize
{
    return pageWrapSize;
}

- (void) setPageWrapSize:(int)aPageWrapSize
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPageWrapSize:pageWrapSize];
    pageWrapSize = aPageWrapSize;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelPageWrapSizeChanged object:self];
}

- (int) pageSize
{
	switch(pageWrapSize){
		case 0:  return 16*1024*1024;
		case 1:  return 4*1024*1024;
		case 2:  return 1024*1024;
		case 3:  return 256*1024;
		case 4:  return 64*1024;
		case 5:  return 16*1024;
		case 6:  return 4*1024;
		case 7:  return 1024;
		case 8:  return 256;
		case 9:  return 128;
		case 10: return 64;
	}
	return 0;
}

- (unsigned long) stopDelay
{
    return stopDelay;
}

- (void) setStopDelay:(unsigned long)aStopDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStopDelay:stopDelay];
    stopDelay = aStopDelay;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelStopDelayChanged object:self];
}

- (unsigned long) startDelay
{
    return startDelay;
}

- (void) setStartDelay:(unsigned long)aStartDelay
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStartDelay:startDelay];
    startDelay = aStartDelay;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelStartDelayChanged object:self];
}

- (BOOL) lemoStartStopLogic
{
    return lemoStartStopLogic;
}

- (void) setLemoStartStopLogic:(BOOL)aLemoStartStopLogic
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoStartStopLogic:lemoStartStopLogic];
    lemoStartStopLogic = aLemoStartStopLogic;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelLemoStartStopLogicChanged object:self];
}

- (BOOL) internalTriggerAsStop
{
    return internalTriggerAsStop;
}

- (void) setInternalTriggerAsStop:(BOOL)aInternalTriggerAsStop
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInternalTriggerAsStop:internalTriggerAsStop];
    internalTriggerAsStop = aInternalTriggerAsStop;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelInternalTriggerAsStopChanged object:self];
}

- (BOOL) autoStartMode
{
    return autoStartMode;
}

- (void) setAutoStartMode:(BOOL)aAutoStartMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutoStartMode:autoStartMode];
    autoStartMode = aAutoStartMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelAutoStartModeChanged object:self];
}

- (void) setDefaults
{
	int i;
	for(i=0;i<8;i++){
		[self setThreshold:i	withValue:0];
		[self setDacValue:i		withValue:3000];
		[self setTrigPulseLen:i withValue:10];
		[self setPeakingTime:i	withValue:8];
		[self setSumG:i			withValue:15];
	}
	[self setClockSource:0];
}


- (unsigned char) triggerModeMask 
{
    return triggerModeMask;
}

- (void) setTriggerModeMask:(unsigned char)aMask 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTriggerModeMask:[self triggerModeMask]];
    triggerModeMask = aMask;	    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelTriggerModeMaskChanged object:self];
}

- (BOOL) triggerModeMaskBit:(int)bit
{
	return triggerModeMask&(1<<bit);
}

- (void) setTriggerModeMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned long aMask = triggerModeMask;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setTriggerModeMask:aMask];
}

- (unsigned char) gtMask 
{
    return gtMask;
}

- (void) setGtMask:(unsigned char)aMask 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGtMask:[self gtMask]];
    gtMask = aMask;	    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelGtMaskChanged object:self];
}

- (BOOL) gtMaskBit:(int)bit
{
	return gtMask&(1<<bit);
}

- (void) setGtMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned long aMask = gtMask;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setGtMask:aMask];
}

- (unsigned char) ltMask {
	
    return ltMask;
}

- (void) setLtMask:(unsigned char)aMask 
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLtMask:[self ltMask]];
    ltMask = aMask;	    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelLtMaskChanged object:self];
}

- (BOOL) ltMaskBit:(int)bit
{
	return ltMask&(1<<bit);
}

- (void) setLtMaskBit:(int)bit withValue:(BOOL)aValue
{
	unsigned long aMask = ltMask;
	if(aValue)aMask |= (1<<bit);
	else      aMask &= ~(1<<bit);
	[self setLtMask:aMask];
}

- (long) maxNumEvents
{
    return maxNumEvents;
}

- (void) setMaxNumEvents:(long)aMaxNumEvents
{
	if(aMaxNumEvents<0)aMaxNumEvents=0;
	else if(aMaxNumEvents>kMaxNumEvents)aMaxNumEvents = kMaxNumEvents;
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxNumEvents:maxNumEvents];
    maxNumEvents = aMaxNumEvents;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelMaxNumEventsChanged object:self];
}


- (BOOL) multiEvent
{
    return multiEvent;
}

- (void) setMultiEvent:(BOOL)aMultiEvent
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMultiEvent:multiEvent];
    multiEvent = aMultiEvent;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelMultiEventChanged object:self];
}

- (int) clockSource
{
    return clockSource;
}

- (void) setClockSource:(int)aClockSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = aClockSource;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelClockSourceChanged object:self];
}

- (NSString*) clockSourceName:(int)aValue
{
	switch (aValue) {
		case 0: return @"Internal 200MHz";
		case 1: return @"Internal 100MHz";
		case 2: return @"Internal 50MHz";
		case 3: return @"External x 5";
		case 4: return @"External x 2";
		case 5: return @"External";
		case 6: return @"Lemo P2";
		default:return @"Unknown";
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320RateGroupChangedNotification object:self];    
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
- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumSIS3320Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}


- (long) dacValue:(int)aChan
{
	if(!dacValues){
		dacValues = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[dacValues addObject:[NSNumber numberWithInt:0]];
    }
    return [[dacValues objectAtIndex:aChan] intValue];
}

- (void) setDacValue:(int)aChan withValue:(long)aValue 
{ 
	if(!dacValues){
		dacValues = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[dacValues addObject:[NSNumber numberWithInt:0]];
    }
	if(aValue<0)aValue = 0;
	if(aValue>0xffff)aValue = 0xffff;
    [[[self undoManager] prepareWithInvocationTarget:self] setDacValue:aChan withValue:[self dacValue:aChan]];
    [dacValues replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelDacValueChanged object:self userInfo:userInfo];
}
- (int) threshold:(short)aChan
{
	if(!thresholds){
		thresholds = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[thresholds addObject:[NSNumber numberWithInt:0]];
    }
    return [[thresholds objectAtIndex:aChan] intValue];
}

- (void) setThreshold:(short)aChan withValue:(int)aValue 
{ 
	if(!thresholds){
		thresholds = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[thresholds addObject:[NSNumber numberWithInt:0]];
    }
	if(aValue<0)aValue = 0;
	if(aValue>0xFFFF)aValue = 0xFFFF;
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelThresholdChanged object:self userInfo:userInfo];
}

- (int) trigPulseLen:(short)aChan
{
	if(!trigPulseLens){
		trigPulseLens = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[trigPulseLens addObject:[NSNumber numberWithInt:0]];
    }
    return [[trigPulseLens objectAtIndex:aChan] intValue];
}

- (void) setTrigPulseLen:(short)aChan withValue:(int)aValue 
{ 
	if(!trigPulseLens){
		trigPulseLens = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[trigPulseLens addObject:[NSNumber numberWithInt:0]];
	}
	if(aValue<0)aValue = 0;
	if(aValue>0xff)aValue = 0xff;
	[[[self undoManager] prepareWithInvocationTarget:self] setTrigPulseLen:aChan withValue:[self trigPulseLen:aChan]];
	[trigPulseLens replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelTrigPulseLenChanged object:self userInfo:userInfo];
}

- (int) sumG:(short)aChan
{
	if(!sumGs)return 0;
    return [[sumGs objectAtIndex:aChan] intValue];
}

- (void) setSumG:(short)aChan withValue:(int)aValue
{
	if(!sumGs){
		sumGs = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[sumGs addObject:[NSNumber numberWithInt:0]];
	}
	if(aValue<0)aValue = 0;
	if(aValue>16)aValue = 16;
	[[[self undoManager] prepareWithInvocationTarget:self] setSumG:aChan withValue:[self sumG:aChan]];
	[sumGs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelSumGChanged object:self userInfo:userInfo];
}

- (int) peakingTime:(short)aChan
{
	if(!peakingTimes)return 0;
    return [[peakingTimes objectAtIndex:aChan] intValue];
}

- (void) setPeakingTime:(short)aChan withValue:(int)aValue
{
	if(!peakingTimes){
		peakingTimes = [[NSMutableArray arrayWithCapacity:kNumSIS3320Channels] retain];
		int i;
		for(i=0;i<kNumSIS3320Channels;i++)[peakingTimes addObject:[NSNumber numberWithInt:0]];
	}
	if(aValue<0)aValue = 0;
	if(aValue>16)aValue = 16;
	[[[self undoManager] prepareWithInvocationTarget:self] setPeakingTime:aChan withValue:[self peakingTime:aChan]];
	[peakingTimes replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelPeakingTimeChanged object:self userInfo:userInfo];
}


#pragma mark •••Hardware Access
- (void) readModuleID:(BOOL)verbose
{	
	unsigned long result = 0;
	[[self adapter] readLongBlock:&result
                         atAddress:baseAddress + kModuleIDReg
                        numToRead:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
	moduleID = result >> 16;
	unsigned short majorRev = (result >> 8) & 0xff;
	unsigned short minorRev = result & 0xff;
	if(verbose)NSLog(@"%@ ID: %x  Firmware:%x.%x\n",[self fullID],moduleID,majorRev,minorRev);
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3320ModelIDChanged object:self];
}

- (void) initBoard
{  
	[self writeAcquisitionRegister];
	
	[self writeStartDelay:startDelay];
	[self writeStopDelay:stopDelay];
	[self writeTriggerClearCounter];
	
	[self writeValue:maxNumEvents offset:kMaxNumEventsReg];
	[self writeEventConfigRegister];
	[self writeValue:sampleLength&0xfffffc	 offset:kSampleLengthAll];
	[self writeSampleStartAddress:sampleStartAddress&0xfffffc];
	[self writeTriggerSetupRegisters];
	[self writeGainControlRegister];
	[self writeControlStatusRegister];
	
	[self writeDacOffsets];
	[self writeAdcMemoryPage:0];
}

- (void) writeGainControlRegister
{
	// The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.	
	unsigned long aValue = 0x0;
	
	[[self adapter] writeLongBlock:&aValue
                         atAddress:baseAddress + kGainRegister
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) writeControlStatusRegister
{
	// The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.	
	unsigned long aMask = 0x0;
	
	aMask |= (ledOn		 & 0x1);
	//put the inverse in the top bits to turn off everything else
	aMask = ((~aMask & 0x0000ffff)<<16) | aMask;
	[[self adapter] writeLongBlock:&aMask
                         atAddress:baseAddress + kControlStatus
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) writeAcquisitionRegister
{
	// The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.	
	unsigned long aMask = 0x0;
	switch(clockSource){
		case 0: aMask = kSetClockTo200MHz;				break;
		case 1: aMask = kSetClockTo100MHz;				break;
		case 2: aMask = kSetClockTo50MHz;				break;
		case 3: aMask = kSetClockToLemoX5ClockIn;		break;
		case 4: aMask = kSetClockToLemoDoubleClockIn;	break;
		case 5: aMask = kSetClockToLemoClockIn;			break;
		case 6: aMask = kSetClockToP2ClockIn;			break;
	}
	
	if(autoStartMode) aMask |= kEnableAutoStart;
	else			  aMask |= kDisableAutoStart;

	if(multiEvent) aMask |= kEnableMultiEvent;
	else		    aMask |= kDisableMultiEvent;

	if(internalTriggerAsStop)	aMask |= kEnableInternalTrigger;
	   else						aMask |= kDisableInternalTrigger;

	if(lemoStartStopLogic)	aMask |= kEnableLemoStartStop;
	else					aMask |= kDisableLemoStartStop;

	[[self adapter] writeLongBlock:&aMask
                         atAddress:baseAddress + kAcquisitionControlReg
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) writeAdcTestMode
{
	int i;
	for(i=0;i<8;i++){
		unsigned long testValue = 0x55 | (1L<<16);
		[[self adapter] writeLongBlock:&testValue
							 atAddress:baseAddress + kAdcInputModeAll
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
	}
}

- (void) writeEventConfigRegister
{
	unsigned long aMask = pageWrapSize & 0xf;
	if(enablePageWrap)		   aMask |= kEnablePageWrapMode;
	if(enableSampleLenStop)    aMask |= kEnableSampleLenStopMode;
	if(enableUserInAccumGate)  aMask |= kEnableUserInAccumGateMode;
	if(enableUserInDataStream) aMask |= kEnableUserInDataStreamMode;
		
	[[self adapter] writeLongBlock:&aMask
                         atAddress:baseAddress + kEventConfigAll
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (unsigned long) readAcqRegister
{
	unsigned long aValue;
	[[self adapter] readLongBlock:&aValue
                         atAddress:baseAddress + kAcquisitionControlReg
                        numToRead:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
	return aValue;
}

- (unsigned long) readEventCounter
{
	unsigned long aValue;
	[[self adapter] readLongBlock:&aValue
						atAddress:baseAddress + kEventCounterReg
                        numToRead:1
					   withAddMod:addressModifier
					usingAddSpace:0x01];
	return aValue;
}

- (void) writeAdcMemoryPage:(unsigned long)aPage
{
	[[self adapter] writeLongBlock:&aPage
						 atAddress:baseAddress + kAdcMemoryPageReg
						numToWrite:1
						withAddMod:addressModifier
					 usingAddSpace:0x01];
}

- (void) writeStartDelay:(unsigned long)aValue
{
	[[self adapter] writeLongBlock:&aValue
						 atAddress:baseAddress + kExternStartDelayReg
						numToWrite:1
						withAddMod:addressModifier
					 usingAddSpace:0x01];
}

- (void) writeStopDelay:(unsigned long)aValue
{
	[[self adapter] writeLongBlock:&aValue
						 atAddress:baseAddress + kExternStopDelayReg
						numToWrite:1
						withAddMod:addressModifier
					 usingAddSpace:0x01];
}


- (void) writeTriggerClearCounter
{
	unsigned long aValue = [self pageSize];
	int i;
	for(i=0;i<8;i++){
		[[self adapter] writeLongBlock:&aValue
							 atAddress:baseAddress + triggerFlagClearCounter[i]
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
	}
}

- (void) writeDacOffsets
{
	unsigned long dataWord;
	unsigned long max_timeout, timeout_cnt;
	
	int i;
	for (i=0;i<8;i++) {	
		
		dataWord =  [self dacValue:i] ;
		[[self adapter] writeLongBlock:&dataWord
							 atAddress:baseAddress + kDacDataReg
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		dataWord =  1 + (i<<4); // write to DAC Register
		[[self adapter] writeLongBlock:&dataWord
							 atAddress:baseAddress + kDacStatusReg
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		max_timeout = 5000 ;
		timeout_cnt = 0 ;
		do {
			[[self adapter] readLongBlock:&dataWord
								 atAddress:baseAddress + kDacStatusReg
								numToRead:1
								withAddMod:addressModifier
							 usingAddSpace:0x01];
			timeout_cnt++;
		} while ( ((dataWord & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) )    ;
		
		if (timeout_cnt >=  max_timeout) {
			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i); 
			continue;
		}
		
		dataWord =  2 + (i<<4); // Load DACs 
		[[self adapter] writeLongBlock:&dataWord
							 atAddress:baseAddress + kDacStatusReg
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		timeout_cnt = 0 ;
		do {
			[[self adapter] readLongBlock:&dataWord
								atAddress:baseAddress + kDacStatusReg
								numToRead:1
							   withAddMod:addressModifier
							usingAddSpace:0x01];
			timeout_cnt++;
		} while ( ((dataWord & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) )    ;
		
		if (timeout_cnt >=  max_timeout) {
			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i); 
			continue;
		}
	}
}

- (void) writeSampleStartAddress:(unsigned long)aValue
{
	[[self adapter] writeLongBlock:&aValue
						 atAddress:baseAddress + kSampleStartAddressAll
						numToWrite:1
						withAddMod:addressModifier
					 usingAddSpace:0x01];
}

- (void) writeValue:(unsigned long)aValue offset:(long)anOffset
{
	[[self adapter] writeLongBlock:&aValue
                         atAddress:baseAddress + anOffset
                        numToWrite:1
                        withAddMod:addressModifier
                     usingAddSpace:0x01];
}

- (void) writeTriggerSetupRegisters
{
	
	int i;
	for(i=0;i<kNumSIS3320Channels;i++){
		unsigned long aMask = 0x0;
		aMask |= ([self trigPulseLen:i] & 0xFF) << 16;
		aMask |= ([self sumG:i]         & 0x1F) <<  8;
		aMask |= ([self peakingTime:i]  & 0x1F) <<  0;
		[[self adapter] writeLongBlock:&aMask
							 atAddress:baseAddress + triggerSetupRegOffsets[i]
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
	}
	
	for(i = 0; i < kNumSIS3320Channels; i++) {
		unsigned long theThresholdValue =  [self threshold:i];
		unsigned long writeValue =	((triggerModeMask	& (1L<<i)) << 26) | 
									((gtMask			& (1L<<i)) << 25) | 
									((ltMask			& (1L<<i)) << 24) | 
									(theThresholdValue  & 0xffff) ;
		
		[[self adapter] writeLongBlock:&writeValue
							 atAddress:baseAddress + triggerThresholdRegOffsets[i]
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
	}
	
}

- (unsigned long) readAcquisitionRegister
{
	unsigned long aValue = 0x0;
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
	NSLogFont(font,@"Chan Thresholds \n");
	int i;
	for(i =0; i < 8; i++) {
		unsigned long aThreshold;
		[[self adapter] readLongBlock: &aThreshold
							atAddress: baseAddress + triggerThresholdRegOffsets[i]
							numToRead: 1
						   withAddMod: addressModifier
						usingAddSpace: 0x01];
		
		
		NSLogFont(font,@" %2d %8d\n",i,(aThreshold&0xffff));
	}
	
	NSLogFont(font,@"-------------------------------------------\n");
	NSLogFont(font,@"Chan   Trigger   PulseLen  SumGap  PeakTime\n");
	for(i =0; i < 4; i++) {
		unsigned long aValue;
		[[self adapter] readLongBlock: &aValue
							atAddress: baseAddress + triggerSetupRegOffsets[i]
							numToRead: 1
						   withAddMod: addressModifier
						usingAddSpace: 0x01];
				
		NSLogFont(font,@" %2d      0x%x   %8d    %4d     %4d\n",i,(aValue>>24)&0x7, (aValue>>16)&0xff,(aValue>>8)&0x1f,aValue&0x1f);
	}
	
	NSLogFont(font,@"-------------------------------------------\n");
	unsigned long aValue = [self readAcqRegister];
	NSLogFont(font,@"Clock Source     : %@\n",[self clockSourceName:(aValue>>12 & 0x7)]);
	NSLogFont(font,@"MultiEvent       : %@\n",((aValue>>5) & 0x1)   ? @"YES":@"NO");
	NSLogFont(font,@"Internal Triggers: %@\n",((aValue>>6) & 0x1) ? @"Enabled":@"Disabled");
}

#pragma mark •••Data Taker
- (unsigned long) dataId { return dataId; }

- (void) setDataId: (unsigned long) DataId
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
								 @"ORSIS3320WaveformDecoder",            @"decoder",
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
    return kNumSIS3320Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Source"];
    [p setFormat:@"##0" upperLimit:3 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockSource:) getMethod:@selector(clockSource)];
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
    [p setName:@"Threshold ON"];
    [p setFormat:@"##0" upperLimit:0x3fff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
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
    else if([param isEqualToString:@"Dac Value"])		return [[cardDictionary objectForKey:@"dacValues"]		objectAtIndex:aChannel];
	else if([param isEqualToString:@"Pulse Length"])	return [[cardDictionary objectForKey:@"trigPulseLens"]	objectAtIndex:aChannel];
	else if([param isEqualToString:@"Gap Length"])		return [[cardDictionary objectForKey:@"sumGs"]			objectAtIndex:aChannel];
	else if([param isEqualToString:@"Peak Length"])		return [[cardDictionary objectForKey:@"peakingTimes"]	objectAtIndex:aChannel];
	else if([param isEqualToString:@"Clock Source"])	return [cardDictionary objectForKey:@"clockSource"];
	else if([param isEqualToString:@"Max Events"])				return [cardDictionary objectForKey:@"maxEvents"];
	else if([param isEqualToString:@"Multi Event"])				return [cardDictionary objectForKey:@"multiEvent"];
	
    else return nil;
}

- (NSArray*) wizardSelections
{
    NSMutableArray* a = [NSMutableArray array];
    [a addObject:[ORHWWizSelection itemAtLevel:kContainerLevel name:@"Crate"   className:@"ORVmeCrateModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel    name:@"Card"    className:@"ORSIS3320Model"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel   name:@"Channel" className:@"ORSIS3320Model"]];
    return a;
}

#pragma mark •••Data Taker
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3320Model"];    
        
    [self startRates];
	//cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    theController   = [self adapter];
	ledOn = YES;
	
	[self reset];
	NSLog(@"1 arm flag: 0x%x\n",[self readAcqRegister] & kAcqStatusArmedFlag);
	[self initBoard];
	NSLog(@"2 arm flag: 0x%x\n",[self readAcqRegister] & kAcqStatusArmedFlag);
	
	[self armSamplingLogic];
	NSLog(@"3 arm flag: 0x%x\n",[self readAcqRegister] & kAcqStatusArmedFlag);
	[self startSampling];
	
	isRunning		= NO;
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    @try {	
		isRunning		= YES;
		unsigned long status = [self readAcqRegister];
		if((status & kAcqStatusArmedFlag) != kAcqStatusArmedFlag){
			int i;
			
		//for(i=0;i<kNumSIS3320Channels;i++){
			for(i=0;i<4;i++){
				unsigned long nextSampleAddress = [self readEventDir:i];
				BOOL trig = (nextSampleAddress >> 28) & 0x1;
				if(trig){
					nextSampleAddress &= 0x1FFFFFc;
					[self readAdcChannel:aDataPacket channel:i];
				}
			}
			[self armSamplingLogic];
		}
	}
	@catch(NSException* localException) {
		[self incExceptionCount];
		[localException raise];
	}
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
	ledOn = NO;
	[self writeControlStatusRegister];
	
	[self disarmSamplingLogic];
	isRunning = NO;
    [waveFormRateGroup stop];
	free(data);
	data = nil;
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id				= kSIS3320; //should be unique
	configStruct->card_info[index].hw_mask[0]				= dataId;	//better be unique
	configStruct->card_info[index].slot						= [self slot];
	configStruct->card_info[index].crate					= [self crateNumber];
	configStruct->card_info[index].add_mod					= addressModifier;
	configStruct->card_info[index].base_add					= baseAddress;
    configStruct->card_info[index].deviceSpecificData[0]	= 0;
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
}

- (void) reset
{
	unsigned long aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						atAddress: baseAddress + kResetRegister
						numToWrite: 1
					   withAddMod: addressModifier
					usingAddSpace: 0x01];
	
}

- (void) armSamplingLogic
{
	unsigned long aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						atAddress: baseAddress + kArmSamplingLogic
						numToWrite: 1
					   withAddMod: addressModifier
					usingAddSpace: 0x01];
	
}

- (void) disarmSamplingLogic
{
	unsigned long aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						atAddress: baseAddress + kDisarmSamplingLogic
						numToWrite: 1
					   withAddMod: addressModifier
					usingAddSpace: 0x01];
	
}

- (void) startSampling
{
	unsigned long aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						 atAddress: baseAddress + kVMEStartSampling
						numToWrite: 1
						withAddMod: addressModifier
					 usingAddSpace: 0x01];
	
}

- (void) stopSampling
{
	unsigned long aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						 atAddress: baseAddress + kVMEStopSampling
						numToWrite: 1
						withAddMod: addressModifier
					 usingAddSpace: 0x01];
	
}

- (void) resetDDR2MemoryLogic:(id)sender
{
	unsigned long aValue = 1;
	[[self adapter] writeLongBlock: &aValue
						 atAddress: baseAddress + kResetDDR2MemoryLogic
						numToWrite: 1
						withAddMod: addressModifier
					 usingAddSpace: 0x01];
	
}

- (unsigned long) readEventDir:(int)aChannel
{
	unsigned long aValue = 0;
	int i;
	for(i=0;i<10;i++){
	[[self adapter] readLongBlock: &aValue
						atAddress: baseAddress + eventDirectoryRegOffsets[aChannel]// + i*4
						numToRead: 1
						withAddMod: addressModifier
					 usingAddSpace: 0x01];
		//NSLog(@"%d: 0x%08x\n",i,aValue);
	}
	return aValue;
}

- (BOOL) bumpRateFromDecodeStage:(short)channel
{
    if(isRunning)return NO;
    
    ++waveFormCount[channel];
    return YES;
}

- (unsigned long) waveFormCount:(int)aChannel
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
    for(i=0;i<kNumSIS3320Channels;i++){
        waveFormCount[i]=0;
    }
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setGtMask:[decoder decodeIntForKey:@"gtMask"]];
    [self setLtMask:[decoder decodeIntForKey:@"ltMask"]];
    [self setSampleStartAddress:[decoder decodeIntForKey:@"sampleStartAddress"]];
    [self setSampleLength:[decoder decodeIntForKey:@"sampleLength"]];
    [self setEnableUserInAccumGate:[decoder decodeBoolForKey:@"enableUserInAccumGate"]];
    [self setEnableUserInDataStream:[decoder decodeBoolForKey:@"enableUserInDataStream"]];
    [self setEnableSampleLenStop:[decoder decodeBoolForKey:@"enableSampleLenStop"]];
    [self setEnablePageWrap:[decoder decodeBoolForKey:@"enablePageWrap"]];
    [self setPageWrapSize:[decoder decodeIntForKey:@"pageWrapSize"]];
    [self setStopDelay:				[decoder decodeInt32ForKey:@"stopDelay"]];
    [self setStartDelay:			[decoder decodeInt32ForKey:@"startDelay"]];
    [self setLemoStartStopLogic:	[decoder decodeBoolForKey:@"lemoStartStopLogic"]];
    [self setInternalTriggerAsStop:	[decoder decodeBoolForKey:@"internalTriggerAsStop"]];
    [self setAutoStartMode:			[decoder decodeBoolForKey:@"autoStartMode"]];
	
    [self setMaxNumEvents:			[decoder decodeInt32ForKey:@"maxNumEvents"]];
    [self setMultiEvent:			[decoder decodeBoolForKey:@"multiEvent"]];
    [self setClockSource:			[decoder decodeIntForKey:@"clockSource"]];
 	
	peakingTimes	= [[decoder decodeObjectForKey:@"peakingTimes"] retain];
	thresholds		= [[decoder decodeObjectForKey:@"thresholds"] retain];
	sumGs			= [[decoder decodeObjectForKey:@"sumGs"] retain];
	trigPulseLens	= [[decoder decodeObjectForKey:@"trigPulseLens"] retain];
	dacValues		= [[decoder decodeObjectForKey:@"dacValues"] retain];

    [self setWaveFormRateGroup:[decoder decodeObjectForKey:@"waveFormRateGroup"]];
    if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3320Channels groupTag:0] autorelease]];
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
    [encoder encodeInt:gtMask					forKey:@"gtMask"];
    [encoder encodeInt:ltMask					forKey:@"ltMask"];
    [encoder encodeInt:sampleStartAddress		forKey:@"sampleStartAddress"];
    [encoder encodeInt:sampleLength				forKey:@"sampleLength"];
    [encoder encodeBool:enableUserInAccumGate	forKey:@"enableUserInAccumGate"];
    [encoder encodeBool:enableUserInDataStream	forKey:@"enableUserInDataStream"];
    [encoder encodeBool:enableSampleLenStop		forKey:@"enableSampleLenStop"];
    [encoder encodeBool:enablePageWrap			forKey:@"enablePageWrap"];
    [encoder encodeInt:pageWrapSize				forKey:@"pageWrapSize"];
    [encoder encodeInt32:stopDelay				forKey:@"stopDelay"];
    [encoder encodeInt32:startDelay				forKey:@"startDelay"];
    [encoder encodeBool:lemoStartStopLogic		forKey:@"lemoStartStopLogic"];
    [encoder encodeBool:internalTriggerAsStop	forKey:@"internalTriggerAsStop"];
    [encoder encodeBool:autoStartMode			forKey:@"autoStartMode"];
	
    [encoder encodeInt32:maxNumEvents			forKey:@"maxNumEvents"];
    [encoder encodeBool:multiEvent				forKey:@"multiEvent"];
    [encoder encodeInt:clockSource				forKey:@"clockSource"];
	
	if(dacValues)		[encoder encodeObject:dacValues		forKey:@"dacValues"];
	if(thresholds)		[encoder encodeObject:thresholds	forKey:@"thresholds"];
	if(peakingTimes)	[encoder encodeObject:peakingTimes	forKey:@"peakingTimes"];
	if(sumGs)			[encoder encodeObject:sumGs			forKey:@"sumGs"];
	if(trigPulseLens)	[encoder encodeObject:trigPulseLens	forKey:@"trigPulseLens"];
	
	[encoder encodeObject:waveFormRateGroup		forKey:@"waveFormRateGroup"];

}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
    if(thresholds)		[objDictionary setObject:thresholds						forKey:@"thresholds"];	
    if(dacValues)		[objDictionary setObject:dacValues						forKey:@"dacValues"];	
    if(trigPulseLens)	[objDictionary setObject:trigPulseLens					forKey:@"trigPulseLens"];	
    if(peakingTimes)	[objDictionary setObject:peakingTimes					forKey:@"peakingTimes"];	
    if(sumGs)			[objDictionary setObject:sumGs							forKey:@"sumGs"];	
    [objDictionary setObject:[NSNumber numberWithLong:maxNumEvents]				forKey:@"maxNumEvents"];
    [objDictionary setObject:[NSNumber numberWithLong:multiEvent]				forKey:@"multiEvent"];
    [objDictionary setObject:[NSNumber numberWithLong:clockSource]				forKey:@"clockSource"];
	
	return objDictionary;
}

#pragma mark •••AutoTesting
- (NSArray*) autoTests 
{
	NSMutableArray* myTests = [NSMutableArray array];
	[myTests addObject:[ORVmeReadOnlyTest test:kControlStatus wordSize:4 name:@"Control Status"]];
	[myTests addObject:[ORVmeReadOnlyTest test:kModuleIDReg wordSize:4 name:@"Module ID"]];
	[myTests addObject:[ORVmeReadWriteTest test:kMaxNumEventsReg wordSize:4 validMask:0x000fffff name:@"Max Events"]];
	[myTests addObject:[ORVmeReadOnlyTest test:kEventCounterReg wordSize:4 name:@"Event Counter"]];
	[myTests addObject:[ORVmeReadWriteTest test:kAdcMemoryPageReg wordSize:4 validMask:0x0000000f name:@"Page Reg"]];

	[myTests addObject:[ORVmeReadOnlyTest test:kAcquisitionControlReg wordSize:4 name:@"Acquisition Control"]];

	int i;
	for(i=0;i<8;i++){
		[myTests addObject:[ORVmeReadWriteTest test:triggerThresholdRegOffsets[i] wordSize:4 validMask:0xffff name:[NSString stringWithFormat:@"ADC%d",i]]];
	}
	return myTests;
	
}
@end

@implementation ORSIS3320Model (private)
//- (void) takeDataType1:(ORDataPacket*)aDataPacket userInfo:(id)userInfo reorder:(BOOL)reorder
//{
	/*
	unsigned long status = [self readAcqRegister];
	if((status & kAcqStatusArmedFlag) != kAcqStatusArmedFlag){
		int i;
		for(i=0;i<kNumSIS3320Channels;i++){
			
			unsigned long stop_next_sample_addr = 0;
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
				if(multiEvent)n = [self readEventCounter];
				if(n>0){
					int event;
					unsigned long start = 0;
					unsigned long eventSize = stop_next_sample_addr/n;
					for(event=0;event<n;event++){
						[self readAndShip:aDataPacket channel:i sampleStartAddress:start sampleEndAddress:start+eventSize reOrder:reorder];
						start += eventSize;
					}
				}
			}
		}
		[self armSamplingLogic];
	}

} */

- (void) readAndShip:(ORDataPacket*)aDataPacket
			 channel:(int) aChannel 
  sampleStartAddress:(unsigned long) aBufferSampleStartAddress 
	sampleEndAddress:(unsigned long) aBufferSampleEndLength
			 reOrder:(BOOL)reOrder
{
	/*
	
	unsigned long numLongWords = (aBufferSampleEndLength - aBufferSampleStartAddress)/2;
	NSMutableData* theData = [NSMutableData dataWithLength:numLongWords*4 + 4 + 4]; //data + ORCA header
	unsigned long* dataPtr = (unsigned long*)[theData bytes];
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
	 */
}


- (NSData*) reOrderOneEvent:(NSData*)theOriginalData
{/*
	unsigned long i;
	unsigned long  wrap_length	= [self memoryWrapLength];
	unsigned long* inDataPtr    = (unsigned long*)[theOriginalData bytes];
	unsigned long  dataLength   = [theOriginalData length];
	
	NSMutableData* theRearrangedData = [NSMutableData dataWithLength:dataLength];
	unsigned long* outDataPtr		 = (unsigned long*)[theRearrangedData bytes];
	
	unsigned long lword_length     = 0;
	unsigned long lword_stop_index = 0;
	unsigned long lword_wrap_index = 0;
	
	unsigned long wrapped	   = 0;
	unsigned long stopDelayCounter=0;
	
	unsigned long event_sample_length = wrap_length;
	
	if (dataLength != 0) {
		outDataPtr[0] = inDataPtr[0]; //copy ORCA header
		outDataPtr[1] = inDataPtr[1]; //copy ORCA header
		
		unsigned long index = 2;
		
		outDataPtr[index] = inDataPtr[index];	// copy Timestamp	
		outDataPtr[index+1] = inDataPtr[index+1];	// copy Timestamp	    
		
		wrapped			 =   ((inDataPtr[4]  & 0x08000000) >> 27); 
		stopDelayCounter =   ((inDataPtr[4]  & 0x03000000) >> 24); 
		
		unsigned long stopAddress =   ((inDataPtr[index+2]  & 0x7) << 24)  
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
  */
	return nil;
}

- (void) readAdcChannel:(ORDataPacket*)aDataPacket channel:(int)adc_channel
{	
	
	unsigned long event_sample_start_addr = sampleStartAddress; //temp....
	unsigned long event_sample_length = [self sampleLength];
	
	// 64KSample   0x10000			
	// 256KSample  0x40000
	// 1 MSample   0x100000
	// 4 MSample   0x400000     VME Byte Address offset  0x80 00000
	
	// 32 MSample   0x2000000; VME Byte Address offset  0x80 00000
		
	unsigned long max_page_sample_length  = 0x10000 ;
	unsigned long page_sample_length_mask = max_page_sample_length - 1 ;
	
	unsigned long next_event_sample_start_addr =  (event_sample_start_addr &  0x01fffffc);	// max 32 MSample
	unsigned long rest_event_sample_length     =  (event_sample_length & 0x03fffffc);		// max 32 MSample
	if (rest_event_sample_length  >= 0x2000000) {
		rest_event_sample_length =  0x2000000;
	}     
	
	//do {
		unsigned long sub_event_sample_addr  =  (next_event_sample_start_addr & page_sample_length_mask) ;
		unsigned long sub_max_page_sample_length =  max_page_sample_length - sub_event_sample_addr ;
		
		unsigned long sub_event_sample_length ;
	
		if (rest_event_sample_length >= sub_max_page_sample_length) {
			sub_event_sample_length = sub_max_page_sample_length  ;
		}
		else {
			sub_event_sample_length = rest_event_sample_length  ; // - sub_event_sample_addr
		}
		
		//unsigned long sub_page_addr_offset    =  (next_event_sample_start_addr >> 22) & 0x7 ;
		
		
		unsigned long dma_request_nof_lwords     =  (sub_event_sample_length) / 2  ; // Lwords
		//unsigned long dma_adc_addr_offset_bytes  =  (sub_event_sample_addr) * 2    ; // Bytes		
		
		// set page
		//[self writeAdcMemoryPage:sub_page_addr_offset];
		
		// read		
	unsigned long addr			 = [self baseAddress] + adcOffset[adc_channel];// + dma_adc_addr_offset_bytes;
		unsigned long req_nof_lwords = dma_request_nof_lwords ;
		
		if(!data) data = (unsigned long*)malloc((3+req_nof_lwords)*sizeof(long));
		data[0] =   dataId | (3+req_nof_lwords);
		data[1] =   (([self crateNumber]&0x0000000f)<<21) | 
					(([self slot] & 0x0000001f)<<16)      |
					((adc_channel & 0x000000ff)<<8);
		data[2] = [self sampleLength]/2;
		
		[[self adapter] readLongBlock:&data[3]
							atAddress:addr
							numToRead:req_nof_lwords
						   withAddMod:addressModifier
						usingAddSpace:0x01];			
		[aDataPacket addLongsToFrameBuffer:data length:3+req_nof_lwords];

		next_event_sample_start_addr =  next_event_sample_start_addr + sub_event_sample_length;  
		rest_event_sample_length     =  rest_event_sample_length     - sub_event_sample_length;  
		
	//} while (rest_event_sample_length>0) ;

}
@end
