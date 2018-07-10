//-------------------------------------------------------------------------
//  ORPQModel.h
//
//  2016-06-01 Created by Phil Harvey (Based on ORSqlModel.h by M.Howe)
//
//
//  Abritrary database accesses may be made via this object by defining
//  a callback function in the calling object like this:
//
//    - (void) callbackProc:(ORPQResult*)theResult
//    {
//        // do stuff here
//    }
//
//  then calling dbQuery like this:
//
//    if ([ORPQModel getCurrent]) {
//        [[ORPQModel getCurrent] dbQuery:@"<query string>" object:self selector:@selector(callbackProc:)];
//    }
//
//-------------------------------------------------------------

#pragma mark ***Imported Files

#define kSnoCrates          20
#define kSnoCardsPerCrate   16
#define kSnoChannelsPerCard 32
#define kSnoCardsTotal      (kSnoCrates * kSnoCardsPerCrate)
#define kSnoChannels        (kSnoCardsTotal * kSnoChannelsPerCard)

// indices for PQ_FEC valid flags
// (same as order of columns as extracted from the FEC database)
// (all except hvDisabled must have the same numbers as the column numbers when reading the detector db)
enum {
    kFEC_exists,    // set to 1 if card exists in current detector state (if 0, all elements except hvDisabled will be invalid)
    kFEC_hvDisabled,
    kFEC_nhit100enabled,
    kFEC_nhit100delay,
    kFEC_nhit20enabled,
    kFEC_nhit20width,
    kFEC_nhit20delay,
    kFEC_vbal0,
    kFEC_vbal1,
    kFEC_tac0trim,  // (tcmos_tacshift in the database)
    kFEC_tac1trim,  // (scmos in the database)
    kFEC_vthr,
    kFEC_pedEnabled,
    kFEC_seqDisabled,
    kFEC_tdiscRp1,  // (tdisc_rmpup in the database)
    kFEC_tdiscRp2,  // (tdisc_rmp in the database)
    kFEC_tdiscVsi,
    kFEC_tdiscVli,
    kFEC_tcmosVmax,
    kFEC_tcmosTacref,
    kFEC_tcmosIsetm,
    kFEC_tcmosIseta,
    kFEC_vres,      // (vint in the database)
    kFEC_hvref,
    kFEC_mbid,
    kFEC_dbid,
    kFEC_pmticid,
    kFEC_numDbColumns
};

#define kNumFecTdisc    8
#define kNumFecIset     2
#define kNumDbPerFec    4

typedef struct {
    uint32_t        hvDisabled;   // resistor pulled or no cable
    uint32_t        nhit100enabled;
    unsigned char   nhit100delay[kSnoChannelsPerCard];
    uint32_t        nhit20enabled;
    unsigned char   nhit20width[kSnoChannelsPerCard];
    unsigned char   nhit20delay[kSnoChannelsPerCard];
    unsigned char   vbal0[kSnoChannelsPerCard];
    unsigned char   vbal1[kSnoChannelsPerCard];
    unsigned char   tac0trim[kSnoChannelsPerCard];
    unsigned char   tac1trim[kSnoChannelsPerCard];
    unsigned char   vthr[kSnoChannelsPerCard];
    uint32_t        pedEnabled;
    uint32_t        seqDisabled;
    unsigned char   tdiscRp1[kNumFecTdisc];
    unsigned char   tdiscRp2[kNumFecTdisc];
    unsigned char   tdiscVsi[kNumFecTdisc];
    unsigned char   tdiscVli[kNumFecTdisc];
    uint32_t        tcmosVmax;
    uint32_t        tcmosTacref;
    uint32_t        tcmosIsetm[kNumFecIset];
    uint32_t        tcmosIseta[kNumFecIset];
    uint32_t        vres;
    uint32_t        hvref;
    uint32_t        mbid;                       // motherboard ID
    uint32_t        dbid[kNumDbPerFec];         // daughterboard ID's
    uint32_t        pmticid;                    // PMTIC ID
    uint32_t        valid[kFEC_numDbColumns];   // bitmasks for settings loaded from hardware (see enum above)
} PQ_FEC;

// indices for PQ_MTC valid flags
// (same as order of columns as extracted from the MTC database)
enum {
    kMTC_controlReg,
    kMTC_mtcaDacs,
    kMTC_pedWidth,
    kMTC_coarseDelay,
    kMTC_fineDelay,
    kMTC_pedMask,
    kMTC_prescale,
    kMTC_lockoutWidth,
    kMTC_gtMask,
    kMTC_gtCrateMask,
    kMTC_mtcaRelays,
    kMTC_pulserRate,
    kMTC_numDbColumns,
};

