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
#import "ORSegmentGroup.h"
#import "ORDetectorSegment.h"
#import "OROnCallListModel.h"
#import "ORDataFileModel.h"
#import "ORTimeRate.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

NSString* ORInFluxDBAuthTokenChanged       = @"ORInFluxDBAuthTokenChanged";
NSString* ORInFluxDBOrgChanged             = @"ORInFluxDBOrgChanged";
NSString* ORInFluxDBBucketChanged          = @"ORInFluxDBBucketChanged";
NSString* ORInFluxDBHostNameChanged        = @"ORInFluxDBHostNameChanged";
NSString* ORInFluxDBModelDBInfoChanged     = @"ORInFluxDBModelDBInfoChanged";
NSString* ORInFluxDBRateChanged            = @"ORInFluxDBRateChanged";
NSString* ORInFluxDBStealthModeChanged     = @"ORInFluxDBStealthModeChanged";
NSString* ORInFluxDBBucketArrayChanged     = @"ORInFluxDBBucketArrayChanged";
NSString* ORInFluxDBOrgArrayChanged        = @"ORInFluxDBOrgArrayChanged";
NSString* ORInFluxDBErrorChanged           = @"ORInFluxDBErrorChanged";
NSString* ORInFluxDBConnectionStatusChanged= @"ORInFluxDBConnectionStatusChanged";
NSString* ORInFluxDBMaxLineCountChanged    = @"ORInFluxDBMaxLineCountChanged";
NSString* ORInFluxDBMeasurementTimeOutChanged    = @"ORInFluxDBMeasurementTimeOutChanged";
NSString* ORInFluxDBLock                   = @"ORInFluxDBLock";

static NSString* ORInFluxDBModelInConnector = @"ORInFluxDBModelInConnector";

@interface ORInFluxDBModel (private)
- (void) updateProcesses;
- (void) updateExperimentDuringRun;
- (void) updateHistory;
- (void) updateMachineRecord;
- (void) updateRunState:(ORRunModel*)rc running:(BOOL)isRunning;
- (void) processElementStateChanged:(NSNotification*)aNote;
- (void) periodicCompact;
- (void) updateDataSets;
- (void) _cancelAllPeriodicOperations;
- (void) _startAllPeriodicOperations;
- (void) decodeBucketList:(NSDictionary*)result;
- (void) decodeOrgList   :(NSDictionary*)result;
- (void) processStatusLogLine:(NSNotification*)aNote;

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
    [hostName        release];
    [processThread   release];
    [authToken       release];;
    [org             release];
    [thisHostAddress release];
    [bucketArray     release];
    [orgArray        release];
    [timer           invalidate];
    [timer           release];
    [experimentName  release];
    [runNumberString release];
    [errorString     release];
    [connectionAlarm clearAlarm];
    [connectionAlarm release];
    [lastAlarmDate   release];
    [cmdBuffer       release];

    [super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
        [self setConnectionStatusOK];
        [self connectionChanged];
        [self _startAllPeriodicOperations];
        [self registerNotificationObservers];
        [self executeDBCmd:[ORInFluxDBListOrgs    listOrgs]];
        [self executeDBCmd:[ORInFluxDBListBuckets listBuckets]];
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

- (void) connectionChanged
{
    [self setExperimentName: [[self nextObject] objectName]];
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
                     selector : @selector(runStarted:)
                         name : ORRunStartedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStarted:)
                         name : ORRunStartSubRunNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(runStopped:)
                         name : ORRunBetweenSubRunsNotification
                       object : nil];
    

    [notifyCenter addObserver : self
                     selector : @selector(runStopped:)
                         name : ORRunStoppedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(alarmPosted:)
                         name : ORAlarmWasPostedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(alarmAcknowledged:)
                         name : ORAlarmWasAcknowledgedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(alarmCleared:)
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
    
    [notifyCenter addObserver : self
                     selector : @selector(processStatusLogLine:)
                         name : @"ORDBPostLogMessage"
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(getOnCallChanges:)
                         name : OROnCallListModelEdited
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(dataFileNameChanged:)
                         name : ORDataFileChangedNotification
                       object : nil];
}

