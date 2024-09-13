//  Orca
//  ORFlashCamListenerModel.m
//
//  Created by Tom Caldwell on May 1, 2020
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

#import "ORFlashCamListenerModel.h"
#import "ORFlashCamReadoutModel.h"
#import "ORFlashCamADCModel.h"
#import "ORFlashCamTriggerModel.h"
#import "ORFlashCamGlobalTriggerModel.h"
#import "FlashCamUtils.h"
#import "Utilities.h"
#import "ORDataTypeAssigner.h"
#import "ORDataTaskModel.h"
#import "ORSmartFolder.h"
#import "ANSIEscapeHelper.h"

NSString* ORFlashCamListenerModelConfigChanged       = @"ORFlashCamListenerModelConfigChanged";
NSString* ORFlashCamListenerModelStatusChanged       = @"ORFlashCamListenerModelStatusChanged";
//NSString* ORFlashCamListenerModelConnected         = @"ORFlashCamListenerModelConnected";
//NSString* ORFlashCamListenerModelDisconnected      = @"ORFlashCamListenerModelDisconnected";
NSString* ORFlashCamListenerModelChanMapChanged      = @"ORFlashCamListenerModelChanMapChanged";
NSString* ORFlashCamListenerModelCardMapChanged      = @"ORFlashCamListenerModelCardMapChanged";
NSString* ORFlashCamListenerModelConfigBufferFull    = @"ORFlashCamListenerModelConfigBufferFull";
NSString* ORFlashCamListenerModelStatusBufferFull    = @"ORFlashCamListenerModelStatusBufferFull";
NSString* ORFlashCamListenerModelFCLogChanged        = @"ORFlashCamListenerModelFCLogChanged";
NSString* ORFlashCamListenerModelFCRunLogChanged     = @"ORFlashCamListenerModelFCRunLogChanged";
NSString* ORFlashCamListenerModelFCRunLogFlushed     = @"ORFlashCamListenerModelFCRunLogFlushed";
NSString* ORFlashCamListenerModelSWTStatusChanged    = @"ORFlashCamListenerModelSWTStatusChanged";
NSString* ORFlashCamListenerModelSWTConfigChanged    = @"ORFlashCamListenerModelSWTConfigChanged";

@implementation ORFlashCamListenerModel

#define DEBUG_PRINT(fmt, ...) do { if (DEBUG) fprintf( stderr, (fmt), __VA_ARGS__); } while (0)
#define DEBUG 0
//#define DEBUG_FSP

#pragma mark •••Initialization

- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    interface          = @"";
    port               = 4000;
    ip                 = @"";
    timeout            = 2000;
    ioBuffer           = 0; // 0 uses default BUFIO_BUFSIZE = 256 kB
    stateBuffer        = 20;
    configParams       = [[NSMutableDictionary dictionary] retain];
    [self setConfigParam:@"maxPayload"      withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"eventBuffer"     withValue:[NSNumber numberWithInt:1024]];
    [self setConfigParam:@"phaseAdjust"     withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"baselineSlew"    withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"integratorLen"   withValue:[NSNumber numberWithInt:7]];
    [self setConfigParam:@"eventSamples"    withValue:[NSNumber numberWithInt:2048]];
    [self setConfigParam:@"signalDepth"     withValue:[NSNumber numberWithInt:1024]];
    [self setConfigParam:@"retriggerLength" withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"traceType"       withValue:[NSNumber numberWithInt:1]];
    [self setConfigParam:@"resetMode"       withValue:[NSNumber numberWithInt:2]];
    [self setConfigParam:@"timeout"         withValue:[NSNumber numberWithInt:1000]];
    [self setConfigParam:@"evPerRequest"    withValue:[NSNumber numberWithInt:1]];
    [self setConfigParam:@"daqMode"         withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"nonsparseStart"  withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"nonsparseEnd"    withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"sparseOverwrite" withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"gpsMode"         withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"gpsusClockAlarm" withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"baselineCalib"   withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"trigTimer1Addr"  withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"trigTimer1Sec"   withValue:[NSNumber numberWithInt:1]];
    [self setConfigParam:@"trigTimer2Addr"  withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"trigTimer2Sec"   withValue:[NSNumber numberWithInt:1]];
    [self setConfigParam:@"pileupRej"       withValue:[NSNumber numberWithDouble:0.0]];
    [self setConfigParam:@"logTime"         withValue:[NSNumber numberWithDouble:1.0]];
    [self setConfigParam:@"incBaseline"     withValue:[NSNumber numberWithBool:NO]];
    [self setConfigParam:@"trigAllEnable"   withValue:[NSNumber numberWithBool:YES]];
    [self setConfigParam:@"extraFlags"      withString:@""];
    [self setConfigParam:@"extraFiles"      withValue:[NSNumber numberWithBool:NO]];
    
    [self setConfigParam:@"fspEnabled"      withValue:[NSNumber numberWithBool:NO]];
    [self setConfigParam:@"fspHWEnabled"      withValue:[NSNumber numberWithBool:NO]];
    [self setConfigParam:@"fspPSEnabled"      withValue:[NSNumber numberWithBool:NO]];
    [self setConfigParam:@"fspWriteNonTriggered" withValue:[NSNumber numberWithBool:NO]];
    [self setConfigParam:@"fspLogTime"      withValue:[NSNumber numberWithDouble:3.0]];
    [self setConfigParam:@"fspLogLevel"      withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"fspPulserChan"   withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"fspBaselineChan" withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"fspMuonChan"     withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"fspHWMajThreshold"  withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"fspHWPreScaleRatio"  withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"fspPSPreWindow"   withValue:[NSNumber numberWithInt:2000000]];
    [self setConfigParam:@"fspPSPostWindow"   withValue:[NSNumber numberWithInt:2000000]];
    [self setConfigParam:@"fspPSPreScaleRatio"  withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"fspPSMuonCoincidence"  withValue:[NSNumber numberWithBool:NO]];
    [self setConfigParam:@"fspPSSumWindowStart"  withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"fspPSSumWindowStop"  withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"fspPSSumWindowSize"  withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"fspPSCoincidenceThreshold"  withValue:[NSNumber numberWithDouble:20.0]];
    [self setConfigParam:@"fspPSAbsoluteThreshold"  withValue:[NSNumber numberWithDouble:1200.0]];
    reader             = NULL;
    readerRecordCount  = 0;
    enableStreamProcessor = NO;
    writeNonTriggered = NO;
    processor           = NULL;
    fspPSChannelMap = (int*)calloc(FCIOMaxChannels, sizeof(int));
    fspPSChannelGains = (float*)calloc(FCIOMaxChannels, sizeof(float));
    fspPSChannelThresholds = (float*)calloc(FCIOMaxChannels, sizeof(float));
    fspPSChannelShapings = (int*)calloc(FCIOMaxChannels, sizeof(int));
    fspPSChannelLowPass = (float*)calloc(FCIOMaxChannels, sizeof(float));
    fspHWChannelMap = (int*)calloc(FCIOMaxChannels, sizeof(int));
    fspHWPrescaleThresholds = (unsigned short*)calloc(FCIOMaxChannels, sizeof(unsigned short));
    fspFlagChannelMap = (int*)calloc(FCIOMaxChannels, sizeof(int));
    fspFlagChannelThresholds = (int*)calloc(FCIOMaxChannels, sizeof(int));
    runFailedAlarm     = nil;
    unrecognizedPacket = false;
    unrecognizedStates = nil;
    listenerRemoteIsFile = NO;
    eventCount         = 0;
    runTime            = 0.0;
    readMB             = 0.0;
    rateMB             = 0.0;
    rateHz             = 0.0;
    timeLock           = 0.0;
    deadTime           = 0.0;
    totDead            = 0.0;
    curDead            = 0.0;
    dataRateHistory    = [[ORTimeRate alloc] init];
    [dataRateHistory   setLastAverageTime:[NSDate date]];
    [dataRateHistory   setSampleTime:10];
    eventRateHistory   = [[ORTimeRate alloc] init];
    [eventRateHistory  setLastAverageTime:[NSDate date]];
    [eventRateHistory  setSampleTime:10];
    deadTimeHistory    = [[ORTimeRate alloc] init];
    [deadTimeHistory   setLastAverageTime:[NSDate date]];
    [deadTimeHistory   setSampleTime:10];
    swtBufferFillLevelHistory    = [[ORTimeRate alloc] init];
    [swtBufferFillLevelHistory   setLastAverageTime:[NSDate date]];
    [swtBufferFillLevelHistory   setSampleTime:10];
    swtDiscardRateHistory   = [[ORTimeRate alloc] init];
    [swtDiscardRateHistory  setLastAverageTime:[NSDate date]];
    [swtDiscardRateHistory  setSampleTime:10];
    swtOutputRateHistory    = [[ORTimeRate alloc] init];
    [swtOutputRateHistory   setLastAverageTime:[NSDate date]];
    [swtOutputRateHistory   setSampleTime:10];
    chanMap            = nil;
    cardMap            = nil;
    [self setRemoteInterfaces:[NSMutableArray array]];
    ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
    [readList setAcceptedProtocol:  @"ORDataTaker"];
    [readList addAcceptedObjectName:@"ORFlashCamADCModel"];
    [readList addAcceptedObjectName:@"ORFlashCamADCStdModel"];
    [self setReadOutList:readList];
    [readList release];
    fclogIndex = 0;
    fclog      = nil;
    [self setFCLogLines:10000];
    fcrunlog = [[NSMutableArray arrayWithCapacity:[self fclogLines]] retain];
    dataFileObject = nil;
    listenerThread = nil;

    startFinished = NO;
    setupFinished = NO;
    stopRunning = NO;
    takingData = NO;
    runTaskCompleted = NO;
    dataFileName = nil;

    currentStartupTime = 0;

    [self registerNotificationObservers];

    [[self undoManager] enableUndoRegistration];
    return self;
}

- (id) initWithInterface:(NSString*)iface port:(uint16_t)p
{
    self = [self init];
    [interface release];
    interface   = [iface copy];
    port        = p;
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if(reader) FCIODestroyStateReader(reader);
    if(processor) FSPDestroy(processor);

    [runFailedAlarm      clearAlarm];
    [runFailedAlarm      release];
    [unrecognizedStates  release];
    [interface           release];
    [ip                  release];
    [remoteInterfaces    release];
    [configParams        release];
    [status              release];
    [dataPacketForThread release];
    [dataRateHistory     release];
    [eventRateHistory    release];
    [deadTimeHistory     release];
    [swtBufferFillLevelHistory     release];
    [swtDiscardRateHistory    release];
    [swtOutputRateHistory     release];
    [runTask             release];
    [listenerThread      release];
    [readOutList         release];
    [readOutArgs         release];
    [dataFileName        release];
    [fclog               release];
    [fcrunlog            release];
    [logDateFormatter    release];
    [ansieHelper         release];
    
    free(fspPSChannelMap);
    free(fspPSChannelGains);
    free(fspPSChannelThresholds);
    free(fspPSChannelShapings);
    free(fspPSChannelLowPass);
    free(fspHWChannelMap);
    free(fspHWPrescaleThresholds);
    free(fspFlagChannelMap);
    free(fspFlagChannelThresholds);
    [super dealloc];
}

- (void) setUpImage
{
    NSRect   aRect = NSMakeRect(0,0,44,44);
    NSImage* image = [[NSImage alloc] initWithSize:aRect.size];

    [image lockFocus];
    NSImage* cimage = [NSImage imageNamed:@"flashcam_listener"];
    [cimage drawInRect:aRect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [self decorateIcon:image];
    [image unlockFocus];

    [self setImage:image];
    [image release];
}

- (void) makeMainController
{
    [self linkToController:@"ORFlashCamListenerController"];
}

- (void) decorateIcon:(NSImage*)anImage
{
    NSSize iconSize = [anImage size];
    if(reader){
        NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSFont fontWithName:@"Helvetica" size:20.0],NSFontAttributeName,
                                         [NSColor greenColor],NSForegroundColorAttributeName,nil];
        NSAttributedString* s = [[NSAttributedString alloc] initWithString:@")" attributes:attrsDictionary];
        [s drawAtPoint:NSMakePoint([s size].width/2,iconSize.height/2-[s size].height/2)];
        [s release];

        attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSFont fontWithName:@"Helvetica" size:30.0],NSFontAttributeName,
                           [NSColor greenColor],NSForegroundColorAttributeName,nil];
        s = [[NSAttributedString alloc] initWithString:@")" attributes:attrsDictionary];
        [s drawAtPoint:NSMakePoint([s size].width/2+5,iconSize.height/2-[s size].height/2)];
        [s release];
    }
    else {
        NSDictionary* attrsDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSFont fontWithName:@"Helvetica" size:25.0],NSFontAttributeName,
                                         [NSColor redColor],NSForegroundColorAttributeName,nil];
        NSAttributedString* s = [[NSAttributedString alloc] initWithString:@"x" attributes:attrsDictionary];
        [s drawAtPoint:NSMakePoint([s size].width/2,iconSize.height/2-[s size].height/2)];
        [s release];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORGroupSelectionChanged object:self];
}

- (BOOL) acceptsGuardian:(OrcaObject*)aGuardian
{
    if([aGuardian isMemberOfClass:NSClassFromString(@"ORFlashCamReadoutModel")]) return YES;
    return NO;
}

