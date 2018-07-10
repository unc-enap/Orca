//
//  ORDbService.m
//  Orca
//
//  Created by Mark Howe on 10/3/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "ORDbService.h"
#import "StatusLog.h"
#import <sys/socket.h>


@implementation ORDbService
- (id) initWithService:(NSNetService*)aService
{
	[super init];
	[self setFullConnectionName:[NSString stringWithFormat:@"%@: %@",[aService name],[[NSHost currentHost] name]]];
	[self connect:[[aService addresses] objectAtIndex:0]];
	return self;
}

- (void) dealloc
{
	NSLog(@"dbService dealloc\n");
	[self disconnect];
	[super dealloc];
}

- (void) setDelegate:(id)aDelegate
{
	delegate = aDelegate;
}

- (bycopy NSString*) name
{
	return fullConnectionName;
}

- (BOOL) stillThere
{
	return YES;
}

- (void) setFullConnectionName:(NSString*)fullName
{
	[fullConnectionName release];
	fullConnectionName = [fullName retain];
}


- (int) subscriberCount
{
	return 0;
}

- (void) connect:(NSData*)anAddress
{
	if(anAddress) {

		// Create the send port
		sendPort = [[NSSocketPort alloc] initRemoteWithProtocolFamily:AF_INET 
														   socketType:SOCK_STREAM 
															 protocol:INET_TCP 
															  address:anAddress];
		
		if(!sendPort){
			NSLog(@"sendPort == 0\n");
		}
		// Create an NSConnection
		connection = [[NSConnection connectionWithReceivePort:nil sendPort:sendPort] retain];
		[sendPort release];
		sendPort = nil;		
		// Set timeouts to something reasonable
		[connection setRequestTimeout:4.0];
		[connection setReplyTimeout:4.0];

		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(connectionDied:) 
													 name:NSConnectionDidDieNotification 
												   object:connection];

		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(portInvalid:) 
													 name:NSPortDidBecomeInvalidNotification 
												   object:sendPort];

		NS_DURING
			// Get the proxy
			proxy = [[connection rootProxy] retain];

			// By telling the proxy about the protocol for the object 
			// it represents, we significantly reduce the network 
			// traffic involved in each invocation
			[proxy setProtocolForProxy:@protocol(SqlServing)];

			BOOL successful = [proxy registerClient:self];
			if (successful) {
				NSLog(@"Connected\n");
			} 
			else {
				NSLog(@"Host already connected\n");
				[self disconnect];
			}
		NS_HANDLER
			// If the server does not respond in 10 seconds,  
			// this handler will get called
			NSLog(@"Unable to connect:\n %@\n",connection);
			[self disconnect];
			[localException raise];
		NS_ENDHANDLER


	}
}

- (void) connectionDied:(NSNotification *)aNotification
{
	[self disconnect];	
}

- (void) portInvalid:(NSNotification *)aNotification
{
	[self disconnect];	
}


- (void) disconnect
{
	NSLog(@"Disconnected\n");
	NS_DURING
		[proxy unregisterClient:self];
	NS_HANDLER
	NS_ENDHANDLER
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[connection invalidate];
	[connection release];
	connection = nil;

	//[sendPort invalidate];
	//[sendPort release];
	//sendPort = nil;

    [proxy release];
    proxy = nil;
	
	if([delegate respondsToSelector:@selector(dbServiceDidDisconnect:)]){
		[delegate dbServiceDidDisconnect:self];
	}

}

@end
