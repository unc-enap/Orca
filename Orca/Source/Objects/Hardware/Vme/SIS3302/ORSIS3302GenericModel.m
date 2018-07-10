//-------------------------------------------------------------------------
//  ORSIS3302.h
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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
#import "ORSIS3302GenericModel.h"
#import "ORDataTypeAssigner.h"
#import "ORHWWizParam.h"
#import "ORHWWizSelection.h"
#import "ORVmeCrateModel.h"
#import "ORRateGroup.h"
#import "ORTimer.h"
#import "VME_HW_Definitions.h"
#import "ORVmeTests.h"
#import "ORVmeReadWriteCommand.h"
#import "ORCommandList.h"

ORSIS3302_IMPLEMENT_NOTIFY(FirmwareVersion);

ORSIS3302_IMPLEMENT_NOTIFY(PreTriggerDelay);

ORSIS3302_IMPLEMENT_NOTIFY(SampleLength);
ORSIS3302_IMPLEMENT_NOTIFY(DacOffset);

ORSIS3302_IMPLEMENT_NOTIFY(ClockSource);
ORSIS3302_IMPLEMENT_NOTIFY(TriggerOutEnabled);
ORSIS3302_IMPLEMENT_NOTIFY(Threshold);
ORSIS3302_IMPLEMENT_NOTIFY(Gt);
ORSIS3302_IMPLEMENT_NOTIFY(TrapFilterTrigger);

ORSIS3302_IMPLEMENT_NOTIFY(SettingsLock);
ORSIS3302_IMPLEMENT_NOTIFY(RateGroup);
ORSIS3302_IMPLEMENT_NOTIFY(SampleDone);
ORSIS3302_IMPLEMENT_NOTIFY(ID);

ORSIS3302_IMPLEMENT_NOTIFY(PulseLength);
ORSIS3302_IMPLEMENT_NOTIFY(SumG);
ORSIS3302_IMPLEMENT_NOTIFY(PeakingTime);
ORSIS3302_IMPLEMENT_NOTIFY(InternalTriggerDelay);

ORSIS3302_IMPLEMENT_NOTIFY(Averaging);
ORSIS3302_IMPLEMENT_NOTIFY(StopAtEvent);
ORSIS3302_IMPLEMENT_NOTIFY(EnablePageWrap);
ORSIS3302_IMPLEMENT_NOTIFY(PageWrapSize);
ORSIS3302_IMPLEMENT_NOTIFY(TestDataEnable);
ORSIS3302_IMPLEMENT_NOTIFY(TestDataType);

ORSIS3302_IMPLEMENT_NOTIFY(StartDelay);
ORSIS3302_IMPLEMENT_NOTIFY(StopDelay);
ORSIS3302_IMPLEMENT_NOTIFY(MaxEvents);
ORSIS3302_IMPLEMENT_NOTIFY(LemoTimestamp);
ORSIS3302_IMPLEMENT_NOTIFY(LemoStartStop);
ORSIS3302_IMPLEMENT_NOTIFY(InternalTrigStart);
ORSIS3302_IMPLEMENT_NOTIFY(InternalTrigStop);
ORSIS3302_IMPLEMENT_NOTIFY(MultiEventMode);
ORSIS3302_IMPLEMENT_NOTIFY(AutostartMode);

ORSIS3302_IMPLEMENT_NOTIFY(CardInited);

@interface ORSIS3302GenericModel (private)
- (void) writeDacOffsets;
- (void) setUpArrays;
- (NSMutableArray*) arrayOfLength:(int)len;
- (void) executeCommandList:(ORCommandList*) aList;
- (void) writePageRegister:(int) aPage;
- (void) writePreTriggerDelay;
- (void) writeDelaysAndMaxEvents;
- (void) writeAcquisitionRegister:(BOOL)forceAutostartOff;
- (void) writeEventConfiguration;
- (void) writeAdcInputMode;
- (void) writeThresholds;
- (void) writeTriggerSetups;
@end

@implementation ORSIS3302GenericModel
#pragma mark •••Static Declarations
//offsets from the base address
typedef struct {
	unsigned long offset;
	NSString* name;
} SIS3302GammaRegisterInformation;

#define kNumSIS3302GenReadRegs 70

static SIS3302GammaRegisterInformation register_information[kNumSIS3302GenReadRegs] = {
	{0x00000000,  @"Control/Status"},                         
	{0x00000004,  @"Module Id. and Firmware Revision"},                         
	{0x00000008,  @"Interrupt configuration"},                         
	{0x0000000C,  @"Interrupt control"},     
	{0x00000010,  @"Acquisition control/status"}, 
	{0x00000014,  @"Extern Start Delay"},     
	{0x00000018,  @"Extern Stop Delay"},         
	{0x00000020,  @"Max number of events"},     
	{0x00000024,  @"Actual Event counter"},             
	{0x00000030,  @"Broadcast Setup register"},                         
	{0x00000034,  @"ADC Memory Page register"},  
	{0x00000050,  @"DAC Control Status register"},                         
	{0x00000054,  @"DAC Data register"},    
	{0x00000060,  @"XILINX JTAG_TEST/JTAG_DATA_IN"},   
	
	//group 1
	{0x02000000,  @"Event configuration (ADC1, ADC2)"},    
	{0x02000004,  @"End Length (ADC1, ADC2)"},    
	{0x02000008,  @"Sample start address (ADC1, ADC2)"},    
	{0x0200000C,  @"ADC input mode (ADC1, ADC2)"},
	{0x02000010,  @"Next Sample address ADC1"},    
	{0x02000014,  @"Next Sample address ADC2"},    
	{0x02000020,  @"Actual Sample Value (ADC1, ADC2)"},    
	{0x02000024,  @"internal Test"},    
	{0x02000028,  @"DDR2 Memory Logic Verification (ADC1, ADC2)"},    
	{0x0200002C,  @"Triger flag clear (ADC1, ADC2)"},	
	{0x02000030,  @"Trigger Setup ADC1"},    
	{0x02000034,  @"Trigger Threshold ADC1"},   
	{0x02000038,  @"Trigger Setup ADC2"},    
	{0x0200003C,  @"Trigger Threshold ADC2"},   
		
	//group 2
	{0x02800000,  @"Event configuration (ADC3, ADC4)"},    
	{0x02800004,  @"End Length (ADC3, ADC4)"},    
	{0x02800008,  @"Sample start address (ADC3, ADC4)"},    
	{0x0280000C,  @"ADC input mode (ADC3, ADC4)"},
	{0x02800010,  @"Next Sample address ADC3"},    
	{0x02800014,  @"Next Sample address ADC4"},    
	{0x02800020,  @"Actual Sample Value (ADC3, ADC4)"},    
	{0x02800024,  @"internal Test"},    
	{0x02800028,  @"DDR2 Memory Logic Verification (ADC3, ADC4)"},    
	{0x0280002C,  @"Triger flag clear (ADC3, ADC4)"},	
	{0x02800030,  @"Trigger Setup ADC3"},    
	{0x02800034,  @"Trigger Threshold ADC3"},   
	{0x02800038,  @"Trigger Setup ADC4"},    
	{0x0280003C,  @"Trigger Threshold ADC4"},   
    
	//group 3
	{0x03000000,  @"Event configuration (ADC5, ADC6)"},    
	{0x03000004,  @"End Length (ADC5, ADC6)"},    
	{0x03000008,  @"Sample start address (ADC5, ADC6)"},    
	{0x0300000C,  @"ADC input mode (ADC5, ADC6)"},
	{0x03000010,  @"Next Sample address ADC5"},    
	{0x03000014,  @"Next Sample address ADC6"},    
	{0x03000020,  @"Actual Sample Value (ADC5, ADC6)"},    
	{0x03000024,  @"internal Test"},    
	{0x03000028,  @"DDR2 Memory Logic Verification (ADC5, ADC6)"},    
	{0x0300002C,  @"Triger flag clear (ADC5, ADC6)"},	
	{0x03000030,  @"Trigger Setup ADC5"},    
	{0x03000034,  @"Trigger Threshold ADC5"},   
	{0x03000038,  @"Trigger Setup ADC6"},    
	{0x0300003C,  @"Trigger Threshold ADC6"},   
	
	//group 4
	{0x03800000,  @"Event configuration (ADC7, ADC8)"},    
	{0x03800004,  @"End Length (ADC7, ADC8)"},    
	{0x03800008,  @"Sample start address (ADC7, ADC8)"},    
	{0x0380000C,  @"ADC input mode (ADC7, ADC8)"},
	{0x03800010,  @"Next Sample address ADC7"},    
	{0x03800014,  @"Next Sample address ADC8"},    
	{0x03800020,  @"Actual Sample Value (ADC7, ADC8)"},    
	{0x03800024,  @"internal Test"},    
	{0x03800028,  @"DDR2 Memory Logic Verification (ADC7, ADC8)"},    
	{0x0380002C,  @"Triger flag clear (ADC7, ADC8)"},	
	{0x03800030,  @"Trigger Setup ADC7"},    
	{0x03800034,  @"Trigger Threshold ADC7"},   
	{0x03800038,  @"Trigger Setup ADC8"},    
	{0x0380003C,  @"Trigger Threshold ADC8"}       
};

