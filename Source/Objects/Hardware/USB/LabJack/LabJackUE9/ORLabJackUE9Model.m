//
//  ORLabJackUE9Model.m
//  Orca
//
//  Created by Mark Howe on Fri Nov 11,2011.
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
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
#import "ORLabJackUE9Model.h"
#import "NSNotifications+Extensions.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "NetSocket.h"
#import "ORCard.h"
#import "ORCB37Model.h"
#import "ORSafeQueue.h"
#import "ORAlarm.h"

NSString* ORLabJackUE9CmdLocalIDChanged = @"ORLabJackUE9CmdLocalIDChanged";
NSString* ORLabJackUE9CmdClockDivisorChanged = @"ORLabJackUE9CmdClockDivisorChanged";

@implementation ORLabJackUE9Cmd

@synthesize cmdData, tag;

- (void) dealloc
{
	self.cmdData = nil;
	[super dealloc];
}
@end


NSString* ORLabJackUE9ModelLocalIDChanged			= @"ORLabJackUE9ModelLocalIDChanged";
NSString* ORLabJackUE9ModelClockDivisorChanged		= @"ORLabJackUE9ModelClockDivisorChanged";
NSString* ORLabJackUE9ModelClockSelectionChanged	= @"ORLabJackUE9ModelClockSelectionChanged";
NSString* ORLabJackUE9IsConnectedChanged			= @"ORLabJackUE9IsConnectedChanged";
NSString* ORLabJackUE9IpAddressChanged				= @"ORLabJackUE9IpAddressChanged";
NSString* ORLabJackUE9ModelInvolvedInProcessChanged = @"ORLabJackUE9ModelInvolvedInProcessChanged";
NSString* ORLabJackUE9ModelAOut1Changed				= @"ORLabJackUE9ModelAOut1Changed";
NSString* ORLabJackUE9ModelAOut0Changed				= @"ORLabJackUE9ModelAOut0Changed";
NSString* ORLabJackUE9ShipDataChanged				= @"ORLabJackUE9ShipDataChanged";
NSString* ORLabJackUE9DigitalOutputEnabledChanged	= @"ORLabJackUE9DigitalOutputEnabledChanged";
NSString* ORLabJackUE9CounterChanged				= @"ORLabJackUE9CounterChanged";
NSString* ORLabJackUE9Lock							= @"ORLabJackUE9Lock";
NSString* ORLabJackUE9ChannelNameChanged			= @"ORLabJackUE9ChannelNameChanged";
NSString* ORLabJackUE9ChannelUnitChanged			= @"ORLabJackUE9ChannelUnitChanged";
NSString* ORLabJackUE9AdcChanged					= @"ORLabJackUE9AdcChanged";
NSString* ORLabJackUE9GainChanged					= @"ORLabJackUE9GainChanged";
NSString* ORLabJackUE9DoNameChanged					= @"ORLabJackUE9DoNameChanged";
NSString* ORLabJackUE9DoDirectionChanged			= @"ORLabJackUE9DoDirectionChanged";
NSString* ORLabJackUE9DoValueOutChanged				= @"ORLabJackUE9DoValueOutChanged";
NSString* ORLabJackUE9DoValueInChanged				= @"ORLabJackUE9DoValueInChanged";
NSString* ORLabJackUE9IoValueInChanged				= @"ORLabJackUE9IoValueInChanged";
NSString* ORLabJackUE9PollTimeChanged				= @"ORLabJackUE9PollTimeChanged";
NSString* ORLabJackUE9HiLimitChanged				= @"ORLabJackUE9HiLimitChanged";
NSString* ORLabJackUE9LowLimitChanged				= @"ORLabJackUE9LowLimitChanged";
NSString* ORLabJackUE9SlopeChanged					= @"ORLabJackUE9SlopeChanged";
NSString* ORLabJackUE9InterceptChanged				= @"ORLabJackUE9InterceptChanged";
NSString* ORLabJackUE9MinValueChanged				= @"ORLabJackUE9MinValueChanged";
NSString* ORLabJackUE9MaxValueChanged				= @"ORLabJackUE9MaxValueChanged";
NSString* ORLabJackUE9TimerChanged					= @"ORLabJackUE9TimerChanged";
NSString* ORLabJackUE9BipolarChanged				= @"ORLabJackUE9BipolarChanged";
NSString* ORLabJackUE9ModelTimerOptionChanged		= @"ORLabJackUE9ModelTimerOptionChanged";
NSString* ORLabJackUE9ModelTimerEnableMaskChanged	= @"ORLabJackUE9ModelTimerEnableMaskChanged";
NSString* ORLabJackUE9ModelCounterEnableMaskChanged	= @"ORLabJackUE9ModelCounterEnableMaskChanged";
NSString* ORLabJackUE9ModelTimerResultChanged		= @"ORLabJackUE9ModelTimerResultChanged";
NSString* ORLabJackUE9ModelAdcEnableMaskChanged		= @"ORLabJackUE9ModelAdcEnableMaskChanged";

#define kUE9Idle			0
#define kUE9ComCmd			1
#define kUE9CalBlock		2
#define kUE9SingleIO		3
#define kUE9ReadAllValues	4
#define kUE9TimerCounter	5
#define kUE9ControlConfig   6

#define kUE9DigitalBitRead	0x0
#define kUE9DigitalBitWrite	0x1
#define DigitalPortRead		0x2
#define DigitalPortWrite	0x3
#define kUE9AnalogIn		0x4
#define kUE9AnalogOut		0x5

@interface ORLabJackUE9Model (private)
- (void) normalChecksum:(unsigned char*)b len:(int)n;
- (void) extendedChecksum:(unsigned char*)b len:(int)n;
- (unsigned char) normalChecksum8:(unsigned char*)b len:(int)n;
- (unsigned short) extendedChecksum16:(unsigned char*)b len:(int) n;
- (unsigned char) extendedChecksum8:(unsigned char*) b;
- (double) bufferToDouble:(unsigned char*)buffer index:(int) startIndex;
- (unsigned char) numberTimersEnabled;
- (void) readAdcsForMux:(int)aMuxSlot;
- (void) readSingleAdc:(int)aChan;

- (void) timeout;
- (void) decodeComCmd:(NSData*) theData;
- (void) decodeCalibData:(NSData*)theData;
- (void) decodeSingleAdcRead:(NSData*) theData;
- (void) decodeReadAllValues:(NSData*) theData;
- (void) decodeTimerCounter:(NSData*) theData;
- (long) convert:(unsigned long)rawAdc gainBip:(unsigned short)bipGain result:(float*)voltage;
- (long) convert:(float) analogVoltage chan:(int) DACNumber result:(unsigned short*)rawDacValue;
- (unsigned char) gainBipWord:(int)channelPair;
@end

#define kLabJackUE9DataSize 100

@implementation ORLabJackUE9Model
- (id)init
{
	self = [super init];
	int i;
	for(i=0;i<kUE9NumAdcs;i++){
		lowLimit[i] = -10;
		hiLimit[i]  = 10;
		minValue[i] = -10;
		maxValue[i]  = 10;
		slope[i] = 1;
		intercept[i] = 0;
	}
		
	return self;	
}

- (void) dealloc 
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	int i;
	for(i=0;i<kUE9NumAdcs;i++)	[channelName[i] release];
	for(i=0;i<kUE9NumAdcs;i++)	[channelUnit[i] release];
	for(i=0;i<kUE9NumIO;i++)	[doName[i] release];
    [serialNumber release];
	[cmdQueue release];
	[lastRequest release];
    [socketClosedAlarm clearAlarm];
    [socketClosedAlarm release];
	[super dealloc];
}


- (void) makeMainController
{
    [self linkToController:@"ORLabJackUE9Controller"];
}

