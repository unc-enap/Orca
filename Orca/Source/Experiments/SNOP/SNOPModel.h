//
//  SNOPModel.h
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


#pragma mark 짜짜짜Imported Files
#import "ORExperimentModel.h"
#import "ORVmeCardDecoder.h"
#import "RedisClient.h"
#import "ECARun.h"
#import "NHitMonitor.h"
#import "SessionDB.h"
#import "LivePedestals.h"

@class ORCouchDB;
@class ORRunModel;
@class ORPingTask;

@protocol snotDbDelegate <NSObject>
@required
- (ORCouchDB*) orcaDbRef:(id)aCouchDelegate;
- (ORCouchDB*) debugDBRef:(id)aCouchDelegate;
- (ORCouchDB*) orcaDbRefWithEntryDB:(id)aCouchDelegate withDB:(NSString*)entryDB;
@end

#define kUseTubeView	0
#define kUseCrateView	1
#define kUsePSUPView	2
#define kNumTubes	20 //XL3s
#define kNumOfCrates 19 //number of Crates in SNO+
#define STANDARD_RUN_VERSION 2 //Increase if Standard Runs table structure is changed
#define SNOP_ORCA_VERSION "1.0.1" //The current Orca release

BOOL isNotRunningOrIsInMaintenance();

@interface SNOPModel: ORExperimentModel <snotDbDelegate>
{
    SessionDB* sessionDB;
    ORAlarm* defaultRunAlarm;

    NSString* _orcaDBUserName;
    NSString* _orcaDBPassword;
    NSString* _orcaDBName;
    unsigned int _orcaDBPort;
    NSString* _orcaDBIPAddress;
    NSMutableArray* _orcaDBConnectionHistory;
    NSUInteger _orcaDBIPNumberIndex;
    ORPingTask*	_orcaDBPingTask;
    
    NSString* _debugDBUserName;
    NSString* _debugDBPassword;
    NSString* _debugDBName;
    NSString* _smellieRunNameLabel;
    NSString* _tellieRunNameLabel;
    NSString* _amellieRunNameLabel;
    unsigned int _debugDBPort;
    NSString* _debugDBIPAddress;
    NSMutableArray* _debugDBConnectionHistory;
    NSUInteger _debugDBIPNumberIndex;
    ORPingTask*	_debugDBPingTask;
    
    struct {
        unsigned long coarseDelay;
        unsigned long fineDelay;
        unsigned long chargePulseAmp;
        unsigned long pedestalWidth;
        unsigned long calType; // pattern ID (1 to 4) + 10 * (1 ped, 2 tslope, 3 qslope)
        unsigned long stepNumber;
        unsigned long nTSlopePoints;
    } _epedStruct;
    
    NSDictionary* _runDocument;
    NSDictionary* _configDocument;
    NSDictionary* _mtcConfigDoc;
    NSMutableDictionary* _runTypeDocumentPhysics;
    NSMutableDictionary* _smellieRunFiles;
    NSMutableDictionary* _tellieRunFiles;
    NSMutableDictionary* _amellieRunFiles;
    
    bool _smellieDBReadInProgress;
    bool _smellieDocUploaded;
    NSMutableDictionary* standardRunCollection;
    NSString* standardRunType;
    NSString* standardRunVersion;
    NSString* lastStandardRunType;
    NSString* lastStandardRunVersion;
    NSNumber* standardRunTableVersion;

    bool rolloverRun;

    NSString *mtcHost;
    int mtcPort;

    NSString *xl3Host;
    int xl3Port;

    NSString *dataHost;
    int dataPort;

    NSString *logHost;
    int logPort;

    /* Nhit Monitor Settings. */
    NHitMonitor *nhitMonitor;
    int nhitMonitorCrate;
    int nhitMonitorPulserRate;
    int nhitMonitorNumPulses;
    int nhitMonitorMaxNhit;

    /* Settings for running the nhit monitor automatically during runs. */
    BOOL nhitMonitorAutoRun;
    int nhitMonitorAutoPulserRate;
    int nhitMonitorAutoNumPulses;
    int nhitMonitorAutoMaxNhit;
    NSTimer *nhitMonitorTimer;
    uint32_t nhitMonitorRunType;
    uint32_t nhitMonitorCrateMask;
    NSTimeInterval nhitMonitorTimeInterval;

    NSLock *ecaLock;

    RedisClient *mtc_server;
    RedisClient *xl3_server;

    int state;
    int start;
    bool resync;
    bool waitingForBuffers;     // flag indicates we are waiting for our buffers to empty

    @private
        //Run type word
        unsigned long runTypeWord;
        unsigned long lastRunTypeWord;
        NSString* lastRunTypeWordHex;
        ECARun* anECARun;
        LivePedestals* livePeds;
}