#pragma mark ***Initialization
- (id) init 
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setAddressModifier:0x09];
    [self setBaseAddress:0x08000000];
    [self initParams];
	
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc 
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	
	[pulseLengths release];
	[peakingTimes release];
 	[thresholds release];
	
    [dacOffsets release];
	[sumGs release];
    [preTriggerDelays release];

	[sampleLengths release];
	[averagingSettings release];
	[pageWrapSize release];
	[testDataType release];
	
	[waveFormRateGroup release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SIS3302Card"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORSIS3302GenericController"];
}

- (NSString*) helpURL
{
	return @"VME/SIS3302_(Gamma).html";
}

- (NSRange)	memoryFootprint
{
	return NSMakeRange(baseAddress, 0x00780000 + (8*0x1024*0x1024));
}

#pragma mark ***Accessors

- (float) firmwareVersion
{
    return firmwareVersion;
}

- (void) setFirmwareVersion:(float)aFirmwareVersion
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFirmwareVersion:firmwareVersion];
    
    firmwareVersion = aFirmwareVersion;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericFirmwareVersionChanged object:self];
}


- (void) setDefaults
{
	int i;
	for(i=0;i<8;i++){
		[self setThreshold:i withValue:0x64];
		[self setPeakingTime:i withValue:250];
		[self setSumG:i withValue:263];
		[self setDacOffset:i withValue:30000];
	}
	for(i=0;i<4;i++){
		[self setSampleLength:i withValue:2048];
		[self setPreTriggerDelay:i withValue:1];
	}
	
	[self setGtMask:0xff];
	
}

- (int) clockSource
{
    return clockSource;
}

- (void) setClockSource:(int)aClockSource
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSource:clockSource];
    clockSource = [self limitIntValue:aClockSource min:0 max:7];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericClockSourceChanged object:self];
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
    
    [[NSNotificationCenter defaultCenter]
	 postNotificationName:ORSIS3302GenericRateGroupChanged
	 object:self];    
}

- (id) rateObject:(int)channel
{
    return [waveFormRateGroup rateObject:channel];
}

- (void) initParams
{
	[self setUpArrays];
	[self setDefaults];
}

- (void) setRateIntegrationTime:(double)newIntegrationTime
{
	//we this here so we have undo/redo on the rate object.
    [[[self undoManager] prepareWithInvocationTarget:self] setRateIntegrationTime:[waveFormRateGroup integrationTime]];
    [waveFormRateGroup setIntegrationTime:newIntegrationTime];
}

- (unsigned long) getCounter:(int)counterTag forGroup:(int)groupTag
{
	if(groupTag == 0){
		if(counterTag>=0 && counterTag<kNumSIS3302Channels){
			return waveFormCount[counterTag];
		}	
		else return 0;
	}
	else return 0;
}

- (int) limitIntValue:(int)aValue min:(int)aMin max:(int)aMax
{
	if(aValue<aMin)return aMin;
	else if(aValue>aMax)return aMax;
	else return aValue;
}


//ORAdcInfoProviding protocol requirement
- (unsigned short) gain:(unsigned short) aChan
{
    return 0;
}
- (void) setGain:(unsigned short) aChan withValue:(unsigned short) aGain
{
}
- (BOOL) partOfEvent:(unsigned short)chan
{
	return (gtMask & (1L<<chan)) != 0;
}
- (BOOL)onlineMaskBit:(int)bit
{
	//translate back to the triggerEnabled Bit
	return (gtMask & (1L<<bit)) != 0;
}

- (short) gtMask { return gtMask; }
- (BOOL) gt:(short)chan	 { return (gtMask & (1<<chan)) != 0; }
- (void) setGtMask:(long)aMask	
{ 
	[[[self undoManager] prepareWithInvocationTarget:self] setGtMask:gtMask];
	gtMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericGtChanged object:self];
}

- (void) setGtBit:(short)chan withValue:(BOOL)aValue		
{ 
	unsigned char aMask = gtMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setGtMask:aMask];
}

- (short) useTrapTriggerMask { return useTrapTriggerMask; }
- (BOOL) useTrapTrigger:(short)chan
{
    if (chan > kNumSIS3302Channels) return NO;
    return (useTrapTriggerMask & (1<<chan)) != 0 ;
}
- (void) setUseTrapTriggerMask:(short)aMask
{
	[[[self undoManager] prepareWithInvocationTarget:self] setUseTrapTriggerMask:useTrapTriggerMask];
	useTrapTriggerMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericTrapFilterTriggerChanged object:self];

}
- (void) setUseTrapTriggerMask:(short)chan withValue:(BOOL)aValue
{ 
	unsigned char aMask = useTrapTriggerMask;
	if(aValue)aMask |= (1<<chan);
	else aMask &= ~(1<<chan);
	[self setUseTrapTriggerMask:aMask];
}

- (int) threshold:(short)aChan { return [[thresholds objectAtIndex:aChan]intValue]; }
- (void) setThreshold:(short)aChan withValue:(int)aValue 
{ 
	aValue = [self limitIntValue:aValue min:0 max:0x1FFFF];
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:aChan withValue:[self threshold:aChan]];
    [thresholds replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericThresholdChanged object:self];
	//ORAdcInfoProviding protocol requirement
	[self postAdcInfoProvidingValueChanged];
}

- (unsigned short) dacOffset:(short)aChan { return [[dacOffsets objectAtIndex:aChan]intValue]; }
- (void) setDacOffset:(short)aChan withValue:(int)aValue 
{
	aValue = [self limitIntValue:aValue min:0 max:0xffff];
    [[[self undoManager] prepareWithInvocationTarget:self] setDacOffset:aChan withValue:[self dacOffset:aChan]];
    [dacOffsets replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericDacOffsetChanged object:self];
}

- (short) pulseLength:(short)aChan { return [[pulseLengths objectAtIndex:aChan] shortValue]; }
- (void) setPulseLength:(short)aChan withValue:(short)aValue 
{ 
	aValue = [self limitIntValue:aValue min:0 max:0xff];
    [[[self undoManager] prepareWithInvocationTarget:self] setPulseLength:aChan withValue:[self pulseLength:aChan]];
    [pulseLengths replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericPulseLengthChanged object:self];
}

- (short) sumG:(short)aChan { return [[sumGs objectAtIndex:aChan] shortValue]; }
- (void) setSumG:(short)aChan withValue:(short)aValue 
{ 
	short temp = [self peakingTime:aChan];
	aValue = [self limitIntValue:aValue min:0 max:0x3ff];
    [[[self undoManager] prepareWithInvocationTarget:self] setSumG:aChan withValue:[self sumG:aChan]];
	if (aValue < temp) aValue = temp;
    [sumGs replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericSumGChanged object:self];
}

- (short) peakingTime:(short)aChan { return [[peakingTimes objectAtIndex:aChan] shortValue]; }
- (void) setPeakingTime:(short)aChan withValue:(short)aValue 
{ 
	short temp = [self sumG:aChan];
	aValue = [self limitIntValue:aValue min:0 max:0x3ff];
    [[[self undoManager] prepareWithInvocationTarget:self] setPeakingTime:aChan withValue:[self peakingTime:aChan]];
	if (temp < aValue) [self setSumG:aChan withValue:aValue];
    [peakingTimes replaceObjectAtIndex:aChan withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericPeakingTimeChanged object:self];
}

- (int) preTriggerDelay:(short)aGroup 
{ 
	if(aGroup>=4)return 0; 
	return [[preTriggerDelays objectAtIndex:aGroup]intValue]; 
}
- (void) setPreTriggerDelay:(short)aGroup withValue:(int)aPreTriggerDelay
{
	if(aGroup>=4)return; 
    [[[self undoManager] prepareWithInvocationTarget:self] setPreTriggerDelay:aGroup withValue:[self preTriggerDelay:aGroup]];
    int preTriggerDelay = [self limitIntValue:aPreTriggerDelay min:1 max:1023];
	
	[preTriggerDelays replaceObjectAtIndex:aGroup withObject:[NSNumber numberWithInt:preTriggerDelay]];
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericPreTriggerDelayChanged object:self];
}

