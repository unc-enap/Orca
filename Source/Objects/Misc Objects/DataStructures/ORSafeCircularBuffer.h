//
//  ORSafeCircularBuffer.h
//  Orca
//
//  Created by Mark Howe on 2/16/06.
//  Copyright 2006 CENPA, University of Washington. All rights reserved.
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





@interface ORSafeCircularBuffer : NSObject {
	@private
		NSMutableData* buffer;
		NSUInteger*	 dataPtr;
		unsigned bufferSize;
		unsigned readMark;
		unsigned writeMark;
		unsigned numBlocksWritten;
		unsigned numBlocksRead;
		unsigned numBytesWritten;
		unsigned numBytesRead;
		NSLock*  bufferLock;
		int32_t freeSpace;
}

- (id) initWithBufferSize:(int32_t) aBufferSize;
- (BOOL) writeData:(NSData*)someData;
- (BOOL) writeBlock:(char*)someBytes length:(int32_t)numBytes;
- (NSData*) readNextBlock;
- (NSData*) readNextBlockAppendedTo:(NSData*)someData;
- (int32_t) numBlocksWritten;
- (int32_t) numBlocksRead;
- (void) reset;
- (BOOL) dataAvailable;
- (int32_t) bufferSize;
- (int32_t) readMark;
- (int32_t) writeMark;

+ (void) fullTest;
+ (void) test:(int32_t)bufferSize;

@end
