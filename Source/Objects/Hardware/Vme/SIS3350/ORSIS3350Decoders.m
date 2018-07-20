//
//  ORSIS3350Decoders.m
//  Orca
//
//  Created by Mark A. Howe on Thursday 8/6/09
//  Copyright (c) 2009 Universiy of North Carolina. All rights reserved.
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

#import "ORSIS3350Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORSIS3350Model.h"

/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
 ..
 .. TBD.....
 */

@implementation ORSIS3350WaveformDecoder
- (id) init

{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualSIS3350Cards release];
    [super dealloc];
}


- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	
	uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);
	
	ptr++; //point to location
	int crate	= (*ptr&0x01e00000)>>21;
    int card	= (*ptr&0x001f0000)>>16;
    int channel = (*ptr&0x0000000f);

	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	NSString* channelKey	= [self getChannelKey: channel];
	
	ptr++; //point to the start of data
	ptr += 4; //skip the time stamps and info
	
	NSMutableData* tmpData = [NSMutableData dataWithBytes:someData length:(length-6)*sizeof(int32_t)];
	unsigned short* dp = (unsigned short*)[tmpData bytes];
	int i;
	for(i=0;i<length-6;i++){
		*dp++ = *ptr & 0xfff;
		*dp++ = (*ptr>>16) & 0xfff;
		ptr++;
	}
	[aDataSet loadWaveform:tmpData
					offset:0 //bytes!
				  unitSize:2 //unit size in bytes!
					sender:self  
				  withKeys:@"SIS3350", @"Waveforms",crateKey,cardKey,channelKey,nil];
	
	//get the actual object
	if(getRatesFromDecodeStage && !skipRateCounts){
		NSString* aKey = [crateKey stringByAppendingString:cardKey];
		if(!actualSIS3350Cards)actualSIS3350Cards = [[NSMutableDictionary alloc] init];
		ORSIS3350Model* obj = [actualSIS3350Cards objectForKey:aKey];
		if(!obj){
			NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORSIS3350Model")];
			NSEnumerator* e = [listOfCards objectEnumerator];
			ORSIS3350Model* aCard;
			while(aCard = [e nextObject]){
				if([aCard slot] == card){
					[actualSIS3350Cards setObject:aCard forKey:aKey];
					obj = aCard;
					break;
				}
			}
		}
		getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:channel];
	}

    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	ptr++;
    NSString* title    = @"SIS3350 Waveform Record\n\n";
    NSString* crate    = [NSString stringWithFormat:@"Crate = %u\n",(*ptr&0x01e00000)>>21];
    NSString* card     = [NSString stringWithFormat:@"Card  = %u\n",(*ptr&0x001f0000)>>16];
    NSString* channel  = [NSString stringWithFormat:@"Channel  = %u\n",*ptr&0x0000000f];
    return [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,channel];               
}

@end
