#pragma mark ***Imported Files
#import "ORFlashCamModel.h"
#import "ORTaskSequence.h"

NSString* ORFlashCamModelIPAddressChanged      = @"ORFlashCamModelIPAddressChanged";
NSString* ORFlashCamModelUsernameChanged       = @"ORFlashCamModelUsernameChanged";
NSString* ORFlashCamModelEthInterfaceChanged   = @"ORFlashCamModelEthInterfaceChanged";
NSString* ORFlashCamModelEthTypeChanged        = @"ORFlashCamModelEthTypeChanged";
NSString* ORFlashCamModelBoardAddressChanged   = @"ORFlashCamModelBoardAddressChanged";
NSString* ORFlashCamModelTraceTypeChanged      = @"ORFlashCamModelTraceTypeChanged";
NSString* ORFlashCamModelSignalDepthChanged    = @"ORFlashCamModelSignalDepthChanged";
NSString* ORFlashCamModelPostTriggerChanged    = @"ORFlashCamModelPostTriggerChanged";
NSString* ORFlashCamModelBaselineOffsetChanged = @"ORFlashCamModelBaselineOffsetChanged";
NSString* ORFlashCamModelBaselineBiasChanged   = @"ORFlashCamModelBaselineBiasChanged";
NSString* ORFlashCamModelRemoteDataPathChanged = @"ORFlashCamModelRemoteDataPathChanged";
NSString* ORFlashCamModelRemoteFilenameChanged = @"ORFlashCamModelRemoteFilenameChanged";
NSString* ORFlashCamModelRunNumberChanged      = @"ORFlashCamModelRunNumberChanged";
NSString* ORFlashCamModelRunCountChanged       = @"ORFlashCamModelRunCountChanged";
NSString* ORFlashCamModelRunLengthChanged      = @"ORFlashCamModelRunLengthChanged";
NSString* ORFlashCamModelRunUpdateChanged      = @"ORFlashCamModelRunUpdateChanged";
NSString* ORFlashCamModelChanEnabledChanged    = @"ORFlashCamModelChanEnabledChanged";
NSString* ORFlashCamModelThresholdChanged      = @"ORFlashCamModelThresholdChanged";
NSString* ORFlashCamModelPoleZeroChanged       = @"ORFlashCamModelPoleZeroChanged";
NSString* ORFlashCamModelShapeTimeChanged      = @"ORFlashCamModelShapeTimeChanged";
NSString* ORFlashCamModelPingStart             = @"ORFlashCamModelPingStart";
NSString* ORFlashCamModelPingEnd               = @"ORFlashCamModelPingEnd";
NSString* ORFlashCamModelRunInProgress         = @"ORFlashCamModelRunInProgress";
NSString* ORFlashCamModelRunEnded              = @"ORFlashCamModelRunEnded";

@implementation ORFlashCamModel

- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setIPAddress:@""];
    [self setUsername:@""];
    [self setEthInterface:@""];
    [self setEthType:@""];
    [self setBoardAddress:10];
    [self setTraceType:0];
    [self setSignalDepth:2048];
    [self setPostTrigger:0];
    [self setBaselineOffset:500];
    [self setBaselineBias:0];
    [self setRemoteDataPath:@""];
    [self setRemoteFilename:@""];
    [self setRunNumber:0];
    [self setRunCount:1];
    [self setRunLength:600];
    [self setRunUpdate:YES];
    for(int i=0; i<kMaxFlashCamChannels; i++){
        [self setChanEnabled:i withValue:NO];
        [self setThreshold:i withValue:5000];
        [self setPoleZero:i withValue:58000];
        [self setShapeTime:i withValue:5000];
    }
    pingTask = nil;
    pingSuccess = NO;
    runTasks = nil;
    runKilled = NO;
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) dealloc
{
    [ipAddress release];
    [username release];
    [ethInterface release];
    [ethType release];
    [remoteDataPath release];
    [remoteFilename release];
    if(pingTask) [pingTask release];
    if(runTasks) [runTasks release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) wakeUp
{
    if([self aWake]) return;
    [super wakeUp];
}

- (void) sleep
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super sleep];
}

#pragma mark ***Initialization
- (void) makeMainController
{
    [self linkToController:@"ORFlashCamController"];
}

