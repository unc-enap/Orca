//
//  OREHQ8060nDecoders.m
//  Orca
//
//  Created by Mark Howe on Thurs Jan 6,2011
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

#import "OREHQ8060nDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "OREHQ8060nModel.h"

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

@implementation OREHQ8060nDecoderForHV

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    return  ExtractLength(ptr[0]);; //must return number of longs
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* theString =  @"EHQ8060n HV\n\n";               
	int crate	= ShiftAndExtract(ptr[1],20,0xF);
	int card	= ShiftAndExtract(ptr[1],16,0xF);
	theString = [theString stringByAppendingFormat:@"%@\n",[self getCrateKey:crate]];
	theString = [theString stringByAppendingFormat:@"%@\n",[self getCardKey:card]];

	NSCalendarDate* date = [NSCalendarDate dateWithTimeIntervalSince1970:(NSTimeInterval)ptr[4]];
	[date setCalendarFormat:@"%m/%d/%y %H:%M:%S"];
	theString = [theString stringByAppendingFormat:@"%@\n",date];
	union {
		float asFloat;
		unsigned long asLong;
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
