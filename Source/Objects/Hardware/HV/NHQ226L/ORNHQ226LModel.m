
// ORNHQ226LModel.cpp
// Orca
//
//  Created by Mark Howe on Tues Sept 14,2010.
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
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
#import "ORNHQ226LModel.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"

#pragma mark •••Notification Strings
NSString* ORNHQ226LModelSerialPortChanged	= @"ORNHQ226LModelSerialPortChanged";
NSString* ORNHQ226LModelPortNameChanged		= @"ORNHQ226LModelPortNameChanged";
NSString* ORNHQ226LModelPortStateChanged	= @"ORNHQ226LModelPortStateChanged";
NSString* ORNHQ226LModelPollingErrorChanged = @"ORNHQ226LModelPollingErrorChanged";
NSString* ORNHQ226LModelStatusReg1Changed	= @"ORNHQ226LModelStatusReg2Changed";
NSString* ORNHQ226LModelStatusReg2Changed	= @"ORNHQ226LModelStatusReg2Changed";
NSString* ORNHQ226LSettingsLock				= @"ORNHQ226LSettingsLock";
NSString* ORNHQ226LSetVoltageChanged		= @"ORNHQ226LSetVoltageChanged";
NSString* ORNHQ226LActVoltageChanged		= @"ORNHQ226LActVoltageChanged";
NSString* ORNHQ226LRampRateChanged			= @"ORNHQ226LRampRateChanged";
NSString* ORNHQ226LPollTimeChanged			= @"ORNHQ226LPollTimeChanged";
NSString* ORNHQ226LModelTimeOutErrorChanged	= @"ORNHQ226LModelTimeOutErrorChanged";
NSString* ORNHQ226LActCurrentChanged		= @"ORNHQ226LActCurrentChanged";
NSString* ORNHQ226LMaxCurrentChanged		= @"ORNHQ226LMaxCurrentChanged";
NSString* ORNHQ226LMaxVoltageChanged		= @"ORNHQ226LMaxVoltageChanged";
NSString* ORNHQ226LModelTimeout				= @"ORNHQ226LModelTimeout";

@implementation ORNHQ226LModel

- (id) init //designated initializer
{
    self = [super init];
	
    [[self undoManager] disableUndoRegistration];
		
    [[self undoManager] enableUndoRegistration];
	
    return self;
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
	[serialPort release];
	[super dealloc];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"NHQ226L"]];	
}

- (void) makeMainController
{
    [self linkToController:@"ORNHQ226LController"];
}

- (NSString*) helpURL
{
	return @"VME/NHQ226L.html";
}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
	
    [notifyCenter addObserver : self
                     selector : @selector(dataReceived:)
                         name : ORSerialPortDataReceived
                       object : nil];
}
#pragma mark •••Accessors

- (BOOL) pollingError
{
    return pollingError;
}

- (void) setPollingError:(BOOL)aPollingError
{
	if(pollingError!= aPollingError){
		pollingError = aPollingError;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelPollingErrorChanged object:self];
	}
}

- (unsigned short) statusReg1Chan:(unsigned short)aChan
{
	if(aChan>=kNumNHQ226LChannels)return 0;
    return statusReg1Chan[aChan];
}

- (void) setStatusReg1Chan:(unsigned short)aChan withValue:(unsigned short)aStatusWord
{
	if(aChan>=kNumNHQ226LChannels)return;
	if(statusReg1Chan[aChan] != aStatusWord || useStatusReg1Anyway[aChan]){
		statusChanged = YES;
		statusReg1Chan[aChan] = aStatusWord;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelStatusReg1Changed object:self userInfo:userInfo];
		useStatusReg1Anyway[aChan] = NO;
	}
}

- (unsigned short) statusReg2Chan:(unsigned short)aChan
{
	if(aChan>=kNumNHQ226LChannels)return 0;
    return statusReg2Chan[aChan];
}

- (void) setStatusReg2Chan:(unsigned short)aChan withValue:(unsigned short)aStatusWord
{
	if(aChan>=kNumNHQ226LChannels)return;
	if(statusReg2Chan[aChan] != aStatusWord){
		statusChanged = YES;
		statusReg2Chan[aChan] = aStatusWord;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelStatusReg2Changed object:self userInfo:userInfo];
	}
}

