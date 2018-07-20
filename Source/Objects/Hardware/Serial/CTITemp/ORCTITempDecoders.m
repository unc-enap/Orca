//
//  ORCTITempDecoders.m
//  Orca
//
//  Created by Mark Howe on 08/1/05.
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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

#import "ORCTITempDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

//------------------------------------------------------------------------------------------------
// Data Format
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
//
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//                     ^^^^ ^^^^ ^^^^ ^^^^- device id
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  temperature  encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time temp taken in seconds since Jan 1, 1970
//------------------------------------------------------------------------------------------------
static NSString* kCTITempUnit[8] = {
    //pre-make some keys for speed.
    @"Unit 0",@"Unit 1",@"Unit 2",@"Unit 3",@"Unit 4",@"Unit 5",@"Unit 6",@"Unit 7"
};

@implementation ORCTITempDecoderForTemperature

- (NSString*) getUnitKey:(unsigned short)aUnit
{
    if(aUnit<8) return kCTITempUnit[aUnit];
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
						withKeys:@"CTI Temp",
								[self getUnitKey:dataPtr[1] & 0x0000ffff],
								nil];
	
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"CTI TempRecord\n\n";
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


