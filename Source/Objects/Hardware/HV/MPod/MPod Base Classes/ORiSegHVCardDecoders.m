//
//  ORiSegHVCardDecoders.m
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

#import "ORiSegHVCardDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"

/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
-----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
----------^^^^-------------------------- Crate number
---------------^^^^--------------------- Card number
----------------------------^ ^^^^------ number of channels
--------------------------------------^- Polarity (1 == pos, 0 == neg)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -ON Mask
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -Spare
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time in seconds since Jan 1, 1970
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Voltage encoded as a float (chan 0)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Current encoded as a float (chan 0)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Voltage encoded as a float (chan 1)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  actual Current encoded as a float (chan 1)
..
..
Followed by the rest of the channel values
 */

@implementation ORiSegHVCardDecoderForHV

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
    return  ExtractLength(ptr[0]);; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* theString =  @"iSegHVCard HV\n\n";               
	int crate	= ShiftAndExtract(ptr[1],20,0xF);
	int card	= ShiftAndExtract(ptr[1],16,0xF);
	int polarity= ptr[1] & 0x1;
	int numChannels = ShiftAndExtract(ptr[1],4,0x1F);
	
    uint32_t onMask = ptr[2];

	theString = [theString stringByAppendingFormat:@"%@\n",[self getCrateKey:crate]];
	theString = [theString stringByAppendingFormat:@"%@\n",[self getCardKey:card]];

	NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)ptr[4]];
	theString = [theString stringByAppendingFormat:@"%@\n",[date stdDescription]];
	union {
		float asFloat;
		uint32_t asLong;
	}theData;
	theString = [theString stringByAppendingFormat:@"-Actual Values-\n"];
	int theChan;
	for(theChan=0;theChan<numChannels;theChan++){
		theString = [theString stringByAppendingFormat:@"Channel %d (%@)\n",theChan,(onMask & (0x1<<theChan))?@"ON":@"OFF"];
		theData.asLong = ptr[5+theChan]; //act Voltage
		theString = [theString stringByAppendingFormat:@"Voltage: %c%.2f V\n",polarity?'+':'-',theData.asFloat];
		theData.asLong = ptr[6+theChan]; //act Current
		theString = [theString stringByAppendingFormat:@"Current: %.3f mA\n",theData.asFloat*1000000.];
	}
	return theString;
}

@end
