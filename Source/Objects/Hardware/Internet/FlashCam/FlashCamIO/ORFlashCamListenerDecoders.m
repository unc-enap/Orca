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

@implementation ORFCIODecoder

- (ORFCIODecoder*) init
{
    self = [super init];
    if (self != nil) {
        for (int i = 0; i < kMaxFCIOStreams; i++) {
            fcioStreams[i] = NULL;
            fspStates[i] = NULL;
            processors[i] = NULL;
        }
    }
    return self;
}


- (void) dealloc
{
    for (int i = 0; i < kMaxFCIOStreams; i++) {
        FCIOClose(fcioStreams[i]);
        FSPDestroy(processors[i]);
        free(fspStates[i]);
    }
    [fcCards release];
    [super dealloc];
}

- (void) addToObjectList:(NSMutableDictionary*)dict
{
    NSString* cname = [dict objectForKey:@"className"];
    if([cname isEqualToString:@""]) return;
    NSMutableArray* objs = [dict objectForKey:@"objects"];
    if(!objs){
        objs = [NSMutableArray array];
        [dict setObject:objs forKey:@"objects"];
    }
    [objs addObjectsFromArray:[[(ORAppDelegate*)[NSApp delegate] document]
                            collectObjectsOfClass:NSClassFromString(cname)]];
}

- (bool) allocOrUpdate:(void*)someData withSize:(size_t)size andListener:(uint32_t)listener_id
{
    if (listener_id >= kMaxFCIOStreams) {
        NSLogColor([NSColor redColor], @"ORFlashCamListenerDecoder: listener_id %u exceeds lookup array size %d. This is a hardcoded limit and needs to be changed in ORFLashCamListenerDecoders.h", listener_id, kMaxFCIOStreams);
        return NO;
    }

    if (!fcioStreams[listener_id]) {
        NSString* peer = [NSString stringWithFormat:@"mem://%p/%zu", someData, size];
        fcioStreams[listener_id] = FCIOOpen([peer UTF8String], 0, 0);
        if (fcioStreams[listener_id]) {
            fspStates[listener_id] = calloc(1, sizeof(FSPState));
            processors[listener_id] = FSPCreate(0);
            return YES;
        }
        return NO;
    } else {
        return !FCIOSetMemField(FCIOStreamHandle(fcioStreams[listener_id]), someData, size);
    }
}