- (void) registerNotificationObservers
{
    NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [notifyCenter addObserver : self
                     selector : @selector(dataFileNameChanged:)
                         name : ORDataFileChangedNotification
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(writeFCIOLog:)
                         name : ORDataFileModelLogWrittenNotification
                       object : nil];
    [notifyCenter addObserver : self
                     selector : @selector(fileLimitExceeded:)
                         name : ORDataFileLimitExceededNotification
                       object : nil];
}

#pragma mark •••Accessors

- (void) dataFileNameChanged:(NSNotification*) aNote
{
    NSString* filename  = [[aNote object] fileName];
    NSString* extension = [[aNote object] fileStaticSuffix];
    if(![extension isEqualToString:@""]){
        NSRange r = [filename rangeOfString:extension options:NSBackwardsSearch];
        filename  = [filename substringWithRange:NSMakeRange(0, r.location)];
    }
    if (dataFileName != nil) {
        DEBUG_PRINT( "%s: dataFileNameChanged: dataFileName already set. %s.\n", [[self identifier] UTF8String], [dataFileName UTF8String]);
        [dataFileName release];
    }
    dataFileName = [[[NSString stringWithFormat:@"%@/openFiles/%@_FCIO_%lu.fcio",
                       [[[aNote object] dataFolder] finalDirectoryName], filename,(unsigned long)[self tag]] stringByExpandingTildeInPath] retain];
}

- (NSString*) streamDescription
{
    if (listenerRemoteIsFile && dataFileName != nil)
        return [NSString stringWithString:dataFileName];
    else
        return [NSString stringWithFormat:@"%@:%d on %@", ip, port, interface];
}

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"%@ listener %d:%d", [guardian identifier], [self uniqueIdNumber], [self port]];
}

- (NSString*) interface
{
    if(!interface) return @"";
    return interface;
}

- (uint16_t) port
{
    return port;
}

- (NSString*) ip
{
    if(!ip) return @"";
    return ip;
}

- (NSMutableArray*) remoteInterfaces
{
    return remoteInterfaces;
}

- (NSUInteger) remoteInterfaceCount
{
    if(remoteInterfaces) return [remoteInterfaces count];
    return 0;
}

- (NSString*) remoteInterfaceAtIndex:(NSUInteger)index
{
    if(!remoteInterfaces) return @"";
    else if(index >= [remoteInterfaces count]) return @"";
    else return [remoteInterfaces objectAtIndex:index];
}

- (NSString*) ethType
{
    NSString* type = @"";
    for(NSString* eth in remoteInterfaces){
        NSString* t = [guardian ethTypeAtIndex:[guardian indexOfInterface:eth]];
        if([type isEqualToString:@""]) type = [NSString stringWithString:t];
        else if(![t isEqualToString:type]){
            NSLogColor([NSColor redColor], @"%@: error getting ethernet type - all interfaces associated with the same listener must have identical type\n", [self identifier]);
            return @"";
        }
    }
    return type;
}

- (NSNumber*) configParam:(NSString*)p
{
    if([p isEqualToString:@"maxPayload"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"maxPayload"] intValue]];
    else if([p isEqualToString:@"eventBuffer"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"eventBuffer"] intValue]];
    else if([p isEqualToString:@"phaseAdjust"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"phaseAdjust"] intValue]];
    else if([p isEqualToString:@"baselineSlew"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"baselineSlew"] intValue]];
    else if([p isEqualToString:@"integratorLen"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"integratorLen"] intValue]];
    else if([p isEqualToString:@"eventSamples"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"eventSamples"] intValue]];
    else if([p isEqualToString:@"signalDepth"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"signalDepth"] intValue]];
    else if([p isEqualToString:@"retriggerLength"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"retriggerLength"] intValue]];
    else if([p isEqualToString:@"traceType"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"traceType"] intValue]];
    else if([p isEqualToString:@"resetMode"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"resetMode"] intValue]];
    else if([p isEqualToString:@"timeout"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"timeout"] intValue]];
    else if([p isEqualToString:@"evPerRequest"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"evPerRequest"] intValue]];
    else if([p isEqualToString:@"daqMode"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"daqMode"] intValue]];
    else if([p isEqualToString:@"nonsparseStart"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"nonsparseStart"] intValue]];
    else if([p isEqualToString:@"nonsparseEnd"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"nonsparseEnd"] intValue]];
    else if([p isEqualToString:@"sparseOverwrite"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"sparseOverwrite"] intValue]];
    else if([p isEqualToString:@"gpsMode"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"gpsMode"] intValue]];
    else if([p isEqualToString:@"gpsusClockAlarm"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"gpsusClockAlarm"] intValue]];
    else if([p isEqualToString:@"baselineCalib"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"baselineCalib"] intValue]];
    else if([p isEqualToString:@"trigTimer1Addr"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"trigTimer1Addr"] intValue]];
    else if([p isEqualToString:@"trigTimer1Sec"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"trigTimer1Sec"] intValue]];
    else if([p isEqualToString:@"trigTimer2Addr"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"trigTimer2Addr"] intValue]];
    else if([p isEqualToString:@"trigTimer2Sec"])
        return [NSNumber numberWithInt:[[configParams objectForKey:@"trigTimer2Sec"] intValue]];
    else if([p isEqualToString:@"pileupRej"])
        return [NSNumber numberWithDouble:[[configParams objectForKey:@"pileupRej"] doubleValue]];
    else if([p isEqualToString:@"logTime"])
        return [NSNumber numberWithDouble:[[configParams objectForKey:@"logTime"] doubleValue]];
    else if([p isEqualToString:@"incBaseline"])
        return [NSNumber numberWithBool:[[configParams objectForKey:@"incBaseline"] boolValue]];
    else if([p isEqualToString:@"trigAllEnable"])
        return [NSNumber numberWithBool:[[configParams objectForKey:@"trigAllEnable"] boolValue]];
    else if([p isEqualToString:@"extraFlags"])
        return [configParams objectForKey:@"extraFlags"];
    else if([p isEqualToString:@"extraFiles"])
        return [NSNumber numberWithBool:[[configParams objectForKey:@"extraFiles"] boolValue]];
    else if([p isEqualToString:@"writeFCIOLog"])
        return [NSNumber numberWithBool:[[configParams objectForKey:@"writeFCIOLog"] boolValue]];
    else if([p isEqualToString:@"fspEnabled"])
        return [NSNumber numberWithBool:[[configParams objectForKey:p] boolValue]];
    else if([p isEqualToString:@"fspHWEnabled"])
        return [NSNumber numberWithBool:[[configParams objectForKey:p] boolValue]];
    else if([p isEqualToString:@"fspPSEnabled"])
        return [NSNumber numberWithBool:[[configParams objectForKey:p] boolValue]];
    else if([p isEqualToString:@"fspWriteNonTriggered"])
        return [NSNumber numberWithBool:[[configParams objectForKey:p] boolValue]];
    else if([p isEqualToString:@"fspLogTime"])
        return [NSNumber numberWithDouble:[[configParams objectForKey:p] doubleValue]];
    else if([p isEqualToString:@"fspLogLevel"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"fspPulserChan"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"fspBaselineChan"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"fspMuonChan"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"fspHWMajThreshold"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"fspHWPreScaleRatio"])
        return [NSNumber numberWithDouble:[[configParams objectForKey:p] intValue]];
//    else if([p isEqualToString:@"fspHWCheckAll"])
//        return [NSNumber numberWithBool:[[configParams objectForKey:p] boolValue]];
    else if([p isEqualToString:@"fspPSPreWindow"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"fspPSPostWindow"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"fspPSPreScaleRatio"])
        return [NSNumber numberWithDouble:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"fspPSMuonCoincidence"])
        return [NSNumber numberWithBool:[[configParams objectForKey:p] boolValue]];
    else if([p isEqualToString:@"fspPSSumWindowStart"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"fspPSSumWindowStop"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"fspPSSumWindowSize"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"fspPSCoincidenceThreshold"])
        return [NSNumber numberWithDouble:[[configParams objectForKey:p] doubleValue]];
    else if([p isEqualToString:@"fspPSAbsoluteThreshold"])
        return [NSNumber numberWithDouble:[[configParams objectForKey:p] doubleValue]];
    else{
        NSLog(@"%@: unknown configuration parameter %@\n",[self identifier], p);
        return nil;
    }
}

- (NSMutableArray*) runFlags:(bool)print
{
    NSMutableArray* f = [NSMutableArray array];
    // -blbias is per ADC Card, -bldac is per channel
    [f addObjectsFromArray:@[@"-blbias", @"0", @"-bldac", @"2000"]];
    [f addObjectsFromArray:@[@"-mpl",  [NSString stringWithFormat:@"%d", [[self configParam:@"maxPayload"]    intValue]]]];
    [f addObjectsFromArray:@[@"-slots",[NSString stringWithFormat:@"%d", [[self configParam:@"eventBuffer"]   intValue]]]];
    [f addObjectsFromArray:@[@"-aph",  [NSString stringWithFormat:@"%d", [[self configParam:@"phaseAdjust"]   intValue]]]];
    [f addObjectsFromArray:@[@"-bls",  [NSString stringWithFormat:@"%d", [[self configParam:@"baselineSlew"]  intValue]]]];
    [f addObjectsFromArray:@[@"-il",   [NSString stringWithFormat:@"%d", [[self configParam:@"integratorLen"] intValue]]]];
    [f addObjectsFromArray:@[@"-es",   [NSString stringWithFormat:@"%d", [[self configParam:@"eventSamples"]  intValue]]]];
    [f addObjectsFromArray:@[@"-sd",   [NSString stringWithFormat:@"%d", [[self configParam:@"signalDepth"]   intValue]]]];
    [f addObjectsFromArray:@[@"-tl",   [NSString stringWithFormat:@"%d", [[self configParam:@"retriggerLength"]intValue]]]];

    //--------------------------------------------------------------
    //MAH 7/24/23
    //special case... traceType popup index 5 --> make the output value 501
    int gtVal = [[self configParam:@"traceType"] intValue];
    if(gtVal == 5)gtVal = 501;
    [f addObjectsFromArray:@[@"-gt",   [NSString stringWithFormat:@"%d", gtVal]]];
    //--------------------------------------------------------------


    [f addObjectsFromArray:@[@"-rst",  [NSString stringWithFormat:@"%d", [[self configParam:@"resetMode"]     intValue]]]];
    [f addObjectsFromArray:@[@"-tmo",  [NSString stringWithFormat:@"%d", [[self configParam:@"timeout"]       intValue]]]];
    [f addObjectsFromArray:@[@"-re",   [NSString stringWithFormat:@"%d", [[self configParam:@"evPerRequest"]  intValue]]]];
    [f addObjectsFromArray:@[@"-bl",   [NSString stringWithFormat:@"%d", [[self configParam:@"baselineCalib"] intValue]]]];
    [f addObjectsFromArray:@[@"-gpr",  [NSString stringWithFormat:@"%.2f", [[self configParam:@"pileupRej"]  doubleValue]]]];
    [f addObjectsFromArray:@[@"-lt",   [NSString stringWithFormat:@"%.2f", [[self configParam:@"logTime"]    doubleValue]]]];
    // TODO: -blinc is a debug hardware development parameter, should leave it to the extraFlags if ever needed.
    [f addObjectsFromArray:@[@"-blinc",[NSString stringWithFormat:@"%d", [[self configParam:@"incBaseline"]   intValue]]]];
    if([[self configParam:@"gpsMode"] intValue] == 0)
        [f addObjectsFromArray:@[@"-gps", @"0"]];
    else
        [f addObjectsFromArray:@[@"-gps", [NSString stringWithFormat:@"%d,%d",
                                           [[self configParam:@"gpsusClockAlarm"] intValue],
                                           [[self configParam:@"gpsMode"] intValue]]]];
    if([[self configParam:@"daqMode"] intValue] != 11)
        [f addObjectsFromArray:@[@"-dm", [NSString stringWithFormat:@"%d", [[self configParam:@"daqMode"] intValue]]]];
    else
        [f addObjectsFromArray:@[@"-dm", [NSString stringWithFormat:@"%d,%d,%d,%d",
                                          [[self configParam:@"daqMode"] intValue],
                                          [[self configParam:@"nonsparseStart"] intValue],
                                          [[self configParam:@"nonsparseEnd"] intValue],
                                          [[self configParam:@"sparseOverwrite"] intValue]]]];
    if(![[self configParam:@"trigAllEnable"] boolValue]) [f addObjectsFromArray:@[@"-athr", @"0"]];
    if([[self configParam:@"trigTimer1Addr"] intValue] > 0)
        [f addObjectsFromArray:@[@"-t1", [NSString stringWithFormat:@"%x,%d",
                                          [[self configParam:@"trigTimer1Addr"] intValue],
                                          [[self configParam:@"trigTimer1Sec"]  intValue]]]];
    if([[self configParam:@"trigTimer2Addr"] intValue] > 0)
        [f addObjectsFromArray:@[@"-t2", [NSString stringWithFormat:@"%x,%d",
                                          [[self configParam:@"trigTimer2Addr"] intValue],
                                          [[self configParam:@"trigTimer2Sec"]  intValue]]]];
    if(print) NSLog(@"%@\n", [f componentsJoinedByString:@" "]);
    return f;
}

- (int) timeout
{
    return timeout;
}

- (int) ioBuffer
{
    return ioBuffer;
}

