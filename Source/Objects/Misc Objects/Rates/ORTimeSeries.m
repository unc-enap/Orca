//
//  ORTimeSeries.m
//  Orca
//
//  Created by Mark Howe on Tue Sep 09 2003.
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


//
// averages a set of time data.
//

#import "ORTimeSeries.h"

NSString* ORTimeSeriesChangedNotification 	= @"ORTimeSeriesChangedNotification";

@implementation ORTimeSeries
- (id) init
{
	self = [super init];
	writeIndex = 0;
	lastWriteIndex = 0;
	readIndex = 0;
	return self;
}

#pragma mark ¥¥¥Accessors
- (void) clear
{
	writeIndex = 0;
	readIndex = 0;
	int i;
	for(i=0;i<kTimeSeriesBufferSize;i++){
		value[i] = 0;
		time[i] = 0;
	}
	[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORTimeSeriesChangedNotification object:self userInfo:nil];
}

- (uint32_t) startTime
{
	return time[readIndex];
}

- (void) addValue:(float)aValue atTime:(uint32_t)aTime
{		
	if(aTime != time[lastWriteIndex]){
		value[writeIndex] = aValue;
		time[writeIndex]  = aTime;
		lastWriteIndex = writeIndex;
		writeIndex = (writeIndex+1)%kTimeSeriesBufferSize;
		if(writeIndex == readIndex){
			//the circular buffer is full, advance the read position
			readIndex = (readIndex+1)%kTimeSeriesBufferSize;
		}
				
		[[NSNotificationCenter defaultCenter] postNotificationOnMainThreadWithName:ORTimeSeriesChangedNotification object:self userInfo:nil];
	}
}

- (NSUInteger) count
{
	if(writeIndex == 0 && readIndex==0)return 0;
	else if(writeIndex > readIndex)return writeIndex - readIndex;
	else return kTimeSeriesBufferSize-readIndex + writeIndex;
}


- (void) index:(NSUInteger)index time:(uint32_t*)theTime value:(double*)y
{
	if(index<kTimeSeriesBufferSize){
		int i = (readIndex+index)%kTimeSeriesBufferSize;
		*y = value[i];
		*theTime = time[i];
	}
}

- (uint32_t) timeAtIndex:(NSUInteger)index
{
	if(index<kTimeSeriesBufferSize){
		int i = (readIndex+index)%kTimeSeriesBufferSize;
		return time[i];
	}
	else return [self startTime];
}

- (float) valueAtIndex:(NSUInteger)index
{
	if(index<kTimeSeriesBufferSize){
		int i = (readIndex+index)%kTimeSeriesBufferSize;
		return value[i];
	}
	else return [self startTime];
}

@end
