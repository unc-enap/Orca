//
//  ORAD811Decoders.m
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


#import "ORAD811Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORAD811Model.h"
#import "ORDataTypeAssigner.h"

@implementation ORAD811DecoderForAdc

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
    uint32_t length;
    uint32_t* ptr = (uint32_t*)someData;
    if(IsShortForm(*ptr)){
        length = 1;
    }
    else  {       //oh, we have been assign the int32_t form--skip to the next int32_t word for the data
        length = ExtractLength(*ptr);
        ptr++;
    }
    
	unsigned char crate   = (*ptr&0x01e00000)>>21;
	unsigned char card   = (*ptr& 0x001f0000)>>16;
	unsigned char channel = (*ptr&0x0000f000)>>12;
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getStationKey: card];
	NSString* channelKey = [self getChannelKey: channel];
    uint32_t  value = *ptr&0x00000fff;
	
    [aDataSet histogram:value numBins:2048 sender:self  withKeys:@"AD811", crateKey,cardKey,channelKey,nil];

    
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	uint32_t length = ExtractLength(*ptr);
	if(!IsShortForm(*ptr)){
        ptr++; //now p[0] is the word with the location (short -or- int32_t form
    }
    
    NSString* title= @"AD811 ADC Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate    = %u\n",(ptr[0]&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Station  = %u\n",(ptr[0]&0x001f0000)>>16];
    NSString* chan  = [NSString stringWithFormat:@"Chan     = %u\n",(ptr[0]&0x0000f000)>>12];
    NSString* adc   = [NSString stringWithFormat:@"ADC      = 0x%x\n",ptr[0]&0x00000fff];
    NSDate* theTime = nil;
	
	if(length ==4){
		union {
			NSTimeInterval asTimeInterval;
			uint32_t asLongs[2];
		}theTimeRef;
		theTimeRef.asLongs[1] = ptr[1];
		theTimeRef.asLongs[0] = ptr[2];
		
		theTime   = [NSDate dateWithTimeIntervalSinceReferenceDate:theTimeRef.asTimeInterval];
		NSString* inSec = [NSString stringWithFormat:@"\n(%.3f secs)\n",theTimeRef.asTimeInterval];
		return [NSString stringWithFormat:@"%@%@%@%@%@\nTimeStamp:\n%@%@\n",title,crate,card,chan,adc,[theTime descriptionFromTemplate:@"MM/dd/yy HH:mm:ss:F"],inSec];
		
	}
	
	
    else return [NSString stringWithFormat:@"%@%@%@%@%@\n",title,crate,card,chan,adc];               
}


@end