- (int) stateBuffer
{
    return stateBuffer;
}

- (FCIOStateReader*) reader
{
    return reader;
}

- (int) readerRecordCount
{
    return (reader) ? reader->nrecords : 0;
}

- (int) bufferedRecords
{
    return bufferedRecords;
}

- (uint32_t) configId
{
    return configId;
}

- (uint32_t) statusId
{
    return statusId;
}

- (uint32_t) eventId
{
    return eventId;
}

- (uint32_t) listenerDataId
{
    return listenerDataId;
}

- (NSString*) status
{
    if(!status) return @"";
    return status;
}

- (NSUInteger) eventCount
{
    return eventCount;
}

- (double) runTime
{
    return runTime;
}

- (double) readMB
{
    return readMB;
}

- (double) rateMB
{
    return rateMB;
}

- (double) rateHz
{
    return rateHz;
}

- (double) timeLock
{
    return  timeLock;
}

- (double) deadTime
{
    return deadTime;
}

- (double) totDead
{
    return totDead;
}

- (double) curDead
{
    return curDead;
}

- (double) swtRunTime
{
    if (processor)
        return processor->stats->runtime;
    return 0.0;
}

- (int) swtEventCount
{
    if (processor)
        return processor->stats->n_written_events;
    return 0;
}

- (double) swtAvgInputRate
{
    if (processor)
        return processor->stats->avg_rate_read_events;
    return 0.0;
}

- (double) swtAvgOutputRate
{
    if (processor)
        return processor->stats->avg_rate_write_events;
    return 0.0;
}

- (double) swtAvgDiscardRate
{
    if (processor)
        return processor->stats->avg_rate_discard_events;
    return 0.0;
}

- (int) swtFreeStates
{
    if (processor)
        return FSPFreeStates(processor);
    return 0;
}

- (ORTimeRate*) dataRateHistory
{
    return dataRateHistory;
}

- (ORTimeRate*) eventRateHistory
{
    return eventRateHistory;
}

- (ORTimeRate*) deadTimeHistory
{
    return deadTimeHistory;
}

- (ORTimeRate*) swtBufferFillLevelHistory
{
    return swtBufferFillLevelHistory;
}

- (ORTimeRate*) swtDiscardRateHistory
{
    return swtDiscardRateHistory;
}

- (ORTimeRate*) swtOutputRateHistory
{
    return swtOutputRateHistory;
}

- (ORReadOutList*) readOutList
{
    return readOutList;
}

- (NSMutableArray*) readOutArgs
{
    return readOutArgs;
}

- (NSMutableArray*) children
{
    return [NSMutableArray arrayWithObject:readOutList];
}

- (NSUInteger) fclogLines
{
    return [fclog count];
}

- (NSString*) fclog:(NSUInteger)nprev
{
    if(nprev >= [self fclogLines]) return @"";
    NSUInteger index = ([self fclogLines] + fclogIndex - nprev) % [self fclogLines];
    return [fclog objectAtIndex:index];
}

- (NSUInteger) fcrunlogLines
{
    return [fcrunlog count];
}

- (NSString*) fcrunlog:(NSUInteger)nprev
{
    if(nprev >= [self fcrunlogLines]) return @"";
    return [fcrunlog objectAtIndex:[self fcrunlogLines]-1-nprev];
}

- (void) setInterface:(NSString*)iface andPort:(uint16_t)p
{
    if(!iface) return;
    if(interface) if([interface isEqualToString:iface] && port == p) return;
    [interface release];
    interface = [iface copy];
    port = p;
    [self updateIP];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelConfigChanged
                                                        object:self];
}

- (void) setInterface:(NSString*)iface
{
    if(!iface) return;
    if(interface) if([interface isEqualToString:iface]) return;
    [interface release];
    interface = [iface copy];
    [self updateIP];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelConfigChanged
                                                        object:self];
}

- (void) updateIP
{
    NSString* tmp = ipAddress(interface);
    if(ip) if([ip isEqualToString:tmp]) return;
    [ip release];
    ip = [tmp retain];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelConfigChanged
                                                        object:self];
}

- (void) setPort:(uint16_t)p
{
    if(port == p) return;
    port = p;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelConfigChanged
                                                        object:self];
}

- (void) setRemoteInterfaces:(NSMutableArray*)ifaces
{
    [remoteInterfaces autorelease];
    remoteInterfaces = [ifaces retain];
}

- (void) addRemoteInterface:(NSString*)iface
{
    if(iface == nil) return;
    if([iface isEqualToString:@""]) return;
    if(!remoteInterfaces) [self setRemoteInterfaces:[NSMutableArray array]];
    for(NSString* i in remoteInterfaces) if([i isEqualToString:iface]) return;
    [remoteInterfaces addObject:iface];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelConfigChanged
                                                        object:self];
}

- (void) removeRemoteInterface:(NSString*)iface
{
    if(!remoteInterfaces) return;
    for(NSUInteger i=0; i<[remoteInterfaces count]; i++){
        if([[remoteInterfaces objectAtIndex:i] isEqualTo:iface]){
            [remoteInterfaces removeObjectAtIndex:i];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelConfigChanged
                                                                object:self];
        }
    }
}

- (void) removeRemoteInterfaceAtIndex:(NSUInteger)index
{
    if(!remoteInterfaces) return;
    if(index >= [remoteInterfaces count]) return;
    [remoteInterfaces removeObjectAtIndex:index];
}

- (NSString*) configParamString:(NSString*)aKey
{
    //sanity check
    id aVal = [configParams objectForKey:aKey];
    if([aVal isKindOfClass:[NSString class]])return aVal;
    else return @"";
}

- (uint32_t) maxADCCards
{
    if([[self configParam:@"traceType"] intValue] == 0) return FCIOMaxChannels / 24;
    else return FCIOMaxChannels / 6;
}

- (void) setConfigParam:(NSString*)p withString:(NSString*)aString
{
    if(!aString)aString=@"";
    [configParams setObject:aString forKey:p];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelConfigChanged object:self];
}

- (void) setConfigParam:(NSString*)p withValue:(NSNumber*)v
{
    if([p isEqualToString:@"maxPayload"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0, [v intValue])] forKey:p];
    else if([p isEqualToString:@"extraFiles"])
        [configParams setObject:v forKey:p];
    else if([p isEqualToString:@"writeFCIOLog"])
        [configParams setObject:v forKey:p];
    else if([p isEqualToString:@"eventBuffer"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0, [v intValue])] forKey:p];
    else if([p isEqualToString:@"phaseAdjust"])
        [configParams setObject:[NSNumber numberWithInt:[v intValue]] forKey:p];
    else if([p isEqualToString:@"baselineSlew"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(1, [v intValue]), 255)] forKey:p];
    else if([p isEqualToString:@"integratorLen"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(1, [v intValue]), 7)] forKey:p];
    else if([p isEqualToString:@"eventSamples"]){
        int val = MIN(MAX(2, [v intValue]), 4*8192);
        [configParams setObject:[NSNumber numberWithInt:val+(val%2)] forKey:p];
    }
    else if([p isEqualToString:@"signalDepth"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0, [v intValue])] forKey:p];
    else if([p isEqualToString:@"retriggerLength"]){
        int maxval = [[self configParam:@"eventSamples"] intValue];
        if([[self configParam:@"traceType"] intValue] > 0) maxval *= 4;
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(0, [v intValue]), maxval)] forKey:p];
    }
    else if([p isEqualToString:@"traceType"]){
        int prevType = [[self configParam:p] intValue];
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(0, [v intValue]), 5)] forKey:p];
        int newType = [[self configParam:p] intValue];
        if(prevType > 0 && newType == 0)
            [self setConfigParam:@"retriggerLength" withValue:[self configParam:@"retriggerLength"]];
    }
    else if([p isEqualToString:@"resetMode"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(0, [v intValue]), 2)] forKey:p];
    else if([p isEqualToString:@"timeout"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0, [v intValue])] forKey:p];
    else if([p isEqualToString:@"evPerRequest"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0, [v intValue])] forKey:p];
    else if([p isEqualToString:@"daqMode"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0, [v intValue])] forKey:p];
    else if([p isEqualToString:@"baselineCalib"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(0, [v intValue]), 65536)]  forKey:p];
    else if([p isEqualToString:@"trigTimer1Addr"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0, [v intValue])] forKey:p];
    else if([p isEqualToString:@"trigTimer1Sec"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0, [v intValue])] forKey:p];
    else if([p isEqualToString:@"trigTimer2Addr"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0, [v intValue])] forKey:p];
    else if([p isEqualToString:@"trigTimer2Sec"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0, [v intValue])] forKey:p];
    else if([p isEqualToString:@"pileupRej"])
        [configParams setObject:[NSNumber numberWithDouble:MIN(MAX(0., [v doubleValue]), 65536.)] forKey:p];
    else if([p isEqualToString:@"logTime"])
        [configParams setObject:[NSNumber numberWithDouble:MAX(0, [v doubleValue])] forKey:p];
    else if([p isEqualToString:@"incBaseline"])
        [configParams setObject:[NSNumber numberWithBool:[v boolValue]] forKey:p];
    else if([p isEqualToString:@"trigAllEnable"])
        [configParams setObject:[NSNumber numberWithBool:[v boolValue]] forKey:p];
    else if([p isEqualToString:@"gpsEnabled"]){
        BOOL enabled = [v boolValue];
        [configParams setObject:[NSNumber numberWithBool:enabled] forKey:p];
        if(!enabled) [configParams setObject:[NSNumber numberWithInt:0] forKey:p];
    }
    else if([p isEqualToString:@"gpsMode"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(0, [v intValue]), 5)] forKey:p];
    else if([p isEqualToString:@"gpsusClockAlarm"]){
        int mode = [[self configParam:@"gpsMode"] intValue];
        if(mode == 3 || mode == 4) [configParams setObject:[NSNumber numberWithInt:0] forKey:p];
        else [configParams setObject:[NSNumber numberWithInt:[v intValue]] forKey:p];
    }
    else if([p isEqualToString:@"daqMode"]){
        int m = MIN(MAX(0, [v intValue]), 12);
        if(m <= 2 || m >= 10) [configParams setObject:[NSNumber numberWithInt:m] forKey:p];
    }
    else if([p isEqualToString:@"nonsparseStart"] || [p isEqualToString:@"nonsparseEnd"] || [p isEqualToString:@"sparseOverwrite"]){
        if([[self configParam:@"daqMode"] intValue] < 10) [configParams setObject:[NSNumber numberWithInt:-1] forKey:p];
        else{
            if([p isEqualToString:@"nonsparseStart"])
                [configParams setObject:[NSNumber numberWithInt:MAX(-1, [v intValue])] forKey:p]; //jfw MAX -1 consistent with Tom's L200 code
            else if([p isEqualToString:@"nonsparseEnd"])
                [configParams setObject:[NSNumber numberWithInt:MAX([[self configParam:@"nonsparseStart"] intValue], [v intValue])] forKey:p];
            else if([p isEqualToString:@"sparseOverwrite"])
                [configParams setObject:[NSNumber numberWithInt:MIN(MAX(-1, [v intValue]), 1)] forKey:p];
        }
    }

    else if([p isEqualToString:@"fspEnabled"])
        [configParams setObject:[NSNumber numberWithBool:[v boolValue]] forKey:p];
    else if([p isEqualToString:@"fspHWEnabled"])
        [configParams setObject:[NSNumber numberWithBool:[v boolValue]] forKey:p];
    else if([p isEqualToString:@"fspPSEnabled"])
        [configParams setObject:[NSNumber numberWithBool:[v boolValue]] forKey:p];
    else if([p isEqualToString:@"fspWriteNonTriggered"])
        [configParams setObject:[NSNumber numberWithBool:[v boolValue]] forKey:p];
    else if([p isEqualToString:@"fspLogTime"])
        [configParams setObject:[NSNumber numberWithDouble:MIN(MAX(1.0,[v doubleValue]),60.0)] forKey:p];
    else if([p isEqualToString:@"fspLogLevel"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(0,[v intValue]),5)] forKey:p];
    else if([p isEqualToString:@"fspPulserChan"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(-1,[v intValue]),2304)] forKey:p];
    else if([p isEqualToString:@"fspBaselineChan"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(-1,[v intValue]),2304)] forKey:p];
    else if([p isEqualToString:@"fspMuonChan"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(-1,[v intValue]),2304)] forKey:p];
    else if([p isEqualToString:@"fspHWMajThreshold"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(1,[v intValue]),2304)] forKey:p];
    else if([p isEqualToString:@"fspHWPrescaleRatio"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0,[v intValue])] forKey:p];
    else if([p isEqualToString:@"fspHWPreScaleThreshold"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0,[v intValue])] forKey:p];
