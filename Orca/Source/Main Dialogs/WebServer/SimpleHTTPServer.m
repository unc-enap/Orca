//
//  SimpleHTTPServer.m
//  Orca
//
//  Created by Mark Howe on Tuesday, June 23,2009.
//  Copyright (c) 2009 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics  sponsored 
//in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "SimpleHTTPServer.h"
#import "SimpleHTTPConnection.h"
#import "WebServer.h"
#import <sys/socket.h>   // for AF_INET, PF_INET, SOCK_STREAM, SOL_SOCKET, SO_REUSEADDR
#import <netinet/in.h>   // for IPPROTO_TCP, sockaddr_in

@interface SimpleHTTPServer (PrivateMethods)
- (void)setCurrentRequest:(NSDictionary *)value;
- (void)processNextRequestIfNecessary;
@end

@implementation SimpleHTTPServer

- (id)initWithTCPPort:(unsigned)po delegate:(id)dl
{
    if( self = [super init] ) {
        port = po;
        delegate = dl;
        connections = [[NSMutableArray alloc] init];
        requests = [[NSMutableArray alloc] init];
        [self setCurrentRequest:nil];
        
        NSAssert(delegate != nil, @"Please specify a delegate");
        NSAssert([delegate respondsToSelector:@selector(processURL:connection:)],
                  @"Delegate needs to implement 'processURL:connection:'");

        socketPort = [[NSSocketPort alloc] initWithTCPPort:port];
		fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:[socketPort socket]
                                                     closeOnDealloc:YES];
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(newConnection:)
                   name:NSFileHandleConnectionAcceptedNotification
                 object:nil];
        
        [fileHandle acceptConnectionInBackgroundAndNotify];
    }
    return self;
}

- (void)dealloc
{
    [currentRequest release];
    [requests release];
    [connections release];
    [socketPort release];
    [fileHandle closeFile];
    [fileHandle release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


#pragma mark Managing connections

- (void) closeConnections 
{
	[fileHandle closeFile];
}

- (NSArray *)connections { return connections; }
- (void)newConnection:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSFileHandle *remoteFileHandle = [userInfo objectForKey:NSFileHandleNotificationFileHandleItem];
    NSNumber *errorNo = [userInfo objectForKey:@"NSFileHandleError"];
    if( errorNo ) {
        NSLog(@"NSFileHandle Error: %@\n", errorNo);
        return;
    }

    [fileHandle acceptConnectionInBackgroundAndNotify];

    if( remoteFileHandle ) {
        SimpleHTTPConnection *connection = [[SimpleHTTPConnection alloc] initWithFileHandle:remoteFileHandle delegate:self];
        if( connection ) {
            NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndex:[connections count]];
            [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:insertedIndexes forKey:@"connections"];
            [connections addObject:connection];
            [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:insertedIndexes forKey:@"connections"];
            [connection release];
        }
    }
}

- (void)closeConnection:(SimpleHTTPConnection *)connection;
{
    unsigned connectionIndex = [connections indexOfObjectIdenticalTo:connection];
    if( connectionIndex == NSNotFound ) return;

    // We remove all pending requests pertaining to connection
    NSMutableIndexSet *obsoleteRequests = [NSMutableIndexSet indexSet];
    BOOL stopProcessing = NO;
    int k;
    for( k = 0; k < [requests count]; k++) {
        NSDictionary *request = [requests objectAtIndex:k];
        if( [request objectForKey:@"connection"] == connection ) {
            if( request == [self currentRequest] ) stopProcessing = YES;
            [obsoleteRequests addIndex:k];
        }
    }
    
    NSIndexSet *connectionIndexSet = [NSIndexSet indexSetWithIndex:connectionIndex];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:obsoleteRequests forKey:@"requests"];
    [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:connectionIndexSet forKey:@"connections"];
    [requests removeObjectsAtIndexes:obsoleteRequests];
    [connections removeObjectsAtIndexes:connectionIndexSet];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:connectionIndexSet forKey:@"connections"];
    [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:obsoleteRequests forKey:@"requests"];
    
    if( stopProcessing ) {
        [self setCurrentRequest:nil];
    }
    [self processNextRequestIfNecessary];
}


