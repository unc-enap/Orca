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
#import "tmio.h"
#import "Utilities.h"
#import "ORDataTypeAssigner.h"

NSString* ORFlashCamListenerModelConfigChanged = @"ORFlashCamListenerModelConfigChanged";
NSString* ORFlashCamListenerModelStatusChanged = @"ORFlashCamListenerModelStatusChanged";
//NSString* ORFlashCamListenerModelConnected     = @"ORFlashCamListenerModelConnected";
//NSString* ORFlashCamListenerModelDisconnected  = @"ORFlashCamListenerModelDisconnected";
NSString* ORFlashCamListenerModelChanMapChanged   = @"ORFlashCamListenerModelChanMapChanged";
NSString* ORFlashCamListenerModelCardMapChanged   = @"ORFlashCamListenerModelCardMapChanged";
NSString* ORFlashCamListenerModelConfigBufferFull = @"ORFlashCamListenerModelConfigBufferFull";
NSString* ORFlashCamListenerModelStatusBufferFull = @"ORFlashCamListenerModelStatusBufferFull";

@implementation ORFlashCamListenerModel

#pragma mark •••Initialization

- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    interface          = @"";
    port               = 4000;
    ip                 = @"";
    timeout            = 2000;
    ioBuffer           = BUFIO_BUFSIZE/1024;
    stateBuffer        = 20;
    configParams       = [[NSMutableDictionary dictionary] retain];
    [self setConfigParam:@"maxPayload"      withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"eventBuffer"     withValue:[NSNumber numberWithInt:1024]];
    [self setConfigParam:@"phaseAdjust"     withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"baselineSlew"    withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"integratorLen"   withValue:[NSNumber numberWithInt:7]];
    [self setConfigParam:@"eventSamples"    withValue:[NSNumber numberWithInt:2048]];
    [self setConfigParam:@"signalDepth"     withValue:[NSNumber numberWithInt:1024]];
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
    [self setConfigParam:@"baselineCalib"   withValue:[NSNumber numberWithInt:-1]];
    [self setConfigParam:@"trigTimer1Addr"  withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"trigTimer1Sec"   withValue:[NSNumber numberWithInt:1]];
    [self setConfigParam:@"trigTimer2Addr"  withValue:[NSNumber numberWithInt:0]];
    [self setConfigParam:@"trigTimer2Sec"   withValue:[NSNumber numberWithInt:1]];
    [self setConfigParam:@"pileupRej"       withValue:[NSNumber numberWithDouble:0.0]];
    [self setConfigParam:@"logTime"         withValue:[NSNumber numberWithDouble:1.0]];
    [self setConfigParam:@"incBaseline"     withValue:[NSNumber numberWithBool:YES]];
    [self setConfigParam:@"trigAllEnable"   withValue:[NSNumber numberWithBool:YES]];
    throttle           = 0.0;
    reader             = NULL;
    readerRecordCount  = 0;
    bufferedRecords    = 0;
    configBuffer       = (uint32_t*) malloc((2*sizeof(uint32_t) + sizeof(fcio_config)) * kFlashCamConfigBufferLength);
    configBufferIndex  = 0;
    takeDataConfigIndex= 0;
    bufferedConfigCount= 0;
    statusBuffer       = (uint32_t*) malloc((2*sizeof(uint32_t) + sizeof(fcio_status)) * kFlashCamStatusBufferLength);
    statusBufferIndex  = 0;
    takeDataStatusIndex= 0;
    bufferedStatusCount= 0;
    runFailedAlarm     = nil;
    unrecognizedPacket = false;
    unrecognizedStates = nil;
    status             = @"disconnected";
    eventCount         = 0;
    runTime            = 0.0;
    readMB             = 0.0;
    rateMB             = 0.0;
    rateHz             = 0.0;
    timeLock           = 0.0;
    deadTime           = 0.0;
    totDead            = 0.0;
    curDead            = 0.0;
    dataRateHistory    = [[ORTimeRate alloc] init]; //MAH 10/2/22 removed retain
    [dataRateHistory   setLastAverageTime:[NSDate date]];
    [dataRateHistory   setSampleTime:10];
    eventRateHistory   = [[ORTimeRate alloc] init]; //MAH 10/2/22 removed retain
    [eventRateHistory  setLastAverageTime:[NSDate date]];
    [eventRateHistory  setSampleTime:10];
    deadTimeHistory    = [[ORTimeRate alloc] init]; //MAH 10/2/22 removed retain
    [deadTimeHistory   setLastAverageTime:[NSDate date]];
    [deadTimeHistory   setSampleTime:10];
    taskSequencer            = nil;
    chanMap            = nil;
    cardMap            = nil;
    [self setRemoteInterfaces:[NSMutableArray array]];
    ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
    [readList setAcceptedProtocol:@"ORDataTaker"];
    [readList addAcceptedObjectName:@"ORFlashCamADCModel"];
    [self setReadOutList:readList];
    [readList release];
    //[self setReadOutArgs:[[NSMutableArray alloc] init]]; //MAH 9/12/22 commented out. Caused double retain
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (id) initWithInterface:(NSString*)iface port:(uint16_t)p
{
    self = [self init]; //MAH 9/18/22. didn't assign self from result of init
    [interface release];
    interface   = [iface copy];
    port        = p;
    return self;
}

