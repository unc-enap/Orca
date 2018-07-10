//
//  ORCaen265Decoders.m
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


#import "ORCaen265Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORCaen265Model.h"
#import "ORDataTypeAssigner.h"

/*
Short Form:
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^--------------------------------- V265 ID (from header)
--------^-^^^--------------------------- Crate number
-------------^-^^^^--------------------- Card number
--------------------^^^----------------- Channel number
-----------------------^---------------- Range Type (0==12 bit, 1==15bit)
-------------------------^^^^ ^^^^ ^^^^- adc value

Long Form:
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^----------------------- V265 ID (from header)
-----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length (always 2 longs)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------^-^^^--------------------------- Crate number
-------------^-^^^^--------------------- Card number
--------------------^^^----------------- Channel number
-----------------------^---------------- Range Type (0==12 bit, 1==15bit)
-------------------------^^^^ ^^^^ ^^^^- adc value
*/


@implementation ORCaen265DecoderForAdc

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long length;
    unsigned long* ptr = (unsigned long*)someData;
	if(IsLongForm(*ptr)) {
        ptr++;
        length = 2;
    } else {
        length = 1;
    }
	unsigned char crate   = (*ptr&0x01e00000)>>21;
	unsigned char card   = (*ptr& 0x001f0000)>>16;
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getCardKey: card];
	short chan = (*ptr >> 13) & 0x7;
    if ((((*ptr) >> 12) & 0x1) == 0) { //ignore 15 bit dynamic range
        [aDataSet histogram:*ptr&0x00000fff numBins:4096 sender:self  withKeys:@"Caen265", crateKey,cardKey,[self getChannelKey: chan],nil];
    }
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Caen265 ADC Record\n\n";
	if(IsLongForm(*ptr))ptr++;
    NSString* crate = [NSString stringWithFormat:@"Crate = %lu\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %lu\n",(*ptr&0x001f0000)>>16];
    NSString* chan  = [NSString stringWithFormat:@"Chan  = %lu\n",(*ptr>>13)&0x7];
	NSString* type  = [NSString stringWithFormat:@"Range = %@\n",*ptr&0x00001000?@"12 Bit":@"15 Bit"];
	NSString* data  = [NSString stringWithFormat:@"Value = 0x%lx\n",*ptr&0x00000fff];
	    
    return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,crate,card,chan,type,data];               
}


@end

