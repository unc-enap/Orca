//
//  ORLabJackT7Decoders.m
//  Orca
//
//  Created by Mark Howe on Fri Jan 20,2017.
//  Updated by Jan Behrens on Dec 21, 2020.
//  Copyright (c) 2017-2020 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Physics and Department sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#import "ORLabJackT7Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORLabJackT7Model.h"

//------------------------------------------------------------------------------------------------
// Data Format (total length: 34 longs/qwords = 1088 bits)
//
// 0x0000: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
// 0x0020: ^^^^ ^^^^ ^^^^ ^^----------------------  data id
//                          ^^ ^^^^ ^^^^ ^^^^ ^^^^  length in longs (qwords)
//
// 0x0040: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//              ^^^^ ^^^^-------------------------  adc diff mask (8 bits)
//                        ^^^^ ^^^^ ^^^^ ^^^^ ^^^^  device id (20 bits)
// 0x0060: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 0 encoded as a float
// 0x0080: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 1 encoded as a float
// 0x00A0: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 2 encoded as a float
// 0x00C0: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 3 encoded as a float
// 0x00E0: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 4 encoded as a float
//
// 0x0100: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 5 encoded as a float
// 0x0120: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 6 encoded as a float
// 0x0140: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 7 encoded as a float
// 0x0160: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 8 encoded as a float
// 0x0180: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 9 encoded as a float
// 0x01A0: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 10 encoded as a float
// 0x01C0: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 11 encoded as a float
// 0x01E0: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 12 encoded as a float
//
// 0x0200: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 13 encoded as a float
// 0x0220: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 14 encoded as a float
// 0x0240: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 15 encoded as a float (internal)
// 0x0260: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 16 encoded as a float (internal)
// 0x0280: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter0 lo (32 bits)
// 0x02A0: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter0 hi (32 bits)
// 0x02C0: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter1 lo (32 bits)
// 0x02E0: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter1 hi (32 bits)
//
// 0x0300: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter2 lo (32 bits)
// 0x0320: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter2 hi (32 bits)
// 0x0340: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter3 lo (32 bits)
// 0x0360: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter3 hi (32 bits)
// 0x0380: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//                             ^^^^ ^^^^ ^^^^ ^^^^  DO direction bits (24 bits)
//                        ^^^^--------------------  IO direction bits (4 bits)
// 0x03A0: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//                             ^^^^ ^^^^ ^^^^ ^^^^  DO out bit values
//                        ^^^^--------------------  IO out bit values
// 0x03C0: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//                             ^^^^ ^^^^ ^^^^ ^^^^  DO in bit values
//                        ^^^^--------------------  IO in bit values
// 0x03E0: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  seconds since Jan 1, 1970
//
// 0x0400: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  internal RTC (seconds since Jan 1, 1970)
// 0x0420: xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  spare
//------------------------------------------------------------------------------------------------
static NSString* kLabJackT7Unit[kNumT7AdcChannels] = {
    //pre-make some keys for speed.
    @"Unit 0",  @"Unit 1",  @"Unit 2",  @"Unit 3",
    @"Unit 4",  @"Unit 5",  @"Unit 6",  @"Unit 7",
    @"Unit 8",  @"Unit 9",  @"Unit 10", @"Unit 11",
    @"Unit 12", @"Unit 13", @"Unit 14", @"Unit 15"

};

@implementation ORLabJackT7DecoderForIOData

- (NSString*) getUnitKey:(unsigned short)aUnit
{
    if(aUnit<kNumT7AdcChannels) return kLabJackT7Unit[aUnit];
    else return [NSString stringWithFormat:@"Unit %d",aUnit];
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t *dataPtr = (uint32_t*)someData;
    union {
        float asFloat;
        uint32_t asLong;
    }theAdcValue;

    int index = 2;  // skip first two dwords
    int i;

    uint32_t theTime = dataPtr[0x03E0];

    for(i=0;i<kNumT7AdcChannels;i++){
        theAdcValue.asLong = dataPtr[index];  // encoded as float, use union to convert
        [aDataSet loadTimeSeries:theAdcValue.asFloat
                          atTime:theTime
                          sender:self
                        withKeys:@"LabJackT7",
                                [self getUnitKey:dataPtr[1] & 0x0000ffff],
                                [self getChannelKey:i],
                                nil];
        index++;
    }

    // TODO: what about counters and digital I/O

    return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"LabJackT7 DataRecord\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];
    union {
        float asFloat;
        uint32_t asLong;
    }theAdcValue;

    theString = [theString stringByAppendingFormat:@"HW ID = %u\n",dataPtr[1] & 0x0000ffff];

    int index = 2;  // skip first two dwords
    int i;

    for(i=0;i<kNumT7AdcChannels;i++){
        theAdcValue.asLong = dataPtr[index++];
        theString = [theString stringByAppendingFormat:@"%d: %.3f\n",i,theAdcValue.asFloat];
    }

    theString = [theString stringByAppendingFormat:@"Counter0 lo = 0x%08x\n",dataPtr[index++]];
    theString = [theString stringByAppendingFormat:@"Counter0 hi = 0x%08x\n",dataPtr[index++]];
    theString = [theString stringByAppendingFormat:@"Counter1 lo = 0x%08x\n",dataPtr[index++]];
    theString = [theString stringByAppendingFormat:@"Counter1 hi = 0x%08x\n",dataPtr[index++]];
    theString = [theString stringByAppendingFormat:@"Counter2 lo = 0x%08x\n",dataPtr[index++]];
    theString = [theString stringByAppendingFormat:@"Counter2 hi = 0x%08x\n",dataPtr[index++]];
    theString = [theString stringByAppendingFormat:@"Counter3 lo = 0x%08x\n",dataPtr[index++]];
    theString = [theString stringByAppendingFormat:@"Counter3 hi = 0x%08x\n",dataPtr[index++]];
    theString = [theString stringByAppendingFormat:@"I/O Dir = 0x%08x\n",dataPtr[index++] & 0x000fffff];
    theString = [theString stringByAppendingFormat:@"I/O Out = 0x%08x\n",dataPtr[index++] & 0x000fffff];
    theString = [theString stringByAppendingFormat:@"I/O In  = 0x%08x\n",dataPtr[index++] & 0x000fffff];

    NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[0x03E0]];
    theString = [theString stringByAppendingFormat:@"%@\n",date];

    return theString;
}
@end
