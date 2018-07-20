//
//  ORLakeShore210Decoders.m
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


#import "ORLakeShore210Decoders.h"
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
//                   ^--------------------- 1=(Kelvin), 0= (Celsius)
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  temperature chan 0 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time temp 0 taken in seconds since Jan 1, 1970
// ... chans 1 - 7 follow
//------------------------------------------------------------------------------------------------
static NSString* kLakeShoreUnit[8] = {
    //pre-make some keys for speed.
    @"Unit 0",  @"Unit 1",  @"Unit 2",  @"Unit 3",
    @"Unit 4",  @"Unit 5",  @"Unit 6",  @"Unit 7"

};
static NSString* kLakeShoreTempUnit[3] = {
    //pre-make some keys for speed.
    @"Celsius",  @"Kelvin", @"Raw"
};

@implementation ORLakeShore210DecoderForTemperature

- (NSString*) getUnitKey:(unsigned short)aUnit
{
    if(aUnit<8) return kLakeShoreUnit[aUnit];
    else return [NSString stringWithFormat:@"Unit %d",aUnit];			
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t *dataPtr = (uint32_t*)someData;
	union {
		float asFloat;
		uint32_t asLong;
	}theTemp;
	
	int i;
	int index = 2;
	for(i=0;i<8;i++){
		theTemp.asLong = dataPtr[index];									//encoded as float, use union to convert
		[aDataSet loadTimeSeries:theTemp.asFloat										
						  atTime:dataPtr[index+1]
						  sender:self 
						withKeys:@"LakeShore218",
								[self getUnitKey:dataPtr[1] & 0x0000ffff],
								kLakeShoreTempUnit[((dataPtr[1]>>16) & 0x3)],		//Celsius,Kelvin,Raw
								[self getChannelKey:i],
								nil];
		index+=2;
	}
	
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"Lake Shore 218 TempRecord\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	union {
		float asFloat;
		uint32_t asLong;
	}theData;
	theString = [theString stringByAppendingFormat:@"HW ID = %u\n",dataPtr[1] & 0x0000ffff];
	theString = [theString stringByAppendingFormat:@"Units = %@\n",kLakeShoreTempUnit[((dataPtr[1]>>16) & 0x3)]];
	int i;
	int index = 2;
	for(i=0;i<8;i++){
		theData.asLong = dataPtr[index];
		
		NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[index+1]];
		
		theString = [theString stringByAppendingFormat:@"%d: %.2f %@\n",i,theData.asFloat,date];
		index+=2;
	}
	return theString;
}
@end


