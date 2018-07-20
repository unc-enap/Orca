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


#import "ORLabJackDecoders.h"
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
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 0 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 1 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 2 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 3 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 4 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 5 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 6 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 7 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  
// --------------------^^^^ ^^^^ ^^^^ ^^^^  DO Direction Bits
// ---------------^^^^--------------------  IO Direction Bits
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  
// --------------------^^^^ ^^^^ ^^^^ ^^^^  DO Out Bit Values
// ---------------^^^^--------------------  IO Out Bit Values
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  
// --------------------^^^^ ^^^^ ^^^^ ^^^^  DO In Bit Values
// ---------------^^^^--------------------  IO In Bit Values
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  seconds since Jan 1, 1970
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  spare
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  spare
//------------------------------------------------------------------------------------------------
static NSString* kLabJackUnit[8] = {
    //pre-make some keys for speed.
    @"Unit 0",  @"Unit 1",  @"Unit 2",  @"Unit 3",
    @"Unit 4",  @"Unit 5",  @"Unit 6",  @"Unit 7"

};

@implementation ORLabJackDecoderForIOData

- (NSString*) getUnitKey:(unsigned short)aUnit
{
    if(aUnit<8) return kLabJackUnit[aUnit];
    else return [NSString stringWithFormat:@"Unit %d",aUnit];			
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t *dataPtr = (uint32_t*)someData;
	union {
		float asFloat;
		uint32_t asLong;
	}theAdcValue;
	
	int i;
	int index = 2;
	uint32_t theTime = dataPtr[14];
	for(i=0;i<8;i++){
		theAdcValue.asLong = dataPtr[index];									//encoded as float, use union to convert
		[aDataSet loadTimeSeries:theAdcValue.asFloat										
						  atTime:theTime
						  sender:self 
						withKeys:@"LabJack",
								[self getUnitKey:dataPtr[1] & 0x0000ffff],
								[self getChannelKey:i],
								nil];
		index++;
	}
	
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"LabJack DataRecord\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	union {
		float asFloat;
		uint32_t asLong;
	}theAdcValue;
	theString = [theString stringByAppendingFormat:@"HW ID = %u\n",dataPtr[1] & 0x0000ffff];
	int i;
	int index = 2;
	for(i=0;i<8;i++){
		theAdcValue.asLong = dataPtr[index];
		theString = [theString stringByAppendingFormat:@"%d: %.3f\n",i,theAdcValue.asFloat];
		index++;
	}
	theString = [theString stringByAppendingFormat:@"Counter = 0x%08x\n",dataPtr[index++]];
	theString = [theString stringByAppendingFormat:@"I/O Dir = 0x%08x\n",dataPtr[index++] & 0x000fffff];
	theString = [theString stringByAppendingFormat:@"I/O Out = 0x%08x\n",dataPtr[index++] & 0x000fffff];
	theString = [theString stringByAppendingFormat:@"I/O In  = 0x%08x\n",dataPtr[index++] & 0x000fffff];
	
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[index]];
	theString = [theString stringByAppendingFormat:@"%@\n",date];
	
	return theString;
}
@end


