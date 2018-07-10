//
//  OR4ChanTriggerDecoders.m
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


#import "OR4ChanTriggerDecoders.h"
#import "OR4ChanTriggerModel.h"
#import "ORDataTypeAssigner.h"

NSString* chan4TriggerEventName[4] = {
    @"Event 1 Clk",
    @"Event 2 Clk",
    @"Event 3 Clk",
    @"Event 4 Clk",
};

@implementation OR4ChanTriggerDecoderFor100MHzClock
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long *ptr	 = (unsigned long*)someData;
    unsigned long length = ExtractLength(*ptr);
    ptr++;
    unsigned long value = *ptr;
    int index = (value >> 24) & 0x7;
    if(index < 4){
        [aDataSet loadGenericData:@" " sender:self withKeys:@"Four Chan Latched Clock",chan4TriggerEventName[index],nil];
    }
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Trigger Clock Record\n\n";
    ptr++;
    unsigned long upperClock = *ptr & 0x00ffffff;
    int index = (*ptr >> 24) & 0x7;
    NSString* name;
    if(index<4){
        name = [NSString stringWithFormat:@"%@\n",chan4TriggerEventName[index]];
    }
    else {
        name = [NSString stringWithFormat:@"Out of bounds index: %d\n",index];
    }
    NSString* upper = [NSString stringWithFormat:@"Upper Clock: %lu\n",upperClock];

    ptr++;
    NSString* lower = [NSString stringWithFormat:@"Lower Clock: %lu\n",*ptr];

    return [NSString stringWithFormat:@"%@%@%@%@",title,name,upper,lower];               
}

@end
