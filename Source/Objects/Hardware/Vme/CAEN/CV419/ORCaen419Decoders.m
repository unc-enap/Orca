//
//  ORCaen419Decoders.m
//  Orca
//
//  Created by Mark Howe on 2/23.
//  Copyright 2009 CENPA, University of Washington. All rights reserved.
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

#import "ORCaen419Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORCaen419Model.h"
#import "ORDataTypeAssigner.h"
#import "ORCaen419Model.h"

@implementation ORCaen419DecoderForAdc

- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actual419s release];
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
        ptr++;
        length = 2;
    }
    
	unsigned char crate   = (*ptr&0x01e00000)>>21;
	unsigned char card   = (*ptr& 0x001f0000)>>16;
	unsigned char channel = (*ptr&0x0000f000)>>12;
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getCardKey: card];
	NSString* channelKey = [self getChannelKey: channel];
	
    [aDataSet histogram:*ptr&0x00000fff numBins:4096 sender:self  withKeys:@"CV419", crateKey,cardKey,channelKey,nil];

	//get the actual object
	if(getRatesFromDecodeStage && !skipRateCounts){
		NSString* caen419Key = [crateKey stringByAppendingString:cardKey];
		if(!actual419s)actual419s = [[NSMutableDictionary alloc] init];
		ORCaen419Model* obj = [actual419s objectForKey:caen419Key];
		if(!obj){
			NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORCaen419Model")];
			NSEnumerator* e = [listOfCards objectEnumerator];
			ORCaen419Model* aCard;
			while(aCard = [e nextObject]){
				if([aCard crateNumber] == crate && [aCard slot] == card){
					[actual419s setObject:aCard forKey:caen419Key];
					obj = aCard;
					break;
				}
			}
		}
		getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:channel];
	}
	
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    if(!IsShortForm(*ptr)){
        ptr++;
    }

    NSString* title= @"CV419 ADC Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate = %u\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",(*ptr&0x001f0000)>>16];
    NSString* chan  = [NSString stringWithFormat:@"Chan  = %u\n",(*ptr&0x0000f000)>>12];
    NSString* adc   = [NSString stringWithFormat:@"ADC   = 0x%x\n",*ptr&0x00000fff];
    
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,crate,card,chan,adc];               
}

@end


