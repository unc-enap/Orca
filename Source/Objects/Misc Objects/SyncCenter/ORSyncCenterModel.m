//
//  ORSyncCenterModel.m
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
#import "ORSyncCenterModel.h"
#import "ORAlarm.h"
#import "OROnCallListModel.h"
#import "ORRemoteSocketModel.h"
#import "ORAlarmCollection.h"


#define kAllowedTimeout 5
#define kDoingOnCallList 0
#define kDoingAlarmList  1

NSString* ORSyncCenterLock                  = @"ORSyncCenterLock";
NSString* ORSyncCenterOrcaRemoved           = @"ORSyncCenterOrcaRemoved";
NSString* ORSyncCenterOrcaAdded             = @"ORSyncCenterOrcaAdded";
NSString* ORSyncCenterModelReloadTable      = @"ORSyncCenterModelReloadTable";

@interface ORSyncCenterModel (private)
- (OROnCallListModel*)      findOnCallList;
- (ORRemoteSocketModel*)    findSocket;
- (id)                      findObject:(NSString*)aClassName;
@end

@implementation ORSyncCenterModel
@synthesize orcaList,syncCommander;

- (void) makeMainController
{
    [self linkToController:@"ORSyncCenterController"];
}

- (void) dealloc
{
 	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
   
    self.orcaList = nil;
    self.syncCommander = nil;
    
    [super dealloc];
}

- (void) setUpImage     { [self setImage:[NSImage imageNamed:@"SyncCenter"]]; }
- (BOOL) solitaryObject { return YES; }

#pragma mark ***Sync Methods
- (void) syncNow
{
    if(!syncCommander){
        int i;
        for(i =0;i<[orcaList count];i++){
            [[orcaList objectAtIndex:i] setObject:@"" forKey:@"kOnCallSyncState"];
            [[orcaList objectAtIndex:i] setObject:@"" forKey:@"kAlarmSyncState"];
        }
        self.syncCommander = [[[ORSyncCommander alloc] initWithDelegate:self] autorelease];
    }
    if(![syncCommander isRunning])[syncCommander start];
    else                          [syncCommander stop];
}

- (void) syncDone
{
    [syncCommander autorelease];
    syncCommander = nil;
}

- (void) setStatus:(int)index state:(NSString*)aState
{
    if(index < [orcaList count]){
        NSString* key;
        if([syncCommander workPhase] == kDoingOnCallList)   key = @"kOnCallSyncState";
        else                                                key = @"kAlarmSyncState";
        [[orcaList objectAtIndex:index] setObject:aState forKey:key];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSyncCenterModelReloadTable object:self];
   }
}

- (BOOL) okToSyncOnCallList:(int)index
{
    if(index < [orcaList count]){
        return [[[orcaList objectAtIndex:index] objectForKey:@"kSyncOnCallList"] boolValue];
    }
    return NO;
}

- (BOOL) okToSyncAlarmList:(int)index
{
    if(index < [orcaList count]){
        return [[[orcaList objectAtIndex:index] objectForKey:@"kSyncAlarmList"] boolValue];
    }
    return NO;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [notifyCenter addObserver : self
                     selector : @selector(doDelayedSync:)
                         name : OROnCallListModelEdited
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(doDelayedSync:)
                         name : ORAlarmEMailListEdited
                       object : nil];
}

- (void) doDelayedSync:(NSNotification*)aNote
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedSync) object:nil];
    [self performSelector:@selector(delayedSync) withObject:[aNote object] afterDelay:30];
}
      
- (void) delayedSync
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(delayedSync) object:nil];
    [syncCommander stop];
    [self syncNow];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    
    [[self undoManager] disableUndoRegistration];
    self.orcaList =   [decoder decodeObjectForKey:@"orcaList"];
    [[self undoManager] enableUndoRegistration];
    
    [self registerNotificationObservers];

    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:orcaList    forKey:@"orcaList"];
}

#pragma mark •••CardHolding Protocol
- (int) maxNumberOfObjects	{ return 2;     }
- (int) objWidth			{ return 100;   }
- (int) groupSeparation		{ return 0;     }