@property (nonatomic,retain) NSMutableDictionary* smellieRunFiles;
@property (nonatomic,retain) NSMutableDictionary* tellieRunFiles;
@property (nonatomic,retain) NSMutableDictionary* amellieRunFiles;

@property (nonatomic,copy) NSString* orcaDBUserName;
@property (nonatomic,copy) NSString* orcaDBPassword;
@property (nonatomic,copy) NSString* orcaDBName;
@property (nonatomic,assign) unsigned int orcaDBPort;
@property (nonatomic,copy) NSString* orcaDBIPAddress;
@property (nonatomic,retain) NSMutableArray* orcaDBConnectionHistory;
@property (nonatomic,assign) NSUInteger orcaDBIPNumberIndex;
@property (nonatomic,retain) ORPingTask* orcaDBPingTask;

@property (nonatomic,copy) NSString* debugDBUserName;
@property (nonatomic,copy) NSString* debugDBPassword;
@property (nonatomic,copy) NSString* debugDBName;
@property (nonatomic,copy) NSString* smellieRunNameLabel;
@property (nonatomic,copy) NSString* tellieRunNameLabel;
@property (nonatomic,copy) NSString* amellieRunNameLabel;
@property (nonatomic,assign) unsigned int debugDBPort;
@property (nonatomic,copy) NSString* debugDBIPAddress;
@property (nonatomic,retain) NSMutableArray* debugDBConnectionHistory;
@property (nonatomic,assign) NSUInteger debugDBIPNumberIndex;
@property (nonatomic,retain) ORPingTask* debugDBPingTask;

@property (nonatomic,assign) bool smellieDBReadInProgress;
@property (nonatomic,assign) bool smellieDocUploaded;

@property (copy,setter=setDataServerHost:) NSString *dataHost;
@property (setter=setDataServerPort:) int dataPort;

@property (copy,setter=setLogServerHost:) NSString *logHost;
@property (setter=setLogServerPort:) int logPort;
@property (nonatomic,assign) bool resync;

- (id) init;
- (void) awakeAfterDocumentLoaded;

- (void) setSessionDBUsername: (NSString *) username;
- (NSString *) sessionDBUsername;
- (void) setSessionDBPassword: (NSString *) password;
- (NSString *) sessionDBPassword;
- (void) setSessionDBName: (NSString *) dbname;
- (NSString *) sessionDBName;
- (void) setSessionDBAddress: (NSString *) address;
- (NSString *) sessionDBAddress;
- (void) setSessionDBPort: (unsigned int) port;
- (unsigned int) sessionDBPort;
- (void) setSessionDBLockID: (unsigned int) lockID;
- (unsigned int) sessionDBLockID;

- (void) setMTCPort: (int) port;
- (int) mtcPort;

- (void) setMTCHost: (NSString *) host;
- (NSString *) mtcHost;

- (void) setXL3Port: (int) port;
- (int) xl3Port;

- (void) setXL3Host: (NSString *) host;
- (NSString *) xl3Host;

- (void) setLogNameFormat;
- (void) saveLogFiles:(NSNotification*)aNote;

- (void) initOrcaDBConnectionHistory;
- (void) clearOrcaDBConnectionHistory;
- (id) orcaDBConnectionHistoryItem:(unsigned int)index;
- (void) orcaDBPing;

- (void) initDebugDBConnectionHistory;
- (void) clearDebugDBConnectionHistory;
- (id) debugDBConnectionHistoryItem:(unsigned int)index;
- (void) debugDBPing;

- (void) taskFinished:(ORPingTask*)aTask;
- (void) couchDBResult:(id)aResult tag:(NSString*)aTag op:(id)anOp;

- (void) pingCratesAtRunStart;
- (NSLock *) ecaLock;
- (void) pingCrates;
- (void) runNhitMonitorAutomatically;
- (void) runNhitMonitor;
- (void) stopNhitMonitor;

#pragma mark ⅴorcascript helpers
- (void) zeroPedestalMasks;
- (void) hvMasterTriggersOFF;

#pragma mark 짜짜짜Notifications
- (void) registerNotificationObservers;

- (void) runInitialization:(NSNotification*)aNote;
- (void) runAboutToStart:(NSNotification*)aNote;
- (void) runStarted:(NSNotification*)aNote;
- (void) runAboutToStop:(NSNotification*)aNote;
- (void) runStopped:(NSNotification*)aNote;

- (void) _waitForBuffers;

- (void) subRunStarted:(NSNotification*)aNote;
- (void) subRunEnded:(NSNotification*)aNote;
- (void) detectorStateChanged:(NSNotification*)aNote;

- (void) enableGlobalSecurity;

- (void) updateEPEDStructWithCoarseDelay: (unsigned long) coarseDelay
                               fineDelay: (unsigned long) fineDelay
                          chargePulseAmp: (unsigned long) chargePulseAmp
                           pedestalWidth: (unsigned long) pedestalWidth
                                 calType: (unsigned long) calType;