- (void) dataFileNameChanged:(NSNotification*)aNote
{
    ORDataFileModel* df = [aNote object];
    ORRunModel* rc = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORRunModel,1"];
    
    ORInFluxDBMeasurement* aCmd = [ORInFluxDBMeasurement measurementForBucket:@"ORCA" org:org];
    [aCmd start   : @"DataFile"];
    [aCmd addField: @"FileName" withString:[df fileName]];
    [aCmd addField: @"RunNumber"    withLong:[rc runNumber]];
    [aCmd addField: @"SubRunNumber" withLong:[rc subRunNumber]];
    [aCmd setTimeStamp: [[NSDate date]timeIntervalSince1970] ];
    [self executeDBCmd:aCmd];
}

-(ORInFluxDBMeasurement*) cmdForBucket:(NSString*)aBucket
{
    return [ORInFluxDBMeasurement measurementForBucket:aBucket org:org];
}

- (void) getOnCallChanges:(NSNotification*)aNote
{
    [(OROnCallListModel*)[aNote object] loadBucket:experimentName inFluxDB:self];
}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) awakeAfterDocumentLoaded
{
    [self startTimer];
//    [self deleteCurrentAlarms];
    [[self nextObject] postInFluxSetUp];
    connectionAlarm = nil;
    lastAlarmDate   = nil;
}

#pragma mark ***Accessors
- (void) setConnectionStatusBad
{
    [self setConnectionStatus:kInFluxDBConnectionBad];
}

- (void) setConnectionStatusOK
{
    [self setConnectionStatus:kInFluxDBConnectionOK];
}

- (void) setConnectionStatusUnknown
{
    [self setConnectionStatus:kInFluxDBConnectionUnknown];
}

- (ORInFluxDBConnectionStatus) connectionStatus
{
    return connectionStatus;
}

- (void) setConnectionStatus:(ORInFluxDBConnectionStatus)status
{
    switch(status){
        case kInFluxDBConnectionBad:
            [self setErrorString:@"No Connection"];
            if(!connectionAlarm){
                if(lastAlarmDate) if(ABS([lastAlarmDate timeIntervalSinceNow]) < 1.0) break;
                NSString* s = [NSString stringWithFormat:@"InFlux (%u) Unable to Connect",[self uniqueIdNumber]];
                connectionAlarm = [[ORAlarm alloc] initWithName:s severity:kImportantAlarm];
                [connectionAlarm setSticky:YES];
                [connectionAlarm setHelpString:@"No InfluxDB connection.\nORCA has tried repeatedly and has been unable to reconnect. Intervention is required. Contact your database manager.\n\nThis alarm will not go away until the problem is cleared. Acknowledging the alarm will silence it."];
                [connectionAlarm postAlarm];
                [lastAlarmDate release];
                lastAlarmDate = [[NSDate now] retain];
            }
            break;
            
        case kInFluxDBConnectionOK:
            [connectionAlarm clearAlarm];
            [connectionAlarm release];
            connectionAlarm = nil;
            [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBConnectionStatusChanged object:self];
            break;
            
        case kInFluxDBConnectionUnknown:
            [self setErrorString:@"Connection status unknown"];
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setConnectionStatusUnknown) object:nil];
            break;
            
        default:
            return;
    }
    connectionStatus = status;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORInFluxDBConnectionStatusChanged object:self];
}

- (id) nextObject
{
    return [self objectConnectedTo:ORInFluxDBModelInConnector];
}

- (NSString*) experimentName
{
    return experimentName;
}

- (void) setExperimentName:(NSString*)aName
{
    [experimentName autorelease];
    experimentName = [aName copy];
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
    [self setConnectionStatusUnknown];
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
    [self setConnectionStatusUnknown];
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
    
    [self setConnectionStatusUnknown];

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
- (short) measurementTimeOut { return measurementTimeOut;}
- (short) maxLineCount       { return maxLineCount;}

- (void)  setMeasurementTimeOut:(short)aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMeasurementTimeOut:measurementTimeOut];
    if(aValue<0)aValue=0;
    if(aValue>10)aValue=10;

    measurementTimeOut = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORInFluxDBMeasurementTimeOutChanged object:self];
}

