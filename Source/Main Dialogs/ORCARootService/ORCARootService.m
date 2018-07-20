//
//  ORCARootService.m
//  Orca
//
//  Created by Mark Howe on Thu Nov 06 2003.
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


#import "ORCARootService.h"
#import "NetSocket.h"
#import "ORDataPacket.h"
#import "ORDataTypeAssigner.h"
#import "ORCARootServiceDefs.h"
#import "SynthesizeSingleton.h"

NSString* ORCARootServicePortChanged			= @"ORCARootServicePortChanged";
NSString* ORCARootServiceTimeConnectedChanged	= @"ORCARootServiceTimeConnectedChanged";
NSString* ORCARootServiceHostNameChanged		= @"ORCARootServiceHostNameChanged";
NSString* ORCARootServiceConnectAtStartChanged	= @"ORCARootServiceConnectAtStartChanged";
NSString* ORCARootServiceAutoReconnectChanged	= @"ORCARootServiceAutoReconnectChanged";
NSString* ORORCARootServiceLock					= @"ORORCARootServiceLock";


@implementation ORCARootService

SYNTHESIZE_SINGLETON_FOR_CLASS(ORCARootService);

- (id) init
{
    self = [super init];
    requestTag = 0;
    [[self undoManager] disableUndoRegistration];
    NSInteger port = [[NSUserDefaults standardUserDefaults] integerForKey: @"orca.rootservice.ServiceHostPort"];
    if(port==0)port = kORCARootServicePort;
	[self setAutoReconnect:[[NSUserDefaults standardUserDefaults] integerForKey: @"orca.rootservice.AutoReconnect"]];
	[self setConnectAtStart:[[NSUserDefaults standardUserDefaults] integerForKey: @"orca.rootservice.ConnectAtStartUp"]];
	
	NSString* s = [[NSUserDefaults standardUserDefaults] objectForKey: @"orca.rootservice.ServiceHostName"];
	hostNameIndex = [[NSUserDefaults standardUserDefaults] integerForKey: @"orca.rootservice.HostNameIndex"];
	NSArray* theHistory = [[NSUserDefaults standardUserDefaults] arrayForKey: @"orca.rootservice.ServiceHistory"];

	if(!theHistory)connectionHistory = [[NSMutableArray alloc] init];
    else {
        connectionHistory = [[NSMutableArray alloc] initWithArray:theHistory];
    }
	if(s){
		if(![connectionHistory containsObject:s])[connectionHistory addObject:s];
	}
	if(![connectionHistory containsObject:kORCARootServiceHost])[connectionHistory addObject:kORCARootServiceHost];
	if(hostNameIndex<[connectionHistory count]){
		[self setHostName:[connectionHistory objectAtIndex:	hostNameIndex]];
	}
    [self setSocketPort:(int)port];
    [[self undoManager] enableUndoRegistration];
    	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestNotification:) name:ORCARootServiceRequestNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelRequest:) name:ORCARootServiceCancelRequest object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(broadcastConnectionStatus) name:ORCARootServiceBroadcastConnection object:nil];

	RemoveORCARootWarnings; //a #define from ORCARootServiceDefs.h 
		
    return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[waitingObjects release];
	[socket setDelegate:nil];
    [socket release];
    [timeConnected release];
    [name release];
	[hostName release];
	[dataBuffer release];
	[connectionHistory release];
    [super dealloc];
}

- (void) connectAtStartUp
{
    if(connectAtStart){
        [self connectSocket:YES];
    }
}
#pragma mark ¥¥¥Accessors
- (NSUndoManager *)undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}


- (void) connectSocket:(BOOL)state
{
    if(state){
        [self setSocket:[NetSocket netsocketConnectedToHost:hostName port:socketPort]];
    }
    else {
        [socket close];
        [self setIsConnected:[socket isConnected]];
    }
}

- (NSString*) hostName
{
	return hostName;
}

