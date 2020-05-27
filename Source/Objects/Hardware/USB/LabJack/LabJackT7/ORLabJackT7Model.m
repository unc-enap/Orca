//
//  ORLabJackT7Model.m
//  Orca
//
//  Created by Mark Howe on Fri Jan 20,2017.
//  Copyright (c) 2017 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Physics and Department sponsored in part by the United States 
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
#import "ORLabJackT7Model.h"
#import "NSNotifications+Extensions.h"
#import "ORDataTypeAssigner.h"

#import "orca_t7.h"

NSString* ORLabJackT7ModelDeviceSerialNumberChanged = @"ORLabJackT7ModelDeviceSerialNumberChanged";
NSString* ORLabJackT7ModelDeviceHandleChanged = @"ORLabJackT7ModelDeviceHandleChanged";
NSString* ORLabJackT7ModelInvolvedInProcessChanged = @"ORLabJackT7ModelInvolvedInProcessChanged";
NSString* ORLabJackT7ModelAOut1Changed			= @"ORLabJackT7ModelAOut1Changed";
NSString* ORLabJackT7ModelAOut0Changed			= @"ORLabJackT7ModelAOut0Changed";
NSString* ORLabJackT7ShipDataChanged			= @"ORLabJackT7ShipDataChanged";
NSString* ORLabJackT7DigitalOutputEnabledChanged= @"ORLabJackT7DigitalOutputEnabledChanged";
NSString* ORLabJackT7CounterChanged				= @"ORLabJackT7CounterChanged";
NSString* ORLabJackT7Lock						= @"ORLabJackT7Lock";
NSString* ORLabJackT7ChannelNameChanged			= @"ORLabJackT7ChannelNameChanged";
NSString* ORLabJackT7ChannelUnitChanged			= @"ORLabJackT7ChannelUnitChanged";
NSString* ORLabJackT7AdcChanged					= @"ORLabJackT7AdcChanged";
NSString* ORLabJackT7AdcRangeChanged            = @"ORLabJackT7AdcRangeChanged";
NSString* ORLabJackT7DoNameChanged				= @"ORLabJackT7DoNameChanged";
NSString* ORLabJackT7DoDirectionChanged			= @"ORLabJackT7DoDirectionChanged";
NSString* ORLabJackT7DoValueOutChanged			= @"ORLabJackT7DoValueOutChanged";
NSString* ORLabJackT7DoValueInChanged			= @"ORLabJackT7DoValueInChanged";
NSString* ORLabJackT7PollTimeChanged			= @"ORLabJackT7PollTimeChanged";
NSString* ORLabJackT7HiLimitChanged				= @"ORLabJackT7HiLimitChanged";
NSString* ORLabJackT7LowLimitChanged			= @"ORLabJackT7LowLimitChanged";
NSString* ORLabJackT7AdcDiffChanged				= @"ORLabJackT7AdcDiffChanged";
NSString* ORLabJackT7SlopeChanged				= @"ORLabJackT7SlopeChanged";
NSString* ORLabJackT7InterceptChanged			= @"ORLabJackT7InterceptChanged";
NSString* ORLabJackT7MinValueChanged			= @"ORLabJackT7MinValueChanged";
NSString* ORLabJackT7MaxValueChanged			= @"ORLabJackT7MaxValueChanged";
NSString* ORLabJackT7EnabledChanged             = @"ORLabJackT7EnabledChanged";
NSString* ORLabJackT7CounterEnabledChanged      = @"ORLabJackT7CounterEnabledChanged";

@interface ORLabJackT7Model (private)
- (void) pollHardware;
- (void) setUpCounters;
- (void) readCounters;
- (void) writeDigitalIO;
- (void) writeDacs;
- (void) readAdcValues;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(int*)anArray forKey:(NSString*)aKey;
@end

@implementation ORLabJackT7Model
- (id) init
{
    self = [super init];
    int i;
    for(i=0;i<kNumT7AdcChannels;i++){
        counterEnabled[i] = YES;
        enabled[i]      = YES;
        lowLimit[i]     = -10;
        hiLimit[i]      = 10;
        minValue[i]     = -10;
        maxValue[i]     = 10;
        slope[i]        = 1;
        intercept[i]    = 0;
    }
    return self;
}
- (void) dealloc 
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	int i;
	for(i=0;i<kNumT7AdcChannels;i++)  [channelName[i] release];
	for(i=0;i<kNumT7AdcChannels;i++)  [channelUnit[i] release];
	for(i=0;i<kNumT7IOChannels;i++)	  [doName[i] release];
    
    if(deviceHandle){
        closeLabJack(deviceHandle);
    }
	[super dealloc];
}

