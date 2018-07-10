//
//  ORCircularBuffer.h
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
#import "ORCircularBufferTypeDefs.h"

// Define this only is attempting to debug circular buffers in Mac RAM
//#define __DEBUG_CBUFFER__

@interface ORCircularBuffer : NSObject <NSCoding>{
	unsigned long 	baseAddress;
	unsigned short 	addressModifier;
	unsigned short  addressSpace;
	unsigned long   sentinelRetryTotal;
	id				adapter;

	unsigned long	queueSize;
	tCBWord headValue;
	tCBWord	tailValue;
	
}

#pragma mark •••Accessors
- (void) 			setBaseAddress:(unsigned long) anAddress;
- (unsigned long) 	baseAddress;
- (void)			setAddressModifier:(unsigned short)anAddressModifier;
- (unsigned short)  addressModifier;
- (void)			setAddressSpace:(unsigned short)anAddressSpace;
- (unsigned short)  addressSpace;
- (void) 			setSentinelRetryTotal:(unsigned long)value;
- (unsigned long)	sentinelRetryTotal;
- (void)			setAdapter:(id)anAdapter;

#pragma mark •••Hardware Access
- (SCBHeader) readControlBlockHeader;
- (unsigned long) getNumberOfBlocksInBuffer;
- (unsigned long) getBlocksWritten;
- (unsigned long) getBlocksRead;
- (unsigned long) getBytesWritten;

-(unsigned long) getBytesRead;
- (BOOL) sentinelValid;

- (void) writeLongBlock:(unsigned long) anAddress blocks:(unsigned long) aNumberOfBlocks atPtr:(unsigned long*) aReadPtr;

- (void) writeLong:(unsigned long) anAddress value:(unsigned long) aValue;
- (void) readLongBlock:(unsigned long) anAddress blocks:(unsigned long) aNumberOfBlocks atPtr:(unsigned long*)aWritePtr;
- (void) readLong:(unsigned long) anAddress atPtr:(unsigned long*) aValue;

- (void) getQueHead:(unsigned long*)aHeadValue tail:(unsigned long*)aTailValue;

@end
