//
//  ORTimedWorker.h
//  Orca
//
//  Created by Mark Howe on Mon Nov 25 2002.
//  Copyright (c) 2002 CENPA, University of Washington. All rights reserved.
//

#pragma mark ¥¥¥Imported Files
#import <Cocoa/Cocoa.h>

#import "ORSimpleWorker.h"
@protocol TimedWorkerMethods <WorkerMethods>
- (void)startTimedWork:(NSTimeInterval)aTimeToRun;
@end

#pragma mark ¥¥¥Protocol
@protocol TimedWorkerController
- (void)setWorker:(id)anObject tag:(int)serverTag;
- (void)setWorkerProgress:(double)newStatus finished:(BOOL)running tag:(int)tag;
- (void)setWorkerElapsed:(NSTimeInterval)elapsedTime totalTimeToRun:(NSTimeInterval)timeToGo;
@end

@interface ORTimedWorker : ORSimpleWorker {
	@private
	BOOL timedWork;
    NSDate* startDate;
    NSTimeInterval startTime;
    NSTimeInterval elapsedTime;
    NSTimeInterval totalTimeToRun;
	NSTimeInterval timeLeft;
	NSTimeInterval lastElapsedTime;
}

- (void)startTimedWork:(NSTimeInterval)aTimeToRun;

@end

