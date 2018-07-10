//
//  ORDbService.h
//  Orca
//
//  Created by Mark Howe on 10/3/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SqlServing.h"

@interface ORDbService : NSObject <SqlUsing>{
    id				proxy;
	id				delegate;
	NSString*		fullConnectionName;
	NSSocketPort*	sendPort;
	NSConnection*	connection;
}

- (id) initWithService:(NSNetService*)aService;
- (void) dealloc;
- (void) setDelegate:(id)aDelegate;
- (void) setFullConnectionName:(NSString*)fullName;
- (void) connect:(NSData*)anAddress;
- (void) disconnect;

- (bycopy NSString*) name;
- (BOOL) stillThere;

@end

@interface NSObject (ORDbService)
- (void) serviceWasDropped:(ORDbService*)aService;
- (void) dbServiceDidDisconnect:(ORDbService*)aService;
@end