-(void) setUpImage
{
	int cb37count = [[self orcaObjects] count];
    if(cb37count==0) {
        [self setImage:[NSImage imageNamed:@"LabJackUE9"]];
    }
    else {
		NSImage* aCachedImage = [NSImage imageNamed:@"LabJackUE9Mux80"];
		NSImage* i = [[NSImage alloc] initWithSize:[aCachedImage size]];
		[i lockFocus];
        [aCachedImage drawAtPoint:NSZeroPoint fromRect:[aCachedImage imageRect] operation:NSCompositeSourceOver fraction:1.0];		
		if([[self orcaObjects] count]){
			NSAffineTransform* transform = [NSAffineTransform transform];
			[transform translateXBy:50 yBy:20];
			[transform scaleXBy:.3 yBy:.3];
			[transform concat];
			NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
			OrcaObject* anObject;
			while(anObject = [e nextObject]){
				BOOL oldHighlightState = [anObject highlighted];
				[anObject setHighlighted:NO];
				[anObject drawSelf:NSMakeRect(0,0,500,[[self image] size].height)];
				[anObject setHighlighted:oldHighlightState];
			}
		}
		[i unlockFocus];
		[self setImage:i];
		[i release];
    }
	[[NSNotificationCenter defaultCenter] postNotificationName:OROrcaObjectImageChanged object:self];
 }

- (NSString*) title 
{
	return [NSString stringWithFormat:@"LabJackUE9"];
}


#pragma mark ***Accessors

- (int) localID
{
    return localID;
}

- (void) setLocalID:(int)aLocalID
{
    localID = aLocalID;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelLocalIDChanged object:self];
}

- (int) clockDivisor
{
    return clockDivisor;
}

- (void) setClockDivisor:(int)aClockDivisor
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockDivisor:clockDivisor];
    clockDivisor = aClockDivisor;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9CmdClockDivisorChanged object:self];
}

- (int) clockSelection
{
    return clockSelection;
}

- (void) setClockSelection:(int)aClockSelection
{
    [[[self undoManager] prepareWithInvocationTarget:self] setClockSelection:clockSelection];
    clockSelection = aClockSelection;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelClockSelectionChanged object:self];
}

- (unsigned short) counterEnableMask
{
    return counterEnableMask;
}

- (void) setCounterEnableMask:(unsigned short)anEnableMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setCounterEnableMask:counterEnableMask];
    counterEnableMask = anEnableMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelCounterEnableMaskChanged object:self];
}
- (void) setCounterEnableBit:(int)bit value:(BOOL)aValue
{
	unsigned long aMask = counterEnableMask;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setCounterEnableMask:aMask];
}

- (BOOL) adcEnabled:(int)adcChan
{
	if(adcChan>=0 && adcChan<kUE9NumAdcs){
		int group = adcChan/32;
		int bit   = adcChan%32;
		return (adcEnabledMask[group] >> bit) & 0x1;
	}
	else return 0;
}

- (unsigned long) adcEnabledMask:(int)aGroup
{
	if(aGroup>=0 && aGroup<3) return adcEnabledMask[aGroup];
	else return 0;
}

- (void) setAdcEnabled:(int)aGroup mask:(unsigned long)anEnableMask
{
	if(aGroup>=0 && aGroup<3){
		[[[self undoManager] prepareWithInvocationTarget:self] setAdcEnabled:aGroup mask:adcEnabledMask[aGroup]];
		adcEnabledMask[aGroup] = anEnableMask;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelAdcEnableMaskChanged object:self];
	}
}

- (void) setAdcEnabled:(int)bit value:(BOOL)aValue
{
	int group = bit/32;
	if(group<3){
		unsigned long aMask = adcEnabledMask[group];
		int subBit = bit%32;
		if(aValue) aMask  |= (1<<subBit);
		else	   aMask &= ~(1<<subBit);
		[self setAdcEnabled:group mask:aMask];
	}
}

- (unsigned short) timerEnableMask
{
    return timerEnableMask;
}

- (void) setTimerEnableMask:(unsigned short)aTimerEnableMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTimerEnableMask:timerEnableMask];
    timerEnableMask = aTimerEnableMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelTimerEnableMaskChanged object:self];
}

- (void) setTimerEnableBit:(int)bit value:(BOOL)aValue
{
	unsigned long aMask = timerEnableMask;
	if(aValue)aMask |= (1<<bit);
	else aMask &= ~(1<<bit);
	[self setTimerEnableMask:aMask];
}

- (unsigned short) timerOption:(int)index
{
	if(index>=0 && index<kUE9NumTimers) return timerOption[index];
	else return 0;
}

- (void) setTimer:(int)index option:(unsigned short)aTimerOption
{
	if(index>=0 && index<kUE9NumTimers){
		[[[self undoManager] prepareWithInvocationTarget:self] setTimer:index option:timerOption[index]];
		timerOption[index] = aTimerOption;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelTimerOptionChanged object:self];
	}
}

- (ORLabJackUE9Cmd*) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(ORLabJackUE9Cmd*)aRequest
{
	[aRequest retain];
	[lastRequest release];
	lastRequest = aRequest;
}

- (NetSocket*) socket
{
	return socket;
}

- (void) setSocket:(NetSocket*)aSocket
{
	if(aSocket != socket)[socket close];
	[aSocket retain];
	[socket release];
	socket = aSocket;
    [socket setDelegate:self];
}

- (void) setIsConnected:(BOOL)aFlag
{
    isConnected = aFlag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9IsConnectedChanged object:self];
}

- (NSString*) ipAddress
{
    return ipAddress;
}

- (void) setIpAddress:(NSString*)aIpAddress
{
	if(!aIpAddress)aIpAddress = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIpAddress:ipAddress];
    
    [ipAddress autorelease];
    ipAddress = [aIpAddress copy];    
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9IpAddressChanged object:self];
}


- (void) connect
{
	if(!isConnected){
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:52360]];	
		wasConnected = YES;

	}
	else {
        wasConnected = NO;
		[self setSocket:nil];
        [self setIsConnected:[socket isConnected]];
	}
}

- (BOOL) isConnected
{
	return isConnected;
}
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        
        if(socketClosedAlarm){
            [socketClosedAlarm clearAlarm];
            [socketClosedAlarm release];
            socketClosedAlarm = nil;
        }
        
        [self setIsConnected:[socket isConnected]];
		[self getCalibrationInfo:0];
		[self getCalibrationInfo:1];
		[self getCalibrationInfo:2];
		[self getCalibrationInfo:3];
		[self getCalibrationInfo:4];
		[self sendComCmd:NO];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
    if(inNetSocket == socket){
		NSData* theData = [inNetSocket readData];
		switch(lastRequest.tag){
			case kUE9ComCmd: 
				[self decodeComCmd:theData]; 
			break;
				
			case kUE9CalBlock: 
				[self decodeCalibData:theData]; 
			break;
				
			case kUE9SingleIO:
				[self decodeSingleAdcRead:theData]; 
			break;
				
			case kUE9ReadAllValues:
				[self decodeReadAllValues:theData]; 
			break;
				
			case kUE9TimerCounter:
				[self decodeTimerCounter:theData]; 
			break;
			case kUE9ControlConfig:
				//don't need to handle this one. We only use it to ensure the power level gets
				//set right for the 48 MHz clock
			break;

		}
		
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
		[self setLastRequest:nil];			 //clear the last request
		[self processOneCommandFromQueue];	 //do the next command in the queu
	}
}

- (void) goToNextCommand
{
	[self setLastRequest:nil];			 //clear the last request
	[self processOneCommandFromQueue];	 //do the next command in the queue
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        if(wasConnected){
            if(!socketClosedAlarm){
                NSString* aName = [NSString stringWithFormat:@"%@ socket dropped",[self fullID]];
                socketClosedAlarm = [[ORAlarm alloc] initWithName:aName severity:kHardwareAlarm];
                [socketClosedAlarm setSticky:NO];
            }
            if(![socketClosedAlarm isPosted]){
                [socketClosedAlarm postAlarm];
                [socketClosedAlarm setMailDelay:k30SecDelay];
            }
        }
		[self setIsConnected:NO];
		[socket autorelease];
		socket = nil;
    }
}

- (BOOL) involvedInProcess
{
    return involvedInProcess;
}

- (void) setInvolvedInProcess:(BOOL)aInvolvedInProcess
{
    involvedInProcess = aInvolvedInProcess;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelInvolvedInProcessChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelAOut1Changed object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelAOut0Changed object:self];
}

- (float) slope:(int)i
{
	if(i>=0 && i<kUE9NumAdcs)return slope[i];
	else return 20./4095.;
}

