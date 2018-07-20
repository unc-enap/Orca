
//  NetSocket
//  NetSocket.h
//  Version 0.9
//  Created by Dustin Mierau


#import <netinet/in.h>
#define kNetSocketSentAll  0
#define kNetSocketSentSome 1
#define kNetSocketBlocked  2

@interface NetSocket : NSObject 
{
	CFSocketRef	     mCFSocketRef;
	CFRunLoopSourceRef  mCFSocketRunLoopSourceRef;
	id				 mDelegate;
	NSTimer*	     mConnectionTimer;
	BOOL		     mSocketConnected;
	BOOL		     mSocketListening;
	NSMutableData*   mOutgoingBuffer;
	NSMutableData*   mIncomingBuffer;
	NSRecursiveLock* mLock;
    int              mBufferStatus;
    int              mOldBufferStatus;
    uint32_t    mOldAmountInBuffer;
}

// Creation
+ (NetSocket*)netsocket;
+ (NetSocket*)netsocketListeningOnRandomPort;
+ (NetSocket*)netsocketListeningOnPort:(uint16_t)inPort;
+ (NetSocket*)netsocketConnectedToHost:(NSString*)inHostname port:(uint16_t)inPort;

// Delegate
- (id)delegate;
- (void)setDelegate:(id)inDelegate;

// Opening and Closing
- (BOOL)open;
- (void)close;

// Runloop Scheduling
- (BOOL)scheduleOnCurrentRunLoop;
- (BOOL)scheduleOnRunLoop:(NSRunLoop*)inRunLoop;

// Listening
- (BOOL)listenOnRandomPort;
- (BOOL)listenOnPort:(uint16_t)inPort;
- (BOOL)listenOnPort:(uint16_t)inPort maxPendingConnections:(int)inMaxPendingConnections;

// Connecting
- (BOOL)connectToHost:(NSString*)inHostname port:(uint16_t)inPort;
- (BOOL)connectToHost:(NSString*)inHostname port:(uint16_t)inPort timeout:(NSTimeInterval)inTimeout;

// Peeking
- (NSData*)peekData;

// Reading
- (NSUInteger)read:(void*)inBuffer amount:(NSUInteger)inAmount;
- (NSUInteger)readOntoData:(NSMutableData*)inData;
- (NSUInteger)readOntoData:(NSMutableData*)inData amount:(NSUInteger)inAmount;
- (NSUInteger)readOntoString:(NSMutableString*)inString encoding:(NSStringEncoding)inEncoding amount:(NSUInteger)inAmount;
- (NSData*)readData;
- (NSData*)readData:(NSUInteger)inAmount;
- (NSString*)readString:(NSStringEncoding)inEncoding;
- (NSString*)readString:(NSStringEncoding)inEncoding amount:(NSUInteger)inAmount;

// Writing
- (void)write:(const void*)inBytes length:(NSUInteger)inLength;
- (void)writeData:(NSData*)inData;
- (void)writeString:(NSString*)inString encoding:(NSStringEncoding)inEncoding;

// Properties
- (NSString*)remoteHost;
- (uint16_t)remotePort;
- (NSString*)localHost;
- (uint16_t)localPort;
- (BOOL)isConnected;
- (BOOL)isListening;
- (NSUInteger)incomingBufferLength;
- (NSUInteger)outgoingBufferLength;
- (CFSocketNativeHandle)nativeSocketHandle;
- (CFSocketRef)cfsocketRef;

// Convenience methods
+ (void)ignoreBrokenPipes;
+ (NSString*)stringWithSocketAddress:(struct in_addr*)inAddress;

@end

#pragma mark -

@interface NSObject (NetSocketDelegate)
- (void) netsocketConnected:(NetSocket*)inNetSocket;
- (void) netsocket:(NetSocket*)inNetSocket connectionTimedOut:(NSTimeInterval)inTimeout;
- (void) netsocketDisconnected:(NetSocket*)inNetSocket;
- (void) netsocket:(NetSocket*)inNetSocket connectionAccepted:(NetSocket*)inNewNetSocket;
- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount;
- (void) netsocketDataSent:(NetSocket*)inNetSocket length:(int32_t)amount;
- (void) netsocketDataInOutgoingBuffer:(NetSocket*)inNetSocket length:(int32_t)amount;
- (void) netsocket:(NetSocket*)inNetSocket status:(int)status;
@end
