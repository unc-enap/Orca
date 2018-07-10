//
//  ORSimpleWorker.h
//  ThreadExample
//
//  Created by don on Sat Dec 08 2001.
//  Copyright (c) 2001 Don Yacktman. All rights reserved.
//

#pragma mark ¥¥¥Imported Files
#import <Foundation/Foundation.h>
@protocol WorkerMethods
- (void)startWork;
- (void)togglePause;
- (void)pause;
- (void)resume;
- (void)stopWork;
- (BOOL)isRunning;
- (BOOL)isPaused;
@end

@protocol SimpleWorkerController
// the server object will send the controller (parent) these messages
- (void) workerStarted:(int)serverTag;
- (void) workerStopped:(int)serverTag;
- (void)setWorker:(id)anObject tag:(int)serverTag;
- (void)setWorkerProgress:(double)newStatus finished:(BOOL)running tag:(int)tag;
@end


@interface ORSimpleWorker : NSObject
{
	@private
    int amountDone, oldAmountDone, tag;
    BOOL paused, running, suppressProgress;
    id <SimpleWorkerController> parent;
}

// you call this to spawn a new thread
#pragma mark ¥¥¥Class Methods
+ (NSConnection *) startWorkerThreadWithTag:(int)tag forController:(id <SimpleWorkerController>)controller;

#pragma mark ¥¥¥Control
- (void)startWork;
- (void)togglePause;
- (void)pause;
- (void)resume;
- (void)stopWork;
- (BOOL)isRunning;
- (BOOL)isPaused;

#pragma mark ¥¥¥Accessors
- (int)   amountDone;
- (void)  setAmountDone:(int)aValue;
- (int)   running;
- (int)   tag;
- (BOOL)  isPaused;
- (BOOL)  isRunning;
- (id)    parent;

- (BOOL)  suppressProgress;

	// these are for subclasses to override
- (id) initForParent:(id <SimpleWorkerController>)theParent withTag:(int)theTag; // be sure to call super!
- (void) doWork; // don't call super!  (be sure to set "amountDone" correctly between 0 and 100 before returning)
- (float) delayBetweenSteps; // don't call super! (default is no delay -- 0.0)

@end
