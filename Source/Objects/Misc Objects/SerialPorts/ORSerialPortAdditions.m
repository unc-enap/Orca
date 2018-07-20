//
//  ORSerialPortAdditions.m
//  ORCA
//
//  Created by Mark Howe on Mon Feb 10 2003.
//  Copyright � 2002 CENPA, University of Washington. All rights reserved.
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

//  Modified from ORSerialPortList.h by Andreas Mayer

#import "ORSerialPortAdditions.h"
#import "NSDate+Extensions.h"

@implementation ORSerialPort (ORSerialPortAdditions)


// ============================================================
#pragma mark -
#pragma mark ━ blocking IO ━
// ============================================================

- (void)doRead:(NSTimer *)timer;
{
    int res;
    FD_ZERO(readfds);
    FD_SET(fileDescriptor, readfds);
    timeout->tv_sec = 0;
    timeout->tv_usec = 1;
    res = select(fileDescriptor+1, readfds, nil, nil, timeout);
    if (res >= 1) {
        [readTarget performSelector:readSelector withObject:[self readString]];
		[readTarget release];
		readTarget = nil;
    }
    else {
        readTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(doRead:) userInfo:self  repeats:NO] retain];
    }
}

-(NSString *)readString
{
    if (buffer == nil) buffer = malloc(AMSER_MAXBUFSIZE);
    ssize_t len = read(fileDescriptor, buffer, AMSER_MAXBUFSIZE);
	return [[[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding] autorelease];
}

- (int) writeString:(NSString *)string
{
    int totalWritten = 0;
    NSUInteger totalNeedToWrite = [string length];
    int i;
    for(i=0;i<totalNeedToWrite;i++){
        NSString* stringToWrite = [string substringFromIndex:totalWritten];
        NSUInteger len = [stringToWrite length];
        const char* cString = [stringToWrite cStringUsingEncoding:NSASCIIStringEncoding];
        totalWritten  +=  write(fileDescriptor, cString, len);
        if(totalWritten >= totalNeedToWrite)break;
    }
    
    return totalWritten;
}

- (int) writeCharArray:(const unsigned char *)ptr length:(int)theLength
{
    int totalWritten     = 0;
    int totalNeedToWrite = theLength;
    int i;
    for(i=0;i<totalNeedToWrite;i++){
        NSUInteger numWritten =  write(fileDescriptor, ptr, theLength-totalWritten);
        ptr          += numWritten;
        totalWritten += numWritten;
        if(totalWritten >= totalNeedToWrite)break;
    }
    
    return totalWritten;
}

- (int) readCharArray:(unsigned char *)ptr length:(int)theLength
{
    return (int)read(fileDescriptor, (void*)ptr, theLength);
}



- (int) checkRead
{
    FD_ZERO(readfds);
    FD_SET(fileDescriptor, readfds);
    timeout->tv_sec = 0;
    timeout->tv_usec = 1;
    return select(fileDescriptor+1, readfds, nil, nil, timeout);
}

- (void) waitForInput:(id)target selector:(SEL)selector
{
    readTarget = [target retain];
    readSelector = selector;
    if (readTimer) [readTimer release];
    readTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(doRead:) userInfo:self repeats:NO] retain];
    
}

// ============================================================
#pragma mark -
#pragma mark ━ threaded IO ━
// ============================================================

- (void)readDataInBackground
{
    //if (delegateHandlesReadInBackground) {
    [countReadInBackgroundThreadsLock lock];
    countReadInBackgroundThreads++;
    [countReadInBackgroundThreadsLock unlock];
    [NSThread detachNewThreadSelector:@selector(readDataInBackgroundThread) toTarget:self withObject:nil];
    //} else {
    // ... throw exception?
    //}
}

- (void)stopReadInBackground
{
    [stopReadInBackgroundLock lock];
    stopReadInBackground = YES;
    //NSLog(@"stopReadInBackground set to YES\n");
    [stopReadInBackgroundLock unlock];
}

- (void)writeDataInBackground:(NSData *)data
{
    if (delegateHandlesWriteInBackground) {
        [countWriteInBackgroundThreadsLock lock];
        countWriteInBackgroundThreads++;
        [countWriteInBackgroundThreadsLock unlock];
        [NSThread detachNewThreadSelector:@selector(writeDataInBackgroundThread:) toTarget:self withObject:data];
    } else {
        // ... throw exception?
    }
}

- (void)stopWriteInBackground
{
    [stopWriteInBackgroundLock lock];
    stopWriteInBackground = YES;
    [stopWriteInBackgroundLock unlock];
}

- (int)numberOfWriteInBackgroundThreads
{
    return countWriteInBackgroundThreads;
}

- (void) serialPortReadData:(NSDictionary*)data
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSerialPortDataReceived object:self userInfo:data];
    [self readDataInBackground]; 
}

// ============================================================
#pragma mark -
#pragma mark ━ threaded methods ━
// ============================================================

