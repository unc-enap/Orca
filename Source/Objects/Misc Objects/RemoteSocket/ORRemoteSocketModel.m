//
//  ORRemoteSocketModel.m
//  Orca
//
//  Created by Mark Howe on 10/18/06.
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

#import "ORRemoteSocketModel.h"
#import "NetSocket.h"
#import "ORRemoteCommander.h"

NSString* ORRSRemotePortChanged		 = @"ORRSRemotePortChanged";
NSString* ORRSRemoteHostChanged		 = @"ORRSRemoteHostChanged";
NSString* ORRemoteSocketLock		 = @"ORRemoteSocketLock";
NSString* ORRSRemoteConnectedChanged = @"ORRSRemoteConnectedChanged";
NSString* ORRemoteSocketQueueCountChanged = @"ORRemoteSocketQueueCountChanged";

@implementation ORRemoteSocketModel
#pragma mark ***Initialization

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    @try {
        [queue removeObserver:self forKeyPath:@"operationCount"];
    }
    @catch (NSException* e){
        
    }
	if(isConnected) {
		[self disconnect];
	}
    
    [queue cancelAllOperations];
    [queue release];
   
    [socket setDelegate:nil];
    [socket release];
    
    [remoteHost release];
	[responseDictionary release];
	[super dealloc];
}

- (void) wakeUp
{
    if([self aWake])return;
    [super wakeUp];
    [queue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
}

- (void) sleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [queue removeObserver:self forKeyPath:@"operationCount"];
    [queue cancelAllOperations];
    [super sleep];
}
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"RemoteSocket"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORRemoteSocketController"];
}


- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
	return [super acceptsGuardian:aGuardian] ||
            [aGuardian isMemberOfClass:NSClassFromString(@"MajoranaModel")] ||
            [aGuardian isMemberOfClass:NSClassFromString(@"ORSyncCenterModel")] ||
            [aGuardian isMemberOfClass:NSClassFromString(@"ORApcUpsModel")];
}

#pragma mark ***Accessors
- (void) setNewHost:(NSString*)newHost andPort:(int)newPort
{
	[self setRemoteHost:newHost];
	[self setRemotePort:newPort];
}

- (NSString*) remoteHost
{
	if(remoteHost)	return remoteHost;
	else			return @"";
}

- (void) setRemoteHost:(NSString *)newHost
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRemoteHost:remoteHost];
    
    [remoteHost autorelease];
    remoteHost = [newHost copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRSRemoteHostChanged object:self];
}

- (int) remotePort
{
	return remotePort;
}

- (void) setRemotePort:(int)newPort
{
    if(newPort==0)newPort = 4667;
    if(newPort == remotePort)return;
	if(isConnected) return;
	[[[self undoManager] prepareWithInvocationTarget:self] setRemotePort:remotePort];
	remotePort = newPort;
	[[NSNotificationCenter defaultCenter] postNotificationName:ORRSRemotePortChanged object:self];
}

- (BOOL) isConnected
{
	return isConnected;
}

- (void) setIsConnected:(BOOL)flag
{
	isConnected = flag;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRSRemoteConnectedChanged object:self];
}

- (int) connectionTimeout
{
	if(connectionTimeout < 1)return SCCDefaultConnectionTimeout;
	return connectionTimeout;
}

- (void) setConnectionTimeout:(int)newTimeout
{
	connectionTimeout = newTimeout;
}

- (NSStringEncoding) defaultStringEncoding
{
	if(defaultStringEncoding!=0)	return defaultStringEncoding;
	else							return NSASCIIStringEncoding;
}

- (void) setDefaultStringEncoding:(NSStringEncoding)encoding
{
	defaultStringEncoding = encoding;
}

- (NetSocket*) socket
{
    return socket;
}

- (void) setSocket:(NetSocket*)aSocket
{
    [aSocket retain];
    [socket release];
    socket = aSocket;
    [socket setDelegate:self];
}

#pragma mark Connecting
- (void) connect
{
    if(remoteHost && remotePort){
        [self setSocket:[NetSocket netsocketConnectedToHost:remoteHost port:remotePort]];
    }
}

- (void) disconnect
{
    [socket close];
    [self setIsConnected:[socket isConnected]];
}

#pragma mark Sending and Receiving
- (void) sendString:(NSString*)aString
{
    [self sendStrings:[NSArray arrayWithObjects:aString,nil]];
}

- (void) sendStrings:(NSArray*)cmdArray
{
    [self sendStrings:cmdArray delegate:nil];
}

- (void) sendStrings:(NSArray*)cmdArray delegate:(id)aDelegate
{
    if(!queue){
        queue = [[NSOperationQueue alloc] init];
        [queue setMaxConcurrentOperationCount:1]; //can only do one at a time
        [queue addObserver:self forKeyPath:@"operationCount" options:0 context:NULL];
    }
    [self setConnectionTimeout:5];
    if(![self isConnected])[self connect];

    ORResponseWaitOp* anOp = [[ORResponseWaitOp alloc] initWithRemoteObj:self commands:cmdArray delegate:aDelegate];
    [queue addOperation:anOp];
    [anOp release];

}

