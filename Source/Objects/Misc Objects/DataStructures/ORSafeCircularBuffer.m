//
//  ORSafeCircularBuffer.m
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


#import "ORSafeCircularBuffer.h"
//

@implementation ORSafeCircularBuffer
- (id) initWithBufferSize:(int32_t) aBufferSize
{
	self = [super init];
    if(aBufferSize==0)aBufferSize = 1024*100; //if passed zero, put something in....
	bufferSize		 = (uint32_t)aBufferSize;
	buffer			 = [[NSMutableData dataWithLength:bufferSize * sizeof(int32_t)] retain];
	[buffer setLength:bufferSize * sizeof(int32_t)];
	bufferLock		 = [[NSLock alloc] init];
	numBlocksWritten = 0;
	numBlocksRead	 = 0;
	numBytesWritten	 = 0;
	numBytesRead	 = 0;
	freeSpace		 = bufferSize;
	readMark		 = 0;
	writeMark		 = 0;
	dataPtr			 = [buffer mutableBytes];

	return self;
}

- (void) dealloc
{
	[bufferLock release];
	[buffer release];
	[super dealloc];
}

- (void) reset
{
	readMark = writeMark = 0;
	numBytesRead = numBytesWritten = 0;
	numBlocksRead = numBlocksWritten = 0;
}

- (int32_t) bufferSize
{
	return bufferSize;
}

- (int32_t) readMark
{
	return readMark;
}
- (int32_t) writeMark
{
	return writeMark;
}

- (BOOL) writeBlock:(char*)someBytes length:(int32_t)numBytes
{
	[bufferLock lock];
	BOOL full = NO;
	if(freeSpace > 0){
		//theData is released when pulled from the CB
		NSData* theData = [[NSData dataWithBytes:someBytes length:numBytes] retain];
		*(dataPtr+writeMark) = (uint32_t)theData;
		writeMark = (writeMark+1)%bufferSize;	//move the write mark ahead 
		numBytesWritten += numBytes;
		numBlocksWritten++;
		freeSpace--; 
	}
	else full = YES;
	[bufferLock unlock];
	return full;
}

- (BOOL) writeData:(NSData*)someData
{
	[bufferLock lock];
	BOOL full = NO;
	if(freeSpace > 0){
		[someData retain];
		*(dataPtr+writeMark) = (uint32_t)someData;
		writeMark = (writeMark+1)%bufferSize;	//move the write mark ahead 
		numBytesWritten += [someData length];
		numBlocksWritten++;
		freeSpace--; 
	}
	else full = YES;
	[bufferLock unlock];
	return full;
}

- (int32_t) numBlocksWritten
{
	return numBlocksWritten;
}

- (int32_t) numBlocksRead
{
	return numBlocksRead;
}

- (BOOL) dataAvailable
{
	BOOL result;
	[bufferLock lock];
	result =  writeMark != readMark || freeSpace == 0;
	[bufferLock unlock];
	return result;
}

- (NSData*) readNextBlockAppendedTo:(NSData*)someData
{
	if(!someData)return [self readNextBlock];
	else {
		NSData* theNewData = [self readNextBlock];
		if(!theNewData)return nil;
		else {
			NSMutableData* theData = [NSMutableData dataWithData:someData];
			[theData appendData:theNewData];
			return theData;
		}
	}
}

- (NSData*) readNextBlock
{
	NSData* theBlock = nil;
	
	[bufferLock lock];
	if(writeMark != readMark || freeSpace == 0){
		theBlock = (NSData*)(*(dataPtr+readMark));
		readMark = (readMark + 1) % bufferSize; //move the read mark ahead
		//NSLog(@" read data block from CB size: %d\n",[theBlock length]);
		numBytesRead += [theBlock length];
		numBlocksRead++;
		freeSpace++; 
	}
	[bufferLock unlock];
	return [theBlock autorelease];
}


//------------Tests---------------------
static char tb[]= {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17};
static BOOL readRunning = NO;
static BOOL writeRunning = NO;
static BOOL cbThreadTestPassed = YES;

- (void) testReadThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSTimeInterval t0 = [NSDate timeIntervalSinceReferenceDate];
	int32_t count = 0;
	while([NSDate timeIntervalSinceReferenceDate]-t0 < 0.7) {
		NSData* result = [self readNextBlock];
		if(result){
			count++;
			const char* p = [result bytes];
			int i;
			for(i=0;i<sizeof(tb);i++){
				if(p[i] != tb[i]){
					cbThreadTestPassed = NO;
					break;
				}
			}
		}
	}

	NSLog(@"read: %d blocks\n",count);
	readRunning = NO;
	[pool release];
}

