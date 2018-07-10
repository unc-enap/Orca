//
//  ORLakeShore210Decoders.m
//  Orca
//
//  Created by Mark Howe on Fri Jan 20,2017.
//  Copyright (c) 2017 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina Physics and Department sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------


#import "ORLabJackU6Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORLabJackU6Model.h"

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
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter0 lo 32 bites
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter0 hi 32 bites
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter1 lo 32 bites
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counter1 hi 32 bites
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
static NSString* kLabJackU6Unit[kNumU6AdcChannels] = {
    //pre-make some keys for speed.
    @"Unit 0",  @"Unit 1",  @"Unit 2",   @"Unit 3",
    @"Unit 4",  @"Unit 5",  @"Unit 6",   @"Unit 7",
    @"Unit 8",  @"Unit 9",  @"Unit 10",  @"Unit 11",
    @"Unit 12", @"Unit 13"

};

@implementation ORLabJackU6DecoderForIOData

- (NSString*) getUnitKey:(unsigned short)aUnit
{
    if(aUnit<kNumU6AdcChannels) return kLabJackU6Unit[aUnit];
    else return [NSString stringWithFormat:@"Unit %d",aUnit];			
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	unsigned long *dataPtr = (unsigned long*)someData;
	union {
		float asFloat;
		unsigned long asLong;
	}theAdcValue;
	
	int i;
	int index = 2;
	unsigned long theTime = dataPtr[23];
	for(i=0;i<kNumU6AdcChannels;i++){
		theAdcValue.asLong = dataPtr[index];									//encoded as float, use union to convert
		[aDataSet loadTimeSeries:theAdcValue.asFloat										
						  atTime:theTime
						  sender:self 
						withKeys:@"LabJackU6",
								[self getUnitKey:dataPtr[1] & 0x0000ffff],
								[self getChannelKey:i],
								nil];
		index++;
	}
	
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(unsigned long*)dataPtr
{
    NSString* title= @"LabJackU6 DataRecord\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	union {
		float asFloat;
		unsigned long asLong;
	}theAdcValue;
	theString = [theString stringByAppendingFormat:@"HW ID = %lu\n",dataPtr[1] & 0x0000ffff];
	int i;
	int index = 2;
	for(i=0;i<kNumU6AdcChannels;i++){
		theAdcValue.asLong = dataPtr[index];
		theString = [theString stringByAppendingFormat:@"%d: %.3f\n",i,theAdcValue.asFloat];
		index++;
	}
    theString = [theString stringByAppendingFormat:@"Counter0 lo = 0x%08lx\n",dataPtr[index++]];
    theString = [theString stringByAppendingFormat:@"Counter0 hi = 0x%08lx\n",dataPtr[index++]];
    theString = [theString stringByAppendingFormat:@"Counter1 lo = 0x%08lx\n",dataPtr[index++]];
    theString = [theString stringByAppendingFormat:@"Counter1 hi = 0x%08lx\n",dataPtr[index++]];
	theString = [theString stringByAppendingFormat:@"I/O Dir = 0x%08lx\n",dataPtr[index++] & 0x000fffff];
	theString = [theString stringByAppendingFormat:@"I/O Out = 0x%08lx\n",dataPtr[index++] & 0x000fffff];
	theString = [theString stringByAppendingFormat:@"I/O In  = 0x%08lx\n",dataPtr[index++] & 0x000fffff];
	
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[index]];
	theString = [theString stringByAppendingFormat:@"%@\n",date];
	
	return theString;
}
@end


