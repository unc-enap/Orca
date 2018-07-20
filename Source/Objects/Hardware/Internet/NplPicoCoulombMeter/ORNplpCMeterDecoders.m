//
//  ORNplpCMeterDecoders.m
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


#import "ORNplpCMeterDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"

/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
-----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
-----------------------------------^^^^- Device number
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^- Unix time (GMT
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^------------------------------- id counter
----------^----------------------------- signal?
-----------^^--------------------------- chan
-------------^-------------------------- a or b
---------------^^^^ ^^^^ ^^^^ ^^^^ ^^^^- data (full scale = 12pC)
....followed records to fullfill the total length
*/

@implementation ORNplpCMeterDecoder
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr	 = (uint32_t*)someData;
    uint32_t length = ExtractLength(*ptr);
	ptr++; //point to unique id 
	NSString* deviceId  = [NSString stringWithFormat:@"device%2u",*ptr&0x0000000f];
	ptr++; //point to time 
	int i;

	for(i=0;i<length-3;i++){
		ptr++;
		NSString* channelKey			= [self getChannelKey:(*ptr&0x00600000)>>21];
		[aDataSet histogram:(*ptr & 0x000fffff)>>9 numBins:4095 sender:self withKeys:@"NplpCMeter",deviceId,channelKey,nil];
	}
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    uint32_t length = ExtractLength(*ptr);
    NSString* title= @"NplpCMeter Record\n\n";

	ptr++;
	NSString* deviceId  = [NSString stringWithFormat:@"device%2u\n",*ptr&0x0000000f];

	ptr++;
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:*ptr];

	NSString* valueString = @"";
	int n = (int)length - 3;
	int i;
	for(i=0;i<n;i++){
		ptr++;
		valueString   = [valueString stringByAppendingFormat:@"Value(%02u) = %0.6f\n",(*ptr&0x00f00000)>>20, (12. * (*ptr&0x000fffff))/1048576.];
    }
    return [NSString stringWithFormat:@"%@%@%@%@",title,deviceId,[date descriptionFromTemplate:@"MM/dd/yy HH:mm:SSS z\n"],valueString];
}


@end


