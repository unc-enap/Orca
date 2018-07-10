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

#import "ORUDPConnection.h"

#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <unistd.h>

NSString* ORUDPConnectionHostNameChanged    = @"ORUDPConnectionHostNameChanged";
NSString* ORUDPConnectionPortChanged        = @"ORUDPConnectionPortChanged";

@interface ORUDPConnection ()
- (void)stopHostResolution;
- (void)stopWithError:(NSError *)error;
- (void)stopWithStreamError:(CFStreamError)streamError;
@end

@implementation ORUDPConnection

@synthesize delegate;
@synthesize port;
@synthesize hostName;
@synthesize hostAddress;
@synthesize server;

- (id)init
{
    self = [super init];
    if (self != nil) {
        // do nothing
    }
    return self;
}

- (void) dealloc
{
    self.hostName = nil;
    self.hostAddress = nil;
    
    [self stop];
    [super dealloc];
}

- (BOOL)isServer
{
    return self.hostName == nil;
}


- (void)sendData:(NSData *)data toAddress:(NSData *)addr
// Called by both -sendData: and the server echoing code to send data
// via the socket.  addr is nil in the client case, whereupon the
// data is automatically sent to the hostAddress by virtue of the fact
// that the socket is connected to that address.
{
    int                     err;
    int                     sock;
    ssize_t                 bytesWritten;
    const struct sockaddr * addrPtr;
    socklen_t               addrLen;
    
    assert(data != nil);
    assert( (addr != nil) == self.isServer );
    assert( (addr == nil) || ([addr length] <= sizeof(struct sockaddr_storage)) );
    
    sock = CFSocketGetNative(self->_cfSocket);
    assert(sock >= 0);
    
    if (addr == nil) {
        addr = self.hostAddress;
        assert(addr != nil);
        addrPtr = NULL;
        addrLen = 0;
    }
    else {
        addrPtr = [addr bytes];
        addrLen = (socklen_t) [addr length];
    }
    
    bytesWritten = sendto(sock, [data bytes], [data length], 0, addrPtr, addrLen);
    if (bytesWritten < 0) {
        err = errno;
    } else  if (bytesWritten == 0) {
        err = EPIPE;
    } else {
        // We ignore any short writes, which shouldn't happen for UDP anyway.
        assert( (NSUInteger) bytesWritten == [data length] );
        err = 0;
    }
    
    if (err == 0) {
        if ( ([self delegate] != nil) && [[self delegate] respondsToSelector:@selector(udpConnection:didSendData:toAddress:)] ) {
            [[self delegate] udpConnection:self didSendData:data toAddress:addr];
        }
    } else {
        if ( ([self delegate] != nil) && [[self delegate] respondsToSelector:@selector(udpConnection:didFailToSendData:toAddress:error:)] ) {
            [[self delegate] udpConnection:self didFailToSendData:data toAddress:addr error:[NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil]];
        }
    }
}

- (void)readData
// Called by the CFSocket read callback to actually read and process data
// from the socket.
{
    int                     err;
    int                     sock;
    struct sockaddr_storage addr;
    socklen_t               addrLen;
    uint8_t                 buffer[65536];
    ssize_t                 bytesRead;
    
    sock = CFSocketGetNative(self->_cfSocket);
    assert(sock >= 0);
    
    addrLen = sizeof(addr);
    bytesRead = recvfrom(sock, buffer, sizeof(buffer), 0, (struct sockaddr *) &addr, &addrLen);
    if (bytesRead < 0) {
        err = errno;
    } else if (bytesRead == 0) {
        err = EPIPE;
    } else {
        NSData *    dataObj;
        NSData *    addrObj;
        
        err = 0;
        
        dataObj = [NSData dataWithBytes:buffer length:(NSUInteger) bytesRead];
        assert(dataObj != nil);
        addrObj = [NSData dataWithBytes:&addr  length:addrLen  ];
        assert(addrObj != nil);
        
        // Tell the delegate about the data.
        
        if ( ([self delegate] != nil) && [[self delegate] respondsToSelector:@selector(udpConnection:didReceiveData:fromAddress:)] ) {
            [[self delegate] udpConnection:self didReceiveData:dataObj fromAddress:addrObj];
        }
        
        // Echo the data back to the sender.
        
        if (self.isServer) {
            [self sendData:dataObj toAddress:addrObj];
        }
    }
    
    // If we got an error, tell the delegate.
    
    if (err != 0) {
        if ( ([self delegate] != nil) && [[self delegate] respondsToSelector:@selector(udpConnection:didReceiveError:)] ) {
            [[self delegate] udpConnection:self didReceiveError:[NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil]];
        }
    }
}

