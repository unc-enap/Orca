//
//  XL3_Link.m
//  ORCA
//
//  Created by Jarek Kaspar on Sat, Jul 9, 2010.
//  Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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
#import "PacketTypes.h"
#import "XL3_Link.h"
#import "ORSafeCircularBuffer.h"

#import <netdb.h>
#import <sys/types.h>
#import <sys/socket.h>
#import <sys/select.h>
#import <sys/errno.h>
#include "anet.h"
#import "SNOPModel.h"

NSString* XL3_LinkConnectionChanged     = @"XL3_LinkConnectionChanged";
NSString* XL3_LinkTimeConnectedChanged	= @"XL3_LinkTimeConnectedChanged";
NSString* XL3_LinkIPNumberChanged       = @"XL3_LinkIPNumberChanged";
NSString* XL3_LinkConnectStateChanged	= @"XL3_LinkConnectStateChanged";
NSString* XL3_LinkErrorTimeOutChanged	= @"XL3_LinkErrorTimeOutChanged";
NSString* XL3_LinkAutoConnectChanged    = @"XL3_LinkAutoConnectChanged";


#define kCmdArrayHighWater 1000


@implementation XL3_Link

@synthesize pendingThreads;

- (id) init
{
	self = [super init];
    if (self == nil) return nil;
    
	commandSocketLock = [[NSLock alloc] init];
	coreSocketLock = [[NSLock alloc] init];
	cmdArrayLock = [[NSLock alloc] init];
    connectionLock = [[NSLock alloc] init];
    pendingThreads = 0;
	[self setNeedToSwap];
	connectState = kDisconnected;
	cmdArray = [[NSMutableArray alloc] init];
	numPackets = 0;
	return self;
}

- (void) dealloc
{
	[commandSocketLock release];
	[coreSocketLock release];
	[cmdArrayLock release];
    [connectionLock release];
	if(cmdArray){
		[cmdArray release];
		cmdArray = nil;
	}
	
	[super dealloc];
}

- (void) wakeUp 
{
	
}

- (void) sleep 	
{
	
}

- (void) awakeAfterDocumentLoaded
{
    if (autoConnect) [self connectSocket];
}

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
    if (self == nil) return nil;
    
	[[self undoManager] disableUndoRegistration];

	[self setErrorTimeOut: [decoder decodeIntForKey: @"errorTimeOut"]];
    [self setAutoConnect: [decoder decodeBoolForKey: @"autoConnect"]];
	[self setNeedToSwap];

	commandSocketLock = [[NSLock alloc] init];
	coreSocketLock = [[NSLock alloc] init];
	cmdArrayLock = [[NSLock alloc] init];
	cmdArray = [[NSMutableArray alloc] init];
	
	connectState = kDisconnected;
    pendingThreads = 0;
	numPackets = 0;

	[[self undoManager] enableUndoRegistration];
	return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeInteger:[self errorTimeOut] forKey:@"errorTimeOut"];
    [encoder encodeBool:autoConnect forKey:@"autoConnect"];
}


#pragma mark •••Accessors

- (BOOL) needToSwap
{
	return needToSwap;
}

- (void) setNeedToSwap
{
	//VME bus & ML403 are big-endian, ethernet as well
	if (0x0000ABCD == htonl(0x0000ABCD)) needToSwap = NO;
	else needToSwap = YES;
}

#define swapLong(x) (((uint32_t)(x) << 24) | (((uint32_t)(x) & 0x0000FF00) <<  8) | (((uint32_t)(x) & 0x00FF0000) >>  8) | ((uint32_t)(x) >> 24))
#define swapShort(x) (((uint16_t)(x) <<  8) | ((uint16_t)(x)>>  8))

- (int)  connectState;
{
	return connectState;
}

- (BOOL) isConnected
{
	return isConnected;
}

- (void) setIsConnected:(BOOL)aNewIsConnected
{
    @synchronized(self) {
        isConnected = aNewIsConnected;

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectionChanged object: self];
        });

        [self setTimeConnected:isConnected?[NSDate date]:nil];
    }
}

- (BOOL) autoConnect
{
	return autoConnect;
}

- (void) setAutoConnect:(BOOL)anAutoConnect
{
	autoConnect = anAutoConnect;
	[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkAutoConnectChanged object: self];
}