- (void) makeMainController
{
    [self linkToController:@"ORLabJackT7Controller"];
}

- (NSString*) helpURL
{
    //return @"USB/LabJackT7.html";  // FIXME
	return @"USB/LabJackU6.html";
}

- (void) setUpImage
{
    //[self setImage:[NSImage imageNamed:@"LabJackT7"]];  // FIXME
    [self setImage:[NSImage imageNamed:@"LabJackU6"]];
}

- (NSString*) title 
{
	return [NSString stringWithFormat:@"LabJackT7 (Serial# %@)",@"fix me"];
}

- (NSUInteger) vendorID
{
	return 0x0CD5;
}

- (NSUInteger) productID
{
	return 0x0007;	//LabJackT7 ID
}

#pragma mark ***Accessors
- (int) deviceHandle
{
    return deviceHandle;
}

- (void) setDeviceHandle:(int)aDeviceHandle
{
    deviceHandle = aDeviceHandle;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7ModelDeviceHandleChanged object:self];
}

- (BOOL) deviceOpen
{
    return deviceHandle != 0;
}

- (int) deviceSerialNumber
{
    return deviceSerialNumber;
}

- (void) setDeviceSerialNumber:(int)aDeviceSerialNumber
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDeviceSerialNumber:deviceSerialNumber];

    deviceSerialNumber = aDeviceSerialNumber;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7ModelDeviceSerialNumberChanged object:self];
}

- (BOOL) involvedInProcess
{
    return involvedInProcess;
}

- (void) setInvolvedInProcess:(BOOL)aInvolvedInProcess
{
    involvedInProcess = aInvolvedInProcess;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7ModelInvolvedInProcessChanged object:self];
}
- (BOOL) enabled:(unsigned short)chan
{
    if(chan<kNumT7AdcChannels)return enabled[chan];
    else return NO;
}
- (void) setEnabled:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan<kNumT7AdcChannels) && (aValue!=enabled[chan])){
        [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:chan withValue:enabled[chan]];
        
        enabled[chan] = aValue;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7EnabledChanged object:self];
    }
}
- (BOOL) counterEnabled:(unsigned short)chan
{
    if(chan<kNumT7Counters) return counterEnabled[chan];
    else return NO;
}
- (void) setCounterEnabled:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan<kNumT7Counters) && (aValue!=counterEnabled[chan])){
        [[[self undoManager] prepareWithInvocationTarget:self] setCounterEnabled:chan withValue:counterEnabled[chan]];
        
        counterEnabled[chan] = aValue;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7CounterEnabledChanged object:self];
    }
    [self setUpCounters];
}

- (unsigned short) aOut1
{
    return aOut1;
}

- (void) setAOut1:(unsigned short)aValue
{
    if(aValue>4095) aValue=4095;  // FIXME: check this number
    [[[self undoManager] prepareWithInvocationTarget:self] setAOut1:aOut1];
    
    aOut1 = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7ModelAOut1Changed object:self];
}

- (void) setAOut0Voltage:(float)aValue
{
    [self setAOut0:aValue*4095./5.0];  // FIXME: see above
}

- (void) setAOut1Voltage:(float)aValue
{
    [self setAOut1:aValue*4095./5.0];  // FIXME: see above
}
		 
- (unsigned short) aOut0
{
    return aOut0;
}

- (void) setAOut0:(unsigned short)aValue
{
	if(aValue>4095) aValue=4095;  // FIXME: check this number
    [[[self undoManager] prepareWithInvocationTarget:self] setAOut0:aOut0];
    
    aOut0 = aValue;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7ModelAOut0Changed object:self];
}

- (float) slope:(unsigned short)chan
{
	if(chan<kNumT7AdcChannels)return slope[chan];
	else return 20./4095.;  // FIXME: see above
}

- (void) setSlope:(unsigned short)chan withValue:(float)aValue
{
	if(chan<kNumT7AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setSlope:chan withValue:slope[chan]];
		
		slope[chan] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:chan] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7SlopeChanged object:self userInfo:userInfo];
		
	}
}

