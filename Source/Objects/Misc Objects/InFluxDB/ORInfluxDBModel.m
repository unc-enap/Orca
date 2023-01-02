//
//  ORInFluxDBModel.m
//  Orca
//
//  Created by Mark Howe on 12/7/2022.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//Washington at the Center for Experimental Nuclear Physics and
//Astrophysics (CENPA) sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORInFluxDBModel.h"
#import "ORInFluxDBCmd.h"
#import "MemoryWatcher.h"
#import "ORAppDelegate.h"
#import "NSNotifications+Extensions.h"
#import "Utilities.h"
#import "ORSafeQueue.h"
#import "ORExperimentModel.h"
#import "ORAlarmCollection.h"
#import "ORAlarm.h"
#import "OR1DHisto.h"
#import "ORProcessModel.h"
#import "ORProcessElementModel.h"
#import "ORRunModel.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

NSString* ORInFluxDBPortNumberChanged      = @"ORInFluxDBPortNumberChanged";
NSString* ORInFluxDBAuthTokenChanged       = @"ORInFluxDBAuthTokenChanged";
NSString* ORInFluxDBOrgChanged             = @"ORInFluxDBOrgChanged";
NSString* ORInFluxDBBucketChanged          = @"ORInFluxDBBucketChanged";
NSString* ORInFluxDBHostNameChanged        = @"ORInFluxDBHostNameChanged";
NSString* ORInFluxDBModelDBInfoChanged     = @"ORInFluxDBModelDBInfoChanged";
NSString* ORInFluxDBRateChanged            = @"ORInFluxDBRateChanged";
NSString* ORInFluxDBStealthModeChanged     = @"ORInFluxDBStealthModeChanged";
NSString* ORInFluxDBBucketArrayChanged     = @"ORInFluxDBBucketArrayChanged";
NSString* ORInFluxDBOrgArrayChanged        = @"ORInFluxDBOrgArrayChanged";

NSString* ORInFluxDBLock                   = @"ORInFluxDBLock";

static NSString* ORInFluxDBModelInConnector = @"ORInFluxDBModelInConnector";

@interface ORInFluxDBModel (private)
- (void) updateProcesses;
- (void) updateExperiment;
- (void) updateHistory;
- (void) updateMachineRecord;
- (void) postRunState:(NSNotification*)aNote;
- (void) postRunTime:(NSNotification*)aNote;
- (void) postRunOptions:(NSNotification*)aNote;
- (void) updateRunState:(ORRunModel*)rc;
- (void) processElementStateChanged:(NSNotification*)aNote;
- (void) periodicCompact;
- (void) updateDataSets;
- (void) _cancelAllPeriodicOperations;
- (void) _startAllPeriodicOperations;
- (void) decodeBucketList:(NSDictionary*)result;
- (void) decodeOrgList   :(NSDictionary*)result;
@end

@implementation ORInFluxDBModel

#pragma mark ***Initialization

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [responseData    release];
    [hostName        release];
    [processThread   release];
    [authToken       release];;
    [org             release];
    [thisHostAddress release];
    [bucketArray     release];
    [orgArray        release];
    [timer           invalidate];
    [timer           release];

    [super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
        
        [self _startAllPeriodicOperations];
        [self registerNotificationObservers];
        [self executeDBCmd:[ORInFluxDBListBuckets inFluxDBListBuckets]];
        [self executeDBCmd:[ORInFluxDBListOrgs    inFluxDBListOrgs]];
    }
    [super wakeUp];
}

