//
//  ORCircularBuffer.m
//  Orca
//
//  Created by Mark Howe on Tue Apr 01 2003.
//  Copyright (c) 2003 CENPA, University of Washington. All rights reserved.
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


/*
 *		PUBLIC Memory Map:
 *
 *
 *		cbBase	->		-------------------------------------------
 *						| SCBHeader                			      |
 *						-------------------------------------------
 *		qBegin	->		| block 0								  |
 *						-------------------------------------------
 *		...				| block 1                                 |
 *						-------------------------------------------
 *                       | ...           					      |
 *						-------------------------------------------
 *
 *
 *		Block Layout:
 *
 *							-----------------------------	+0
 *							| size      				|
 *							-----------------------------	+sizeof(tCBWord)
 *							| data      				|
 *							-----------------------------	+sizeof(tCBWord) * size
 *																+ sizeof(tCBWord)
 *
 */

#pragma mark •••Imported Files
#import "ORCircularBuffer.h"
#import "ORVmeIOCard.h"

@implementation ORCircularBuffer

#pragma mark •••Initialization
- (id)init
{
	self = [super init];
	[self setAddressModifier: 0x09]; 
	[self setAddressSpace: 3];
	[self setSentinelRetryTotal:0];
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

#pragma mark •••Accessors
- (void) setBaseAddress:(unsigned long) anAddress
{
	baseAddress = anAddress;	
}

- (unsigned long) baseAddress
{
	return baseAddress;
}

- (void)setAddressModifier:(unsigned short)anAddressModifier
{
	addressModifier = anAddressModifier;
}

- (unsigned short) addressModifier
{
	return addressModifier;
}

- (void) setAddressSpace:(unsigned short)anAddressSpace
{
	addressSpace =  anAddressSpace;
}

- (unsigned short)addressSpace
{
	return addressSpace;	
}

- (void) setSentinelRetryTotal:(unsigned long)value
{
	sentinelRetryTotal = value;
}

- (unsigned long)sentinelRetryTotal
{
	return sentinelRetryTotal;
}


- (void) getQueHead:(unsigned long*)aHeadValue tail:(unsigned long*)aTailValue
{
	*aHeadValue = (unsigned long)headValue;
	*aTailValue = (unsigned long)tailValue;
}

- (void)setAdapter:(id)anAdapter;
{
	adapter = anAdapter;
}


#pragma mark •••Hardware Access
- (SCBHeader) readControlBlockHeader
{
	SCBHeader theControlBlockHeader;
	@try {
		[adapter readLongBlock:(unsigned long*)&theControlBlockHeader
					 atAddress:baseAddress
					 numToRead:sizeof(SCBHeader)/sizeof(unsigned long)
					withAddMod:addressModifier
				 usingAddSpace:addressSpace];
		
		
		queueSize = theControlBlockHeader.cbNumWords;
		headValue = (tCBWord)theControlBlockHeader.qHead;
		tailValue = (tCBWord)theControlBlockHeader.qTail;
		
	}
	@catch(NSException* localException) {
		memset(&theControlBlockHeader,0,sizeof(SCBHeader));		
	}
	
	
	return theControlBlockHeader;
}

- (unsigned long) getNumberOfBlocksInBuffer
{
	SCBHeader theControlBlockHeader = [self readControlBlockHeader];
	if( (theControlBlockHeader.writeSentinel & 0x00ffffff) == CB_SENTINEL){
		return theControlBlockHeader.blocksWritten - theControlBlockHeader.blocksRead;		
	}
	else return 0;
}

- (unsigned long) getBlocksWritten
{
	SCBHeader theControlBlockHeader = [self readControlBlockHeader];
	if( (theControlBlockHeader.writeSentinel & 0x00ffffff) == CB_SENTINEL){
		return theControlBlockHeader.blocksWritten;		
	}
	else return 0;
}

- (unsigned long) getBlocksRead
{
	SCBHeader theControlBlockHeader = [self readControlBlockHeader];
	if( (theControlBlockHeader.writeSentinel & 0x00ffffff) == CB_SENTINEL){
		return theControlBlockHeader.blocksRead;
	}
	else return 0;
}

- (unsigned long) getBytesWritten
{
	SCBHeader theControlBlockHeader = [self readControlBlockHeader];
	if( (theControlBlockHeader.writeSentinel & 0x00ffffff) == CB_SENTINEL){
		return theControlBlockHeader.bytesWritten;
	}
	else return 0;
}

- (unsigned long) getBytesRead
{
	SCBHeader theControlBlockHeader = [self readControlBlockHeader];
	if( (theControlBlockHeader.writeSentinel & 0x00ffffff) == CB_SENTINEL){
		return theControlBlockHeader.bytesRead;
	}
	else return 0;
}

- (BOOL) sentinelValid
{
	int sentinelRetry;
	BOOL sentinelOK = false;
	for(sentinelRetry=0;sentinelRetry<3;sentinelRetry++){
		@try {
			SCBHeader theControlBlockHeader = [self readControlBlockHeader];
			sentinelOK = ((theControlBlockHeader.writeSentinel & 0x00ffffff) == CB_SENTINEL);
		}
		@catch(NSException* localException) {
			++sentinelRetryTotal;
		}
		if(sentinelOK)break;
	}
	return sentinelOK;
}

- (void) writeLongBlock:(unsigned long) anAddress blocks:(unsigned long) aNumberOfBlocks atPtr:(unsigned long*) aWritePtr
{
	[adapter writeLongBlock:aWritePtr
				  atAddress:anAddress
				 numToWrite:aNumberOfBlocks
				 withAddMod:addressModifier
			  usingAddSpace:addressSpace];
}

- (void) writeLong:(unsigned long) anAddress value:(unsigned long) aValue
{
	[adapter writeLongBlock:&aValue
				  atAddress:anAddress
				 numToWrite:1
				 withAddMod:addressModifier
			  usingAddSpace:addressSpace];
}

- (void) readLongBlock:(unsigned long) anAddress blocks:(unsigned long) aNumberOfBlocks atPtr:(unsigned long*)aReadPtr
{
	[adapter readLongBlock:aReadPtr
				 atAddress:anAddress
				 numToRead:aNumberOfBlocks
				withAddMod:addressModifier
			 usingAddSpace:addressSpace];
}

- (void) readLong:(unsigned long) anAddress atPtr:(unsigned long*) aValue
{
	[adapter readLongBlock:aValue
				 atAddress:anAddress
				 numToRead:1
				withAddMod:addressModifier
			 usingAddSpace:addressSpace];
}


#pragma mark •••Archival
static NSString *ORCBBaseAddress 			= @"CB base address";
static NSString *ORCBAddressModifier 		= @"CB address modifier";
static NSString *ORCBAddressSpace 			= @"CB address space";

- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super init];
	[self setBaseAddress:[decoder decodeIntForKey:ORCBBaseAddress]];
	[self setAddressModifier:[decoder decodeIntForKey:ORCBAddressModifier]];
	[self setAddressSpace:[decoder decodeIntForKey:ORCBAddressSpace]];
    return self;
}

- (void)encodeWithCoder:(NSCoder*)encoder
{
	[encoder encodeInt:[self baseAddress] forKey:ORCBBaseAddress];
	[encoder encodeInt:addressModifier forKey:ORCBAddressModifier];
	[encoder encodeInt:addressSpace forKey:ORCBAddressSpace];
}

@end


