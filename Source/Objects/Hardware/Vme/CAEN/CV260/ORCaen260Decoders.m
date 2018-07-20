//
//  ORCaen260Decoders.m
//  Orca
//
//  Created by Mark Howe on 12/7/07
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//Washington at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#import "ORCaen260Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORCaen260Model.h"
#import "ORDataTypeAssigner.h"

/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^----------------------- V260 ID (from header)
-----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length (always 20 longs)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------^-^^^--------------------------- Crate number
-------------^-^^^^--------------------- Card number
--------------------^^^^ ^^^^ ^^^^ ^^^^- enabled mask
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  UT time of last read
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter 0
..
..
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter 15
*/


@implementation ORCaen260DecoderForScaler

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
	ptr++; //point to the location word
	unsigned char crate   = (*ptr&0x01e00000)>>21;
	unsigned char card   = (*ptr& 0x001f0000)>>16;
	//unsigned char mask   = (*ptr& 0x0000ffff);
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getCardKey: card];
	ptr++;	//point to the time
	ptr++;	//first data word
	int i;
	for(i=0;i<kNumCaen260Channels;i++){
		NSString* valueString = [NSString stringWithFormat:@"%u",*ptr];
		NSString* channelKey = [self getChannelKey:i];

		[aDataSet loadGenericData:valueString sender:self withKeys:@"Scalers",@"V260",  crateKey,cardKey,channelKey,nil];
		ptr++;
	}
    return 19; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"Caen260 Scaler Record\n\n";
	ptr++; //point to location
    NSString* crate = [NSString stringWithFormat:@"Crate = %u\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",(*ptr&0x001f0000)>>16];
    NSString* mask  = [NSString stringWithFormat:@"Mask  = 0x%x\n",(*ptr)&0xffff];
	ptr++; //point to time
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:*ptr];
	ptr++; //first data word	
	int i;
	NSString* s = [NSString stringWithFormat:@"%@%@%@%@%@",title,crate,card,mask,[date descriptionFromTemplate:@"MM/dd/yy H:mm:ss z\n"]];
	for(i=0;i<kNumCaen260Channels;i++){
		s = [s stringByAppendingFormat:@"%d:%u\n",i,*ptr];
		ptr++;
	}
	
    return s;               
}


@end

