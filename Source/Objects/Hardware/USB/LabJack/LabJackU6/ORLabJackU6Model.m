//
//  ORLabJackU6Model.m
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
#import "ORLabJackU6Model.h"
#import "NSNotifications+Extensions.h"
#import "ORDataTypeAssigner.h"
#import "labjackusb.h"
#import "u6.h"

NSString* ORLabJackU6ModelDeviceSerialNumberChanged = @"ORLabJackU6ModelDeviceSerialNumberChanged";
NSString* ORLabJackU6ModelDeviceHandleChanged = @"ORLabJackU6ModelDeviceHandleChanged";
NSString* ORLabJackU6ModelInvolvedInProcessChanged = @"ORLabJackU6ModelInvolvedInProcessChanged";
NSString* ORLabJackU6ModelAOut1Changed			= @"ORLabJackU6ModelAOut1Changed";
NSString* ORLabJackU6ModelAOut0Changed			= @"ORLabJackU6ModelAOut0Changed";
NSString* ORLabJackU6ShipDataChanged			= @"ORLabJackU6ShipDataChanged";
NSString* ORLabJackU6DigitalOutputEnabledChanged= @"ORLabJackU6DigitalOutputEnabledChanged";
NSString* ORLabJackU6CounterChanged				= @"ORLabJackU6CounterChanged";
NSString* ORLabJackU6Lock						= @"ORLabJackU6Lock";
NSString* ORLabJackU6ChannelNameChanged			= @"ORLabJackU6ChannelNameChanged";
NSString* ORLabJackU6ChannelUnitChanged			= @"ORLabJackU6ChannelUnitChanged";
NSString* ORLabJackU6AdcChanged					= @"ORLabJackU6AdcChanged";
NSString* ORLabJackU6AdcRangeChanged            = @"ORLabJackU6AdcRangeChanged";
NSString* ORLabJackU6DoNameChanged				= @"ORLabJackU6DoNameChanged";
NSString* ORLabJackU6DoDirectionChanged			= @"ORLabJackU6DoDirectionChanged";
NSString* ORLabJackU6DoValueOutChanged			= @"ORLabJackU6DoValueOutChanged";
NSString* ORLabJackU6DoValueInChanged			= @"ORLabJackU6DoValueInChanged";
NSString* ORLabJackU6PollTimeChanged			= @"ORLabJackU6PollTimeChanged";
NSString* ORLabJackU6HiLimitChanged				= @"ORLabJackU6HiLimitChanged";
NSString* ORLabJackU6LowLimitChanged			= @"ORLabJackU6LowLimitChanged";
NSString* ORLabJackU6AdcDiffChanged				= @"ORLabJackU6AdcDiffChanged";
NSString* ORLabJackU6SlopeChanged				= @"ORLabJackU6SlopeChanged";
NSString* ORLabJackU6InterceptChanged			= @"ORLabJackU6InterceptChanged";
NSString* ORLabJackU6MinValueChanged			= @"ORLabJackU6MinValueChanged";
NSString* ORLabJackU6MaxValueChanged			= @"ORLabJackU6MaxValueChanged";
NSString* ORLabJackU6EnabledChanged             = @"ORLabJackU6EnabledChanged";
NSString* ORLabJackU6CounterEnabledChanged      = @"ORLabJackU6CounterEnabledChanged";

@interface ORLabJackU6Model (private)
- (void) pollHardware;
- (void) setUpCounters;
- (void) readCounters;
- (void) writeDigitalIO;
- (void) writeDacs;
- (void) readAdcValues;
- (void) addCurrentState:(NSMutableDictionary*)dictionary cArray:(int*)anArray forKey:(NSString*)aKey;
@end

#define kLabJackU6DataSize 26