#define kNumMtcDacs     14
#define kNumMtcRelays   7

// order of MTCA DAC entries in the mtca_dacs entry of the database
enum {
    kMTCA_DAC_NHit100Lo,
    kMTCA_DAC_NHit100Med,
    kMTCA_DAC_NHit100Hi,
    kMTCA_DAC_NHit20,
    kMTCA_DAC_NHit20LB,
    kMTCA_DAC_ESumLo,
    kMTCA_DAC_ESumHi,
    kMTCA_DAC_OWLN,
    kMTCA_DAC_OWLELo,
    kMTCA_DAC_OWLEHi,
    kMTCA_DAC_Spare1,
    kMTCA_DAC_Spare2,
    kMTCA_DAC_Spare3,
    kMTCA_DAC_Spare4,
};

typedef struct {
    uint32_t    controlReg;
    uint32_t    mtcaDacs[kNumMtcDacs];
    uint32_t    pedWidth;
    uint32_t    coarseDelay;
    uint32_t    fineDelay;
    uint32_t    pedMask;
    uint32_t    prescale;
    uint32_t    lockoutWidth;
    uint32_t    gtMask;
    uint32_t    gtCrateMask;
    uint32_t    mtcaRelays[kNumMtcRelays];
    uint32_t    pulserRate;
    uint32_t    valid[kMTC_numDbColumns];
} PQ_MTC;

// indices for PQ_Crate valid flags
// (same as order of columns as extracted from the crate database)
enum {
    kCrate_exists,
    kCrate_ctcDelay,
    kCrate_hvRelayMask1,
    kCrate_hvRelayMask2,
    kCrate_hvAOn,
    kCrate_hvBOn,
    kCrate_hvDacA,
    kCrate_hvDacB,
    kCrate_xl3ReadoutMask,
    kCrate_xl3Mode,
    kCrate_numDbColumns,
};

typedef struct {
    uint32_t    exists; // (essentially a dummy variable to pad for column 0)
    uint32_t    ctcDelay;
    uint32_t    hvRelayMask1;
    uint32_t    hvRelayMask2;
    uint32_t    hvAOn;
    uint32_t    hvBOn;
    uint32_t    hvDacA;
    uint32_t    hvDacB;
    uint32_t    xl3ReadoutMask;
    uint32_t    xl3Mode;
    uint32_t    valid[kCrate_numDbColumns];
} PQ_Crate;

// indices for PQ_CAEN valid flags
// (same as order of columns as extracted from the CAEN database)
enum {
    kCAEN_channelConfiguration,
    kCAEN_bufferOrganization,
    kCAEN_customSize,
    kCAEN_acquisitionControl,
    kCAEN_triggerMask,
    kCAEN_triggerOutMask,
    kCAEN_postTrigger,
    kCAEN_frontPanelIoControl,
    kCAEN_channelMask,
    kCAEN_channelDacs,
    kCAEN_numDbColumns,
};

#define kNumCaenChannelDacs 8

typedef struct {
    uint32_t    channelConfiguration;
    uint32_t    bufferOrganization;
    uint32_t    customSize;
    uint32_t    acquisitionControl;
    uint32_t    triggerMask;
    uint32_t    triggerOutMask;
    uint32_t    postTrigger;
    uint32_t    frontPanelIoControl;
    uint32_t    channelMask;
    uint32_t    channelDacs[kNumCaenChannelDacs];
    uint32_t    valid[kCAEN_numDbColumns];
} PQ_CAEN;

// indices for PQ_RUN valid flags
enum {
    kRun_runNumber,
    kRun_runType,
    kRun_runInProgress,
    kRun_runStartTime,
    kRun_numDbColumns,
};

typedef struct {
    uint32_t    runNumber;
    uint32_t    runType;
    uint32_t    runInProgress;
    NSDate    * runStartTime;
    uint32_t    valid[kRun_numDbColumns];
} PQ_Run;

//----------------------------------------------------------------------------------------------------
@interface ORPQDetectorDB : NSMutableData
{
@private
    NSMutableData * data;
@public
    int         pmthvLoaded;    // number of PMT HV channels loaded from db
    int         fecLoaded;      // number of FEC cards loaded from db
    int         crateLoaded;    // number of crates loaded from db
    int         mtcLoaded;      // 1 if MTC settings were loaded from db
    int         caenLoaded;     // 1 if CAEN settings were loaded from db
    int         runLoaded;      // 1 if run state was loaded from db
}