- (void) setSlope:(int)i value:(float)aValue
{
	if(i>=0 && i<kUE9NumAdcs){
		[[[self undoManager] prepareWithInvocationTarget:self] setSlope:i value:slope[i]];
		
		slope[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9SlopeChanged object:self userInfo:userInfo];
		
	}
}

- (float) intercept:(int)i
{
	if(i>=0 && i<kUE9NumAdcs)return intercept[i];
	else return -10;
}

- (void) setIntercept:(int)i value:(float)aValue
{
	if(i>=0 && i<kUE9NumAdcs){
		[[[self undoManager] prepareWithInvocationTarget:self] setIntercept:i value:intercept[i]];
		
		intercept[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9InterceptChanged object:self userInfo:userInfo];
		
	}
}

- (float) lowLimit:(int)i
{
	if(i>=0 && i<kUE9NumAdcs)return lowLimit[i];
	else return 0;
}

- (void) setLowLimit:(int)i value:(float)aValue
{
	if(i>=0 && i<kUE9NumAdcs){
		[[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:i value:lowLimit[i]];
		
		lowLimit[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9LowLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) hiLimit:(int)i
{
	if(i>=0 && i<kUE9NumAdcs)return hiLimit[i];
	else return 0;
}

- (void) setHiLimit:(int)i value:(float)aValue
{
	if(i>=0 && i<kUE9NumAdcs){
		[[[self undoManager] prepareWithInvocationTarget:self] setHiLimit:i value:lowLimit[i]];
		
		hiLimit[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9HiLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) minValue:(int)i
{
	if(i>=0 && i<kUE9NumAdcs)return minValue[i];
	else return 0;
}

- (void) setMinValue:(int)i value:(float)aValue
{
	if(i>=0 && i<kUE9NumAdcs){
		[[[self undoManager] prepareWithInvocationTarget:self] setMinValue:i value:minValue[i]];
		
		minValue[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9MinValueChanged object:self userInfo:userInfo];
		
	}
}
- (float) maxValue:(int)i
{
	if(i>=0 && i<kUE9NumAdcs)return maxValue[i];
	else return 0;
}

- (void) setMaxValue:(int)i value:(float)aValue
{
	if(i>=0 && i<kUE9NumAdcs){
		[[[self undoManager] prepareWithInvocationTarget:self] setMaxValue:i value:maxValue[i]];
		
		maxValue[i] = aValue; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9MaxValueChanged object:self userInfo:userInfo];
		
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ShipDataChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9PollTimeChanged object:self];
}

- (BOOL) digitalOutputEnabled
{
    return digitalOutputEnabled;
}

- (void) setDigitalOutputEnabled:(BOOL)aDigitalOutputEnabled
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDigitalOutputEnabled:digitalOutputEnabled];
    digitalOutputEnabled = aDigitalOutputEnabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9DigitalOutputEnabledChanged object:self];
}

- (unsigned long) counter:(int)i
{
	if(i>=0 && i<2)return counter[i];
	else return 0;
}

- (void) setCounter:(int)i value:(unsigned long)aValue
{
	if(i>=0 && i<2){
		counter[i] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9CounterChanged object:self];
	}
}
- (unsigned long) timerResult:(int)i
{
	if(i>=0 && i<6)return timerResult[i];
	else return 0;
}
- (void) setTimerResult:(int)i value:(unsigned long)aValue
{
	if(i>=0 && i<6){
		timerResult[i] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ModelTimerResultChanged object:self];
	}
}

- (unsigned long) timer:(int)i
{
	if(i>=0 && i<6)return timer[i];
	else return 0;
}

- (void) setTimer:(int)i value:(unsigned long)aValue
{
	if(i>=0 && i<6){
		[[[self undoManager] prepareWithInvocationTarget:self] setTimer:i value:timer[i]];
		timer[i] = aValue;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9TimerChanged object:self];
	}
}

- (NSString*) channelName:(int)i
{
	if(i>=0 && i<kUE9NumAdcs){
		if([channelName[i] length])return channelName[i];
		else return [NSString stringWithFormat:@"Chan %d",i];
	}
	else return @"";
}

- (void) setChannel:(int)i name:(NSString*)aName
{
	if(i>=0 && i<kUE9NumAdcs){
		[[[self undoManager] prepareWithInvocationTarget:self] setChannel:i name:channelName[i]];
		
		[channelName[i] autorelease];
		channelName[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ChannelNameChanged object:self userInfo:userInfo];
		
	}
}

- (NSString*) channelUnit:(int)i
{
	if(i>=0 && i<kUE9NumAdcs){
		if([channelUnit[i] length])return channelUnit[i];
		else return @"V";
	}
	else return @"";
}

- (void) setChannel:(int)i unit:(NSString*)aName
{
	if(i>=0 && i<kUE9NumAdcs){
		[[[self undoManager] prepareWithInvocationTarget:self] setChannel:i unit:channelUnit[i]];
		
		[channelUnit[i] autorelease];
		channelUnit[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9ChannelUnitChanged object:self userInfo:userInfo];
		
	}
}

- (NSString*) doName:(int)i
{
	if(i>=0 && i<kUE9NumIO){
		if([doName[i] length])return doName[i];
		else return [NSString stringWithFormat:@"DO%d",i];
	}
	else return @"";
}

- (void) setDo:(int)i name:(NSString*)aName
{
	if(i>=0 && i<kUE9NumIO){
		[[[self undoManager] prepareWithInvocationTarget:self] setDo:i name:doName[i]];
		
		[doName[i] autorelease];
		doName[i] = [aName copy]; 
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9DoNameChanged object:self userInfo:userInfo];
	}
}

- (float) adc:(int)i
{
	unsigned short result = 0;
	@synchronized(self){
		if(i>=0 && i<kUE9NumAdcs){
			result =  adc[i];
		}
	}
	return result;
}

- (void) setAdc:(int)i value:(float)aValue
{
	@synchronized(self){
		if(i>=0 && i<kUE9NumAdcs){
			adc[i] = aValue; 
			
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9AdcChanged object:self userInfo:userInfo];
		}	
	}
}
- (int) gain:(int)i
{
	unsigned short result = 0;
	@synchronized(self){
		if(i>=0 && i<kUE9NumAdcs){
			result =  gain[i];
		}
	}
	return result;
}

- (void) setGain:(int)i value:(int)aValue
{
	@synchronized(self){
		if(i>=0 && i<kUE9NumAdcs){
			[[[self undoManager] prepareWithInvocationTarget:self] setGain:i value:gain[i]];
			gain[i] = aValue; 
			
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9GainChanged object:self userInfo:userInfo];
		}	
	}
}
- (BOOL) bipolar:(int)i
{
	unsigned short result = 0;
	@synchronized(self){
		if(i>=0 && i<kUE9NumAdcs){
			result =  bipolar[i];
		}
	}
	return result;
}

- (void) setBipolar:(int)i value:(BOOL)aValue
{
	@synchronized(self){
		if(i>=0 && i<kUE9NumAdcs){
			[[[self undoManager] prepareWithInvocationTarget:self] setBipolar:i value:bipolar[i]];
			bipolar[i] = aValue; 
			
			NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
			
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9BipolarChanged object:self userInfo:userInfo];
		}	
	}
}
- (unsigned long) doDirection
{
    return doDirection;
}

- (void) setDoDirection:(unsigned long)aMask
{
    [[[self undoManager] prepareWithInvocationTarget:self] setDoDirection:doDirection];
    doDirection = aMask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLabJackUE9DoDirectionChanged object:self];
}


- (void) setDoDirectionBit:(int)bit value:(BOOL)aValue
{
	unsigned long aMask = doDirection;
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
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9DoValueOutChanged object:self];
	}
}

- (void) setOutputBit:(int)bit value:(BOOL) aValue
{
	[self setDoValueOutBit:bit value:aValue];
}

- (void) setDoValueOutBit:(int)bit value:(BOOL)aValue
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

- (unsigned short) doValueIn
{
    return doValueIn;
}

- (void) setDoValueIn:(unsigned long)aMask
{
	@synchronized(self){
		doValueIn = aMask;
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORLabJackUE9DoValueInChanged object:self];
	}
}