- (void) setHostName:(NSString*)aName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setHostName:hostName];
    [hostName autorelease];
    hostName = [aName copy];    	

	if(!connectionHistory)connectionHistory = [[NSMutableArray alloc] init];
	if(![connectionHistory containsObject:hostName] && [hostName length]!=0){
		[connectionHistory addObject:hostName];
	}
	if(aName)hostNameIndex = [connectionHistory indexOfObject:aName];
	else hostNameIndex = 0;

    [[NSUserDefaults standardUserDefaults] setObject:connectionHistory forKey:@"orca.rootservice.ServiceHistory"];
    [[NSUserDefaults standardUserDefaults] setInteger:hostNameIndex forKey:@"orca.rootservice.HostNameIndex"];
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCARootServiceHostNameChanged object:self userInfo:nil];

}

- (NSUInteger) hostNameIndex
{
	return hostNameIndex;
}

- (NetSocket*) socket
{
	return socket;
}
- (void) setSocket:(NetSocket*)aSocket
{
	[aSocket retain];
	[socket release];
	socket = aSocket;
    [socket setDelegate:self];
}

- (BOOL) isConnected
{
	return isConnected;
}

- (void) setIsConnected:(BOOL)aNewIsConnected
{
	isConnected = aNewIsConnected;
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:isConnected] forKey:ORCARootServiceConnectedKey];
	[[NSNotificationCenter defaultCenter] 
			postNotificationName:ORCARootServiceConnectionChanged 
                          object: self 
						  userInfo:userInfo];

	[self setTimeConnected:isConnected?[NSDate date]:nil];
}

- (void) clearHistory
{
	[connectionHistory release];
	connectionHistory = nil;

	[self setHostName:hostName];
	
}

- (void) broadcastConnectionStatus
{
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:isConnected] forKey:ORCARootServiceConnectedKey];
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORCARootServiceConnectionChanged
                      object:self 
					userInfo:userInfo];
}

- (NSArray*) connectionHistory
{
	return connectionHistory;
}

- (NSUInteger) connectionHistoryCount
{
	return [connectionHistory count];
}

- (id) connectionHistoryItem:(NSUInteger)index
{
	if(index<[connectionHistory count])return [connectionHistory objectAtIndex:index];
	else return nil;
}


- (int) socketPort
{
    return socketPort;
}
- (void) setSocketPort:(int)aPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSocketPort:socketPort];
    
    socketPort = aPort;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORCARootServicePortChanged object:self];
    [[NSUserDefaults standardUserDefaults] setInteger:socketPort forKey:@"orca.rootservice.ServiceHostPort"];
}

- (NSString*) name
{
	return name;
}

- (void) setName:(NSString*)newName
{
	[name autorelease];
	name=[newName copy];
}

- (uint64_t)totalSent
{
    return totalSent;
}

- (void)setTotalSent:(uint64_t)aTotalSent
{
    totalSent = (uint32_t)aTotalSent;
}

- (NSDate*) timeConnected
{
	return timeConnected;
}

- (void) setTimeConnected:(NSDate*)newTimeConnected
{
	[timeConnected autorelease];
	timeConnected=[newTimeConnected retain];	
	[[NSNotificationCenter defaultCenter] postNotificationName:ORCARootServiceTimeConnectedChanged object:self];
}

- (uint32_t)amountInBuffer 
{
    return amountInBuffer;
}

- (void)setAmountInBuffer:(uint32_t)anAmountInBuffer 
{
    amountInBuffer = anAmountInBuffer;
}

- (void)writeData:(NSData*)inData
{
    [socket writeData:inData];
}

- (uint32_t) dataId
{
    return dataId;
}
- (void) setDataId: (uint32_t) aDataId
{
    dataId = aDataId;
}
- (void) setDataIds:(id)assigner
{
    dataId = [assigner reservedDataId:[self className]];
}