- (int) readFCIOExtension:(FCIOData*) fcio listener:(uint32_t)listener_id
{
    uint8_t br_buffer[FCIOMaxChannels];
    uint64_t hwid_buffer[FCIOMaxChannels];
    uint8_t crate_number[FCIOMaxChannels];
    uint8_t crate_slot[FCIOMaxChannels];

    int br_buffer_size = FCIORead(FCIOStreamHandle(fcio), FCIOMaxChannels, br_buffer)/sizeof(*br_buffer);
    int hwid_buffer_size = FCIORead(FCIOStreamHandle(fcio), FCIOMaxChannels, hwid_buffer)/sizeof(*hwid_buffer);
    int crate_number_size = FCIORead(FCIOStreamHandle(fcio), FCIOMaxChannels, crate_number)/sizeof(*crate_number);
    int crate_slot_size = FCIORead(FCIOStreamHandle(fcio), FCIOMaxChannels, crate_slot)/sizeof(*crate_slot);

    if(!decoderOptions) decoderOptions = [[NSMutableDictionary dictionary] retain];

    for (int i = 0; i < fcio->config.adcs; i++) {
        uint16_t channel = fcio->config.tracemap[i] & 0xffff;

        [decoderOptions setObject:[NSNumber numberWithUnsignedInteger:crate_number[i]] forKey:[NSString stringWithFormat:@"Listener %2d,Trace %4d,crateKey",   listener_id, i]];
        [decoderOptions setObject:[NSNumber numberWithUnsignedInteger:crate_slot[i]]   forKey:[NSString stringWithFormat:@"Listener %2d,Trace %4d,cardKey",    listener_id, i]];
        [decoderOptions setObject:[NSNumber numberWithUnsignedInteger:channel]         forKey:[NSString stringWithFormat:@"Listener %2d,Trace %4d,channelKey", listener_id, i]];
    }

    return br_buffer_size + hwid_buffer_size + crate_number_size + crate_slot_size;
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    if (!someData)
        return 0;
    uint32* ptr = (uint32*) someData;
    uint32* data_ptr = ptr + 3;

    uint32_t recordLength = ExtractLength(*ptr);
    uint32_t listener_id =  ptr[2] & 0xffff;
    uint32_t recordSize = (recordLength - 3) * sizeof(uint32_t);

    if (![self allocOrUpdate:data_ptr withSize: recordSize andListener: listener_id]) {
        return NO;
    }

    FCIOData* fcio = fcioStreams[listener_id];

    int tag = FCIOGetRecord(fcio); // expect records defined in fcio.h, will be read automatically

    switch (tag) {
        case FCIOConfig:
            // read orca extension of record
            [self readFCIOExtension:fcio listener:listener_id];
            break;
        case FCIOSparseEvent:
        case FCIOEvent:
        case FCIOEventHeader: {
            if (aDataSet) {
                uint32_t wfSamples = fcio->config.eventsamples;
                for (int i = 0; i < fcio->event.num_traces; i++) {
                    int trace_idx = fcio->event.trace_list[i];
                    unsigned int crate = [[decoderOptions objectForKey:[NSString stringWithFormat:@"Listener %2d,Trace %4d,crateKey", listener_id, trace_idx]] unsignedIntValue];
                    unsigned int card = [[decoderOptions objectForKey:[NSString stringWithFormat:@"Listener %2d,Trace %4d,cardKey", listener_id, trace_idx]] unsignedIntValue];
                    unsigned int channel = [[decoderOptions objectForKey:[NSString stringWithFormat:@"Listener %2d,Trace %4d,channelKey", listener_id, trace_idx]] unsignedIntValue];

                    NSString* crateKey   = [self getCrateKey:crate];
                    NSString* cardKey    = [self getCardKey:card] ;
                    NSString* channelKey = [self getChannelKey:channel];

                    uint16_t fpga_baseline = fcio->event.theader[trace_idx][0];
                    uint16_t fpga_integrator = fcio->event.theader[trace_idx][1];

                    [aDataSet histogram:fpga_baseline numBins:0xffff sender:self
                               withKeys:@"FlashCamADC", @"Baseline", crateKey, cardKey, channelKey, nil];
                    [aDataSet histogram:fpga_integrator numBins:0xffff sender:self
                               withKeys:@"FlashCamADC", @"Energy", crateKey, cardKey, channelKey, nil];

                    // get the flashcam card to add to the baseline history
                    NSString* key = [crateKey stringByAppendingString:cardKey];
                    if(!fcCards) fcCards = [[NSMutableDictionary alloc] init];
                    id obj = [fcCards objectForKey:key];
                    if(!obj){
                        NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"ORFlashCamADCModel",
                                                                                                      @"className", nil];
                        [self performSelectorOnMainThread:@selector(addToObjectList:) withObject:dict waitUntilDone:YES];
                        [dict setObject:@"ORFlashCamADCStdModel" forKey:@"className"];
                        [self performSelectorOnMainThread:@selector(addToObjectList:) withObject:dict waitUntilDone:YES];
                        NSMutableArray* listOfCards = [dict objectForKey:@"objects"];
                        NSEnumerator* e = [listOfCards objectEnumerator];
                        id fccard;
                        while(fccard = [e nextObject]){
                            if([fccard slot] == card && [fccard crateNumber] == crate){
                                [fcCards setObject:fccard forKey:key];
                                obj = fccard;
                                break;
                            }
                        }
                    }
                    if(obj)
                        if(channel>=0 && channel<[obj numberOfChannels])
                            [[obj baselineHistory:channel] addDataToTimeAverage:(float)fpga_baseline];

                    if (tag == FCIOEventHeader)
                        continue;

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
                    if([aDataSet isSomeoneLooking:[NSString stringWithFormat:@"FlashCamADC,Waveforms,%d,%d,%d", crate, card, channel]]){
                        someoneWatching = YES;
                    }

                    // decode the waveform if this is the first one or the above conditions are satisfied
                    if(lastTime == 0 || (fullDecode && someoneWatching)){
                        NSMutableData* tmpData = [NSMutableData dataWithCapacity:wfSamples*sizeof(unsigned short)];
                        [tmpData setLength:wfSamples*sizeof(unsigned short)];
                        memcpy((uint32_t*) [tmpData bytes], fcio->event.trace[i], wfSamples*sizeof(unsigned short));
                        [aDataSet loadWaveform:tmpData offset:0 unitSize:2 sender:self
                                      withKeys:@"FlashCamADC", @"Waveforms", crateKey, cardKey, channelKey, nil];
                    }

                    
                }
            }
            break;
        }
        case FCIOStatus:
            break;
    }

    // read software trigger record
    FSPState* fspstate = fspStates[listener_id];
    StreamProcessor* processor = processors[listener_id];

    tag = FCIOGetRecord(fcio); // expect records defined in fsp.h. need to read the data explicitely.
    switch (tag) {
        case FCIOFSPConfig: {
            FCIOGetFSPConfig(fcio, processor);
            break;
        }
        case FCIOFSPEvent: {
            FCIOGetFSPEvent(fcio, fspstate);
            break;
        }
        case FCIOFSPStatus: {
            FCIOGetFSPStatus(fcio, processor);
            break;
        }
    }






    return recordLength;
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    [self decodeData:dataPtr fromDecoder:nil intoDataSet:nil];
    return NULL;
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