- (void) setTimeErrorState:(BOOL)aState
{
	if(timeOutError != aState){
		timeOutError = aState;
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelTimeOutErrorChanged object:self];
	}
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LPollTimeChanged object:self];
}

- (float) voltage:(unsigned short) aChan
{
	if(aChan>=kNumNHQ226LChannels)return 0;
    return voltage[aChan];
}

- (void) setVoltage:(unsigned short) aChan withValue:(float) aVoltage
{
	if(aChan>=kNumNHQ226LChannels)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setVoltage:aChan withValue:voltage[aChan]];
	voltage[aChan] = aVoltage;
    NSLog(@"NHQ226L (%d): Set Voltage %d: %f\n",[self uniqueIdNumber],aChan,aVoltage);
   [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LSetVoltageChanged object:self userInfo: nil];
}

- (float) actVoltage:(unsigned short) aChan
{
	if(aChan>=kNumNHQ226LChannels)return 0;
    return actVoltage[aChan];
}

- (void) setActVoltage:(unsigned short) aChan withValue:(float) aVoltage
{
	if(aChan>=kNumNHQ226LChannels)return;
    if(fabs(aVoltage)<1)aVoltage = 0;
	if(actVoltage[aChan] != aVoltage){
		if(fabs(actVoltage[aChan]-aVoltage)>1){
			statusChanged = YES;
		}
		actVoltage[aChan] = aVoltage;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LActVoltageChanged object:self userInfo: userInfo];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelStatusReg1Changed object:self userInfo: userInfo]; //also send this to force some updates
	}
}

- (float) actCurrent:(unsigned short) aChan
{
	if(aChan>=kNumNHQ226LChannels)return 0;
    return actCurrent[aChan];
}

- (void) setActCurrent:(unsigned short) aChan withValue:(float) aCurrent
{
	if(aChan>=kNumNHQ226LChannels)return;
	if(actCurrent[aChan] != aCurrent){
		statusChanged = YES;
		actCurrent[aChan] = aCurrent;
		NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:aChan] forKey:@"Channel"];
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LActCurrentChanged object:self userInfo: userInfo];
	}
}

- (float) maxCurrent:(unsigned short) aChan
{
	if(aChan>=kNumNHQ226LChannels)return 0;
    return maxCurrent[aChan];
}

- (void) setMaxCurrent:(unsigned short) aChan withValue:(float) aCurrent
{
	if(aChan>=kNumNHQ226LChannels)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxCurrent:aChan withValue:voltage[aChan]];
	maxCurrent[aChan] = aCurrent;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LMaxCurrentChanged object:self userInfo: nil];
}

- (float) maxVoltage:(unsigned short) aChan
{
	if(aChan>=kNumNHQ226LChannels)return 2;
	return maxVoltage[aChan];
}

- (void) setMaxVoltage:(unsigned short) aChan withValue:(float) aValue
{
	if(aChan>=kNumNHQ226LChannels)return;
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxVoltage:aChan withValue:maxVoltage[aChan]];
	maxVoltage[aChan] = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LMaxVoltageChanged object:self userInfo: nil];
}

- (unsigned short) rampRate:(unsigned short) aChan
{
	if(aChan>=kNumNHQ226LChannels)return 2;
	return rampRate[aChan];
}

- (void) setRampRate:(unsigned short) aChan withValue:(unsigned short) aRampRate
{
	if(aChan>=kNumNHQ226LChannels)return;
	
	if(aRampRate<2)aRampRate = 2;
	else if(aRampRate>255)aRampRate = 255;
	
	[[[self undoManager] prepareWithInvocationTarget:self] setVoltage:aChan withValue:[self voltage:aChan]];
	rampRate[aChan] = aRampRate;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LRampRateChanged object:self userInfo: nil];
}

- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}

