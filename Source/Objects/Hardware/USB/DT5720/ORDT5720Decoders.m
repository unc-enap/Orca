//
//  ORDT5720Decoder.h
//  Orca
//
//  Created by Mark Howe on Wed Mar 12,2014.
//  Copyright (c) 2014 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina at the Center sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------
#import "ORDT5720Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDT5720Model.h"

/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 --------^-^^^--------------------------- Unit number
 --------------------------------------^- 0=Standard, 1=Pack2.5
 ....Followed by the event as described in the manual
 */

@implementation ORDT5720Decoder

- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
    [actualCards release];
    [super dealloc];
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr   = (uint32_t*)someData;
    uint32_t length = ExtractLength(ptr[0]);
    
    int unitNumber       = (ptr[1]>>16 & 0xf);
    BOOL packed          = (ptr[1]>>0  & 0x1);
    NSString* unitKey    = [NSString stringWithFormat:@"Unit %2d",unitNumber];
    
    uint32_t eventLength = length-2;
    uint32_t index = 2;
    while (eventLength > 4) { //make sure at least the CAEN header is there
        if (ptr[index] == 0 || ptr[index] >> 28 != 0xa) break; //trailing zeros or
        uint32_t eventSize = ptr[index] & 0x0fffffff;
        if (eventSize > eventLength) return length;
        index++;
        int  zeroSuppression      = (ptr[index]>>24  & 0x1);
        uint32_t channelMask = ptr[index] & 0xf;
        index += 3;
        
        short numChans = 0;
        short chan[4];
        int i;
        for(i=0;i<4;i++){
            if(channelMask & (1<<i)){
                chan[numChans] = i;
                numChans++;
            }
        }
        
        //event may be empty if triggered by EXT trigger and no channel is selected
        if (numChans == 0) {
            continue;
            //return length;
        }
        
        eventSize -= 4;
        eventSize = eventSize/numChans;
        
        int j;
        for(j=0;j<numChans;j++){
            
             int wordCount = 0;
            NSMutableData* tmpData = nil;
            if(!packed){
                if(zeroSuppression == 0){
                    tmpData= [[[NSMutableData alloc] initWithLength:2*eventSize*sizeof(unsigned short)] autorelease];
                    unsigned short* dPtr = (unsigned short*)[tmpData bytes];
                    //not packed, normal format
                    int k;
                    for(k=0;k<eventSize;k++){
                        dPtr[wordCount++] =	 ptr[index] & 0x00000fff;
                        dPtr[wordCount++] =	(ptr[index] & 0x0fff0000) >> 16;
                        index++;
                    }
                }
                else {
                    //not packed, but using zero length encoding
                    uint32_t size   = ptr[index];
                    tmpData= [[[NSMutableData alloc] initWithLength:2*size*sizeof(unsigned short)] autorelease];
                    unsigned short* dPtr = (unsigned short*)[tmpData bytes];
                    int controlWordCount = 0;
                    while(1){
                        index++; //point to control word
                        uint32_t controlWord = ptr[index];
                        BOOL good = (controlWord >> 31);
                        uint32_t numStoredSkippedWords = controlWord&0xfffff;
                        int k;

                        if(good || controlWordCount>62){
                            index++; //point to data
                            for(k=0;k<numStoredSkippedWords;k++){
                                dPtr[wordCount++] =	 ptr[index] & 0x00000fff;
                                if(wordCount>=2*size)break;

                                dPtr[wordCount++] =	(ptr[index] & 0x0fff0000) >> 16;
                                if(wordCount>=2*size)break;

                                index++;
                            }
                        }
                        else {
                            for(k=0;k<numStoredSkippedWords;k++){
                                dPtr[wordCount++] =	 0x0;
                                if(wordCount>=2*size)break;
                                dPtr[wordCount++] =	 0x0;
                                if(wordCount>=2*size)break;
                           }
                        }
                        controlWordCount++;
                        if(wordCount>=2*size)break;
                    }

                    
                }
            }
            else {
                if(zeroSuppression == 0){
                    tmpData= [[[NSMutableData alloc] initWithLength:2*eventSize*sizeof(unsigned short)] autorelease];
                    unsigned short* dPtr = (unsigned short*)[tmpData bytes];
                   //packed, no zero suppression
                    int k;
                    for(k=0;k<eventSize;k++){
                        uint32_t *d = &ptr[index];
                        
                        dPtr[wordCount++] = (d[0]     & 0xFC0) | (d[0] & 0x7F);
                        if(wordCount>=2*eventSize)break;

                        dPtr[wordCount++] = (d[0]>>12 & 0xFC0) | (d[0]>>12 & 0x7F);
                        if(wordCount>=2*eventSize)break;

                        dPtr[wordCount++] = (d[1]<<6  & 0xFC0) | (d[0]>>24 & 0x7f);
                        if(wordCount>=2*eventSize)break;

                        dPtr[wordCount++] = (d[1]>>6  & 0xFC0) | (d[1]>>6 & 0x7F);
                        if(wordCount>=2*eventSize)break;

                        dPtr[wordCount++] = (d[1]>>18 & 0xFC0) | (d[1]>>18 & 0x7F);
                        if(wordCount>=2*eventSize)break;

                        index+=2;
                    }
                }
                else {
                    uint32_t size = ptr[index];
                    tmpData= [[[NSMutableData alloc] initWithLength:2*size*sizeof(unsigned short)] autorelease];
                    unsigned short* dPtr = (unsigned short*)[tmpData bytes];
                    int controlWordCount = 0;
                    while(1){
                        index++; //point to control word
                        uint32_t controlWord = ptr[index];
                        BOOL good = (controlWord >> 31);
                        uint32_t numStoredSkippedWords = controlWord&0xfffff;
                        int k;

                        if(good || controlWordCount>62){
                            index++; //point to data
                            for(k=0;k<numStoredSkippedWords;k++){
                                uint32_t *d = &ptr[index];
                                
                                dPtr[wordCount++] = (d[0]     & 0xFC0) | (d[0] & 0x7F);
                                if(wordCount>=2*size)break;
                                
                                dPtr[wordCount++] = (d[0]>>12 & 0xFC0) | (d[0]>>12 & 0x7F);
                                if(wordCount>=2*size)break;
                                
                                dPtr[wordCount++] = (d[1]<<6  & 0xFC0) | (d[0]>>24 & 0x7f);
                                if(wordCount>=2*size)break;
                                
                                dPtr[wordCount++] = (d[1]>>6  & 0xFC0) | (d[1]>>6 & 0x7F);
                                if(wordCount>=2*size)break;
                                
                                dPtr[wordCount++] = (d[1]>>18 & 0xFC0) | (d[1]>>18 & 0x7F);
                                if(wordCount>=2*size)break;
                                
                                
                                index+=2;
                                if(wordCount>=2*size)break;
                            }
                        }
                        else {
                            for(k=0;k<numStoredSkippedWords;k++){
                                dPtr[wordCount++] =	 0x0;
                                if(wordCount>=2*size)break;
                                dPtr[wordCount++] =	 0x0;
                                if(wordCount>=2*size)break;
                           }
                        }
                        controlWordCount++;

                        if(wordCount>=2*size)break;
                    }
                    
                }
            }
            if(tmpData)[aDataSet loadWaveform:tmpData
                            offset:0 //bytes!
                          unitSize:2 //unit size in bytes!
                            sender:self
                          withKeys:@"DT5720", @"Waveforms",unitKey,[self getChannelKey: chan[j]],nil];
            
            if(getRatesFromDecodeStage){
                if(!actualCards)actualCards = [[NSMutableDictionary alloc] init];
                ORDT5720Model* obj = [actualCards objectForKey:unitKey];
                if(!obj){
                    NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORDT5720Model")];
                    NSEnumerator* e = [listOfCards objectEnumerator];
                    ORDT5720Model* aCard;
                    while(aCard = [e nextObject]){
                        if([aCard uniqueIdNumber] == unitNumber){
                            [actualCards setObject:aCard forKey:unitKey];
                            obj = aCard;
                            break;
                        }
                    }
                }
                getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:chan[j]];
            }
        }
        eventLength -= eventSize*numChans + 4;
    }
    
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    uint32_t length = ExtractLength(ptr[0]);
    NSMutableString* dsc = [NSMutableString string];
    
    if(length > 6) { //make sure we have at least the CAEN header
        NSString* recordLen           = [NSString stringWithFormat:@"Record len = %u\n",         length];
        NSString* eventSize           = [NSString stringWithFormat:@"Event size = %u\n",         ptr[2] & 0x0fffffff];
        NSString* packed              = [NSString stringWithFormat:@"Packed: %@\n",              (ptr[2] & 0x1)?@"YES":@"NO"];
        NSString* isZeroLengthEncoded = [NSString stringWithFormat:@"Zero length enc: %@\n",    ((ptr[3] >> 24) & 0x1)?@"YES":@"NO"];
        NSString* sChannelMask        = [NSString stringWithFormat:@"Channel mask = 0x%02x\n",   ptr[3] & 0xf];
        NSString* eventCounter        = [NSString stringWithFormat:@"Event counter = 0x%06x\n",  ptr[4] & 0xffffff];
        NSString* timeTag             = [NSString stringWithFormat:@"Time tag = 0x%08x\n\n",     ptr[5]];
        
        [dsc appendFormat:@"%@%@%@%@%@%@%@", recordLen,eventSize, packed, isZeroLengthEncoded, sChannelMask, eventCounter, timeTag];
    }
    
    return dsc;
}

@end
