//
//  ORSIS3300Decoders.m
//  Orca
//
//  Created by Mark A. Howe on Wednesday 9/30/08.
//  Copyright (c) 2008 CENPA. University of Washington. All rights reserved.
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

#import "ORSIS3300Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORSIS3300Model.h"

/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 --------^-^^^--------------------------- Crate number
 -------------^-^^^^--------------------- Card number
 --------------------------------------^- 1==SIS33001, 0==SIS3000 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx-Trigger Event Word
 ^---------------------------------------1 if ADC0 in this event
 -^--------------------------------------1 if ADC1 in this event
 --^-------------------------------------1 if ADC2 in this event
 ---^------------------------------------1 if ADC3 in this event
 -----^----------------------------------1 if ADC4 in this event
 ------^---------------------------------1 if ADC5 in this event
 -------^--------------------------------1 if ADC6 in this event
 --------^-------------------------------1 if ADC7 in this event
 ------------^---------------------------1 if wrapped
 ---------------^^^^ ^^^^ ^^^^ ^^^^ ^^^^-Event Data End Address
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^-------------------------------Event #
 ----------^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^-Time from previous event always zero unless in multievent mode
 
 waveform follows:
 Each word may have data for two ADC channels. The high order 16
 bits are for ADC0,2,4,6. The low order bits are for ADC1,3,5,7
 
 if SIS3300:
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^----------------------------------------Status of User Bit
 --------------------^--------------------Status of Gate Chaining Bit
 ---^-------------------^-----------------Out of Range Bit
 -----^^^^ ^^^^ ^^^^------^^^^ ^^^^ ^^^^--12 bit Data
 if SIS3301:
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^---------------------------------------Status of User Bit
 --------------------^-------------------Status of Gate Chaining Bit
 -^-------------------^------------------Out of Range Bit
 --^^ ^^^^ ^^^^ ^^^^---^^ ^^^^ ^^^^ ^^^^-14-bit Data
 */

@implementation ORSIS3300WaveformDecoder
- (id) init

{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualSIS3300Cards release];
    [super dealloc];
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);
	ptr++; //point to location info
    int crate = (*ptr&0x01e00000)>>21;
    int card  = (*ptr&0x001f0000)>>16;
	int moduleID = (*ptr & 0x1);
	ptr++; //event trigger word
	uint32_t triggerWord= *ptr;
	
	ptr++; //point to the event# and timestamp (timestamp always zero unless in multievent mode)
	ptr++; //point to the data

	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	
	int32_t numDataWords = length-4;
	//any of the channels may have triggered, so have to check each bit in the adc mask
	int channel;
	uint32_t aMask = moduleID?0x3fff:0xfff;
	for(channel=0;channel<8;channel++){
		if(triggerWord & (0x80000000 >> channel)){
			NSMutableData* tmpData = [NSMutableData dataWithLength:numDataWords*sizeof(short)];
			short* sPtr = (short*)[tmpData bytes];
			NSString* channelKey = [self getChannelKey: channel];
			int i;
			if(channel%2){
				for(i=0;i<(length-3);i++) {
					sPtr[i] = ptr[i] & aMask;	
				}
			}
			else {
				for(i=0;i<(length-3);i++) {
					sPtr[i] = (ptr[i]>>16) & aMask;	
				}
			}
			
			[aDataSet loadWaveform:tmpData
							offset:0 //bytes!
						  unitSize:2 //unit size in bytes!
							sender:self  
						  withKeys:@"SIS3300", @"Waveforms",crateKey,cardKey,channelKey,nil];
			
			//get the actual object
            if(getRatesFromDecodeStage && !skipRateCounts){
				NSString* aKey = [crateKey stringByAppendingString:cardKey];
				if(!actualSIS3300Cards)actualSIS3300Cards = [[NSMutableDictionary alloc] init];
				ORSIS3300Model* obj = [actualSIS3300Cards objectForKey:aKey];
				if(!obj){
					NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORSIS3300Model")];
					NSEnumerator* e = [listOfCards objectEnumerator];
					ORSIS3300Model* aCard;
					while(aCard = [e nextObject]){
						if([aCard slot] == card){
							[actualSIS3300Cards setObject:aCard forKey:aKey];
							obj = aCard;
							break;
						}
					}
				}
				getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:channel];
			}
			
			
		}
	}

 
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
	ptr++;
    NSString* title= @"SIS3300 Waveform Record\n\n";
    NSString* crate = [NSString stringWithFormat:@"Crate = %u\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",(*ptr&0x001f0000)>>16];
	NSString* moduleID = (*ptr&0x1)?@"SIS3301":@"SIS3300";
	ptr++;
	NSString* triggerWord = [NSString stringWithFormat:@"TriggerWord  = 0x08%x\n",*ptr];
	ptr++;
	NSString* Event = [NSString stringWithFormat:@"Event  = 0x%08x\n",(*ptr>>24)&0xff];
	NSString* Time = [NSString stringWithFormat:@"Time Since Last Trigger  = 0x%08x\n",*ptr&0xffffff];

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,moduleID,triggerWord,Event,Time];               
}

@end
