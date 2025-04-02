//  Orca
//  ORFlashCamListenerDecoders.m
//
//  Created by Tom Caldwell on November 28, 2021
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

#import "ORFlashCamListenerDecoders.h"
#import "fcio.h"
#import "fcio_utils.h"
#import "tmio.h"

@implementation ORFCIOBaseDecoder

- (void) setConfig:(ORFCIOConfigDecoder*)another
{
    config = another;
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    return 0;
}

@end


@implementation ORFCIOConfigDecoder

- (ORFCIOConfigDecoder*) init
{
    [super init];
    if (self != nil) {
        for (int i = 0; i < kMaxFCIOStreams; i++) {
            fcioStreams[i] = NULL;
            processors[i] = NULL;
            initialized[i] = NO;
        }
    }
    return self;
}

- (void) dealloc
{
    [super dealloc];
    for (int i = 0; i < kMaxFCIOStreams; i++) {
        FCIOClose(fcioStreams[i]);
        FSPDestroy(processors[i]);
    }
}

- (void)broadcastToOthers:(ORDecoder*)aDecoder
{
    if ([self decodersInitialized])
        return;

    NSArray *supportedDecoders = @[@"FlashCamEvent", @"FlashCamEventHeader", @"FlashCamStatus"];
    for (NSString* dec in supportedDecoders) {
        id dataId = [aDecoder headerObject:@"dataDescription",@"ORFlashCamListenerModel",dec,@"dataId",nil];
        ORFCIOBaseDecoder* decoder = (ORFCIOBaseDecoder*)[aDecoder objectForKey: (id)dataId];
        [decoder setConfig:self];
    }
    initialized[currentListenerId] = YES;
}


- (void) setupOptionsfromHeader:(NSDictionary*)aHeader forListener:(uint32_t) listener_id andTracemap:(unsigned int*)tracemap withSize:(size_t)nadcs;
{
    if(!decoderOptions) decoderOptions = [[NSMutableDictionary dictionary] retain];
    //set up the crate cache
    NSArray* crates = [aHeader nestedObjectForKey:@"ObjectInfo",@"Crates",nil];

    for (int crateIndex = 0; crateIndex < [crates count]; crateIndex++){

        NSDictionary* headerCrateDictionary = [crates objectAtIndex:crateIndex];
        NSNumber* crate = [headerCrateDictionary objectForKey:@"CrateNumber"];

        NSArray* cards = [headerCrateDictionary objectForKey:@"Cards"];
        for (int cardIndex = 0; cardIndex < [cards count]; cardIndex++){
            NSDictionary* headerCardDictionary = [cards objectAtIndex:cardIndex];
            NSNumber* card = [headerCardDictionary objectForKey:@"Card"];

            unsigned int cardAddress = [[headerCardDictionary objectForKey:@"CardAddress"] unsignedIntValue];
            for (int trace_idx = 0; trace_idx < nadcs; trace_idx++) {
                unsigned int fcioCardAddress = tracemap[trace_idx] >> 16;
                if (fcioCardAddress == cardAddress) {
                    unsigned int chan = tracemap[trace_idx] & 0xFFFF;
                    NSNumber* channel = [NSNumber numberWithUnsignedInteger:chan];
                    [decoderOptions setObject:crate forKey:[NSString stringWithFormat:@"Listener %2d,Trace %4d,crate", listener_id, trace_idx]];
                    [decoderOptions setObject:card forKey:[NSString stringWithFormat:@"Listener %2d,Trace %4d,card", listener_id, trace_idx]];
                    [decoderOptions setObject:channel forKey:[NSString stringWithFormat:@"Listener %2d,Trace %4d,channel", listener_id, trace_idx]];
                }
            }
        }
    }
}

