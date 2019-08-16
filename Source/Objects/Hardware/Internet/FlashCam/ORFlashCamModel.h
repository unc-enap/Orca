#pragma mark ***Imported Files

#define kMaxFlashCamChannels 6

@class ORTaskSequence;
@class ORPingTask;

@interface ORFlashCamModel : OrcaObject
{
    NSString* ipAddress;
    NSString* username;
    NSString* ethInterface;
    NSString* ethType;
    unsigned int boardAddress;
    unsigned int traceType;
    unsigned int signalDepth;
    unsigned int postTrigger;
    unsigned int baselineOffset;
    int baselineBias;
    NSString* remoteDataPath;
    NSString* remoteFilename;
    unsigned int runNumber;
    unsigned int runCount;
    unsigned int runLength;
    bool runUpdate;
    bool chanEnabled[kMaxFlashCamChannels];
    unsigned int threshold[kMaxFlashCamChannels];
    unsigned int poleZero[kMaxFlashCamChannels];
    unsigned int shapeTime[kMaxFlashCamChannels];
    ORPingTask* pingTask;
    bool pingSuccess;
    ORTaskSequence* runTasks;
    bool runKilled;
}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;

#pragma mark ***Accessors
- (NSString*) ipAddress;
- (NSString*) ethInterface;
- (NSString*) ethType;
- (NSString*) username;
- (unsigned int) boardAddress;
- (unsigned int) traceType;
- (unsigned int) signalDepth;
- (unsigned int) postTrigger;
- (unsigned int) baselineOffset;
- (int) baselineBias;
- (NSString*) remoteDataPath;
- (NSString*) remoteFilename;
- (unsigned int) runNumber;
- (unsigned int) runCount;
- (unsigned int) runLength;
- (bool) runUpdate;
- (bool) chanEnabled:(unsigned int)chan;
- (unsigned int) threshold:(unsigned int)chan;
- (unsigned int) poleZero:(unsigned int)chan;
- (unsigned int) shapeTime:(unsigned int)chan;
- (bool) pingSuccess;
- (void) setIPAddress:(NSString*)ip;
- (void) setUsername:(NSString*)user;
- (void) setEthInterface:(NSString*)eth;
- (void) setEthType:(NSString*)etype;
- (void) setBoardAddress:(unsigned int)address;
- (void) setTraceType:(unsigned int)ttype;
- (void) setSignalDepth:(unsigned int)sdepth;
- (void) setPostTrigger:(unsigned int)ptrigger;
- (void) setBaselineOffset:(unsigned int)boffset;
- (void) setBaselineBias:(int)bbias;
- (void) setRemoteDataPath:(NSString*)path;
- (void) setRemoteFilename:(NSString*)fname;
- (void) setRunNumber:(unsigned int)run;
- (void) setRunCount:(unsigned int)count;
- (void) setRunLength:(unsigned int)length;
- (void) setRunUpdate:(bool)update;
- (void) setChanEnabled:(unsigned int)chan withValue:(bool)enabled;
- (void) setThreshold:(unsigned int)chan withValue:(unsigned int)thresh;
- (void) setPoleZero:(unsigned int)chan withValue:(unsigned int)pz;
- (void) setShapeTime:(unsigned int)chan withValue:(unsigned int)st;

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;

#pragma mark ***Commands
- (void) sendPing:(bool)verbose;
- (bool) pingRunning;
- (void) taskFinished:(id)task;
- (void) tasksCompleted:(id)sender;
- (void) taskData:(NSDictionary*)taskData;
- (void) startRun;
- (void) startRunAfterPing;
- (void) killRun;

@end

extern NSString* ORFlashCamModelIPAddressChanged;
extern NSString* ORFlashCamModelUsernameChanged;
extern NSString* ORFlashCamModelEthInterfaceChanged;
extern NSString* ORFlashCamModelEthTypeChanged;
extern NSString* ORFlashCamModelBoardAddressChanged;
extern NSString* ORFlashCamModelTraceTypeChanged;
extern NSString* ORFlashCamModelSignalDepthChanged;
extern NSString* ORFlashCamModelPostTriggerChanged;
extern NSString* ORFlashCamModelBaselineOffsetChanged;
extern NSString* ORFlashCamModelBaselineBiasChanged;
extern NSString* ORFlashCamModelRemoteDataPathChanged;
extern NSString* ORFlashCamModelRemoteFilenameChanged;
extern NSString* ORFlashCamModelRunNumberChanged;
extern NSString* ORFlashCamModelRunCountChanged;
extern NSString* ORFlashCamModelRunLengthChanged;
extern NSString* ORFlashCamModelRunUpdateChanged;
extern NSString* ORFlashCamModelChanEnabledChanged;
extern NSString* ORFlashCamModelThresholdChanged;
extern NSString* ORFlashCamModelPoleZeroChanged;
extern NSString* ORFlashCamModelShapeTimeChanged;
extern NSString* ORFlashCamModelPingStart;
extern NSString* ORFlashCamModelPingEnd;
extern NSString* ORFlashCamModelRunInProgress;
extern NSString* ORFlashCamModelRunEnded;
