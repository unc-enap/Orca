//
//  ORL2551Decoders.m
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


#import "ORL2551Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORL2551Model.h"
#import "ORDataTypeAssigner.h"
#import "ORValueBarGroupView.h"

@implementation ORL2551DecoderForScalers

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
    unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(ptr[0]);
    
	unsigned char crate   = (ptr[1]>>16)&0xf;
	unsigned char card    = ptr[1] & 0x001f;
    int i;
    for(i=0;i<12;i++){
        unsigned char channel = (ptr[2+i]>>28) & 0xf;
        NSString* crateKey = [self getCrateKey: crate];
        NSString* cardKey = [self getStationKey: card];
        NSString* channelKey = [self getChannelKey: channel];
        unsigned long scalerValue = ptr[2+i]&0x00ffffff;
        NSString* scaler = [NSString stringWithFormat:@"%lu",scalerValue];
        [aDataSet loadGenericData:scaler sender:self withKeys:@"Scalers",@"LS2551", crateKey,cardKey,channelKey,nil];
        [aDataSet loadScalerSum:scalerValue sender:self withKeys:@"Scaler Sums",@"LS2551", crateKey,cardKey,channelKey,nil];
	}
    
    return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)someData
{
    
    NSString* title= @"L2551 Scaler Sum\n\n";

    unsigned long* ptr = (unsigned long*)someData;
    
	NSString* crate = [NSString stringWithFormat:@"Crate    = %lu\n",(ptr[1]>>16)&0xf];
    NSString* card  = [NSString stringWithFormat:@"Station  = %lu\n",ptr[1] & 0x001f];
    NSString* totalString = [NSString stringWithFormat:@"%@%@%@\nScaler Sum\n",title,crate,card];
    ptr+=2;
    int i;
    for(i=0;i<12;i++){
        totalString = [totalString stringByAppendingFormat:@"%2lu: %10lu\n",(ptr[i]>>28) & 0xf,ptr[i]&0x00ffffff];
    }
    
    return totalString;               
}


@end

