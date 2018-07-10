//
//  ORNplpCMeterModel.m
//  Orca
//
//  Created by Mark Howe on Mon Apr 21 2008
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


#pragma mark •••Imported Files
#import "ORNplpCMeterModel.h"
#import "NetSocket.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORQueue.h"

NSString* ORNplpCMeterReceiveCountChanged	= @"ORNplpCMeterReceiveCountChanged";
NSString* ORNplpCMeterIsConnectedChanged	= @"ORNplpCMeterIsConnectedChanged";
NSString* ORNplpCMeterIpAddressChanged		= @"ORNplpCMeterIpAddressChanged";
NSString* ORNplpCMeterAverageChanged		= @"ORNplpCMeterAverageChanged";
NSString* ORNplpCMeterFrameError			= @"ORNplpCMeterFrameError";
NSString* ORNplpCMeterLock					= @"ORNplpCMeterLock";
NSString* ORNplpCMeterMinValueChanged		= @"ORNplpCMeterMinValueChanged";
NSString* ORNplpCMeterMaxValueChanged		= @"ORNplpCMeterMaxValueChanged";
NSString* ORNplpCMeterHiLimitChanged		= @"ORNplpCMeterHiLimitChanged";
NSString* ORNplpCMeterLowLimitChanged		= @"ORNplpCMeterLowLimitChanged";


@implementation ORNplpCMeterModel

- (void) makeMainController
{
    [self linkToController:@"ORNplpCMeterController"];
}

- (void) dealloc
{
	[socket close];
    [socket setDelegate:nil];
	[socket release];
	[meterData release];
	
	int i;
	for(i=0;i<kNplpCNumChannels;i++) [dataStack[i] release];
	
    [super dealloc];
}

- (void) awakeAfterDocumentLoaded
{
	@try {
		
		int i;
		for(i=0;i<kNplpCNumChannels;i++) dataStack[i] = [[ORQueue alloc] init];
		
		[self connect];
		[self connectionChanged];
	}
	@catch(NSException* localException) {
	}
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"NplpCMeterIcon"]];
}

#pragma mark ***Accessors

- (unsigned short) receiveCount
{
    return receiveCount;
}

- (void) setReceiveCount:(unsigned short)aCount
{
    receiveCount = aCount;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNplpCMeterReceiveCountChanged object:self];
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

- (unsigned int) frameError
{
	return frameError;
}

- (void) setFrameError:(unsigned int)aValue
{
	frameError = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORNplpCMeterFrameError object:self];
	
}

- (void) setIsConnected:(BOOL)aFlag
{
    isConnected = aFlag;
	[self setReceiveCount:0];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNplpCMeterIsConnectedChanged object:self];
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
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNplpCMeterIpAddressChanged object:self];
}


- (void) connect
{
	if(!isConnected){
		[self setSocket:[NetSocket netsocketConnectedToHost:ipAddress port:kNplpCMeterPort]];	
	}
	else {
		[self stop];
		[self setSocket:nil];	
        [self setIsConnected:[socket isConnected]];
	}
}

- (BOOL) isConnected
{
	return isConnected;
}

- (float) meterAverage:(unsigned short)aChannel
{
	if(aChannel<kNplpCNumChannels)return meterAverage[aChannel];
	else return 0;
}

- (void) setMeter:(int)chan average:(float)aValue
{
	meterAverage[chan] = aValue;
	NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORNplpCMeterAverageChanged object:self userInfo:userInfo];
	
}

- (void) appendMeterData:(NSData*)someData
{
	if(!meterData)meterData = [[NSMutableData alloc] initWithCapacity:1024];
	[meterData appendData:someData];
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
		[self start];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
    if(inNetSocket == socket){
		[self appendMeterData:[inNetSocket readData]];
		[self shipValues];
	}
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:NO];
		[socket autorelease];
		socket = nil;
    }
}

- (void) start
{
	[socket write:&kNplpCStart length:1];
}

- (void) stop
{
	[socket write:&kNplpCStop length:1];
}

#pragma mark •••Data Records
- (unsigned long) dataId
{
	return dataId;
}

- (void) setDataId: (unsigned long) aDataId
{
	dataId = aDataId;
}

- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherCard
{
    [self setDataId:[anotherCard dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"NplpCMeter"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
								 @"ORNplpCMeterDecoder",					@"decoder",
								 [NSNumber numberWithLong:dataId],       @"dataId",
								 [NSNumber numberWithBool:YES],          @"variable",
								 [NSNumber numberWithLong:-1],			@"length",
								 nil];
    [dataDictionary setObject:aDictionary forKey:@"NplpCMeter"];
    
    return dataDictionary;
}

- (void) shipValues
{
	
	unsigned int numBytes = [meterData length];
	if((numBytes>23) /*&& (numBytes%4 == 0)*/) {											//OK, we know we got a integer number of long words
		if([self validateMeterData]){
			unsigned long data[1003];									//max buffer size is 1000 data words + ORCA header
			unsigned int numLongsToShip = numBytes/sizeof(long);		//convert size to longs
			numLongsToShip = numLongsToShip<1000?numLongsToShip:1000;	//don't exceed the data array
			data[0] = dataId | (3 + numLongsToShip);					//first word is ORCA id and size
			data[1] =  [self uniqueIdNumber]&0xf;						//second word is device number
			
			//get the time(UT!)
			time_t	ut_time;
			time(&ut_time);
			//struct tm* theTimeGMTAsStruct = gmtime(&theTime);
			//time_t ut_time = mktime(theTimeGMTAsStruct);
			data[2] = ut_time;											//third word is seconds since 1970 (UT)
			
			unsigned long* p = (unsigned long*)[meterData bytes];
			
			int i;
			for(i=0;i<numLongsToShip;i++){
				p[i] = CFSwapInt32BigToHost(p[i]);
				data[3+i] = p[i];
				int chan = (p[i] & 0x00600000) >> 21;
				if(chan < kNplpCNumChannels) [dataStack[chan] enqueue: [NSNumber numberWithLong:p[i] & 0x000fffff]];
			}
			
			[self averageMeterData];
			[meterData replaceBytesInRange:NSMakeRange(0,numLongsToShip*sizeof(long)) withBytes:nil length:0];
			
			if([gOrcaGlobals runInProgress] && numBytes>0){
				[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
																	object:[NSData dataWithBytes:data length:(3+numLongsToShip)*sizeof(long)]];
			}
			[self setReceiveCount: receiveCount + 1];
		}
		
		else {
			unsigned char* p = (unsigned char*)[meterData bytes];
			unsigned int ctmax = [meterData length] - 4;
			
			unsigned int ctgood = 0;
			for (; ctgood<ctmax && (p[ctgood]+1)%256 == p[ctgood+4]; ctgood+=4); // ctgood is now the first bad data entry
			
			unsigned int ctbad = ctgood;
			for (;ctbad<ctmax && (p[ctbad]+1)%256 != p[ctbad+4]; ++ctbad); // ctbad is now the first good data entry
			
			[meterData replaceBytesInRange:NSMakeRange(ctgood,(ctbad-ctgood)) withBytes:nil length:0]; 
			
			// if still bad, restart the connection. validatateMeterData will allow for 1 missing entry
			if (![self validateMeterData]){ 
				[self stop];
				[self performSelector:@selector(restart) withObject:nil afterDelay:2];
			}	
			
			[self setFrameError:frameError+1];
		}
	}
	
}

- (void) restart
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[meterData release];
	meterData = nil;
	int i;
	for(i=0;i<kNplpCNumChannels;i++) {
		[dataStack[i] release];
		dataStack[i] = [[ORQueue alloc] init];
	}
	if (isConnected) {
		[self performSelector:@selector(connect) withObject:nil afterDelay:2];		
		[self performSelector:@selector(start) withObject:nil afterDelay:2];		
		[self performSelector:@selector(connect) withObject:nil afterDelay:2];
	}
	else 
		[self performSelector:@selector(start) withObject:nil afterDelay:2];
	
}

- (void) averageMeterData
{
	int chan;
	for(chan=0;chan<kNplpCNumChannels;chan++){
		int count = [dataStack[chan] count];
		if(count){
			NSEnumerator* e = [dataStack[chan] objectEnumerator];
			NSNumber* aValue;
			long sum = 0;
			while(aValue = [e nextObject]){
				sum += [aValue longValue];
			}
			[self setMeter:chan average:sum/(float)count];
			if(count>10){
				int j;
				for(j=0;j<count-10;j++)[dataStack[chan] dequeueFromBottom];
			}
		}
		else [self setMeter:chan average:0];
		
	}
}