- (void) setErrorTimeOut:(int)aValue
{
	[[[self undoManager] prepareWithInvocationTarget:self] setErrorTimeOut:[self errorTimeOut]];
	_errorTimeOut = aValue;
	[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkErrorTimeOutChanged object:self];
}

- (int) errorTimeOut
{
	return _errorTimeOut;
}

- (int) errorTimeOutSeconds
{
	static int translatedTimeOut[4] = {2,5,60,0};
	if([self errorTimeOut] < 0 || [self errorTimeOut] > 3) return 2;
	else return translatedTimeOut[[self errorTimeOut]];
}

/**
 * Connects if disconnected / disconnectes if connected or waiting.
 */
- (void) toggleConnect
{
	int oldState = connectState;
	switch(connectState){
		case kDisconnected:
			@try {
				[self connectSocket]; //will throw if can't connect
				connectState = kWaiting;
			}
			@catch (NSException* localException) {
				connectState = kDisconnected;
			}
			break;

		case kWaiting:
			@try {
				[self disconnectSocket]; //will throw if can't connect
				connectState = kDisconnected;
			}
			@catch (NSException* localException) {
				connectState = kDisconnected;
			}
			break;

		case kConnected:
			@try {
				[self disconnectSocket]; //will throw if can't connect
				connectState = kDisconnected;
			}
			@catch (NSException* localException) {
				connectState = kDisconnected;
			}
			break;
	}

	if (oldState != connectState) {
		[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object:self];
	}
}

- (NSDate*) timeConnected
{
	return timeConnected;
}

- (void) setTimeConnected:(NSDate*)newTimeConnected
{
	[timeConnected autorelease];
	timeConnected=[newTimeConnected retain];	
	[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkTimeConnectedChanged object:self];
}

- (NSString*) IPNumber
{
	if(!IPNumber)return @"";
	return IPNumber;
}

- (void) setIPNumber:(NSString*)aIPNumber
{
	if([aIPNumber length]){
		[[[self undoManager] prepareWithInvocationTarget:self] setIPNumber:IPNumber];
		
		[IPNumber autorelease];
		IPNumber = [aIPNumber copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkIPNumberChanged object:self];
	}
}

- (uint32_t)  portNumber
{
	return portNumber;
}

- (void) setPortNumber:(uint32_t)aPortNumber;
{
	portNumber = aPortNumber;
}

- (NSString*) crateName
{
	if(!crateName) return @"";
	return crateName;
}

- (void) setCrateName:(NSString*)aCrateName
{
	if([aCrateName length]){
		[[[self undoManager] prepareWithInvocationTarget:self] setCrateName:crateName];
		
		[crateName autorelease];
		crateName = [aCrateName copy];    	
	}
}	

/**
 * Prepares a new MultiCmd to be built with addMultiCmdToAddress.
 * WARNING: will clear any previously prepared MultiCmd ***not thread safe***
 */
- (void) newMultiCmd
{
	aMultiCmdPacket.header.packetType = MULTI_FAST_CMD_ID;
	aMultiCmdPacket.header.numBundles = 0;
	memset(aMultiCmdPacket.payload, 0, XL3_PAYLOAD_SIZE);
}

/**
 * Appends a new register write to the pending MultiCmd
 * WARNING: does not check that the MultiCmd is full
 */
- (void) addMultiCmdToAddress:(int32_t)anAddress withValue:(int32_t)aValue
{
	MultiCommand* theMultiCommand = (MultiCommand*) aMultiCmdPacket.payload;
	Command* aCommand = &(theMultiCommand->cmd[theMultiCommand->howMany]);

	aCommand->cmdNum = theMultiCommand->howMany;
	aCommand->packetNum = 0; //redundant
	aCommand->flags = 0;
	aCommand->address = (uint32_t)anAddress;
	aCommand->data = (uint32_t)aValue;
	
	theMultiCommand->howMany++;
}

/**
 * Sends the pending MultiCmd and returns the response. Does not raise exception
 * on failure. Check multiCmdFailed for success or inspect the result packet.
 */
