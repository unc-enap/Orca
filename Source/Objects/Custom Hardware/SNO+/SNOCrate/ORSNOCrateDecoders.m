//
//  ORSNOCrateDecoders.m
//  Orca
//
//Created by Jarek Kaspar on Wed, April 21, 2010
//Copyright (c) 2010 CENPA, University of Washington. All rights reserved.
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


#import "ORSNOCrateDecoders.h"
#import "ORDataPacket.h"
#import "ORDataSet.h"
#import "ORSNOCrateModel.h"
#import "ORDataTypeAssigner.h"

@implementation ORSNOCrateDecoderForPMT

- (unsigned long) decodeData:(void*)someData fromDecoder:(ORDecoder*)aDecoder intoDataSet:(ORDataSet*)aDataSet
{
	unsigned long* ptr = (unsigned long*)someData;
	unsigned long length = ExtractLength(*ptr);
	return length; //must return number of bytes processed.
}

- (NSString*) dataRecordDescription:(unsigned long*)ptr
{
	ptr++;
	NSString* sGTId = [NSString stringWithFormat:@"GTId = 0x%06lx\n",
		(*ptr & 0x0000ffff) | ((ptr[2] << 4) & 0x000f0000) | ((ptr[2] >> 8) & 0x00f00000)];
	NSString* sCrate = [NSString stringWithFormat:@"Crate = %lu\n", (*ptr >> 21) & 0x1fUL];
	NSString* sBoard = [NSString stringWithFormat:@"Board = %lu\n", (*ptr >> 26) & 0x0fUL];
	NSString* sChannel = [NSString stringWithFormat:@"Channel = %lu\n", (*ptr >> 16) & 0x1fUL];
	NSString* sCell = [NSString stringWithFormat:@"Cell = %lu\n", (ptr[1] >> 12) & 0x0fUL];
	NSString* sQHL = [NSString stringWithFormat:@"QHL = 0x%03lx\n", ptr[2] & 0x0fffUL ^ 0x0800UL];
	NSString* sQHS = [NSString stringWithFormat:@"QHS = 0x%03lx\n", (ptr[1] >> 16) & 0x0fffUL ^ 0x0800UL];
	NSString* sQLX = [NSString stringWithFormat:@"QLX = 0x%03lx\n", ptr[1] & 0x0fffUL ^ 0x0800UL];
	NSString* sTAC = [NSString stringWithFormat:@"TAC = 0x%03lx\n", (ptr[2] >> 16) & 0x0fffUL ^ 0x0800UL];
	NSString* sCGT16 = [NSString stringWithFormat:@"CGT16 sync error: %@\n",
		((*ptr >> 30) & 0x1UL) ? @"Yes" : @"No"];
	NSString* sCGT24 = [NSString stringWithFormat:@"CGT24 sync error: %@\n",
		((*ptr >> 31) & 0x1UL) ? @"Yes" : @"No"];
	NSString* sES16 = [NSString stringWithFormat:@"CMOS16 sync error: %@\n",
		((ptr[1] >> 31) & 0x1UL) ? @"Yes" : @"No"];
	NSString* sMissed = [NSString stringWithFormat:@"Missed count error: %@\n",
		((ptr[1] >> 28) & 0x1UL) ? @"Yes" : @"No"];
	NSString* sNC = [NSString stringWithFormat:@"NC / CC flag: %@\n",
		((ptr[1] >> 29) & 0x1UL) ? @"CC" : @"NC"];
	NSString* sLGI = [NSString stringWithFormat:@"LGI select: %@\n",
		((ptr[1] >> 30) & 0x1UL) ? @"Long" : @"Short"];
	NSString* sWrd0 = [NSString stringWithFormat:@"Wrd0 = 0x%08lx\n", *ptr];
	NSString* sWrd1 = [NSString stringWithFormat:@"Wrd1 = 0x%08lx\n", ptr[1]];
	NSString* sWrd2 = [NSString stringWithFormat:@"Wrd2 = 0x%08lx\n", ptr[2]];

	return [NSString stringWithFormat:@"%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@%@", 
		sGTId, sCrate, sBoard, sChannel, sCell, sQHL, sQHS, sQLX, sTAC, sCGT16,
		sCGT24, sES16, sMissed, sNC, sLGI, sWrd0, sWrd1, sWrd2];
}

@end