- (void) mainThreadSendString:(NSString*)aString
{
    if([NSThread isMainThread]){
        @synchronized(self){
            @try {
                [socket writeString:aString encoding:[self defaultStringEncoding]];
            }
            @catch (NSException* exception) {
            }
        }
    }
}
- (BOOL) queueEmpty
{
    return [queue operationCount]==0;
}
- (void) processMessage:(NSString*)message
{
    @synchronized(self){
        if(!responseDictionary)responseDictionary = [[NSMutableDictionary dictionary] retain];
        message = [[message trimSpacesFromEnds] removeNLandCRs];
        NSArray* parts = [message componentsSeparatedByString:@":"];
        if([parts count]==2){
            NSString* aKey   = [[parts objectAtIndex:0]trimSpacesFromEnds];
            NSString* aValue = [[parts objectAtIndex:1]trimSpacesFromEnds];
            if([aKey length]!=0 && [aValue length]!=0){
                [responseDictionary setObject:aValue forKey:aKey];
                
            }
        }
    }
}
- (BOOL) responseExistsForKey:(NSString*)aKey
{
    BOOL itExists = NO;
    @synchronized(self){
        itExists = [responseDictionary objectForKey:aKey]!=nil;
    }
	return itExists;
}

- (void) removeResponseForKey:(NSString*)aKey
{
    @synchronized(self){
        [responseDictionary removeObjectForKey:aKey];
    }
}
- (id) responseForKeyButDoNotRemove:(NSString*)aKey
{
    if(aKey){
        id theValue = nil;
        @synchronized(self){
            theValue =  [[[responseDictionary objectForKey:aKey] retain] autorelease];
        }
        return theValue;
    }
    else return nil;
}
- (id) responseForKey:(NSString*)aKey
{
	if(aKey){
        id theValue = nil;
        @synchronized(self){
            theValue =  [[[responseDictionary objectForKey:aKey] retain] autorelease];
            [responseDictionary removeObjectForKey:aKey];
        }
		return theValue;
	}
	else return nil;
}
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == queue && [keyPath isEqual:@"operationCount"]) {
        NSNumber* n = [NSNumber numberWithInteger:[[queue operations] count]];
        [self performSelectorOnMainThread:@selector(setQueueCount:) withObject:n waitUntilDone:NO];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void) setQueueCount:(NSNumber*)n
{
    queueCount = [n intValue];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRemoteSocketQueueCountChanged object:self];
}


- (int) queueCount
{
    return queueCount;
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{    
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setRemoteHost:[decoder decodeObjectForKey:@"remoteHost"]];
    [self setRemotePort:[decoder decodeIntForKey:@"remotePort"]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:remoteHost forKey:@"remoteHost"];
    [encoder encodeInteger:remotePort    forKey:@"remotePort"];
}

#pragma mark ***Delegate Methods
- (void) netsocketConnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
    }
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:NO];
        [socket setDelegate:nil];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
    if(inNetSocket == socket){
        NSString* theString = [[NSString alloc] initWithData:[inNetSocket readData] encoding:NSASCIIStringEncoding];
        NSArray* parts = [theString componentsSeparatedByString:@"\n"];
        for(NSString* aPart in parts){
            if([aPart length]==0) continue;
            else if([aPart rangeOfString:@"OrcaHeartBeat"].location != NSNotFound) continue;
            else if([aPart rangeOfString:@"runStatus"].location     != NSNotFound) continue;
            else [self processMessage:aPart];
        }
        [theString release];
    }
}
@end

@implementation ORResponseWaitOp

- (id) initWithRemoteObj:(ORRemoteSocketModel*)aRemObj commands:(NSArray*)cmdArray delegate:(ORRemoteCommander*)aDelegate
{
    self = [super init];
    delegate    = [aDelegate retain];
    remObj      = [aRemObj retain];
    cmds        = [cmdArray retain];
    [self  setQueuePriority:NSOperationQueuePriorityVeryHigh];
    return self;
}

- (void) dealloc
{
    [delegate release];
    [cmds release];
    [remObj release];
    [super dealloc];
}

- (void) main
{
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    //our delegate may have just now opened the port. We may be here before it is actually open.
    
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    while (![self isCancelled]){
        NSTimeInterval totalTime = [NSDate timeIntervalSinceReferenceDate] - startTime;
        if(totalTime>10 || [remObj isConnected]){
            break;
        }
        [NSThread sleepForTimeInterval:.05];
    }
    
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    
    if([remObj isConnected]){
        for(id aCmd in cmds){
            if([self isCancelled])break;
            [remObj performSelectorOnMainThread:@selector(mainThreadSendString:) withObject:aCmd waitUntilDone:YES];
            
            NSString* aKey = nil;
            NSArray* parts = [aCmd componentsSeparatedByString:@"="];
            if([parts count]==2){
                aKey = [[parts objectAtIndex:0] trimSpacesFromEnds];
            }
            NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
            while (![self isCancelled]){
                NSTimeInterval totalTime = [NSDate timeIntervalSinceReferenceDate] - startTime;
                if(totalTime>10)break;
                if(aKey){
                    if([remObj responseExistsForKey:aKey]){
                        if(delegate != nil){
                            id aValue = [remObj responseForKey:aKey];
                            [result setObject:aValue forKey:aKey];
                        }
                        break;
                    }
                }
                if([remObj responseExistsForKey:@"Error"]){
                    id aValue = [remObj responseForKey:@"Error"];  //clear the error
                    [result setObject:aValue forKey:@"Error"];
                    break;
                }
                if([remObj responseExistsForKey:@"Success"]){
                    [remObj responseForKey:@"Success"]; //clear the success flag
                    break;
                }
            }
        }
        [result setObject:[NSNumber numberWithBool:YES] forKey:@"connected"];
    }
    else [result setObject:[NSNumber numberWithBool:NO] forKey:@"connected"];
    
    [delegate performSelectorOnMainThread:@selector(setRemoteOpStatus:) withObject:result waitUntilDone:YES];
    [pool release];
}

@end


