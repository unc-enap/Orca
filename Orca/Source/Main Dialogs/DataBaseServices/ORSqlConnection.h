//
//  ORSqlConnection.h
//  ORSqlConnection
//
//  Created by Mark Howe on 9/26/06.
//  Copyright 2006 CENPA,University of Washington. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SqlServing.h"


@interface ORSqlConnection : NSObject <SqlUsing> {
    id					 proxy;
    NSData*				 address;
	NSString*			 connectionName;
	NSString*			 fullConnectionName;
	BOOL				 dbConnected;
	id					 delegate;
}


#pragma mark ¥¥¥Initialization
- (id) initWithName:(NSString*)aName;
- (void) dealloc;
- (void) cleanup;

#pragma mark ¥¥¥Accessors
- (void) setConnectionName:(NSString*)aName;
- (void) setAddress:(NSData *)s;
- (void) setDbConnected:(BOOL)aState;
- (BOOL) dbConnected;
- (void) setDelegate:(id)aDelegate;

- (BOOL) connect:(NSString*)dataBase user:(NSString*)userName passWord:(NSString*)passWord;
- (void) disconnect;
- (void) sendMessage:(NSString*)aCommand;
- (BOOL) subscriptionStartedTo:(NSNetService*)aService;
- (void) subscriptionEnded;


#pragma mark ¥¥¥SqlUsing Protocol
- (bycopy NSString *)name;

#pragma mark ¥¥¥Notifications
- (void)connectionDown:(NSNotification *)aNote;
- (void) applicationIsQuiting:(NSNotification*)aNote;
@end

extern NSString* ORSqlConnectionChanged;

