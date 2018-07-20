//
//  SNOPModel.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 20, 2010.
//  Copyright (c) 2010  University of North Carolina. All rights reserved.
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


#pragma mark ¥¥¥Imported Files
#import "SNOPModel.h"
#import "SNOPController.h"
#import "ORSegmentGroup.h"
#import "ORTaskSequence.h"
#import "ORCouchDB.h"
#import "ORXL3Model.h"
#import "ORDataTaker.h"
#import "ORDataTypeAssigner.h"
#import "ORGlobal.h"
#import "ORRunModel.h"
#import "ORMTCModel.h"
#import "ORMTCController.h"
#import "ORMTC_Constants.h"
#import "ORFecDaughterCardModel.h"
#import "ORFec32Model.h"
#import "OROrderedObjManager.h"
#import "ORSNOConstants.h"
#import "ORDataFileModel.h"
#import "ELLIEModel.h"
#import "SNOP_Run_Constants.h"
#import "SBC_Link.h"
#import "SNOCmds.h"
#import "RedisClient.h"
#include <stdint.h>
#include <unistd.h>
#import "SNOCaenModel.h"
#import "TUBiiModel.h"
#import "XL3_Link.h"
#import "ORPQModel.h"
#import "ORPQResult.h"
#import "RunTypeWordBits.hh"
#import "TUBiiModel.h"
#import "SessionDB.h"

#define RUNNING 0
#define STARTING 1
#define STOPPING 2
#define STOPPED 3

#define COLD_START 0
#define CONTINUOUS_START 1
#define ROLLOVER_START 2

static NSString* SNOPDbConnector	= @"SNOPDbConnector";
NSString* ORSNOPModelOrcaDBIPAddressChanged = @"ORSNOPModelOrcaDBIPAddressChanged";
NSString* ORSNOPModelDebugDBIPAddressChanged = @"ORSNOPModelDebugDBIPAddressChanged";
NSString* ORSNOPRunTypeWordChangedNotification = @"ORSNOPRunTypeWordChangedNotification";
NSString* ORSNOPRunTypeChangedNotification = @"ORSNOPRunTypeChangedNotification";
NSString* ORSNOPRunsLockNotification = @"ORSNOPRunsLockNotification";
NSString* ORSNOPModelSRCollectionChangedNotification = @"ORSNOPModelSRCollectionChangedNotification";
NSString* ORSNOPModelSRChangedNotification = @"ORSNOPModelSRChangedNotification";
NSString* ORSNOPModelSRVersionChangedNotification = @"ORSNOPModelSRVersionChangedNotification";
NSString* ORSNOPModelNhitMonitorChangedNotification = @"ORSNOPModelNhitMonitorChangedNotification";
NSString* ORSNOPStillWaitingForBuffersNotification = @"ORSNOPStillWaitingForBuffersNotification";
NSString* ORSNOPNotWaitingForBuffersNotification = @"ORSNOPNotWaitingForBuffersNotification";
NSString* ORRoutineChangedNotification = @"ORRoutineChangedNotification";

BOOL isNotRunningOrIsInMaintenance()
{
    return (![gOrcaGlobals runInProgress] ||
            (([gOrcaGlobals runType] & kMaintenanceRun) ||
             ([gOrcaGlobals runType] & kDiagnosticRun)));
}

@implementation SNOPModel

@synthesize
orcaDBUserName = _orcaDBUserName,
smellieRunNameLabel = _smellieRunNameLabel,
tellieRunNameLabel = _tellieRunNameLabel,
amellieRunNameLabel = _amellieRunNameLabel,
orcaDBPassword = _orcaDBPassword,
orcaDBName = _orcaDBName,
orcaDBPort = _orcaDBPort,
orcaDBConnectionHistory = _orcaDBConnectionHistory,
orcaDBIPNumberIndex = _orcaDBIPNumberIndex,
orcaDBPingTask = _orcaDBPingTask,
debugDBUserName = _debugDBUserName,
debugDBPassword = _debugDBPassword,
debugDBName = _debugDBName,
debugDBPort = _debugDBPort,
debugDBConnectionHistory = _debugDBConnectionHistory,
debugDBIPNumberIndex = _debugDBIPNumberIndex,
debugDBPingTask = _debugDBPingTask,
smellieDBReadInProgress = _smellieDBReadInProgress,
smellieDocUploaded = _smellieDocUploaded,
dataHost,
dataPort,
logHost,
logPort,
resync,
smellieRunFiles = _smellieRunFiles,
amellieRunFiles = _amellieRunFiles,
tellieRunFiles = _tellieRunFiles;

#pragma mark ¥¥¥Initialization

- (id) init
{
    self = [super init];

    rolloverRun = NO;
    state = STOPPED;
    start = COLD_START;
    resync = NO;

    /* initialize our connection to the MTC server */
    mtc_server = [[RedisClient alloc] init];

    /* initialize our connection to the XL3 server */
    xl3_server = [[RedisClient alloc] init];

    [[self undoManager] disableUndoRegistration];

    [self setMTCHost:@""];
    [self setXL3Host:@""];
    [self setDataServerHost:@""];
    [self setLogServerHost:@""];

    [self setMTCPort:4001];
    [self setXL3Port:4004];
    [self setDataServerPort:4005];
    [self setLogServerPort:4001];

    [self initOrcaDBConnectionHistory];
    [self initDebugDBConnectionHistory];

    [[self undoManager] enableUndoRegistration];

    return self;
}


#pragma mark ¥¥¥Session DB Interface

- (void) setSessionDBUsername: (NSString *) username
{
    [[self sessionDB] setUsername:username];
}

- (NSString *) sessionDBUsername
{
    return [sessionDB username];
}

- (void) setSessionDBPassword: (NSString *) password
{
    [[self sessionDB] setPassword:password];
}

- (NSString *) sessionDBPassword
{
    return [sessionDB password];
}

- (void) setSessionDBName: (NSString *) dbname
{
    [[self sessionDB] setDbname:dbname];
}

- (NSString *) sessionDBName
{
    return [sessionDB dbname];
}

- (void) setSessionDBAddress: (NSString *) address
{
    [[self sessionDB] setAddress:address];
}

- (NSString *) sessionDBAddress
{
    return [sessionDB address];
}

- (void) setSessionDBPort: (unsigned int) port
{
    [[self sessionDB] setPort:port];
}

- (unsigned int) sessionDBPort
{
    return [sessionDB port];
}

- (void) setSessionDBLockID: (unsigned int) lockID
{
    [[self sessionDB] setLockID:lockID];
}

- (unsigned int) sessionDBLockID
{
    return [sessionDB lockID];
}

#pragma mark ¥¥¥Hardware

- (void) setMTCPort: (int) port
{
    int i;

    if (port == mtcPort) return;

    mtcPort = port;
    [mtc_server disconnect];
    [mtc_server setPort:port];

    /* Set the MTC server hostname for the MTC model. */
    NSArray* mtcs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];

    ORMTCModel* mtc;
    for (i = 0; i < [mtcs count]; i++) {
        mtc = [mtcs objectAtIndex:0];
        [mtc setMTCPort:port];
    }

    /* Set the MTC server hostname for the CAEN model. */
    NSArray* caens = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"SNOCaenModel")];

    SNOCaenModel* caen;
    for (i = 0; i < [caens count]; i++) {
        caen = [caens objectAtIndex:0];
        [caen setMTCPort:port];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SNOPSettingsChanged" object:self];
}

- (int) mtcPort
{
    return mtcPort;
}

- (void) setMTCHost: (NSString *) host
{
    int i;

    if ([host isEqualToString:mtcHost]) return;

    [mtcHost autorelease];//MAH -- strings should be handled like this
    mtcHost = [host copy];
    [mtc_server disconnect];
    [mtc_server setHost:host];

    /* Set the MTC server hostname for the MTC model. */
    NSArray* mtcs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];

    ORMTCModel* mtc;
    for (i = 0; i < [mtcs count]; i++) {
        mtc = [mtcs objectAtIndex:i];
        [mtc setMTCHost:host];
    }

    /* Set the MTC server hostname for the CAEN model. */
    NSArray* caens = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"SNOCaenModel")];

    SNOCaenModel* caen;
    for (i = 0; i < [caens count]; i++) {
        caen = [caens objectAtIndex:i];
        [caen setMTCHost:host];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SNOPSettingsChanged" object:self];
}

- (NSString *) mtcHost
{
    return mtcHost;
}

- (void) setXL3Port: (int) port
{
    /* Set the port number for the XL3 server redis client. */
    if (port == xl3Port) return;

    xl3Port = port;
    [xl3_server disconnect];
    [xl3_server setPort:port];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SNOPSettingsChanged" object:self];
}

- (int) xl3Port
{
    return xl3Port;
}

- (void) setXL3Host: (NSString *) host
{
    /* Set the XL3 server hostname. This function will automatically
     * sync this value to all of the XL3 model objects. */
    int i;

    if ([host isEqualToString:xl3Host]) return;

    [xl3Host autorelease];//MAH -- strings should be handled like this
    xl3Host = [host copy];
    [xl3_server disconnect];
    [xl3_server setHost:host];

    /* Set the XL3 server hostname for the XL3 models. */
    NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];

    ORXL3Model* xl3;
    for (i = 0; i < [xl3s count]; i++) {
        xl3 = [xl3s objectAtIndex:i];
        [[xl3 xl3Link] disconnectSocket];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:@"SNOPSettingsChanged" object:self];
}

- (NSString *) xl3Host
{
    return xl3Host;
}

- (void) setLogNameFormat
{
    NSArray *dataFileModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORDataFileModel")];
    if (![dataFileModels count]) {
        NSLogColor([NSColor redColor], @"SetLogNameFormat: can't find ORDataFileModel!\n");
        return;
    }
    ORDataFileModel* aDataFileModel = [dataFileModels objectAtIndex:0];

    // Get hostname of operator machine
    char hostname[255];
    gethostname(hostname, 255);

    // Add a prefix / suffix to the datafile
    [aDataFileModel setFilePrefix:@""];
    [aDataFileModel setFileStaticSuffix:[NSString stringWithFormat:@"_%s",hostname]];
}

