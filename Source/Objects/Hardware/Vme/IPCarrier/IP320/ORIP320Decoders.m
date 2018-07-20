//
//  ORIP320Decoders.m
//  Orca
//
//  Created by Mark Howe on 3/4/08.
//  Copyright 2008 CENPA, University of Washington. All rights reserved.
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


#import "ORIP320Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORIP320Model.h"


static NSString* kIPSlotKey[4] = {
		@"IP D",
		@"IP C",
		@"IP B",
		@"IP A"
};
@implementation ORIP320DecoderForAdc

- (NSString*) getSlotKey:(unsigned short)aSlot
{
	if(aSlot<4) return kIPSlotKey[aSlot];
	else return [NSString stringWithFormat:@"IP %2d",aSlot];		
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr	 = (uint32_t*)someData;
    uint32_t length = ExtractLength(*ptr);
	ptr++;
	unsigned char crate  = (*ptr&0x01e00000)>>21;
	unsigned char card   = (*ptr& 0x001f0000)>>16;
	unsigned char ipSlot = *ptr&0x0000000f;
	NSString* crateKey	 = [self getCrateKey: crate];
	NSString* cardKey	 = [self getCardKey: card];
	NSString* ipSlotKey  = [self getSlotKey:ipSlot];
	
	ptr++; //point to time
	uint32_t theTime = *ptr;

	int n = (int)(length - 3);
	int i;
	for(i=0;i<n;i++){
		ptr++;	//channel
		int chan   = (*ptr>>16) & 0x000000ff;
		int32_t rawValue = (*ptr & 0x00000fff);
		[aDataSet loadTimeSeries:rawValue atTime:theTime sender:self withKeys:@"IP320",@"Raw",
															crateKey,
															cardKey,
															ipSlotKey,
															[self getChannelKey:chan],nil];

    }


    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    uint32_t length = ExtractLength(*ptr);
    NSString* title= @"IP320 ADC Record\n\n";

	ptr++;
    NSString* crate			= [NSString stringWithFormat:@"Crate = %u\n",(*ptr&0x01e00000)>>21];
    NSString* card			= [NSString stringWithFormat:@"Card  = %u\n",(*ptr&0x001f0000)>>16];
	NSString* ipSlotKey		= [NSString stringWithFormat:@"IP    = %@\n",[self getSlotKey:*ptr&0x0000000f]];

	ptr++;
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:*ptr];

	NSString* adcString = @"";
	int n = (int)length - 3;
	int i;
	for(i=0;i<n;i++){
		ptr++;
		adcString   = [adcString stringByAppendingFormat:@"ADC(%02u) = 0x%x\n",(*ptr>>16)&0x000000ff, *ptr&0x00000fff];
    }

    return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,crate,card,ipSlotKey,[date descriptionFromTemplate:@"MM/dd/yy HH:mm:ss z\n"],adcString];
}


@end




@implementation ORIP320DecoderForValue

- (NSString*) getSlotKey:(unsigned short)aSlot
{
	if(aSlot<4) return kIPSlotKey[aSlot];
	else return [NSString stringWithFormat:@"IP %2d",aSlot];		
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr	 = (uint32_t*)someData;
    uint32_t length = ExtractLength(*ptr);
	ptr++;
	unsigned char crate  = (*ptr&0x01e00000)>>21;
	unsigned char card   = (*ptr& 0x001f0000)>>16;
	unsigned char ipSlot = *ptr&0x0000000f;
	NSString* crateKey	 = [self getCrateKey: crate];
	NSString* cardKey	 = [self getCardKey: card];
	NSString* ipSlotKey  = [self getSlotKey:ipSlot];
	ptr++; //point to time
	uint32_t theTime = *ptr;
	//[aDataSet loadGenericData:@" " sender:self withKeys:@"IP320",crateKey,cardKey,ipSlotKey,nil];

	int n = ((int)length - 3)/2;
	
	union {
		float asFloat;
		uint32_t asLong;
	}theValue;
		
	int i;
	for(i=0;i<n;i++){
		ptr++;	//channel
		int chan   = (int)*ptr;
		ptr++;	//value (encoded as int32_t)
		theValue.asLong = *ptr;
		[aDataSet loadTimeSeries:theValue.asFloat atTime:theTime sender:self withKeys:@"IP320",@"Value",
															crateKey,
															cardKey,
															ipSlotKey,
															[self getChannelKey:chan],nil];

    }




    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    uint32_t length = ExtractLength(*ptr);
    NSString* title= @"IP320 Converted Value\n\n";

	ptr++;
    NSString* crate			= [NSString stringWithFormat:@"Crate = %u\n",(*ptr&0x01e00000)>>21];
    NSString* card			= [NSString stringWithFormat:@"Card  = %u\n",(*ptr&0x001f0000)>>16];
	NSString* ipSlotKey		= [NSString stringWithFormat:@"IP    = %@\n",[self getSlotKey:*ptr&0x0000000f]];

	ptr++;
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:*ptr];

	NSString* adcString = @"";
	int n = ((int)length - 3)/2;
	
	union {
		float asFloat;
		uint32_t asLong;
	}theValue;
	
	int i;
	for(i=0;i<n;i++){
		ptr++;	//channel
		int chan   = (int)*ptr;
		ptr++;	//value (encoded as int32_t)
		theValue.asLong = *ptr;
		[adcString stringByAppendingFormat:@"ADC(%02d) = %.4f\n",chan, theValue.asFloat];
    }
    return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,crate,card,ipSlotKey,[date descriptionFromTemplate:@"MM/dd/yy HH:mm:ss z"],adcString];
}


@end