- (void) syncDataIdsWith:(id)anotherObj
{
    [self setDataId:[anotherObj dataId]];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORCARootServiceDecoder",			@"decoder",
        [NSNumber numberWithLong:dataId],   @"dataId",
        [NSNumber numberWithBool:YES],      @"variable",
        [NSNumber numberWithLong:-1],		@"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"ResponsePacket"];
    return dataDictionary;
}

#pragma mark ¥¥¥Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
		NSLog( @"ORCARoot Service: Connection established\n" );		
		[self setName:[socket remoteHost]];
		
		
		ORDataTypeAssigner* assigner = [[ORDataTypeAssigner alloc] init];
		dataId = [assigner reservedDataId:[self className]];
		[assigner release];
   
		ORDataPacket* aDataPacket = [[ORDataPacket alloc] init];
		[aDataPacket makeFileHeader];
		[aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORCARootService"];
		
		id aFileHeader = [aDataPacket fileHeader];
		if(aFileHeader){
			NSData* dataHeader = [ORDecoder  convertHeaderToData:aFileHeader];
			if(dataHeader)[socket writeData:dataHeader];
		}
		[aDataPacket release];
		
        [self setIsConnected:[socket isConnected]];
	}
}

- (void)netsocketDisconnected:(NetSocket*)inNetSocket
{	
    if(inNetSocket == socket){
		NSLog(@"ORCARoot Service: %@ disconnected\n",[inNetSocket remoteHost]);
        [self setIsConnected:[socket isConnected]];
		[self setName:@"---"];
        if(autoReconnect)[self performSelector:@selector(reConnect) withObject:nil afterDelay:10];
        [self setIsConnected:NO];
    }

}

- (BOOL) autoReconnect
{
	return autoReconnect;
}

- (void) setAutoReconnect:(BOOL)aAutoReconnect
{
	[[[self undoManager] prepareWithInvocationTarget:self] setAutoReconnect:autoReconnect];
    
	autoReconnect = aAutoReconnect;
    
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORCARootServiceAutoReconnectChanged
                      object:self];
    [[NSUserDefaults standardUserDefaults] setInteger:autoReconnect forKey:@"orca.rootservice.AutoReconnect"];
}

- (BOOL) connectAtStart
{
	return connectAtStart;
}

- (void) setConnectAtStart:(BOOL)aConnectAtStart
{
	[[[self undoManager] prepareWithInvocationTarget:self] setConnectAtStart:connectAtStart];
    
	connectAtStart = aConnectAtStart;
    
	[[NSNotificationCenter defaultCenter]
		postNotificationName:ORCARootServiceConnectAtStartChanged
                      object:self];
    [[NSUserDefaults standardUserDefaults] setInteger:connectAtStart forKey:@"orca.rootservice.ConnectAtStartUp"];
}


- (void) reConnect
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(reConnect) object:nil];
    [self connectSocket:YES];
}

- (void) netsocketDataInOutgoingBuffer:(NetSocket*)insocket length:(uint32_t)length
{
	if(insocket == socket){
		[self setAmountInBuffer:length];
	}
}

- (void) clearCounts
{
    [self setTotalSent:0];
    [self setAmountInBuffer:0];
}