- (void) setUpImage
{
    NSImage* cimage = [NSImage imageNamed:@"flashcam.png"];
    NSSize size = [cimage size];
    NSSize newsize;
    newsize.width  = 0.4*size.width;
    newsize.height = 0.4*size.height;
    NSImage* image = [[NSImage alloc] initWithSize:newsize];
    [image lockFocus];
    NSRect rect;
    rect.origin = NSZeroPoint;
    rect.size.width = newsize.width;
    rect.size.height = newsize.height;
    [cimage drawInRect:rect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [image unlockFocus];
    [self setImage:image];
}

#pragma mark ***Accessors
- (NSString*) ipAddress
{
    if(!ipAddress) return @"";
    return ipAddress;
}

- (NSString*) username
{
    if(!username) return @"";
    return username;
}

- (NSString*) ethInterface
{
    if(!ethInterface) return @"";
    return ethInterface;
}

- (NSString*) ethType
{
    if(!ethType) return @"";
    return ethType;
}

- (unsigned int) boardAddress
{
    return boardAddress;
}

- (unsigned int) traceType
{
    return traceType;
}

- (unsigned int) signalDepth
{
    return signalDepth;
}

- (unsigned int) postTrigger
{
    return postTrigger;
}

- (unsigned int) baselineOffset
{
    return baselineOffset;
}

- (int) baselineBias
{
    return baselineBias;
}

- (NSString*) remoteDataPath
{
    if(!remoteDataPath) return @"";
    return remoteDataPath;
}

- (NSString*) remoteFilename
{
    if(!remoteFilename) return @"";
    return remoteFilename;
}

- (unsigned int) runNumber
{
    return runNumber;
}

- (unsigned int) runCount
{
    return runCount;
}

- (unsigned int) runLength
{
    return runLength;
}

- (bool) runUpdate
{
    return runUpdate;
}

- (bool) chanEnabled:(unsigned int)chan
{
    if(chan >= kMaxFlashCamChannels) return false;
    return chanEnabled[chan];
}

- (unsigned int) threshold:(unsigned int)chan
{
    if(chan >= kMaxFlashCamChannels) return false;
    return threshold[chan];
}

- (unsigned int) poleZero:(unsigned int)chan
{
    if(chan >= kMaxFlashCamChannels) return false;
    return poleZero[chan];
}

- (unsigned int) shapeTime:(unsigned int)chan
{
    if(chan >= kMaxFlashCamChannels) return false;
    return shapeTime[chan];
}

- (bool) pingSuccess
{
    return pingSuccess;
}

- (void) setIPAddress:(NSString*)ip
{
    if(!ip) ip = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIPAddress:[self ipAddress]];
    [ipAddress autorelease];
    ipAddress = [ip copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelIPAddressChanged object:self];
}

- (void) setUsername:(NSString*)user
{
    if(!user) user = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setUsername:[self username]];
    [username autorelease];
    username = [user copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelUsernameChanged object:self];
}

- (void) setEthInterface:(NSString *)eth
{
    if(!eth) eth = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setEthInterface:[self ethInterface]];
    [ethInterface autorelease];
    ethInterface = [eth copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelEthInterfaceChanged object:self];
}

- (void) setEthType:(NSString *)etype
{
    if(!etype) etype = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setEthType:[self ethType]];
    [ethType autorelease];
    ethType = [etype copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelEthTypeChanged object:self];
}

- (void) setBoardAddress:(unsigned int)address
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBoardAddress:boardAddress];
    boardAddress = address;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelBoardAddressChanged object:self];
}

- (void) setTraceType:(unsigned int)ttype
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTraceType:traceType];
    traceType = ttype;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelTraceTypeChanged object:self];
}

- (void) setSignalDepth:(unsigned int)sdepth
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSignalDepth:signalDepth];
    signalDepth = MAX(0, MIN(7000, sdepth));
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelSignalDepthChanged object:self];
}

- (void) setPostTrigger:(unsigned int)ptrigger
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPostTrigger:postTrigger];
    postTrigger = MAX(0, MIN(8000, ptrigger));
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelPostTriggerChanged object:self];
}

- (void) setBaselineOffset:(unsigned int)boffset
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBaselineOffset:baselineOffset];
    baselineOffset = MAX(100, MIN(3900, boffset));
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelBaselineOffsetChanged
                                                        object:self];
}

- (void) setBaselineBias:(int)bbias
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBaselineBias:baselineBias];
    baselineBias = MAX(-2000, MIN(2000, bbias));
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelBaselineBiasChanged
                                                        object:self];
}

