//
//  ORSyncCenterModel.h
//  Orca
//
//  Created by Mark Howe on Thursday, Sept 15, 2016
//  Copyright (c) 2016 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#pragma mark •••Imported Files
#import "OROrderedObjHolding.h"
#import "ORRemoteCommander.h"

@class ORSyncCommander;

@interface ORSyncCenterModel : ORGroup <OROrderedObjHolding>
{
    NSMutableArray*     orcaList;
    ORSyncCommander*    syncCommander;
 }

#pragma mark ***Accessors

#pragma mark ***Utilities
- (NSArray*) orcaList;
- (void) addOrca;
- (void) addOrca:(id)anAddress atIndex:(NSUInteger)anIndex;
- (void) removeOrcaAtIndex:(NSUInteger) anIndex;
- (NSUInteger)  orcaCount;
- (void) setIndex:(NSUInteger)anIndex value:(id)anObject forKey:(id)aKey;
- (void) syncNow;
- (void) setStatus:(int)index state:(NSString*)aState;
- (NSUInteger)  orcaCount;
- (BOOL) okToSyncOnCallList:(int)index;
- (BOOL) okToSyncAlarmList:(int)index;
- (void) doDelayedSync:(NSNotification*)aNote;
- (void) delayedSync;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark •••OROrderedObjHolding Protocol
- (int) maxNumberOfObjects;
- (int) objWidth;
- (int) groupSeparation;
- (NSString*) nameForSlot:(int)aSlot;
- (NSRange) legalSlotsForObj:(id)anObj;
- (int) slotAtPoint:(NSPoint)aPoint;
- (NSPoint) pointForSlot:(int)aSlot;
- (void) place:(id)anObj intoSlot:(int)aSlot;
- (NSUInteger) slotForObj:(id)anObj;
- (int) numberSlotsNeededFor:(id)anObj;

@property (retain, nonatomic) NSMutableArray* orcaList;
@property (retain) ORSyncCommander* syncCommander;
@end

extern NSString* ORSyncCenterOrcaRemoved;
extern NSString* ORSyncCenterOrcaAdded;
extern NSString* ORSyncCenterModelReloadTable;
extern NSString* ORSyncCenterLock;

typedef struct {
    int         state;
    NSString*   name;
} SyncCommanderStateInfo;

//do NOT change this list without changing the StateInfo array in the .m file
enum {
    kSyncCommander_SyncSetIpAddress,
    kSyncCommander_GetOnCallList,
    kSyncCommander_GetAlarmList,
    kSyncCommander_SendCmds,
    kSyncCommander_WaitOnConnection,
    kSyncCommander_CheckListCount,
    kSyncCommander_IncWorkingIndex,
    kSyncCommander_Done,
    kSyncCommander_NumStates //must be last
};

@interface ORSyncCommander : ORRemoteCommander
{
    ORSyncCenterModel*      delegate;
    int                     workPhase;
    float                   stepDelay;
    float                   timeInState;
    NSString*               ipAddress;
    NSArray*                alarmList;
    NSArray*                onCallList;
    BOOL                    isRunning;
    int                     nextState;
    int                     workingIndex;
}

- (id) initWithDelegate:(ORSyncCenterModel*)aDelegate;
- (void)        start;
- (void)        stop;
- (int)         numStates;
- (void)        step;
- (NSString*)   workTypePhrase;

@property (assign) ORSyncCenterModel*       delegate;
@property (assign) float                    stepDelay;
@property (assign) int                      workingIndex;
@property (assign) int                      workPhase;
@property (assign,nonatomic) BOOL           isRunning;
@property (assign,nonatomic) int            nextState;
@property (copy) NSString*                  ipAddress;
@property (retain) NSArray*                 onCallList;
@property (retain) NSArray*                 alarmList;
@end

extern NSString* ORSyncCommanderIsRunningChanged;
extern NSString* ORSyncCommanderStateChanged;

