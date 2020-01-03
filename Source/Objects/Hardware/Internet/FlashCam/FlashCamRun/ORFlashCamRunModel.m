//  Orca
//  ORFlashCamRunModel.m
//
//  Created by Tom Caldwell on Monday Dec 26,2019
//  Copyright (c) 2019 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Department of Physics and Astrophysics
//sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORFlashCamRunModel.h"
#import "ORFlashCamADCModel.h"
#import "ORFlashCamMasterModel.h"

NSString* ORFlashCamRunModelIPAddressChanged       = @"ORFlashCamRunModelIPAddressChanged";
NSString* ORFlashCamRunModelUsernameChanged        = @"ORFlashCamRunModelUsernameChanged";
NSString* ORFlashCamRunModelEthInterfaceChanged    = @"ORFlashCamRunModelEthInterfaceChanged";
NSString* ORFlashCamRunModelEthInterfaceAdded      = @"ORFlashCamRunModelEthInterfaceAdded";
NSString* ORFlashCamRunModelEthInterfaceRemoved    = @"ORFlashCamRunModelEthInterfaceRemoved";
NSString* ORFlashCamRunModelEthTypeChanged         = @"ORFlashCamRunModelEthTypeChanged";
NSString* ORFlashCamRunModelMaxPayloadChanged      = @"ORFlashCamRunModelMaxPayloadChanged";
NSString* ORFlashCamRunModelEventBufferChanged     = @"ORFlashCamRunModelEventBufferChanged";
NSString* ORFlashCamRunModelPhaseAdjustChanged     = @"ORFlashCamRunModelPhaseAdjustChanged";
NSString* ORFlashCamRunModelBaselineSlewChanged    = @"ORFlashCamRunModelBaselineSlewChanged";
NSString* ORFlashCamRunModelIntegratorLenChanged   = @"ORFlashCamRunModelIntegratorLenChanged";
NSString* ORFlashCamRunModelEventSamplesChanged    = @"ORFlashCamRunModelEventSamplesChanged";
NSString* ORFlashCamRunModelTraceTypeChanged       = @"ORFlashCamRunModelTraceTypeChanged";
NSString* ORFlashCamRunModelPileupRejectionChanged = @"ORFlashCamRunModelPileupRejectionChanged";
NSString* ORFlashCamRunModelLogTimeChanged         = @"ORFlashCamRunModelLogTimeChanged";
NSString* ORFlashCamRunModelGPSEnabledChanged      = @"ORFlashCamRunModelGPSEnabledChanged";
NSString* ORFlashCamRunModelIncludeBaselineChanged = @"ORFlashCamRunModelIncludeBaselineChanged";
NSString* ORFlashCamRunModelAdditionalFlagsChanged = @"ORFlashCamRunModelAdditionalFlagsChanged";
NSString* ORFlashCamRunModelOverrideCmdChanged     = @"ORFlashCamRunModelOverrideCmdChanged";
NSString* ORFlashCamRunModelRunOverrideChanged     = @"ORFlashCamRunModelRunOverrideChanged";
NSString* ORFlashCamRunModelRemoteDataPathChanged  = @"ORFlashCamRunModelRemoteDataPathChanged";
NSString* ORFlashCamRunModelRemoteFilenameChanged  = @"ORFlashCamRunModelRemoteFilenameChanged";
NSString* ORFlashCamRunModelRunNumberChanged       = @"ORFlashCamRunModelRunNumberChanged";
NSString* ORFlashCamRunModelRunCountChanged        = @"ORFlashCamRunModelRunCountChanged";
NSString* ORFlashCamRunModelRunLengthChanged       = @"ORFlashCamRunModelRunLengthChanged";
NSString* ORFlashCamRunModelRunUpdateChanged       = @"ORFlashCamRunModelRunUpdateChanged";
NSString* ORFlashCamRunModelPingStart              = @"ORFlashCamRunModelPingStart";
NSString* ORFlashCamRunModelPingEnd                = @"ORFlashCamRunModelPingEnd";
NSString* ORFlashCamRunModelRunInProgress          = @"ORFlashCamRunModelRunInProgress";
NSString* ORFlashCamRunModelRunEnded               = @"ORFlashCamRunModelRunEnded";

