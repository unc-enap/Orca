//
//  ORSocketThreadedClient.m
//  Orca
//
//  Created by Mark Howe on 2/17/06.
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


#import "ORSocketThreadedClient.h"
#import "NetSocket.h"
#import "ORSafeCircularBuffer.h"

@implementation ORSocketThreadedClient
- (id) initWithNetSocket:(NetSocket*)insocket
{
	self = [super init];
	[NSThread detachNewThreadSelector:@selector(startWork:) toTarget:self withObject:insocket];
	return self;
}

- (void)dealloc
{
    [_cancelled release];
	[super dealloc];
}

#pragma mark •••Thread
- (void) startWork:(NetSocket*)insocket
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	circularBuffer = [[ORSafeCircularBuffer alloc] initWithBufferSize:100*1024];
	socket = [insocket retain];
	
	// Setup socket for use
	[socket open];
	[socket scheduleOnCurrentRunLoop];
	[socket setDelegate:self];
	
	[self setName:[insocket remoteHost]];
    _cancelled  = [[NSConditionLock alloc] initWithCondition:NO];

	while(![self cancelled]){
		NSAutoreleasePool* localPool = [[NSAutoreleasePool alloc] init];
		[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
		[localPool release];
	}


    if([delegate respondsToSelector:@selector(clientWorkDone:)]){
	    [delegate clientWorkDone:self];
    }
	
	[circularBuffer autorelease];
	[_cancelled autorelease];
	_cancelled = nil;
	
	[pool release];
}

- (void) markAsCancelled
{
    // Get lock if we're currently NOT cancelled
    if( [_cancelled tryLockWhenCondition:NO] )
        [_cancelled unlockWithCondition:YES];
}

- (BOOL) cancelled
{
    return [_cancelled condition];
}

- (void)netsocket:(NetSocket*)insocket dataAvailable:(NSUInteger)inAmount
{
    if(insocket == socket){
		[circularBuffer writeData:[socket readData]];
    }
}

- (BOOL) dataAvailable
{
	return [circularBuffer dataAvailable];
}

- (NSData*) readNextBlock
{
	return [circularBuffer readNextBlock];
}

- (NSData*) readNextBlockAppendedTo:(NSData*)someData
{
	return [circularBuffer readNextBlockAppendedTo:someData];
}

- (NSUInteger) bufferSize
{
	return [circularBuffer bufferSize];
}

- (NSUInteger) readMark
{
	return [circularBuffer readMark];
}

- (NSUInteger) writeMark
{
	return [circularBuffer writeMark];
}

- (void) reset
{
	[circularBuffer reset];
}



@end
