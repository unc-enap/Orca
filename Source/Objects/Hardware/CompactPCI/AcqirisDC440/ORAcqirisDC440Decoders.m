//
//  ORShaperDecoders.m
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


#import "ORAcqirisDC440Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORAcqirisDC440Model.h"
#import "ORDataTypeAssigner.h"
#import "ORAcqirisDC440Model.h"

@implementation ORAcqirisDC440DecoderForWaveform

- (id) init
{
    self = [super init];
    getRatesFromDecodeStage = YES;
    return self;
}

- (void) dealloc
{
	[actualAcqirisDC440 release];
    [super dealloc];
}

//---------------------------------------------------------------
//Data format
/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^------------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^--length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
        ^ ^^^----------------------------crate
             ^ ^^^^----------------------card
					^^^^ ^^^^------------channel
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx --timeStamp Lo
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx --timeStamp Hi
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx --index offset To Valid Data
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx --number shorts in waveform
.. followed by n shorts and padded as
.. needed to the int32_t word boundary
.. at the end of the record

.. note that the data as read off the hardware contains up
   to 32 words that are not valid. The index offset lets
   you know where to start.
*/
//---------------------------------------------------------------

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
    uint32_t length = ExtractLength(*ptr);
	if(length==sizeof(Acquiris_OrcaWaveformStruct)/sizeof(int32_t))return length; //empty waveform

    ptr++;	//point to location
	unsigned char crate   = (*ptr&0x01e00000)>>21;
	unsigned char card    = (*ptr&0x001f0000)>>16;
	unsigned char channel = (*ptr&0x0000ff00)>>8;
	
	NSString* crateKey	  = [self getCrateKey: crate];
	NSString* cardKey	  = [self getCardKey: card];
	NSString* channelKey  = [self getChannelKey: channel];

    ptr++;	//point to timeLo
    ptr++;	//point to timeHi
    ptr++;	//point to valid data offset

	int32_t offsetToValidDataBytes = *ptr * sizeof(short);

    NSData* tmpData = [ NSData dataWithBytes: (char*) someData length: length*sizeof(int32_t) ];

    // Set up the waveform
    [ aDataSet loadWaveform: tmpData								//pass in the whole data set
                    offset: sizeof(Acquiris_OrcaWaveformStruct) +	//offset to the start of actual data (bytes!)
							offsetToValidDataBytes
				  unitSize: sizeof(short)							//unit size in bytes
                    sender: self 
                    withKeys: @"AcqirisDC440",crateKey,cardKey,channelKey,nil];
	

	//get the actual object
	if(getRatesFromDecodeStage && !skipRateCounts){
		NSString* acqirisKey = [crateKey stringByAppendingString:cardKey];
		if(!actualAcqirisDC440)actualAcqirisDC440 = [[NSMutableDictionary alloc] init];
		ORAcqirisDC440Model* obj = [actualAcqirisDC440 objectForKey:acqirisKey];
		if(!obj){
			NSArray* listOfCards = [[(ORAppDelegate*)[NSApp delegate] document] collectObjectsOfClass:NSClassFromString(@"ORAcqirisDC440Model")];
			NSEnumerator* e = [listOfCards objectEnumerator];
			ORAcqirisDC440Model* aCard;
			while(aCard = [e nextObject]){
				if( [aCard slot]+1 == card){
					[actualAcqirisDC440 setObject:aCard forKey:acqirisKey];
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
	ptr++;

    NSString* title= @"Acqiris DC440 Waveform Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate = %u\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Card  = %u\n",(*ptr&0x001f0000)>>16];
    NSString* chan  = [NSString stringWithFormat:@"Chan  = %u\n",(*ptr&0x0000ff00)>>8];

 	ptr++;
	NSString* timeLo  = [NSString stringWithFormat:@"Time Lo  = %u\n",*ptr];

 	ptr++;
	NSString* timeHi  = [NSString stringWithFormat:@"Time Hi  = %u\n",*ptr];

 	ptr++;
	NSString* numPoints = [NSString stringWithFormat:@"Num Points = %u\n",*ptr];

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@",title,crate,card,chan,timeLo,timeHi,numPoints];               
}

@end


