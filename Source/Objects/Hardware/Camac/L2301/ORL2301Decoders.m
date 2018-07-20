//
//  ORAD811Decoders.m
//  Orca
//
//  Created by Sam Meijer, Jason Detwiler, and David Miller, July 2012.
//  Adapted from AD811 code by Mark Howe, written 9/21/04.
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


#import "ORL2301Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORL2301Model.h"
#import "ORDataTypeAssigner.h"

@implementation ORL2301DecoderForHist

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
    if(IsShortForm(*ptr)) {
    	NSLog(@"L2301 Card Warning: should not get short form; quitting...");
        return 1;
    }
    else  {       //oh, we have been assign the int32_t form--skip to the next int32_t word for the data
        length = ExtractLength(*ptr);
        ptr++;
    }

    unsigned char crate   = (*ptr&0x01e00000)>>21;
    unsigned char card   = (*ptr& 0x001f0000)>>16;
    NSString* crateKey = [self getCrateKey: crate];
    NSString* cardKey = [self getStationKey: card];
	
    uint32_t headerSize = 2;
    bool hasTiming = (*ptr&0x02000000);
    if(hasTiming) {
		ptr += 2;
		headerSize = 4;
    }
    if(length < headerSize) {
    	NSLog(@"L2301 Card Warning: got length < headerSize...");
        return length;
    }
    if(length == headerSize) return length;
    	
    uint32_t nBins = length-headerSize;
    unsigned int iBin;
    for(iBin = 0; iBin < nBins; iBin++) {
        ptr++;
		uint32_t  bin = (*ptr&0xffff0000) >> 16;
		uint32_t  value = *ptr&0x0000ffff;
		[aDataSet histogramWW:bin weight:value numBins:1024 sender:self withKeys:@"L2301", crateKey,cardKey,nil,nil];
    }
	
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    uint32_t length = ExtractLength(*ptr);
    if(!IsShortForm(*ptr)){
        ptr++; //now p[0] is the word with the location (short -or- int32_t form
    }
	
    NSString* crate = [NSString stringWithFormat:@"Crate    = %u\n",(ptr[0]&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Station  = %u\n",(ptr[0]&0x001f0000)>>16];
	
    uint32_t headerSize = 2;
    bool hasTiming = (*ptr&0x02000000);
    if(hasTiming) {
		ptr += 2;
		headerSize = 4;
    }
	
    uint32_t nBins = length-headerSize;
    NSString* nBinsStr = [NSString stringWithFormat:@"NBins    = %u\n", nBins];
	
    unsigned int counts = 0;
    unsigned int iBin;
    for(iBin = 0; iBin < nBins; iBin++) {
		counts += *ptr&0x0000ffff;
		ptr++;
    }
    NSString* countsStr = [NSString stringWithFormat:@"Counts   = %d\n", counts];
    
    NSString* title= @"L2301 Hist Record\n\n";
    
    NSDate* theTime = nil;
	
    if(hasTiming){
        ptr -= (nBins+2);
    	union {
    	    NSTimeInterval asTimeInterval;
    	    uint32_t asLongs[2];
    	} theTimeRef;
    	theTimeRef.asLongs[1] = ptr[1];
    	theTimeRef.asLongs[0] = ptr[2];
    	
    	theTime   = [NSDate dateWithTimeIntervalSinceReferenceDate:theTimeRef.asTimeInterval];
    	NSString* inSec = [NSString stringWithFormat:@"\n(%.3f secs)\n",theTimeRef.asTimeInterval];
    	return [NSString stringWithFormat:@"%@%@%@%@%@\nTimeStamp:\n%@%@\n",title,crate,card,nBinsStr,countsStr,[theTime descriptionFromTemplate:@"MM/dd/yy HH:mm:SSS"],inSec];
    	
    }
	
	
    else return [NSString stringWithFormat:@"%@%@%@%@%@\n",title,crate,card,nBinsStr,countsStr];               
}


@end

