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
#import "MemoryWatcher.h"
#import "ORAppDelegate.h"
#import "NSNotifications+Extensions.h"
#import "SynthesizeSingleton.h"
#import "Utilities.h"
#import "ORSafeQueue.h"
#import "ORExperimentModel.h"
#import "ORAlarmCollection.h"
#import "ORAlarm.h"
#import "OR1DHisto.h"
#import "ORProcessModel.h"
#import "ORProcessElementModel.h"
#import "ORRunModel.h"
#import "ORInFluxDBCmd.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

NSString* ORInFluxDBPortNumberChanged      = @"ORInFluxDBPortNumberChanged";
NSString* ORInFluxDBAuthTokenChanged       = @"ORInFluxDBAuthTokenChanged";
NSString* ORInFluxDBOrgChanged             = @"ORInFluxDBOrgChanged";
NSString* ORInFluxDBBucketChanged          = @"ORInFluxDBBucketChanged";
NSString* ORInFluxDBHostNameChanged        = @"ORInFluxDBHostNameChanged";
NSString* ORInFluxDBModelDBInfoChanged       = @"ORInFluxDBModelDBInfoChanged";
NSString* ORInFluxDBTimeConnectedChanged   = @"ORInFluxDBTimeConnectedChanged";
NSString* ORInFluxDBAccessTypeChanged      = @"ORInFluxDBAccessTypeChanged";
NSString* ORInFluxDBSocketStatusChanged    = @"ORInFluxDBSocketStatusChanged";
NSString* ORInFluxDBRateChanged            = @"ORInFluxDBRateChanged";
NSString* ORInFluxDBStealthModeChanged     = @"ORInFluxDBStealthModeChanged";

NSString* ORInFluxDBLock                   = @"ORInFluxDBLock";

static NSString* ORInFluxDBModelInConnector = @"ORInFluxDBModelInConnector";

@interface ORInFluxDBModel (private)
//only for the telegraf socket mode with inFluxDB line format
- (void) setUpInFluxSocket;
- (void) openInFluxSocket;
- (void) closeInFluxSocket;
- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)event;
- (void) readIn:(NSString *)s;
- (void) writeOut:(NSString *)s;

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
    [responseData  release];
    [hostName      release];
    [processThread release];
    [timer         invalidate];
    [timer         release];

    [authToken      release];;
    [org            release];
    [bucket         release];

    [self closeInFluxSocket];
    [inputStream    release];
    [outputStream   release];
    [thisHostAddress release];
    [super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
        [self _startAllPeriodicOperations];
        [self registerNotificationObservers];
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
    [ aConnector setConnectorType: 'DB I' ];
    [ aConnector addRestrictedConnectionType: 'DB O' ]; //can only connect to DB outputs
    
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

- (NSInteger) accessType
{
    return accessType;
}

- (void) setAccessType:(NSInteger)anAccessType
{
    [[[self undoManager] prepareWithInvocationTarget:self] setAccessType:accessType ];
    if(accessType != anAccessType){
        if(accessType==kUseInFluxHttpProtocol){
            if(inputStream)[self closeInFluxSocket];
            [self setPortNumber:8094];
            [self setUpInFluxSocket];
        }
        else {
            [self setPortNumber:8086];
            [self closeInFluxSocket];
        }
    }
    accessType = anAccessType;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBAccessTypeChanged object:self];
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

- (NSString*)   bucket
{
    return bucket;
}

- (void) setBucket:(NSString*)aBucket
{
    if(!aBucket)aBucket = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setBucket:bucket ];
    
    [bucket autorelease];
    bucket = [aBucket copy];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBBucketChanged object:self];
}

- (BOOL) isConnected
{
    return isConnected;
}

