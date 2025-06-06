//
//  MJDPreAmp.m
//  Orca
//
//  Created by Mark Howe on Thurs April 12, 2012.
//  Copyright © 2012 University of North Carolina. All rights reserved.
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

#import "ORMJDPreAmpModel.h"
#import "ORMJDPreAmpDecoders.h"
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
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  unix time of measurement
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  enabled adc mask
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 0 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 1 encoded as a float
// ....
// ....
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 15 encoded as a float
//-----------------------------------------------------------------------------------------------
static NSString* kMJDPreAmpUnit[21] = {
    //pre-make some keys for speed.
    @"PreAmp 0",  @"PreAmp 1", @"PreAmp 2", @"PreAmp 3", @"PreAmp 4", @"PreAmp 5",
    @"PreAmp 6",  @"PreAmp 7", @"PreAmp 8", @"PreAmp 9", @"PreAmp 10", @"PreAmp 11",
    @"PreAmp 12",  @"PreAmp 13", @"PreAmp 15", @"PreAmp 16", @"PreAmp 17", @"PreAmp 18",
    @"PreAmp 19",  @"PreAmp 20", 
};

@implementation ORMJDPreAmpDecoderForAdc

- (NSString*) getPreAmpKey:(unsigned short)aUnit
{
    if(aUnit<21) return kMJDPreAmpUnit[aUnit];
    else return [NSString stringWithFormat:@"PreAmp %d",aUnit];			
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t *dataPtr = (uint32_t*)someData;
	union {
		float asFloat;
		uint32_t asLong;
	}theValue;
	int ident = dataPtr[1] & 0xfff;
	int i;
	int index = 4;
	for(i=0;i<kMJDPreAmpAdcChannels;i++){
		uint32_t theTime;
		theTime = dataPtr[2];
		theValue.asLong = dataPtr[index]; //encoded as float, use union to convert
		
		[aDataSet loadTimeSeries:theValue.asFloat										
						  atTime:theTime
						  sender:self 
						withKeys:@"MJDPreAmp",
								[self getPreAmpKey:ident],
								nil];
		index++;
	}
	
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"MJD PreAmp\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	int ident = dataPtr[1] & 0xfff;
	theString = [theString stringByAppendingFormat:@"%@\n",[self getPreAmpKey:ident]];
	union {
		float asFloat;
		uint32_t asLong;
	}theData;
		
	NSDate* date1 = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[2]];
    theString = [theString stringByAppendingFormat:@"TimeStamp: %@\n",[date1 stdDescription]];

	uint32_t enabledMask = dataPtr[3];
	int index = 4;
	int i;
	for(i=0;i<kMJDPreAmpAdcChannels;i++){
		if(enabledMask & (0x1<<i)){
			theData.asLong = dataPtr[index];
			theString = [theString stringByAppendingFormat:@"%d: %.3f\n",i,theData.asFloat];
		}
		index++;
	}
	return theString;
}
@end


