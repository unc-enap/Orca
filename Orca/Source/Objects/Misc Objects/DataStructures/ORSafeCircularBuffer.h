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
		unsigned long*	 dataPtr;
		unsigned bufferSize;
		unsigned readMark;
		unsigned writeMark;
		unsigned numBlocksWritten;
		unsigned numBlocksRead;
		unsigned numBytesWritten;
		unsigned numBytesRead;
		NSLock*  bufferLock;
		long freeSpace;
}

- (id) initWithBufferSize:(NSUInteger) aBufferSize;
- (BOOL) writeData:(NSData*)someData;
- (BOOL) writeBlock:(char*)someBytes length:(NSUInteger)numBytes;
- (NSData*) readNextBlock;
- (NSData*) readNextBlockAppendedTo:(NSData*)someData;
- (NSUInteger) numBlocksWritten;
- (NSUInteger) numBlocksRead;
- (void) reset;
- (BOOL) dataAvailable;
- (NSUInteger) bufferSize;
- (NSUInteger) readMark;
- (NSUInteger) writeMark;

+ (void) fullTest;
+ (void) test:(long)bufferSize;

@end
