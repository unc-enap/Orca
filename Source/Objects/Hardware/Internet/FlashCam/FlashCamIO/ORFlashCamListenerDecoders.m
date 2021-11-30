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

    NSString* readid   = [NSString stringWithFormat:@"Readout Object ID:    %u\n", readout];
    NSString* listenid = [NSString stringWithFormat:@"Listener Object ID:   %u\n", listener];
    NSString* evlist   = [NSString stringWithFormat:@"Event List ID:        %d\n", (int) dataPtr[2]];
    NSString* adcchan  = [NSString stringWithFormat:@"ADC  Channels:        %d\n", (int) dataPtr[3]];
    NSString* trigchan = [NSString stringWithFormat:@"Trig Channels:        %d\n", (int) dataPtr[4]];
    NSString* samples  = [NSString stringWithFormat:@"WF Samples:           %d\n", (int) dataPtr[5]];
    NSString* adcbits  = [NSString stringWithFormat:@"Bits/sample:          %d\n", (int) dataPtr[6]];
    NSString* sumlen   = [NSString stringWithFormat:@"Integrator Lnegth:    %d\n", (int) dataPtr[7]];
    NSString* blprec   = [NSString stringWithFormat:@"Baseline Precision:   %d\n", (int) dataPtr[8]];
    NSString* globals  = [NSString stringWithFormat:@"Global Trigger Cards: %d\n", (int) dataPtr[9]];
    NSString* triggers = [NSString stringWithFormat:@"Trigger Cards:        %d\n", (int) dataPtr[10]];
    NSString* adcs     = [NSString stringWithFormat:@"ADC Cards:            %d\n", (int) dataPtr[11]];
    NSString* gps      = [NSString stringWithFormat:@"GPS Mode:             %d\n", (int) dataPtr[12]];
    
    NSMutableString* tracemap = [NSMutableString string];
    [tracemap appendString:@"Trace Map (addr:chan):\n"];
    for(unsigned int i=0; i<FCIOMaxChannels; i++){
        uint32_t val = dataPtr[13+i];
        if(val == 0) continue;
        uint32_t addr = (val & 0xffff0000) >> 16;
        uint32_t chan =  val & 0x0000ffff;
        [tracemap appendString:[NSString stringWithFormat:@"0x%x:%u,", addr, chan]];
    }
    
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@", readid, listenid,
            evlist, adcchan, trigchan, samples, adcbits, sumlen, blprec, globals, triggers, adcs, gps,
            [tracemap substringWithRange:NSMakeRange(0, [tracemap length]-1)]];
}

@end
