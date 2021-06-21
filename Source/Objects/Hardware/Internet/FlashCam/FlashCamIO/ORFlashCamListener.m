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

#import "ORFlashCamListener.h"
#import "ORFlashCamReadoutModel.h"
#import "ORFlashCamADCModel.h"
#import "Utilities.h"

NSString* ORFlashCamListenerConfigChanged = @"ORFlashCamListenerConfigChanged";
NSString* ORFlashCamListenerStatusChanged = @"ORFlashCamListenerStatusChanged";
//NSString* ORFlashCamListenerConnected     = @"ORFlashCamListenerConnected";
//NSString* ORFlashCamListenerDisconnected  = @"ORFlashCamListenerDisconnected";
NSString* ORFlashCamListenerChanMapChanged = @"ORFlashCamListenerChanMapChanged";

@implementation ORFlashCamListener

#pragma mark •••Initialization

- (id) init
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    interface         = @"";
    port              = 4000;
    ip                = @"";
    timeout           = 2000;
    ioBuffer          = BUFIO_BUFSIZE/1024;
    stateBuffer       = 20000;
    throttle          = 0.0;
    reader            = NULL;
    readerRecordCount = 0;
    bufferedRecords   = 0;
    status            = @"disconnected";
    eventCount        = 0;
    runTime           = 0.0;
    readMB            = 0.0;
    rateMB            = 0.0;
    rateHz            = 0.0;
    timeLock          = 0.0;
    deadTime          = 0.0;
    totDead           = 0.0;
    curDead           = 0.0;
    runTask           = nil;
    readOutList       = nil;
    chanMap           = nil;
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (id) initWithInterface:(NSString*)iface port:(uint16_t)p readOutIdentifier:(NSString*)roi
{
    [self init];
    interface   = [[iface copy] retain];
    port        = p;
    readOutList = [[[ORReadOutList alloc] initWithIdentifier:roi] retain];
    [readOutList setAcceptedProtocol:@"ORDataTakerReadOutList"];
    [readOutList addAcceptedObjectName:@"ORFlashCamADCModel"];
    return self;
}

- (void) dealloc
{
    [interface release];
    [ip release];
    [status release];
    if(reader) FCIODestroyStateReader(reader);
    if(runTask) [runTask release];
    if(readOutList) [readOutList release];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [super dealloc];
}


#pragma mark •••Accessors

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

- (void) setInterface:(NSString*)iface andPort:(uint16_t)p
{
    if(!iface) return;
    if(interface) if([interface isEqualToString:iface] && port == p) return;
    interface = [[iface copy] retain];
    port = p;
    [self updateIP];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerConfigChanged
                                                        object:self];
}

- (void) setInterface:(NSString*)iface
{
    if(!iface) return;
    if(interface) if([interface isEqualToString:iface]) return;
    interface = [[iface copy] retain];
    [self updateIP];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerConfigChanged
                                                        object:self];
}

- (void) updateIP
{
    NSString* tmp = ipAddress(interface);
    if(ip) if([ip isEqualToString:tmp]) return;
    [ip release];
    ip = [tmp retain];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerConfigChanged
                                                        object:self];
    [self setStatus:@"disconnected"];
    return;
}

- (void) setPort:(uint16_t)p
{
    if(port == p) return;
    port = p;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerConfigChanged
                                                        object:self];
}

- (void) setTimeout:(int)to
{
    if(timeout == to) return;
    timeout = to;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerConfigChanged
                                                        object:self];
}

- (void) setIObuffer:(int)io
{
    if(ioBuffer == io) return;
    ioBuffer = io;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerConfigChanged
                                                        object:self];
}

- (void) setStateBuffer:(int)sb
{
    if(stateBuffer == sb) return;
    stateBuffer = sb;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerConfigChanged
                                                        object:self];
}

- (void) setThrottle:(double)t
{
    if(throttle == t) return;
    throttle = t;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerConfigChanged
                                                        object:self];
}

- (void) setChanMap:(NSMutableArray*)chMap
{
    if(chanMap) [chanMap release];
    chanMap = nil;
    if(chMap){
        [chMap autorelease];
        chanMap = [[chMap copy] retain];
    }
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
        NSLog(@"ORFlashCamListener: channel mapping has not been specified, aborting connection\n");
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
        NSLog(@"ORFlashCamListener: unable to obtain IP address for interface %@\n", interface);
        return NO;
    }
    NSString* s = [NSString stringWithFormat:@"tcp://listen/%d/%@", port, ip];
    reader = FCIOCreateStateReader([s UTF8String], timeout, ioBuffer, stateBuffer);
    if(reader){
        NSLog(@"ORFlashCamListener: connected to %@:%d on %@\n", ip, port, interface);
        [self setStatus:@"connected"];
        readerRecordCount = 0;
        bufferedRecords   = 0;
        [self read];
        return YES;
    }
    else{
        NSLog(@"ORFlashCamListener: unable to connect to %@:%d on %@\n", ip, port, interface);
        return NO;
    }
}

