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

@class ORRemoteRunItemController;
@class NetSocket;
#import "ORRunModel.h"

@interface ORRemoteRunItem : NSObject <NSCopying>
{
    id	       owner;           //this is ORDistributedRunModel
    id         controller;      //ORDistrubutedRunController
    NSString*  ipNumber;
    bool       isConnected;
    bool       ignore;
    NetSocket* socket;
    NSInteger  remotePort;
    NSString*  systemName;
    int        runningState;
    uint32_t   runNumber;
}

#pragma mark •••Initialization
- (id) initWithOwner:(id)anOwner;
- (id) copyWithZone:(NSZone *)zone;
- (NSUndoManager*) undoManager;
- (ORRemoteRunItemController*) makeController:(id)anOwner;

#pragma mark •••Accessors
- (id)        owner;
- (void)      setOwner:(id)anObj;
- (void)      removeSelf;
- (void)      setIpNumber:(NSString*)aString;
- (NSString*) ipNumber;
- (BOOL)      isConnected;
- (void)      setIsConnected:(BOOL)aIsConnected;
- (uint32_t)  runNumber;
- (void)      setRunNumber:(uint32_t)aRunNumber;
- (NSString*) systemName;;
- (void)      setSystemName:(NSString*)aName;
- (bool)      ignore;
- (void)      setIgnore:(bool)aState;
- (NSInteger) remotePort;
- (void)      setRemotePort:(NSInteger)aRemotePort;

#pragma mark •••Command Handling
- (void) parseString:(NSString*)inString;
- (void) sendSetup;
- (void) setRunningState:(int)aRunningState;
- (void) fullUpdate;
- (void) startRun:(BOOL)doInit;
- (void) restartRun;
- (void) haltRun;
- (void) stopRun;
- (void) setRunningState:(int)aRunningState;
- (int)  runningState;
- (void) setSuccess:(int)state;
- (void) doTimedUpdate;

#pragma mark •••Socket Stuff
- (void)       netsocket:(NetSocket*)inNetSocket dataAvailable:(NSUInteger)inAmount;
- (void)       netsocketDisconnected:(NetSocket*)inNetSocket;
- (void)       sendCmd:(NSString*)aCmd;
- (void)       connectSocket:(BOOL)state;
- (NetSocket*) socket;
- (void)       setSocket:(NetSocket*)aSocket;

#pragma mark •••Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
@end

extern NSString* ORRemoteRunItemIgnoreChanged;
extern NSString* ORRemoteRunItemIpNumberChanged;
extern NSString* ORRemoteRunItemIsConnectedChanged;
extern NSString* ORRemoteRunItemPort;
extern NSString* ORRemoteRunItemPortChanged;
extern NSString* ORRemoteRunItemStateChanged;
extern NSString* ORRemoteRunItemSystemNameChanged;
extern NSString* ORRemoteRunItemRunNumberChanged;
