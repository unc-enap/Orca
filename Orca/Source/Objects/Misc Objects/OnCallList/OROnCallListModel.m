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

#pragma mark •••Local Strings
NSString* OROnCallListModelLastFileChanged	= @"OROnCallListModelLastFileChanged";
NSString* OROnCallListPersonAdded           = @"OROnCallListPersonAdded";
NSString* OROnCallListPersonRemoved         = @"OROnCallListPersonRemoved";
NSString* OROnCallListListLock              = @"OROnCallListListLock";
NSString* OROnCallListModelReloadTable      = @"OROnCallListModelReloadTable";
NSString* OROnCallListPeopleNotifiedChanged = @"OROnCallListPeopleNotifiedChanged";
NSString* OROnCallListMessageChanged        = @"OROnCallListMessageChanged";
NSString* OROnCallListModelEdited           = @"OROnCallListMessageChanged";

#define kOnCallAlarmWaitTime        3*60
#define kOnCallAcknowledgeWaitTime 10*60

@interface OROnCallListModel (private)
- (void) postCouchDBRecord;
- (void) postCouchDBRecord:(BOOL)alsoToHistory;
@end


@implementation OROnCallListModel

@synthesize onCallList,lastFile,primaryNotified,secondaryNotified,tertiaryNotified;
@synthesize timePrimaryNotified,timeSecondaryNotified,timeTertiaryNotified,message;

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