- (void)  setMaxLineCount:(short) aValue
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxLineCount:maxLineCount];
    if(aValue<0)aValue=0;
    if(aValue>5000)aValue=5000;
    maxLineCount = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORInFluxDBMaxLineCountChanged object:self];
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

- (NSInteger) messageRate     { return messageRate; }
- (BOOL)      cancelled       { return canceled; }
- (void)      markAsCanceled  { canceled = YES;  }

#pragma mark ***Measurements
- (void) bufferMeasurement:(ORInFluxDBMeasurement*)aCmd
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cmdFlush) object:nil];
    [self performSelector:@selector(cmdFlush) withObject:nil afterDelay:2];

    if(measurementTimeOut==0 || maxLineCount==0){
        [self sendCmd:aCmd];
    }
    else {
        NSString* aBucket = [aCmd bucket];
        if(!cmdBuffer) cmdBuffer = [[NSMutableDictionary alloc] init];
        if(![cmdBuffer objectForKey:aBucket]){
            [cmdBuffer setObject:[NSMutableDictionary dictionary] forKey:aBucket];
        }
        NSMutableDictionary* dict = [cmdBuffer objectForKey:aBucket];
        if(![dict objectForKey:@"kTimeStamp"])[dict setObject:[NSDate date] forKey:@"kTimeStamp"];
        if(![dict objectForKey:@"kCmdArray"]) [dict setObject:[NSMutableArray array] forKey:@"kCmdArray"];
        NSMutableArray* cmds = [dict objectForKey:@"kCmdArray"];
        [cmds addObject:aCmd];
        if([cmds count]>maxLineCount){
            [self consolidateAndSendCmdArray:cmds];
        }
    }
}

- (void) cmdFlush
{
    @synchronized (self) {
        for(id aBucket in cmdBuffer){
            NSMutableDictionary* dict = [cmdBuffer objectForKey:aBucket];
            NSDate* timeStamp = [dict objectForKey:@"kTimeStamp"];
            if(fabs([timeStamp timeIntervalSinceNow])>measurementTimeOut){
                [self consolidateAndSendCmdArray:[dict objectForKey:@"kCmdArray"]];
            }
        }
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cmdFlush) object:nil];
        [self performSelector:@selector(cmdFlush) withObject:nil afterDelay:measurementTimeOut];
    }
}

- (void) consolidateAndSendCmdArray:(NSMutableArray*)cmds
{
    if([cmds count]==0)return;
    ORInFluxDBMeasurement* firstCmd = [cmds firstObject]; //need the bucket and org. will be same for all here
    ORInFluxDBCmdLineMode* aCombinedCmd = [ORInFluxDBCmdLineMode lineModeForBucket:[firstCmd bucket] org:[firstCmd org]];
    for(ORInFluxDBMeasurement* aCmd in cmds){
        [aCombinedCmd appendLine:[aCmd cmdLine]];
    }
    [cmds removeAllObjects];

    [self executeDBCmd:aCombinedCmd];
}

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
    
    if(([self connectionStatus]==kInFluxDBConnectionOK) && connectionAlarm && [connectionAlarm acknowledged]){
        [connectionAlarm clearAlarm];
        [connectionAlarm release];
        connectionAlarm = nil;
    }
}