- (float) intercept:(unsigned short)chan
{
	if(chan<kNumT7AdcChannels)return intercept[chan];
	else return -10;
}

- (void) setIntercept:(unsigned short)chan withValue:(float)aValue
{
	if(chan<kNumT7AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setIntercept:chan withValue:intercept[chan]];
		
		intercept[chan] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:chan] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7InterceptChanged object:self userInfo:userInfo];
		
	}
}

- (float) lowLimit:(unsigned short)chan
{
	if(chan<kNumT7AdcChannels)return lowLimit[chan];
	else return 0;
}

- (void) setLowLimit:(unsigned short)chan withValue:(float)aValue
{
	if(chan<kNumT7AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:chan withValue:lowLimit[chan]];
		
		lowLimit[chan] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:chan] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7LowLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) hiLimit:(unsigned short)chan
{
	if(chan<kNumT7AdcChannels)return hiLimit[chan];
	else return 0;
}

- (void) setHiLimit:(unsigned short)chan withValue:(float)aValue
{
	if(chan<kNumT7AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setHiLimit:chan withValue:lowLimit[chan]];
		
		hiLimit[chan] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:chan] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7HiLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) minValue:(unsigned short)chan
{
	if(chan<kNumT7AdcChannels)return minValue[chan];
	else return 0;
}

- (void) setMinValue:(unsigned short)chan withValue:(float)aValue
{
	if(chan<kNumT7AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setMinValue:chan withValue:minValue[chan]];
		
		minValue[chan] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:chan] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7MinValueChanged object:self userInfo:userInfo];
		
	}
}
- (float) maxValue:(unsigned short)chan
{
	if(chan<kNumT7AdcChannels)return maxValue[chan];
	else return 0;
}

- (void) setMaxValue:(unsigned short)chan withValue:(float)aValue
{
	if(chan<kNumT7AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setMaxValue:chan withValue:maxValue[chan]];
		
		maxValue[chan] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:chan] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7MaxValueChanged object:self userInfo:userInfo];
		
	}
}


- (BOOL) shipData
{
    return shipData;
}

- (void) setShipData:(BOOL)aShipData
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipData:shipData];
    shipData = aShipData;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7ShipDataChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
	[self pollHardware];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7PollTimeChanged object:self];
}

- (BOOL) digitalOutputEnabled
{
    return digitalOutputEnabled;
}

- (void) setDigitalOutputEnabled:(BOOL)aDigitalOutputEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDigitalOutputEnabled:digitalOutputEnabled];
    digitalOutputEnabled = aDigitalOutputEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7DigitalOutputEnabledChanged object:self];
}

- (uint64_t) counter:(unsigned short)chan
{
    if(chan<kNumT7Counters){
        return counter[chan];
    }
    else return 0;
}

- (void) setCounter:(unsigned short)chan withValue:(uint64_t)aValue
{
    if(chan<kNumT7Counters){
        counter[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7CounterChanged object:self];
    }
}

- (NSString*) channelName:(unsigned short)chan
{
	if(chan<kNumT7AdcChannels){
		if([channelName[chan] length])return channelName[chan];
		else return [NSString stringWithFormat:@"Chan %d",chan];
	}
	else return @"";
}

- (void) setChannel:(unsigned short)chan name:(NSString*)aName
{
	if(chan<kNumT7AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setChannel:chan name:channelName[chan]];
		
		[channelName[chan] autorelease];
		channelName[chan] = [aName copy];
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:chan] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7ChannelNameChanged object:self userInfo:userInfo];
		
	}
}

- (NSString*) channelUnit:(unsigned short)chan
{
	if(chan<kNumT7AdcChannels){
		if([channelUnit[chan] length])return channelUnit[chan];
		else return @"V";
	}
	else return @"";
}

- (void) setChannel:(unsigned short)chan unit:(NSString*)aName
{
	if(chan<kNumT7AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setChannel:chan unit:channelUnit[chan]];
		
		[channelUnit[chan] autorelease];
		channelUnit[chan] = [aName copy];
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:chan] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7ChannelUnitChanged object:self userInfo:userInfo];
		
	}
}

