//
//  ORGretinaTriggerDecoder.m
//  Orca
//
// Created by Mark  A. Howe on Sat Aug 23, 2014
//  Copyright 2014 University of North Carolina. All rights reserved.
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


#import "ORGretinatriggerDecoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

//------------------------------------------------------------------------------------------------
// Data Format
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
// ^^^^ ^^^^ ^^^^ ^^------------------------data id
//                  ^^ ^^^^ ^^^^ ^^^^ ^^^^--length in longs
//
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
// ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^  -------spare bits
//                                  ^-------locked
//                                 ^ -------link was lost
//                                    ^^^^--device id
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx--Mac Unix time in seconds since Jan 1,1970 (UT)
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
// ^^^^ ^^^^ ^^^^ ^^^^ ---------------------spare bits
//                     ^^^^ ^^^^ ^^^^ ^^^^--timeStampA
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
// ^^^^ ^^^^ ^^^^ ^^^^ ---------------------timeStampB
//                     ^^^^ ^^^^ ^^^^ ^^^^--timeStampC
//-----------------------------------------------------------------------------------------------

@implementation ORGretinaTriggerDecoder

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t* p = (uint32_t*)someData;
    uint32_t length = ExtractLength(p[0]);
    //just record it in the data monitor
    [aDataSet loadGenericData:@" " sender:self withKeys:@"Master Trigger",nil];
	return length;
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"Master Trigger\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	int ident = dataPtr[1] & 0xfff;
    BOOL locked    = ShiftAndExtract(dataPtr[1], 4, 0x1);
    BOOL lockLost  = ShiftAndExtract(dataPtr[1], 5, 0x1);
    BOOL doNotLock = ShiftAndExtract(dataPtr[1], 6, 0x1);
    
	theString = [theString stringByAppendingFormat:@"Unit %d\n",ident];
    NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[2]];
    
    theString = [theString stringByAppendingFormat:@"Date: %@\n",[date stdDescription]];
    theString = [theString stringByAppendingFormat:@"TimeStamp: %lld\n",(uint64_t)dataPtr[3]<<32 | dataPtr[4]];
    
    theString = [theString stringByAppendingFormat:@"Locked:   %@\n",locked   ? @"YES":@"NO"];
    theString = [theString stringByAppendingFormat:@"LockLost: %@\n",lockLost ? @"YES":@"NO"];
    if(doNotLock)theString = [theString stringByAppendingString:@"User Opted NOT to Lock"];

	return theString;
}

@end