- (void) sleep
{
    canceled = YES;
    [self _cancelAllPeriodicOperations];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super sleep];
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"InFlux"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORInFluxDBController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORInFluxDBModelInConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
    [aConnector setConnectorType: 'DB I' ];
    [aConnector addRestrictedConnectionType: 'DB O' ]; //can only connect to DB outputs
    
    [aConnector release];
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter removeObserver:self];
    
    [notifyCenter addObserver : self
                     selector : @selector(applicationIsTerminating:)
                         name : @"ORAppTerminating"
                       object : (ORAppDelegate*)[NSApp delegate]];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStatusChanged:)
                         name : ORRunStatusChangedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runOptionsOrTimeChanged:)
                         name : ORRunElapsedTimesChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runOptionsOrTimeChanged:)
                         name : ORRunRepeatRunChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(alarmsChanged:)
                         name : ORAlarmWasPostedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(alarmsChanged:)
                         name : ORAlarmWasAcknowledgedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(alarmsChanged:)
                         name : ORAlarmWasClearedNotification
                       object : nil];
        
    [notifyCenter addObserver : self
                     selector : @selector(updateProcesses)
                         name : ORProcessRunningChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(processElementStateChanged:)
                         name : ORProcessElementStateChangedNotification
                       object : nil];

}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
 }

- (void) awakeAfterDocumentLoaded
{
    [self startTimer];
}

#pragma mark ***Accessors
- (id) nextObject
{
    return [self objectConnectedTo:ORInFluxDBModelInConnector];
}

- (NSUInteger) portNumber
{
    return portNumber;
}

- (void) setPortNumber:(NSUInteger)aPort
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortNumber:portNumber];
    if(aPort == 0)aPort = 8086;
    portNumber = aPort;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBPortNumberChanged object:self];
}

- (NSString*) hostName
{
    return hostName;
}

- (void) setHostName:(NSString*)aHostName
{
    if(!aHostName)aHostName = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setHostName:hostName];
    
    [hostName autorelease];
    hostName = [aHostName copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBHostNameChanged object:self];
}

- (NSString*) authToken
{
    return authToken;
}

- (void) setAuthToken:(NSString*)aAuthToken
{
    if(!aAuthToken)aAuthToken = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setAuthToken:authToken ];
    
    [authToken autorelease];
    authToken = [aAuthToken copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBAuthTokenChanged object:self];
}

- (NSString*) org
{
    return org;
}

- (void) setOrg:(NSString*)anOrg
{
    if(!anOrg)anOrg = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setOrg:org ];
    
    [org autorelease];
    org = [anOrg copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBOrgChanged object:self];
}

- (BOOL) stealthMode
{
    return stealthMode;
}

- (void) setStealthMode:(BOOL)aStealthMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStealthMode:stealthMode];
    stealthMode = aStealthMode;
    if(stealthMode){
        [self _cancelAllPeriodicOperations];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBStealthModeChanged object:self];
}

- (void) startTimer
{
    [timer invalidate];
    [timer release];
    timer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(calcRate)userInfo:nil repeats:YES] retain];
}

- (void) calcRate
{
    messageRate = totalSent;
    totalSent = 0;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORInFluxDBRateChanged object:self];
}

- (NSInteger) messageRate        { return messageRate; }
- (BOOL)      cancelled       { return canceled; }
- (void)      markAsCanceled  { canceled = YES;  }


#pragma mark ***Measurements
- (void) sendCmd:(ORInFluxDBCmd*)aCmd
{
    if(!processThread){
        processThread = [[NSThread alloc] initWithTarget:self selector:@selector(sendMeasurments) object:nil];
        [processThread start];
    }
    if(!messageQueue){
        messageQueue = [[ORSafeQueue alloc] init];
    }
    [messageQueue enqueue:aCmd];
}

