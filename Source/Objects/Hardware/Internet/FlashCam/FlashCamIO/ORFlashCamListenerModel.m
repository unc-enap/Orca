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
NSString* ORFlashCamListenerModelLPPConfigChanged    = @"ORFlashCamListenerModelLPPConfigChanged";

@implementation ORFlashCamListenerModel

#define DEBUG_PRINT(fmt, ...) do { if (DEBUG) fprintf( stderr, (fmt), __VA_ARGS__); } while (0)
#define DEBUG 0
//#define DEBUG_LPP

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
    
    [self setConfigParam:@"lppEnabled"      withValue:[NSNumber numberWithBool:NO]];
    [self setConfigParam:@"lppHWEnabled"      withValue:[NSNumber numberWithBool:NO]];
    [self setConfigParam:@"lppPSEnabled"      withValue:[NSNumber numberWithBool:NO]];
    [self setConfigParam:@"lppWriteNonTriggered" withValue:[NSNumber numberWithBool:NO]];
    [self setConfigParam:@"lppLogTime"      withValue:[NSNumber numberWithDouble:3.0]];
    [self setConfigParam:@"lppLogLevel"      withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"lppPulserChan"   withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"lppBaselineChan" withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"lppMuonChan"     withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"lppHWMajThreshold"  withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"lppHWPreScalingRate"  withValue:[NSNumber numberWithDouble:0.00]];
//    [self setConfigParam:@"lppHWCheckAll"  withValue:[NSNumber numberWithBool:YES]];
    [self setConfigParam:@"lppPSPreWindow"   withValue:[NSNumber numberWithInt:2000000]];
    [self setConfigParam:@"lppPSPostWindow"   withValue:[NSNumber numberWithInt:2000000]];
    [self setConfigParam:@"lppPSPreScalingRate"  withValue:[NSNumber numberWithDouble:0.0]];
    [self setConfigParam:@"lppPSMuonCoincidence"  withValue:[NSNumber numberWithBool:NO]];
    [self setConfigParam:@"lppPSSumWindowStart"  withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"lppPSSumWindowSize"  withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"lppPSCoincidenceThreshold"  withValue:[NSNumber numberWithDouble:20.0]];
    [self setConfigParam:@"lppPSAbsoluteThreshold"  withValue:[NSNumber numberWithDouble:1200.0]];
    reader             = NULL;
    readerRecordCount  = 0;
    bufferedRecords    = 0;
    configBuffer       = (uint32_t*) malloc((2*sizeof(uint32_t) + sizeof(fcio_config) +
                                             (sizeof(uint32_t)*(uint32_t)ceil([self maxADCCards]/4.0) +
                                              sizeof(uint64_t))*[self maxADCCards]) * kFlashCamConfigBufferLength);
    configBufferIndex  = 0;
    takeDataConfigIndex= 0;
    bufferedConfigCount= 0;
    statusBuffer       = (uint32_t*) malloc((2*sizeof(uint32_t) + sizeof(fcio_status)) * kFlashCamStatusBufferLength);
    statusBufferIndex  = 0;
    takeDataStatusIndex= 0;
    bufferedStatusCount= 0;
    enablePostProcessor = NO;
    postprocessor      = NULL;
    lppPSChannelMap = (int*)calloc(FCIOMaxChannels, sizeof(int));
    lppPSChannelGains = (float*)calloc(FCIOMaxChannels, sizeof(float));
    lppPSChannelThresholds = (float*)calloc(FCIOMaxChannels, sizeof(float));
    lppPSChannelShapings = (int*)calloc(FCIOMaxChannels, sizeof(int));
    lppPSChannelLowPass = (float*)calloc(FCIOMaxChannels, sizeof(float));
    lppHWChannelMap = (int*)calloc(FCIOMaxChannels, sizeof(int));
    lppHWPrescalingThresholds = (unsigned short*)calloc(FCIOMaxChannels, sizeof(unsigned short));
    lppFlagChannelMap = (int*)calloc(FCIOMaxChannels, sizeof(int));
    lppFlagChannelThresholds = (int*)calloc(FCIOMaxChannels, sizeof(int));
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
    if(postprocessor) LPPDestroy(postprocessor);
    free(configBuffer);
    configBuffer = NULL;

    free(statusBuffer);
    statusBuffer = NULL;

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
    [runTask             release];
    [listenerThread      release];
    [readOutList         release];
    [readOutArgs         release];
    [dataFileName        release];
    [fclog               release];
    [fcrunlog            release];
    [logDateFormatter    release];
    [ansieHelper         release];
    
    free(lppPSChannelMap);
    free(lppPSChannelGains);
    free(lppPSChannelThresholds);
    free(lppPSChannelShapings);
    free(lppPSChannelLowPass);
    free(lppHWChannelMap);
    free(lppHWPrescalingThresholds);
    free(lppFlagChannelMap);
    free(lppFlagChannelThresholds);
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
    else if([p isEqualToString:@"lppEnabled"])
        return [NSNumber numberWithBool:[[configParams objectForKey:p] boolValue]];
    else if([p isEqualToString:@"lppHWEnabled"])
        return [NSNumber numberWithBool:[[configParams objectForKey:p] boolValue]];
    else if([p isEqualToString:@"lppPSEnabled"])
        return [NSNumber numberWithBool:[[configParams objectForKey:p] boolValue]];
    else if([p isEqualToString:@"lppWriteNonTriggered"])
        return [NSNumber numberWithBool:[[configParams objectForKey:p] boolValue]];
    else if([p isEqualToString:@"lppLogTime"])
        return [NSNumber numberWithDouble:[[configParams objectForKey:p] doubleValue]];
    else if([p isEqualToString:@"lppLogLevel"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"lppPulserChan"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"lppBaselineChan"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"lppMuonChan"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"lppHWMajThreshold"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"lppHWPreScalingRate"])
        return [NSNumber numberWithDouble:[[configParams objectForKey:p] doubleValue]];
