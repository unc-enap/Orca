//
//  SessionDB.m
//  Orca
//
//  Created by Andy Mastbaum on Mon Nov 20, 2017.
//

#pragma mark ¥¥¥Imported Files

#import "ORPQModel.h"
#import "SNOPModel.h"
#import "SessionDB.h"
#import "ORPQConnection.h"
#import "ORPQResult.h"
#include <stdint.h>
#include <unistd.h>

@implementation SessionDB

@synthesize
username = _username,
password = _password,
dbname = _dbname,
address = _address,
port = _port,
lockID = _lockID,
ignoreSessionDB = _ignoreSessionDB,
sessionKey = _sessionKey;

#pragma mark ¥¥¥Initialization

/** Default initialization. */
- (id) init
{
    self = [super init];
    [self registerNotificationObservers];
    return self;
}

- (void) dealloc
{
    [connection disconnect];

    [_username release];
    [_password release];
    [_dbname release];
    [_address release];
    [_sessionKey release];

    [super dealloc];
}

/** Register notification listeners. */
- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(orcaAboutToQuit:)
                         name : OROrcaAboutToQuitNotice
                       object : nil];
}

/** Handle OROrcaAboutToQuitNotice notifications. */
- (void) orcaAboutToQuit: (NSNotification*) aNote
{
    [self postSessionEnd];
}

/** Initialize the connection to the session/locking database. */
- (bool) connect
{
    ORPQConnection* conn = connection;

    if (!conn) {
        conn = [[ORPQConnection alloc] init];
    }

    if (conn && (![conn isConnected] || ![conn checkConnection])) {
        [conn disconnect];
        NSString* host = [NSString stringWithFormat:@"%@:%u", [self address], [self port]];
        [conn connectToHost : host
                   userName : [self username]
                   passWord : [self password]
                   dataBase : [self dbname]];
    }

    connection = conn;

    return conn && [conn isConnected] && [conn checkConnection];
}

/** Start a new session. */
- (void) startSession
{
    /* Check that Orca is the latest version. This will either block or quit. */
    [self checkOrcaVersion];

    /* Check that no other Orca is controlling the detector, using a database lock. This will either block or quit. */
    [self checkLock:true];

    /* Post information about this Orca session the database. */
    [self postSessionStart];

    /* A timer to check the lock every 10 seconds, to make sure we still have it. */
    [NSTimer scheduledTimerWithTimeInterval:10.0
                                     target:self
                                   selector:@selector(timerCheckLock:)
                                   userInfo:nil
                                    repeats:YES];
}


#pragma mark ¥¥¥Exclusive Locks

/** Try to obtain an exclusive advisory lock. */
- (bool) acquireLock : (bool) connect
{
    NSNumber* gotLock = [NSNumber numberWithBool:false];

    if ([self ignoreSessionDB]) {
        return true;
    }

    bool connected = [self connect];

    /* Try to get the lock. */
    if (connected) {
        @try {
            ORPQResult* result = [connection queryString:[NSString stringWithFormat:@"select pg_try_advisory_lock(%i);", [self lockID]]];
            gotLock = [[result fetchRowAsType:MCPTypeDictionary row:0] valueForKey:@"pg_try_advisory_lock"];
        }
        @catch (NSException* e) {
            NSLogColor([NSColor redColor], @"Unable to obtain database lock: \"%@\"\n", e.reason);
        }

        if (![gotLock boolValue]) {
            NSLogColor([NSColor redColor], @"Unable to obtain database lock: %@ on %@:%u/%@ ID %u\n",
                       _username, _address, _port, _dbname, _lockID);
        }
    }
    else {
        NSLogColor([NSColor redColor], @"Unable to obtain database lock: DB not connected.\n");
    }

    return [gotLock boolValue];
}

/**
 * Try to obtain the database lock, and block with a modal dialog if we can't.
 * If connect is YES, attempt to connect to the session DB first.
 */
