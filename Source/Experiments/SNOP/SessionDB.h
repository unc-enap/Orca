//
//  SessionDB.h
//  Orca
//
//  Created by Andy Mastbaum on Mon Nov 20, 2017.
//
//  Class that handles connections to the SNO+ Orca session database. This
//  database is used for locking that prevents multiple copies of Orca from
//  controlling the detector at once, logging information about the current
//  Orca session to a DB, and checking the Orca version against the current
//  production version.
//

#import <Foundation/Foundation.h>
#import <stdint.h>

@class ORPQConnection;

@interface SessionDB : NSObject {

@private
    NSString* _username;
    NSString* _password;
    NSString* _dbname;
    NSString* _address;
    unsigned int _port;
    unsigned int _lockID;

    ORPQConnection* connection;

    BOOL _ignoreSessionDB;
    NSNumber* _sessionKey;
}

- (id) init;
- (void) dealloc;
- (void) registerNotificationObservers;
- (void) startSession;
- (void) orcaAboutToQuit: (NSNotification*) aNote;
- (bool) connect;
- (void) postSessionStart;
- (void) postSessionEnd;
- (bool) acquireLock : (bool) connect;
- (void) checkLock : (bool) connect;
- (void) timerCheckLockModal : (NSTimer*) timer;
- (void) timerCheckLock : (NSTimer*) timer;
- (void) checkOrcaVersion;

@property (nonatomic,copy) NSString* username;
@property (nonatomic,copy) NSString* password;
@property (nonatomic,copy) NSString* dbname;
@property (nonatomic,copy) NSString* address;
@property (nonatomic,assign) unsigned int port;
@property (nonatomic,assign) unsigned int lockID;

@property (nonatomic,assign) BOOL ignoreSessionDB;
@property (nonatomic,copy) NSNumber* sessionKey;

@end
