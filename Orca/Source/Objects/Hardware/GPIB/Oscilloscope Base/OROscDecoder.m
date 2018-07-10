//
//  OROscDecoder.m
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


#import "OROscDecoder.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"


@implementation OROscDecoder

- (unsigned long) decodeData: (void*) aSomeData fromDecoder:(ORDecoder*)aDecoder intoDataSet: (ORDataSet*) aDataSet
{
    unsigned long* dataPtr;
    long offset;
    
    dataPtr = (unsigned long*) aSomeData; 
    
	long length 	= ExtractLength(*dataPtr);
	
	dataPtr++;
	offset = 8;   //bytes!
	
    // Header information
    short scope 	= ( *dataPtr >> 23 ) & 0xf;
    short channel 	= ( *dataPtr >> 19 ) & 0xf;

    NSData* tmpData = [ NSData dataWithBytes: (char*) aSomeData length: length*sizeof(long) ];

            
    // Set up the waveform
    [ aDataSet loadWaveform: tmpData	//pass in the whole data set
                    offset: offset		//offset to the start of actual data (bytes!)
				  unitSize: 1			//unit size in bytes
                    sender: self 
                    withKeys: [ NSString stringWithFormat: @"Scope %d", scope ],
                            [ NSString stringWithFormat: @"Channel %d", channel ],
                            nil];
                
    return length ; 
}

- (unsigned long) decodeGtId: (void*) aSomeData fromDecoder:(ORDecoder*)aDecoder intoDataSet: (ORDataSet*) aDataSet
{
    unsigned long* ptr = (unsigned long*)aSomeData;
    if(IsShortForm(*ptr)){
        return 1;
    }
    else {
        return 2;
    }
}

- (unsigned long) decodeClock: (void*) aSomeData fromDecoder:(ORDecoder*)aDecoder intoDataSet: (ORDataSet*) aDataSet
{
    return 3;
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Scope Data Record\n\n";

    NSString* scope = [NSString stringWithFormat:@"Scope = %lu (GPIB Address)\n",( ptr[1] >> 23 ) & 0xf];
    NSString* chan  = [NSString stringWithFormat:@"Chan  = %lu\n",( ptr[1] >> 19 ) & 0xf];
    NSString* length = [NSString stringWithFormat:@"%lu bytes of data follow\n",(ptr[0] & 0x3ffff)*sizeof(long)-8];

    return [NSString stringWithFormat:@"%@%@%@%@",title,scope,chan,length];
}

- (NSString*) dataGtIdDescription:(unsigned long*)ptr
{
    NSString* title= @"Scope GTID Record\n\n";
    if(!IsShortForm(*ptr))ptr++;
    NSString* gtid = [NSString stringWithFormat:@"GTID = %lu\n", *ptr & 0x003fffff];
    return [NSString stringWithFormat:@"%@%@",title,gtid];
}

- (NSString*) dataClockDescription:(unsigned long*)ptr
{
    NSString* title= @"Scope Clock Record\n\n";
    return [NSString stringWithFormat:@"%@Not Decoded",title];
}


@end
