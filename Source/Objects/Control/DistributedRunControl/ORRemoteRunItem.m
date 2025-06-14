//
//  ORRemoteRunItemController.m
//  Orca
//
//  Created by Mark Howe on Apr 22, 2025.
//  Copyright (c) 2025 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Physics Department sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORRemoteRunItem.h"
#import "ORDistributedRunModel.h"
#import "ORDistributedRunController.h"
#import "ORRemoteRunItemController.h"
#import "NetSocket.h"
#import "ORStatusController.h"

NSString* ORRemoteRunItemIpNumberChanged    = @"ORRemoteRunItemIpNumberChanged";
NSString* ORRemoteRunItemIsConnectedChanged = @"ORRemoteRunItemIsConnectedChanged";
NSString* ORRemoteRunItemPort               = @"ORRemoteRunItemPort";
NSString* ORRemoteRunItemPortChanged        = @"ORRemoteRunItemPortChanged";
NSString* ORRemoteRunItemStateChanged       = @"ORRemoteRunItemStateChanged";
NSString* ORRemoteRunItemSystemNameChanged  = @"ORRemoteRunItemSystemNameChanged";
NSString* ORRemoteRunItemIgnoreChanged      = @"ORRemoteRunItemIgnoreChanged";
NSString* ORRemoteRunItemRunNumberChanged   = @"ORRemoteRunItemRunNumberChanged";

@implementation ORRemoteRunItem

#pragma mark •••Initialization
- (id) initWithOwner:(id)anOwner;
{
	self  = [super init];
	owner = anOwner;
    remotePort = 4667; //default
	return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    id obj = [[NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]] retain];
	[obj setOwner:owner];
	return obj;
}

- (void) dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	[super dealloc];
}

- (ORRemoteRunItemController*) makeController:(id)anOwner
{
	ORRemoteRunItemController* theController =  [[ORRemoteRunItemController alloc] initWithNib:@"RemoteRunItem"];
	[theController setOwner:anOwner];
	[theController setModel:self];
	return [theController autorelease];
}

#pragma mark •••Accessors
- (id)   owner              { return owner; }
- (void) setOwner:(id)anObj { owner = anObj; }

- (NSString*) systemName   { return systemName; }
- (void)      setSystemName:(NSString*)aName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSystemName:systemName];

    if(!aName)aName=@"";
    [systemName autorelease];
    systemName = [aName copy];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORRemoteRunItemSystemNameChanged
        object: self];
}

- (NSString*) ipNumber
{
    //have to make sure we don't return nil
    if([ipNumber length])return ipNumber;
    else                 return @"";
}

- (void) setIpNumber:(NSString*)aString
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIpNumber:ipNumber];

    if(!aString)aString=@"";
    [ipNumber autorelease];
    ipNumber = [aString copy];
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORRemoteRunItemIpNumberChanged
        object: self];
}

- (BOOL) isConnected { return isConnected; }
- (void) setIsConnected:(BOOL)aValue
{
    isConnected  = aValue;
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ORRemoteRunItemIsConnectedChanged
     object:self];
}

- (bool) ignore { return ignore; }
- (void) setIgnore:(bool)aState
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIgnore:ignore];

    ignore = aState;
    
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORRemoteRunItemIgnoreChanged
        object: self];
}

- (NetSocket*) socket {return socket;}
- (void) setSocket:(NetSocket*)aSocket
{
    [aSocket retain];
    [socket release];
    socket = aSocket;
    
    [socket setDelegate:self];
}

- (NSInteger) remotePort {return remotePort;}
- (void) setRemotePort:(NSInteger)aRemotePort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRemotePort:remotePort];
    
    remotePort = aRemotePort;
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:ORRemoteRunItemPortChanged
     object:self];
}
- (NSUndoManager*) undoManager
{
    return [(ORAppDelegate*)[NSApp delegate] undoManager];
}

- (void) removeSelf { [owner removeRemoteRunItem:self]; }

#pragma mark •••Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setIpNumber:    [decoder decodeObjectForKey: @"ipNumber"]];
    [self setRemotePort:  [decoder decodeIntegerForKey:@"remotePort"]];
    [self setIgnore:      [decoder decodeBoolForKey:   @"ignore"]];
    [self setSystemName:  [decoder decodeObjectForKey: @"systemName"]];
    
    if(remotePort == 0)[self setRemotePort:4667];
    
    bool wasConnected = [decoder decodeBoolForKey: @"wasConnected"];
    if(wasConnected)[self connectSocket:YES];

    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject: ipNumber    forKey:@"ipNumber"];
    [encoder encodeInteger:remotePort  forKey:@"remotePort"];
    [encoder encodeObject: systemName  forKey:@"systemName"];
    [encoder encodeBool:   ignore      forKey:@"ignore"];
    [encoder encodeBool:   isConnected forKey:@"wasConnected"];
}

#pragma mark •••Socket Stuff
- (void) connectSocket:(BOOL)state
{
    if(state){
        [self setSocket:[NetSocket netsocketConnectedToHost:ipNumber port:remotePort]];
    }
    else {
        [socket close];
        [self setIsConnected:[socket isConnected]];
        [self setRunningState:eRunStopped];
    }
}

- (void) netsocketConnected:(id)aSocket
{
    if(aSocket == socket){
        [self setIsConnected:[socket isConnected]];
        [self fullUpdate];
    }
}