- (XL3Packet*) executeMultiCmd
{
	MultiCommand* theMultiCommand = (MultiCommand*) aMultiCmdPacket.payload;
    for (uint32_t i = 0; i < theMultiCommand->howMany; i++) {
		Command* command = &(theMultiCommand->cmd[i]);
		command->cmdNum = htonl(command->cmdNum);
		command->packetNum = htons(command->packetNum);
		command->address = htonl(command->address);
		command->data = htonl(command->data);
	}
	theMultiCommand->howMany = htonl(theMultiCommand->howMany);

	@try {
		[self sendXL3Packet:&aMultiCmdPacket];
	}
	@catch (NSException* localException) {
		NSLogColor([NSColor redColor],@"%@ MultiCmd failed.\n", [self crateName]);
	}
	
	theMultiCommand->howMany = ntohl(theMultiCommand->howMany);
	for (uint32_t i = 0; i < theMultiCommand->howMany; i++) {
		Command* command = &(theMultiCommand->cmd[i]);
		command->cmdNum = ntohl(command->cmdNum);
		command->packetNum = ntohs(command->packetNum);
		command->address = ntohl(command->address);
		command->data = ntohl(command->data);
	}
	
	return &aMultiCmdPacket;
}

/**
 * Returns true if the last MultiCmd was a success, false otherwise. Result is
 * undefined if executeMultiCmd was not the last called out of [newMultiCmd,
 * addMultiCmdToAddress, or executeMultiCmd] 
 */
- (BOOL) multiCmdFailed
{
	BOOL error = NO;
	MultiCommand* theMultiCommand = (MultiCommand*) aMultiCmdPacket.payload;

	unsigned int i = 0;
	for (i = 0; i < theMultiCommand->howMany; i++) {
		Command* command = &theMultiCommand->cmd[i];
		error |= command->flags;
	}
			
	return error;
}

/**
 * Sends a raw xl3Packet and stores the response in xl3Packet. Throws 
 * exceptions if there are issues. 
 */
- (void) sendXL3Packet:(XL3Packet*)xl3Packet
{
	//expects the packet is swapped correctly (both header and payload)
	unsigned char packetType = xl3Packet->header.packetType;
	
	[commandSocketLock lock];
	@try {
		[self writePacket:xl3Packet];
		unsigned short packetNum = ntohs(xl3Packet->header.packetNum);
		[self readXL3Packet:xl3Packet withPacketType:packetType andPacketNum:packetNum];
	}
	@catch (NSException* localException) {
		@throw localException;
	}
	@finally {
	    [commandSocketLock unlock];
	}
}

/**
 * Sends a command packet with the specified payload. Must specify if the command
 * replies whether you want it or not, otherwise we will leak memory. The reply 
 * payload is stored in payload. Throws exceptions on failure.
 */
- (void) sendCommand:(uint8_t) aCmd withPayload:(char *) payload expectResponse:(BOOL) askForResponse
{
    //client is responsible for payload swapping, we take care of the header
    XL3Packet xl3Packet;
    
    unsigned short packetNum;
    xl3Packet.header.packetType = aCmd;
    xl3Packet.header.numBundles = 0;
    memcpy(xl3Packet.payload, payload, XL3_PAYLOAD_SIZE);
    
    [commandSocketLock lock]; 
    @try {
        [self writePacket:&xl3Packet];
        packetNum = ntohs(xl3Packet.header.packetNum);
    } @catch (NSException* localException) {
        @throw localException;
    }
    @finally {
        [commandSocketLock unlock];
    }
    if(askForResponse){
        @try {
            [self readXL3Packet:&xl3Packet withPacketType:aCmd andPacketNum:packetNum];
            memcpy(payload, xl3Packet.payload, XL3_PAYLOAD_SIZE);
        } @catch (NSException* localException) {
            @throw localException;
        }
    } else {
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.005]];
    }
}

/**
 * Sends a command packet with no payload. Must specify if the command
 * replies whether you want it or not, otherwise we will leak memory. Throws
 * exceptions on failure. 
 */
- (void) sendCommand:(uint8_t)aCmd expectResponse:(BOOL) askForResponse
{
	char payload[XL3_PAYLOAD_SIZE];
	 @try {
		[self sendCommand:aCmd withPayload:payload expectResponse:askForResponse];
	} @catch (NSException* localException) {
		@throw localException;
		//what about the response?		
	}
}

/**
 * Sends a fast command to address. The specified data is sent in the packet 
 * and the result is coppied into the same variable. Throws exceptions on failure.
 *
 * Note: aCmd is unused - all are sent as FAST_CMD_ID
 */