// Buffer
- (unsigned int) sampleLength:(short)group
{
    if(group>=4)return 0; 
    return [[sampleLengths objectAtIndex:group] intValue];
}
- (void) setSampleLength:(short)group withValue:(int)aValue
{
    if(group>=4)return; 
    [[[self undoManager] prepareWithInvocationTarget:self] setSampleLength:group withValue:[self sampleLength:group]];
	aValue = [self limitIntValue:aValue min:4 max:0x1ffffff];
	aValue = (aValue/4)*4;
    [sampleLengths replaceObjectAtIndex:group withObject:[NSNumber numberWithInt:aValue]];
	//[self calculateSampleValues];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericSampleLengthChanged object:self];
}
- (EORSIS3302GenericAveraging) averagingType:(short)group
{
    if(group>=4)return 0; 
    return [[averagingSettings objectAtIndex:group] intValue];
}
- (void) setAveragingType:(short)group withValue:(EORSIS3302GenericAveraging)aValue
{
    if(group>=4)return; 
    [[[self undoManager] prepareWithInvocationTarget:self] setAveragingType:group withValue:[self averagingType:group]];
    [averagingSettings replaceObjectAtIndex:group withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericAveragingChanged object:self];
}
- (BOOL) stopEventAtLength:(short)group
{
    if(group>=4)return 0; 
    return (stopAtEventLengthMask & (1 << group)) != 0; 
}
- (void) setStopEventAtLength:(long)aMask	
{ 
	[[[self undoManager] prepareWithInvocationTarget:self] setStopEventAtLength:stopAtEventLengthMask];
	stopAtEventLengthMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericStopAtEventChanged object:self];
}
- (void) setStopEventAtLength:(short)group withValue:(BOOL)aValue
{
	unsigned char aMask = stopAtEventLengthMask;
	if(aValue)aMask |= (1<<group);
	else aMask &= ~(1<<group);
	[self setStopEventAtLength:aMask];

}
- (BOOL) pageWrap:(short)group
{
    if(group>=4)return 0; 
    return (enablePageWrapMask & (1 << group)) != 0; 
}
- (void) setPageWrap:(long)aMask	
{ 
	[[[self undoManager] prepareWithInvocationTarget:self] setPageWrap:enablePageWrapMask];
	enablePageWrapMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericEnablePageWrapChanged object:self];
}
- (void) setPageWrap:(short)group withValue:(BOOL)aValue
{
	unsigned char aMask = enablePageWrapMask;
	if(aValue)aMask |= (1<<group);
	else aMask &= ~(1<<group);
	[self setPageWrap:aMask];

}

- (EORSIS3302PageSize) pageWrapSize:(short)group
{
    if(group>=4)return 0; 
    return [[pageWrapSize objectAtIndex:group] intValue];
}
- (void) setPageWrapSize:(short)group withValue:(EORSIS3302PageSize)aValue
{
    if(group>=4)return; 
    [[[self undoManager] prepareWithInvocationTarget:self] setPageWrapSize:group withValue:[self pageWrapSize:group]];
    [pageWrapSize replaceObjectAtIndex:group withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericPageWrapSizeChanged object:self];
}

- (BOOL) enableTestData:(short)group
{
    if(group>=4)return 0; 
    return ((enableTestDataMask & (1 << group)) != 0); 
}
- (void) setEnableTestData:(long)aMask
{ 
	[[[self undoManager] prepareWithInvocationTarget:self] setEnableTestData:enableTestDataMask];
	enableTestDataMask = aMask;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericTestDataEnableChanged object:self];
}
- (void) setEnableTestData:(short)group withValue:(BOOL)aValue
{
	unsigned char aMask = enableTestDataMask;
	if(aValue)aMask |= (1<<group);
	else aMask &= ~(1<<group);
	[self setEnableTestData:aMask];
}
- (EORSIS3302TestDataType) testDataType:(short)group
{
    if(group>=4)return 0; 
    return [[testDataType objectAtIndex:group] intValue];
}
- (void) setTestDataType:(short)group withValue:(EORSIS3302TestDataType)aValue
{
    if(group>=4)return; 
    [[[self undoManager] prepareWithInvocationTarget:self] setTestDataType:group withValue:[self testDataType:group]];
    [testDataType replaceObjectAtIndex:group withObject:[NSNumber numberWithInt:aValue]];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericTestDataTypeChanged object:self];
}
// Trigger/Lemo configuration
@synthesize startDelay;
@synthesize stopDelay;    
@synthesize maxEvents;
@synthesize lemoTimestampEnabled;
@synthesize lemoStartStopEnabled;    
@synthesize internalTrigStartEnabled;
@synthesize internalTrigStopEnabled;    
@synthesize multiEventModeEnabled;
@synthesize autostartModeEnabled;    

- (void) setStartDelay:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStartDelay:[self startDelay]];
    startDelay = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericStartDelayChanged object:self];
}
- (void) setStopDelay:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStopDelay:[self stopDelay]];
    stopDelay = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericStopDelayChanged object:self];
}

- (void) setMaxEvents:(int)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxEvents:[self maxEvents]];
    maxEvents = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericMaxEventsChanged object:self];
}

- (void) setLemoTimestampEnabled:(BOOL)aVal
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoTimestampEnabled:[self lemoTimestampEnabled]];
    lemoTimestampEnabled = aVal;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericLemoTimestampChanged object:self];
}

- (void) setLemoStartStopEnabled:(BOOL)aVal    
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLemoStartStopEnabled:[self lemoStartStopEnabled]];
    lemoStartStopEnabled = aVal;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericLemoStartStopChanged object:self];
}

- (void) setInternalTrigStartEnabled:(BOOL)aVal
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInternalTrigStartEnabled:[self internalTrigStartEnabled]];
    internalTrigStartEnabled = aVal;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericInternalTrigStartChanged object:self];
}

- (void) setInternalTrigStopEnabled:(BOOL)aVal    
{
    [[[self undoManager] prepareWithInvocationTarget:self] setInternalTrigStopEnabled:[self internalTrigStopEnabled]];
    internalTrigStopEnabled = aVal;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericInternalTrigStopChanged object:self];
}

- (void) setMultiEventModeEnabled:(BOOL)aVal
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMultiEventModeEnabled:[self multiEventModeEnabled]];
    multiEventModeEnabled = aVal;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericMultiEventModeChanged object:self];
}

- (void) setAutostartModeEnabled:(BOOL)aVal    
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAutostartModeEnabled:[self autostartModeEnabled]];
    autostartModeEnabled = aVal;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericAutostartModeChanged object:self];
}

	
#pragma mark •••Reg Declarations

- (unsigned long) getPreTriggerDelayOffset:(int) aGroup 
{
    switch (aGroup) {
        case 0: return kSIS3302GenericPreTriggerDelayAdc12;
        case 1: return kSIS3302GenericPreTriggerDelayAdc34;
        case 2: return kSIS3302GenericPreTriggerDelayAdc56;
        case 3: return kSIS3302GenericPreTriggerDelayAdc78;
    }
    return (unsigned long)-1;
}

- (unsigned long) getADCBufferRegisterOffset:(int) channel 
{
    switch (channel) {
        case 0: return kSIS3302Adc1Offset;
        case 1: return kSIS3302Adc2Offset;
        case 2: return kSIS3302Adc3Offset;
        case 3: return kSIS3302Adc4Offset;
        case 4: return kSIS3302Adc5Offset;
        case 5: return kSIS3302Adc6Offset;
        case 6: return kSIS3302Adc7Offset;
        case 7: return kSIS3302Adc8Offset;
    }
    return (unsigned long) -1;
}

- (unsigned long) getThresholdRegOffsets:(int) channel 
{
    switch (channel) {
        case 0: return 	kSIS3302TriggerThresholdAdc1;
		case 1: return 	kSIS3302TriggerThresholdAdc2;
		case 2: return 	kSIS3302TriggerThresholdAdc3;
		case 3: return 	kSIS3302TriggerThresholdAdc4;
		case 4:	return 	kSIS3302TriggerThresholdAdc5;
		case 5: return 	kSIS3302TriggerThresholdAdc6;
		case 6: return 	kSIS3302TriggerThresholdAdc7;
		case 7: return 	kSIS3302TriggerThresholdAdc8;
    }
    return (unsigned long) -1;
}