- (void) setDoValueInBit:(int)bit value:(BOOL)aValue
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

- (void) resetCounter
{
	[self sendTimerCounter:kUE9ResetCounters];
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
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"LabJackUE9"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORLabJackUE9DecoderForIOData",@"decoder",
								 [NSNumber numberWithLong:dataId],   @"dataId",
								 [NSNumber numberWithBool:NO],       @"variable",
								 [NSNumber numberWithLong:kLabJackUE9DataSize],       @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"Temperatures"];
    
    return dataDictionary;
}

- (unsigned long) timeMeasured
{
	return timeMeasured;
}


- (void) shipIOData
{
    if([[ORGlobal sharedGlobal] runInProgress]){
		
		unsigned long data[kLabJackUE9DataSize];
		data[0] = dataId | kLabJackUE9DataSize;
		data[1] = ([self uniqueIdNumber] & 0x0000ffff);
		data[2] = timeMeasured;
	
		union {
			float asFloat;
			unsigned long asLong;
		} theData;
		
		int index = 3;
		int i;
		for(i=0;i<kUE9NumAdcs;i++){
			theData.asFloat = [self convertedValue:i];
			data[index] = theData.asLong;
			index++;
		}
		data[index++] = counter[0];
		data[index++] = counter[1];
		data[index++] = timerResult[0];
		data[index++] = timerResult[1];
		data[index++] = timerResult[2];
		data[index++] = timerResult[3];
		data[index++] = timerResult[4];
		data[index++] = timerResult[5];
		data[index++] = (doDirection & 0xFFFFFF);
		data[index++] = (doValueOut  & 0xFFFFFF);
		data[index++] = (doValueIn   & 0xFFFFFF);
	
		data[index++] = 0; //spares
		data[index++] = 0;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(long)*kLabJackUE9DataSize]];
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
			if(shipData) [self performSelectorOnMainThread:@selector(shipIOData) withObject:nil waitUntilDone:NO];
            readOnce = YES;
        }
		@catch(NSException* localException) { 
			//catch this here to prevent it from falling thru, but nothing to do.
        }
		
		//grab the bit pattern at the start of the cycle. it
		//will not be changed during the cycle.
		processInputValue = doValueIn & doDirection;
		processOutputMask = ~doDirection;
		
    }
}

- (void) endProcessCycle
{
	readOnce = NO;
	//don't use the setter so the undo manager is bypassed
	unsigned long newOutputValue = processOutputMask & processOutputValue & 0xFFFFFF;
	doValueOut |= newOutputValue;
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
    return [NSString stringWithFormat:@"LJUE9,%lu",[self uniqueIdNumber]];
}

- (NSString*) processingTitle
{
    return [self identifier];
}

- (double) convertedValue:(int)aChan
{
    if(aChan>=0 && aChan<kUE9NumAdcs){
        if([self adcEnabled:aChan])return slope[aChan] * adc[aChan] + intercept[aChan];
        else {
            maxValue[aChan] = 0; 
            minValue[aChan] = 0; 
        }
    }
	return 0;
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
		if(channel>=0 && channel<kUE9NumAdcs){
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
    [self setClockDivisor:[decoder decodeIntForKey:@"clockDivisor"]];
    [self setClockSelection:[decoder decodeIntForKey:@"clockSelection"]];
    [self setDoDirection:[decoder decodeInt32ForKey:@"doDirection"]];
    [self setTimerEnableMask:[decoder decodeIntForKey:@"timerEnableMask"]];
    [self setCounterEnableMask:[decoder decodeIntForKey:@"counterEnableMask"]];
  	[self setIpAddress:[decoder decodeObjectForKey:@"ipAddress"]];
	[self setAOut1:[decoder decodeIntForKey:@"aOut1"]];
    [self setAOut0:[decoder decodeIntForKey:@"aOut0"]];
    [self setShipData:[decoder decodeBoolForKey:@"shipData"]];
    [self setDigitalOutputEnabled:[decoder decodeBoolForKey:@"digitalOutputEnabled"]];
	int i;
	for(i=0;i<kUE9NumAdcs;i++) {
		
		NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"channelName%d",i]];
		if(aName)[self setChannel:i name:aName];
		else	 [self setChannel:i name:[NSString stringWithFormat:@"Chan %2d",i]];
		
		NSString* aUnit = [decoder decodeObjectForKey:[NSString stringWithFormat:@"channelUnit%d",i]];
		if(aUnit)[self setChannel:i unit:aName];
		else	 [self setChannel:i unit:@"V"];
		
		[self setMinValue:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"minValue%d",i]]];
		[self setMaxValue:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"maxValue%d",i]]];
		[self setLowLimit:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"lowLimit%d",i]]];
		[self setHiLimit:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"hiLimit%d",i]]];
		[self setSlope:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"slope%d",i]]];
		[self setIntercept:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"intercept%d",i]]];
	}
	for(i=0;i<3;i++) {
		[self setAdcEnabled:i mask:[decoder decodeInt32ForKey:[NSString stringWithFormat:@"adcEnabledMask%d",i]]];
	}
	
	for(i=0;i<kUE9NumIO;i++) {
		NSString* aName = [decoder decodeObjectForKey:[NSString stringWithFormat:@"DO%d",i]];
		if(aName)[self setDo:i name:aName];
		else [self setDo:i name:[NSString stringWithFormat:@"DO%d",i]];
	}
	
	for(i=0;i<kUE9NumAdcs;i++) {
		[self setGain:i value:[decoder decodeIntForKey:[NSString stringWithFormat:@"gain%d",i]]];
	}
	
	for(i=0;i<kUE9NumTimers;i++) {
		[self setTimer:i option:[decoder decodeIntForKey:[NSString stringWithFormat:@"timerOption%d",i]]];
	}
	
	wasConnected = [decoder decodeBoolForKey:@"wasConnected"];
	if(wasConnected && !isConnected)[self connect];
	
    [self setPollTime:		[decoder decodeIntForKey:@"pollTime"]];

	
	
    [[self undoManager] enableUndoRegistration]; 
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeBool:wasConnected forKey:@"wasConnected"];
	[encoder encodeInt:clockDivisor forKey:@"clockDivisor"];
	[encoder encodeInt:clockSelection forKey:@"clockSelection"];
	[encoder encodeInt:timerEnableMask forKey:@"timerEnableMask"];
	[encoder encodeInt:counterEnableMask forKey:@"counterEnableMask"];
	[encoder encodeObject:ipAddress forKey:@"ipAddress"];
	[encoder encodeInt:aOut1 forKey:@"aOut1"];
    [encoder encodeInt:aOut0 forKey:@"aOut0"];
    [encoder encodeBool:shipData forKey:@"shipData"];
    [encoder encodeInt:pollTime forKey:@"pollTime"];
    [encoder encodeInt32:doDirection forKey:@"doDirection"];
    [encoder encodeBool:digitalOutputEnabled forKey:@"digitalOutputEnabled"];
	int i;
	for(i=0;i<kUE9NumAdcs;i++) {
		[encoder encodeObject:channelUnit[i] forKey:[NSString stringWithFormat:@"unitName%d",i]];
		[encoder encodeObject:channelName[i] forKey:[NSString stringWithFormat:@"channelName%d",i]];
		[encoder encodeFloat:lowLimit[i] forKey:[NSString stringWithFormat:@"lowLimit%d",i]];
		[encoder encodeFloat:hiLimit[i] forKey:[NSString stringWithFormat:@"hiLimit%d",i]];
		[encoder encodeFloat:slope[i] forKey:[NSString stringWithFormat:@"slope%d",i]];
		[encoder encodeFloat:intercept[i] forKey:[NSString stringWithFormat:@"intercept%d",i]];
		[encoder encodeFloat:minValue[i] forKey:[NSString stringWithFormat:@"minValue%d",i]];
		[encoder encodeFloat:maxValue[i] forKey:[NSString stringWithFormat:@"maxValue%d",i]];
	}
	for(i=0;i<3;i++) {
		[encoder encodeInt32:adcEnabledMask[i] forKey:[NSString stringWithFormat:@"adcEnabledMask%d",i]];
	}
	
	for(i=0;i<kUE9NumIO;i++) {
		[encoder encodeObject:doName[i] forKey:[NSString stringWithFormat:@"DO%d",i]];
	}
	for(i=0;i<4;i++) {
		[encoder encodeInt:gain[i] forKey:[NSString stringWithFormat:@"gain%d",i]];
	}
	for(i=0;i<kUE9NumTimers;i++) {
		[encoder encodeInt:timerOption[i] forKey:[NSString stringWithFormat:@"timerOption%d",i]];
	}

}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	
    //[objDictionary setObject:[NSNumber numberWithInt:adcDiff] forKey:@"AdcDiffMask"];
	
    return objDictionary;
}

