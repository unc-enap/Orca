//
//  XL3_Link.h
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

#import "PacketTypes.h"
@class ORSafeCircularBuffer;

typedef enum eXL3_ConnectStates {
	kDisconnected,
	kWaiting,
	kConnected
} eXL3_CrateStates;


@interface XL3_Link : ORGroup
{
	int         workingSocket;      //handle to the current socket connection
	NSLock*		commandSocketLock;	//avoids clashes between commands. Wrap an XL3 packet write,
                                    //so you know a possible write error comes from your command.
	NSLock*		coreSocketLock;		//protects the socket, to guarantee that full packet is read/written
                                    //and that reads and writes do not clash, XL3 is a fixed packet size protocol
	NSLock*		cmdArrayLock;		//cmdArrayLock protects manipulations with the array of command responses
                                    //received from an XL3, to synchronize the threaded worker pushing XL3 responses,
                                    //and XL3Model pulling/distributing the responses
    int         pendingThreads;     //Number of threads waiting on a response
    NSLock*     connectionLock;     //Must be held before modifying pendingThreads
	BOOL		needToSwap;         //Whether byte order needs swapping to communicate with the XL3
	NSString*	IPNumber;
	NSString*	crateName;
	uint32_t	portNumber;
    BOOL        autoConnect;
    BOOL		isConnected;
	int		connectState;
	int		_errorTimeOut;
	NSDate*	timeConnected;
	NSMutableArray*	cmdArray;       //Array of cmd packet responses received from XL3 but not yet dispatched to requesters
	uint16_t numPackets;
	uint64_t num_dat_packets;
	XL3Packet	aMultiCmdPacket;
    uint32_t _fifoBundle[16];  //an array to enter data stream
}

@property (assign,nonatomic) BOOL isConnected;
@property (assign,nonatomic) int pendingThreads;
@property (assign,nonatomic) BOOL autoConnect;
@property (assign,nonatomic) int errorTimeOut;

- (id)   init;
- (void) dealloc;
- (void) wakeUp; 
- (void) sleep ;

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••Accessors
- (BOOL) needToSwap;
- (void) setNeedToSwap;
- (int)  connectState;
- (void) setErrorTimeOut:(int)aValue;
- (int) errorTimeOut;
- (int) errorTimeOutSeconds;
- (void) toggleConnect;
- (NSDate*) timeConnected;
- (void) setTimeConnected:(NSDate*)newTimeConnected;
- (NSString*) IPNumber;
- (void) setIPNumber:(NSString*)aIPNumber;
- (uint32_t)  portNumber;
- (void) setPortNumber:(uint32_t)aPortNumber;
- (NSString*) crateName;
- (void) setCrateName:(NSString*)aCrateName;

- (void) newMultiCmd;
- (void) addMultiCmdToAddress:(int32_t)anAddress withValue:(int32_t)aValue;
- (XL3Packet*) executeMultiCmd;
- (BOOL) multiCmdFailed;

- (void) sendXL3Packet:(XL3Packet*)aSendPacket;
- (void) sendCommand:(uint8_t) aCmd withPayload:(char *) payloadBlock expectResponse:(BOOL) askForResponse;
- (void) sendCommand:(uint8_t) aCmd expectResponse:(BOOL) askForResponse;
- (void) sendCommand:(uint8_t) aCmd toAddress:(uint32_t) address withData:(uint32_t *) value;
- (void) readXL3Packet:(XL3Packet*) aPacket withPacketType:(uint8_t) packetType andPacketNum:(uint16_t) packetNum;

- (void) connectSocket;
- (void) disconnectSocket;
- (void) connectToPort;
- (void) writePacket:(XL3Packet*)aPacket;
- (void) readPacket:(XL3Packet*)aPacket;

@end


extern NSString* XL3_LinkConnectionChanged;
extern NSString* XL3_LinkTimeConnectedChanged;
extern NSString* XL3_LinkIPNumberChanged;
extern NSString* XL3_LinkConnectStateChanged;
extern NSString* XL3_LinkErrorTimeOutChanged;
extern NSString* XL3_LinkAutoConnectChanged;
