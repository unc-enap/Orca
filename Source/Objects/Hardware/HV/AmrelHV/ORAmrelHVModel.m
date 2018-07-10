//
//  ORAmrelHVModel.m
//  Orca
//
//  Created by Mark Howe on Thursday, Aug 20,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "ORAmrelHVModel.h"

#import "ORHVRampItem.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"
#import "ORSerialPortList.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"


#define kActualVoltageValidMask 0x4
#define kActualCurrentValidMask 0x2
#define kOutputValidMask		0x1
#define kDataValidMask (kActualVoltageValidMask | kActualCurrentValidMask | kOutputValidMask)

NSString* ORAmrelHVModelRampStateChanged	= @"ORAmrelHVModelRampStateChanged";
NSString* ORAmrelHVModelRampEnabledChanged	= @"ORAmrelHVModelRampEnabledChanged";
NSString* ORAmrelHVModelOutputStateChanged	= @"ORAmrelHVModelOutputStateChanged";
NSString* ORAmrelHVModelNumberOfChannelsChanged = @"ORAmrelHVModelNumberOfChannelsChanged";
NSString* ORAmrelHVSetVoltageChanged		= @"ORAmrelHVSetVoltageChanged";
NSString* ORAmrelHVActVoltageChanged		= @"ORAmrelHVActVoltageChanged";
NSString* ORAmrelHVModelRampRateChanged		= @"ORAmrelHVModelRampRateChanged";
NSString* ORAmrelHVPollTimeChanged			= @"ORAmrelHVPollTimeChanged";
NSString* ORAmrelHVModelTimeOutErrorChanged	= @"ORAmrelHVModelTimeOutErrorChanged";
NSString* ORAmrelHVActCurrentChanged		= @"ORAmrelHVActCurrentChanged";
NSString* ORAmrelHVMaxCurrentChanged		= @"ORAmrelHVMaxCurrentChanged";
NSString* ORAmrelHVLock						= @"ORAmrelHVLock";
NSString* ORAmrelHVModelSerialPortChanged	= @"ORAmrelHVModelSerialPortChanged";
NSString* ORAmrelHVModelPortNameChanged		= @"ORAmrelHVModelPortNameChanged";
NSString* ORAmrelHVModelPortStateChanged	= @"ORAmrelHVModelPortStateChanged";
NSString* ORAmrelHVPolarityChanged			= @"ORAmrelHVPolarityChanged";
NSString* ORAmrelHVModelTimeout				= @"ORAmrelHVModelTimeout";
NSString* ORAmrelHVModelDataIsValidChanged	= @"ORAmrelHVModelDataIsValidChanged";

@interface ORAmrelHVModel (private)
- (void) timeout;
- (void) processOneCommandFromQueue;
- (void) doVoltage:(unsigned short)aChan;
- (void) startRamp:(unsigned short)aChan;
- (void) runRampStep:(unsigned short)aChan;
- (void) setRampState:(unsigned short)aChan withValue:(int)aRampState;
- (void) setActVoltage:(unsigned short) aChan withValue:(float) aVoltage;
- (void) setDataValid:(unsigned short)aChan bit:(BOOL)aValue;
- (void) resetDataValid;
@end

#define kGetActualVoltageCmd	@"MEAS:VOLT?"
#define kGetActualCurrentCmd	@"MEAS:CURR?"
#define kSetVoltageCmd			@"VOLT:LEV"
#define kSetMaxCurrentCmd		@"CURR:LEV"
#define kSetCurrentTripCmd		@"CURR:PROT:STAT"
#define kCurrentTripClrCmd		@"CURR:PROT:CLE"
#define kSetOutputCmd			@"OUTP:STAT"
#define kGetOutputCmd			@"OUTP:STAT?"
#define kSetPolarityCmd			@"OUTP:REL:POL"
#define kGetPolarityCmd			@"OUTP:REL:POL?"

@implementation ORAmrelHVModel