static void SocketReadCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
// This C routine is called by CFSocket when there's data waiting on our
// UDP socket.  It just redirects the call to Objective-C code.
{
    ORUDPConnection *       obj;
    
    obj = (__bridge ORUDPConnection *) info;
    assert([obj isKindOfClass:[ORUDPConnection class]]);
    
#pragma unused(s)
    assert(s == obj->_cfSocket);
#pragma unused(type)
    assert(type == kCFSocketReadCallBack);
#pragma unused(address)
    assert(address == nil);
#pragma unused(data)
    assert(data == nil);
    
    [obj readData];
}



- (BOOL)setupSocketConnectedToAddress:(NSData *)address port:(NSUInteger)aPort error:(NSError **)errorPtr
// Sets up the CFSocket in either client or server mode.  In client mode,
// address contains the address that the socket should be connected to.
// The address contains zero port number, so the port parameter is used instead.
// In server mode, address is nil and the socket is bound to the wildcard
// address on the specified port.
{
    int                     err;
    int                     junk;
    int                     sock;
    const CFSocketContext   context = { 0, (__bridge void *)(self), NULL, NULL, NULL };
    CFRunLoopSourceRef      rls;
    
    assert( (address == nil) == self.isServer );
    assert( (address == nil) || ([address length] <= sizeof(struct sockaddr_storage)) );
    assert(aPort < 65536);
    
    assert(self->_cfSocket == NULL);
    
    // Create the UDP socket itself.
    
    err = 0;
    sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock < 0) {
        err = errno;
    }
    
    // Bind or connect the socket, depending on whether we're in server or client mode.
    
    if (err == 0) {
        struct sockaddr_in      addr;
        
        memset(&addr, 0, sizeof(addr));
        if (address == nil) {
            // Server mode.  Set up the address based on the socket family of the socket
            // that we created, with the wildcard address and the caller-supplied port number.
            addr.sin_len         = sizeof(addr);
            addr.sin_family      = AF_INET;
            addr.sin_port        = htons(aPort);
            addr.sin_addr.s_addr = INADDR_ANY;
            err = bind(sock, (const struct sockaddr *) &addr, sizeof(addr));
        } else {
            // Client mode.  Set up the address on the caller-supplied address and port
            // number.
            if ([address length] > sizeof(addr)) {
                assert(NO);         // very weird
                [address getBytes:&addr length:sizeof(addr)];
            } else {
                [address getBytes:&addr length:[address length]];
            }
            assert(addr.sin_family == AF_INET);
            addr.sin_port = htons(aPort);
            err = connect(sock, (const struct sockaddr *) &addr, sizeof(addr));
        }
        if (err < 0) {
            err = errno;
        }
    }
    
    // From now on we want the socket in non-blocking mode to prevent any unexpected
    // blocking of the main thread.  None of the above should block for any meaningful
    // amount of time.
    
    if (err == 0) {
        int flags;
        
        flags = fcntl(sock, F_GETFL);
        err = fcntl(sock, F_SETFL, flags | O_NONBLOCK);
        if (err < 0) {
            err = errno;
        }
    }
    
    // Wrap the socket in a CFSocket that's scheduled on the runloop.
    
    if (err == 0) {
        self->_cfSocket = CFSocketCreateWithNative(NULL, sock, kCFSocketReadCallBack, SocketReadCallback, &context);
        
        // The socket will now take care of cleaning up our file descriptor.
        
        assert( CFSocketGetSocketFlags(self->_cfSocket) & kCFSocketCloseOnInvalidate );
        sock = -1;
        
        rls = CFSocketCreateRunLoopSource(NULL, self->_cfSocket, 0);
        assert(rls != NULL);
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
        
        CFRelease(rls);
    }
    
    // Handle any errors.
    
    if (sock != -1) {
        junk = close(sock);
        assert(junk == 0);
    }
    assert( (err == 0) == (self->_cfSocket != NULL) );
    if ( (self->_cfSocket == NULL) && (errorPtr != NULL) ) {
        *errorPtr = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
    }
    
    return (err == 0);
}