- (bool) openOrSet:(void*)someData 
{
    uint32* ptr = (uint32*) someData;
    uint32* data_ptr = ptr + 3;

    currentRecordLength = ExtractLength(*ptr);
    currentListenerId =  ptr[2] & 0xffff;
    size_t recordSize = (currentRecordLength - 3) * sizeof(uint32_t);

    if (currentListenerId >= kMaxFCIOStreams) {
        NSLogColor([NSColor redColor], @"ORFCIOConfigDecoder: listener_id %u exceeds lookup array size %d. This is a hardcoded limit and needs to be changed in ORFLashCamListenerDecoders.h", currentListenerId, kMaxFCIOStreams);
        return NO;
    }

    if (!fcioStreams[currentListenerId]) {
        NSString* peer = [NSString stringWithFormat:@"mem://%p/%zu", data_ptr, recordSize];
        fcioStreams[currentListenerId] = FCIOOpen([peer UTF8String], 0, 0);
        if (fcioStreams[currentListenerId]) {
            if (!processors[currentListenerId])
                processors[currentListenerId] = FSPCreate(0);
            return YES;
        }
        return NO;
    } else {
        return !FCIOSetMemField(FCIOStreamHandle(fcioStreams[currentListenerId]), data_ptr, recordSize);
    }
}

- (FCIOData*) fcioStream
{
    return fcioStreams[currentListenerId];
}
- (StreamProcessor*) processor
{
    return processors[currentListenerId];
}
- (bool) decodersInitialized
{
    return initialized[currentListenerId];
}
- (uint32_t) recordLength
{
    return currentRecordLength;
}

- (NSNumber*) getCrateForTrace:(int)trace_idx
{
    return [decoderOptions objectForKey:[NSString stringWithFormat:@"Listener %2d,Trace %4d,crate", currentListenerId, trace_idx]];
}

- (NSNumber*) getCardForTrace:(int)trace_idx
{
    return [decoderOptions objectForKey:[NSString stringWithFormat:@"Listener %2d,Trace %4d,card", currentListenerId, trace_idx]];
}

- (NSNumber*) getChannelForTrace:(int)trace_idx
{
    return [decoderOptions objectForKey:[NSString stringWithFormat:@"Listener %2d,Trace %4d,channel", currentListenerId, trace_idx]];
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    if (!someData)
        return 0;

    if (![self openOrSet:someData])
        return 0;

    //Only this decoder!
    [self broadcastToOthers:aDecoder];

    FCIOData* fcio = [self fcioStream];
    StreamProcessor* processor = [self processor];

    int tag;
    while ( (tag = FCIOGetRecord(fcio)) && tag != FCIOConfig && tag > 0) {
        if (tag == FCIOFSPConfig)
            FCIOGetFSPConfig(fcio, processor);
        if (tag == -TMIO_PROTOCOL_TAG) {
            FCIOClose(fcio);
            fcioStreams[currentListenerId] = NULL;
            [self openOrSet:someData];
        }
    }
    if (tag <= 0) {
        NSLogColor([NSColor redColor], @"ORFCIOConfigDecoder received malformed packet without FCIOConfig record.\n");
        return 0;
    }
    if (currentListenerId != fcio->config.streamid)
    [self setupOptionsfromHeader:[aDecoder fileHeader] forListener:currentListenerId andTracemap:fcio->config.tracemap withSize:fcio->config.adcs];

    return currentRecordLength;
}


- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{

    [self decodeData:dataPtr fromDecoder:nil intoDataSet:nil];
    FCIOData* fcio = [self fcioStream];
    if (!fcio)
        return @"ORFCIOConfigDecoder not initialized.\n";

    uint32_t readout  = (dataPtr[2] & 0xffff0000) >> 16;
    uint32_t listener =  dataPtr[2] & 0x0000ffff;

    NSString* readid   = [NSString stringWithFormat:@"Readout Object ID:    %u\n", readout];
    NSString* listenid = [NSString stringWithFormat:@"Listener Object ID:   %u\n", listener];
    NSString* evlist   = [NSString stringWithFormat:@"Stream ID:            %d\n", fcio->config.streamid];
    NSString* adcchan  = [NSString stringWithFormat:@"ADC  Channels:        %d\n", fcio->config.adcs];
    NSString* trigchan = [NSString stringWithFormat:@"Trig Channels:        %d\n", fcio->config.triggers];
    NSString* samples  = [NSString stringWithFormat:@"WF Samples:           %d\n", fcio->config.eventsamples];
    NSString* adcbits  = [NSString stringWithFormat:@"Bits/sample:          %d\n", fcio->config.adcbits];
    NSString* sumlen   = [NSString stringWithFormat:@"Integrator Length:    %d\n", fcio->config.sumlength];
    NSString* blprec   = [NSString stringWithFormat:@"Baseline Precision:   %d\n", fcio->config.blprecision];
    NSString* globals  = [NSString stringWithFormat:@"Global Trigger Cards: %d\n", fcio->config.mastercards];
    NSString* triggers = [NSString stringWithFormat:@"Trigger Cards:        %d\n", fcio->config.triggercards];
    NSString* adcs     = [NSString stringWithFormat:@"ADC Cards:            %d\n", fcio->config.adccards];
    NSString* gps      = [NSString stringWithFormat:@"GPS Mode:             %d\n", fcio->config.gps];

    NSMutableString* tracemap = [NSMutableString string];
    [tracemap appendString:@"Trace Map (addr:chan):\n"];
    for(unsigned int i=0; i<fcio->config.adcs; i++){
        uint32_t val = fcio->config.tracemap[i];
        if(val == 0) continue;
        uint32_t addr = (val & 0xffff0000) >> 16;
        uint32_t chan =  val & 0x0000ffff;
        [tracemap appendString:[NSString stringWithFormat:@"0x%x:%u,", addr, chan]];
    }

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@\n%@", readid, listenid,
            evlist, adcchan, trigchan, samples, adcbits, sumlen, blprec, globals, triggers, adcs, gps,
            [tracemap substringWithRange:NSMakeRange(0, [tracemap length]-1)]];
}

@end


@implementation ORFCIOEventDecoder

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    [self decodeData:dataPtr fromDecoder:nil intoDataSet:nil];
    FCIOData* fcio = [config fcioStream];
    if (!fcio)
        return @"ORFCIOConfig needs to be decoded first.\nPlease select this record.\n";

    NSString* title = @"FlashCam Event Record\n\n";
    NSString* type = [NSString stringWithFormat:@"Event type  = %u\n",  fcio->event.type];
    NSString* evtno = [NSString stringWithFormat:@"Event no    = %d\n",  fcio->event.timestamp[0]];
    NSString* num_traces = [NSString stringWithFormat:@"Num Channels    = %d\n",  fcio->event.num_traces];
    NSString* header = @"Raw waveform header:\n";
    for(int i=0; i<fcio->event.timeoffset_size; i++)
        header = [header stringByAppendingFormat:@"timeoffset[%d]: %d\n", i, fcio->event.timeoffset[i]];
    for(int i=0; i<fcio->event.deadregion_size; i++)
        header = [header stringByAppendingFormat:@"deadregion[%d]: %d\n", i, fcio->event.deadregion[i]];
    for(int i=0; i<fcio->event.timestamp_size; i++)
        header = [header stringByAppendingFormat:@"timestamp[%d]:  %d\n", i, fcio->event.timestamp[i]];
    for(int i=0; i<fcio->event.num_traces; i++)
        header = [header stringByAppendingFormat:@"baseline[%d]:  %u\n", i, fcio->event.theader[fcio->event.trace_list[i]][0]];
    for(int i=0; i<fcio->event.num_traces; i++)
        header = [header stringByAppendingFormat:@"energy[%d]:  %u\n", i, fcio->event.theader[fcio->event.trace_list[i]][1]];

    return [NSString stringWithFormat:@"%@%@%@%@%@", title, type, evtno, num_traces, header];
}