- (void) alarmsChanged:(NSNotification*)aNote
{
    if(!stealthMode){
        ORAlarmCollection* alarmCollection = [ORAlarmCollection sharedAlarmCollection];
        NSArray* theAlarms = [[[alarmCollection alarms] retain] autorelease];
        NSMutableArray* arrayForDoc = [NSMutableArray array];
        if([theAlarms count]){
            for(id anAlarm in theAlarms)[arrayForDoc addObject:[anAlarm alarmInfo]];
        }
        NSDictionary* alarmInfo  = [NSDictionary dictionaryWithObjectsAndKeys:@"alarms",@"_id",@"alarms",@"name",arrayForDoc,@"alarmlist",@"alarms",@"type",nil];
     }
}
- (void) updateRunInfo
{
    if(!stealthMode){
        NSArray* runObjects = [[self document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
        if([runObjects count]){
            ORRunModel* rc = [runObjects objectAtIndex:0];
            [self updateRunState:rc];
        }
    }
}

- (void) updateRunState:(ORRunModel*)rc
{
    if(!stealthMode){
        NSDictionary* info          = [rc runInfo];
        uint32_t runNumberLocal     = (uint32_t)[[info objectForKey:@"kRunNumber"] unsignedLongValue];
        uint32_t subRunNumberLocal  = (uint32_t)[[info objectForKey:@"kSubRunNumber"]unsignedLongValue];
        uint32_t runStatus          = (uint32_t)[[info objectForKey:@"ORRunStatusValue"]unsignedLongValue];
        uint32_t runMask            = (uint32_t)[[info objectForKey:@"ORRunTypeMask"]unsignedLongValue];
        uint32_t runPaused          = (uint32_t)[[info objectForKey:@"ORRunPaused"]unsignedLongValue];
        
        ORInFluxDBMeasurement* aCmd = [ORInFluxDBMeasurement inFluxDBMeasurement:@"L200" org:org];
        [aCmd start:@"Run" withTags:@"Type=Status"];
        [aCmd addLong:@"RunNumber"    withValue:runNumberLocal];
        [aCmd addLong:@"SubRunNumber" withValue:subRunNumberLocal];
        [aCmd addLong:@"RunStatus"    withValue:runStatus];
        [aCmd addLong:@"RunMask"      withValue:runMask];
        [aCmd addLong:@"RunPaused"    withValue:runPaused];
        [self executeDBCmd:aCmd];
    }
}

- (void) runStatusChanged:(NSNotification*)aNote
{
    [self updateRunState:[aNote object]];
    //[self updateDataSets];
}

- (void) runStarted:(NSNotification*)aNote
{
    NSDictionary* info = [aNote userInfo];
    if([[info objectForKey:@"kRunMode"] intValue]==kNormalRun){
        uint32_t runNumberLocal     = (uint32_t)[[info objectForKey:@"kRunNumber"] unsignedLongValue];
        uint32_t subRunNumberLocal  = (uint32_t)[[info objectForKey:@"kSubRunNumber"]unsignedLongValue];
 
        ORInFluxDBMeasurement* aCmd = [ORInFluxDBMeasurement inFluxDBMeasurement:@"L200" org:org];
        [aCmd start:@"Run" withTags:[NSString stringWithFormat:@"Type=Status"]];
        [aCmd addLong:@"RunNumber"    withValue:runNumberLocal];
        [aCmd addLong:@"SubRunNumber" withValue:subRunNumberLocal];
        [self executeDBCmd:aCmd];

        
//        [self startDBMeasurement:@"RunInfo" withTags:@"Type=StartRun"];
//        [self addLong:@"RunNumber"    withValue:runNumberLocal];
//        [self addLong:@"SubRunNumber" withValue:subRunNumberLocal];
//        [self endDBMeasurement];
//        [self sendMeasurementsToDB];
    }
}

- (void) runStopped:(NSNotification*)aNote
{
    NSDictionary* info = [aNote userInfo];
    if([[info objectForKey:@"kRunMode"] intValue]==kNormalRun){
        uint32_t runNumberLocal     = (uint32_t)[[info objectForKey:@"kRunNumber"] unsignedLongValue];
        uint32_t subRunNumberLocal  = (uint32_t)[[info objectForKey:@"kSubRunNumber"]unsignedLongValue];
        float elapsedTimeLocal      = [[info objectForKey:@"kElapsedTime"]floatValue];
//        [self startDBMeasurement:@"RunInfo" withTags:@"Type=EndRun"];
//        [self addLong:@"RunNumber"     withValue:runNumberLocal];
//        [self addLong:@"SubRunNumber"  withValue:subRunNumberLocal];
//        [self addDouble:@"ElapsedTime" withValue:elapsedTimeLocal];
//        [self endDBMeasurement];
//        [self sendMeasurementsToDB];
    }
}

- (void) clearAlert
{
    [self setAlertMessage:@""];
    NSDictionary* alertMessageDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                            @"",                        @"alertMessage",
                                            [NSNumber numberWithInt:0], @"alertMessageType",
                                            nil];
//    [self startDBMeasurement:@"ORCA" withTags:@"alarm=cleared"];
//    [self addString:@"alertMessage"   withValue:@""];
//    [self addLong:@"alertMessageType" withValue:0];
//    [self endDBMeasurement];
//    [self sendMeasurementsToDB];
}

- (void) postAlert
{
    NSString* messageToPost;
    if([alertMessage length]==0)messageToPost = @"";
    else messageToPost = alertMessage;
    
//    [self startDBMeasurement:@"ORCA" withTags:@"alarm=posted"];
//    [self addString:@"alertMessage"   withValue:messageToPost];
//    [self addLong:@"alertMessageType" withValue:alertType];
//    [self endDBMeasurement];
//    [self sendMeasurementsToDB];
}

- (NSString*) alertMessage
{
    if(!alertMessage)return @"";
    else             return alertMessage;
}

- (void) setAlertMessage:(NSString*)aAlertMessage
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAlertMessage:alertMessage];
    
    [alertMessage autorelease];
    alertMessage = [aAlertMessage copy];
}

