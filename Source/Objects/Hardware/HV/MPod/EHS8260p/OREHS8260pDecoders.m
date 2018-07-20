//
//  OREHS8260pDecoders.m
//  Orca
//
//  Created by Mark Howe on Tues Feb 1,2011
//  Copyright (c) 2011 University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina Department of Physics and Astrophysics 
//sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "OREHS8260pDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "OREHS8260pModel.h"

/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
-----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
----------^^^^-------------------------- Crate number
---------------^^^^--------------------- Card number
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -Spare
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -Spare
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time in seconds since Jan 1, 1970
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Voltage encoded as a float (chan 0)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Current encoded as a float (chan 0)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Voltage encoded as a float (chan 1)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Current encoded as a float (chan 1)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Voltage encoded as a float (chan 2)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Current encoded as a float (chan 2)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Voltage encoded as a float (chan 3)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Current encoded as a float (chan 3)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Voltage encoded as a float (chan 4)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Current encoded as a float (chan 4)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Voltage encoded as a float (chan 5)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Current encoded as a float (chan 5)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Voltage encoded as a float (chan 6)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Current encoded as a float (chan 6)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Voltage encoded as a float (chan 7)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Current encoded as a float (chan 7)
*/

@implementation OREHS8260pDecoderForHV

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
    return  ExtractLength(ptr[0]);; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* theString =  @"EHS8260p HV\n\n";               
	int crate	= ShiftAndExtract(ptr[1],20,0xF);
	int card	= ShiftAndExtract(ptr[1],16,0xF);
	theString = [theString stringByAppendingFormat:@"%@\n",[self getCrateKey:crate]];
	theString = [theString stringByAppendingFormat:@"%@\n",[self getCardKey:card]];

	NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)ptr[4]];
	theString = [theString stringByAppendingFormat:@"%@\n",[date stdDescription]];
	union {
		float asFloat;
		uint32_t asLong;
	}theData;
	theString = [theString stringByAppendingFormat:@"--------------------------\n"];
	int theChan;
	for(theChan=0;theChan<8;theChan++){
		theString = [theString stringByAppendingFormat:@"Channel %d\n",theChan];
		theData.asLong = ptr[5+theChan]; //act Voltage
		theString = [theString stringByAppendingFormat:@"Act Voltage (%d): %.2f V\n",theChan,theData.asFloat];
		theData.asLong = ptr[6+theChan]; //act Current
		theString = [theString stringByAppendingFormat:@"Act Current (%d): %.3f mA\n",theChan,theData.asFloat*1000.];
	}
	return theString;
}

@end
