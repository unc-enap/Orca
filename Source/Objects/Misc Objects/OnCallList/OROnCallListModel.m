//
//  OROnCallListModel.m
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

#pragma mark •••Imported Files
#import "OROnCallListModel.h"
#import "ORAlarm.h"
#import "ORAlarmCollection.h"
#import "ORMailer.h"
#import "ORPreferencesController.h"
#import "ORInFluxDBModel.h"

#pragma mark •••Local Strings
NSString* OROnCallListModelLastFileChanged	= @"OROnCallListModelLastFileChanged";
NSString* OROnCallListPersonAdded           = @"OROnCallListPersonAdded";
NSString* OROnCallListPersonRemoved         = @"OROnCallListPersonRemoved";
NSString* OROnCallListListLock              = @"OROnCallListListLock";
NSString* OROnCallListModelReloadTable      = @"OROnCallListModelReloadTable";
NSString* OROnCallListPeopleNotifiedChanged = @"OROnCallListPeopleNotifiedChanged";
NSString* OROnCallListMessageChanged        = @"OROnCallListMessageChanged";
NSString* OROnCallListSlackChanged          = @"OROnCallListSlackChanged";
NSString* OROnCallListRocketChatChanged     = @"OROnCallListRocketChatChanged";
NSString* OROnCallListModelEdited           = @"OROnCallListModelEdited";

#define kOnCallAlarmWaitTime        3*60
#define kOnCallAcknowledgeWaitTime 10*60

@interface OROnCallListModel (private)
- (void) postCouchDBRecord;
- (void) postCouchDBRecord:(BOOL)alsoToHistory;
@end


@implementation OROnCallListModel

@synthesize onCallList,lastFile,primaryNotified,secondaryNotified,tertiaryNotified,quaternaryNotified;
@synthesize timePrimaryNotified,timeSecondaryNotified,timeTertiaryNotified,timeQuaternaryNotified,message;
@synthesize slackEnabled,rocketChatEnabled;

#pragma mark •••initialization

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    //properties can be released like this:
    self.onCallList             = nil;
    self.message                = nil;
    self.lastFile               = nil;
    self.timePrimaryNotified    = nil;
    self.timeSecondaryNotified  = nil;
    self.timeTertiaryNotified   = nil;
    self.timeQuaternaryNotified   = nil;
    
    [notificationTimer invalidate];
    [notificationTimer release];
    
    [super dealloc];
}

- (BOOL) solitaryObject     { return YES; }
- (void) setUpImage         { [self setImage:[NSImage imageNamed:@"OnCallList"]]; }
- (void) makeMainController { [self linkToController:@"OROnCallListController"];  }
- (NSString*) helpURL       { return @"Subsystems/On_Call_List.html";             }

- (void) awakeAfterDocumentLoaded
{
    [self postCouchDBRecord];
}
- (BOOL) acceptsGuardian: (OrcaObject *)aGuardian
{
    return [super acceptsGuardian:aGuardian] ||
           [aGuardian isMemberOfClass:NSClassFromString(@"ORSyncCenterModel")];
}

#pragma mark ***Accessors
- (void) postAGlobalNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListModelEdited object:self];
}

- (void) setLastFile:(NSString*)aPath
{
    [lastFile autorelease];
    lastFile = [aPath copy];

    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListModelLastFileChanged object:self];
}

- (void) setMessage:(NSString*)aString
{
    if(!aString)aString = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setMessage:message];
    [message autorelease];
    message = [aString copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListMessageChanged object:self];
}

- (void) addPerson
{
    if(!onCallList)self.onCallList = [NSMutableArray array];
    [onCallList addObject:[OROnCallPerson onCallPerson]];
    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListPersonAdded object:self];
    [self postAGlobalNotification];
}

- (void) removeAll
{
    [onCallList release];
    onCallList = nil;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListModelReloadTable object:self];
}

- (void) add:(NSString*)aName contact:(NSString*)contactInfo role:(int)aRole timeZone:(NSString*)timeZone
{
    if(!onCallList)self.onCallList = [NSMutableArray array];
    OROnCallPerson* aPerson = [OROnCallPerson onCallPerson:aName address:contactInfo role:aRole timeZone:timeZone];
    [onCallList addObject:aPerson];
    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListPersonAdded object:self];
}

- (void)add:(NSString *)aName contact:(NSString *)contactInfo role:(int)aRole {
    if(!onCallList)self.onCallList = [NSMutableArray array];
    OROnCallPerson* aPerson = [OROnCallPerson onCallPerson:aName address:contactInfo role:aRole timeZone:@""];
    [onCallList addObject:aPerson];
    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListPersonAdded object:self];
}

- (void) removePersonAtIndex:(int) anIndex
{
    if(anIndex < [onCallList count]){
        [onCallList removeObjectAtIndex:anIndex];
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:anIndex] forKey:@"Index"];
        [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListPersonRemoved object:self userInfo:userInfo];
        [self postAGlobalNotification];
   }
}

- (id) personAtIndex:(int)anIndex
{
	if(anIndex>=0 && anIndex<[onCallList count])return [onCallList objectAtIndex:anIndex];
	else return nil;
}

- (uint32_t) onCallListCount { return (uint32_t)[onCallList count]; }
- (BOOL) notificationScheduled
{
    return notificationTimer != nil;
}

