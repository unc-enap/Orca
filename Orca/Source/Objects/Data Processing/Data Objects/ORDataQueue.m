//
//  ORDataQueue.m
//  Orca
//
//  Created by Mark Howe on Thu Mar 06 2003.
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
#import "ORDataQueue.h"
#import "ORFileIOHelpers.h"
#import "ORDataSet.h"
#import "ORDataTaker.h"
#import "ORDataTypeAssigner.h"
#import "NSDictionary+Extensions.h"

#define kDataVersion 3
#define kMinSize 4096*2
#define kMinCapacity 4096

@implementation ORDataQueue
- (id)init
{
    self = [super init];
	
    theDataLock         = [[NSRecursiveLock alloc] init];
	lastFrameBufferSize = kMinSize;
    return self;
}

- (void) dealloc
{
    [theDataLock release];
    [dataArray release];
	[cacheArray release];
    [frameBuffer release];
    [super dealloc];
}

#pragma mark •••Accessors

- (void) startFrameTimer
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceFrameLoad) object:nil];
    [self performSelector:@selector(forceFrameLoad) withObject:nil afterDelay:.1];
	oldFrameCounter = 0;
	frameCounter = 0;
}

- (void) stopFrameTimer
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(forceFrameLoad) object:nil];
}

- (void) forceFrameLoad
{
	++frameCounter;
    [self performSelector:@selector(forceFrameLoad) withObject:nil afterDelay:.1];
}

- (NSMutableArray*)  dataArray
{
	[theDataLock lock];   //-----begin critical section
	NSMutableArray* temp = [[dataArray retain] autorelease];
	[theDataLock unlock];   //-----end critical section
	return temp;
}

- (void) setDataArray:(NSMutableArray*)someData
{
	[theDataLock lock];   //-----begin critical section
    [someData retain];
    [dataArray release];
    dataArray = someData;
	[theDataLock unlock];   //-----end critical section
}

- (NSMutableData*)  frameBuffer
{
	[theDataLock lock];   //-----begin critical section
	NSMutableData* temp = [[frameBuffer retain] autorelease];
	[theDataLock unlock];   //-----end critical section
	return temp;
}

- (void) setFrameBuffer:(NSMutableData*)someData
{
	[theDataLock lock];   //-----begin critical section
    [someData retain];
    [frameBuffer release];
    frameBuffer = someData;
	
	frameIndex = 0;
    reserveIndex = 0;
	[theDataLock unlock];   //-----end critical section
}

- (NSMutableArray*) cacheArray
{
	[theDataLock lock];   //-----begin critical section
	NSMutableArray* temp = [[cacheArray retain] autorelease];
	[theDataLock unlock];   //-----end critical section
	return temp;
}
- (void) setCacheArray:(NSMutableArray*)newCacheArray
{
	[theDataLock lock];   //-----begin critical section
    [cacheArray autorelease];
    cacheArray=[newCacheArray retain];
	[theDataLock unlock];   //-----end critical section
}

//------------------------------------------------------------------------------
//data addition methods
- (unsigned long) frameIndex
{
	return frameIndex;
}
- (void) replaceReservedDataInFrameBufferAtIndex:(unsigned long)index withLongs:(unsigned long*)data length:(unsigned long)length
{
	[theDataLock lock];   //-----begin critical section
	if(frameBuffer && index<reserveIndex){
		memcpy(((unsigned long*)[frameBuffer bytes])+reservePool[index],data,length*sizeof(long));
		addedData = YES;
	}
	[theDataLock unlock];   //-----end critical section
}


- (unsigned long) addLongsToFrameBuffer:(unsigned long*)someData length:(unsigned long)length
{
	[theDataLock lock];   //-----begin critical section
    if(!frameBuffer){
		[self setFrameBuffer:[NSMutableData dataWithLength:lastFrameBufferSize]];
	}
	if((frameIndex+length)*sizeof(long)>=[frameBuffer length]){
		[frameBuffer increaseLengthBy:(length*sizeof(long))+kMinSize];
        lastFrameBufferSize = [frameBuffer length];
	}
    memcpy(((unsigned long*)[frameBuffer bytes])+frameIndex,someData,length*sizeof(long));
	
	frameIndex += length;
    addedData = YES;
	[theDataLock unlock];   //-----end critical section
	return  frameIndex;
}

- (unsigned long*) getBlockForAddingLongs:(unsigned long)length
{
	[theDataLock lock];   //-----begin critical section
    if(!frameBuffer){
		[self setFrameBuffer:[NSMutableData dataWithLength:lastFrameBufferSize]];
	}
	unsigned long oldFrameIndex = frameIndex;
	frameIndex += length;
	if([frameBuffer length]<frameIndex*sizeof(long)){
		unsigned long deltaLength = (length*sizeof(long))+kMinSize;
		[frameBuffer increaseLengthBy:deltaLength];
        lastFrameBufferSize = [frameBuffer length];  
	}
	unsigned long* ptr = (unsigned long*)[frameBuffer bytes];
	[theDataLock unlock];   //-----end critical section
	return &ptr[oldFrameIndex];
}