- (void) sendCommand:(uint8_t) aCmd toAddress:(uint32_t) address withData:(uint32_t *) value
{
	char payload[XL3_PAYLOAD_SIZE];
	Command* command = (Command*) payload;
		
	command->cmdNum = 0;
	command->packetNum = 0; //redundant
	command->flags = 0;
	command->address = (uint32_t) address;
	command->data = *(uint32_t*) value;

	command->cmdNum = htonl(command->cmdNum);
	command->packetNum = htons(command->packetNum);
	command->address = htonl(command->address);
	command->data = htonl(command->data);

	@try { 
		[self sendCommand:FAST_CMD_ID withPayload:payload expectResponse:YES];
	}
	@catch (NSException* e) {
		NSLog(@"%@ Command error sending command\n", [self crateName]);
		@throw e;
	}
	//return the same packet!
	if (command->flags != 0) {
		@throw [NSException exceptionWithName:@"Command error.\n" reason:@"XL3 bus error\n" userInfo:nil];
	}	

	*value = ntohl(command->data);	
}

/**
 * Blocks until connectToPort reads and inserts a packet with the specified 
 * packetType and packetNum into cmdArray. The result is stored in aPacket which
 * is assumed to be XL3_PACKET_SIZE bytes.
 *
 * Will terminate with an exception if the XL3 disconnects, we hit the timeout,
 * or anything else unsavory happens.
 */
- (void) readXL3Packet:(XL3Packet*) aPacket withPacketType:(uint8_t) packetType andPacketNum: (uint16_t) packetNum
{
    // lock connection and if connected increment the pending count, otherwise throw exception
    [connectionLock lock];
    if ([self isConnected]) {
        [self setPendingThreads:pendingThreads+1];
        [connectionLock unlock];
    } else {
        [connectionLock unlock];
        @throw [NSException exceptionWithName:@"ReadXL3Packet not connected"
            reason:[NSString stringWithFormat:@"Not connected for %@ <%@> port: %u\n", [self crateName], IPNumber, portNumber]
            userInfo:nil];
    }
    
    //look into the cmdArray
    NSDate* sleepDate = [[NSDate alloc] initWithTimeIntervalSinceNow:0.01];
	[NSThread sleepUntilDate:sleepDate];
    [sleepDate release];
    sleepDate = nil;
    
	NSDictionary* aCmd;
	NSMutableArray* foundCmds = [[NSMutableArray alloc] initWithCapacity:1];
	time_t xl3ReadTimer = time(0);
    NSNumber* aPacketType;
    NSNumber* aPacketNum;

    // loop until disconnect, packet found (breaks out), timeout (exception thrown)
	while ([self isConnected]) {
		[cmdArrayLock lock];
		@try {
			for (aCmd in cmdArray) {
				aPacketType = [aCmd objectForKey:@"packetType"];
				aPacketNum = [aCmd objectForKey:@"packetNum"];

				if ([aPacketType unsignedCharValue] == packetType && [aPacketNum unsignedShortValue] == packetNum) {
					[foundCmds addObject:aCmd];
				}
			}
		}
        @catch (NSException* e) {
            [connectionLock lock];
            [self setPendingThreads:pendingThreads-1];
            [connectionLock unlock];
            [foundCmds release];
            foundCmds = nil;
			[cmdArrayLock unlock];
			NSLogColor([NSColor redColor],@"Error in readXL3Packet parsing cmdArray: %@ %@\n", [e name], [e reason]);
			@throw e;
		}
		@finally {
			[cmdArrayLock unlock];
		}

		if ([foundCmds count]) {
			break;
		} else if ([self errorTimeOutSeconds] && time(0) - xl3ReadTimer > [self errorTimeOutSeconds]) {
            [connectionLock lock];
            [self setPendingThreads:pendingThreads-1];
            [connectionLock unlock];
            [foundCmds release];
            foundCmds = nil;
            [self performSelectorOnMainThread:@selector(disconnectSocket) withObject:nil waitUntilDone:NO];
			@throw [NSException exceptionWithName:@"ReadXL3Packet time out"
				reason:[NSString stringWithFormat:@"Time out for %@ <%@> port: %u\n", [self crateName], IPNumber, portNumber]
				userInfo:nil];
		} else {
            usleep(500);
        }
	}

    if ([foundCmds count] == 0) {
        [connectionLock lock];
        [self setPendingThreads:pendingThreads-1];
        [connectionLock unlock];
        [foundCmds release];
        foundCmds = nil;
        @throw [NSException exceptionWithName:@"ReadXL3Packet XL3 disconnected"
            reason:[NSString stringWithFormat:@"XL3 disconnected for %@ <%@> port: %u\n", [self crateName], IPNumber, portNumber]
            userInfo:nil];
    } else if ([foundCmds count] > 1) {
		NSLogColor([NSColor redColor],@"Multiple responses for XL3 command with packet type: %d and packet num: %d from %@ <%@> port: %d\n",
		      [self crateName], IPNumber, portNumber, packetType, packetNum);
	}
	
	aCmd = [foundCmds objectAtIndex:0];
	[[aCmd objectForKey:@"xl3Packet"] getBytes:aPacket length:XL3_PACKET_SIZE];
	
	[cmdArrayLock lock];
	@try {
		[cmdArray removeObjectsInArray:foundCmds];
	}
	@catch (NSException* localException) {
		NSLogColor([NSColor redColor],@"XL3_Link error removing an XL3 packet from the command array\n");
		NSLogColor([NSColor redColor],@"%@ %@\n", [localException name], [localException reason]);
		@throw localException;
	}
    @finally {
        [cmdArrayLock unlock];
        [connectionLock lock];
        [self setPendingThreads:pendingThreads-1];
        [connectionLock unlock];
        [foundCmds release];
        foundCmds = nil;
    }
} 