- (void) saveLogFiles:(NSNotification*)aNote
{
    /*
     This method gets called by a notification observer, which waits for ORCA to close.
    */
    NSArray*  runObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runObjects count]){
        NSLogColor([NSColor redColor], @"waitForRunNumber: couldn't find run control object!");
        /* This should never happen. */
        return;
    }
    ORRunModel* runControl = [runObjects objectAtIndex:0];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlushLogsNotification object:self userInfo:[runControl runInfo]];
}

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];

    rolloverRun = NO;
    state = STOPPED;
    start = COLD_START;
    resync = NO;

    // Session database
    sessionDB = [[SessionDB alloc] init];
    [[self sessionDB] setUsername:[decoder decodeObjectForKey:@"ORSNOPModelLockDBUserName"]];
    [[self sessionDB] setPassword:[decoder decodeObjectForKey:@"ORSNOPModelLockDBPassword"]];
    [[self sessionDB] setDbname:[decoder decodeObjectForKey:@"ORSNOPModelLockDBName"]];
    [[self sessionDB] setAddress:[decoder decodeObjectForKey:@"ORSNOPModelLockDBIPAddress"]];
    [[self sessionDB] setPort:[decoder decodeIntForKey:@"ORSNOPModelLockDBPort"]];
    [[self sessionDB] setLockID:[decoder decodeIntForKey:@"ORSNOPModelLockDBLockID"]];

    /* Initialize ECARun object: this doesn't start the run */
    anECARun = [[ECARun alloc] init];
    nhitMonitor = [[NHitMonitor alloc] init];
    ecaLock = [[NSLock alloc] init];
    /* Initialize LivePed object*/
    livePeds = [[LivePedestals alloc] init];
    [[self undoManager] disableUndoRegistration];
    [self initOrcaDBConnectionHistory];
    [self initDebugDBConnectionHistory];

    //CouchDB
    self.orcaDBUserName = [decoder decodeObjectForKey:@"ORSNOPModelOrcaDBUserName"];
    self.orcaDBPassword = [decoder decodeObjectForKey:@"ORSNOPModelOrcaDBPassword"];
    self.orcaDBName = [decoder decodeObjectForKey:@"ORSNOPModelOrcaDBName"];
    self.orcaDBPort = [decoder decodeIntForKey:@"ORSNOPModelOrcaDBPort"];
    self.orcaDBIPAddress = [decoder decodeObjectForKey:@"ORSNOPModelOrcaDBIPAddress"];
    self.debugDBUserName = [decoder decodeObjectForKey:@"ORSNOPModelDebugDBUserName"];
    self.debugDBPassword = [decoder decodeObjectForKey:@"ORSNOPModelDebugDBPassword"];
    self.debugDBName = [decoder decodeObjectForKey:@"ORSNOPModelDebugDBName"];
    self.debugDBPort = [decoder decodeIntForKey:@"ORSNOPModelDebugDBPort"];
    self.debugDBIPAddress = [decoder decodeObjectForKey:@"ORSNOPModelDebugDBIPAddress"];

    //Standard Runs
    //fixed memory leak -- no matching release for alloc MAH 03/08/2017
    [self setStandardRunTableVersion:[[[NSNumber alloc] initWithInt:STANDARD_RUN_VERSION] autorelease]];
    standardRunCollection = [[NSMutableDictionary alloc] init];
    [self setLastStandardRunType:[decoder decodeObjectForKey:@"SNOPlastStandardRunType"]];
    [self setLastStandardRunVersion:[decoder decodeObjectForKey:@"SNOPlastStandardRunVersion"]];
    [self setLastRunTypeWordHex:[decoder decodeObjectForKey:@"SNOPlastRunTypeWordHex"]];
    [self setStandardRunType:[decoder decodeObjectForKey:@"SNOPStandardRunType"]];
    [self setStandardRunVersion:[decoder decodeObjectForKey:@"SNOPStandardRunVersion"]];

    //ECA
    [anECARun setECA_pattern:[decoder decodeIntForKey:@"SNOPECApattern"]];
    [anECARun setECA_type:[decoder decodeObjectForKey:@"SNOPECAtype"]];
    [anECARun setECA_tslope_pattern:[decoder decodeIntForKey:@"SNOPECAtslppattern"]];
    [anECARun setECA_nevents:[decoder decodeIntForKey:@"SNOPECANEvents"]];
    [anECARun setECA_rate:[decoder decodeObjectForKey:@"SNOPECAPulserRate"]];

    //Settings
    [self setMTCHost:[decoder decodeObjectForKey:@"mtcHost"]];
    [self setMTCPort:[decoder decodeIntForKey:@"mtcPort"]];

    [self setXL3Host:[decoder decodeObjectForKey:@"xl3Host"]];
    [self setXL3Port:[decoder decodeIntForKey:@"xl3Port"]];

    [self setDataServerHost:[decoder decodeObjectForKey:@"dataHost"]];
    [self setDataServerPort:[decoder decodeIntForKey:@"dataPort"]];

    [self setLogServerHost:[decoder decodeObjectForKey:@"logHost"]];
    [self setLogServerPort:[decoder decodeIntForKey:@"logPort"]];
    
    /* Check if we actually decoded the mtc, xl3, data, and log server
     * hostnames and ports. decodeObjectForKey() will return NULL if the
     * key doesn't exist, and decodeIntForKey() will return 0. */
    if ([self mtcHost] == NULL) [self setMTCHost:@""];
    if ([self xl3Host] == NULL) [self setXL3Host:@""];
    if ([self dataHost] == NULL) [self setDataServerHost:@""];
    if ([self logHost] == NULL) [self setLogServerHost:@""];

    if ([self mtcPort] == 0) [self setMTCPort:4001];
    if ([self xl3Port] == 0) [self setXL3Port:4004];
    if ([self dataPort] == 0) [self setDataServerPort:4005];
    if ([self logPort] == 0) [self setLogServerPort:4001];

    /* Nhit Monitor Settings */
    [self setNhitMonitorCrate:[decoder decodeIntForKey:@"nhitMonitorCrate"]];
    [self setNhitMonitorPulserRate:[decoder decodeIntForKey:@"nhitMonitorPulserRate"]];
    [self setNhitMonitorNumPulses:[decoder decodeIntForKey:@"nhitMonitorNumPulses"]];
    [self setNhitMonitorMaxNhit:[decoder decodeIntForKey:@"nhitMonitorMaxNhit"]];
    [self setNhitMonitorAutoPulserRate:[decoder decodeIntForKey:@"nhitMonitorAutoPulserRate"]];
    [self setNhitMonitorAutoNumPulses:[decoder decodeIntForKey:@"nhitMonitorAutoNumPulses"]];
    [self setNhitMonitorAutoMaxNhit:[decoder decodeIntForKey:@"nhitMonitorAutoMaxNhit"]];
    [self setNhitMonitorRunType:[decoder decodeIntForKey:@"nhitMonitorRunType"]];
    [self setNhitMonitorCrateMask:[decoder decodeIntForKey:@"nhitMonitorCrateMask"]];
    /* Don't automatically run the nhit monitor until we load all the settings.
     * Initially the time interval and auto run variables will be uninitialized
     * in this method and if we set the time interval here and
     * nhitMonitorAutoRun is set to YES, it will start the automatic timer
     * before the settings are loaded. */
    nhitMonitorAutoRun = NO;
    [self setNhitMonitorTimeInterval:[decoder decodeDoubleForKey:@"nhitMonitorTimeInterval"]];
    [self setNhitMonitorAutoRun:[decoder decodeBoolForKey:@"nhitMonitorAutoRun"]];
    [[self undoManager] enableUndoRegistration];

    //Set extra security
    [gSecurity addSuperUnlockMask:kDiagnosticRun forObject:self];

    /* initialize our connection to the MTC server */
    mtc_server = [[RedisClient alloc] initWithHostName:mtcHost withPort:mtcPort];

    /* initialize our connection to the XL3 server */
    xl3_server = [[RedisClient alloc] initWithHostName:xl3Host withPort:xl3Port];

    return self;
}

- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"SNOP"]];
}

- (void) makeMainController
{
    [self linkToController:@"SNOPController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint([self frame].size.width - kConnectorSize,2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:SNOPDbConnector];
    [aConnector setOffColor:[NSColor brownColor]];
    [aConnector setOnColor:[NSColor magentaColor]];
    [aConnector setConnectorType: 'DB O'];
    [aConnector addRestrictedConnectionType: 'DB I']; //can only connect to DB outputs
    [aConnector release];
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [standardRunCollection removeAllObjects];
    [standardRunCollection release];
    [standardRunType release];
    [standardRunVersion release];
    [standardRunTableVersion release];
    [_debugDBConnectionHistory release];
    [_debugDBName release];
    [_debugDBUserName release];
    [_debugDBPassword release];
    [_debugDBPingTask release];
    [_orcaDBName release];
    [_orcaDBPassword release];
    [_orcaDBUserName release];
    [_orcaDBConnectionHistory release];
    [_orcaDBPingTask release];
    [_smellieRunNameLabel release];
    [dataHost release];
    [logHost release];
    [anECARun release];
    [livePeds release];
    [nhitMonitor release];
    [sessionDB release];
    [ecaLock release];
    [_smellieRunFiles release];
    [_tellieRunFiles release];
    [_tellieRunNameLabel release];
    [_amellieRunFiles release];
    [_amellieRunNameLabel release];

    [defaultRunAlarm clearAlarm];
    [defaultRunAlarm dealloc];
    [super dealloc];
}

- (void) sleep
{
    [super sleep];
}

- (void) awakeAfterDocumentLoaded
{
    /**
     * Check that no other Orca is controlling the detector (using a database
     * lock and that we are running the latest version, and post session
     * information to the database. This will either block or quit.
     */
    [[self sessionDB] startSession];

    /* Add hostname as prefix to logs */
    [self setLogNameFormat];

    /* Get the standard runs from the database. */
    [self refreshStandardRunsFromDB];
    [self enableGlobalSecurity];
    [[ORGlobal sharedGlobal] setCanQuitDuringRun:YES];
}

- (void) initOrcaDBConnectionHistory
{
    self.orcaDBIPNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.orcaDBIPNumberIndex",[self className]]];

    if (!self.orcaDBConnectionHistory) {
        NSArray *his = [[NSUserDefaults standardUserDefaults] objectForKey:
                [NSString stringWithFormat:@"orca.%@.orcaDBConnectionHistory",[self className]]];

        self.orcaDBConnectionHistory = [[his mutableCopy] autorelease];
    }

    if (!self.orcaDBConnectionHistory) {
        self.orcaDBConnectionHistory = [NSMutableArray array];
    }
}

- (void) initDebugDBConnectionHistory
{
    self.debugDBIPNumberIndex = [[NSUserDefaults standardUserDefaults] integerForKey: [NSString stringWithFormat:@"orca.%@.debugDBIPNumberIndex",[self className]]];

    if (!self.debugDBConnectionHistory) {
        NSArray *his = [[NSUserDefaults standardUserDefaults] objectForKey:
                [NSString stringWithFormat:@"orca.%@.debugDBConnectionHistory",[self className]]];
        
        self.debugDBConnectionHistory = [[his mutableCopy] autorelease];
    }

    if (!self.debugDBConnectionHistory) {
        self.debugDBConnectionHistory = [NSMutableArray array];
    }
}

#pragma mark ¥¥¥Notifications
- (void) registerNotificationObservers
{
    [super registerNotificationObservers];
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    
    [notifyCenter addObserver : self
                     selector : @selector(runInitialization:)
                         name : ORRunInitializationNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runAboutToRollOver:)
                         name : ORRunIsAboutToRollOver
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStart:)
                         name : ORRunSecondChanceForWait
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runStarted:)
                         name : ORRunStartedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runAboutToStop:)
                         name : ORRunAboutToStopNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(runStopped:)
                         name : ORRunStoppedNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(subRunStarted:)
                         name : ORRunStartSubRunNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(subRunEnded:)
                         name : ORRunBetweenSubRunsNotification
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(detectorStateChanged:)
                         name : ORPQDetectorStateChanged
                       object : nil];

    [notifyCenter addObserver : self
                     selector : @selector(saveLogFiles:)
                         name : OROrcaAboutToQuitNotice
                       object : nil];
}

- (void) runAboutToRollOver:(NSNotification*)aNote
{
    /* When the next run is going to be started due to a rollover, this method
     * is called.
     *
     * Note that the rolloverRun variable is reset to NO after the next run
     * start. */
    rolloverRun = YES;
}

