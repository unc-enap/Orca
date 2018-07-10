//
//  SimpleHTTPConnection.m
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

#import "SimpleHTTPConnection.h"
#import "SimpleHTTPServer.h"
#import <netinet/in.h>      // for sockaddr_in
#import <arpa/inet.h>       // for inet_ntoa


@implementation SimpleHTTPConnection

- (id)initWithFileHandle:(NSFileHandle *)fh delegate:(id)dl
{
    if( self = [super init] ) {
        fileHandle = [fh retain];
        delegate = dl;
        isMessageComplete = YES;
        message = NULL;

        // Get IP address of remote client
        CFSocketRef socket;
        socket = CFSocketCreateWithNative(kCFAllocatorDefault,
                                          [fileHandle fileDescriptor],
                                          kCFSocketNoCallBack, NULL, NULL);
        CFDataRef addrData = CFSocketCopyPeerAddress(socket);
        CFRelease(socket);
        if( addrData ) {
            struct sockaddr_in *sock = (struct sockaddr_in *)CFDataGetBytePtr(addrData);
            char *naddr = inet_ntoa(sock->sin_addr);
            [self setAddress:[NSString stringWithCString:naddr]];
            CFRelease(addrData);
        } 
		else {
            [self setAddress:@"NULL"];
        }

        // Register for notification when data arrives
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(dataReceivedNotification:)
                   name:NSFileHandleReadCompletionNotification
                 object:fileHandle];
        [fileHandle readInBackgroundAndNotify];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if( message ) CFRelease(message);
    [fileHandle release];
    [super dealloc];
}

- (NSFileHandle *)fileHandle { return fileHandle; }

- (void)setAddress:(NSString *)value
{
    [address release];
    address = [value copy];
}
- (NSString *)address { return address; }


- (void)dataReceivedNotification:(NSNotification *)notification
{
    NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    
    if ( [data length] == 0 ) {
        // NSFileHandle's way of telling us that the client closed the connection
        [delegate closeConnection:self];
    } else {
        [fileHandle readInBackgroundAndNotify];
        
        if( isMessageComplete ) {
            message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, TRUE);
        }
        Boolean success = CFHTTPMessageAppendBytes(message,
                                                   [data bytes],
                                                   [data length]);
        if( success ) {
            if( CFHTTPMessageIsHeaderComplete(message) ) {
                isMessageComplete = YES;
                CFURLRef url = CFHTTPMessageCopyRequestURL(message);
                [delegate newRequestWithURL:(NSURL *)url connection:self];
                CFRelease(url);
                CFRelease(message);
                message = NULL;
            } else {
                isMessageComplete = NO;
            }
        } else {
            NSLog(@"Incomming message not a HTTP header, ignored.\n");
            [delegate closeConnection:self];
        }
    }
}

@end
