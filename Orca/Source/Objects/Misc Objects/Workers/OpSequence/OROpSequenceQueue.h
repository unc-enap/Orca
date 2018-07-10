//
//  ScriptQueue.h
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

#import <Cocoa/Cocoa.h>

@class OROpSeqStep;

@interface OROpSequenceQueue : NSOperationQueue
{
	NSMutableDictionary*    queueState;
	NSMutableArray*         cleanupSteps;
    NSDictionary*           textAttributes;
    NSDictionary*           errorAttributes;
}

- (void) setStateValue:(id)value forKey:(NSString *)key;
- (id)   stateValueForKey:(NSString *)  key;
- (void) clearState;
- (void) addCleanupStep:(OROpSeqStep*)   cleanupStep;
- (void) pushCleanupStep:(OROpSeqStep*)  cleanupStep;
- (void) removeCleanupStep:(OROpSeqStep*)cleanupStep;
- (void) insertStepToRunImmediately:(OROpSeqStep*)scriptStep
	blockingDependentsOfStep:(OROpSeqStep*)dependeeStep;


@property (nonatomic, copy) NSDictionary* textAttributes;
@property (nonatomic, copy) NSDictionary* errorAttributes;


@end

extern NSString* const ScriptQueueCancelledNotification;