- (void) runOptionsOrTimeChanged:(NSNotification*)aNote
{
    if(!scheduledForRunInfoUpdate){
        scheduledForRunInfoUpdate = YES;
        [self performSelector:@selector(updateRunState:) withObject:[aNote object] afterDelay:5];
    }
}

- (void) executeDBCmd:(id)aCmd
{
    [aCmd executeCmd:self];
}

- (NSString*) orgId
{
    for(id anOrg in orgArray){
        if([[anOrg objectForKey:@"name"] isEqualToString:org]){
            return [anOrg objectForKey:@"id"];
        }
    }
    return @"";
}

- (void) deleteBucket:(NSInteger)index
{
    NSDictionary* bucketInfo   = [bucketArray objectAtIndex:index];
    NSString*      aBucketId   = [bucketInfo objectForKey:@"id"];
    if(aBucketId){
        ORInFluxDBDeleteBucket* aCmd = [ORInFluxDBDeleteBucket inFluxDBDeleteBucket];
        [aCmd setBucketId:[bucketInfo objectForKey:@"id"]];
        [self executeDBCmd:aCmd];
        [self performSelector:@selector(executeDBCmd:) withObject:[ORInFluxDBListBuckets inFluxDBListBuckets] afterDelay:2];
    }
}

- (void) createBuckets
{
    [self executeDBCmd:[ORInFluxDBCreateBucket inFluxDBCreateBucket:@"L200"
                                                              orgId:[self orgId] expireTime:60*60]];
    [self executeDBCmd:[ORInFluxDBCreateBucket inFluxDBCreateBucket:@"ORCA"
                                                              orgId:[self orgId] expireTime:60*60]];
    [self executeDBCmd:[ORInFluxDBCreateBucket inFluxDBCreateBucket:@"Sensors"
                                                              orgId:[self orgId] expireTime:60*60]];
    [self executeDBCmd:[ORInFluxDBCreateBucket inFluxDBCreateBucket:@"Computer"
                                                              orgId:[self orgId] expireTime:60*60]];

    [self performSelector:@selector(executeDBCmd:) withObject:[ORInFluxDBListBuckets inFluxDBListBuckets] afterDelay:1];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager]  disableUndoRegistration];
    [self setHostName:   [decoder decodeObjectForKey: @"HostName"]];
    [self setPortNumber: [decoder decodeIntegerForKey:@"PortNumber"]];
    [self setAuthToken:  [decoder decodeObjectForKey:@"Token"]];
    [self setOrg:        [decoder decodeObjectForKey:@"Org"]];
    [[self undoManager]  enableUndoRegistration];
    [self registerNotificationObservers];
   return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:portNumber   forKey:@"PortNumber"];
    [encoder encodeObject:hostName      forKey:@"HostName"];
    [encoder encodeObject:authToken     forKey:@"Token"];
    [encoder encodeObject:org           forKey:@"Org"];
}