- (void) checkLock : (bool) connect
{
    /* If the session database is not set up, disable locking. */
    if (![self address] || [[self address] isEqualToString:@""]) {
        NSLog(@"Orca session database address not set, disabling locking.\n");
        [self setIgnoreSessionDB:YES];
    }

    /* Try to acquire the lock. If we get it, proceed with initialization. */
    if ([self ignoreSessionDB] || [self acquireLock:connect]) {
        return;
    }

    /* We don't have the lock. Open a modal dialog asking whether to quit Orca, retry immediately, or ignore the lock. */
    [(ORAppDelegate*)[NSApp delegate] closeSplashWindow];

    NSAlert* alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Quit Orca"];
    [alert addButtonWithTitle:@"Retry Now"];
    [alert addButtonWithTitle:@"Ignore Locking"];
    [alert setInformativeText:@"Unable to obtain exclusive lock. (Is another copy of Orca running?)\n\nWaiting to acquire lock..."];
    [alert setAlertStyle:NSWarningAlertStyle];

    /* A timer to check the lock every 5 seconds, and close the window/proceed if we can obtain it. */
    NSTimer* dbModalTimer = [NSTimer scheduledTimerWithTimeInterval : 5
                                                             target : self
                                                           selector : @selector(timerCheckLockModal:)
                                                           userInfo : nil
                                                            repeats : YES];

    [[NSRunLoop currentRunLoop] addTimer:dbModalTimer forMode:NSModalPanelRunLoopMode];

    /* Launch the modal. */
    [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    int modalAction = [alert runModal];

    if (modalAction == NSAlertFirstButtonReturn) {  // Quit Orca
        ORAppDelegate* delegate = [NSApp delegate];
        [alert release];
        [delegate terminate:self];
    }
    else if (modalAction == NSAlertSecondButtonReturn) {  // Retry Now
        [alert release];
        [self checkLock:true];
    }
    else if (modalAction == NSAlertThirdButtonReturn) {  // Ignore Locking
        [alert release];
        [self setIgnoreSessionDB:YES];
    }
    else {
        [alert release];
    }

    [dbModalTimer invalidate];
}

/** Try again to acquire the database lock. If we get it, close the modal and loading can proceed. */
- (void) timerCheckLockModal: (NSTimer*) timer
{
    if ([self acquireLock:true]) {
        [NSApp abortModal];
    }
}

/* Check the DB lock periodically to see if we still have it. */
- (void) timerCheckLock: (NSTimer*) timer
{
    /* Check that we still have the DB lock. */
    [self checkLock:false];
}


#pragma mark ¥¥¥Session Logging

/** Post some system information to the session DB. */
- (void) postSessionStart
{
    bool connected = [self connect];

    if (!connected) {
        NSLogColor([NSColor redColor], @"Unable to post session start to DB: DB not connected.\n");
        return;
    }

    char hostname[255];
    gethostname(hostname, 255);
    NSString* osxVersion = [[NSProcessInfo processInfo] operatingSystemVersionString];

    NSNumber* key = nil;
    NSString* query = [NSString stringWithFormat:@"insert into orca_sessions (orca_version, hostname, osx_version) values ('%s', '%s', '%@') returning key", SNOP_ORCA_VERSION, hostname, osxVersion];

    @try {
        ORPQResult* result = [connection queryString:query];
        key = [[result fetchRowAsType:MCPTypeDictionary row:0] valueForKey:@"key"];
        NSLog(@"Session: hostname: %s, orca: %s, os: %@, key: %@\n",
              hostname, SNOP_ORCA_VERSION, osxVersion, key);
    }
    @catch (NSException* e) {
        NSLogColor([NSColor redColor], @"Error posting session start to DB: \"%@\"\n", e.reason);
    }

    [self setSessionKey:[key copy]];
}


/** Before Orca quits, post the end timestamp to the session database. */
- (void) postSessionEnd
{
    bool connected = [self connect];

    if (!connected) {
        NSLogColor([NSColor redColor], @"Unable to post session end to DB: DB not connected.\n");
        return;
    }

    if ([self sessionKey]) {
        NSString* query = [NSString stringWithFormat:@"update orca_sessions set end_timestamp = now() where key = %@", [self sessionKey]];
        @try {
            [connection queryString:query];
        }
        @catch (NSException* e) {
            NSLogColor([NSColor redColor], @"Error posting session end to DB: \"%@\"\n", e.reason);
        }
    }
}


#pragma mark ¥¥¥Orca Version

/** Check that the Orca version is up to date. */
- (void) checkOrcaVersion
{
    /* If the session database is not set up, give up. */
    if (![self address] || [[self address] isEqualToString:@""]) {
        NSLog(@"Orca session database address not set, disabling version checking.\n");
        return;
    }

    bool connected = [self connect];
    NSString* version;

    /* Try to get the current version. */
    if (connected) {
        @try {
            ORPQResult* result = [connection queryString:@"select version from orca_versions order by timestamp desc limit 1;"];
            version = [[result fetchRowAsType:MCPTypeDictionary row:0] valueForKey:@"version"];
        }
        @catch (NSException* e) {
            NSLogColor([NSColor redColor], @"Warning! Unable to obtain Orca version from database: \"%@\"\n", e.reason);
            return;
        }
    }
    else {
        NSLogColor([NSColor redColor], @"Warning! Unable to obtain Orca version from database: DB not connected.\n");
        return;
    }

    // Compare the current and DB version strings
    if ([version isEqualToString:[NSString stringWithFormat:@"%s", SNOP_ORCA_VERSION]]) {
        // Versions match
        return;
    }

    // Versions do not match, alert the user
    [(ORAppDelegate*)[NSApp delegate] closeSplashWindow];

    NSString* text = [NSString stringWithFormat:@"This Orca version (%s) does not match the production version (%@)", SNOP_ORCA_VERSION, version];
    NSAlert* alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"Quit Orca"];
    [alert addButtonWithTitle:@"Start Anyway"];
    [alert setInformativeText:text];
    [alert setAlertStyle:NSWarningAlertStyle];

    /* Launch the modal. */
    [[NSRunningApplication currentApplication] activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    int modalAction = [alert runModal];

    if (modalAction == NSAlertFirstButtonReturn) {  // Quit Orca
        [alert release];
        [(ORAppDelegate*)[NSApp delegate] terminate:self];
    }
    else if (modalAction == NSAlertSecondButtonReturn) {  // Start Anyway
        [alert release];
    }
    else {
        [alert release];
    }
}

@end
