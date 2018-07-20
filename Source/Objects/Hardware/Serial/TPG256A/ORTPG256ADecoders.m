//
//  ORTPG256ADecoders.m
//  Orca
//
//  Created by Mark Howe on Mon Apr 16 2012.
//  Copyright 2012  University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina at the Center for Experimental Nuclear Physics and 
//Astrophysics (CENPA) sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------


#import "ORTPG256ADecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

//------------------------------------------------------------------------------------------------
// Data Format
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
//
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//                          ^^^^ ^^^^ ^^^^- device id
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  pressure chan 0 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time pressure 0 taken in seconds since Jan 1, 1970
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  pressure chan 1 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time pressure 1 taken in seconds since Jan 1, 1970
//...
//...
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  pressure chan 5 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time pressure 5 taken in seconds since Jan 1, 1970
//-----------------------------------------------------------------------------------------------
static NSString* kTPG256AUnit[6] = {
    //pre-make some keys for speed.
    @"Gauge 0",  @"Gauge 1",@"Gauge 2",
    @"Gauge 3",  @"Gauge 4",@"Gauge 5",
};

@implementation ORTPG256ADecoderForPressure

- (NSString*) getGaugeKey:(unsigned short)aUnit
{
    if(aUnit<6) return kTPG256AUnit[aUnit];
    else return [NSString stringWithFormat:@"Gauge %d",aUnit];			
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t *dataPtr = (uint32_t*)someData;
	union {
		float asFloat;
		uint32_t asLong;
	}theTemp;
	int ident = dataPtr[1] & 0xfff;
	int i;
	int index = 2;
	for(i=0;i<6;i++){
		theTemp.asLong = dataPtr[index];									//encoded as float, use union to convert
		[aDataSet loadTimeSeries:theTemp.asFloat										
						  atTime:dataPtr[index+1]
						  sender:self 
						withKeys:@"TPG256A",
								[NSString stringWithFormat:@"Unit %d",ident],
								[self getGaugeKey:i],
								nil];
		index+=2;
	}
	
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"TPG 256A Controller\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	int ident = dataPtr[1] & 0xfff;
	theString = [theString stringByAppendingFormat:@"Unit %d\n",ident];
	union {
		float asFloat;
		uint32_t asLong;
	}theData;
	int i;
	int index = 2;
	for(i=0;i<6;i++){
		theData.asLong = dataPtr[index];
		
		NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[index+1]];
		
		theString = [theString stringByAppendingFormat:@"Gauge %d: %.2E %@\n",i,theData.asFloat,date];
		index+=2;
	}
	return theString;
}
@end


