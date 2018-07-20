//
//  ORSIS3316Decoders.m
//  Orca
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2015 CENPA. University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolinaponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#import "ORSIS3316Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORSIS3316Model.h"

/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 --------^-^^^--------------------------- Crate number
 -------------^-^^^^--------------------- Card number
 --------------------^^^^ ^^^^----------- Chan number
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Num Records in this record
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Num longs in each record
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Num of Records that were in the FIFO
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Num of longs in data header -- can get from the raw data also
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare

 N Data Records follow with format described in manual (NOTE THE FORMAT BITS)

  */

@implementation ORSIS3316WaveformDecoder
- (id) init

{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualSIS3316Cards release];
    [super dealloc];
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr       = (uint32_t*)someData;
	uint32_t length     = ExtractLength(ptr[0]);
    int crate                = (ptr[1]>>21) & 0xf;
    int card                 = (ptr[1]>>16) & 0x1f;
    int channel              = (ptr[1]>>8)  & 0xff;
	NSString* crateKey		 = [self getCrateKey:   crate];
    NSString* cardKey        = [self getCardKey:    card];
    NSString* channelKey     = [self getChannelKey: channel];
    
    uint32_t numRecords    = ptr[2];
    uint32_t dataHeaderLen = ptr[5];

    uint32_t orcaHeaderLen = 10;
    uint32_t* dataStartPtr = ptr + orcaHeaderLen;
    

    int i;
    for(i=0;i<numRecords;i++){
        uint32_t numLongs    = dataStartPtr[dataHeaderLen-1] & 0x3ffffff;
        uint32_t numSamples  = numLongs*2;
        uint32_t checkByte   = dataStartPtr[dataHeaderLen-1] >>28;
        if((checkByte == 0xE) && (numLongs <= length)){
            
            dataStartPtr+=dataHeaderLen;
            NSMutableData* tmpData = [NSMutableData dataWithBytes:dataStartPtr length:numSamples*sizeof(short)];
            if(tmpData){
                [aDataSet loadWaveform:tmpData
                                offset:0
                              unitSize:2 //unit size in bytes!
                                sender:self
                              withKeys:@"SIS3316", @"Waveforms",crateKey,cardKey,channelKey,nil];
            }
            dataStartPtr += numLongs;
        
            //get the actual object
            if(getRatesFromDecodeStage && !skipRateCounts){
                NSString* aKey = [crateKey stringByAppendingString:cardKey];
                if(!actualSIS3316Cards)actualSIS3316Cards = [[NSMutableDictionary alloc] init];
                ORSIS3316Model* obj = [actualSIS3316Cards objectForKey:aKey];
                if(!obj){
                    NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORSIS3316Model")];
                    NSEnumerator* e = [listOfCards objectEnumerator];
                    ORSIS3316Model* aCard;
                    while(aCard = [e nextObject]){
                        if([aCard slot] == card){
                            [actualSIS3316Cards setObject:aCard forKey:aKey];
                            obj = aCard;
                            break;
                        }
                    }
                }
                getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:channel];
            }
        }
        else {
            break;
        }
    }
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"SIS3316 Waveform Record\n\n";
    NSString* crate = [NSString stringWithFormat:@"Crate = %u\n",(ptr[1] >> 21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",(ptr[1] >> 16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Card  = %u\n",(ptr[1] >>  8) & 0xff];
    uint32_t numRecords        = ptr[2];
    uint32_t longsInOneRecord  = ptr[3];
    uint32_t numRecordsInFifo  = ptr[4];

    NSString* s = [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,chan];
    s = [s stringByAppendingFormat:@"Num Records in Packet: %d\n", numRecords];
    s = [s stringByAppendingFormat:@"Num Longs in Each: %d\n",     longsInOneRecord];
    s = [s stringByAppendingFormat:@"Num Records in FIFO: %d\n", numRecordsInFifo];
    return s;
}

@end


/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 --------^-^^^--------------------------- Crate number
 -------------^-^^^^--------------------- Card number
 --------------------^^^^ ^^^^----------- Chan number
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare

 N longs follow containing the histogram
 
 */

@implementation ORSIS3316HistogramDecoder
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr       = (uint32_t*)someData;
    uint32_t length     = ExtractLength(ptr[0]);
    int crate                = (ptr[1]>>21) & 0xf;
    int card                 = (ptr[1]>>16) & 0x1f;
    int channel              = (ptr[1]>>8)  & 0xff;
    NSString* crateKey       = [self getCrateKey:   crate];
    NSString* cardKey        = [self getCardKey:    card];
    NSString* channelKey     = [self getChannelKey: channel];
    uint32_t orcaHeaderLen = 10;
    uint32_t* dataStartPtr = ptr + orcaHeaderLen;
    uint32_t numLongs      = length - orcaHeaderLen;

    NSMutableData* tmpData = [NSMutableData dataWithBytes:dataStartPtr length:numLongs*sizeof(int32_t)];
    if(tmpData){
        [aDataSet loadSpectrum:tmpData
                        sender:self
                      withKeys:@"SIS3316",@"Histogram",crateKey,cardKey,channelKey,nil];

    }
    dataStartPtr += numLongs;

    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"SIS3316 Histogram Record\n\n";
    NSString* crate = [NSString stringWithFormat:@"Crate = %u\n",(ptr[1] >> 21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",(ptr[1] >> 16) & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Card  = %u\n",(ptr[1] >>  8) & 0xff];
    
    NSString* s = [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,chan];
    return s;
}

@end

/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 --------^-^^^--------------------------- Crate number
 -------------^-^^^^--------------------- Card number
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Spare

 N Data Records follow with format described in manual the statistic counter
 */

@implementation ORSIS3316StatisticsDecoder
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr       = (uint32_t*)someData;
    uint32_t length     = ExtractLength(ptr[0]);
    int crate                = (ptr[1]>>21) & 0xf;
    int card                 = (ptr[1]>>16) & 0x1f;
    NSString* crateKey       = [self getCrateKey:   crate];
    NSString* cardKey        = [self getCardKey:    card];
    [aDataSet loadGenericData:@"Read" sender:self withKeys:@"SIS3316", @"Statistics",crateKey,cardKey,nil];
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    uint32_t orcaHeaderLen = 10;
    NSString* title= @"SIS3316 Statistics Record\n\n";
    NSString* crate = [NSString stringWithFormat:@"Crate = %u\n",(ptr[1] >> 21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",(ptr[1] >> 16) & 0x1f];
    NSString* s = [NSString stringWithFormat:@"%@%@%@\n",title,crate,card];
    ptr += orcaHeaderLen;
    int i;
    for(i=0;i<16;i++){
        s = [s stringByAppendingFormat:@"Chan %d Counters\n",i];
        s = [s stringByAppendingFormat:@"All     : %u\n",*ptr++];
        s = [s stringByAppendingFormat:@"Events  : %u\n",*ptr++];
        s = [s stringByAppendingFormat:@"DeadTime: %u\n",*ptr++];
        s = [s stringByAppendingFormat:@"Pileup  : %u\n",*ptr++];
        s = [s stringByAppendingFormat:@"Veto    : %u\n",*ptr++];
        s = [s stringByAppendingFormat:@"HE      : %u\n",*ptr++];
        s = [s stringByAppendingString:@"------------------------\n"];
    }
    return s;
}

@end