- (void) setIsConnected:(BOOL)aNewIsConnected
{
    isConnected = aNewIsConnected;
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

//- (void) removeEndingComma
//{
//    NSRange lastComma = [outputBuffer rangeOfString:@"," options:NSBackwardsSearch];
//
//    if(lastComma.location == [outputBuffer length]-1) {
//        [outputBuffer replaceCharactersInRange:lastComma
//                                           withString: @""];
//    }
//}
//
//- (void) addLong:(NSString*)aValueName withValue:(long)aValue
//{
//    [outputBuffer appendFormat:@"%@=%ld,",aValueName,aValue];
//}
//
//- (void) addDouble:(NSString*)aValueName withValue:(double)aValue
//{
//    [outputBuffer appendFormat:@"%@=%f,",aValueName,aValue];
//}
//
//- (void) addString:(NSString*)aValueName withValue:(NSString*)aValue
//{
//    [outputBuffer appendFormat:@"%@=\"%@\",",aValueName,aValue];
//}
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
        ORInFluxDBCmd* aCmd = [[ORInFluxDBCmd alloc] initWithCmdType:kInfluxDBMeasurement];
        [aCmd start:@"RunInfo" withTags:@"Type=Run"];
        [aCmd addLong:@"RunNumber"    withValue:runNumberLocal];
        [aCmd addLong:@"SubRunNumber" withValue:subRunNumberLocal];
        [aCmd addLong:@"RunStatus"    withValue:runStatus];
        [aCmd addLong:@"RunMask"      withValue:runMask];
        [aCmd addLong:@"RunPaused"    withValue:runPaused];
        [aCmd end:self];
        [aCmd release];
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
 
        ORInFluxDBCmd* aCmd = [[ORInFluxDBCmd alloc] initWithCmdType:kInfluxDBMeasurement];
        [aCmd start:@"RunInfo" withTags:[NSString stringWithFormat:@"Type=StartRun"]];
        [aCmd addLong:@"RunNumber"    withValue:runNumberLocal];
        [aCmd addLong:@"SubRunNumber" withValue:subRunNumberLocal];
        [aCmd end:self];
        [aCmd release];

        
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

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager]  disableUndoRegistration];
    [self setHostName:   [decoder decodeObjectForKey: @"HostName"]];
    [self setPortNumber: [decoder decodeIntegerForKey:@"PortNumber"]];
    [self setAccessType: [decoder decodeIntegerForKey:@"AccessType"]];
    [self setAuthToken:  [decoder decodeObjectForKey:@"Token"]];
    [self setOrg:        [decoder decodeObjectForKey:@"Org"]];
    [self setBucket:     [decoder decodeObjectForKey:@"Bucket"]];
    [[self undoManager]  enableUndoRegistration];
    [self registerNotificationObservers];
   return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInteger:portNumber   forKey:@"PortNumber"];
    [encoder encodeInteger:accessType   forKey:@"AccessType"];
    [encoder encodeObject:hostName      forKey:@"HostName"];
    [encoder encodeObject:authToken     forKey:@"Token"];
    [encoder encodeObject:org           forKey:@"Org"];
    [encoder encodeObject:bucket        forKey:@"Bucket"];
}

