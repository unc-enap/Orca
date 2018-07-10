//
//  ORCaenDataDecoders.m
//  Orca
//
//  Created by Mark Howe on Tues June 1 2010.
//  Copyright © 2010 University of North Carolina. All rights reserved.
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

#import "ORCaen775Decoders.h"
#import "ORDataSet.h"

@implementation ORCAEN775DecoderForTdc
- (unsigned long) decodeData:(void*) aSomeData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*) aDataSet
{
    short i;
    long* ptr = (long*) aSomeData;
	long length = ExtractLength(ptr[0]);
	NSString* crateKey = [self getCrateKey:ShiftAndExtract(ptr[1],21,0x0000000f)];
	NSString* cardKey  = [self getCardKey: ShiftAndExtract(ptr[1],16,0x0000001f)];
    for( i = 2; i < length; i++ ){
		int dataType = ShiftAndExtract(ptr[i],24,0x7);
		if(dataType == 0x0){
			int tdcValue = ShiftAndExtract(ptr[i],0,0xfff);
			int chan     = [self channel:ptr[i]];
			NSString* channelKey  = [self getChannelKey: chan];
			[aDataSet histogram:tdcValue numBins:0xfff sender:self withKeys:@"CAEN775 TDC",crateKey,cardKey,channelKey,nil];
        }
    }
    return length;
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	long length = ExtractLength(ptr[0]);
    NSString* title= @"CAEN775 TDC Record\n\n";
	
    NSString* len	=[NSString stringWithFormat: @"# TDC = %lu\n",length-2];
    NSString* crate = [NSString stringWithFormat:@"Crate = %lu\n",(ptr[1] >> 21)&0x0000000f];
    NSString* card  = [NSString stringWithFormat:@"Card  = %lu\n",(ptr[1] >> 16)&0x0000001f];    
	
    NSString* restOfString = [NSString string];
    int i;
    for( i = 2; i < length; i++ ){
		int dataType = ShiftAndExtract(ptr[i],24,0x7);
		if(dataType == 0x0){
			int tdcValue = ShiftAndExtract(ptr[i],0,0xfff);
			int channel  = [self channel:ptr[i]];
			restOfString = [restOfString stringByAppendingFormat:@"Chan  = %d  Value = %d\n",channel,tdcValue];
        }
    }
	
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,len,crate,card,restOfString];               
}

- (unsigned short) channel: (unsigned long) pDataValue
{
    return	ShiftAndExtract(pDataValue,16,0x1F);
}
- (NSString*) identifier
{
    return @"CAEN 775";
}

@end

@implementation ORCAEN775NDecoderForTdc

- (unsigned short) channel: (unsigned long) pDataValue
{
    return	ShiftAndExtract(pDataValue,17,0xF);
}

@end