@implementation ORLabJackU6Model
- (id) init
{
    self = [super init];
    int i;
    for(i=0;i<kNumU6AdcChannels;i++){
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
	for(i=0;i<kNumU6AdcChannels;i++)	[channelName[i] release];
	for(i=0;i<kNumU6AdcChannels;i++)	[channelUnit[i] release];
	for(i=0;i<kNumU6IOChannels;i++)	[doName[i] release];
    
    if(deviceHandle){
        LJUSB_CloseDevice(deviceHandle);
    }
	[super dealloc];
}

- (void) makeMainController
{
    [self linkToController:@"ORLabJackU6Controller"];
}

- (NSString*) helpURL
{
	return @"USB/LabJackU6.html";
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"LabJackU6"]];
}

- (NSString*) title 
{
	return [NSString stringWithFormat:@"LabJackU6 (Serial# %@)",@"fix me"];
}

- (NSUInteger) vendorID
{
	return 0x0CD5;
}

- (NSUInteger) productID
{
	return 0x0006;	//LabJackU6 ID
}

#pragma mark ***Accessors
- (HANDLE) deviceHandle
{
    return deviceHandle;
}

- (void) setDeviceHandle:(HANDLE)aDeviceHandle
{
    deviceHandle = aDeviceHandle;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6ModelDeviceHandleChanged object:self];
}

- (BOOL) deviceOpen
{
    return deviceHandle!=0;
}

- (unsigned long) deviceSerialNumber
{
    return deviceSerialNumber;
}

- (void) setDeviceSerialNumber:(unsigned long)aDeviceSerialNumber
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDeviceSerialNumber:deviceSerialNumber];

    deviceSerialNumber = aDeviceSerialNumber;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6ModelDeviceSerialNumberChanged object:self];
}

- (BOOL) involvedInProcess
{
    return involvedInProcess;
}

- (void) setInvolvedInProcess:(BOOL)aInvolvedInProcess
{
    involvedInProcess = aInvolvedInProcess;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6ModelInvolvedInProcessChanged object:self];
}
- (BOOL) enabled:(unsigned short)chan
{
    if(chan<kNumU6AdcChannels)return enabled[chan];
    else return NO;
}
- (void) setEnabled:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan<kNumU6AdcChannels) && (aValue!=enabled[chan])){
        [[[self undoManager] prepareWithInvocationTarget:self] setEnabled:chan withValue:enabled[chan]];
        enabled[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6EnabledChanged object:self];
    }
}
- (BOOL) counterEnabled:(unsigned short)chan
{
    if(chan<2)return counterEnabled[chan];
    else return NO;
}
- (void) setCounterEnabled:(unsigned short)chan withValue:(BOOL)aValue
{
    if((chan<2) && (aValue!=counterEnabled[chan])){
        [[[self undoManager] prepareWithInvocationTarget:self] setCounterEnabled:chan withValue:counterEnabled[chan]];
        counterEnabled[chan] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6CounterEnabledChanged object:self];
    }
    [self setUpCounters];
}

- (unsigned short) aOut1
{
    return aOut1;
}

- (void) setAOut1:(unsigned short)aValue
{
	if(aValue>4095)aValue=4095;
    [[[self undoManager] prepareWithInvocationTarget:self] setAOut1:aOut1];
    aOut1 = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6ModelAOut1Changed object:self];
}

- (void) setAOut0Voltage:(float)aValue
{
	[self setAOut0:aValue*4095./5.0];
}

- (void) setAOut1Voltage:(float)aValue
{
	[self setAOut1:aValue*4095./5.0];
}
		 
- (unsigned short) aOut0
{
    return aOut0;
}

- (void) setAOut0:(unsigned short)aValue
{
	if(aValue>4095)aValue=4095;
    [[[self undoManager] prepareWithInvocationTarget:self] setAOut0:aOut0];
    aOut0 = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6ModelAOut0Changed object:self];
}

- (float) slope:(int)i
{
	if(i>=0 && i<kNumU6AdcChannels)return slope[i];
	else return 20./4095.;
}

- (void) setSlope:(int)i withValue:(float)aValue
{
	if(i>=0 && i<kNumU6AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setSlope:i withValue:slope[i]];
		
		slope[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6SlopeChanged object:self userInfo:userInfo];
		
	}
}