- (void)startServerOnPort:(NSUInteger)aPort
// See comment in header.
{
    assert( (aPort > 0) && (aPort < 65536) );
    
    assert([self port] == 0);     // don't try and start a started object
    if ([self port] == 0) {
        BOOL        success;
        NSError *   error;
        
        // Create a fully configured socket.
        
        success = [self setupSocketConnectedToAddress:nil port:aPort error:&error];
        
        // If we can create the socket, we're good to go.  Otherwise, we report an error
        // to the delegate.
        
        if (success) {
            [self setPort:aPort];
            
            if ( ([self delegate] != nil) && [[self delegate] respondsToSelector:@selector(udpConnection:didStartWithAddress:)] ) {
                CFDataRef   localAddress;
                
                localAddress = CFSocketCopyAddress(self->_cfSocket);
                assert(localAddress != NULL);
                
                [[self delegate] udpConnection:self didStartWithAddress:(__bridge NSData *) localAddress];
                
                CFRelease(localAddress);
            }
        } else {
            [self stopWithError:error];
        }
    }
}

- (void)hostResolutionDone
// Called by our CFHost resolution callback (HostResolveCallback) when host
// resolution is complete.  We find the best IP address and create a socket
// connected to that.
{
    assert([self port] != 0);
    assert(self->_cfHost != NULL);
    assert(self->_cfSocket == NULL);
    assert(self.hostAddress == nil);
    
    NSError* error = nil;
    Boolean             resolved;
    NSArray* resolvedAddresses = (__bridge NSArray *) CFHostGetAddressing(self->_cfHost, &resolved);
    if ( resolved && (resolvedAddresses != nil) ) {
        // Walk through the resolved addresses looking for one that we can work with.
        for (NSData * address in resolvedAddresses) {
            const struct sockaddr*addrPtr = (const struct sockaddr *) [address bytes];
            NSUInteger addrLen = [address length];
            assert(addrLen >= sizeof(struct sockaddr));
            BOOL success = NO;
            if ((addrPtr->sa_family == AF_INET)) {
                success = [self setupSocketConnectedToAddress:address port:[self port] error:&error];
                if (success) {
                    CFDataRef hostAdr = CFSocketCopyPeerAddress(self->_cfSocket);
                    assert(hostAdr != NULL);
                    self.hostAddress = (__bridge NSData *) hostAdr;
                    CFRelease(hostAdr);
                }
            }
            if (success) {
                //found one.
                break;
            }
        }
    }
    
    // If we didn't get an address and didn't get an error, synthesise a host not found error.
    
    if ( (self.hostAddress == nil) && (error == nil) ) {
        error = [NSError errorWithDomain:(NSString *)kCFErrorDomainCFNetwork code:kCFHostErrorHostNotFound userInfo:nil];
    }
    
    if (error == nil) {
        [self stopHostResolution]; //done with that
        if ( ([self delegate] != nil) && [[self delegate] respondsToSelector:@selector(udpConnection:didStartWithAddress:)] ) {
            [[self delegate] udpConnection:self didStartWithAddress:self.hostAddress];
        }
    }
    else {
        [self stopWithError:error];
    }
}

static void HostResolveCallback(CFHostRef theHost, CFHostInfoType typeInfo, const CFStreamError *error, void *info)
// This C routine is called by CFHost when the host resolution is complete.
// It just redirects the call to the appropriate Objective-C method.
{
    ORUDPConnection* obj = (__bridge ORUDPConnection *) info;
    assert([obj isKindOfClass:[ORUDPConnection class]]);
    
#pragma unused(theHost)
    assert(theHost == obj->_cfHost);
#pragma unused(typeInfo)
    assert(typeInfo == kCFHostAddresses);
    
    if ( (error != NULL) && (error->domain != 0) ) {
        [obj stopWithStreamError:*error];
    }
    else {
        [obj hostResolutionDone];
    }
}