- (void) makeMainController
{
    [self linkToController:@"ORAmrelHVController"];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [buffer release];
	[cmdQueue release];
	[lastRequest release];
    [portName release];
	[inComingData release];
    if([serialPort isOpen]){
        [serialPort close];
    }
	[serialPort setDelegate:nil];

	[lastRampStep[0] release];
	[lastRampStep[1] release];

    [serialPort release];
    [super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"AmrelHV"]];
}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(dataReceived:)
                         name : ORSerialPortDataReceived
                       object : nil];
}

#pragma mark ***Accessors
- (BOOL) channelIsValid:(unsigned short)aChan
{
	return (aChan<[self numberOfChannels]);
}

- (int) rampState:(unsigned short)aChan
{
  	if([self channelIsValid:aChan]) return rampState[aChan];
	else        return kAmrelHVNotRamping;
}

- (BOOL) rampEnabled:(unsigned short)aChan
{
 	if([self channelIsValid:aChan]) return rampEnabled[aChan];
	else return 0;
}

- (void) setRampEnabled:(unsigned short)aChan withValue:(BOOL)aRampEnabled
{
	if([self channelIsValid:aChan]){
		[[[self undoManager] prepareWithInvocationTarget:self] setRampEnabled:aChan withValue:rampEnabled[aChan]];
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		rampEnabled[aChan] = aRampEnabled;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelRampEnabledChanged object:self userInfo:userInfo];
	}
}

- (float) rampRate:(unsigned short)aChan
{
	if([self channelIsValid:aChan]) return rampRate[aChan];
	else        return 1;
}

- (void) setRampRate:(unsigned short)aChan withValue:(float)aRate;
{
	if([self channelIsValid:aChan]){
		if(aRate<.1) aRate = .1;
		[[[self undoManager] prepareWithInvocationTarget:self] setRampRate:aChan withValue:rampRate[aChan]];
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		rampRate[aChan] = aRate;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelRampRateChanged object:self userInfo:userInfo];
	}
}

- (BOOL) outputState:(unsigned short) aChan
{
	if([self channelIsValid:aChan]) return outputState[aChan];
	else        return 0;
}

- (void) setOutputState:(unsigned short)aChan withValue:(BOOL)aOutputState
{
	if([self channelIsValid:aChan]){
		if(aOutputState != outputState[aChan]) {
			statusChanged[aChan] = YES;
		}
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		outputState[aChan] = aOutputState;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelOutputStateChanged object:self userInfo:userInfo];
	}
	if((outputState[0] || outputState[1]) && pollTime == 0){
		[[self undoManager] disableUndoRegistration];
		[self setPollTime:2];
		[[self undoManager] enableUndoRegistration];
	}
	//else if(!outputState[0] && !outputState[1]){
	//	[[self undoManager] disableUndoRegistration];
	//	[self setPollTime:0];
	//	[[self undoManager] enableUndoRegistration];
	//}
}

- (int) numberOfChannels
{
	if(numberOfChannels==0)numberOfChannels=1;
    return numberOfChannels;
}

- (void) setNumberOfChannels:(int)aNumberOfChannels
{
	if(aNumberOfChannels==0)aNumberOfChannels = 1;
	else if(aNumberOfChannels>2)aNumberOfChannels=2;
    [[[self undoManager] prepareWithInvocationTarget:self] setNumberOfChannels:numberOfChannels];
    numberOfChannels = aNumberOfChannels;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelNumberOfChannelsChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVPollTimeChanged object:self];
	if(pollTime == 0){
		[self performSelector:@selector(resetDataValid) withObject:nil afterDelay:.1];
	}
	
}

- (BOOL) polarity:(unsigned short) aChan
{
	if(aChan>=kNumAmrelHVChannels)return 0;
    return polarity[aChan];
}

- (void)  setPolarity:(unsigned short) aChan withValue:(BOOL) aState
{
	if(aChan>=kNumAmrelHVChannels)return;
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[[self undoManager] prepareWithInvocationTarget:self] setPolarity:aChan withValue:polarity[aChan]];
	polarity[aChan] = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVPolarityChanged object:self  userInfo:userInfo];
}

- (float) voltage:(unsigned short) aChan
{
	if(aChan>=kNumAmrelHVChannels)return 0;
    return voltage[aChan];
}

