//
//  ORPQModel.m
//
//  2016-06-01 Created by Phil Harvey (Based on ORSqlModel.m by M.Howe)
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

#import "ORPQModel.h"
#import "ORPQConnection.h"
#import "ORPQResult.h"
#import "ORAlarmController.h"

const int kPQAlarm_OrcaAlarmActive = 85001;
const int kOrcaAlarmMin = 80000;
const int kOrcaAlarmMax = 89999;

NSString* ORPQModelStealthModeChanged = @"ORPQModelStealthModeChanged";
NSString* ORPQDataBaseNameChanged	= @"ORPQDataBaseNameChanged";
NSString* ORPQPasswordChanged		= @"ORPQPasswordChanged";
NSString* ORPQUserNameChanged		= @"ORPQUserNameChanged";
NSString* ORPQHostNameChanged		= @"ORPQHostNameChanged";
NSString* ORPQConnectionValidChanged = @"ORPQConnectionValidChanged";
NSString* ORPQDetectorStateChanged  = @"ORPQDetectorStateChanged";
NSString* ORPQLock					= @"ORPQLock";

static ORPQModel *currentORPQModel = nil;

static NSString* ORPQModelInConnector 	= @"ORPQModelInConnector";

@interface ORPQModel (private)
- (ORPQConnection*) pqConnection;
- (void) alarmPosted:(NSNotification*)aNote;
- (void) alarmCleared:(NSNotification*)aNote;
@end

@implementation ORPQModel

+ (ORPQModel*)getCurrent
{
    return currentORPQModel;
}

#pragma mark ***Initialization
- (id) init
{
	self=[super init];
    currentORPQModel = self;
    return self;
}
- (void) dealloc
{
    if (currentORPQModel == self) currentORPQModel = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [dataBaseName release];
    [password release];
    [userName release];
    [hostName release];
	[super dealloc];
}

- (void) wakeUp
{
    if(![self aWake]){
		[self registerNotificationObservers];
    }
    [super wakeUp];
}


- (void) sleep
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[ORPQDBQueue queue]cancelAllOperations];
	[[ORPQDBQueue queue] waitUntilAllOperationsAreFinished];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super sleep];
}

- (void) awakeAfterDocumentLoaded
{
    [self detectorDbQuery:NULL selector:NULL];   // load our current detector state
}
- (BOOL) solitaryObject
{
    return YES;
}
- (void) setUpImage
{
    [self setImage:[NSImage imageNamed:@"PostgreSQL"]];
}

- (void) makeMainController
{
    [self linkToController:@"ORPQController"];
}

- (void) makeConnectors
{
    ORConnector* aConnector = [[ORConnector alloc] initAt:NSMakePoint(0,[self frame].size.height/2-kConnectorSize/2) withGuardian:self withObjectLink:self];
    [[self connectors] setObject:aConnector forKey:ORPQModelInConnector];
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
                     selector : @selector(alarmPosted:)
                         name : ORAlarmWasPostedNotification
                       object : nil];	
	
    [notifyCenter addObserver : self
                     selector : @selector(alarmCleared:)
                         name : ORAlarmWasClearedNotification
                       object : nil];	

}

- (void) applicationIsTerminating:(NSNotification*)aNote
{
}


#pragma mark ***Accessors

- (id) nextObject
{
	return [self objectConnectedTo:ORPQModelInConnector];
}

- (void)dbQuery:(NSString*)aCommand object:(id)anObject selector:(SEL)aSelector timeout:(float)aTimeoutSecs
{
    if(stealthMode){
        [anObject performSelector:aSelector withObject:nil afterDelay:0.1];
    } else {
        ORPQQueryOp* anOp = [[ORPQQueryOp alloc] initWithDelegate:self object:anObject selector:aSelector];
        if (aTimeoutSecs) {
            [anOp performSelector:@selector(cancel) withObject:nil afterDelay:aTimeoutSecs];
        }
        [anOp setCommand:aCommand];
        [ORPQDBQueue addOperation:anOp];
        [anOp release];
    }
}

- (void)dbQuery:(NSString*)aCommand object:(id)anObject selector:(SEL)aSelector
{
    [self dbQuery:aCommand object:anObject selector:aSelector timeout:0];
}

- (void)dbQuery:(NSString*)aCommand
{
    [self dbQuery:aCommand object:nil selector:nil timeout:0];
}

- (void)detectorDbQuery:(id)anObject selector:(SEL)aSelector
{
    if(stealthMode){
        [anObject performSelector:aSelector withObject:nil afterDelay:0.1];
    } else {
        ORPQQueryOp* anOp = [[ORPQQueryOp alloc] initWithDelegate:self object:anObject selector:aSelector];
        [anOp setCommandType:kPQCommandType_GetDetectorDB];
        [ORPQDBQueue addOperation:anOp];
        [anOp release];
    }
}

// cancel all dbQuery and pmtdbQuery operations
- (void) cancelDbQueries
{
    for (NSOperation *op in [[ORPQDBQueue queue] operations]) {
        if ([op isKindOfClass:[ORPQQueryOp class]]) {
            [op cancel];
        }
    }
}


