//
//  ORDefender3000Decoders.m
//  Orca
//
//  Created by Mark Howe on 05/14/2024.
//  Copyright 2024 CENPA, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
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

#import "ORDefender3000Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

//-----------------------------------------------------------------------------------
// Data Format
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//                     ^^^^ ^^^^ ^^^^ ^^^^- device id
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  weight  encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time weight taken in seconds since Jan 1, 1970
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  format data
//                                     ^^^-- 1:g,2:kg,3:lb,4:oz,5:lb:oz
//                                ^^^------- 0:unknown,1:Dynamic
//-------------------------------------------------------------------------------------
static NSString* kDefender3000Unit[8] = {
    //pre-make some keys for speed.
    @"Unit 0",@"Unit 1",@"Unit 2",@"Unit 3",@"Unit 4",@"Unit 5",@"Unit 6",@"Unit 7"
};

@implementation ORDefender3000DecoderForWeight

- (NSString*) getUnitKey:(unsigned short)aUnit
{
    if(aUnit<8) return kDefender3000Unit[aUnit];
    else return [NSString stringWithFormat:@"Unit %d",aUnit];			
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t *dataPtr = (uint32_t*)someData;
	union {
		float asFloat;
		uint32_t asLong;
	}theTemp;
	
	int index = 2;
	theTemp.asLong = dataPtr[index];									//encoded as float, use union to convert
	[aDataSet loadTimeSeries:theTemp.asFloat										
						  atTime:dataPtr[index+1]
						  sender:self 
						withKeys:@"Defender",
								[self getUnitKey:dataPtr[1] & 0x0000ffff],
								nil];
	
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"Defender Weight Record\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];
	union {
		float asFloat;
		uint32_t asLong;
	}theData;
	theString = [theString stringByAppendingFormat:@"HW ID = %u\n",dataPtr[1] & 0x0000ffff];
	int index = 2;
	theData.asLong = dataPtr[index];
	
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[index+1]];	
	theString = [theString stringByAppendingFormat:@"%.2f %@\n",theData.asFloat,[date stdDescription]];
	
	return theString;
}
@end


