//
//  ORVarianTPSDecoders.m
//  Orca
//
// Created by Mark  A. Howe on Wed 12/2/09
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

#import "ORVarianTPSDecoders.h"
#import "ORDataSet.h"

//------------------------------------------------------------------------------------------------
// Data Format
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
// ^^^^ ^^^^ ^^^^ ^^------------------------data id
//                  ^^ ^^^^ ^^^^ ^^^^ ^^^^--length in longs
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  
//                               ^^^^ ^^^^--Unique ID
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time pressure taken in seconds since Jan 1, 1970 UT time
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  pressure encoded as Long
//-----------------------------------------------------------------------------------------------

@implementation ORVarianTPSDecoderForPressure

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	unsigned long *p = (unsigned long*)someData;
	int ident = ShiftAndExtract(p[1],0,0xff);
	union {
		float asFloat;
		unsigned long asLong;
	}theTemp;
	theTemp.asLong = p[2];									//encoded as float, use union to convert
	[aDataSet loadTimeSeries:theTemp.asFloat*10.0E7										
					  atTime:p[3]
					  sender:self 
					withKeys:@"VarianTPS",
	 [NSString stringWithFormat:@"Unit %d",ident],nil];
	
	return ExtractLength(p[0]);
}

- (NSString*) dataRecordDescription:(unsigned long*)p
{
    NSString* title= @"VarianTPS Controller\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	int ident = ShiftAndExtract(p[1],0,0xff);
	theString = [theString stringByAppendingFormat:@"Unit %d\n",ident];
		
	union {
		float asFloat;
		unsigned long asLong;
	}theTemp;
	theTemp.asLong = p[2];									//encoded as float, use union to convert

	theString = [theString stringByAppendingFormat:@"%.2E %s\n",theTemp.asFloat,ctime((const time_t *)(&p[3]))];
	return theString;
}
@end