- (void) setVoltage:(unsigned short) aChan withValue:(float) aVoltage
{
	if(aChan>=kNumAmrelHVChannels)return;
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[[self undoManager] prepareWithInvocationTarget:self] setVoltage:aChan withValue:voltage[aChan]];
	voltage[aChan] = aVoltage;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVSetVoltageChanged object:self  userInfo:userInfo];
}

- (float) actVoltage:(unsigned short) aChan
{
	if(aChan>=kNumAmrelHVChannels)return 0;
    return actVoltage[aChan];
}

- (float) actCurrent:(unsigned short) aChan
{
	if(aChan>=kNumAmrelHVChannels)return 0;
    return actCurrent[aChan];
}

- (void) setActCurrent:(unsigned short) aChan withValue:(float) aCurrent
{
	if(aChan>=kNumAmrelHVChannels)return;
	if(actCurrent[aChan] != aCurrent){
		if(fabs(actCurrent[aChan]-aCurrent)>.001){
			statusChanged[aChan] = YES;
		}		
		actCurrent[aChan] = aCurrent;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVActCurrentChanged object:self userInfo: userInfo];
	}
}

- (float) maxCurrent:(unsigned short) aChan
{
	if(aChan>=kNumAmrelHVChannels)return 0;
    return maxCurrent[aChan];
}

- (void) setMaxCurrent:(unsigned short) aChan withValue:(float) aCurrent
{
	if(aChan>=kNumAmrelHVChannels)return;
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxCurrent:aChan withValue:maxCurrent[aChan]];
	maxCurrent[aChan] = aCurrent;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVMaxCurrentChanged object:self  userInfo:userInfo];
}


- (NSString*) lockName
{
	return ORAmrelHVLock;
}

- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollTime == 0 )return;
	if([cmdQueue count] == 0){
		[self getAllValues];
		float nextPollTime = pollTime;
		if(   rampState[0] != kAmrelHVNotRamping 
		   || rampState[1] != kAmrelHVNotRamping) nextPollTime = 1;
		
		[self performSelector:@selector(pollHardware) withObject:nil afterDelay:nextPollTime];

	}
	else {
		//the queue is not empty... we'll try again in a short time.
		[self performSelector:@selector(pollHardware) withObject:nil afterDelay:1]; 
	}
}

- (void) getAllValues
{
	[[self undoManager] disableUndoRegistration];
	int i;
	for(i=0;i<[self numberOfChannels];i++){
		[self getOutput:i];
		[self getActualVoltage:i];
		[self getActualCurrent:i];
		if(statusChanged[i])[self shipVoltageRecords];
	}
	
    [[self undoManager] enableUndoRegistration];
}

- (void) shipVoltageRecords
{
	if([[ORGlobal sharedGlobal] runInProgress]){
		//get the time(UT!)
		time_t	ut_Time;
		time(&ut_Time);
		//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
		
		int i;
		for(i=0;i<[self numberOfChannels];i++){
			unsigned long data[5];
			data[0] = dataId | 5;
			data[1] = ((i & 0x1)<<28) | (([self outputState:i] & 0x1)<<16) | ([self uniqueIdNumber]&0xfff);
			data[2] = ut_Time;
			
			union {
				float asFloat;
				unsigned long asLong;
			}theData;
			theData.asFloat = actVoltage[i];
			data[3] = theData.asLong;
				
			theData.asFloat = actCurrent[i];
			data[4] = theData.asLong;
			[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																object:[NSData dataWithBytes:data length:sizeof(long)*5]];
			statusChanged[i] = NO;
		}
	}	
}