- (void) updateEPEDStructWithStepNumber: (unsigned long) stepNumber;
- (void) shipSubRunRecord;
- (void) shipEPEDRecord;
- (void) stillWaitingForBuffers;
- (void) abortWaitingForBuffers;

#pragma mark 짜짜짜Accessors
- (NHitMonitor *) nhitMonitor;
- (int) nhitMonitorCrate;
- (void) setNhitMonitorCrate: (int) crate;
- (int) nhitMonitorPulserRate;
- (void) setNhitMonitorPulserRate: (int) pulserRate;
- (int) nhitMonitorNumPulses;
- (void) setNhitMonitorNumPulses: (int) numPulses;
- (int) nhitMonitorMaxNhit;
- (void) setNhitMonitorMaxNhit: (int) maxNhit;
- (int) nhitMonitorAutoRun;
- (void) setNhitMonitorAutoRun: (BOOL) run;
- (int) nhitMonitorAutoPulserRate;
- (void) setNhitMonitorAutoPulserRate: (int) pulserRate;
- (int) nhitMonitorAutoNumPulses;
- (void) setNhitMonitorAutoNumPulses: (int) numPulses;
- (int) nhitMonitorAutoMaxNhit;
- (void) setNhitMonitorAutoMaxNhit: (int) maxNhit;
- (uint32_t) nhitMonitorRunType;
- (void) setNhitMonitorRunType: (uint32_t) runType;
- (uint32_t) nhitMonitorCrateMask;
- (void) setNhitMonitorCrateMask: (uint32_t) mask;
- (NSTimeInterval) nhitMonitorTimeInterval;
- (void) setNhitMonitorTimeInterval: (NSTimeInterval) interval;

- (unsigned long) runTypeWord;
- (void) setRunTypeWord:(unsigned long)aMask;
- (unsigned long) lastRunTypeWord;
- (void) setLastRunTypeWord:(unsigned long)aMask;
- (NSString*) lastRunTypeWordHex;
- (void) setLastRunTypeWordHex:(NSString*)aValue;
- (NSMutableDictionary*) standardRunCollection;
- (NSString*) standardRunType;
- (void) setStandardRunType:(NSString*)aValue;
- (NSString*) standardRunVersion;
- (void) setStandardRunVersion:(NSString*)aValue;
- (NSString*) lastStandardRunType;
- (void) setLastStandardRunType:(NSString*)aValue;
- (NSString*) lastStandardRunVersion;
- (void) setLastStandardRunVersion:(NSString*)aValue;
- (NSNumber*) standardRunTableVersion;

#pragma mark 짜짜짜Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

#pragma mark 짜짜짜Specific Dialog Lock Methods
- (NSString*) experimentMapLock;
- (NSString*) experimentDetectorLock;
- (NSString*) experimentDetailsLock;

#pragma mark 짜짜짜SnotDbDelegate
- (ORCouchDB*) orcaDbRef:(id)aCouchDelegate;
- (ORCouchDB*) debugDBRef:(id)aCouchDelegate;
- (ORCouchDB*) orcaDbRefWithEntryDB:(id)aCouchDelegate withDB:(NSString*)entryDB;

// smellie functions -------
-(void) getSmellieRunFiles;

// tellie functions -------
-(void) getTellieRunFiles;

//tellie functions -------
-(void) getAmellieRunFiles;

// ECA
-(ECARun*) anECARun;

//Live Pedestals
-(LivePedestals*) livePeds;

//Standard runs functions
-(BOOL) refreshStandardRunsFromDB;
-(BOOL) startStandardRun:(NSString*)_standardRun withVersion:(NSString*)_standardRunVersion;
-(BOOL) loadStandardRun:(NSString*)runTypeName withVersion:(NSString*)runVersion;
-(BOOL) saveStandardRun:(NSString*)runTypeName withVersion:(NSString*)runVersion;
-(void) loadSettingsInHW;
-(void) stopRun;

@end

extern NSString* ORSNOPModelOrcaDBIPAddressChanged;
extern NSString* ORSNOPModelDebugDBIPAddressChanged;
extern NSString* ORSNOPRunTypeWordChangedNotification;
extern NSString* SNOPRunTypeChangedNotification;
extern NSString* ORSNOPRunsLockNotification;
extern NSString* ORSNOPModelSRCollectionChangedNotification;
extern NSString* ORSNOPModelSRChangedNotification;
extern NSString* ORSNOPModelSRVersionChangedNotification;
extern NSString* ORSNOPModelNhitMonitorChangedNotification;
extern NSString* ORSNOPStillWaitingForBuffersNotification;
extern NSString* ORSNOPNotWaitingForBuffersNotification;
extern NSString* ORRoutineChangedNotification;