- (void) queryAll
{
	if([[self orcaObjects]count] == 0){
		[self readAllValues];
	}
	else {
		NSEnumerator* e  = [[self orcaObjects] objectEnumerator];
        ORCB37Model* aCB37;
        while(aCB37 = [e nextObject]){
			[self readAdcsForMux:[aCB37 slot]];
		}
		[self readAllValues];
	}
	[self sendTimerCounter:kUE9ReadCounters];
}

- (int) muxIndexFromAdcIndex:(int)adcIndex
{
	if([[self orcaObjects] count]==0)return adcIndex;
	else {
		if     (adcIndex >=  0 && adcIndex < 4)  return adcIndex;
		else if(adcIndex >=  4 && adcIndex < 12) return 120 + (adcIndex -  4); //slot X2
		else if(adcIndex >= 12 && adcIndex < 36) return  48 + (adcIndex - 12); //slot X3
		else if(adcIndex >= 36 && adcIndex < 60) return  72 + (adcIndex - 36); //slot X4
		else if(adcIndex >= 60 && adcIndex < 84) return  96 + (adcIndex - 60); //slot X5
		else return 119;
	}
}

- (int) adcIndexFromMuxIndex:(int)muxIndex
{
	if([[self orcaObjects] count]==0)return muxIndex;
	else {
		if     (muxIndex >= 0   && muxIndex <= 3)	return muxIndex;
		else if(muxIndex >= 120 && muxIndex <= 127) return (muxIndex - 120) + 4; //slot X2
		else if(muxIndex >=  48 && muxIndex <= 71)	return (muxIndex -  48) + 12; //slot X3
		else if(muxIndex >=  72 && muxIndex <= 95)  return (muxIndex -  72) + 36; //slot X4
		else if(muxIndex >=  96 && muxIndex <= 119) return (muxIndex -  96) + 60; //slot X5
		else return 83;
	}
}

- (void) pollHardware
{
	[self pollHardware:NO];
}

- (void) pollHardware:(BOOL)force
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollTime == 0 && !force)return;
	[self queryAll];
	if(pollTime == -1)[self performSelector:@selector(pollHardware) withObject:nil afterDelay:1/5.];
	else if(pollTime!=0) [self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}

- (void) enqueCmd:(NSData*)cmdData tag:(int)aTag
{
	if(![self isConnected])return;
	ORLabJackUE9Cmd* aCmd = [[[ORLabJackUE9Cmd alloc] init] autorelease];
	aCmd.cmdData  = cmdData;
	aCmd.tag	  = aTag;
	if(!cmdQueue)cmdQueue = [[ORSafeQueue alloc] init];
	[cmdQueue enqueue:aCmd];
	if(!lastRequest){
		[self processOneCommandFromQueue];
	}
}
- (void) processOneCommandFromQueue
{
	if(![self isConnected]){
		[cmdQueue removeAllObjects];
		[self setLastRequest:nil];
		return;
	}
	if([cmdQueue count] == 0) return;
	ORLabJackUE9Cmd* aCmd = [cmdQueue dequeue];
	[self setLastRequest:aCmd];
	
	if(aCmd){
		[self startTimeOut];
		unsigned char* sendBuffer = (unsigned char*)[[aCmd cmdData] bytes];
		[socket write:sendBuffer length:[[aCmd cmdData] length]];
	}
	if(!lastRequest){
		[self processOneCommandFromQueue];
	}
}

- (void) startTimeOut
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:10];
}

- (void) getCalibrationInfo:(int)block
{
	if(block>=0 && block<5){
		unsigned char sendBuffer[8];		
		sendBuffer[1] = (unsigned char)0xF8;  //command unsigned char
		sendBuffer[2] = (unsigned char)0x01;  //number of data words
		sendBuffer[3] = (unsigned char)0x2A;  //extended command number
		sendBuffer[6] = (unsigned char)0x00;
		sendBuffer[7] = (unsigned char)block;    //Blocknum = 0
		[self extendedChecksum:sendBuffer len:8];
		NSData* data = [NSData dataWithBytes:sendBuffer length:8];
		[self enqueCmd:data tag:kUE9CalBlock];
	}
}

- (void) sendComCmd:(BOOL)aVerbose
{		
	verbose = aVerbose;
	unsigned char sendBuff[38];
	sendBuff[1] = (unsigned char)0x78;  //command bytes
	sendBuff[2] = (unsigned char)0x10;  //number of data words
	sendBuff[3] = (unsigned char)0x01;  //extended command number
								  //Rest of the command is zero'ed out. not used.
	int i;
	for(i = 6; i < 38; i++) sendBuff[i] = (unsigned char)(0x00);
	
	[self extendedChecksum:sendBuff len:38];
	
	NSData* data = [NSData dataWithBytes:sendBuff length:38];
	[self enqueCmd:data tag:kUE9ComCmd];
}

- (void) readAllValues
{	
	unsigned char sendBuff[34];
	int i;
	unsigned short rawDacValue;
	
	unsigned char ainResolution = 12;
	
	sendBuff[1] = (unsigned char)0xF8;  //command byte
	sendBuff[2] = (unsigned char)0x0E;  //number of data words
	sendBuff[3] = (unsigned char)0x00;  //extended command number
	
	//the FIO, EIO, CIO and MIO directions and states
	unsigned long dirMask = ~doDirection; //*** backward from the U12. We invert here to be consistent
	sendBuff[6]  = (unsigned char)0xFF;					 //FIOMask
	sendBuff[7]  = (unsigned char)(dirMask & 0xFF);		 //FIODir
	sendBuff[8]  = (unsigned char)(doValueOut & 0xFF);	 //FIOState
	sendBuff[9]  = (unsigned char)0xFF;					 //MIOMask
	sendBuff[10] = (unsigned char)((dirMask>>8) & 0xFF); //MIODir
	sendBuff[11] = (unsigned char)((doValueOut>>8) & 0xFF); //MIOState
	sendBuff[12] = (unsigned char)0xFF;					//CIOMask
	sendBuff[13] = ((unsigned char)(((dirMask>>16) & 0xF)<<4) | ((doValueOut>>16) & 0xF)); //CIODirState: 7-4 Dir, 3-0 state

	sendBuff[14] = 0x0; //MIOMask not used
	sendBuff[15] = 0x0; //MIODirState not used
	
	unsigned char outputEnabled = 0x0;
	if(digitalOutputEnabled) outputEnabled = 0xC0;
	if([self convert:aOut0*4.86/4096 chan:0 result:&rawDacValue]==0){
		//setting the voltage of DAC0
		sendBuff[16] = (unsigned char)( rawDacValue & (0x00FF) ); //low bits of voltage
		sendBuff[17] = (unsigned char)( rawDacValue / 256 ) + outputEnabled; //high bits of voltage
	}
	else {
		sendBuff[16] = 0; //low bits of voltage
		sendBuff[17] = 0; //high bits of voltage
	}
	//(bit 7 : Enable, bit 6: Update)
	if([self convert:aOut1*4.86/4096 chan:1 result:&rawDacValue]==0){	
		//setting the voltage of DAC1
		sendBuff[18] = (unsigned char)( rawDacValue & (0x00FF) ); //low bits of voltage
		sendBuff[19] = (unsigned char)( rawDacValue / 256 ) + outputEnabled; //high bits of voltage
																	//(bit 7 : Enable, bit 6: Update)
	}
	else {
		sendBuff[18] = 0;
		sendBuff[19] = 0;
	}
	
	if([[self orcaObjects] count]==0){
		//only read the adc if there is no mux80 board
		sendBuff[20] = (unsigned char)(adcEnabledMask[0]&0xff);		  //AINMask AIN0-AIN7
		sendBuff[21] = (unsigned char)((adcEnabledMask[0]>>8)&0xff);  //AINMask AIN8 - AIN15
	}
	else {
		//there is at least one mux 80 so the adc reads will be done somewhere else
		sendBuff[20] = 0;  //AINMask AIN0-AIN7
		sendBuff[21] = 0;  //AINMask AIN8 - AIN15
	}
	sendBuff[22] = (unsigned char)(0x00);						  //AIN14ChannelNumber - not using
	sendBuff[23] = (unsigned char)(0x00);						  //AIN15ChannelNumber - not using
	sendBuff[24] = ainResolution;								  //Resolution = 12
	sendBuff[25] = 1;											  //SettlingTime
	
	for(i = 26; i < 34; i++) {
		sendBuff[i] = [self gainBipWord:i-26];
	}
	[self extendedChecksum:sendBuff len:34];
	
	NSData* data = [NSData dataWithBytes:sendBuff length:34];
	[self enqueCmd:data tag:kUE9ReadAllValues];
}