- (void) startConnectedToHostName:(NSString *)aHostName port:(NSUInteger)aPort
// See comment in header.
{
    assert(aHostName != nil);
    assert( (aPort > 0) && (aPort < 65536) );
    
    assert(self.port == 0);     // don't try and start a started object
    if (self.port == 0) {
        CFHostClientContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
        
        assert(self->_cfHost == NULL);
        
        self->_cfHost = CFHostCreateWithName(NULL, (__bridge CFStringRef) aHostName);
        assert(self->_cfHost != NULL);
        
        CFHostSetClient(self->_cfHost, HostResolveCallback, &context);
        
        CFHostScheduleWithRunLoop(self->_cfHost, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        
        CFStreamError       streamError;
        Boolean success = CFHostStartInfoResolution(self->_cfHost, kCFHostAddresses, &streamError);
        if (success) {
            self.hostName = aHostName;
            self.port = aPort;
            // ... continue in HostResolveCallback
        }
        else {
            [self stopWithStreamError:streamError];
        }
    }
}

- (void)sendData:(NSData *)data
// See comment in header.
{
    // If you call -sendData: on a object in server mode or an object in client mode
    // that's not fully set up (hostAddress is nil), we just ignore you.
    if (self.isServer || (self.hostAddress == nil) ) {
        assert(NO);
    }
    else {
        [self sendData:data toAddress:nil];
    }
}

- (void) stopHostResolution
// Called to stop the CFHost part of the object, if it's still running.
{
    if (self->_cfHost != NULL) {
        CFHostSetClient(self->_cfHost, NULL, NULL);
        CFHostCancelInfoResolution(self->_cfHost, kCFHostAddresses);
        CFHostUnscheduleFromRunLoop(self->_cfHost, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        CFRelease(self->_cfHost);
        self->_cfHost = NULL;
    }
}

- (void)stop
// See comment in header.
{
    self.hostName = nil;
    self.hostAddress = nil;
    self.port = 0;
    [self stopHostResolution];
    if (self->_cfSocket != NULL) {
        CFSocketInvalidate(self->_cfSocket);
        CFRelease(self->_cfSocket);
        self->_cfSocket = NULL;
    }
    if ( ([self delegate] != nil) && [[self delegate] respondsToSelector:@selector(echoDidStop:)] ) {
        // The following line ensures that we don't get deallocated until the next time around the
        // run loop.  This is important if our delegate holds the last reference to us and
        // this callback causes it to release that reference.  At that point our object (self) gets
        // deallocated, which causes problems if any of the routines that called us reference self.
        // We prevent this problem by performing a no-op method on ourself, which keeps self alive
        // until the perform occurs.
        [self performSelector:@selector(noop) withObject:nil afterDelay:0.0];
        [[self delegate] echoDidStop:self];
    }
}

- (void)noop
{
}

- (void) stopWithError:(NSError *)error
{
    assert(error != nil);
    [self stop];
    if ( ([self delegate] != nil) && [[self delegate] respondsToSelector:@selector(udpConnection:didStopWithError:)] ) {
        // The following line ensures that we don't get deallocated until the next time around the
        // run loop.  This is important if our delegate holds the last reference to us and
        // this callback causes it to release that reference.  At that point our object (self) gets
        // deallocated, which causes problems if any of the routines that called us reference self.
        // We prevent this problem by performing a no-op method on ourself, which keeps self alive
        // until the perform occurs.
        [self performSelector:@selector(noop) withObject:nil afterDelay:0.0];
        [[self delegate] udpConnection:self didStopWithError:error];
    }
}

- (void) stopWithStreamError:(CFStreamError)streamError
{
    NSDictionary *  userInfo;
    NSError *       error;
    
    if (streamError.domain == kCFStreamErrorDomainNetDB) {
        userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                    [NSNumber numberWithInteger:streamError.error], kCFGetAddrInfoFailureKey,
                    nil
                    ];
    }
    else {
        userInfo = nil;
    }
    error = [NSError errorWithDomain:(NSString *)kCFErrorDomainCFNetwork code:kCFHostErrorUnknown userInfo:userInfo];
    assert(error != nil);
    
    [self stopWithError:error];
}


@end