- (void) disconnect
{
    if(reader) FCIODestroyStateReader(reader);
    reader = NULL;
    if(![[self status] isEqualToString:@"disconnected"])
        NSLog(@"ORFlashCamListener: disconnected from %@:%d on %@\n", ip, port, interface);
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
        NSLog(@"ORFlashCamListener: record buffer overflow, aborting stream listening\n");
        [self disconnect];
        return;
    }
    while(bufferedRecords > 0){
        FCIOState* state = FCIOGetNextState(reader);
        if(state){
            if(![status isEqualToString:@"OK/running"]) [self setStatus:@"connected"];
            switch(state->last_tag){
                case FCIOConfig: {
                    NSMutableArray* cards = [NSMutableArray array];
                    for(id dict in chanMap){
                        ORFlashCamADCModel* card = [dict objectForKey:@"adc"];
                        if([cards containsObject:card]) continue;
                        [card setWFsamples:state->config->eventsamples];
                    }
                    break;
                }
                case FCIOEvent: {
                    int num_traces = state->event->num_traces;
                    if(num_traces != [chanMap count]){
                        NSLog(@"ORFlashCamListener: number of raw traces in event packet != channel map size, aborting\n");
                        [self disconnect];
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
                    NSLog(@"ORFlashCamListener: skipping received FCIORecEvent packet - packet type not supported\n");
                    break;
                case FCIOStatus:
                    break;
                default:
                    NSLog(@"ORFlashCamListener: unrecognized fcio state tag %d\n", state->last_tag);
                    break;
            }
            bufferedRecords --;
            readerRecordCount ++;
        
            /*if(reader->nrecords % 10000 == 0){
             NSLog(@"FCIORead:\n");
             NSLog(@"\tnrecords   %d\n", reader->nrecords);
             NSLog(@"\tmax_states %d\n", reader->max_states);
             NSLog(@"\tcur_state  %d\n", reader->cur_state);
             NSLog(@"\tlast_tag   %d\n", state->last_tag);
             NSLog(@"\tnconfigs   %d\n", reader->nconfigs);
             NSLog(@"\tnevents    %d\n", reader->nevents);
             NSLog(@"\tnstatuses  %d\n", reader->nstatuses);
             NSLog(@"\tnrecev     %d\n", reader->nrecevents);
             }*/
        }
        else{
            NSLog(@"ORFlashCamListener: failed to read state\n");
            [self disconnect];
            return;
        }
        [self performSelector:@selector(read) withObject:nil afterDelay:throttle];
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
        NSLog(@"%d%@\n", [v count], v);
        if([v count] >= 10){
            totDead = [[v objectAtIndex:[v count]-2] doubleValue];
            curDead = [[v objectAtIndex:[v count]-1] doubleValue];
        }
        else{
            totDead = -1.0;
            curDead = -1.0;
        }
    }
    /*else{
         r0 = [text rangeOfString:@"ORFlashCamRunModel: starting readout, writing to"];
         r1 = [text rangeOfString:@" endl "];
         if(r0.location != NSNotFound && r1.location != NSNotFound){
             NSString* s = [NSString stringWithFormat:@"tcp://listen/%d/%@", port, ip];
             if(reader) FCIODestroyStateReader(reader);
             reader = FCIOCreateStateReader([s UTF8String], timeout, ioBuffer, stateBuffer);
             if(reader){
                 NSLog(@"ORFlashCamListener: connected to %@:%d on %@\n", ip, port, interface);
                 [self read];
             }
             else NSLog(@"ORFlashCamListener: unable to connect to %@:%d on %@\n",
                        ip, port, interface);
         }
    }*/
    // fixme: add updates for run termination, etc
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerStatusChanged object:self];
    [text release];
}


#pragma mark •••Data taker methods

- (void) takeData:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    
}

- (void) runTaskStarted:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    
}

- (void) runTaskStopped:(ORDataPacket*)aDataPacket userInfo:(NSDictionary*)userInfo
{
    
}

- (void) reset
{
    
}


#pragma mark •••Archival

- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    [[self undoManager] disableUndoRegistration];
    [self setInterface:     [decoder decodeObjectForKey:@"interface"]];
    [self setPort:(uint16_t)[decoder decodeIntForKey:@"port"]];
    [self setTimeout:       [decoder decodeIntForKey:@"timeout"]];
    [self setIObuffer:      [decoder decodeIntForKey:@"ioBuffer"]];
    [self setStateBuffer:   [decoder decodeIntForKey:@"stateBuffer"]];
    [self setThrottle:      [decoder decodeDoubleForKey:@"throttle"]];
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
    runTask           = nil;
    readOutList       = [decoder decodeObjectForKey:@"readOutList"];
    chanMap           = nil;
    [[self undoManager] enableUndoRegistration];
    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeObject:interface   forKey:@"interface"];
    [encoder encodeInt:(int)port      forKey:@"port"];
    [encoder encodeInt:timeout        forKey:@"timeout"];
    [encoder encodeInt:ioBuffer       forKey:@"ioBuffer"];
    [encoder encodeInt:stateBuffer    forKey:@"stateBuffer"];
    [encoder encodeDouble:throttle    forKey:@"throttle"];
    [encoder encodeObject:readOutList forKey:@"readOutList"];
}

@end

@implementation ORFlashCamListener (private)
- (void) setStatus:(NSString*)s
{
    if(status) if([status isEqualToString:s]) return;
    status = [[s copy] retain];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORFlashCamListenerStatusChanged
                                                        object:self];
}
@end