#pragma mark •••Hardware Access
- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	if(pollTime == 0 )return;
    [[self undoManager] disableUndoRegistration];
	@try {
        if([cmdQueue count]==0){
            [self readStatusWord:0];
            [self readStatusWord:1];
            [self readModuleStatus:0];
            [self readModuleStatus:1];
            [self readActVoltage:0];
            [self readActVoltage:1];
            [self readActCurrent:0];
            [self readActCurrent:1];
            if(statusChanged)[self shipVoltageRecords];
            [self setPollingError:NO];
        }
	}
	@catch(NSException* e){
		[self setPollingError:YES];
		NSLogError(@"Polling Error",@"NHQ226L",nil);
	}
	
    [[self undoManager] enableUndoRegistration];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}

- (void) initBoard
{
}

- (void) loadValues:(unsigned short)aChannel
{
	useStatusReg1Anyway[aChannel] = YES; //force an update
	
	if(aChannel>=kNumNHQ226LChannels)return;
    [self sendCmd:[NSString stringWithFormat:@"V%d=%d",aChannel+1,rampRate[aChannel]]];
    [self sendCmd:[NSString stringWithFormat:@"D%d=%.2f",aChannel+1,voltage[aChannel]]];
    [self sendCmd:[NSString stringWithFormat:@"L%d=%.0f",aChannel+1,maxCurrent[aChannel]]];
    [self sendCmd:[NSString stringWithFormat:@"G%d",aChannel+1]];
}

- (void) stopRamp:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return;
	[self readActCurrent:aChannel];
    [self sendCmd:[NSString stringWithFormat:@"D%d=%.2f",aChannel+1,fabs(actVoltage[aChannel])]];
    [self sendCmd:[NSString stringWithFormat:@"G%d",aChannel+1]];
	
}

- (void) panicToZero:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return;
    [self sendCmd:[NSString stringWithFormat:@"V%d=%d",aChannel+1,255]];
    [self sendCmd:[NSString stringWithFormat:@"D%d=0.00",aChannel+1]];
    [self sendCmd:[NSString stringWithFormat:@"G%d",aChannel+1]];
}


- (void) readStatusWord:(unsigned short)aChan
{
	NSString* cmd = [NSString stringWithFormat:@"S%d",aChan+1];
	[self sendCmd:cmd];
}

- (void) readModuleStatus:(unsigned short)aChan
{
	NSString* cmd = [NSString stringWithFormat:@"T%d",aChan+1];
	[self sendCmd:cmd];
}

- (void) readActVoltage:(unsigned short)aChan
{
	NSString* cmd = [NSString stringWithFormat:@"U%d",aChan+1];
	[self sendCmd:cmd];
}

- (void) readActCurrent:(unsigned short)aChan
{
	NSString* cmd = [NSString stringWithFormat:@"I%d",aChan+1];
	[self sendCmd:cmd];
}

- (void) readModuleID
{
	[self sendCmd:@"#"];
}

#pragma mark •••Helpers
- (NSString*) rampStateString:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return @"";
    if(statusReg2Chan[aChannel] == kHVIsOn)return @"HV ON";
    else if(statusReg2Chan[aChannel] == kHVIsOff)return @"HV OFF";
    else if(statusReg2Chan[aChannel] == kLowToHigh)return @"Falling";
    else if(statusReg2Chan[aChannel] == kHighToLow)return @"Rising";
 	else return @"?";
}

- (eNHQ226LRampingState) rampingState:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return kHVOff;
	if(!(statusReg1Chan[aChannel] & kHVOff)){
		if(statusReg2Chan[aChannel] == kLowToHigh || statusReg2Chan[aChannel] == kHighToLow) {
			if(statusReg2Chan[aChannel] == kLowToHigh)return kHVRampingUp;
			else return kHVRampingDn;
		}
		else {
			if(statusReg2Chan[aChannel] == kHVIsOff)return kHVOff;
			else {
				if(fabs(actVoltage[aChannel])<2)return kHVStableLow;
				else return kHVStableHigh;
			}
		}
	}
	else return kHVOff;
}

- (BOOL) polarity:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return 0;
	return statusReg1Chan[aChannel] & kHVPolarity;
}

- (BOOL) hvPower:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return 0;
	return !(statusReg1Chan[aChannel] & kHVSwitch); //reversed so YES is power on
}

- (BOOL) killSwitch:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return 0;
	return (statusReg1Chan[aChannel] & kKillSwitch); 
}

