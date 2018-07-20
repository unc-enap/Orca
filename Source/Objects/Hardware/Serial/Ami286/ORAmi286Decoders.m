//
//  ORAmi286Decoders.m
//  Orca
//
//  Created by Mark Howe on Fri Sept 14, 2007.
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


#import "ORAmi286Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"

//------------------------------------------------------------------------------------------------
// Data Format
//xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
//^^^^ ^^^^ ^^^^ ^^-----------------------data id
//                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs
//
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
// ^^^^------------------------------------ fill state for level 3
//      ^^^^------------------------------- fill state for level 2
//           ^^^^-------------------------- fill state for level 1
//                ^^^^--------------------- fill state for level 0
//                          ^^^^ ^^^^ ^^^^- device id
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  level chan 0 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time level 0 taken in seconds since Jan 1, 1970
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  level chan 1 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time level 1 taken in seconds since Jan 1, 1970
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  level chan 2 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time level 2 taken in seconds since Jan 1, 1970
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  level chan 3 encoded as a float
// xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time level 3 taken in seconds since Jan 1, 1970
//-----------------------------------------------------------------------------------------------
static NSString* kBocTicUnit[4] = {
    //pre-make some keys for speed.
    @"Level 0",  @"Level 1",  @"Level 2", @"Level 3"

};

@implementation ORAmi286DecoderForLevel

- (NSString*) getLevelKey:(unsigned short)aUnit
{
    if(aUnit<4) return kBocTicUnit[aUnit];
    else return [NSString stringWithFormat:@"Level %d",aUnit];			
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	uint32_t *dataPtr = (uint32_t*)someData;
	union {
		float asFloat;
		uint32_t asLong;
	}theTemp;
	int ident = dataPtr[1] & 0xfff;
	int i;
	int index = 2;
	for(i=0;i<4;i++){
		theTemp.asLong = dataPtr[index];									//encoded as float, use union to convert
		[aDataSet loadTimeSeries:theTemp.asFloat										
						  atTime:dataPtr[index+1]
						  sender:self 
						withKeys:@"AMI286",
								[NSString stringWithFormat:@"Unit %d",ident],
								[self getLevelKey:i],
								nil];
		index+=2;
	}
	
	return ExtractLength(dataPtr[0]);
}
- (NSString*) fillStatusName:(int)i
{
	switch(i){
		case 0: return @"Off";
		case 1: return @"On";
		case 2: return @"Auto-Off";
		case 3: return @"Auto-On";
		case 4: return @"Expired";
		default: return @"?";
	}
}
- (NSString*) dataRecordDescription:(uint32_t*)dataPtr
{
    NSString* title= @"AMI 286 Controller\n\n";
    NSString* theString =  [NSString stringWithFormat:@"%@\n",title];               
	int ident = dataPtr[1] & 0xfff;
	theString = [theString stringByAppendingFormat:@"Unit %d\n",ident];
	union {
		float asFloat;
		uint32_t asLong;
	}theData;
	int i;
	int index = 2;
	for(i=0;i<4;i++){
		theData.asLong = dataPtr[index];
		int fillState =  ShiftAndExtract(dataPtr[1],16+(i*4),0xf);
		NSDate* date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)dataPtr[index+1]];
		
		theString = [theString stringByAppendingFormat:@"Level %d: %.2E %@\n",i,theData.asFloat,[date stdDescription]];
		theString = [theString stringByAppendingFormat:@"State: %@\n",[self fillStatusName:fillState]];
		index+=2;
	}
	return theString;
}
@end