//    else if([p isEqualToString:@"fspHWCheckAll"])
//        [configParams setObject:[NSNumber numberWithBool:[v boolValue]] forKey:p];
    else if([p isEqualToString:@"fspPSPreWindow"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(0,[v intValue]),2147483647)] forKey:p];
    else if([p isEqualToString:@"fspPSPostWindow"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(0,[v intValue]),2147483647)] forKey:p];
    else if([p isEqualToString:@"fspPSPreScaleRatio"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0.0,[v intValue])] forKey:p];
    else if([p isEqualToString:@"fspPSMuonCoincidence"])
        [configParams setObject:[NSNumber numberWithBool:[v boolValue]] forKey:p];
    else if([p isEqualToString:@"fspPSSumWindowStart"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(0,[v intValue]),32768)] forKey:p];
    else if([p isEqualToString:@"fspPSSumWindowStop"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(-1,[v intValue]),32768)] forKey:p];
    else if([p isEqualToString:@"fspPSSumWindowSize"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(1,[v intValue]),32767)] forKey:p];
    else if([p isEqualToString:@"fspPSCoincidenceThreshold"])
        [configParams setObject:[NSNumber numberWithDouble:MAX(0.0,[v doubleValue])] forKey:p];
    else if([p isEqualToString:@"fspPSAbsoluteThreshold"])
        [configParams setObject:[NSNumber numberWithDouble:MAX(0.0,[v doubleValue])] forKey:p];
    else{
        NSLog(@"%@: unknown configuration parameter %@\n",[self identifier], p);
        return;
    }
    if (DEBUG)
        NSLog(@"%@: set parameter %@ to %@\n",[self identifier], p, v);
}

- (void) setTimeout:(int)to
{
    if(timeout == to) return;
    timeout = to;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelConfigChanged
                                                        object:self];
}

- (void) setIObuffer:(int)io
{
    if(ioBuffer == io) return;
    ioBuffer = io;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelConfigChanged
                                                        object:self];
}

- (void) setStateBuffer:(int)sb
{
    if(stateBuffer == sb) return;
    stateBuffer = sb;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelConfigChanged
                                                        object:self];
}

- (void) setConfigId:(uint32_t)cId
{
    configId = cId;
}

- (void) setStatusId:(uint32_t)sId
{
    statusId = sId;
}

- (void) setEventId:(uint32_t)eId
{
    eventId = eId;
}

- (void) setListenerDataId:(uint32_t)lId
{
    listenerDataId = lId;
}

- (void) setDataIds:(id)assigner
{
    listenerDataId = [assigner assignDataIds:kLongForm];
//    configId = [assigner assignDataIds:kLongForm];
//    eventId = [assigner assignDataIds:kLongForm];
//    statusId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherListener
{
    [self setListenerDataId:[anotherListener listenerDataId]];
//    [self setConfigId:[anotherListener configId]];
//    [self setEventId:[anotherListener eventId]];
//    [self setStatusId:[anotherListener statusId]];
}

- (void) setReadOutList:(ORReadOutList*)newList
{
    [newList retain];
    [readOutList release];
    readOutList = newList;
}

- (void) setReadOutArgs:(NSMutableArray*)args
{
    [args retain];
    [readOutArgs release];
    readOutArgs = args;
}

- (void) setChanMap:(NSMutableArray*)chMap
{
    [chMap retain];
    [chanMap release];
    chanMap = chMap;
}

- (void) setCardMap:(NSMutableArray*)map
{
    [map retain];
    [cardMap release];
    cardMap = map;
}

- (void) setFCLogLines:(NSUInteger)nlines
{
    nlines = MAX(100, MIN(100000, nlines));
    if(nlines == [self fclogLines]) return;
    NSMutableArray* log = [NSMutableArray arrayWithCapacity:nlines];
    for(NSUInteger i=0; i<nlines; i++) [log addObject:@""];
    NSUInteger n = 0;
    if(fclog){
        n = MIN([self fclogLines]-1, nlines-1);
        for(NSUInteger i=n; i<[fclog count]; i--)
            [log setObject:[self fclog:i] atIndexedSubscript:n-i];
    }
    [log retain];
    [fclog release];
    fclog = log;
    fclogIndex = n;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelFCLogChanged object:self];
}

- (void) appendToFCLog:(NSString*)line andNotify:(BOOL)notify
{
    fclogIndex = (fclogIndex + 1) % [self fclogLines];
    [fclog setObject:line atIndexedSubscript:fclogIndex];
    if(notify)
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelFCLogChanged object:self];
}

- (void) clearFCLog
{
    for(NSUInteger i=0; i<[self fclogLines]; i++) [fclog setObject:@"" atIndexedSubscript:i];
    fclogIndex = 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelFCLogChanged object:self];
}

- (void) appendToFCRunLog:(NSString*)line
{
    [fcrunlog addObject:line];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelFCRunLogChanged object:self];
}


#pragma mark •••Comparison methods

- (BOOL) sameInterface:(NSString*)iface andPort:(uint16_t)p
{
    if(![interface isEqualToString:iface]) return NO;
    if(port != p) return NO;
    return YES;
}

- (BOOL) sameIP:(NSString*)address andPort:(uint16_t)p
{
    if(![ip isEqualToString:address]) return NO;
    if(port != p) return NO;
    return YES;
}


#pragma mark •••FCIO methods

- (void) listenerThreadMain:(ORDataPacket*)aDataPacket
{
    currentStartupTime = 0; // reset the counter
    bool readoutReady = NO;
    bool success = NO;
    if ( (readoutReady = [self waitForReady])) {
        if (!stopRunning && readoutReady) {
            DEBUG_PRINT("%s: waitForReady success\n", [[self identifier] UTF8String]);
            setupFinished = NO;
            [self setupReadoutTask];
            if (!stopRunning && setupFinished) {
                DEBUG_PRINT("%s: setupReadoutTask success\n", [[self identifier] UTF8String]);

                if ([self waitForTakingData]) {
                    DEBUG_PRINT("%s: waitForTakingData success\n", [[self identifier] UTF8String]);
                    startFinished = NO;

                    [self performSelectorOnMainThread:@selector(startReadoutTask) withObject:self waitUntilDone:YES];

                    if (!stopRunning && startFinished) {
                        DEBUG_PRINT("%s: startReadoutTask success\n", [[self identifier] UTF8String]);

                        if ( [self fcioOpen] ) {
                            [self performSelectorOnMainThread:@selector(setUpImage) withObject:nil waitUntilDone:NO];
                            DEBUG_PRINT("%s: fcioOpen success\n", [[self identifier] UTF8String]);
                            bool running = false;
                            do {
                                @autoreleasepool {
                                    //autoreleasing here is needed; there is a memory leak in the call-chain somewhere otherwise
                                    if ((running = [self fcioRead:aDataPacket])) {
                                        // putDataInQueue is self-locking (regarding thread-safety)
                                        [[aDataPacket dataTask] putDataInQueue:aDataPacket force:YES];
                                    }
                                }
                                if (stopRunning) {
                                    // need to stop this here inside the loop so the reader disconnects automatically and correctly.
                                    // we need to continue to read data, so it needs to run in the background.
                                    [self performSelectorInBackground:@selector(stopReadoutTask) withObject:self];
                                    DEBUG_PRINT("%s: stopReadoutTask success\n", [[self identifier] UTF8String]);
                                    stopRunning = NO; // it's just a signal, we want to run stopReadoutTask to run only once.
                                }

                            } while (running);
                        }
                        if ([self fcioClose]) {
                            // fcioClose checks the state of end-of-stream
                            success = YES;
                            DEBUG_PRINT("%s: fcioClose success\n", [[self identifier] UTF8String]);
                            // this is success, everything else means something went wrong and
                            // it's the responsibility of the corresponding code-sections to report what went wrong
                        }
                    }
                }
            }
        }
    }
    [self performSelectorOnMainThread:@selector(setUpImage) withObject:nil waitUntilDone:NO];
    DEBUG_PRINT("%s: listenerThreadMain %s with readoutReady=%d setupFinished=%d startFinished=%d stopRunning=%d.\n",[[self identifier] UTF8String],  success?"succeeded":"failed", readoutReady, setupFinished, startFinished, stopRunning);
    if (!success) {
        // this is a blank call to stopReadoutTask in most cases, as the runTask shouldn't actually be running anymore,
        // except when failing during startReadoutTask phase.
        // as we already closed or never opened the listener side, we can wait for the task to finish synchronously.
        [self stopReadoutTask];
        [self runFailed];
    }
}

- (bool) setupStreamProcessor
{
    if ([[self configParam:@"daqMode"] intValue] == 12) {
        NSLogColor([NSColor redColor],@"%s: Usage of the Software Trigger in singles mode is not implemented.\n", [self identifier]);
        return NO;
    }
    // overwrite parameter, use for debugging purposes. even though fsp would not
    // write, we want them in the output datastream
    writeNonTriggered = [[self configParam:@"fspWriteNonTriggered"] boolValue];

    nfspPSChannels = 0;
    nfspHWChannels = 0;
    nfspFlagChannels = 0;
    fspPulserChannel = -1;
    fspBaselineChannel = -1;
    fspMuonChannel = -1;
    fspPulserChannelThreshold = 0;
    fspBaselineChannelThreshold = 0;
    fspBaselineChannelThreshold = 0;
    for(ORReadOutObject* obj in [readOutList children]){
        if(![[obj object] isKindOfClass:NSClassFromString(@"ORFlashCamCard")]) continue;
        ORFlashCamCard* card = (ORFlashCamCard*) [obj object];
        if([card isKindOfClass:NSClassFromString(@"ORFlashCamADCModel")]){
            ORFlashCamADCModel* adc = (ORFlashCamADCModel*) card;
            for (unsigned int ich = 0; ich < [adc numberOfChannels]; ich++) {
                if (![adc chanEnabled:ich]) { // if the channel is not enable for readout, is cannot be parsed to the processor.
                    continue;
                }
                int identifier = ([adc cardAddress] << 16) + ich;
                switch([adc swtInclude:ich]) {
                    case 1: { // Peak Sum
                        fspPSChannelMap[nfspPSChannels] = identifier;
                        fspPSChannelGains[nfspPSChannels] = [adc swtCalibration:ich];
                        fspPSChannelThresholds[nfspPSChannels] = [adc swtThreshold:ich];
                        fspPSChannelShapings[nfspPSChannels] = [adc swtShapingTime:ich];
                        fspPSChannelLowPass[nfspPSChannels] = 0.0; // Don't need lowpass for now
                        nfspPSChannels++;
                        break;
                    }
                    case 2: { // HW Multiplicity
                        fspHWChannelMap[nfspHWChannels] = identifier;
                        fspHWPrescaleThresholds[nfspHWChannels] = (unsigned short)[adc swtThreshold:ich];
                        nfspHWChannels++;
                        break;
                    }
                    case 3: { // Digital Flag
                        // TODO: Digital Flag Channel Type not implemented, only specialized versions available
                        NSLogColor([NSColor redColor], @"%@: setupSoftwareTrigger: Digital Flag selected on 0x%x, but it's not implemented yet.", [self identifier], identifier);
                    }
                    case 4: {
                        if (fspPulserChannel == -1) {
                            fspPulserChannel = identifier;
                            fspPulserChannelThreshold = [adc swtCalibration:ich] * [adc swtThreshold:ich];
                        } else {
                            NSLogColor([NSColor redColor], @"%@: setupSoftwareTrigger: Trying to overwrite Pulser Channel setting 0x%x with 0x%x.\n", [self identifier], fspPulserChannel, identifier );
                            return NO;
                        }
                        break;
                    }
                    case 5: {
                        if (fspBaselineChannel == -1) {
                            fspBaselineChannel = identifier;
                            fspBaselineChannelThreshold = [adc swtCalibration:ich] * [adc swtThreshold:ich];
                        } else {
                            NSLogColor([NSColor redColor], @"%@: setupSoftwareTrigger: Trying to overwrite Baseline Channel setting 0x%x with 0x%x.\n", [self identifier], fspBaselineChannel, identifier );
                            return NO;
                        }
                        break;
                    }
                    case 6: {
                        if (fspMuonChannel == -1) {
                            fspMuonChannel = identifier;
                            fspMuonChannelThreshold = [adc swtCalibration:ich] * [adc swtThreshold:ich];
                        } else {
                            NSLogColor([NSColor redColor], @"%@: setupSoftwareTrigger: Trying to overwrite Muon Channel setting 0x%x with 0x%x.\n", [self identifier], fspMuonChannel, identifier );
                            return NO;
                        }
                        break;
                    }
                    default: {
                        // either 0 or new unknown tag values in the Controller
                        // Don't add to the correspondig list.
                        break;
                    }
                }
            }
        }
    }
    
    if (processor) {
        // should never occur, but we make sure
        FSPDestroy(processor);
    }

    if (!(processor = FSPCreate(reader->max_states-1))) {
        NSLog(@"%@: Couldn't allocate software trigger.\n", [self identifier]);
        return NO;
    }
    FSPSetLogTime(processor, [[self configParam:@"fspLogTime"] doubleValue]);
    FSPSetLogLevel(processor, [[self configParam:@"fspLogLevel"] intValue]);
    
    /* always set the Aux Parameters to get sane defaults, we picked some at the beginning of this function.*/
    if (!FSP_L200_SetAuxParameters(processor, FCIO_TRACE_MAP_FORMAT,
                             fspPulserChannel, fspPulserChannelThreshold,
                             fspBaselineChannel, fspBaselineChannelThreshold,
                             fspMuonChannel, fspMuonChannelThreshold
                             )) {
        NSLogColor([NSColor redColor], @"%@: setupSoftwareTrigger: Error parsing Aux parameters.\n", [self identifier]);
        return NO;
    }

    if ([self configParam:@"fspHWEnabled"] && nfspHWChannels) {
        if (!FSP_L200_SetGeParameters(processor, nfspHWChannels, fspHWChannelMap, FCIO_TRACE_MAP_FORMAT,
                                [[self configParam:@"fspHWMajThreshold"] intValue],
                                0, // do not skip any channels to check
                                fspHWPrescaleThresholds,
                                [[self configParam:@"fspHWPreScaleRatio"] intValue])) {
            NSLogColor([NSColor redColor], @"%@: setupSoftwareTrigger: Error parsing HW Multiplicity parameters.\n", [self identifier]);
            return NO;
        }
    }

    if ([self configParam:@"fspPSEnabled"] && nfspPSChannels) {
        if (!FSP_L200_SetSiPMParameters(processor, nfspPSChannels, fspPSChannelMap, FCIO_TRACE_MAP_FORMAT,
                                  fspPSChannelGains, fspPSChannelThresholds,
                                  fspPSChannelShapings, fspPSChannelLowPass,
                                  [[self configParam:@"fspPSPreWindow"] intValue],
                                  [[self configParam:@"fspPSPostWindow"] intValue],
                                  [[self configParam:@"fspPSSumWindowSize"] intValue],
                                  [[self configParam:@"fspPSSumWindowStart"] intValue],
                                  [[self configParam:@"fspPSSumWindowStop"] intValue],
                                  [[self configParam:@"fspPSAbsoluteThreshold"] floatValue],
                                  [[self configParam:@"fspPSCoincidenceThreshold"] floatValue],
                                  [[self configParam:@"fspPSPreScaleRatio"] intValue],
                                  [[self configParam:@"fspPSMuonCoincidence"] intValue])) {
            NSLogColor([NSColor redColor], @"%@: setupSoftwareTrigger: Error parsing Peak Sum parameters.\n", [self identifier]);
            return NO;
        }
    }
    int realized_buffer_depth = FSPSetBufferSize(processor, stateBuffer);
    if (realized_buffer_depth != stateBuffer) {
        // should also never occur
        NSLogColor([NSColor redColor], @"%@: Software trigger: buffer depth too small, adjust the state buffer depth to 16 at minimum\n", [self identifier]);
        return NO;
    }

//                const char* filepath = "<path_to_config>/fspconfig_local.txt";
//                FSPSetParametersFromFile(postprocessor, filepath);
    NSLog(@"%@: Software trigger initialized.\n", [self identifier]);
    return YES;
}