- (BOOL) currentTripped:(unsigned short)aChannel
{
//	if(aChannel>=kNumNHQ226LChannels)return 0;
//	return (statusReg2Chan[aChannel] & kCurrentExceeded); 
return NO; /////////ToDo
}

- (BOOL) controlState:(unsigned short)aChannel
{
	if(aChannel>=kNumNHQ226LChannels)return NO;
	return !(statusReg1Chan[aChannel] & kHVControl);
}


#pragma mark •••Header Stuff
- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"NHQ226LModel"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORNHQ226LDecoderForHVStatus",                 @"decoder",
								 [NSNumber numberWithLong:dataId],               @"dataId",
								 [NSNumber numberWithBool:NO],                   @"variable",
								 [NSNumber numberWithLong:11],					 @"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"HVStatus"];
    return dataDictionary;
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
	int i;	
	for(i=0;i<kNumNHQ226LChannels;i++){
		[self setVoltage:i withValue:   [decoder decodeFloatForKey:[NSString stringWithFormat:@"voltage%d",i]]];
		[self setMaxCurrent:i withValue:[decoder decodeFloatForKey:[NSString stringWithFormat:@"maxCurrent%d",i]]];
		[self setRampRate:i withValue:  [decoder decodeIntForKey:  [NSString stringWithFormat:@"rampRate%d",i]]];
	}
	[self setPortWasOpen:	[decoder decodeBoolForKey:	 @"portWasOpen"]];
    [self setPortName:		[decoder decodeObjectForKey: @"portName"]];
	[self setPollTime:[decoder decodeIntForKey:@"pollTime"]];
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	int i;	
	for(i=0;i<kNumNHQ226LChannels;i++){
		[encoder encodeFloat:voltage[i]    forKey:[NSString stringWithFormat:@"voltage%d",i]];
		[encoder encodeFloat:maxCurrent[i] forKey:[NSString stringWithFormat:@"maxCurrent%d",i]];
		[encoder encodeInt:rampRate[i]     forKey:[NSString stringWithFormat:@"rampRate%d",i]];
	}
    [encoder encodeBool:portWasOpen		forKey: @"portWasOpen"];
    [encoder encodeObject:portName		forKey: @"portName"];
	[encoder encodeInt:pollTime			forKey:@"pollTime"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [super addParametersToDictionary:dictionary];
	NSArray* status1 = [NSArray arrayWithObjects:[NSNumber numberWithInt:statusReg1Chan[0]],[NSNumber numberWithInt:statusReg1Chan[1]],nil];
    [objDictionary setObject:status1 forKey:@"StatusReg1"];	

	NSArray* status2 = [NSArray arrayWithObjects:[NSNumber numberWithInt:statusReg2Chan[0]],[NSNumber numberWithInt:statusReg2Chan[1]],nil];
    [objDictionary setObject:status2 forKey:@"StatusReg2"];
	
	NSArray* theActVoltages = [NSArray arrayWithObjects:[NSNumber numberWithFloat:actVoltage[0]],[NSNumber numberWithFloat:actVoltage[1]],nil];
    [objDictionary setObject:theActVoltages forKey:@"Voltages"];
	
	NSArray* theActCurrents = [NSArray arrayWithObjects:[NSNumber numberWithFloat:actCurrent[0]],[NSNumber numberWithFloat:actCurrent[1]],nil];
    [objDictionary setObject:theActCurrents forKey:@"Currents"];
     	
	return objDictionary;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherNHQ226L
{
    [self setDataId:[anotherNHQ226L dataId]];
}

#pragma mark •••RecordShipper
- (void) shipVoltageRecords
{
	if([[ORGlobal sharedGlobal] runInProgress]){
		//get the time(UT!)
		time_t	ut_Time;
		time(&ut_Time);
		//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
		
		unsigned long data[11];
		data[0] = dataId | 11;
		data[1] = [self uniqueIdNumber]&0xfff;
		data[2] = ut_Time;
		
		union {
			float asFloat;
			unsigned long asLong;
		}theData;
		int index = 3;
		int i;
		for(i=0;i<2;i++){
			data[index++] = statusReg1Chan[i];
			data[index++] = statusReg2Chan[i];

			theData.asFloat = actVoltage[i];
			data[index++] = theData.asLong;

			theData.asFloat = actCurrent[i];
			data[index++] = theData.asLong;
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(long)*11]];
	}	
	statusChanged = NO;
}