- (void) runInitialization:(NSNotification*)aNote
{
    /* Called at the start of a run before the run actually starts. Here
     * we initialize the hardware before the run starts. */
    NSArray* objs;
    ORMTCModel *mtc;
    SNOCaenModel *caen;
    ORXL3Model *xl3;
    TUBiiModel *tubii;
    int i;

    [defaultRunAlarm clearAlarm];

    objs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];

    if ([objs count]) {
        mtc = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        goto err;
    }

    objs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"SNOCaenModel")];

    if ([objs count]) {
        caen = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find SNO CAEN model. Please add it to the experiment and restart the run.\n");
        goto err;
    }

    objs = [[(ORAppDelegate*)[NSApp delegate] document]
            collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    if ([objs count]) {
        tubii = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find TUBii model. Please add it to the experiment and restart the run.\n");
        return;
    }

    switch (state) {
    case STOPPED:
        start = COLD_START;
        break;
    case RUNNING:
        if (rolloverRun) {
            start = ROLLOVER_START;
            rolloverRun = NO;
        } else {
            start = CONTINUOUS_START;
        }
        break;
    default:
        start = COLD_START;
    }

    state = STARTING;

    switch (start) {
    case ROLLOVER_START:
        /* We don't queue the run start here for rollover runs. Since we don't
         * send a queue_run_start command to the mtc server, the first gtid and
         * the valid gtid fields in the run header will be the same. */
        break;
    case CONTINUOUS_START:
        @try {
            /* Tell the MTC server to queue the run start. This will suspend
             * the MTC readout and fire a SOFT_GT. When the run starts, we will
             * resume the MTC readout */
            [mtc_server okCommand:"queue_run_start"];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"error sending queue_run_start "
                       "command to mtc_server: %@\n", [e reason]);
            goto err;
        }

        /* Load the MTC settings from model to hardware. */
        if ([mtc initAtRunStart:1]) {
            NSLogColor([NSColor redColor], @"error initializing MTC.\n");
            goto err;
        }

        /* Load the TUBii settings to hardware. */
        if ([tubii sendCurrentModelStateToHW]) {
            NSLogColor([NSColor redColor], @"error initializing TUBii.\n");
        }

        /* Load the XL3 hardware. */
        objs = [[(ORAppDelegate*)[NSApp delegate] document]
             collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];

        for (i = 0; i < [objs count]; i++) {
            xl3 = [objs objectAtIndex:i];

            if ([gOrcaGlobals runType] & kPhysicsRun) {
                /* If we're in a physics run, we zero the pedestal masks before
                 * the run starts. This is because it was noticed that the
                 * number of channels in the pedestal mask seems to affect the
                 * noise on the trigger signals. See
                 * http://snopl.us/shift/view/9e1ff17e58704756a99f947ec2509f39?index_start=15. */
                [xl3 zeroPedestalMasksAtRunStart];
            }
        }

        break;
    default:
        /* Turn off triggers */
        @try {
            [mtc_server okCommand:"set_gt_mask 0"];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"error sending set_gt_mask command "
                       "to mtc_server: %@\n", [e reason]);
            goto err;
        }

        @try {
            [mtc_server okCommand:"reset_gtid"];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"error sending reset_gtid command "
                       "to mtc_server: %@\n", [e reason]);
            goto err;
        }

        /* Load the CAEN settings to hardware. */
        if ([caen initAtRunStart]) {
            NSLogColor([NSColor redColor], @"error initializing CAEN.\n");
            goto err;
        }

        /* Load the TUBii settings to hardware. */
        if ([tubii sendCurrentModelStateToHW]) {
            NSLogColor([NSColor redColor], @"error initializing TUBii.\n");
        }

        /* Load the MTC hardware. */
        if ([mtc initAtRunStart:0]) {
            NSLogColor([NSColor redColor], @"error initializing MTC.\n");
            goto err;
        }

        /* Load the XL3 hardware. */
        objs = [[(ORAppDelegate*)[NSApp delegate] document]
             collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];

        for (i = 0; i < [objs count]; i++) {
            xl3 = [objs objectAtIndex:i];

            if ([xl3 initAtRunStart]) {
                NSLogColor([NSColor redColor], @"error initializing XL3 %i.\n", [xl3 crateNumber]);
                goto err;
            }

            if ([gOrcaGlobals runType] & kPhysicsRun) {
                /* If we're in a physics run, we zero the pedestal masks before
                 * the run starts. This is because it was noticed that the
                 * number of channels in the pedestal mask seems to affect the
                 * noise on the trigger signals. See
                 * http://snopl.us/shift/view/9e1ff17e58704756a99f947ec2509f39?index_start=15. */
                [xl3 zeroPedestalMasksAtRunStart];
            }
        }

        break;
    }

    if ([ORPQModel getCurrent]) {
        /* Wait to start the run until we get the next run number from the
         * database. */
        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"querying database for run number",
                                  @"Reason",
                                  nil];

        /* Tell the run control to wait. */
        [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object: self userInfo: userInfo];

        [[ORPQModel getCurrent] dbQuery:@"SELECT nextval('run_number')"
             object:self selector:@selector(waitForRunNumber:) timeout:1.0];
    } else {
        /* If there is no database object, just continue with the existing run
         * number saved to Orca. */
        NSLogColor([NSColor redColor], @"Unable to find ORCA PostgreSQL model. Please add it to the experiment. Aborting run start.\n");

        goto err;
    }

    return;

err:
{
    /* Need to abort the run start here, because uncaught exceptions are not
     * handled by ORCA during this phase of run start */
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"", @"Reason",
                                @"", @"Details",
                                nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStartupAbort object: self userInfo: userInfo];

    state = STOPPED;
}
}

- (void) waitForRunNumber: (ORPQResult *) result
{
    NSInteger numRows, numCols, run_number;

    if (!result) {
        NSLogColor([NSColor redColor], @"Error getting the run number from the database. Using default run number. Data is going in the bit bucket.\n");
        goto err;
    }

    numRows = [result numOfRows];
    numCols = [result numOfFields];

    if (numRows != 1) {
        NSLogColor([NSColor redColor], @"Error getting run number from database: got %i rows but expected 1. Using default run number. Data is going in the bit bucket.", numRows);
        goto err;
    }

    if (numCols != 1) {
        NSLogColor([NSColor redColor], @"Error getting run number from database: got %i columns but expected 1. Using default run number. Data is going in the bit bucket.", numCols);
        goto err;
    }

    run_number = [result getInt64atRow:0 column:0];

    NSArray*  runObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runObjects count]){
        NSLogColor([NSColor redColor], @"waitForRunNumber: couldn't find run control object!");
        [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object: self];
        /* This should never happen. */
        return;
    }

    ORRunModel* runControl = [runObjects objectAtIndex:0];

    /* We set the run to the next run number - 1 because the run control will
     * increment the run number before the run starts. */
    [runControl setRunNumber:(uint32_t)run_number-1];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object: self];

    return;

err:
{
    NSArray*  runObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];

    if(![runObjects count]){
        NSLogColor([NSColor redColor], @"waitForRunNumber: couldn't find run control object!");
        [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object: self];
        /* This should never happen. */
        return;
    }

    ORRunModel* runControl = [runObjects objectAtIndex:0];

    [runControl setRunNumber:0xffffffff - 1];

    /* Post an Orca alarm indicating that the default run number is being used. */
    if (!defaultRunAlarm) {
        defaultRunAlarm = [[ORAlarm alloc] initWithName:[NSString stringWithFormat:@"Using default run number"]
                                               severity:kImportantAlarm];
        [defaultRunAlarm setAdditionalInfoString:@"Correct this immediately, as data may be lost."];
        [defaultRunAlarm setSticky:YES];
    }
    [defaultRunAlarm setAcknowledged:NO];
    [defaultRunAlarm postAlarm];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORReleaseRunStateChangeWait object: self];

    return;
}
}

- (void) runAboutToStart:(NSNotification*)aNote
{
    NSArray* objs;
    ORMTCModel *mtc;

    objs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];

    if ([objs count]) {
        mtc = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        goto err;
    }

    switch (start) {
    case COLD_START:
        @try {
            /* Tell the MTC server to queue the run start. This will suspend
             * the MTC readout and fire a SOFT_GT. When the run starts, we will
             * resume the MTC readout */
            [mtc_server okCommand:"queue_run_start"];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"error sending queue_run_start "
                       "command to mtc_server: %@\n", [e reason]);
            goto err;
        }

        /* Load the GT mask. */
        if ([mtc initAtRunStart:1]) {
            NSLogColor([NSColor redColor], @"error initializing MTC.\n");
            goto err;
        }

        break;
    default:
        break;
    }

    return;

err:
{
    /* Need to abort the run start here, because uncaught exceptions are not
     * handled by ORCA during this phase of run start */
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"", @"Reason",
                                @"", @"Details",
                                nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStartupAbort object: self userInfo: userInfo];

    state = STOPPED;
}
}

- (void) runStarted:(NSNotification*)aNote
{
    ORRunModel *run = [aNote object];

    uint32_t run_type = [run runType];
    uint32_t run_number = [run runNumber];
    uint32_t source_mask = 0; /* needs to come from the MANIP system */

    @try {
        /* send the run_start command to the MTC server which will send the
         * run header record to the builder, resume the MTC readout, fire a
         * SOFT_GT, and send a trigger record to the builder */
        [mtc_server okCommand:"run_start %d %d %d", run_number, run_type, source_mask];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor], @"error sending run_start "
                   "command to mtc_server: %@\n", [e reason]);
        goto err;
    }

    state = RUNNING;
    if (start != ROLLOVER_START) {
        [self setLastStandardRunType:[self standardRunType]];
        [self setLastStandardRunVersion:[self standardRunVersion]];
        [self setLastRunTypeWord:run_type];
        NSString* _lastRunTypeWord = [NSString stringWithFormat:@"0x%X",(int)run_type];
        [self setLastRunTypeWordHex:_lastRunTypeWord]; //FIXME: revisit if we go over 32 bits
    }

    if(run_type & (kECAPedestalRun | kECATSlopeRun)){
        /* Launch the ECA routine if this is an ECA run, as in
         * the PDST or TSLP bits are enabled */
        [[self anECARun] launchECAThread:NULL];
    }
    else {

        if (run_type & kPhysicsRun) {
        /* If this is a physics run with no ECAs nor embedded pedestals, we 
         * ping each slot in the detector once at the beginning of the run 
         * to look for any trigger issues. */
        [self pingCratesAtRunStart];
        }
        
        if(run_type & (kEmbeddedPeds)){
            /* Launch the Live Pedestals routine if the corresponding
             * bit is ticked in the run type word. */
            [[self livePeds] launchLivePedsThread];
        }

    }

    return;

err:
{
    /* Need to abort the run start here, because uncaught exceptions are not
     * handled by ORCA during this phase of run start */
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                @"", @"Reason",
                                @"", @"Details",
                                nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRequestRunHalt object: self userInfo: userInfo];

    state = RUNNING;
}
}

- (void) runAboutToStop:(NSNotification*)aNote
{
    /* If this is a hard stop, we send run_stop to the MTC server which
     * will fire a SOFT_GT and turn triggers off. Then we need to wait
     * until the MTC/CAEN/XL3s have read out all the data. */

    // Stop the ECA thread
    /* This will send a cancel signal to the ECAThread which will exit at the
     * end of the current ECA step. This makes the run wait until the ECAThread
     * is stopped */
    if ([anECARun isExecuting] && ![anECARun isFinishing]) {
        [anECARun stop];
    }

    NSDictionary *userInfo = [aNote userInfo];

    if (![[userInfo objectForKey:@"willRestart"] boolValue] || resync) {
        state = STOPPING;
        resync = NO;
    }

    switch (state) {
    case STOPPING:
        @try {
            [mtc_server okCommand:"run_stop"];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"error sending run_stop "
                       "command to mtc_server: %@\n", [e reason]);
            goto err;
        }

        @try {
            [mtc_server okCommand:"disable_pulser"];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"error sending disable_pulser "
                       "command to mtc_server: %@\n", [e reason]);
            goto err;
        }

        NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"waiting for MTC/XL3/CAEN data", @"Reason",
                                  nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORAddRunStateChangeWait object: self userInfo: userInfo];

        waitingForBuffers = true;
        /* detach a thread to monitor XL3/CAEN/MTC buffers */
        [NSThread detachNewThreadSelector:@selector(_waitForBuffers)
                                 toTarget:self
                               withObject:nil];
        // post a modal dialog after 10 secs if the buffers haven't cleared yet
        [self performSelector:@selector(stillWaitingForBuffers) withObject:nil afterDelay:10];
        break;
    default:
        break;
    }

    return;

err:
    state = RUNNING;
}

- (void) stillWaitingForBuffers
{
    /* We're stopping a run but our buffers are taking a while to clear, so
     * send a notification to allow our controller to throw up a "force stop" dialog */
    if (waitingForBuffers) {
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORSNOPStillWaitingForBuffersNotification object:self];
    }
}

- (void) abortWaitingForBuffers
{
    /* Give up on waiting for our buffers to clear at the end of a run */
    waitingForBuffers = false;
}

- (void) _waitForBuffers
{
    /* Since we are running in a separate thread, we just open a new
     * connection to the MTC and XL3 servers. */
    @autoreleasepool {
        RedisClient *mtc = [[RedisClient alloc] initWithHostName:mtcHost withPort:mtcPort];
        RedisClient *xl3 = [[RedisClient alloc] initWithHostName:xl3Host withPort:xl3Port];

        while (waitingForBuffers) {
            @try {
                if (([mtc intCommand:"data_available"] == 0) &&
                    ([xl3 intCommand:"data_available"] == 0))
                    break;
            } @catch (NSException *e) {
                NSLog(@"Failed to check MTC/XL3 data buffers. Quitting run...\n");
                break;
            }
        }

        [mtc release];
        [xl3 release];
        waitingForBuffers = false;
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORSNOPNotWaitingForBuffersNotification object:self];

        /* Go ahead and end the run. */
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORReleaseRunStateChangeWait object: self];
    }
}