- (unsigned long) getTriggerSetupRegOffsets:(int) channel 
{
    switch (channel) {
		case 0: return 	kSIS3302TriggerSetupAdc1;
		case 1: return 	kSIS3302TriggerSetupAdc2;
		case 2: return 	kSIS3302TriggerSetupAdc3;
		case 3: return 	kSIS3302TriggerSetupAdc4;
		case 4: return 	kSIS3302TriggerSetupAdc5;
		case 5: return 	kSIS3302TriggerSetupAdc6;
		case 6: return 	kSIS3302TriggerSetupAdc7;
		case 7: return 	kSIS3302TriggerSetupAdc8;
    }
    return (unsigned long) -1;
}

- (unsigned long) getEventDirectoryForChannel:(int) channel 
{
    switch (channel) {
		case 0: return 	kSIS3302GenericEventDirectoryAdc1;
		case 1: return 	kSIS3302GenericEventDirectoryAdc2;
		case 2: return 	kSIS3302GenericEventDirectoryAdc3;
		case 3: return 	kSIS3302GenericEventDirectoryAdc4;
		case 4: return 	kSIS3302GenericEventDirectoryAdc5;
		case 5: return 	kSIS3302GenericEventDirectoryAdc6;
		case 6: return 	kSIS3302GenericEventDirectoryAdc7;
		case 7: return 	kSIS3302GenericEventDirectoryAdc8;
    }
    return (unsigned long) -1;
}

- (unsigned long) getNextSampleAddressForChannel:(int) channel 
{
    switch (channel) {
		case 0: return 	kSIS3302ActualSampleAddressAdc1;
		case 1: return 	kSIS3302ActualSampleAddressAdc2;
		case 2: return 	kSIS3302ActualSampleAddressAdc3;
		case 3: return 	kSIS3302ActualSampleAddressAdc4;
		case 4: return 	kSIS3302ActualSampleAddressAdc5;
		case 5: return 	kSIS3302ActualSampleAddressAdc6;
		case 6: return 	kSIS3302ActualSampleAddressAdc7;
		case 7: return 	kSIS3302ActualSampleAddressAdc8;
    }
    return (unsigned long) -1;
}

- (unsigned long) getEventConfigOffsets:(int)group
{
	switch (group) {
		case 0: return kSIS3302EventConfigAdc12;
		case 1: return kSIS3302EventConfigAdc34;
		case 2: return kSIS3302EventConfigAdc56;
		case 3: return kSIS3302EventConfigAdc78;
	}
	return (unsigned long) -1;	 
}

- (unsigned long) getEventLengthOffsets:(int)group
{
	switch (group) {
		case 0: return kSIS3302GenericSampleLengthAdc12;
		case 1: return kSIS3302GenericSampleLengthAdc34;
		case 2: return kSIS3302GenericSampleLengthAdc56;
		case 3: return kSIS3302GenericSampleLengthAdc78;
	}
	return (unsigned long) -1;	 
}

- (unsigned long) getSampleStartOffsets:(int)group
{
	switch (group) {
		case 0: return kSIS3302GenericSampleStartAdc12;
		case 1: return kSIS3302GenericSampleStartAdc34;
		case 2: return kSIS3302GenericSampleStartAdc56;
		case 3: return kSIS3302GenericSampleStartAdc78;
	}
	return (unsigned long) -1;	 
}

- (unsigned long) getAdcInputModeOffsets:(int)group
{
	switch (group) {
		case 0: return kSIS3302GenericAdcInputModeAdc12;
		case 1: return kSIS3302GenericAdcInputModeAdc34;
		case 2: return kSIS3302GenericAdcInputModeAdc56;
		case 3: return kSIS3302GenericAdcInputModeAdc78;
	}
	return (unsigned long) -1;	 
}

- (unsigned long) getAdcMemory:(int)channel
{
    switch (channel) {			
		case 0: return 	kSIS3302Adc1Offset;
		case 1: return 	kSIS3302Adc2Offset;
		case 2: return 	kSIS3302Adc3Offset;
		case 3: return 	kSIS3302Adc4Offset;
		case 4: return 	kSIS3302Adc5Offset;
		case 5: return 	kSIS3302Adc6Offset;
		case 6: return 	kSIS3302Adc7Offset;
		case 7: return 	kSIS3302Adc8Offset;
 	}
	return (unsigned long) -1;	 
}

#pragma mark •••Hardware Access
- (void) readModuleID:(BOOL)verbose
{	
	unsigned long result = 0;
	[[self adapter] readLongBlock:&result
						atAddress:[self baseAddress] + kSIS3302ModID
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	unsigned long moduleID = result >> 16;
	unsigned short majorRev = (result >> 8) & 0xff;
	unsigned short minorRev = result & 0xff;
	NSString* s = [NSString stringWithFormat:@"%x.%x",majorRev,minorRev];
	[self setFirmwareVersion:[s floatValue]];
	if(verbose){
		NSLog(@"SIS3302 ID: %x  Firmware:%.2f\n",moduleID,firmwareVersion);
		if(moduleID != 0x3302)NSLogColor([NSColor redColor], @"Warning: HW mismatch. 3302 object is 0x%x HW\n",moduleID);
	}
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericIDChanged object:self];
}

- (void) setLed:(BOOL)state
{
	unsigned long aValue = CSRMask(state,kSISLed);
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3302ControlStatus
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) clearTimeStamp
{
	unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3302GenericKeyTimestampClear
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) forceTrigger
{
    unsigned long aValue = 0;
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3302GenericKeyArmSampleLogic
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3302GenericKeySampling
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];    
}

- (unsigned long) acqReg
{
 	unsigned long aValue = 0;
	[[self adapter] readLongBlock:&aValue
						atAddress:[self baseAddress] + kSIS3302AcquisitionControl
                        numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];
	return aValue;
}

- (void) readThresholds:(BOOL)verbose
{   
	int i;
	if(verbose) NSLog(@"Reading Thresholds:\n");
	
	for(i =0; i < kNumSIS3302Channels; i++) {
		unsigned long aValue;
		[[self adapter] readLongBlock: &aValue
							atAddress: [self baseAddress] + [self getThresholdRegOffsets:i]
							numToRead: 1
						   withAddMod: [self addressModifier]
						usingAddSpace: 0x01];
		
		if(verbose){
			unsigned short thresh = (aValue&0xffff);
			BOOL triggerDisabled  = (aValue>>26) & 0x1;
			BOOL triggerModeGT    = (aValue>>25) & 0x1;
			NSLog(@"%d: %8s %2s 0x%4x\n",i, triggerDisabled ? "Trig Out Disabled": "Trig Out Enabled",  triggerModeGT?"GT":"  " ,thresh);
		}
	}
}

- (void) regDump
{
	@try {
		NSFont* font = [NSFont fontWithName:@"Monaco" size:11];
		NSLogFont(font,@"Reg Dump for SIS3302 (Slot %d)\n",[self slot]);
		NSLogFont(font,@"-----------------------------------\n");
		NSLogFont(font,@"[Add Offset]   Value        Name\n");
		NSLogFont(font,@"-----------------------------------\n");
		
		ORCommandList* aList = [ORCommandList commandList];
		int i;
		for(i=0;i<kNumSIS3302GenReadRegs;i++){
			[aList addCommand: [ORVmeReadWriteCommand readLongBlockAtAddress: [self baseAddress] + register_information[i].offset
																   numToRead: 1
																  withAddMod: [self addressModifier]
															   usingAddSpace: 0x01]];
		}
		[self executeCommandList:aList];
		
		//if we get here, the results can retrieved in the same order as sent
		for(i=0;i<kNumSIS3302GenReadRegs;i++){
			NSLogFont(font, @"[0x%08x] 0x%08x    %@\n",register_information[i].offset,[aList longValueForCmd:i],register_information[i].name);
		}
		
	}
	@catch(NSException* localException) {
        NSLog(@"SIS3302 Reg Dump FAILED.\n");
        ORRunAlertPanel([localException name], @"%@\nSIS3302 Reg Dump FAILED", @"OK", nil, nil,
                        localException);
    }
}

