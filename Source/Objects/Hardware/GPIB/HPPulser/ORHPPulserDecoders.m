//
//  ORHPPulserDecoders.m
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


#import "ORHPPulserDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"

@implementation ORHPPulserDecoderForPulserSettings
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long value = *((unsigned long*)someData);
    //for now, just return the length
    return ExtractLength(value);
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    union packed {
        unsigned long longValue;
        float floatValue;
    }packed;


    NSString* title= @"HP Pulser Record\n\n";
    
    NSString* waveForm  = [NSString stringWithFormat:@"Waveform    = %lu\n",ptr[1]];
    packed.longValue = ptr[2];
    NSString* voltage = [NSString stringWithFormat:  @"Voltage     = %.2f\n",packed.floatValue];
    packed.longValue = ptr[3];
    NSString* burstRate = [NSString stringWithFormat:@"Burst Rate  = %.2f\n",packed.floatValue];
    packed.longValue = ptr[4];
    NSString* width = [NSString stringWithFormat:@"Total Width = %.2f\n",packed.floatValue];

    return [NSString stringWithFormat:@"%@%@%@%@%@",title,waveForm,voltage,burstRate,width];               
}


@end
