//
//  ORInFluxDBModel.m
//  Orca
//
//  Created by Mark Howe on 12/7/2022.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#import "ORInFluxDBModel.h"
#import "ORInFluxDB.h"
#import "MemoryWatcher.h"
#import "NSNotifications+Extensions.h"
#import "Utilities.h"
#import "ORRunModel.h"
#import "ORStatusController.h"
#import "ORProcessModel.h"
#import "ORProcessElementModel.h"
#import <sys/socket.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

NSString* ORInFluxDBPasswordChanged				  = @"ORInFluxDBPasswordChanged";
NSString* ORInFluxDBPortNumberChanged              = @"ORInFluxDBPortNumberChanged";
NSString* ORInFluxDBUserNameChanged				  = @"ORInFluxDBUserNameChanged";
NSString* ORInFluxDBRemoteHostNameChanged		  = @"ORInFluxDBRemoteHostNameChanged";
NSString* ORInFluxDBModelDBInfoChanged			  = @"ORInFluxDBModelDBInfoChanged";
NSString* ORInFluxDBLock							  = @"ORInFluxDBLock";
NSString* ORInFluxDBLocalHostNameChanged           = @"ORInFluxDBLocalHostNameChanged";

#define kInFluxDBPort            5984

static NSString* ORInFluxDBModelInConnector 	= @"ORInFluxDBModelInConnector";

@interface ORInFluxDBModel (private)
@end

@implementation ORInFluxDBModel

#pragma mark ***Initialization

- (id) init
{
    self = [super init];
    [self setPortNumber:kInFluxDBPort];
    return self;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [password       release];
    [userName       release];
    [localHostName  release];
    [remoteHostName release];
    [thisHostAdress   release];

	[super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
        //[self createDatabases];
        [self _startAllPeriodicOperations];
        [self registerNotificationObservers];
    }
    [super wakeUp];
}


- (void) sleep
{
    [self _cancelAllPeriodicOperations];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super sleep];
}

- (BOOL) solitaryObject
{
    return YES;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"InFluxDB"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORInFluxDBController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORInFluxDBModelInConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
	[ aConnector setConnectorType: 'DB I' ];
	[ aConnector addRestrictedConnectionType: 'DB O' ]; //can only connect to DB outputs
	
    [aConnector release];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
	[notifyCenter removeObserver:self];
	
    [notifyCenter addObserver : self
                     selector : @selector(applicationIsTerminating:)
                         name : @"ORAppTerminating"
                       object : (ORAppDelegate*)[NSApp delegate]];

    [notifyCenter addObserver : self
					 selector : @selector(addObjectValueRecord:)
						 name : @"ORInFluxDBAddObjectRecord"
					   object : nil];
}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[ORInFluxDBQueue sharedInFluxDBQueue] cancelAllOperations];
 }

- (void) awakeAfterDocumentLoaded
{
}

#pragma mark ***Accessors


- (id) nextObject
{
	return [self objectConnectedTo:ORInFluxDBModelInConnector];
}

- (NSString*) password
{
    return password;
}

- (void) setPassword:(NSString*)aPassword
{
	if(aPassword){
		[[[self undoManager] prepareWithInvocationTarget:self] setPassword:password];
		
		[password autorelease];
		password = ([aPassword length] == 0) ? nil : [aPassword copy];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBPasswordChanged object:self];
	}
}

- (NSUInteger) portNumber
{
    return portNumber;
}

- (void) setPortNumber:(NSUInteger)aPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortNumber:portNumber];
    if(aPort == 0)aPort = 5984;
    
    portNumber = aPort;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBPortNumberChanged object:self];
}

- (NSString*) userName
{
    return userName;
}

- (void) setUserName:(NSString*)aUserName
{
	if(aUserName){
		[[[self undoManager] prepareWithInvocationTarget:self] setUserName:userName];
		
		[userName autorelease];
		userName = ([aUserName length] == 0) ? nil : [aUserName copy];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBUserNameChanged object:self];
	}
}

- (NSString*) remoteHostName
{
    return remoteHostName;
}

- (void) setRemoteHostName:(NSString*)aHostName
{
	if(aHostName){
		[[[self undoManager] prepareWithInvocationTarget:self] setRemoteHostName:remoteHostName];
		
		[remoteHostName autorelease];
		remoteHostName = [aHostName copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBRemoteHostNameChanged object:self];
	}
}

- (NSString*) localHostName
{
    return localHostName;
}

- (void) setLocalHostName:(NSString*)aHostName
{
	if(aHostName){
		[[[self undoManager] prepareWithInvocationTarget:self] setLocalHostName:localHostName];
		
		[localHostName autorelease];
		localHostName = [aHostName copy];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBLocalHostNameChanged object:self];
	}
}

- (NSString*) databaseName
{		
	return [self machineName];
}


- (NSString*) machineName
{		
	NSString* machineName = [NSString stringWithFormat:@"%@",computerName()];
	machineName = [machineName stringByReplacingOccurrencesOfString:@" " withString:@"_"];
	return [machineName lowercaseString];
}

- (ORInFluxDB*) remoteDBRef
{
    return [self remoteDBRef:[self databaseName]];

}
- (ORInFluxDB*) remoteDBRef:(NSString*)aDatabaseName
{
    if([remoteHostName length]==0)return nil;
    else return nil;
	//else return [ORInFluxDB inFluxHost:remoteHostName port:portNumber username:userName pwd:password database:aDatabaseName delegate:self];
}

- (void) addObjectValueRecord:(NSNotification*)aNote
{
}

- (void) _cancelAllPeriodicOperations
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) _startAllPeriodicOperations
{
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{    
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setPassword:      [decoder decodeObjectForKey: @"Password"]];
    [self setLocalHostName: [decoder decodeObjectForKey: @"LocalHostName"]];
    [self setUserName:      [decoder decodeObjectForKey: @"UserName"]];
    [self setRemoteHostName:[decoder decodeObjectForKey: @"RemoteHostName"]];
    [self setPortNumber:    [decoder decodeIntegerForKey:@"PortNumber"]];
    [[self undoManager] enableUndoRegistration];
	[self registerNotificationObservers];
   return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:password              forKey:@"Password"];
    [encoder encodeInteger:portNumber           forKey:@"PortNumber"];
    [encoder encodeObject:userName              forKey:@"UserName"];
    [encoder encodeObject:localHostName         forKey:@"LocalHostName"];
    [encoder encodeObject:remoteHostName        forKey:@"RemoteHostName"];

}
@end

