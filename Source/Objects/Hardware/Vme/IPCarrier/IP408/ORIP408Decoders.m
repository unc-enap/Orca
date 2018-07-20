//
//  ORIP408Decoders.m
//  Orca
//
//  Created by Mark Howe on Tue Mar 31,2009.
//  Copyright 2009 CENPA, University of Washington. All rights reserved.
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


#import "ORIP408Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"
#import "ORIP408Model.h"

/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 --------^-^^^--------------------------- Crate number
 -------------^-^^^^--------------------- Card number
 -----------------------------------^^^^- Channel number
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -Unix Time (seconds from 1970)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -Write Mask
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -Read Mask
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -Write Value
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx -Read Value
*/

static NSString* kIPSlotKey[4] = {
		@"IP D",
		@"IP C",
		@"IP B",
		@"IP A"
};
@implementation ORIP408DecoderForValues

- (NSString*) getSlotKey:(unsigned short)aSlot
{
	if(aSlot<4) return kIPSlotKey[aSlot];
	else return [NSString stringWithFormat:@"IP %2d",aSlot];		
}

- (uint32_t) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    uint32_t* ptr	 = (uint32_t*)someData;
    uint32_t length = ExtractLength(*ptr);
	//we don't do anything with these values (at least for now)
    return length; //must return number of longs processed.
}

- (NSString*) dataRecordDescription:(uint32_t*)ptr
{
    NSString* title= @"IP408 Value Record\n\n";

	ptr++;
    NSString* crate			= [NSString stringWithFormat:@"Crate = %u\n",(*ptr&0x01e00000)>>21];
    NSString* card			= [NSString stringWithFormat:@"Card  = %u\n",(*ptr&0x001f0000)>>16];
	NSString* ipSlotKey		= [NSString stringWithFormat:@"IP    = %@\n",[self getSlotKey:*ptr&0x0000000f]];

	ptr++;
	NSDate* date = [NSDate dateWithTimeIntervalSince1970:*ptr];

    NSString* s = [NSString stringWithFormat:@"%@%@%@%@%@",title,crate,card,ipSlotKey,[date descriptionFromTemplate:@"MM/dd/yy HH:mm:ss z\n"]];
	ptr++;  s = [s stringByAppendingFormat:@"WriteMask : 0x%08X\n",*ptr];
	ptr++;  s = [s stringByAppendingFormat:@"ReadMask  : 0x%08X\n",*ptr];
	ptr++;  s = [s stringByAppendingFormat:@"WriteValue: 0x%08X\n",*ptr];
	ptr++;  s = [s stringByAppendingFormat:@"ReadValue : 0x%08X\n",*ptr];

    return s;               
}

@end