- (unsigned long)reserveSpaceInFrameBuffer:(unsigned long)length
{
	[theDataLock lock];   //-----begin critical section
    if(!frameBuffer) [self setFrameBuffer:[NSMutableData dataWithLength:kMinSize]];
	
    reservePool[reserveIndex] = frameIndex;
	unsigned long oldIndex = reserveIndex;
    reserveIndex++;
	
	frameIndex += length;
	if([frameBuffer length]<=frameIndex*sizeof(long)){
		[frameBuffer increaseLengthBy:(length*sizeof(long))+kMinSize];
        lastFrameBufferSize = [frameBuffer length];        
	}
	[theDataLock unlock];   //-----end critical section
	return oldIndex;
}

- (void) removeReservedLongsFromFrameBuffer:(NSRange)aRange
{
	[theDataLock lock];   //-----begin critical section
	if(frameBuffer){
        unsigned long actualReservedLocation = reservePool[aRange.location];
        if(actualReservedLocation>=0){
			unsigned long* ptr = (unsigned long*)[frameBuffer bytes];
			memmove(&ptr[actualReservedLocation],&ptr[actualReservedLocation+aRange.length],(frameIndex-actualReservedLocation-aRange.length)*sizeof(long));
			frameIndex -= aRange.length;
			
			unsigned long i;
			reservePool[aRange.location] = -1;
			for(i=aRange.location+1;i<reserveIndex;i++){
				reservePool[i] -= aRange.length;
			}
		}
	}	
	[theDataLock unlock];   //-----end critical section
}

- (void) addFrameBuffer:(BOOL)forceAdd
{
	if(frameBuffer && (forceAdd || (oldFrameCounter!=frameCounter) || dataAvailable || dataInCache)){
		[theDataLock lock];   //-----begin critical section
		oldFrameCounter = frameCounter;
		[frameBuffer setLength:(frameIndex*sizeof(long))];
		
		//[self addData:frameBuffer];
		if(!dataArray)[self setDataArray:[NSMutableArray arrayWithCapacity:kMinCapacity]];
		[dataArray addObject:frameBuffer];
		addedData = YES;
		
		dataAvailable = NO;
		[frameBuffer release];
        frameBuffer = nil;
		frameIndex = 0;
		[theDataLock unlock];   //-----end critical section
	}
	reserveIndex = 0;
}

- (void) addData:(NSData*)someData
{
	[theDataLock lock];   //-----begin critical section
    if(!dataArray)[self setDataArray:[NSMutableArray arrayWithCapacity:kMinCapacity]];
    [dataArray addObject:someData];
    addedData = YES;
	dataAvailable = YES;
	[theDataLock unlock];   //-----end critical section
}


- (void) addDataFromArray:(NSArray*)aDataArray
{
	[theDataLock lock];   //-----begin critical section
    if(!dataArray)[self setDataArray:[NSMutableArray arrayWithCapacity:kMinCapacity]];
    [dataArray addObjectsFromArray:aDataArray];
    addedData = YES;
	dataAvailable = YES;
	[theDataLock unlock];   //-----end critical section
}

- (void) addCachedData
{
	if(dataInCache){
		[theDataLock lock];   //-----begin critical section
		if([cacheArray count]){
			[self addDataFromArray:cacheArray];
			[cacheArray removeAllObjects];
		}
		dataInCache = NO;
		[theDataLock unlock];   //-----end critical section
	}
}

- (unsigned long) dataCount
{
	unsigned long theCount = 0;
	if([theDataLock tryLock]){  //-----begin critical section
		theCount = [dataArray count];
		[theDataLock unlock];   //-----end critical section
	}
	return theCount;
}

- (void) addDataToCach:(NSData*)someData;
{
    [theDataLock lock];   //-----begin critical section
    if(!cacheArray)[self setCacheArray:[NSMutableArray arrayWithCapacity:kMinCapacity]];
    [cacheArray addObject:someData];
	dataInCache = YES;
    [theDataLock unlock];   //-----end critical section
}

- (void) addArrayToCache:(NSArray*)aDataArray
{
    [theDataLock lock];   //-----begin critical section
    if(!cacheArray)[self setCacheArray:[NSMutableArray arrayWithCapacity:kMinCapacity]];
    [cacheArray addObjectsFromArray:aDataArray];
	dataInCache = YES;
    [theDataLock unlock];   //-----end critical section
}

- (void) clearData
{
    [theDataLock lock];   //-----begin critical section
    [dataArray removeAllObjects];
	
	frameIndex = 0;
    reserveIndex = 0;
	
	dataAvailable = NO;
    addedData = NO;
    [theDataLock unlock];   //-----end critical section
}

- (BOOL) addedData
{
    return addedData;
}

- (void) setAddedData:(BOOL)flag
{
    addedData = flag;
}

@end