- (float) intercept:(int)i
{
	if(i>=0 && i<kNumU6AdcChannels)return intercept[i];
	else return -10;
}

- (void) setIntercept:(int)i withValue:(float)aValue
{
	if(i>=0 && i<kNumU6AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setIntercept:i withValue:intercept[i]];
		
		intercept[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6InterceptChanged object:self userInfo:userInfo];
		
	}
}

- (float) lowLimit:(int)i
{
	if(i>=0 && i<kNumU6AdcChannels)return lowLimit[i];
	else return 0;
}

- (void) setLowLimit:(int)i withValue:(float)aValue
{
	if(i>=0 && i<kNumU6AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:i withValue:lowLimit[i]];
		
		lowLimit[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6LowLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) hiLimit:(int)i
{
	if(i>=0 && i<kNumU6AdcChannels)return hiLimit[i];
	else return 0;
}

- (void) setHiLimit:(int)i withValue:(float)aValue
{
	if(i>=0 && i<kNumU6AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setHiLimit:i withValue:lowLimit[i]];
		
		hiLimit[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6HiLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) minValue:(int)i
{
	if(i>=0 && i<kNumU6AdcChannels)return minValue[i];
	else return 0;
}

- (void) setMinValue:(int)i withValue:(float)aValue
{
	if(i>=0 && i<kNumU6AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setMinValue:i withValue:minValue[i]];
		
		minValue[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6MinValueChanged object:self userInfo:userInfo];
		
	}
}
- (float) maxValue:(int)i
{
	if(i>=0 && i<kNumU6AdcChannels)return maxValue[i];
	else return 0;
}

- (void) setMaxValue:(int)i withValue:(float)aValue
{
	if(i>=0 && i<kNumU6AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setMaxValue:i withValue:maxValue[i]];
		
		maxValue[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6MaxValueChanged object:self userInfo:userInfo];
		
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6ShipDataChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6PollTimeChanged object:self];
}

- (BOOL) digitalOutputEnabled
{
    return digitalOutputEnabled;
}

- (void) setDigitalOutputEnabled:(BOOL)aDigitalOutputEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDigitalOutputEnabled:digitalOutputEnabled];
    digitalOutputEnabled = aDigitalOutputEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6DigitalOutputEnabledChanged object:self];
}

- (unsigned long long) counter:(int)i
{
    if(i>=0 && i<2){
        return counter[i];
    }
    else return 0;
}

- (void) setCounter:(int)i withValue:(unsigned long long)aValue
{
    if(i>=0 && i<2){
        counter[i] = aValue;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6CounterChanged object:self];
    }
}

- (NSString*) channelName:(int)i
{
	if(i>=0 && i<kNumU6AdcChannels){
		if([channelName[i] length])return channelName[i];
		else return [NSString stringWithFormat:@"Chan %d",i];
	}
	else return @"";
}

- (void) setChannel:(int)i name:(NSString*)aName
{
	if(i>=0 && i<kNumU6AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setChannel:i name:channelName[i]];
		
		[channelName[i] autorelease];
		channelName[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6ChannelNameChanged object:self userInfo:userInfo];
		
	}
}

- (NSString*) channelUnit:(int)i
{
	if(i>=0 && i<kNumU6AdcChannels){
		if([channelUnit[i] length])return channelUnit[i];
		else return @"V";
	}
	else return @"";
}

- (void) setChannel:(int)i unit:(NSString*)aName
{
	if(i>=0 && i<kNumU6AdcChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setChannel:i unit:channelUnit[i]];
		
		[channelUnit[i] autorelease];
		channelUnit[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6ChannelUnitChanged object:self userInfo:userInfo];
		
	}
}

- (NSString*) doName:(int)i
{
	if(i>=0 && i<kNumU6IOChannels){
		if([doName[i] length])return doName[i];
		else return [NSString stringWithFormat:@"DO%d",i];
	}
	else return @"";
}

