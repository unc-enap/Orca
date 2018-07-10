//  ORUDPConnection.m
//  Orca
//
//  Created by Mark Howe on 1/23/18. Heavily copied from Apple's UDPEcho example
//  Copyright 2018, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import <Foundation/Foundation.h>

#if TARGET_OS_EMBEDDED || TARGET_IPHONE_SIMULATOR
#import <CFNetwork/CFNetwork.h>
#else
#import <CoreServices/CoreServices.h>
#endif

@protocol ORUDPConnectionDelegate;

@interface ORUDPConnection : NSObject
{
    CFHostRef               _cfHost;
    CFSocketRef             _cfSocket;
    id <ORUDPConnectionDelegate> delegate;
    NSString*                hostName;
    NSData*                  hostAddress;
    NSUInteger               port;
    BOOL                     server;
}
- (id)init;
- (BOOL)isServer;

- (void)startServerOnPort:(NSUInteger)port;
// Starts an echo server on the specified port.  Will call the
// -udpConnection:didStartWithAddress: delegate method on success and the
// -udpConnection:didStopWithError: on failure.  After that, the various
// 'data' delegate methods may be called.

- (void)startConnectedToHostName:(NSString *)hostName port:(NSUInteger)port;
// Starts a client targetting the specified host and port.
// Will call -udpConnection:didStartWithAddress: delegate method on success and
// the -udpConnection:didStopWithError: on failure.  At that point you can call
// -sendData: to send data to the server and the various 'data' delegate
// methods may be called.

- (void)sendData:(NSData *)data;
// On the client, sends the specified data to the server.  The
// -udpConnection:didSendData:toAddress: or -udpConnection:didFailToSendData:toAddress:error:
// delegate method will be called to indicate the success or failure
// of the send, and the -udpConnection:didReceiveData:fromAddress: delegate method
// will be called if a response is received.

- (void)stop;
// Will stop the object, preventing any future network operations or delegate
// method calls until the next start call.

@property (nonatomic, assign) id<ORUDPConnectionDelegate>    delegate;
@property (nonatomic, assign) BOOL   server;
@property (nonatomic, copy ) NSData *               hostAddress;    // valid in client mode after successful start
@property (nonatomic, copy ) NSString *             hostName;       // valid in client mode
@property (nonatomic, assign ) NSUInteger             port;           // valid in client and server mode

@end



@protocol ORUDPConnectionDelegate <NSObject>

@optional

// In all cases an address is an NSData containing some form of (struct sockaddr),
// specifically a (struct sockaddr_in) or (struct sockaddr_in6).

- (void)udpConnection:(ORUDPConnection *)echo didReceiveData:(NSData *)data fromAddress:(NSData *)addr;
// Called after successfully receiving data.  On a server object this data will
// automatically be echoed back to the sender.
//
// assert(echo != nil);
// assert(data != nil);
// assert(addr != nil);

- (void)udpConnection:(ORUDPConnection *)echo didReceiveError:(NSError *)error;
// Called after a failure to receive data.
//
// assert(echo != nil);
// assert(error != nil);

- (void)udpConnection:(ORUDPConnection *)echo didSendData:(NSData *)data toAddress:(NSData *)addr;
// Called after successfully sending data.  On the server side this is typically
// the result of an echo.
//
// assert(echo != nil);
// assert(data != nil);
// assert(addr != nil);

- (void)udpConnection:(ORUDPConnection *)echo didFailToSendData:(NSData *)data toAddress:(NSData *)addr error:(NSError *)error;
// Called after a failure to send data.
//
// assert(echo != nil);
// assert(data != nil);
// assert(addr != nil);
// assert(error != nil);

- (void)udpConnection:(ORUDPConnection *)echo didStartWithAddress:(NSData *)address;
// Called after the object has successfully started up.  On the client addresses
// is the list of addresses associated with the host name passed to
// -startConnectedToHostName:port:.  On the server, this is the local address
// to which the server is bound.
//
// assert(echo != nil);
// assert(address != nil);
- (void)echoDidStop:(ORUDPConnection *)echo;

- (void)udpConnection:(ORUDPConnection *)echo didStopWithError:(NSError *)error;
// Called after the object stops spontaneously (that is, after some sort of failure,
// but now after a call to -stop).
//
// assert(echo != nil);
// assert(error != nil);

@end


