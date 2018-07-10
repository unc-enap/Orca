//
//  ORTimedWorker.m
//  Orca
//
//  Created by Mark Howe on Mon Nov 25 2002.
//  Copyright (c) 2002 . All rights reserved.
//

#pragma mark ¥¥¥Imported Files
#import "ORTimedWorker.h"

#pragma mark ¥¥¥Private Interface
//-------------------------------------------------------------------------------------------
// private interface for ORSimpleWorker
//-------------------------------------------------------------------------------------------
@interface ORTimedWorker (private)
- (void) _initTimes;
@end
//-------------------------------------------------------------------------------------------

@implementation ORTimedWorker

-(void)startWork
{
	[super startWork];
	timedWork = NO;
	
	elapsedTime = 0;
	lastElapsedTime = elapsedTime;
	
	[self _initTimes];
}

- (void)startTimedWork:(NSTimeInterval)aTimeToRun
{
	[super startWork];
	totalTimeToRun = aTimeToRun;
	timeLeft = totalTimeToRun;
	timedWork = YES;
	[self _initTimes];
}

- (void)doWork
{
	elapsedTime = [NSDate timeIntervalSinceReferenceDate]-startTime;
	if(abs(elapsedTime - lastElapsedTime) >=1){
		[[self parent] setWorkerElapsed:elapsedTime totalTimeToRun:timeLeft];
		lastElapsedTime = elapsedTime;
	}
	if(timedWork){
		timeLeft = (totalTimeToRun - elapsedTime) + 1;
		[self setAmountDone:100*elapsedTime/(float)totalTimeToRun];
		if(timeLeft<=1){
			[self setAmountDone:100]; //this forces the thread to halt
			timeLeft = 0;
			[[self parent] setWorkerElapsed:elapsedTime totalTimeToRun:timeLeft];
			[[self parent] workerStopped:[self tag]];
		}
	}
	
}

#pragma mark ¥¥¥Private Methods
- (void) _initTimes
{
	startDate = [NSDate date];
	startTime = [NSDate timeIntervalSinceReferenceDate];
}


@end
