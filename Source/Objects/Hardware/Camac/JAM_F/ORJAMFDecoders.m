//
//  ORJAMFDecoders.m
//  Orca
//
//  Created by Mark Howe on 3/27/08.
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

#import "ORJAMFDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORJAMFModel.h"

@implementation ORJAMFDecoderForAdc

/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
-----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------^-^^^--------------------------- Crate number
-------------^-^^^^--------------------- Station number
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx- Unix time (gmt)
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx- adc word 1  (Note one adc word for each enabled channel, up to 16 total)
---------------^^^^--------------------- chan number
--------------------^^^^-^^^^-^^^^-^^^^- raw adc number
...
...
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx- adc word n
---------------^^^^--------------------- chan number
--------------------^^^^-^^^^-^^^^-^^^^- raw adc number
*/

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr	 = (uint32_t*)someData;
    uint32_t length = ExtractLength(*ptr);
	ptr++;
	unsigned char crate  = (*ptr&0x01e00000)>>21;
	unsigned char card   = (*ptr& 0x001f0000)>>16;
	NSString* crateKey	 = [self getCrateKey: crate];
	NSString* cardKey	 = [self getStationKey: card];
	
	[aDataSet loadGenericData:@" " sender:self withKeys:@"JAMF",crateKey,cardKey,nil];

    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    uint32_t length = ExtractLength(*ptr);
    NSString* title= @"JAMF ADC Record\n\n";

	ptr++;
    NSString* crate			= [NSString stringWithFormat:@"Crate = %u\n",(*ptr&0x01e00000)>>21];
    NSString* card			= [NSString stringWithFormat:@"Station  = %u\n",(*ptr&0x001f0000)>>16];

	ptr++;
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:*ptr];

	NSString* adcString = @"";
	int n = (int)(length - 3);
	int i;
	for(i=0;i<n;i++){
		ptr++;
		adcString   = [adcString stringByAppendingFormat:@"ADC(%02u) = 0x%x\n",(*ptr>>16)&0x000000ff, *ptr&0x00000fff];
    }
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,crate,card,[date descriptionFromTemplate:@"MM/dd/yy HH:mm:ss z\n"],adcString];
}


@end


