//
//  ORSqlConnection.m
//  ORSqlConnection
//
//  Created by Mark Howe on 9/26/06.
//  Copyright 2006 CENPA,University of Washington. All rights reserved.
//

#import "ORSqlConnection.h"
#import "StatusLog.h"
#import <sys/socket.h>

@interface ORSqlConnection (private)
- (void) connect;
@end

NSString* ORSqlConnectionChanged = @"ORSqlConnectionChanged";

@implementation ORSqlConnection

#pragma mark ¥¥¥Initialization

- (id) initWithName:(NSString*)aName
{
	[super init];
	[self setConnectionName:aName];	
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(applicationIsQuiting:)
                         name : @"ORAppTerminating"
                       object : nil];

	return self;
}


- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cleanup];
	[address release];
	[connectionName release];
	[fullConnectionName release];
    [super dealloc];
}

- (void) cleanup
{
    NSConnection *connection = [proxy connectionForProxy];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [connection invalidate];
    [proxy release];
    proxy = nil;
	[self setDbConnected:NO];
}

#pragma mark ¥¥¥Accessors

- (void) setDbConnected:(BOOL)aState
{
	dbConnected = aState;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORSqlConnectionChanged object:self];
}

- (BOOL) dbConnected
{
	return dbConnected;
}

- (void) setConnectionName:(NSString*)aName
{
    [connectionName autorelease];
    connectionName = [aName copy];
	
	[fullConnectionName release];
	fullConnectionName = [[NSString stringWithFormat:@"%@: %@",connectionName,[[NSHost currentHost] name]] retain];
}

- (void) setAddress:(NSData *)s
{
    [s retain];
    [address release];
    address = s;
}


- (BOOL) subscriptionStartedTo:(NSNetService*)aService
{
	BOOL result = YES;
	NS_DURING
		NSArray* addresses = [aService addresses];
		if([addresses count]) {
			// Just take the first address
			[self setAddress:[addresses objectAtIndex:0]];
	
			// Connect to selected server
			[self connect];
		}
	NS_HANDLER
		result = NO;
	NS_ENDHANDLER
	
	return result;
}

- (void) subscriptionEnded
{
    NS_DURING
        [proxy unsubscribeClient:self];
        NSLog(@"Unsubscribed\n");
        [self cleanup];
    NS_HANDLER
        NSLog(@"Error unsubscribing\n");
    NS_ENDHANDLER
}

- (BOOL) connect:(NSString*)dataBase user:(NSString*)userName passWord:(NSString*)passWord
{
	[self setDbConnected:[proxy connect:fullConnectionName 
									 to:dataBase 
								   user:userName 
							   password:passWord]];
	return dbConnected;
}

- (void) disconnect
{
	[proxy disconnect:fullConnectionName];
	[self setDbConnected:NO];
}

- (void) connect
{
	[self setAddress:address];

    // Create the send port
    NSSocketPort* sendPort = [[NSSocketPort alloc]
		   initRemoteWithProtocolFamily:AF_INET 
		   socketType:SOCK_STREAM 
		   protocol:INET_TCP 
		   address:address];

    // Create an NSConnection
    NSConnection* connection = [NSConnection connectionWithReceivePort:nil 
                                                sendPort:sendPort];
    
    // Set timeouts to something reasonable
    [connection setRequestTimeout:10.0];
    [connection setReplyTimeout:10.0];

    // The send port is retained by the connection
    [sendPort release];
           
    NS_DURING
        // Get the proxy
        proxy = [[connection rootProxy] retain];

        // Get informed when the connection fails
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                 selector:@selector(connectionDown:) 
                                     name:NSConnectionDidDieNotification 
                                   object:connection];

        // By telling the proxy about the protocol for the object 
        // it represents, we significantly reduce the network 
        // traffic involved in each invocation
        [proxy setProtocolForProxy:@protocol(SqlServing)];

        // Try to subscribe with chosen nickname
        BOOL successful = [proxy subscribeClient:self];
        if (successful) {
            NSLog(@"Connected\n");
        } else {
            NSLog(@"Host already connected\n");
            [self cleanup];
        }
    NS_HANDLER
        // If the server does not respond in 10 seconds,  
        // this handler will get called
        NSLog(@"Unable to connect\n");
        [self cleanup];
		[localException raise];
    NS_ENDHANDLER
}

- (void) sendMessage:(NSString*)aCommand
{
	if(!dbConnected){
		[proxy client:fullConnectionName execute:aCommand];
	}
}

- (void) setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}

#pragma mark ¥¥¥SqlUsing Protocol
- (bycopy NSString *)name
{
    return fullConnectionName;
}

#pragma mark ¥¥¥Delegate Methods
- (void) applicationIsQuiting:(NSNotification*)aNote
{
    NSLog(@"invalidating connection\n");
	[self subscriptionEnded];
}
@end


