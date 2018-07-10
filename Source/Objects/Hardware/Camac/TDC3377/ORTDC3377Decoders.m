//
//  ORTDC3377Decoders.m
//  Orca
//
//  Created by Mark Howe on 8/5/05.
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


#import "ORTDC3377Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORTDC3377Model.h"

@implementation ORTDC3377DecoderForTDC

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

//---------------------------------------------------------------
//Data format
/*
xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^-----------------------data id
                 ^^ ^^^^ ^^^^ ^^^^ ^^^^-length in longs

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
       ^--------------------------------1 = double word timestamp, 0 = single word timestamp (that was bogus coding)
        ^ ^^^---------------------------crate
             ^ ^^^^---------------------card
                    ^^^^ ^^^^ ^^^^ ^^^^-numDataWords (16 bit), see below

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^-reference date (high part of double)

xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^ ^^^^-reference date (low part of double)

The rest of the record consists of a 16 bit Header Word followed by
numDataWords data words:

1xxx xxxx xxxx xxxx Header Word (highest bit set)
 ^------------------0=short word format, 1=double word format
      ^-------------0=leading edge only, 1=leading and trailing edge

if single word format and leading edge only:
0xxx xxxx xxxx xxxx Data Word (highest bit NOT set)
 ^^^ ^^-------------channel
       ^^ ^^^^ ^^^^-data value

if single word format and leading and trailing edge
0xxx xxxx xxxx xxxx  Data Word (highest bit NOT set)
 ^^^ ^^-------------channel
       ^------------0=leading edge, 1=trailing edge
        ^ ^^^^ ^^^^-data value

if double word format
0xxx xxx1 xxxx xxxx 1st Data Word (highest bit NOT set, 9th bit set)
 ^^^ ^^-------------channel
       ^------------0=leading edge, 1=trailing edge
        ^-----------0=second word, 1=first word
          ^^^^ ^^^^-high part

0xxx xxx0 xxxx xxxx 2nd Data Word (highest bit NOT set, 9th bit NOT set)
 ^^^ ^^-------------channel
       ^------------0=leading edge, 1=trailing edge
        ^-----------0=second word, 1=first word
          ^^^^ ^^^^-low part
*/
//--------------------------------------------------------------------


- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
 
    //word 0 -- the dataID and the total length in longs
    unsigned long length = ExtractLength(ptr[0]); //get the length
	//word 1 -- crate, card, and number of datawords following
	unsigned char version = (ptr[1]>>25) & 0x1;
	unsigned char crate  = (ptr[1]>>21) & 0xf;
	unsigned char card   = (ptr[1]>>16) & 0x1f;
    unsigned short numDataWords = ptr[1] & 0x0000ffff;
	//word 2 (and 3 for version 1) ref date word(s)--skip
	int headerIndex = 3;				//header starts at 3
	if(version == 1) headerIndex = 4;	//header starts at 4
	
	unsigned short* headerPtr = (unsigned short*)(&ptr[headerIndex]); //recast the ptr for shorts
	
    if(*headerPtr & 0x8000){ //make sure it's really a header word
        //word 2 -- data record header from hw, tells us the format 
        BOOL leadingAndTrailingEdge = (*headerPtr>>10) & 0x1;
        BOOL doubleWordFormat       = (*headerPtr>>14) & 0x1;

        NSString* crateKey = [self getCrateKey: crate];
        NSString* cardKey = [self getStationKey: card];

        //decode the rest, skipping over the orca header and the data header parts.
        //first recast the data ptr to a short
        unsigned short *dataPtr = (unsigned short*)(&headerPtr[1]);
        int i;
        for(i=0;i<numDataWords;i++){
            if(dataPtr[i] & ~0x8000){
                NSString* channelKey = [self getChannelKey: (dataPtr[i]>>10) & 0x1f];
           
                if(doubleWordFormat){
                    //decode the first word
                    //verify that it really is the first word
                    if((dataPtr[i]>>8) & 0x1){
                        unsigned short highWord = dataPtr[i]&0xff;
                    
                        i++; //go to next word
                        //verify that it really is the second word
                        if(i <numDataWords && !((dataPtr[i]>>8) & 0x1)){
                            unsigned short lowWord = dataPtr[i]&0xff;
                            [aDataSet histogram:(highWord<<8 | lowWord) numBins:65536 sender:self  withKeys:@"TDC3377", crateKey,cardKey,channelKey,nil];
                       
                        }
                        else break;
                    }
                    else break;
                }
                else {
                    unsigned short value;
                    if(!leadingAndTrailingEdge){
                        value = dataPtr[i]& 0x3ff;
                    }
                    else {
                         value = dataPtr[i]& 0x1ff;
                    }
                    [aDataSet histogram:value numBins:1024 sender:self  withKeys:@"TDC3377", crateKey,cardKey,channelKey,nil];
                }
            }
            else break;
        }
    }
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)someData
{
    
    NSMutableString* totalString = [NSMutableString stringWithCapacity:1024];
    [totalString appendString:@"TDC3377 TDC\n\n"]; 

    unsigned long* ptr = (unsigned long*)someData;
    
	[totalString appendString:[NSString stringWithFormat:@"Crate    = %lu\n",(ptr[1]>>21) & 0xf]];
    [totalString appendString:[NSString stringWithFormat:@"Station  = %lu\n",(ptr[1]>>16) & 0x1f]];
	unsigned char version = (ptr[1]>>25) & 0x1;
 
    //word 0 -- the dataID and the total length in longs
	//word 1 -- crate, card, and number of datawords following
    unsigned short numDataWords = ptr[1] & 0x0000ffff;
	//word 2 -- event time as number secs since ref date (float)
	int headerIndex = 3;
	if(version == 1){
		union {
			NSTimeInterval asTimeInterval;
			unsigned long asLongs[2];
		}theTimeRef;
		theTimeRef.asLongs[1] = ptr[2];
		theTimeRef.asLongs[0] = ptr[3];
		NSDate* theTime   = [NSDate dateWithTimeIntervalSinceReferenceDate:theTimeRef.asTimeInterval];

		[totalString appendString:[NSString stringWithFormat:@"timeStamp  = %@\n",theTime]];
		[totalString appendString:[NSString stringWithFormat:@"(in secs)  = %f\n",theTimeRef.asTimeInterval]];
		headerIndex = 4;
	}
	
	
	unsigned short* headerPtr = (unsigned short*)(&ptr[headerIndex]); //recast the ptr for shorts

    if(*headerPtr & 0x8000){ //make sure it's really a header word
        //word 2 -- data record header from hw, tells us the format 
        BOOL leadingAndTrailingEdge = (*headerPtr>>10) & 0x1;
        BOOL doubleWordFormat       = (*headerPtr>>14) & 0x1;
        [totalString appendString:[NSString stringWithFormat:@"Edge    = %@\n",leadingAndTrailingEdge?@"Both":@"Leading"]];
        [totalString appendString:[NSString stringWithFormat:@"Format  = %@\n",doubleWordFormat?@"Double Word":@"Single"]];

        //decode the rest, skipping over the orca header and the data header parts.
        //first recast the data ptr to a short
        unsigned short *dataPtr = (unsigned short*)(&headerPtr[1]);
        int i;
        for(i=0;i<numDataWords;i++){
            if(dataPtr[i] & ~0x8000){
                [totalString appendString:[NSString stringWithFormat:@"Chan    = %d\n",(dataPtr[i]>>10) & 0x1f]];

           
                if(doubleWordFormat){
                    //decode the first word
                    //verify that it really is the first word
                    if((dataPtr[i]>>8) & 0x1){
                        unsigned short highWord = dataPtr[i]&0xff;
                    
                        i++; //go to next word
                        //verify that it really is the second word
                        if(i <numDataWords && !((dataPtr[i]>>8) & 0x1)){
                            unsigned short lowWord = dataPtr[i]&0xff;
                            [totalString appendString:[NSString stringWithFormat:@"Value   = %d\n",highWord<<8 | lowWord]];

                        }
                        else break;
                    }
                    else break;
                }
                else {
                    unsigned short value;
                    if(leadingAndTrailingEdge){
							value = dataPtr[i]& 0x1ff;

                    }
                    else {
							value = dataPtr[i]& 0x3ff;

                    }
                    [totalString appendString:[NSString stringWithFormat:@"Value   = %d\n",value]];
                }
            }
            else break;
        }
    }
    return totalString;               
}


@end