- (BOOL) stealthMode
{
    return stealthMode;
}

- (void) setStealthMode:(BOOL)aStealthMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStealthMode:stealthMode];
    stealthMode = aStealthMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORPQModelStealthModeChanged object:self];
}

- (NSString*) dataBaseName
{
    return dataBaseName;
}

- (void) setDataBaseName:(NSString*)aDataBaseName
{
	if(aDataBaseName){
		[[[self undoManager] prepareWithInvocationTarget:self] setDataBaseName:dataBaseName];
		
		[dataBaseName autorelease];
		dataBaseName = [aDataBaseName copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORPQDataBaseNameChanged object:self];
	}
}

- (NSString*) password
{
    return password;
}

- (void) setPassword:(NSString*)aPassword
{
	if(aPassword){
		[[[self undoManager] prepareWithInvocationTarget:self] setPassword:password];
		
		[password autorelease];
		password = [aPassword copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORPQPasswordChanged object:self];
	}
}

- (NSString*) userName
{
    return userName;
}

- (void) setUserName:(NSString*)aUserName
{
	if(aUserName){
		[[[self undoManager] prepareWithInvocationTarget:self] setUserName:userName];
		
		[userName autorelease];
		userName = [aUserName copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORPQUserNameChanged object:self];
	}
}

- (NSString*) hostName
{
    return hostName;
}

- (void) setHostName:(NSString*)aHostName
{
	if(aHostName){
		[[[self undoManager] prepareWithInvocationTarget:self] setHostName:hostName];
		
		[hostName autorelease];
		hostName = [aHostName copy];    
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORPQHostNameChanged object:self];
	}
}

#pragma mark ***Archival
- (id)initWithCoder:(NSCoder*)decoder
{    
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setDataBaseName:[decoder decodeObjectForKey:@"DataBaseName"]];
    [self setPassword:[decoder decodeObjectForKey:@"Password"]];
    [self setUserName:[decoder decodeObjectForKey:@"UserName"]];
    [self setHostName:[decoder decodeObjectForKey:@"HostName"]];
    [self setStealthMode:[decoder decodeBoolForKey:@"stealthMode"]];
    [[self undoManager] enableUndoRegistration];    
	[self registerNotificationObservers];
    currentORPQModel = self;
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeBool:stealthMode forKey:@"stealthMode"];
    [encoder encodeObject:dataBaseName forKey:@"DataBaseName"];
    [encoder encodeObject:password forKey:@"Password"];
    [encoder encodeObject:userName forKey:@"UserName"];
    [encoder encodeObject:hostName forKey:@"HostName"];
}

#pragma mark ***SQL Access
- (void) testConnection
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];

    if(!stealthMode){
        ORPQQueryOp* anOp = [[ORPQQueryOp alloc] initWithDelegate:self];
        [anOp setCommandType:kPQCommandType_TestConnection];
        [ORPQDBQueue addOperation:anOp];
        [anOp release];
    }
}