- (NSString*) nameForSlot:(int)aSlot
{
    return [NSString stringWithFormat:@"Slot %d",aSlot];
}

- (NSRange) legalSlotsForObj:(id)anObj
{
	if(     [anObj isKindOfClass:NSClassFromString(@"OROnCallListModel")])		return NSMakeRange(0,1);
	else if([anObj isKindOfClass:NSClassFromString(@"ORRemoteSocketModel")])	return NSMakeRange(1,1);
    else return NSMakeRange(0,0);
}

- (BOOL) slot:(int)aSlot excludedFor:(id)anObj
{
	if(aSlot      == 0 && [anObj isKindOfClass:NSClassFromString(@"OROnCallListModel")])      return NO;
	else if(aSlot == 1 && [anObj isKindOfClass:NSClassFromString(@"ORRemoteSocketModel")])	  return NO;
    else return YES;
}

- (int) slotAtPoint:(NSPoint)aPoint
{
	return floor(((int)aPoint.x)/[self objWidth]);
}

- (NSPoint) pointForSlot:(int)aSlot
{
	return NSMakePoint(aSlot*[self objWidth],0);
}

- (void) place:(id)anObj intoSlot:(int)aSlot
{
    [anObj setTag:aSlot];
	NSPoint slotPoint = [self pointForSlot:aSlot];
	[anObj moveTo:slotPoint];
}

- (NSUInteger) slotForObj:(id)anObj
{
    return [anObj tag];
}

- (int) numberSlotsNeededFor:(id)anObj
{
	return 1;
}

- (id)   remoteSocket;
{
    return [self findObject:@"ORRemoteSocketModel"];
}

- (void) addOrca
{
    if(!orcaList) self.orcaList = [NSMutableArray array];
    id entry = [NSMutableDictionary dictionary];
    [entry setObject:[NSNumber numberWithInt:1] forKey:@"kSyncOnCallList"];
    [entry setObject:[NSNumber numberWithInt:1] forKey:@"kSyncAlarmList"];
    [self addOrca:entry atIndex:[orcaList count]];
}

- (void) addOrca:(id)anAddress atIndex:(NSUInteger)anIndex
{
    if(!orcaList) self.orcaList = [NSMutableArray array];
    if([orcaList count] == 0) anIndex = 0;
    anIndex = MIN(anIndex,[orcaList count]);
    [[[(ORAppDelegate*)[NSApp delegate] undoManager] prepareWithInvocationTarget:self] removeOrcaAtIndex:anIndex];
    [orcaList insertObject:anAddress atIndex:anIndex];
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:anIndex] forKey:@"Index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSyncCenterOrcaAdded object:self userInfo:userInfo];
}

- (void) removeOrcaAtIndex:(NSUInteger) anIndex
{
    id anOrca = [orcaList objectAtIndex:anIndex];
    [[[(ORAppDelegate*)[NSApp delegate] undoManager] prepareWithInvocationTarget:self] addOrca:anOrca atIndex:anIndex];
    [orcaList removeObjectAtIndex:anIndex];
    NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:anIndex] forKey:@"Index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSyncCenterOrcaRemoved object:self userInfo:userInfo];
}
- (NSArray*) orcaList
{
    return orcaList;
}

- (NSUInteger)  orcaCount
{
    return [orcaList count];
}

- (void) setIndex:(NSUInteger)anIndex value:(id)anObject forKey:(id)aKey
{
    if(!anObject)anObject = @"";
    if(anIndex < [orcaList count]){
        NSMutableDictionary* anItem = [orcaList objectAtIndex:anIndex];
        [[[(ORAppDelegate*)[NSApp delegate] undoManager] prepareWithInvocationTarget:self] setIndex:anIndex value:[anItem objectForKey:aKey] forKey:aKey];
        [anItem setObject:anObject forKey:aKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSyncCenterModelReloadTable object:self];
    }
}
@end

