//
//  ScriptQueue.m
//  CocoaScript
//
//  Created by Matt Gallagher on 2010/11/01.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "OROpSequenceQueue.h"
#import "OROpSeqStep.h"

NSString * const ScriptQueueCancelledNotification = @"ScriptQueueCancelledNotification";

@implementation OROpSequenceQueue
@synthesize textAttributes;
@synthesize errorAttributes;

- (id) init
{
	self = [super init];
	if (self != nil) {
		queueState          = [[NSMutableDictionary alloc] init];
		cleanupSteps        = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
    [textAttributes release];
    [errorAttributes release];
	[queueState        release];
	[cleanupSteps      release];    
	[super dealloc];
}

- (void) setStateValue:(id)value forKey:(NSString *)key
{
	@synchronized(self) {
		[queueState setValue:value forKey:key];
	}
}

- (id) stateValueForKey:(NSString *)key
{
	id value = nil;
	@synchronized(self) {
		value = [[[queueState valueForKey:key] retain] autorelease];
	}
	return value;
}

- (void) postCancelledNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:ScriptQueueCancelledNotification object:self];
}

- (void) cancelAllOperations
{
	@synchronized(self){
		[super cancelAllOperations];
	
		for (OROpSeqStep *cleanupStep in cleanupSteps){
			[self addOperation:cleanupStep];
		}
		[cleanupSteps removeAllObjects];
	}

	[self performSelectorOnMainThread:@selector(postCancelledNotification) withObject:nil waitUntilDone:NO];
}

//
// insertStepToRunImmediately:blockingDependentsOfStep:
//
// Used to ensure, while the queue is running that the provided scriptStep is
// the immediate next step to execute.
//
// To ensure that subsequent steps don't try to run simulaneously with this new
// high priority step, you can provide a dependeeStep whose dependents will all
// be made dependent upon the new scriptStep (forcing them to block until the
// scriptStep is complete).
//
// Parameters:
//    scriptStep - new high priority script step
//    dependeeStep - step whose dependents should block until after scriptStep
//
- (void) insertStepToRunImmediately:(OROpSeqStep*)scriptStep
           blockingDependentsOfStep:(OROpSeqStep*)dependeeStep
{
	for (NSOperation *dependency in [[[scriptStep dependencies] copy] autorelease]){
		[scriptStep removeDependency:dependency];
	}
	[scriptStep setConcurrentStep:scriptStep];
	[scriptStep setQueuePriority:NSOperationQueuePriorityVeryHigh];

	if (dependeeStep){
		for (NSOperation *operation in [self operations]){
			if ([[operation dependencies] containsObject:dependeeStep]){
				[operation addDependency:scriptStep];
			}
		}
	}

	[self addOperation:scriptStep];
}

//
// addOperation:
//
// Override of operation to change the default concurrency behavior.
//
// For regular NSOperationQueues, the default is no dependency between steps.
//
// For ScriptQueue, the default is that a new step is always made dependent on
// the previous step in the queue.
//
// This default can be changed by setting the "concurrentStep" -- where all the
// dependencies of the "concurrentStep" are used as dependencies instead.
//
// If the "concurrentStep" is equal to the "scriptStep" then no dependencies are
// added to the "scriptStep".
//
// Parameters:
//    scriptStep - the step to add to the queue.
//
- (void)addOperation:(OROpSeqStep *)scriptStep
{
	OROpSeqStep *simultaneousStep = [scriptStep concurrentStep];
	if (simultaneousStep && simultaneousStep != scriptStep){
		NSInteger stepIndex = [[self operations] indexOfObject:simultaneousStep];
		if (stepIndex != NSNotFound){
			for (OROpSeqStep *dependency in [simultaneousStep dependencies]){
				[scriptStep addDependency:dependency];
			}
		}
	}
	else if (!simultaneousStep){
		OROpSeqStep *lastStep = [[self operations] lastObject];
		if (lastStep){
			[scriptStep addDependency:lastStep];
		}
	}
	
	[super addOperation:scriptStep];
}


- (void)addCleanupStep:(OROpSeqStep *)cleanupStep
{
	@synchronized(self){
		[cleanupSteps addObject:cleanupStep];
	}
}

// -- ops for cleanup if sequence is cancelled
- (void)pushCleanupStep:(OROpSeqStep *)cleanupStep
{
	@synchronized(self){
		[cleanupSteps insertObject:cleanupStep atIndex:0];
	}
}


- (void)removeCleanupStep:(OROpSeqStep *)cleanupStep
{
	@synchronized(self){
		[cleanupSteps removeObject:cleanupStep];
	}
}


- (void)clearState
{
	@synchronized(self){
		[queueState removeAllObjects];
		[cleanupSteps removeAllObjects];
	}
}

@end
