//
//  ORLNGSSlowControlsModel.m
//  Orca
//
//  Created by Mark Howe on Thursday, Aug 20,2009
//  Copyright (c) 2009 Univerisy of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the Univerisy of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the Univerisy of North 
//Carolina reserve all rights in the program. Neither the authors,
//Univerisy of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#pragma mark •••Imported Files
#import "ORLNGSSlowControlsModel.h"
#import "ORSafeQueue.h"

NSString* ORLNGSSlowControlsPollTimeChanged			= @"ORLNGSSlowControlsPollTimeChanged";
NSString* ORLNGSSlowControlsModelTimeOutErrorChanged= @"ORLNGSSlowControlsModelTimeOutErrorChanged";
NSString* ORLNGSSlowControlsLock					= @"ORLNGSSlowControlsLock";
NSString* ORLNGSSlowControlsModelTimeout			= @"ORLNGSSlowControlsModelTimeout";
NSString* ORLNGSSlowControlsModelDataIsValidChanged = @"ORLNGSSlowControlsModelDataIsValidChanged";
NSString* ORL200SlowControlsErrorCountChanged       = @"ORL200SlowControlsErrorCountChanged";
NSString* ORL200SlowControlsUserNameChanged         = @"ORL200SlowControlsUserNameChanged";
NSString* ORL200SlowControlsPassWordChanged         = @"ORL200SlowControlsPassWordChanged";
NSString* ORL200SlowControlsIPAddressChanged        = @"ORL200SlowControlsIPAddressChanged";


@implementation ORLNGSSlowControlsModel

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    canceled = YES;
	[cmdQueue       release];
	[lastRequest    release];
    [processThread  release];
    [passWord       release];
    [userName       release];
    [super dealloc];
}
- (void) sleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super sleep];
}
- (void) makeMainController
{
    [self linkToController:@"ORLNGSSlowControlsController"];
}

- (void) setUpImage {
    NSImage* image = [NSImage imageNamed:@"LNGSSlowControls"];
    [self setImage:image];
}

- (void) registerNotificationObservers
{
//	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

//    [notifyCenter addObserver : self
//                     selector : @selector(dataReceived:)
//                         name : ORSerialPortDataReceived
//                       object : nil];
}

#pragma mark ***Accessors

- (NSString*) ipAddress
{
    if(!ipAddress)return @"";
    return ipAddress;
}
- (void) setIPAddress:(NSString*)anIP
{
    if(!anIP)anIP = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIPAddress:ipAddress];
    [ipAddress autorelease];
    ipAddress = [anIP copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORL200SlowControlsIPAddressChanged object:self];
}
- (NSString*) userName
{
    return userName;
}
- (void) setUserName:(NSString*)aName
{
    if(!aName)aName = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setUserName:userName];
    [userName autorelease];
    userName = [aName copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORL200SlowControlsUserNameChanged object:self];
}

- (NSString*) passWord
{
    return passWord;
}

- (void) setPassWord:(NSString*)aPassword;
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPassWord:passWord];
    [passWord autorelease];
    passWord = [aPassword copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORL200SlowControlsPassWordChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLNGSSlowControlsPollTimeChanged object:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
    if(pollTime)[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}

- (void)pollHardware
{
    ORL200SCCmd* aCmd = [[ORL200SCCmd alloc]init];
    [aCmd setRequest:@"Test"];
    //[self putRequestInQueue:aCmd];
    [aCmd release];
    if(pollTime)[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}

- (NSString*) lockName
{
	return ORLNGSSlowControlsLock;
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];

    [self setPollTime:        [decoder decodeIntForKey: @"pollTime"]];
    [self setUserName:        [decoder decodeObjectForKey: @"userName"]];
    [self setPassWord:        [decoder decodeObjectForKey: @"passWord"]];
    [self setIPAddress:       [decoder decodeObjectForKey: @"ipAddress"]];
    [[self undoManager] enableUndoRegistration];
    [self registerNotificationObservers];
		
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:pollTime           forKey: @"pollTime"];
    [encoder encodeObject:userName            forKey: @"userName"];
    [encoder encodeObject:passWord            forKey: @"passWord"];
    [encoder encodeObject:ipAddress           forKey: @"ipAddress"];
}


- (NSString*) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(NSString*)aRequest
{
	[aRequest retain];
	[lastRequest release];
	lastRequest = aRequest;    
}

- (BOOL) allDataIsValid:(unsigned short)aChan
{
    return YES;
}

- (void) dataReceived:(NSNotification*)note
{
}

- (void) putRequestInQueue:(ORL200SCCmd*)aCmd
{
    if(!processThread){
        processThread = [[NSThread alloc] initWithTarget:self selector:@selector(processQueue) object:nil];
        [processThread start];
    }
    if(!cmdQueue){
        cmdQueue = [[ORSafeQueue alloc] init];
    }
    [cmdQueue enqueue:aCmd];
}

#pragma mark ***Thread
- (void)processQueue
{
    NSAutoreleasePool* outerPool = [[NSAutoreleasePool alloc] init];
    if(!cmdQueue){
        cmdQueue = [[ORSafeQueue alloc] init];
    }

    do {
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
        id     aCmd = [cmdQueue dequeue];
        if(aCmd!=nil){
            NSLog(@"%@\n",[aCmd request]);
        }
        [pool release];
        [NSThread sleepForTimeInterval:.01];
    }while(!canceled);
    [outerPool release];
}

- (void) resetDataValid
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ORLNGSSlowControlsModelDataIsValidChanged object:self];
}

- (void) setDataValid:(unsigned short)aChan bit:(BOOL)aMask
{
}

- (void) timeout
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
	NSLogError(@"command timeout",@"LNGSSlowControls",nil);
    [[NSNotificationCenter defaultCenter] postNotificationName:ORLNGSSlowControlsModelTimeout object:self];
	[self setLastRequest:nil];
	[cmdQueue removeAllObjects];
}

@end

@implementation ORL200SCCmd
- (void) dealloc
{
    [request release];
    [super dealloc];
}
- (void) setRequest:(NSString*)aRequest
{
    [request release];
    request = [aRequest copy];
}
- (NSString*)request
{
    return request;
}
@end
