/*
 *  CircularBuffer.h
 *  cPciTest
 *
 *  Created by Mark Howe on 6/14/07.
 *  Copyright 2007 CENPA, University of Washington. All rights reserved.
 *
 */
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

#include "SBC_Cmds.h"
#include <sys/types.h>
#include <stdint.h>

void CB_initialize(size_t length);
void CB_cleanup(void);
void CB_writeDataBlock(int32_t* data, int32_t length);
int32_t CB_nextBlockSize(void);
int32_t CB_readNextDataBlock(int32_t* buffer,int32_t maxSize);
void CB_getBufferInfo(BufferInfo* buffInfo);
int32_t CB_freeSpace(void);
void CB_flush(void);
