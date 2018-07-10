//
//  ORSIS3801Decoders.m
//  Orca
//
//  Created by Mark A. Howe on Thursday 6/9/11.
//  Copyright (c) 2011 CENPA. University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of 
//North Carolina  sponsored in part by the United States 
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020. 
//The University has certain rights in the program pursuant to 
//the contract and the program should not be copied or distributed 
//outside your organization.  The DOE and the University of 
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty, 
//express or implied, or assume any liability or responsibility 
//for the use of this software.
//-------------------------------------------------------------

#import "ORSIS3801Decoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORDataTypeAssigner.h"

/*
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 ^^^^ ^^^^ ^^^^ ^^----------------------- Data ID (from header)
 -----------------^^ ^^^^ ^^^^ ^^^^ ^^^^- length
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx
 --------^-^^^--------------------------- Crate number
 -------------^-^^^^--------------------- Card number
 --------------------------------------^- 1==SIS38020, 0==SIS3000 
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  time read in seconds since Jan 1, 1970
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  last time read in seconds since Jan 1, 1970 (zero if first sample)
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  count enabled mask
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  overFlow mask
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  options
 -------------------------------------^^- lemo in mode
 ------------------------------------^--- enable25MHzPulses
 -----------------------------------^---- enableInputTestMode
 ---------------------------------^------ enableReferencePulser
 --------------------------------^------- clearOnRunStart
 -------------------------------^-------- enable25MHzPulses
 ------------------------------^--------- syncWithRun
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counts for chan 1
 ..
 ..
 xxxx xxxx xxxx xxxx xxxx xxxx xxxx xxxx  counts for chan 32

 */

@implementation ORSIS3801DecoderForCounts

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
    unsigned long* ptr    = (unsigned long*)someData; 
	unsigned long  length = ExtractLength(ptr[0]);

	short crate    = ShiftAndExtract(ptr[1],21,0xf);
	short card     = ShiftAndExtract(ptr[1],16,0x1f);
	NSString* module = (ptr[1]&0x1)?@"SIS3820":@"SIS3801";
	NSString* crateKey	= [self getCrateKey: crate];
	NSString* cardKey	= [self getCardKey: card];
	
	int i;
	for(i=0;i<32;i++){
		NSString* scalerValue = [NSString stringWithFormat:@"%u",ptr[7+i]];
		NSString* channelKey	= [self getCardKey: i];

		[aDataSet loadGenericData:scalerValue sender:self withKeys:@"Scalers",module, crateKey,cardKey,channelKey,nil];
	}
	
	return length; //must return number of longs
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	NSString* s = @"";
	s = [s stringByAppendingString: @"SIS3801 Scaler Record\n\n"];
	s = [s stringByAppendingFormat:@"Crate = %d\n",ShiftAndExtract(ptr[1],21,0xf)];
	s = [s stringByAppendingFormat:@"Card  = %d\n",ShiftAndExtract(ptr[1],16,0x1f)];
	s = [s stringByAppendingString:(ptr[1]&0x1)?@"SIS3820\n":@"SIS3801\n"];

	NSCalendarDate* date;	 
	date= [NSCalendarDate dateWithTimeIntervalSince1970:(NSTimeInterval)ptr[2]];
	[date setCalendarFormat:@"%m/%d/%y %H:%M:%S"];
	s = [s stringByAppendingFormat:@"This Read: %@\n",date];
	
	date = [NSCalendarDate dateWithTimeIntervalSince1970:(NSTimeInterval)ptr[3]];
	[date setCalendarFormat:@"%m/%d/%y %H:%M:%S"];
	s = [s stringByAppendingFormat:@"Last Read: %@\n",date];
		 
	s = [s stringByAppendingFormat:@"Enabled  Mask: 0x%08x\n",ptr[4]];
	s = [s stringByAppendingFormat:@"OverFlow Mask: 0x%08x\n",ptr[5]];
	
	s = [s stringByAppendingFormat:@"LemoInMod: %d\n",ShiftAndExtract(ptr[6],0,0x3)];
	s = [s stringByAppendingFormat:@"25MHz Pulses Enabled: %@\n",ShiftAndExtract(ptr[6],3,0x1)?@"YES":@"NO"];
	s = [s stringByAppendingFormat:@"Input Test Mode Enabled: %@\n",ShiftAndExtract(ptr[6],4,0x1)?@"YES":@"NO"];
	s = [s stringByAppendingFormat:@"Ref Pulser Enabled: %@\n",ShiftAndExtract(ptr[6],5,0x1)?@"YES":@"NO"];
	s = [s stringByAppendingFormat:@"Clear On Run Start: %@\n",ShiftAndExtract(ptr[6],6,0x1)?@"YES":@"NO"];
	s = [s stringByAppendingFormat:@"Sync With Run Start: %@\n",ShiftAndExtract(ptr[6],7,0x1)?@"YES":@"NO"];

	s = [s stringByAppendingString:@"Counts:\n"];
	
	int i;
	for(i=0;i<32;i++){
		s = [s stringByAppendingFormat:@"%2d: %u\n",i,ptr[7+i]];
	}
	

    return s;               
}

@end