- (void) panicToZero:(unsigned short)aChan
{
	if(aChan == 0xFFFF ){
		[self stopRamp:0];
		[self stopRamp:1];
		[self sendCmd:kSetVoltageCmd channel:0 value:0];
		[self sendCmd:kSetVoltageCmd channel:1 value:0];
		[self setOutput:0 withValue:NO];
		[self setOutput:1 withValue:NO];
	}
	else if([self channelIsValid:aChan]){
		[self stopRamp:aChan];
		[self sendCmd:kSetVoltageCmd channel:aChan value:aChan];
		[self setOutput:aChan withValue:NO];
	}
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    [self setNumberOfChannels:[decoder decodeIntForKey:@"numberOfChannels"]];
	int i;
	for(i=0;i<kNumAmrelHVChannels;i++){
		[self setVoltage:i withValue:	 [decoder decodeFloatForKey:[NSString stringWithFormat:@"voltage%d",i]]];
		[self setMaxCurrent:i withValue: [decoder decodeFloatForKey:[NSString stringWithFormat:@"maxCurrent%d",i]]];
		[self setRampEnabled:i withValue:[decoder decodeBoolForKey:	[NSString stringWithFormat:@"rampEnabled%d",i]]];
		[self setRampRate:i withValue:	 [decoder decodeFloatForKey:[NSString stringWithFormat:@"rampingRate%d",i]]];
		if(rampRate[i]==0)[self setRampRate:i withValue:1.0];
	}
	[self setPortWasOpen:	[decoder decodeBoolForKey:	 @"portWasOpen"]];
    [self setPortName:		[decoder decodeObjectForKey: @"portName"]];
    [self setPollTime:		[decoder decodeIntForKey: @"pollTime"]];
    [[self undoManager] enableUndoRegistration];    
    [self registerNotificationObservers];
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeInt:numberOfChannels forKey:@"numberOfChannels"];
	int i;
	for(i=0;i<kNumAmrelHVChannels;i++){
		[encoder encodeFloat:voltage[i]		forKey:[NSString stringWithFormat:@"voltage%d",i]];
		[encoder encodeFloat:rampRate[i]	forKey:[NSString stringWithFormat:@"rampingRate%d",i]];
		[encoder encodeFloat:maxCurrent[i]	forKey:[NSString stringWithFormat:@"maxCurrent%d",i]];
		[encoder encodeBool:rampEnabled[i]	forKey:[NSString stringWithFormat:@"rampEnabled%d",i]];
	}
    [encoder encodeBool:portWasOpen		forKey: @"portWasOpen"];
    [encoder encodeObject:portName		forKey: @"portName"];
    [encoder encodeInt:pollTime			forKey: @"pollTime"];
}

- (void) sendCmd:(NSString*)aCommand channel:(short)aChannel value:(float)aValue
{
	if([serialPort isOpen]){
		if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
		[cmdQueue addObject:[aCommand stringByAppendingFormat:@" %d %f\r\n",aChannel+1,aValue]];
		if(!lastRequest)[self processOneCommandFromQueue];	
	}
}

- (void) sendCmd:(NSString*)aCommand channel:(short)aChannel boolValue:(BOOL)aValue
{
	if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
	[cmdQueue addObject:[aCommand stringByAppendingFormat:@" %d %d\r\n",aChannel+1,aValue]];
	if(!lastRequest && [serialPort isOpen])[self processOneCommandFromQueue];	
}

- (void) sendCmd:(NSString*)aCommand channel:(short)aChannel
{
	if([serialPort isOpen]){
		if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
		[cmdQueue addObject:[aCommand stringByAppendingFormat:@" %d\r\n",aChannel+1]];
		if(!lastRequest)[self processOneCommandFromQueue];
	}
}

- (void) sendCmd:(NSString*)aCommand
{	
	if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
	
	[cmdQueue addObject:aCommand];
	if(!lastRequest)[self processOneCommandFromQueue];
}

- (NSString*) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(NSString*)aRequest
{
	[aRequest retain];
	[lastRequest release];
	lastRequest = aRequest;    
}

- (BOOL) portWasOpen
{
    return portWasOpen;
}

- (void) setPortWasOpen:(BOOL)aPortWasOpen
{
    portWasOpen = aPortWasOpen;
}

- (NSString*) portName
{
    return portName;
}

- (void) setPortName:(NSString*)aPortName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortName:portName];
    
    if(![aPortName isEqualToString:portName]){
        [portName autorelease];
        portName = [aPortName copy];    
		
        BOOL valid = NO;
        NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
        ORSerialPort *aPort;
        while (aPort = [enumerator nextObject]) {
            if([portName isEqualToString:[aPort name]]){
                [self setSerialPort:aPort];
                if(portWasOpen){
                    [self openPort:YES];
				}
                valid = YES;
                break;
            }
        } 
        if(!valid){
            [self setSerialPort:nil];
        }       
    }
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelPortNameChanged object:self];
}

