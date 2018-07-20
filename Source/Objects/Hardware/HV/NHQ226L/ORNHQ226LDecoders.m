//
//  ORNHQ226LDecoders.m
//  Orca
//
//  Created by Mark Howe on Tues Sept 14,2010.
//  Copyright (c) 2010 University of North Carolina. All rights reserved.
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

#import "ORNHQ226LDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"

//------------------------------------------------------------------------------------------------
// Data Format
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
//
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//                          ^^^^ ^^^^ ^^^^- device id
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time in seconds since Jan 1, 1970
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  StatusWord1 for channel 0
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  StatusWord2 for channel 0
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Voltage chan 0 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Current chan 0 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  StatusWord1 for channel 1
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  StatusWord2 for channel 1
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Voltage chan 1 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Current chan 1 encoded as a float
//-----------------------------------------------------------------------------------------------

@implementation ORNHQ226LDecoderForHVStatus

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t value = *((uint32_t*)someData);
    return ExtractLength(value);	
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* theString =  @"NHQ226L HV Controller\n\n";               
	int ident = dataPtr[1] & 0xfff;
	theString = [theString stringByAppendingFormat:@"Unit %d\n",ident];
	
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[2]];
    theString = [theString stringByAppendingFormat:@"%@\n",date];
	union {
		float asFloat;
		uint32_t asLong;
	}theData;
	
	theString = [theString stringByAppendingFormat:@"--------------------------\n"];
	theString = [theString stringByAppendingFormat:@"Channel 0\n"];
	theString = [theString stringByAppendingFormat:@"Status Words 0x%02x  0x%02x\n",dataPtr[3],dataPtr[4]];
	theData.asLong = dataPtr[5]; //act Voltage 0
	theString = [theString stringByAppendingFormat:@"Act Voltage: %.1f\n",theData.asFloat];
	theData.asLong = dataPtr[6]; //act Current 0
	theString = [theString stringByAppendingFormat:@"Act Current: %.1f\n",theData.asFloat];
	
	theString = [theString stringByAppendingFormat:@"--------------------------\n"];
	theString = [theString stringByAppendingFormat:@"Channel 1\n"];
	theString = [theString stringByAppendingFormat:@"Status Words 0x%02x 0x%02x\n",dataPtr[7],dataPtr[8]];
	theData.asLong = dataPtr[9]; //act Voltage 1
	theString = [theString stringByAppendingFormat:@"Act Voltage: %.1f\n",theData.asFloat];
	theData.asLong = dataPtr[10]; //act Current 1
	theString = [theString stringByAppendingFormat:@"Act Current: %.1f\n",theData.asFloat];
	
	return theString;
	
}

@end