- (void) processStatusLogLine:(NSNotification*)aNote
{
    BOOL userMessage = NO;
    NSAttributedString* s = [[aNote userInfo] objectForKey:@"Log"];
    
    //could be a user entered message
    if(!s){
        userMessage = YES;
        s = [[aNote userInfo]objectForKey:@"UserMessage"];
    }
        
    __block NSString* tags = @"level=0";

    [s enumerateAttribute:(NSString *) NSForegroundColorAttributeName
                                     inRange:NSMakeRange(0, [s length])
    options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                                  usingBlock:^(id value, NSRange range, BOOL *stop) {
        
        if([[value description] isEqualToString:@"_NSTaggedPointerColor"]){
            NSString* subString = [value description];
            //sRGB IEC61966-2.1 colorspace 1 0 0 1
 //           if([s rangeOfString:@"sRGB"].location != NSNotFound){
                NSArray* parts = [subString componentsSeparatedByString:@" "];
                //sRGB IEC61966-2.1 colorspace 1 0 0 1
                if([parts count]>=6){
                    if([[parts objectAtIndex:3]intValue]==1 &&
                       [[parts objectAtIndex:4]intValue]==0 &&
                       [[parts objectAtIndex:5]intValue]==0 ){
                        tags = @"level=1";
                    }
                    else if([[parts objectAtIndex:3]intValue]==0 &&
                            [[parts objectAtIndex:4]intValue]==1 &&
                            [[parts objectAtIndex:5]intValue]==0 ){
                        tags = @"level=2";
                    }
                }
            }
//        }
        }];

    NSString* measurementName;
    if (userMessage)
        measurementName = @"UserMessage";
    else
        measurementName = @"StatusLog";

    ORInFluxDBMeasurement* aCmd = [ORInFluxDBMeasurement measurementForBucket:@"Logs" org:org];
    [aCmd   start  : measurementName withTags:tags];
    [aCmd addField: @"Line"     withString:[s string]];
    [aCmd setTimeStamp: [[NSDate date]timeIntervalSince1970] ];
    [self executeDBCmd:aCmd];

}

- (NSString*) errorString
{
    return errorString;
}

- (void) setErrorString:(NSString*)anError
{
    [errorString autorelease];
    errorString = [anError copy];
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORInFluxDBErrorChanged
                                    object:self
                                  userInfo:nil
                             waitUntilDone:NO];

}

- (void) updateAlarmState:(ORAlarm*)anAlarm
{
    ORRunModel*   rc    = [[(ORAppDelegate*)[NSApp delegate] document] findObjectWithFullID:@"ORRunModel,1"];
    NSString* alarmName = [[anAlarm name]stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    NSString* help      = [anAlarm helpString];
    NSInteger firstLF   = [help rangeOfString:@"\n"].location;
    help                = [help substringFromIndex:firstLF];

    NSString* stateName ;
    if ([anAlarm isPosted]) {
        if ([anAlarm acknowledged]) {
            stateName = @"ack";
        } else {
            stateName = [anAlarm severityName];
        }
    } else {
        stateName = @"clear";
    }

    ORInFluxDBMeasurement* aCmd = [ORInFluxDBMeasurement measurementForBucket:@"Alarms" org:org];
    [aCmd start:    @"Alarm"];
    [aCmd addTag:   @"Severity"      withString:[anAlarm severityName]];
    [aCmd addField: alarmName         withString:stateName];
//        [aCmd addTag: @"Help"          withString:help];
    [aCmd addTag: @"RunNumber"    withLong:[rc runNumber]];
    [aCmd addTag: @"SubRunNumber" withLong:[rc subRunNumber]];
//        [aCmd setTimeStamp:[anAlarm timePostedUnixTimestamp]];
    [aCmd setTimeStamp:[[NSDate date]timeIntervalSince1970]];
    [self executeDBCmd:aCmd];
}

- (void) alarmPosted:(NSNotification*)aNote
{
    if(!stealthMode){
        [self updateAlarmState:[aNote object]];
    }
}

- (void) alarmAcknowledged:(NSNotification*)aNote
{
    if(!stealthMode){
        [self updateAlarmState:[aNote object]];
    }
}

- (void) alarmCleared:(NSNotification*)aNote
{
    if(!stealthMode){
        [self updateAlarmState:[aNote object]];
    }
}

- (void) updateRunState:(ORRunModel*)rc running:(BOOL)isRunning
{
    scheduledForRunInfoUpdate = NO;

    if(!stealthMode){
        ORInFluxDBMeasurement* aCmd = [ORInFluxDBMeasurement measurementForBucket:@"ORCA" org:org];
        [aCmd    start: @"CurrentRun"  withTags:@"Type=Status"];
        [aCmd addField: @"RunNumber"   withLong:[rc runNumber]];
        [aCmd addField: @"SubRunNumber" withLong:[rc subRunNumber]];
        [aCmd addField: @"Running"     withBoolean:isRunning];
        [aCmd addField: @"ElapsedTime" withLong:[rc elapsedRunTime]];
        [aCmd addField: @"TimeToGo"    withLong:(long)[rc timeToGo]];
        [aCmd addField: @"RunType"     withLong:[rc runType]];
        [aCmd addField: @"TimedRun"    withBoolean:[rc timedRun]];
        [aCmd addField: @"RunMode"     withString:[[ORGlobal sharedGlobal] runMode] == kNormalRun?@"Normal":@"OffLine"];
        [aCmd addField: @"Repeating"   withBoolean:[rc repeatRun]];
        if([rc timedRun])[aCmd addField: @"Length"  withLong:[rc timeLimit]];
        else             [aCmd addField: @"Length"  withLong:0];

        [aCmd addField:   @"RunModeDesc" withString:[rc runTypesMaskString]];
        [self executeDBCmd:aCmd];
    }
}

- (void) runStarted:(NSNotification*)aNote
{
    if(!stealthMode){
        ORRunModel* rc  = [aNote object];
        [self updateRunState:rc running:YES];
        [runNumberString release];
        runNumberString = [rc fullRunNumberString];
        [[self nextObject] postInFluxSetUp];
    }
}

- (void) runStopped:(NSNotification*)aNote
{
    [runNumberString release];
    runNumberString = nil;

    if(!stealthMode){
        [self updateRunState:[aNote object] running:NO];
//        [self performSelector:@selector(updateExperiment) withObject:nil afterDelay:1];
    }
}

- (void) executeDBCmd:(id)aCmd
{
    @synchronized (self) {
        [aCmd executeCmd:self];
    }
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
        ORInFluxDBDeleteBucket* aCmd = [ORInFluxDBDeleteBucket deleteBucket];
        [aCmd setBucketId:[bucketInfo objectForKey:@"id"]];
        [self executeDBCmd:aCmd];
        [self performSelector:@selector(executeDBCmd:) withObject:[ORInFluxDBListBuckets listBuckets] afterDelay:2];
        NSLog(@"Posting Delete Bucket %@:%@\n",[bucketInfo objectForKey:@"name"],[self org]);
    }
}