static NSString* ORFlashCamRunModelEthConnectors[kFlashCamMaxEthInterfaces] =
{ @"FlashCamEthInterface0", @"FlashCamEthInterface1",
  @"FlashCamEthInterface2", @"FlashCamEthInterface3"};

@implementation ORFlashCamRunModel

#pragma mark •••Initialization

- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setIPAddress:@""];
    [self setUsername:@""];
    ethInterface = [NSMutableArray array];
    [self setEthType:@""];
    [self setMaxPayload:0];
    [self setEventBuffer:1000];
    [self setPhaseAdjust:-1];
    [self setBaselineSlew:0];
    [self setIntegratorLen:7];
    [self setEventSamples:2048];
    [self setTraceType:1];
    [self setPileupRejection:0.0];
    [self setLogTime:1.0];
    [self setGPSEnabled:NO];
    [self setIncludeBaseline:YES];
    [self setAdditionalFlags:@""];
    [self setOverrideCmd:@""];
    [self setRunOverride:NO];
    [self setRemoteDataPath:@""];
    [self setRemoteFilename:@""];
    [self setRunNumber:0];
    [self setRunCount:1];
    [self setRunLength:600];
    [self setRunUpdate:YES];
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
    if(ethInterface) [ethInterface release];
    [ethType release];
    [additionalFlags release];
    [overrideCmd release];
    [remoteDataPath release];
    [remoteFilename release];
    if(pingTask) [pingTask release];
    if(runTasks) [runTasks release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) makeMainController
{
    [self linkToController:@"ORFlashCamRunController"];
}

- (void) setUpImage
{
    NSImage* cimage = [NSImage imageNamed:@"flashcam"];
    NSSize size = [cimage size];
    NSSize newsize;
    newsize.width  = 0.5*size.width;
    newsize.height = 0.5*size.height;
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

- (void) makeConnectors
{
    float dx = ([self frame].size.width -kConnectorSize) / (kFlashCamMaxEthInterfaces - 1);
    for(int i=0; i<kFlashCamMaxEthInterfaces; i++){
        ORConnector* connector = [[ORConnector alloc] initAt:NSMakePoint([self x]+i*dx, [self y])
                                                withGuardian:self
                                              withObjectLink:self];
        //[connector setIoType:kInputConnector];
        [connector setConnectorImageType:kSmallDot];
        [connector setConnectorType:'FCEI'];
        [connector addRestrictedConnectionType:'FCEO'];
        [connector setOffColor:[NSColor colorWithCalibratedRed:1 green:1 blue:0.3 alpha:1]];
        [connector setOnColor:[NSColor colorWithCalibratedRed:0.1 green:0.1 blue:1 alpha:1]];
        if(i >= [self ethInterfaceCount]) [connector setHidden:YES];
        [[self connectors] setObject:connector forKey:ORFlashCamRunModelEthConnectors[i]];
        [connector release];
    }
}

#pragma mark •••Accessors

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

- (int) ethInterfaceCount
{
    if(!ethInterface) return 0;
    return (int) [ethInterface count];
}

- (int) indexOfInterface:(NSString*)interface
{
    if(!interface || !ethInterface) return -1;
    for(int i=0; i<[self ethInterfaceCount]; i++){
        NSString* eth = [self ethInterfaceAtIndex:i];
        if(!eth) continue;
        if([eth isEqualToString:interface]) return i;
    }
    return -1;
}

- (NSString*) ethInterfaceAtIndex:(int)index
{
    if(index < 0 || index >= [self ethInterfaceCount]) return nil;
    return [[[ethInterface objectAtIndex:index] copy] autorelease];
}

- (NSString*) ethType
{
    if(!ethType) return @"";
    return ethType;
}

- (int) maxPayload
{
    return maxPayload;
}

- (int) eventBuffer
{
    return eventBuffer;
}

- (int) phaseAdjust
{
    return phaseAdjust;
}

- (int) baselineSlew
{
    return baselineSlew;
}

- (int) integratorLen
{
    return integratorLen;
}

- (int) eventSamples
{
    return eventSamples;
}

- (int) traceType
{
    return traceType;
}

- (float) pileupRejection
{
    return pileupRejection;
}

- (float) logTime
{
    return logTime;
}

- (bool) gpsEnabled
{
    return gpsEnabled;
}

- (bool) includeBaseline
{
    return includeBaseline;
}

- (NSString*) additionalFlags
{
    if(!additionalFlags) return @"";
    return additionalFlags;
}

- (NSString*) overrideCmd
{
    if(!overrideCmd) return @"";
    return overrideCmd;
}

- (bool) runOverride
{
    return runOverride;
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

- (bool) pingSuccess
{
    return pingSuccess;
}

- (void) setIPAddress:(NSString*)ip
{
    if(!ip) return;
    if(!ipAddress) ipAddress = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setIPAddress:[self ipAddress]];
    [ipAddress autorelease];
    ipAddress = [ip copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelIPAddressChanged object:self];
}

- (void) setUsername:(NSString*)user
{
    if(!user) return;
    if(!username) username = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setUsername:[self username]];
    [username autorelease];
    username = [user copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelUsernameChanged object:self];
}