- (void) briefReport
{
	[self readThresholds:YES];
	
	unsigned long EventConfig = 0;
	[[self adapter] readLongBlock:&EventConfig
						atAddress:[self baseAddress] +kSIS3302EventConfigAdc12
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];	
	NSLog(@"EventConfig: 0x%08x\n",EventConfig);
	
	unsigned long pretrigger = 0;
	[[self adapter] readLongBlock:&pretrigger
						atAddress:[self baseAddress] + kSIS3302GenericPreTriggerDelayAdc12
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];	
	
	NSLog(@"pretrigger: 0x%08x\n",pretrigger);
	
	unsigned long sampleLength1 = 0;
	[[self adapter] readLongBlock:&sampleLength1
						atAddress:[self baseAddress] + kSIS3302GenericSampleLengthAdc12
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];	
	
	NSLog(@"Sample length: 0x%08x\n",sampleLength1);
	
	unsigned long sampleStart = 0;
	[[self adapter] readLongBlock:&sampleStart
						atAddress:[self baseAddress] + kSIS3302GenericSampleStartAdc12
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];	
	
	NSLog(@"Sample start: 0x%08x\n",sampleStart);
	
	unsigned long prevNextSampleAddress1 = 0;
	[[self adapter] readLongBlock:&prevNextSampleAddress1
						atAddress:[self baseAddress] + kSIS3302ActualSampleAddressAdc1
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];	
	
	NSLog(@"prevNextSampleAddress1: 0x%08x\n",prevNextSampleAddress1);
	
	unsigned long prevNextSampleAddress2 = 0;
	[[self adapter] readLongBlock:&prevNextSampleAddress2
						atAddress:[self baseAddress] + kSIS3302ActualSampleAddressAdc2
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];	
	
	NSLog(@"prevNextSampleAddress2: 0x%08x\n",prevNextSampleAddress2);
	
	unsigned long triggerSetup1 = 0;
	[[self adapter] readLongBlock:&triggerSetup1
						atAddress:[self baseAddress] + kSIS3302TriggerSetupAdc1
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];	
	
	NSLog(@"triggerSetup1: 0x%08x\n",triggerSetup1);
	
	unsigned long triggerSetup2 = 0;
	[[self adapter] readLongBlock:&triggerSetup2
						atAddress:[self baseAddress] + kSIS3302TriggerSetupAdc2
						numToRead:1
					   withAddMod:[self addressModifier]
					usingAddSpace:0x01];	
	
	NSLog(@"triggerSetup2: 0x%08x\n",triggerSetup2);
}

- (void) initBoard
{  

	[self readModuleID:NO];
    [self writeAdcInputMode];    
	[self writeEventConfiguration];
	[self writePreTriggerDelay];
	[self writeTriggerSetups];
	[self writeThresholds];
	[self writeDacOffsets];
	[self resetSamplingLogic];
	[self writeDelaysAndMaxEvents];
	[self writeAcquisitionRegister:NO];			//set up the Acquisition Register
	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSIS3302GenericCardInitedChanged object:self];
	
}

#pragma mark •••Data Taker
- (unsigned long) lostDataId { return lostDataId; }
- (void) setLostDataId: (unsigned long) anId
{
    lostDataId = anId;
}

- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId   = [assigner assignDataIds:kLongForm]; 
    lostDataId  = [assigner assignDataIds:kLongForm]; 
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
	NSDictionary* aDictionary;
	
    aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
				   @"ORSIS3302GenericDecoderForWaveform",				@"decoder",
				   [NSNumber numberWithLong:dataId],@"dataId",
				   [NSNumber numberWithBool:YES],   @"variable",
				   [NSNumber numberWithLong:-1],	@"length",
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
    return kNumSIS3302Channels;
}

