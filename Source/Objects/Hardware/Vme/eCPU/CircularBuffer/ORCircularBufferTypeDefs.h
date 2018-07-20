//
//  ORCircularBufferTypeDefs.h
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

#define	BUFFER_OVERFLOW		0xffffffff
#define	CB_SENTINEL_INVALID	0xfffffffe
#define	CB_SENTINEL			0x00abcdef

typedef uint32_t tCBWord;			// all reads and writes to data memory are
								 // of this primitive size
//	PUBLIC interface parameters - keep in buffer memory
typedef struct {
	// (W == WRITER has write permission, R == READER has write permission)
		// CONSTANTS
	uint32_t	tCBWordSize;			// +0x00 (W) sizeof(tCBWord) - check that compiler's agree
	uint32_t	cbNumWords;				// +0x04 (W) number of tCBWords data buffer can hold
		// Variables
	tCBWord			*qHead;					// +0x08 (W) where to ADD
	uint32_t	blocksLostToFullBuffer;	// +0x0C (W) number of SVarSizeBlocks lost due to
	uint32_t	blocksWritten;			// +0x10 (W) number of SVarSizeBlock's the writer has written
	uint32_t	bytesWritten;			// +0x14 (W) number of bytes the writer has written
	tCBWord			*qTail;					// +0x18 (R) where to REMOVE
	uint32_t	blocksRead;				// +0x1C (R) number of SVarSizeBlock's the reader has read
	uint32_t	bytesRead;				// +0x20 (R) number of bytes the reader has read
	uint32_t	writeSentinel;			// +0x24 (W) the current version/sentinel of this CB writer
	uint32_t	readSentinel;			// +0x28 (R) the current version/sentinel of this CB reader
		// Data Buffer
	tCBWord			firstCBWord;			// (W) first tCBWord of the data buffer
} SCBHeader;