- (void) personTakingNewRole:(id)newPerson;
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(sendShiftChangeMessage) object:nil];
    [self performSelector:@selector(sendShiftChangeMessage) withObject:nil afterDelay:60];
    //for all on-call roles, only one person is designated
    if([newPerson isOnCall]){
        //someone else can now be relieved
        for(OROnCallPerson* aPerson in onCallList){
            [aPerson setStatus:@""];
            if(aPerson != newPerson){
                if([aPerson isOnCall] && [aPerson hasSameRoleAs:newPerson]){
                    [aPerson takeOffCall];
                }
            }
        }
    }
    else {
        [newPerson takeOffCall];
    }
    //now the roles are:
    OROnCallPerson* primary       = [self primaryPerson];
    OROnCallPerson* secondary     = [self secondaryPerson];
    OROnCallPerson* tertiary      = [self tertiaryPerson];
    OROnCallPerson* quaternary    = [self quaternaryPerson];
    //find new primary
    if(!primary && (secondary || tertiary || quaternary)){
        if(secondary)       [secondary   setValue:[NSNumber numberWithInt:1] forKey:kPersonRole];
        else if(tertiary)   [tertiary    setValue:[NSNumber numberWithInt:1] forKey:kPersonRole];
        else                [quaternary  setValue:[NSNumber numberWithInt:1] forKey:kPersonRole];
    }
    
    //find new secondary
    secondary     = [self secondaryPerson];
    tertiary      = [self tertiaryPerson];
    quaternary    = [self quaternaryPerson];
    if(!secondary && (tertiary || quaternary)){
        [tertiary  setValue:[NSNumber numberWithInt:2] forKey:kPersonRole];
    }
    
    //find new tertiary
    tertiary      = [self tertiaryPerson];
    quaternary    = [self quaternaryPerson];
    if(!tertiary && quaternary){
        [quaternary  setValue:[NSNumber numberWithInt:3] forKey:kPersonRole];
    }
    
    //with a new role(s) we reset the notification if needed
    NSArray* allAlarms  = [[ORAlarmCollection sharedAlarmCollection] alarms];
    for(id anAlarm in allAlarms){
        if(![anAlarm acknowledged] && [anAlarm severity]>kSetupAlarm){
            [notificationTimer invalidate];
            [notificationTimer release];
            notificationTimer = nil;
            [self startContactProcess];
            break;
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListModelReloadTable object:self];
    [self postCouchDBRecord:YES];
    [self postAGlobalNotification];
}

-(void) setSlackEnabled:(BOOL)enabled
{
    slackEnabled = enabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListSlackChanged object:self];
}

-(void) setRocketChatEnabled:(BOOL)enabled
{
    rocketChatEnabled = enabled;
    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListRocketChatChanged object:self];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [notifyCenter addObserver : self
                     selector : @selector(alarmPosted:)
                         name : ORAlarmWasPostedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(alarmCleared:)
                         name : ORAlarmWasClearedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(alarmAcknowledged:)
                         name : ORAlarmWasAcknowledgedNotification
                       object : nil];
}

- (void) alarmPosted:(NSNotification*)aNote
{
    ORAlarm* theAlarm = [aNote object];
    if([theAlarm severity]>kSetupAlarm){
        [self startContactProcess];
    }
}