#pragma mark •••Serial Port
- (void) sendCmd:(NSString*)aCommand
{
	if([serialPort isOpen]){
		if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
		[cmdQueue addObject:[aCommand stringByAppendingString:@"\r\n"]];
		if(!lastRequest)[self processOneCommandFromQueue];	
	}
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelPortNameChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelSerialPortChanged object:self];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelPortStateChanged object:self];
}

- (void) dataReceived:(NSNotification*)note
{
	BOOL done = NO;
	if(!lastRequest){
		done = YES;
	}
    else if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
		if(!inComingData)inComingData = [[NSMutableData data] retain];
        [inComingData appendData:[[note userInfo] objectForKey:@"data"]];

		NSString* theResponse = [[[[NSString alloc] initWithData: inComingData 
														encoding: NSASCIIStringEncoding] autorelease] uppercaseString];
		if(theResponse){
			if([theResponse hasPrefix:@"?"]){
				done = YES;
				//handle error
				NSLog(@"Got Error.\n");
			}
			else {
				NSArray* parts = [theResponse componentsSeparatedByString:@"\r\n"];
				if([parts count] == 3){
                    [self decode:parts];
					done = YES;
				}
				
			}
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

- (void) timeout
{
	doSync[0] = NO;
	doSync[1] = NO;
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	NSLogError(@"command timeout",@"NHQ226L",nil);
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNHQ226LModelTimeout object:self];
	[self setLastRequest:nil];
	[cmdQueue removeAllObjects];
	[inComingData release];
	inComingData = nil;
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

- (void) serialPortWriteProgress:(NSDictionary *)dataDictionary;
{
}

- (void) syncDialog
{
	int i;
	for(i=0;i<2;i++)doSync[i] = YES;
	[self getAllValues];
}

- (void) getAllValues
{
	[[self undoManager] disableUndoRegistration];
	int i;
	for(i=0;i<2;i++){
		//[self getOutput:i];
		[self readActVoltage:i];
		[self readActCurrent:i];
		if(statusChanged)[self shipVoltageRecords];
	}
    [[self undoManager] enableUndoRegistration];
}

- (void) decode:(NSArray*)parts
{
    @try {
        //assumes that parts has a count of 3
        NSString* p1 = [parts objectAtIndex:0];
        NSString* cmd = [p1 substringToIndex:1];
        NSString* p2 = [parts objectAtIndex:1];
        //NSString* p3 = [parts objectAtIndex:2];
        if([cmd isEqualToString:@"I"]){
            int chan = [[p1 substringFromIndex:1] intValue]-1;
            float mantisse = [[p2 substringToIndex:4] floatValue];
            float exponent = [[p2 substringFromIndex:4] floatValue];
            [self setActCurrent:chan withValue:mantisse * pow(10,exponent)];
        }
        else if([cmd isEqualToString:@"U"]){
            //Ux * {polarity/mantisse/exp} * 
            int chan = [[p1 substringFromIndex:1] intValue]-1;
            float mantisse = [[p2 substringToIndex:6] floatValue];
            float exponent = [[p2 substringFromIndex:6] floatValue];
            [self setActVoltage:chan withValue:mantisse * pow(10,exponent)];
        }
        else if([cmd isEqualToString:@"M"]){
            //Mx * nnn * //percent of Vout Max
            int chan = [[p1 substringFromIndex:1] intValue]-1;
            [self setMaxVoltage:chan withValue:[p2 floatValue]];
        }
        else if([cmd isEqualToString:@"N"]){
            //Nx * nnn * //percent of Vout Max
            int chan = [[p1 substringFromIndex:1] intValue]-1;
            [self setMaxCurrent:chan withValue:[p2 floatValue]];
        }
        else if([cmd isEqualToString:@"D"]){
            ////----doesn't appear to match the manaul.....
            //int chan = [[p1 substringFromIndex:1] intValue]-1;
            //NSRange r = [p1 rangeOfString:@"="];
            //if(r.location == NSNotFound){
                //Dx * {mantisse/exp} * //read Voltage
                //float mantisse = [[p2 substringToIndex:6] floatValue];
                //float exponent = [[p2 substringFromIndex:6] floatValue];
               // [self setVoltage:chan withValue:mantisse * pow(10,exponent)];
           // }
           // else {
                //Dx * Dx=nnnn.nn * //set Voltage
                //[self setVoltage:chan withValue:[[p1 substringFromIndex:3] floatValue]];
           // }
        }
        else if([cmd isEqualToString:@"V"]){
            int chan = [[p1 substringFromIndex:1] intValue]-1;
            NSRange r = [p2 rangeOfString:@"="];
            if(r.location == NSNotFound){
                //Vx * nnn * //read Ramp Speed
                [self setRampRate:chan withValue:[p2 intValue]];
            }
            else {
                //Vx * Vx=nnn * //set Ramp Speed
                [self setRampRate:chan withValue:[[p2 substringFromIndex:3] intValue]];
            }
        }
        else if([cmd isEqualToString:@"G"]){
            //Gx * Sx=nnn * //start voltage change Sx = status info
            //int chan = [[p1 substringFromIndex:1] intValue]-1;
            //NSString* status = [p2 substringFromIndex:3];
            //process status info
        }
        else if([cmd isEqualToString:@"S"]){
            //Sx *Sx=xxx * //status
            int chan = [[p1 substringFromIndex:1] intValue]-1;
            NSString* status = [p2 substringFromIndex:3];
            [self decodeStatus:status channel:chan];
        }
        else if([cmd isEqualToString:@"T"]){
            //Tx * nnn * //module status
            int chan = [[p1 substringFromIndex:1] intValue]-1;
            [self setStatusReg1Chan:chan withValue:[p2 intValue]];
        }
        else if([cmd isEqualToString:@"#"]){
            NSArray* p = [p2 componentsSeparatedByString:@";"];
            if([p count] >= 4){
                NSLog(@"NHQ226L (%d):\n", [self uniqueIdNumber]);
                NSLog(@"Unit Number = %@\n",[p objectAtIndex:0]);
                NSLog(@"Firmware Ver = %@\n",[p objectAtIndex:1]);
                NSLog(@"Vout Max = %@\n",[p objectAtIndex:2]);
                NSLog(@"Iout Max = %@\n",[p objectAtIndex:3]);
            }

        }
	}
    @catch(NSException* e){
        NSLog(@"NHQ226L (%d): Failed at: %@\n",[self uniqueIdNumber],parts);
    }
	
}
- (NSString*) status2String:(unsigned short)aChan
{
    switch(statusReg2Chan[aChan]){
        case kHVIsOn:       return @"ON";
        case kHVIsOff:      return @"OFF";
        case kLowToHigh:    return @"Going Low To High";
        case kHighToLow:    return @"Going High To Low";
        case kManual:       return @"Manual";
        case kErr:          return @"V or I Exceeded";
        case kInh:          return @"Inhibit Was Active";
        case kTrip:         return @"I Trip Was Active";
        default:            return @"--";
    }
}

- (void) decodeStatus:(NSString*)s channel:(int)aChan
{
    if([s hasPrefix:@"ON"]){
        [self setStatusReg2Chan:aChan withValue:kHVIsOn];
    }
    else if([s hasPrefix:@"OFF"]){
        [self setStatusReg2Chan:aChan withValue:kHVIsOff];
    }
    else if([s hasPrefix:@"L2H"]){
        [self setStatusReg2Chan:aChan withValue:kLowToHigh];
    }
    else if([s hasPrefix:@"H2L"]){
        [self setStatusReg2Chan:aChan withValue:kHighToLow];
    }
    else if([s hasPrefix:@"MAN"]){
        [self setStatusReg2Chan:aChan withValue:kManual];
    }
    else if([s hasPrefix:@"ERR"]){
        [self setStatusReg2Chan:aChan withValue:kErr];
    }
    else if([s hasPrefix:@"INH"]){
        [self setStatusReg2Chan:aChan withValue:kInh];
    }
    else if([s hasPrefix:@"TRP"]){
        [self setStatusReg2Chan:aChan withValue:kTrip];
    }
}

@end