- (void) add:(NSString*)aName contact:(NSString*)contactInfo role:(int)aRole
{
    if(!onCallList)self.onCallList = [NSMutableArray array];
    OROnCallPerson* aPerson = [OROnCallPerson onCallPerson:aName address:contactInfo role:aRole];    
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

- (unsigned long) onCallListCount { return [onCallList count]; }
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
    OROnCallPerson* primary     = [self primaryPerson];
    OROnCallPerson* secondary   = [self secondaryPerson];
    OROnCallPerson* tertiary    = [self tertiaryPerson];
    //find new primary
    if(!primary && (secondary || tertiary)){
        if(secondary)   [secondary setValue:[NSNumber numberWithInt:1] forKey:kPersonRole];
        else            [tertiary  setValue:[NSNumber numberWithInt:1] forKey:kPersonRole];
    }
    
    //find new secondary
    secondary   = [self secondaryPerson];
    tertiary    = [self tertiaryPerson];
    if(!secondary && tertiary){
        [tertiary  setValue:[NSNumber numberWithInt:2] forKey:kPersonRole];
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
    OROnCallPerson* primary     = [self primaryPerson];
    OROnCallPerson* secondary   = [self secondaryPerson];
    OROnCallPerson* tertiary    = [self tertiaryPerson];

    if(!notificationTimer && (primary || secondary || tertiary)){
        notificationTimer = [[NSTimer scheduledTimerWithTimeInterval:kOnCallAlarmWaitTime target:self selector:@selector(notifyPrimary:) userInfo:nil repeats:NO] retain];
         NSDate* contactDate = [[NSDate date] dateByAddingTimeInterval:kOnCallAcknowledgeWaitTime];
        if(primary){
            [primary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
            if(secondary)       [secondary setStatus:@"Next on deck"];
            else if(tertiary)   [tertiary  setStatus:@"Next on deck"];
        }
        else if(secondary){
            [secondary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
            if(tertiary)   [tertiary  setStatus:@"Next on deck"];
        }
        else if(tertiary){
            [tertiary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
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
    if(primary)         [primary   sendMessage:message];
    else if(secondary)  [secondary sendMessage:message];
    else if(tertiary)   [tertiary  sendMessage:message];
    else NSLog(@"No on call person to send message to!\n");
}

- (void) broadcastMessage:(NSString*)aMessage
{
    if([aMessage length]){
        [[self primaryPerson]   sendMessage:aMessage];
        [[self secondaryPerson] sendMessage:aMessage];
        [[self tertiaryPerson]  sendMessage:aMessage];
    }
}

- (OROnCallPerson*) primaryPerson
{
    for(OROnCallPerson* aPerson in onCallList){
        if([aPerson isPrimary])return aPerson;
    }
    return nil;
}
- (OROnCallPerson*) secondaryPerson
{
    for(OROnCallPerson* aPerson in onCallList){
        if([aPerson isSecondary])return aPerson;
    }
    return nil;
}

- (OROnCallPerson*) tertiaryPerson
{
    for(OROnCallPerson* aPerson in onCallList){
        if([aPerson isTertiary])return aPerson;
    }
    return nil;
}

- (void) resetAll
{
    [notificationTimer invalidate];
    [notificationTimer release];
    notificationTimer   = nil;
    
    self.primaryNotified     = NO;
    self.secondaryNotified   = NO;
    self.tertiaryNotified    = NO;
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
    OROnCallPerson* primary     = [self primaryPerson];
    OROnCallPerson* secondary   = [self secondaryPerson];
    OROnCallPerson* tertiary    = [self tertiaryPerson];
    if(primary){
        
        [primary sendAlarmReport];

        self.primaryNotified        = YES;
        self.timePrimaryNotified    = [NSDate date];
        if(!notificationTimer){
            notificationTimer = [[NSTimer scheduledTimerWithTimeInterval:kOnCallAcknowledgeWaitTime target:self selector:@selector(notifySecondary:) userInfo:nil repeats:NO] retain];
            NSDate* contactDate = [[NSDate date] dateByAddingTimeInterval:kOnCallAcknowledgeWaitTime];
            
            if(secondary){
                [secondary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
                if(tertiary)   [tertiary  setStatus:@"Next on deck"];
            }
            else if(tertiary)[tertiary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListPeopleNotifiedChanged object:self];
    }
    else {
        [self notifySecondary:nil];
    }
}

- (void) notifySecondary:(NSTimer*)aTimer
{
    OROnCallPerson* secondary   = [self secondaryPerson];
    OROnCallPerson* tertiary    = [self tertiaryPerson];
    if(secondary){
        [notificationTimer invalidate];
        [notificationTimer release];
        notificationTimer = nil;

        [secondary sendAlarmReport];
        self.secondaryNotified = YES;
        self.timeSecondaryNotified = [NSDate date];
        if(!notificationTimer){
            notificationTimer = [[NSTimer scheduledTimerWithTimeInterval:kOnCallAcknowledgeWaitTime target:self selector:@selector(notifyTertiary:) userInfo:nil repeats:NO] retain];
            if(tertiary){
                NSDate* contactDate = [[NSDate date] dateByAddingTimeInterval:kOnCallAcknowledgeWaitTime];
               [tertiary setStatus:[NSString stringWithFormat:@"Will Contact: %@",[contactDate descriptionFromTemplate:@"HH:mm:ss"]]];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListPeopleNotifiedChanged object:self];
    }
    else {
        [self notifyTertiary:nil];
    }
}

- (void) notifyTertiary:(NSTimer*)aTimer
{
    [notificationTimer invalidate];
    [notificationTimer release];
    notificationTimer = nil;
    
    OROnCallPerson* tertiary    = [self tertiaryPerson];
    if(tertiary){
        [tertiary sendAlarmReport];
    
        self.tertiaryNotified       = YES;
        self.timeTertiaryNotified   = [NSDate date];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:OROnCallListPeopleNotifiedChanged object:self];
}


#pragma mark •••Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setLastFile:  [decoder decodeObjectForKey:@"lastFile"]];
    [self setMessage:   [decoder decodeObjectForKey:@"message"]];
    onCallList =        [[decoder decodeObjectForKey:@"onCallList"] retain];
	
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
    if([self primaryPerson] || [self secondaryPerson] || [self tertiaryPerson]){
        
        [messageToSend appendFormat:@"The On-list has been changed.\n"];
        [messageToSend appendString:@"Here are the new shift responsibilities:\n\n"];
        
        if([self primaryPerson])[messageToSend appendFormat:@"Primary: %@\n",[[self primaryPerson] name]];
        else [messageToSend appendString:@"Primary: NO ONE\n"];
        
        if([self secondaryPerson])[messageToSend appendFormat:@"Secondary: %@\n",[[self secondaryPerson] name]];
        else [messageToSend appendString:@"Secondary: NO ONE\n"];
        
        if([self tertiaryPerson])[messageToSend appendFormat:@"Tertiary: %@\n",[[self tertiaryPerson] name]];
        else [messageToSend appendString:@"Tertiary: NO ONE\n"];
        [messageToSend appendString:@"\nThis message was sent to the entire list.\n"];

    }
    else {
        [messageToSend appendString:@"The On-list has been changed. There is no one on call!!\n Someone should take responibility!"];
   
    }
    for(id aPerson in onCallList){
        [aPerson sendMessage:messageToSend];
    }
}


@end

//--------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------
@implementation OROnCallPerson
@synthesize data;

#define kOffCall    0
#define kPrimary    1
#define kSecondary  2
#define kTertiary   3

+ (id) onCallPerson
{
    OROnCallPerson* aPerson = [[OROnCallPerson alloc] init];
    NSMutableDictionary* data        = [NSMutableDictionary dictionary];
    [data setObject:[NSNumber numberWithInt:0] forKey:kPersonRole];
    [data setObject:@"" forKey:kPersonName];
    [data setObject:@"" forKey:kPersonAddress];
    [data setObject:@"" forKey:kPersonStatus];
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
    aPerson.data = data;
    return [aPerson autorelease];

}

- (void) dealloc
{
    self.data = nil;
    [super dealloc];
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
- (NSString*) name           { return [self valueForKey:kPersonName];                            }
- (NSString*) address        { return [self valueForKey:kPersonAddress];                         }
- (NSString*) status         { return [self valueForKey:kPersonStatus];                          }

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
            if(isAlarm) s = [NSString stringWithFormat:@"[%@] Posted alarms:\n\n%@\nAcknowlege them or others will be contacted!",computerName(),aMessage];
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

- (void) sendAlarmReport
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
         }
    }
    else {
        [self setStatus:@"No Address"];
        NSLog(@"No contact info available for %@\n",[self name]);
    }
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
    
    if([[record allKeys] count]){
        [record setObject:@"OnCall" forKey:@"title"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddObjectRecord" object:self userInfo:record];
        
        if(alsoToHistory)[[NSNotificationCenter defaultCenter] postNotificationName:@"ORCouchDBAddHistoryAdcRecord" object:self userInfo:record];
    }
}
@end