- (void)readDataInBackgroundThread
{
    NSData *data = nil;
    void *localBuffer;
    int bytesRead = 0;
    fd_set *localReadFDs;
    
    localBuffer = malloc(AMSER_MAXBUFSIZE);
    [stopReadInBackgroundLock lock];
    stopReadInBackground = NO;
    //NSLog(@"stopReadInBackground set to NO: %@", [NSThread currentThread]);
    [stopReadInBackgroundLock unlock];
    //NSLog(@"attempt readLock: %@", [NSThread currentThread]);
    [readLock lock];	// write in sequence
                        //NSLog(@"readLock locked: %@", [NSThread currentThread]);
    NSAutoreleasePool *localAutoreleasePool = [[NSAutoreleasePool alloc] init];
    localReadFDs = malloc(sizeof(*localReadFDs));
    FD_ZERO(localReadFDs);
    FD_SET(fileDescriptor, localReadFDs);
    int res = select(fileDescriptor+1, localReadFDs, nil, nil, nil); // timeout);
    if (!stopReadInBackground) {
        //NSLog(@"attempt closeLock: %@", [NSThread currentThread]);
        [closeLock lock];
        //NSLog(@"closeLock locked: %@", [NSThread currentThread]);
        if ((res >= 1) && (fileDescriptor >= 0)) {
            bytesRead = (int)read(fileDescriptor, localBuffer, AMSER_MAXBUFSIZE);
        }
		if(bytesRead>0){
			data = [NSData dataWithBytes:localBuffer length:bytesRead];
			[self performSelectorOnMainThread:@selector(serialPortReadData:) withObject:[NSDictionary dictionaryWithObjectsAndKeys: self, @"serialPort", data, @"data", nil] waitUntilDone:NO];
		}
		[closeLock unlock];
		if(bytesRead<0){
			[self close];
		}
		//NSLog(@"closeLock unlocked: %@", [NSThread currentThread]);
		
    } else {
    }
    
    [readLock unlock];
    //NSLog(@"readLock unlocked: %@", [NSThread currentThread]);
    [countReadInBackgroundThreadsLock lock];
    countReadInBackgroundThreads--;
    [countReadInBackgroundThreadsLock unlock];
    
    free(localReadFDs);
    [localAutoreleasePool release];
    free(localBuffer);
}

-(void) reportProgress:(int) progress dataLen:(unsigned int)dataLen
{
    [delegate performSelectorOnMainThread:@selector(serialPortWriteProgress:) withObject:[NSDictionary dictionaryWithObjectsAndKeys:self, @"serialPort", [NSNumber numberWithInt:progress], @"value", [NSNumber numberWithInt:dataLen], @"total", nil] waitUntilDone:NO];
}


- (void)writeDataInBackgroundThread:(NSData *)data
{
    
    void *localBuffer;
    unsigned int pos;
    unsigned int bufferLen;
    unsigned int dataLen;
    unsigned int written;
    NSDate *nextNotificationDate;
    BOOL notificationSent = NO;
    int32_t speed;
    int32_t estimatedTime;
    BOOL error = NO;
    
    
    NSAutoreleasePool *localAutoreleasePool = [[NSAutoreleasePool alloc] init];
    
    [data retain];
    localBuffer = malloc(AMSER_MAXBUFSIZE);
    [stopWriteInBackgroundLock lock];
    stopWriteInBackground = NO;
    [stopWriteInBackgroundLock unlock];
    [writeLock lock];	// write in sequence
    pos = 0;
    dataLen = (unsigned int)[data length];
    speed = [self getSpeed];
    estimatedTime = (dataLen*8)/speed;
    if (estimatedTime > 3) { // will take more than 3 seconds
        notificationSent = YES;
        [self reportProgress:pos dataLen:dataLen];
        nextNotificationDate = [NSDate dateWithTimeIntervalSinceNow:1.0];
    } else {
        nextNotificationDate = [NSDate dateWithTimeIntervalSinceNow:2.0];
    }
    while (!stopWriteInBackground && (pos < dataLen) && !error) {
        bufferLen = MIN(AMSER_MAXBUFSIZE, dataLen-pos);
        
        [data getBytes:localBuffer range:NSMakeRange(pos, bufferLen)];
        written = (unsigned int)write(fileDescriptor, localBuffer, bufferLen);
        if ((error = (written == 0))) // error condition
            break;
        pos += written;
        
        if ([(NSDate *)[NSDate date] compare:nextNotificationDate] == NSOrderedDescending) {
            if (notificationSent || (pos < dataLen)) { // not for last block only
                notificationSent = YES;
                [self reportProgress:pos dataLen:dataLen];
                nextNotificationDate = [NSDate dateWithTimeIntervalSinceNow:1.0];
            }
        }
    }
    if (notificationSent) {
        [self reportProgress:pos dataLen:dataLen];
    }
    [stopWriteInBackgroundLock lock];
    stopWriteInBackground = NO;
    [stopWriteInBackgroundLock unlock];
    [writeLock unlock];
    [countWriteInBackgroundThreadsLock lock];
    countWriteInBackgroundThreads--;
    [countWriteInBackgroundThreadsLock unlock];
    
    free(localBuffer);
    [data release];
    [localAutoreleasePool release];
}


@end
