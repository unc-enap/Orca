//
//  ORPollingTimeStampDecoders.m
//  Orca
//
//  Created by Mark Howe on 9/21/04.
//  Copyright 2004 CENPA, University of Washington. All rights reserved.
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


#import "ORPollingTimeStampDecoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
//------------------------------------------------------------------
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs (always 3)
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-seconds since Jan 1,1970
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-microseconds since last second


@implementation ORPollingTimeStampDecoder


- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;    
    return ExtractLength(ptr[0]); //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)someData
{
    uint32_t* ptr   = (uint32_t*)someData;
	
    NSString* title         = @"PollingTimeStamp Record\n\n";
    NSString* seconds       = [NSString stringWithFormat:@"Seconds     : %u\n",ptr[1]];
    NSString* microseconds  = [NSString stringWithFormat:@"Microseconds: %u\n",ptr[2]];

	
    return [NSString stringWithFormat:@"%@%@%@",title,seconds,microseconds];
}

@end