- (void) runStopped:(NSNotification*)aNote
{
    /* By this point, the MTC/CAEN/XL3s should be read out, so if this is
     * a hard run stop, we send the MTC server the builder_end_run command
     * which will tell the builder to flush all events */

    switch (state) {
    case STOPPING:
        @try {
            [mtc_server okCommand:"builder_end_run"];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"error sending builder_end_run "
                       "command to mtc_server: %@\n", [e reason]);
        }

        state = STOPPED;
        break;
    }

}

- (void) subRunStarted:(NSNotification*)aNote
{
    //Ship subrunrecord - A special case of an eped record
    [self shipSubRunRecord];
}

- (void) subRunEnded:(NSNotification*)aNote
{
}

- (void) detectorStateChanged:(NSNotification*)aNote
{
    ORPQDetectorDB *detDB = [aNote object];

    if (!detDB) return;

    PQ_Run *pqRun = [detDB getRun];

    if (!pqRun) return;

    NSArray *runObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if(![runObjects count]){
        NSLogColor([NSColor redColor], @"detectorStateChanged: couldn't find run control object!");
        return;     // (should never happen)
    }
    ORRunModel* runControl = [runObjects objectAtIndex:0];

    // update current run number
    if (pqRun->valid[kRun_runNumber]) {
        [runControl setRunNumber:pqRun->runNumber];
    }
    // update run type
    if (pqRun->valid[kRun_runType]) {
        [runControl setRunType:pqRun->runType];
    }

    // update run state and run start time
    if (pqRun->valid[kRun_runInProgress] && pqRun->runInProgress && [runControl runningState] == eRunStopped) {
        [runControl setRunningState:eRunInProgress];
        if (pqRun->valid[kRun_runStartTime]) {
            [runControl setStartTime:pqRun->runStartTime];
            [runControl setElapsedRunTime:-[pqRun->runStartTime timeIntervalSinceNow]];
            [runControl startTimer];
        }
        state = RUNNING;
    }

    // Get data file object to check if there's an active datafile.
    NSArray *dataFileModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORDataFileModel")];
    if (![dataFileModels count]) {
        NSLogColor([NSColor redColor], @"SetLogNameFormat: can't find ORDataFileModel!\n");
        return; // (should never happen)
    }
    ORDataFileModel* aDataFileModel = [dataFileModels objectAtIndex:0];

    // Check if the datafile name is defined. If ORCA has just started up, it won't be.
    // By setting here all file IO will be available for the current run. Otherwise
    // initialisation would only happen at the next run boundry.
    if([[aDataFileModel fileName] isEqualToString:@""]){
        NSLog(@"SNOPModel: There was no datafile name! Probably due to opening new ORCA. Correcting this now.\n");
        [self setLogNameFormat]; // this should have already been called by awakeAfterDocumentLoaded, but do it here too for piece of mind
        [aDataFileModel runTaskStarted:[runControl runInfo]];
    }
}

- (void) enableGlobalSecurity
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:OROrcaSecurityEnabled];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGlobalSecurityStateChanged object:self userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:OROrcaSecurityEnabled]];
}

// orca script helper (will come from DB)
- (void) updateEPEDStructWithCoarseDelay: (uint32_t) coarseDelay
                               fineDelay: (uint32_t) fineDelay
                          chargePulseAmp: (uint32_t) chargePulseAmp
                           pedestalWidth: (uint32_t) pedestalWidth
                                 calType: (uint32_t) calType
{
    _epedStruct.coarseDelay = coarseDelay; // nsec
    _epedStruct.fineDelay = fineDelay; // psec
    _epedStruct.chargePulseAmp = chargePulseAmp; // clicks
    _epedStruct.pedestalWidth = pedestalWidth; // nsec
    _epedStruct.calType = calType; // ECA_Type * 10 + ECA_Pattern
}

- (void) updateEPEDStructWithStepNumber: (uint32_t) stepNumber
{
    _epedStruct.stepNumber = stepNumber;
}

- (void) updateEPEDStructWithNSlopePoint: (uint32_t) nTSlopePoints
{
    _epedStruct.nTSlopePoints = nTSlopePoints;
}

- (void) shipSubRunRecord
{
    /* Sends a command to the MTC server to ship an 'EPED' record to the data
     * stream server, which will eventually get to the builder. The feature that 
     * distinguishs between the subRunRecord and the eped record is the 
     * inclusion of the subrun flag, defined in rat's zdab_convert.cc as:
     * 
     *     #define EPED_FLAG_SUBRUN 0x01000000
     *
     * All fields associated with EPED settings are set to zero, with the exception
     * of the half crate id, which is repurposed to hold the 
     * [runControl subRunNumber]. The mtc server adds a GTID value to the record
     * before piping it down to the builder.
     *
     */
    //get the run controller
    NSArray*  runObjects = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if([runObjects count]){
        ORRunModel* runControl = [runObjects objectAtIndex:0];
        if ([[ORGlobal sharedGlobal] runInProgress]) {
            @try {
                [mtc_server okCommand:"send_eped_record %d %d %d %d %d %d %d",
                 0,
                 0,
                 0,
                 0,
                 [runControl subRunNumber], /* In place of half crate id */
                 0,
                 0x01000000 /* subRun flag */
                 ];
            } @catch (NSException *e) {
                NSLogColor([NSColor redColor], @"failed to send EPED record: %@ \n",
                           [e reason]);
            }
        }
    }
}

- (void) shipEPEDStructWithCoarseDelay: (uint32_t) coarseDelay
                             fineDelay: (uint32_t) fineDelay
                        chargePulseAmp: (uint32_t) chargePulseAmp
                         pedestalWidth: (uint32_t) pedestalWidth
                               calType: (uint32_t) calType
                            stepNumber: (uint32_t) stepNumber
{
    if ([[ORGlobal sharedGlobal] runInProgress]) {
        @try {
            [mtc_server okCommand:"send_eped_record %d %d %d %d %d %d %d",
                pedestalWidth,
                coarseDelay,
                fineDelay,
                chargePulseAmp, /* qinj_dacsetting */
                stepNumber, /* half crate id? */
                calType,
                0 /* flags */
            ];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"failed to send EPED record: %@ \n",
                       [e reason]);
        }
    }
}

- (void) shipEPEDRecord
{
    /* Sends a command to the MTC server to ship an EPED record to the data
     * stream server, which will eventually get to the builder.
     *
     * Note: Currently, this function does not send EPED records to mark
     * subrun boundaries. To accomplish this, one would need to mask in
     * the EPED_FLAG_SUBRUN bit in the flags bitmask, where EPED_FLAG_SUBRUN
     * is defined in the builder's RecordInfo.h as:
     *
     *     #define EPED_FLAG_SUBRUN 0x1000000
     *
     */
    if ([[ORGlobal sharedGlobal] runInProgress]) {
        @try {
            [mtc_server okCommand:"send_eped_record %d %d %d %d %d %d %d",
                _epedStruct.pedestalWidth,
                _epedStruct.coarseDelay,
                _epedStruct.fineDelay,
                _epedStruct.chargePulseAmp, /* qinj_dacsetting */
                _epedStruct.stepNumber, /* half crate id? */
                _epedStruct.calType,
                0 /* flags */
            ];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor], @"failed to send EPED record: %@ \n",
                       [e reason]);
        }
    }
}

static NSComparisonResult compareXL3s(ORXL3Model *xl3_1, ORXL3Model *xl3_2, void *context)
{
    if ([xl3_1 crateNumber] < [xl3_2 crateNumber]) {
        return NSOrderedAscending;
    } else if ([xl3_1 crateNumber] > [xl3_2 crateNumber]) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (NSLock *) ecaLock
{
    return ecaLock;
}

- (void) pingCratesAtRunStart
{
    [NSThread detachNewThreadSelector:@selector(_pingCratesAtRunStart)
                             toTarget:self
                           withObject:nil];
}

- (void) _pingCratesAtRunStart
{
    @autoreleasepool {
        /* Try to acquire the lock for 10 seconds. If we can't get it then we
         * just skip the ping crates. */
        if ([ecaLock lockBeforeDate:[NSDate dateWithTimeIntervalSinceNow:10.0]]) {
            @try {
                [self __pingCratesAtRunStart];
            } @finally {
                /* Make sure to unlock the lock when we're done. */
                [ecaLock unlock];
            }
        } else {
            NSLogColor([NSColor redColor],
                       @"pingCratesAtRunStart: unable to acquire eca lock!\n");
        }
    }
}

- (void) __pingCratesAtRunStart
{
    /* Fire pedestals on each slot in the detector. This function is called at
     * the start of physics runs. A nearline job will eventually look at these
     * events to determine if any slots are not firing triggers correctly.
     * This function should only be called in a separate thread. */
    int i, j, k;
    uint32_t crate_pedestal_mask, coarse_delay, fine_delay, pedestal_width, gt_mask;
    float pulser_rate;
    uint32_t channelMasks[16];

    NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    NSArray* mtcs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];

    xl3s = [xl3s sortedArrayUsingFunction:compareXL3s context:nil];

    ORMTCModel* mtc;
    ORXL3Model* xl3;

    if ([mtcs count] == 0) {
        NSLogColor([NSColor redColor],
                   @"pingCratesAtRunStart: couldn't find MTC object.\n");
        return;
    }

    mtc = [mtcs objectAtIndex:0];

    crate_pedestal_mask = [mtc pedCrateMask];
    coarse_delay = [mtc coarseDelay];
    fine_delay = [mtc fineDelay];
    pedestal_width = [mtc pedestalWidth];
    gt_mask = [mtc gtMask];

    pulser_rate = [mtc pgtRate];

    /* Set the coarse delay. */
    [mtc setCoarseDelay:250];
    @try {
        [mtc loadCoarseDelayToHardware];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor],
                   @"pingCratesAtRunStart: error setting the MTCD coarse delay. error: "
                    "%@ reason: %@\n", [e name], [e reason]);
        return;
    }

    /* Set the fine delay. */
    [mtc setFineDelay:0];
    @try {
        [mtc loadFineDelayToHardware];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor],
                   @"pingCratesAtRunStart: error setting the MTCD fine delay. error: "
                    "%@ reason: %@\n", [e name], [e reason]);
        return;
    }

    /* Reset the pedestal width. */
    [mtc setPedestalWidth:50];
    @try {
        [mtc loadPedWidthToHardware];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor],
                   @"pingCratesAtRunStart: error setting the MTCD pedestal width. error: "
                    "%@ reason: %@\n", [e name], [e reason]);
        return;
    }

    /* Enable all pedestals for each crate, and then fire a single pedestal
     * pulse. */
    for (i = 0; i < [xl3s count]; i++) {
        xl3 = [xl3s objectAtIndex:i];

        /* Enable all crates in the MTCD pedestal mask. */
        [mtc setPedCrateMask:1 << [xl3 crateNumber]];

        @try {
            [mtc loadPedestalCrateMaskToHardware];
        } @catch (NSException *e) {
            NSLogColor([NSColor redColor],
                       @"pingCratesAtRunStart: error setting the MTCD crate pedestal mask. error: "
                        "%@ reason: %@\n", [e name], [e reason]);
            continue;
        }

        if (![[xl3 xl3Link] isConnected]) continue;

        for (j = 0; j < 16; j++) {
            if (!([xl3 getSlotsPresent] & (1 << j))) continue;

            for (k = 0; k < 16; k++) {
                if (k == j) {
                    /* For the slot we are testing, set the pedestal mask to
                     * 0xffffffff. */
                    channelMasks[k] = 0xffffffff;
                } else {
                    /* For all other slots, pedestal channels 17 and 18 to make
                     * sure we don't get any pedestal pickup. */
                    channelMasks[k] = 0x60000;
                }
            }

            if ([xl3 multiSetPedestalMask:[xl3 getSlotsPresent]
                     patterns:channelMasks]) {
                NSLogColor([NSColor redColor], @"pingCratesAtRunStart: failed to set pedestal mask "
                            "for crate %02d slot %02d\n", i, j);
                continue;
            }

            /* The crate and slot are encoded in the step number or
             * half_crate_id field. For example, to unpack the crate and
             * slot:
             *
             *     crate = (eped_record.half_crate_id >> 4) & 0xff;
             *     slot = eped_record.half_crate_id & 0xf;
             */
            [self shipEPEDStructWithCoarseDelay: [mtc coarseDelay]
                                      fineDelay: [mtc fineDelay]
                                 chargePulseAmp: 0
                                  pedestalWidth: [mtc pedestalWidth]
                                        calType: 50
                                     stepNumber: ((i << 4) | j)];

            @try {
                [mtc firePedestals:1 withRate:1];
            } @catch (NSException *e) {
                NSLogColor([NSColor redColor],
                           @"pingCratesAtRunStart: failed to fire pedestal. error: %@ reason: %@\n",
                           [e name], [e reason]);
            }
        }
    }

    /* Send an EPED record with calType set to zero to let the nearline job
     * know that we are done. */
    [self shipEPEDStructWithCoarseDelay: [mtc coarseDelay]
                              fineDelay: [mtc fineDelay]
                         chargePulseAmp: 0
                          pedestalWidth: [mtc pedestalWidth]
                                calType: 0
                             stepNumber: 0xffffffff];

    /* Set the pedestal mask for each crate back. */
    for (i = 0; i < [xl3s count]; i++) {
        xl3 = [xl3s objectAtIndex:i];

        if ([[xl3 xl3Link] isConnected]) {
            [xl3 setPedestals];
        }
    }

    /* Reset the crate pedestal all crates in the MTCD pedestal mask. */
    [mtc setPedCrateMask:crate_pedestal_mask];
    @try {
        [mtc loadPedestalCrateMaskToHardware];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor],
                   @"pingCratesAtRunStart: error setting the MTCD crate pedestal mask. error: "
                    "%@ reason: %@\n", [e name], [e reason]);
    }

    /* Reset the coarse delay. */
    [mtc setCoarseDelay:coarse_delay];
    @try {
        [mtc loadCoarseDelayToHardware];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor],
                   @"pingCratesAtRunStart: error setting the MTCD coarse delay. error: "
                    "%@ reason: %@\n", [e name], [e reason]);
    }

    /* Reset the fine delay. */
    [mtc setFineDelay:fine_delay];
    @try {
        [mtc loadFineDelayToHardware];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor],
                   @"pingCratesAtRunStart: error setting the MTCD fine delay. error: "
                    "%@ reason: %@\n", [e name], [e reason]);
    }

    /* Reset the pedestal width. */
    [mtc setPedestalWidth:pedestal_width];
    @try {
        [mtc loadPedWidthToHardware];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor],
                   @"pingCratesAtRunStart: error setting the MTCD pedestal width. error: "
                    "%@ reason: %@\n", [e name], [e reason]);
    }

    /* Reset the pulser rate since the firePedestals function sets the pulser
     * rate to 0. */
    @try {
        [mtc setPgtRate:pulser_rate];
        [mtc loadPulserRateToHardware];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor],
                   @"pingCratesAtRunStart: error setting the pulser rate. error: "
                    "%@ reason: %@\n", [e name], [e reason]);
    }
}