- (NSArray*) wizardParameters
{
    NSMutableArray* a = [NSMutableArray array];
    ORHWWizParam* p;
  	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Run Mode"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setRunMode:) getMethod:@selector(runMode)];
    [a addObject:p];

	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"GT"];
    [p setFormat:@"##0" upperLimit:1 lowerLimit:0 stepSize:1 units:@"BOOL"];
    [p setSetMethod:@selector(setGtBit:withValue:) getMethod:@selector(gt:)];
    [a addObject:p];
			
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Clock Source"];
    [p setFormat:@"##0" upperLimit:7 lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setClockSource:) getMethod:@selector(clockSource)];
    [p setActionMask:kAction_Set_Mask];
    [a addObject:p];
	
    p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Threshold"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setThreshold:withValue:) getMethod:@selector(threshold:)];
	[p setCanBeRamped:YES];
    [a addObject:p];
		
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pulse Length"];
    [p setFormat:@"##0" upperLimit:0xff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPulseLength:withValue:) getMethod:@selector(pulseLength:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Sum G"];
    [p setFormat:@"##0" upperLimit:0x3ff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setSumG:withValue:) getMethod:@selector(sumG:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Peaking Time"];
    [p setFormat:@"##0" upperLimit:0x3ff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPeakingTime:withValue:) getMethod:@selector(peakingTime:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Dac Offset"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:0 stepSize:1 units:@""];
    [p setSetMethod:@selector(setDacOffset:withValue:) getMethod:@selector(dacOffset:)];
    [a addObject:p];
		
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Sample Length"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:4 stepSize:1 units:@""];
    [p setSetMethod:@selector(setSampleLength:withValue:) getMethod:@selector(sampleLength:)];
    [a addObject:p];
	
	p = [[[ORHWWizParam alloc] init] autorelease];
    [p setName:@"Pretrigger Delay"];
    [p setFormat:@"##0" upperLimit:0xffff lowerLimit:1 stepSize:1 units:@""];
    [p setSetMethod:@selector(setPreTriggerDelay:withValue:) getMethod:@selector(preTriggerDelay:)];
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
    [a addObject:[ORHWWizSelection itemAtLevel:kObjectLevel name:@"Card" className:@"ORSIS3302GenericModel"]];
    [a addObject:[ORHWWizSelection itemAtLevel:kChannelLevel name:@"Channel" className:@"ORSIS3302GenericModel"]];
    return a;
}

- (NSNumber*) extractParam:(NSString*)param from:(NSDictionary*)fileHeader forChannel:(int)aChannel
{
	NSDictionary* cardDictionary = [self findCardDictionaryInHeader:fileHeader];
	if([param isEqualToString:@"Threshold"])						return [[cardDictionary objectForKey:@"thresholds"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"PulseLength"])					return [[cardDictionary objectForKey:@"pulseLengths"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"SumG"])						return [[cardDictionary objectForKey:@"sumGs"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"PeakingTime"])					return [[cardDictionary objectForKey:@"peakingTimes"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"InternalTriggerDelay"])		return [[cardDictionary objectForKey:@"internalTriggerDelays"] objectAtIndex:aChannel];
	else if([param isEqualToString:@"Dac Offset"])					return [[cardDictionary objectForKey:@"dacOffsets"] objectAtIndex:aChannel];
    else if([param isEqualToString:@"Clock Source"])				return [cardDictionary objectForKey:@"clockSource"];
    else if([param isEqualToString:@"Run Mode"])					return [cardDictionary objectForKey:@"runMode"];
    else if([param isEqualToString:@"GT"])							return [cardDictionary objectForKey:@"gtMask"];
    else if([param isEqualToString:@"Buffer Wrap Enabled"])			return [cardDictionary objectForKey:@"bufferWrapEnabledMask"];
    else if([param isEqualToString:@"Trigger Gate Delay"])			return [cardDictionary objectForKey:@"triggerGateLength"];
    else if([param isEqualToString:@"Pretrigger Delay"])			return [cardDictionary objectForKey:@"preTriggerDelay"];
    else if([param isEqualToString:@"Sample Length"])				return [cardDictionary objectForKey:@"sampleLength"];
	else return nil;
}

#pragma mark •••DataTaking
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(![[self adapter] controllerCard]){
        [NSException raise:@"Not Connected" format:@"You must connect to a PCI Controller (i.e. a 617)."];
    }
    
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORSIS3302Generic"];    
    
    //cache some stuff
    location        = (([self crateNumber]&0x0000000f)<<21) | (([self slot]& 0x0000001f)<<16);
    theController   = [self adapter];
    
	[self reset];
	[self initBoard];

	[self setLed:YES];
	[self clearTimeStamp];
	
	isRunning	= NO;
	count=0;
    [self startRates];
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	//reading events from the mac is very, very slow. If the buffer is filling up, it can take a long time to readout all events.
	//Because of this we limit the number of events from any one buffer read. The SBC should be used if possible.
    const unsigned totalPageSize = 0x800000;
    const unsigned totalPageNumberMask = totalPageSize - 1;
    const unsigned maxSubWaveformLength = kMaxSIS3302SingleMaxRecord - 4;
    @try {
        unsigned long check;
        unsigned long checkTwo;
        [theController readLongBlock:&check
                            atAddress:[self baseAddress] + kSIS3302AcquisitionControl
                            numToRead:1
                           withAddMod:addressModifier
                        usingAddSpace:0x01];
        if ( (check & 0x10000) != 0 ) {
            // this means we are sampling
            // in principle, we should be able to read out, but we wait.
            return;
        }

        // otherwise we have data, try to read it out.
        int chan;
        for (chan=0;chan<kNumSIS3302Channels;chan++) {
            [theController readLongBlock:&checkTwo
                               atAddress:[self baseAddress] + [self getNextSampleAddressForChannel:chan]
                               numToRead:1
                              withAddMod:addressModifier
                           usingAddSpace:0x01];
            
            [theController readLongBlock:&check
                                atAddress:[self baseAddress] + [self getEventDirectoryForChannel:chan]
                                numToRead:1
                               withAddMod:addressModifier
                            usingAddSpace:0x01];            
            // Total number of longs
            check &= 0x1FFFFFC;            
            if (checkTwo == 0 || checkTwo != check) return;
        }
        BOOL needsReset = NO;
        for (chan=0;chan<kNumSIS3302Channels;chan++) {
            
            [theController readLongBlock:&check
                               atAddress:[self baseAddress] + [self getEventDirectoryForChannel:chan]
                               numToRead:1
                              withAddMod:addressModifier
                           usingAddSpace:0x01];            
            // Total number of longs
            check &= 0x1FFFFFC;            
            if (check == 0) continue;
            needsReset = YES;

            unsigned long pageNumberTag = 0;
            unsigned long readLongs = 0;
            unsigned int readAtAddress = 0;
            unsigned int longsToRead = check/2;
            for (;readLongs < longsToRead;readLongs += maxSubWaveformLength) {
                // Get the next number of longs to read
                unsigned int nextToRead = (longsToRead - readLongs > maxSubWaveformLength) ? maxSubWaveformLength : (longsToRead - readLongs);
 
                unsigned int tempToRead = nextToRead;
                unsigned int ptrOffset = 0;
                while (tempToRead > 0) {
                    unsigned long pageNumber = (readAtAddress >> 23) & 0x7;
                    [theController writeLongBlock:&pageNumber
                                        atAddress:[self baseAddress] + kSIS3302AdcMemoryPageRegister
                                        numToWrite:1
                                       withAddMod:addressModifier
                                    usingAddSpace:0x01];  
                    unsigned int bytesToRead = (4*tempToRead & totalPageNumberMask);
                    unsigned int addrToRead = [self baseAddress] + [self getAdcMemory:chan] + (readAtAddress & totalPageNumberMask);
                    if (((bytesToRead + (readAtAddress & totalPageNumberMask)) > totalPageNumberMask)) {
                        bytesToRead = totalPageNumberMask - (readAtAddress & totalPageNumberMask) + 1;
                    }
                    [theController readLongBlock:&dataRecord[4 + ptrOffset]
                                        atAddress:addrToRead
                                        numToRead:bytesToRead/4
                                       withAddMod:0x8
                                    usingAddSpace:0x01]; 
                    readAtAddress += bytesToRead;
                    ptrOffset += bytesToRead/4;                    
                    tempToRead -= bytesToRead/4;

                }
                dataRecord[0] = dataId | nextToRead + 4;
                dataRecord[1] =	location | ((chan & 0x000000ff)<<8);                
                dataRecord[2] = pageNumberTag++;
                dataRecord[3] = longsToRead;
                
                [aDataPacket addLongsToFrameBuffer:&dataRecord[0] length:(nextToRead+4)];
            }
             
        }
        
        // reset the sampling logic, allow everything to go back to 0.
        if (needsReset) [self resetSamplingLogic];
        
        
	}
	@catch(NSException* localException) {
		[self incExceptionCount];
		[localException raise];
	}
}


- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
	isRunning = NO;
	
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{

    [waveFormRateGroup stop];
	[self setLed:NO];
	
}

//this is the data structure for the new SBCs (i.e. VX704 from Concurrent)
- (int) load_HW_Config_Structure:(SBC_crate_config*)configStruct index:(int)index
{
	configStruct->total_cards++;
	configStruct->card_info[index].hw_type_id				= kSIS3302; //should be unique
	configStruct->card_info[index].hw_mask[0]				= dataId;	//better be unique
	configStruct->card_info[index].hw_mask[1]				= lostDataId;	//better be unique
	configStruct->card_info[index].slot						= [self slot];
	configStruct->card_info[index].crate					= [self crateNumber];
	configStruct->card_info[index].add_mod					= [self addressModifier];
	configStruct->card_info[index].base_add					= [self baseAddress];
	configStruct->card_info[index].deviceSpecificData[0]	= [self sampleLength:0]/2;
	configStruct->card_info[index].deviceSpecificData[1]	= [self sampleLength:1]/2;
	configStruct->card_info[index].deviceSpecificData[2]	= [self sampleLength:2]/2;
	configStruct->card_info[index].deviceSpecificData[3]	= [self sampleLength:3]/2;
	configStruct->card_info[index].deviceSpecificData[4]	= 0;
	configStruct->card_info[index].deviceSpecificData[5]	= 0;
	configStruct->card_info[index].deviceSpecificData[6]	= 0;
	
	configStruct->card_info[index].num_Trigger_Indexes		= 0;
	
	configStruct->card_info[index].next_Card_Index 	= index+1;	
	
	return index+1;
	
}

- (void) reset
{
 	unsigned long aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3302KeyReset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
}

- (void) resetSamplingLogic
{
    // First turn off autostart if it's on
    [self writeAcquisitionRegister:YES];
    
 	unsigned long aValue = 0; //value doesn't matter 
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3302KeyDisarm
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3302KeySampleLogicReset
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
    
	[[self adapter] writeLongBlock:&aValue
                         atAddress:[self baseAddress] + kSIS3302KeyDisarm
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];    
    [self writeAcquisitionRegister:NO];
    
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
    for(i=0;i<kNumSIS3302Channels;i++){
        waveFormCount[i]=0;
    }
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	
    [self setFirmwareVersion:			[decoder decodeFloatForKey:@"firmwareVersion"]];
	

    [self setClockSource:				[decoder decodeIntForKey:@"clockSource"]];
	[self setGtMask:					[decoder decodeIntForKey:@"gtMask"]];
	[self setUseTrapTriggerMask:		[decoder decodeIntForKey:@"trapMask"]];    
    [self setWaveFormRateGroup:			[decoder decodeObjectForKey:@"waveFormRateGroup"]];
    [self setStopEventAtLength:         [decoder decodeIntForKey:@"stopEventAtLength"]];
    [self setPageWrap:                  [decoder decodeIntForKey:@"enablePageWrap"]];
    [self setEnableTestData:            [decoder decodeIntForKey:@"enableTestData"]];    
    [self setLemoTimestampEnabled:            [decoder decodeIntForKey:@"lemoTimestampEnabled"]];    
    [self setLemoStartStopEnabled:            [decoder decodeIntForKey:@"lemoStartStopEnabled"]];    
    [self setInternalTrigStartEnabled:        [decoder decodeIntForKey:@"internalTrigStartEnabled"]];    
    [self setInternalTrigStopEnabled:         [decoder decodeIntForKey:@"internalTrigStopEnabled"]];    
    [self setMultiEventModeEnabled:           [decoder decodeIntForKey:@"multiEventModeEnabled"]];    
    [self setAutostartModeEnabled:            [decoder decodeIntForKey:@"autostartModeEnabled"]];    
    [self setStartDelay:                      [decoder decodeIntForKey:@"startDelay"]];    
    [self setStopDelay:                       [decoder decodeIntForKey:@"stopDelay"]];    
    [self setMaxEvents:                       [decoder decodeIntForKey:@"maxEvents"]];    
	
    sampleLengths = 			[[decoder decodeObjectForKey:@"sampleLengths"]retain];
   
	thresholds  =				[[decoder decodeObjectForKey:@"thresholds"] retain];
    dacOffsets  =				[[decoder decodeObjectForKey:@"dacOffsets"] retain];
	pulseLengths =				[[decoder decodeObjectForKey:@"pulseLengths"] retain];
	sumGs =						[[decoder decodeObjectForKey:@"sumGs"] retain];
	peakingTimes =				[[decoder decodeObjectForKey:@"peakingTimes"] retain];
    preTriggerDelays =			[[decoder decodeObjectForKey:@"preTriggerDelays"] retain];

    averagingSettings=			[[decoder decodeObjectForKey:@"averagingSettings"] retain];
	
    pageWrapSize =			[[decoder decodeObjectForKey:@"pageWrapSize"] retain];
    
    testDataType =			[[decoder decodeObjectForKey:@"testDataType"] retain];
    
	//force a constraint check by reloading the pretrigger delays
	int aGroup;
	for(aGroup=0;aGroup<4;aGroup++){
		[self setPreTriggerDelay:aGroup withValue:[self preTriggerDelay:aGroup]];
	}
	
	//firmware 15xx
	if(!waveFormRateGroup){
		[self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3302Channels groupTag:0] autorelease]];
	    [waveFormRateGroup setIntegrationTime:5];
    }
    [waveFormRateGroup resetRates];
    [waveFormRateGroup calcRates];
	
	[self setUpArrays];
	
    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	
	[encoder encodeFloat:firmwareVersion		forKey:@"firmwareVersion"];

    [encoder encodeInt:gtMask					forKey:@"gtMask"];
	[encoder encodeInt:useTrapTriggerMask       forKey:@"trapMask"];        
    [encoder encodeInt:clockSource				forKey:@"clockSource"];
    
    [encoder encodeInt:stopAtEventLengthMask    forKey:@"stopEventAtLength"];
    [encoder encodeInt:enablePageWrapMask       forKey:@"enablePageWrap"];
    [encoder encodeInt:enableTestDataMask       forKey:@"enableTestData"]; 
    
    [encoder encodeObject:waveFormRateGroup		forKey:@"waveFormRateGroup"];
	[encoder encodeObject:thresholds			forKey:@"thresholds"];
	[encoder encodeObject:dacOffsets			forKey:@"dacOffsets"];
	[encoder encodeObject:pulseLengths			forKey:@"pulseLengths"];
	[encoder encodeObject:sumGs					forKey:@"sumGs"];
	[encoder encodeObject:peakingTimes			forKey:@"peakingTimes"];
	[encoder encodeObject:preTriggerDelays		forKey:@"preTriggerDelays"];
	[encoder encodeObject:sampleLengths			forKey:@"sampleLengths"];    
    

    [encoder encodeObject:averagingSettings forKey:@"averagingSettings"];	
    [encoder encodeObject:pageWrapSize forKey:@"pageWrapSize"];
    [encoder encodeObject:testDataType forKey:@"testDataType"];

    [encoder encodeInt:lemoTimestampEnabled   forKey:@"lemoTimestampEnabled"];    
    [encoder encodeInt:lemoStartStopEnabled   forKey:@"lemoStartStopEnabled"];    
    [encoder encodeInt:internalTrigStartEnabled   forKey:@"internalTrigStartEnabled"];    
    [encoder encodeInt:internalTrigStopEnabled   forKey:@"internalTrigStopEnabled"];    
    [encoder encodeInt:multiEventModeEnabled   forKey:@"multiEventModeEnabled"];    
    [encoder encodeInt:autostartModeEnabled   forKey:@"autostartModeEnabled"];    
    [encoder encodeInt:startDelay   forKey:@"startDelay"];    
    [encoder encodeInt:stopDelay   forKey:@"stopDelay"];    
    [encoder encodeInt:maxEvents   forKey:@"maxEvents"];    
	
	
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	
    [objDictionary setObject: [NSNumber numberWithLong:gtMask]						forKey:@"gtMask"];	
	[objDictionary setObject: [NSNumber numberWithInt:clockSource]					forKey:@"clockSource"];
 	
	
	[objDictionary setObject:sampleLengths		forKey:@"sampleLengths"];
	[objDictionary setObject: dacOffsets		forKey:@"dacOffsets"];
    [objDictionary setObject: thresholds		forKey:@"thresholds"];		
    [objDictionary setObject: pulseLengths		forKey:@"pulseLengths"];	
    [objDictionary setObject: sumGs				forKey:@"sumGs"];	
    [objDictionary setObject: peakingTimes		forKey:@"peakingTimes"];	
	[objDictionary setObject: preTriggerDelays		forKey:@"preTriggerDelays"];
    
    [objDictionary setObject:averagingSettings forKey:@"averagingSettings"];	
    [objDictionary setObject:pageWrapSize forKey:@"pageWrapSize"];
    [objDictionary setObject:testDataType forKey:@"testDataType"];	
    
    [objDictionary setObject:[NSNumber numberWithInt:lemoTimestampEnabled]  forKey:@"lemoTimestampEnabled"];    
    [objDictionary setObject:[NSNumber numberWithInt:lemoStartStopEnabled]  forKey:@"lemoStartStopEnabled"];    
    [objDictionary setObject:[NSNumber numberWithInt:internalTrigStartEnabled]  forKey:@"internalTrigStartEnabled"];    
    [objDictionary setObject:[NSNumber numberWithInt:internalTrigStopEnabled]  forKey:@"internalTrigStopEnabled"];    
    [objDictionary setObject:[NSNumber numberWithInt:multiEventModeEnabled]  forKey:@"multiEventModeEnabled"];    
    [objDictionary setObject:[NSNumber numberWithInt:autostartModeEnabled]  forKey:@"autostartModeEnabled"];    
    [objDictionary setObject:[NSNumber numberWithInt:startDelay]  forKey:@"startDelay"];    
    [objDictionary setObject:[NSNumber numberWithInt:stopDelay]  forKey:@"stopDelay"];    
    [objDictionary setObject:[NSNumber numberWithInt:maxEvents]  forKey:@"maxEvents"];  
    
    [objDictionary setObject:[NSNumber numberWithInt:stopAtEventLengthMask]   forKey:@"stopEventAtLength"];
    [objDictionary setObject:[NSNumber numberWithInt:enablePageWrapMask]      forKey:@"enablePageWrap"];
    [objDictionary setObject:[NSNumber numberWithInt:enableTestDataMask]      forKey:@"enableTestData"];
    
    return objDictionary;
}