- (void) addEthInterface:(NSString*)eth
{
    if(!eth) return;
    if(!ethInterface) ethInterface = [NSMutableArray array];
    if([self indexOfInterface:eth] >= 0) return;
    [ethInterface addObject:[eth copy]];
    if([self ethInterfaceCount] <= kFlashCamMaxEthInterfaces){
        int i = [self ethInterfaceCount] - 1;
        [[[self connectors] objectForKey:ORFlashCamRunModelEthConnectors[i]] setHidden:NO];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORConnectionChanged object:self];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelEthInterfaceAdded object:self];
}

- (void) setEthInterface:(NSString*)eth atIndex:(int)index
{
    if(!eth) return;
    if(index < 0 || index >= [self ethInterfaceCount]) return;
    [[ethInterface objectAtIndex:index] autorelease];
    if([self indexOfInterface:eth] < 0)
        [ethInterface setObject:[eth copy] atIndexedSubscript:index];
    else [ethInterface setObject:@"" atIndexedSubscript:index];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelEthInterfaceChanged object:self];
}

- (void) removeEthInterface:(NSString*)eth
{
    [self removeEthInterfaceAtIndex:[self indexOfInterface:eth]];
}

- (void) removeEthInterfaceAtIndex:(int)index
{
    if(index < 0 || index >= [self ethInterfaceCount]) return;
    [[ethInterface objectAtIndex:index] autorelease];
    [ethInterface removeObjectAtIndex:index];
    if([self ethInterfaceCount] < kFlashCamMaxEthInterfaces){
        int i = [self ethInterfaceCount];
        [[[self connectors] objectForKey:ORFlashCamRunModelEthConnectors[i]] disconnect];
        [[[self connectors] objectForKey:ORFlashCamRunModelEthConnectors[i]] setHidden:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORConnectionChanged object:self];
    }
    NSDictionary* info = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index] forKey:@"index"];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelEthInterfaceRemoved object:self userInfo:info];
}

- (void) setEthType:(NSString*)eth
{
    if(!eth) return;
    if(!ethType) ethType = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setEthType:[self ethType]];
    [ethType autorelease];
    ethType = [eth copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelEthTypeChanged object:self];
}

- (void) setMaxPayload:(int)payload
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMaxPayload:[self maxPayload]];
    maxPayload = payload;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelMaxPayloadChanged object:self];
}

- (void) setEventBuffer:(int)buffer
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEventBuffer:[self eventBuffer]];
    eventBuffer = buffer;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelEventBufferChanged object:self];
}

- (void) setPhaseAdjust:(int)phase
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPhaseAdjust:[self phaseAdjust]];
    phaseAdjust = phase;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelPhaseAdjustChanged object:self];
}

- (void) setBaselineSlew:(int)slew
{
    [[[self undoManager] prepareWithInvocationTarget:self] setBaselineSlew:[self baselineSlew]];
    baselineSlew = slew;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelBaselineSlewChanged object:self];
}

- (void) setIntegratorLen:(int)len
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIntegratorLen:[self integratorLen]];
    integratorLen = len;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelIntegratorLenChanged object:self];
}

- (void) setEventSamples:(int)samples
{
    [[[self undoManager] prepareWithInvocationTarget:self] setEventSamples:[self eventSamples]];
    eventSamples = samples;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelEventSamplesChanged object:self];
}

- (void) setTraceType:(int)ttype
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTraceType:[self traceType]];
    traceType = ttype;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelTraceTypeChanged object:self];
}