- (void) setRemoteDataPath:(NSString*)path
{
    if(!path) path = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setRemoteDataPath:[self remoteDataPath]];
    [remoteDataPath autorelease];
    remoteDataPath = [path copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelRemoteDataPathChanged
                                                        object:self];
}

- (void) setRemoteFilename:(NSString*)fname
{
    if(!fname) fname = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setRemoteFilename:[self remoteFilename]];
    [remoteFilename autorelease];
    remoteFilename = [fname copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelRemoteFilenameChanged
                                                        object:self];
}

- (void) setRunNumber:(unsigned int)run
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunNumber:runNumber];
    runNumber = run;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelRunNumberChanged object:self];
}

- (void) setRunCount:(unsigned int)count
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunCount:runCount];
    runCount = count;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelRunCountChanged object:self];
}

- (void) setRunLength:(unsigned int)length
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunLength:runLength];
    runLength = length;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelRunLengthChanged object:self];
}

- (void) setRunUpdate:(bool)update
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunUpdate:runUpdate];
    runUpdate = update;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelRunUpdateChanged object:self];
}

- (void) setChanEnabled:(unsigned int)chan withValue:(bool)enabled
{
    if(chan >= kMaxFlashCamChannels) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setChanEnabled:chan withValue:chanEnabled[chan]];
    chanEnabled[chan] = enabled;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelChanEnabledChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setThreshold:(unsigned int)chan withValue:(unsigned int)thresh
{
    if(chan >= kMaxFlashCamChannels) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setThreshold:chan withValue:threshold[chan]];
    threshold[chan] = thresh;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"Channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelThresholdChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setPoleZero:(unsigned int)chan withValue:(unsigned int)pz
{
    if(chan >= kMaxFlashCamChannels) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setPoleZero:chan withValue:poleZero[chan]];
    poleZero[chan] = pz;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelPoleZeroChanged
                                                        object:self
                                                      userInfo:info];
}

- (void) setShapeTime:(unsigned int)chan withValue:(unsigned int)st
{
    if(chan >= kMaxFlashCamChannels) return;
    [[[self undoManager] prepareWithInvocationTarget:self] setShapeTime:chan withValue:shapeTime[chan]];
    shapeTime[chan] = st;
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:chan] forKey:@"channel"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelShapeTimeChanged
                                                        object:self
                                                      userInfo:info];
}

# pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setIPAddress:     [decoder decodeObjectForKey:@"ipAddress"]];
    [self setUsername:      [decoder decodeObjectForKey:@"username"]];
    [self setEthInterface:  [decoder decodeObjectForKey:@"ethInterface"]];
    [self setEthType:       [decoder decodeObjectForKey:@"ethType"]];
    [self setBoardAddress:  [[decoder decodeObjectForKey:@"boardAddress"]   unsignedIntegerValue]];
    [self setTraceType:     [[decoder decodeObjectForKey:@"traceType"]      unsignedIntegerValue]];
    [self setSignalDepth:   [[decoder decodeObjectForKey:@"signalDepth"]    unsignedIntegerValue]];
    [self setPostTrigger:   [[decoder decodeObjectForKey:@"postTrigger"]    unsignedIntegerValue]];
    [self setBaselineOffset:[[decoder decodeObjectForKey:@"baselineOffset"] unsignedIntegerValue]];
    [self setBaselineBias:  [[decoder decodeObjectForKey:@"baselineBias"]   unsignedIntegerValue]];
    [self setRemoteDataPath:[decoder decodeObjectForKey:@"remoteDataPath"]];
    [self setRemoteFilename:[decoder decodeObjectForKey:@"remoteFilename"]];
    [self setRunNumber:     [[decoder decodeObjectForKey:@"runNumber"]      unsignedIntegerValue]];
    [self setRunCount:      [[decoder decodeObjectForKey:@"runCount"]       unsignedIntegerValue]];
    [self setRunLength:     [[decoder decodeObjectForKey:@"runLength"]      unsignedIntegerValue]];
    [self setRunUpdate:     [decoder decodeBoolForKey:@"runUpdate"]];
    for(int i=0; i<kMaxFlashCamChannels; i++){
        [self setChanEnabled:i
                   withValue:[decoder decodeBoolForKey:[NSString stringWithFormat:@"chanEnabled%i", i]]];
        [self setThreshold:i withValue:[[decoder decodeObjectForKey:[NSString stringWithFormat:@"threshold%i", i]] unsignedIntegerValue]];
        [self setPoleZero:i  withValue:[[decoder decodeObjectForKey:[NSString stringWithFormat:@"poleZero%i",  i]] unsignedIntegerValue]];
        [self setShapeTime:i withValue:[[decoder decodeObjectForKey:[NSString stringWithFormat:@"shapeTime%i", i]] unsignedIntegerValue]];
    }
    pingTask = nil;
    pingSuccess = NO;
    runTasks = nil;
    runKilled = NO;
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:ipAddress      forKey:@"ipAddress"];
    [encoder encodeObject:username       forKey:@"username"];
    [encoder encodeObject:ethInterface   forKey:@"ethInterface"];
    [encoder encodeObject:ethType        forKey:@"ethType"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInteger:boardAddress]   forKey:@"boardAddress"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInteger:traceType]      forKey:@"traceType"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInteger:signalDepth]    forKey:@"signalDepth"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInteger:postTrigger]    forKey:@"postTrigger"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInteger:baselineOffset] forKey:@"baselineOffset"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInteger:baselineBias]   forKey:@"baselineBias"];
    [encoder encodeObject:remoteDataPath forKey:@"remoteDataPath"];
    [encoder encodeObject:remoteFilename forKey:@"remoteFilename"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInteger:runNumber]      forKey:@"runNumber"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInteger:runCount]       forKey:@"runCount"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInteger:runLength]      forKey:@"runLength"];
    [encoder encodeBool:runUpdate        forKey:@"runUpdate"];
    for(int i=0; i<kMaxFlashCamChannels; i++){
        [encoder encodeBool:chanEnabled[i] forKey:[NSString stringWithFormat:@"chanEnabled%i", i]];
        [encoder encodeObject:[NSNumber numberWithUnsignedInteger:threshold[i]] forKey:[NSString stringWithFormat:@"threshold%i", i]];
        [encoder encodeObject:[NSNumber numberWithUnsignedInteger:poleZero[i]]  forKey:[NSString stringWithFormat:@"poleZero%i", i]];
        [encoder encodeObject:[NSNumber numberWithUnsignedInteger:shapeTime[i]] forKey:[NSString stringWithFormat:@"shapeTime%i", i]];
    }
}

#pragma mark ***Commands
- (void) sendPing:(bool)verbose
{
    if(!pingTask){
        pingSuccess = NO;
        pingTask = [[ORPingTask pingTaskWithDelegate:self] retain];
        pingTask.launchPath = @"/sbin/ping";
        pingTask.arguments = [NSArray arrayWithObjects:@"-c", @"1", @"-t", @"1", @"-q", ipAddress, nil];
        pingTask.verbose = verbose;
        pingTask.textToDelegate = YES;
        [pingTask ping];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelPingStart object:self];
    }
}

- (bool) pingRunning
{
    return pingTask != nil;
}

- (void) taskFinished:(id)task
{
    if(task == pingTask){
        [pingTask release];
        pingTask = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelPingEnd object:self];
    }
    else if(task == runTasks){
        if(runKilled){
            [runTasks abortTasks];
            runKilled = NO;
        }
    }
}

- (void) tasksCompleted:(id)sender
{
    if(sender == runTasks){
        runTasks = nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelRunEnded object:self];
    }
}

- (void) taskData:(NSDictionary *)taskData
{
    id task        = [taskData objectForKey:@"Task"];
    NSString* text = [taskData objectForKey:@"Text"];
    if(task == pingTask){
        if([text rangeOfString:@" 0.0% packet loss"].location != NSNotFound) pingSuccess = YES;
        else pingSuccess = NO;
    }
}

- (void) startRun
{
    runKilled = NO;
    unsigned int chmask = 0;
    for(int i=0; i<kMaxFlashCamChannels; i++) if(chanEnabled[i]) chmask += 1 << i;
    if(chmask == 0){
        NSLog(@"ORFlashCamModel: no channels are enabled, aborting run start\n");
        return;
    }
    // check that we can ping the remote host
    [self sendPing:NO];
    // now wait for the ping task and start the run if successful
    [self startRunAfterPing];
}