- (void) setConfig:(ORFCIOConfigDecoder *)another
{
    config = another;
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
{
    if (!someData)
        return 0;


    if (![config openOrSet:someData])
        return 0;

    FCIOData* fcio = [config fcioStream];
    StreamProcessor* processor = [config processor];

    int tag;
    while ( (tag = FCIOGetRecord(fcio)) && tag != FCIOEvent && tag != FCIOSparseEvent && tag > 0) {
        if (tag == FCIOFSPEvent)
            FCIOGetFSPEvent(fcio, processor);
    }
    if (tag <= 0) {
        NSLogColor([NSColor redColor], @"ORFCIOEventDecoder received malformed packet without FCIOConfig record.\n");
        return 0;
    }
    if (aDataSet) {
        uint32_t wfSamples = fcio->config.eventsamples;
        for (int i = 0; i < fcio->event.num_traces; i++) {
            int trace_idx = fcio->event.trace_list[i];
            unsigned int crate = [[config getCrateForTrace:trace_idx] unsignedIntValue];
            unsigned int card = [[config getCardForTrace:trace_idx] unsignedIntValue];
            unsigned int  channel = [[config getChannelForTrace:trace_idx] unsignedIntValue];

            NSString* crateKey = [self getCrateKey:crate];
            NSString* cardKey = [self getCardKey:card];
            NSString* channelKey = [self getChannelKey:channel];

            uint16_t fpga_baseline = fcio->event.theader[trace_idx][0];
            uint16_t fpga_integrator = fcio->event.theader[trace_idx][1];

            [aDataSet histogram:fpga_baseline numBins:0xffff sender:self
                       withKeys:@"FlashCamADC", @"Baseline", crateKey, cardKey, channelKey, nil];
            [aDataSet histogram:fpga_integrator numBins:0xffff sender:self
                       withKeys:@"FlashCamADC", @"Energy", crateKey, cardKey, channelKey, nil];

            // Event specific, not in Header
            // only decode the waveform if it has been 100 ms since the last decoded waveform and the plotting window is open
            BOOL fullDecode = NO;
            struct timeval tv;
            gettimeofday(&tv, NULL);
            uint64_t now = (uint64_t)(tv.tv_sec)*1000 + (uint64_t)(tv.tv_usec)/1000;
            if(!decoderOptions) decoderOptions = [[NSMutableDictionary dictionary] retain];
            NSString* lastTimeKey = [NSString stringWithFormat:@"%@,%@,%@,LastTime", crateKey, cardKey, channelKey];
            uint64_t lastTime = [[decoderOptions objectForKey:lastTimeKey] unsignedLongLongValue];
            if(now - lastTime >= 100){
                fullDecode = YES;
                [decoderOptions setObject:[NSNumber numberWithUnsignedLongLong:now] forKey:lastTimeKey];
            }
            BOOL someoneWatching = NO;
            if([aDataSet isSomeoneLooking:[NSString stringWithFormat:@"FlashCamADC,Waveforms,%d,%d,%d", crate , card, channel]]){
                someoneWatching = YES;
            }

            // decode the waveform if this is the first one or the above conditions are satisfied
            if(lastTime == 0 || (fullDecode && someoneWatching)){
                NSMutableData* tmpData = [NSMutableData dataWithCapacity:wfSamples*sizeof(unsigned short)];
                [tmpData setLength:wfSamples*sizeof(unsigned short)];
                memcpy((uint32_t*) [tmpData bytes], fcio->event.trace[trace_idx], wfSamples*sizeof(unsigned short));
                [aDataSet loadWaveform:tmpData offset:0 unitSize:2 sender:self
                              withKeys:@"FlashCamADC", @"Waveforms", crateKey, cardKey, channelKey, nil];
            }
        }
    }

    return [config recordLength];
}

@end


@implementation ORFCIOEventHeaderDecoder

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    [self decodeData:dataPtr fromDecoder:nil intoDataSet:nil];
    FCIOData* fcio = [config fcioStream];
    if (!fcio)
        return @"ORFCIOConfig needs to be decoded first.\nPlease select this record.\n";

    NSString* title = @"FlashCam Event Record\n\n";
    NSString* type = [NSString stringWithFormat:@"Event type  = %u\n",  fcio->event.type];
    NSString* evtno = [NSString stringWithFormat:@"Event no    = %d\n",  fcio->event.timestamp[0]];
    NSString* num_traces = [NSString stringWithFormat:@"Num Channels    = %d\n",  fcio->event.num_traces];
    NSString* header = @"Raw waveform header:\n";
    for(int i=0; i<fcio->event.timeoffset_size; i++)
        header = [header stringByAppendingFormat:@"timeoffset[%d]: %d\n", i, fcio->event.timeoffset[i]];
    for(int i=0; i<fcio->event.deadregion_size; i++)
        header = [header stringByAppendingFormat:@"deadregion[%d]: %d\n", i, fcio->event.deadregion[i]];
    for(int i=0; i<fcio->event.timestamp_size; i++)
        header = [header stringByAppendingFormat:@"timestamp[%d]:  %d\n", i, fcio->event.timestamp[i]];
    for(int i=0; i<fcio->event.num_traces; i++)
        header = [header stringByAppendingFormat:@"baseline[%d]:  %d\n", i, fcio->event.theader[i][0]];
    for(int i=0; i<fcio->event.num_traces; i++)
        header = [header stringByAppendingFormat:@"energy[%d]:  %d\n", i, fcio->event.theader[i][1]];

    return [NSString stringWithFormat:@"%@%@%@%@%@", title, type, evtno, num_traces, header];
}

