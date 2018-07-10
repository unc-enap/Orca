//
//  ORGretinaDecoders.m
//  Orca
//
//  Created by Mark Howe on 02/07/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
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

#import "ORGretinaDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORGretinaModel.h"

/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
-----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------^-^^^--------------------------- Crate number
-------------^-^^^^--------------------- Card number
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
------------------------------------^^^- Channel number
^^^^ ^^^^ ^^^^ ^^^^--------------------- Data Length
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------------------^^^^ ^^^^ ^^^^ ^^^^- LED1
^^^^ ^^^^ ^^^^ ^^^^--------------------- LED2
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------------------^^^^ ^^^^ ^^^^ ^^^^- LED3
^^^^ ^^^^ ^^^^ ^^^^--------------------- Energy bit 0-15
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
-------------------------------^^^ ^^^^- Energy bit 16-22
--------------------^------------------- P
---------------------^------------------ C
----------------------^----------------- E
-----------------------^---------------- Sx
^^^^ ^^^^ ^^^^ ^^^^--------------------- CFD Timestamp bit0-15
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
--------------------^^^^ ^^^^ ^^^^ ^^^^- CFD Timestamp bit16-31
^^^^ ^^^^ ^^^^ ^^^^--------------------- CFD Timestamp bit32-47
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
------------------------ ^^^^ ^^^^ ^^^^- Raw data point0
-----^^^^ ^^^^ ^^^^--------------------- Raw data point1
Raw data points continue until the Data length is used up....
*/

@implementation ORGretinaWaveformDecoder
- (id) init

{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualGretinaCards release];
    [super dealloc];
}

- (unsigned long) decodeData:(void*)someData fromDataPacket:(ORDataPacket*)aDataPacket intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
	ptr++; //point to location info
    int crate = (*ptr&0x01e00000)>>21;
    int card  = (*ptr&0x001f0000)>>16;

	ptr++; //first word of the actual card packet
	int channel		 = *ptr&0x7;
	int packetLength = (*ptr>>16) - 6;
	
/*	ptr++; //point to led0-15 && 16-31
	unsigned short led1 = *ptr & 0xffff;
	unsigned short led2 = (*ptr & 0xffff0000)>>8;
 
	ptr++;
	unsigned short led3 = *ptr & 0xffff;

	NSLog(@"0x%08x 0x%08x 0x%08x\n",led3,led2,led1);
*/	
	ptr += 2; //point to Energy low word
	unsigned long energy = *ptr >> 16;
	ptr++;	  //point to Energy second word
	energy += (*ptr & 0x0000007f) << 16;
	
	// energy is in 2's complement, taking abs value if necessary
    if((energy >> 22) & 0x1) energy = (~energy + 1) & 0x7fffff;

	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getCardKey: card];
	NSString* channelKey = [self getChannelKey: channel];


    [aDataSet histogram:energy>>2 numBins:4096*8 sender:self  withKeys:@"Gretina", @"Energy",crateKey,cardKey,channelKey,nil];
	
	ptr += 3; //point to the data

    NSMutableData* tmpData = [NSMutableData dataWithCapacity:512*2];
	
	//note:  there is something wrong here. The package length should be in longs but the
	//packet is always half empty.   
	[tmpData setLength:packetLength*sizeof(long)];
	unsigned short* dPtr = (unsigned short*)[tmpData bytes];
	int i;
	int wordCount = 0;
	for(i=0;i<packetLength;i++){
		dPtr[wordCount++] =	0x00000fff & *ptr;		
		dPtr[wordCount++] =	(0x0fff0000 & *ptr) >> 16;		
		ptr++;
	}
    [aDataSet loadWaveform:tmpData 
					offset:0 //bytes!
				  unitSize:2 //unit size in bytes!
					sender:self  
				  withKeys:@"Gretina", @"Waveforms",crateKey,cardKey,channelKey,nil];

	//get the actual object
	if(getRatesFromDecodeStage){
		NSString* aKey = [crateKey stringByAppendingString:cardKey];
		if(!actualGretinaCards)actualGretinaCards = [[NSMutableDictionary alloc] init];
		ORGretinaModel* obj = [actualGretinaCards objectForKey:aKey];
		if(!obj){
			NSArray* listOfCards = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORGretinaModel")];
			NSEnumerator* e = [listOfCards objectEnumerator];
			ORGretinaModel* aCard;
			while(aCard = [e nextObject]){
				if([aCard slot] == card){
					[actualGretinaCards setObject:aCard forKey:aKey];
					obj = aCard;
					break;
				}
			}
		}
		getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:channel];
	}


	 
    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	ptr++;

    NSString* title= @"Gretina Waveform Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate = %d\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %d\n",(*ptr&0x001f0000)>>16];
	ptr++;
    NSString* chan  = [NSString stringWithFormat:@"Chan  = %d\n",*ptr&0x7];
	ptr+=2;
	unsigned long energy = *ptr >> 16;
	ptr++;	  //point to Energy second word
	energy += (*ptr & 0x0000007f) << 16;
	
	// energy is in 2's complement, taking abs value if necessary
    if((energy >> 22) & 0x1) energy = (~energy + 1) & 0x7fffff;
	NSString* energyStr  = [NSString stringWithFormat:@"Energy  = %d\n",energy];
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,crate,card,chan,energyStr];               
}

@end
