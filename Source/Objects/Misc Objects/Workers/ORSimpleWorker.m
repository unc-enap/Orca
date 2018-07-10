//
//  ORSimpleWorker.m
//  ThreadExample
//
//  Created by Mark Howe on Thurs 11/21/02. Borrowed heavily from Yacktman's book.
//  Copyright (c) CENPA, University of Washington. All rights reserved.
//

#pragma mark ¥¥¥Imported Files
#import "ORSimpleWorker.h"

#pragma mark ¥¥¥Private Interface
//-------------------------------------------------------------------------------------------
// private interface for ORSimpleWorker
//-------------------------------------------------------------------------------------------
@interface ORSimpleWorker(_private)
+ (void)_connectWithPorts:(NSArray *)portArray;
- (void)_workStep:(id)sender;
- (void)_doWork;
- (void)_cancelPendingWork;
- (void)_updateProgress;
@end
//-------------------------------------------------------------------------------------------


@implementation ORSimpleWorker

#pragma mark ¥¥¥Class Methods
// sets up a DO connection in the main thread and then kicks off a
// new thread with a brand new server object in it.
+ (NSConnection *)startWorkerThreadWithTag:(int)theTag forController:(id <SimpleWorkerController>)controller
{
    NSPort *port1 = [NSPort port];
    NSPort *port2 = [NSPort port];
    NSArray *portArray = [NSArray arrayWithObjects:port2, port1, [NSNumber numberWithInt:theTag], nil];
    NSConnection *serverConnection = [[NSConnection alloc] initWithReceivePort:port1 sendPort:port2];
    [serverConnection setRootObject:controller];
    [NSThread detachNewThreadSelector:@selector(_connectWithPorts:) toTarget:self withObject:portArray];
    return serverConnection;
}


#pragma mark ¥¥¥Intialization
- (id)init
{
    return [self initForParent:nil withTag:0];
}

- (id)initForParent:(id <SimpleWorkerController>)theParent withTag:(int)theTag
{
    self = [super init];
    if (!self) return nil;
	
    tag 			 = theTag;
    amountDone 		 = 0;
    oldAmountDone 	 = 0;
    parent 			 = theParent;
    suppressProgress = NO;
    running 		 = NO;
    paused 			 = NO;
	
    return self;
}

#pragma mark ¥¥¥Accessors
- (id) parent
{
	return parent;
}

- (int) amountDone
{
	return amountDone;
}

- (void) setAmountDone:(int)aValue
{
	amountDone = aValue;
}

- (int) running
{
	return running;
}

- (int) tag
{
	return tag;
}

- (BOOL)isRunning
{
    return running;
}

- (BOOL)isPaused
{
    return paused;
}

#pragma mark ¥¥¥Thread Run Control
- (void)startWork
{
	running = NO;
	[self _cancelPendingWork];
    [self _updateProgress];

	[parent workerStarted:tag];
	
    amountDone = 0;
	oldAmountDone = amountDone;
    running = YES;
    [self _updateProgress];
    [self resume];
}

- (void)togglePause
{
    if (!running) return;
    if (paused) [self resume];
    else [self pause];
}

- (void)pause
{
    paused = YES;
    [self _cancelPendingWork];
}

- (void)resume
{
    if (!running) return;
    paused = NO;
    [self _doWork];
}

- (void)stopWork
{
	running = NO;
	[self _cancelPendingWork];
    [self _updateProgress];
	[parent workerStopped:tag];
}


- (void)doWork
{
    amountDone += 1; // dummy implementation to force progress
}

- (float)delayBetweenSteps
{
    return 0.0; // default is to not wait between calculation steps
}

- (BOOL) suppressProgress
{
	return suppressProgress;
}


#pragma mark ¥¥¥Private Methods
// finish setting the the DO connection to the main thread
// and set up a run loop for this thread.  The main thread
// will call us with requests to process data which the run
// loop will pick up.  If there's nothing to do, the run
// loop will block and no CPU time will be wasted.
+ (void)_connectWithPorts:(NSArray *)portArray
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSConnection *serverConnection = [NSConnection connectionWithReceivePort:[portArray objectAtIndex:0] sendPort:[portArray objectAtIndex:1]];
    int theTag 	 = [[portArray objectAtIndex:2] intValue];
    id rootProxy = (id)[serverConnection rootProxy];
    ORSimpleWorker *serverObject = [[self alloc] initForParent:rootProxy withTag:theTag];
    [rootProxy setWorker:serverObject tag:theTag];
    [serverObject release];
    [[NSRunLoop currentRunLoop] run];
    [pool release];
}

- (void)_workStep:(id)sender
{
    [self doWork];
    if (amountDone >= 100) {
        amountDone = 100;
        running = NO;
    }
    if(amountDone!=oldAmountDone){
		[self _updateProgress];
		oldAmountDone = amountDone;
	}
	if (running) [self _doWork];
}

- (void)_updateProgress
{
    if (![self suppressProgress]) {
        [parent setWorkerProgress:(double)amountDone finished:running tag:tag];
    }
}

- (void)_doWork
{
	[self performSelector:@selector(_workStep:) withObject:self afterDelay:[self delayBetweenSteps]];
}

- (void)_cancelPendingWork
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self
				selector:@selector(_workStep:) object:self];
}

@end