- (void) sendTimerCounter:(int) option
{

	//Note: If using the quadrature input timer mode, the returned 32 bit
    //      integer is signed
    unsigned char sendBuff[30];
	
    //Enable timers and counters
    sendBuff[1] = (unsigned char)0xF8;  //Command byte
    sendBuff[2] = (unsigned char)0x0C;  //Number of data words
    sendBuff[3] = (unsigned char)0x18;  //Extended command number
    sendBuff[6] = (unsigned char)clockDivisor;  //TimerClockDivisor
	
	unsigned char enableMask = 0;
	if(option & kUE9UpdateCounters){
		enableMask |= 0x80;										//update Config
		enableMask |= ((counterEnableMask & 0x3)<<3);			//counter enable bits
		enableMask |= ([self numberTimersEnabled] & 0x7);		//number of timers enabled
	}
    sendBuff[7] = (unsigned char)enableMask;  
										
    sendBuff[8] = (unsigned char)(clockSelection & 0x3);	//0 = 750 kHz (if using system 
															//clock, call ControlConfig first and set the 
															//PowerLevel to a fixed state)
	if(option & kUE9ResetCounters) sendBuff[9] = (unsigned char)0xFF;						//reset all the times and counters
	else sendBuff[9] = 0x0;
	
	int i;
	for(i=0;i<kUE9NumTimers;i++){
		sendBuff[10+i*3] = (unsigned char)timerOption[i]; 
		sendBuff[11+i*3] = (unsigned char) timer[i]&0x00FF;	  //Timer0Value (low byte)
		sendBuff[12+i*3] = (unsigned char)(timer[i]&0xFF00)>>8;  //Timer0Value (high byte)
	}
	
	sendBuff[28] = (unsigned char)0x00;  //Counter0Mode (always pass 0)
    sendBuff[29] = (unsigned char)0x00;  //Counter1Mode (always pass 0) 
	
	[self extendedChecksum:sendBuff len:30];
	
    //Sending command to UE9
	NSData* data = [NSData dataWithBytes:sendBuff length:30];
	[self enqueCmd:data tag:kUE9TimerCounter];
}

#pragma mark •••OROrderedObjHolding Protocol
- (int) maxNumberOfObjects	{ return 4; }
- (int) objWidth			{ return 16; }
- (int) groupSeparation		{ return 8; }
- (int) crateNumber			{ return 0; }
- (NSString*) nameForSlot:(int)aSlot	{ return [NSString stringWithFormat:@"Mux80 X%d",aSlot+2]; }

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj { return NO;}

- (NSRange) legalSlotsForObj:(id)anObj
{
	return NSMakeRange(0,[self maxNumberOfObjects]);
}

- (int) slotAtPoint:(NSPoint)aPoint 
{
	return floor(((int)aPoint.x)/([self objWidth]+[self groupSeparation]));
}

- (NSPoint) pointForSlot:(int)aSlot 
{
	return NSMakePoint(aSlot*([self objWidth]+[self groupSeparation]),0);
}

- (void) place:(id)anObj intoSlot:(int)aSlot
{
	[anObj setSlot: aSlot];
	[anObj moveTo:[self pointForSlot:aSlot]];
}

- (int) slotForObj:(id)anObj
{
	return [anObj slot];
}

- (int) numberSlotsNeededFor:(id)anObj
{
	return [anObj numberSlotsUsed];
}

- (void) changeIPAddress:(NSString*)aNewAddress
{
	NSArray* ipParts = [aNewAddress componentsSeparatedByString:@"."];
	if([ipParts count]==4){
		verbose = YES;
		[self setIpAddress:aNewAddress];
		unsigned char sendBuff[38];
		sendBuff[1] = (unsigned char)0x78;  //command bytes
		sendBuff[2] = (unsigned char)0x10;  //number of data words
		sendBuff[3] = (unsigned char)0x01;  //extended command number
											//Rest of the command is zero'ed out. not used.
		sendBuff[6] = 0x0C;					//mask set to write the IP number
		int i;
		for(i = 7; i < 38; i++) sendBuff[i] = (unsigned char)(0x00);
		
		sendBuff[10] = [[ipParts objectAtIndex:3] intValue];
		sendBuff[11] = [[ipParts objectAtIndex:2] intValue];
		sendBuff[12] = [[ipParts objectAtIndex:1] intValue];
		sendBuff[13] = [[ipParts objectAtIndex:0] intValue];

		sendBuff[14] = 1;
		sendBuff[15] = [[ipParts objectAtIndex:2] intValue];
		sendBuff[16] = [[ipParts objectAtIndex:1] intValue];
		sendBuff[17] = [[ipParts objectAtIndex:0] intValue];
		
		
		[self extendedChecksum:sendBuff len:38];
		
		NSData* data = [NSData dataWithBytes:sendBuff length:38];
		[self enqueCmd:data tag:kUE9ComCmd];
		NSLog(@"Change LabJack (%d) IP to %@\n",[self uniqueIdNumber],aNewAddress);
		NSLog(@"Change LabJack (%d) GateWasy to %@.%@.%@.1\n",[self uniqueIdNumber],[ipParts objectAtIndex:0],[ipParts objectAtIndex:1],[ipParts objectAtIndex:2]);
		NSLog(@"You must power cycle the UE9 before it takes effect\n");
		NSLog(@"You should restart ORCA as well.\n");
		[self connect]; //toggle the connection
	}
	else {
		NSLog(@"Can NOT change LabJack (%d) IP to %@\n",[self uniqueIdNumber],aNewAddress);
	}
}

- (void) changeLocalID:(unsigned char)newLocalID
{
	unsigned char sendBuff[38];
	sendBuff[1] = (unsigned char)0x78;  //command bytes
	sendBuff[2] = (unsigned char)0x10;  //number of data words
	sendBuff[3] = (unsigned char)0x01;  //extended command number
	sendBuff[6] = 0x01;					//mask set to write the LocalID number
	int i;
	for(i = 7; i < 38; i++) sendBuff[i] = (unsigned char)(0x00);
	
	sendBuff[8] = newLocalID;
	
	[self extendedChecksum:sendBuff len:38];
	
	NSData* data = [NSData dataWithBytes:sendBuff length:38];
	verbose = NO;
	[self enqueCmd:data tag:kUE9ComCmd];
	NSLog(@"Change LabJack (%d) LocalID to %d\n",[self uniqueIdNumber],newLocalID);
	NSLog(@"You must power cycle the UE9 before it takes effect\n");
}


- (BOOL) CB37Exists:(int)aSlot
{
    NSEnumerator* e = [[self orcaObjects] objectEnumerator];
    ORCB37Model* anObject;
    while(anObject = [e nextObject]){
        if([anObject slot] == aSlot)return YES;
    }
    return NO;
}