- (void) dealloc
{
    [interface release];
    [ip release];
    [remoteInterfaces release];
    [configParams release];
    [status release];
    if(runFailedAlarm){
        [runFailedAlarm clearAlarm];
        [runFailedAlarm release];
    }
    if(unrecognizedStates) [unrecognizedStates release];
    if(reader) FCIODestroyStateReader(reader);
    free(configBuffer);
    configBuffer = NULL;
    free(statusBuffer);
    statusBuffer = NULL;
    [dataRateHistory release];
    [eventRateHistory release];
    [deadTimeHistory release];
    [taskSequencer release];
    [runTask release]; //MAH 9/17/22
    [readOutList release];
    [readOutArgs release];
    [readStateLock release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}

- (void) setUpImage
{
    NSImage* cimage = [NSImage imageNamed:@"flashcam_listener"];
    //NSSize size = [cimage size];
    NSSize newsize;
    newsize.height = 45;
    newsize.width  = newsize.height;
    NSImage* image = [[NSImage alloc] initWithSize:newsize];
    [image lockFocus];
    NSRect rect;
    rect.origin = NSZeroPoint;
    rect.size.width = newsize.width;
    rect.size.height = newsize.height;
    [cimage drawInRect:rect fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0];
    [image unlockFocus];
    [self setImage:image];
    [image release]; //MAH 2/18/22
}

- (BOOL) acceptsGuardian:(OrcaObject*)aGuardian
{
    if([aGuardian isMemberOfClass:NSClassFromString(@"ORFlashCamReadoutModel")]) return YES;
    return NO;
}

#pragma mark •••Accessors

- (NSString*) identifier
{
    return [NSString stringWithFormat:@"%@, listener %d", [guardian identifier], [self uniqueIdNumber]];
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
            NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: error getting ethernet type - all interfaces associated with the same listener must have identical type\n");
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
    else{
        NSLog(@"ORFlashCamListenerModel: unknown configuration parameter %@\n", p);
        return nil;
    }
}

- (NSMutableArray*) runFlags:(bool)print
{
    NSMutableArray* f = [NSMutableArray array];
    [f addObjectsFromArray:@[@"-blbias", @"0", @"-bldac", @"2000"]];
    [f addObjectsFromArray:@[@"-mpl",  [NSString stringWithFormat:@"%d", [[self configParam:@"maxPayload"]    intValue]]]];
    [f addObjectsFromArray:@[@"-slots",[NSString stringWithFormat:@"%d", [[self configParam:@"eventBuffer"]   intValue]]]];
    [f addObjectsFromArray:@[@"-aph",  [NSString stringWithFormat:@"%d", [[self configParam:@"phaseAdjust"]   intValue]]]];
    [f addObjectsFromArray:@[@"-bls",  [NSString stringWithFormat:@"%d", [[self configParam:@"baselineSlew"]  intValue]]]];
    [f addObjectsFromArray:@[@"-il",   [NSString stringWithFormat:@"%d", [[self configParam:@"integratorLen"] intValue]]]];
    [f addObjectsFromArray:@[@"-es",   [NSString stringWithFormat:@"%d", [[self configParam:@"eventSamples"]  intValue]]]];
    [f addObjectsFromArray:@[@"-sd",   [NSString stringWithFormat:@"%d", [[self configParam:@"signalDepth"]   intValue]]]];
    [f addObjectsFromArray:@[@"-gt",   [NSString stringWithFormat:@"%d", [[self configParam:@"traceType"]     intValue]]]];
    [f addObjectsFromArray:@[@"-rst",  [NSString stringWithFormat:@"%d", [[self configParam:@"resetMode"]     intValue]]]];
    [f addObjectsFromArray:@[@"-tmo",  [NSString stringWithFormat:@"%d", [[self configParam:@"timeout"]       intValue]]]];
    [f addObjectsFromArray:@[@"-re",   [NSString stringWithFormat:@"%d", [[self configParam:@"evPerRequest"]  intValue]]]];
    [f addObjectsFromArray:@[@"-bl",   [NSString stringWithFormat:@"%d", [[self configParam:@"baselineCalib"] intValue]]]];
    [f addObjectsFromArray:@[@"-gpr",[NSString stringWithFormat:@"%.2f", [[self configParam:@"pileupRej"]  doubleValue]]]];
    [f addObjectsFromArray:@[@"-lt", [NSString stringWithFormat:@"%.2f", [[self configParam:@"logTime"]    doubleValue]]]];
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
    if(![self configParam:@"trigAllEnable"]) [f addObjectsFromArray:@[@"-athr", @"0"]];
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

- (double) throttle
{
    return throttle;
}

- (FCIOStateReader*) reader
{
    return reader;
}

- (int) readerRecordCount
{
    return readerRecordCount;
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

- (ORTaskSequence*) taskSequencer
{
    if(!taskSequencer){
        taskSequencer = [[ORTaskSequence taskSequenceWithDelegate:self] retain];
        [taskSequencer setVerbose:NO];
        [taskSequencer setTextToDelegate:YES];
    }
    return taskSequencer;
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
    [self setStatus:@"disconnected"];
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

- (void) setConfigParam:(NSString*)p withValue:(NSNumber*)v
{
    if([p isEqualToString:@"maxPayload"])
        [configParams setObject:[NSNumber numberWithInt:MAX(0, [v intValue])] forKey:p];
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
    else if([p isEqualToString:@"traceType"])
        [configParams setObject:[NSNumber numberWithInt:MIN(MAX(0, [v intValue]), 4)] forKey:p];
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
    else{
        NSLog(@"ORFlashCamListenerModel: unknown configuration parameter %@\n", p);
        return;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelConfigChanged object:self];
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

- (void) setThrottle:(double)t
{
    if(throttle == t) return;
    throttle = t;
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

- (bool) connect
{

    if(!chanMap){
        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: channel mapping has not been specified, aborting connection\n");
        [self setStatus:@"disconnected"];
        return NO;
    }
    if(!interface || port == 0){
        [self setStatus:@"disconnected"];
        return NO;
    }
    if([status isEqualToString:@"connected"]) return YES;
    [self setStatus:@"disconnected"];
    [self updateIP];
    if([ip isEqualToString:@""]){
        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: unable to obtain IP address for interface %@\n", interface);
        return NO;
    }
    NSString* s = [NSString stringWithFormat:@"tcp://listen/%d/%@", port, ip];
    reader = FCIOCreateStateReader([s UTF8String], timeout, ioBuffer, stateBuffer);
    FCIOSelectStateTag(reader, 0);
    if(reader){
        NSLog(@"ORFlashCamListenerModel: connected to %@:%d on %@\n", ip, port, interface);
        [self setStatus:@"connected"];
        readerRecordCount = 0;
        bufferedRecords   = 0;
        //[self read]; //now in takedata thread
        return YES;
    }
    else{
        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: unable to connect to %@:%d on %@\n", ip, port, interface);
        [self setStatus:@"disconnected"];
        return NO;
    }
}

- (void) disconnect:(bool)destroy
{

//    @synchronized(self){ //MAH not needed now that "read" is in takeData thread
        //[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(read) object:nil];
        if(reader) tmio_close(reader->stream);
        [self setStatus:@"disconnected"];
        if(destroy){
            if(reader) FCIODestroyStateReader(reader);
            reader = NULL;
        }
        if(![[self status] isEqualToString:@"disconnected"])
            NSLog(@"ORFlashCamListenerModel: disconnected from %@:%d on %@\n", ip, port, interface);
        [self setChanMap:nil];
        [self setCardMap:nil];
  //  }
}

- (void) read
{

    //-----------------------------------------------------------------------------------
    //MAH 9/18/22 
    //reading the status must not be done if the FC is being shutdown. If we get the lock
    //the run shutdown is not in progress and we continue normally.
    //The only way we don't get the lock is if a run is stopping.
    //-----------------------------------------------------------------------------------
    if([readStateLock tryLock]){
        //got the lock, it is safe to proceed
        if(!reader){
            [self disconnect:false];
            [readStateLock unlock]; //MAH. early return must release
            return;
        }
        // fixme: deal with nrecord roll overs - why is nrecords not an unsigned long?
        bufferedRecords = reader->nrecords - readerRecordCount;
        if(bufferedRecords > reader->max_states){
            NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: record buffer overflow for %@:%d on %@, aborting stream listening\n", ip, port, interface);
            [self disconnect:true];
            [self runFailed];
            [readStateLock unlock]; //MAH. early return must release
            return;
        }
        FCIOState* state = FCIOGetNextState(reader);
        if(state){
            if(![status isEqualToString:@"OK/running"]) [self setStatus:@"connected"];
            switch(state->last_tag){
                case FCIOConfig: {
                    for(id obj in dataTakers) [obj setWFsamples:state->config->eventsamples];
                    [self readConfig:state->config];
                    break;
                }
                case FCIOEvent: {
                    int num_traces = state->event->num_traces;
                    if(num_traces != [chanMap count]){
                        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: number of raw traces in event packet %d != channel map size %d, aborting\n", num_traces, [chanMap count]);
                        [self disconnect:true];
                        [self runFailed];
                        [readStateLock unlock]; //MAH. early return must release
                        return;
                    }
                    for(int itr=0; itr<num_traces; itr++){
                        NSDictionary* dict = [chanMap objectAtIndex:itr];
                        ORFlashCamADCModel* card = [dict objectForKey:@"adc"];
                        unsigned int chan = [[dict objectForKey:@"channel"] unsignedIntValue];
                        [card event:state->event withIndex:itr andChannel:chan];
                    }
                    break;
                }
                case FCIOSparseEvent: {
                    int num_traces = state->event->num_traces;
                    if(num_traces > [chanMap count]){
                        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: number of raw traces in event packet %d > channel map size %d, aborting\n", num_traces, [chanMap count]);
                        [self disconnect:true];
                        [self runFailed];
                        [readStateLock unlock]; //MAH. early return must release
                        return;
                    }
                    for(int itr=0; itr<num_traces; itr++){
                        NSDictionary* dict = [chanMap objectAtIndex:state->event->trace_list[itr]];
                        ORFlashCamADCModel* card = [dict objectForKey:@"adc"];
                        unsigned int chan = [[dict objectForKey:@"channel"] unsignedIntValue];
                        [card event:state->event withIndex:state->event->trace_list[itr] andChannel:chan];
                    }
                    break;
                }
                case FCIORecEvent:
                    if(!unrecognizedPacket){
                        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: skipping received FCIORecEvent packet - packet type not supported!\n");
                        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: WARNING - suppressing further instances of this message for this object in this run\n");
                    }
                    unrecognizedPacket = true;
                    break;
                case FCIOStatus:
                    [self readStatus:state->status];
                    break;
                default: {
                    bool found = false;
                    for(id n in unrecognizedStates) if((int) state->last_tag == [n intValue]) found = true;
                    if(!found){
                        [unrecognizedStates addObject:[NSNumber numberWithInt:(int)state->last_tag]];
                        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: unrecognized fcio state tag %d\n", state->last_tag);
                        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: WARNING - suppressing further instances of this message for this object in this run\n");
                    }
                    break;
                }
            }
            readerRecordCount ++;
        }
        else{
            if(![[self status] isEqualToString:@"disconnected"]){
                NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: failed to read state\n");
                [self disconnect:true];
                [self runFailed];
            }
            [readStateLock unlock]; //MAH. early return must release
            return;
        }
 //     if([gOrcaGlobals runRunning]) [self performSelector:@selector(read) withObject:nil afterDelay:throttle];  //MAH 10/17/22 read is now done in takeData thread.
        [readStateLock unlock]; //MAH
    }
    
}

- (void) runFailed
{
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

- (void) taskFinished:(id)task
{
}

- (void) tasksCompleted:(id)sender
{
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

- (void) taskData:(NSMutableDictionary*)taskData
{
    NSString* text = [[[taskData objectForKey:@"Text"] retain]autorelease];
    NSRange r0 = [text rangeOfString:@"event"];
    NSRange r1 = [text rangeOfString:@"OK/running"];
    if(r0.location != NSNotFound && r1.location != NSNotFound){
        // if the readout is running, parse the log command
        if(r1.location <= r0.location+r0.length) return;
        NSRange r = NSMakeRange(r0.location+r0.length+1, r1.location-r0.location-r0.length-2);
        NSArray* a = [[text substringWithRange:r] componentsSeparatedByString:@","];
        if([a count] != 6) return;
        status = @"OK/running";
        eventCount = [[a objectAtIndex:0] intValue];
        runTime =  [self parseValueFromFCLog:[a objectAtIndex:1] withIdentifier:@"sec"];
        readMB =   [self parseValueFromFCLog:[a objectAtIndex:2] withIdentifier:@"MB"   andBreak:@"/"];
        rateMB =   [self parseValueFromFCLog:[a objectAtIndex:4] withIdentifier:@"MB/s" andBreak:@"/"];
        rateHz =   [self parseValueFromFCLog:[a objectAtIndex:5] withIdentifier:@"evt/s"];
        timeLock = [self parseValueFromFCLog:[a objectAtIndex:5] withIdentifier:@"lock"];
        deadTime = [self parseValueFromFCLog:[a objectAtIndex:5] withIdentifier:@"dead"];
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
    // fixme: add updates for run termination, etc
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelStatusChanged object:self];
    //[text release]; //MAH 9/18/22 text leaked on early returns. Use autorelease above instead
}


#pragma mark •••Data taker methods

- (void) startReadoutAfterPing
{
    if([guardian pingRunning]){
        [self performSelector:@selector(startReadoutAfterPing) withObject:self afterDelay:0.01];
        return;
    }
    [self updateIP];
    
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
    unsigned int adcCount = 0;
    int maxShapeTime = 0;
    for(ORReadOutObject* obj in [readOutList children]){
        if(![[obj object] isKindOfClass:NSClassFromString(@"ORFlashCamCard")]) continue;
        ORFlashCamCard* card = (ORFlashCamCard*) [obj object];
        if([[card className] isEqualToString:@"ORFlashCamADCModel"]){
            ORFlashCamADCModel* adc = (ORFlashCamADCModel*) card;
            [addressList appendString:[NSString stringWithFormat:@"%x,", [adc cardAddress]]];
            [adcCards addObject:adc];
            [argCard addObjectsFromArray:[adc runFlagsForCardIndex:adcCount
                                                  andChannelOffset:adcCount*[adc numberOfChannels]
                                                       withTrigAll:[[self configParam:@"trigAllEnable"] boolValue]]];
            for(unsigned int ich=0; ich<[adc numberOfChannels]; ich++){
                if([adc chanEnabled:ich]){
                    NSDictionary* chDict = [NSDictionary dictionaryWithObjectsAndKeys:adc, @"adc", [NSNumber numberWithUnsignedInt:ich], @"channel", nil];
                    [orcaChanMap addObject:chDict];
                    maxShapeTime = MAX(maxShapeTime, [adc shapeTime:ich]);
                }
            }
            adcCount ++;
            // if this adc is connected to a trigger card, add to the respective set
            if([[card trigConnector] isConnected]){
                id conobj = [[card trigConnector] connectedObject];
                NSString* cname = [conobj className];
                if([cname isEqualToString:@"ORFlashCamGlobalTriggerModel"]) [gtriggerCards addObject:conobj];
                else if([cname isEqualToString:@"ORFlashCamTriggerModel"])  [triggerCards  addObject:conobj];
            }
        }
    }
    // check if the number of channels exceeds the hardware limit for flashcam
    if([orcaChanMap count] > FCIOMaxChannels){
        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel on %@ at %@:%d failed to start run due to number "
                   "of enabled channels %d exceeding the FCIO architectural limit of %d\n",
                   interface, ip, (int) port, [orcaChanMap count], FCIOMaxChannels);
        [self runFailed];
        return;
    }
    // make sure the shaping time and event samples are such that flashcam will silently change the waveform length
    if(MIN(8000, 20+maxShapeTime*2.5/16) > [[self configParam:@"eventSamples"] intValue]){
        int samples = [[self configParam:@"eventSamples"] intValue];
        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel on %@ at %@:%d failed to start run due to max shaping "
                   "time of %d ns with event samples set to %d. Set the shaping time for all channels <= %d ns or "
                   "set the event samples >= %d\n", interface, ip, (int) port, maxShapeTime, samples,
                   (int) ((samples-20)*16/2.5), (int) (20+maxShapeTime*2.5/16));
        [self runFailed];
        return;
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
        [readoutArgs addObjectsFromArray:[card runFlagsForCardIndex:ntrig]];
        ntrig ++;
    }
    [addressList insertString:trigAddr atIndex:0];
    mergeRunFlags(argCard);
    // make sure there is at most one global trigger card
    if([gtriggerCards count] > 1){
        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel on %@ at %@:%d failed to start run due to multiple connected global trigger cards\n", interface, ip, (int) port);
        [self runFailed];
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
    [argCard addObjectsFromArray:@[@"-a", [addressList substringWithRange:NSMakeRange(0, [addressList length]-1)]]];
    NSString* listen = [NSString stringWithFormat:@"tcp://connect/%d/%@", port, ip];
    [readoutArgs addObjectsFromArray:@[@"-ei", [[self remoteInterfaces] componentsJoinedByString:@","]]];
    [readoutArgs addObjectsFromArray:@[@"-et", [self ethType]]];
    [readoutArgs addObjectsFromArray:[self runFlags:NO]];
    [readoutArgs addObjectsFromArray:argCard];
    [readoutArgs addObjectsFromArray:@[@"-o", listen]];
    [self setReadOutArgs:readoutArgs];
//*******************************************************
//MAH 9/17/22 commented out this block. launching the readout doen't have to use the taskSequence object dirctly. Can just use NSTask. See below
//but keep the [self taskSequencer] code around in case Tom wants to use it for something else
//    if([guardian localMode]){
//        NSString* p = [[[guardian fcSourcePath] stringByExpandingTildeInPath] stringByAppendingString:@"/server/"];
//        [[self taskSequencer] addTask:[p stringByAppendingString:@"readout-fc250b"] arguments:[NSArray arrayWithArray:readoutArgs]];
//        NSLog(@"%@readout-fc250b %@\n", p, [readoutArgs componentsJoinedByString:@" "]);
//    }
//    else {
//        [[self taskSequencer] addTask:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/remote_run"]
//                      arguments:[NSArray arrayWithArray:readoutArgs]];
//    }
//  [[self taskSequencer] launch]; //MAH part of old way

//*******************************************************

//----------------------------------------------------------------------
//MAH 9/17/22. Using just NSTask directly so we can get hold of the standard input pipe
    [runTask release];
    runTask = [[NSTask alloc] init];
    
    NSString* taskPath;
    if([guardian localMode]){
        taskPath = [[[guardian fcSourcePath] stringByExpandingTildeInPath] stringByAppendingString:@"/server/readout-fc250b"];
        NSLog(@"%@readout-fc250b %@\n", taskPath, [readoutArgs componentsJoinedByString:@" "]);
    }
    else {
        taskPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/remote_run"];
    }
    
    [runTask setLaunchPath:taskPath];
    [runTask setArguments: [NSArray arrayWithArray:readoutArgs]];
    [runTask setStandardInput:[NSPipe pipe]];
    if(@available(macOS 10.13,*)){
        NSError *error =nil;
        if(![runTask launchAndReturnError:(&error)]){
            NSLogColor([NSColor redColor],@"ORFlashCamListenerModel: RunTask failed with error :%@ \n",error);
            [self runFailed];
            [runTask release]; //optional release here, could leave to the next run start???
            runTask = nil;     //make sure it can't be used
        }
    }
    else {
        //older MacOS's
        [runTask launch];
    }
//----------------------------------------------------------------------

    [self setChanMap:orcaChanMap];
    [self connect];
    if(![status isEqualToString:@"connected"]){
        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel on %@ at %@:%d failed to start run\n",
                   interface, ip, (int) port);
        [self runFailed];
    }
}

- (void) readConfig:(fcio_config*)config
{
    
   // @synchronized(self){ //MAH not needed now that "read" is in takeData thread
        // validate the number of waveform samples
        if(config->eventsamples != [[self configParam:@"eventSamples"] intValue]){
            NSLogColor([NSColor redColor], @"ORFlashCamListenerModel on %@ at %@:%d user defined waveform length %d "
                       " != waveform length from configuration packet %d\n", interface, ip, (int) port,
                       [[self configParam:@"eventSamples"] intValue], config->eventsamples);
            [self runFailed];
        }
        // read the configuration packet
        uint32_t index = configBufferIndex;
        configBufferIndex = (configBufferIndex + 1) % kFlashCamConfigBufferLength;
        bufferedConfigCount ++;
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
        memcpy(configBuffer + offset, config->tracemap, FCIOMaxChannels*sizeof(uint32_t));
        if(bufferedConfigCount == kFlashCamConfigBufferLength){
            NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: error config buffer full on %@ at %@:%d\n",
                       interface, ip, (int) port);
            [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelConfigBufferFull
                                                                object:self];
        }
        // validate the channel map
        bool fail = false;
        for(unsigned int i=0; i<FCIOMaxChannels; i++){
            uint32_t addr  = (config->tracemap[i] & 0xffff0000) >> 16;
            uint32_t input =  config->tracemap[i] & 0x0000ffff;
            if(i >= (unsigned int) [chanMap count]){
                if(config->tracemap[i] == 0) continue;
                else{
                    NSLogColor([NSColor redColor], @"ORFlashCamListenerModel on %@ at %@:%d failed to start run due to "
                               "FCIO channel map entry (index %u card 0x%x input %u) not found in Orca channel map\n",
                               interface, ip, (int) port, i, addr, input);
                    fail = true;
                    continue;
                }
            }
            NSDictionary* dict = [chanMap objectAtIndex:i];
            if([[dict objectForKey:@"adc"]          cardAddress] != addr ||
               [[dict objectForKey:@"channel"] unsignedIntValue] != input){
                NSLogColor([NSColor redColor], @"ORFlashCamListenerModel on %@ at %@:%d failed to start run due to "
                           "inconsistent channel map entry at index %u: FCIO - card 0x%x input %u, ORCA - card 0x%x input %u\n",
                           interface, ip, (int) port, i, addr, input,
                           [[dict objectForKey:@"adc"] cardAddress], [[dict objectForKey:@"channel"] unsignedIntValue]);
                fail = true;
            }
        }
        if(fail) [self runFailed];
        else NSLog(@"ORFlashCamListenerModel on %@ at %@:%d successfully validated channel map\n", interface, ip, (int) port);
   // }
}

- (void) readStatus:(fcio_status*)fcstatus
{
//@synchronized(self){ //MAH not needed now that "read" is in takeData thread
        uint32_t index = statusBufferIndex;
        statusBufferIndex = (statusBufferIndex + 1) % kFlashCamStatusBufferLength;
        bufferedStatusCount ++;
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
            NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: error status buffer full on %@ at %@:%d\n",
                       interface, ip, (int) port);
        }
   // }
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
//    @synchronized(self){ //MAH not needed now that "read" is in takeData thread
        @try {
            if(reader)[self read]; //MAH 10/17/22 added so read calld in this thread instead of GUI thread
            // add a single configuration packet to the data
            if(bufferedConfigCount > 0){
                uint32_t length = 2 + sizeof(fcio_config) / sizeof(uint32_t);
                uint32_t index = length * takeDataConfigIndex;
                takeDataConfigIndex = (takeDataConfigIndex + 1) % kFlashCamConfigBufferLength;
                bufferedConfigCount --;
                configBuffer[index]    = configId | (length & 0x3ffff);
                configBuffer[index+1]  = ((unsigned short) [guardian uniqueIdNumber]) << 16;
                configBuffer[index+1] |=  (unsigned short) [self uniqueIdNumber];
                [aDataPacket addLongsToFrameBuffer:configBuffer+index length:length];
            }
            // add a single status packet to the data
            if(bufferedStatusCount > 0){
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
                [aDataPacket addLongsToFrameBuffer:statusBuffer+index length:length];
            }
            // allow all connected data takers to add to the data packet
            NSEnumerator* e = [dataTakers objectEnumerator];
            id obj;
            while(obj = [e nextObject]) [obj takeData:aDataPacket userInfo:userInfo];
        }
        @catch(NSException* e){
            NSLogError(@"",@"FlashCamListener Error",@"");
            [e raise];
        }
//    }
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(runFailedAlarm) [runFailedAlarm clearAlarm];
    unrecognizedPacket = false;
    if(!unrecognizedStates) unrecognizedStates = [[NSMutableArray array] retain];
    [unrecognizedStates removeAllObjects];
    [readOutArgs removeAllObjects];
    memset(configBuffer, 0, kFlashCamConfigBufferLength * (2 + sizeof(fcio_config)/sizeof(uint32_t)));
    configBufferIndex = 0;
    takeDataConfigIndex = 0;
    bufferedConfigCount = 0;
    memset(statusBuffer, 0, kFlashCamStatusBufferLength * (2 + sizeof(fcio_status)/sizeof(uint32_t)));
    statusBufferIndex = 0;
    takeDataStatusIndex = 0;
    bufferedStatusCount = 0;
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"ORFlashCamListenerModel"];
    [self startReadoutAfterPing];
    dataTakers = [[readOutList allObjects] retain];
    NSEnumerator* e = [[readOutList allObjects] objectEnumerator];
    id obj;
    while(obj = [e nextObject]) [obj runTaskStarted:aDataPacket userInfo:userInfo];
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    //-----------------------------------------------------
    //MAH 9/17/22... shut down the FlashCAM by sending an EOL
    //The periodic status read will be not be repeated if the global
    //running flag is clear, but there might one pending.
    //this next line will ensure it doesn't get rescheduled at all after this point
//    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(read) object:nil];
    @try { //MAH just in case an exception is thrown in the following block
        //If there is a read status in flight, we will block here until it is done
        [readStateLock lock];
        NSFileHandle*  fh = [[runTask standardInput] fileHandleForWriting];
        [fh writeData:[@"\n" dataUsingEncoding: NSASCIIStringEncoding]];
        [ORTimer delay:2]; //been told we have to wait 2 seconds
        [runTask terminate];
        [runTask release]; //optional release here, could leave to the next run start???
        runTask = nil;     //make sure it can't be used
    }
    @catch(NSException* e){
    }
    @finally {
        [readStateLock unlock];
    }
    //-----------------------------------------------------

    [self disconnect:false];
    [[self taskSequencer] abortTasks];
    [taskSequencer release];
    taskSequencer = nil;
    [readOutArgs removeAllObjects];
    
    memset(configBuffer, 0, kFlashCamConfigBufferLength * (2 + sizeof(fcio_config)/sizeof(uint32_t)));
    configBufferIndex = 0;
    takeDataConfigIndex = 0;
    bufferedConfigCount = 0;
    memset(statusBuffer, 0, kFlashCamStatusBufferLength * (2 + sizeof(fcio_status)/sizeof(uint32_t)));
    statusBufferIndex = 0;
    takeDataStatusIndex = 0;
    bufferedStatusCount = 0;
    // write the remaining config and status packets
    while(bufferedConfigCount > 0 || bufferedStatusCount > 0) [self takeData:aDataPacket userInfo:userInfo];
    // allow the connected data takers to write any remaining data
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]) [obj runIsStopping:aDataPacket userInfo:userInfo];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(reader) FCIODestroyStateReader(reader);
    reader = NULL;
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
    [self setThrottle:        [decoder decodeDoubleForKey:@"throttle"]];
    if(configParams) [configParams release];
    configParams = [[decoder decodeObjectForKey:@"configParams"] retain];
    reader            = NULL;
    readerRecordCount = 0;
    bufferedRecords   = 0;
    if(!configBuffer) configBuffer = (uint32_t*) malloc((2*sizeof(uint32_t) + sizeof(fcio_config)) * kFlashCamConfigBufferLength);
    configBufferIndex = 0;
    takeDataConfigIndex=0;
    bufferedConfigCount=0;
    if(!statusBuffer) statusBuffer = (uint32_t*) malloc((2*sizeof(uint32_t) + sizeof(fcio_status)) * kFlashCamStatusBufferLength);
    statusBufferIndex = 0;
    takeDataStatusIndex=0;
    bufferedStatusCount=0;
    eventCount        = 0;
    runTime           = 0.0;
    readMB            = 0.0;
    rateMB            = 0.0;
    rateHz            = 0.0;
    timeLock          = 0.0;
    deadTime          = 0.0;
    totDead           = 0.0;
    curDead           = 0.0;
   // [dataRateHistory autorelease]; //MAH 10/5/22 not needed
    dataRateHistory   = [[ORTimeRate alloc] init];
    [dataRateHistory  setLastAverageTime:[NSDate date]];
    [dataRateHistory  setSampleTime:10];
   // [eventRateHistory autorelease];//MAH 10/5/22 not needed
    eventRateHistory  = [[ORTimeRate alloc] init];
    [eventRateHistory setLastAverageTime:[NSDate date]];
    [eventRateHistory setSampleTime:10];
  //  [deadTimeHistory autorelease];//MAH 10/5/22 not needed
    deadTimeHistory   = [[ORTimeRate alloc] init];
    [deadTimeHistory  setLastAverageTime:[NSDate date]];
    [deadTimeHistory  setSampleTime:10];
    taskSequencer           = nil;
    chanMap           = nil;
    [self setReadOutList:[decoder decodeObjectForKey:@"readOutList"]];
    //[self setReadOutArgs:[[NSMutableArray alloc] init]]; //MAH 9/12/22 commented out. Caused double retain
    readStateLock = [[NSLock alloc]init]; //MAH added some thread safety
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:interface        forKey:@"interface"];
    [encoder encodeInt:(int)port           forKey:@"port"];
    [encoder encodeObject:remoteInterfaces forKey:@"remoteInterfaces"];
    [encoder encodeObject:configParams     forKey:@"configParams"];
    [encoder encodeInt:timeout             forKey:@"timeout"];
    [encoder encodeInt:ioBuffer            forKey:@"ioBuffer"];
    [encoder encodeInt:stateBuffer         forKey:@"stateBuffer"];
    [encoder encodeDouble:throttle         forKey:@"throttle"];
    [encoder encodeObject:readOutList      forKey:@"readOutList"];
}

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    [dictionary setObject:[self className] forKey:@"Class Name"];
    [dictionary setObject:[NSNumber numberWithUnsignedInt:[self uniqueIdNumber]] forKey:@"uniqueID"];
    [dictionary setObject:interface forKey:@"interface"];
    [dictionary setObject:[NSNumber numberWithUnsignedInt:port] forKey:@"port"];
    for(id key in configParams) [dictionary setObject:[configParams objectForKey:key] forKey:key]; //MAH 9/18/22 no need to retain

    return dictionary;
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
