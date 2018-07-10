//
//  ConditionalStep.m
//  CocoaScript
//
//  Created by Matt Gallagher on 2010/11/05.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "ORConditionalStep.h"


@implementation ORConditionalStep

@synthesize block;
@synthesize runOnMainThread;

//
// conditionalStepWithBlock:
//
// ConditionalStep is a step which runs a block that returns a boolean. If the
// boolean is false, then the set of predicatedSteps are removed from the
// queue.
//
// Parameters:
//    aBlock - the block which is run and returns a boolean.
//
// returns the initialized step
//
+ (ORConditionalStep *)conditionalStepWithBlock:(ConditionalStepBlock)aBlock
{
	ORConditionalStep *step = [[[self alloc] init] autorelease];
	step->predicatedSteps = [[NSMutableSet alloc] init];	
	step.block = Block_copy(aBlock);

	return step;
}

//
// runStep
//
// Runs the block (optionally on the main thread) and removes steps if it
// returns false.
//
- (void)runStep
{
    [super runStep];
	if (runOnMainThread)    dispatch_sync(dispatch_get_main_queue(), ^{conditionalResult = block(self);});
	else                    conditionalResult = block(self);
	
	if (!conditionalResult){
		//
		// Cancel all predicated steps since the condition is false
		//
		for (OROpSeqStep *predicatedStep in predicatedSteps){
			//
			// Before cancelling a step, we must make sure that any step
			// which lists the soon-to-be-cancelled step as a dependency
			// instead becomes dependent on the soon-to-be-cancelled step's
			// dependencies
			//
			NSArray *operations = [currentQueue operations];
			NSInteger operationsCount = [operations count];
			NSInteger stepIndex = [operations indexOfObject:predicatedStep];
			if (stepIndex > 0 && stepIndex != NSNotFound){
                NSInteger i;
				for (i = stepIndex + 1; i < operationsCount; i++){
					NSOperation *currentStep = [operations objectAtIndex:i];
					if ([[currentStep dependencies] containsObject:predicatedStep]){
						for (NSOperation *dependency in [predicatedStep dependencies]){
							[currentStep addDependency:dependency];
						}
					}
				}
			}
			
			[predicatedStep cancel];
		}
	}
}

- (void)addPredicatedStep:(OROpSeqStep *)step
{
	[predicatedSteps addObject:step];
}

- (void)dealloc
{
	[predicatedSteps release];
	Block_release(block);

	[super dealloc];
}

@end