- (void) executeDBCmd:(int)aCmdID
{
    ORInFluxDBCmd* aCmd = [[ORInFluxDBCmd alloc] initWithCmdType:aCmdID];
    [aCmd end:self];
    [aCmd release];
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
            ORInFluxDBCmd* aMeasurement = [[ORInFluxDBCmd alloc] initWithCmdType:kInfluxDBMeasurement];
            [aMeasurement start:@"CPU" withTags:[NSString stringWithFormat:@"name=%@",computerName()]];
            [aMeasurement addString:@"hwAddress" withValue:macAddress()];
            [aMeasurement addString:@"ipAddress" withValue:thisHostAddress];
            [aMeasurement end:self];
            [aMeasurement release];

            long uptime = [[(ORAppDelegate*)(ORAppDelegate*)[NSApp delegate] memoryWatcher] accurateUptime];
            long memory = [[(ORAppDelegate*)(ORAppDelegate*)[NSApp delegate] memoryWatcher] orcaMemory];

            aMeasurement = [[ORInFluxDBCmd alloc] initWithCmdType:kInfluxDBMeasurement];
            [aMeasurement start:@"ORCA" withTags:@"type=stats"];
            [aMeasurement addLong:@"uptime" withValue:uptime];
            [aMeasurement addLong:@"memory" withValue:memory];
            [aMeasurement end:self];
            [aMeasurement release];

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
                    
                    ORInFluxDBCmd* aCmd = [[ORInFluxDBCmd alloc] initWithCmdType:kInfluxDBMeasurement];
                    [aCmd start:@"DiskInfo" withTags:[NSString stringWithFormat:@"disk=%@",aVolume]];
                    [aCmd addDouble:@"freeSpace"   withValue:freeSpace];
                    [aCmd addDouble:@"totalSpace"  withValue:totalSpace];
                    [aCmd addDouble:@"percentUsed" withValue:percentUsed];
                    [aCmd end:self];
                    [aCmd release];
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
            NSString*            requestString = nil;
            NSMutableURLRequest* request       = nil;
            if(accessType == kUseInFluxHttpProtocol){
                //-----access type is via inFluxDB http format-----
                switch([aCmd cmdType]){
                    case kInfluxDBMeasurement:
                        requestString = [NSString stringWithFormat:@"http://%@:%ld/api/v2/write?org=%@&bucket=%@&precision=ns",hostName,portNumber,org,bucket];
                        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
                        
                        request.HTTPMethod = @"POST";
                        [request setValue:@"text/plain; charset=utf-8"    forHTTPHeaderField:@"Content-Type"];
                        [request setValue:@"text/plain; application/json" forHTTPHeaderField:@"Accept"];
                        [request setValue:[NSString stringWithFormat:@"Token %@",[self authToken]]                     forHTTPHeaderField:@"Authorization"];
                        request.HTTPBody = [aCmd payload];
                        break;
                        
                    case kInFluxDBListBuckets:
                        requestString = [NSString stringWithFormat:@"http://%@:%ld/api/v2/buckets",hostName,portNumber];
                        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
                        request.HTTPMethod = @"GET";
                        [request setValue:[NSString stringWithFormat:@"Token %@",[self authToken]]                     forHTTPHeaderField:@"Authorization"];
                        break;
                        
                    case kInFluxDBListOrgs:
                        requestString = [NSString stringWithFormat:@"http://%@:%ld/api/v2/orgs",hostName,portNumber];
                        request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestString]];
                        
                        request.HTTPMethod = @"GET";
                        [request setValue:[NSString stringWithFormat:@"Token %@",[self authToken]] forHTTPHeaderField:@"Authorization"];

//                        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
//                        [dict setObject:@"UNC"  forKey:@"org"];
//                        [dict setObject:@"L200" forKey:@"name"];
//                        NSMutableDictionary* ret = [NSMutableDictionary dictionary];
//                        [ret setObject:@"expire" forKey:@"type"];
//                        [ret setObject:[NSNumber numberWithInt:86400] forKey:@"everySeconds"];
//                        [ret setObject:[NSNumber numberWithInt:0] forKey:@"shardGroupDurationSeconds"];
//                        NSArray* retArray = [NSArray arrayWithObject:ret];
//                        [dict setObject:retArray forKey:@"retentionRules"];
                        
//                        NSError *error;
//                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
//                                                                           options:0 // Pass 0 if you don't care about the readability of the generated string
//                                                                             error:&error];
//
//
//
//                       // NSData* d =[s dataUsingEncoding:NSASCIIStringEncoding];
//                        request.HTTPBody = jsonData;

                        break;
                }
                
                if(requestString){
                    NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
                    NSURLSession*             session = [NSURLSession sessionWithConfiguration:config];
                    
                    NSURLSessionDataTask* dbTask = [session dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
                        if (!error) {
                            NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*) response;
                            NSDictionary* json = [NSJSONSerialization JSONObjectWithData: data
                                                                                 options: kNilOptions
                                                                                   error: &error];
                            switch([aCmd cmdType]){
                                case kInFluxDBListOrgs:
                                    //if (httpResp.statusCode == 200) {
                                    NSLog(@"Orgs: %d\n",[aCmd cmdType]);
                                    NSLog(@"code: %d\n%@\n",httpResp.statusCode,[json allKeys]);
                                    break;
                                case kInFluxDBListBuckets:
                                    //if (httpResp.statusCode == 200) {
                                    NSLog(@"Buckets: %d\n",[aCmd cmdType]);
                                    NSLog(@"code: %d\n%@\n",httpResp.statusCode,[json allKeys]);
                                    break;

                            }
                        }
                    }];
                    
                    [dbTask resume]; //task is created in paused state, so start it
                    
                    totalSent += [[aCmd payload] length];
                }
            }
            else {
                //-----access type is via telegraf socket-----
                if(!inputStream) [self setUpInFluxSocket];
                [self writeOut:[aCmd outputBuffer]];
            }
        }
        [NSThread sleepForTimeInterval:.01];
        [pool release];
    }while(!canceled);
    [self closeInFluxSocket];
    [outerPool release];
}

