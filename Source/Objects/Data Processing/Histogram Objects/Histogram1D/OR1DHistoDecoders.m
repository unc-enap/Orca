//
//  OR1DHistoDecoders.m
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


#import "OR1DHistoDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "OR1DHisto.h"

@implementation OR1DHistoDecoder

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr	 = (unsigned long*)someData;
    unsigned long length = ExtractLength(*ptr);

    ptr++; //point at the key length
    unsigned long keyLength = *ptr;
    
    ptr++; //point at the keys
    
    NSString* allKeys  = [NSString stringWithUTF8String:(const char*)ptr];
    NSArray*  keyArray = [allKeys componentsSeparatedByString:@"/"];
    ptr += keyLength; //point at the data length
    unsigned long numBins = *ptr;
    ptr++; //point at the histogram data
	
   [aDataSet loadHistogram:ptr numBins:numBins withKeyArray:keyArray];

    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{    
    NSString* title= @"1D Histogram Record\n\n";

    ptr++; //point at key block length;
    unsigned long keyLength = *ptr;
    ptr++;
    NSString* allKeys = [NSString stringWithUTF8String:(const char*)ptr];
    allKeys = [[allKeys componentsSeparatedByString:@"/"] componentsJoinedByString:@"\n"];
    ptr+=keyLength; //point at the histo length
    
    NSString* length = [NSString stringWithFormat:@"\nLength    = %lu\n",*ptr];
    
    return [NSString stringWithFormat:@"%@%@%@",title,allKeys,length];               
}


@end