- (void) setDo:(int)i name:(NSString*)aName
{
	if(i>=0 && i<kNumU6IOChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setDo:i name:doName[i]];
		
		[doName[i] autorelease];
		doName[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6DoNameChanged object:self userInfo:userInfo];
		
	}
}

- (double) adc:(int)i
{
	double result = 0;
	@synchronized(self){
		if(i>=0 && i<kNumU6AdcChannels){
			result =  adc[i];
		}
	}
	return result;
}

- (void) setAdc:(int)i withValue:(double)aValue
{
	@synchronized(self){
		if(i>=0 && i<kNumU6AdcChannels){
			adc[i] = aValue; 
			
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackU6AdcChanged object:self userInfo:userInfo];
		}	
	}
}
- (int) adcRange:(int)i
{
	unsigned short result = 0;
	@synchronized(self){
        if(i>=0 && i<kNumU6AdcChannels){
            result =  adcRange[i];
        }
	}
	return result;
}

- (void) setAdcRange:(int)i withValue:(int)aValue
{
	@synchronized(self){
        if(i>=0 && i<kNumU6AdcChannels){
            [[[self undoManager] prepareWithInvocationTarget:self] setAdcRange:i withValue:adcRange[i]];
            adcRange[i] = aValue;
            
            NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
            [userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
            
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackU6AdcRangeChanged object:self  userInfo:userInfo];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6AdcDiffChanged object:self];
	
}

- (void) setAdcDiffBit:(int)bit withValue:(BOOL)aValue
{
	unsigned short aMask = adcDiff;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setAdcDiff:aMask];
}

- (unsigned long) doDirection
{
    return doDirection;
}

- (void) setDoDirection:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoDirection:doDirection];
    doDirection = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackU6DoDirectionChanged object:self];
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

- (unsigned long) doValueOut
{
    return doValueOut;
}

- (void) setDoValueOut:(unsigned long)aMask
{
	@synchronized(self){
		[[[self undoManager] prepareWithInvocationTarget:self] setDoValueOut:doValueOut];
		doValueOut = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackU6DoValueOutChanged object:self];
	}
}

- (void) setDoValueOutBit:(int)bit withValue:(BOOL)aValue
{
	unsigned long aMask = doValueOut;
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

- (unsigned long) doValueIn
{
    return doValueIn;
}

- (void) setDoValueIn:(unsigned long)aMask
{
	@synchronized(self){
		doValueIn = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackU6DoValueInChanged object:self];
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
    HANDLE h =  openU6Connection(deviceSerialNumber);
    if(h){
        [self setDeviceHandle:h];
        long error = getCalibrationInfo(deviceHandle, &caliInfo);
        
        [self setUpCounters];
        
        if(error!=0){
            NSLog(@"%@ return invalid calibration constants (error: %d)\n",[self fullID],error);
        }
    }
}

- (void) closeDevice
{
    closeUSBConnection(deviceHandle);
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
			ORLabJackU6Query* anOp = [[ORLabJackU6Query alloc] initWithDelegate:self];
			[queue addOperation:anOp];
			[anOp release];
			led = !led;
		}
	}
}

#pragma mark ***Data Records
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
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
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"LabJackU6"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORLabJackU6DecoderForIOData",@"decoder",
								 [NSNumber numberWithLong:dataId],   @"dataId",
								 [NSNumber numberWithBool:NO],       @"variable",
								 [NSNumber numberWithLong:kLabJackU6DataSize],       @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Temperatures"];
    
    return dataDictionary;
}

- (unsigned long) timeMeasured
{
	return timeMeasured;
}

