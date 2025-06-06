//
//  NcdMuxDecoders.m
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


#import "NcdMuxDecoders.h"
#import "NcdMuxModel.h"
#import "NcdMuxBoxModel.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"

#pragma mark •••Static Definitions
static NSString* kMuxBoxKey[8] = {
    //pre-make some keys for speed.
    @"Box 0",  @"Box 1",  @"Box 2",  @"Box 3",
    @"Box 4",  @"Box 5",  @"Box 6",  @"Box 7"
};

@implementation NcdMuxDecoderForMux
- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
   uint32_t* ptr = (uint32_t*)someData;
    uint32_t length;
    if(IsShortForm(*ptr)){
        length = 1;
    }
    else {
        ptr++; //int32_t version
        length = 2;
    }
    
    //mux event reg
    unsigned short chanHitMask = *ptr & 0x00000fff;
    short box = (*ptr>>kMuxBusNumberDataRecordShift) & 0x00000007;
    NSString* aKey = [self getMuxBoxKey:  box];
    int i;
    for(i=0;i<kNumMuxChannels;i++){
        if(chanHitMask&(1<<i)){
            [aDataSet loadGenericData:@"" sender:self withKeys:@"Mux",aKey,[NSString stringWithFormat:@"Channel %2d",i],nil];
        }
    }
    return length;    
}
- (NSString*) getMuxBoxKey:(unsigned short)aMuxBox
{
    if(aMuxBox<8) return kMuxBoxKey[aMuxBox];
    else return [NSString stringWithFormat:@"Box %d",aMuxBox];
}


- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    if(!IsShortForm(*ptr))ptr++;
    NSString* title= @"Mux Event Record\n\n";
    unsigned short chanHitMask = ptr[0] & 0x00000fff;
    NSString* box = [NSString stringWithFormat:@"Box      = %u\n",(ptr[0]>>kMuxBusNumberDataRecordShift) & 0x00000007];
    NSString* hit = [NSString stringWithFormat:@"Hit Mask = 0x%x\n",chanHitMask];
    NSString* subTitle = @"Channels Hit:\n";
    NSString* restOfString = [NSString string];
    int i;
    for(i=0;i<kNumMuxChannels;i++){
        if(chanHitMask&(1<<i)){
            restOfString = [restOfString stringByAppendingFormat:@"Chan %d\n",i];
        }
    }

    return [NSString stringWithFormat:@"%@%@%@%@%@",title,box,hit,subTitle,restOfString];
}

@end

@implementation NcdMuxDecoderForMuxEventReg

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr = (uint32_t*)someData;
    uint32_t length;
    if(IsShortForm(*ptr)){
        length = 1;
    }
    else {
        ptr++; //int32_t version
        length = 2;
    }
    
    //mux global reg
    [aDataSet loadGenericData:[NSString stringWithFormat:@"0x%08x",*ptr&0x0000ffff] sender:self withKeys:@"Mux Global Reg",nil];
    return length;
}
- (NSString*) getMuxBoxKey:(unsigned short)aMuxBox
{
    if(aMuxBox<8) return kMuxBoxKey[aMuxBox];
    else return [NSString stringWithFormat:@"Box %d",aMuxBox];
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"Mux Global Register Record\n\n";
    NSString* reg = [NSString stringWithFormat:@"Register = 0x%x\n",*ptr&0x0000ffff];

    return [NSString stringWithFormat:@"%@%@",title,reg];
}

@end

