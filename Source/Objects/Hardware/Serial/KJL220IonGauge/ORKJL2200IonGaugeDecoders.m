//
//  ORKJL2200IonGaugeDecoders.m
//  Orca
//
// Created by Mark  A. Howe on Thurs Apr 22 2010
// Copyright (c) 2010 University of North Caroline. All rights reserved.
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


#import "ORKJL2200IonGaugeDecoders.h"
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
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  Pressure encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time Pressure taken in seconds since Jan 1, 1970
//------------------------------------------------------------------------------------------------
static NSString* kKJL2200Unit[8] = {
    //pre-make some keys for speed.
    @"Unit 0",  @"Unit 1",  @"Unit 2",  @"Unit 3",
    @"Unit 4",  @"Unit 5",  @"Unit 6",  @"Unit 7"

};


@implementation ORKJL2200IonGaugeDecoderForPressure

- (NSString*) getUnitKey:(unsigned short)aUnit
{
    if(aUnit<8) return kKJL2200Unit[aUnit];
    else return [NSString stringWithFormat:@"Unit %d",aUnit];			
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t *dataPtr = (uint32_t*)someData;
	union {
		float asFloat;
		uint32_t asLong;
	}thePressure;
	
	thePressure.asLong = dataPtr[2];									//encoded as float, use union to convert
	[aDataSet loadTimeSeries:thePressure.asFloat										
					  atTime:dataPtr[3]
					  sender:self 
					withKeys:@"KJL2200IonGaugePressure",
							[self getUnitKey:dataPtr[1] & 0x0000ffff],
							@"Pressure",
							nil];
	
	
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"Keithley 6487 Pressure\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	union {
		float asFloat;
		uint32_t asLong;
	}theData;
	theString = [theString stringByAppendingFormat:@"HW ID = %u\n",dataPtr[1] & 0x0000ffff];
	
	theData.asLong = dataPtr[2];
	
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[3]];	
	theString = [theString stringByAppendingFormat:@"%.2f %@\n",theData.asFloat,date];
	
	return theString;
}
@end