- (ORSerialPort*) serialPort
{
    return serialPort;
}

- (void) setSerialPort:(ORSerialPort*)aSerialPort
{
    [aSerialPort retain];
    [serialPort release];
    serialPort = aSerialPort;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelSerialPortChanged object:self];
}

- (void) openPort:(BOOL)state
{
    if(state) {
        [serialPort open];
		[serialPort setSpeed:9600];
		[serialPort setParityNone];
		[serialPort setStopBits2:NO];
		[serialPort setDataBits:8];
		[serialPort commitChanges];

		[serialPort setDelegate:self];

	}
    else {
		[serialPort close];
		[cmdQueue removeAllObjects];
	}
    portWasOpen = [serialPort isOpen];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelPortStateChanged object:self];
    
}

- (void) syncDialog
{
	int i;
	for(i=0;i<[self numberOfChannels];i++)doSync[i] = YES;
	[self getAllValues];
}

- (BOOL) allDataIsValid:(unsigned short)aChan
{
	if([self channelIsValid:aChan]){
		return (dataValidMask[aChan] & kDataValidMask) == kDataValidMask;
	}
	else return NO;
}



#pragma mark •••HW Commands
- (void) getID										{ [self sendCmd:@"*IDN?\r\n"]; }
- (void) getActualVoltage:(unsigned short)aChan		{ [self sendCmd:kGetActualVoltageCmd channel:aChan]; }
- (void) getActualCurrent:(unsigned short)aChan		{ [self sendCmd:kGetActualCurrentCmd channel:aChan]; }
- (void) getOutput:(unsigned short)aChan			{ [self sendCmd:kGetOutputCmd channel:aChan]; }
- (void) clearCurrentTrip:(unsigned short)aChan		{ [self sendCmd:kCurrentTripClrCmd channel:aChan]; }

- (void) setOutput:(unsigned short)aChannel withValue:(BOOL)aState
{
	[self sendCmd:kSetOutputCmd channel:aChannel value:aState]; 
}

- (void) togglePower:(unsigned short)aChannel
{
	if([self channelIsValid:aChannel]){
		if([self allDataIsValid:aChannel]){
			[self setVoltage:aChannel withValue:0];
			if(outputState[aChannel]){
				[self setOutput:aChannel withValue:NO];
			}
			else {
				[self setOutput:aChannel withValue:YES];
			}
		}
	}
}



- (void) loadHardware:(unsigned short)aChan
{
	if([self channelIsValid:aChan]){
		[self sendCmd:kSetOutputCmd     channel:aChan boolValue:outputState[aChan]];
		[self sendCmd:kSetPolarityCmd   channel:aChan boolValue:polarity[aChan]];
		[self sendCmd:kSetMaxCurrentCmd channel:aChan value:maxCurrent[aChan]];
		[self doVoltage:aChan];
	}
}