- (NSString*) doName:(unsigned short)chan
{
	if(chan<kNumT7IOChannels){
		if([doName[chan] length])return doName[chan];
		else return [NSString stringWithFormat:@"DO%d",chan];
	}
	else return @"";
}

- (void) setDo:(unsigned short)chan name:(NSString*)aName
{
	if(chan<kNumT7IOChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setDo:chan name:doName[chan]];
		
		[doName[chan] autorelease];
		doName[chan] = [aName copy];
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:chan] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7DoNameChanged object:self userInfo:userInfo];
		
	}
}

- (double) adc:(unsigned short)chan
{
	double result = 0;
	@synchronized(self){
		if(chan<kNumT7AdcChannels){
			result =  adc[chan];
		}
	}
	return result;
}

- (void) setAdc:(unsigned short)chan withValue:(double)aValue
{
	@synchronized(self){
		if(chan<kNumT7AdcChannels){
			adc[chan] = aValue;
			
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:[NSNumber numberWithInt:chan] forKey: @"Channel"];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackT7AdcChanged object:self userInfo:userInfo];
		}	
	}
}
- (int) adcRange:(unsigned short)chan
{
	unsigned short result = 0;
	@synchronized(self){
        if(chan<kNumT7AdcChannels){
            result =  adcRange[chan];
        }
	}
	return result;
}

- (void) setAdcRange:(unsigned short)chan withValue:(int)aValue
{
	@synchronized(self){
        if(chan>=0 && chan<kNumT7AdcChannels){
            [[[self undoManager] prepareWithInvocationTarget:self] setAdcRange:chan withValue:adcRange[chan]];
            adcRange[chan] = aValue;
            
            NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
            [userInfo setObject:[NSNumber numberWithInt:chan] forKey: @"Channel"];
            
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackT7AdcRangeChanged object:self  userInfo:userInfo];
        }
	}
}

- (unsigned short) adcDiff
{
	return adcDiff;
}

- (void) setAdcDiff:(unsigned short)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAdcDiff:adcDiff];
    adcDiff = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7AdcDiffChanged object:self];
	
}

- (void) setAdcDiffBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = adcDiff;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setAdcDiff:aMask];
}

- (uint32_t) doDirection
{
    return doDirection;
}

- (void) setDoDirection:(uint32_t)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoDirection:doDirection];
    doDirection = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackT7DoDirectionChanged object:self];
}


- (void) setDoDirectionBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = doDirection;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setDoDirection:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (uint32_t) doValueOut
{
    return doValueOut;
}

- (void) setDoValueOut:(uint32_t)aMask
{
	@synchronized(self){
		[[[self undoManager] prepareWithInvocationTarget:self] setDoValueOut:doValueOut];
		doValueOut = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackT7DoValueOutChanged object:self];
	}
}

- (void) setDoValueOutBit:(int)bit withValue:(BOOL)aValue
{
	uint32_t aMask = doValueOut;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setDoValueOut:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (NSColor*) doInColor:(int)i
{
	if(doDirection & (1L<<i) ) return (doValueIn & 1L<<i) ? 
		[NSColor colorWithCalibratedRed:0 green:.8 blue:0 alpha:1.0] :
		[NSColor colorWithCalibratedRed:.8 green:0 blue:0 alpha:1.0];
	else						 return [NSColor blackColor];
}

- (uint32_t) doValueIn
{
    return doValueIn;
}

- (void) setDoValueIn:(uint32_t)aMask
{
	@synchronized(self){
		doValueIn = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackT7DoValueInChanged object:self];
	}
}

- (void) setDoValueInBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = doValueIn;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setDoValueIn:aMask];
	//ORAdcInfoProviding protocol requirement
	//[self postAdcInfoProvidingValueChanged];
}

- (NSString*) doInString:(int)i
{
	if(doDirection & (1L<<i) ) return (doValueIn & 1L<<i) ? @"Hi":@"Lo";
	else						 return @"";
}


- (void) resetCounter:(int)i
{
    if(i>=0 && i<2){
        doResetOfCounter[i] = YES;
        [self queryAll];
    }
}


#pragma mark ***HW Access
- (void) toggleOpen
{
    if(!deviceHandle && deviceSerialNumber!=0){
        [self openDevice];
    }
    else {
        [self closeDevice];
    }
}

