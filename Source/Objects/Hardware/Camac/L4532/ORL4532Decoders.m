//
//  ORL4532Decoders.m
//  Orca
//
//  Created by Mark Howe on 9/29/06.
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


#import "ORL4532Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORL4532Model.h"
#import "ORDataTypeAssigner.h"

//---------------------------------------------------------------
//Data format for Trigger Record
/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx event count

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
       ^--------------------------------1 = double word timestamp included
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card

if timestamp included the next two words follow, otherwise nothing
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^-reference date (high part of double)

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^-reference date (low part of double)
*/

@implementation ORL4532DecoderForTrigger

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr   = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);

	ptr++;
	ptr++;
    NSString* crate = [self getCrateKey:(*ptr&0x01e00000)>>21];
    NSString* card  = [self getStationKey:(*ptr&0x001f0000)>>16];
	[aDataSet loadGenericData:@" " sender:self withKeys:@"L4532",crate,card,@"Trigger",nil];

    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{    
    NSString* title= @"L4532 Trigger Record\n\n";
	ptr++;
	NSString* eventCount = [NSString stringWithFormat:@"EventCount = %u\n",*ptr];

	ptr++;
    NSString* crate = [NSString stringWithFormat:@"Crate    = %u\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Station  = %u\n",(*ptr&0x001f0000)>>16];

	BOOL timingIncluded = (*ptr&0x02000000)>>25;
	NSString* timeString;
	if(timingIncluded)	{
		union {
			NSTimeInterval asTimeInterval;
			uint32_t asLongs[2];
		}theTimeRef;
		ptr++;
		theTimeRef.asLongs[1] = *ptr;
		ptr++;
		theTimeRef.asLongs[0] = *ptr;
		NSDate* theTime   = [NSDate dateWithTimeIntervalSinceReferenceDate:theTimeRef.asTimeInterval];
		timeString = [NSString string];
		timeString = [timeString stringByAppendingFormat:@"timeStamp  = %@\n",[theTime descriptionFromTemplate:@"MM/dd/yy HH:mm:SSS"]];
		timeString = [timeString stringByAppendingFormat:@"(in secs)  = %.3f\n\n",theTimeRef.asTimeInterval];

	}
	else timeString = @"\nNo Timing Info Included\n";
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,crate,card,eventCount,timeString];               
}
@end

//---------------------------------------------------------------
//Data format for Channel Trigger Record
/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx trigger Mask
*/

static NSString* kTriggerKey[32] = {
	//pre-make some keys for speed.
	@"Channel 0", @"Channel 1", @"Channel 2", @"Channel 3",
	@"Channel 4", @"Channel 5", @"Channel 6", @"Channel 7",
	@"Channel 8", @"Channel 9", @"Channel10", @"Channel11",
	@"Channel12", @"Channel13", @"Channel14", @"Channel15",
	@"Channel16", @"Channel17", @"Channel18", @"Channel19",
	@"Channel20", @"Channel21", @"Channel22", @"Channel23",
	@"Channel24", @"Channel25", @"Channel26", @"Channel27",
	@"Channel28", @"Channel29", @"Channel30", @"Channel31"
};


@implementation ORL4532DecoderForChannelTrigger

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr   = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);
	ptr++;
    NSString* crate = [self getCrateKey:(*ptr&0x01e00000)>>21];
    NSString* card  = [self getStationKey:(*ptr&0x001f0000)>>16];

	ptr++;
	uint32_t mask = *ptr;
	int i;
	for(i=0;i<32;i++){
		if(mask & (1L<<i)){
			[aDataSet loadGenericData:@" " sender:self withKeys:@"L4532",crate,card,@"Latch",kTriggerKey[i],nil];
		}
	}
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{    
    NSString* title= @"L4532 Channel Trigger Record\n\n";

	ptr++;
    NSString* crate = [NSString stringWithFormat:@"Crate    = %u\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Station  = %u\n",(*ptr&0x001f0000)>>16];

	ptr++;
	NSString* eventCount = [NSString stringWithFormat:@"Trigger Mask = 0x%08x\n",*ptr];

    return [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,eventCount];               
}


@end


