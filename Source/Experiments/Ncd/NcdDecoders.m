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

- (uint32_t) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t value = *((uint32_t*)someData);
    return ExtractLength(value);
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    union packed {
        uint32_t longValue;
        float floatValue;
    }packed;


    NSString* title= @"HP Pulser Record\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:    @"GTID        = %u\n",ptr[1]];
    NSString* waveForm  = [NSString stringWithFormat:@"Waveform    = %u\n",ptr[2]];
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

- (uint32_t) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t value = *((uint32_t*)someData);
    return ExtractLength(value);
}
- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"NCD LogAmp Task\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:    @"GTID  = %u\n",ptr[1]];
    NSString* state = [NSString stringWithFormat:    @"State = %@\n",ptr[2]?@"Started":@"Stopped"];

    return [NSString stringWithFormat:@"%@%@%@",title,gtid,state];               
}
@end

@implementation NcdDecoderForLinearityTask

- (uint32_t) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t value = *((uint32_t*)someData);
    return ExtractLength(value);
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"NCD Linearity Task\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:    @"GTID  = %u\n",ptr[1]];
    NSString* state = [NSString stringWithFormat:    @"State = %@\n",ptr[2]?@"Started":@"Stopped"];

    return [NSString stringWithFormat:@"%@%@%@",title,gtid,state];               
}


@end

@implementation NcdDecoderForThresholdTask

- (uint32_t) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t value = *((uint32_t*)someData);
    return ExtractLength(value);
}
- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"NCD Threshold Task\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:    @"GTID  = %u\n",ptr[1]];
    NSString* state = [NSString stringWithFormat:    @"State = %@\n",ptr[2]?@"Started":@"Stopped"];

    return [NSString stringWithFormat:@"%@%@%@",title,gtid,state];               
}
@end

@implementation NcdDecoderForCableCheckTask

- (uint32_t) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t value = *((uint32_t*)someData);
    return ExtractLength(value);
}
- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"NCD CableCheck Task\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:    @"GTID  = %u\n",ptr[1]];
    NSString* state = [NSString stringWithFormat:    @"State = %@\n",ptr[2]?@"Started":@"Stopped"];

    return [NSString stringWithFormat:@"%@%@%@",title,gtid,state];               
}
@end

@implementation NcdDecoderForStepPDSTask

- (uint32_t) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t value = *((uint32_t*)someData);
    return ExtractLength(value);
}
- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"NCD StepPDS Task\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:    @"GTID  = %u\n",ptr[1]];
    NSString* state = [NSString stringWithFormat:    @"State = %@\n",ptr[2]?@"Started":@"Stopped"];

    return [NSString stringWithFormat:@"%@%@%@",title,gtid,state];               
}
@end

@implementation NcdDecoderForPulseChannelsTask

- (uint32_t) decodeData:(void*)someData  fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    return ExtractLength(*((uint32_t*)someData));
}
- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"NCD Pulse Channels Task\n\n";
    
    NSString* gtid  = [NSString stringWithFormat:    @"GTID  = %u\n",ptr[1]];
    NSString* state = [NSString stringWithFormat:    @"State = %@\n",ptr[2]?@"Started":@"Stopped"];

    return [NSString stringWithFormat:@"%@%@%@",title,gtid,state];               
}
@end