- (void) openDevice
{
    int h;
    long error = openLabJack(&h);   // FIXME: use deviceSerialNumber
    if(error!=0){
        NSLog(@"%@ cannot open device (error: %d)\n",[self fullID],error);
    }
    if(h){
        [self setDeviceHandle:h];
        long error = getCalibrationInfo(deviceHandle, &caliInfo);  // FIXME: is this needed?
        
        [self setUpCounters];
        
        if(error!=0){
            NSLog(@"%@ return invalid calibration constants (error: %d)\n",[self fullID],error);
        }
    }
}

- (void) closeDevice
{
    closeLabJack(deviceHandle);
    [self setDeviceHandle: 0];
}

- (void) queryAll
{
	if(deviceHandle){
		if(!queue){
			queue = [[NSOperationQueue alloc] init];
			[queue setMaxConcurrentOperationCount:1]; //can only do one at a time
		}	
		if ([[queue operations] count] == 0) {
			ORLabJackT7Query* anOp = [[ORLabJackT7Query alloc] initWithDelegate:self];
			[queue addOperation:anOp];
			[anOp release];
			led = !led;
		}
	}
}

#pragma mark ***Data Records
- (uint32_t) dataId { return dataId; }
- (void) setDataId: (uint32_t) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId   = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anOtherDevice
{
    [self setDataId:[anOtherDevice dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"LabJackT7"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORLabJackT7DecoderForIOData",@"decoder",
								 [NSNumber numberWithLong:dataId],   @"dataId",
								 [NSNumber numberWithBool:NO],       @"variable",
								 [NSNumber numberWithLong:kLabJackT7DataSize],       @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Temperatures"];
    
    return dataDictionary;
}

- (uint32_t) timeMeasured
{
	return timeMeasured;
}

- (void) shipTheData
{
    if([[ORGlobal sharedGlobal] runInProgress]){
		
		uint32_t data[kLabJackT7DataSize];
		data[0] = dataId | kLabJackT7DataSize;
		data[1] = ((adcDiff & 0x7f) << 16) | ([self uniqueIdNumber] & 0x0000fffff);
		
		union {
			float asFloat;
			uint32_t asLong;
		} theData;
		
		int index = 2;
		int i;
		for(i=0;i<kNumT7AdcChannels;i++){
			theData.asFloat = [self convertedValue:i];
			data[index] = theData.asLong;
			index++;
		}
        data[index++] = (int32_t)(counter[0]         & 0x00000000ffffffff);
        data[index++] = (int32_t)((counter[0] >> 32) & 0x00000000ffffffff);
        data[index++] = (int32_t)(counter[1]         & 0x00000000ffffffff);
        data[index++] = (int32_t)((counter[1] >> 32) & 0x00000000ffffffff);
		data[index++] = (doDirection & 0xFFFFF);
		data[index++] = (doValueOut  & 0xFFFFF);
		data[index++] = (doValueIn   & 0xFFFFF);
	
		data[index++] = timeMeasured;
		data[index++] = 0; //spares
		data[index++] = 0;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(int32_t)*kLabJackT7DataSize]];
	}
}
#pragma mark •••Bit Processing Protocol
- (void) processIsStarting
{
	//we will control the polling loop
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
    readOnce = NO;
	[self setInvolvedInProcess:YES];
}

- (void) processIsStopping
{
	//return control to the normal loop
	[self setPollTime:pollTime];
	[self setInvolvedInProcess:NO];
}

//note that everything called by these routines MUST be threadsafe
- (void) startProcessCycle
{
    if(!readOnce){
        @try { 
            [self performSelectorOnMainThread:@selector(queryAll) withObject:nil waitUntilDone:NO]; 
            readOnce = YES;
        }
		@catch(NSException* localException) { 
			//catch this here to prevent it from falling thru, but nothing to do.
        }
		
		//grab the bit pattern at the start of the cycle. it
		//will not be changed during the cycle.
		processInputValue = doValueIn  & ~doDirection;
		processOutputMask = doDirection ;
		
    }
}

- (void) endProcessCycle
{
	readOnce = NO;
	//don't use the setter so the undo manager is bypassed
	doValueOut = processOutputValue & 0xFFFFF;
}

- (BOOL) processValue:(int)channel
{
	return (processInputValue & (1L<<channel)) > 0;
}