- (void) printChannelLocations
{
    int CB37Pin[14] = {37,18,36,17,35,16,34,15,33,14,32,13,31,12};
    int i;
    NSFont* font = [NSFont fontWithName:@"Monaco" size:11];
    NSLogFont(font, @"LabJackUE9 (%d) Channel Map\n",[self uniqueIdNumber]);
    if([[self orcaObjects] count]==0){
        //no CB37 attached
        for(i=0;i<4;i++)  NSLogFont(font,@"%2d DB37 %2d and Terminal Block AIN%2d\n",i,CB37Pin[i],i);
        for(i=4;i<14;i++) NSLogFont(font,@"%2d DB37 %2d\n",i,CB37Pin[i]);    
    }
    else {
        for(i=0;i<4;i++)NSLogFont(font,@"%2d Terminal Block AIN%2d\n",i,i);
        if([self CB37Exists:0] && [self CB37Exists:1]){
            for(i=0;i<12;i++) NSLogFont(font,@"%2d X2 AIN%2d\n",i,i);
            for(i=12;i<14;i++)NSLogFont(font,@"%2d X3 AIN%2d\n",i,i-12);
        }
        else if([self CB37Exists:0]  && ![self CB37Exists:1]){
            for(i=0;i<12;i++) NSLogFont(font,@"%2d X2 AIN%2d\n",i,i);
            for(i=12;i<14;i++)NSLogFont(font,@"%2d UnAvailable\n",i);       
        }
        else if(![self CB37Exists:0] && [self CB37Exists:1]){
            for(i=0;i<12;i++) NSLogFont(font,@"%2d UnAvailable\n",i);
            for(i=12;i<14;i++)NSLogFont(font,@"%2d X3 AIN%2d\n",i,i-12);       
        }
        else for(i=4;i<14;i++)NSLogFont(font,@"%2d UnAvailable\n",i);
    }
}


@end

@implementation ORLabJackUE9Model (private)

- (void) readSingleAdc:(int)aChan
{		
	unsigned char ainResolution = 12;
	unsigned char sendBuff[8];
	sendBuff[1] = (unsigned char)0xA3;			//command byte
	sendBuff[2] = (unsigned char)kUE9AnalogIn;  //IOType = 4 (adc)
	sendBuff[3] = (unsigned char)aChan;			//Channel
	sendBuff[4] = [self gainBipWord:[self adcIndexFromMuxIndex:aChan]/2];		//BipGain 
	sendBuff[5] = ainResolution;				//Resolution = 12
	sendBuff[6] = (unsigned char)0x00;			//SettlingTime = 0
	sendBuff[7] = (unsigned char)0x00;			//Reserved
	
	[self normalChecksum:sendBuff len:8];
	
	NSData* data = [NSData dataWithBytes:sendBuff length:8];
	[self enqueCmd:data tag:kUE9SingleIO];	
}

- (void) readAdcsForMux:(int)aMuxSlot
{
	int i;
	if(aMuxSlot == 0){
		for(i=0;i<24;i++){
			int muxIndex = [self muxIndexFromAdcIndex:i];
			if([self adcEnabled:i]){
				[self readSingleAdc:muxIndex];
			}
		}
	}
	else if(aMuxSlot >= 1){
		for(i=0;i<24;i++){
			int adcIndex = i + 12 + ((aMuxSlot-1)*24);
			int muxIndex = [self muxIndexFromAdcIndex:adcIndex];
			if([self adcEnabled:adcIndex]){
				[self readSingleAdc:muxIndex];
			}
		}
	}
}

- (unsigned char) numberTimersEnabled
{
	unsigned char count = 0;
	int i;
	for(i=0;i<kUE9NumTimers;i++){
		if(timerEnableMask & (0x1<<i)) count++;
	}
	return count;
}

- (void) timeout
{
	NSLogError(@"command timeout",@"LabJackUE9",nil);
	[cmdQueue removeAllObjects];
	[self setLastRequest:nil];
}
	
- (unsigned char) gainBipWord:(int)channelPair
{
	//info for two channel packed into one byte
	unsigned char gainBip = 0x00;
	if(channelPair>=0 && channelPair<kUE9NumAdcs/2){
		int chan = channelPair*2;
		
		//lower channel is in low nibble
		if(bipolar[chan]) gainBip |= 0x08;
		else gainBip |= gain[chan];
		
		//higer channel is in high nibble
		chan++;
		if(bipolar[chan]) gainBip |= 0x80;
		else gainBip |= (gain[chan]<<4);
	}
	return gainBip;
}

#pragma mark ***Checksum Helpers
- (void) normalChecksum:(unsigned char*)b len:(int)n
{
	b[0]=[self normalChecksum8:b len:n];
}

- (void) extendedChecksum:(unsigned char*)b len:(int)n
{
	unsigned short a;
	a = [self extendedChecksum16:b len:n];
	b[4] = (unsigned char)(a & 0xff);
	b[5] = (unsigned char)((a / 256) & 0xff);
	b[0] = [self extendedChecksum8:b];
}


- (unsigned char) normalChecksum8:(unsigned char*)b len:(int)n
{
	int i;
	unsigned short a, bb;
	
	//Sums bytes 1 to n-1 unsigned to a 2 byte value. Sums quotient and
	//remainder of 256 division.  Again, sums quotient and remainder of
	//256 division.
	for(i = 1, a = 0; i < n; i++){
		a+=(unsigned short)b[i];
	}
	bb = a / 256;
	a = (a - 256 * bb) + bb;
	bb = a / 256;
	
	return (unsigned char)((a-256*bb)+bb);
}


- (unsigned short) extendedChecksum16:(unsigned char*)b len:(int) n
{
	int i, a = 0;
	
	//Sums bytes 6 to n-1 to a unsigned 2 byte value
	for(i = 6; i < n; i++){
		a += (unsigned short)b[i];
	}
	return a;
}


/* Sum bytes 1 to 5. Sum quotient and remainder of 256 division. Again, sum
 quotient and remainder of 256 division. Return result as unsigned char. */
- (unsigned char) extendedChecksum8:(unsigned char*) b
{
	int i, a, bb;
	
	//Sums bytes 1 to 5. Sums quotient and remainder of 256 division. Again, sums 
	//quotient and remainder of 256 division.
	for(i = 1, a = 0; i < 6; i++){
		a+=(unsigned short)b[i];
	}
	bb = a / 256;
	a = (a - 256 * bb) + bb;
	bb = a / 256;
	
	return (unsigned char)((a - 256 * bb) + bb);  
}

- (double) bufferToDouble:(unsigned char*)buffer index:(int) startIndex 
{ 
    unsigned long resultDec = 0;
	unsigned long resultWh = 0;
    int i;
    for( i = 0; i < 4; i++ ){
        resultDec += (unsigned long)buffer[startIndex + i] * pow(2, (i*8));
        resultWh += (unsigned long)buffer[startIndex + i + 4] * pow(2, (i*8));
    }
	
    return ( (double)((int)resultWh) + (double)(resultDec)/4294967296.0 );
}

- (void) decodeComCmd:(NSData*) theData
{
	unsigned char* recBuff = (unsigned char*)[theData bytes];
	if(verbose){
		NSLog(@"LocalID (byte 8): %d\n", recBuff[8]);
		NSLog(@"PowerLevel (byte 9): %d\n", recBuff[9]);
		NSLog(@"ipAddress (bytes 10-13): %d.%d.%d.%d\n", recBuff[13], recBuff[12], recBuff[11], recBuff[10]);
		NSLog(@"Gateway (bytes 14 - 17): %d.%d.%d.%d\n", recBuff[17], recBuff[16], recBuff[15], recBuff[14]);
		NSLog(@"Subnet (bytes 18 - 21): %d.%d.%d.%d\n", recBuff[21], recBuff[20], recBuff[19], recBuff[18]);
		NSLog(@"PortA (bytes 22 - 23): %d\n", recBuff[22] + (recBuff[23] * 256 ));
		NSLog(@"PortB (bytes 24 - 25): %d\n", recBuff[24] + (recBuff[25] * 256 ));
		NSLog(@"DHCPEnabled (byte 26): %d\n", recBuff[26]);
		NSLog(@"ProductID (byte 27): %d\n", recBuff[27]);
		int i;
		NSString* s = @"MACAddress (bytes 28 - 33): ";
		for(i = 5; i >= 0  ; i--){
			s = [s stringByAppendingFormat:@"%02x",recBuff[i+28]];
			if(i !=0)s = [s stringByAppendingString:@"."];
		}
		NSLog(@"%@\n",s);
		NSLog(@"HWVersion (bytes 34-35): %.3f\n", (unsigned int)recBuff[35]  + (double)recBuff[34]/100.0);
		NSLog(@"CommFWVersion (bytes 36-37): %.3f\n\n", (unsigned int)recBuff[37] + (double)recBuff[36]/100.0);
		verbose = NO;
	}
	[self setLocalID:recBuff[8]];
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
}

