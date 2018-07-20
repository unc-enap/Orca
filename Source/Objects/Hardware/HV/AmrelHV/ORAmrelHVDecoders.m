//
//  ORAmrelHVDecoders.m
//  Orca
//
//  Created by Mark Howe on 8/27/09.
//  Copyright 2009 CENPA, University of North Carolina. All rights reserved.
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

#import "ORAmrelHVDecoders.h"
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
//    ^------------------------------------ channel
//                   ^--------------------- power (1==ON)
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time in seconds since Jan 1, 1970
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Voltage encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Voltage encoded as a float
//-----------------------------------------------------------------------------------------------

@implementation ORAmrelHVDecoderForHVStatus

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t value = *((uint32_t*)someData);
    return ExtractLength(value);	
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* theString =  @"AmrelHV HV Controller\n\n";               
	int ident = dataPtr[1] & 0xfff;
	theString = [theString stringByAppendingFormat:@"Unit %d\n",ident];
	int theChan  = (dataPtr[1] >> 28) & 0x1;
	int thePower  = (dataPtr[1] >> 16) & 0x1;
	
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[2]];
	theString = [theString stringByAppendingFormat:@"%@\n",[date stdDescription]];
	union {
		float asFloat;
		uint32_t asLong;
	}theData;
	
	theString = [theString stringByAppendingFormat:@"--------------------------\n"];
	theString = [theString stringByAppendingFormat:@"Channel %d\n",theChan];
	theString = [theString stringByAppendingFormat:@"Power is %@\n",thePower?@"ON":@"OFF"];
	theData.asLong = dataPtr[3]; //act Voltage
	theString = [theString stringByAppendingFormat:@"Act Voltage: %.2f\n",theData.asFloat];
	theData.asLong = dataPtr[4]; //act Current
	theString = [theString stringByAppendingFormat:@"Act Current: %.3f\n",theData.asFloat];
		
	return theString;
	
}

@end