- (void) disconnectSql
{
	if(pqConnection){
		[pqConnection disconnect];
		[pqConnection release];
		pqConnection = nil;
        [[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORPQConnectionValidChanged object:self];
	}
}

- (BOOL) connected
{
	return [pqConnection isConnected];
}


- (void) logQueryException:(NSException*)e
{
	NSLogError([e reason],@"SQL",@"Query Problem",nil);
	[pqConnection release];
	pqConnection = nil;
}

@end

@implementation ORPQModel (private)

- (ORPQConnection*) pqConnection
{
	@synchronized(self){
		BOOL oldConnectionValid = [pqConnection isConnected];
		BOOL newConnectionValid = oldConnectionValid;
		if(!pqConnection) pqConnection = [[ORPQConnection alloc] init];
		if(![pqConnection isConnected]){
			newConnectionValid = [pqConnection connectToHost:hostName userName:userName passWord:password dataBase:dataBaseName verbose:NO];
		}
	
		if(newConnectionValid != oldConnectionValid){
			[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORPQConnectionValidChanged object:self];
		}
	}
	return [pqConnection isConnected]?pqConnection:nil;
}


- (void) alarmPosted:(NSNotification*)aNote
{
	if(!stealthMode){
		ORPQPostAlarmOp* anOp = [[ORPQPostAlarmOp alloc] initWithDelegate:self];
		[anOp postAlarm:[aNote object]];
		[ORPQDBQueue addOperation:anOp];
		[anOp release];
	}
}

- (void) alarmCleared:(NSNotification*)aNote
{
	if(!stealthMode){
		ORPQPostAlarmOp* anOp = [[ORPQPostAlarmOp alloc] initWithDelegate:self];
		[anOp clearAlarm:[aNote object]];
		[ORPQDBQueue addOperation:anOp];
		[anOp release];
	}
}
@end

@implementation ORRunState
@end

@implementation ORPQOperation
- (id) initWithDelegate:(id)aDelegate
{
    return [self initWithDelegate:aDelegate object:nil selector:nil];
}

- (id) initWithDelegate:(id)aDelegate object:(id)anObject selector:(SEL)aSelector
{
	self = [super init];
	delegate = aDelegate;
    object = anObject;
    selector = aSelector;
    return self;
}

- (void) dealloc
{
	[super dealloc];
}

@end

@implementation ORPQDetectorDB

- (id) init
{
    self = [super init];
    // this may look a bit odd, but calculating the size like this will account for
    // any padding the compiler may add between the structures
    int len = (int)((PQ_Run *)((PQ_CAEN *)((PQ_MTC *)((PQ_Crate *)((PQ_FEC *)0 + kSnoCardsTotal) + kSnoCrates) + 1) + 1) + 1);
    data = [[[NSMutableData alloc] initWithLength:len] retain];
    return self;
}

- (void) dealloc
{
    [data release];
    pmthvLoaded = fecLoaded = crateLoaded = mtcLoaded = caenLoaded = 0;
    [super dealloc];
}

- (PQ_FEC *) getFEC:(int)aCard crate:(int)aCrate
{
    if (!fecLoaded || aCrate >= kSnoCrates || aCard >= kSnoCardsPerCrate) return nil;
    return (PQ_FEC *)[data mutableBytes] + aCrate * kSnoCardsPerCrate + aCard;
}

- (PQ_FEC *) getPmthv:(int)aCard crate:(int)aCrate
{
    if (!pmthvLoaded || aCrate >= kSnoCrates || aCard >= kSnoCardsPerCrate) return nil;
    return (PQ_FEC *)[data mutableBytes] + aCrate * kSnoCardsPerCrate + aCard;
}

- (PQ_Crate *) getCrate:(int)aCrate
{
    if (!crateLoaded || aCrate >= kSnoCrates) return nil;
    return (PQ_Crate *)((PQ_FEC *)[data mutableBytes] + kSnoCardsTotal) + aCrate;
}

- (PQ_MTC *) getMTC
{
    if (!mtcLoaded) return nil;
    return (PQ_MTC *)((PQ_Crate *)((PQ_FEC *)[data mutableBytes] + kSnoCardsTotal) + kSnoCrates);
}

- (PQ_CAEN *) getCAEN
{
    if (!caenLoaded) return nil;
    return (PQ_CAEN *)((PQ_MTC *)((PQ_Crate *)((PQ_FEC *)[data mutableBytes] + kSnoCardsTotal) + kSnoCrates) + 1);
}

- (PQ_Run *) getRun
{
    if (!runLoaded) return nil;
    return (PQ_Run *)((PQ_CAEN *)((PQ_MTC *)((PQ_Crate *)((PQ_FEC *)[data mutableBytes] + kSnoCardsTotal) + kSnoCrates) + 1) + 1);
}

@end

@implementation ORPQQueryOp
- (void) dealloc
{
    [command release];
    [super dealloc];
}

- (void) setCommand:(NSString*)aCommand;
{
    [command autorelease];
    command = [aCommand copy];
}

- (void) setCommandType:(int)aCommandType;
{
    commandType = aCommandType;
}

- (void) _detectorDbCallback:(ORPQDetectorDB *)detDB
{
    @try {
        // inform everyone that our detector state has changed
        if (detDB) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ORPQDetectorStateChanged object:detDB];
        }
    }
    @catch(NSException* e){
        NSLogColor([NSColor redColor],@"Exception caught! (problem updating ORCA GUI)\n");
    }
    @finally {
        // finally do our callback
        if (![self isCancelled] && selector) {
            [object performSelector:selector withObject:detDB];
            selector = nil;
        }
    }
}

- (void) cancel
{
    [super cancel];
    if (selector) {
        // do callback with nil object
        [object performSelectorOnMainThread:selector withObject:nil waitUntilDone:YES];
        selector = nil;
    }
}

