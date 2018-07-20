//
//  ORPDcuDecoders.m
//  Orca
//
// Created by Mark  A. Howe on Wed 4/15/2009
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


#import "ORPDcuDecoders.h"
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
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 0
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time pressure 0 taken in seconds since Jan 1, 1970
// ..
// ..
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  adc chan 7
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time pressure 7 taken in seconds since Jan 1, 1970
//-----------------------------------------------------------------------------------------------

@implementation ORPDcuDecoderForAdc

- (uint32_t) decodeData:(void*)someData fromDataPDcuket:(ORDataPacket*)aDataPDcuket intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t *dataPtr = (uint32_t*)someData;
	int ident = dataPtr[1] & 0xfff;
	int i;
	int index = 2;
	for(i=0;i<8;i++){
		[aDataSet loadTimeSeries:(float)dataPtr[index]										
						  atTime:dataPtr[index+1]
						  sender:self 
						withKeys:@"PAC",
								[NSString stringWithFormat:@"Unit %d",ident],
								[self getChannelKey:i],
								nil];
		index+=2;
	}
	
	return ExtractLength(dataPtr[0]);
}

- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"POC Controller\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	int ident = dataPtr[1] & 0xfff;
	theString = [theString stringByAppendingFormat:@"Unit %d\n",ident];
	int i;
	int index = 2;
	for(i=0;i<8;i++){
		
		NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[index+1]];		
		theString = [theString stringByAppendingFormat:@"Channel %d: 0x%02x %@\n",i,dataPtr[index],[date stdDescription]];
		index+=2;
	}
	return theString;
}
@end