- (bool) fcioOpen
{
    DEBUG_PRINT( "%s %s: fcioOpen\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
    if(reader)
        return NO;

    NSString* fcioRemote = (listenerRemoteIsFile) ? dataFileName : [NSString stringWithFormat:@"tcp://listen/%d/%@", port, ip];

    // If the remote is a file, FCIOCreateStateReader will fail, if it doesn't exist yet.
    // We use the same timeout as for TCP connections to wait for it's existence.
    if (listenerRemoteIsFile && timeout > 0) {
        double delay = 0.5;
        int total_delay = 0;
        while (total_delay < timeout) {
            if ([[NSFileManager defaultManager] fileExistsAtPath: fcioRemote] )
                break;

            [ORTimer delay: delay];
            total_delay += (int)delay * 1000; // seconds to milliseconds
        }
        // Let the error checking propagate to FCIOCreateStateReader
    }
    fcio_last_tag = -2; // not used in fcio protocol, use it to identify the FCIO stream state in fcioClose()
    reader = FCIOCreateStateReader([fcioRemote UTF8String], timeout, ioBuffer, stateBuffer);
    if(reader){
        NSLog(@"%@: connected to %@\n",[self identifier], [self streamDescription]);
        FCIOSelectStateTag(reader, 0);
        if (enableStreamProcessor && ![self setupStreamProcessor]) {
            return NO;
        }
           
        return YES;
    } else {
        NSLogColor([NSColor redColor], @"%@: unable to open %@\n",[self identifier], [self streamDescription]);
        return NO;
    }
}

- (bool) fcioClose
{
    DEBUG_PRINT( "%s %s: fcioClose\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);

    if(reader)
        FCIODestroyStateReader(reader);
    reader = NULL;

    if(processor)
        FSPDestroy(processor);
    processor = NULL;

    if(fcio_mem_writer)
        FCIODisconnect(fcio_mem_writer);
    fcio_mem_writer = NULL;

    switch (fcio_last_tag) {
        // fcio_last_tag contains the last valid tag, if read
        // The readout-fc250b binary should always send an FCIOStatus record on normal exit.
        // If it exits without reading any data from the hardware, it might send an FCIOConfig
        case FCIOStatus: {
            NSLog(@"%@: FCIO stream closed.\n", [self identifier]);
            return YES;
        }
        case FCIOConfig: {
            NSLog(@"%@: FCIO stream closed early with FCIOConfig.\n", [self identifier]);
            break;
        }
        case -2: {
            NSLog(@"%@: FCIO stream never connected.\n", [self identifier]);
            break;
        }
        default: {
            NSLog(@"%@: FCIO stream closed with unexpected tag %d.\n", [self identifier], fcio_last_tag);
            break;
        }
    }
    return NO;
}

- (void) updateRecordSizes:(FCIOState*) state and:(FSPState*) fspstate
{
    // TODO make this as performant as possible - prevent lot's of calculations, check they are needed
    FCIOStateCalculateRecordSizes(state, &fcioSizes);
    FSPCalculateRecordSizes(processor, fspstate, &fcioSizes);
}


- (bool) fcioRead:(ORDataPacket*) aDataPacket
{
    if (listenerRemoteIsFile && ![runTask isRunning] && reader->timeout) {
        // if the remote is a file, reading EOF is a signal that we do not have
        // any more data to read.
        // FCIOGetNextState will wait for its timeout to see if there is more.
        // if the runTask is not running any longer, no more data will come
        // and we can savely reduce the timeout to 0
        // This will reduce waiting times at the end of run. Especially important
        // if multiple listeners are connected with high timeouts (a few seconds)
        FCIOTimeout(reader->stream, 0); // set the library timeout
        reader->timeout = 0; // unfortunately the timeout variable has to be set
                             // manually for separate internal code sections.
    }



    FCIOState* state = NULL;
    FSPState* fspstate = NULL;

    int timedout = 0; // contains timeout reason
    // no software trigger and real-time processing, just read the data from FlashCam
    if (!processor) {
        if ( ! (state = FCIOGetNextState(reader, &timedout))) {
            DEBUG_PRINT( "%s %s: fcioRead: end-of-stream: timedout %d\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String], timedout);
            if (timedout == 1 && !listenerRemoteIsFile)
                NSLog(@"%@: FCIO stream closed due to timeout.\n", [self identifier]);
            else if (timedout == 2)
                NSLog(@"%@: FCIO stream closed due to timeout, however deselected records arrived.\n", [self identifier]);
            return NO;
        }
    // additionally process all records, reading of FlashCam data is handled internally
    } else {
        if (!(fspstate = FSPGetNextState(processor, reader, &timedout))) {
            DEBUG_PRINT( "%s %s: fcioRead: end-of-stream: timedout %d\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String], timedout);
            if (timedout == 1 && !listenerRemoteIsFile)
                NSLog(@"%@: FCIO stream closed due to timeout.\n", [self identifier]);
            else if (timedout == 2)
                NSLog(@"%@: FCIO stream closed due to timeout, however deselected records arrived.\n", [self identifier]);
            else if (timedout == 10)
                NSLogColor([NSColor redColor], @"%@: post processor buffer overflow. Increase the ReadoutModel state buffer size.\n",[self identifier]);
        }

        if (FSPStatsUpdate(processor, !fspstate)) {
            // returns one if stats have been updated, or if the stream ends.
            // only updates states for every fsp log time period
            [swtBufferFillLevelHistory  addDataToTimeAverage:(float)FSPFreeStates(processor)];
            [swtDiscardRateHistory addDataToTimeAverage:(float)processor->stats->dt_rate_discard_events];
            [swtOutputRateHistory  addDataToTimeAverage:(float)processor->stats->dt_rate_write_events];

            [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelSWTStatusChanged object:self];
        }

#ifdef DEBUG_FSP
        int fspLogLevel = [[self configParam:@"fspLogLevel"] intValue];
        if (FSPStatsUpdate(processor, !fspstate)) {
            // returns one if stats have been updated, or if the stream ends.
            if (fspLogLevel > 0) {
                char logstring[255];
                if (FSPStatsInfluxString(postprocessor, logstring, 255))
                    fprintf(stderr, "%s: postprocessor %s\n", [[self identifier] UTF8String],logstring);
            }
        }
        char statestring[19] = {0};
        FSPFlags2char(fspstate, 18, statestring);
        if (!fspstate->write) {
            if (fspLogLevel > 5) {
                fprintf(stderr, "%s: postprocessor record_flags=%s\n", [[self identifier] UTF8String], statestring);
            }
        } else {
            if (fspLogLevel > 2 && fspstate->stream_tag != FCIOStatus) {
                fprintf(stderr, "%s: postprocessor record_flags=%s ge,multi=%d,min=%d,max=%d sipm,sum=%f,max=%f,mult=%d,offset=%d fill_level=%d\n",
                        [[self identifier] UTF8String], statestring,
                        fspstate->majority,fspstate->ge_min_fpga_energy, fspstate->ge_max_fpga_energy,
                        fspstate->largest_sum_pe, fspstate->largest_pe,
                        fspstate->channel_multiplicity,fspstate->largest_sum_offset,
                        FSPBufferFillLevel(postprocessor->buffer)
                        );
            }
        }
#endif
        if (!fspstate)
            return NO; // stream has ended - similar to FCIOGetNextState
        state = fspstate->state; // set current read record

//        if (!fspstate->write_flags.write && !writeNonTriggered) // write to output even if software trigger did not trigger
//            return YES;
    }
    // keep this for consistency check after the stream ended
    fcio_last_tag = state->last_tag;

    switch(fcio_last_tag) {
        case FCIOStatus: {
            for (int i = 0; i < state->status->cards; i++) {
                unsigned int ID = state->status->data[i].reqid;
                for(id dict in cardMap){
                    if([[dict objectForKey:@"fcioID"] unsignedIntValue] == ID){
                        [[dict objectForKey:@"card"] readStatus:state->status atIndex:i];
                        break;
                    }
                }
            }
        }
    }

    // fspstate is allowed to be NULL - it steers the output depending on SoftwareTrigger activation.
    return [self shipFCIO:aDataPacket state:state fspState:fspstate];
}

- (size_t) dataRecordSize:(int) write_tag fcioState:(FCIOState*) state fspState:(FSPState*) fspstate
{
    size_t requiredSize = 0;

    switch (write_tag) {
        case FCIOConfig:
            requiredSize += fcioSizes.protocol + fcioSizes.config;
            // Orca extends the config record by shipping board revisions and hardware ids
            requiredSize += state->config->adcs * (3 * sizeof(uint8_t) + sizeof(uint64_t)) + 4 * sizeof(int);
            break;
        case FCIOEvent:
            requiredSize += fcioSizes.event;
            break;
        case FCIOSparseEvent:
            requiredSize += fcioSizes.sparseevent;
            break;
        case FCIOEventHeader:
            requiredSize += fcioSizes.eventheader;
            break;
        case FCIOStatus:
            requiredSize += fcioSizes.status;
            break;
    }

    if (fspstate) switch (write_tag) {
        case FCIOConfig:
            requiredSize += fcioSizes.fspconfig;
            break;
        case FCIOEvent:
        case FCIOSparseEvent:
        case FCIOEventHeader:
            requiredSize += fcioSizes.fspevent;
            break;
        case FCIOStatus:
            requiredSize += fcioSizes.fspstatus;
            break;
    }
    return requiredSize;
}

- (int) getWriteTag:(FCIOState*) state and:(FSPState*) fspstate
{
    if (fspstate && (fspstate->write_flags.write))
        return state->last_tag;

    else switch (state->last_tag) {
        case FCIOEvent:
        case FCIOSparseEvent:
            return FCIOEventHeader;
    }
    return state->last_tag;
}

- (uint32_t) getWriteDataId:(int) tag
{
    switch (tag) {
        case FCIOConfig:
            return configId;
        case FCIOSparseEvent:
        case FCIOEvent:
        case FCIOEventHeader:
            return eventId;
        case FCIOStatus:
            return statusId;
        default:
            return 0;
    }
}

- (int) addBoardInfoToRecord:(FCIOStream) stream from:(fcio_config*) config
{
    size_t br_data_size = config->adcs * sizeof(uint8_t) ;
    size_t hwid_data_size = config->adcs * sizeof(uint64_t);
    size_t crate_number_size = config->adcs * sizeof(uint8_t);
    size_t crate_slot_size = config->adcs * sizeof(uint8_t);

    uint8_t br_buffer[FCIOMaxChannels];
    uint64_t hwid_buffer[FCIOMaxChannels];

    uint8_t crate_number[FCIOMaxChannels];
    uint8_t crate_slot[FCIOMaxChannels];
    

    for (int i = 0; i < config->adcs; i++) {
        uint16_t addr = (config->tracemap[i] & 0xFFFF0000) >> 16;

        for(id obj in [readOutList children]){
            if([[obj object] cardAddress] != (uint32_t) addr)
                continue;

            br_buffer[i] = [[obj object] boardRevision];
            hwid_buffer[i] = [[obj object] hardwareID];
            crate_number[i] = [[obj object] crateNumber];
            crate_slot[i] = [[obj object] slot];
            break;
        }
    }
    int written_size = 0;
    written_size += FCIOWrite(stream, (int)br_data_size, br_buffer);
    written_size += FCIOWrite(stream, (int)hwid_data_size, hwid_buffer);
    written_size += FCIOWrite(stream, (int)crate_number_size, crate_number);
    written_size += FCIOWrite(stream, (int)crate_slot_size, crate_slot);

    if (FCIOFlush(stream))
        return 0;

    return written_size;
}

- (int) ORExtendFCIOState:(FCIOStream) stream from: (FCIOState*) state as:(int)writeTag
{
    switch (writeTag)
        case FCIOConfig:
            return [self addBoardInfoToRecord:stream from:state->config];
    return -1;
}

- (bool) shipFCIO:(ORDataPacket*)aDataPacket state:(FCIOState*)state fspState: (FSPState*)fspstate
{
    if (!state) {
        DEBUG_PRINT( "%s %s: shipFCIO no FCIOState\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
        return NO;
    }

    [self updateRecordSizes:state and: fspstate];

    uint32_t header_length = 3; // dataId + recordLength + readout/listenerId
    size_t header_size = header_length * sizeof(int32_t);

    // determines the output depending on write_flags if fspstate is present
    int writeTag = [self getWriteTag:state and: fspstate];

    size_t recordSize = header_size + [self dataRecordSize:writeTag fcioState:state fspState:fspstate];

    // calculate the required size in units of int32_t
    uint32_t recordLength = (uint32_t)recordSize / sizeof(int32_t) + (recordSize % sizeof(int32_t) != 0);

    // get a slot to write the data to, using getBlockForAddingLongs to prevent memcpy
    uint32_t* dataRecord = [aDataPacket getBlockForAddingLongs: recordLength];

    // get dataId corresponding to the FCIOTag which was read from stream
//    uint32_t dataId = [self getWriteDataId:writeTag];
    uint32_t dataId = listenerDataId;
    if ( !dataId ) {
        DEBUG_PRINT( "%s %s: shipFCIO no valid dataId\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
        return NO;
    }


    dataRecord[0] = dataId; // use extended format, write recordLength to the second entry
    dataRecord[1] = recordLength;

    /* FlashCamIO Header */
    dataRecord[2]  = ((unsigned short) [guardian uniqueIdNumber]) << 16; // ReadoutID
    dataRecord[2] |=  (unsigned short) [self uniqueIdNumber];            // ListenerID

    char* start_ptr = (char*)&dataRecord[header_length]; // from here FCIO is allowed to write
    char* end_ptr = (char*)&dataRecord[recordLength]; // up to here FCIO is allowed to write
    char* data_ptr = start_ptr;

    size_t stream_size_offset = FCIOStreamBytes(fcio_mem_writer, 'w', 0);

    if (!fcio_mem_writer) { // need to initialize the FCIOWriter
        if (writeTag != FCIOConfig) // only do this on FCIOConfig - otherwise the received FCIO data stream is malformed
            return NO;

        NSString* peer = [NSString stringWithFormat:@"mem://%p/%zu", data_ptr, end_ptr - data_ptr];

        fcio_mem_writer = FCIOConnect([peer UTF8String] , 'w', 0, 0); // writes the PROTOCOL TAG (4 bytes) and PROTOCOL string (64 bytes)
        data_ptr = start_ptr + FCIOStreamBytes(fcio_mem_writer, 'w', stream_size_offset);
        if (data_ptr > end_ptr)
            return NO;
        DEBUG_PRINT("Connect total %zu remaining %zu\n", data_ptr - start_ptr, end_ptr - data_ptr );
    }

    FCIOSetMemField(fcio_mem_writer, data_ptr, end_ptr - data_ptr);
    FCIOPutState(fcio_mem_writer, state, writeTag);
    data_ptr = start_ptr + FCIOStreamBytes(fcio_mem_writer, 'w', stream_size_offset);
    DEBUG_PRINT("State total %zu remaining %zu\n", data_ptr - start_ptr, end_ptr - data_ptr );
    if (data_ptr > end_ptr)
        return NO;

    FCIOSetMemField(fcio_mem_writer, data_ptr, end_ptr - data_ptr);
    [ self ORExtendFCIOState:fcio_mem_writer from:state as:writeTag]; // we append additional fields to the fcio record, might be 0 bytes if there are none
    data_ptr = start_ptr + FCIOStreamBytes(fcio_mem_writer, 'w', stream_size_offset);
    DEBUG_PRINT("ORCA total %zu remaining %zu\n", data_ptr - start_ptr, end_ptr - data_ptr );
    if (data_ptr > end_ptr)
        return NO;

    FCIOSetMemField(fcio_mem_writer, data_ptr, end_ptr - data_ptr);
    FCIOPutFSP(fcio_mem_writer, processor, writeTag); // append the software trigger output, only if processor exists
    data_ptr = start_ptr + FCIOStreamBytes(fcio_mem_writer, 'w', stream_size_offset);
    DEBUG_PRINT("FSP total %zu remaining %zu\n", data_ptr - start_ptr, end_ptr - data_ptr );
    if (data_ptr > end_ptr)
        return NO;

//    FCIOWriteMessage(fcio_mem_writer, 0); // EOF tag, allows the reading side to continue until this is found and skip the rest
//    data_ptr = start_ptr + FCIOStreamBytes(fcio_mem_writer, 'w', stream_size_offset);
//    fprintf(stderr, "DEBUG END total %zu remaining %zu\n", data_ptr - start_ptr, end_ptr - data_ptr );

    // zero-pad the remaining buffer, allows the reading side to continue reading until recordLength is reached.
    while( data_ptr < end_ptr)
        *data_ptr++ = 0;
    DEBUG_PRINT("ZERO total %zu remaining %zu\n", data_ptr - start_ptr, end_ptr - data_ptr );

    return YES;
}

- (void) runFailed
{
    DEBUG_PRINT( "%s %s: runFailed\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
    [self performSelectorOnMainThread:@selector(runFailedMainThread) withObject:nil waitUntilDone:NO];
}

- (void) runFailedMainThread
{
    DEBUG_PRINT( "%s %s: runFailedMainThread\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRequestRunHalt object:self];
    if(!runFailedAlarm){
        runFailedAlarm = [[ORAlarm alloc] initWithName:@"FlashCamListener run failed"
                                              severity:kRunInhibitorAlarm];
        [runFailedAlarm setSticky:NO];
    }
    if(![runFailedAlarm isPosted]){
        [runFailedAlarm setAcknowledged:NO];
        [runFailedAlarm postAlarm];
    }
}

#pragma mark •••Task methods

- (bool) waitForReady
{

    bool waitForGuardianReady = YES;
    bool waitForFileName = YES;
    while ( currentStartupTime < timeout ) {

        [ORTimer delay: 0.05];
        currentStartupTime += 50; // seconds to milliseconds

        waitForGuardianReady = (guardian && ![guardian readoutReady]);

        listenerRemoteIsFile = [[self configParam:@"extraFiles"] boolValue];
        waitForFileName = listenerRemoteIsFile && !dataFileName;

        if (!waitForGuardianReady && !waitForFileName) {
            return YES;
        }
    }
    if (waitForGuardianReady)
        NSLogColor([NSColor redColor], @"%@: setupReadoutTask guardian (ADCCard) not ready after %dms.\n", [self identifier], currentStartupTime);

    if (waitForFileName)
        NSLogColor([NSColor redColor], @"%@: setupReadoutTask Filename not know after %dms.\n", [self identifier], currentStartupTime);

    return NO;
}

- (bool) waitForTakingData
{
    while ( currentStartupTime < timeout ) {

        [ORTimer delay: 0.05];
        currentStartupTime += 50; // seconds to milliseconds

        if (takingData) {
            return YES;
        }
    }
    return NO;
}

- (bool) waitForReadoutTaskToStop
{
    int currentStopTime = 0;
    while ( currentStopTime < timeout ) {

        [ORTimer delay: 0.05];
        currentStopTime += 50; // seconds to milliseconds

        if (runTaskCompleted) {
            return YES;
        }
    }
    return NO;
}



- (void) setupReadoutTask
{
    [self updateIP];
    if([ip isEqualToString:@""]){
        NSLogColor([NSColor redColor], @"%@: unable to obtain IP address for interface %@\n",[self identifier], interface);
        return;
    }

    NSMutableArray*  readoutArgs   = [NSMutableArray array];
    [readoutArgs addObjectsFromArray:[self readOutArgs]];
    NSMutableString* addressList   = [NSMutableString string];
    NSMutableArray*  argCard       = [NSMutableArray  array];
    NSMutableArray*  orcaChanMap   = [NSMutableArray  array];
    NSMutableArray*  orcaCardMap   = [NSMutableArray  array];
    NSMutableArray*  adcCards      = [NSMutableArray  array];
    NSMutableSet*    triggerCards  = [NSMutableSet    set];
    NSMutableSet*    gtriggerCards = [NSMutableSet    set];
    // add the adc cards to the address list and their arguments to the list
    unsigned int adcCardCount = 0;
    int maxShapeTime = 0;
    for(ORReadOutObject* obj in [readOutList children]){
        if(![[obj object] isKindOfClass:NSClassFromString(@"ORFlashCamCard")]) continue;
        ORFlashCamCard* card = (ORFlashCamCard*) [obj object];
        if([card isKindOfClass:NSClassFromString(@"ORFlashCamADCModel")]){

            ORFlashCamADCModel* adc = (ORFlashCamADCModel*) card;
            [addressList appendString:[NSString stringWithFormat:@"%x,", [adc cardAddress]]];
            [adcCards addObject:adc];
            [argCard addObjectsFromArray:[adc runFlagsForCardIndex:adcCardCount
                                                  andChannelOffset:adcCardCount*[adc numberOfChannels]
                                                       withTrigAll:[[self configParam:@"trigAllEnable"] boolValue]]];

            for(unsigned int ich=0; ich<[adc numberOfChannels]; ich++){
                if([adc chanEnabled:ich]){
                    NSDictionary* chDict = [NSDictionary dictionaryWithObjectsAndKeys:adc, @"adc", [NSNumber numberWithUnsignedInt:ich], @"channel", nil];
                    [orcaChanMap addObject:chDict];
                    maxShapeTime = MAX(maxShapeTime, [adc shapeTime:ich]);
                }
            }
            adcCardCount ++;
            // if this adc is connected to a trigger card, add to the respective set
            if([[card trigConnector] isConnected]){
                id conobj = [[card trigConnector] connectedObject];
                NSString* cname = [conobj className];
                if([cname isEqualToString:@"ORFlashCamGlobalTriggerModel"]) [gtriggerCards addObject:conobj];
                else if([cname isEqualToString:@"ORFlashCamTriggerModel"])  [triggerCards  addObject:conobj];
            }
        }
    }
    if (adcCardCount == 0) {
        NSLogColor([NSColor redColor], @"%@: no ADC Card in the readout list.\n", [self identifier]);
        return;
    }

    // check if the number of channels exceeds the hardware limit for flashcam
    if([orcaChanMap count] > FCIOMaxChannels){
        NSLogColor([NSColor redColor], @"%@: failed to start run due to number "
                   "of enabled channels %d exceeding the FCIO architectural limit of %d\n",
                   [self identifier], [orcaChanMap count], FCIOMaxChannels);
        return;
    }
    [self setChanMap:orcaChanMap];
    // make sure the shaping time and event samples are such that flashcam will silently change the waveform length
    if([[self configParam:@"traceType"] intValue] != 0){
        if(MIN(8000, 20+maxShapeTime*2.5/16) > [[self configParam:@"eventSamples"] intValue]){
            int samples = [[self configParam:@"eventSamples"] intValue];
            NSLogColor([NSColor redColor], @"%@: failed to start run due to max shaping "
                       "time of %d ns with event samples set to %d. Set the shaping time for all channels <= %d ns or "
                       "set the event samples >= %d\n", [self identifier], maxShapeTime, samples,
                       (int) ((samples-20)*16/2.5), (int) (20+maxShapeTime*2.5/16));
            return;
        }
    }
    // if the trigger cards are connected to any global trigger cards, add those to the set
    for(id card in triggerCards){
        id conobj = [[card trigConnector] connectedObject];
        NSString* cname = [conobj className];
        if([cname isEqualToString:@"ORFlashCamGlobalTriggerModel"]) [gtriggerCards addObject:conobj];
        else if([cname isEqualToString:@"ORFlashCamGlobalTriggerModel"]) [triggerCards addObject:conobj];
    }
    // check that the trigger  ards are connected to one of the remote interfaces
    NSMutableSet* gtriggers = [NSMutableSet set];
    NSMutableSet* triggers  = [NSMutableSet set];
    for(NSString* e in [self remoteInterfaces]){
        [gtriggers addObjectsFromArray:[guardian connectedObjects:@"ORFlashCamGlobalTriggerModel" toInterface:e]];
        [triggers  addObjectsFromArray:[guardian connectedObjects:@"ORFlashCamTriggerModel"       toInterface:e]];
    }
    [gtriggerCards intersectSet:gtriggers];
    [triggerCards  intersectSet:triggers];
    // add the trigger cards to the address list
    unsigned int ntrig = 0;
    NSMutableString* trigAddr = [NSMutableString string];
    for(id card in triggerCards){
        [trigAddr appendString:[NSString stringWithFormat:@"%x,", [card cardAddress]]];
        if ([gtriggerCards count] > 0) // only add the submaster flags, if there is a global trigger card
            [readoutArgs addObjectsFromArray:[card runFlagsForCardIndex:ntrig]];
        ntrig ++;
    }
    [addressList insertString:trigAddr atIndex:0];
    mergeRunFlags(argCard);
    // make sure there is at most one global trigger card
    if([gtriggerCards count] > 1){
        NSLogColor([NSColor redColor], @"%@: failed to start run due to multiple connected global trigger cards\n", [self identifier]);
        return;
    }
    else if([gtriggerCards count] == 1){
        for(id card in gtriggerCards){
            [addressList insertString:[NSString stringWithFormat:@"%x,", [card cardAddress]] atIndex:0];
            [readoutArgs addObjectsFromArray:[card runFlags]];
        }
    }
    // construct the card mapping
    for(id card in gtriggerCards){
        NSNumber* index = [NSNumber numberWithUnsignedLong:[orcaCardMap count]];
        [orcaCardMap addObject:[NSDictionary dictionaryWithObjectsAndKeys:card, @"card", index, @"fcioID", nil]];
        [card setFCIOID:[index unsignedIntValue]];
    }
    for(id card in triggerCards){
        NSNumber* index = [NSNumber numberWithUnsignedLong:[orcaCardMap count]];
        [orcaCardMap addObject:[NSDictionary dictionaryWithObjectsAndKeys:card, @"card", index, @"fcioID", nil]];
        [card setFCIOID:[index unsignedIntValue]];
    }
    for(id card in adcCards){
        NSNumber* index = [NSNumber numberWithUnsignedLong:[orcaCardMap count]];
        [orcaCardMap addObject:[NSDictionary dictionaryWithObjectsAndKeys:card, @"card", index, @"fcioID", nil]];
        [card setFCIOID:[index unsignedIntValue]];
    }
    [self setCardMap:orcaCardMap];
    // fixme: check for no cards and no enabled channels here
    if ([addressList length] > 0)
        [argCard addObjectsFromArray:@[@"-a", [addressList substringWithRange:NSMakeRange(0, [addressList length]-1)]]];
    else {
        NSLogColor([NSColor redColor], @"%@: setupReadoutTask: addressList is empty - check if all addresses are set correctly.\n", [self identifier]);
        return;
    }
    [readoutArgs addObjectsFromArray:@[@"-ei", [[self remoteInterfaces] componentsJoinedByString:@","]]];
    [readoutArgs addObjectsFromArray:@[@"-et", [self ethType]]];
    [readoutArgs addObjectsFromArray:@[@"-tmio", [@(timeout) stringValue]]]; // reuse the same timeout as the reading side.
    [readoutArgs addObjectsFromArray:[self runFlags:NO]];
    [readoutArgs addObjectsFromArray:argCard];

    //-------added extra, manually entered Flags--------
    //-------MAH 02/1/22--------------------------------
    NSString* extraFlags = [self configParamString:@"extraFlags"];
    if([extraFlags length]>0){
        extraFlags = [extraFlags removeExtraSpaces];
        extraFlags = [extraFlags removeNLandCRs];
        NSArray *extraFlagsArray = [extraFlags componentsSeparatedByString:@" "];
        [readoutArgs addObjectsFromArray:extraFlagsArray];
    }

    [self setReadOutArgs:readoutArgs]; // set args as far as we can, need to store it until startReadoutTask is called.

    enableStreamProcessor = [[self configParam:@"fspEnabled"] boolValue];

    setupFinished = YES;
}

- (void) startReadoutTask
{
    // execute startReadoutTask only from the main Thread!
    // otherwise the notifications and gui updates of the controller might not work.
    NSMutableArray* readoutArgs = [self readOutArgs];
    if (listenerRemoteIsFile && dataFileName != nil) {
        DEBUG_PRINT( "startReadoutTask, remote is file and dataFileName is %s\n", [dataFileName UTF8String]);
        [readoutArgs addObjectsFromArray:@[@"-o", dataFileName]];
    } else {
        NSString* listen = [NSString stringWithFormat:@"tcp://connect/%d/%@", port, ip];
        [readoutArgs addObjectsFromArray:@[@"-o", listen]];
    }

    [runTask release];
    runTask = [[NSTask alloc] init];

    NSPipe* inpipe  = [NSPipe pipe];
    NSPipe* outpipe = [NSPipe pipe];
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];

    [nc addObserver : self
           selector : @selector(taskDataAvailable:)
               name : NSFileHandleReadCompletionNotification
             object : [outpipe fileHandleForReading]];

    [nc addObserver : self
           selector : @selector(taskCompleted:)
               name : NSTaskDidTerminateNotification
             object : runTask];

    [[outpipe fileHandleForReading] readInBackgroundAndNotify];
    [runTask setStandardInput:inpipe];
    [runTask setStandardOutput:outpipe];
    [runTask setStandardError:outpipe];


    NSString* taskPath;
    if([guardian localMode]){
        taskPath = [[[guardian fcSourcePath] stringByExpandingTildeInPath] stringByAppendingString:@"/server/readout-fc250b"];
    }
    else {
        taskPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/remote_run"];
    }

    [runTask setLaunchPath:taskPath];

    [runTask setArguments: [NSArray arrayWithArray:readoutArgs]];
    NSString* ccc = [NSString stringWithFormat:@"%@ %@\n", [runTask launchPath], [[runTask arguments] componentsJoinedByString:@" "]];
    DEBUG_PRINT( "startReadoutTask %s\n", [ccc UTF8String]);
    [self setReadOutArgs:readoutArgs]; // store final readout args

    for(NSString* line in fcrunlog) [self appendToFCLog:line andNotify:NO];
    [fcrunlog removeAllObjects];

    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelFCLogChanged    object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelFCRunLogFlushed object:self];

    NSString* cmd = [NSString stringWithFormat:@"%@ %@\n", [runTask launchPath], [[runTask arguments] componentsJoinedByString:@" "]];
    NSLog(cmd);

    [self appendToFCRunLog:[NSString stringWithFormat:@"%@ %@\n", [[self logDateFormatter] stringFromDate:[NSDate now]], cmd]];

    DEBUG_PRINT( "%s %s: startReadout launching runTask\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
    if(@available(macOS 10.13,*)){
        NSError *error = nil;
        if(![runTask launchAndReturnError:(&error)]){
            NSLogColor([NSColor redColor],@"%@: RunTask failed with error:%@\n",[self identifier], error);
        }
    }
    else {
        //older MacOS's
        [runTask launch];
    }

    startFinished = YES;
    [self setStatus:@"running"];
}

- (void) stopReadoutTask
{
    DEBUG_PRINT( "%s %s: stopReadoutTask runTask isRunning %d\n",
                [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String], [runTask isRunning]);
    if ([runTask isRunning]) {
        NSFileHandle* fh = [[runTask standardInput] fileHandleForWriting];
        bool writeSuccess = [fh writeData:[@"\n" dataUsingEncoding:NSASCIIStringEncoding] error:nil];
        if (!writeSuccess) {
            [runTask terminate];
            DEBUG_PRINT( "%s %s: stopReadoutTask couldn't write EOL to runTask\n",[[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
        }
        DEBUG_PRINT( "%s %s: stopReadoutTask waiting for runTask to stop\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
        [runTask waitUntilExit];
    }
    [self waitForReadoutTaskToStop]; // waits for the final processing of the log output, is set by taskCompleted()

    [self setStatus:@"stopped"];
    DEBUG_PRINT( "%s %s: stopReadoutTask finished\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
}

- (double) parseValueFromFCLog:(NSString*)text withIdentifier:(NSString*)ident andBreak:(NSString*)brk
{
    NSArray* v = [text componentsSeparatedByString:@" "];
    NSUInteger i = [v indexOfObject:ident];
    if(i == NSNotFound)  return 0.0;
    if(i+1 >= [v count]) return 0.0;
    if([brk isEqualToString:@""]) return [[v objectAtIndex:i+1] doubleValue];
    else return [[[[v objectAtIndex:i+1] componentsSeparatedByString:brk] objectAtIndex:0] doubleValue];
}

- (double) parseValueFromFCLog:(NSString*)text withIdentifier:(NSString*)ident
{
    return [self parseValueFromFCLog:text withIdentifier:ident andBreak:@""];
}

- (void) taskDataAvailable:(NSNotification*)note
{
    if([note object] != [[runTask standardOutput] fileHandleForReading])
        return;
    @autoreleasepool {
        NSData* incomingData   = [[note userInfo] valueForKey:NSFileHandleNotificationDataItem];
        if(incomingData && [incomingData length]){
            NSString* incomingText = [[[NSString alloc] initWithData:incomingData encoding:NSASCIIStringEncoding]autorelease];
            NSDictionary* taskData = [NSDictionary dictionaryWithObjectsAndKeys:runTask,@"Task",incomingText,@"Text",nil];
            [self taskData:taskData];
        }
        if([runTask isRunning]) [[note object] readInBackgroundAndNotify];
    }

}

- (NSDateFormatter*) logDateFormatter
{
    if(!logDateFormatter){
        logDateFormatter = [[NSDateFormatter alloc] init]; //allocate  here, dealloc later
        logDateFormatter.locale = [NSLocale currentLocale];
        [logDateFormatter setLocalizedDateFormatFromTemplate:@"MM/dd/yy HH:mm:ss"];
    }
    return logDateFormatter;
}

- (ANSIEscapeHelper*) ansieHelper
{
    if(!ansieHelper){
        ansieHelper = [[ANSIEscapeHelper alloc] init]; //allocate  here, dealloc later
        [ansieHelper setFont:[NSFont fontWithName:@"Courier New" size:12]];
        [ansieHelper setDefaultStringColor:[NSColor redColor]];
    }
    return ansieHelper;
}

- (void) taskData:(NSDictionary*)taskData
{
    if([taskData objectForKey:@"Task"] != runTask) return;
    NSString* incomingText = [taskData objectForKey:@"Text"];
    NSArray* incomingLines = [incomingText componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    for(NSString* aLine in incomingLines){
        if([aLine isEqualToString:@""]) continue;
         [self appendToFCRunLog:[NSString stringWithFormat:@"%@ %@\n",
                                [[self logDateFormatter] stringFromDate:[NSDate now]], aLine]];
        if([aLine rangeOfString:@"error"   options:NSCaseInsensitiveSearch].location != NSNotFound ||
           [aLine rangeOfString:@"warning" options:NSCaseInsensitiveSearch].location != NSNotFound){
            NSLogAttr([[self ansieHelper] attributedStringWithANSIEscapedString:[self fcrunlog:0]]);
        }
        else if([aLine rangeOfString:@"FC250bMapFadc"].location == 0){
            NSMutableArray* a = [NSMutableArray arrayWithArray:[aLine componentsSeparatedByString:@" "]];
            [a removeObjectsInArray:[NSArray arrayWithObject:@""]];
            NSString* addr = @"";
            NSString* hwid = @"";
            for(NSUInteger i=0; i<[a count]-9; i++){
                NSString* s = [a objectAtIndex:i];
                if([s isEqualToString:@"adr"])     addr = [a objectAtIndex:i+1];
                else if([s isEqualToString:@"id"]) hwid = [a objectAtIndex:i+9];
            }
            bool success = false;
            if(addr && hwid){
                @try{
                    unsigned int address;
                    NSScanner* scan = [NSScanner scannerWithString:addr];
                    [scan scanHexInt:&address];
                    for(id obj in [readOutList children]){
                        if([[obj object] respondsToSelector:@selector(cardAddress)] &&
                           [[obj object] respondsToSelector:@selector(setUniqueHWID:)]){
                            if((address = [[obj object] cardAddress])){
                                [[obj object] setUniqueHWID:hwid];
                                success = true;
                                break;
                            }
                        }
                    }
                }
                @catch(NSException* e){
                    NSLogColor([NSColor redColor], @"%@: exception parsing address %@ "
                               " or unique hardware ID %@\n", [self identifier], addr, hwid);
                    [self runFailed];
                }
            }
            if(!success){
                NSLogColor([NSColor redColor], @"%@: unable to parse mapping %@\n", [self identifier], aLine);
                [self runFailed];
            }
        }
        NSRange r0 = [aLine rangeOfString:@"event"];
        NSRange r1 = [aLine rangeOfString:@"OK/running"];
        if(r0.location != NSNotFound && r1.location != NSNotFound){
            // if the readout is running, parse the log command
            if(r1.location <= r0.location+r0.length) continue;
            NSRange r = NSMakeRange(r0.location+r0.length+1, r1.location-r0.location-r0.length-2);
            NSArray* a = [[aLine substringWithRange:r] componentsSeparatedByString:@","];
            if([a count] != 6) continue;
            eventCount = [[a objectAtIndex:0] intValue];
            runTime    = [self parseValueFromFCLog:[a objectAtIndex:1] withIdentifier:@"sec"];
            readMB     = [self parseValueFromFCLog:[a objectAtIndex:2] withIdentifier:@"MB"   andBreak:@"/"];
            rateMB     = [self parseValueFromFCLog:[a objectAtIndex:4] withIdentifier:@"MB/s" andBreak:@"/"];
            rateHz     = [self parseValueFromFCLog:[a objectAtIndex:5] withIdentifier:@"evt/s"];
            timeLock   = [self parseValueFromFCLog:[a objectAtIndex:5] withIdentifier:@"lock"];
            deadTime   = [self parseValueFromFCLog:[a objectAtIndex:5] withIdentifier:@"dead"];
            NSArray* v = [[[a objectAtIndex:5] stringByReplacingOccurrencesOfString:@"%" withString:@""] componentsSeparatedByString:@" "];
            if([v count] >= 10){
                totDead = [[v objectAtIndex:[v count]-2] doubleValue];
                curDead = [[v objectAtIndex:[v count]-1] doubleValue];
            }
            else{
                totDead = -1.0;
                curDead = -1.0;
            }
            [dataRateHistory  addDataToTimeAverage:(float)rateMB];
            [eventRateHistory addDataToTimeAverage:(float)rateHz];
            [deadTimeHistory  addDataToTimeAverage:(float)curDead];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelStatusChanged object:self];
}

- (void) taskCompleted:(NSNotification*)note
{
    // reset the hardare id to 0 since they will be read again at the start of the next run
    if([note object] == runTask){
        for(id obj in [readOutList children]){
            if([obj respondsToSelector:@selector(setBoardRevision:)] &&
               [obj respondsToSelector:@selector(setHardwareID:)]){
                [obj setBoardRevision:0];
                [obj setHardwareID:0];
            }
        }
        // read to the end of the run task's standard output
        NSData* data = [[[runTask standardOutput] fileHandleForReading] readDataToEndOfFile];
        if(data && [data length]){
            NSString*     text     = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            NSDictionary* taskData = [NSDictionary dictionaryWithObjectsAndKeys:runTask,@"Task",text,@"Text",nil];
            [self taskData:taskData];
            [text release];
        }
        [[[runTask standardInput]  fileHandleForWriting] closeFile];
        [[[runTask standardOutput] fileHandleForReading] closeFile];

        // if the readout process stops for some reason other than it being terminated in the run stopping,
        // there were errors, so stop the run
        if ([runTask terminationStatus]) {
            NSLog(@"%@: readout process terminated unexpectedly with exit code: %d\n",
                  [self identifier], [runTask terminationStatus]);
            [self runFailed];
        }
    }

    uint32_t runState = [gOrcaGlobals runState];
    if(runState != eRunStopped && runState != eRunStopping)
        [self runFailed];
    // remove notification observers
    NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:NSFileHandleReadCompletionNotification object:nil];
    [nc removeObserver:self name:NSTaskDidTerminateNotification object:nil];

    // signal that all lines have been read and the log-parsing is finished
    runTaskCompleted = YES;
}

#pragma mark •••Data taker methods
- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    // check the listenerThreadMain method
    takingData = YES;
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    DEBUG_PRINT( "%s %s: runTaskStarted\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
    if(runFailedAlarm) [runFailedAlarm clearAlarm];
    unrecognizedPacket = false;
    if(!unrecognizedStates) unrecognizedStates = [[NSMutableArray array] retain];
    [unrecognizedStates removeAllObjects];
    [readOutArgs removeAllObjects];

    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORFlashCamListenerModel"];

    if(!dataPacketForThread)dataPacketForThread = [[ORDataPacket alloc]init];
    [dataPacketForThread setDataTask:[aDataPacket dataTask]];

    [listenerThread release];
    listenerThread = [[NSThread alloc] initWithTarget:self
                                           selector:@selector(listenerThreadMain:)
                                            object:dataPacketForThread];

    [listenerThread start]; // all setup and startup is done inside the thread
    /* due to the threaded datataking in the listener, we cannot start the thread and runTask here,
       as they could start writing data before the full startup chain of runTaskStarted calls is completed.
       We could either wait for a notification which depends on the connected objects, or wait until the last
       possible moment, which is when takeData is called. Only then does the system expect some data to arrive.
       The second approach is used.
     */

    dataTakers = [[readOutList allObjects] retain];
    NSEnumerator* e = [[readOutList allObjects] objectEnumerator];
    id obj;
    while(obj = [e nextObject]) [obj runTaskStarted:aDataPacket userInfo:userInfo];
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    DEBUG_PRINT( "%s %s: runIsStopping\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
    stopRunning = YES;
    takingData = NO;
    while(![listenerThread isFinished] && [listenerThread isExecuting])
        ;

    stopRunning = NO;
    runTaskCompleted = NO;

    // allow the connected data takers to write any remaining data
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]) [obj runIsStopping:aDataPacket userInfo:userInfo];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    DEBUG_PRINT( "%s %s: runTaskStopped\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
    [dataFileName release];
    dataFileName = nil;
    listenerRemoteIsFile = NO;

    currentStartupTime = 0;

    [readOutArgs removeAllObjects];

    [self setChanMap:nil];
    [self setCardMap:nil];

    // we keep the readerThread and runTask objects alive
    // so we can check on their state between runs.

    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]) [obj runTaskStopped:aDataPacket userInfo:userInfo];
    [dataTakers release];
    dataTakers = nil;
}

- (void) saveReadOutList:(NSFileHandle*)aFile
{
    [readOutList saveUsingFile:aFile];
}

- (void) loadReadOutList:(NSFileHandle*)aFile
{
    [self setReadOutList:[[[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"] autorelease]];
    [readOutList loadUsingFile:aFile];
}

- (void) reset
{
    [self disconnect];
    [readOutArgs removeAllObjects];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    NSDictionary* dl =  [NSDictionary dictionaryWithObjectsAndKeys:
                        @"ORFCIODecoder",                                    @"decoder",
                        [NSNumber numberWithLong:listenerDataId],            @"dataId",
                        [NSNumber numberWithBool:YES],                       @"variable",
                        [NSNumber numberWithLong:-1],                        @"length",
                        [NSNumber numberWithLong:[self uniqueIdNumber]],     @"listenerId",
                        [NSNumber numberWithLong:[guardian uniqueIdNumber]], @"readoutId",
                        nil];
    [dict setObject:dl forKey:@"FlashCamDataStream"];
//    NSDictionary* dc = [NSDictionary dictionaryWithObjectsAndKeys:
//                        @"ORFCIODecoder",                                @"decoder",
//                        [NSNumber numberWithLong:configId],              @"dataId",
//                        [NSNumber numberWithBool:YES],                   @"variable",
//                        [NSNumber numberWithLong:-1],                    @"length", nil];
//    NSDictionary* ds = [NSDictionary dictionaryWithObjectsAndKeys:
//                        @"ORFCIODecoder",                                @"decoder",
//                        [NSNumber numberWithLong:statusId],              @"dataId",
//                        [NSNumber numberWithBool:YES],                   @"variable",
//                        [NSNumber numberWithLong:-1],                    @"length", nil];
//    NSDictionary* de = [NSDictionary dictionaryWithObjectsAndKeys:
//                        @"ORFCIODecoder",                                @"decoder",
//                        [NSNumber numberWithLong:eventId],               @"dataId",
//                        [NSNumber numberWithBool:YES],                   @"variable",
//                        [NSNumber numberWithLong:-1],                    @"length", nil];
//    [dict setObject:dc forKey:@"FlashCamConfig"];
//    [dict setObject:ds forKey:@"FlashCamStatus"];
//    [dict setObject:de forKey:@"FlashCamEvent"];
    return dict;
}


#pragma mark •••Archival

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setInterface:       [decoder decodeObjectForKey:@"interface"]];
    [self setPort:  (uint16_t)[decoder decodeIntForKey:@"port"]];
    [self setRemoteInterfaces:[decoder decodeObjectForKey:@"remoteInterfaces"]];
    [self setTimeout:         [decoder decodeIntForKey:@"timeout"]];
    [self setIObuffer:        [decoder decodeIntForKey:@"ioBuffer"]];
    [self setStateBuffer:     [decoder decodeIntForKey:@"stateBuffer"]];
    if(configParams) [configParams release];
    configParams = [[decoder decodeObjectForKey:@"configParams"] retain];
    reader            = NULL;
    readerRecordCount = 0;
    bufferedRecords   = 0;
    listenerRemoteIsFile = NO;

    fspPSChannelMap = (int*)calloc(FCIOMaxChannels, sizeof(int));
    fspPSChannelGains = (float*)calloc(FCIOMaxChannels, sizeof(float));
    fspPSChannelThresholds = (float*)calloc(FCIOMaxChannels, sizeof(float));
    fspPSChannelShapings = (int*)calloc(FCIOMaxChannels, sizeof(int));
    fspPSChannelLowPass = (float*)calloc(FCIOMaxChannels, sizeof(float));
    fspHWChannelMap = (int*)calloc(FCIOMaxChannels, sizeof(int));
    fspHWPrescaleThresholds = (unsigned short*)calloc(FCIOMaxChannels, sizeof(unsigned short));
    fspFlagChannelMap = (int*)calloc(FCIOMaxChannels, sizeof(int));
    fspFlagChannelThresholds = (int*)calloc(FCIOMaxChannels, sizeof(int));

    eventCount        = 0;
    runTime           = 0.0;
    readMB            = 0.0;
    rateMB            = 0.0;
    rateHz            = 0.0;
    timeLock          = 0.0;
    deadTime          = 0.0;
    totDead           = 0.0;
    curDead           = 0.0;
    dataRateHistory   = [[ORTimeRate alloc] init];
    [dataRateHistory  setLastAverageTime:[NSDate date]];
    [dataRateHistory  setSampleTime:10];
    eventRateHistory  = [[ORTimeRate alloc] init];
    [eventRateHistory setLastAverageTime:[NSDate date]];
    [eventRateHistory setSampleTime:10];
    deadTimeHistory   = [[ORTimeRate alloc] init];
    [deadTimeHistory  setLastAverageTime:[NSDate date]];
    [deadTimeHistory  setSampleTime:10];
    swtBufferFillLevelHistory    = [[ORTimeRate alloc] init];
    [swtBufferFillLevelHistory   setLastAverageTime:[NSDate date]];
    [swtBufferFillLevelHistory   setSampleTime:10];
    swtDiscardRateHistory   = [[ORTimeRate alloc] init];
    [swtDiscardRateHistory  setLastAverageTime:[NSDate date]];
    [swtDiscardRateHistory  setSampleTime:10];
    swtOutputRateHistory    = [[ORTimeRate alloc] init];
    [swtOutputRateHistory   setLastAverageTime:[NSDate date]];
    [swtOutputRateHistory   setSampleTime:10];
    chanMap           = nil;
    [self setReadOutList:[decoder decodeObjectForKey:@"readOutList"]];
    fclogIndex = 0;
    fclog      = nil;
    [self setFCLogLines:[decoder decodeIntForKey:@"fclogLines"]];
    fcrunlog = [[NSMutableArray arrayWithCapacity:[self fclogLines]] retain];
    dataFileObject = nil;
    listenerThread = nil;
    startFinished = NO;
    setupFinished = NO;
    stopRunning = NO;
    takingData = NO;
    runTaskCompleted = NO;
    dataFileName = nil;

    currentStartupTime = 0;

    [self registerNotificationObservers];

    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:interface           forKey:@"interface"];
    [encoder encodeInt:(int)port              forKey:@"port"];
    [encoder encodeObject:remoteInterfaces    forKey:@"remoteInterfaces"];
    [encoder encodeObject:configParams        forKey:@"configParams"];
    [encoder encodeInt:timeout                forKey:@"timeout"];
    [encoder encodeInt:ioBuffer               forKey:@"ioBuffer"];
    [encoder encodeInt:stateBuffer            forKey:@"stateBuffer"];
    [encoder encodeObject:readOutList         forKey:@"readOutList"];
    [encoder encodeInt:(int)[self fclogLines] forKey:@"fclogLines"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    [dictionary setObject:[self className] forKey:@"Class Name"];
    [dictionary setObject:[NSNumber numberWithUnsignedInt:[self uniqueIdNumber]] forKey:@"uniqueID"];
    [dictionary setObject:interface forKey:@"interface"];
    [dictionary setObject:[NSNumber numberWithUnsignedInt:port] forKey:@"port"];
    for(id key in configParams) [dictionary setObject:[configParams objectForKey:key] forKey:key];

    return dictionary;
}

- (void) writeFCIOLog:(NSNotification*)note
{
    if(![[self configParam:@"writeFCIOLog"] boolValue]) return;
    NSString* fname = [NSString stringWithFormat:@"%@_FCIO_%lu.log",
                       [[note userInfo] objectForKey:@"statusFileNameBase"], (unsigned long)[self tag]];
    NSString* fullName = [[[[[note object] statusFolder] finalDirectoryName]
                           stringByExpandingTildeInPath] stringByAppendingPathComponent:fname];
    [[NSFileManager defaultManager] createFileAtPath:fullName contents:nil attributes:nil];
    NSFileHandle* handle = [NSFileHandle fileHandleForWritingAtPath:fullName];
    @try{
        for(NSString* line in fcrunlog) [handle writeData:[line dataUsingEncoding:NSASCIIStringEncoding]];
    }
    @catch(NSException* exception){ }
    [handle closeFile];
}

- (void) fileLimitExceeded:(NSNotification*)note
{
    dataFileObject = [note object];
}

@end

@implementation ORFlashCamListenerModel (private)
- (void) setStatus:(NSString*)s
{
    if(status) if([status isEqualToString:s]) return;
    [s retain];
    [status release];
    status = s;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelStatusChanged object:self];
}

@end