- (BOOL) validateMeterData
{
	unsigned long* p = (unsigned long*)[meterData bytes];
	unsigned int len = [meterData length]/4;
	int i;
	short lastCount = 0;
	short count;
	short missing = 0;
	for(i=0;i<len;i++){
		count = CFSwapInt32BigToHost(p[i])>>24;
		if(i!=0)
			if(count != (lastCount+1)%256){
				missing+=(count-lastCount+255)%256;
				if (missing>1) // allow for up to one missing event
					return NO;
			}
		lastCount = count;
	}
	return YES;
}
- (float) lowLimit:(int)i
{
	if(i>=0 && i<kNplpCNumChannels)return lowLimit[i];
	else return 0;
}

- (void) setLowLimit:(int)i value:(float)aValue
{
	if(i>=0 && i<kNplpCNumChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setLowLimit:i value:lowLimit[i]];
		
		lowLimit[i] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNplpCMeterLowLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) hiLimit:(int)i
{
	if(i>=0 && i<kNplpCNumChannels)return hiLimit[i];
	else return 0;
}

- (void) setHiLimit:(int)i value:(float)aValue
{
	if(i>=0 && i<kNplpCNumChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setHiLimit:i value:lowLimit[i]];
		
		hiLimit[i] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNplpCMeterHiLimitChanged object:self userInfo:userInfo];
		
	}
}

- (float) minValue:(int)i
{
	if(i>=0 && i<kNplpCNumChannels)return minValue[i];
	else return 0;
}

- (void) setMinValue:(int)i value:(float)aValue
{
	if(i>=0 && i<kNplpCNumChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setMinValue:i value:minValue[i]];
		
		minValue[i] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNplpCMeterMinValueChanged object:self userInfo:userInfo];
		
	}
}
- (float) maxValue:(int)i
{
	if(i>=0 && i<kNplpCNumChannels)return maxValue[i];
	else return 0;
}

- (void) setMaxValue:(int)i value:(float)aValue
{
	if(i>=0 && i<kNplpCNumChannels){
		[[[self undoManager] prepareWithInvocationTarget:self] setMaxValue:i value:maxValue[i]];
		
		maxValue[i] = aValue;
		
		NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
		[userInfo setObject:[NSNumber numberWithInt:i] forKey: @"Channel"];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORNplpCMeterMaxValueChanged object:self userInfo:userInfo];
		
	}
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
	[self setIpAddress:[decoder decodeObjectForKey:@"ORNplpCMeterModelIpAddress"]];
    int i;
    for(i=0;i<kNplpCNumChannels;i++) {
        [self setMinValue:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"minValue%d",i]]];
        [self setMaxValue:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"maxValue%d",i]]];
        [self setLowLimit:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"lowLimit%d",i]]];
        [self setHiLimit:i value:[decoder decodeFloatForKey:[NSString stringWithFormat:@"hiLimit%d",i]]];
    }
    [[self undoManager] enableUndoRegistration];
	
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:ipAddress forKey:@"ORNplpCMeterModelIpAddress"];
    int i;
    for(i=0;i<kNplpCNumChannels;i++) {
        [encoder encodeFloat:lowLimit[i] forKey:[NSString stringWithFormat:@"lowLimit%d",i]];
        [encoder encodeFloat:hiLimit[i] forKey:[NSString stringWithFormat:@"hiLimit%d",i]];
        [encoder encodeFloat:minValue[i] forKey:[NSString stringWithFormat:@"minValue%d",i]];
        [encoder encodeFloat:maxValue[i] forKey:[NSString stringWithFormat:@"maxValue%d",i]];
    }
}

#pragma mark •••Bit Processing Protocol
- (void) processIsStarting { }
- (void) processIsStopping { }
- (void) startProcessCycle { }
- (void) endProcessCycle   { }
- (void) setProcessOutput:(int)aChan value:(int)aValue {}

- (NSString*) identifier
{
	NSString* s;
 	@synchronized(self){
		s= [NSString stringWithFormat:@"pCMeter,%lu",[self uniqueIdNumber]];
	}
	return s;
}

- (NSString*) processingTitle
{
	NSString* s;
 	@synchronized(self){
		s= [self identifier];
	}
	return s;
}


- (double) convertedValue:(int)aChan
{
	double theValue = 0;
	@synchronized(self){
		if(aChan<kNplpCNumChannels)theValue =  meterAverage[aChan];
    }
	return theValue;
}

- (BOOL) processValue:(int)channel
{
    return TRUE;
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
		if(channel<kNplpCNumChannels){
			*theLowLimit = lowLimit[channel];
			*theHighLimit =  hiLimit[channel];
		}
		else {
			*theLowLimit = 0;
			*theHighLimit = 5;
		}
	}
}


@end