- (void) setPileupRejection:(float)rej
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPileupRejection:[self pileupRejection]];
    pileupRejection = rej;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelPileupRejectionChanged object:self];
}

- (void) setLogTime:(float)time
{
    [[[self undoManager] prepareWithInvocationTarget:self] setLogTime:[self logTime]];
    logTime = time;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelLogTimeChanged object:self];
}

- (void) setGPSEnabled:(bool)enable
{
    [[[self undoManager] prepareWithInvocationTarget:self] setGPSEnabled:[self gpsEnabled]];
    gpsEnabled = enable;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelGPSEnabledChanged object:self];
}

- (void) setIncludeBaseline:(bool)inc
{
    [[[self undoManager] prepareWithInvocationTarget:self] setIncludeBaseline:[self includeBaseline]];
    includeBaseline = inc;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelIncludeBaselineChanged object:self];
}

- (void) setAdditionalFlags:(NSString*)flags
{
    if(!flags) return;
    if(!additionalFlags) additionalFlags = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setAdditionalFlags:[self additionalFlags]];
    [additionalFlags autorelease];
    additionalFlags = [flags copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelAdditionalFlagsChanged object:self];
}

- (void) setOverrideCmd:(NSString *)cmd
{
    if(!cmd) return;
    if(!overrideCmd) overrideCmd = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setOverrideCmd:[self overrideCmd]];
    [overrideCmd autorelease];
    overrideCmd = [cmd copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelOverrideCmdChanged object:self];
}

- (void) setRunOverride:(bool)runover
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunOverride:[self runOverride]];
    runOverride = runover;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelRunOverrideChanged object:self];
}


- (void) setRemoteDataPath:(NSString*)path
{
    if(!path) return;
    if(!remoteDataPath) remoteDataPath = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setRemoteDataPath:[self remoteDataPath]];
    [remoteDataPath autorelease];
    remoteDataPath = [path copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelRemoteDataPathChanged
                                                        object:self];
}

- (void) setRemoteFilename:(NSString*)fname
{
    if(!fname) return;
    if(!remoteFilename) remoteFilename = @"";
    [[[self undoManager] prepareWithInvocationTarget:self] setRemoteFilename:[self remoteFilename]];
    [remoteFilename autorelease];
    remoteFilename = [fname copy];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelRemoteFilenameChanged
                                                        object:self];
}

- (void) setRunNumber:(unsigned int)run
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunNumber:runNumber];
    runNumber = run;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelRunNumberChanged object:self];
}

- (void) setRunCount:(unsigned int)count
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunCount:runCount];
    runCount = count;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelRunCountChanged object:self];
}

- (void) setRunLength:(unsigned int)length
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunLength:runLength];
    runLength = length;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelRunLengthChanged object:self];
}

- (void) setRunUpdate:(bool)update
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRunUpdate:runUpdate];
    runUpdate = update;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelRunUpdateChanged object:self];
}

