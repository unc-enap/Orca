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

#import "ORGroup.h"
#import "OROrderedObjHolding.h"
#import "ORDataTaker.h"
#import "ORTaskSequence.h"
#import "ORConnector.h"
#import "ORFlashCamListenerModel.h"
#import "ORFlashCamCard.h"
#import "fcio.h"

#define kFlashCamMaxEthInterfaces 4
#define kFlashCamMaxListeners 8
#define kFlashCamDefaultPort 4000
#define kFlashCamDefaultBuffer 20000
#define kFlashCamDefaultTimeout 2000 // ms

#define kFlashCamEthTypeCount 5
static NSString* kFlashCamEthTypes[kFlashCamEthTypeCount] = {@"efb1", @"efb2", @"efb3", @"efb4", @"efb5"};

@interface ORFlashCamReadoutModel : ORGroup <OROrderedObjHolding,ORDataTaker>
{
    @private
    NSString* ipAddress;
    NSString* username;
    NSMutableArray* ethInterface;
    NSMutableArray* ethType;
    NSString* fcSourcePath;
    bool validFCSourcePath;
    bool checkedFCSourcePath;
    ORPingTask* pingTask;
    bool pingSuccess;
    ORTaskSequence* remotePathTask;
    ORTaskSequence* firmwareTasks;
    NSMutableArray* firmwareQueue;
    ORTaskSequence* rebootTasks;
    NSMutableArray* rebootQueue;
    ORAlarm* runFailedAlarm;
    bool readoutReady;
}

#pragma mark •••Initialization
- (id) init;
- (void) dealloc;
- (void) setUpImage;
- (void) makeMainController;

#pragma mark •••Accessors
- (bool) readoutReady;
- (NSString*) identifier;
- (NSString*) ipAddress;
- (NSString*) username;
- (bool) localMode;
- (int) ethInterfaceCount;
- (int) indexOfInterface:(NSString*)interface;
- (NSString*) ethInterfaceAtIndex:(int)index;
- (NSString*) ethTypeAtIndex:(int)index;
- (NSString*) fcSourcePath;
- (bool) validFCSourcePath;
- (bool) pingSuccess;
- (ORTaskSequence*) remotePathTask;
- (int) listenerCount;
- (ORFlashCamListenerModel*) getListenerAtIndex:(int)i;
- (ORFlashCamListenerModel*) getListenerForTag:(int)t;
- (ORFlashCamListenerModel*) getListener:(NSString*)eth atPort:(uint16_t)p;
- (ORFlashCamListenerModel*) getListenerForIP:(NSString*)ip atPort:(uint16_t)p;
- (int) getIndexOfListener:(NSString*)eth atPort:(uint16_t)p;

- (void) setIPAddress:(NSString*)ip;
- (void) setUsername:(NSString*)user;
- (void) setEthInterface:(NSMutableArray*)eth;
- (void) setEthType:(NSMutableArray*)eth;
- (void) addEthInterface:(NSString*)eth;
- (void) setEthInterface:(NSString*)eth atIndex:(int)index;
- (void) removeEthInterface:(NSString*)eth;
- (void) removeEthInterfaceAtIndex:(int)index;
- (void) setEthType:(NSString*)etype atIndex:(int)index;
- (void) setFCSourcePath:(NSString*)path;
- (void) checkFCSourcePath;
- (void) addListener:(ORFlashCamListenerModel*)listener;
- (void) addListener:(NSString*)eth atPort:(uint16_t)p;
- (void) setListener:(NSString*)eth atPort:(uint16_t)p forIndex:(int)i;
- (void) removeListener:(NSString*)eth atPort:(uint16_t)p;
- (void) removeListenerAtIndex:(int)i;

#pragma mark •••Commands
- (void) updateIPs;
- (void) sendPing:(bool)verbose;
- (bool) pingRunning;
- (void) getRemotePath;
- (void) taskFinished:(id)task;
- (void) tasksCompleted:(id)sender;
- (void) taskData:(NSDictionary*)taskData;
- (void) getFirmwareVersion:(ORFlashCamCard*)card;
- (void) getFirmwareVersionAfterPing:(ORFlashCamCard*)card;
- (void) rebootCard:(ORFlashCamCard*)card;
- (void) rebootCardAfterPing:(ORFlashCamCard*)card;
- (int) ethIndexForCard:(ORCard*)card;
- (NSMutableArray*) connectedObjects:(NSString*)cname toInterface:(NSString*)eth;
- (NSMutableArray*) connectedObjects:(NSString*)cname;
- (void) startRunAfterPing;
- (void) runFailed;
//- (void) killRun;

#pragma mark •••OrOrderedObjHolding Protocol
- (int) maxNumberOfObjects;
- (int) objWidth;
- (int) groupSeparation;
- (int) numberSlotsNeededFor:(id)obj;
- (NSString*) nameForSlot:(int)slot;
- (NSRange) legalSlotsForObj:(id)obj;
- (int) slotAtPoint:(NSPoint)point;
- (NSPoint) pointForSlot:(int)slot;
- (void) place:(id)obj intoSlot:(int)slot;
- (int) slotForObj:(id)obj;
- (BOOL) slot:(int)aSlot excludedFor:(id)anObj;
- (void) drawSlotBoundaries;
- (void) drawSlotLabels;

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
extern NSString* ORFlashCamReadoutModelFCSourcePathChanged;
extern NSString* ORFlashCamReadoutModelPingStart;
extern NSString* ORFlashCamReadoutModelPingEnd;
extern NSString* ORFlashCamReadoutModelRemotePathStart;
extern NSString* ORFlashCamReadoutModelRemotePathEnd;
extern NSString* ORFlashCamReadoutModelRunInProgress;
extern NSString* ORFlashCamReadoutModelRunEnded;
extern NSString* ORFlashCamReadoutModelListenerChanged;
extern NSString* ORFlashCamReadoutModelListenerAdded;
extern NSString* ORFlashCamReadoutModelListenerRemoved;
extern NSString* ORFlashCamReadoutSettingsLock;