- (void) pingCrates
{
    /* Enables pedestals for all channels in each crate one at a time and sends
     * a pedestal pulse. This is useful to check that triggers are enabled for
     * crates that are at high voltage. */
    int i;
    uint32_t crate_pedestal_mask;
    float pulser_rate;

    NSArray* xl3s = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORXL3Model")];
    NSArray* mtcs = [[(ORAppDelegate*)[NSApp delegate] document]
         collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];

    xl3s = [xl3s sortedArrayUsingFunction:compareXL3s context:nil];

    ORMTCModel* mtc;
    ORXL3Model* xl3;

    if ([mtcs count] == 0) {
        NSLogColor([NSColor redColor], @"pingCrates: couldn't find MTC object.\n");
        return;
    }

    mtc = [mtcs objectAtIndex:0];

    crate_pedestal_mask = [mtc pedCrateMask];

    pulser_rate = [mtc pgtRate];

    /* Enable all crates in the MTCD pedestal mask. */
    [mtc setPedCrateMask:0xffffff];

    @try {
        [mtc loadPedestalCrateMaskToHardware];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor],
                   @"pingCrates: error setting the MTCD crate pedestal mask. error: "
                    "%@ reason: %@\n", [e name], [e reason]);
        return;
    }

    /* Set all the pedestal masks to 0. */
    for (i = 0; i < [xl3s count]; i++) {
        xl3 = [xl3s objectAtIndex:i];

        if ([[xl3 xl3Link] isConnected]) {
            if ([xl3 setPedestalMask:[xl3 getSlotsPresent] pattern:0]) {
                NSLogColor([NSColor redColor],
                           @"pingCrates: failed to set pedestal mask for crate %02d\n", i);
                continue;
            }
        }
    }

    /* Enable all pedestals for each crate, and then fire a single pedestal
     * pulse. */
    for (i = 0; i < [xl3s count]; i++) {
        xl3 = [xl3s objectAtIndex:i];

        if ([[xl3 xl3Link] isConnected]) {
            if ([xl3 setPedestalMask:[xl3 getSlotsPresent]
                 pattern:0xffffffff]) {
                NSLogColor([NSColor redColor],
                           @"pingCrates: failed to set pedestal mask for crate %02d\n", i);
                continue;
            }

            @try {
                [mtc firePedestals:1 withRate:1];
            } @catch (NSException *e) {
                NSLogColor([NSColor redColor],
                           @"pingCrates: failed to fire pedestal. error: %@ reason: %@\n",
                           [e name], [e reason]);
            }

            /* Set pedestal mask back to 0. */
            if ([xl3 setPedestalMask:[xl3 getSlotsPresent] pattern:0]) {
                NSLogColor([NSColor redColor],
                           @"pingCrates: failed to set pedestal mask for crate %02d\n", i);
                continue;
            }

            NSLog(@"PING crate %02d\n", i);
        }
    }

    /* Set the pedestal mask for each crate back. */
    for (i = 0; i < [xl3s count]; i++) {
        xl3 = [xl3s objectAtIndex:i];

        if ([[xl3 xl3Link] isConnected]) {
            [xl3 setPedestals];
        }
    }

    /* Reset the crate pedestal all crates in the MTCD pedestal mask. */
    [mtc setPedCrateMask:crate_pedestal_mask];
    @try {
        [mtc loadPedestalCrateMaskToHardware];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor],
                   @"pingCrates: error setting the MTCD crate pedestal mask. error: "
                    "%@ reason: %@\n", [e name], [e reason]);
    }

    /* Reset the pulser rate since the firePedestals function sets the pulser
     * rate to 0. */
    @try {
        [mtc setPgtRate:pulser_rate];
        [mtc loadPulserRateToHardware];
    } @catch (NSException *e) {
        NSLogColor([NSColor redColor],
                   @"pingCrates: error setting the pulser rate. error: "
                    "%@ reason: %@\n", [e name], [e reason]);
    }
}

- (void) runNhitMonitor
{
    [nhitMonitor start:[self nhitMonitorCrate]
                 pulserRate:[self nhitMonitorPulserRate]
                 numPulses:[self nhitMonitorNumPulses]
                 maxNhit:[self nhitMonitorMaxNhit]];
}

- (void) runNhitMonitorAutomatically
{
    /* Run the nhit monitor, but first check to see if we are in a specific
     * run. */
    static int last_crate = -1;
    int i, crate = -1;

    if ([gOrcaGlobals runInProgress]) {
        if ([gOrcaGlobals runType] & nhitMonitorRunType) {
            /* Run the nhit monitor on the next crate in the crate mask. */
            if (last_crate == -1) {
                /* This is the first time we've run, so just find the first
                 * crate. */
                for (i = 0; i < 20; i++) {
                    if ([self nhitMonitorCrateMask] & (1L << i)) {
                        crate = i;
                        break;
                    }
                }
            } else {
                for (i = 1; i <= 20; i++) {
                    if ([self nhitMonitorCrateMask] & \
                        (1L << ((last_crate + i) % 20))) {
                        crate = (last_crate + i) % 20;
                        break;
                    }
                }
            }
            if (crate == -1) {
                /* Nothing is checked. */
                NSLog(@"nhit monitor is set to run automatically, "
                      "but no crates are checked.\n");
                return;
            }
            [nhitMonitor start:crate
                         pulserRate:[self nhitMonitorAutoPulserRate]
                         numPulses:[self nhitMonitorAutoNumPulses]
                         maxNhit:[self nhitMonitorAutoMaxNhit]];
            last_crate = crate;
        }
    }
}

- (void) stopNhitMonitor
{
    [nhitMonitor stop];
}

#pragma mark ¥¥¥Accessors

- (SessionDB *) sessionDB;
{
    return sessionDB;
}

- (NHitMonitor *) nhitMonitor
{
    return nhitMonitor;
}

- (int) nhitMonitorCrate
{
    return nhitMonitorCrate;
}

- (void) setNhitMonitorCrate: (int) crate
{
    nhitMonitorCrate = crate;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelNhitMonitorChangedNotification object:self];
}

- (int) nhitMonitorPulserRate
{
    return nhitMonitorPulserRate;
}

- (void) setNhitMonitorPulserRate: (int) pulserRate
{
    nhitMonitorPulserRate = pulserRate;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelNhitMonitorChangedNotification object:self];
}

- (int) nhitMonitorNumPulses
{
    return nhitMonitorNumPulses;
}

- (void) setNhitMonitorNumPulses: (int) numPulses
{
    nhitMonitorNumPulses = numPulses;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelNhitMonitorChangedNotification object:self];
}

- (int) nhitMonitorMaxNhit
{
    return nhitMonitorMaxNhit;
}

- (void) setNhitMonitorMaxNhit: (int) maxNhit
{
    nhitMonitorMaxNhit = maxNhit;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelNhitMonitorChangedNotification object:self];
}

- (int) nhitMonitorAutoRun
{
    return nhitMonitorAutoRun;
}

- (void) setNhitMonitorAutoRun: (BOOL) run
{
    nhitMonitorAutoRun = run;

    /* Stop any current timer. */
    if (nhitMonitorTimer) {
        [nhitMonitorTimer invalidate];
        nhitMonitorTimer = nil;
    }

    if (nhitMonitorAutoRun) {
        nhitMonitorTimer = [NSTimer scheduledTimerWithTimeInterval:nhitMonitorTimeInterval target:self selector:@selector(runNhitMonitorAutomatically) userInfo:nil repeats:YES];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelNhitMonitorChangedNotification object:self];
}

- (int) nhitMonitorAutoPulserRate
{
    return nhitMonitorAutoPulserRate;
}

- (void) setNhitMonitorAutoPulserRate: (int) pulserRate
{
    nhitMonitorAutoPulserRate = pulserRate;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelNhitMonitorChangedNotification object:self];
}

- (int) nhitMonitorAutoNumPulses
{
    return nhitMonitorAutoNumPulses;
}

- (void) setNhitMonitorAutoNumPulses: (int) numPulses
{
    nhitMonitorAutoNumPulses = numPulses;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelNhitMonitorChangedNotification object:self];
}

- (int) nhitMonitorAutoMaxNhit
{
    return nhitMonitorAutoMaxNhit;
}

- (void) setNhitMonitorAutoMaxNhit: (int) maxNhit
{
    nhitMonitorAutoMaxNhit = maxNhit;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelNhitMonitorChangedNotification object:self];
}

- (uint32_t) nhitMonitorRunType
{
    return nhitMonitorRunType;
}

- (void) setNhitMonitorRunType: (uint32_t) runType
{
    nhitMonitorRunType = runType;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelNhitMonitorChangedNotification object:self];
}

- (uint32_t) nhitMonitorCrateMask
{
    return nhitMonitorCrateMask;
}

- (void) setNhitMonitorCrateMask: (uint32_t) mask
{
    nhitMonitorCrateMask = mask;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelNhitMonitorChangedNotification object:self];
}

- (NSTimeInterval) nhitMonitorTimeInterval
{
    return nhitMonitorTimeInterval;
}

- (void) setNhitMonitorTimeInterval: (NSTimeInterval) interval
{
    nhitMonitorTimeInterval = interval;

    /* Stop any current timer. */
    if (nhitMonitorTimer) {
        [nhitMonitorTimer invalidate];
        nhitMonitorTimer = nil;
    }

    if (nhitMonitorAutoRun) {
        nhitMonitorTimer = [NSTimer scheduledTimerWithTimeInterval:nhitMonitorTimeInterval target:self selector:@selector(runNhitMonitorAutomatically) userInfo:nil repeats:YES];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelNhitMonitorChangedNotification object:self];
}

- (void) clearOrcaDBConnectionHistory
{
    self.orcaDBConnectionHistory = nil;
    [self setOrcaDBIPAddress:[self orcaDBIPAddress]];
}