#pragma mark •••Archival

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setIPAddress:      [decoder decodeObjectForKey:@"ipAddress"]];
    [self setUsername:       [decoder decodeObjectForKey:@"username"]];
    ethInterface = [[decoder decodeObjectForKey:@"ethInterface"] retain];
    [self setEthType:        [decoder decodeObjectForKey:@"ethType"]];
    [self setMaxPayload:     [decoder decodeIntForKey:@"maxPayload"]];
    [self setEventBuffer:    [decoder decodeIntForKey:@"eventBuffer"]];
    [self setPhaseAdjust:    [decoder decodeIntForKey:@"phaseAdjust"]];
    [self setBaselineSlew:   [decoder decodeIntForKey:@"baselineSlew"]];
    [self setIntegratorLen:  [decoder decodeIntForKey:@"integratorLen"]];
    [self setEventSamples:   [decoder decodeIntForKey:@"eventSamples"]];
    [self setTraceType:      [decoder decodeIntForKey:@"traceType"]];
    [self setPileupRejection:[decoder decodeFloatForKey:@"pileupRejection"]];
    [self setLogTime:        [decoder decodeFloatForKey:@"logTime"]];
    [self setGPSEnabled:     [decoder decodeBoolForKey:@"gpsEnabled"]];
    [self setIncludeBaseline:[decoder decodeBoolForKey:@"includeBaseline"]];
    [self setAdditionalFlags:[decoder decodeObjectForKey:@"additionalFlags"]];
    [self setOverrideCmd:    [decoder decodeObjectForKey:@"overrideCmd"]];
    [self setRunOverride:    [decoder decodeBoolForKey:@"runOverride"]];
    [self setRemoteDataPath: [decoder decodeObjectForKey:@"remoteDataPath"]];
    [self setRemoteFilename: [decoder decodeObjectForKey:@"remoteFilename"]];
    [self setRunNumber:      [[decoder decodeObjectForKey:@"runNumber"] unsignedIntValue]];
    [self setRunCount:       [[decoder decodeObjectForKey:@"runCount"]  unsignedIntValue]];
    [self setRunLength:      [[decoder decodeObjectForKey:@"runLength"] unsignedIntValue]];
    [self setRunUpdate:      [decoder decodeBoolForKey:@"runUpdate"]];
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
    [encoder encodeObject:ipAddress       forKey:@"ipAddress"];
    [encoder encodeObject:username        forKey:@"username"];
    [encoder encodeObject:ethInterface    forKey:@"ethInterface"];
    [encoder encodeObject:ethType         forKey:@"ethType"];
    [encoder encodeInt:maxPayload         forKey:@"maxPayload"];
    [encoder encodeInt:eventBuffer        forKey:@"eventBuffer"];
    [encoder encodeInt:phaseAdjust        forKey:@"phaseAdjust"];
    [encoder encodeInt:baselineSlew       forKey:@"baselineSlew"];
    [encoder encodeInt:integratorLen      forKey:@"integratorLen"];
    [encoder encodeInt:eventSamples       forKey:@"eventSamples"];
    [encoder encodeInt:traceType          forKey:@"traceType"];
    [encoder encodeFloat:pileupRejection  forKey:@"pileupRejection"];
    [encoder encodeFloat:logTime          forKey:@"logTime"];
    [encoder encodeBool:gpsEnabled        forKey:@"gpsEnabled"];
    [encoder encodeObject:additionalFlags forKey:@"additionalFlags"];
    [encoder encodeObject:overrideCmd     forKey:@"overrideCmd"];
    [encoder encodeBool:runOverride       forKey:@"runOverride"];
    [encoder encodeObject:remoteDataPath  forKey:@"remoteDataPath"];
    [encoder encodeObject:remoteFilename  forKey:@"remoteFilename"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInt:runNumber] forKey:@"runNumber"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInt:runCount]  forKey:@"runCount"];
    [encoder encodeObject:[NSNumber numberWithUnsignedInt:runLength] forKey:@"runLength"];
    [encoder encodeBool:runUpdate         forKey:@"runUpdate"];
}

#pragma mark •••Commands

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
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelPingStart object:self];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelPingEnd object:self];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelRunEnded object:self];
    }
}

- (void) taskData:(NSDictionary*)taskData
{
    id task        = [taskData objectForKey:@"Task"];
    NSString* text = [taskData objectForKey:@"Text"];
    if(task == pingTask){
        if([text rangeOfString:@" 0.0% packet loss"].location != NSNotFound) pingSuccess = YES;
        else pingSuccess = NO;
    }
}

- (NSMutableArray*) runFlags
{
    NSMutableArray* flags = [NSMutableArray array];
    [flags addObject:@"-ei"];
    [flags addObjectsFromArray:ethInterface];
    [flags addObjectsFromArray:@[@"-et",    ethType]];
    [flags addObjectsFromArray:@[@"-mt",    [NSString stringWithFormat:@"%d", runLength]]];
    [flags addObjectsFromArray:@[@"-mpl",   [NSString stringWithFormat:@"%i", maxPayload]]];
    [flags addObjectsFromArray:@[@"-slots", [NSString stringWithFormat:@"%i", eventBuffer]]];
    [flags addObjectsFromArray:@[@"-aph",   [NSString stringWithFormat:@"%i", phaseAdjust]]];
    [flags addObjectsFromArray:@[@"-bls",   [NSString stringWithFormat:@"%i", baselineSlew]]];
    [flags addObjectsFromArray:@[@"-il",    [NSString stringWithFormat:@"%i", integratorLen]]];
    [flags addObjectsFromArray:@[@"-es",    [NSString stringWithFormat:@"%i", eventSamples]]];
    [flags addObjectsFromArray:@[@"-gt",    [NSString stringWithFormat:@"%i", traceType]]];
    [flags addObjectsFromArray:@[@"-gpr",   [NSString stringWithFormat:@"%.2f", pileupRejection]]];
    [flags addObjectsFromArray:@[@"-lt",    [NSString stringWithFormat:@"%.2f", logTime]]];
    [flags addObjectsFromArray:@[@"-gps",   [NSString stringWithFormat:@"%i", (int)gpsEnabled]]];
    [flags addObjectsFromArray:@[@"-blinc", [NSString stringWithFormat:@"%i", (int)includeBaseline]]];
    return flags;
}

