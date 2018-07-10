//
//  ORSIS3320Decoders.m
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

#import "ORSIS3320Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORSIS3320Model.h"

/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
 ..
 .. TBD.....
 */

@implementation ORSIS3320WaveformDecoder
- (id) init

{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualSIS3320Cards release];
    [super dealloc];
}


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	
	unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
	
	int crate	= ShiftAndExtract(ptr[1],21,0xf);
	int card	= ShiftAndExtract(ptr[1],16,0x1f);
	int channel = ShiftAndExtract(ptr[1],8,0xff);
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	NSString* channelKey	= [self getChannelKey: channel];
		
	NSMutableData* tmpData = [NSMutableData dataWithBytes:someData length:(length-3)*sizeof(long)];
	unsigned short* dp = (unsigned short*)[tmpData bytes];
	int i;
	for(i=3;i<length-3;i++){
		*dp++ = ptr[i] & 0xffff;
		*dp++ = (ptr[i]>>16) & 0xffff;
	}
	[aDataSet loadWaveform:tmpData
					offset:0 //bytes!
				  unitSize:2 //unit size in bytes!
					sender:self  
				  withKeys:@"SIS3320", @"Waveforms",crateKey,cardKey,channelKey,nil];
	
	//get the actual object
	if(getRatesFromDecodeStage){
		NSString* aKey = [crateKey stringByAppendingString:cardKey];
		if(!actualSIS3320Cards)actualSIS3320Cards = [[NSMutableDictionary alloc] init];
		ORSIS3320Model* obj = [actualSIS3320Cards objectForKey:aKey];
		if(!obj){
			NSArray* listOfCards = [[[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORSIS3320Model")];
			for(ORSIS3320Model* aCard in listOfCards){
				if([aCard slot] == card){
					[actualSIS3320Cards setObject:aCard forKey:aKey];
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
    NSString* title    = @"SIS3320 Waveform Record\n\n";
    NSString* crate    = [NSString stringWithFormat:@"Crate = %d\n",ShiftAndExtract(ptr[1],21,0xf)];
    NSString* card     = [NSString stringWithFormat:@"Card  = %d\n",ShiftAndExtract(ptr[1],16,0x1f)];
    NSString* channel  = [NSString stringWithFormat:@"Channel  = %d\n",ShiftAndExtract(ptr[1],0,0xf)];
    return [NSString stringWithFormat:@"%@%@%@%@",title,crate,card,channel];               
}

@end