// load and parse the full detector database from the PostgreSQL server
- (ORPQDetectorDB *) loadDetectorDB: (ORPQConnection *)pqConnection
{
    int countBadNhit100Enabled = 0;
    int countBadNhit20Enabled = 0;
    int countBadSequencerEnabled = 0;
    int countBadThresholdNotMax = 0;
//
// load PMT HV database
//
    [command autorelease];
    // column:    0     1    2       3
    char *cols = "crate,card,channel,pmthv";
    command = [[NSString stringWithFormat: @"SELECT %s FROM pmtdb",cols] retain];
    ORPQResult *theResult;
    @try {
        theResult = [pqConnection queryString:command];
    }
    @catch (NSException* e) {
        theResult = nil;
    }
    if ([self isCancelled]) return nil;
    ORPQDetectorDB *detDB = [[[ORPQDetectorDB alloc] init] autorelease];
    if (theResult) {
        int numRows = [theResult numOfRows];
        int numCols = [theResult numOfFields];
        if (numCols != 4) {
            NSLog(@"Expected %d columns from PMT HV database, but got %d\n", 4, numCols);
            numRows = 0;
        }
        detDB->pmthvLoaded = numRows;
        for (int i=0; i<numRows; ++i) {
            int64_t val = [theResult getInt64atRow:i column:3];
            if (val == kPQBadValue) continue;
            unsigned crate   = [theResult getInt64atRow:i column:0];
            unsigned card    = [theResult getInt64atRow:i column:1];
            unsigned channel = [theResult getInt64atRow:i column:2];
            if (crate < kSnoCrates && card < kSnoCardsPerCrate && channel < kSnoChannelsPerCard) {
                PQ_FEC *pqFEC = [detDB getPmthv:card crate:crate];
                pqFEC->valid[kFEC_hvDisabled] |= (1 << channel);
                if (val == 1) pqFEC->hvDisabled |= (1 << channel);
            }
        }
    }
//
// load FEC database
//
    [command autorelease];
    // (funny, but tcmos_tacshift=tac0trim and scmos=tac1trim)
    //      0     1    2          3           4         5          6          7      8      9              10    11   12            13           14          15        16        17        18         19           20          21          22   23    24   25   26
    cols = "crate,slot,tr100_mask,tr100_delay,tr20_mask,tr20_width,tr20_delay,vbal_0,vbal_1,tcmos_tacshift,scmos,vthr,pedestal_mask,disable_mask,tdisc_rmpup,tdisc_rmp,tdisc_vsi,tdisc_vli,tcmos_vmax,tcmos_tacref,tcmos_isetm,tcmos_iseta,vint,hvref,mbid,dbid,pmticid";
    command = [[NSString stringWithFormat: @"SELECT %s FROM current_detector_state",cols] retain];
    @try {
        theResult = [pqConnection queryString:command];
    }
    @catch (NSException* e) {
        theResult = nil;
    }
    if ([self isCancelled]) return nil;
    if (theResult) {
        int numRows = [theResult numOfRows];
        int numCols = [theResult numOfFields];
        if (numCols != kFEC_numDbColumns) {
            NSLog(@"Expected %d columns from detector database, but got %d\n", kFEC_numDbColumns, numCols);
            numRows = 0;
        }
        detDB->fecLoaded = numRows;
        for (int i=0; i<numRows; ++i) {
            unsigned crate = [theResult getInt64atRow:i column:0];
            unsigned card  = [theResult getInt64atRow:i column:1];
            if (crate >= kSnoCrates || card >= kSnoCardsPerCrate) continue;
            PQ_FEC *pqFEC = [detDB getFEC:card crate:crate];
            // set flag indicating that the card exists in the current detector state
            pqFEC->valid[kFEC_exists] = 1;
            for (int col=2; col<kFEC_numDbColumns; ++col) {
                NSMutableData *dat = [theResult getInt64arrayAtRow:i column:col];
                if (!dat) continue;
                int n = [dat length] / sizeof(int64_t);
                if (n > kSnoChannelsPerCard) n = kSnoChannelsPerCard;
                int64_t *valPt = (int64_t *)[dat mutableBytes];
                for (int ch=0; ch<n; ++ch) {
                    // ignore bad values (includes NULL values)
                    if (valPt[ch] == kPQBadValue) continue;
                    uint32_t val = (uint32_t)valPt[ch];
                    // set valid flag for this setting for this channel
                    pqFEC->valid[col] |= (1 << ch);
                    switch (col) {
                        case kFEC_nhit100enabled:
                            if (val) {
                                pqFEC->nhit100enabled |= (1 << ch);
                                if (pqFEC->valid[kFEC_hvDisabled] & pqFEC->hvDisabled & (1 << ch)) ++countBadNhit100Enabled;
                            }
                            break;
                        case kFEC_nhit100delay:
                            pqFEC->nhit100delay[ch] = val;
                            break;
                        case kFEC_nhit20enabled:
                            if (val) {
                                pqFEC->nhit20enabled |= (1 << ch);
                                if (pqFEC->valid[kFEC_hvDisabled] & pqFEC->hvDisabled & (1 << ch)) ++countBadNhit20Enabled;
                            }
                            break;
                        case kFEC_nhit20width:
                            pqFEC->nhit20width[ch] = val;
                            break;
                        case kFEC_nhit20delay:
                            pqFEC->nhit20delay[ch] = val;
                            break;
                        case kFEC_vbal0:
                            pqFEC->vbal0[ch] = val;
                            break;
                        case kFEC_vbal1:
                            pqFEC->vbal1[ch] = val;
                            break;
                        case kFEC_tac0trim:
                            pqFEC->tac0trim[ch] = val;
                            break;
                        case kFEC_tac1trim:
                            pqFEC->tac1trim[ch] = val;
                            break;
                        case kFEC_vthr:
                            pqFEC->vthr[ch] = val;
                            if ((pqFEC->valid[kFEC_hvDisabled] & pqFEC->hvDisabled & (1 << ch)) && (val != 255)) {
                                ++countBadThresholdNotMax;
                            }
                            break;
                        case kFEC_pedEnabled:
                            pqFEC->pedEnabled = val;
                            pqFEC->valid[col] = 0xffffffff;
                            break;
                        case kFEC_seqDisabled: {
                            pqFEC->seqDisabled = val;
                            pqFEC->valid[col] = 0xffffffff;
                            uint32_t bad = pqFEC->valid[kFEC_hvDisabled] & (pqFEC->hvDisabled & ~val);
                            if (bad) {
                                for (int i=0; i<32; ++i) {
                                    if (bad & (1 << i)) ++countBadSequencerEnabled;
                                }
                            }
                        }   break;
                        case kFEC_tdiscRp1:
                            if (ch < kNumFecTdisc) pqFEC->tdiscRp1[ch] = val;
                            break;
                        case kFEC_tdiscRp2:
                            if (ch < kNumFecTdisc) pqFEC->tdiscRp2[ch] = val;
                            break;
                        case kFEC_tdiscVsi:
                            if (ch < kNumFecTdisc) pqFEC->tdiscVsi[ch] = val;
                            break;
                        case kFEC_tdiscVli:
                            if (ch < kNumFecTdisc) pqFEC->tdiscVli[ch] = val;
                            break;
                        case kFEC_tcmosVmax:
                            pqFEC->tcmosVmax = val;
                            break;
                        case kFEC_tcmosTacref:
                            pqFEC->tcmosTacref = val;
                            break;
                        case kFEC_tcmosIsetm:
                            if (ch < kNumFecIset) pqFEC->tcmosIsetm[ch] = val;
                            break;
                        case kFEC_tcmosIseta:
                            if (ch < kNumFecIset) pqFEC->tcmosIseta[ch] = val;
                            break;
                        case kFEC_vres:
                            pqFEC->vres = val;
                            break;
                        case kFEC_hvref:
                            pqFEC->hvref = val;
                            break;
                        case kFEC_mbid:
                            pqFEC->mbid = val;
                            break;
                        case kFEC_dbid:
                            if (ch < kNumDbPerFec) pqFEC->dbid[ch] = val;
                            break;
                        case kFEC_pmticid:
                            pqFEC->pmticid = val;
                            break;
                    }
                }
            }
        }
    }
//
// load Crate database
//
    [command autorelease];
    cols = "crate,ctc_delay,hv_relay_mask1,hv_relay_mask2,hv_a_on,hv_b_on,hv_dac_a,hv_dac_b,xl3_readout_mask,xl3_mode";
    command = [[NSString stringWithFormat: @"SELECT %s FROM current_crate_state",cols] retain];
    @try {
        theResult = [pqConnection queryString:command];
    }
    @catch (NSException* e) {
        theResult = nil;
    }
    if ([self isCancelled]) return nil;
    if (theResult) {
        int numRows = [theResult numOfRows];
        int numCols = [theResult numOfFields];
        if (numCols != kCrate_numDbColumns) {
            NSLog(@"Expected %d columns from crate database, but got %d\n", kCrate_numDbColumns, numCols);
            numRows = 0;
        }
        detDB->crateLoaded = numRows;
        for (int i=0; i<numRows; ++i) {
            unsigned crate = [theResult getInt64atRow:i column:0];
            if (crate >= kSnoCrates) continue;
            PQ_Crate *pqCrate = [detDB getCrate:crate];
            // set flag indicating that the crate exists in the current detector state
            pqCrate->valid[kCrate_exists] = pqCrate->exists = 1;
            for (int col=1; col<kCrate_numDbColumns; ++col) {
                NSMutableData *dat = [theResult getInt64arrayAtRow:i column:col];
                if (!dat || [dat length] < sizeof(int64_t)) continue;
                int64_t *valPt = (int64_t *)[dat mutableBytes];
                if (*valPt == kPQBadValue) continue;
                uint32_t val = (uint32_t)*valPt;
                pqCrate->valid[col] = 1;   // set valid flag for this setting
                switch (col) {
                    case kCrate_ctcDelay:
                        pqCrate->ctcDelay = val;
                        break;
                    case kCrate_hvRelayMask1:
                        pqCrate->hvRelayMask1 = val;
                        pqCrate->valid[col] = 0xffffffff;
                        break;
                    case kCrate_hvRelayMask2:
                        pqCrate->hvRelayMask2 = val;
                        pqCrate->valid[col] = 0xffffffff;
                        break;
                    case kCrate_hvAOn:
                        pqCrate->hvAOn = val;
                        break;
                    case kCrate_hvBOn:
                        pqCrate->hvBOn = val;
                        break;
                    case kCrate_hvDacA:
                        pqCrate->hvDacA = val;
                        break;
                    case kCrate_hvDacB:
                        pqCrate->hvDacB = val;
                        break;
                    case kCrate_xl3ReadoutMask:
                        pqCrate->xl3ReadoutMask = val;
                        pqCrate->valid[col] = 0xffffffff;
                        break;
                    case kCrate_xl3Mode:
                        pqCrate->xl3Mode = val;
                        break;
                }
            }
        }
    }
//
// load MTC database
//
    [command autorelease];
    cols = "control_register,mtca_dacs,pedestal_width,coarse_delay,fine_delay,pedestal_mask,prescale,lockout_width,gt_mask,gt_crate_mask,mtca_relays,pulser_rate";
    command = [[NSString stringWithFormat: @"SELECT %s FROM mtc WHERE key = (SELECT mtc FROM run_state WHERE run = 0)",cols] retain];
    @try {
        theResult = [pqConnection queryString:command];
    }
    @catch (NSException* e) {
        theResult = nil;
    }
    if ([self isCancelled]) return nil;
    if (theResult) {
        int numRows = [theResult numOfRows];
        int numCols = [theResult numOfFields];
        if (numCols != kMTC_numDbColumns) {
            NSLog(@"Expected %d columns from MTC database, but got %d\n", kMTC_numDbColumns, numCols);
        } else if (numRows) {
            detDB->mtcLoaded = 1;
            PQ_MTC *pqMTC = [detDB getMTC];
            for (int col=0; col<kMTC_numDbColumns; ++col) {
                NSMutableData *dat = [theResult getInt64arrayAtRow:0 column:col];
                if (!dat) continue;
                int n = [dat length] / sizeof(int64_t);
                if (col == kMTC_mtcaDacs) {
                    if (n > kNumMtcDacs) n = kNumMtcDacs;
                } else if (col == kMTC_mtcaRelays) {
                    if (n > kNumMtcRelays) n = kNumMtcRelays;
                } else {
                    if (n > 1) n = 1;
                }
                for (int j=0; j<n; ++j) {
                    int64_t *valPt = (int64_t *)[dat mutableBytes];
                    if (valPt[j] == kPQBadValue) continue;
                    pqMTC->valid[col] |= (1 << j);    // set valid flag
                    uint32_t val = (uint32_t)valPt[j];
                    switch (col) {
                        case kMTC_controlReg:
                            pqMTC->controlReg = val;
                            break;
                        case kMTC_mtcaDacs:
                            pqMTC->mtcaDacs[j] = val;
                            break;
                        case kMTC_pedWidth:
                            pqMTC->pedWidth = val;
                            break;
                        case kMTC_coarseDelay:
                            pqMTC->coarseDelay = val;
                            break;
                        case kMTC_fineDelay:
                            pqMTC->fineDelay = val;
                            break;
                        case kMTC_pedMask:
                            pqMTC->pedMask = val;
                            pqMTC->valid[kMTC_pedMask] = 0xffffffff;
                            break;
                        case kMTC_prescale:
                            pqMTC->prescale = val;
                            break;
                        case kMTC_lockoutWidth:
                            pqMTC->lockoutWidth = val;
                            break;
                        case kMTC_gtMask:
                            pqMTC->gtMask = val;
                            pqMTC->valid[kMTC_gtMask] = 0xffffffff;
                            break;
                        case kMTC_gtCrateMask:
                            pqMTC->gtCrateMask = val;
                            pqMTC->valid[kMTC_gtCrateMask] = 0xffffffff;
                            break;
                        case kMTC_mtcaRelays:
                            pqMTC->mtcaRelays[j] = val;
                            break;
                        case kMTC_pulserRate:
                            pqMTC->pulserRate = val;
                            break;
                    }
                }
            }
        }
    }
//
// load CAEN database
//
    [command autorelease];
    cols = "channel_configuration,buffer_organization,custom_size,acquisition_control,trigger_mask,trigger_out_mask,post_trigger,front_panel_io_control,channel_mask,channel_dacs";
    command = [[NSString stringWithFormat: @"SELECT %s FROM caen WHERE key = (SELECT caen FROM run_state WHERE run = 0)",cols] retain];
    @try {
        theResult = [pqConnection queryString:command];
    }
    @catch (NSException* e) {
        theResult = nil;
    }
    if ([self isCancelled]) return nil;
    if (theResult) {
        int numRows = [theResult numOfRows];
        int numCols = [theResult numOfFields];
        if (numCols != kCAEN_numDbColumns) {
            NSLog(@"Expected %d columns from CAEN database, but got %d\n", kCAEN_numDbColumns, numCols);
        } else if (numRows) {
            detDB->caenLoaded = 1;
            PQ_CAEN *pqCAEN = [detDB getCAEN];
            for (int col=0; col<kCAEN_numDbColumns; ++col) {
                NSMutableData *dat = [theResult getInt64arrayAtRow:0 column:col];
                if (!dat) continue;
                int n = [dat length] / sizeof(int64_t);
                if (col == kCAEN_channelDacs) {
                    if (n > kNumCaenChannelDacs) n = kNumCaenChannelDacs;
                } else {
                    if (n > 1) n = 1;
                }
                for (int j=0; j<n; ++j) {
                    int64_t *valPt = (int64_t *)[dat mutableBytes];
                    if (valPt[j] == kPQBadValue) continue;
                    pqCAEN->valid[col] |= (1 << j);    // set valid flag
                    uint32_t val = (uint32_t)valPt[j];
                    switch (col) {
                        case kCAEN_channelConfiguration:
                            pqCAEN->channelConfiguration = val;
                            break;
                        case kCAEN_bufferOrganization:
                            pqCAEN->bufferOrganization = val;
                            break;
                        case kCAEN_customSize:
                            pqCAEN->customSize = val;
                            break;
                        case kCAEN_acquisitionControl:
                            pqCAEN->acquisitionControl = val;
                            break;
                        case kCAEN_triggerMask:
                            pqCAEN->triggerMask = val;
                            pqCAEN->valid[kCAEN_triggerMask] = 0xffffffff;
                            break;
                        case kCAEN_triggerOutMask:
                            pqCAEN->triggerOutMask = val;
                            pqCAEN->valid[kCAEN_triggerOutMask] = 0xffffffff;
                            break;
                        case kCAEN_postTrigger:
                            pqCAEN->postTrigger = val;
                            break;
                        case kCAEN_frontPanelIoControl:
                            pqCAEN->frontPanelIoControl = val;
                            break;
                        case kCAEN_channelMask:
                            pqCAEN->channelMask = val;
                            pqCAEN->valid[kCAEN_channelMask] = 0xffffffff;
                            break;
                        case kCAEN_channelDacs:
                            pqCAEN->channelDacs[j] = val;
                            break;
                    }
                }
            }
        }
    }
//
// load run state
//
    [command autorelease];
    command = [[NSString stringWithFormat: @"SELECT run_type,timestamp,end_timestamp FROM run_state WHERE run=(SELECT last_value FROM run_number)"] retain];
    @try {
        theResult = [pqConnection queryString:command];
    }
    @catch (NSException* e) {
        theResult = nil;
    }
    if ([self isCancelled]) return nil;
    if (theResult) {
        int numRows = [theResult numOfRows];
        int numCols = [theResult numOfFields];
        if (numRows != 1 || numCols != 3) {
            NSLogColor([NSColor redColor], @"Error getting run state from database\n");
        } else {
            detDB->runLoaded = 1;
            PQ_Run *pqRun = [detDB getRun];
            int64_t run_type = [theResult getInt64atRow:0 column:0];
            // (don't try to set run state unless run type is valid)
            if (run_type != kPQBadValue) {
                pqRun->runType = run_type;
                pqRun->valid[kRun_runType] = 1;
                pqRun->runStartTime = [theResult getDateAtRow:0 column:1];
                if (pqRun->runStartTime) pqRun->valid[kRun_runStartTime] = 1;
                pqRun->runInProgress = [theResult isNullAtRow:0 column:2];
                pqRun->valid[kRun_runInProgress] = 1;
            }
        }
    }
//
// load run number
//
    [command autorelease];
    command = [[NSString stringWithFormat: @"SELECT last_value FROM run_number"] retain];
    @try {
        theResult = [pqConnection queryString:command];
    }
    @catch (NSException* e) {
        theResult = nil;
    }
    if ([self isCancelled]) return nil;
    if (theResult) {
        int numRows = [theResult numOfRows];
        int numCols = [theResult numOfFields];
        if (numRows != 1 || numCols != 1) {
            NSLogColor([NSColor redColor], @"Error getting run number from database\n");
        } else {
            detDB->runLoaded = 1;
            PQ_Run *pqRun = [detDB getRun];
            int64_t run_number = [theResult getInt64atRow:0 column:0];
            if (run_number != kPQBadValue) {
                pqRun->runNumber = run_number;
                pqRun->valid[kRun_runNumber] = 1;
            }
        }
    }
    // all done
    if (detDB->pmthvLoaded || detDB->fecLoaded || detDB->crateLoaded ||
        detDB->mtcLoaded || detDB->caenLoaded)
    {
        NSLog(@"Loaded %@ DB: PMTHV(%d), FEC(%d), Crate(%d), MTC(%d), CAEN(%d)\n", [delegate dataBaseName],
              detDB->pmthvLoaded, detDB->fecLoaded, detDB->crateLoaded, detDB->mtcLoaded, detDB->caenLoaded);
        if (countBadNhit100Enabled || countBadNhit20Enabled) {
            NSLogColor([NSColor redColor], @"Warning!  Some bad channels have triggers enabled:\n");
            if (countBadNhit100Enabled) NSLogColor([NSColor redColor], @"  - %d bad channels with NHIT100 enabled\n", countBadNhit100Enabled);
            if (countBadNhit20Enabled)  NSLogColor([NSColor redColor], @"  - %d bad channels with NHIT20 enabled\n", countBadNhit20Enabled);
        } else if (countBadSequencerEnabled || countBadThresholdNotMax) {
            NSLog(@"Note!  Some bad channels are enabled:\n");
        }
        if (countBadSequencerEnabled) NSLog(@"  - %d bad channels with sequencer enabled\n", countBadSequencerEnabled);
        if (countBadThresholdNotMax)  NSLog(@"  - %d bad channels with threshold not set to max\n", countBadThresholdNotMax);
        return detDB;
    } else {
        [detDB release];
        NSLogColor([NSColor redColor], @"Error loading %@ DB!\n", [delegate dataBaseName]);
        return nil;
    }
}

