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
 .. what follows is the data read from the card. Note that it may contain many waveforms.....
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


- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	
	uint32_t* ptr = (uint32_t*)someData;
	uint32_t length = ExtractLength(*ptr);
        	
	int crate	= ShiftAndExtract(ptr[1],21,0xf);
	int card	= ShiftAndExtract(ptr[1],16,0x1f);
	int channel = ShiftAndExtract(ptr[1],8,0xff);
	
	NSString* crateKey		= [self getCrateKey: crate];
	NSString* cardKey		= [self getCardKey: card];
	NSString* channelKey	= [self getChannelKey: channel];

    //-----------------------------------------------------------
    //set up for sending the record count for the data monitor
    ORSIS3320Model* obj = nil;
    //get the actual object
    if(getRatesFromDecodeStage){
        NSString* aKey = [crateKey stringByAppendingString:cardKey];
        if(!actualSIS3320Cards)actualSIS3320Cards = [[NSMutableDictionary alloc] init];
        obj = [actualSIS3320Cards objectForKey:aKey];
        if(!obj){
            NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORSIS3320Model")];
            for(ORSIS3320Model* aCard in listOfCards){
                if([aCard slot] == card){
                    [actualSIS3320Cards setObject:aCard forKey:aKey];
                    obj = aCard;
                    break;
                }
            }
        }
    }
    //-----------------------------------------------------------
    
	uint32_t startIndex = 2;
    do {
        uint32_t indexToDataSize = startIndex+9; //point to the word holding the record size
        uint32_t indexToData = startIndex + 10;
        
        uint32_t numberOfSamples   = 0; 
        uint32_t headerCheck       = (ptr[ indexToDataSize] & 0xffff0000) >> 16;
        
        if( headerCheck == 0xdada )      numberOfSamples = ptr[indexToDataSize] & 0xffff;   //health header, with samples
        else if( headerCheck == 0xeded ) numberOfSamples = 0;                               //just the header, no samples
        else                             break;                                             //this is bad... don't do any processing
        
        uint32_t recordSizeInLongs = ceil((float)numberOfSamples/2);
        if(recordSizeInLongs){
                NSMutableData* tmpData = [NSMutableData dataWithBytes:someData length:recordSizeInLongs*sizeof(int32_t)];
                unsigned short* dp = (unsigned short*)[tmpData bytes];
                uint32_t i;
                for( i = indexToData; i < indexToData + recordSizeInLongs; i++ ){
                    *dp++ = ptr[i] & 0xffff;
                    *dp++ = (ptr[i]>>16) & 0xffff;
                }
                [aDataSet loadWaveform:tmpData
                                offset:0 //bytes!
                              unitSize:2 //unit size in bytes!
                                sender:self
                              withKeys:@"SIS3320", @"Waveforms",crateKey,cardKey,channelKey,nil];

            if(getRatesFromDecodeStage){
                 getRatesFromDecodeStage = [obj bumpRateFromDecodeStage:channel];
            }
        }
        startIndex += recordSizeInLongs + 10; //header is 10 int32_t words
        
    }while(startIndex<length);

    return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title    = @"SIS3320 Waveform Record\n\n";
    NSString* crate    = [NSString stringWithFormat: @"Crate      = %d\n",ShiftAndExtract(ptr[1],21,0xf)];
    NSString* card     = [NSString stringWithFormat: @"Card       = %d\n",ShiftAndExtract(ptr[1],16,0x1f)];
    NSString* channel  = [NSString stringWithFormat: @"Channel    = %d\n",ShiftAndExtract(ptr[1],0,0xf)];
    NSString* timehigh  = [NSString stringWithFormat:@"Time(High) = %d\n",ShiftAndExtract(ptr[2],16,0xffff)];
    NSString* timelow  = [NSString stringWithFormat: @"Time(Low)  = %d\n",ShiftAndExtract(ptr[3],0,0xffffffff)];
    NSString* accum1  = [NSString stringWithFormat:  @"Accum Sum Gate1  = %d\n",ShiftAndExtract(ptr[4],0,0xfffff)];
    NSString* accum2  = [NSString stringWithFormat:  @"Accum Sum Gate2  = %d\n",ShiftAndExtract(ptr[5],0,0xfffff)];
    NSString* accum3  = [NSString stringWithFormat:  @"Accum Sum Gate3  = %d\n",ShiftAndExtract(ptr[6],0,0xfffff)];
    NSString* accum4  = [NSString stringWithFormat:  @"Accum Sum Gate4  = %d\n",ShiftAndExtract(ptr[7],0,0xfffff)];
    NSString* accum5  = [NSString stringWithFormat:  @"Accum Sum Gate5  = %d\n",ShiftAndExtract(ptr[8],0,0xfffff)];
    NSString* accum6  = [NSString stringWithFormat:  @"Accum Sum Gate6  = %d\n",ShiftAndExtract(ptr[8],16,0xffff)];
    NSString* accum7  = [NSString stringWithFormat:  @"Accum Sum Gate7  = %d\n",ShiftAndExtract(ptr[9],0,0xffff)];
    NSString* accum8  = [NSString stringWithFormat:  @"Accum Sum Gate8  = %d\n",ShiftAndExtract(ptr[9],16,0xffff)];
    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@",title,crate,card,channel,timehigh,timelow,accum1,accum2,accum3,accum4,accum5,accum6,accum7,accum8];
}

@end