/**
 * Spawns a thread to connect to the XL3 server invoking the connectToPort method
 */
- (void) connectSocket
{
	if(([IPNumber length]!=0) && (portNumber!=0)){
		@try {
			[NSThread detachNewThreadSelector:@selector(connectToPort) toTarget:self withObject:nil];
		}
		@catch (NSException* localException) {
			NSLog(@"Socket creation failed for %@ on port %d\n", [self crateName], portNumber);
			[self setIsConnected: NO];
			[self setTimeConnected:nil];
			
			@throw localException;
		}
	}
	else {
        NSLog(@"connectSocket: XL3_Link failed to call connect for IP %@ and port %d\n", IPNumber, portNumber);
	}
}

/**
 * Called to either clean up the connection or to trigger the connection to be terminated
 */
- (void) disconnectSocket
{
    if (workingSocket){
		close(workingSocket);
		workingSocket = 0;
	}
		
	[self setIsConnected: NO];
	[self setTimeConnected:nil];
    
	NSLog(@"Disconnected %@ <%@> port: %d\n", [self crateName], IPNumber, portNumber);
}

/**
 * Swaps byte order of n longs at pointer p
 */
static void SwapLongBlock(void* p, int32_t n)
{
    int32_t* lp = (int32_t*)p;
    int32_t i;
    for(i=0;i<n;i++){
        int32_t x = *lp;
        *lp =  (((x) & 0x000000FF) << 24) |    
        (((x) & 0x0000FF00) <<  8) |    
        (((x) & 0x00FF0000) >>  8) |    
        (((x) & 0xFF000000) >> 24);
        lp++;
    }
}

/**
 * Runs as a unique thread for each XL3 with the lifetime of the XL3 connection.
 * Started with connectSocket.
 *
 * Pulls connection information for the XL3 server from the SNOP model and 
 * attempts a connection after all threads waiting on responses from the 
 * previous connection finish. Updates the connectionState sending 
 * XL3_LinkConnectStateChanged notifications at each stage.
 *
 * XL3 packets are parsed here. All but a few in the switch statement are 
 * replies to queries stored in the cmdArray and can be obtained with the 
 * selector readXL3Packet. PING packets are automatically PONG'd here.
 *
 */