- (void) clearDebugDBConnectionHistory
{
    self.debugDBConnectionHistory = nil;
    [self setDebugDBIPAddress:[self debugDBIPAddress]];
}

- (id) orcaDBConnectionHistoryItem:(unsigned int)index
{
    if (self.orcaDBConnectionHistory && index < [self.orcaDBConnectionHistory count]) {
        return [self.orcaDBConnectionHistory objectAtIndex:index];
    } else {
        return nil;
    }
}

- (id) debugDBConnectionHistoryItem:(unsigned int)index
{
    if (self.debugDBConnectionHistory && index < [self.debugDBConnectionHistory count]) {
        return [self.debugDBConnectionHistory objectAtIndex:index];
    } else {
        return nil;
    }
}

- (NSString*) orcaDBIPAddress
{
    if (!_orcaDBIPAddress) {
        return @"";
    }
    id result;
    result = [_orcaDBIPAddress retain];
    return [result autorelease];
}

- (void) setOrcaDBIPAddress:(NSString*)orcaIPAddress
{
    if ([orcaIPAddress length] && orcaIPAddress != self.orcaDBIPAddress) {
        [[[self undoManager] prepareWithInvocationTarget:self] setOrcaDBIPAddress:self.orcaDBIPAddress];

        if (self.orcaDBIPAddress) [_orcaDBIPAddress autorelease];
        if (orcaIPAddress) _orcaDBIPAddress = [orcaIPAddress copy];

        if (!self.orcaDBConnectionHistory) self.orcaDBConnectionHistory = [NSMutableArray arrayWithCapacity:4];
        if (![self.orcaDBConnectionHistory containsObject:self.orcaDBIPAddress]){
            [self.orcaDBConnectionHistory addObject:self.orcaDBIPAddress];
        }
        self.orcaDBIPNumberIndex = [self.orcaDBConnectionHistory indexOfObject:self.orcaDBIPAddress];

        [[NSUserDefaults standardUserDefaults] setObject:self.orcaDBConnectionHistory forKey:[NSString stringWithFormat:@"orca.%@.orcaDBConnectionHistory",[self className]]];
        [[NSUserDefaults standardUserDefaults] setInteger:self.orcaDBIPNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.orcaDBIPNumberIndex",[self className]]];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelOrcaDBIPAddressChanged object:self];
    }
}

- (NSString*) debugDBIPAddress
{
    if (!_debugDBIPAddress) {
        return @"";
    }
    id result;
    result = [_debugDBIPAddress retain];
    return [result autorelease];
}

- (void) setDebugDBIPAddress:(NSString*)debugIPAddress
{
    if ([debugIPAddress length] && debugIPAddress != self.debugDBIPAddress) {
        [[[self undoManager] prepareWithInvocationTarget:self] setDebugDBIPAddress:self.debugDBIPAddress];

        if (self.debugDBIPAddress) [_debugDBIPAddress autorelease];
        if (debugIPAddress) _debugDBIPAddress = [debugIPAddress copy];

        if (!self.debugDBConnectionHistory) self.debugDBConnectionHistory = [NSMutableArray arrayWithCapacity:4];
        if (![self.debugDBConnectionHistory containsObject:self.debugDBIPAddress]) {
            [self.debugDBConnectionHistory addObject:self.debugDBIPAddress];
        }
        self.debugDBIPNumberIndex = [self.debugDBConnectionHistory indexOfObject:self.debugDBIPAddress];

        [[NSUserDefaults standardUserDefaults] setObject:self.debugDBConnectionHistory forKey:[NSString stringWithFormat:@"orca.%@.debugDBConnectionHistory",[self className]]];
        [[NSUserDefaults standardUserDefaults] setInteger:self.debugDBIPNumberIndex forKey:[NSString stringWithFormat:@"orca.%@.debugDBIPNumberIndex",[self className]]];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelDebugDBIPAddressChanged object:self];
    }
}

- (void) orcaDBPing
{
    if (!self.orcaDBPingTask) {
        self.orcaDBPingTask = [ORPingTask pingTaskWithDelegate:self];
        
        self.orcaDBPingTask.launchPath      = @"/sbin/ping";
        self.orcaDBPingTask.arguments       = [NSArray arrayWithObjects:@"-c",@"2",@"-t",@"5",@"-q",self.orcaDBIPAddress,nil];
        
        self.orcaDBPingTask.verbose         = YES;
        self.orcaDBPingTask.textToDelegate  = YES;
        [self.orcaDBPingTask ping];
    }
}

- (void) debugDBPing
{
    if (!self.debugDBPingTask) {
        self.debugDBPingTask = [ORPingTask pingTaskWithDelegate:self];
        
        self.debugDBPingTask.launchPath     = @"/sbin/ping";
        self.debugDBPingTask.arguments      = [NSArray arrayWithObjects:@"-c",@"2",@"-t",@"5",@"-q",self.debugDBIPAddress,nil];
        
        self.debugDBPingTask.verbose        = YES;
        self.debugDBPingTask.textToDelegate = YES;
        [self.debugDBPingTask ping];
    }
}

- (void) taskFinished:(ORPingTask*)aTask
{
    if (aTask == self.orcaDBPingTask) {
        self.orcaDBPingTask = nil;
    } else if (aTask == self.debugDBPingTask) {
	self.debugDBPingTask = nil;
    }
}

- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp
{
    @synchronized(self) {
        if ([aResult isKindOfClass:[NSDictionary class]]) {
            NSString* message = [aResult objectForKey:@"Message"];
            if (message) {
                [aResult prettyPrint:@"CouchDB Message:"];
                return;
            } else if ([aTag isEqualToString:@"kSmellieRunHeaderRetrieved"]) {
                [self parseSmellieRunFileDocs:aResult];
            } else if ([aTag isEqualToString:@"kTellieRunHeaderRetrieved"]) {
                [self parseTellieRunFileDocs:aResult];
            }
            else if ([aTag isEqualToString:@"kAmellieRunHeaderRetrieved"])
            {
                [self parseAmellieRunFileDocs:aResult];
            }
            else if ([aTag isEqualToString:@"Message"]) {
                [aResult prettyPrint:@"CouchDB Message:"];
            } else if ([aTag isEqualToString:@"kStandardRunPosted"]) {
                /* Standard run was successfully posted. */
                NSLog(@"Standard Run saved.\n");
                [self refreshStandardRunsFromDB];
            } else {
                [aResult prettyPrint:@"CouchDB"];
            }
        } else if ([aResult isKindOfClass:[NSArray class]]) {
            /*
            if([aTag isEqualToString:kListDB]){
                [aResult prettyPrint:@"CouchDB List:"];
            else [aResult prettyPrint:@"CouchDB"];
             */
            [aResult prettyPrint:@"CouchDB"];
        } else {
            NSLog(@"%@\n",aResult);
        }
    } // synchronized
}

#pragma mark ¥¥¥Specific Dialog Lock Methods

- (NSString*) experimentMapLock
{
	return @"SNOPMapLock";
}

- (NSString*) experimentDetectorLock
{
	return @"SNOPDetectorLock";
}

- (NSString*) experimentDetailsLock
{
	return @"SNOPDetailsLock";
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];

    // Session Database
    [encoder encodeObject:[[self sessionDB] username] forKey:@"ORSNOPModelLockDBUserName"];
    [encoder encodeObject:[[self sessionDB] password] forKey:@"ORSNOPModelLockDBPassword"];
    [encoder encodeObject:[[self sessionDB] dbname] forKey:@"ORSNOPModelLockDBName"];
    [encoder encodeObject:[[self sessionDB] address] forKey:@"ORSNOPModelLockDBIPAddress"];
    [encoder encodeInteger:[[self sessionDB] port] forKey:@"ORSNOPModelLockDBPort"];
    [encoder encodeInteger:[[self sessionDB] lockID] forKey:@"ORSNOPModelLockDBLockID"];

    //CouchDB
    [encoder encodeObject:self.orcaDBUserName forKey:@"ORSNOPModelOrcaDBUserName"];
    [encoder encodeObject:self.orcaDBPassword forKey:@"ORSNOPModelOrcaDBPassword"];
    [encoder encodeObject:self.orcaDBName forKey:@"ORSNOPModelOrcaDBName"];
    [encoder encodeInteger:self.orcaDBPort forKey:@"ORSNOPModelOrcaDBPort"];
    [encoder encodeObject:self.orcaDBIPAddress forKey:@"ORSNOPModelOrcaDBIPAddress"];
    [encoder encodeObject:self.debugDBUserName forKey:@"ORSNOPModelDebugDBUserName"];
    [encoder encodeObject:self.debugDBPassword forKey:@"ORSNOPModelDebugDBPassword"];
    [encoder encodeObject:self.debugDBName forKey:@"ORSNOPModelDebugDBName"];
    [encoder encodeInteger:self.debugDBPort forKey:@"ORSNOPModelDebugDBPort"];
    [encoder encodeObject:self.debugDBIPAddress forKey:@"ORSNOPModelDebugDBIPAddress"];

    //Run status
    [encoder encodeObject:[self lastStandardRunType] forKey:@"SNOPlastStandardRunType"];
    [encoder encodeObject:[self lastStandardRunVersion] forKey:@"SNOPlastStandardRunVersion"];
    [encoder encodeObject:[self lastRunTypeWordHex] forKey:@"SNOPlastRunTypeWordHex"];
    [encoder encodeObject:[self standardRunType] forKey:@"SNOPStandardRunType"];
    [encoder encodeObject:[self standardRunVersion] forKey:@"SNOPStandardRunVersion"];

    //ECA
    [encoder encodeInteger:[anECARun ECA_pattern] forKey:@"SNOPECApattern"];
    [encoder encodeObject:[anECARun ECA_type] forKey:@"SNOPECAtype"];
    [encoder encodeInteger:[anECARun ECA_tslope_pattern] forKey:@"SNOPECAtslppattern"];
    [encoder encodeInteger:[anECARun ECA_nevents] forKey:@"SNOPECANEvents"];
    [encoder encodeObject:[anECARun ECA_rate] forKey:@"SNOPECAPulserRate"];

    //Settings
    [encoder encodeObject:[self mtcHost] forKey:@"mtcHost"];
    [encoder encodeInteger:[self mtcPort] forKey:@"mtcPort"];

    [encoder encodeObject:[self xl3Host] forKey:@"xl3Host"];
    [encoder encodeInteger:[self xl3Port] forKey:@"xl3Port"];

    [encoder encodeObject:[self dataHost] forKey:@"dataHost"];
    [encoder encodeInteger:[self dataPort] forKey:@"dataPort"];

    [encoder encodeObject:[self logHost] forKey:@"logHost"];
    [encoder encodeInteger:[self logPort] forKey:@"logPort"];

    /* Nhit Monitor Settings */
    [encoder encodeInteger:[self nhitMonitorCrate] forKey:@"nhitMonitorCrate"];
    [encoder encodeInteger:[self nhitMonitorPulserRate] forKey:@"nhitMonitorPulserRate"];
    [encoder encodeInteger:[self nhitMonitorNumPulses] forKey:@"nhitMonitorNumPulses"];
    [encoder encodeInteger:[self nhitMonitorMaxNhit] forKey:@"nhitMonitorMaxNhit"];
    [encoder encodeBool:[self nhitMonitorAutoRun] forKey:@"nhitMonitorAutoRun"];
    [encoder encodeInteger:[self nhitMonitorAutoPulserRate] forKey:@"nhitMonitorAutoPulserRate"];
    [encoder encodeInteger:[self nhitMonitorAutoNumPulses] forKey:@"nhitMonitorAutoNumPulses"];
    [encoder encodeInteger:[self nhitMonitorAutoMaxNhit] forKey:@"nhitMonitorAutoMaxNhit"];
    [encoder encodeInteger:[self nhitMonitorRunType] forKey:@"nhitMonitorRunType"];
    [encoder encodeInteger:[self nhitMonitorCrateMask] forKey:@"nhitMonitorCrateMask"];
    [encoder encodeDouble:[self nhitMonitorTimeInterval] forKey:@"nhitMonitorTimeInterval"];
}

#pragma mark ¥¥¥SnotDbDelegate