- (void) setProcessOutput:(int)channel value:(int)value
{
	processOutputMask |= (1L<<channel);
	if(value)	processOutputValue |= (1L<<channel);
	else		processOutputValue &= ~(1L<<channel);
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"LabJackT7,%u",[self uniqueIdNumber]];
}

- (NSString*) processingTitle
{
    return [self identifier];
}

- (double) convertedValue:(int)aChan
{
	if(aChan>=0 && aChan<kNumT7AdcChannels)return slope[aChan] * adc[aChan] + intercept[aChan];
	else return 0;
}

- (double) maxValueForChan:(int)aChan
{
	return maxValue[aChan];
}

- (double) minValueForChan:(int)aChan
{
	return minValue[aChan];
}
- (void) getAlarmRangeLow:(double*)theLowLimit high:(double*)theHighLimit channel:(int)channel
{
	@synchronized(self){
		if(channel>=0 && channel<kNumT7AdcChannels){
			*theLowLimit = lowLimit[channel];
			*theHighLimit =  hiLimit[channel];
		}
		else {
			*theLowLimit = -10;
			*theHighLimit = 10;
		}
	}		
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setDeviceSerialNumber:	[decoder decodeIntForKey:@"deviceSerialNumber"]];
    [self setAOut1:                 [decoder decodeIntegerForKey:@"aOut1"]];
    [self setAOut0:                 [decoder decodeIntegerForKey:@"aOut0"]];
    [self setShipData:              [decoder decodeBoolForKey:@"shipData"]];
    [self setDigitalOutputEnabled:  [decoder decodeBoolForKey:@"digitalOutputEnabled"]];
	int i;
    
    for(i=0;i<kNumT7AdcChannels;i++) {
        //some reasonable defaults
        [self setSlope:i withValue:1.0];
        [self setIntercept:i withValue:0.0];
 		
		NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"channelName%d",i]];
		if(aName)[self setChannel:i name:aName];
		else	 [self setChannel:i name:[NSString stringWithFormat:@"Chan %d",i]];
		
		NSString* aUnit = [decoder decodeObjectForKey:[NSString stringWithFormat:@"channelUnit%d",i]];
		if(aUnit)[self setChannel:i unit:aName];
		else	 [self setChannel:i unit:@"V"];
		
		[self setMinValue:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"minValue%d",i]]];
		[self setMaxValue:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"maxValue%d",i]]];
		[self setLowLimit:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"lowLimit%d",i]]];
		[self setHiLimit:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"hiLimit%d",i]]];
		[self setSlope:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"slope%d",i]]];
        [self setIntercept:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"intercept%d",i]]];
 
        [self setAdcRange:i withValue:[decoder decodeIntForKey:[NSString stringWithFormat:@"adcRange%d",i]]];
        [self setEnabled:i withValue:[decoder decodeBoolForKey:[NSString stringWithFormat:@"enabled%d",i]]];
        [self setChannel:i unit:[decoder decodeObjectForKey:[NSString stringWithFormat:@"channelUnit%d",i]]];
        
	}
    for(i=0;i<kNumT7IOChannels;i++) {
        NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"DO%d",i]];
        if(aName)[self setDo:i name:aName];
        else [self setDo:i name:[NSString stringWithFormat:@"DO%d",i]];
   }
    for(i=0;i<2;i++) {
        [self setCounterEnabled:i withValue:[decoder decodeBoolForKey:[NSString stringWithFormat:@"counterEnabled%d",i]]];
    }

	[self setAdcDiff:       [decoder decodeIntegerForKey:  @"adcDiff"]];
	[self setDoDirection:	[decoder decodeIntForKey:@"doDirection"]];
    [self setPollTime:		[decoder decodeIntForKey:  @"pollTime"]];
    
    BOOL wasOpen = [decoder decodeBoolForKey:@"wasOpen"];
    if(wasOpen && deviceSerialNumber!=0){
        [self openDevice];
    }
    
    [[self undoManager] enableUndoRegistration];    
	
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:deviceSerialNumber	    forKey: @"deviceSerialNumber"];
    [encoder encodeInteger:aOut1                    forKey:@"aOut1"];
    [encoder encodeInteger:aOut0                    forKey:@"aOut0"];
    [encoder encodeBool:shipData                forKey:@"shipData"];
    [encoder encodeInteger:pollTime                 forKey:@"pollTime"];
    [encoder encodeBool:digitalOutputEnabled    forKey:@"digitalOutputEnabled"];
	int i;
	for(i=0;i<kNumT7AdcChannels;i++) {
		[encoder encodeObject:channelUnit[i] forKey:[NSString stringWithFormat:@"unitName%d",i]];
		[encoder encodeObject:channelName[i] forKey:[NSString stringWithFormat:@"channelName%d",i]];
		[encoder encodeFloat:lowLimit[i] forKey:[NSString stringWithFormat:@"lowLimit%d",i]];
		[encoder encodeFloat:hiLimit[i] forKey:[NSString stringWithFormat:@"hiLimit%d",i]];
		[encoder encodeFloat:slope[i] forKey:[NSString stringWithFormat:@"slope%d",i]];
		[encoder encodeFloat:intercept[i] forKey:[NSString stringWithFormat:@"intercept%d",i]];
		[encoder encodeFloat:minValue[i] forKey:[NSString stringWithFormat:@"minValue%d",i]];
        [encoder encodeFloat:maxValue[i] forKey:[NSString stringWithFormat:@"maxValue%d",i]];
        [encoder encodeInteger:adcRange[i] forKey:[NSString stringWithFormat:@"adcRange%d",i]];
        [encoder encodeBool:enabled[i] forKey:[NSString stringWithFormat:@"enabled%d",i]];
        [encoder encodeObject:channelUnit[i] forKey:[NSString stringWithFormat:@"channelUnit%d",i]];
    }
    for(i=0;i<kNumT7IOChannels;i++) {
        [encoder encodeObject:doName[i] forKey:[NSString stringWithFormat:@"DO%d",i]];
	}
    for(i=0;i<kNumT7Counters;i++) {
        [encoder encodeBool:counterEnabled[i] forKey:[NSString stringWithFormat:@"counterEnabled%d",i]];
    }
	
    [encoder encodeInteger:adcDiff		forKey:@"adcDiff"];
    [encoder encodeInt:doDirection	forKey:@"doDirection"];
    [encoder encodeBool:[self deviceOpen] forKey:@"wasOpen"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	
    [self addCurrentState:objDictionary cArray:adcRange forKey:@"adcRange"];
    [objDictionary setObject:[NSNumber numberWithInt:adcDiff] forKey:@"AdcDiffMask"];
	
    return objDictionary;
}