- (void) shipTheData
{
    if([[ORGlobal sharedGlobal] runInProgress]){
		
		unsigned long data[kLabJackU6DataSize];
		data[0] = dataId | kLabJackU6DataSize;
		data[1] = ((adcDiff & 0x7f) << 16) | ([self uniqueIdNumber] & 0x0000fffff);
		
		union {
			float asFloat;
			unsigned long asLong;
		} theData;
		
		int index = 2;
		int i;
		for(i=0;i<kNumU6AdcChannels;i++){
			theData.asFloat = [self convertedValue:i];
			data[index] = theData.asLong;
			index++;
		}
        data[index++] = (long)(counter[0]         & 0x00000000ffffffff);
        data[index++] = (long)((counter[0] >> 32) & 0x00000000ffffffff);
        data[index++] = (long)(counter[1]         & 0x00000000ffffffff);
        data[index++] = (long)((counter[1] >> 32) & 0x00000000ffffffff);
		data[index++] = (doDirection & 0xFFFFF);
		data[index++] = (doValueOut  & 0xFFFFF);
		data[index++] = (doValueIn   & 0xFFFFF);
	
		data[index++] = timeMeasured;
		data[index++] = 0; //spares
		data[index++] = 0;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(long)*kLabJackU6DataSize]];
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
    return [NSString stringWithFormat:@"LabJackU6,%lu",[self uniqueIdNumber]];
}

- (NSString*) processingTitle
{
    return [self identifier];
}