- (ORCouchDB*) orcaDbRef:(id)aCouchDelegate
{
    ORCouchDB* result = [ORCouchDB couchHost:self.orcaDBIPAddress
                                        port:self.orcaDBPort
                                    username:self.orcaDBUserName
                                         pwd:self.orcaDBPassword
                                    database:self.orcaDBName
                                    delegate:self];

    if (aCouchDelegate)
        [result setDelegate:aCouchDelegate];
    
    return [[result retain] autorelease];
}

- (ORCouchDB*) orcaDbRefWithEntryDB:(id)aCouchDelegate withDB:(NSString*)entryDB;
{
     ORCouchDB* result = [ORCouchDB couchHost:self.orcaDBIPAddress
                                         port:self.orcaDBPort
                                     username:self.orcaDBUserName
                                          pwd:self.orcaDBPassword
                                     database:entryDB
                                     delegate:self];
     
     if (aCouchDelegate)
         [result setDelegate:aCouchDelegate];
 
     return [[result retain] autorelease];
 }

- (ORCouchDB*) debugDBRef:(id) aCouchDelegate
{
    ORCouchDB* result = [ORCouchDB couchHost:self.debugDBIPAddress
                                        port:self.debugDBPort
                                    username:self.debugDBUserName
                                         pwd:self.debugDBPassword
                                    database:self.debugDBName
                                    delegate:self];

    if (aCouchDelegate)
        [result setDelegate:aCouchDelegate];
    
    return [[result retain] autorelease];
}

#pragma mark ¥¥¥OrcaScript helpers

- (void) zeroPedestalMasks
{
    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")]
     makeObjectsPerformSelector:@selector(zeroPedestalMasks)];
}

- (void) hvMasterTriggersOFF
{
    [[[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORXL3Model")] makeObjectsPerformSelector:@selector(hvTriggersOFF)];
}

- (void) getSmellieRunFiles
{
    //Set SmellieRunFiles to nil
    [self setSmellieRunFiles:nil];
    
    // Check there is an ELLIE model in the current configuration
    NSArray *ellieModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if (![ellieModels count]) {
        NSLogColor([NSColor redColor], @"Must have an ELLIE object in the configuration\n");
        return;
    }

    ELLIEModel* anELLIEModel = [ellieModels objectAtIndex:0];
    NSString *requestString = [NSString stringWithFormat:@"_design/smellieMainQuery/_view/pullEllieRunHeaders?startkey=3"];

    // This line calls [self couchDBresult], which in turn calls [self parseSmellieRunFileDocs] where the
    // [self smellieRunFiles] property variable gets set.
    [[anELLIEModel couchDBRef:self withDB:@"smellie"] getDocumentId:requestString tag:@"kSmellieRunHeaderRetrieved"];

    // Also force the smellie config to be loaded into the ellie model
    [anELLIEModel fetchCurrentSmellieConfig];
}

-(void) parseSmellieRunFileDocs:(id)aResult
{
    /* Use the result returned from the smellie database query to fill a
     * dictionary with all the available run file documents. */
    int nFiles = (int)[[aResult objectForKey:@"rows"] count];
    NSMutableDictionary *runFiles = [[NSMutableDictionary alloc] init];

    for (int i = 0; i < nFiles; i++) {
        NSMutableDictionary* smellieRunFileIterator = [[[aResult objectForKey:@"rows"] objectAtIndex:i] objectForKey:@"value"];
        NSString *keyForSmellieDocs = [NSString stringWithFormat:@"%u",i];
        [runFiles setObject:smellieRunFileIterator forKey:keyForSmellieDocs];
    }
    
    [self setSmellieRunFiles:runFiles];
    [runFiles release];
    
    [self setSmellieDocUploaded:YES];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SmellieRunFilesLoaded" object:self];
}

- (void) getTellieRunFiles
{
    //Set TellieRunFiles to nil
    [self setTellieRunFiles:nil];

    // Check there is an ELLIE model in the current configuration
    NSArray *ellieModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if (![ellieModels count]) {
        NSLogColor([NSColor redColor], @"Must have an ELLIE object in the configuration\n");
        return;
    }

    ELLIEModel* anELLIEModel = [ellieModels objectAtIndex:0];
    NSString *requestString = [NSString stringWithFormat:@"_design/runs/_view/run_plans"];

    // This line calls [self couchDBresult], which in turn calls [self parseSmellieRunFileDocs] where the
    // [self smellieRunFiles] property variable gets set.
    [[anELLIEModel couchDBRef:self withDB:@"telliedb"]  getDocumentId:requestString tag:@"kTellieRunHeaderRetrieved"];
}

-(void) parseTellieRunFileDocs:(id)aResult
{
    // Use the result returned from the tellie database query to fill a dictionary with all the available
    // run file documents.
    int nFiles = (int)[[aResult objectForKey:@"rows"] count];
    NSMutableDictionary *runFiles = [[NSMutableDictionary alloc] init];

    for (int i = 0; i < nFiles; i++) {
        NSMutableDictionary* tellieRunFileIterator = [[[aResult objectForKey:@"rows"] objectAtIndex:i] objectForKey:@"value"];
        NSString *keyForTellieDocs = [NSString stringWithFormat:@"%u",i];
        [runFiles setObject:tellieRunFileIterator forKey:keyForTellieDocs];
    }

    [self setTellieRunFiles:runFiles];
    [runFiles release];

    [[NSNotificationCenter defaultCenter] postNotificationName: @"TellieRunFilesLoaded" object:nil];
}

- (void) getAmellieRunFiles
{
    //Set TellieRunFiles to nil
    [self setAmellieRunFiles:nil];

    // Check there is an ELLIE model in the current configuration
    NSArray*  ellieModels = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ELLIEModel")];
    if(![ellieModels count]){
        NSLogColor([NSColor redColor], @"Must have an ELLIE object in the configuration\n");
        return;
    }

    ELLIEModel* anELLIEModel = [ellieModels objectAtIndex:0];
    NSString *requestString = [NSString stringWithFormat:@"_design/runs/_view/run_plans"];

    // This line calls [self couchDBresult], which in turn calls [self parseSmellieRunFileDocs] where the
    // [self smellieRunFiles] property variable gets set.
    [[anELLIEModel couchDBRef:self withDB:@"amellie"]  getDocumentId:requestString tag:@"kAmellieRunHeaderRetrieved"];
}

-(void) parseAmellieRunFileDocs:(id)aResult
{
    // Use the result returned from the tellie database query to fill a dictionary with all the available
    // run file documents.
    int nFiles = (int)[[aResult objectForKey:@"rows"] count];
    NSMutableDictionary *runFiles = [[NSMutableDictionary alloc] init];

    for(int i=0;i<nFiles;i++){
        NSMutableDictionary* amellieRunFileIterator = [[[aResult objectForKey:@"rows"] objectAtIndex:i] objectForKey:@"value"];
        NSString *keyForAmellieDocs = [NSString stringWithFormat:@"%u",i];
        [runFiles setObject:amellieRunFileIterator forKey:keyForAmellieDocs];
    }

    [self setAmellieRunFiles:runFiles];
    [runFiles release];

    [[NSNotificationCenter defaultCenter] postNotificationName: @"AmellieRunFilesLoaded" object:nil];
}

- (uint32_t) runTypeWord
{
    return runTypeWord;
}

- (void) setRunTypeWord:(uint32_t)aValue
{
    runTypeWord = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPRunTypeWordChangedNotification object: self];
}

- (uint32_t) lastRunTypeWord
{
    return lastRunTypeWord;
}

- (void) setLastRunTypeWord:(uint32_t)aValue
{
    lastRunTypeWord = aValue;
}

- (NSString*) lastRunTypeWordHex
{
    return lastRunTypeWordHex;
}

- (void) setLastRunTypeWordHex:(NSString*)aValue
{
    [lastRunTypeWordHex autorelease]; //MAH -- strings should be handled like this
    lastRunTypeWordHex = [aValue copy];
}

- (NSMutableDictionary*)standardRunCollection
{
    return standardRunCollection;
}

- (NSString*)standardRunType
{
    return standardRunType;
}

- (void) setStandardRunType:(NSString *)aValue
{
    [standardRunType autorelease];//MAH -- strings should be handled like this
    standardRunType = [aValue copy];

    /* Update standard run version */
    //Check if DB is empty
    if ([[standardRunCollection objectForKey:standardRunType] count] == 0) {
        [self setStandardRunVersion:@""];
    }

    //Check if previous selected run version exists
    if ([[standardRunCollection objectForKey:standardRunType] objectForKey:standardRunVersion] == nil) {
        //If not, select DEFAULT
        [self setStandardRunVersion:@"DEFAULT"];
    } else {
        [self setStandardRunVersion:[self standardRunVersion]];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelSRChangedNotification object:self];
}

- (NSString*)standardRunVersion
{
    return standardRunVersion;
}

- (void) setStandardRunVersion:(NSString *)aValue
{
    [standardRunVersion autorelease];//MAH -- strings should be handled like this
    standardRunVersion = [aValue copy];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelSRVersionChangedNotification object:self];
}

- (NSString*)lastStandardRunType
{
    return lastStandardRunType;
}

- (void) setLastStandardRunType:(NSString *)aValue
{
    [lastStandardRunType autorelease];//MAH -- strings should be handled like this
    lastStandardRunType = [aValue copy];
}

- (NSString*) lastStandardRunVersion
{
    return lastStandardRunVersion;
}

- (void) setLastStandardRunVersion:(NSString *)aValue
{
    [lastStandardRunVersion autorelease];//MAH -- strings should be handled like this
    lastStandardRunVersion = [aValue copy];
}

- (NSNumber*) standardRunTableVersion
{
    return standardRunTableVersion;
}

- (void)setStandardRunTableVersion:(NSNumber *)aValue
{
    [standardRunTableVersion autorelease];
    standardRunTableVersion = [aValue copy];
}

- (ECARun*) anECARun
{
    return anECARun;
}

- (LivePedestals*) livePeds{
    return livePeds;
}

- (BOOL) startStandardRun:(NSString*)_standardRun withVersion:(NSString*)_standardRunVersion
{
    /* Load settings into GUI from DB. The start run logic will take care of
     * shipping those to HW. */
    SNOCaenModel* caen;

    /* Get RC model */
    ORRunModel *aRunModel = nil;
    NSArray *objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if ([objs count]) {
        aRunModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"SNOPModel: couldn't find Run Model. \n");
        return NO;
    }

    //Make sure we are not running any RunScripts
    [aRunModel setSelectedRunTypeScript:0];

    [self setStandardRunType:_standardRun];
    [self setStandardRunVersion:_standardRunVersion];

    /* If we are not going to maintenance we shouldn't be polling */
    NSMutableDictionary *runSettings = [[[self standardRunCollection] objectForKey:[self standardRunType]] objectForKey:[self standardRunVersion]];

    if (runSettings == nil) {
        NSLogColor([NSColor redColor], @"Standard run %@(%@) does NOT exists in DB. \n", [self standardRunType], [self standardRunVersion]);
        return NO;
    }

    if ([aRunModel runningState] == eRunInProgress) {
        NSArray *objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOCaenModel")];
        if ([objs count]) {
            caen = [objs objectAtIndex:0];

            /* Check to see if the CAEN settings need to be reloaded. */
            @try {
                if ([caen checkFromSerialization:runSettings]) {
                    /* Need to resync. */
                    NSLog(@"CAEN settings are different in this standard run. Resyncing...\n");
                    [self setResync:YES];
                }
            } @catch (NSException *e) {
                NSLogColor([NSColor redColor], @"unable to validate CAEN settings because of exception. name: %@ reason: %@. Assuming settings haven't changed...\n", [e name], [e reason]);
            }
        } else {
            NSLogColor([NSColor redColor], @"couldn't find CAEN model. Assuming settings haven't changed.\n");
        }
    }

    //Load the standard run and stop run initialization if failed
    if (![self loadStandardRun:_standardRun withVersion:_standardRunVersion]) return NO;

    //Start or restart the run
    if ([aRunModel isRunning]) {
        /* If there is already a run going, then we restart the run. */
        if ([[self document] isDocumentEdited]) {
            /* If the GUI has changed, save the document first. */
            [[self document] afterSaveDo: @selector(restartRun) withTarget:aRunModel];
            [[self document] saveDocument:nil];
        } else {
            [aRunModel restartRun];
        }
    } else {
        /* If there is no run going, then we start a new run. */
        if ([[self document] isDocumentEdited]) {
            [[self document] afterSaveDo: @selector(startRun) withTarget:aRunModel];
            [[self document] saveDocument:nil];
        } else {
            [aRunModel startRun];
        }
    }

    return YES;
}

