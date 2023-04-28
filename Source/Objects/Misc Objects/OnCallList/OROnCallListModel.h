//
//  OROnCallListModel.h
//  Orca
//
//  Created by Mark Howe on Monday Oct 19 2015.
//  Copyright (c) 2015 University of North Carolina. All rights reserved.
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
#define kPersonRole      @"kPersonRole"
#define kPersonName      @"kPersonName"
#define kPersonAddress   @"kPersonAddress"
#define kPersonStatus    @"kPersonStatus"
#define kPersonTimeZone  @"kPersonTimeZone"

@class OROnCallPerson;
@class ORInFluxDBModel;
@interface OROnCallListModel : OrcaObject  {
    NSMutableArray* onCallList;
    NSString*       lastFile;
    NSString*       message;
    NSTimer*        notificationTimer;
    BOOL            primaryNotified;
    BOOL            secondaryNotified;
    BOOL            tertiaryNotified;
    BOOL            quaternaryNotified;
    NSDate*         timePrimaryNotified;
    NSDate*         timeSecondaryNotified;
    NSDate*         timeTertiaryNotified;
    NSDate*         timeQuaternaryNotified;
    BOOL            slackEnabled;
    BOOL            rocketChatEnabled;
}

#pragma mark •••Notifications
- (void) registerNotificationObservers;
- (void) alarmPosted:       (NSNotification*)aNote;
- (void) alarmCleared:      (NSNotification*)aNote;
- (void) alarmAcknowledged: (NSNotification*)aNote;
- (void) resetAll;
- (void) postAGlobalNotification;
- (void) loadBucket:(NSString*)aBucket inFluxDB:(ORInFluxDBModel*)influx;

#pragma mark •••Accessors
- (void) addPerson;
- (void) removeAll;
- (void) add:(NSString*)aName contact:(NSString*)contactInfo role:(int)aRole;
- (void) removePersonAtIndex:(int) anIndex;
- (id)   personAtIndex:      (int)anIndex;
- (void) personTakingNewRole:(id)aPerson;
- (void) startContactProcess;
- (uint32_t) onCallListCount;
- (OROnCallPerson*) primaryPerson:(BOOL)check;
- (OROnCallPerson*) secondaryPerson:(BOOL)check;
- (OROnCallPerson*) tertiaryPerson:(BOOL)check;
- (OROnCallPerson*) quaternaryPerson:(BOOL)check;
- (BOOL) notificationScheduled;
- (void) sendMessageToOnCallPerson;
- (void) broadcastMessage:(NSString*)aMessage;
- (void) sendShiftChangeMessage;
- (void) sendChatMessage:(NSString*)aMessage withList:(NSMutableArray*)aList;
- (void) sendChatMessage:(NSString*)aMessage withList:(NSMutableArray*)aList isAlarm:(BOOL)isAlarm;
- (BOOL) sendCurlMessage:(NSString*)type withArgs:(NSMutableArray*)args;

#pragma mark •••Save/Restore
- (void) saveToFile:        (NSString*)aPath;
- (void) restoreFromFile:   (NSString*)aPath;
- (id)   initWithCoder:     (NSCoder*)decoder;
- (void) encodeWithCoder:   (NSCoder*)encoder;

@property   (retain) NSMutableArray* onCallList;
@property   (retain,nonatomic) NSString* lastFile;
@property   (copy,nonatomic)   NSString* message;
@property   (retain) NSDate*         timePrimaryNotified;
@property   (retain) NSDate*         timeSecondaryNotified;
@property   (retain) NSDate*         timeTertiaryNotified;
@property   (retain) NSDate*         timeQuaternaryNotified;
@property   (assign) BOOL            primaryNotified;
@property   (assign) BOOL            secondaryNotified;
@property   (assign) BOOL            tertiaryNotified;
@property   (assign) BOOL            quaternaryNotified;
@property   (assign,nonatomic) BOOL  slackEnabled;
@property   (assign,nonatomic) BOOL  rocketChatEnabled;
@end

extern NSString* OROnCallListModelLastFileChanged;
extern NSString* OROnCallListPersonAdded;
extern NSString* OROnCallListPersonRemoved;
extern NSString* OROnCallListModelReloadTable;
extern NSString* OROnCallListListLock;
extern NSString* OROnCallListPeopleNotifiedChanged;
extern NSString* OROnCallListMessageChanged;
extern NSString* OROnCallListSlackChanged;
extern NSString* OROnCallListRocketChatChanged;
extern NSString* OROnCallListModelEdited;

@interface OROnCallPerson : NSObject <NSCopying> {
    NSMutableDictionary* data;
}
+ (id) onCallPerson;
+ (id) onCallPerson:(NSString*)aName address:(NSString*)contactInfo role:(int)aRole timeZone:(NSString*)timeZone;
- (id)copyWithZone:(NSZone *)zone;
- (void) setValue:(id)anObject forKey:(id)aKey;
- (id)   valueForKey:(id)aKey;
- (BOOL) isOnCall;
- (BOOL) hasSameRoleAs:(OROnCallPerson*)anOtherPerson;
- (void) takeOffCall;
- (BOOL) isPrimary;
- (BOOL) isSecondary;
- (BOOL) isTertiary;
- (BOOL) isQuaternary;
- (NSString*) name;
- (NSString*) address;
- (void)      setStatus:(NSString*)aString;
- (NSString*) status;
- (void) sendMessage:(NSString*)aMessage;
- (void) sendMessage:(NSString*)aMessage isAlarm:(BOOL)isAlarm;
- (NSString*) sendAlarmReport;
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (void) mailSent:(NSString*)to;
- (void) loadBucket:(NSString*)aBucket inFluxDB:(ORInFluxDBModel*)influx;
- (BOOL) checkTimeZone:(BOOL)check;
- (NSString*) timezone;

@property   (retain) NSMutableDictionary* data;

@end