- (void) netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount
{
    if(inNetSocket == socket){
        NSString* inString = [socket readString:NSASCIIStringEncoding];
        if(inString){
            [self parseString:inString];
        }
    }
}

- (void) netsocketDisconnected:(NetSocket*)inNetSocket
{
    if(inNetSocket == socket){
        [self setIsConnected:[socket isConnected]];
        [self setIsConnected:NO];
        [self setRunningState:eRunStopped];
    }
}

- (void) sendCmd:(NSString*)aCmd
{
    if([self isConnected]){
        [socket writeString:aCmd encoding:NSASCIIStringEncoding];
    }
}

- (void) doTimedUpdate;
{
    if([socket isConnected]){
        [self sendCmd:@"runningState=[RunControl runningState];"];
   }
}

#pragma mark  •••Incoming Strings
- (void) parseString:(NSString*)inString
{
    [[self undoManager] disableUndoRegistration];
    NSArray* lines= [inString componentsSeparatedByString:@"\n"];
    int n = (int)[lines count];
    int i;
    NSCharacterSet* numberSet =  [NSCharacterSet decimalDigitCharacterSet];
    
    for(i=0;i<n;i++){
        NSString* aLine = [lines objectAtIndex:i];
        NSRange firstColonRange = [aLine rangeOfString:@":"];
        if(firstColonRange.location != NSNotFound){
            NSString* key = [aLine substringToIndex:firstColonRange.location];
            id value      = [aLine substringFromIndex:firstColonRange.location+1];
            if([numberSet characterIsMember:[value characterAtIndex:0]]){
                value = [NSDecimalNumber decimalNumberWithString:value];
            }
            @try {
                [self setValue:value forKey:key];
            }
            @catch(NSException* localException) {
            }
        }
    }
    [[self undoManager] enableUndoRegistration];
}

- (void) setSuccess:(int)state
{
   //just for KVC
}

- (void) setPostAlarm:(NSString*)anAlarm
{
    NSLogColor([NSColor redColor],@"%@ posted Alarm: %@\n",systemName,anAlarm);
}

- (void) sendSetup
{
    if(isConnected){
        [self sendCmd:[NSString stringWithFormat:@"[RunControl setTimeLimit:%f];" ,[owner timeLimit]]];
        [self sendCmd:[NSString stringWithFormat:@"[RunControl setRepeatRun:%d];" ,[owner repeatRun]]];
        [self sendCmd:[NSString stringWithFormat:@"[RunControl setTimedRun:%d];"  ,[owner timedRun]]];
        [self sendCmd:[NSString stringWithFormat:@"[RunControl setQuickStart:%d];",[owner quickStart]]];
    }
}

- (void) fullUpdate
{
    if(isConnected){
        [self sendCmd:@"runningState = [RunControl runningState];"];
    }
}

- (void) setRunningState:(int)aRunningState
{
    runningState = aRunningState;

    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORRemoteRunItemStateChanged
        object: self];
}

- (int) runningState
{
    return runningState;
}

- (void) setRunStatus:(int)aRunningState
{
    //this is just to provide a method for KVC
    [self setRunningState:aRunningState];
}

- (uint32_t) runNumber
{
    return runNumber;
}

- (void) setRunNumber:(uint32_t)aValue
{
    runNumber = aValue;
    NSString* runNumberCmd = [NSString stringWithFormat:@"[RunControl setRunNumber:%d];",aValue];
    [self sendCmd:runNumberCmd];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:ORRemoteRunItemRunNumberChanged
        object: self];
}

- (void) startRun:(BOOL)doInit
{
    if(!ignore){
        if([socket isConnected]){
            [self sendCmd:@"[RunControl setRemoteControl:0];"];
            [self sendSetup];
            NSString* startRunCmd = [NSString stringWithFormat:@"[RunControl startRun:%d];",doInit];
            [self sendCmd:startRunCmd];
            [self sendCmd:@"runNumber = [RunControl runNumber];"];
            [self sendCmd:@"[RunControl setRemoteControl:1];"];
            [self sendCmd:@"[RunControl setRemoteInterface:1];"];
            
            NSLog(@"-------------------------------------\n");
            NSLog(@"%@ run started.\n",[self systemName]);
            NSLog(@"-------------------------------------\n");
        }
        else {
            NSLogColor([NSColor redColor],@"%@ Not connected: run not started\n",[self systemName]);
        }
    }
    else {
        NSLogColor([NSColor redColor],@"%@ set to ignore: run not started\n",[self systemName]);
    }
}


- (void) restartRun
{
    [self stopRun];
    [self startRun:![owner quickStart]];
}

- (void) haltRun
{
    [self stopRun];
}

- (void)stopRun
{
    if(!ignore){
        if([socket isConnected]){
            [self sendCmd:@"[RunControl haltRun];"];
            [self sendCmd:@"[RunControl setRemoteControl:0];"];
            NSLog(@"-------------------------------------\n");
            NSLog(@"Remote Run On %@ stopped.\n",[self systemName]);
            NSLog(@"-------------------------------------\n");
        }
        else {
            NSLog(@"%@ not connected: run not stopped\n",[self systemName]);
        }
    }
    else {
        NSLog(@"%@ ignored: run not stopped\n",[self systemName]);
    }
}

@end

