//
//  ORDT5725Decoder.h
//  Orca
//
//  Created by Mark Howe on Wed Jun 29,2016.
//  Copyright (c) 2016 University of North Carolina. All rights reserved.
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
#import "ORDT5725Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDT5725Model.h"

/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 1010 ---------------------------------- 
 -----^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ event size (in # of 32 bit longs)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ---------------^^^^-------------------- uniqueIdNumber (added in model.m)
 ....Followed by the event as described in the manual
 */

@implementation ORDT5725Decoder

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
    uint32_t index  = 0;
    uint32_t* ptr   = (uint32_t*)someData;
    uint32_t length = (ptr[0] & 0x0fffffff);
    index++; //1
    
    int unitNumber       = (ptr[1]>>16 & 0xf);
    NSString* unitKey    = [NSString stringWithFormat:@"Unit %2d",unitNumber];
    index += 2; //3

    uint32_t eventLength = length-2;
    while (eventLength > 4) { //make sure at least the CAEN header is there
        uint32_t channelMask = ptr[index] & 0xff;
        index += 3; //6 - start of data
        
        short numChans = 0;
        short chan[8];
        int i;
        for (i=0; i<8; i++) {
            if (channelMask & (1<<i)) {
                chan[numChans] = i;
                numChans++;
            }
        }
        
        //event may be empty if triggered by EXT trigger and no channel is selected
        if (numChans == 0) {
            break;
        }
        
        eventLength -= 4;
        uint32_t eventSize = eventLength/numChans;
        
        for (int j=0; j<numChans; j++) {
            int wordCount = 0;
            NSMutableData* tmpData = [[[NSMutableData alloc] initWithLength:2*eventSize*sizeof(unsigned short)] autorelease];
            unsigned short* dPtr = (unsigned short*)[tmpData bytes];
            for(int k=0; k<eventSize; k++){
                dPtr[wordCount++] =	 ptr[index] & 0x00003fff;
                dPtr[wordCount++] =	(ptr[index] & 0x3fff0000) >> 16;
                index++;
            }
            if(tmpData)[aDataSet loadWaveform:tmpData
                            offset:0 //bytes!
                          unitSize:2 //unit size in bytes!
                            sender:self
                          withKeys:@"DT5725", @"Waveforms",unitKey,[self getChannelKey: chan[j]],nil];
            
            if(getRatesFromDecodeStage){
                //Get serial number
                if(!actualCards)actualCards = [[NSMutableDictionary alloc] init];
                ORDT5725Model* obj = [actualCards objectForKey:unitKey];
                if(!obj){
                    NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORDT5725Model")];
                    NSEnumerator* e = [listOfCards objectEnumerator];
                    ORDT5725Model* aCard;
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
        eventLength -= eventSize*numChans;
    }
    
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    uint32_t length = (ptr[0] & 0x0fffffff);
    NSMutableString* dsc = [NSMutableString string];
    
    if(length > 6) { //make sure we have at least the CAEN header
        NSString* recordLen           = [NSString stringWithFormat:@"Event size = %u\n",           ptr[0] & 0x0fffffff];
        NSString* boardFail           = [NSString stringWithFormat:@"Board fail = %@\n",            (ptr[1]>>26)&0x1?@YES:@NO];
        NSString* softTrig            = [NSString stringWithFormat:@"Software Trigger = %@\n",      (ptr[1]>>18)&0x1?@YES:@NO];
        NSString* extTrig             = [NSString stringWithFormat:@"External Trigger = %@\n",      (ptr[1]>>17)&0x1?@YES:@NO];
        NSString* selfTrig            = [NSString stringWithFormat:@"Self Trigger = pair %u\n",    (ptr[1]>>8)&0xf];
        NSString* ETTT                = [NSString stringWithFormat:@"ETTT = %u\n",                 (ptr[1]>>8)&0xffff];
        NSString* sChannelMask        = [NSString stringWithFormat:@"Channel mask = 0x%02x\n",     ptr[1] & 0xff];
        NSString* eventCounter        = [NSString stringWithFormat:@"Event counter = 0x%06x\n",    ptr[2] & 0xffffff];
        NSString* timeTag             = [NSString stringWithFormat:@"Time tag = 0x%08x\n\n",       ptr[3]];
        
        [dsc appendFormat:@"%@%@%@%@%@%@%@%@%@", recordLen, boardFail, softTrig, extTrig, selfTrig, ETTT, sChannelMask, eventCounter, timeTag];
    }
    
    return dsc;
}

@end