- (NSMutableArray*) connectedObjects:(NSString*)cname
{
    NSMutableArray* objs = [NSMutableArray array];
    for(int ieth=0; ieth<MIN(kFlashCamMaxEthInterfaces, [self ethInterfaceCount]); ieth++){
        ORConnector* connector = [connectors objectForKey:ORFlashCamRunModelEthConnectors[ieth]];
        if(!connector) continue;
        if(![connector isConnected]) continue;
        id obj = [connector connectedObject];
        if(!obj) continue;
        if([[obj className] isEqualToString:cname]) [objs addObject:obj];
        else if([[obj className] isEqualToString:@"ORFlashCamEthLinkModel"])
            [objs addObjectsFromArray:[obj connectedObjects:cname]];
    }
    return objs;
}

- (void) startRun
{
    runKilled = NO;
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
            NSLog(@"ORFlashCamRunModel: ping failure aborting remote run\n");
            return;
        }
        NSLog(@"ping success\n");
        NSMutableArray* args = [NSMutableArray array];
        if(runOverride) [args addObjectsFromArray:[overrideCmd componentsSeparatedByString:@" "]];
        else{
            [args addObjectsFromArray:@[username, ipAddress, @"$FLASHCAMDIR/server/readout-fc250b"]];
            [args addObjectsFromArray:[self runFlags]];
            NSMutableArray* adcs = [self connectedObjects:@"ORFlashCamADCModel"];
            NSMutableArray* masters = [self connectedObjects:@"ORFlashCamMasterModel"];
            // get the list of board addresses
            NSMutableString* addressList = [NSMutableString string];;
            for(unsigned i=0; i<[adcs count]; i++){
                ORFlashCamADCModel* adc = [adcs objectAtIndex:i];
                if(i < [adcs count] - 1 || [masters count] > 0)
                    [addressList appendString:[NSString stringWithFormat:@"%x,", [adc boardAddress]]];
                else [addressList appendString:[NSString stringWithFormat:@"%x", [adc boardAddress]]];
            }
            for(unsigned i=0; i<[masters count]; i++){
                ORFlashCamMasterModel* master = [masters objectAtIndex:i];
                if(i < [masters count] - 1)
                    [addressList appendString:[NSString stringWithFormat:@"%x,", [master boardAddress]]];
                else [addressList appendString:[NSString stringWithFormat:@"%x",  [master boardAddress]]];
            }
            [args addObjectsFromArray:@[@"-a", addressList]];
            // set the master card flag
            if([masters count] > 0){
                if([masters count] > 1) NSLog(@"ORFlashCamRunModel: multiple master cards assuming"
                                              " first master card in configuration\n");
                NSString* s = [NSString stringWithFormat:@"%x", [[masters objectAtIndex:0] boardAddress]];
                [args addObjectsFromArray:@[@"-ma", s]];
            }
            // append the flags for each adc card
            unsigned int chanOffset = 0;
            for(unsigned int i=0; i<[adcs count]; i++){
                ORFlashCamADCModel* adc = [adcs objectAtIndex:i];
                [args addObjectsFromArray:@[@"-am", [NSString stringWithFormat:@"%x,%x,1", [adc chanMask], [adc boardAddress]]]];
                [args addObjectsFromArray:[adc runFlagsForChannelOffset:chanOffset]];
                chanOffset += [adc nChanEnabled];
            }
            // append any additional user-specified flags
            if(additionalFlags)
                [args addObjectsFromArray:[additionalFlags componentsSeparatedByString:@" "]];
        }
        // setup the run tasks and set add the filename for each run
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
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelRunInProgress object:self];
        if(runUpdate){
            [self setRunNumber:(runNumber+runCount)];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelRunNumberChanged
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
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamRunModelRunEnded object:self];
}

@end