#pragma mark Managing requests
- (unsigned) port
{
	return port;
}

- (NSArray*) requests { return requests; }

- (void) newRequestWithURL:(NSURL *)url connection:(SimpleHTTPConnection *)connection
{
    if( url == nil ) return;
    
    NSDictionary *request = [NSDictionary dictionaryWithObjectsAndKeys:
        url, @"url",
        connection, @"connection",
        [NSCalendarDate date], @"date", nil];
    
    NSIndexSet *insertedIndexes = [NSIndexSet indexSetWithIndex:[requests count]];
    [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:insertedIndexes forKey:@"requests"];
    [requests addObject:request];
    [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:insertedIndexes forKey:@"requests"];
    
    [self performSelector:@selector(processNextRequestIfNecessary) withObject:nil afterDelay:.1];
}

- (void)processNextRequestIfNecessary
{
    if( [self currentRequest] == nil && [requests count] > 0 ) {
        [self setCurrentRequest:[requests objectAtIndex:0]];
        [delegate processURL:[currentRequest objectForKey:@"url"]
                  connection:[currentRequest objectForKey:@"connection"]];
    }
}

- (void)setCurrentRequest:(NSDictionary *)value
{
    [currentRequest autorelease];
    currentRequest = [value retain];
}
- (NSDictionary *)currentRequest { return currentRequest; }


#pragma mark Sending replies

// The Content-Length header field will be automatically added
- (void)replyWithStatusCode:(int)code
                    headers:(NSDictionary*) headers
                       body:(NSData*) body
{
    CFHTTPMessageRef msg;
    msg = CFHTTPMessageCreateResponse(kCFAllocatorDefault,
                                      code,
                                      NULL, // Use standard status description 
                                      kCFHTTPVersion1_1);

    NSEnumerator *keys = [headers keyEnumerator];
    NSString *key;
    while( key = [keys nextObject] ) {
        id value = [headers objectForKey:key];
        if( ![value isKindOfClass:[NSString class]] ) value = [value description];
        if( ![key isKindOfClass:[NSString class]] ) key = [key description];
        CFHTTPMessageSetHeaderFieldValue(msg, (CFStringRef)key, (CFStringRef)value);
    }

    if( body ) {
        NSString *length = [NSString stringWithFormat:@"%d", [body length]];
        CFHTTPMessageSetHeaderFieldValue(msg,
                                         (CFStringRef)@"Content-Length",
                                         (CFStringRef)length);
        CFHTTPMessageSetBody(msg, (CFDataRef)body);
    }
    
    CFDataRef msgData = CFHTTPMessageCopySerializedMessage(msg);
    @try {
        NSFileHandle *remoteFileHandle = [[[self currentRequest] objectForKey:@"connection"] fileHandle];
        [remoteFileHandle writeData:(NSData *)msgData];
    }
    @catch (NSException *exception) {
        NSLog(@"Error while sending response (%@): %@\n", [[self currentRequest] objectForKey:@"url"], [exception  reason]);
    }
    
    CFRelease(msgData);
    CFRelease(msg);
    
    // A reply indicates that the current request has been completed
    // (either successfully of by responding with an error message)
    // Hence we need to remove the current request:
    unsigned index = [requests indexOfObjectIdenticalTo:[self currentRequest]];
    if( index != NSNotFound ) {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:index];
        [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"requests"];
        [requests removeObjectsAtIndexes:indexSet];
        [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexSet forKey:@"requests"];
    }
    [self setCurrentRequest:nil];
    [self processNextRequestIfNecessary];
}

- (void)replyWithData:(NSData *)data MIMEType:(NSString *)type
{
    NSDictionary *headers = [NSDictionary dictionaryWithObject:type forKey:@"Content-Type"];
    [self replyWithStatusCode:200 headers:headers body:data];  // 200 = 'OK'
}

- (void)replyWithStatusCode:(int)code message:(NSString *)message
{
    NSData *body = [message dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    [self replyWithStatusCode:code headers:nil body:body];
}

@end