- (NSArray*) autoTests 
{
	NSMutableArray* myTests = [NSMutableArray array];
	[myTests addObject:[ORVmeReadOnlyTest test:kSIS3302AcquisitionControl wordSize:4 name:@"Acquistion Reg"]];
	[myTests addObject:[ORVmeWriteOnlyTest test:kSIS3302KeyReset wordSize:4 name:@"Reset"]];
	//TO DO.. add more tests
	
	int i;
	for(i=0;i<8;i++){
		[myTests addObject:[ORVmeReadWriteTest test:[self getThresholdRegOffsets:i] wordSize:4 validMask:0x1ffff name:@"Threshold"]];
	}
	return myTests;
}

//ORAdcInfoProviding protocol requirement
- (void) postAdcInfoProvidingValueChanged
{
	[[NSNotificationCenter defaultCenter]
	 postNotificationName:ORAdcInfoProvidingValueChanged
	 object:self
	 userInfo: nil];
}
//for adcProvidingProtocol... but not used for now
- (unsigned long) eventCount:(int)channel
{
	return 0;
}
- (void) clearEventCounts
{
}
- (unsigned long) thresholdForDisplay:(unsigned short) aChan
{
	return [self threshold:aChan];
}
- (unsigned short) gainForDisplay:(unsigned short) aChan
{
	return [self gain:aChan];
}
@end

@implementation ORSIS3302GenericModel (private)
- (NSMutableArray*) arrayOfLength:(int)len
{
	int i;
	NSMutableArray* anArray = [NSMutableArray arrayWithCapacity:kNumSIS3302Channels];
	for(i=0;i<len;i++)[anArray addObject:[NSNumber numberWithInt:0]];
	return anArray;
}

- (void) setUpArrays
{
	if(!thresholds)				thresholds			  = [[self arrayOfLength:kNumSIS3302Channels] retain];
	if(!dacOffsets)				dacOffsets			  = [[self arrayOfLength:kNumSIS3302Channels] retain];
	if(!pulseLengths)			pulseLengths		  = [[self arrayOfLength:kNumSIS3302Channels] retain];
	if(!sumGs)					sumGs				  = [[self arrayOfLength:kNumSIS3302Channels] retain];
	if(!peakingTimes)			peakingTimes		  = [[self arrayOfLength:kNumSIS3302Channels] retain];
	
	if(!preTriggerDelays)	preTriggerDelays	= [[self arrayOfLength:kNumSIS3302Groups] retain];
	
	if(!waveFormRateGroup){
        [self setWaveFormRateGroup:[[[ORRateGroup alloc] initGroup:kNumSIS3302Channels groupTag:0] autorelease]];
        [waveFormRateGroup setIntegrationTime:5];
    }

	if(!sampleLengths)		sampleLengths		= [[self arrayOfLength:kNumSIS3302Groups] retain];
	if(!averagingSettings)		averagingSettings		= [[self arrayOfLength:kNumSIS3302Groups] retain];
	if(!pageWrapSize)		pageWrapSize		= [[self arrayOfLength:kNumSIS3302Groups] retain];
	if(!testDataType)		testDataType		= [[self arrayOfLength:kNumSIS3302Groups] retain];
	
}