- (void) dataReceived:(NSNotification*)note
{
	//query response = OK\n\rRESPONSE\n\rOK\n\r
	//non-query response = OK\n\r
	//error response = OK\n\rERROR\n\rOK\n\r
	
	BOOL done = NO;
	if(!lastRequest){
		done = YES;
	}
    else if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
		if(!inComingData)inComingData = [[NSMutableData data] retain];
        [inComingData appendData:[[note userInfo] objectForKey:@"data"]];
		
		NSString* theLastCommand = [lastRequest uppercaseString];
		
		NSString* theResponse = [[[[NSString alloc] initWithData:inComingData 
														  encoding:NSASCIIStringEncoding] autorelease] uppercaseString];
		
		BOOL isQuery = ([theLastCommand rangeOfString:@"?"].location != NSNotFound);
		
		NSArray* parts = [theResponse componentsSeparatedByString:@"\r\n"];
		if(isQuery && [parts count] == 4){ //4 because the last \n\r results in a zero length part
			
			theResponse = [parts objectAtIndex:1];
			
			if([theResponse isEqualToString:@"ERROR"]){
				//count the error....
				done = YES;
			}
			else if([theLastCommand hasPrefix:@"*IDN?"]){
				NSLog(@"%@\n",theResponse);
				done = YES;
			}
			
			else if([theLastCommand hasPrefix:kGetActualVoltageCmd]){
				int theChannel	 = [[theLastCommand substringFromIndex:[kGetActualVoltageCmd length]] intValue] - 1;
				float theVoltage = [theResponse floatValue];
				[self setActVoltage:theChannel withValue:theVoltage];
				[self setDataValid:theChannel bit: kActualVoltageValidMask];
				if(doSync[theChannel]){
					[[self undoManager] disableUndoRegistration];
					[self setVoltage:theChannel withValue:theVoltage];
					doSync[theChannel] = NO;
					[[self undoManager] enableUndoRegistration];
				}
				[self runRampStep:theChannel];
				done = YES;
			}
			
			else if([theLastCommand hasPrefix:kGetActualCurrentCmd]){
				int theChannel	 = [[theLastCommand substringFromIndex:[kGetActualCurrentCmd length]] intValue] - 1;
				float theCurrent = [theResponse floatValue];
				[self setActCurrent:theChannel withValue:theCurrent];
				[self setDataValid:theChannel bit: kActualCurrentValidMask];
				done = YES;
			}
			
			else if([theLastCommand hasPrefix:kGetOutputCmd]){
				int theChannel = [[theLastCommand substringFromIndex:[kGetOutputCmd length]] intValue] - 1;
				BOOL theState  = [theResponse boolValue];
				[self setOutputState:theChannel withValue:theState];
				[self setDataValid:theChannel bit: kOutputValidMask];
				done = YES;
			}
			else {
				done = YES;
			}
		}	
		else if(!isQuery && [parts count] == 2){ //2 because the last \n\r results in a zero length part
			done = YES;
		}
		else if(!isQuery && [parts count] == 4){ //4 because the last \n\r results in a zero length part
			if([theResponse isEqualToString:@"ERROR"]){
				//count the error....
			}
			done = YES;
		}
	}
	if(done){
		[inComingData release];
		inComingData = nil;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
		[self setLastRequest:nil];			 //clear the last request
		[self processOneCommandFromQueue];	 //do the next command in the queue
	}
}

- (void) serialPortWriteProgress:(NSDictionary *)dataDictionary;
{
}

- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherSupply
{
    [self setDataId:[anotherSupply dataId]];
}

#pragma mark •••Header Stuff
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"AmrelHVModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORAmrelHVDecoderForHVStatus",                 @"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:NO],                   @"variable",
								 [NSNumber numberWithLong:5],					 @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"HVStatus"];
    return dataDictionary;
}


- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	
	NSArray* theActVoltages = [NSArray arrayWithObjects:[NSNumber numberWithFloat:actVoltage[0]],[NSNumber numberWithFloat:actVoltage[1]],nil];
    [objDictionary setObject:theActVoltages forKey:@"Voltages"];
	
	NSArray* theActCurrents = [NSArray arrayWithObjects:[NSNumber numberWithFloat:actCurrent[0]],[NSNumber numberWithFloat:actCurrent[1]],nil];
    [objDictionary setObject:theActCurrents forKey:@"Currents"];
	
	return objDictionary;
}

- (void) stopRamp:(unsigned short)aChan
{
	[self setRampState:aChan withValue: kAmrelHVNotRamping];
}

- (float) rampProgress:(unsigned short)aChan
{
	if(startDelta[aChan]){
		return 100.0 - 100.0*(fabs(targetVoltage[aChan]-actVoltage[aChan])/fabs(startDelta[aChan]));
	}
	else return 0;
}

@end

@implementation ORAmrelHVModel (private)

- (void) resetDataValid
{
	dataValidMask[0] = 0;
	dataValidMask[1] = 0;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelDataIsValidChanged object:self];
	
}

