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