- (void) writeDacOffsets
{
	
	unsigned int max_timeout, timeout_cnt;
	
	int i;
	for (i=0;i<kNumSIS3302Channels;i++) {
		unsigned long data =  [self dacOffset:i];
		unsigned long addr = [self baseAddress] + kSIS3302DacData  ;
		
		// Set the Data in the DAC Register
		[[self adapter] writeLongBlock:&data
							 atAddress:addr
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		
		data =  1 + (i << 4); // write to DAC Register
		addr = [self baseAddress] + kSIS3302DacControlStatus  ;
		// Tell card to set the DAC shift Register
		[[self adapter] writeLongBlock:&data
							 atAddress:addr
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		max_timeout = 5000 ;
		timeout_cnt = 0 ;
		addr = [self baseAddress] + kSIS3302DacControlStatus  ;
		// Wait until done.
		do {
			[[self adapter] readLongBlock:&data
								atAddress:addr
								numToRead:1
							   withAddMod:addressModifier
							usingAddSpace:0x01];
			
			timeout_cnt++;
		} while ( ((data & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) )    ;
		
		if (timeout_cnt >=  max_timeout) {
			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i); 
			return;
		}
		
		[[self adapter] writeLongBlock:&data
							 atAddress:addr
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		
		data =  2 + (i << 4); // Load DACs 
		addr = [self baseAddress] + kSIS3302DacControlStatus  ;
		[[self adapter] writeLongBlock:&data
							 atAddress:addr
							numToWrite:1
							withAddMod:addressModifier
						 usingAddSpace:0x01];
		
		timeout_cnt = 0 ;
		addr = [self baseAddress] + kSIS3302DacControlStatus  ;
		do {
			[[self adapter] readLongBlock:&data
								atAddress:addr
								numToRead:1
							   withAddMod:addressModifier
							usingAddSpace:0x01];
			timeout_cnt++;
		} while ( ((data & 0x8000) == 0x8000) && (timeout_cnt <  max_timeout) )    ;
		
		if (timeout_cnt >=  max_timeout) {
			NSLog(@"%@ Failed programing the DAC offset for channel %d\n",[self fullID],i); 
			return;
		}
	}
}

- (void) writeDelaysAndMaxEvents
{
    unsigned long aMask = [self startDelay] & 0xFFFFFF;
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kSIS3302GenericStartDelay
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];    
    
    aMask = [self stopDelay] & 0xFFFFFF;
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kSIS3302GenericStopDelay
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];        
    aMask = [self maxEvents] & 0xFFFFF;
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kSIS3302GenericMaximumNumberOfEvents
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];   
}

- (void) writeAcquisitionRegister:(BOOL)forceAutostartOff
{
	// The register is set up as a J/K flip/flop -- 1 bit to set a function and 1 bit to disable.	
	unsigned long aMask = 0x0;
	aMask |= ((clockSource & 0x7)<< 12);
	
    aMask |= [self lemoTimestampEnabled] << 9;
    aMask |= [self lemoStartStopEnabled] << 8;
    aMask |= [self internalTrigStartEnabled] << 7;
    aMask |= [self internalTrigStopEnabled] << 6;
    aMask |= [self multiEventModeEnabled] << 5;
    if (!forceAutostartOff) {
        // If we don't force the autostart to be off, then set it
        aMask |= [self autostartModeEnabled] << 4;
    }
   
    
    //aMask |= (1 << 11); // Set it to be big endian
    
	//put the inverse in the top bits to turn off everything else
	aMask = ((~aMask & 0x0000ffff)<<16) | aMask;
	
	[[self adapter] writeLongBlock:&aMask
                         atAddress:[self baseAddress] + kSIS3302AcquisitionControl
                        numToWrite:1
                        withAddMod:[self addressModifier]
                     usingAddSpace:0x01];
        
}

- (void) writeThresholds
{   
	ORCommandList* aList = [ORCommandList commandList];
	int i;
	unsigned long thresholdMask;
	for(i = 0; i < kNumSIS3302Channels; i++) {
		thresholdMask  = (![self useTrapTrigger:i]) << 26;
		if([self gt:i])	thresholdMask |= (1<<25);
        else            thresholdMask |= (1<<24);
		
		thresholdMask |= ([self threshold:i] & 0xffff);
		
		[aList addCommand: [ORVmeReadWriteCommand writeLongBlock: &thresholdMask
													   atAddress: [self baseAddress] + [self getThresholdRegOffsets:i]
													  numToWrite: 1
													  withAddMod: [self addressModifier]
												   usingAddSpace: 0x01]];
		
		
	}
	[self executeCommandList:aList];
}

- (void) writeEventConfiguration
{
	int i;
	ORCommandList* aList = [ORCommandList commandList];
	for(i=0;i<kNumSIS3302Channels/2;i++){
		unsigned long aValueMask = 0x0;
		aValueMask =  ([self averagingType:i] << 12)    |
        ([self stopEventAtLength:i] << 5) | 
        ([self pageWrap:i] << 4)          | 
        [self pageWrapSize:i];
		[aList addCommand: [ORVmeReadWriteCommand writeLongBlock: &aValueMask
													   atAddress: [self baseAddress] + [self getEventConfigOffsets:i]
													  numToWrite: 1
													  withAddMod: [self addressModifier]
												   usingAddSpace: 0x01]];
	}
	//extended length
	for(i=0;i<kNumSIS3302Channels/2;i++){
		unsigned long aValueMask = (([self sampleLength:i]-4) & 0xFFFFFFC);
		[aList addCommand: [ORVmeReadWriteCommand writeLongBlock: &aValueMask
													   atAddress: [self baseAddress] + [self getEventLengthOffsets:i]
													  numToWrite: 1
													  withAddMod: [self addressModifier]
												   usingAddSpace: 0x01]];
	}
    // write sample start
	for(i=0;i<kNumSIS3302Channels/2;i++){
		unsigned long aValueMask = 0;
		[aList addCommand: [ORVmeReadWriteCommand writeLongBlock: &aValueMask
													   atAddress: [self baseAddress] + [self getSampleStartOffsets:i]
													  numToWrite: 1
													  withAddMod: [self addressModifier]
												   usingAddSpace: 0x01]];
	}    
	[self executeCommandList:aList];
	
}

- (void) writeAdcInputMode
{
	int i;
	ORCommandList* aList = [ORCommandList commandList];    
    for(i=0;i<kNumSIS3302Channels/2;i++){
		unsigned long aValueMask = ([self testDataType:i] << 17) | 
        ([self enableTestData:i] << 16);
		[aList addCommand: [ORVmeReadWriteCommand writeLongBlock: &aValueMask
													   atAddress: [self baseAddress] + [self getAdcInputModeOffsets:i]
													  numToWrite: 1
													  withAddMod: [self addressModifier]
												   usingAddSpace: 0x01]];
	}    
	[self executeCommandList:aList];
}

- (void) writePreTriggerDelay
{
	int i;
	for(i=0;i<kNumSIS3302Channels/2;i++) {
        
		unsigned long aValue = [self preTriggerDelay:i] & 0xFFF;
		[[self adapter] writeLongBlock:&aValue
							 atAddress:[self baseAddress] + [self getPreTriggerDelayOffset:i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}	
}

- (void) writeTriggerSetups
{
	int i;
	for(i = 0; i < kNumSIS3302Channels; i++) {
		unsigned long aTriggerMask = 
		(([self pulseLength:i] & 0xffL) << 16) | 
		(([self sumG:i]        & 0x1fL) <<  8) | 
		([self peakingTime:i] & 0x1fL);
		
		[[self adapter] writeLongBlock:&aTriggerMask
							 atAddress:[self baseAddress] + [self getTriggerSetupRegOffsets:i]
							numToWrite:1
							withAddMod:[self addressModifier]
						 usingAddSpace:0x01];
	}
}


- (void) writePageRegister:(int) aPage 
{	
	unsigned long aValue = aPage & 0xf;
	[[self adapter] writeLongBlock:&aValue
						 atAddress:[self baseAddress] + kSIS3302AdcMemoryPageRegister
						numToWrite:1
						withAddMod:[self addressModifier]
					 usingAddSpace:0x01];	
}

- (void) executeCommandList:(ORCommandList*) aList
{
	[[self adapter] executeCommandList:aList];
}
@end