- (uint32_t) queueMaxSize
{
    return 1000;
}

- (void) _cancelAllPeriodicOperations
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) _startAllPeriodicOperations
{
    [self performSelector:@selector(updateMachineRecord) withObject:nil afterDelay:2];
    [self performSelector:@selector(updateExperiment)    withObject:nil afterDelay:3];
    [self performSelector:@selector(updateRunInfo)       withObject:nil afterDelay:4];
}

- (void) updateMachineRecord
{
    if(!stealthMode){
        @try {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateMachineRecord) object:nil];
            if([thisHostAddress length]==0){
                //only have to get this once
                struct ifaddrs *ifaddr, *ifa;
                if (getifaddrs(&ifaddr) == 0) {
                    // Successfully received the structs of addresses.
                    char tempInterAddr[INET_ADDRSTRLEN];
                    NSMutableArray* names = [NSMutableArray array];
                    // The following is a replacement for [[NSHost currentHost] addresses].  The problem is
                    // that the NSHost call can do reverse DNS calls which block and are *very* slow.  The
                    // following is much faster.
                    for (ifa = ifaddr; ifa != nil; ifa = ifa->ifa_next) {
                        // skip IPv6 addresses
                        if (ifa->ifa_addr->sa_family != AF_INET) continue;
                        inet_ntop(AF_INET,
                                  &((struct sockaddr_in *)ifa->ifa_addr)->sin_addr,
                                  tempInterAddr,
                                  sizeof(tempInterAddr));
                        [names addObject:[NSString stringWithCString:tempInterAddr encoding:NSASCIIStringEncoding]];
                    }
                    freeifaddrs(ifaddr);
                    // Now enumerate and find the first non-loop-back address.
                    NSEnumerator* e = [names objectEnumerator];
                    id aName;
                    while(aName = [e nextObject]){
                        if([aName rangeOfString:@".0.0."].location == NSNotFound){
                            thisHostAddress = [aName copy];
                            break;
                        }
                    }
                }
            }
            if(!thisHostAddress)thisHostAddress = @"";
            ORInFluxDBMeasurement* aMeasurement = [ORInFluxDBMeasurement inFluxDBMeasurement:@"Computer" org:org];
            [aMeasurement start:@"Identity" withTags:[NSString stringWithFormat:@"name=%@",computerName()]];
            [aMeasurement addString:@"hwAddress" withValue:macAddress()];
            [aMeasurement addString:@"ipAddress" withValue:thisHostAddress];
            [self executeDBCmd:aMeasurement];

            long uptime = [[(ORAppDelegate*)(ORAppDelegate*)[NSApp delegate] memoryWatcher] accurateUptime];
            long memory = [[(ORAppDelegate*)(ORAppDelegate*)[NSApp delegate] memoryWatcher] orcaMemory];

            aMeasurement  = [ORInFluxDBMeasurement inFluxDBMeasurement:@"ORCA" org:org];
            [aMeasurement start:@"resources" withTags:@"type=runTime"];
            [aMeasurement addLong:@"uptime" withValue:uptime];
            [aMeasurement addLong:@"memory" withValue:memory];
            [self executeDBCmd:aMeasurement];

            NSFileManager* fm = [NSFileManager defaultManager];
            NSArray* diskInfo = [fm mountedVolumeURLsIncludingResourceValuesForKeys:0 options:NSVolumeEnumerationSkipHiddenVolumes];
            for(id aVolume in diskInfo){
                NSError *fsError = nil;
                aVolume = [aVolume relativePath];
                NSDictionary *fsDictionary = [fm attributesOfFileSystemForPath:aVolume error:&fsError];
                
                if (fsDictionary != nil){
                    //if([aVolume rangeOfString:@"Volumes"].location !=NSNotFound){
                    // aVolume = [aVolume substringFromIndex:9];
                    double freeSpace   = [[fsDictionary objectForKey:@"NSFileSystemFreeSize"] doubleValue]/1E9;
                    double totalSpace  = [[fsDictionary objectForKey:@"NSFileSystemSize"] doubleValue]/1E9;
                    double percentUsed = 100*(totalSpace-freeSpace)/totalSpace;
                    
                    aMeasurement  = [ORInFluxDBMeasurement inFluxDBMeasurement:@"Computer" org:org];
                    [aMeasurement start:@"DiskInfo" withTags:[NSString stringWithFormat:@"disk=%@",aVolume]];
                    [aMeasurement addDouble:@"freeSpace"   withValue:freeSpace];
                    [aMeasurement addDouble:@"totalSpace"  withValue:totalSpace];
                    [aMeasurement addDouble:@"percentUsed" withValue:percentUsed];
                    [self executeDBCmd:aMeasurement];
                }
            }
        }
        @catch (NSException* e){
            NSLog(@"%@ %@ Exception: %@\n",[self fullID],NSStringFromSelector(_cmd),e);
        }
        @finally {
            [self performSelector:@selector(updateMachineRecord) withObject:nil afterDelay:60];
        }
    }
}

