//
//  SimpleHTTPServer.h
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

@class SimpleHTTPConnection;

@interface SimpleHTTPServer : NSObject {
    unsigned		port;
    id				delegate;

    NSSocketPort*	socketPort;
    NSFileHandle*	fileHandle;
    NSMutableArray*	connections;
    NSMutableArray*	requests;    
    NSDictionary*	currentRequest;
}

- (id) initWithTCPPort:(unsigned)po delegate:(id)dl;

- (NSArray*) connections;
- (NSArray*) requests;
- (unsigned) port;
- (void) closeConnection:(SimpleHTTPConnection *)connection;
- (void) newRequestWithURL:(NSURL *)url connection:(SimpleHTTPConnection *)connection;

// Request currently being processed
// Note: this need not be the most recently received request
- (NSDictionary*) currentRequest;

- (void) replyWithStatusCode:(int)code
                    headers:(NSDictionary *)headers
                       body:(NSData *)body;
- (void) replyWithData:(NSData *)data MIMEType:(NSString *)type;
- (void) replyWithStatusCode:(int)code message:(NSString *)message;

@end