- (void) deleteBucketByName:(NSString*)aName
{
    for(id aBucket in bucketArray){
        if([[aBucket objectForKey:@"name"]isEqualToString:aName]){
            ORInFluxDBDeleteBucket* aCmd = [ORInFluxDBDeleteBucket deleteBucket];
            [aCmd setBucketId:[aBucket objectForKey:@"id"]];
            [self executeDBCmd:aCmd];
            [self performSelector:@selector(executeDBCmd:) withObject:[ORInFluxDBListBuckets listBuckets] afterDelay:2];
        }
    }
}
- (void) createBuckets
{
    if(experimentName){
        [self executeDBCmd:[ORInFluxDBCreateBucket createBucket:experimentName
                                                          orgId:[self orgId] expireTime:60*60*24*7]];
    }
    [self executeDBCmd:[ORInFluxDBCreateBucket createBucket:@"Logs"
                                                      orgId:[self orgId] expireTime:60*60*24*60]];
    
    [self executeDBCmd:[ORInFluxDBCreateBucket createBucket:@"HWMaps"
                                                      orgId:[self orgId] expireTime:60*60*24*60]];

    [self executeDBCmd:[ORInFluxDBCreateBucket createBucket:@"ORCA"
                                                      orgId:[self orgId] expireTime:60*60*24*14]];
    
    [self executeDBCmd:[ORInFluxDBCreateBucket createBucket:@"Sensors"
                                                      orgId:[self orgId] expireTime:60*60*24*60]];
    
    [self executeDBCmd:[ORInFluxDBCreateBucket createBucket:@"Computer"
                                                      orgId:[self orgId] expireTime:60*60*24*10]];
    
    [self executeDBCmd:[ORInFluxDBCreateBucket createBucket:@"Alarms"
                                                      orgId:[self orgId] expireTime:60*60*24*10]];

    [self executeDBCmd:[ORInFluxDBCreateBucket createBucket:@"SlowControls"
                                                      orgId:[self orgId] expireTime:60*60*24*10]];

    
    [self performSelector:@selector(executeDBCmd:) withObject:[ORInFluxDBListBuckets listBuckets] afterDelay:1];
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager]  disableUndoRegistration];
    [self setHostName:   [decoder decodeObjectForKey     : @"HostName"]];
    [self setAuthToken:  [decoder decodeObjectForKey     : @"Token"]];
    [self setOrg:        [decoder decodeObjectForKey     : @"Org"]];
    [self setExperimentName: [decoder decodeObjectForKey : @"experimentName"]];
    [self setMeasurementTimeOut: [decoder decodeIntForKey: @"measurementTimeOut"]];
    [self setMaxLineCount: [decoder decodeIntForKey      : @"maxLineCount"]];
    [[self undoManager]  enableUndoRegistration];
    [self registerNotificationObservers];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:hostName       forKey: @"HostName"];
    [encoder encodeObject:authToken      forKey: @"Token"];
    [encoder encodeObject:org            forKey: @"Org"];
    [encoder encodeObject:experimentName forKey: @"experimentName"];
    [encoder encodeInt:measurementTimeOut forKey: @"measurementTimeOut"];
    [encoder encodeInt:maxLineCount      forKey: @"maxLineCount"];
}