//    else if([p isEqualToString:@"lppHWCheckAll"])
//        return [NSNumber numberWithBool:[[configParams objectForKey:p] boolValue]];
    else if([p isEqualToString:@"lppPSPreWindow"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"lppPSPostWindow"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"lppPSPreScalingRate"])
        return [NSNumber numberWithDouble:[[configParams objectForKey:p] doubleValue]];
    else if([p isEqualToString:@"lppPSMuonCoincidence"])
        return [NSNumber numberWithBool:[[configParams objectForKey:p] boolValue]];
    else if([p isEqualToString:@"lppPSSumWindowStart"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"lppPSSumWindowSize"])
        return [NSNumber numberWithInt:[[configParams objectForKey:p] intValue]];
    else if([p isEqualToString:@"lppPSCoincidenceThreshold"])
        return [NSNumber numberWithDouble:[[configParams objectForKey:p] doubleValue]];
    else if([p isEqualToString:@"lppPSAbsoluteThreshold"])
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
        if(newType != prevType && (newType == 0 || prevType == 0)){
            free(configBuffer);
            configBuffer = (uint32_t*) malloc((2*sizeof(uint32_t) + sizeof(fcio_config) +
                                               (sizeof(uint32_t)*(uint32_t)ceil([self maxADCCards]/4.0) +
                                                sizeof(uint64_t))*[self maxADCCards]) * kFlashCamConfigBufferLength);
            configBufferIndex  = 0;
            takeDataConfigIndex= 0;
            bufferedConfigCount= 0;
        }
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

    else if([p isEqualToString:@"lppEnabled"])
        [configParams setObject:[NSNumber numberWithBool:[v boolValue]] forKey:p];
    else if([p isEqualToString:@"lppHWEnabled"])
        [configParams setObject:[NSNumber numberWithBool:[v boolValue]] forKey:p];
    else if([p isEqualToString:@"lppPSEnabled"])
        [configParams setObject:[NSNumber numberWithBool:[v boolValue]] forKey:p];
    else if([p isEqualToString:@"lppWriteNonTriggered"])
        [configParams setObject:[NSNumber numberWithBool:[v boolValue]] forKey:p];
    else if([p isEqualToString:@"lppLogTime"])
        [configParams setObject:[NSNumber numberWithDouble:MIN(MAX(1.0,[v doubleValue]),60.0)] forKey:p];
    else if([p isEqualToString:@"lppLogLevel"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(0,[v intValue]),5)] forKey:p];
    else if([p isEqualToString:@"lppPulserChan"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(-1,[v intValue]),2304)] forKey:p];
    else if([p isEqualToString:@"lppBaselineChan"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(-1,[v intValue]),2304)] forKey:p];
    else if([p isEqualToString:@"lppMuonChan"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(-1,[v intValue]),2304)] forKey:p];
    else if([p isEqualToString:@"lppHWMajThreshold"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(1,[v intValue]),2304)] forKey:p];
    else if([p isEqualToString:@"lppHWPreScalingRate"])
        [configParams setObject:[NSNumber numberWithDouble:MAX(0.0,[v doubleValue])] forKey:p];
    else if([p isEqualToString:@"lppHWPreScalingThreshold"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0,[v intValue])] forKey:p];
//    else if([p isEqualToString:@"lppHWCheckAll"])
//        [configParams setObject:[NSNumber numberWithBool:[v boolValue]] forKey:p];
    else if([p isEqualToString:@"lppPSPreWindow"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(0,[v intValue]),2147483647)] forKey:p];
    else if([p isEqualToString:@"lppPSPostWindow"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(0,[v intValue]),2147483647)] forKey:p];
    else if([p isEqualToString:@"lppPSPreScalingRate"])
        [configParams setObject:[NSNumber numberWithDouble:MAX(0.0,[v doubleValue])] forKey:p];
    else if([p isEqualToString:@"lppPSMuonCoincidence"])
        [configParams setObject:[NSNumber numberWithBool:[v boolValue]] forKey:p];
    else if([p isEqualToString:@"lppPSSumWindowStart"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(0,[v intValue]),32768)] forKey:p];
    else if([p isEqualToString:@"lppPSSumWindowSize"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(1,[v intValue]),32767)] forKey:p];
    else if([p isEqualToString:@"lppPSCoincidenceThreshold"])
        [configParams setObject:[NSNumber numberWithDouble:MAX(0.0,[v doubleValue])] forKey:p];
    else if([p isEqualToString:@"lppPSAbsoluteThreshold"])
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

