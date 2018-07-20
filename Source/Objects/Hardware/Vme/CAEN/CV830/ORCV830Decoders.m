//
//  ORCV830Decoders.m
//  Orca
//
//  Created by Mark Howe on 06/06/2012
// Copyright (c) 2012 University of North Carolina. All rights reserved.
//
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina,or U.S. Government make any warranty,
//express or implied,or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#import "ORCV830Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORCV830Model.h"
#import "ORDataTypeAssigner.h"

/* Event Record
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^----------------------- V830 ID (from header)
-----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length (variable)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------^-^^^--------------------------- Crate number
-------------^-^^^^--------------------- Card number
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx- Chan0 Roll over
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx- Enabled Mask
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  header
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter 0
..
..
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter 31 //note that only enabled channels are included so list may be shorter
*/


@implementation ORCV830DecoderForEvent

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr		= (uint32_t*)someData;
	uint32_t length	= ExtractLength(ptr[0]);
	int crate				= ShiftAndExtract(ptr[1],21,0xf);
	int card				= ShiftAndExtract(ptr[1],16,0x1f);
	uint32_t enabledMask	= ptr[3];
	NSString* crateKey   = [self getCrateKey: crate];
	NSString* cardKey    = [self getCardKey: card];
	
	
	int i;
	for(i=0;i<32;i++){
		if(enabledMask & (0x1L<<i)){
			NSString* valueString;
            if((i==0) && (enabledMask&0x1)){
                valueString = [NSString stringWithFormat:@"%u - %u",ptr[2],ptr[5+i]];
            }
            else {
                valueString = [NSString stringWithFormat:@"%u",ptr[5+i]];
            }
			NSString* channelKey = [self getChannelKey:i];

			[aDataSet loadGenericData:valueString sender:self withKeys:@"V830",  crateKey,cardKey,channelKey,nil];
			ptr++;
		}
	}
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"CV830 Scaler Record\n";
	uint32_t crateNum			= ShiftAndExtract(ptr[1],21,0xf);
	uint32_t cardNum			= ShiftAndExtract(ptr[1],16,0x1f);
	uint32_t enabledMask		= ptr[3];

    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",crateNum];
    NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",cardNum];
	NSString* s = [NSString stringWithFormat:@"%@%@%@\n",title,crate,card];
	s = [s stringByAppendingFormat:@"Enabled Mask:0x%08x\n",enabledMask];
		
	int i;
	for(i=0;i<32;i++){
		if(enabledMask & (0x1L<<i)){
            if((i==0) && (enabledMask&0x1)){
                s = [s stringByAppendingFormat:@"%d: 0x%x - 0x%x\n",i,ptr[2],ptr[5+i]];
            }
            else {
                s = [s stringByAppendingFormat:@"%d: 0x%08x",i,ptr[5+i]];
            }
		}
	}

    return s;               
}


@end

/* Polled Scalers Record
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- V830 ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length (always 20 longs)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 --------^-^^^--------------------------- Crate number
 -------------^-^^^^--------------------- Card number
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  enabled mask
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  UT time of last read
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter 0
 ..
 ..
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter 31
 */


@implementation ORCV830DecoderForPolledRead

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length	= ExtractLength(ptr[0]);
	int crateNum	= ShiftAndExtract(ptr[1],21,0xf);
	int cardNum		= ShiftAndExtract(ptr[1],16,0x1f);
	uint32_t enabledMask = ptr[2];
	NSString* crateKey = [self getCrateKey: crateNum];
	NSString* cardKey = [self getCardKey: cardNum];
	int i;
	for(i=0;i<kNumCV830Channels;i++){
		if(enabledMask & (0x1L<<i)){
			NSString* valueString = [NSString stringWithFormat:@"%u",ptr[5+i]];
			[aDataSet loadGenericData:valueString sender:self withKeys:@"V830Poll",  crateKey,cardKey,[self getChannelKey:i],nil];
		}
	}
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"CV830 Scaler Record\n\n";
	int crateNum	= ShiftAndExtract(ptr[1],21,0xf);
	int cardNum		= ShiftAndExtract(ptr[1],16,0x1f);
	uint32_t enabledMask = ptr[2];
    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",crateNum];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",(*ptr&0x001f0000)>>16];
    NSString* mask  = [NSString stringWithFormat:@"Mask  = 0x%x\n",cardNum];
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:ptr[3]];
	int i;
	NSString* s = [NSString stringWithFormat:@"%@%@%@%@%@\n",title,crate,card,mask,[date descriptionFromTemplate:@"MM/dd/yy HH:mm:ss z"]];
	for(i=0;i<kNumCV830Channels;i++){
		if(enabledMask & (0x1L<<i)){
			s = [s stringByAppendingFormat:@"%d:%u\n",i,ptr[5+i]];
		}
	}
	
    return s;               
}


@end