- (void) testWriteThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	NSTimeInterval t0 = [NSDate timeIntervalSinceReferenceDate];
	int32_t count = 0;
	while([NSDate timeIntervalSinceReferenceDate]-t0 < 0.5){
		if(![self writeBlock:tb length:sizeof(tb)]){
			count++;
		}
	}
	writeRunning = NO;
	NSLog(@"wrote: %d blocks\n",count);
	[pool release];
}

+ (void) fullTest
{
	NSLog(@"-----start ORSafeCircularBuffer Tests------\n");
	NSLog(@"testing small buffer size (100 entries)\n");
	[ORSafeCircularBuffer test:100];
	NSLog(@"testing large buffer size (odd size) (100001 entries)\n");
	[ORSafeCircularBuffer test:100000];
	NSLog(@"-----end ORSafeCircularBuffer Tests------\n");
	
}

+ (void) test:(int32_t)aBufferSize
{
	ORSafeCircularBuffer* aBuffer = [[ORSafeCircularBuffer alloc] initWithBufferSize:aBufferSize];
	NSData* result;
	result = [aBuffer readNextBlock];
	if(result!= nil) NSLog(@"failed empty read\n");
	else			 NSLog(@"PASSED empty read\n");	
	
	char testBuffer[]= {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17};
	BOOL passed = YES;
	int j;
	srandom((unsigned)[NSDate timeIntervalSinceReferenceDate]);
	for(j=0;j<5000;j++){
		int ranSize = 1+random()%16;

		[aBuffer writeBlock:testBuffer length:ranSize];
		result = [aBuffer readNextBlock];
		if(result){
			const char* p = [result bytes];
			int i;
			for(i=0;i<ranSize;i++){
				if(p[i] != testBuffer[i]){
					passed = NO;
					break;
				}
			}
			if(!passed)	{
				NSLog(@"FAILED read %d\n",j);
				break;
			}
		}
		else NSLog(@"FAILED read %d\n",j);	
	}
	if(passed)NSLog(@"PASSED big readout test\n");
	
	
	int32_t startBlockCount = [aBuffer numBlocksWritten];
	int32_t maxCanHold = [aBuffer bufferSize];
	int i;
	for(i=0;i<maxCanHold+3;i++){
		[aBuffer writeBlock:testBuffer length:sizeof(testBuffer)];
	}
	
	//should have overflowed
	int32_t numWritten = [aBuffer numBlocksWritten] - startBlockCount;
	if(numWritten == maxCanHold)NSLog(@"PASSED overflow write test\n");
	else						NSLog(@"FAILED overflow write test\n");

	startBlockCount = [aBuffer numBlocksRead];
	for(j=0;j<maxCanHold+3;j++){
		result = [aBuffer readNextBlock];
		if(result){
			const char* p = [result bytes];
			int i;
			for(i=0;i<17;i++){
				if(p[i] != testBuffer[i]){
					passed = NO;
					break;
				}
			}
			if(!passed)	{
				NSLog(@"FAILED overflow read %d\n",j);
				break;
			}
		}
		else if(j<maxCanHold)NSLog(@"FAILED overflow read %d\n",j);	
	}
	int32_t numRead = [aBuffer numBlocksRead] - startBlockCount;
	
	if(passed && numRead == maxCanHold)NSLog(@"PASSED overflow readout test\n");
	
	readRunning = YES;
	writeRunning = YES;
	cbThreadTestPassed = YES;
	[NSThread detachNewThreadSelector:@selector(testReadThread) toTarget:aBuffer withObject:nil];
	[NSThread detachNewThreadSelector:@selector(testWriteThread) toTarget:aBuffer withObject:nil];
	
	NSTimeInterval t0 = [NSDate timeIntervalSinceReferenceDate];
	do {
		if(!readRunning && !writeRunning)break;
	} while([NSDate timeIntervalSinceReferenceDate]-t0 < 1);
	if(cbThreadTestPassed) NSLog(@"PASSED thread access test\n");
	else				   NSLog(@"FAILED thread access test\n");
	[aBuffer release];
}
@end