- (void) decodeSingleAdcRead:(NSData*)theData
{
	unsigned char* recBuff = (unsigned char*)[theData bytes];
	unsigned long rawAdc = recBuff[5] + recBuff[6] * 256;
	float voltage;
	if([self convert:rawAdc gainBip:recBuff[4] result:&voltage]==0){
		int adcIndex = [self adcIndexFromMuxIndex:recBuff[3]];
		[self setAdc:adcIndex value:voltage];
	}
	else NSLogError(@"Error converting ADC result",@"LabJackUE9",nil);

}

- (void) decodeTimerCounter:(NSData*) theData
{
	int i;
	unsigned char* recBuff = (unsigned char*)[theData bytes];
	unsigned long enabledMask = recBuff[7];
	for( i = 0; i < kUE9NumTimers; i++ ){
		unsigned long value = 0 ;
		if(enabledMask & (0x1<<i)){
			value =	 (unsigned long)recBuff[8 + 4*i]      | 
			((unsigned long)recBuff[9 + 4*i]<<8)  | 
			((unsigned long)recBuff[10 + 4*i]<<16) | 
			((unsigned long)recBuff[11 + 4*i]<<24);
		}
		[self setTimerResult:i value:value];
    }

	for( i = 0; i < 2; i++ ){
		unsigned long value = 0;
		if(enabledMask & (0x40<<i)){
			value =	 (unsigned long)recBuff[32 + 4*i]      | 
					((unsigned long)recBuff[33 + 4*i]<<8)  | 
					((unsigned long)recBuff[34 + 4*i]<<16) | 
					((unsigned long)recBuff[35 + 4*i]<<24);
		}
        [self setCounter:i value:value];
    }
}

- (void) decodeReadAllValues:(NSData*) theData
{
	int i;
	unsigned char* recBuff = (unsigned char*)[theData bytes];
	if(recBuff[1] != (unsigned char)0xF8 || recBuff[2] != (unsigned char)0x1D || recBuff[3] != (unsigned char)0x00){
		NSLogError(@"received buffer has wrong command bytes",@"LabJackUE9",nil);
		return;
	}
	
	unsigned long dirMask = (recBuff[6] | (recBuff[8] << 8) | ((recBuff[10]&0xf) << 16));
	[self setDoValueIn: ~dirMask & (recBuff[7] | (recBuff[9] << 8) | ((recBuff[11]&0xf) << 16))];
	
	if([[self orcaObjects] count]==0){
		float voltage;
		for(i = 0; i < 14; i++){
			unsigned long rawAdc = recBuff[12 + 2*i] + recBuff[13 + 2*i] * 256;
			
			//getting analog voltage
			unsigned short gainBip = 0x00;
			if(bipolar[i]) gainBip = 0x8;
			else gainBip = gain[i];
			if([self convert:rawAdc gainBip:gainBip result:&voltage]==0){
				[self setAdc:i value:voltage];
			}
		}
	}
}

- (void) decodeCalibData:(NSData*)theData
{

	if( [theData length] < 136 ){
		NSLogError(@"Calibration data incomplete",@"LabJackUE9",nil);
		return;
	}
	unsigned char* recBuffer = (unsigned char*)[theData bytes];
	if( recBuffer[1] != (unsigned char)0xF8 || recBuffer[2] != (unsigned char)0x41 || recBuffer[3] != (unsigned char)0x2A ){
		NSLogError(@"received buffer has wrong command bytes",@"LabJackUE9",nil);
		return;
	}
	int i = recBuffer[7];
	
	switch(i){
		case 0:
			//block data starts on byte 8 of the buffer
			unipolarSlope[0]	= [self bufferToDouble:recBuffer + 8 index:0];
			unipolarOffset[0]	= [self bufferToDouble:recBuffer + 8 index:8];
			unipolarSlope[1]	= [self bufferToDouble:recBuffer + 8 index:16];
			unipolarOffset[1]	= [self bufferToDouble:recBuffer + 8 index:24];
			unipolarSlope[2]	= [self bufferToDouble:recBuffer + 8 index:32];
			unipolarOffset[2]	= [self bufferToDouble:recBuffer + 8 index:40];
			unipolarSlope[3]	= [self bufferToDouble:recBuffer + 8 index:48];
			unipolarOffset[3]	= [self bufferToDouble:recBuffer + 8 index:56];
		break;
			
		case 1:
			bipolarSlope	= [self bufferToDouble:recBuffer + 8 index:0];
			bipolarOffset	= [self bufferToDouble:recBuffer + 8 index:8];
		break;
			
		case 2:
			DACSlope[0]		= [self bufferToDouble:recBuffer + 8	index:0];
			DACOffset[0]	= [self bufferToDouble:recBuffer + 8	index:8];
			DACSlope[1]		= [self bufferToDouble:recBuffer + 8	index:16];
			DACOffset[1]	= [self bufferToDouble:recBuffer + 8	index:24];
			tempSlope		= [self bufferToDouble:recBuffer + 8	index:32];
			tempSlopeLow	= [self bufferToDouble:recBuffer + 8	index:48];
			calTemp			= [self bufferToDouble:recBuffer + 8	index:64];
			Vref			= [self bufferToDouble:recBuffer + 8	index:72];
			VrefDiv2		= [self bufferToDouble:recBuffer + 8	index:88];
			VsSlope			= [self bufferToDouble:recBuffer + 8	index:96];
		break;
			
		case 3:
			hiResUnipolarSlope  = [self bufferToDouble:recBuffer + 8 index:0];
			hiResUnipolarOffset = [self bufferToDouble:recBuffer + 8 index:8];
		break;
			
		case 4:
			hiResBipolarSlope  = [self bufferToDouble:recBuffer + 8 index:0];
			hiResBipolarOffset = [self bufferToDouble:recBuffer + 8 index:8];
		break;
	}
}
- (long) convert:(float) analogVoltage chan:(int) DACNumber result:(unsigned short*)rawDacValue
{
	float internalSlope;
	float internalOffset;
    
	switch(DACNumber) {
		case 0:
			internalSlope = DACSlope[0];
			internalOffset = DACOffset[0];
		break;
		case 1:
			internalSlope = DACSlope[1];
			internalOffset = DACOffset[1];
		break;
		default:
			return -1;
	}
	
	float tempBytesVoltage = internalSlope * analogVoltage + internalOffset;
	
	//Checking to make sure bytesVoltage will be a value between 0 and 4095, 
	//or that a unsigned short overflow does not occur.  A too high analogVoltage 
	//(above 5 volts) or too low analogVoltage (below 0 volts) will cause a 
	//value not between 0 and 4095.
	if(tempBytesVoltage < 0)	tempBytesVoltage = 0;
	if(tempBytesVoltage > 4095) tempBytesVoltage = 4095;
	
	*rawDacValue = (unsigned short)tempBytesVoltage; 
	
	return 0;
}

- (long) convert:(unsigned long)rawAdc gainBip:(unsigned short)gainBip result:(float*)analogVoltage
{
	float internalSlope;
	float internalOffset;
		
	switch(gainBip ){
		case 0:
			internalSlope = unipolarSlope[0];
			internalOffset = unipolarOffset[0];
		break;
		case 1:
			internalSlope = unipolarSlope[1];
			internalOffset = unipolarOffset[1];
		break;
		case 2:
			internalSlope = unipolarSlope[2];
			internalOffset = unipolarOffset[2];
		break;
		case 3:
			internalSlope = unipolarSlope[3];
			internalOffset = unipolarOffset[3];
		break;
		case 8:
			internalSlope = bipolarSlope;
			internalOffset = bipolarOffset;
		break;
		default:
			return -1;
	}
	*analogVoltage = (internalSlope * rawAdc) + internalOffset;
	return 0;
}
@end