- (void) updateExperiment
{
    if(!stealthMode){
    }
}

- (NSArray*) bucketArray
{
    return bucketArray;
}

- (NSArray*) orgArray
{
    return orgArray;
}

#pragma mark ***Thread
- (void)sendMeasurments
{
    NSAutoreleasePool* outerPool = [[NSAutoreleasePool alloc] init];
    if(!messageQueue){
        messageQueue = [[ORSafeQueue alloc] init];
    }

    do {
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
        ORInFluxDBCmd*     aCmd = [messageQueue dequeue];
        if(aCmd){
            NSMutableURLRequest* request = [aCmd requestFrom:self];
            NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
            NSURLSession*             session = [NSURLSession sessionWithConfiguration:config];
            NSURLSessionDataTask*      dbTask = [session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
                if (!error) {
                    NSDictionary* result = [NSJSONSerialization JSONObjectWithData: data
                                                                           options: kNilOptions
                                                                             error: &error];
                    [aCmd logResult:result delegate:self];
                }
            }];
            
            [dbTask resume]; //task is created in paused state, so start it
            
            totalSent += [aCmd requestSize];
        }
        [NSThread sleepForTimeInterval:.01];
        [pool release];
    }while(!canceled);
    [outerPool release];
}

- (void) decodeBucketList:(NSDictionary*)result
{
    NSArray* anArray = [result objectForKey:@"buckets"];
    if([anArray count]){
        [bucketArray release];
        bucketArray = [anArray retain];
    }
    else {
        [bucketArray release];
        bucketArray = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORInFluxDBBucketArrayChanged
                                    object:self
                                  userInfo:nil
                             waitUntilDone:NO];

}

- (void) decodeOrgList:(NSDictionary*)result
{
    NSArray* anArray = [result objectForKey:@"orgs"];
    if([anArray count]){
        [orgArray release];
        orgArray = [anArray retain];
    }
    else {
        [orgArray release];
        orgArray = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORInFluxDBOrgArrayChanged
                                                                        object:self
                                                                      userInfo:nil
                                                                 waitUntilDone:NO];
}
@end