- (void) setConfig:(ORFCIOConfigDecoder *)another
{
    config = another;
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
{
    if (!someData)
        return 0;


    if (![config openOrSet:someData])
        return 0;

    FCIOData* fcio = [config fcioStream];
    StreamProcessor* processor = [config processor];

    int tag;
    while ( (tag = FCIOGetRecord(fcio)) && tag != FCIOEventHeader && tag > 0) {
        if (tag == FCIOFSPEvent)
            FCIOGetFSPEvent(fcio, processor);
    }
    if (tag <= 0) {
        NSLogColor([NSColor redColor], @"ORFCIOEventHeaderDecoder received malformed packet without FCIOConfig record.\n");
        return 0;
    }

    if (aDataSet) {
        for (int i = 0; i < fcio->event.num_traces; i++) {
            int trace_idx = fcio->event.trace_list[i];
            NSString* crateKey = [self getCrateKey:[[config getCrateForTrace:trace_idx] unsignedIntValue]];
            NSString* cardKey = [self getCardKey:[[config getCardForTrace:trace_idx] unsignedIntValue]];
            NSString* channelKey = [self getChannelKey:[[config getChannelForTrace:trace_idx] unsignedIntValue]];

            uint16_t fpga_baseline = fcio->event.theader[trace_idx][0];
            uint16_t fpga_integrator = fcio->event.theader[trace_idx][1];

            [aDataSet histogram:fpga_baseline numBins:0xffff sender:self
                       withKeys:@"FlashCamADC", @"Baseline", crateKey, cardKey, channelKey, nil];
            [aDataSet histogram:fpga_integrator numBins:0xffff sender:self
                       withKeys:@"FlashCamADC", @"Energy", crateKey, cardKey, channelKey, nil];
        }
    }

    return [config recordLength];
}

@end


@implementation ORFCIOStatusDecoder

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    [self decodeData:dataPtr fromDecoder:nil intoDataSet:nil];
    FCIOData* fcio = [config fcioStream];
    if (!fcio)
        return @"ORFCIOConfig needs to be decoded first.\nPlease select this record.\n";

    uint32_t readout  = (dataPtr[2] & 0xffff0000) >> 16;
    uint32_t listener =  dataPtr[2] & 0x0000ffff;

    NSString* readid    = [NSString stringWithFormat:@"Readout Object ID:    %u\n", readout];
    NSString* listenid  = [NSString stringWithFormat:@"Listener Object ID:   %u\n", listener];
    NSString* status    = [NSString stringWithFormat:@"Status (1=no errors): %d\n", fcio->status.status];
    NSString* fcsec     = [NSString stringWithFormat:@"fc250 Seconds:        %d\n", fcio->status.statustime[0]];
    NSString* fcusec    = [NSString stringWithFormat:@"fc250 uSeconds:       %d\n", fcio->status.statustime[1]];
    NSString* cpusec    = [NSString stringWithFormat:@"CPU Seconds:          %d\n", fcio->status.statustime[2]];
    NSString* cpuusec   = [NSString stringWithFormat:@"CPU uSeconds:         %d\n", fcio->status.statustime[3]];
    NSString* startsec  = [NSString stringWithFormat:@"Start Seconds:        %d\n", fcio->status.statustime[5]];
    NSString* startusec = [NSString stringWithFormat:@"Start uSeconds:       %d\n", fcio->status.statustime[6]];
    NSString* cards     = [NSString stringWithFormat:@"Number of Cards:      %d\n", fcio->status.cards];
    NSString* dsize     = [NSString stringWithFormat:@"Size of Card Data:    %d\n", fcio->status.size];

    NSMutableString* cdata = [NSMutableString string];
    for(int i=0; i<fcio->status.cards; i++){
        [cdata appendString:[NSString stringWithFormat:@"Card Index %d:\n", i]];
        [cdata appendString:[NSString stringWithFormat:@"  id:             %u\n", fcio->status.data[i].reqid]];
        [cdata appendString:[NSString stringWithFormat:@"  status:         %u\n", fcio->status.data[i].status]];
        [cdata appendString:[NSString stringWithFormat:@"  event:          %u\n", fcio->status.data[i].eventno]];
        [cdata appendString:[NSString stringWithFormat:@"  pps:            %u\n", fcio->status.data[i].pps]];
        [cdata appendString:[NSString stringWithFormat:@"  ticks:          %u\n", fcio->status.data[i].ticks]];
        [cdata appendString:[NSString stringWithFormat:@"  maxticks:       %u\n", fcio->status.data[i].maxticks]];
        [cdata appendString:[NSString stringWithFormat:@"  tot  errors:    %u\n", fcio->status.data[i].totalerrors]];
        [cdata appendString:[NSString stringWithFormat:@"  env  errors:    %u\n", fcio->status.data[i].enverrors]];
        [cdata appendString:[NSString stringWithFormat:@"  cti  errors:    %u\n", fcio->status.data[i].ctierrors]];
        [cdata appendString:[NSString stringWithFormat:@"  link errors:    %u\n", fcio->status.data[i].linkerrors]];
        [cdata appendString:[NSString stringWithFormat:@"  temp0     (mC): %u\n", fcio->status.data[i].environment[0]]];
        [cdata appendString:[NSString stringWithFormat:@"  temp1     (mC): %u\n", fcio->status.data[i].environment[1]]];
        [cdata appendString:[NSString stringWithFormat:@"  temp2     (mC): %u\n", fcio->status.data[i].environment[2]]];
        [cdata appendString:[NSString stringWithFormat:@"  temp3     (mC): %u\n", fcio->status.data[i].environment[3]]];
        [cdata appendString:[NSString stringWithFormat:@"  temp4     (mC): %u\n", fcio->status.data[i].environment[4]]];
        [cdata appendString:[NSString stringWithFormat:@"  voltage0  (mV): %u\n", fcio->status.data[i].environment[5]]];
        [cdata appendString:[NSString stringWithFormat:@"  voltage1  (mV): %u\n", fcio->status.data[i].environment[6]]];
        [cdata appendString:[NSString stringWithFormat:@"  voltage2  (mV): %u\n", fcio->status.data[i].environment[7]]];
        [cdata appendString:[NSString stringWithFormat:@"  voltage3  (mV): %u\n", fcio->status.data[i].environment[8]]];
        [cdata appendString:[NSString stringWithFormat:@"  voltage4  (mV): %u\n", fcio->status.data[i].environment[9]]];
        [cdata appendString:[NSString stringWithFormat:@"  voltage5  (mV): %u\n", fcio->status.data[i].environment[10]]];
        [cdata appendString:[NSString stringWithFormat:@"  main I    (mA): %u\n", fcio->status.data[i].environment[11]]];
        [cdata appendString:[NSString stringWithFormat:@"  humidity      : %u\n", fcio->status.data[i].environment[12]]];
        [cdata appendString:[NSString stringWithFormat:@"  adc temp0 (mC): %u\n", fcio->status.data[i].environment[13]]];
        [cdata appendString:[NSString stringWithFormat:@"  adc temp1 (mC): %u\n", fcio->status.data[i].environment[14]]];
    }

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@", readid, listenid,
            status, fcsec, fcusec, cpusec, cpuusec, startsec, startusec, cards, dsize, cdata];
}