- (void) connectToPort
{
    char err[ANET_ERR_LEN];
    char *host;
    
    if (isConnected) {
        NSLogColor([NSColor redColor],@"%@ already connected, aborting reconnect.\n",[self crateName]);
        return;
    }

    NSArray* objs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"SNOPModel")];

    SNOPModel* sno;
    if ([objs count] == 0) {
        NSLogColor([NSColor redColor],
            @"xl3: Couldn't find SNO+ model to get XL3 server "
             "hostname and port from. Please add a SNO+ model object to the "
             "experiment.\n");
        return;
    }

    sno = [objs objectAtIndex:0];
    host = (char *) [[sno xl3Host] UTF8String];

	NSAutoreleasePool *pool = [[NSAutoreleasePool allocWithZone:nil] init];

    connectState = kWaiting;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];

    //wait for all pending threads on a previous connection to finish
    [connectionLock lock];
    while (pendingThreads > 0) {
        [connectionLock unlock];
        usleep(100000);
        [connectionLock lock];
    }
    [connectionLock unlock];
    
    workingSocket = 0;
    if ((workingSocket = (int)anetTcpConnect(err, host, (int)portNumber)) == ANET_ERR) {
        if (workingSocket) {
            close(workingSocket);
            workingSocket = 0;
        }

        connectState = kDisconnected;
        [[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];

        [self setIsConnected:NO];

        [NSThread sleepForTimeInterval:10.0];
    } else {
        [self setIsConnected:YES];
    }
	
    if ([self isConnected]) {
        connectState = kConnected;
        [[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];
        NSLog(@"%@ connected on local port %d\n",[self crateName], [self portNumber]);
    }

	fd_set fds;
	int selectionResult = 0;
	struct timeval tv;
	tv.tv_sec  = 0;
	tv.tv_usec = 2000;

	XL3Packet xl3Packet;	

	time_t t0 = time(0);
    BOOL go = [self isConnected];
    
	while(go) { //yes, this is correct
		if (!workingSocket) {
			NSLog(@"%@ not connected <%@> port: %d\n", [self crateName], IPNumber, portNumber);
			break;
		}
				
		FD_ZERO(&fds);
		FD_SET(workingSocket, &fds);
		selectionResult = select(workingSocket + 1, &fds, NULL, NULL, &tv);
		if (selectionResult == -1 && !(errno == EAGAIN || errno == EINTR)) {
            usleep(500);
            
			if (workingSocket) {
				NSLog(@"Error reading XL3 <%@> port: %d\n", IPNumber, portNumber);
			}
			break;
		}

		if (selectionResult > 0 && FD_ISSET(workingSocket, &fds)) {
			@try {
				[self readPacket:&xl3Packet];
            }
			@catch (NSException* localException) {
				if (workingSocket) {
					NSLog(@"Couldn't read from XL3 <%@> port:%d\n", IPNumber, portNumber);
				}
				break;
			}
			
            //reset the timer
            t0 = time(0);
            
            switch (xl3Packet.header.packetType) {
                case MEGA_BUNDLE_ID: 
                    NSLogColor([NSColor redColor],@"ORCA received a MEGABUNDLE from %@ - this should not happen!\n", [self crateName]);
                    break;
                
                case PING_ID:
                    NSLogColor([NSColor redColor],@"ORCA received a PING from %@ - this should not happen!\n", [self crateName]);
                    break;
                
                case MESSAGE_ID: {
                    xl3Packet.payload[XL3_PAYLOAD_SIZE-1] = '\0';
                    NSString* msg = [NSString stringWithFormat:@"%s", xl3Packet.payload]; //odd encoding
                    msg = [msg stringByReplacingOccurrencesOfString:@"\r" withString:@""];
                    NSLog(@"%@ message:\n%@\n", [self crateName], msg);
                } break;
                
                case ERROR_ID: {
                    NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ error packet received:\n", [self crateName]];
                    int error;
                    ErrorPacket* data = (ErrorPacket*)&xl3Packet.payload;
                    if (needToSwap) SwapLongBlock(data, sizeof(ErrorPacket)/4);

                    error = data->cmdRejected;
                    if (error) [msg appendFormat:@"cmd_in_rejected: 0x%x, ", error];
                    error = data->transferError;
                    if (error) [msg appendFormat:@"transfer_error: 0x%x, ", error];
                    error = data->xl3DataAvailUnknown;
                    if (error) [msg appendFormat:@"xl3_davail_unknown: 0x%x, ", error];
                    unsigned int slot;
                    for (slot=0; slot<16; slot++) {
                        error = data->fecBundleReadError[slot];
                        if (error) [msg appendFormat:@"bundle_read_error slot %2d: 0x%x, ", slot, error];
                    }
                    for (slot=0; slot<16; slot++) {
                        error = data->fecBundleResyncError[slot];
                        if (error) [msg appendFormat:@"bundle_resync_error slot %2d: 0x%x, ", slot, error];
                    }
                    for (slot=0; slot< 16; slot++) {
                        error = data->fecMemLevelUnknown[slot];
                        if (error) [msg appendFormat:@"mem_level_unknown slot %2d: 0x%x, ", slot, error];
                    }
                    [msg appendFormat:@"\n"];
                    NSLogColor([NSColor redColor],msg);
                } break;

                case SCREWED_ID: {
                    NSMutableString* msg = [NSMutableString stringWithFormat:@"%@ screwed for slot:\n", [self crateName]];
                    unsigned int i, error;
                    for (i = 0; i < 16; i++) {
                        error = ((ScrewedPacket*)xl3Packet.payload)->fecScrewed[i];
                        error = ntohl(error);
                        [msg appendFormat:@"%2d: 0x%x\n", i, error];
                    }
                    NSLogColor([NSColor redColor],msg);
                } break;

                default: { //cmd response
                    unsigned short packetNum = ntohs(xl3Packet.header.packetNum);
                    unsigned char packetType = xl3Packet.header.packetType;
                                    
                    NSData* packetData = [[NSData alloc] initWithBytes:(char*)&xl3Packet length:XL3_PACKET_SIZE];
                    NSNumber* packetNNum = [[NSNumber alloc] initWithUnsignedShort:packetNum];
                    NSNumber* packetNType = [[NSNumber alloc] initWithUnsignedChar:packetType];
                    NSDate* packetDate = [[NSDate alloc] init];
                    NSDictionary* aDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:
                                                 packetNNum, @"packetNum",
                                                 packetNType, @"packetType",
                                                 packetDate, @"date",
                                                 packetData, @"xl3Packet",
                                                 nil];
                    
                    [cmdArrayLock lock];
                    @try {
                        [cmdArray addObject:aDictionary];
                    }
                    @catch (NSException* e) {
                        NSLog(@"%@: Failed to add received command response into the command array\n", [self crateName]);
                    }
                    @finally {
                        [cmdArrayLock unlock];
                    }

                    [aDictionary release];
                    aDictionary = nil;
                    [packetData release];
                    packetData = nil;
                    [packetNNum release];
                    packetNNum = nil;
                    [packetNType release];
                    packetNType = nil;
                    [packetDate release];
                    packetDate = nil;
                    
                    if ([cmdArray count] > kCmdArrayHighWater) {
                        NSLog(@"%@ command array close to full.\n", [self crateName]);
                    }
                }
            } //case
        } //select
    } //while

	if (workingSocket) {
        close(workingSocket);
        workingSocket = 0;
	
		NSLog(@"%@ disconnected from local port %d\n", [self crateName], [self portNumber]);
		connectState = kDisconnected;
		[[NSNotificationCenter defaultCenter] postNotificationName:XL3_LinkConnectStateChanged object: self];
		[self setIsConnected:NO];
	}

	[pool release];

    if ([self autoConnect]) {
        [self performSelectorOnMainThread:@selector(connectSocket) withObject:nil waitUntilDone:NO];
    }
}

