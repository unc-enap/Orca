//
//  ORPxi6289Decoders.m
//  Orca
//
//  Created by Mark Howe on Thurs Aug 26 2010
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
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

#import "ORPxi6289Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORPxi6289Model.h"

/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
-----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------^-^^^--------------------------- Crate number
-------------^-^^^^--------------------- Card number
				    ^^^^ ^^^^------------Channel
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------------------^^^^ ^^^^ ^^^^ ^^^^- Data Length
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------------------^^^^ ^^^^ ^^^^ ^^^^- Raw data point0
^^^^ ^^^^ ^^^^ ^^^^--------------------- Raw data point1
Raw data points continue until the Data length is used up....
*/

@implementation ORPxi6289DecoderForWaveform

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(ptr[0]);
	int crate	= ShiftAndExtract(ptr[1],21,0xf);
	int card	= ShiftAndExtract(ptr[1],16,0x1f);
	int channel = ShiftAndExtract(ptr[1],8,0xff);

	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	NSString* channelKey	= [self getChannelKey: channel];
	
	int dataLength = ptr[2] & 0x0000ffff; //datalength in longs
		
    NSMutableData* tmpData = [NSMutableData dataWithCapacity:dataLength*sizeof(int32_t)]; 	   
	[tmpData setLength:dataLength*sizeof(int32_t)];
	unsigned short* dPtr = (unsigned short*)[tmpData bytes];
	int i;
	int wordCount = 0;
	for(i=0;i<dataLength;i++){
		dPtr[wordCount++] =	 0x0000ffff & ptr[3 + i];		
		dPtr[wordCount++] =	(0xffff0000 & ptr[3 + i]) >> 16;		
		ptr++;
	}
	
    [aDataSet loadWaveform:tmpData 
					offset:0 //bytes!
				  unitSize:2 //unit size in bytes!
					sender:self  
				  withKeys:@"Pxi6289", @"Waveforms",crateKey,cardKey,channelKey,nil];

    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	
    NSString* title= @"Pxi6289 Waveform Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate = %u\n",ShiftAndExtract(ptr[1],21,0xf)];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",ShiftAndExtract(ptr[1],16,0x1f)];
    NSString* chan  = [NSString stringWithFormat:@"Chan  = %u\n",ShiftAndExtract(ptr[1],8,0xff)];
	
    return [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,chan];               
}

@end
