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
#import "Utilities.h"

NSString* ORFlashCamListenerModelConfigChanged = @"ORFlashCamListenerModelConfigChanged";
NSString* ORFlashCamListenerModelStatusChanged = @"ORFlashCamListenerModelStatusChanged";
//NSString* ORFlashCamListenerModelConnected     = @"ORFlashCamListenerModelConnected";
//NSString* ORFlashCamListenerModelDisconnected  = @"ORFlashCamListenerModelDisconnected";
NSString* ORFlashCamListenerChanMapChanged = @"ORFlashCamListenerModelChanMapChanged";

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
    stateBuffer        = 20000;
    throttle           = 0.0;
    reader             = NULL;
    readerRecordCount  = 0;
    bufferedRecords    = 0;
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
    dataRateHistory    = [[[ORTimeRate alloc] init] retain];
    [dataRateHistory   setLastAverageTime:[NSDate date]];
    [dataRateHistory   setSampleTime:10];
    eventRateHistory   = [[[ORTimeRate alloc] init] retain];
    [eventRateHistory  setLastAverageTime:[NSDate date]];
    [eventRateHistory  setSampleTime:10];
    deadTimeHistory    = [[[ORTimeRate alloc] init] retain];
    [deadTimeHistory   setLastAverageTime:[NSDate date]];
    [deadTimeHistory   setSampleTime:10];
    runTask            = nil;
    chanMap            = nil;
    [self setRemoteInterfaces:[NSMutableArray array]];
    ORReadOutList* readList = [[ORReadOutList alloc] initWithIdentifier:@"ReadOut List"];
    [readList setAcceptedProtocol:@"ORDataTaker"];
    [readList addAcceptedObjectName:@"ORFlashCamADCModel"];
    [self setReadOutList:readList];
    [readList release];
    [self setReadOutArgs:[NSMutableArray array]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (id) initWithInterface:(NSString*)iface port:(uint16_t)p
{
    [self init];
    interface   = [[iface copy] retain];
    port        = p;
    return self;
}

- (void) dealloc
{
    [interface release];
    [ip release];
    [remoteInterfaces release];
    [status release];
    if(runFailedAlarm){
        [runFailedAlarm clearAlarm];
        [runFailedAlarm release];
    }
    if(unrecognizedStates) [unrecognizedStates release];
    if(reader) FCIODestroyStateReader(reader);
    [dataRateHistory release];
    [eventRateHistory release];
    [deadTimeHistory release];
    [runTask release];
    [readOutList release];
    [readOutArgs release];
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
    for(int i=0; i<(int)[self remoteInterfaceCount]; i++){
        NSString* t = [guardian ethTypeAtIndex:i];
        if([type isEqualToString:@""]) type = [t copy];
        else if(![t isEqualToString:type]){
            NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: error getting ethernet type - all interfaces associated with the same listener must have identical type\n");
            return @"";
        }
    }
    return type;
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

- (ORTaskSequence*) runTask
{
    if(!runTask){
        runTask = [[ORTaskSequence taskSequenceWithDelegate:self] retain];
        [runTask setVerbose:NO];
        [runTask setTextToDelegate:YES];
    }
    return runTask;
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

- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* dict = [super addParametersToDictionary:dictionary];
    [dict setObject:interface forKey:@"interface"];
    [dict setObject:[NSNumber numberWithUnsignedInt:port] forKey:@"port"];
    return dict;
}

- (void) setInterface:(NSString*)iface andPort:(uint16_t)p
{
    if(!iface) return;
    if(interface) if([interface isEqualToString:iface] && port == p) return;
    interface = [[iface copy] retain];
    port = p;
    [self updateIP];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelConfigChanged
                                                        object:self];
}

- (void) setInterface:(NSString*)iface
{
    if(!iface) return;
    if(interface) if([interface isEqualToString:iface]) return;
    interface = [[iface copy] retain];
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

- (void) setReadOutList:(ORReadOutList*)newList
{
    [readOutList autorelease];
    readOutList = [newList retain];
}

- (void) setReadOutArgs:(NSMutableArray*)args
{
    [readOutArgs autorelease];
    readOutArgs = [args retain];
}

- (void) setChanMap:(NSMutableArray*)chMap
{
    [chanMap autorelease];
    chanMap = [chMap retain];
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
    if(reader){
        NSLog(@"ORFlashCamListenerModel: connected to %@:%d on %@\n", ip, port, interface);
        [self setStatus:@"connected"];
        readerRecordCount = 0;
        bufferedRecords   = 0;
        [self read];
        return YES;
    }
    else{
        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: unable to connect to %@:%d on %@\n", ip, port, interface);
        [self setStatus:@"disconnected"];
        return NO;
    }
}

- (void) disconnect
{
    if(reader) FCIODestroyStateReader(reader);
    reader = NULL;
    if(![[self status] isEqualToString:@"disconnected"])
        NSLog(@"ORFlashCamListenerModel: disconnected from %@:%d on %@\n", ip, port, interface);
    [self setStatus:@"disconnected"];
    [self setChanMap:nil];
    readerRecordCount = 0;
    bufferedRecords   = 0;
}

- (void) read
{
    if(!reader){
        [self disconnect];
        return;
    }
    // fixme: deal with nrecord roll overs - why is nrecords not an unsigned long?
    bufferedRecords = reader->nrecords - readerRecordCount;
    if(bufferedRecords > reader->max_states){
        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: record buffer overflow for %@:%d on %@, aborting stream listening\n", ip, port, interface);
        [self disconnect];
        [self runFailed];
        return;
    }
    FCIOState* state = FCIOGetNextState(reader);
    if(state){
        if(![status isEqualToString:@"OK/running"]) [self setStatus:@"connected"];
        switch(state->last_tag){
            case FCIOConfig: {
                for(id obj in dataTakers) [obj setWFsamples:state->config->eventsamples];
                break;
            }
            case FCIOEvent: {
                int num_traces = state->event->num_traces;
                if(num_traces != [chanMap count]){
                    NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: number of raw traces in event packet %d != channel map size %d, aborting\n", num_traces, [chanMap count]);
                    [self disconnect];
                    [self runFailed];
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
            case FCIORecEvent:
                if(!unrecognizedPacket){
                    NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: skipping received FCIORecEvent packet - packet type not supported!\n");
                    NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: WARNING - suppressing further instances of this message for this object in this run\n");
                }
                unrecognizedPacket = true;
                break;
            case FCIOStatus:
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
        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel: failed to read state\n");
        [self disconnect];
        return;
    }
    [self performSelector:@selector(read) withObject:nil afterDelay:throttle];
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
    NSString* text = [[taskData objectForKey:@"Text"] retain];
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
    [text release];
}


#pragma mark •••Data taker methods

- (void) startReadoutAfterPing
{
    if([guardian pingRunning] || [readOutArgs count] == 0){
        [self performSelector:@selector(startReadoutAfterPing) withObject:self afterDelay:0.01];
        return;
    }
    [self updateIP];
    NSMutableArray* argCard      = [NSMutableArray array];
    NSMutableString* addressList = [NSMutableString string];
    NSMutableArray* orcaChanMap  = [NSMutableArray array];
    unsigned int adcCount = 0;
    for(ORReadOutObject* obj in [readOutList children]){
        if(![[obj object] isKindOfClass:NSClassFromString(@"ORFlashCamCard")]) continue;
        ORFlashCamCard* card = (ORFlashCamCard*) [obj object];
        if([[card className] isEqualToString:@"ORFlashCamADCModel"]){
            ORFlashCamADCModel* adc = (ORFlashCamADCModel*) card;
            [addressList appendString:[NSString stringWithFormat:@"%x,", [adc cardAddress]]];
            [argCard addObjectsFromArray:[adc runFlagsForCardIndex:adcCount
                                                  andChannelOffset:(unsigned int)[orcaChanMap count]]];
            for(unsigned int ich=0; ich<kMaxFlashCamADCChannels; ich++){
                if([adc chanEnabled:ich]){
                    NSDictionary* chDict = [NSDictionary dictionaryWithObjectsAndKeys:adc, @"adc", [NSNumber numberWithUnsignedInt:ich], @"channel", nil];
                    [orcaChanMap addObject:chDict];
                }
            }
            adcCount ++;
        }
    }
    // fixme: check for no cards and no enabled channels here
    [argCard addObjectsFromArray:@[@"-a", [addressList substringWithRange:NSMakeRange(0, [addressList length]-1)]]];
    // fixme: check channel maps here
    // fixme: add the card level arguments and the addresses for the trigger card(s)
    bool foundTrigger = NO;
    for(NSString* e in [self remoteInterfaces]){
        NSMutableArray* triggers = [guardian connectedObjects:@"ORFlashCamTriggerModel" toInterface:e];
        if([triggers count] > 0){
            ORFlashCamTriggerModel* trigger = [triggers objectAtIndex:0];
            if([triggers count] > 1 || foundTrigger)
                NSLog(@"ORFlashCamReadoutModel: multiple trigger cards connected, assuming first"
                        " trigger card in configuration 0x%x\n", [trigger cardAddress]);
            [argCard addObjectsFromArray:@[@"-ma", [NSString stringWithFormat:@"%x", [trigger cardAddress]]]];
            foundTrigger = YES;
            // fixme - don't know if trigger addresses also need to be added to address list
        }
    }
    NSString* listen = [NSString stringWithFormat:@"tcp://connect/%d/%@", port, ip];
    [readOutArgs addObjectsFromArray:@[@"-ei", [[self remoteInterfaces] componentsJoinedByString:@","]]];
    [readOutArgs addObjectsFromArray:@[@"-et", [self ethType]]];
    [readOutArgs addObjectsFromArray:argCard];
    [readOutArgs addObjectsFromArray:@[@"-o", listen]];
    if([guardian localMode]){
        NSString* p = [[[guardian fcSourcePath] stringByExpandingTildeInPath] stringByAppendingString:@"/server/"];
        [[self runTask] addTask:[p stringByAppendingString:@"readout-fc250b"] arguments:[NSArray arrayWithArray:readOutArgs]];
    }
    else{
        [[self runTask] addTask:[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/remote_run"]
                      arguments:[NSArray arrayWithArray:readOutArgs]];
    }
    [[self runTask] launch];
    [self setChanMap:orcaChanMap];
    [self connect];
    if(![status isEqualToString:@"connected"]){
        NSLogColor([NSColor redColor], @"ORFlashCamListenerModel on %@ at %@:%d failed to start run\n",
                   interface, ip, (int) port);
        [self runFailed];
    }
}

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]) [obj takeData:aDataPacket userInfo:userInfo];
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    if(runFailedAlarm) [runFailedAlarm clearAlarm];
    unrecognizedPacket = false;
    if(!unrecognizedStates) unrecognizedStates = [[NSMutableArray array] retain];
    [unrecognizedStates removeAllObjects];
    [readOutArgs removeAllObjects];
    [self startReadoutAfterPing];
    dataTakers = [[readOutList allObjects] retain];
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]) [obj runTaskStarted:aDataPacket userInfo:userInfo];
}

- (void) runIsStopping:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    NSEnumerator* e = [dataTakers objectEnumerator];
    id obj;
    while(obj = [e nextObject]) [obj runIsStopping:aDataPacket userInfo:userInfo];
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    [self disconnect];
    [[self runTask] abortTasks];
    [runTask release];
    runTask = nil;
    [readOutArgs removeAllObjects];
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
    reader            = NULL;
    readerRecordCount = 0;
    bufferedRecords   = 0;
    eventCount        = 0;
    runTime           = 0.0;
    readMB            = 0.0;
    rateMB            = 0.0;
    rateHz            = 0.0;
    timeLock          = 0.0;
    deadTime          = 0.0;
    totDead           = 0.0;
    curDead           = 0.0;
    [dataRateHistory autorelease];
    dataRateHistory   = [[[ORTimeRate alloc] init] retain];
    [dataRateHistory  setLastAverageTime:[NSDate date]];
    [dataRateHistory  setSampleTime:10];
    [eventRateHistory autorelease];
    eventRateHistory  = [[[ORTimeRate alloc] init] retain];
    [eventRateHistory setLastAverageTime:[NSDate date]];
    [eventRateHistory setSampleTime:10];
    [deadTimeHistory autorelease];
    deadTimeHistory   = [[[ORTimeRate alloc] init] retain];
    [deadTimeHistory  setLastAverageTime:[NSDate date]];
    [deadTimeHistory  setSampleTime:10];
    runTask           = nil;
    chanMap           = nil;
    [self setReadOutList:[decoder decodeObjectForKey:@"readOutList"]];
    [self setReadOutArgs:[NSMutableArray array]];
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:interface        forKey:@"interface"];
    [encoder encodeInt:(int)port           forKey:@"port"];
    [encoder encodeObject:remoteInterfaces forKey:@"remoteInterfaces"];
    [encoder encodeInt:timeout             forKey:@"timeout"];
    [encoder encodeInt:ioBuffer            forKey:@"ioBuffer"];
    [encoder encodeInt:stateBuffer         forKey:@"stateBuffer"];
    [encoder encodeDouble:throttle         forKey:@"throttle"];
    [encoder encodeObject:readOutList      forKey:@"readOutList"];
}

@end

@implementation ORFlashCamListenerModel (private)
- (void) setStatus:(NSString*)s
{
    if(status) if([status isEqualToString:s]) return;
    status = [[s copy] retain];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerModelStatusChanged
                                                        object:self];
}

@end
