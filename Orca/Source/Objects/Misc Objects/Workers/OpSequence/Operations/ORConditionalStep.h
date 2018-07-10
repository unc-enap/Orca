//
//  ConditionalStep.h
//  CocoaScript
//
//  Created by Matt Gallagher on 2010/11/04.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "OROpSeqStep.h"

@class ORConditionalStep;

typedef BOOL (^ConditionalStepBlock)(ORConditionalStep *);

@interface ORConditionalStep : OROpSeqStep
{
	ConditionalStepBlock block;
	BOOL runOnMainThread;
	BOOL conditionalResult;
	NSMutableSet *predicatedSteps;
}

@property (assign) ConditionalStepBlock block;
@property (readwrite) BOOL runOnMainThread;

+ (ORConditionalStep *)conditionalStepWithBlock:(ConditionalStepBlock)aBlock;
- (void)addPredicatedStep:(OROpSeqStep *)step;

@end
