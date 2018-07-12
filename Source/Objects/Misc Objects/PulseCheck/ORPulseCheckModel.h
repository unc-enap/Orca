//
//  ORPulseCheckModel.h
//  Orca
//
//  Created by Mark Howe on Monday Apr 4,2016.
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

@class ORMachineToCheck;
@class ORAlarm;
@class ORFileGetterOp;

@interface ORPulseCheckModel : OrcaObject  {
    NSMutableArray*     machines;
    NSString*           lastFile;
    NSTimer*            notificationTimer;
    NSOperationQueue*   fileQueue;
}

#pragma mark •••Accessors
- (void) addMachine;
- (void) removeMachineAtIndex:(NSInteger) anIndex;
- (ORMachineToCheck*) machineAtIndex:(NSInteger)anIndex;
- (NSInteger) machineCount;
- (void) checkMachines:(NSTimer*)aTimer;
- (void) setUpQueue;

#pragma mark •••Save/Restore
- (void) saveToFile:        (NSString*)aPath;
- (void) restoreFromFile:   (NSString*)aPath;
- (id)   initWithCoder:     (NSCoder*)decoder;
- (void) encodeWithCoder:   (NSCoder*)encoder;

@property (retain,nonatomic) NSString*        lastFile;
@property (retain) NSMutableArray*  machines;
@end

extern NSString* ORPulseCheckModelLastFileChanged;
extern NSString* ORPulseCheckMachineAdded;
extern NSString* ORPulseCheckMachineRemoved;
extern NSString* ORPulseCheckModelReloadTable;
extern NSString* ORPulseCheckListLock;

@interface ORMachineToCheck : NSObject <NSCopying> {
    NSMutableDictionary*    data;
    ORAlarm*                noHeartbeatAlarm;
    ORFileGetterOp*         mover;
}
+ (id) machineToCheck;
- (id) copyWithZone:(NSZone *)zone;
- (void) setValue:(id)anObject forKey:(NSString*)aKey;
- (id)   valueForKey:(NSString*)aKey;
- (NSString*) ipNumber;
- (NSString*) username;
- (NSString*) password;
- (NSString*) heartbeatPath;
- (NSString*) lastChecked;
- (NSString*) status;
- (void)      setStatus:(NSString*)aString;
- (void)      setLastChecked:(NSString*)aDate;
- (NSString*) status;
- (void) doCheck:(NSOperationQueue*)fileQueue;
- (void) fileGetterIsDone;
- (NSString*)localPath;
- (void) postHeartbeatAlarm;
- (void) clearHeartbeatAlarm;
- (void) resetStatus;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

@property (retain) NSMutableDictionary* data;

@end