- (void) readSerialNumbers
{
    findLabJacks();  // FIXME: improve this function (e.g. show in GUI)
}
- (int) adcConvertedRange:(unsigned short)chan
{
    // FIXME: this needs to be changed
    switch([self adcRange:chan]){
        case 0: return 0;
        case 1: return 2;
        case 2: return 8;
        case 3: return 10;
        case 4: return 11;
        default: return 0;
    }
}

@end

@implementation ORLabJackT7Model (private)
- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollTime == 0 )return;
    [[self undoManager] disableUndoRegistration];
	[self queryAll];
    [[self undoManager] enableUndoRegistration];
	if(pollTime == -1)[self performSelector:@selector(pollHardware) withObject:nil afterDelay:1/200.];
	else [self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}

- (void) setUpCounters
{
    // FIXME: update this
#if 0
    int32_t aEnableTimers[4] = {0,0,0,0}; //not supporting timers at this time
    int32_t aTimerModes[4]   = {0,0,0,0}; //not supporting timers at this time
    double aTimerValues[4]  = {0,0,0,0};
    int32_t aEnableCounters[2] = {counterEnabled[0],counterEnabled[1]};
    int32_t error = eTCConfig(deviceHandle,
                          aEnableTimers,
                          aEnableCounters,
                          0,
                          LJ_tc48MHZ,
                          1,
                          aTimerModes,
                          aTimerValues,
                          0,
                          0);
    if(error!=0){
        NSLog(@"%@ return invalid counter constants (error: %d)\n",[self fullID],error);
    }
#endif
}

