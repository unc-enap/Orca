//
//  ORAD3511Decoders.m
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


#import "ORAD3511Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORAD3511Model.h"
#import "ORDataTypeAssigner.h"


//---------------------------------------------------------------
//Data format
/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
       ^--------------------------------1 = double word timestamp included
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card

if timestamp included the next two words follow, otherwise the data follows
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^-reference date (high part of double)

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^-reference date (low part of double)

...followed by length in longs - (2 if NO timestamp) or (4 if timestamp included)
*/

@implementation ORAD3511DecoderForAdc

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr   = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);

	ptr++;
    
	unsigned char crate   = (*ptr&0x01e00000)>>21;
	unsigned char card   = (*ptr& 0x001f0000)>>16;
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getStationKey: card];
	BOOL timingIncluded = (*ptr&0x02000000)>>25;
	BOOL dataOffset;
	if(timingIncluded)	{
		dataOffset = 4;
		ptr++;	//skip over the timing word #1
		ptr++; //skip over the timing word #2
	}
	else dataOffset = 2;
	
	int i;
	for(i=0;i<length-dataOffset;i++){
		ptr++;
		uint32_t  value = *ptr;
		[aDataSet histogram:value numBins:8192 sender:self  withKeys:@"AD3511", crateKey,cardKey,@"ADC",nil];


	}
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	uint32_t length = ExtractLength(*ptr);
	ptr++;
    
    NSString* title= @"AD3511 ADC Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate    = %u\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Station  = %u\n",(*ptr&0x001f0000)>>16];

	BOOL timingIncluded = (*ptr&0x02000000)>>25;
	BOOL dataOffset;
	NSMutableString* adcValues = [NSMutableString stringWithFormat:@"buffer size: %u\n",timingIncluded?length-4:length-2];
	if(timingIncluded)	{
		dataOffset = 4;
		union {
			NSTimeInterval asTimeInterval;
			uint32_t asLongs[2];
		}theTimeRef;
		ptr++;
		theTimeRef.asLongs[1] = *ptr;
		ptr++;
		theTimeRef.asLongs[0] = *ptr;
		NSDate* theTime   = [NSDate dateWithTimeIntervalSinceReferenceDate:theTimeRef.asTimeInterval];

		[adcValues appendString:[NSString stringWithFormat:@"timeStamp  = %@\n",[theTime descriptionFromTemplate:@"MM/dd/yy HH:mm:ss:FF"]]];
		[adcValues appendString:[NSString stringWithFormat:@"(in secs)  = %.3f\n\n",theTimeRef.asTimeInterval]];

	}
	else dataOffset = 2;



	int i;
	for(i=0;i<length-dataOffset;i++){
		ptr++;
		[adcValues appendFormat:@"%d: %u\n",i,*ptr];
	}
    return [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,adcValues];               
}


@end