- (void) stopRun
{
    ORRunModel *aRunModel = nil;
    NSArray *objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    if ([objs count]) {
        aRunModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"SNOPModel: couldn't find Run Model. \n");
        return;
    }

    [aRunModel quitSelectedRunScript];
    [aRunModel performSelector:@selector(haltRun)withObject:nil afterDelay:.1];
}

- (BOOL) refreshStandardRunsFromDB
{
    // Prune the Standard Runs collection
    [standardRunCollection removeAllObjects];

    // First add Off-line standard runs
    NSMutableDictionary* runSettings = [NSMutableDictionary dictionary];
    NSMutableDictionary* versionCollection = [NSMutableDictionary dictionary];
    NSNumber* diagRunType = [NSNumber numberWithInt:kDiagnosticRun];
    [runSettings setObject:diagRunType forKey:@"run_type_word"];
    [versionCollection setObject:runSettings forKey:@"DEFAULT"];
    [standardRunCollection setObject:versionCollection forKey:@"DIAGNOSTIC"];

    // Now query DB and fetch the SRs
    NSString *urlString, *link, *ret;
    NSURLRequest *request;
    NSURLResponse *response;
    NSError *error = nil;
    NSData *data;

    urlString = [NSString stringWithFormat:@"http://%@:%@@%@:%u/%@/_design/standardRuns/_view/getStandardRunsWithVersion?startkey=[%@, \"\", \"\", 0]&endkey=[%@,\"\ufff0\",\"\ufff0\",{}]&include_docs=True",
                 [self orcaDBUserName],
                 [self orcaDBPassword],
                 [self orcaDBIPAddress],
                 [self orcaDBPort],
                 [self orcaDBName],
                 [self standardRunTableVersion],
                 [self standardRunTableVersion]];

    //link = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    link = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
   request = [NSURLRequest requestWithURL:[NSURL URLWithString:link] cachePolicy:0 timeoutInterval:2];
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    if (error != nil) {
        NSLogColor([NSColor redColor], @"Error reading standard runs from "
                   "database: %@\n", [error localizedDescription]);
        goto err;
    }
    ret = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    NSDictionary *theStandardRuns = [NSJSONSerialization JSONObjectWithData:[ret dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    // JSON formatting error
    if (error != nil) {
        NSLogColor([NSColor redColor], @"Error reading standard runs from "
                   "database: %@\n", [error localizedDescription]);
        goto err;
    }

    // If SR not found select diagnostic run
    if ([[theStandardRuns valueForKey:@"error"] isEqualToString:@"not_found"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelSRCollectionChangedNotification object:self];
        [self setStandardRunType:@"DIAGNOSTIC"];
        NSLogColor([NSColor redColor],@"Error querying couchDB, please check the settings are correct and you have connection. \n");
        return false;
    }

    // Query succeded
    for (id aStandardRun in [theStandardRuns valueForKey:@"rows"]) {
        NSString *runtype = [[aStandardRun valueForKey:@"key"] objectAtIndex:1];
        NSString *runversion = [[aStandardRun valueForKey:@"key"] objectAtIndex:2];
        NSDictionary *runsettings = [aStandardRun valueForKey:@"doc"];
        if ([runtype isEqualToString:@"DIAGNOSTIC"]) continue; // Diagnostic is a protected name
        if ([standardRunCollection objectForKey:runtype] == nil) {
            [standardRunCollection setObject:[NSMutableDictionary dictionary] forKey:runtype];
        }
        [[standardRunCollection objectForKey:runtype] setObject:runsettings forKey:runversion];
    }

    /* Notify the controller to update the popup menu */
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelSRCollectionChangedNotification object:self];

    /* Update standard run type */
    if ([standardRunCollection count] == 0) {
        /* Database is empty, so we set the standard run version to the empty string. */
        [self setStandardRunType:@""];
        return false;
    } else if([standardRunCollection objectForKey:[self standardRunType]] == nil){
        /* The current type is not in the standard runs anymore, so we select the first version. */
        [self setStandardRunType:[[standardRunCollection keyEnumerator] nextObject]];
    } else {
        [self setStandardRunType:[self standardRunType]];
    }

    /* Update standard run version */
    if ([[standardRunCollection objectForKey:[self standardRunType]] count] == 0){
        /* Database is empty, so we set the standard run version to the empty string. */
        [self setStandardRunVersion:@""];
    } else if ([[standardRunCollection objectForKey:[self standardRunType]] objectForKey:[self standardRunVersion]] == nil) {
        /* The current version is not in the standard runs anymore, so we select the DEFAULT version. */
        [self setStandardRunVersion:@"DEFAULT"];
    } else {
        [self setStandardRunVersion:[self standardRunVersion]];
    }

    return true;

err:

    [[NSNotificationCenter defaultCenter] postNotificationName:ORSNOPModelSRCollectionChangedNotification object:self];
    [self setStandardRunType:@"DIAGNOSTIC"];
    [self setStandardRunVersion:@"DEFAULT"];
    return false;

}

// Load Detector Settings from the DB into the Models
- (BOOL) loadStandardRun:(NSString*)runTypeName withVersion:(NSString*)runVersion
{
    NSMutableDictionary *runSettings = [[[self standardRunCollection] objectForKey:runTypeName] objectForKey:runVersion];
    if (runSettings == nil) {
        NSLogColor([NSColor redColor], @"Standard run %@(%@) does NOT exists in DB.\n",runTypeName, runVersion);
        return false;
    }

    /* Get models */
    NSArray *objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtcModel;
    if ([objs count]) {
        mtcModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return false;
    }

    objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel* runControlModel;
    if ([objs count]) {
        runControlModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find RC model. Please add it to the experiment and restart the run.\n");
        return false;
    }

    objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    TUBiiModel* tubiiModel;
    if ([objs count]) {
        tubiiModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find TUBii model. Please add it to the experiment and restart the run.\n");
        return false;
    }

    objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOCaenModel")];
    SNOCaenModel* caenModel;
    if ([objs count]) {
        caenModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find CAEN model. Please add it to the experiment and restart the run.\n");
        return false;
    }

    //Load values
    @try {
        //Load run type word
        uint32_t nextruntypeword = (uint32_t)[[runSettings valueForKey:@"run_type_word"] unsignedLongValue];
        uint32_t currentruntypeword = [runControlModel runType];
        //Do not touch the data quality bits
        currentruntypeword &= 0xFFE00000;
        nextruntypeword |= currentruntypeword;
        [runControlModel setRunType:nextruntypeword];
        
        //Do not load thresholds if in Diagnostic run
        if(nextruntypeword & kDiagnosticRun) return true;

        //Load MTC settings
        [mtcModel loadFromSerialization:runSettings];
        //Load CAEN settings
        [caenModel loadFromSerialization:runSettings];
        //Load TUBii settings
        [tubiiModel loadFromSerialization:runSettings];

        if (nextruntypeword & (kECARun | kECAPedestalRun | kECATSlopeRun)) {
            /* Load the ECA settings if it's an ECA run. This will set MTC
             * settings for correct ECA running, so we want this to be done
             * before loading settings in HW. */
            [[self anECARun] setECASettings];
        }

        NSLog(@"Standard run %@ (%@) settings loaded.\n",runTypeName,runVersion);
        return true;
    } @catch (NSException *e) {
        NSLog(@"Error retrieving Standard Runs information: \n %@ \n", e);
        return false;
    }
}

//Save MTC settings in a Standard Run table in CouchDB for later use by the Run Scripts or the user
//Return True on success and False on failure
- (BOOL) saveStandardRun:(NSString*)runTypeName withVersion:(NSString*)runVersion
{
    // Check that runTypeName is properly set:
    if (runTypeName == nil || runVersion == nil) {
        ORRunAlertPanel(@"Invalid Standard Run Name",@"Please, set a valid name in the popup menus and click enter",@"OK",nil,nil);
        return false;
    } else if([runTypeName isEqualToString:@"DIAGNOSTIC"]) {
        NSLog(@"You cannot save a DIAGNOSTIC run. \n");
        return false;
    } else {
        BOOL cancel = ORRunAlertPanel([NSString stringWithFormat:@"Overwriting stored values for run \"%@\" with version \"%@\"",
                                       runTypeName,runVersion],
                                      @"Is this really what you want?",@"Cancel",@"Yes, Save it",nil);
        if (cancel) return false;
    }

    // Get RC model
    NSArray *objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORRunModel")];
    ORRunModel *runControlModel;
    if ([objs count]) {
        runControlModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find RC model. Please add it to the experiment and restart the run.\n");
        return false;
    }

    // Get MTC model
    objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel* mtc;
    if ([objs count]) {
        mtc = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return false;
    }

    // Get TUBii model
    objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    TUBiiModel *tubiiModel;
    if ([objs count]) {
        tubiiModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find TUBii model. Please add it to the experiment and restart the run.\n");
        return false;
    }

    // Get CAEN model
    objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOCaenModel")];
    SNOCaenModel *caenModel;
    if ([objs count]) {
        caenModel = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find CAEN model. Please add it to the experiment and restart the run.\n");
        return false;
    }

    // Build run table
    NSMutableDictionary *detectorSettings = [NSMutableDictionary dictionaryWithCapacity:200];

    [detectorSettings setObject:@"standard_run" forKey:@"type"];
    [detectorSettings setObject:standardRunTableVersion forKey:@"version"];
    [detectorSettings setObject:runTypeName forKey:@"run_type"];
    [detectorSettings setObject:runVersion forKey:@"run_version"];
    NSNumber *date = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
    [detectorSettings setObject:date forKey:@"time_stamp"];
    // Do not touch the data quality bits
    uint32_t currentRunTypeWord = [runControlModel runType];
    currentRunTypeWord &= ~0xFFE00000;
    [detectorSettings setObject:[NSNumber numberWithUnsignedLong:currentRunTypeWord] forKey:@"run_type_word"];

    // Save MTC/D parameters, trigger masks and MTC/A+ thresholds
    NSMutableDictionary* mtc_serial = [mtc serializeToDictionary];
    [detectorSettings addEntriesFromDictionary:mtc_serial];

    // Save TUBii settings
    NSMutableDictionary* tubii_serial = [tubiiModel serializeToDictionary];
    if (tubii_serial != NULL) [detectorSettings addEntriesFromDictionary:tubii_serial];
    else return false;

    // Save CAEN settings
    NSMutableDictionary* caen_serial = [caenModel serializeToDictionary];
    if (caen_serial != NULL) [detectorSettings addEntriesFromDictionary:caen_serial];
    else return false;

    NSLog(@"Saving settings for Standard Run %@ - Version %@: \n %@ \n",runTypeName,runVersion,detectorSettings);

    [[self orcaDbRefWithEntryDB:self withDB:[self orcaDBName]] addDocument:detectorSettings tag:@"kStandardRunPosted"];

    return true;
}

//Ship GUI settings to hardware
- (void) loadSettingsInHW
{
    NSArray *objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORMTCModel")];
    ORMTCModel *mtc;
    if ([objs count]) {
        mtc = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find MTC model. Please add it to the experiment and restart the run.\n");
        return;
    }

    objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"SNOCaenModel")];
    SNOCaenModel *caen;
    if ([objs count]) {
        caen = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find CAEN model. Please add it to the experiment and restart the run.\n");
        return;
    }

    objs = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"TUBiiModel")];
    TUBiiModel *tubii;
    if ([objs count]) {
        tubii = [objs objectAtIndex:0];
    } else {
        NSLogColor([NSColor redColor], @"couldn't find TUBii model. Please add it to the experiment and restart the run.\n");
        return;
    }

    @try {
        //Load TUBii settings
        [tubii sendCurrentModelStateToHW];

        //Load CAEN settings
        [caen initBoard];

        //Load MTC settings
        [mtc loadTheMTCADacs];
        [mtc setGlobalTriggerWordMask];
        [mtc loadPulserRateToHardware];
    } @catch(NSException *e) {
        NSLogColor([NSColor redColor], @"Problem loading settings into Hardware: %@\n",[e reason]);
        return;
    }
    
    NSLog(@"Settings loaded in Hardware \n");
}

@end