- (void) startRunAfterPing
{
    // if the ping task is still running, wait
    if([self pingRunning]) [self performSelector:@selector(startRunAfterPing) withObject:self afterDelay:0.1];
    else{
        // if the ping failed, don't attempt to start the runs
        if(!pingSuccess){
            NSLog(@"ORFlashCamModel: ping failure aborting remote run\n");
            return;
        }
        // setup the run tasks
        unsigned int chmask = 0;
        for(int i=0; i<kMaxFlashCamChannels; i++) if(chanEnabled[i]) chmask += 1 << i;
        // set the flashcam arguments
        NSMutableArray* args = [[NSMutableArray alloc] init];
        [args addObjectsFromArray:@[username, ipAddress, @"$FLASHCAMDIR/fc250b-3.1/server/readout-fc250b"]];
        [args addObjectsFromArray:@[@"-re", @"100"]]; // currently no documentation on this option
        [args addObjectsFromArray:@[@"-ei", ethInterface, @"-et", [self ethType]]];
        [args addObjectsFromArray:@[@"-a",      [NSString stringWithFormat:@"%i", [self boardAddress]]]];
        [args addObjectsFromArray:@[@"-gt",     [NSString stringWithFormat:@"%i", [self traceType]+1]]];
        [args addObjectsFromArray:@[@"-sd",     [NSString stringWithFormat:@"%i", [self signalDepth]]]];
	[args addObjectsFromArray:@[@"-es",     [NSString stringWithFormat:@"%i", [self postTrigger]]]];
        [args addObjectsFromArray:@[@"-bl",     [NSString stringWithFormat:@"%i", [self baselineOffset]]]];
        [args addObjectsFromArray:@[@"-blbias", [NSString stringWithFormat:@"%i", [self baselineBias]]]];
        for(int i=0; i<kMaxFlashCamChannels; i++){
            if(!chanEnabled[i]) continue;
            [args addObjectsFromArray:@[@"-athr", [NSString stringWithFormat:@"%i,%i,1", threshold[i], i]]];
            [args addObjectsFromArray:@[@"-gpz",  [NSString stringWithFormat:@"%i,%i,1", poleZero[i],  i]]];
            [args addObjectsFromArray:@[@"-gs",   [NSString stringWithFormat:@"%i,%i,1", shapeTime[i], i]]];
        }
        [args addObjectsFromArray:@[@"-am", [NSString stringWithFormat:@"%02x", chmask]]];
        [args addObjectsFromArray:@[@"-mt", [NSString stringWithFormat:@"%i", [self runLength]]]];
        // setup the task sequence and add a task for each run to acquire
        NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
        runTasks = [ORTaskSequence taskSequenceWithDelegate:self];
        [runTasks setVerbose:YES];
        for(int run=runNumber; run<runNumber+runCount; run++){
            NSString* fname = [NSString stringWithFormat:@"%@/%@%i.fcio", [self remoteDataPath], [self remoteFilename], run];
            NSMutableArray* argCopy = [[NSMutableArray alloc] initWithArray:args copyItems:YES];
            [argCopy addObjectsFromArray:@[@"-o", fname]];
            [argCopy addObject:[NSString stringWithFormat:@"%i", run]];
            NSLog([NSString stringWithFormat:@"%@\n", [argCopy componentsJoinedByString:@" "]]);
            [runTasks addTask:[resourcePath stringByAppendingPathComponent:@"remote_run"]
                    arguments:[NSArray arrayWithArray:argCopy]];
            [argCopy release];
        }
        // launch the tasks to start the run(s)
        [runTasks setTextToDelegate:YES];
        [runTasks launch];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelRunInProgress object:self];
        [args release];
        if(runUpdate){
            [self setRunNumber:(runNumber+runCount)];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamModelRunNumberChanged
                                                                object:self];
        }
    }
}

- (void) killRun
{
    // kill any flashcam readout processes running on the remote host
    NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
    ORTaskSequence* tasks = [ORTaskSequence taskSequenceWithDelegate:self];
    [tasks setVerbose:YES];
    [tasks addTask:[resourcePath stringByAppendingPathComponent:@"kill_run"]
         arguments:[NSArray arrayWithObjects:username, ipAddress,
                    @"/usr/bin/pkill", @"-c", @"readout-fc", nil]];
    [tasks setTextToDelegate:YES];
    runKilled = YES;
    [tasks launch];
    // abort any remaining run tasks
    if(runTasks != nil) [runTasks abortTasks];
}



@end