- (void) setDataIds:(id)assigner
{
    configId = [assigner assignDataIds:kLongForm];
    statusId = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherListener
{
    [self setConfigId:[anotherListener configId]];
    [self setStatusId:[anotherListener statusId]];
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

- (bool) setupPostProcessor
{
    if ([[self configParam:@"daqMode"] intValue] == 12) {
        NSLogColor([NSColor redColor],@"%s: Cannot use software trigger in singles mode!\n", [self identifier]);
        return NO;
    }
    nlppPSChannels = 0;
    nlppHWChannels = 0;
    nlppFlagChannels = 0;
    lppPulserChannel = -1;
    lppBaselineChannel = -1;
    lppMuonChannel = -1;
    lppPulserChannelThreshold = 0;
    lppBaselineChannelThreshold = 0;
    lppBaselineChannelThreshold = 0;
    for(ORReadOutObject* obj in [readOutList children]){
        if(![[obj object] isKindOfClass:NSClassFromString(@"ORFlashCamCard")]) continue;
        ORFlashCamCard* card = (ORFlashCamCard*) [obj object];
        if([card isKindOfClass:NSClassFromString(@"ORFlashCamADCModel")]){
            ORFlashCamADCModel* adc = (ORFlashCamADCModel*) card;
            for (unsigned int ich = 0; ich < [adc numberOfChannels]; ich++) {
                if (![adc chanEnabled:ich]) { // if the channel is not enable for readout, is cannot be parsed to the postprocessor.
                    continue;
                }
                int identifier = ([adc cardAddress] << 16) + ich;
                switch([adc swtInclude:ich]) {
                    case 1: { // Peak Sum
                        lppPSChannelMap[nlppPSChannels] = identifier;
                        lppPSChannelGains[nlppPSChannels] = [adc swtCalibration:ich];
                        lppPSChannelThresholds[nlppPSChannels] = [adc swtThreshold:ich];
                        lppPSChannelShapings[nlppPSChannels] = [adc swtShapingTime:ich];
                        lppPSChannelLowPass[nlppPSChannels] = 0.0; // Don't need lowpass for now
                        nlppPSChannels++;
                        break;
                    }
                    case 2: { // HW Multiplicity
                        lppHWChannelMap[nlppHWChannels] = identifier;
                        lppHWPrescalingThresholds[nlppHWChannels] = (unsigned short)[adc swtThreshold:ich];
                        nlppHWChannels++;
                        break;
                    }
                    case 3: { // Digital Flag
                        // TODO: Digital Flag Channel Type not implemented, only specialized versions available
                        NSLogColor([NSColor redColor], @"%@: setupSoftwareTrigger: Digital Flag selected on 0x%x, but it's not implemented yet.", [self identifier], identifier);
                    }
                    case 4: {
                        if (lppPulserChannel == -1) {
                            lppPulserChannel = identifier;
                            lppPulserChannelThreshold = [adc swtCalibration:ich] * [adc swtThreshold:ich];
                        } else {
                            NSLogColor([NSColor redColor], @"%@: setupSoftwareTrigger: Trying to overwrite Pulser Channel setting 0x%x with 0x%x.\n", [self identifier], lppPulserChannel, identifier );
                            return NO;
                        }
                        break;
                    }
                    case 5: {
                        if (lppBaselineChannel == -1) {
                            lppBaselineChannel = identifier;
                            lppBaselineChannelThreshold = [adc swtCalibration:ich] * [adc swtThreshold:ich];
                        } else {
                            NSLogColor([NSColor redColor], @"%@: setupSoftwareTrigger: Trying to overwrite Baseline Channel setting 0x%x with 0x%x.\n", [self identifier], lppBaselineChannel, identifier );
                            return NO;
                        }
                        break;
                    }
                    case 6: {
                        if (lppMuonChannel == -1) {
                            lppMuonChannel = identifier;
                            lppMuonChannelThreshold = [adc swtCalibration:ich] * [adc swtThreshold:ich];
                        } else {
                            NSLogColor([NSColor redColor], @"%@: setupSoftwareTrigger: Trying to overwrite Muon Channel setting 0x%x with 0x%x.\n", [self identifier], lppMuonChannel, identifier );
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
    
    if (postprocessor) {
        // should never occur, buf if it does, because code evolves, it is checked again.
        LPPDestroy(postprocessor);
    }

    if (!(postprocessor = LPPCreate())) {
        NSLog(@"%@: Couldn't allocate software trigger.\n", [self identifier]);
        return NO;
    }
    LPPSetLogTime(postprocessor, [[self configParam:@"lppLogTime"] doubleValue]);
    LPPSetLogLevel(postprocessor, [[self configParam:@"lppLogLevel"] intValue]);

    
    const char* channelmap_format = "fcio-tracemap";
    
    /* always set the Aux Parameters to get sane defaults, we picked some at the beginning of this function.*/
    if (!LPPSetAuxParameters(postprocessor, channelmap_format,
                             lppPulserChannel, lppPulserChannelThreshold,
                             lppBaselineChannel, lppBaselineChannelThreshold,
                             lppMuonChannel, lppMuonChannelThreshold
                             )) {
        NSLogColor([NSColor redColor], @"%@: setupSoftwareTrigger: Error parsing Aux parameters.\n", [self identifier]);
        return NO;
    }

    if ([self configParam:@"lppHWEnabled"] && nlppHWChannels) {
        if (!LPPSetGeParameters(postprocessor, nlppHWChannels, lppHWChannelMap, channelmap_format,
                                [[self configParam:@"lppHWMajThreshold"] intValue],
                                0, // do not skip any channels to check
                                lppHWPrescalingThresholds,
                                [[self configParam:@"lppHWPreScalingRate"] floatValue])) {
            NSLogColor([NSColor redColor], @"%@: setupSoftwareTrigger: Error parsing HW Multiplicity parameters.\n", [self identifier]);
            return NO;
        }
    }

    if ([self configParam:@"lppPSEnabled"] && nlppPSChannels) {
        if (!LPPSetSiPMParameters(postprocessor, nlppPSChannels, lppPSChannelMap, channelmap_format,
                                  lppPSChannelGains, lppPSChannelThresholds,
                                  lppPSChannelShapings, lppPSChannelLowPass,
                                  [[self configParam:@"lppPSPreWindow"] intValue],
                                  [[self configParam:@"lppPSPostWindow"] intValue],
                                  [[self configParam:@"lppPSSumWindowSize"] intValue],
                                  [[self configParam:@"lppPSSumWindowStart"] intValue],
                                  [[self configParam:@"lppPSSumWindowStart"] intValue] + [[self configParam:@"lppPSSumWindowSize"] intValue],
                                  [[self configParam:@"lppPSAbsoluteThreshold"] floatValue],
                                  [[self configParam:@"lppPSCoincidenceThreshold"] floatValue],
                                  [[self configParam:@"lppPSPreScalingRate"] floatValue],
                                  [[self configParam:@"lppPSMuonCoincidence"] intValue])) {
            NSLogColor([NSColor redColor], @"%@: setupSoftwareTrigger: Error parsing Peak Sum parameters.\n", [self identifier]);
            return NO;
        }
    }
    int realized_buffer_depth = LPPSetBufferSize(postprocessor, stateBuffer);
    if (realized_buffer_depth != stateBuffer) {
        // should also never occur
        NSLogColor([NSColor redColor], @"%@: Software trigger: buffer depth too small, adjust the state buffer depth to 16 at minimum\n", [self identifier]);
        return NO;
    }

//                const char* filepath = "<path_to_config>/lppconfig_local.txt";
//                LPPSetParametersFromFile(postprocessor, filepath);
    NSLog(@"%@: Software trigger initialized.\n", [self identifier]);
    // Push the Config into the postprocessor, so it's ready when read() is being called.
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
//        FCIODeselectStateTag(reader, 0); // deselect all
//        FCIOSelectStateTag(reader, FCIOConfig);
//        FCIOSelectStateTag(reader, FCIOStatus);
//        FCIOSelectStateTag(reader, FCIOEvent);
//        FCIOSelectStateTag(reader, FCIOSparseEvent);
        if (enablePostProcessor && ![self setupPostProcessor]) {
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

    if(postprocessor)
        LPPDestroy(postprocessor);
    postprocessor = NULL;

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


- (bool) fcioRead:(ORDataPacket*) aDataPacket
{
    if (listenerRemoteIsFile && ![runTask isRunning] && reader->timeout) {
        // if the remote is a file, reading EOF is a signal that we might not have any more data to read
        // and FCIOGetNextState will wait for its timeout to try to read more
        // if the runTask is not running anymore, no more data will come
        // and we can savely reduce the timeout to 0
        // This will reduce waiting times at the end of run. Especially important
        // if multiple listeners are connected with high timeouts (a few seconds)
        FCIOTimeout(reader->stream, 0); // set the library timeout
        reader->timeout = 0; // unfortunately the timeout variable has to be twice for separate internal code sections.
    }

    int timedout = 0; // contains timeout reason
    bool writeWaveforms = true;
    bool writeNonTriggered = [[self configParam:@"lppWriteNonTriggered"] boolValue];
    int lppLogLevel = [[self configParam:@"lppLogLevel"] intValue];
    FCIOState* state = NULL;
    LPPState* lppstate = NULL;
    if (!postprocessor) {
        if ( ! (state = FCIOGetNextState(reader, &timedout))) {
            DEBUG_PRINT( "%s %s: fcioRead: end-of-stream: timedout %d\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String], timedout);
            if (timedout == 1 && !listenerRemoteIsFile)
                NSLog(@"%@: FCIO stream closed due to timeout.\n", [self identifier]);
            else if (timedout == 2)
                NSLog(@"%@: FCIO stream closed due to timeout, however deselected records arrived.\n", [self identifier]);
            return NO;
        }
        
    } else {
        if (!(lppstate = LPPGetNextState(postprocessor, reader, &timedout))) {
            DEBUG_PRINT( "%s %s: fcioRead: end-of-stream: timedout %d\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String], timedout);
            if (timedout == 1 && !listenerRemoteIsFile)
                NSLog(@"%@: FCIO stream closed due to timeout.\n", [self identifier]);
            else if (timedout == 2)
                NSLog(@"%@: FCIO stream closed due to timeout, however deselected records arrived.\n", [self identifier]);
            else if (timedout == 10)
                NSLogColor([NSColor redColor], @"%@: post processor buffer overflow. Increase the ReadoutModel state buffer size.\n",[self identifier]);
        }

#ifdef DEBUG_LPP
        if (LPPStatsUpdate(postprocessor, !lppstate)) {
            // returns one if stats have been updated, or if the stream ends.
            if (lppLogLevel > 0) {
                char logstring[255];
                if (LPPStatsInfluxString(postprocessor, logstring, 255))
                    fprintf(stderr, "%s: postprocessor %s\n", [[self identifier] UTF8String],logstring);
            }
        }
        char statestring[19] = {0};
        LPPFlags2char(lppstate, 18, statestring);
        if (!lppstate->write) {
            if (lppLogLevel > 5) {
                fprintf(stderr, "%s: postprocessor record_flags=%s\n", [[self identifier] UTF8String], statestring);
            }
        } else {
            if (lppLogLevel > 2 && lppstate->stream_tag != FCIOStatus) {
                fprintf(stderr, "%s: postprocessor record_flags=%s ge,multi=%d,min=%d,max=%d sipm,sum=%f,max=%f,mult=%d,offset=%d fill_level=%d\n",
                        [[self identifier] UTF8String], statestring,
                        lppstate->majority,lppstate->ge_min_fpga_energy, lppstate->ge_max_fpga_energy,
                        lppstate->largest_sum_pe, lppstate->largest_pe,
                        lppstate->channel_multiplicity,lppstate->largest_sum_offset,
                        LPPBufferFillLevel(postprocessor->buffer)
                        );
            }
        }
#endif
        if (!lppstate)
            return NO; // stream has ended - similar to FCIOGetNextState
        state = lppstate->state; // set current read record

        if (!lppstate->write && !writeNonTriggered) // write to output even if software trigger did not trigger
            return YES;
    }
    fcio_last_tag = state->last_tag;
    // TODO: Implement the writing of the additional postprocessor information, for triggered & non-triggered records.
    // decide on what to write, and how
    // - add postprocessor flags to regular events OR send additional record
    // would be better to have a dynamic size possible for these kinds
    // of extensions

    switch(state->last_tag){
        case FCIOConfig: {
            DEBUG_PRINT( "%s %s: fcioRead: config\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
            for(id obj in dataTakers) [obj setWFsamples:state->config->eventsamples];
            [self readConfig:state->config];
            [self sendConfigPacket:aDataPacket]; // send outside of the locked function
            break;
        }
        case FCIOEvent:
        case FCIOSparseEvent: {

#ifdef DEBUG_LPP
            if (!lppstate->write) {
                writeWaveforms = false; // might not properly work with data parsing downstream
            }
            // this implementation reused the unused timestamp fields. This produces conflicts with fc250b version 2.
            // should better use a separate new record.
            state->event->type = 10; // LPP Event, use new EventType
            state->event->timestamp[4] = (unsigned int)(lppstate->flags.trigger); // unsigned int
            state->event->timestamp[5] = (unsigned int)(lppstate->flags.event); // unsigned int
            state->event->timestamp[6] = (unsigned int)(lppstate->largest_sum_pe * 100);  // increase precision up to 2 decimals, won't ever need more than that
            state->event->timestamp[7] = lppstate->largest_sum_offset; // the sample within the event
            state->event->timestamp[8] = lppstate->channel_multiplicity; // the number of channels participating
            state->event->timestamp[9] = *(int*)(&lppstate->largest_pe);  // float
            state->event->timestamp_size = 10;
#endif
            for(int itr=0; itr<state->event->num_traces; itr++){
                NSDictionary* dict = [chanMap objectAtIndex:state->event->trace_list[itr]];
                ORFlashCamADCModel* card = [dict objectForKey:@"adc"];
                unsigned int chan = [[dict objectForKey:@"channel"] unsignedIntValue];
                [card shipEvent:state->event withIndex:state->event->trace_list[itr]
                     andChannel:chan use:aDataPacket includeWF:writeWaveforms];
            }

            break;
        }
        case FCIORecEvent: {
            if(!unrecognizedPacket){
                NSLogColor([NSColor redColor], @"%@: skipping received FCIORecEvent packet on %@ - packet type not supported!\n", [self identifier], [self streamDescription]);
                NSLogColor([NSColor redColor], @"%@: WARNING - suppressing further instances of this message for this object in this run\n", [self identifier]);
            }
            unrecognizedPacket = true;
            break;
        }
        case FCIOStatus: {
            DEBUG_PRINT( "%s %s: fcioRead: status\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
            [self readStatus:state->status];
            [self sendStatusPacket:aDataPacket];
            break;
        }
        default: {
            bool found = false;
            // we don't pass unrecognized states, actually might be best to
            // deselect them in the statereader.. multiple ways to handle this
            for(id n in unrecognizedStates)
                if((int) state->last_tag == [n intValue]) found = true;
            if(!found){
                [unrecognizedStates addObject:[NSNumber numberWithInt:(int)state->last_tag]];
                NSLogColor([NSColor redColor], @"%@: unrecognized fcio record tag %d on %@\n", [self identifier], state->last_tag, [self streamDescription]);
                NSLogColor([NSColor redColor], @"%@: WARNING - suppressing further instances of this message for this object in this run\n", [self identifier]);
            }
            break;
        }
    }

    return YES;
}

- (void) runFailed
{
    DEBUG_PRINT( "%s %s: runFailed\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
    [self performSelectorOnMainThread:@selector(runFailedMainThread) withObject:nil waitUntilDone:NO];
}

- (void) runFailedMainThread
{
    DEBUG_PRINT( "%s %s: runFailedMainThreaed\n", [[self identifier] UTF8String], [[[NSThread currentThread] description] UTF8String]);
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

    enablePostProcessor = [[self configParam:@"lppEnabled"] boolValue];

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

- (void) readConfig:(fcio_config*)config
{
    // validate the number of waveform samples
    if(config->eventsamples != [[self configParam:@"eventSamples"] intValue]){
        NSLogColor([NSColor redColor], @"%@: user defined waveform length %d "
                   " != waveform length from configuration packet %d\n", [self identifier],
                   [[self configParam:@"eventSamples"] intValue], config->eventsamples);
        [self runFailed];
    }
    // read the configuration packet
    uint32_t index = configBufferIndex;
    configBufferIndex = (configBufferIndex + 1) % kFlashCamConfigBufferLength;
    bufferedConfigCount++;
    uint32_t offset = 2 + (2 + sizeof(fcio_config)/sizeof(uint32_t)) * index;
    configBuffer[offset++] = (uint32_t) config->telid;
    configBuffer[offset++] = (uint32_t) config->adcs;
    configBuffer[offset++] = (uint32_t) config->triggers;
    configBuffer[offset++] = (uint32_t) config->eventsamples;
    configBuffer[offset++] = (uint32_t) config->adcbits;
    configBuffer[offset++] = (uint32_t) config->sumlength;
    configBuffer[offset++] = (uint32_t) config->blprecision;
    configBuffer[offset++] = (uint32_t) config->mastercards;
    configBuffer[offset++] = (uint32_t) config->triggercards;
    configBuffer[offset++] = (uint32_t) config->adccards;
    configBuffer[offset++] = (uint32_t) config->gps;
    memcpy(configBuffer + offset, config->tracemap, config->adcs*sizeof(uint32_t));
    offset += FCIOMaxChannels;
    // append the board revision and main board ids to the configuration packet
    NSMutableArray* addresses = [NSMutableArray array];
    uint32 broffset = offset + (uint32_t) ceil([self maxADCCards]/4.0);
    for(int i=0; i<config->adcs; i++){
        uint16_t addr = (config->tracemap[i] & 0xFFFF0000) >> 16;
        NSUInteger index = [addresses indexOfObjectIdenticalTo:[NSNumber numberWithUnsignedShort:addr]];
        if(index == NSNotFound){
            [addresses addObject:[NSNumber numberWithUnsignedShort:addr]];
            index = [addresses count] - 1;
        }
        else continue;
        bool found = false;
        for(id obj in [readOutList children]){
            if([[obj object] cardAddress] != (uint32_t) addr) continue;
            configBuffer[offset+index/4] |= (((uint32_t) [[obj object] boardRevision]) << (8*(index%4)));
            configBuffer[broffset]   = (uint32_t) (([[obj object] hardwareID] & 0xFFFFFFFF00000000) >> 32);
            configBuffer[broffset+1] = (uint32_t) (([[obj object] hardwareID] & 0x00000000FFFFFFFF));
            broffset += 2;
            found = true;
            break;
        }
        if(!found){
            NSLogColor([NSColor redColor], @"%@: adc mapping error for address 0x%hhx\n",
                       [self identifier], addr);
            [self runFailed];
        }
    }
    if(bufferedConfigCount == kFlashCamConfigBufferLength){
        NSLogColor([NSColor redColor], @"%@: error config buffer full\n",
                   [self identifier]);
        [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelConfigBufferFull
                                                            object:self];
    }
    // validate the channel map
    bool fail = false;
    for(unsigned int i=0; i<config->adcs; i++){
        uint32_t addr  = (config->tracemap[i] & 0xffff0000) >> 16;
        uint32_t input =  config->tracemap[i] & 0x0000ffff;
        if(i >= (unsigned int) [chanMap count]){
            if(config->tracemap[i] == 0) continue;
            else{
                NSLogColor([NSColor redColor], @"%@: failed to start run due to "
                           "FCIO channel map entry (index %u card 0x%x input %u) not found in Orca channel map\n",
                          [self identifier], i, addr, input);
                fail = true;
                continue;
            }
        }
        NSDictionary* dict = [chanMap objectAtIndex:i];
        if([[dict objectForKey:@"adc"]          cardAddress] != addr ||
           [[dict objectForKey:@"channel"] unsignedIntValue] != input){
            NSLogColor([NSColor redColor], @"%@: failed to start run due to "
                       "inconsistent channel map entry at index %u: FCIO - card 0x%x input %u, ORCA - card 0x%x input %u\n",
                       [self identifier], i, addr, input,
                       [[dict objectForKey:@"adc"] cardAddress], [[dict objectForKey:@"channel"] unsignedIntValue]);
            fail = true;
        }
    }
    if(fail) {
        NSLogColor([NSColor redColor], @"%@: failed to validated channel map\n", [self identifier]);
        [self runFailed];
    }
}

- (void) sendConfigPacket:(ORDataPacket*)aDataPacket
{
    uint32_t blength = 2 + sizeof(fcio_config) / sizeof(uint32_t);
    uint32_t dlength = blength;
    blength += (uint32_t) ceil([self maxADCCards]/4.0) + 2*[self maxADCCards];
    uint32_t index = blength * takeDataConfigIndex;
    dlength -= FCIOMaxChannels - configBuffer[index+3];
    uint32_t nadc = configBuffer[index+11];
    dlength += (uint32_t) ceil(nadc/4.0) + 2*nadc;
    takeDataConfigIndex = (takeDataConfigIndex + 1) % kFlashCamConfigBufferLength;
    bufferedConfigCount --;
    configBuffer[index]    = configId | (dlength & 0x3ffff);
    DEBUG_PRINT( "sendConfig: dataid %u record %u -> %u\n", configId, dlength, configBuffer[index]);
    configBuffer[index+1]  = ((unsigned short) [guardian uniqueIdNumber]) << 16;
    configBuffer[index+1] |=  (unsigned short) [self uniqueIdNumber];
    [aDataPacket addLongsToFrameBuffer:configBuffer+index
                                length:dlength-(uint32_t)ceil(nadc/4.0)-2*nadc];
    index += 2 + sizeof(fcio_config)/sizeof(uint32_t);
    [aDataPacket addLongsToFrameBuffer:configBuffer+index length:(uint32_t)ceil(nadc/4.0)];
    index += (uint32_t) ceil([self maxADCCards]/4.0);
    [aDataPacket addLongsToFrameBuffer:configBuffer+index length:nadc*2];
}

- (void) readStatus:(fcio_status*)fcstatus
{
    uint32_t index = statusBufferIndex;
    statusBufferIndex = (statusBufferIndex + 1) % kFlashCamStatusBufferLength;
    bufferedStatusCount++;
    uint32_t offset = 2 + (2 + sizeof(fcio_status)/sizeof(uint32_t)) * index;
    statusBuffer[offset++] = (uint32_t) fcstatus->status;
    memcpy(statusBuffer+offset, fcstatus->statustime, 10*sizeof(uint32_t));
    offset += 10;
    statusBuffer[offset++] = fcstatus->cards;
    statusBuffer[offset++] = fcstatus->size;
    for(int i=0; i<fcstatus->cards; i++){
        statusBuffer[offset++] = (fcstatus->data+i)->reqid;
        statusBuffer[offset++] = (fcstatus->data+i)->status;
        statusBuffer[offset++] = (fcstatus->data+i)->eventno;
        statusBuffer[offset++] = (fcstatus->data+i)->pps;
        statusBuffer[offset++] = (fcstatus->data+i)->ticks;
        statusBuffer[offset++] = (fcstatus->data+i)->maxticks;
        statusBuffer[offset++] = (fcstatus->data+i)->numenv;
        statusBuffer[offset++] = (fcstatus->data+i)->numctilinks;
        statusBuffer[offset++] = (fcstatus->data+i)->numlinks;
        statusBuffer[offset++] = (fcstatus->data+i)->dummy;
        statusBuffer[offset++] = (fcstatus->data+i)->totalerrors;
        statusBuffer[offset++] = (fcstatus->data+i)->enverrors;
        statusBuffer[offset++] = (fcstatus->data+i)->ctierrors;
        statusBuffer[offset++] = (fcstatus->data+i)->linkerrors;
        memcpy(statusBuffer+offset, (fcstatus->data+i)->othererrors, 5*sizeof(uint32_t));
        offset += 5;
        memcpy(statusBuffer+offset, (fcstatus->data+i)->environment, 16*sizeof(uint32_t));
        offset += 16;
        memcpy(statusBuffer+offset, (fcstatus->data+i)->ctilinks, 4*sizeof(uint32_t));
        offset += 4;
        memcpy(statusBuffer+offset, (fcstatus->data+i)->linkstates, fcstatus->cards*sizeof(uint32_t));
        unsigned int ID = (fcstatus->data+i)->reqid;
        for(id dict in cardMap){
            if([[dict objectForKey:@"fcioID"] unsignedIntValue] == ID){
                [[dict objectForKey:@"card"] readStatus:fcstatus atIndex:i];
                break;
            }
        }
    }
    if(bufferedStatusCount == kFlashCamStatusBufferLength){
        NSLogColor([NSColor redColor], @"%@: error status buffer full\n",
                   [self identifier]);
    }
}

- (void) sendStatusPacket:(ORDataPacket*)aDataPacket
{
    uint32_t index = (2 + sizeof(fcio_status) / sizeof(uint32_t)) * takeDataStatusIndex;
    takeDataStatusIndex = (takeDataStatusIndex + 1) % kFlashCamStatusBufferLength;
    bufferedStatusCount --;
    int cards = (int) statusBuffer[index+13];
    int dsize = (int) statusBuffer[index+14];
    uint32_t length = 2 + (sizeof(fcio_status) -
                           (256-cards)*(dsize+cards*sizeof(uint32_t))) / sizeof(uint32_t);
    statusBuffer[index]    = statusId | (length & 0x3ffff);
    statusBuffer[index+1]  = ((unsigned short) [guardian uniqueIdNumber]) << 16;
    statusBuffer[index+1] |=  (unsigned short) [self uniqueIdNumber];
    DEBUG_PRINT( "sendStatus: dataid %u record %u -> %u\n", statusId, length, statusBuffer[index]);
    [aDataPacket addLongsToFrameBuffer:statusBuffer+index length:length];
}

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

    memset(configBuffer, 0, kFlashCamConfigBufferLength * (2 + sizeof(fcio_config)/sizeof(uint32_t) + (uint32_t)
                                                           ceil([self maxADCCards]/4.0) + 2*[self maxADCCards]));
    configBufferIndex   = 0;
    takeDataConfigIndex = 0;
    bufferedConfigCount = 0;

    memset(statusBuffer, 0, kFlashCamStatusBufferLength * (2 + sizeof(fcio_status)/sizeof(uint32_t)));
    statusBufferIndex   = 0;
    takeDataStatusIndex = 0;
    bufferedStatusCount = 0;

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

    memset(configBuffer, 0, kFlashCamConfigBufferLength * (2 + sizeof(fcio_config)/sizeof(uint32_t) + (uint32_t)
                                                           ceil([self maxADCCards]/4.0) + 2*[self maxADCCards]));
    configBufferIndex   = 0;
    takeDataConfigIndex = 0;
    bufferedConfigCount = 0;
    memset(statusBuffer, 0, kFlashCamStatusBufferLength * (2 + sizeof(fcio_status)/sizeof(uint32_t)));
    statusBufferIndex   = 0;
    takeDataStatusIndex = 0;
    bufferedStatusCount = 0;

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
    NSDictionary* dc = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"ORFlashCamListenerConfigDecoder",              @"decoder",
                        [NSNumber numberWithLong:configId],              @"dataId",
                        [NSNumber numberWithBool:NO],                    @"variable",
                        [NSNumber numberWithLong:sizeof(fcio_config)+2], @"length", nil];
    NSDictionary* ds = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"ORFlashCamListenerStatusDecoder",              @"decoder",
                        [NSNumber numberWithLong:statusId],              @"dataId",
                        [NSNumber numberWithBool:YES],                   @"variable",
                        [NSNumber numberWithLong:-1],                    @"length", nil];
    [dict setObject:dc forKey:@"FlashCamConfig"];
    [dict setObject:ds forKey:@"FlashCamStatus"];
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

    lppPSChannelMap = (int*)calloc(FCIOMaxChannels, sizeof(int));
    lppPSChannelGains = (float*)calloc(FCIOMaxChannels, sizeof(float));
    lppPSChannelThresholds = (float*)calloc(FCIOMaxChannels, sizeof(float));
    lppPSChannelShapings = (int*)calloc(FCIOMaxChannels, sizeof(int));
    lppPSChannelLowPass = (float*)calloc(FCIOMaxChannels, sizeof(float));
    lppHWChannelMap = (int*)calloc(FCIOMaxChannels, sizeof(int));
    lppHWPrescalingThresholds = (unsigned short*)calloc(FCIOMaxChannels, sizeof(unsigned short));
    lppFlagChannelMap = (int*)calloc(FCIOMaxChannels, sizeof(int));
    lppFlagChannelThresholds = (int*)calloc(FCIOMaxChannels, sizeof(int));

    if(!configBuffer) configBuffer = (uint32_t*) malloc((2*sizeof(uint32_t) + sizeof(fcio_config)) * kFlashCamConfigBufferLength);
    configBufferIndex = 0;
    takeDataConfigIndex = 0;
    bufferedConfigCount = 0;
    if(!statusBuffer) statusBuffer = (uint32_t*) malloc((2*sizeof(uint32_t) + sizeof(fcio_status)) * kFlashCamStatusBufferLength);
    statusBufferIndex = 0;
    takeDataStatusIndex = 0;
    bufferedStatusCount = 0;
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