- (id)          init;
- (void)        dealloc;
- (PQ_FEC *)    getFEC:(int)aCard crate:(int)aCrate;
- (PQ_FEC *)    getPmthv:(int)aCard crate:(int)aCrate;
- (PQ_Crate *)  getCrate:(int)aCrate;
- (PQ_MTC *)    getMTC;
- (PQ_CAEN *)   getCAEN;
- (PQ_Run *)    getRun;

@end
//----------------------------------------------------------------------------------------------------

@class ORPQConnection;
@class ORPQModel;
@class ORPQResult;
@class NSMutableData;

@interface ORPQModel : OrcaObject
{
@private
	ORPQConnection* pqConnection;
	NSString*	hostName;
    NSString*	userName;
    NSString*	password;
    NSString*	dataBaseName;
    BOOL		stealthMode;
}

+ (ORPQModel *)getCurrent;

#pragma mark ***Initialization
- (id)   init;
- (void) dealloc;
- (void) awakeAfterDocumentLoaded;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) applicationIsTerminating:(NSNotification*)aNote;

#pragma mark ***Accessors

/**
 @brief Arbitrary detector db query
 @param aCommand PostgreSQL command string
 @param anObject Callback object
 @param aSelector Callback object selector (called with an ORPQResult object, or nil on error)
 @param aTimeoutSecs Timeout time in seconds (0 for no timeout)
 */
- (void) dbQuery:(NSString*)aCommand object:(id)anObject selector:(SEL)aSelector timeout:(float)aTimeoutSecs;

/**
 @brief Arbitrary detector db query with no timeout
 @param aCommand PostgreSQL command string
 @param anObject Callback object
 @param aSelector Callback object selector (called with an ORPQResult object, or nil on error)
 */
- (void) dbQuery:(NSString*)aCommand object:(id)anObject selector:(SEL)aSelector;

/**
 @brief Arbitrary detector db query with no callback or timeout
 @param aCommand PostgreSQL command string
 */
- (void) dbQuery:(NSString*)aCommand;

/**
 @brief Get SNO+ detector database
 @param anObject Callback object
 @param aSelector Callback object selector (called with an ORPQDetectorDB object, or nil on error)
 */
- (void) detectorDbQuery:(id)anObject selector:(SEL)aSelector;

- (void) cancelDbQueries;
- (BOOL) stealthMode;
- (void) setStealthMode:(BOOL)aStealthMode;
- (NSString*) dataBaseName;
- (void) setDataBaseName:(NSString*)aDataBaseName;
- (NSString*) password;
- (void) setPassword:(NSString*)aPassword;
- (NSString*) userName;
- (void) setUserName:(NSString*)aUserName;
- (NSString*) hostName;
- (void) setHostName:(NSString*)aHostName;
- (void) logQueryException:(NSException*)e;
- (id) nextObject;

#pragma mark ***Archival
- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***SQL Access
- (void) testConnection;
- (BOOL) connected;
- (void) disconnectSql;

@end

extern NSString* ORPQModelStealthModeChanged;
extern NSString* ORPQDataBaseNameChanged;
extern NSString* ORPQPasswordChanged;
extern NSString* ORPQUserNameChanged;
extern NSString* ORPQHostNameChanged;
extern NSString* ORPQConnectionValidChanged;
extern NSString* ORPQDetectorStateChanged;
extern NSString* ORPQLock;


@interface ORPQOperation : NSOperation
{
    id delegate;
    id object;      // object for callback
    SEL selector;   // selector for main thread callback when done (no callback if nil)
}

- (id)	 initWithDelegate:(id)aDelegate;
- (id)	 initWithDelegate:(id)aDelegate object:(id)anObject selector:(SEL)aSelector;
- (void) dealloc;
@end

@interface ORRunState : NSObject
{
    @public int run;
    @public int state;
}
@end

enum ePQCommandType {
    kPQCommandType_General,
    kPQCommandType_GetDetectorDB,
    kPQCommandType_TestConnection,
};

@interface ORPQQueryOp : ORPQOperation
{
    NSString *command;
    int commandType;
}
- (void) setCommand:(NSString*)aCommand;
- (void) setCommandType:(int)aCommandType;
- (ORPQDetectorDB *) loadDetectorDB:(ORPQConnection*)pqConnection;
- (void) _detectorDbCallback:(NSMutableData*)data;
- (void) cancel;
- (void) main;
@end

#define kClear 0
#define kPost  1
@interface ORPQPostAlarmOp : ORPQOperation
{
	BOOL opType;
	id alarm;
}
- (void) dealloc;
- (void) postAlarm:(id)anAlarm;
- (void) clearAlarm:(id)anAlarm;
- (void) main;
@end