/**
 * Low level packet write to the workingSocket for the link. This method sets
 * the packetNum for the xl3Packet passed. Raises exceptions on failure.
 *
 * Note: This is private method called from this object only, we lock the
 * socket, and expect that the xl3 thread is the only accessor. 
 */
- (void) writePacket:(XL3Packet*)xl3Packet
{
	if (!workingSocket) {
		[NSException raise:@"Write error" format:@"XL3 not connected %@ <%@> port: %u",[self crateName], IPNumber, portNumber];
	}
    
	int bytesWritten;
	int selectionResult = 0;
	int numBytesToSend = XL3_PACKET_SIZE;
	fd_set write_fds;

	struct timeval tv;
	tv.tv_sec  = [self errorTimeOutSeconds];
	tv.tv_usec = 2000;
	
	time_t t1 = time(0);

    [coreSocketLock lock];
    xl3Packet->header.packetNum = htons(numPackets++);
    char *aPacket = (char*)xl3Packet;
	@try {
		while (numBytesToSend) {
			// The loop is to ignore EAGAIN and EINTR errors as these are harmless 
			do {
				FD_ZERO(&write_fds);
				FD_SET(workingSocket, &write_fds);
				
				selectionResult = select(workingSocket+1, NULL, &write_fds, NULL, &tv);
			} while (selectionResult == -1 && (errno == EAGAIN || errno == EINTR));
			
			if (selectionResult == -1){
				[NSException raise:@"Write error" format:@"Write error %@ <%@>: %s",[self crateName], IPNumber, strerror(errno)];
                [self performSelector:@selector(disconnectSocket) withObject:nil afterDelay:0]; //only runs after the the calling thread is done
			}
			else if (selectionResult == 0 || ([self errorTimeOutSeconds] && time(0) - t1 > [self errorTimeOutSeconds])) {
				[NSException raise:@"Connection time out" format:@"Write to %@ <%@> port: %u timed out",[self crateName], IPNumber, portNumber];
                [self performSelector:@selector(disconnectSocket) withObject:nil afterDelay:0]; //only runs after the the calling thread is done
			}

			do {
				bytesWritten = (int)write(workingSocket, aPacket, numBytesToSend);
			} while (bytesWritten < 0 && (errno == EAGAIN || errno == EINTR));

			if (bytesWritten > 0) {
				aPacket += bytesWritten;
				numBytesToSend -= bytesWritten;
			} 
			else if (bytesWritten < 0) {
				if (errno == EPIPE) {
                    [self performSelector:@selector(disconnectSocket) withObject:nil afterDelay:0]; //only runs after the the calling thread is done
				}
				[NSException raise:@"Write error" format:@"Write error(%s) %@ <%@> port: %u",strerror(errno),[self crateName],IPNumber,portNumber];
			}
		}
	}
	@catch (NSException* localException) {
		if (workingSocket) {
			NSLogColor([NSColor redColor], @"Couldn't write to XL3 <%@> port:%d\n", IPNumber, portNumber);
		}
		@throw localException;
	}
	@finally {
		[coreSocketLock unlock];
	}
}