- (void) main
{
    ORPQResult *theResult;

    if([self isCancelled]) return;

    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
    NSObject *theResultObject = nil;
    BOOL isConnected = NO;

    @try {
        if (commandType == kPQCommandType_TestConnection) {
            [delegate disconnectSql];   // disconnect then reconnect to test the connection
        }
        ORPQConnection* pqConnection = [[delegate pqConnection] retain];
        if([pqConnection isConnected] && ![self isCancelled]){

            switch (commandType) {

                case kPQCommandType_General:
                    theResult = [pqConnection queryString:command];
                    if (theResult && ![self isCancelled]) {
                        theResultObject = theResult;
                    }
                    break;

                case kPQCommandType_GetDetectorDB:
                    theResultObject = [self loadDetectorDB:pqConnection];
                    break;

                case kPQCommandType_TestConnection:
                    NSLog(@"PostgreSQL connected to %@ DB on %@\n", [delegate dataBaseName], [delegate hostName]);
                    [delegate detectorDbQuery:NULL selector:NULL];
                    isConnected = YES;
                    break;
            }
        }
        [pqConnection release];
    }
    @catch(NSException* e){
        if (![self isCancelled]) {
            [delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
        }
    }
    @finally {
        // do callback on main thread if a selector was specified
        if (![self isCancelled]) {
            if (commandType == kPQCommandType_GetDetectorDB) {
                [self performSelectorOnMainThread:@selector(_detectorDbCallback:) withObject:theResultObject waitUntilDone:YES];
            } else if (commandType == kPQCommandType_TestConnection && !isConnected) {
                NSLogColor([NSColor redColor], @"PostgreSQL ERROR connecting to %@ DB on %@\n", [delegate dataBaseName], [delegate hostName]);
            } else if (selector) {
                [object performSelectorOnMainThread:selector withObject:theResultObject waitUntilDone:YES];
                selector = nil;
            }
        }
        [thePool release];
    }
}
@end

@implementation ORPQPostAlarmOp
- (void) dealloc
{
	[alarm release];
	[super dealloc];
}

- (void) postAlarm:(id)anAlarm
{
	[anAlarm retain];
	[alarm release];
	alarm = anAlarm;
	opType = kPost;
}

- (void) clearAlarm:(id)anAlarm
{
	[anAlarm retain];
	[alarm release];
	alarm = anAlarm;
	opType = kClear;
}

// extract alarm number from hex alarm id embedded inside alarm name
// (must be called from inside an auto release pool to handle memory allocated by cStringUsingEncoding)
static int getAlarmNumber(id alarm)
{
    int alarmNum = 0;
    const char *name = [[alarm name] cStringUsingEncoding:NSUTF8StringEncoding];
    // look for alarm number inside brackets in alarm name
    const char *pt = strstr(name, "(");
    if (pt) {
        while (*(++pt)) {
            if ((*pt >= '0') && (*pt <= '9')) {
                alarmNum = (alarmNum * 10) + (*pt - '0');
            } else {
                break;
            }
        }
        if ((*pt != ')') || (alarmNum < kOrcaAlarmMin) || (alarmNum > kOrcaAlarmMax)) alarmNum = 0;
    }
    return alarmNum;
}

- (void) main
{
    if([self isCancelled])return;
    NSAutoreleasePool* thePool = [[NSAutoreleasePool alloc] init];
	@try {
        int alarmNum = getAlarmNumber(alarm);
        if (!alarmNum) {
            // this is a regular ORCA alarm, so just count the number of regular alarms posted
            NSEnumerator* e = [[ORAlarmCollection sharedAlarmCollection] alarmEnumerator];
            id anAlarm;
            int numRegularOrcaAlarms = 0;
            while (anAlarm = [e nextObject]){
                if (getAlarmNumber(anAlarm) > 0) ++numRegularOrcaAlarms;
            }
            // so post/clear a generic ORCA alarm if necessary
            if ((numRegularOrcaAlarms && opType == kPost) || (!numRegularOrcaAlarms && opType == kClear)) {
                alarmNum = kPQAlarm_OrcaAlarmActive;
            }
        }
        if (alarmNum) {
            char *type = (opType==kPost) ? "post" : "clear";
            ORPQConnection* pqConnection = [[delegate pqConnection] retain];
            if([pqConnection isConnected]){
                // post or clear the alarm
                [pqConnection queryString:[NSString stringWithFormat:@"SELECT * FROM %s_alarm(%d)",type,kPQAlarm_OrcaAlarmActive]];
                [pqConnection release];
            }
        }
	}
	@catch(NSException* e){
		[delegate performSelectorOnMainThread:@selector(logQueryException:) withObject:e waitUntilDone:YES];
	}
    @finally {
        [thePool release];
    }
}
@end

