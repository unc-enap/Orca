//  Orca
//  ORFlashCamListenerModel.h
//
//  Created by Tom Caldwell on May 1, 2020
//  Copyright (c) 2019 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORTaskSequence.h"
#import "ORDataTaker.h"
#import "ORReadOutList.h"
#import "ORTimeRate.h"
#import "fcio.h"
#import "bufio.h"

@interface ORFlashCamListenerModel : OrcaObject <ORDataTaker>
{
    @private
    NSString* interface;
    uint16_t port;
    NSString* ip;
    NSMutableArray* remoteInterfaces;
    int timeout;
    int ioBuffer;
    int stateBuffer;
    double throttle;
    FCIOStateReader* reader;
    int readerRecordCount;
    int bufferedRecords;
    NSString* status;
    NSUInteger eventCount;
    double runTime;
    double readMB;
    double rateMB;
    double rateHz;
    double timeLock;
    double deadTime;
    double totDead;
    double curDead;
    ORTimeRate* dataRateHistory;
    ORTimeRate* eventRateHistory;
    ORTimeRate* deadTimeHistory;
    ORTaskSequence* runTask;
    ORReadOutList* readOutList;
    NSArray* dataTakers;
    NSMutableArray* readOutArgs;
    NSMutableArray* chanMap;
}

#pragma mark •••Initialization
- (id) init;
- (id) initWithInterface:(NSString*)iface port:(uint16_t)p;
- (void) dealloc;

#pragma mark •••Accessors
- (NSString*) identifier;
- (NSString*) interface;
- (uint16_t) port;
- (NSString*) ip;
- (NSMutableArray*) remoteInterfaces;
- (NSUInteger) remoteInterfaceCount;
- (NSString*) remoteInterfaceAtIndex:(NSUInteger)index;
- (int) timeout;
- (int) ioBuffer;
- (int) stateBuffer;
- (double) throttle;
- (FCIOStateReader*) reader;
- (int) readerRecordCount;
- (int) bufferedRecords;
- (NSString*) status;
- (NSUInteger) eventCount;
- (double) runTime;
- (double) readMB;
- (double) rateMB;
- (double) rateHz;
- (double) timeLock;
- (double) deadTime;
- (double) totDead;
- (double) curDead;
- (ORTimeRate*) dataRateHistory;
- (ORTimeRate*) eventRateHistory;
- (ORTimeRate*) deadTimeHistory;
- (ORTaskSequence*) runTask;
- (ORReadOutList*) readOutList;
- (NSMutableArray*) readOutArgs;
- (NSMutableArray*) children;

- (void) setInterface:(NSString*)iface andPort:(uint16_t)p;
- (void) setInterface:(NSString*)iface;
- (void) updateIP;
- (void) setPort:(uint16_t)p;
- (void) setRemoteInterfaces:(NSMutableArray*)ifaces;
- (void) addRemoteInterface:(NSString*)iface;
- (void) removeRemoteInterface:(NSString*)iface;
- (void) removeRemoteInterfaceAtIndex:(NSUInteger)index;
- (void) setTimeout:(int)to;
- (void) setIObuffer:(int)io;
- (void) setStateBuffer:(int)sb;
- (void) setThrottle:(double)t;
- (void) setReadOutList:(ORReadOutList*)newList;
- (void) setReadOutArgs:(NSMutableArray*)args;
- (void) setChanMap:(NSMutableArray*)chMap;

#pragma mark •••Comparison methods
- (BOOL) sameInterface:(NSString*)iface andPort:(uint16_t)p;
- (BOOL) sameIP:(NSString*)address andPort:(uint16_t)p;

#pragma mark •••FCIO methods
- (bool) connect;
- (void) disconnect;
- (void) read;

#pragma mark •••Task methods
- (void) taskFinished:(id)task;
- (void) tasksCompleted:(id)sender;
- (void) taskData:(NSMutableDictionary*)taskData;

#pragma mark •••Data taker methods
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) saveReadOutList:(NSFileHandle*)aFile;
- (void) loadReadOutList:(NSFileHandle*)aFile;
- (void) reset;

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

@interface ORFlashCamListenerModel (private)
- (void) setStatus:(NSString*)s;
@end

extern NSString* ORFlashCamListenerModelConfigChanged;
extern NSString* ORFlashCamListenerModelStatusChanged;
//extern NSString* ORFlashCamListenerModelConnected;
//extern NSString* ORFlashCamListenerModelDisconnected;
extern NSString* ORFlashCamListenerModelChanMapChanged;