/**
 * Low level packet read from the XL3. Raise an exception if it times out
 * or the XL3 disconnects.
 *
 * Note: This is private method called from this object only. The read is not
 * locked and it is assumed the XL3 thread (connectToPort) is the only accessor. 
 */
- (void) readPacket:(XL3Packet*)xl3Packet
{
    char *aPacket = (char*)xl3Packet;
    ssize_t n;
    int selectionResult = 0;
    int numBytesToGet = XL3_PACKET_SIZE;
    time_t t1 = time(0);
    fd_set fds;

    struct timeval tv;
    tv.tv_sec  = 0;
    tv.tv_usec = 2000;
    memset(aPacket, 0, XL3_PACKET_SIZE);

    while(numBytesToGet) {
        for (;;) {
            n = recv(workingSocket, aPacket, numBytesToGet, MSG_DONTWAIT);
            if(n < 0 && (errno == EAGAIN || errno == EINTR)) {
                /* Since the socket is nonblocking, recv() returns -1 and sets
                 * errno to EAGAIN if there are no messages available at the
                 * socket. */
                if ([self errorTimeOutSeconds] && \
                    (time(0) - t1) > [self errorTimeOutSeconds]) {
                    [NSException raise:@"Socket time out"
                     format:@"%@ Disconnected", IPNumber];
                }
            } else {
                /* Either we got data or there was a problem. */
                break;
            }
        }

        if (n > 0) {
            /* We read n bytes from the socket. */
            numBytesToGet -= n;
            aPacket += n;
            /* If we've got a full packet break. */
            if (numBytesToGet == 0) break;
        } else if(n == 0) {
            /* If recv() returns 0, it means the XL3 has disconnected. */
            [NSException raise:@"Socket time out" format:@"%@ Disconnected", IPNumber];
        } else {
            /* There was a problem with the socket. */
            [NSException raise:@"Socket error" format:@"Error <%@>: %s",IPNumber,strerror(errno)];
        }

        for (;;) {
            /* Wait until the socket is readable. */
            FD_ZERO(&fds);
            FD_SET(workingSocket, &fds);

            selectionResult = select(workingSocket + 1, &fds, NULL, NULL, &tv);

            if (selectionResult == -1 && \
                !(errno == EAGAIN || errno == EINTR)) {
                NSLog(@"Error reading XL3 <%@> port: %d\n", IPNumber,
                      portNumber);
                [NSException raise:@"Socket Error" format:@"Error <%@>: %s",
                 IPNumber, strerror(errno)];
            }

            if ([self errorTimeOutSeconds] && \
                (time(0) - t1) > [self errorTimeOutSeconds]) {
                [NSException raise:@"Socket time out"
                 format:@"%@ Disconnected",IPNumber];
            }

            if (selectionResult > 0 && FD_ISSET(workingSocket, &fds)) break;
        }
    }
}

@end