- (void) startContactProcess
{
    OROnCallPerson* primary      = [self primaryPerson:NO];
    OROnCallPerson* secondary    = [self secondaryPerson:YES];
    OROnCallPerson* tertiary     = [self tertiaryPerson:YES];
    OROnCallPerson* quaternary   = [self quaternaryPerson:YES];

    if(!notificationTimer && (primary || secondary || tertiary || quaternary)){
        notificationTimer = [[NSTimer scheduledTimerWithTimeInterval:kOnCallAlarmWaitTime target:self selector:@selector(notifyPrimary:) userInfo:nil repeats:NO] retain];
         NSDate* contactDate = [[NSDate date] dateByAddingTimeInterval:kOnCallAcknowledgeWaitTime];
        if([self primaryPerson:YES]){
            [primary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
            if(secondary)         [secondary setStatus:@"Next on deck"];
            else if(tertiary)     [tertiary  setStatus:@"Next on deck"];
            else if(quaternary)   [quaternary  setStatus:@"Next on deck"];
        }
        else if(secondary){
            [secondary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
            if(tertiary)          [tertiary  setStatus:@"Next on deck"];
            else if(quaternary)   [quaternary  setStatus:@"Next on deck"];
        }
        else if(tertiary){
            [tertiary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
            if(quaternary)   [quaternary  setStatus:@"Next on deck"];
        }
        else if(quaternary){
            [quaternary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
        }
    }
    [self postCouchDBRecord];
    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListPeopleNotifiedChanged object:self];
}

- (void) sendMessageToOnCallPerson
{
    OROnCallPerson* primary     = [self primaryPerson];
    OROnCallPerson* secondary   = [self secondaryPerson];
    OROnCallPerson* tertiary    = [self tertiaryPerson];
    OROnCallPerson* quaternary  = [self quaternaryPerson];
    NSMutableArray* rlist = [[[NSMutableArray alloc] init] autorelease];
    if(primary){
        [primary sendMessage:message];
        [rlist addObject:[[[primary name] copy]autorelease]];
    }
    else if(secondary){
        [secondary sendMessage:message];
        [rlist addObject:[[[secondary name] copy]autorelease]];
    }
    else if(tertiary){
        [tertiary sendMessage:message];
        [rlist addObject:[[[tertiary name] copy]autorelease]];
    }
    else if(quaternary){
        [quaternary sendMessage:message];
        [rlist addObject:[[[quaternary name] copy]autorelease]];
    }
    else NSLog(@"No on call person to send message to!\n");
    if([rlist count]) [self sendChatMessage:message withList:rlist];
}

- (void) broadcastMessage:(NSString*)aMessage
{
    if([aMessage length]){
        [[self primaryPerson]     sendMessage:aMessage];
        [[self secondaryPerson]   sendMessage:aMessage];
        [[self tertiaryPerson]    sendMessage:aMessage];
        [[self quaternaryPerson]  sendMessage:aMessage];
        NSMutableArray* rlist = [[[NSMutableArray alloc] init] autorelease];
        if([[[self primaryPerson] address]   length]) [rlist addObject: [[[[self primaryPerson]   name] copy]autorelease]];
        if([[[self secondaryPerson] address] length]) [rlist addObject:[[[[self secondaryPerson] name] copy]autorelease]];
        if([[[self tertiaryPerson] address]  length]) [rlist addObject: [[[[self tertiaryPerson]  name] copy]autorelease]];
        if([[[self quaternaryPerson] address]  length]) [rlist addObject: [[[[self quaternaryPerson]  name] copy]autorelease]];
        if([rlist count]) [self sendChatMessage:aMessage withList:rlist];
    }
}

- (OROnCallPerson*) primaryPerson:(BOOL)check
{
    for(OROnCallPerson* aPerson in onCallList){
        if([aPerson isPrimary] && [aPerson checkTimeZone:check])return aPerson;
    }
    return nil;
}

- (OROnCallPerson*) primaryPerson
{
    return [self primaryPerson:NO];
}

- (OROnCallPerson*) secondaryPerson:(BOOL)check
{
    for(OROnCallPerson* aPerson in onCallList){
        if([aPerson isSecondary] && [aPerson checkTimeZone:check])return aPerson;
    }
    return nil;
}

- (OROnCallPerson*) secondaryPerson
{
    return [self secondaryPerson:NO];
}

- (OROnCallPerson*) tertiaryPerson:(BOOL)check
{
    for(OROnCallPerson* aPerson in onCallList){
        if([aPerson isTertiary] && [aPerson checkTimeZone:check])return aPerson;
    }
    return nil;
}

- (OROnCallPerson*) tertiaryPerson
{
    return [self tertiaryPerson:NO];
}

- (OROnCallPerson*) quaternaryPerson:(BOOL)check
{
    for(OROnCallPerson* aPerson in onCallList){
        if([aPerson isQuaternary] && [aPerson checkTimeZone:check])return aPerson;
    }
    return nil;
}

- (OROnCallPerson*) quaternaryPerson
{
    return [self quaternaryPerson:NO];
}

- (void) resetAll
{
    [notificationTimer invalidate];
    [notificationTimer release];
    notificationTimer   = nil;
    
    self.primaryNotified       = NO;
    self.secondaryNotified     = NO;
    self.tertiaryNotified      = NO;
    self.quaternaryNotified    = NO;
    for(OROnCallPerson* aPerson in onCallList){
        [aPerson setStatus:@""];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListPeopleNotifiedChanged object:self];
}

- (void) alarmCleared:(NSNotification*)aNote
{
    //if all alarms cleared cancel all timers, no need to alert anyone
    NSArray* allAlarms  = [[ORAlarmCollection sharedAlarmCollection] alarms];
    BOOL allCleared     = YES;
    for(id anAlarm in allAlarms){
        if(![anAlarm acknowledged] && [anAlarm severity]>kSetupAlarm){
            allCleared = NO;
            break;
        }
    }
    if(allCleared)[self resetAll];
}

- (void) alarmAcknowledged:(NSNotification*)aNote
{
   //if all alarms acknowledged cancel all timers, no need to alert anyone
    NSArray* allAlarms   = [[ORAlarmCollection sharedAlarmCollection] alarms];
    BOOL allAcknowledged = YES;
    for(id anAlarm in allAlarms){
        if(![anAlarm acknowledged] && [anAlarm severity]>kSetupAlarm){
            allAcknowledged = NO;
            break;
        }
    }
    if(allAcknowledged){
        [self resetAll];
    }
 }

- (void) notifyPrimary:(NSTimer*)aTimer
{
    [notificationTimer invalidate];
    [notificationTimer release];
    notificationTimer = nil;

    OROnCallPerson* primary     = [self primaryPerson:YES];
    OROnCallPerson* secondary   = [self secondaryPerson:YES];
    OROnCallPerson* tertiary    = [self tertiaryPerson:YES];
    OROnCallPerson* quaternary  = [self quaternaryPerson:YES];

    if(primary){
        NSString* report = [primary sendAlarmReport];
        if(report){
            NSMutableArray* rlist = [NSMutableArray arrayWithObjects:[[[primary name] copy] autorelease], nil];
            [self sendChatMessage:report withList:rlist isAlarm:YES];
        }
        self.primaryNotified        = YES;
        self.timePrimaryNotified    = [NSDate date];
        if(!notificationTimer){
            notificationTimer = [[NSTimer scheduledTimerWithTimeInterval:kOnCallAcknowledgeWaitTime target:self selector:@selector(notifySecondary:) userInfo:nil repeats:NO] retain];
            NSDate* contactDate = [[NSDate date] dateByAddingTimeInterval:kOnCallAcknowledgeWaitTime];
            
            if(secondary){
                [secondary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
                if(tertiary)     [tertiary  setStatus:@"Next on deck"];
                else if(quaternary)   [quaternary  setStatus:@"Next on deck"];
            }
            else if(tertiary){
                [tertiary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
                if(quaternary)   [quaternary  setStatus:@"Next on deck"];
            }
            else if(quaternary)[quaternary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListPeopleNotifiedChanged object:self];
    }
    else {
        [self notifySecondary:nil];
    }
}

- (void) notifySecondary:(NSTimer*)aTimer
{
    OROnCallPerson* secondary   = [self secondaryPerson:YES];
    OROnCallPerson* tertiary    = [self tertiaryPerson:YES];
    OROnCallPerson* quaternary  = [self quaternaryPerson:YES];
    if(secondary){
        [notificationTimer invalidate];
        [notificationTimer release];
        notificationTimer = nil;

        NSString* report = [secondary sendAlarmReport];
        if(report){
            NSMutableArray* rlist = [NSMutableArray arrayWithObjects:[[[secondary name] copy] autorelease], nil];
            [self sendChatMessage:report withList:rlist isAlarm:YES];
        }
        self.secondaryNotified = YES;
        self.timeSecondaryNotified = [NSDate date];
        if(!notificationTimer){
            notificationTimer = [[NSTimer scheduledTimerWithTimeInterval:kOnCallAcknowledgeWaitTime target:self selector:@selector(notifyTertiary:) userInfo:nil repeats:NO] retain];
            NSDate* contactDate = [[NSDate date] dateByAddingTimeInterval:kOnCallAcknowledgeWaitTime];
            
            if(tertiary){
                [tertiary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
                if(quaternary)   [quaternary  setStatus:@"Next on deck"];
            }
            else if(quaternary)[quaternary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListPeopleNotifiedChanged object:self];
    }
    else {
        [self notifyTertiary:nil];
    }
}

- (void) notifyTertiary:(NSTimer*)aTimer
{
    OROnCallPerson* tertiary    = [self tertiaryPerson:YES];
    OROnCallPerson* quaternary  = [self quaternaryPerson:YES];
    if(tertiary){
        [notificationTimer invalidate];
        [notificationTimer release];
        notificationTimer = nil;

        NSString* report = [tertiary sendAlarmReport];
        if(report){
            NSMutableArray* rlist = [NSMutableArray arrayWithObjects:[[[tertiary name] copy] autorelease], nil];
            [self sendChatMessage:report withList:rlist isAlarm:YES];
        }
        self.tertiaryNotified = YES;
        self.timeTertiaryNotified = [NSDate date];
        if(!notificationTimer){
            notificationTimer = [[NSTimer scheduledTimerWithTimeInterval:kOnCallAcknowledgeWaitTime target:self selector:@selector(notifyQuaternary:) userInfo:nil repeats:NO] retain];
            NSDate* contactDate = [[NSDate date] dateByAddingTimeInterval:kOnCallAcknowledgeWaitTime];
            
            if(quaternary)[quaternary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListPeopleNotifiedChanged object:self];
    }
    else {
        [self notifyQuaternary:nil];
    }
}

- (void) notifyQuaternary:(NSTimer*)aTimer
{
    [notificationTimer invalidate];
    [notificationTimer release];
    notificationTimer = nil;
    
    OROnCallPerson* primary     = [self primaryPerson:NO];
    OROnCallPerson* quaternary  = [self quaternaryPerson:YES];
    if(quaternary){
        NSString* report = [quaternary sendAlarmReport];
        if(report){
            NSMutableArray* rlist = [NSMutableArray arrayWithObjects:[[[quaternary name] copy] autorelease], nil];
            [self sendChatMessage:report withList:rlist isAlarm:YES];
        }
        self.quaternaryNotified       = YES;
        self.timeQuaternaryNotified   = [NSDate date];
        if(!notificationTimer && !self.primaryNotified){
            notificationTimer = [[NSTimer scheduledTimerWithTimeInterval:kOnCallAcknowledgeWaitTime target:self selector:@selector(forceNotifyPrimary:) userInfo:nil repeats:NO] retain];
            if(primary){
                NSDate* contactDate = [[NSDate date] dateByAddingTimeInterval:kOnCallAcknowledgeWaitTime];
               [primary setStatus:[NSString stringWithFormat:@"Will Force Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListPeopleNotifiedChanged object:self];
    }
    else {
        // else force-notify primary, if hasn't been notified
        [self forceNotifyPrimary:nil];
    }
}

- (void) forceNotifyPrimary:(NSTimer*)aTimer
{
    [notificationTimer invalidate];
    [notificationTimer release];
    notificationTimer = nil;

    OROnCallPerson* primary     = [self primaryPerson:NO];

    if(primary){
        NSString* report = [primary sendAlarmReport];
        if(report){
            NSMutableArray* rlist = [NSMutableArray arrayWithObjects:[[[primary name] copy] autorelease], nil];
            [self sendChatMessage:report withList:rlist isAlarm:YES];
        }
        self.primaryNotified        = YES;
        self.timePrimaryNotified    = [NSDate date];
        [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListPeopleNotifiedChanged object:self];
    }
}

#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setLastFile:  [decoder decodeObjectForKey:@"lastFile"]];
    [self setMessage:   [decoder decodeObjectForKey:@"message"]];
    onCallList =        [[decoder decodeObjectForKey:@"onCallList"] retain];
    slackEnabled =       [[decoder decodeObjectForKey:@"slackEnabled"] boolValue];
    rocketChatEnabled =  [[decoder decodeObjectForKey:@"rocketChatEnabled"] boolValue];
	
    if([lastFile length] == 0)self.lastFile = @"";
    
    [self registerNotificationObservers];

    [[self undoManager] enableUndoRegistration];
    
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
	[encoder encodeObject:lastFile      forKey:@"lastFile"];
    [encoder encodeObject:onCallList    forKey:@"onCallList"];
    [encoder encodeObject:message       forKey:@"message"];
    [encoder encodeObject:[NSNumber numberWithBool:slackEnabled]  forKey:@"slackEnabled"];
    [encoder encodeObject:[NSNumber numberWithBool:rocketChatEnabled] forKey:@"rocketChatEnabled"];
}

- (void) saveToFile:(NSString*)aPath
{
    [self setLastFile:aPath];
    [NSKeyedArchiver archiveRootObject:onCallList toFile:aPath];
}

- (void) restoreFromFile:(NSString*)aPath
{
	[self setLastFile:aPath];
    [onCallList release];
    NSArray* contents = [NSKeyedUnarchiver unarchiveObjectWithFile:[aPath stringByExpandingTildeInPath]];
    onCallList = [contents mutableCopy];
    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListModelReloadTable object:self];
}

- (void) sendShiftChangeMessage
{
    NSMutableString* messageToSend = [NSMutableString stringWithString:@""];
    if([self primaryPerson] || [self secondaryPerson] || [self tertiaryPerson] || [self quaternaryPerson]){
        
        [messageToSend appendFormat:@"The On-list has been changed.\n"];
        [messageToSend appendString:@"Here are the new shift responsibilities:\n\n"];
        
        if([self primaryPerson]){
            [messageToSend appendFormat:@"Primary: %@",[[self primaryPerson] name]];
            if([NSTimeZone timeZoneWithName:[[self primaryPerson] timezone]]){
                [messageToSend appendFormat:@", Time Zone: %@\n",[[self primaryPerson] timezone]];
            }
            else if ([[[self primaryPerson] timezone] length] > 0) {
                [messageToSend appendString:@", Time Zone: INVALID\n"];
            }
            else [messageToSend appendString:@", Time Zone: NOT SPECIFIED\n"];
        }
        else [messageToSend appendString:@"Primary: NO ONE\n"];
        
        if([self secondaryPerson]){
            [messageToSend appendFormat:@"Secondary: %@",[[self secondaryPerson] name]];
            if([NSTimeZone timeZoneWithName:[[self secondaryPerson] timezone]]){
                [messageToSend appendFormat:@", Time Zone: %@\n",[[self secondaryPerson] timezone]];
            }
            else if ([[[self secondaryPerson] timezone] length] > 0) {
                [messageToSend appendString:@", Time Zone: INVALID\n"];
            }
            else [messageToSend appendString:@", Time Zone: NOT SPECIFIED\n"];
        }
        else [messageToSend appendString:@"Secondary: NO ONE\n"];
        
        if([self tertiaryPerson]){
            [messageToSend appendFormat:@"Tertiary: %@",[[self tertiaryPerson] name]];
            if([NSTimeZone timeZoneWithName:[[self tertiaryPerson] timezone]]){
                [messageToSend appendFormat:@", Time Zone: %@\n",[[self tertiaryPerson] timezone]];
            }
            else if ([[[self tertiaryPerson] timezone] length] > 0) {
                [messageToSend appendString:@", Time Zone: INVALID\n"];
            }
            else [messageToSend appendString:@", Time Zone: NOT SPECIFIED\n"];
        }
        else [messageToSend appendString:@"Tertiary: NO ONE\n"];
        
        if([self quaternaryPerson]){
            [messageToSend appendFormat:@"Quaternary: %@",[[self quaternaryPerson] name]];
            if([NSTimeZone timeZoneWithName:[[self quaternaryPerson] timezone]]){
                [messageToSend appendFormat:@", Time Zone: %@\n",[[self quaternaryPerson] timezone]];
            }
            else if ([[[self quaternaryPerson] timezone] length] > 0) {
                [messageToSend appendString:@", Time Zone: INVALID\n"];
            }
            else [messageToSend appendString:@", Time Zone: NOT SPECIFIED\n"];
        }
        else [messageToSend appendString:@"Quaternary: NO ONE\n"];
        [messageToSend appendString:@"\nThis message was sent to the entire list.\n"];

    }
    else {
        [messageToSend appendString:@"The On-list has been changed. There is no one on call!!\n Someone should take responibility!"];
   
    }
    for(id aPerson in onCallList) [aPerson sendMessage:messageToSend];
    [self sendChatMessage:messageToSend withList:nil];
}

- (void) sendChatMessage:(NSString*)aMessage withList:(NSMutableArray*)aList{
    [self sendChatMessage:aMessage withList:aList isAlarm:NO];
}

- (void) sendChatMessage:(NSString*)aMessage withList:(NSMutableArray*)aList isAlarm:(BOOL)isAlarm
{
    if([aMessage length] && (slackEnabled || rocketChatEnabled)){
        NSString* s;
        if(isAlarm) s = [NSString stringWithFormat:@"[%@] Posted alarms:\n\n%@\nAcknowlege them or others will be contacted!\n",computerName(),aMessage];
        else s = [NSString stringWithFormat:@"From ORCA (%@). \n\n%@\n",computerName(),aMessage];
        NSString* rlist;
        if([aList count])
            rlist = [NSString stringWithFormat:@"Message sent to: %@\"}",
                     [aList componentsJoinedByString:@", "]];
        else rlist = @"\"}";
        // send a slack message with curl if the webhook is in the global preferences
        if([[[NSUserDefaults standardUserDefaults] objectForKey:ORSlackWebhook] length] && slackEnabled){
            @try{
                NSMutableString* jmessage = [[[NSMutableString alloc] init] autorelease];
                [jmessage appendString:[NSString stringWithFormat:@"{\"text\":\"%@\n%@", s, rlist]];
                NSMutableArray* args = [NSMutableArray arrayWithObjects:@"-sS", @"-X", @"POST",
                                        @"-H", @"Content-Type: application/json",
                                        @"--connect-timeout", @"5", @"--data", jmessage,
                                        [[NSUserDefaults standardUserDefaults]
                                         objectForKey:ORSlackWebhook], nil];
                if([self sendCurlMessage:@"Slack" withArgs:args]) NSLog(@"Sent to Slack\n");
            }
            @catch(NSException* e){
                NSLog([NSString stringWithFormat:@"Slack messaging exception: %@\n", [e reason]]);
            }
        }
        // try to send a rocket chat message with curl if we have a valid username and password
        // if no user ID and token are empty, first attempt to authenticate
        // if the user ID and token are invalid, the first attempt will fail, so try to re-authenticate
        if([[[NSUserDefaults standardUserDefaults] objectForKey:ORRocketChatUser]     length] &&
           [[[NSUserDefaults standardUserDefaults] objectForKey:ORRocketChatPassword] length] &&
           rocketChatEnabled){
            if(![[[NSUserDefaults standardUserDefaults] objectForKey:ORRocketChatID]    length] ||
               ![[[NSUserDefaults standardUserDefaults] objectForKey:ORRocketChatToken] length]){
                NSLog(@"Not logged in to rocket chat - attempting to authenticate\n");
                [[ORPreferencesController sharedPreferencesController] rocketChatAuthenticateAction:nil];
            }
            if([[[NSUserDefaults standardUserDefaults] objectForKey:ORRocketChatID]    length] &&
               [[[NSUserDefaults standardUserDefaults] objectForKey:ORRocketChatToken] length]){
                @try{
                    NSMutableString* jmessage = [[[NSMutableString alloc] init] autorelease];
                    [jmessage appendString:[NSString stringWithFormat:@"{\"channel\":\"#%@\",",
                                            [[NSUserDefaults standardUserDefaults]
                                             objectForKey:ORRocketChatChannel]]];
                    [jmessage appendString:[NSString stringWithFormat:@"\"text\":\"%@\n%@", s, rlist]];
                    NSString* rmessage=[jmessage stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
                    NSString* rctoken = [NSString stringWithFormat:@"X-Auth-Token: %@",
                                         [[NSUserDefaults standardUserDefaults]
                                          objectForKey:ORRocketChatToken]];
                    NSString* rcid = [NSString stringWithFormat:@"X-User-Id: %@",
                                      [[NSUserDefaults standardUserDefaults] objectForKey:ORRocketChatID]];
                    NSString* rcurl = [NSString stringWithFormat:@"%@:%@/api/v1/chat.postMessage",
                                       [[NSUserDefaults standardUserDefaults] objectForKey:ORRocketChatURL],
                                       [[NSUserDefaults standardUserDefaults] objectForKey:ORRocketChatPort]];
                    NSMutableArray* args = [NSMutableArray arrayWithObjects:@"-sS",
                                            @"-H", @"Content-type: application/json",
                                            @"-H", rctoken, @"-H", rcid,
                                            @"--connect-timeout", @"5", @"--data", rmessage, rcurl, nil];
                    if([self sendCurlMessage:@"RocketChat" withArgs:args]){
                        NSLog(@"Sent to RocketChat\n");
                    }
                    else{
                        NSLog(@"Attempting to re-authenticate with RocketChat\n");
                        [[ORPreferencesController sharedPreferencesController] rocketChatAuthenticateAction:nil];
                        if([[NSUserDefaults standardUserDefaults] objectForKey:ORRocketChatID] &&
                           [[NSUserDefaults standardUserDefaults] objectForKey:ORRocketChatToken]){
                            NSString* rtoken = [NSString stringWithFormat:@"X-Auth-Token: %@",
                                                [[NSUserDefaults standardUserDefaults]  objectForKey:ORRocketChatToken]];
                            NSString* rid = [NSString stringWithFormat:@"X-User-Id: %@",
                                             [[NSUserDefaults standardUserDefaults]     objectForKey:ORRocketChatID]];
                            [args replaceObjectAtIndex:4 withObject:rtoken];
                            [args replaceObjectAtIndex:6 withObject:rid];
                            if([self sendCurlMessage:@"RocketChat" withArgs:args])
                                NSLog(@"Sent to RocketChat\n");
                            else
                                NSLog(@"Failed to send RocketChat message after re-authentication attempt\n");
                        }
                    }
                }
                @catch(NSException* e){
                    NSLog([NSString stringWithFormat:@"RocketChat messaging exception: %@\n", [e reason]]);
                }
            }
        }
    }
}

- (BOOL) sendCurlMessage:(NSString*)type withArgs:(NSMutableArray*)args
{
    NSTask* task = [[[NSTask alloc] init] autorelease];
    task.launchPath = @"/usr/bin/curl";
    task.arguments = args;
    NSPipe* stdOutPipe = [NSPipe pipe];
    [task setStandardOutput:stdOutPipe];
    [task launch];
    [task waitUntilExit];
    NSInteger exitCode = task.terminationStatus;
    BOOL success = NO;
    if(exitCode) NSLog(@"%@ messaging error - curl exited with code %li\n", type, (long) exitCode);
    else{
        NSData* cdata = [[stdOutPipe fileHandleForReading] readDataToEndOfFile];
        NSString* stdOut = [[[NSString alloc] initWithData:cdata encoding:NSUTF8StringEncoding] autorelease];
        success = [stdOut isEqualToString:@"ok"];
        if(!success){
            NSError* jerror = nil;
            NSDictionary* jdict = [NSJSONSerialization JSONObjectWithData:cdata options:NSJSONReadingMutableContainers error:&jerror];
            if([jdict objectForKey:@"success"]) success = YES;
            else NSLog(@"%@ messaging error - curl returned %@\n", type, stdOut);
        }
    }
    return success;
}

- (void) loadBucket:(NSString*)aBucket inFluxDB:(ORInFluxDBModel*)influx
{
    for(OROnCallPerson* person in onCallList){
        [person loadBucket:aBucket inFluxDB:influx];
    }
}

@end

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------
@implementation OROnCallPerson
@synthesize data;

#define kOffCall      0
#define kPrimary      1
#define kSecondary    2
#define kTertiary     3
#define kQuaternary   4

+ (id) onCallPerson
{
    OROnCallPerson* aPerson = [[OROnCallPerson alloc] init];
    NSMutableDictionary* data        = [NSMutableDictionary dictionary];
    [data setObject:[NSNumber numberWithInt:0] forKey:kPersonRole];
    [data setObject:@"" forKey:kPersonName];
    [data setObject:@"" forKey:kPersonAddress];
    [data setObject:@"" forKey:kPersonStatus];
    [data setObject:@"" forKey:kPersonTimeZone];
    aPerson.data = data;
    return [aPerson autorelease];
}

+ (id) onCallPerson:(NSString*)aName address:(NSString*)contactInfo role:(int)aRole
{
    OROnCallPerson* aPerson = [[OROnCallPerson alloc] init];
    NSMutableDictionary* data        = [NSMutableDictionary dictionary];
    [data setObject:aName forKey:kPersonName];
    [data setObject:contactInfo forKey:kPersonAddress];
    [data setObject:[NSNumber numberWithInt:aRole] forKey:kPersonRole];
    [data setObject:@"" forKey:kPersonStatus];
    [data setObject:@"" forKey:kPersonTimeZone];
    aPerson.data = data;
    return [aPerson autorelease];

}

+ (id) onCallPerson:(NSString*)aName address:(NSString*)contactInfo role:(int)aRole timeZone:(NSString*)timeZone
{
    OROnCallPerson* aPerson = [[OROnCallPerson alloc] init];
    NSMutableDictionary* data        = [NSMutableDictionary dictionary];
    [data setObject:aName forKey:kPersonName];
    [data setObject:contactInfo forKey:kPersonAddress];
    [data setObject:[NSNumber numberWithInt:aRole] forKey:kPersonRole];
    [data setObject:@"" forKey:kPersonStatus];
    [data setObject:timeZone forKey:kPersonTimeZone];
    aPerson.data = data;
    return [aPerson autorelease];

}

- (void) dealloc
{
    self.data = nil;
    [super dealloc];
}

- (void) loadBucket:(NSString*)aBucket inFluxDB:(ORInFluxDBModel*)influx
{
    ORInFluxDBMeasurement* aCmd = [ORInFluxDBMeasurement measurementForBucket:aBucket org:[influx org]];
    NSString*                    role = @"OffDuty";
    if([self isPrimary])         role = @"Primary";
    else if([self isSecondary])  role = @"Secondary";
    else if([self isTertiary])   role = @"Tertiary";
    else if([self isQuaternary]) role = @"Quaternary";
    [aCmd start   : @"OnCallList"];
    [aCmd addTag  : @"Role"     withString:role];
    [aCmd addField: @"Name"     withString:[self name]];
    [aCmd addField: @"Contact"  withString:[self address]];
    [aCmd addField: @"Status"   withString:[self status]];
    [influx executeDBCmd:aCmd];
}

- (BOOL) hasSameRoleAs:(OROnCallPerson*)anOtherPerson
{
    return [[self valueForKey:kPersonRole] isEqualTo:[anOtherPerson valueForKey:kPersonRole]];
}

- (void) takeOffCall
{
    [data setValue:[NSNumber numberWithInt:kOffCall] forKey:kPersonRole];
    [self setStatus:@""];
}

- (void) setValue:(id)anObject forKey:(id)aKey
{
    if(!anObject)anObject = @"";
    [[[[ORGlobal sharedGlobal] undoManager] prepareWithInvocationTarget:self] setValue:[data objectForKey:aKey] forKey:aKey];

    [data setObject:anObject forKey:aKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListModelReloadTable object:self];
}

- (id) valueForKey:(id)aKey
{
    return [data objectForKey:aKey];
}

- (BOOL)      isOnCall       { return [[self valueForKey:kPersonRole] intValue] > kOffCall;      }
- (BOOL)      isPrimary      { return [[self valueForKey:kPersonRole] intValue] == kPrimary;     }
- (BOOL)      isSecondary    { return [[self valueForKey:kPersonRole] intValue] == kSecondary;   }
- (BOOL)      isTertiary     { return [[self valueForKey:kPersonRole] intValue] == kTertiary;    }
- (BOOL)      isQuaternary   { return [[self valueForKey:kPersonRole] intValue] == kQuaternary;  }
- (NSString*) name           { return [self valueForKey:kPersonName];                            }
- (NSString*) address        { return [self valueForKey:kPersonAddress];                         }
- (NSString*) status         { return [self valueForKey:kPersonStatus];                          }
- (NSString*) timezone       { return [self valueForKey:kPersonTimeZone];                        }

- (void) setStatus:(NSString*)aString
{
    if(!aString)aString = @"";
    [self setValue:aString forKey:kPersonStatus];
}

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    self.data    = [decoder decodeObjectForKey:@"data"];
   return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeObject:data  forKey:@"data"];
}

- (void) sendMessage:(NSString*)aMessage
{
    [self sendMessage:aMessage isAlarm:NO];
}

- (void) sendMessage:(NSString*)aMessage isAlarm:(BOOL)isAlarm
{
    if([[self address] length]){
        if([aMessage length]){
            NSString* s;
            if(isAlarm) s = [NSString stringWithFormat:@"[%@] Posted alarms:\n\n%@\nAcknowlege them or others will be contacted!\n",computerName(),aMessage];
            else        s = [NSString stringWithFormat:@"From ORCA (%@). \n\n%@\n",computerName(),aMessage];
            
            NSArray* addresses = [[self address] componentsSeparatedByString:@","];
            for(NSString* anAddress in addresses){
                if([anAddress rangeOfString:@"@iMessage"].location != NSNotFound){
                    NSArray* parts = [anAddress componentsSeparatedByString:@"@"];
                    NSString* justNumber = [parts objectAtIndex:0];
                    if([justNumber characterAtIndex:0] == '+')justNumber = [justNumber substringFromIndex:1];
                    if([justNumber characterAtIndex:0] == '1')justNumber = [justNumber substringFromIndex:1];
                    NSDictionary* errorDict;
                    NSAppleEventDescriptor* returnDescriptor = NULL;
                    
                    NSString* template = [NSString stringWithFormat:@"\
                                          tell application \"Messages\"\n\
                                          send \"%@\" to buddy \"+1%@\" of (service 1 whose service type is iMessage)\n\
                                          end tell\n", s,justNumber];
                    
                    NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:template ];
                    
                    returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
                    [scriptObject release];
                    
                    if (returnDescriptor == NULL){ // failed execution
                        NSLog(@"Attempt to send message to %@ Failed with error: %@\n",anAddress,errorDict);
                    }
                }
                else if([anAddress rangeOfString:@"@Jabber"].location != NSNotFound){
                    NSArray* parts = [anAddress componentsSeparatedByString:@"@"];
                    if([parts count]>2){
                        NSString* justNumber = [parts objectAtIndex:1];
                        NSDictionary* errorDict;
                        NSAppleEventDescriptor* returnDescriptor = NULL;
                        
                        NSString* template = [NSString stringWithFormat:@"\
                                              tell application \"Messages\"\n\
                                              send \"%@\" to buddy \"%@\" of (service 1 whose service type is Jabber)\n\
                                              end tell\n", s,justNumber];
                        
                        NSAppleScript* scriptObject = [[NSAppleScript alloc] initWithSource:template ];
                        
                        returnDescriptor = [scriptObject executeAndReturnError: &errorDict];
                        [scriptObject release];
                        
                        if (returnDescriptor == NULL){ // failed execution
                            NSLog(@"Attempt to send message to %@ Failed with error: %@\n",anAddress,errorDict);
                        }
                    }
                    else {
                        NSLog(@"OnCall list: %@ not formated correctly. Format = \"phoneNumber@username@Jabber\"",anAddress);
                    }
                }
                else {
                    ORMailer* mailer = [ORMailer mailer];
                    [mailer setTo:anAddress];
                    [mailer setSubject:[NSString stringWithFormat: @"ORCA message from %@",computerName()]];
                    [mailer setBody:[[[NSAttributedString alloc] initWithString:s] autorelease]];
                    [mailer send:self];
                }
             }
        }
        NSLog(@"On Call Message:\n %@\n",aMessage);
        NSLog(@"Sent to %@\n",[self name]);

    }
    else NSLog(@"No contact info available for %@\n",[self name]);
}

- (NSString*) sendAlarmReport
{
    if([[self address] length]){
        [self setStatus:[NSString stringWithFormat:@"Contacted: %@",[[NSDate date] descriptionFromTemplate:@"HH:mm:ss"]]];
        NSMutableString* report = [NSMutableString stringWithString:@""];
        NSArray* allAlarms  = [[ORAlarmCollection sharedAlarmCollection] alarms];
        for(ORAlarm* anAlarm in allAlarms){
            if(![anAlarm acknowledged] && [anAlarm severity]>kSetupAlarm){
                [report appendFormat:@"From ORCA (%@)\n%@ : %@ @ %@\n",computerName(),[anAlarm name],[ORAlarm alarmSeverityName:[anAlarm severity]],[anAlarm timePosted]];
            }
        }
        
        if([report length]){
            [self sendMessage:report isAlarm:YES];
            return [[report copy] autorelease];
         }
    }
    else {
        [self setStatus:@"No Address"];
        NSLog(@"No contact info available for %@\n",[self name]);
    }
    return nil;
}

- (void) mailSent:(NSString*)to
{
    NSLog(@"On Call Message sent to %@\n",to);
}

- (id) copyWithZone:(NSZone *)zone
{
    OROnCallPerson* copy = [[OROnCallPerson alloc] init];
    copy.data = [[data copyWithZone:zone] autorelease];
    return copy;
}

- (BOOL) checkTimeZone:(BOOL)check
{
    NSString *tz = [self timezone];
    if([tz length] > 0 && check)
    {
        // get current date/time
        NSDate *today = [NSDate date];
        NSCalendar *calendar = [NSCalendar currentCalendar];

        NSTimeZone *user_tz = [NSTimeZone timeZoneWithName:tz];
        if(user_tz == nil){
            NSLog(@"The time zone %@ is invalid, assuming no time zone.\n", tz);
        }
        NSDateComponents *comps_test = [calendar componentsInTimeZone:user_tz fromDate:today];

        long hour = [comps_test hour];

        // assume working hours are 9am to 5pm
        if (hour > 8 && hour < 18) {
            return YES;
        } else {
            return NO;
        }
    }
    else
    {
        return YES;
    }
}
@end

@implementation OROnCallListModel (private)
- (void) postCouchDBRecord
{
    [self postCouchDBRecord:NO];
}
- (void) postCouchDBRecord:(BOOL)alsoToHistory
{
    NSMutableDictionary* record = [NSMutableDictionary dictionary];
    if([self primaryPerson])[record setObject:[[self primaryPerson] data] forKey:@"Primary"];
    if([self secondaryPerson])[record setObject:[[self secondaryPerson] data] forKey:@"Secondary"];
    if([self tertiaryPerson])[record setObject:[[self tertiaryPerson] data] forKey:@"Tertiary"];
    if([self quaternaryPerson])[record setObject:[[self quaternaryPerson] data] forKey:@"Quaternary"];
    
    if([[record allKeys] count]){
        [record setObject:@"OnCall" forKey:@"title"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:record];
        
        if(alsoToHistory)[[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddHistoryAdcRecord" object:self userInfo:record];
    }
}

@end