- (void)netsocketDataSent:(NetSocket*)insocket length:(uint32_t)length
{
	if(insocket == socket){
		[self setTotalSent:[self totalSent]+length];
	}
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
	if(inNetSocket == socket){
		if(dataId==0){
			ORDataTypeAssigner* assigner = [[ORDataTypeAssigner alloc] init];
			dataId = [assigner reservedDataId:[self className]];
			[assigner release];
		}

		if(!dataBuffer)dataBuffer = [[NSMutableData alloc] initWithCapacity:5*1025];
		NSData* data = [inNetSocket readData:inAmount];
		[dataBuffer appendBytes:[data bytes] length:[data length]];
		uint32_t* ptr = (uint32_t*)[dataBuffer bytes];
		uint32_t length = ExtractLength(*ptr);
		uint32_t theID   = ExtractDataId(*ptr);
		if([dataBuffer length]/4 >= length && theID == dataId){
			ptr++;			
			NSString* plist = [[[NSString alloc] initWithBytes:(const char *)ptr length:(length-1)*4 encoding:NSASCIIStringEncoding] autorelease];
			NSDictionary* theResponse = [NSDictionary dictionaryWithPList:plist];
						
			uint32_t oldLength = (uint32_t)[dataBuffer length];
			[dataBuffer replaceBytesInRange:NSMakeRange(0,length*4) withBytes:dataBuffer];
			[dataBuffer setLength:oldLength - length*4];
			
			id aKey = [theResponse objectForKey:@"Request Tag Number"];
			id theRequestingObj = [waitingObjects objectForKey:aKey];
			if([theRequestingObj respondsToSelector:@selector(processResponse:)]){
				[theRequestingObj processResponse:theResponse];
			}
			[waitingObjects removeObjectForKey:aKey];
		}
		fitInFlight = NO;
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(clearFitInFlight) object:nil];

	}
}

- (void) cancelRequest:(NSNotification*)aNote
{
	id requestingObj = [aNote object];
	NSArray* allKeys = [waitingObjects allKeys];
	for(id aKey in allKeys){
		id anObj = [waitingObjects objectForKey:aKey];
		if(anObj == requestingObj){
			[waitingObjects removeObjectForKey:aKey]; 
		}
	}
}

- (void) requestNotification:(NSNotification*)aNote
{
	[self sendRequest:[[aNote userInfo] objectForKey:ServiceRequestKey] fromObject:[aNote object]];
}

- (void) clearFitInFlight
{
	fitInFlight = NO;
}

- (void) sendRequest:(NSMutableDictionary*)request fromObject:(id)anObject
{
	if(!socket)return;
	if(fitInFlight)return;
	
	fitInFlight = YES;
	
	[self performSelector:@selector(clearFitInFlight) withObject:nil afterDelay:5];
	
	if(dataId==0){
		ORDataTypeAssigner* assigner = [[ORDataTypeAssigner alloc] init];
		dataId = [assigner reservedDataId:[self className]];
 		[assigner release];
	}
	
	if(!waitingObjects)waitingObjects = [[NSMutableDictionary dictionary] retain];
	requestTag++;
	[request setObject:[NSNumber numberWithInt:requestTag] forKey:@"Request Tag Number"];
	[waitingObjects setObject:anObject forKey:[NSNumber numberWithInt:requestTag]];
	
	NSData* dataBlock = [request asData];
	
	//the request is now in dataBlock
	uint32_t headerLength        = (uint32_t)[dataBlock length];												  //in bytes
	uint32_t lengthWhenPadded    = sizeof(int32_t)*(round(.5 + headerLength/(float)sizeof(int32_t)));	  //length in bytes to int32_t boundary
	uint32_t padSize             = lengthWhenPadded - headerLength;								  //in bytes
	uint32_t totalLength		  = 1 + (lengthWhenPadded/sizeof(int32_t));							  //in longs
	uint32_t theHeaderWord		  = dataId | (0x3ffff & totalLength);								  //compose the header word
	NSMutableData* dataToSend		  = [NSMutableData dataWithBytes:&theHeaderWord length:sizeof(int32_t)]; //add the header word
	
	[dataToSend appendData:dataBlock];
	
	//pad to nearest int32_t word
	unsigned char padByte = 0;
	int i;
	for(i=0;i<padSize;i++){
		[dataToSend appendBytes:&padByte length:1];
	}
	
	if([dataToSend length] * sizeof(int32_t) > 0x3ffff){
		[dataToSend setLength: 0x3ffff/sizeof(int32_t)];
	}
	
	[socket writeData:dataToSend];
}

@end