- (void) _cancelAllPeriodicOperations
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void) _startAllPeriodicOperations
{
    [self performSelector:@selector(updateMachineRecord)         withObject:nil afterDelay:2];
    [self performSelector:@selector(updateExperimentDuringRun)   withObject:nil afterDelay:3];
}

- (void) updateMachineRecord
{
    if(!stealthMode){
        @try {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateMachineRecord) object:nil];
 
            [self updateMachineAddress];
            [self updateOrcaResources];
            [self updateDiskInfo];
        }
        @catch (NSException* e){
            NSLog(@"%@ %@ updateMachineRecord Exception: %@\n",[self fullID],NSStringFromSelector(_cmd),e);
        }
        @finally {
            [self performSelector:@selector(updateMachineRecord) withObject:nil afterDelay:60];
        }
    }
}

- (void) updateOrcaResources
{
    long uptime = [[(ORAppDelegate*)(ORAppDelegate*)[NSApp delegate] memoryWatcher] upTime];
    long memory = [[(ORAppDelegate*)(ORAppDelegate*)[NSApp delegate] memoryWatcher] orcaMemory];
    
    ORInFluxDBMeasurement* aMeasurement;
    aMeasurement  = [ORInFluxDBMeasurement measurementForBucket:@"ORCA" org:org];
    [aMeasurement start    : @"ORCAStatus"   withTags:@"Type=Resources"];
    [aMeasurement addField : @"Uptime"       withLong:uptime];
    [aMeasurement addField : @"Memory"       withLong:memory];
    [aMeasurement addField : @"ComputerName" withString:computerName()];
    [self executeDBCmd:aMeasurement];
}

- (void) updateDiskInfo
{
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
            ORInFluxDBMeasurement* aMeasurement  = [ORInFluxDBMeasurement measurementForBucket:@"Computer" org:org];
            [aMeasurement start:@"DiskInfo" withTags:[NSString stringWithFormat:@"Disk=%@",aVolume]];
            [aMeasurement addField:@"FreeSpace"   withDouble:freeSpace];
            [aMeasurement addField:@"TotalSpace"  withDouble:totalSpace];
            [aMeasurement addField:@"PercentUsed" withDouble:percentUsed];
            [self executeDBCmd:aMeasurement];
        }
    }
}

- (void) updateMachineAddress
{
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
                [thisHostAddress release];
                thisHostAddress = [aName copy];
                break;
            }
        }
    }
    
    if(thisHostAddress){
        ORInFluxDBMeasurement* aMeasurement = [ORInFluxDBMeasurement measurementForBucket:@"Computer" org:org];
        [aMeasurement start:   @"Identity"     withTags:@"Type=Status"];
        [aMeasurement addField:@"CurrentTime"  withLong:[[NSDate date]timeIntervalSince1970]];
        [aMeasurement addField:@"ComputerName" withString:computerName()];
        [aMeasurement addField:@"HwAddress"    withString:macAddress()];
        [aMeasurement addField:@"IPAddress"    withString:thisHostAddress];
        [self executeDBCmd:aMeasurement];
    }
}