- (void) setConfig:(ORFCIOConfigDecoder *)another
{
    config = another;
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet;
{
    if (!someData)
        return 0;


    if (![config openOrSet:someData])
        return 0;

    FCIOData* fcio = [config fcioStream];
    StreamProcessor* processor = [config processor];

    int tag;
    while ( (tag = FCIOGetRecord(fcio)) && tag != FCIOStatus && tag > 0) {
        if (tag == FCIOFSPStatus)
            FCIOGetFSPStatus(fcio, processor);
    }
    if (tag <= 0) {
        NSLogColor([NSColor redColor], @"ORFCIOStatusDecoder received malformed packet without FCIOConfig record.\n");
        return 0;
    }

    return [config recordLength];
}

@end


@implementation ORFlashCamListenerConfigDecoder

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32* ptr = (uint32*) someData;
    NSString* readout  = [NSString stringWithFormat:@"%u", (ptr[1] & 0xffff0000) >> 16];
    NSString* listener = [NSString stringWithFormat:@"%u",  ptr[1] & 0x0000ffff];
    [aDataSet loadGenericData:@"Config" sender:self withKeys:@"FlashCamListener", @"Config", readout, listener, nil];
    return ExtractLength(*ptr);
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    uint32_t readout  = (dataPtr[1] & 0xffff0000) >> 16;
    uint32_t listener =  dataPtr[1] & 0x0000ffff;
    uint32_t offset = 2;

    NSString* readid   = [NSString stringWithFormat:@"Readout Object ID:    %u\n", readout];
    NSString* listenid = [NSString stringWithFormat:@"Listener Object ID:   %u\n", listener];
    NSString* evlist   = [NSString stringWithFormat:@"Event List ID:        %d\n", (int) dataPtr[offset++]];
    uint32_t nchan = dataPtr[offset];
    NSString* adcchan  = [NSString stringWithFormat:@"ADC  Channels:        %d\n", (int) dataPtr[offset++]];
    NSString* trigchan = [NSString stringWithFormat:@"Trig Channels:        %d\n", (int) dataPtr[offset++]];
    NSString* samples  = [NSString stringWithFormat:@"WF Samples:           %d\n", (int) dataPtr[offset++]];
    NSString* adcbits  = [NSString stringWithFormat:@"Bits/sample:          %d\n", (int) dataPtr[offset++]];
    NSString* sumlen   = [NSString stringWithFormat:@"Integrator Lnegth:    %d\n", (int) dataPtr[offset++]];
    NSString* blprec   = [NSString stringWithFormat:@"Baseline Precision:   %d\n", (int) dataPtr[offset++]];
    NSString* globals  = [NSString stringWithFormat:@"Global Trigger Cards: %d\n", (int) dataPtr[offset++]];
    NSString* triggers = [NSString stringWithFormat:@"Trigger Cards:        %d\n", (int) dataPtr[offset++]];
    uint32_t nadc = dataPtr[offset];
    NSString* adcs     = [NSString stringWithFormat:@"ADC Cards:            %d\n", (int) dataPtr[offset++]];
    NSString* gps      = [NSString stringWithFormat:@"GPS Mode:             %d\n", (int) dataPtr[offset++]];
    
    NSMutableString* tracemap = [NSMutableString string];
    [tracemap appendString:@"Trace Map (addr:chan):\n"];
    for(unsigned int i=0; i<nchan; i++){
        uint32_t val = dataPtr[offset+i];
        if(val == 0) continue;
        uint32_t addr = (val & 0xffff0000) >> 16;
        uint32_t chan =  val & 0x0000ffff;
        [tracemap appendString:[NSString stringWithFormat:@"0x%x:%u,", addr, chan]];
    }
    offset += nchan;
    
    NSMutableString* boardid = [NSMutableString string];
    [boardid appendString:@"ADC Main Board HW IDs:\n"];
    for(unsigned int i=0; i<nadc; i++){
        uint8_t boardRev = (uint8_t) ((dataPtr[offset+(i/4)] & (0xFF << (8*(i%4)))) >> (8*i%4));
        uint64_t hwID = (uint64_t)(dataPtr[offset+(uint32_t)ceil(nadc/4.0)+2*i]) << 32;
        hwID |= dataPtr[offset+(uint32_t)ceil(nadc/4.0)+2*i+1];
        [boardid appendString:[NSString stringWithFormat:@"%hhx-%llx,", boardRev, hwID]];
    }
    
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@\n%@", readid, listenid,
            evlist, adcchan, trigchan, samples, adcbits, sumlen, blprec, globals, triggers, adcs, gps,
            [tracemap substringWithRange:NSMakeRange(0, [tracemap length]-1)],
            [boardid substringWithRange:NSMakeRange(0, [boardid length]-1)]];
}

