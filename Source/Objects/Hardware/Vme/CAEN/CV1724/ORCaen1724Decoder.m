//
//ORCaen1724Decoder.m
//Orca
//
//Created by Mark Howe on Mon Mar 14, 2011.
//Copyright (c) 2011 University of North Carolina. All rights reserved.
//
//-------------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------
#import "ORCaen1724Decoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORCaen1724Model.h"
#import <time.h>

/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
-----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------^-^^^--------------------------- Crate number
-------------^-^^^^--------------------- Card number
--------------------------------------^- 1=Standard, 0=Pack2.5
....Followed by the event as described in the manual
*/

@implementation ORCaen1724WaveformDecoder

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
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);

	ptr++; //point to location
	int crate = (*ptr&0x01e00000)>>21;
	int card  = (*ptr& 0x001f0000)>>16;
	NSString* crateKey	= [self getCrateKey: crate ];
	NSString* cardKey	= [self getCardKey:  card];
	
	ptr++; //point to start of event
	uint32_t eventSize = *ptr & 0x0fffffff;
    if ( eventSize != length - 2 ) return length;
	ptr++; //point to 2nd word of event
	uint32_t channelMask = *ptr & 0x000000ff;
	//NSLog(@"Channel Mask: %d Len: %d Size: %d\n",channelMask,length,eventSize);
	ptr++; //point to 3rd word of event
	ptr++; //point to 4th word of event
	ptr++; //point to start of data
	
	short numChans = 0;
	short chan[8];
	int i;
	for(i=0;i<8;i++){
		if(channelMask & (1<<i)){
			chan[numChans] = i;
			numChans++;
		}
	}
	eventSize -= 4;
	eventSize = eventSize/numChans;
    int j;
    
    BOOL fullDecode = NO;
    if(numChans){
        time_t now;
        time(&now);
        if(now - lastTime >= 1){
            fullDecode = YES;
            lastTime = now;
        }
    }
    
	for(j=0;j<numChans;j++){
        if(fullDecode){
            NSMutableData* tmpData = [[[NSMutableData alloc] initWithLength:2*eventSize*sizeof(unsigned short)] autorelease];
            
            unsigned short* dPtr = (unsigned short*)[tmpData bytes];
            int k;
            int wordCount = 0;
            for(k=0;k<eventSize;k++){
                dPtr[wordCount++] =	0x00003fff & *ptr;		
                dPtr[wordCount++] =	(0x3fff0000 & *ptr) >> 16;		
                ptr++;
            }
            [aDataSet loadWaveform:tmpData 
                            offset:0 //bytes!
                          unitSize:2 //unit size in bytes!
                            sender:self  
                          withKeys:@"CAEN1724", @"Waveforms",crateKey,cardKey,[self getChannelKey: chan[j]],nil];
        }
        else {
            [aDataSet incrementCount:@"CAEN1724", @"Waveforms",crateKey,cardKey,[self getChannelKey: chan[j]],nil];
        }
        if(getRatesFromDecodeStage && !skipRateCounts){
			NSString* aKey = [crateKey stringByAppendingString:cardKey];
			if(!actualCards)actualCards = [[NSMutableDictionary alloc] init];
			ORCaen1724Model* obj = [actualCards objectForKey:aKey];
			if(!obj){
				NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORCaen1724Model")];
				NSEnumerator* e = [listOfCards objectEnumerator];
				ORCaen1724Model* aCard;
				while(aCard = [e nextObject]){
					if([aCard crateNumber] == crate && [aCard slot] == card){
						[actualCards setObject:aCard forKey:aKey];
						obj = aCard;
						break;
					}
				}
			}
			getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:chan[j]];
		}

	}
	
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	//uint32_t length = ExtractLength(*ptr);
	//a single trigger event expected
	
	ptr += 2;
	NSMutableString* dsc = [NSMutableString string];

	NSString* eventSize = [NSString stringWithFormat:@"Event size = %lu\n", *ptr & 0x0fffffffUL];
	NSString* isZeroLengthEncoded = [NSString stringWithFormat:@"Zero length enc: %@\n", ((*ptr >> 24) & 0x1UL)?@"On":@"Off"];
	NSString* lvioPattern = [NSString stringWithFormat:@"LVIO Pattern = 0x%04lx\n", (ptr[1] >> 8) & 0xffffUL];
	NSString* sChannelMask = [NSString stringWithFormat:@"Channel mask = 0x%02lx\n", ptr[1] & 0xffUL];
	NSString* eventCounter = [NSString stringWithFormat:@"Event counter = 0x%06lx\n", ptr[2] & 0xffffffUL];
	NSString* timeTag = [NSString stringWithFormat:@"Time tag = 0x%08x\n", ptr[3]];
	
	[dsc appendFormat:@"%@%@%@%@%@%@", eventSize, isZeroLengthEncoded, lvioPattern, sChannelMask, eventCounter, timeTag];
	return dsc;               
}

@end

