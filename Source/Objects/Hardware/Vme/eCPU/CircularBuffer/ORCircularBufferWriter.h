//
//  ORCircularBufferWriter.h
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


#pragma mark •••Imported Files
#import "ORCircularBuffer.h"

@interface ORCircularBufferWriter : ORCircularBuffer {
	unsigned long maximumMemorySize;
}
#pragma mark •••Accessors
- (void) 			setMaximumMemorySize:(unsigned long) aSize;
- (unsigned long) 	maximumMemorySize;

- (void) 	initializeCircularBuffer;
- (void) 	writeControlBlockHeader:(SCBHeader)aControlBlockHeader;
- (tCBWord) addBlock:(tCBWord*)aBlockOfMemory size:(tCBWord) aLongWordsInBlock;
- (tCBWord) addByteBlock:(char*)inDataP size:(short) dataSize;
@end