@end


@implementation ORFlashCamListenerStatusDecoder

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet{
    uint32_t* ptr = (uint32_t*) someData;
    NSString* readout  = [NSString stringWithFormat:@"%u", (ptr[1] & 0xffff0000) >> 16];
    NSString* listener = [NSString stringWithFormat:@"%u",  ptr[1] & 0x0000ffff];
    [aDataSet loadGenericData:@"Status" sender:self withKeys:@"FlashCamListener", @"Status", readout, listener, nil];
    return ExtractLength(*ptr);
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    uint32_t readout  = (dataPtr[1] & 0xffff0000) >> 16;
    uint32_t listener =  dataPtr[1] & 0x0000ffff;
    uint32_t offset = 2;
    
    NSString* readid    = [NSString stringWithFormat:@"Readout Object ID:    %u\n", readout];
    NSString* listenid  = [NSString stringWithFormat:@"Listener Object ID:   %u\n", listener];
    NSString* status    = [NSString stringWithFormat:@"Status (1=no errors): %d\n", (int) dataPtr[offset++]];
    NSString* fcsec     = [NSString stringWithFormat:@"fc250 Seconds:        %d\n", (int) dataPtr[offset++]];
    NSString* fcusec    = [NSString stringWithFormat:@"fc250 uSeconds:       %d\n", (int) dataPtr[offset++]];
    NSString* cpusec    = [NSString stringWithFormat:@"CPU Seconds:          %d\n", (int) dataPtr[offset++]];
    NSString* cpuusec   = [NSString stringWithFormat:@"CPU uSeconds:         %d\n", (int) dataPtr[offset++]];
    offset ++; // skip the dummy statustime
    NSString* startsec  = [NSString stringWithFormat:@"Start Seconds:        %d\n", (int) dataPtr[offset++]];
    NSString* startusec = [NSString stringWithFormat:@"Start uSeconds:       %d\n", (int) dataPtr[offset++]];
    offset = 13; // jump to the end of the statustime array
    int ncards = (int) dataPtr[offset];
    NSString* cards     = [NSString stringWithFormat:@"Number of Cards:      %d\n", (int) dataPtr[offset++]];
    NSString* dsize     = [NSString stringWithFormat:@"Size of Card Data:    %d\n", (int) dataPtr[offset++]];

    NSMutableString* cdata = [NSMutableString string];
    for(int i=0; i<ncards; i++){
        [cdata appendString:[NSString stringWithFormat:@"Card Index %d:\n", i]];
        [cdata appendString:[NSString stringWithFormat:@"  id:             %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  status:         %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  event:          %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  pps:            %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  ticks:          %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  maxticks:       %u\n", dataPtr[offset++]]];
        offset += 4; // skip numenv, numctilinks, numlinks, and dummy
        [cdata appendString:[NSString stringWithFormat:@"  tot  errors:    %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  env  errors:    %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  cti  errors:    %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  link errors:    %u\n", dataPtr[offset++]]];
        offset += 5; // skip othererrors
        [cdata appendString:[NSString stringWithFormat:@"  temp0     (mC): %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  temp1     (mC): %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  temp2     (mC): %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  temp3     (mC): %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  temp4     (mC): %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  voltage0  (mV): %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  voltage1  (mV): %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  voltage2  (mV): %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  voltage3  (mV): %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  voltage4  (mV): %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  voltage5  (mV): %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  main I    (mA): %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  humidity      : %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  adc temp0 (mC): %u\n", dataPtr[offset++]]];
        [cdata appendString:[NSString stringWithFormat:@"  adc temp1 (mC): %u\n", dataPtr[offset++]]];
    }
    
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@", readid, listenid,
            status, fcsec, fcusec, cpusec, cpuusec, startsec, startusec, cards, dsize, cdata];
}

@end
