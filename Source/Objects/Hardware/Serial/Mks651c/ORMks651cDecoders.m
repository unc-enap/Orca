//
//  ORMks651cDecoders.m
//  Orca
//
// Created by David G. Phillips II on Tue Aug 30, 2011
//  Copyright 2005 CENPA, University of Washington. All rights reserved.
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


#import "ORMks651cDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

//------------------------------------------------------------------------------------------------
// Data Format
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
// ^^^^ ^^^^ ^^^^ ^^------------------------data id
//                  ^^ ^^^^ ^^^^ ^^^^ ^^^^--length in longs
//
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//                          ^^^^ ^^^^ ^^^^--device id
//                ^^^^----------------------units id (0=Torr,1=mTorr,2=mBar,3=uBar,4=kPa,5=Pa,6=cmH20,7=inH20)
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  pressure chan 0 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time pressure 0 taken in seconds since Jan 1, 1970
//-----------------------------------------------------------------------------------------------
@implementation ORMks651cDecoderForPressure

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t *dataPtr = (uint32_t*)someData;
	union {
		float asFloat;
		uint32_t asLong;
	}thePressure;
	int ident = dataPtr[1] & 0xfff;
	thePressure.asLong = dataPtr[2];									//encoded as float, use union to convert
	[aDataSet loadTimeSeries:thePressure.asFloat										
						  atTime:dataPtr[3]
						  sender:self 
						withKeys:@"Mks651c",[NSString stringWithFormat:@"%d",ident],
								nil];
		
	
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"Mks651c Controller\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	int units = (dataPtr[1]>>16) & 0xf;
	if(units == 00)		[theString stringByAppendingString: @"Units = Torr\n"];
	else if(units == 01)	[theString stringByAppendingString: @"Units = mTorr\n"];
	else if(units == 02)	[theString stringByAppendingString: @"Units = mBar\n"];
	else if(units == 03)	[theString stringByAppendingString: @"Units = uBar\n"];
	else if(units == 04)	[theString stringByAppendingString: @"Units = kPa\n"];
	else if(units == 05)	[theString stringByAppendingString: @"Units = Pa\n"];
	else if(units == 06)	[theString stringByAppendingString: @"Units = cmH20\n"];
	else if(units == 07)	[theString stringByAppendingString: @"Units = inH20\n"];
	else				[theString stringByAppendingString: @"Units = Arb\n"];
	int ident = dataPtr[1] & 0xfff;
	theString = [theString stringByAppendingFormat:@"Unit %d\n",ident];
	union {
		float asFloat;
		uint32_t asLong;
	}theData;
    theData.asLong = dataPtr[2];

    NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[3]];
		
    theString = [theString stringByAppendingFormat:@"Gauge %d: %.2E %@\n",ident,theData.asFloat,date];
	return theString;
}
@end


