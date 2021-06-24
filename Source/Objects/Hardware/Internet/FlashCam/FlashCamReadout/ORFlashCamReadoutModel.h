//  Orca
//  ORFlashCamReadoutModel.h
//
//  Created by Tom Caldwell on Monday Dec 26,2019
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

#import "ORReadOutList.h"
#import "ORDataTaker.h"
#import "ORTaskSequence.h"
#import "ORConnector.h"
#import "ORFlashCamListener.h"
#import "ORFlashCamCard.h"
#import "fcio.h"

#define kFlashCamMaxEthInterfaces 4
#define kFlashCamDefaultPort 4000
#define kFlashCamDefaultBuffer 20000
#define kFlashCamDefaultTimeout 2000 // ms

@interface ORFlashCamReadoutModel : OrcaObject <ORDataTakerReadOutList>
{
    @private
    NSString* ipAddress;
    NSString* username;
    NSMutableArray* ethInterface;
    NSMutableArray* ethListenerIndex;
    NSString* ethType;
    NSMutableDictionary* configParams;
    ORPingTask* pingTask;
    bool pingSuccess;
    ORTaskSequence* firmwareTasks;
    NSMutableArray* firmwareQueue;
    bool runKilled;
    NSMutableArray* fclistener;
    ORReadOutList* readOutList;
    //NSMutableArray* dataTakers;
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark •••Accessors
- (NSString*) ipAddress;
- (NSString*) username;
- (bool) localMode;
- (int) ethInterfaceCount;
- (int) indexOfInterface:(NSString*)interface;
- (NSString*) ethInterfaceAtIndex:(int)index;
- (int) ethListenerIndex:(int)index;
- (NSString*) ethType;
- (NSNumber*) configParam:(NSString*)p;
- (bool) pingSuccess;
- (int) listenerCount;
- (ORFlashCamListener*) getListenerAtIndex:(int)i;
- (ORFlashCamListener*) getListener:(NSString*)eth atPort:(uint16_t)p;
- (ORFlashCamListener*) getListenerForIP:(NSString*)ip atPort:(uint16_t)p;
- (int) getIndexOfListener:(NSString*)eth atPort:(uint16_t)p;
- (ORReadOutList*) readOutList;
- (NSMutableArray*) children;

- (void) setIPAddress:(NSString*)ip;
- (void) setUsername:(NSString*)user;
- (void) addEthInterface:(NSString*)eth;
- (void) setEthInterface:(NSString*)eth atIndex:(int)index;
- (void) removeEthInterface:(NSString*)eth;
- (void) removeEthInterfaceAtIndex:(int)index;
- (void) setEthListenerIndex:(int)lindex atIndex:(int)index;
- (void) setEthType:(NSString*)etype;
- (void) setConfigParam:(NSString*)p withValue:(NSNumber*)v;
- (void) addListener:(NSString*)eth atPort:(uint16_t)p;
- (void) setListener:(NSString*)eth atPort:(uint16_t)p forIndex:(int)i;
- (void) removeListener:(NSString*)eth atPort:(uint16_t)p;
- (void) removeListenerAtIndex:(int)i;
- (void) setReadOutList:(ORReadOutList*)readList;

#pragma mark •••Commands
- (void) updateIPs;
- (void) sendPing:(bool)verbose;
- (bool) pingRunning;
- (void) taskFinished:(id)task;
- (void) tasksCompleted:(id)sender;
- (void) taskData:(NSDictionary*)taskData;
- (NSMutableArray*) ethInterfacesForListener:(int)index;
- (int) listenerIndexForCard:(ORCard*)card;
- (void) getFirmwareVersion:(ORFlashCamCard*)card;
- (void) getFirmwareVersionAfterPing:(ORFlashCamCard*)card;
- (int) ethIndexForCard:(ORCard*)card;
- (NSMutableArray*) runFlags;
- (NSMutableArray*) connectedObjects:(NSString*)cname toInterface:(NSString*)eth;
- (NSMutableArray*) connectedObjects:(NSString*)cname;
- (void) startRun;
- (void) startRunAfterPing;
//- (void) killRun;

#pragma mark •••Data taker methods
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo;
- (void) reset;

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@end

#pragma mark •••Externals
extern NSString* ORFlashCamReadoutModelIPAddressChanged;
extern NSString* ORFlashCamReadoutModelUsernameChanged;
extern NSString* ORFlashCamReadoutModelEthInterfaceChanged;
extern NSString* ORFlashCamReadoutModelEthInterfaceAdded;
extern NSString* ORFlashCamReadoutModelEthInterfaceRemoved;
extern NSString* ORFlashCamReadoutModelEthTypeChanged;
extern NSString* ORFlashCamReadoutModelConfigParamChanged;
extern NSString* ORFlashCamReadoutModelPingStart;
extern NSString* ORFlashCamReadoutModelPingEnd;
extern NSString* ORFlashCamReadoutModelRunInProgress;
extern NSString* ORFlashCamReadoutModelRunEnded;
extern NSString* ORFlashCamReadoutModelListenerChanged;
extern NSString* ORFlashCamReadoutModelListenerAdded;
extern NSString* ORFlashCamReadoutModelListenerRemoved;
extern NSString* ORFlashCamReadoutModelMonitoringUpdated;
