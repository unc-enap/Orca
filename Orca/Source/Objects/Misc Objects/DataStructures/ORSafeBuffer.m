//
//  ORSafeBuffer.m
//  Orca
//
//  Created by Mark Howe on 2/5/06.
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


#import "ORSafeBuffer.h"

#define kDefaultMaxSize 10000

@interface ORSafeBuffer (private)
- (BOOL) isFull;
@end


@implementation ORSafeBuffer
- (id) init
{
	self = [self initWithBufferSize:kDefaultMaxSize];
	return self;
}

- (id) initWithBufferSize:(NSUInteger)aSize;
{
	self = [super init];
	startIndex = 0;
	maxSize = aSize;
	buffer = [[NSMutableArray array] retain];
	bufferLock = [[NSLock alloc] init];
	return self;
}

- (void) dealloc
{
	[buffer release];
	[bufferLock release];
	[super dealloc];
}

- (id) objectAtIndex:(NSUInteger)index
{
	id anObject = nil;
	[bufferLock lock];
	@try {
		if([self isFull])	anObject = [buffer objectAtIndex:(startIndex+index)%maxSize];
		else				anObject = [buffer objectAtIndex:index];
	}
	@catch(NSException* localException) {
	}
	
	[bufferLock unlock];
	return anObject;
}

- (void) addObject:(id) anObject
{
	[bufferLock lock];
	@try {
		if([self isFull]){
			[buffer replaceObjectAtIndex:startIndex withObject:anObject];
			startIndex = (startIndex+1)%maxSize;
		}
		else {
			[buffer addObject:anObject];
		}
	}
	@catch(NSException* localException) {
	}
	
	[bufferLock unlock];
}

- (id) lastObject
{
	id anObject = nil;
	[bufferLock lock];
	@try {
		if([self isFull])	anObject = [buffer objectAtIndex:startIndex];
		else				anObject = [buffer lastObject];
	}
	@catch(NSException* localException) {
	}
	
	[bufferLock unlock];
	return anObject;
}

- (NSUInteger) count
{
	return [buffer count];
}

@end

@implementation ORSafeBuffer (private)
- (BOOL) isFull
{
	return [buffer count] == maxSize;
}
@end