- (double) convertedValue:(int)aChan
{
	if(aChan>=0 && aChan<kNumU6AdcChannels)return slope[aChan] * adc[aChan] + intercept[aChan];
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
		if(channel>=0 && channel<kNumU6AdcChannels){
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
    [self setDeviceSerialNumber:	[decoder decodeInt32ForKey:@"deviceSerialNumber"]];
    [self setAOut1:                 [decoder decodeIntForKey:@"aOut1"]];
    [self setAOut0:                 [decoder decodeIntForKey:@"aOut0"]];
    [self setShipData:              [decoder decodeBoolForKey:@"shipData"]];
    [self setDigitalOutputEnabled:  [decoder decodeBoolForKey:@"digitalOutputEnabled"]];
	int i;
    
    for(i=0;i<kNumU6AdcChannels;i++) {
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
    for(i=0;i<kNumU6IOChannels;i++) {
        NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"DO%d",i]];
        if(aName)[self setDo:i name:aName];
        else [self setDo:i name:[NSString stringWithFormat:@"DO%d",i]];
   }
    for(i=0;i<2;i++) {
        [self setCounterEnabled:i withValue:[decoder decodeBoolForKey:[NSString stringWithFormat:@"counterEnabled%d",i]]];
    }

	[self setAdcDiff:       [decoder decodeIntForKey:  @"adcDiff"]];
	[self setDoDirection:	[decoder decodeInt32ForKey:@"doDirection"]];
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
    [encoder encodeInt32:deviceSerialNumber	    forKey: @"deviceSerialNumber"];
    [encoder encodeInt:aOut1                    forKey:@"aOut1"];
    [encoder encodeInt:aOut0                    forKey:@"aOut0"];
    [encoder encodeBool:shipData                forKey:@"shipData"];
    [encoder encodeInt:pollTime                 forKey:@"pollTime"];
    [encoder encodeBool:digitalOutputEnabled    forKey:@"digitalOutputEnabled"];
	int i;
	for(i=0;i<kNumU6AdcChannels;i++) {
		[encoder encodeObject:channelUnit[i] forKey:[NSString stringWithFormat:@"unitName%d",i]];
		[encoder encodeObject:channelName[i] forKey:[NSString stringWithFormat:@"channelName%d",i]];
		[encoder encodeFloat:lowLimit[i] forKey:[NSString stringWithFormat:@"lowLimit%d",i]];
		[encoder encodeFloat:hiLimit[i] forKey:[NSString stringWithFormat:@"hiLimit%d",i]];
		[encoder encodeFloat:slope[i] forKey:[NSString stringWithFormat:@"slope%d",i]];
		[encoder encodeFloat:intercept[i] forKey:[NSString stringWithFormat:@"intercept%d",i]];
		[encoder encodeFloat:minValue[i] forKey:[NSString stringWithFormat:@"minValue%d",i]];
        [encoder encodeFloat:maxValue[i] forKey:[NSString stringWithFormat:@"maxValue%d",i]];
        [encoder encodeInt:adcRange[i] forKey:[NSString stringWithFormat:@"adcRange%d",i]];
        [encoder encodeBool:enabled[i] forKey:[NSString stringWithFormat:@"enabled%d",i]];
        [encoder encodeObject:channelUnit[i] forKey:[NSString stringWithFormat:@"channelUnit%d",i]];
    }
    for(i=0;i<kNumU6IOChannels;i++) {
        [encoder encodeObject:doName[i] forKey:[NSString stringWithFormat:@"DO%d",i]];
	}
    for(i=0;i<2;i++) {
        [encoder encodeBool:counterEnabled[i] forKey:[NSString stringWithFormat:@"counterEnabled%d",i]];
    }
	
    [encoder encodeInt:adcDiff		forKey:@"adcDiff"];
    [encoder encodeInt32:doDirection	forKey:@"doDirection"];
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
    listDeviceSerialNumbers();
}
- (int) adcConvertedRange:(int)chan
{
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

@implementation ORLabJackU6Model (private)
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
    long aEnableTimers[4] = {0,0,0,0}; //not supporting timers at this time
    long aTimerModes[4]   = {0,0,0,0}; //not supporting timers at this time
    double aTimerValues[4]  = {0,0,0,0};
    long aEnableCounters[2] = {counterEnabled[0],counterEnabled[1]};
    long error = eTCConfig(deviceHandle,
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
}

- (void) readCounters
{
    if(counterEnabled[0] || counterEnabled[1]){
        long aReadTimers[4]       = {0,0,0,0}; //don't support timers at this time
        long aUpdateResetTimers[4]= {0,0,0,0}; //don't support timers at this time
        long aReadCounters[2]      = {counterEnabled[0],counterEnabled[1]};
        long aResetCounters[2]    = {doResetOfCounter[0],doResetOfCounter[1]};
        double aTimerValues[4];
        double aCounterValues[2];
        long error =  eTCValues( deviceHandle,
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
            [self setCounter:0 withValue:(long long)aCounterValues[0]];
            [self setCounter:1 withValue:(long long)aCounterValues[1]];
        }
    }
}

- (void) readAdcValues
{
    if(deviceHandle){
        double dblVoltage = 0.0;
        int i;
        int diffMask = [self adcDiff];
        
        time_t	ut_Time;
        time(&ut_Time);
        timeMeasured = ut_Time;
        
        for(i=0;i<kNumU6AdcChannels;i++){
            if(!enabled[i])continue;
            int chanP = i;
            if(diffMask & (0x1<<i/2)){
                //differential read
                eAIN(deviceHandle, &caliInfo, chanP, chanP+1, &dblVoltage, [self adcConvertedRange:i], 0, 0, 0, 0, 0);
                [self setAdc:i withValue:dblVoltage];
                [self setAdc:i+1 withValue:0];
                i++;
            }
            else {
                //single ended read
                eAIN(deviceHandle, &caliInfo, chanP, 15, &dblVoltage, [self adcConvertedRange:i], 0, 0, 0, 0, 0);

                [self setAdc:i withValue:dblVoltage];
            }
        }
    }
 }

- (void) writeDacs
{
    if(deviceHandle && digitalOutputEnabled){
        eDAC(deviceHandle,&caliInfo,0,aOut0*5./4095.,0,0,0);
        eDAC(deviceHandle,&caliInfo,1,aOut1*5./4095.,0,0,0);
    }
}

- (void) writeDigitalIO
{
    if(deviceHandle){
        int i;
        short doValueInStart = doValueIn;
        for(i=0;i<kNumU6IOChannels;i++){
            if((doDirection>>i)&1){
                long result = 0;
                eDI(deviceHandle,i,&result);
                if(result)doValueIn |= (1<<i);
                else doValueIn &= ~(1<<i);
            }
            else eDO(deviceHandle,i,(doValueOut>>i)&0x1);
        }
        if(doValueIn!=doValueInStart){
            [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackU6DoValueInChanged object:self];
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

@implementation ORLabJackU6Query
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

