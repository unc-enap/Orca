//
//  ORTRS1Decoders.m
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


#import "ORTRS1Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORTRS1Model.h"
#import "ORDataTypeAssigner.h"


@implementation OR8818DecoderForWaveform

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (unsigned long) decodeData:(void*)aSomeData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr   = (unsigned long*)aSomeData;
	unsigned long length = ExtractLength(*ptr);

	ptr++; //point to the location word
    
	unsigned char crate = (*ptr&0x01e00000)>>21;
	unsigned char card  = (*ptr& 0x001f0000)>>16;
	NSString* crateKey	= [self getCrateKey: crate];
	NSString* cardKey	= [self getStationKey: card];

    NSData* tmpData = [ NSData dataWithBytes: (char*) aSomeData length: length*sizeof(long) ];

    // Set up the waveform
    [ aDataSet loadWaveform: tmpData		//pass in the whole data set
                    offset: 3*sizeof(long)	//offset to the start of actual data (bytes!)
				  unitSize: 1				//unit size in bytes
                    sender: self 
				  withKeys:	crateKey,
							cardKey,
							nil];
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	ptr++;
    
    NSString* title= @"8818 Digitizer Record\n\n";
    
    NSString* crate = [NSString stringWithFormat:@"Crate    = %lu\n",(*ptr&0x01e00000)>>21];
    NSString* card  = [NSString stringWithFormat:@"Station  = %lu\n",(*ptr&0x001f0000)>>16];
    return [NSString stringWithFormat:@"%@%@%@",title,crate,card];               
}


@end

