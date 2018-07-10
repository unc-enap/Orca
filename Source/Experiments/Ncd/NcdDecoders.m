//
//  NcdDecoders.m
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


#import "NcdDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"

@implementation NcdDecoderForPulserSettings

- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long value = *((unsigned long*)someData);
    return ExtractLength(value);
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    union packed {
        unsigned long longValue;
        float floatValue;
    }packed;


    NSString* title= @"HP Pulser Record\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:    @"GTID        = %lu\n",ptr[1]];
    NSString* waveForm  = [NSString stringWithFormat:@"Waveform    = %lu\n",ptr[2]];
    packed.longValue = ptr[3];
    NSString* voltage = [NSString stringWithFormat:  @"Voltage     = %.2f\n",packed.floatValue];
    packed.longValue = ptr[4];
    NSString* burstRate = [NSString stringWithFormat:@"Burst Rate  = %.2f\n",packed.floatValue];
    packed.longValue = ptr[5];
    NSString* width = [NSString stringWithFormat:    @"Total Width = %.2f\n",packed.floatValue];

    return [NSString stringWithFormat:@"%@%@%@%@%@%@",title,gtid,waveForm,voltage,burstRate,width];               
}


@end

@implementation NcdDecoderForLogAmpTask

- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long value = *((unsigned long*)someData);
    return ExtractLength(value);
}
- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"NCD LogAmp Task\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:    @"GTID  = %lu\n",ptr[1]];
    NSString* state = [NSString stringWithFormat:    @"State = %@\n",ptr[2]?@"Started":@"Stopped"];

    return [NSString stringWithFormat:@"%@%@%@",title,gtid,state];               
}
@end

@implementation NcdDecoderForLinearityTask

- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long value = *((unsigned long*)someData);
    return ExtractLength(value);
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"NCD Linearity Task\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:    @"GTID  = %lu\n",ptr[1]];
    NSString* state = [NSString stringWithFormat:    @"State = %@\n",ptr[2]?@"Started":@"Stopped"];

    return [NSString stringWithFormat:@"%@%@%@",title,gtid,state];               
}


@end

@implementation NcdDecoderForThresholdTask

- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long value = *((unsigned long*)someData);
    return ExtractLength(value);
}
- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"NCD Threshold Task\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:    @"GTID  = %lu\n",ptr[1]];
    NSString* state = [NSString stringWithFormat:    @"State = %@\n",ptr[2]?@"Started":@"Stopped"];

    return [NSString stringWithFormat:@"%@%@%@",title,gtid,state];               
}
@end

@implementation NcdDecoderForCableCheckTask

- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long value = *((unsigned long*)someData);
    return ExtractLength(value);
}
- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"NCD CableCheck Task\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:    @"GTID  = %lu\n",ptr[1]];
    NSString* state = [NSString stringWithFormat:    @"State = %@\n",ptr[2]?@"Started":@"Stopped"];

    return [NSString stringWithFormat:@"%@%@%@",title,gtid,state];               
}
@end

@implementation NcdDecoderForStepPDSTask

- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long value = *((unsigned long*)someData);
    return ExtractLength(value);
}
- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"NCD StepPDS Task\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:    @"GTID  = %lu\n",ptr[1]];
    NSString* state = [NSString stringWithFormat:    @"State = %@\n",ptr[2]?@"Started":@"Stopped"];

    return [NSString stringWithFormat:@"%@%@%@",title,gtid,state];               
}
@end

@implementation NcdDecoderForPulseChannelsTask

- (unsigned long) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    return ExtractLength(*((unsigned long*)someData));
}
- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"NCD Pulse Channels Task\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:    @"GTID  = %lu\n",ptr[1]];
    NSString* state = [NSString stringWithFormat:    @"State = %@\n",ptr[2]?@"Started":@"Stopped"];

    return [NSString stringWithFormat:@"%@%@%@",title,gtid,state];               
}
@end