@implementation ORSyncCenterModel (private)
- (OROnCallListModel*)   findOnCallList	{ return [self findObject:@"OROnCallListModel"]; }
- (ORRemoteSocketModel*) findSocket		{ return [self findObject:@"ORRemoteSocketModel"]; }
- (id) findObject:(NSString*)aClassName
{
	for(OrcaObject* anObj in [self orcaObjects]){
		if([anObj isKindOfClass:NSClassFromString(aClassName)])return anObj;
	}
	return nil;
}
@end

NSString* ORSyncCommanderIsRunningChanged = @"ORSyncCommanderIsRunningChanged";
NSString* ORSyncCommanderStateChanged     = @"ORSyncCommanderStateChanged";

@implementation ORSyncCommander


@synthesize delegate,isRunning,nextState,ipAddress,onCallList,alarmList,stepDelay,workingIndex,workPhase;

- (id) initWithDelegate:(ORSyncCenterModel*)aDelegate
{
    self = [super init];
    self.delegate  = aDelegate;
    self.stepDelay = .3; //default
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    self.delegate    = nil;
    self.ipAddress   = nil;
    self.onCallList  = nil;
    self.alarmList = nil;
    
    [super dealloc];
}

- (void) start
{
    [self setNextState:kSyncCommander_GetOnCallList]; //first state

    self.isRunning = YES;
    [self performSelector:@selector(step) withObject:nil afterDelay:.1];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSyncCommanderIsRunningChanged object:self];
}

- (void) stop
{
    self.isRunning = NO;
    self.nextState   = kSyncCommander_Done;
    [delegate setStatus:workingIndex state:@"Manual Stop"];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSyncCommanderIsRunningChanged object:self];
}


- (void) setNextState:(int)aState
{
    if(nextState != aState){
        timeInState = 0;
    }
    nextState  = aState;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSyncCommanderStateChanged object:self];
}

- (int) numStates { return kSyncCommander_NumStates;}

