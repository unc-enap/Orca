//
//  ORiTrasGasSensorDecoder.m
//  Orca
//
//  Created by Mark Howe on Mon Jan 25, 2009.
//  Copyright 2009 University of North Carolina. All rights reserved.
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


#import "ORiTransGasSensorDecoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

//------------------------------------------------------------------------------------------------
// Data Format
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//                          ^^^^ ^^^^ ^^^^- device id
//      ^^^^ ^^^^ ^^^^--------------------- channel
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time value taken in seconds since Jan 1, 1970
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  gas reading (encoded as float)
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  statusBits (see manual)
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  gasType
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  spare
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  spare
//-----------------------------------------------------------------------------------------------

@implementation ORiTrasGasSensorDecoderForValue

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t* dataPtr = (uint32_t*)someData;
	int ident = ShiftAndExtract(dataPtr[1],0,0xfff);
	int channel = ShiftAndExtract(dataPtr[1],16,0xfff);
	union {
		float asFloat;
		uint32_t asLong;
	}theData;
	theData.asLong = dataPtr[3];
	
	[aDataSet loadTimeSeries:theData.asFloat										
						  atTime:dataPtr[2]
						  sender:self 
						withKeys:@"ITrans",
								[NSString stringWithFormat:@"Unit %d",ident],
								[self getChannelKey:channel],
								nil];
	
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"iTrans Gas Sensor\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	int ident   = ShiftAndExtract(dataPtr[1],0,0xfff);
	int channel = ShiftAndExtract(dataPtr[1],16,0xfff);
	theString   = [theString stringByAppendingFormat:@"Unit %d Chan %d\n",ident,channel];
			
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[2]];
	
	union {
		float asFloat;
		uint32_t asLong;
	}theData;
	theData.asLong = dataPtr[3];
	theString = [theString stringByAppendingFormat:@"Gas Reading %d: %.2E %@\n",channel,theData.asFloat,[date stdDescription]];
	
	return theString;
}
@end