- (void) updateExperimentDuringRun
{
    if(!stealthMode){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateExperimentDuringRun) object:nil];
        @try {
            if([[ORGlobal sharedGlobal] runRunning]){
                [[self nextObject] postInFluxRunTime];
            }
        }
        @catch (NSException* e){
            NSLog(@"%@ %@ updateExperimentDuringRun Exception: %@\n",[self fullID],NSStringFromSelector(_cmd),e);
        }
        @finally {
            [self performSelector:@selector(updateExperimentDuringRun) withObject:nil afterDelay:30];
        }
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

- (void) decodeBucketList:(NSDictionary*)result
{
    NSArray* anArray = [result objectForKey:@"buckets"];
    [bucketArray release];
    bucketArray = [[NSMutableArray array] retain];
    for(NSDictionary* aBucket in anArray){
        if(![[aBucket objectForKey:@"name"] hasPrefix:@"_"]){
            [bucketArray addObject:aBucket];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORInFluxDBBucketArrayChanged
                                    object:self
                                  userInfo:nil
                             waitUntilDone:NO];
    [self printBucketTable];
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
    [self printOrgTable];
}

- (void) printBucketTable
{
    if(bucketArray){
        NSString* title = [NSString stringWithFormat:@"InfluxDB Buckets (%@)",org];
        int width = 37;
        NSLogStartTable(title, width);
        NSLogMono(@"|      name    |         ID         |\n");
        NSLogDivider(@"-",width);
        for(id aBucket in bucketArray){
            NSLogMono(@"| %@ | %@ |\n", [[aBucket objectForKey:@"name"] leftJustified:12],[[aBucket objectForKey:@"id"]leftJustified:18]);
        }
        NSLogDivider(@"=",width);
    }
    else NSLog(@"No buckets found for UNC\n");
}
- (void) printOrgTable
{
    if(orgArray){
        NSString* title = @"InfluxDB Orgs";
        int width = 37;
        NSLogStartTable(title, width);
        NSLogMono(@"|      name    |         ID         |\n");
        NSLogDivider(@"-",width);
        for(id anOrg in orgArray){
            NSLogMono(@"| %@ | %@ |\n", [[anOrg objectForKey:@"name"] leftJustified:12],[[anOrg objectForKey:@"id"]leftJustified:18]);
        }
        NSLogDivider(@"=",width);
    }
    else NSLog(@"No organizations found\n");
}


#pragma mark ***Thread
//-----------------------------------------------------
// here we accumulate measurements under either 5 seconds
// has lapsed since first measurement in the group
// or we have >4000 lines in the buffer. A complication is
// that we have to keep track for each bucket
//-----------------------------------------------------
- (void)sendMeasurments
{
    NSAutoreleasePool* outerPool = [[NSAutoreleasePool alloc] init];
    if(!messageQueue){
        messageQueue = [[ORSafeQueue alloc] init];
    }

    do {
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
        id     aCmd = [messageQueue dequeue];
        if(aCmd!=nil){
            NSMutableURLRequest* request = [aCmd requestFrom:self];
            if(request){
                NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
                NSURLSession*             session = [NSURLSession sessionWithConfiguration:config];
                NSURLSessionDataTask*      dbTask = [session dataTaskWithRequest:request
                                                               completionHandler:^(NSData* data,
                                                                                   NSURLResponse* response,
                                                                                   NSError* error) {
                    if (!error) {
                        NSDictionary* result = [NSJSONSerialization JSONObjectWithData: data
                                                                               options: kNilOptions
                                                                                 error: &error];
                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                        [aCmd logResult:result code:(int)[httpResponse statusCode] delegate:self];
                        [self performSelectorOnMainThread:@selector(setConnectionStatusOK)
                                               withObject:nil
                                            waitUntilDone:NO];
                    }
                    else {
                        [self performSelectorOnMainThread:@selector(setConnectionStatusBad)
                                               withObject:nil
                                            waitUntilDone:NO];
                    }
                }];
                    
                [dbTask resume]; //task is created in paused state, so start it
                    
                totalSent += [aCmd requestSize];
            }
        }
        [pool release];
        if([self connectionStatus] == kInFluxDBConnectionBad) [NSThread sleepForTimeInterval:1.0];
        else [NSThread sleepForTimeInterval:.01];
    }while(!canceled);
    [outerPool release];
}
@end
