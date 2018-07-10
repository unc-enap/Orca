//
//  ORTrigger32Decoders.m
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


#import "ORTrigger32Decoders.h"
#import "ORTrigger32Model.h"
#import "ORDataTypeAssigner.h"

@implementation ORTrigger32DecoderFor10MHzClockRecord
@end

@implementation ORTrigger32DecoderFor100MHzClockRecord
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long *ptr = (unsigned long*)someData;
    unsigned long length;
	ptr++;
	length = 3;
    
    if(*ptr & (1L<<24)){
        [aDataSet loadGenericData:@" " sender:self withKeys:@"Latched Clock",@"Evnt1 Clk",nil];
    }
    else if(*ptr & (1L<<25)){
        [aDataSet loadGenericData:@" " sender:self withKeys:@"Latched Clock",@"Evnt2 Clk",nil];
    }
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Trigger32 10MHz Clock Record\n\n";
    NSString* trigger = [NSString stringWithFormat:@"Trigger   = %d\n",(ptr[1]>>24)&0x1?1:2];
    NSString* upper   = [NSString stringWithFormat:@"Upper Reg = %lu\n",ptr[1]&0x00ffffff];
    NSString* lower   = [NSString stringWithFormat:@"Lower Reg = %lu\n",ptr[2]];

    return [NSString stringWithFormat:@"%@%@%@%@",title,trigger,upper,lower];
}


@end

@implementation ORTrigger32DecoderForGTID1Record
@end
@implementation ORTrigger32DecoderForGTID2Record
@end

@implementation ORTrigger32DecoderForGTIDRecord
- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    unsigned long length;
    if(IsShortForm(*ptr)){
        length = 1;
    }
    else {
        ptr++; //long version
        length = 2;
    }
    
    NSString* valueString = [NSString stringWithFormat:@"%lu",*ptr&0x00ffffff];
    if((*ptr>>24)&0x1){
        [aDataSet loadGenericData:valueString sender:self  withKeys:@"Latched Clock",@"GTID1",nil];
    }
    else {
        [aDataSet loadGenericData:valueString sender:self withKeys:@"Latched Clock",@"GTID2",nil];
    }

    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Trigger32 GTID Record\n\n";
    if(!IsShortForm(*ptr)){
        ptr++; //long version
    }
    NSString* trigger = [NSString stringWithFormat:@"Trigger = %u\n",(*ptr>>24)&0x1 ? 1 : 2];
    NSString* gtid    = [NSString stringWithFormat:@"GTID    = %lu\n",*ptr&0x00ffffff];

    return [NSString stringWithFormat:@"%@%@%@",title,trigger,gtid];
}
@end

@implementation ORTrigger32DecoderForLiveTime

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr = (unsigned long*)someData;
    unsigned long length = ExtractLength(ptr[0]);
	
    NSString* gtidString = [NSString stringWithFormat:@"%lu",ptr[1]];
    [aDataSet loadGenericData:gtidString sender:self withKeys:@"Latched Clock",@"Livetime", @"GTID",nil];
    
    
    total_live   = ((long long)ptr[3]&0x00000000000000ff)<<32 | ptr[4];
    trig1_live   = ((long long)ptr[3]&0x000000000000ff00)<<24 | ptr[5];
    trig2_live   = ((long long)ptr[3]&0x0000000000ff0000)<<16 | ptr[6];
    if(length==8)scope_live   = ((long long)ptr[3]&0x00000000ff000000)<<8  | ptr[7];
    
    NSString* totalString   = @"---";
    NSString* event1String  = @"---";
    NSString* event2String  = @"---";
    NSString* scopeString   = @"---";
    
    if(last_total_live){
        
        long long total_diff = total_live-last_total_live;
        long long trig1_diff = trig1_live-last_trig1_live;
        long long trig2_diff = trig2_live-last_trig2_live;
        long long scope_diff = scope_live-last_scope_live;
        
        //check for rollover
        if(total_diff<0)total_diff = 0xffffffffffffffffLL - (last_total_live - total_live);
        if(trig1_diff<0)trig1_diff = 0xffffffffffffffffLL - (last_trig1_live - trig1_live);
        if(trig2_diff<0)trig2_diff = 0xffffffffffffffffLL - (last_trig2_live - trig2_live);
        if(scope_diff<0)scope_diff = 0xffffffffffffffffLL - (last_scope_live - scope_live);
        
        totalString = [NSString stringWithFormat:@"%lld",total_diff];
        event1String = [NSString stringWithFormat:@"%lld (%.2f%%)",trig1_diff,total_diff==0?0:(10000*trig1_diff/total_diff)/100.];
        event2String = [NSString stringWithFormat:@"%lld (%.2f%%)",trig2_diff,total_diff==0?0:(10000*trig2_diff/total_diff)/100.];
        if(length==8)scopeString = [NSString stringWithFormat:@"%lld (%.2f%%)",scope_diff,total_diff==0?0:(10000*scope_diff/total_diff)/100.];
        
        last_total_live = 0;
        last_trig1_live = 0;
        last_trig2_live = 0;
        last_scope_live = 0;
        
    }
    [aDataSet loadGenericData:totalString sender:self withKeys:@"Latched Clock",@"Livetime", @"Total",nil];
    [aDataSet loadGenericData:event1String sender:self withKeys:@"Latched Clock",@"Livetime", @"Evnt1",nil];
    [aDataSet loadGenericData:event2String sender:self withKeys:@"Latched Clock",@"Livetime", @"Evnt2",nil];
    if(length==8)[aDataSet loadGenericData:scopeString sender:self withKeys:@"Latched Clock",@"Livetime", @"Scope",nil];
    
    
    last_total_live = total_live;
    last_trig1_live = trig1_live;
    last_trig2_live = trig2_live;
    last_scope_live = scope_live;
    
    
    return length;
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
    NSString* title= @"Trigger32 LiveTime Record\n\n";
    NSString* loc  = [NSString stringWithFormat:@"Crate = %lu Card = %lu\n",(ptr[2]>>8) & 0xf,ptr[2] & 0x0000001f];
    NSString* gtid = [NSString stringWithFormat:@"GTID  = %lu\n",ptr[1]];
    NSString* type;
    if(((ptr[2]>>16) & 0x3) == 3)        type = @"Type  = MidRun\n";
    else if(((ptr[2]>>16) & 0x3) == 1)   type = @"Type  = Start\n";
    else                                 type = @"Type  = End\n";
    
    long long total_   = ((long long)ptr[3]&0x00000000000000ff)<<32 | ptr[4];
    long long trig1_   = ((long long)ptr[3]&0x000000000000ff00)<<24 | ptr[5];
    long long trig2_   = ((long long)ptr[3]&0x0000000000ff0000)<<16 | ptr[6];
    long long scope_   = ((long long)ptr[3]&0x00000000ff000000)<<8  | ptr[7];

    NSString* subtitle= @"\nLive Time Registers\n\n";
    NSString* total= [NSString stringWithFormat:@"Total = %lld\n",total_];
    NSString* trig1= [NSString stringWithFormat:@"Trig1 = %lld\n",trig1_];
    NSString* trig2= [NSString stringWithFormat:@"Trig2 = %lld\n",trig2_];
    NSString* scope= [NSString stringWithFormat:@"Scope = %lld\n",scope_];

    return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@",title,loc,gtid,type,subtitle,total,trig1,trig2,scope];
}

@end