- (void) setDataValid:(unsigned short)aChan bit:(BOOL)aMask
{
	if([self channelIsValid:aChan]){
		if(pollTime!=0){
			if((dataValidMask[aChan] & aMask) != aMask){
				dataValidMask[aChan] |= aMask;
				[[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelDataIsValidChanged object:self];
			}
		}
		else [self performSelector:@selector(resetDataValid) withObject:nil afterDelay:.1];
	}
}

- (void) doVoltage:(unsigned short)aChan
{
	if([self rampEnabled:aChan]){
		if(rampState[aChan]==kAmrelHVNotRamping){
			[self startRamp:aChan];
		}
	}
	else {
		[self sendCmd:kSetVoltageCmd channel:aChan value:voltage[aChan]];
	}
}

- (void) startRamp:(unsigned short)aChan
{
	targetVoltage[aChan] = -1; //this will be set when we step
	startVoltage[aChan]  = -1; //this will be set when we step
	startDelta[aChan]    =  0; //this will be set when we step
	[self setRampState:aChan withValue: kAmrelHVRampStarting];
	[lastRampStep[aChan] release];
	lastRampStep[aChan] = nil;
}

- (void) runRampStep:(unsigned short)aChan
{	
	//only called after getting the actvoltage... try to drive it to the target
	if(voltage[aChan] != targetVoltage[aChan]){
		//the final target is changed. this will change how we calculate the percent done
		targetVoltage[aChan] = voltage[aChan];
		startVoltage[aChan] = actVoltage[aChan];
		startDelta[aChan] = targetVoltage[aChan] - startVoltage[aChan];
	}
	
	if(rampEnabled[aChan] && (rampState[aChan]!=kAmrelHVNotRamping)){
		if(lastRampStep[aChan]){
			float			deltaVoltage = voltage[aChan] - actVoltage[aChan];
			NSTimeInterval	deltaTime	 = [[NSDate date] timeIntervalSinceDate:lastRampStep[aChan]];
			if(fabs(deltaVoltage)<.1){
				[self stopRamp:aChan];
				[self sendCmd:kSetVoltageCmd channel:aChan value:voltage[aChan]];
			}
			else {
				float newVoltage;
				if(deltaVoltage<0){
					[self setRampState:aChan withValue: kAmrelHVRampingDn];
					newVoltage = actVoltage[aChan] - rampRate[aChan]*deltaTime;
					if(newVoltage<voltage[aChan])newVoltage = voltage[aChan];
				}
				else {
					[self setRampState:aChan withValue: kAmrelHVRampingUp];
					newVoltage = actVoltage[aChan] + rampRate[aChan]*deltaTime;
					if(newVoltage>voltage[aChan])newVoltage = voltage[aChan];
				}
				[self sendCmd:kSetVoltageCmd channel:aChan value:newVoltage];
			}
		}

		[lastRampStep[aChan] release];
		lastRampStep[aChan] = [[NSDate date] retain];
	}
}


- (void) timeout
{
	doSync[0] = NO;
	doSync[1] = NO;

	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	NSLogError(@"command timeout",@"AmrelHV",nil);
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelTimeout object:self];
	[self setLastRequest:nil];
	[cmdQueue removeAllObjects];
	[self processOneCommandFromQueue];	 //do the next command in the queue
}

- (void) processOneCommandFromQueue
{
	if([cmdQueue count] == 0) return;
	NSString* cmdString = [[[cmdQueue objectAtIndex:0] retain] autorelease];
	[cmdQueue removeObjectAtIndex:0];

	[self setLastRequest:cmdString];
	[serialPort writeDataInBackground:[cmdString dataUsingEncoding:NSASCIIStringEncoding]];
	[self performSelector:@selector(timeout) withObject:nil afterDelay:1];
	
}

- (void) setRampState:(unsigned short)aChan withValue:(int)aRampState
{
    rampState[aChan] = aRampState;
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVModelRampStateChanged object:self userInfo:userInfo];
}

- (void) setActVoltage:(unsigned short) aChan withValue:(float) aVoltage
{
	if(aChan>=kNumAmrelHVChannels)return;
	if(actVoltage[aChan] != aVoltage){
		if(fabs(actVoltage[aChan]-aVoltage)>1){
			statusChanged[aChan] = YES;
		}
		actVoltage[aChan] = aVoltage;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORAmrelHVActVoltageChanged object:self userInfo: userInfo];
	}
}

@end
