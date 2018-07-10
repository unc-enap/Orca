//
//  ORAD413ADecoders.m
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


#import "ORAD413ADecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORAD413AModel.h"
#import "ORDataTypeAssigner.h"

@implementation ORAD413ADecoderForAdc

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long length;
    unsigned long* ptr = (unsigned long*)someData;
    if(IsShortForm(*ptr)){
        length = 1;
    }
    else  {       //oh, we have been assign the long form--skip to the next long word for the data
        ptr++;
        length = 2;
    }
    
	unsigned char crate   = (*ptr>>21) & 0xf;
	unsigned char card   = (*ptr>>16)  & 0x1f;
	unsigned char channel = (*ptr>>13) & 0x3;
	NSString* crateKey = [self getCrateKey: crate];
	NSString* cardKey = [self getStationKey: card];
	NSString* channelKey = [self getChannelKey: channel];
    unsigned long  value = *ptr&0x00001fff;
	
    [aDataSet histogram:value numBins:8064 sender:self  withKeys:@"AD413A", crateKey,cardKey,channelKey,nil];

    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    if(!IsShortForm(*ptr)){
        ptr++;
    }
    
    NSString* title= @"AD413A ADC Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate    = %lu\n",(*ptr>>21) & 0xf];
    NSString* card  = [NSString stringWithFormat:@"Station  = %lu\n",(*ptr>>16)  & 0x1f];
    NSString* chan  = [NSString stringWithFormat:@"Chan     = %lu\n",(*ptr>>13) & 0x3];
    NSString* adc   = [NSString stringWithFormat:@"ADC      = 0x%lx\n",*ptr&0x00001fff];
    
    return [NSString stringWithFormat:@"%@%@%@%@%@",title,crate,card,chan,adc];               
}


@end