- (void) readCounters
{
    // FIXME: update this
#if 0
    if(counterEnabled[0] || counterEnabled[1]){
        int32_t aReadTimers[4]       = {0,0,0,0}; //don't support timers at this time
        int32_t aUpdateResetTimers[4]= {0,0,0,0}; //don't support timers at this time
        int32_t aReadCounters[2]      = {counterEnabled[0],counterEnabled[1]};
        int32_t aResetCounters[2]    = {doResetOfCounter[0],doResetOfCounter[1]};
        double aTimerValues[4];
        double aCounterValues[2];
        int32_t error =  eTCValues( deviceHandle,
                   aReadTimers,
                   aUpdateResetTimers,
                   aReadCounters,
                   aResetCounters,
                   aTimerValues,
                   aCounterValues,
                   0,
                   0);
        
        doResetOfCounter[0] = NO;
        doResetOfCounter[1] = NO;
        if(error == 0){
            [self setCounter:0 withValue:(int64_t)aCounterValues[0]];
            [self setCounter:1 withValue:(int64_t)aCounterValues[1]];
        }
    }
#endif
}

- (void) readAdcValues
{
    if(deviceHandle){
        double dblVoltage = 0.0;
        int i;
        int diffMask = [self adcDiff];  // bit mask for ADCss
        
        time_t	ut_Time;
        time(&ut_Time);
        timeMeasured = (uint32_t)ut_Time;
        
        for(i=0;i<kNumT7AdcChannels;i++){
            if(!enabled[i]) continue;
            int chanP = i;
            if(diffMask & (0x1<<i/2)){
                //differential read
                //eAIN(deviceHandle, &caliInfo, chanP, chanP+1, &dblVoltage, [self adcConvertedRange:i], 0, 0, 0, 0, 0);
                readAIN(deviceHandle, NULL, chanP, chanP+1, &dblVoltage, NULL,
                        0, 0, 0, 0);  // FIXME: set adc range
                [self setAdc:i withValue:dblVoltage];
                
                // adjacent channel not used
                [self setAdc:i+1 withValue:0];
                i++;
            }
            else {
                //single ended read
                //eAIN(deviceHandle, &caliInfo, chanP, 15, &dblVoltage, [self adcConvertedRange:i], 0, 0, 0, 0, 0);
                readAIN(deviceHandle, NULL, chanP, -1, &dblVoltage, NULL,
                        0, 0, 0, 0);  // FIXME: set adc range
                
                [self setAdc:i withValue:dblVoltage];
            }
        }
    }
 }

- (void) writeDacs
{
    // FIXME: add user option for channels
    if(deviceHandle && digitalOutputEnabled){
        //eDAC(deviceHandle,&caliInfo,0,aOut0*5./4095.,0,0,0);
        //eDAC(deviceHandle,&caliInfo,1,aOut1*5./4095.,0,0,0);
        writeDAC(deviceHandle, NULL, 0, aOut0*5./4095.);
        writeDAC(deviceHandle, NULL, 1, aOut1*5./4095.);
    }
}

- (void) writeDigitalIO
{
    if(deviceHandle){
        int i;
        short doValueInStart = doValueIn;
        for(i=0;i<kNumT7IOChannels;i++){
            if((doDirection>>i)&1){
                long result = 0;
                //eDI(deviceHandle,i,&result);
                readDI(deviceHandle, i, &result);
                
                if (result) doValueIn |= (1<<i);
                else doValueIn &= ~(1<<i);
            }
            else {
                //eDO(deviceHandle,i,(doValueOut>>i)&0x1);
                writeDO(deviceHandle, i, (doValueOut>>i)&0x1);
            }
        }
        if(doValueIn!=doValueInStart){
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackT7DoValueInChanged object:self];
        }
    }
}

- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(int*)anArray forKey:(NSString*)aKey
{
	NSMutableArray* ar = [NSMutableArray array];
	int i;
	for(i=0;i<4;i++){
		[ar addObject:[NSNumber numberWithShort:*anArray]];
		anArray++;
	}
	[dictionary setObject:ar forKey:aKey];
}

@end

@implementation ORLabJackT7Query
- (id) initWithDelegate:(id)aDelegate
{
	self = [super init];
	delegate = aDelegate;
    return self;
}

- (void) main
{
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];

	@try {
        [delegate readAdcValues];
		[delegate writeDigitalIO];
        [delegate writeDacs];
        [delegate readCounters];
        [delegate shipTheData];
	}
	@catch(NSException* e){
	}
    @finally {
        [thePool release];
    }
}
@end