#pragma mark ***Access Via Telegraf thread
//-------------------------------------------
//------telegraf stuff.... may not use.....
//-------------------------------------------
- (short) socketStatus
{
    return socketStatus;
}
- (void) setSocketStatus:(short)aState
{
    socketStatus = aState;
    if( socketStatus == NSStreamStatusNotOpen ||
        socketStatus == NSStreamStatusOpening ||
        socketStatus == NSStreamStatusClosed  ||
        socketStatus == NSStreamStatusError) {
            [self setIsConnected:NO];
    }
    else [self setIsConnected:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBSocketStatusChanged object:self];
}

- (void) setUpInFluxSocket
{
    NSString* finalHost = [[hostName copy]autorelease];
    if(![finalHost hasPrefix:@"http://"]){
        finalHost = [NSString stringWithFormat:@"http://%@",finalHost];
    }
    NSURL *url = [NSURL URLWithString:finalHost];
    
    NSLog(@"Setting up connection to Telegraf at %@ : %d\n", [url absoluteString], portNumber);
    
    CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, (CFStringRef)[url host], (uint32_t)portNumber, &readStream, &writeStream);
    
    if(!CFWriteStreamOpen(writeStream)) {
        NSLog(@"Error, telegraf writeStream not open\n");
        return;
    }
    [self openInFluxSocket];
    [self setSocketStatus:[outputStream streamStatus]];
}

- (void)openInFluxSocket
{
    inputStream  = (NSInputStream *)readStream;
    outputStream = (NSOutputStream *)writeStream;
    
    [inputStream retain];
    [outputStream retain];
    
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [inputStream open];
    [outputStream open];
    [self setSocketStatus:[outputStream streamStatus]];
}

- (void)closeInFluxSocket
{
    [inputStream  close];
    [outputStream close];
    
    [inputStream  removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [inputStream setDelegate:nil];
    [outputStream setDelegate:nil];
    
    [inputStream release];
    [outputStream release];
    
    inputStream  = nil;
    outputStream = nil;
    [self setSocketStatus:NSStreamStatusClosed];
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)event
{
    switch(event) {
        case NSStreamEventHasSpaceAvailable: {
            if(stream == outputStream) {
            }
            break;
        }
        case NSStreamEventHasBytesAvailable: {
            if(stream == inputStream) {
                uint8_t buf[1024];
                NSInteger len = [inputStream read:buf maxLength:1024];
                
                if(len > 0) {
                    NSMutableData* data=[[NSMutableData alloc] initWithLength:0];
                    [data appendBytes: (const void *)buf length:len];
                    NSString *s = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                    
                    [self readIn:s];
                    [data release];
                }
            }
            break;
        }
        default: {
            [self setSocketStatus:[outputStream streamStatus]];
            break;
        }
    }
}

- (void)readIn:(NSString *)s
{
    NSLog(@"InFluxDB Socket: %@\n", s);
}

- (void)writeOut:(NSString *)s
{
    uint8_t *buf = (uint8_t *)[s UTF8String];
    [outputStream write:buf maxLength:strlen((char *)buf)];
    totalSent += [s length];
    //NSLog(@"%@", s);
}
//-------------------------------------------

@end