- (void) step
{
    //this state machine loops thru twice, once for the on-call list and once for the alarm email list
    NSMutableArray* cmdList  = nil;;
    NSString*       response = nil;
    [NSObject       cancelPreviousPerformRequestsWithTarget:self selector:@selector(step) object:nil];

    switch (nextState){
            
        case kSyncCommander_GetOnCallList:
            workPhase           = kDoingOnCallList;
            workingIndex        = 0;
            self.onCallList     = [[delegate findOnCallList] onCallList];
            [self setNextState:kSyncCommander_SyncSetIpAddress];
            [delegate setStatus:workingIndex state:@"Get On-Call List"];
            break;
        
        case kSyncCommander_GetAlarmList:
            workPhase           = kDoingAlarmList;
            workingIndex        = 0;
            self.alarmList      = [[ORAlarmCollection sharedAlarmCollection] eMailList];
            [self setNextState:kSyncCommander_SyncSetIpAddress];
            [delegate setStatus:workingIndex state:@"Get Alarm eMail List"];
            break;
            
        case kSyncCommander_SyncSetIpAddress:
            if( ((workPhase == kDoingOnCallList) && [delegate okToSyncOnCallList:workingIndex]) ||
                ((workPhase == kDoingAlarmList)  && [delegate okToSyncAlarmList:workingIndex]  ) ){
                self.ipAddress = [[[delegate orcaList] objectAtIndex:workingIndex] objectForKey:@"kIpAddress"];
                [delegate setStatus:workingIndex state:@"Set Up Socket"];

                [[delegate undoManager] disableUndoRegistration];
                [[delegate findSocket] disconnect];
                [[delegate findSocket] setRemoteHost:ipAddress];
                [[delegate undoManager] enableUndoRegistration];
                [self setNextState:kSyncCommander_SendCmds];
            }
            else {
                [self setNextState:kSyncCommander_IncWorkingIndex];
                [delegate setStatus:workingIndex state:@"Skipped"];
            }
          break;
            
        case kSyncCommander_SendCmds:
            self.remoteOpStatus = nil;
            cmdList = [NSMutableArray array];
            if(workPhase == kDoingOnCallList){
                [cmdList addObject:@"[OROnCallListModel,1 removeAll];"];
                for(id aPerson in self.onCallList){
                    NSString* aCmd = [NSString stringWithFormat:@"[OROnCallListModel,1 add:\"%@\" contact:\"%@\" role:%d];",[aPerson name],[aPerson address],[[aPerson valueForKey:kPersonRole] intValue]];
                    [cmdList addObject:aCmd];
                }
                [cmdList addObject:@"listCount=[OROnCallListModel,1 onCallListCount];"];
            }
            else {
                [cmdList addObject:@"[ORAlarmCollection removeAllAddresses];"];
                for(ORAlarmEMailDestination* anEntry in self.alarmList){
                    NSString* aCmd = [NSString stringWithFormat:@"[ORAlarmCollection addAddress:\"%@\" severityMask:%u];",[anEntry mailAddress],[anEntry severityMask]];
                    [cmdList addObject:aCmd];
                }
                [cmdList addObject:[NSString stringWithFormat:@"[ORAlarmCollection setEmailEnabled:%d];",[[ORAlarmCollection sharedAlarmCollection] emailEnabled]]];
                [cmdList addObject:@"listCount=[ORAlarmCollection eMailCount];"];
           }
            
            [self sendCommands:cmdList remoteSocket:[delegate findSocket]];
            [delegate setStatus:workingIndex state:@"Connecting"];

            [self setNextState:kSyncCommander_WaitOnConnection];
           break;
            
        case kSyncCommander_WaitOnConnection:
            if([[remoteOpStatus objectForKey:@"connected"] boolValue]==YES){
                [delegate setStatus:workingIndex state:@"Synchronizing"];
                [self setNextState:kSyncCommander_CheckListCount];
            }
            else {
                if(timeInState > kAllowedTimeout){
                     NSLogColor([NSColor redColor],@"No Connection to %@. Unable to sync %@ list\n",self.ipAddress,[self workTypePhrase]);
                    [delegate setStatus:workingIndex state:@"Connect Error"];
                    [self setNextState:kSyncCommander_IncWorkingIndex];
                }
            }
            break;
            
        case kSyncCommander_CheckListCount:
            response = [remoteOpStatus objectForKey:@"listCount"];
            if(response){
                NSUInteger countToMatch;
                if(workPhase==kDoingOnCallList) countToMatch = [onCallList count];
                else                            countToMatch = [[ORAlarmCollection sharedAlarmCollection] eMailCount];
                if([response intValue] != countToMatch){
                    [delegate setStatus:workingIndex state:@"Sync Error"];

                    NSLogColor([NSColor redColor],@"List count mismatch for %@. Unable to sync list for %@. Remote list doesn't match after attempt.\n",[self workTypePhrase],self.ipAddress);
                }
                else {
                    [delegate setStatus:workingIndex state:@"Synced"];
                }
                [self setNextState:kSyncCommander_IncWorkingIndex];
            }
            else {
                if(timeInState>kAllowedTimeout){
                    [delegate setStatus:workingIndex state:@"Timeout"];
                    NSLogColor([NSColor redColor],@"Timeout. Unable to sync %@ list for %@\n",[self workTypePhrase],self.ipAddress);
                    [self setNextState:kSyncCommander_IncWorkingIndex];
                }
            }
            break;
            
        case kSyncCommander_IncWorkingIndex:
            workingIndex++;
            if(workingIndex > [delegate orcaCount]-1){
                if(workPhase == kDoingOnCallList){
                    [self setNextState:kSyncCommander_GetAlarmList];
                }
                else [self setNextState:kSyncCommander_Done];
            }
            else {
                [self setNextState:kSyncCommander_SyncSetIpAddress];
            }
            break;
    }
    
    if(nextState == kSyncCommander_Done){
        self.remoteOpStatus = nil;
        self.isRunning = NO;
        if([delegate respondsToSelector:@selector(syncDone)]){
            [delegate syncDone];
        }
    }
    else {
        [self performSelector:@selector(step) withObject:nil afterDelay:self.stepDelay];
        timeInState += self.stepDelay;
    }
}
- (NSString*) workTypePhrase
{
    NSString* s;
    if(workPhase == kDoingOnCallList)s = @"on-call";
    else                             s = @"alarm eMail";
    return s;
}
@end

