//
//  ORCaen1190Decoders.m
//  Orca
//
//  Created by Mark Howe on 05/29/08
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
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


#import "ORCaen1190Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORCaen1190Model.h"
#import "ORDataTypeAssigner.h"

//-------------------------------------------------------------------------------
//data format
//0000 0000 0000 0000 0000 0000 0000 0000
//^^^^ ^^^^ ^^^^ ^^---------------------- device type
//		           ^^ ^^^^ ^^^^ ^^^^ ^^^^ length of record including this header
//0000 0000 0000 0000 0000 0000 0000 0000
//^^^^ ^--------------------------------- spare
//      ^^------------------------------- spare
//        ^ ^^^-------------------------- crate
//             ^ ^^^^-------------------- card
// n bytes of raw data follow.
// each word following can be decoded by looking at the top 5 bits
//0100 0000 0000 0000 0000 0000 0000 0000 Global Header
//^^^^ ^--------------------------------- event count id
//      ^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^----- event count
//                                   ^^^^ GEO
//0000 1000 0000 0000 0000 0000 0000 0000 TDC Header
//^^^^ ^--------------------------------- TDC Header id
//       ^^------------------------------ TDC
//			^^^^ ^^^^ ^^^^--------------- event id
//			               ^^^^ ^^^^ ^^^^ bunch id
//0000 0000 0000 0000 0000 0000 0000 0000 TDC Measurement
//^^^^ ^--------------------------------- TDC measurement id
//      ^-------------------------------- 1: Trailing 0: Leading
//       ^^ ^^^^ ^----------------------- channel
//			      ^^^ ^^^^ ^^^^ ^^^^ ^^^^ measurement (see below for more)
//0001 1000 0000 0000 0000 0000 0000 0000 TDC Trailer
//^^^^ ^--------------------------------- TDC Trailer id
//       ^^------------------------------ TDC
//			^^^^ ^^^^ ^^^^--------------- event id
//			               ^^^^ ^^^^ ^^^^ word count
//0010 0000 0000 0000 0000 0000 0000 0000 TDC Error
//^^^^ ^--------------------------------- TDC Error id
//       ^^------------------------------ TDC
//			           ^^^ ^^^^ ^^^^ ^^^^ word count
//1000 1000 0000 0000 0000 0000 0000 0000 Extended trigger time
//^^^^ ^--------------------------------- Extended trigger time id
//       ^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ Extended trigger time tag
//1000 0000 0000 0000 0000 0000 0000 0000 Trailer
//^^^^ ^--------------------------------- Trailer id
//       ^------------------------------- Trigger Lost (0=OK,no trigger; 1=at least 1 event lost)
//        ^------------------------------ Buffer Overflow (0=OK,no overflow; 1=overflow, possible data loss)
//         ^----------------------------- TDC Error (0=OK,no error; 1=at least one TDC chip in error)
//
// it is also possible to get 'filler' words:
//1100 0000 0000 0000 0000 0000 0000 0000 Filler
//^^^^ ^--------------------------------- Filler id
//
//
//
//Additional info on measurement words
//Leading Measurement (single edge):
//000 0000 0000 0000 0000 
//^^^ ^^^^ ^^^^ ^^^^ ^^^^ Leading time
//Leading Measurement (Pair measurement):
//000 0000 0000 0000 0000 
//^^^ ^^^^--------------- width 
//         ^^^^ ^^^^ ^^^^ Leading time
//Trailing Measurement:
//000 0000 0000 0000 0000 
//^^^ ^^^^ ^^^^ ^^^^ ^^^^ Trailing time
//-------------------------------------------------------------------------------


@implementation ORCaen1190DecoderForTdc

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr   = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
	
    ptr++; //point to the location info
	unsigned char crate			= (*ptr&0x01e00000)>>21;
	unsigned char card			= (*ptr& 0x001f0000)>>16;
	unsigned char edgeDection	= (*ptr& 0x06000000)>>25; 
	int i;
	for(i=0;i<length-2;i++) {
		if(((ptr[i]>>27) & 0x1f) == 0) {
			short chan = (ptr[i]>>19) & 0x7f;
			BOOL  type = (ptr[i]>>26) & 0x1;

			unsigned long tdcValue;
			tdcValue = ptr[i] & 0x7ffff;
			if(edgeDection == 0 && type == 0)tdcValue = tdcValue & 0xfff;
			tdcValue = tdcValue>>4; //prescale to 32K
			[aDataSet histogram:tdcValue numBins:0x7fff sender:self  
								withKeys:	@"Caen1190", 
											[self getCrateKey:   crate],
											[self getCardKey:    card],
											[self getChannelKey: chan],
											nil];
		}
	}
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Caen1190 TDC Record\n\n";
	ptr++;
    NSString* crate = [NSString stringWithFormat:@"Crate = %lu\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %lu\n",(*ptr&0x001f0000)>>16];
	    
    return [NSString stringWithFormat:@"%@%@%@",title,crate,card];               
}


@end

